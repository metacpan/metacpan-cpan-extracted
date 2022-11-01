use strict;
use warnings;
use Test::More;
use FindBin qw( $RealBin );
use lib "$RealBin/../lib";

use App::ipchgmon;

# Exercises the "last_ip" subroutine. This takes an ip address of either
# type and and aoaref. The sub returns two booleans, the first indicating
# whether the ip address is the last of its type in the aoaref and the
# second whether the time since the entry was made in the aoaref is more
# than the leeway.

my $aoaref = [
    ["11.11.11.11",     "2022-08-28T00:00:00Z"],
    ["101.101.101.101", "2022-08-28T01:01:01Z"],
    ["B::0",            "2022-08-28T00:00:00Z"],
    ["B::1",            "2022-08-28T01:01:01Z"],
];

$App::ipchgmon::opt_leeway = 86400;

# IPv4, not last (but in the aoaref) so overdue should not be set.
my $ip = "11.11.11.11";
my ($rtn, $overdue) = App::ipchgmon::last_ip($ip, $aoaref);
ok !$rtn, "$ip is not last" 
    or diag "$ip reported as as last but it is the first";
ok !$overdue, "$ip is not overdue" 
    or diag "$ip reported as overdue but it has been superseded";

# IPv4, last and changed long ago, so overdue
$ip = "101.101.101.101";
($rtn, $overdue) = App::ipchgmon::last_ip($ip, $aoaref);
ok $rtn, "$ip is last" 
    or diag "$ip not given as last but it should be";
ok $overdue, "$ip is overdue"
    or diag "$ip not reported as overdue but is";
    
# IPv6, not last (but in the aoaref) so overdue should not be set.
$ip = "B::0";
($rtn, $overdue) = App::ipchgmon::last_ip($ip, $aoaref);
ok !$rtn, "$ip is not last" 
    or diag "$ip reported as  last but it is the first";
ok !$overdue, "$ip is not overdue" 
    or diag "$ip reported as overdue but it has been superseded";
    
# IPv6, last and changed long ago, so overdue
$ip = "B::1";
($rtn, $overdue) = App::ipchgmon::last_ip($ip, $aoaref);
ok $rtn, "$ip is last" 
    or diag "$ip not reported as last but it should be";
ok $overdue, "$ip is overdue"
    or diag "$ip not reported as overdue but is";
    
done_testing;
