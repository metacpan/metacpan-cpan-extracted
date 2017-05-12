use Test::More tests => 4;
use lib qw(./t/lib);
use TestMasonApp::InterpExecParamsArray;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecParamsArray->new->run;
like($output, qr/<title>InterpExecParamsArray<\/title>/, "mason params array title");
like($output, qr/apple/, "mason params array apple");
like($output, qr/banana/, "mason params array banana");
like($output, qr/melon/, "mason params array melon");

