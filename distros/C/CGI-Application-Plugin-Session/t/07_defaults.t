use Test::More tests => 3;
use File::Spec;
BEGIN { use_ok('CGI::Application::Plugin::Session') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppDefaults;
my $t1_obj = TestAppDefaults->new(QUERY=>CGI->new());
my $t1_output = $t1_obj->run();

like($t1_output, qr/session created/, 'session created');

my ($id1) = $t1_output =~ /id=([a-zA-Z0-9]+)/s;
ok($id1, 'found session id');

# Session object will not dissapear and be written
# to disk until it is DESTROYed
undef $t1_obj;

unlink File::Spec->catdir(File::Spec->tmpdir, 'cgisess_'.$id1);

