use Test::More tests => 2;
use lib qw(./t/lib);
use TestMasonApp::InterpExecFromFH;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecFromFH->new->run;
like($output, qr/<title>InterpExecFromFH<\/title>/, "mason filehandle parameter");
like($output, qr/param : success/, "mason filehandle parameter");

