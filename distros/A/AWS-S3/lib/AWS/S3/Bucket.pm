
package AWS::S3::Bucket;

use Carp 'confess';
use Moose;
use IO::Socket::INET;
use AWS::S3::ResponseParser;
use AWS::S3::FileIterator;

has 's3' => (
    is       => 'ro',
    isa      => 'AWS::S3',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'creation_date' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

use MooseX::Types -declare => [qw/ACLShorts/];

has 'acl' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    clearer  => '_clear_acl',
    default  => sub {
        my $self = shift;
        my $type = 'GetBucketAccessControl';
        return $self->_get_property( $type )->response->decoded_content();
    },
    trigger  => sub {
        my ( $self, $new_val, $old_val ) = @_;

        my %shorts = map { $_ => undef } qw(
          private public-read public-read-write authenticated-read
        );

        my %acl = ();
        if ( $new_val =~ m{<} ) {
            $acl{acl_xml} = $new_val;
        }
        elsif ( exists $shorts{$new_val} ) {
            $acl{acl_short} = $new_val;
        }
        else {
            die "Attempt to set an invalid value for acl: '$new_val'";
        }

        my $type     = 'SetBucketAccessControl';
        my $req      = $self->s3->request( $type, %acl, bucket => $self->name, );
        my $response = $req->request();

        return if $response->response->code == 404;

        if ( my $msg = $response->friendly_error() ) {
            die $msg;
        }    # end if()

        $self->_clear_acl;
    }
);

has 'location_constraint' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    default  => sub {
        my $self = shift;

        my $type     = 'GetBucketLocationConstraint';
        my $response = $self->_get_property( $type );

        my $constraint = $response->xpc->findvalue( '//s3:LocationConstraint' );
        if ( defined $constraint && $constraint eq '' ) {
            return;
        } else {
            return $constraint;
        }
    }
);

has 'policy' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    clearer  => '_clear_policy',
    default  => sub {
        my $self = shift;

        my $type     = 'GetBucketPolicy';
        my $req      = $self->s3->request( $type, bucket => $self->name, );
        my $response = $req->request();

        eval { $response->_parse_errors };
        if ( my $msg = $response->friendly_error() ) {
            if ( $response->error_code eq 'NoSuchBucketPolicy' ) {
                return '';
            } else {
                die $msg;
            }    # end if()
        }    # end if()

        return $response->response->decoded_content();
    },
    trigger  => sub {
        my ( $self, $policy ) = @_;

        my $type = 'SetBucketPolicy';
        my $req  = $self->s3->request(
            $type,
            bucket => $self->name,
            policy => $policy,
        );
        my $response = $req->request();

        #warn "NewPolicy:($policy).......\n";
        #warn $response->response->as_string;
        if ( my $msg = $response->friendly_error() ) {
            die $msg;
        }    # end if()

        $self->_clear_policy;

    }
);

# XXX: Not tested.
sub enable_cloudfront_distribution {
    my ( $s, $cloudfront_dist ) = @_;

    $cloudfront_dist->isa( 'AWS::CloudFront::Distribution' )
      or die "Usage: enable_cloudfront_distribution( <AWS::CloudFront::Distribution object> )";

    my $ident = $cloudfront_dist->cf->create_origin_access_identity( Comment => "Access to s3://" . $s->name, );
    $s->policy( <<"JSON");
{
	"Version":"2008-10-17",
	"Id":"PolicyForCloudFrontPrivateContent",
	"Statement":[{
			"Sid": "Grant a CloudFront Origin Identity access to support private content",
			"Effect":"Allow",
			"Principal": {
			  "CanonicalUser":"@{[ $ident->S3CanonicalUserId ]}"
			},
			"Action": "s3:GetObject",
			"Resource": "arn:aws:s3:::@{[ $s->name ]}/*"
		}
	]
}
JSON
}    # end enable_cloudfront_distribution()

sub files {
    my ( $s, %args ) = @_;

    return AWS::S3::FileIterator->new( %args, bucket => $s, );
}    # end files()

sub file {
    my ( $s, $key ) = @_;

    my $type = 'GetFileInfo';

    my $parser = $s->_get_property( $type, key => $key )
      or return;

    my $res = $parser->response;
    confess "Cannot get file: ", $res->as_string, " " unless $res->is_success;
    return AWS::S3::File->new(
        bucket       => $s,
        key          => $key || undef,
        size         => $res->header( 'content-length' ) || 0,
        contenttype  => $res->header( 'content-type' ) || 'application/octet-stream',
        etag         => $res->header( 'etag' ) || undef,
        lastmodified => $res->header( 'last-modified' ) || undef,
        is_encrypted => ( $res->header( 'x-amz-server-side-encryption' ) || '' ) eq 'AES256' ? 1 : 0,
    );
}    # end file()

