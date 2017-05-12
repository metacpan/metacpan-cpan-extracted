use Test::More tests => 7;
use File::Spec;
BEGIN { use_ok('CGI::Application::Plugin::Session') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppCookie;
my $t1_obj = TestAppCookie->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');
like($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie set');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

# check domain
like($t1_output, qr/domain=mydomain.com;/, 'domain found in cookie');

# check path
like($t1_output, qr/path=\/testpath;/, 'path found in cookie');

# check domain
like($t1_output, qr/expires=/, 'expires found in cookie');

# Session object will not disappear and be written
# to disk until it is DESTROYed
undef $t1_obj;

unlink File::Spec->catdir('t', 'cgisess_'.$id1);

