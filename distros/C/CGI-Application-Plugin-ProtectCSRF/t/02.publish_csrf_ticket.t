use Test::More tests => 1;
use lib qw(./t/lib);
use CSRFApp::PublishCSRFTicket;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $app = CSRFApp::PublishCSRFTicket->new;
my $output = $app->run;
like($output, qr/<input type="hidden" name="_csrf_id" value="([a-z0-9]{40})" \/>/, "publish csrf ticket id");

my($cookie) = $output =~ /Set\-Cookie:\s+(CGISESSID=[a-z0-9]+;\s+path=\/)/;
open FILE, ">", "/tmp/cap-protect-csrf-test" or die $!;
print FILE join "\t", $app->csrf_id, $cookie;
close FILE;

