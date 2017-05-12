use strict;
use warnings;

use Test::More tests => 7;

use HTTP::Request;

BEGIN { $ENV{CATALYST_ENGINE} = 'Embeddable' };
BEGIN { use_ok('Catalyst::Engine::Embeddable') };

use lib 't/lib';
require TestApp;

my ($req, $res);

$req = HTTP::Request->new(GET => 'http://www.catalystframework.org/mkuri?foo=bar');
$res = undef;

TestApp->handle_request($req, \$res);

ok($res, 'Response object defined.');
is($res->code, 200, 'Response code correct.');
is($res->content, 'http://www.catalystframework.org/path/to/somewhere');

$req = HTTP::Request->new(GET => 'http://www.catalystframework.org/mkuriwithpath?foo=bar&foo=baz&one=two');
$res = undef;

TestApp->handle_request($req, \$res);

ok($res, 'Response object defined.');
is($res->code, 200, 'Response code correct.');
is($res->content, 'http://www.catalystframework.org/path/to/somewhere?baz=qux');

