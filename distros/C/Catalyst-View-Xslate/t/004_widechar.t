use strict;
use utf8;
use Encode;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test_render?template=widechar.tx&param=test"))->is_success, 'request ok');
is($response->content, encode_utf8("テストtest"), 'wide characters ok');

ok(($response = request("/test_render?view=SJIS&template=widechar.tx&param=test"))->is_success, 'request ok');
is($response->content, encode("Shift_JIS", "テストtest"), 'wide characters ok');
