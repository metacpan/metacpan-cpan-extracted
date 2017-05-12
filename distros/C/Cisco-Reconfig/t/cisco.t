#!/usr/bin/perl -I. -w

use Cisco::Reconfig;
use Test;
use Carp qw(verbose);
use Scalar::Util qw(weaken);

use strict;

my $debugdump = 0;

#if ($debugdump) {
#	$Cisco::Reconfig::nonext = 1;
#}

BEGIN { plan test => 45 };

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
	no warnings;
	require FindBin;
	require Data::Dumper;
	require File::Slurp;
	require "$FindBin::Bin/lib/Local/NoWeak.pm";
	File::Slurp::write_file("dumped", join("\n",Data::Dumper::Dump(Local::NoWeak::strong_clone($config))));
	exit(0);
}

ok(defined $config);


# -----------------------------------------------------------------
{

my $x = $config->get('line')->alltext;
my $expected = <<'END';
line con 0
 exec-timeout 0 0
line aux 0
line vty 0 4
 exec-timeout 9000 0
 password upGrade3
 logout-warning 120
 login
 escape-character 3
END
ok($x,$expected, "get line -> alltext");


}
# -----------------------------------------------------------------
{

my $x = $config->get('interface ATM3/0.171')->alltext;
my $expected = <<'END';
interface ATM3/0.171 point-to-point
 description Proodit Layer 2
 pvc 20/133
  ubr 1544
  oam-pvc 1
  oam retry 1 600 1
  oam ais-rdi 60 3
  encapsulation aal5mux fr-atm-srv
END
ok($x,$expected, "get interface ATM3/0.171 -> alltext");


}
# -----------------------------------------------------------------
{

my $x = $config->set('route-map OSPFTag', <<END);
	route-map OSPFTag permit 30
	 match ip address 109
	 set metric 24
	 set metric-type type-2
	 set tag 0
	 set level backbone
	!
END
ok($x,'');


}
# -----------------------------------------------------------------
{

my $x = $config->set('route-map source-route-to-fred', <<END);
	route-map source-route-to-fred
	 set ip next-hop 1.2.3.4
	!
END
ok($x,<<END);
route-map source-route-to-fred
 set ip next-hop 1.2.3.4
exit
END

}
# -----------------------------------------------------------------

