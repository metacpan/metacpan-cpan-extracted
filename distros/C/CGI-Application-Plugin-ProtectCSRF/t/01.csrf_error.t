use Test::More tests => 1;
use lib qw(./t/lib);
use CSRFApp::PublishCSRFTicket;

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = "GET";
$ENV{QUERY_STRING} = "rm=finish";

my $output = CSRFApp::PublishCSRFTicket->new->run;
like($output, qr/<h1>your access is csrf!<\/h1>/, "csrf error message");

