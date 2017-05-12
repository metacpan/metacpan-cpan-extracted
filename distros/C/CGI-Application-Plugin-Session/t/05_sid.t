use Test::More tests => 10;
use File::Spec;
BEGIN { use_ok('CGI::Application::Plugin::Session') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppSid;
my $t1_obj = TestAppSid->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

# Session object will not dissapear and be written
# to disk until it is DESTROYed
undef $t1_obj;

# Set a cookie in $ENV{HTTP_COOKIE}
$ENV{HTTP_COOKIE} = CGI::Session->name.'='.$id1;

my $t2_obj = TestAppSid->new(QUERY=>CGI->new());
my $t2_output = $t2_obj->run();

like($t2_output, qr/session found/, 'session found');

like($t2_output, qr/value=test1/, 'session parameter retrieved');

unlike($t2_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie not set');

undef $t2_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id1);

# test with an expired cookie
$ENV{HTTP_COOKIE} = CGI::Session->name.'=badsessionid';

my $t3_obj = TestAppSid->new(QUERY=>CGI->new());
my $t3_output = $t3_obj->run();

like($t3_output, qr/session created/, 'session created');

unlike($t3_output, qr/value=test1/, 'session parameter not found');

like($t3_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id3) = $t3_output =~ /id=([a-zA-Z0-9]+)/s;
undef $t3_obj;
unlink File::Spec->catdir('t', 'cgisess_'.$id3);
