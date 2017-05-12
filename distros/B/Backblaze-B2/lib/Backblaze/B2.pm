package Backblaze::B2;
use strict;
use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

Backblaze::B2 - interface to the Backblaze B2 API

=head1 SYNOPSIS

=head1 METHODS

=head2 C<< Backblaze::B2->new %options >>

=over 4

=item B<< version >>

Allows you to specify the API version. The current
default is C<< v1 >>, which corresponds to the
Backblaze B2 API version 1 as documented at
L<https://www.backblaze.com/b2/docs/>.

=back

=cut

sub new {
    my( $class, %options ) = @_;
    $options{ version } ||= 'v1';
    $class = "$class\::$options{ version }";
    $class->new( %options );
};

=head1 SETUP

=over 4

=item 0. Have a telephone / mobile phone number you're willing to
share with Backblaze

=item 1. Register at for Backblaze B2 Cloud Storage at 

L<https://secure.backblaze.com/account_settings.htm?showPhone=true>

=item 2. Add the phone number to your account at

L<https://secure.backblaze.com/account_settings.htm?showPhone=true>

=item 3. Enable Two-Factor verification through your phone at

L<https://secure.backblaze.com/account_settings.htm?showPhone=true>

=item 4. Create a JSON file named C<B2.credentials>

This file should live in your
home directory
with the application key and the account key:

    { "accountId":      "...",
      "applicationKey": ".............."
    }

=back

=cut

package Backblaze::B2::v1;
use strict;
use Carp qw(croak);

=head1 NAME

Backblaze::B2::v1 - Backblaze B2 API account

=head1 METHODS

=head2 C<< ->new %options >>

    my $b2 = Backblaze::B2::v1->new(
        api => 'Backblaze::B2::v1::Synchronous', # the default
    );

Creates a new instance. Depending on whether you pass in
C<<Backblaze::B2::v1::Synchronous>> or C<<Backblaze::B2::v1::AnyEvent>>,
you will get a synchronous or asynchronous API.

The synchronous API is what is documented here, as this is the
most likely use case.

    my @buckets = $b2->buckets();
    for( @buckets ) {
        ...
    }

