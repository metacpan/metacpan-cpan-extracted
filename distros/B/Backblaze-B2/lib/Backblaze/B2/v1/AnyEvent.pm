package Backblaze::B2::v1::AnyEvent;
use strict;
use JSON::XS;
use MIME::Base64;
use URI::QueryParam;
use Carp qw(croak);

use Promises
    backend => ['AnyEvent'], 'deferred';
use AnyEvent;
use AnyEvent::HTTP;
use URI;
use URI::Escape;
use Digest::SHA1;
use File::Basename;
use Encode;
use Data::Dumper;

use vars qw(@CARP_NOT $VERSION);
$VERSION = '0.02';
@CARP_NOT = qw(Backblaze::B2::v1::Synchronous);

sub isAsync { 1 }
sub api { $_[0] }
sub asyncApi { $_[0] }

sub new {
    my( $class, %options ) = @_;

    require Backblaze::B2;
    
    $options{ api_base } //= $Backblaze::B2::v1::API_BASE
                           = $Backblaze::B2::v1::API_BASE;

    croak "Need an API base"
        unless $options{ api_base };
    
    bless \%options => $class;
}

sub log_message {
    my( $self ) = shift;
    if( $self->{log_message}) {
        goto &{ $self->{log_message}};
    };
}

sub read_credentials {
    my( $self, $file ) = @_;
    
    if( ! defined $file) {
        require File::HomeDir;
        $file = File::HomeDir->my_home . "/credentials.b2";
        $self->log_message(0, "Using default credentials file '$file'");
    };
    
    $self->log_message(1, "Reading credentials from '$file'");
    
    open my $fh, '<', $file
        or croak "Couldn't read credentials from '$file': $!";
    binmode $fh;
    local $/;
    my $json = <$fh>;
    my $cred = decode_json( $json );
    
    $self->{credentials} = $cred;
    
    $cred
};

sub decode_json_response {
    my($self, $body,$hdr) = @_;
    
    $self->log_message(1, sprintf "HTTP Response status %d", $hdr->{Status});

    my @result;
    if( !$body) {
        $self->log_message(4, sprintf "No response body received");
        @result = (0, "No response body received", $hdr);
    } else {
        
        my $b = eval { decode_json( $body ); };
        if( my $err = $@ ) {
            $self->log_message(4, sprintf "Error decoding JSON response body: %s", $err);
            @result = (0, sprintf("Error decoding JSON response body: %s", $err), $hdr);
        } elsif( $hdr->{Status} =~ /^[45]\d\d$/ ) {
            my $reason = $b->{message} || $hdr->{Reason};
            my $status = $b->{status}  || $hdr->{Status};
            $self->log_message(4, sprintf "HTTP error status: %s: %s", $status, $reason);
            @result = ( 0, sprintf(sprintf "HTTP error status: %s: %s", $status, $reason));
        } else {
            @result = (1, "", $b);
        };
    };
    
    @result
}

# Provide headers from the credentials, if available
sub get_headers {
    my( $self ) = @_;
    if( my $token = $self->authorizationToken ) {
        return Authorization => $token
    };
    return ()
}

sub accountId {
    my( $self ) = @_;
    $self->{credentials}->{accountId}
}

sub authorizationToken {
    my( $self ) = @_;
    $self->{credentials}->{authorizationToken}
}

sub downloadUrl {
    my( $self ) = @_;
    $self->{credentials}->{downloadUrl}
}

sub apiUrl {
    my( $self ) = @_;
    $self->{credentials}->{apiUrl}
}


=head2 C<< ->request >>

Returns a promise that will resolve to the response data and the headers from
the request.

=cut

# You might want to override this if you want to use HIJK or
# some other way. If your HTTP requestor is synchronous, just
# return a
# AnyEvent->condvar
# which performs the real task.
# Actually, this now returns just a Promise

sub request {
    my( $self, %options) = @_;
    
    $options{ method } ||= 'GET';
    #my $completed = delete $options{ cb };
    my $method    = delete $options{ method };
    my $endpoint  = delete $options{ api_endpoint };
    my $headers = delete $options{ headers } || {};
    $headers = { $self->get_headers, %$headers };
    my $body = delete $options{ _body };
        
    my $url;
    if( ! $options{url} ) {
        croak "Don't know the api_endpoint for the request"
            unless $endpoint;
        $url = URI->new( join( "/b2api/v1/",
            $self->apiUrl,
            $endpoint)
        );
    } else {
        $url = delete $options{ url };
        $url = URI->new( $url )
            if( ! ref $url );
    };
    for my $k ( keys %options ) {
        my $v = $options{ $k };
        $url->query_param_append($k, $v);
    };
    $self->log_message(1, sprintf "Sending %s request to %s", $method, $url);
    
    my $res = deferred;
    my $req;
    $req = http_request $method => $url,
        headers => $headers,
        body => $body,
        sub {
            my( $data, $headers ) = @_;
            undef $req;
            $res->resolve($data, $headers);
            #undef $res; # justin case
        },
    ;
    
    $res->promise
}

