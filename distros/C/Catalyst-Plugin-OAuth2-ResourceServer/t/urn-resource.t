use v5.36;
use Test::More;
use lib 't/lib';
use HTTP::Request::Common qw/GET/;

use Catalyst::Test 'TestAppURN';

# The app's resource is a URN and it sets no resource_metadata_url, so the
# RFC 9728 well-known URL is not derivable. The challenge must still be a valid
# RFC 6750 Bearer challenge, just without a resource_metadata parameter.
{
    my $res = request( GET '/secure' );
    is( $res->code, 401, 'urn resource, missing token -> 401' );
    my $wa = $res->header('WWW-Authenticate') // '';
    like( $wa, qr/\ABearer\b/, 'still a well-formed Bearer challenge' );
    unlike( $wa, qr/resource_metadata/,
        'resource_metadata omitted when it cannot be derived' );
    unlike( $wa, qr/\burn:/, 'no fragment of the URN leaks into the header' );
}

# The historic bug emitted resource_metadata="urn:/.well-known/oauth-protected-resourceexample:resource".
{
    my $res = request( GET '/secure', Authorization => 'Bearer garbage' );
    is( $res->code, 401, 'urn resource, bad token -> 401' );
    my $wa = $res->header('WWW-Authenticate') // '';
    like( $wa, qr/error="invalid_token"/, 'error= still emitted' );
    unlike( $wa, qr{oauth-protected-resourceexample},
        'the malformed derived URL is gone' );
}

done_testing;
