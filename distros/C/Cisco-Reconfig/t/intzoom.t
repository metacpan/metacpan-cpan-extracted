#!/usr/bin/perl -I. -w

use Cisco::Reconfig;
use Test;
use Carp qw(verbose);
use Scalar::Util qw(weaken);

my $debugdump = 0;

if ($debugdump) {
	$Cisco::Reconfig::nonext = 1;
}

BEGIN { plan test => 2 };

sub wok
{
	my ($a, $b) = @_;
	require File::Slurp;
	import File::Slurp;
	write_file('x', $a);
	write_file('y', $b);
	return ok($a,$b);
}

my $config = readconfig(\*DATA);

if ($debugdump) {
	require File::Slurp;
	require Data::Dumper;
	import File::Slurp;
	import Data::Dumper;
	$Data::Dumper::Sortkeys = 1;
	$Data::Dumper::Sortkeys = 1;
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Indent = 1;
	$Data::Dumper::Indent = 1;
	write_file("dumped", Dumper($config));
	exit(0);
}

ok(defined $config);

my $y = '';
for my $item ($config->get('interface')->all) {
        my $ipaddr = $item->zoom->get('ip address');
	$y .= $ipaddr;
}
ok($y, <<END);
 ip address 218.185.30.57 255.255.255.252
 ip address 172.17.64.90 255.255.255.252
END


# -----------------------------------------------------------------



# -----------------------------------------------------------------
# -----------------------------------------------------------------


__DATA__
interface FastEthernet0/0.32
 description VLAN 32 to cit190-cs1
 bandwidth 100000
 encapsulation dot1Q 32
 ip address 218.185.30.57 255.255.255.252
 rate-limit input 100000000 18750000 37500000 conform-action transmit exceed-action transmit
 rate-limit output 100000000 18750000 37500000 conform-action transmit exceed-action transmit
 ip ospf cost 50
 no cdp enable
!

interface ATM2/0.10189 point-to-point
 description VC to agg1.que31 for Interim management
 bandwidth 1000
 ip address 172.17.64.90 255.255.255.252
 no ip redirects
 no ip proxy-arp
 pvc 10/189
  protocol ip 172.17.64.89
  ubr 1000
  encapsulation aal5snap
 !

