use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');

# JSON-RPC 2.0 success: no 'service' field, response carries jsonrpc:"2.0"
$t->post_ok('/QX-JSON-RPC' => json => { jsonrpc => '2.0', id => 1, method => 'ping' })
  ->status_is(200)
  ->content_type_is('application/json; charset=utf-8')
  ->json_is({ jsonrpc => '2.0', id => 1, result => 'pong' });

# Access-denied method (unknown / not in %allow) -> JSON-RPC 2.0 error with the
# integer code 6 preserved (the frontend's needs-login code). This is DB-free:
# allow_rpc_access returns 0 for any method absent from %allow before any auth/DB
# lookup. NOTE: code 6 (access denied) is checked before code 4 (method exists),
# which is intentional - we don't reveal method existence to unauthorized callers.
$t->post_ok('/QX-JSON-RPC' => json => { jsonrpc => '2.0', id => 2, method => 'nonesuch' })
  ->status_is(200)
  ->json_is('/jsonrpc' => '2.0')
  ->json_is('/id' => 2)
  ->json_is('/error/code' => 6)
  ->json_like('/error/message' => qr/denied/)
  ->json_hasnt('/result');   # error envelope must NOT carry a qx1 'result' key

# Missing jsonrpc version is rejected (non-2.0 request)
$t->post_ok('/QX-JSON-RPC' => json => { id => 3, method => 'ping' })
  ->status_is(500);

done_testing();