# -----------------------------------------------------------------
{

my $x = $config->get('router bgp', 'neighbor 207.181.192.13')->set(<<END);
	neighbor 207.181.192.13 remote-as 10368
	neighbor 207.181.192.13 ebgp-multihop 3
	neighbor 207.181.192.13 update-source Loopback0
	neighbor 207.181.192.13 version 4
	neighbor 207.181.192.13 route-map AS99368-IN in
	neighbor 207.181.192.13 route-map AS99368-OUT out
	neighbor 207.181.192.13 filter-list 111 in
END
ok($x,<<END);
router bgp 10993
 no neighbor 207.181.192.13 send-community
exit
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('router bgp', 'neighbor 207.181.192.13')->set(<<END);
	neighbor 207.181.192.13 remote-as 10368
	neighbor 207.181.192.13 ebgp-multihop 3
	neighbor 207.181.192.13 update-source Loopback0
	neighbor 207.181.192.13 send-community
	neighbor 207.181.192.13 version 4
	neighbor 207.181.192.13 route-map AS99368-IN in
	neighbor 207.181.192.13 route-map AS99368-OUT out
	neighbor 207.181.192.13 filter-list 111 in
END
ok($x,'');

}
# -----------------------------------------------------------------
{

my $x = $config->get('router rip')->set(<<END);
	passive-interface default
	no passive-interface Tunnel0
	default-metric 2
END
ok($x,'');

}
# -----------------------------------------------------------------
{

my $x = $config->get('router bgp', 'neighbor 207.181.192.13')->set(<<END);
	neighbor 207.181.192.13 remote-as 10368
	neighbor 207.181.192.13 ebgp-multihop 3
	neighbor 207.181.192.13 update-source Loopback0
	neighbor 207.181.192.13 send-community
	neighbor 207.181.192.13 version 5
	neighbor 207.181.192.13 route-map AS99368-IN in
	neighbor 207.181.192.13 route-map AS99368-OUT out
	neighbor 207.181.192.13 filter-list 111 in
END
ok($x,<<END);
router bgp 10993
 no neighbor 207.181.192.13 version 4
 neighbor 207.181.192.13 version 5
exit
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('router rip')->set(<<END);
	passive-interface default
	no passive-interface Tunnel0
	default-metric 3
END
ok($x,<<END);
router rip
 passive-interface default
 no passive-interface Tunnel0
 default-metric 3
exit
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface ATM3/0.40', 'pvc 1894635-dasterd', 'class-vc')->set(<<END);
class-vc dsl195
END
ok($x,<<END);
interface ATM3/0.40 multipoint
 pvc 1894635-dasterd 1/3042
  no class-vc dsl192
  class-vc dsl195
 exit
exit
END

}
# -----------------------------------------------------------------
{

my $x = $config->set('router rip', <<END);
	router rip
	 passive-interface default
	 no passive-interface Tunnel0
	 default-metric 3
	!
END
ok($x,<<END);
no router rip
router rip
 passive-interface default
 no passive-interface Tunnel0
 default-metric 3
exit
END

}
# -----------------------------------------------------------------
{

my $x = $config->set('router rip', <<END);
	router rip
	 passive-interface default
	 no passive-interface Tunnel0
	 default-metric 2
	!
END
ok($x,'');


}
# -----------------------------------------------------------------
{

my $x = $config->get('interface ATM3/0.40')->set('pvc 1894635-dasterd', 'class-vc',<<END);
class-vc dsl196
END
ok($x,<<END);
interface ATM3/0.40 multipoint
 pvc 1894635-dasterd
  no class-vc
  class-vc dsl196
 exit
exit
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface ATM3/0.40', 'pvc 1894635-dasterd')->set('class-vc',<<END);
class-vc dsl197
END
ok($x,<<END);
interface ATM3/0.40 multipoint
 pvc 1894635-dasterd 1/3042
  no class-vc
  class-vc dsl197
 exit
exit
END


}
# -----------------------------------------------------------------
{

my $x = $config->get('interface ATM3/0.40', 'pvc 1894635-dasterd')->set('class-vc',<<END);
class-vc dsl198
END
ok($x,<<END);
interface ATM3/0.40 multipoint
 pvc 1894635-dasterd 1/3042
  no class-vc
  class-vc dsl198
 exit
exit
END

}
# -----------------------------------------------------------------
{

my $x = $config->set('interface ATM3/0.40', 'pvc 1894635-dasterd', 'class-vc',<<END);
class-vc dsl199
END
ok($x,<<END);
interface ATM3/0.40
 pvc 1894635-dasterd
  no class-vc
  class-vc dsl199
 exit
exit
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface ATM3/0.40', 'pvc 1894635-dasterd', 'class-vc')->text;
ok($x,<<END);
  class-vc dsl192
END


}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Serial0', 'ip address')->context->text;
ok($x,<<END);
 description Cross-connect to Foobar
 ip address 207.181.198.194 255.255.255.252
 ip access-group 151 in
 bandwidth 154400
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Serial0', 'ip address')->context->context->text;
ok($x,<<END);
interface Serial0
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Serial0', 'ip address')->single->next->text;
ok($x,<<END);
 ip access-group 151 in
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Serial0', 'ip')->zoom->text;
ok($x,<<END);
 ip address 207.181.198.194 255.255.255.252
 ip access-group 151 in
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Serial0', 'ip')->zoom;
ok(defined $x);

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Serial0', 'ip address')->single->text;
ok($x,<<END);
 ip address 207.181.198.194 255.255.255.252
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Serial0', 'ip')->single;
ok(! defined $x);

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Serial0', 'ip')->text;
ok($x,<<END);
 ip address 207.181.198.194 255.255.255.252
 ip access-group 151 in
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Loopback5', 'ip address')->text;
ok($x, <<END);
 ip address 212.212.60.142 255.255.255.255
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Ethernet0', 'ip address')->text;
ok($x, <<END);
 ip address 128.32.32.3 255.255.255.192
