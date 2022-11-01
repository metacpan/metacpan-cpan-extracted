use strict;
use warnings;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";
use LWP::Online ':skip_all'; # This causes the tests to be skipped
                             # without connectivity
use Test::More;

use App::ipchgmon;

# Very simple test for the IP addresses of example.com.
# Huge assumption that these addresses will not change.
# Better ideas gratefully accepted!

my ($ip4, $ip6) = App::ipchgmon::nslookup('example.com');
is $ip6, '2606:2800:220:1:248:1893:25c8:1946', 
    "Correct IPv6 address for example.com ($ip6)";
is $ip4, '93.184.216.34',
    "Correct IPv4 address for example.com ($ip4)";

done_testing;
