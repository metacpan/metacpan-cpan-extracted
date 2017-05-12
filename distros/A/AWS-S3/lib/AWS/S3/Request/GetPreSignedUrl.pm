
package AWS::S3::Request::GetPreSignedUrl;
use Moose;

use AWS::S3::Signer;
use URI::Escape qw(uri_escape);

with 'AWS::S3::Roles::Request';

has 'bucket' => ( is => 'ro', isa => 'Str', required => 1 );
has 'key' => ( is => 'ro', isa => 'Str', required => 1 );
has 'expires' => ( is => 'ro', isa => 'Int', required => 1 );

sub request {
    my $s = shift;

    my $uri = $s->_uri;

    my $req = "GET\n\n\n"
        . $s->expires . "\n/"
        . $s->bucket . "/"
        . $s->key;

    my $signer = AWS::S3::Signer->new(
        s3             => $s->s3,
        method         => "GET",
        uri            => $uri,
        string_to_sign => $req,
    );

    my $signed_uri = $uri->as_string
        . '?AWSAccessKeyId=' . $s->s3->access_key_id
        . '&Expires=' . $s->expires
        . '&Signature=' . uri_escape( $signer->signature );

    return $signed_uri;
}

__PACKAGE__->meta->make_immutable;
