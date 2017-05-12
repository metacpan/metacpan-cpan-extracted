use strict;
use warnings;

use Test::More tests => 10;

use HTTP::Request;

BEGIN { $ENV{CATALYST_ENGINE} = 'Embeddable' };
BEGIN { use_ok('Catalyst::Engine::Embeddable') };

use lib 't/lib';
require TestApp;

my ($req, $res, @err);

$req = HTTP::Request->new(GET => '/eatit');
$res = undef;

TestApp->handle_request($req, \$res);

ok($res, 'Response object defined.');
is($res->code, 500, 'Response code correct.');
like($res->content, qr/Please come back later/, 'exception handled by catalyst');
cmp_ok((scalar @err), '==', 0, 'no errors returned');

TestApp->handle_request($req, \$res, \@err);

ok($res, 'Response object defined.');
is($res->code, 500, 'Response code correct.');
like($res->content, qr/Please come back later/, 'exception handled by catalyst');
cmp_ok((scalar @err), '==', 1, '1 error returned');
like($err[0], qr/Caught exception in TestApp::Controller::Root->eatit "DIAF/, 'first error message');

