use strict;
use warnings;
use LWP::Online ':skip_all'; # This causes the tests to be skipped
                             # without connectivity
use Test::More;
use Data::Validate::IP;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use App::ipchgmon;

# This does a very simple exercise of the get_ip routines. They should get the
# current public IP addresses. These cannot be known, whether in testing or
# production, so the test merely ensures the format is correct.

my $ip6 = App::ipchgmon::get_ip6();
if (defined $ip6) {
    ok is_ipv6($ip6), "Address $ip6 returned in IPv6 format"
        or diag("\"$ip6\" is not in IPv6 format");
} else {
    warn "No IPv6 address. You may need to run with the --4 option."
}

my $ip4 = App::ipchgmon::get_ip4();
ok is_ipv4($ip4), "Address $ip4 returned in IPv4 format"
    or diag("\"$ip4\" is not in IPv4 format");

done_testing;
