use Test::More tests => 17;
use File::Spec;
BEGIN { use_ok('CGI::Application::Plugin::Session') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppSessionCookie;
my $t1_obj = TestAppSessionCookie->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

# check domain
like($t1_output, qr/domain=mydomain.com;/, 'domain found in cookie');

# check path
like($t1_output, qr/path=\/testpath/, 'path found in cookie');

# check expires (should not exist)
unlike($t1_output, qr/expires=/, 'expires not found in cookie');

# Session object will not disappear and be written
# to disk until it is DESTROYed
undef $t1_obj;

unlink File::Spec->catdir('t', 'cgisess_'.$id1);


my $query = new CGI({ rm => 'existing_session_cookie' });
$t1_obj = TestAppSessionCookie->new( QUERY => $query );
$t1_output = $t1_obj->run();

unlike($t1_output, qr/Set-Cookie: CGISESSID=test/, 'existing session cookie was deleted');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie set');

($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

undef $t1_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);


$query = new CGI({ rm => 'existing_session_cookie_plus_extra_cookie' });
$t1_obj = TestAppSessionCookie->new( QUERY => $query );
$t1_output = $t1_obj->run();

unlike($t1_output, qr/Set-Cookie: CGISESSID=test/, 'existing session cookie was deleted');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie set');
like($t1_output, qr/Set-Cookie: TESTCOOKIE=testvalue/, 'existing cookie was not deleted');

($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

undef $t1_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);


$query = new CGI({ rm => 'existing_extra_cookie' });
$t1_obj = TestAppSessionCookie->new( QUERY => $query );
$t1_output = $t1_obj->run();

like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'new session cookie set');
like($t1_output, qr/Set-Cookie: TESTCOOKIE=testvalue/, 'existing cookie was not deleted');

($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

undef $t1_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);

