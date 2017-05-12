use Test::More tests => 2;
use lib qw(./t/lib);
use TestMasonApp::InterpExecSetGlobal;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecSetGlobal->new->run;
like($output, qr/<title>InterpExecSetGlobal<\/title>/, "mason set global title");
like($output, qr/mode : index/, "mason params \$c->get_current_runmode");

