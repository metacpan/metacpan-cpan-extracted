use Test::More tests => 4;
use File::Spec;
BEGIN { use_ok('CGI::Application::Plugin::Session') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppNoCookie;
my $t1_obj = TestAppNoCookie->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');
unlike($t1_output, qr/Set-Cookie: CGISESSID=[a-zA-Z0-9]+/, 'session cookie not set');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

# Session object will not dissapear and be written
# to disk until it is DESTROYed
undef $t1_obj;

unlink File::Spec->catdir('t', 'cgisess_'.$id1);

