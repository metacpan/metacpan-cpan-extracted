use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp', { default_host => 'default.com' };
use Catalyst::Request;

use Test::More tests => 14;

content_like('/index',qr/root/,'content check');
action_ok('/index','Action ok ok','normal action ok');

content_like('/verify_me', qr/success: 0\npage: undef$/,'empty verify ok');
content_like('/verify_me?page=5', qr/success: 0\npage: 5$/,'valid variable ok ');
content_like('/verify_me?page=-1', qr/success: 0\npage: invalid$/,'invalid variable is nothing');
content_like('/verify_me?query=Foo', qr/success: 1\npage: undef\nquery: Foo$/s,'simple var');
content_like('/verify_me?query=+Foo', qr/success: 1\npage: undef\nquery: Foo$/,'required var trimmed');
content_like('/verify_me?query=+Foo+Bar++', qr/success: 1\npage: undef\nquery: Foo Bar$/,'optional not set, required set');
content_like('/verify_me?query=+Foo+Bar++&page=5', qr/success: 1\npage: 5\nquery: Foo Bar$/,'all sorts of valid');
content_like('/verify_me?query=+Foo+Bar++&page=-1', qr/success: 0\nquery: Foo Bar\npage: invalid$/,'failed optional');

content_like('/verify_messages?query=+Foo+Bar++&page=-1', qr/success: 0\npage: invalid_page$/,'failed messaging');
content_like('/verify_override?foo.page=5&foo.query=Bar', qr/success: 1\npage: 5\nquery: Bar$/,'valid variable ok ');
# verify_messages: invalid_page
my ( $res, $c ) = ctx_request('/verify_me_and_die?oh=noes');
ok( @{ $c->error } == 1, 'correct error' );
like($c->error->[0], qr/No verifier for scope/, 'proper error');
