use Test::More tests => 2;
use lib qw(./t/lib);
use TestMasonApp::InterpPostExec;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpPostExec->new->run;
like($output, qr/<title>InterpPostExec<\/title>/, "mason post exec title");
like($output, qr/param : post_exec change/, "mason post exec parameter");

