
package AWS::S3::Request::SetBucketAccessControl;

use Moose;
use AWS::S3::Signer;

with 'AWS::S3::Roles::Request';

has 'bucket' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'acl_short' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has 'acl_xml' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has '+_expect_nothing' => ( default => 1 );

sub request {
    my $s = shift;

    if ( $s->acl_short ) {
        my $signer = AWS::S3::Signer->new(
            s3      => $s->s3,
            method  => 'PUT',
            uri     => $s->protocol . '://' . $s->bucket . '.' . $s->endpoint . '/?acl',
            headers => [ 'x-amz-acl' => $s->acl_short ]
        );
        return $s->_send_request(
            $signer->method => $signer->uri => {
                Authorization => $signer->auth_header,
                Date          => $signer->date,
                'x-amz-acl'   => $s->acl_short
            },
            $s->acl_xml
        );
    } elsif ( $s->acl_xml ) {
        my $signer = AWS::S3::Signer->new(
            s3             => $s->s3,
            method         => 'PUT',
            uri            => $s->protocol . '://' . $s->bucket . '.' . $s->endpoint . '/?acl',
            content        => \$s->acl_xml,
            'content-type' => 'text/xml',
        );
        return $s->_send_request(
            $signer->method => $signer->uri => {
                Authorization => $signer->auth_header,
                Date          => $signer->date,
            },
            $s->acl_xml
        );
    }    # end if()
}    # end request()

__PACKAGE__->meta->make_immutable;