sub add_file {
    my ( $s, %args ) = @_;

    my $file = AWS::S3::File->new(
        %args,
        bucket => $s
    );
    $file->contents( $args{contents} );
    return $file;
}    # end add_file()

sub delete {
    my ( $s ) = @_;

    my $type = 'DeleteBucket';

    my $req = $s->s3->request( $type, bucket => $s->name, );
    my $response = $req->request();

    if ( my $msg = $response->friendly_error() ) {
        die $msg;
    }    # end if()

    return 1;
}    # end delete()

# Working as of v0.023
sub delete_multi {
    my ( $s, @keys ) = @_;

    die "You can only delete up to 1000 keys at once"
      if @keys > 1000;
    my $type = 'DeleteMulti';

    my $req = $s->s3->request(
        $type,
        bucket => $s->name,
        keys   => \@keys,
    );
    my $response = $req->request();

    if ( my $msg = $response->friendly_error() ) {
        die $msg;
    }    # end if()

    return 1;
}    # end delete_multi()

sub _get_property {
    my ( $s, $type, %args ) = @_;

    my $req = $s->s3->request( $type, bucket => $s->name, %args );
    my $response = $req->request();

    return if $response->response->code == 404;

    if ( my $msg = $response->friendly_error() ) {
        die $msg;
    }    # end if()

    return $response;
}    # end _get_property()

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

AWS::S3::Bucket - Object representation of S3 Buckets

=head1 SYNOPSIS

See L<The SYNOPSIS from AWS::S3|AWS::S3/SYNOPSIS> for usage details.

=head1 CONSTRUCTOR

Call C<new()> with the following parameters.

=head1 PUBLIC PROPERTIES

=head2 s3

Required.  An L<AWS::S3> object.

Read-only.

=head2 name

Required.  String.

The name of the bucket.

Read-only.

=head2 creation_date

String.  Returned from the S3 service itself.

Read-only.

=head2 acl

String.  Returns XML string.

Read-only.

See also L<PUT Bucket ACL|http://docs.amazonwebservices.com/AmazonS3/latest/API/index.html?RESTBucketPUTacl.html>

=head2 location_constraint

String.  Read-only.

=over 4

=item * EU

=item * us-west-1

=item * us-west-2

=item * ap-southeast-1

=item * ap-northeast-1

=back

The default value is undef which means 'US'.

See also L<PUT Bucket|http://docs.amazonwebservices.com/AmazonS3/latest/API/index.html?RESTBucketPUT.html>

=head2 policy

Read-only.  String of JSON.

Looks something like this:

  {
    "Version":"2008-10-17",
    "Id":"aaaa-bbbb-cccc-dddd",
    "Statement" : [
      {
        "Effect":"Deny",
        "Sid":"1", 
        "Principal" : {
          "AWS":["1-22-333-4444","3-55-678-9100"]
        },
        "Action":["s3:*"],
        "Resource":"arn:aws:s3:::bucket/*",
      }
    ]
  }

See also L<GET Bucket Policy|http://docs.amazonwebservices.com/AmazonS3/latest/API/index.html?RESTBucketGETpolicy.html>

=head1 PUBLIC METHODS

=head2 files( page_size => $size, page_number => $number, [[marker => $marker,] pattern => qr/$pattern/ ] )

Returns a L<AWS::S3::FileIterator> object with the supplied arguments.

Use the L<AWS::S3::FileIterator> to page through your results.

=head2 file( $key )

Finds the file with that C<$key> and returns an L<AWS::S3::File> object for it.

=head2 delete_multi( \@keys )

Given an ArrayRef of the keys you want to delete, C<delete_multi> can only delete
up to 1000 keys at once.  Empty your buckets for deletion quickly like this:

  my $deleted = 0;
  my $bucket = $s->bucket( 'foobar' );
  my $iter = $bucket->files( page_size => 1000, page_number => 1 );
  while( my @files = $iter->next_page )
  {
    $bucket->delete_multi( map { $_->key } @files );
    $deleted += @files;
    # Reset to page 1:
    $iter->page_number( 1 );
    warn "Deleted $deleted files so far\n";
  }# end while()
  
  # NOW you can delete your bucket (if you want) because it's empty:
  $bucket->delete;

=head1 SEE ALSO

L<The Amazon S3 API Documentation|http://docs.amazonwebservices.com/AmazonS3/latest/API/>

L<AWS::S3::Bucket>

L<AWS::S3::File>

L<AWS::S3::FileIterator>

L<AWS::S3::Owner>

=cut