=head2 C<< ->json_request >>

    my $res = $b2->json_request(...)->then(sub {
        my( $ok, $message, @stuff ) = @_;
    });

Helper routine that expects a JSON formatted response
and returns the decoded JSON structure.

=cut

sub json_request {
    my( $self, %options ) = @_;
    $self->request(
        %options
    )->then(sub {
        
        my( $body, $headers ) = @_;
        
        my $d = deferred;
        my @decoded = $self->decode_json_response($body, $headers);
        my $result = $d->promise;
        $d->resolve( @decoded );
        
        $result
    });
}

sub authorize_account {
    my( $self, %options ) = @_;
    $options{ accountId }
        or croak "Need an accountId";
    $options{ applicationKey }
        or croak "Need an applicationKey";
    my $auth= encode_base64( "$options{accountId}:$options{ applicationKey }" );

    my $url = $self->{api_base} . "b2_authorize_account";

    $self->json_request(
        url => $url,
        headers => {
            "Authorization" => "Basic $auth"
        },
    )->then( sub {
        my( $ok, $msg, $cred ) = @_;
        
        if( $ok ) {
            $self->log_message(1, sprintf "Storing authorization token");
            
            $self->{credentials} = $cred;
        };
        
        return ( $ok, $msg, $cred );
    });
}

=head2 C<< $b2->create_bucket >>

  $b2->create_bucket(
      bucketName => 'my_files',
      bucketType => 'allPrivate',
  );

Bucket names can consist of: letters, digits, "-", and "_". 

L<https://www.backblaze.com/b2/docs/b2_create_bucket.html>

The C<bucketName> has to be B<globally> unique, so expect
this request to fail, a lot.

=cut

sub create_bucket {
    my( $self, %options ) = @_;
    
    croak "Need a bucket name"
        unless defined $options{ bucketName };
    $options{ accountId } ||= $self->accountId;
    $options{ bucketType } ||= 'allPrivate'; # let's be defensive here...
    
    $self->json_request(api_endpoint => 'b2_create_bucket',
        accountId => $options{ accountId },
        bucketName => $options{ bucketName },
        bucketType => $options{ bucketType },
        %options
    )
}

=head2 C<< $b2->delete_bucket >>

  $b2->delete_bucket(
      bucketId => ...,
  );

Bucket names can consist of: letters, digits, "-", and "_". 

L<https://www.backblaze.com/b2/docs/b2_delete_bucket.html>

The bucket must be empty of all versions of all files.

=cut

sub delete_bucket {
    my( $self, %options ) = @_;
    
    croak "Need a bucketId"
        unless defined $options{ bucketId };
    $options{ accountId } ||= $self->accountId;
    
    my $res = AnyEvent->condvar;
    $self->json_request(api_endpoint => 'b2_delete_bucket',
        accountId => $options{ accountId },
        bucketId => $options{ bucketId },
        %options
    );
}

=head2 C<< $b2->list_buckets >>

  $b2->list_buckets();

L<https://www.backblaze.com/b2/docs/b2_list_buckets.html>

Returns the error status, the message and the payload.

=cut

sub list_buckets {
    my( $self, %options ) = @_;
    
    $options{ accountId } ||= $self->accountId;
    
    $self->json_request(api_endpoint => 'b2_list_buckets',
        accountId => $options{ accountId },
        %options
    )
}

=head2 C<< $b2->get_upload_url >>

  my $upload_handle = $b2->get_upload_url();
  $b2->upload_file( file => $file, handle => $upload_handle );

L<https://www.backblaze.com/b2/docs/b2_get_upload_url.html>

=cut

sub get_upload_url {
    my( $self, %options ) = @_;
    
    croak "Need a bucketId"
        unless defined $options{ bucketId };

    $self->json_request(api_endpoint => 'b2_get_upload_url',
        %options
    )
}

=head2 C<< $b2->upload_file >>

  my $upload_handle = $b2->get_upload_url();
  $b2->upload_file(
      file => $file,
      handle => $upload_handle
  );

L<https://www.backblaze.com/b2/docs/b2_upload_file.html>

Note: This method loads the complete file to be uploaded
into memory.

Note: The Backblaze B2 API is vague about when you need
a new upload URL.

=cut

