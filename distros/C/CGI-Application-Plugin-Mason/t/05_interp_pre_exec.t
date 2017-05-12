use Test::More tests => 3;
use lib qw(./t/lib);
use TestMasonApp::InterpPreExec;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpPreExec->new->run;
like($output, qr/<title>InterpPreExec<\/title>/, "mason pre exec title");
like($output, qr/pre_exec_param : pre_exec success/, "mason pre exec parameter1");
like($output, qr/param : success/, "mason pre exec parameter2");

