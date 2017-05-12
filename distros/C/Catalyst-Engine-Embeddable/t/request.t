use strict;
use warnings;

use Test::More tests => 10;

use HTTP::Request;

BEGIN { $ENV{CATALYST_ENGINE} = 'Embeddable' };
BEGIN { use_ok('Catalyst::Engine::Embeddable') };

use lib 't/lib';
require TestApp;

my ($req, $res);

$req = HTTP::Request->new(GET => '/foo');
$res = undef;

TestApp->handle_request($req, \$res);

ok($res, 'Response object defined.');
is($res->code, 200, 'Response code correct.');
is($res->content, 'Hello World!', 'Resonse content correct.');

$req = HTTP::Request->new(GET => '/bar?who=Embed');
$res = undef;

TestApp->handle_request($req, \$res);

ok($res, 'Response object defined.');
is($res->code, 200, 'Response code correct.');
is($res->content, 'Hello Embed!', 'Resonse content correct.');

$req = HTTP::Request->new(POST => '/bar');
$res = undef;

$req->content_type('application/x-www-form-urlencoded');
my $post_body = 'who=Post';
$req->content($post_body);
$req->content_length(length($post_body));

TestApp->handle_request($req, \$res);

ok($res, 'Response object defined.');
is($res->code, 200, 'Response code correct.');
is($res->content, 'Hello Post!', 'Resonse content correct.');

