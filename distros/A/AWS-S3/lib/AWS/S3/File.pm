
package AWS::S3::File;

use Moose;
use Carp 'confess';

use MooseX::Types -declare => [qw/fileContents/];
use MooseX::Types::Moose qw/Str ScalarRef CodeRef/;

subtype fileContents, as ScalarRef;
coerce fileContents,
  from  CodeRef,
  via   {
    my $ref = $_[0];
    my $v = $ref->();
    ref $v ? $v : \$v
  }
;

has 'key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'bucket' => (
    is       => 'ro',
    isa      => 'AWS::S3::Bucket',
    required => 1,
    weak_ref => 0,
);

has 'size' => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
    default  => sub {
      my $self = shift;
      return length ${$self->contents};
    }
);

has 'etag' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has 'owner' => (
    is       => 'ro',
    isa      => 'AWS::S3::Owner',
    required => 0,
    weak_ref => 1,
);

has 'storage_class' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'STANDARD',
    required => 1,
);

has 'lastmodified' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has 'contenttype' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => 'binary/octet-stream'
);

has 'is_encrypted' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $s = shift;

        my $type = 'GetFileInfo';
        my $req  = $s->bucket->s3->request(
            $type,
            bucket => $s->bucket->name,
            key    => $s->key,
        );

        return $req->request->response->header( 'x-amz-server-side-encryption' ) ? 1 : 0;
    },
);

has 'contents' => (
    is       => 'rw',
    isa      => fileContents,
    required => 0,
    lazy     => 1,
    coerce   => 1,
    default  => \&_get_contents,
    trigger  => \&_set_contents
);

sub BUILD {
    my $s = shift;

    return unless $s->etag;
    ( my $etag = $s->etag ) =~ s{^"}{};
    $etag =~ s{"$}{};
    $s->{etag} = $etag;
}    # end BUILD()

sub update {
    my $s       = shift;
    my %args    = @_;
    my @args_ok = grep { /^content(?:s|type)$/ } keys %args;
    if ( @args_ok ) {
        $s->{$_} = $args{$_} for @args_ok;
        $s->_set_contents();
        return 1;
    }
    return;
}    # end update()

sub _get_contents {
    my $s = shift;

    my $type = 'GetFileContents';
    my $req  = $s->bucket->s3->request(
        $type,
        bucket => $s->bucket->name,
        key    => $s->key,
    );

    return \$req->request->response->decoded_content;
}    # end contents()

sub _set_contents {
    my ( $s, $ref ) = @_;

    my $type     = 'SetFileContents';
    my %args     = ();
    my $response = $s->bucket->s3->request(
        $type,
        bucket                 => $s->bucket->name,
        file                   => $s,
        contents               => $ref,
        content_type           => $s->contenttype,
        server_side_encryption => $s->is_encrypted ? 'AES256' : undef,
    )->request();

    ( my $etag = $response->response->header( 'etag' ) ) =~ s{^"}{};
    $etag =~ s{"$}{};
    $s->{etag} = $etag;

    if ( my $msg = $response->friendly_error() ) {
        die $msg;
    }    # end if()
}    # end _set_contents()

sub signed_url {
    my $s       = shift;
    my $expires = shift || time + 3600;

	my $key = $s->key;

	if ( ! $s->bucket->s3->honor_leading_slashes ) {
		$key =~ s!^/!!;
	}

    my $type = "GetPreSignedUrl";
    my $uri  = $s->bucket->s3->request(
        $type,
        bucket  => $s->bucket->name,
        key     => $key,
        expires => $expires,
    )->request;

    return $uri;
}

sub delete {
    my $s = shift;

    my $type = 'DeleteFile';
    my $req  = $s->bucket->s3->request(
        $type,
        bucket => $s->bucket->name,
        key    => $s->key,
    );
    my $response = $req->request();

    if ( my $msg = $response->friendly_error() ) {
        die $msg;
    }    # end if()

    return 1;
}    # end delete()

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

AWS::S3::File - A single file in Amazon S3

=head1 SYNOPSIS

  my $file = $bucket->file('foo/bar.txt');
  
  # contents is a scalarref:
  print @{ $file->contents };
  print $file->size;
  print $file->key;
  print $file->etag;
  print $file->lastmodified;
  
  print $file->owner->display_name;
  
  print $file->bucket->name;
  
  # Set the contents with a scalarref:
  my $new_contents = "This is the new contents of the file.";
  $file->contents( \$new_contents );
  
  # Set the contents with a coderef:
  $file->contents( sub {
    return \$new_contents;
  });
  
  # Alternative update
  $file->update( 
    contents => \'New contents', # optional
    contenttype => 'text/plain'  # optional
  );

  # Get signed URL for the file for public access
  print $file->signed_url( $expiry_time );
  
  # Delete the file:
  $file->delete();

=head1 DESCRIPTION

AWS::S3::File provides a convenience wrapper for dealing with files stored in S3.

=head1 PUBLIC PROPERTIES

=head2 bucket

L<AWS::S3::Bucket> - read-only.

The L<AWS::S3::Bucket> that contains the file.

=head2 key

String - read-only.

The 'filename' (for all intents and purposes) of the file.

=head2 size

Integer - read-only.

The size in bytes of the file.

=head2 etag

String - read-only.

The Amazon S3 'ETag' header for the file.

=head2 owner

L<ASW::S3::Owner> - read-only.

The L<ASW::S3::Owner> that the file belongs to.

=head2 storage_class

String - read-only.

The type of storage used by the file.

=head2 lastmodified

String - read-only.

A date in this format:

  2009-10-28T22:32:00

=head2 contents

ScalarRef|CodeRef - read-write.

Returns a scalar-reference of the file's contents.

Accepts either a scalar-ref or a code-ref (which would return a scalar-ref).

Once given a new value, the file is instantly updated on Amazon S3.

  # GOOD: (uses scalarrefs)
  my $value = "A string";
  $file->contents( \$value );
  $file->contents( sub { return \$value } );
  
  # BAD: (not scalarrefs)
  $file->contents( $value );
  $file->contents( sub { return $value } );

=head1 PUBLIC METHODS

=head2 delete()

Deletes the file from Amazon S3.

=head2 update()

Update contents and/or contenttype of the file.

=head2 signed_url( $expiry_time )

Will return a signed URL for public access to the file. $expiry_time should be a
Unix seconds since epoch, and will default to now + 1 hour is not passed.

Note that the Signature parameter value will be URI encoded to prevent reserved
characters (+, =, etc) causing a bad request.

=head1 SEE ALSO

L<The Amazon S3 API Documentation|http://docs.amazonwebservices.com/AmazonS3/latest/API/>

L<AWS::S3>

L<AWS::S3::Bucket>

L<AWS::S3::FileIterator>

L<AWS::S3::Owner>

=cut

