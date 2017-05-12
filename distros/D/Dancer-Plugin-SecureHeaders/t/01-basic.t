use strict;
use warnings;

use Test::More import => ['!pass'];
use t::lib::TestApp;
use Dancer ':syntax';

my $dancer_version;
BEGIN {
    $dancer_version = (exists &dancer_version) ? int(dancer_version()) : 1;
    require Dancer::Test;
    if ($dancer_version == 1) {
        Dancer::Test->import();
    } else {
        Dancer::Test->import('t::lib::TestApp');
    }
}

diag sprintf "Testing SecureHeaders version %s under Dancer %s",
    $Dancer::Plugin::SecureHeaders::VERSION,
    $Dancer::VERSION;

response_status_is [GET => '/'], 200, "Answers index route ok";
response_headers_include [GET => '/'], ['X-Content-Security-Policy' => "default-src 'self'", 'X-Content-Type-Options' => "nosniff", 'X-Download-Options' => "noopen", 'X-XSS-Protection' => "1; 'mode=block'"], "All default headers were added normally";
response_headers_include [GET => '/'], ['X-Frame-Options' => "ALLOW"], "Configuration override works";

response_status_is [GET => '/manual'], 200, "Answers manual override route ok.";
response_headers_include [GET => '/manual'], ['X-XSS-Protection' => '1'];

done_testing();