The asynchronous API is identical to the synchronous API in spirit, but
will return L<Promises> . These condvars usually return
two or more parameters upon completion:

    my $results = $b2->buckets();
    $results->then( sub{ 
        my( @buckets ) = @_;
        for( @buckets ) {
            ...
        }
    }

The asynchronous API puts the burden of error handling into your code.

=cut

use vars '$API_BASE';
$API_BASE = 'https://api.backblazeb2.com/b2api/v1/';

sub new {
    my( $class, %options ) = @_;
    
    # Hrr. We need to get at an asynchronous API here and potentially
    # wrap the results to synchronous results in case the user wants them.
    # Turtles all the way down, this means we can't reuse calls into ourselves...

    $options{ api } ||= 'Backblaze::B2::v1::Synchronous';
    if( ! ref $options{ api }) {
        eval "require $options{ api }";
        my $class = delete $options{ api };
        $options{ api } = $class->new(%options);
    };
    
    if( $options{ api }->isAsync ) {
        $options{ bucket_class } ||= 'Backblaze::B2::v1::Bucket';
        $options{ file_class } ||= 'Backblaze::B2::v1::File';
    } else {
        $options{ bucket_class } ||= 'Backblaze::B2::v1::Bucket::Synchronized';
        $options{ file_class } ||= 'Backblaze::B2::v1::File::Synchronized';
    };
    
    bless \%options => $class
}

sub read_credentials {
    my( $self, @args ) = @_;
    $self->api->read_credentials(@args)
}

sub authorize_account {
    my( $self, @args ) = @_;
    $self->api->authorize_account(@args)
}

sub _new_bucket {
    my( $self, %options ) = @_;
    
    $self->{bucket_class}->new(
        %options,
        api => $self->api,
        parent => $self,
        file_class => $self->{file_class}
    )
}

sub await($) {
    my $promise = $_[0];
    my @res;
    if( $promise->is_unfulfilled ) {
        require AnyEvent;
        my $await = AnyEvent->condvar;
        $promise->then(sub{
            $await->send(@_);
        }, sub {
            warn "@_";
        });
        @res = $await->recv;
    } else {
        warn "Have results already";
        @res = @{ $promise->result }
    }
    @res
};

sub payload($) {
    my( $ok, $msg, @results ) = await( $_[0] );
    if(! $ok) { croak $msg };
    return wantarray ? @results : $results[0];
}

=head2 C<< ->buckets >>

    my @buckets = $b2->buckets();

Returns a list of L<Backblaze::B2::Bucket> objects associated with
the B2 account.

=cut

sub buckets {
    my( $self ) = @_;
    my $list = $self->api->asyncApi->list_buckets()->then( sub {
        my( $ok, $msg, $list ) = @_;
        map { $self->_new_bucket( %$_ ) }
            @{ $list->{buckets} }
    });
    
    if( !$self->api->isAsync ) {
        return Backblaze::B2::v1::payload $list
    } else {
        return $list
    }
}

=head2 C<< ->bucket_from_id >>

    my @buckets = $b2->bucket_from_id(
        'deadbeef'
    );

Returns a L<Backblaze::B2::Bucket> object that has the given ID. It
does not make an HTTP request to fetch the name and status of that bucket.

=cut

sub bucket_from_id {
    my( $self, $bucket_id ) = @_;
    $self->_new_bucket( bucketId => $bucket_id );
}

=head2 C<< ->create_bucket >>

    my $new_bucket = $b2->create_bucket(
        name => 'my-new-bucket', # only /[A-Za-z0-9-]/i are allowed as bucket names
        type => 'allPrivate', # or allPublic
    );
    
    print sprintf "Created new bucket %s\n", $new_bucket->id;

Creates a new bucket and returns it.

=cut

sub create_bucket {
    my( $self, %options ) = @_;
    $options{ type } ||= 'allPrivate';
    my $b = $self->api->asyncApi->create_bucket(
        bucketName => $options{ name },
        bucketType => $options{ type },
    )->then( sub {
        my( $bucket ) = @_;
        $self->_new_bucket( %$bucket );
    });

    if( !$self->api->isAsync ) {
        Backblaze::B2::v1::payload $b
    }
}

=head2 C<< ->api >>

Returns the underlying API object

=cut

sub api { $_[0]->{api} }

1;

package Backblaze::B2::v1::Bucket;
use strict;
use Scalar::Util 'weaken';

sub new {
    my( $class, %options ) = @_;
    weaken $options{ parent };
    
    # Whoa! We assume that the async version has the same class name
    # as the synchronous version and just strip it off.
    $options{ file_class } =~ s!::Synchronized$!!;
    
    bless \%options => $class,
}

sub name { $_[0]->{bucketName} }
#sub api { $_[0]->{api} }
sub downloadUrl { join "/", $_[0]->api->downloadUrl, $_[0]->name }
sub id { $_[0]->{bucketId} }
sub type { $_[0]->{bucketType} }
sub account { $_[0]->{parent} }

sub _new_file {
    my( $self, %options ) = @_;
    # Should this one magically unwrap AnyEvent::condvar objects?!
    
    #warn $self->{file_class};
    #use Data::Dumper;
    #warn Dumper \%options;
    
    $self->{file_class}->new(
        %options,
        api => $self->api,
        bucket => $self
    );
}

=head2 C<< ->files( %options ) >>

Lists the files contained in this bucket

    my @files = $bucket->files(
        startFileName => undef,
    );

By default it returns only the first 1000
files, but see the C<allFiles> parameter.

=over 4

=item C<< allFiles >>

    allFiles => 1

Passing in a true value for this parameter will make
as many API calls as necessary to fetch all files.

=back

=cut

sub files {
    my( $self, %options ) = @_;
    $options{ maxFileCount } ||= 1000;
    #$options{ startFileName } ||= undef;
    
    $self->api->asyncApi->list_all_file_names(
        bucketId => $self->id,
        %options,
    )->then( sub {
        my( $ok, $msg, @res ) = @_;
        
        $ok, $msg, map { $self->_new_file( %$_, bucket => $self ) } @res
    })
}

=head2 C<< ->upload_file( %options ) >>

Uploads a file into this bucket, potentially creating
a new file version.

    my $new_file = $bucket->upload_file(
        file => 'some/local/file.txt',
        target_file => 'the/public/name.txt',
    );

=over 4

=item C<< file >>

Local name of the source file. This file will be loaded
into memory in one go.

=item C<< target_file >>

Name of the file on the B2 API. Defaults to the local name.

The target file name will have backslashes replaced by forward slashes
to comply with the B2 API.

=item C<< mime_type >>

Content-type of the stored file. Defaults to autodetection by the B2 API.

=item C<< content >>

If you don't have the local content in a file on disk, you can
pass the content in as a string.

=item C<< mtime >>

Time in miliseconds since the epoch to when the content was created.
Defaults to the current time.

=item C<< sha1 >>

Hexdigest of the SHA1 of the content. If this is missing, the SHA1
will be calculated upon upload.

=back

=cut

sub upload_file {
    my( $self, %options ) = @_;
    
    my $api = $self->api->asyncApi;
    $api->get_upload_url(
        bucketId => $self->id,
    )->then(sub {
        my( $ok, $msg, $upload_handle ) = @_;
        $api->upload_file(
            %options,
            handle => $upload_handle
        );
    })->then( sub {
        my( $ok, $msg, @res ) = @_;

        (my $res) = map { $self->_new_file( %$_, bucket => $self ) } @res;
        $ok, $msg, $res
    });
}

=head2 C<< ->download_file_by_name( %options ) >>

Downloads a file from this bucket by name:

    my $content = $bucket->download_file_by_name(
        fileName => 'the/public/name.txt',
    );

This saves you searching through the list of existing files
if you already know the filename.

=cut

sub download_file_by_name {
    my( $self, %options ) = @_;
    $self->api->asyncApi->download_file_by_name(
        bucketName => $self->name,
        %options
    );
}

=head2 C<< ->get_download_authorization( %options ) >>

Downloads a file from this bucket by name:

    my $authToken = $bucket->get_download_authorization(
        fileNamePrefix => '/members/downloads/',
        validDurationInSeconds => 300, # five minutes
    );

This returns an authorization token that can download files with the
given prefix.

=cut

sub get_download_authorization {
    my( $self, %options ) = @_;
    $self->api->asyncApi->get_download_authorization(
        bucketId => $self->id,
        %options
    );
}

=head2 C<< ->api >>

Returns the underlying API object

=cut

sub api { $_[0]->{api} }

package Backblaze::B2::v1::Bucket::Synchronized;
use strict;
use Carp qw(croak);

sub name { $_[0]->{impl}->name }
#sub api { $_[0]->{api} }
sub downloadUrl { $_[0]->{impl}->downloadUrl }
sub id { $_[0]->{impl}->id }
sub type { $_[0]->{impl}->type }
sub account { $_[0]->{impl}->parent }

# Our simple method reflector
use vars '$AUTOLOAD';
sub AUTOLOAD {
    my( $self, @arguments ) = @_;
    $AUTOLOAD =~ /::([^:]+)$/
        or croak "Invalid method name '$AUTOLOAD' called";
    my $method = $1;
    $self->impl->can( $method )
        or croak "Unknown method '$method' called on $self";

    # Install the subroutine for caching
    my $namespace = ref $self;
    no strict 'refs';
    my $new_method = *{"$namespace\::$method"} = sub {
        my $self = shift;
        warn "In <$namespace\::$method>";
        my( $ok, $msg, @results) = Backblaze::B2::v1::await $self->impl->$method( @_ );
        #warn "Results: $ok/$msg/@results";
        if( ! $ok ) {
            croak $msg;
        } else {
            #use Data::Dumper;
            #warn Dumper \@results;
            return wantarray ? @results : $results[0]
        };
    };

    # Invoke the newly installed method
    goto &$new_method;
};

sub new {
    my( $class, %options ) = @_;
    
    my $self = {
        impl => Backblaze::B2::v1::Bucket->new(%options),
        file_class => $options{ file_class },
    };
    
    bless $self => $class,
}

sub impl { $_[0]->{impl} }

sub _new_file {
    my( $self, %options ) = @_;

    $self->{file_class}->new(
        %options,
        api => $self->api,
        bucket => $self
    );
}

=head2 C<< ->files( %options ) >>

Lists the files contained in this bucket

    my @files = $bucket->files(
        startFileName => undef,
    );

By default it returns only the first 1000
files, but see the C<allFiles> parameter.

=over 4

=item C<< allFiles >>

    allFiles => 1

Passing in a true value for this parameter will make
as many API calls as necessary to fetch all files.

=back

=cut

sub files {
    my( $self, %options ) = @_;
    map { $self->_new_file( impl => $_ ) }
        Backblaze::B2::v1::payload $self->impl->files( %options );
}

=head2 C<< ->upload_file( %options ) >>

Uploads a file into this bucket, potentially creating
a new file version.

    my $new_file = $bucket->upload_file(
        file => 'some/local/file.txt',
        target_file => 'the/public/name.txt',
    );

=over 4

=item C<< file >>

Local name of the source file. This file will be loaded
into memory in one go.

=item C<< target_file >>

Name of the file on the B2 API. Defaults to the local name.

The target file name will have backslashes replaced by forward slashes
to comply with the B2 API.

=item C<< mime_type >>

Content-type of the stored file. Defaults to autodetection by the B2 API.

=item C<< content >>

If you don't have the local content in a file on disk, you can
pass the content in as a string.

=item C<< mtime >>

Time in miliseconds since the epoch to when the content was created.
Defaults to the current time.

=item C<< sha1 >>

Hexdigest of the SHA1 of the content. If this is missing, the SHA1
will be calculated upon upload.

=back

=cut

sub upload_file {
    my( $self, %options ) = @_;

    Backblaze::B2::v1::payload $self->impl->upload_file( %options );
}

=head2 C<< ->download_file_by_name( %options ) >>

Downloads a file from this bucket by name:

    my $content = $bucket->download_file_by_name(
        file => 'the/public/name.txt',
    );

This saves you searching through the list of existing files
if you already know the filename.

=cut

sub download_file_by_name {
    my( $self, %options ) = @_;
    return Backblaze::B2::v1::payload $self->impl->download_file_by_name(
        %options
    )
}

=head2 C<< ->api >>

Returns the underlying API object

=cut

sub api { $_[0]->{api} }

package Backblaze::B2::v1::File;
use strict;
#use Scalar::Util 'weaken'; # do we really want to weaken our link?!
# The bucket doesn't hold a ref to us, so we don't want to weaken it

sub new {
    my( $class, %options ) = @_;
    #weaken $options{ bucket };
    #warn "$class: " . join ",", sort keys %options;
    
    bless \%options => $class,
}

sub name { $_[0]->{fileName} }
sub id { $_[0]->{fileId} }
sub action { $_[0]->{action} }
sub bucket { $_[0]->{bucket} }
sub size { $_[0]->{size} }
sub downloadUrl { join "/", $_[0]->bucket->downloadUrl, $_[0]->name }

package Backblaze::B2::v1::File::Synchronized;
use strict;
use Carp qw(croak);
#use Scalar::Util 'weaken'; # do we really want to weaken our link?!
# The bucket doesn't hold a ref to us, so we don't want to weaken it

sub new {
    my( $class, %options ) = @_;
    #weaken $options{ bucket };
    #warn "$class: " . join ",", sort keys %options;
    croak "Need impl" unless $options{ impl };
    
    bless \%options => $class,
}

sub name { $_[0]->{impl}->name }
sub id { $_[0]->{impl}->id }
sub action { $_[0]->{impl}->action }
sub bucket { $_[0]->{impl}->bucket }
sub size { $_[0]->{impl}->size }
sub downloadUrl { $_[0]->{impl}->downloadUrl }


1;
