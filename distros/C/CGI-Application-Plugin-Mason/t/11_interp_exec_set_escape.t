use Test::More tests => 6;
use lib qw(./t/lib);
use TestMasonApp::InterpExecSetEscape;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = TestMasonApp::InterpExecSetEscape->new->run;
like($output, qr/<title>InterpExecSetEscape<\/title>/, "mason set escape title");
like($output, qr/&amp;/,  "mason escape & => &amp;");
like($output, qr/&lt;/,   "mason escape < => &lt;");
like($output, qr/&gt;/,   "mason escape > => &gt;");
like($output, qr/&quot;/, "mason escape \" => &quot;");
like($output, qr/&#039;/, "mason escape ' => &#039;");

