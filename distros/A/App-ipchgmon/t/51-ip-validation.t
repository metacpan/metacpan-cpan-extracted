use strict;
use warnings;
use Test::More;
use FindBin qw( $RealBin );
use Text::CSV qw(csv);
use lib "$RealBin/../lib";

use App::ipchgmon;

# This exercises the valid4 and valid6 routines. The IP address ranges
# are taken from the Data::Validate::IP module. It is necessary to test
# a valid IP at the end because D:V:I will say an address is valid even
# if it is in an impossible block, provided the format is correct.

my $csv4 = <<EOCSV4;
ip,          message,                      diag
0.1.1.1,     is invalid IPv4 - unroutable, has been validated but is unroutable
192.168.1.1, is invalid IPv4 - private,    has been validated but is private
127.0.0.1,   is invalid IPv4 - loopback,   has been validated but is loopback
169.254.0.1, is invalid IPv4 - link local, has been validated but is link local
192.0.2.1,   is invalid IPv4 - test net,   has been validated but is test net
192.88.99.1, is invalid IPv4 - anycast,    has been validated but is anycast
224.0.2.1,   is invalid IPv4 - multicast,  has been validated but is multicast
EOCSV4

my $test4 = csv (in => \$csv4, headers => 'auto', allow_whitespace => 1);

subtest 'IPv4 validation works' => sub {
    for my $hr_test (@$test4) {
        ok (!App::ipchgmon::valid4($$hr_test{ip}),
            $$hr_test{ip} . ' ' . $$hr_test{message})
            or diag  $$hr_test{ip} . ' ' . $$hr_test{diag};
    }

    my $ip = '121.122.123.124';
    ok (App::ipchgmon::valid4($ip), "$ip valid IPv4")
        or diag("$ip has been rejected but is valid");
};

my $csv6 = <<EOCSV6;
ip,          message,                         diag
FC00::1,     is invalid IPv6 - private,       has been validated but is private
::1,         is invalid IPv6 - loopback,      has been validated but is loopback
FE80::1,     is invalid IPv6 - link local,    has been validated but is link local
FF00::1,     is invalid IPv6 - multicast,     has been validated but is multicast
::FFFF:0:1,  is invalid IPv6 - IPv4 mapped,   has been validated but is IPv4 mapped
100::1,      is invalid IPv6 - discard,       has been validated but is discard
2001::1,     is invalid IPv6 - special,       has been validated but is special
2001:DB8::1, is invalid IPv6 - documentation, has been validated but is documentation
EOCSV6

my $test6 = csv (in => \$csv6, headers => 'auto', allow_whitespace => 1);

subtest 'IPv6 validation works' => sub {
    for my $hr_test (@$test6) {
        ok (!App::ipchgmon::valid6($$hr_test{ip}), 
            $$hr_test{ip} . ' ' . $$hr_test{message})
            or diag  $$hr_test{ip} . ' ' . $$hr_test{diag};
    }

    my $ip = 'A::1';
    ok (App::ipchgmon::valid6($ip), "$ip valid IPv6")
        or diag("$ip has been rejected but is valid");
};

done_testing;