sub upload_file {
    my( $self, %options ) = @_;
    
    croak "Need an upload handle"
        unless defined $options{ handle };
    my $handle = delete $options{ handle };

    croak "Need a source file name"
        unless defined $options{ file };
    my $filename = delete $options{ file };
        
    my $target_filename = delete $options{ target_name };
    $target_filename ||= $filename;
    $target_filename =~ s!\\!/!g;
    $target_filename = encode('UTF-8', $target_filename );
    $target_filename =~ s!([^\x21-\x7d])!sprintf "%%%02x", ord $1!ge;
    
    my $mime_type = delete $options{ mime_type } || 'b2/x-auto';
    
    if( not defined $options{ content }) {
        open my $fh, '<', $filename
            or croak "Couldn't open '$filename': $!";
        binmode $fh, ':raw';
        $options{ content } = do { local $/; <$fh> }; # sluuuuurp
        $options{ mtime } = ((stat($fh))[9]) * 1000;
    };

    my $payload = delete $options{ content };
    if( not $options{ sha1 }) {
        my $sha1 = Digest::SHA1->new;
        $sha1->add( $payload );
        $options{ sha1 } = $sha1->hexdigest;
    };
    my $digest = delete $options{ sha1 };
    my $size = length($payload);
    my $mtime = delete $options{ mtime };

    $self->json_request(
        url => $handle->{uploadUrl},
        method => 'POST',
        _body => $payload,
        headers => {
            'Content-Type' => $mime_type,
            'Content-Length' => $size,
            'X-Bz-Content-Sha1' => $digest,
            'X-Bz-File-Name' => $target_filename,
            'Authorization' => $handle->{authorizationToken},
        },
        %options
    );
}

=head2 C<< $b2->list_file_names >>

  my $startFileName;
  my $list = $b2->list_file_names(
      startFileName => $startFileName,
      maxFileCount => 1000, # maximum per round
      bucketId => ...,
      
  );

L<https://www.backblaze.com/b2/docs/b2_list_file_names.html>

=cut

sub list_file_names {
    my( $self, %options ) = @_;
    
    croak "Need a bucket id"
        unless defined $options{ bucketId };

    $self->json_request(
        api_endpoint => 'b2_list_file_names',
        %options
    );
}

=head2 C<< $b2->list_all_file_names >>

  my $list = $b2->list_all_file_names(
      startFileName => $startFileName,
      maxFileCount => 1000, # maximum per round
      bucketId => ...,
      
  );

Retrieves all filenames in a bucket

=cut

sub list_all_file_names {
    my( $self, %options ) = @_;
    
    croak "Need a bucket id"
        unless defined $options{ bucketId };

    my @results;
    
    my $handle_response; $handle_response = sub {
        my( $ok, $msg, $results ) = @_;
        
        $self->log_message(1, sprintf "Got filenames starting from '%s' to '%s'", 
                            $options{startFileName} || '',
                            $results->{nextFileName} || '');
        #use Data::Dumper;
        #warn Dumper $results;

        push @results, @{ $results->{files} };
        
        if( $results->{ endFileName }) {
            $options{ startFileName } = $results->{nextFileName};
            
            $self->log_message(1, sprintf "Requesting filenames starting from '%s'",
                           $options{startFileName} || '');
            # We recurse deeper, but AnyEvent should handle the stack for us
            return 
                $self->list_file_names( %options )
                     ->then( $handle_response );
        } else {
            # We've collected all items
            my $res = deferred;
            $res->resolve(1, "", @results);
            $res->promise
        }
    };
    
    $self->log_message(1, sprintf "Requesting filenames starting from '%s'", $options{startFileName} || '');
    $self->list_file_names( %options )
        ->then( $handle_response );
}


=head2 C<< $b2->download_file_by_name >>

  my $content = $b2->download_file_by_name(
      bucketName => $my_bucket_name,
      fileName => $my_file_name,
  );

L<https://www.backblaze.com/b2/docs/b2_download_file_by_name.html>

=cut

sub download_file_by_name {
    my( $self, %options ) = @_;
    
    croak "Need a bucket name"
        unless defined $options{ bucketName };
    croak "Need a file name"
        unless defined $options{ fileName };
    my $url = join '/',
        $self->{credentials}->{downloadUrl},
        'file',
        delete $options{ bucketName },
        delete $options{ fileName }
        ;
    $self->log_message(1, sprintf "Fetching %s", $url );

    $self->request(
        url => $url,
        %options
    )->then(sub {
        my( $body, $hdr ) = @_;
        $self->log_message(2, sprintf "Fetching %s, received %d bytes", $url, length $body );
        my $ok = $hdr->{Status} =~ /^2\d\d/;
        return( $ok, $hdr->{Reason}, $body );
    })
}

=head2 C<< $b2->get_download_authorization >>

  my $content = $b2->get_download_authorization(
      bucketId => $my_bucket_id,
      fileNamePrefix => $my_file_name,
      validDurationInSeconds => 300, # you have five minutes to start the download
  );

L<https://www.backblaze.com/b2/docs/b2_get_download_authorization.html>

=cut

sub get_download_authorization {
    my( $self, %options ) = @_;
    
    croak "Need a bucket id"
        unless defined $options{ bucketId };
    croak "Need a file name prefix"
        unless defined $options{ fileNamePrefix };
    croak "Need a duration for the token"
        unless defined $options{ validDurationInSeconds };

    $self->json_request(
        api_endpoint => 'b2_get_download_authorization',
        %options
    );
}


1;