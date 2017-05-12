use Test::More tests => 4;
use lib qw(./t/lib);
use TestMasonApp::InterpExecParamsHash;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecParamsHash->new->run;
like($output, qr/<title>InterpExecParamsHash<\/title>/, "mason params hash title");
like($output, qr/fruit : apple/, "mason params hash fruit");
like($output, qr/music : rock/, "mason params hash music");
like($output, qr/sport : baseball/, "mason params hash sport");