END

}
# -----------------------------------------------------------------
{


my $x = '';
for my $i ($config->get('interface')->all) {
	next unless $i->get('description')->text =~ /Foobar/;
	$x .= $i->text;
}
ok($x,<<END);
interface Loopback2
interface Loopback3
interface Tunnel1
interface Serial0
END

}
# -----------------------------------------------------------------
{


my $x = '';
for my $i ($config->get('interface')->all) {
	next unless $i->get('description') =~ /Foobar/;
	$x .= $i->text;
}
ok($x,<<END);
interface Loopback2
interface Loopback3
interface Tunnel1
interface Serial0
END


}
# -----------------------------------------------------------------
{

my $x = '';
for my $i ($config->get('interface')->all) {
	next unless $i->get('description')->text =~ /Foobar/;
	$x .= $i->get('ip address')->text;
}
ok($x,<<END);
 ip address 216.15.30.30 255.255.255.255
 ip address 216.15.30.29 255.255.255.255
 ip address 128.32.32.234 255.255.255.252
 ip address 207.181.198.194 255.255.255.252
END

}
# -----------------------------------------------------------------
{

my $x = '';
for my $i ($config->get('interface')->all) {
	next unless $i->get('description')->text =~ /Foobar/;
	$x .= $i->get('ip address')->text;
}
ok($x,<<END);
 ip address 216.15.30.30 255.255.255.255
 ip address 216.15.30.29 255.255.255.255
 ip address 128.32.32.234 255.255.255.252
 ip address 207.181.198.194 255.255.255.252
END

}
# -----------------------------------------------------------------
{


my $x = '';
my $ser0 = $config->get('interface Serial0');
$x .= $ser0->set('ip address', <<END);
	ip address 207.181.198.194  255.255.255.252
END
ok($x,<<END);
END

}
# -----------------------------------------------------------------
{


my $x = '';
my $ser0 = $config->get('interface Serial0');
$x .= $ser0->set('ip address', <<END);
	ip address 207.181.178.195  255.255.255.252
END
ok($x,<<END);
interface Serial0
 no ip address
 ip address 207.181.178.195 255.255.255.252
exit
END

}
# -----------------------------------------------------------------
{


my $x = '';
my (@i) = $config->get('interface')->all;
ok($#i,13);


}
# -----------------------------------------------------------------
{

my $x = '';
my (@i) = $config->get('interface');
ok($#i,13);

}
# -----------------------------------------------------------------
{

my $x = '';
for my $i ($config->get('interface')->all(qr{^Loopback})) {
	$x .= $i;
}
ok($x,<<END);
interface Loopback0
interface Loopback2
interface Loopback3
interface Loopback4
interface Loopback5
END

}
# -----------------------------------------------------------------
{

my $x = '';
for my $i ($config->get('interface')->all(qr{^Loopback})) {
	$x .= $i->text;
}
ok($x,<<END);
interface Loopback0
interface Loopback2
interface Loopback3
interface Loopback4
interface Loopback5
END

}
# -----------------------------------------------------------------
{


my $v = $config->get('version');
my $x = $v->text;
ok($x, <<END);
version 11.1
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('interface Ethernet0', 'ip address')->text;
ok($x, <<END);
 ip address 128.32.32.3 255.255.255.192
END


}
# -----------------------------------------------------------------
{

my $x = '';
my (@i) = $config->get('interface');
ok($#i,13);

}
# -----------------------------------------------------------------
{

my $x = '';
for my $ip ($config->get('interface', 'ip address')) {
	$x .= $ip->text;
}
ok($x,<<END);
 ip address 128.32.32.245 255.255.255.255
 ip address 216.15.30.30 255.255.255.255
 ip address 216.15.30.29 255.255.255.255
 ip address 128.32.32.176 255.255.255.255
 ip address 212.212.60.142 255.255.255.255
 ip address 128.32.32.230 255.255.255.252
 ip address 128.32.32.234 255.255.255.252
 ip address 128.32.32.162 255.255.255.252
 ip address 128.32.32.165 255.255.255.252
 ip address 128.32.32.3 255.255.255.192
 ip address 207.181.198.194 255.255.255.252
 no ip address
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('ip access-list extended filter')->subs()->text();
ok($x,<<END);
 remark 
 remark ESTABLISHED CONNECTIONS LIVE
 deny ip any host 10.0.0.1
 permit tcp any any established
 remark 
 remark now we'll do something nasty
 remark now we'll do something nasty too
 remark the above lines are only legal in comments
END

}
# -----------------------------------------------------------------
{

my $c = 0;
for my $context ($config->get('interface')->all(qr{^ether}i)) {
	#print $context;
	my $x = $context->get('cdp enable');
	#print $x if $x;
	$c++ if $x =~ /no cdp enable/;
	#print "c=$c\n";
}
ok($c,1);

}
# -----------------------------------------------------------------
# -----------------------------------------------------------------


# -----------------------------------------------------------------
# -----------------------------------------------------------------
{

# last test

	my $dc = 0;
	sub Cisco::Reconfig::DESTROY 
	{
		$dc++;
	}
	#$config->destroy();
	undef $config;
	#print STDERR "DC=$dc\n";
	ok($dc > 700);

}
# -----------------------------------------------------------------
# -----------------------------------------------------------------


__DATA__
!
! Last configuration change at 20:38:42 PDT Mon Jun 26 2000C
! NVRAM config last updated at 20:38:49 PDT Mon Jun 26 2000C
!
version 11.1
service timestamps debug datetime localtime
service timestamps log datetime localtime
service compress-config
service udp-small-servers
service tcp-small-servers
!
hostname humble
!
clock timezone PST -8
clock summer-time PDT recurring
enable secret 5 $1$lgl2$aKQsBG6UOuPYuRRoyOhqT.
enable password naoan1jx
!
username admin password 7 069E0B05E24575A6151317
ip subnet-zero
ip multicast-routing
ip rcmd remote-host crisco 128.32.32.1 cripes
!
interface Loopback0
 description ROUTER ID
 ip address 128.32.32.245 255.255.255.255
!
interface Loopback2
 description ENDPOINT: in Foobar space
 ip address 216.15.30.30 255.255.255.255
!
interface Loopback3
 description ENDPOINT: in Foobar space
 ip address 216.15.30.29 255.255.255.255
!
interface Loopback4
 description ENDPOINT: via Tsoft DSL
 ip address 128.32.32.176 255.255.255.255
!
interface Loopback5
 description ENDPOINT: in the Tweedle block
 ip address 212.212.60.142 255.255.255.255
!
interface Tunnel0
 description TUNNEL to haughty via Gratuity
 ip address 128.32.32.230 255.255.255.252
 no ip redirects
 ip ospf authentication-key badnight
 ip ospf cost 70
 tunnel source Loopback3
 tunnel destination 175.12.121.16
 tunnel mode gre multipoint
 tunnel key 838832
!
interface Tunnel1
 description TUNNEL to haughty via Foobar
 ip address 128.32.32.234 255.255.255.252
 no ip redirects
 ip ospf authentication-key onenight
 ip ospf cost 65
 tunnel source Loopback2
 tunnel destination 175.12.117.13
 tunnel mode gre multipoint
 tunnel key 838839
!
interface Tunnel2
 description TUNNEL to haughty via TSOFT DSL
 ip address 128.32.32.162 255.255.255.252
 no ip redirects
 ip ospf authentication-key nextmorn
 ip ospf cost 22
 bandwidth 1544
 tunnel source Loopback4
 tunnel destination 128.32.32.254
 tunnel mode gre multipoint
 tunnel key 266281
!
interface Tunnel3
 description TUNNEL to haughty via Tweedle
 ip address 128.32.32.165 255.255.255.252
 no ip redirects
 ip ospf authentication-key hangover
 ip ospf cost 64
 tunnel source Loopback5
 tunnel destination 175.12.121.64
 tunnel mode gre multipoint
 tunnel key 992282
!
interface Ethernet0
 ip address 128.32.32.3 255.255.255.192
 ip ospf authentication-key guilty
 no cdp enable
!
interface Serial0
 description Cross-connect to Foobar
 ip address 207.181.198.194 255.255.255.252
 ip access-group 151 in
 bandwidth 154400
!
interface Serial1
 no ip address
 shutdown
!
interface ATM3/0.40 multipoint
 description dasterd bridged pvc
 pvc 1542357-dasterd 1/2978
  class-vc dsl192
  protocol ip 195.22.72.84
 !
 pvc 1626763-dasterd 1/3006
  class-vc dsl192
  protocol ip 195.22.72.91
 !
 pvc 1884832-dasterd 1/3039
  class-vc dsl192
  protocol ip 195.22.72.107
  protocol ip 195.22.72.111
  protocol ip 195.22.72.112
  protocol ip 195.22.72.113
  protocol ip 195.22.72.114
 !
 pvc 1894635-dasterd 1/3042
  class-vc dsl192
  protocol ip 195.22.72.109
 !
 pvc 1940323-dasterd 1/3050
  class-vc dsl192
  protocol ip 195.22.72.117
 !
 pvc 1959519-dasterd 1/3053
  class-vc dsl144
  protocol ip 195.22.72.116
 !
 pvc 1972914-dasterd 1/3058
  class-vc dsl192
  protocol ip 195.22.72.124
 !
 bridge-group 15
!
interface ATM3/0.171 point-to-point
 description Proodit Layer 2
 pvc 20/133
  ubr 1544
  oam-pvc 1
  oam retry 1 600 1
  oam ais-rdi 60 3
  encapsulation aal5mux fr-atm-srv
 !
!
autonomous-system 10993
!
router ospf 1
 redistribute connected
 redistribute static subnets route-map StaticToOSPF
 passive-interface Serial0
 passive-interface Serial1
 network 128.32.32.0 0.0.15.255 area 0
 network 212.212.60.128 0.0.0.31 area 0
 default-information originate metric 30 metric-type 1
 area 0 authentication
 no ospf auto-cost-determination
!
router rip
 passive-interface default
 no passive-interface Tunnel0
 default-metric 2
!
router bgp 10993
 no synchronization
 redistribute static route-map StaticToBGP
 redistribute ospf 1 route-map OSPFToBGP
 neighbor 207.181.192.13 remote-as 10368
 neighbor 207.181.192.13 ebgp-multihop 3
 neighbor 207.181.192.13 update-source Loopback0
 neighbor 207.181.192.13 send-community
 neighbor 207.181.192.13 version 4
 neighbor 207.181.192.13 route-map AS99368-IN in
 neighbor 207.181.192.13 route-map AS99368-OUT out
 neighbor 207.181.192.13 filter-list 111 in
 no auto-summary
!
ip domain-name idiom.com
ip name-server 128.32.32.64
ip name-server 128.32.32.65
ip classless
ip route 204.130.184.0 255.255.255.0 Null0
ip route 207.181.192.13 255.255.255.255 207.181.198.193
ip route 175.12.117.13 255.255.255.255 Serial0
ip route 175.12.121.16 255.255.255.255 Serial0
ip route 175.12.121.18 255.255.255.255 Serial0
ip route 175.12.121.64 255.255.255.252 128.32.32.62
ip route 175.12.121.64 255.255.255.255 128.32.32.5
ip route 175.12.121.68 255.255.255.252 128.32.32.61
ip route 212.212.60.128 255.255.255.224 Null0
ip route 216.15.30.0 255.255.255.224 Null0
ip route 216.15.30.1 255.255.255.255 128.32.32.1
ip route 216.15.30.2 255.255.255.255 128.32.32.1
ip route 216.15.30.5 255.255.255.255 128.32.32.7
ip route 216.15.30.19 255.255.255.255 128.32.32.5
ip route 128.32.32.0 255.255.224.0 Null0
ip route 128.32.32.0 255.255.240.0 Null0
ip route 128.32.32.254 255.255.255.255 128.32.32.5
ip as-path access-list 111 deny _10993_
ip as-path access-list 111 permit .*
logging buffered
access-list 101 permit ip host 192.124.90.0 host 255.255.255.0
access-list 101 permit ip host 192.171.112.0 host 255.255.255.0
access-list 101 permit ip host 204.130.184.0 host 255.255.255.0
access-list 101 permit ip host 204.238.49.0 host 255.255.255.0
access-list 101 deny   ip any any
access-list 103 deny   ip any any
access-list 103 permit ip host 128.32.32.0 host 255.255.224.0
access-list 103 permit ip host 192.124.90.0 host 255.255.255.0
access-list 103 permit ip host 192.171.112.0 host 255.255.255.0
access-list 103 permit ip host 204.238.49.0 host 255.255.255.0
access-list 103 permit ip host 204.130.184.0 host 255.255.255.0
access-list 107 deny   ip any any
access-list 107 permit ip host 0.0.0.0 host 0.0.0.0
access-list 107 deny   ip 128.32.32.0 0.0.31.255 any
access-list 107 deny   ip 10.0.0.0 0.255.255.255 any
access-list 107 deny   ip 172.16.0.0 0.0.255.255 any
access-list 107 deny   ip 192.168.0.0 0.0.255.255 any
access-list 107 permit ip any any
access-list 108 permit ip host 0.0.0.0 host 0.0.0.0
access-list 108 deny   ip any any
access-list 109 permit ip any any
access-list 120 deny   ip host 175.12.121.16 any
access-list 120 deny   ip host 175.12.121.18 any
access-list 120 deny   ip host 175.12.121.64 any
access-list 120 permit ip any any
access-list 121 permit ip any any
access-list 151 permit tcp any any established
access-list 151 deny   tcp any eq 34555 any
access-list 151 deny   tcp any any eq 34555
access-list 151 deny   ip host 127.0.0.1 any
access-list 151 deny   ip 216.15.30.0 0.0.0.31 any
access-list 151 permit ip any any
ip access-list extended filter
 remark 
 remark ESTABLISHED CONNECTIONS LIVE
 deny ip any host 10.0.0.1
 permit tcp any any established
 remark 
 remark now we'll do something nasty
 remark now we'll do something nasty too
 remark the above lines are only legal in comments
!
route-map AS99368-IN permit 30
 match ip address 107
 set ip next-hop 207.181.198.193
!
route-map StaticToOSPF deny 10
 match ip address 120
!
route-map StaticToOSPF permit 15
 match ip address 121
!
route-map AS9995-IN deny 10
!
route-map AS99368-OUT permit 15
 match ip address 103
!
route-map OSPF10993ToBGP permit 12
 match ip address 103
!
route-map StaticToBGP permit 10
 match ip address 103
!
route-map OSPFTag permit 30
 match ip address 109
 set metric 24
 set metric-type type-2
 set tag 0
 set level backbone
!
route-map OSPFToBGP permit 20
 match ip address 101
!
route-map BGP2OSPF permit 30
 match ip address 108
 set metric 24
 set metric-type type-2
 set tag 0
!
route-map nothing permit 22
 match interface Serial0 Serial0
!
snmp-server community joe RO
!
line con 0
 exec-timeout 0 0
line aux 0
line vty 0 4
 exec-timeout 9000 0
 password upGrade3
 logout-warning 120
 login
 escape-character 3
!
ntp clock-period 17179812
ntp max-associations 20
ntp server 4.2.2.2
ntp peer 128.32.32.1
ntp peer 128.32.32.129
ntp server 144.232.192.129
ntp peer 128.32.32.131
ntp peer 128.32.32.5
ntp server 206.251.0.41
ntp server 207.181.192.13
end
