
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

    return $s->signerv4->signed_url(
        $s->_uri,
        $s->expires,
        'GET',
    );
}

__PACKAGE__->meta->make_immutable;
