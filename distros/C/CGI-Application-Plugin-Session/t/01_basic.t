use Test::More tests => 15;
use File::Spec;
BEGIN { use_ok('CGI::Application::Plugin::Session') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppBasic;
my $t1_obj = TestAppBasic->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

my $session_config = $t1_obj->session_config;
is (ref($session_config), 'HASH', 'Retrieved Session Config');

eval { my $session_config = $t1_obj->session_config(SEND_COOKIE => 1) };
like($@, qr/Calling session_config after the session has already been created/, 'session_config called after session created');

# Session object will not dissapear and be written
# to disk until it is DESTROYed
undef $t1_obj;


# Set the Session ID in a parameter
my $t2_obj = TestAppBasic->new(QUERY=>CGI->new({ CGI::Session->name => $id1 }));
my $t2_output = $t2_obj->run();

like($t2_output, qr/session found/, 'session found');

like($t2_output, qr/value=test1/, 'session parameter retrieved');

like($t2_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

undef $t2_obj;



# Set a cookie in $ENV{HTTP_COOKIE}
$ENV{HTTP_COOKIE} = CGI::Session->name.'='.$id1;

my $t3_obj = TestAppBasic->new();
my $t3_output = $t3_obj->run();

like($t3_output, qr/session found/, 'session found');

like($t3_output, qr/value=test1/, 'session parameter retrieved');

unlike($t3_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie not set');

undef $t3_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);



# test with an expired cookie
$ENV{HTTP_COOKIE} = CGI::Session->name.'=badsessionid';

my $t4_obj = TestAppBasic->new(QUERY=>CGI->new());
my $t4_output = $t4_obj->run();

like($t4_output, qr/session created/, 'session created');

unlike($t4_output, qr/value=test1/, 'session parameter not found');

like($t4_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id4) = $t4_output =~ /id=([a-zA-Z0-9]+)/s;
undef $t4_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id4);
