use Test::More tests => 1;
use lib qw(./t/lib);
use TestMasonApp::InterpExecError;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecError->new->run;
like($output, qr/ERROR: could not find component for initial path '\/none.mason'/, "mason error");

