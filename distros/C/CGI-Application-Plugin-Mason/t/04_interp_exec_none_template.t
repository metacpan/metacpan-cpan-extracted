use Test::More tests => 2;
use lib qw(./t/lib);
use TestMasonApp::InterpExecNoneTemplate;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecNoneTemplate->new->run;
like($output, qr/<title>InterpExecNoneTemplate<\/title>/, "mason none template title");
like($output, qr/param : success/, "mason none template parameter");

