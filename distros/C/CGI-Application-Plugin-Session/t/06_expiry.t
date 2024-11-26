use Test::More tests => 16;
use File::Spec;
BEGIN { use_ok('CGI::Application::Plugin::Session') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppExpiry;

$ENV{DEFAULT_EXPIRY} = '+1h';
my $t1_obj = TestAppExpiry->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();


# Set-Cookie: CGISESSID=d7fc7bab0f9e1301fd21717c556337fe; path=/; expires=Sat, 11-Jun-2005 17:47:28 GMT
like($t1_output, qr/\(3600\)/, 'expiry set correctly');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');
like($t1_output, qr/expires=\w{3}, /, 'session cookie expiry set');
my ($year) = $t1_output =~ /\d+[ \-]\w{3}[ \-](\d+) /s;

my ($id1) = $t1_output =~ /CGISESSID=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

undef $t1_obj;

# Set a cookie in $ENV{HTTP_COOKIE}
$ENV{HTTP_COOKIE} = CGI::Session->name.'='.$id1;

# Change the default expiry
$ENV{DEFAULT_EXPIRY} = '+1y';
$t1_obj = TestAppExpiry->new(QUERY=>CGI->new());
$t1_output = $t1_obj->run();


like($t1_output, qr/\(3600\)/, 'expiry set correctly');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');
like($t1_output, qr/expires=\w{3}, /, 'session cookie expiry set');
my ($year2) = $t1_output =~ /\d+[ \-]\w{3}[ \-](\d+) /s;

# This test will fail during the last hour of the year, but I can't be bother to
# test for that :)
is($year2, $year, 'Expiry should not change');

my ($id2) = $t1_output =~ /CGISESSID=([a-zA-Z0-9]+)/s;
ok($id2, 'found session id');
is($id2, $id1, "Session was reused");

undef $t1_obj;

unlink File::Spec->catdir('t', 'cgisess_'.$id1);


delete $ENV{HTTP_COOKIE};
# Change the default expiry
$ENV{DEFAULT_EXPIRY} = '-1y';
$t1_obj = TestAppExpiry->new();
$t1_output = $t1_obj->run();

like($t1_output, qr/\(\-31536000\)/, 'expiry set correctly');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');
like($t1_output, qr/expires=\w{3}, /, 'session cookie expiry set');
($year2) = $t1_output =~ /\d+[ \-]\w{3}[ \-](\d+) /s;

# This test will fail during the last hour of the year, but I can't be bother to
# test for that :)
is($year2, $year-1, 'Expiry should not change');

($id2) = $t1_output =~ /CGISESSID=([a-zA-Z0-9]+)/s;
ok($id2, 'found session id');

undef $t1_obj;

unlink File::Spec->catdir('t', 'cgisess_'.$id2);

