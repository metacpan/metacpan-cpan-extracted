use Test::More tests => 1;
use lib qw(./t/lib);
use CSRFApp::PublishCSRFTicket;

open FILE, "<", "/tmp/cap-protect-csrf-test" or die $!;
my $data = <FILE>;
close FILE;
my($csrf_id, $cookie) = split /\t/, $data;
$ENV{HTTP_COOKIE} = $cookie;
$ENV{REQUEST_METHOD} = "GET";
$ENV{QUERY_STRING} = "rm=finish&_csrf_id=$csrf_id";
$ENV{CGI_APP_RETURN_ONLY} = 1;

my $output = CSRFApp::PublishCSRFTicket->new->run;
like($output, qr/finish!/, "protect csrf");

