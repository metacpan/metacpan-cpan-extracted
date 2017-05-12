use Test::More tests => 2;
use lib qw(./t/lib);
use TestMasonApp::InterpExecFromFile;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecFromFile->new->run;
like($output, qr/<title>InterpExecFromFile<\/title>/, "mason file title");
like($output, qr/param : success/, "mason file parameter");

