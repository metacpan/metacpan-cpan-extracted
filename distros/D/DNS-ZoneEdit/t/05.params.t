use strict;
use warnings;

use Test::More tests => 8;

#==============================================================================#

BEGIN { use_ok('DNS::ZoneEdit') };

my $ze = DNS::ZoneEdit->new();

my $params;

$params = $ze->_make_request_url(hostname=>"hostvalue",myip=>"address");
like($params,qr/host=/,"hostname in param query");
like($params,qr/hostvalue/,"hostname paramvalue in query");
like($params,qr/dnsto=/,"myip param in query");
like($params,qr/address/,"myip paramvalue in query");

## Secure, complicated by whether we can actuall do SSL (requires Crypt::SSLeay)
if ( $ze->_can_do_https() ) {
    $params = $ze->_make_request_url(secure=>1);
    like($params,qr/https:/,"SSL=1 Secure=1");
    $params = $ze->_make_request_url(secure=>undef);
    like($params,qr/https:/,"SSL=1 Secure=undef");
    $params = $ze->_make_request_url(secure=>0);
    like($params,qr/http:/,"SSL=1 Secure=0");
} else {
    $params = $ze->_make_request_url(secure=>undef);
    like($params,qr/http:/,"SSL=0 Secure=undef");
    $params = $ze->_make_request_url(secure=>0);
    like($params,qr/http:/,"SSL=0 Secure=0");
    ok(1,"SSL=0, Secure=1 - not actually tested");
}

#==============================================================================#
