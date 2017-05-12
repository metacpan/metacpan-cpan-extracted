#!/usr/bin/perl -I. -w

#
# The configuration file in this test is buggy.  It's a Cisco
# bug so we'll try to work around it.
#

use Cisco::Reconfig;
use Test;
use Carp qw(verbose);
use Scalar::Util qw(weaken);

my $debugdump = 0;

BEGIN { plan test => 6 };

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
	require Data::XDumper;
	require File::Slurp;
	File::Slurp::write_file("dumped", join("\n",Data::XDumper::Dump($config)));
	exit(0);
}

ok(defined $config);

# -----------------------------------------------------------------

$x = $config->get('controller T1 3/1');
ok($x->subs->text,<<END);
 framing esf
 clock source internal
 linecode b8zs
 description to abc
END

# -----------------------------------------------------------------

$x = $config->get('class-map match-all mpls-1');
ok($x->subs->text,<<END);
  match mpls experimental topmost 1 
END

# -----------------------------------------------------------------

$x = $config->get('class-map match-all mpls-5');
ok($x->subs->text,<<END);
  match mpls experimental topmost 5 
END

# -----------------------------------------------------------------

$x = $config->get('policy-map OutToP');
ok($x->alltext,<<END);
 policy-map OutToP
  class mpls-premium+
   priority percent 15
  class mpls-premium
   bandwidth percent 20
   random-detect
   random-detect precedence 3   776   1292 
  class mpls-standard
   bandwidth percent 16
   random-detect
   random-detect precedence 1   388   1292
END

# -----------------------------------------------------------------

$x = $config->get('interface Loopback0');
ok($x->subs->text,<<END);
 ip address 192.168.2.1 255.255.255.255
END


# -----------------------------------------------------------------


__DATA__
!
! Last configuration change at 22:19:05 GMT Wed Jun 4 2003 by xyz
! NVRAM config last updated at 22:19:05 GMT Wed Jun 4 2003 by xyz
!
version 12.2
no service pad
service tcp-keepalives-in
service timestamps debug datetime msec
service timestamps log datetime msec
service password-encryption
service compress-config
!
hostname banana
!
boot system flash disk2:c7200-p-mz.122-15.T2.bin
logging queue-limit 100
enable secret 5 hahaha
!
clock timezone GMT 0
!
!
ip subnet-zero
no ip source-route
!
!
ip cef
ip tftp source-interface Loopback0
ip domain name company.com
ip name-server 192.168.1.2
!
no ip bootp server
ip vrf MyFavoriteVRF
 description This is my vrf -- something
 rd 65000:2000
 route-target export 65000:15000
 route-target import 65000:15000
!
mpls ldp logging neighbor-changes
mpls traffic-eng tunnels
no tag-switching ip propagate-ttl forwarded
tag-switching tdp router-id Loopback0
frame-relay switching
!
!
voice call carrier capacity active
!
!
!
!
!
!
!
no voice hpi capture buffer
no voice hpi capture destination 
!
!
mta receive maximum-recipients 0
!
!
controller T1 3/0
 framing esf
 clock source internal
 linecode b8zs
 channel-group 0 timeslots 1-3
 channel-group 1 timeslots 4-6
 description to xyz
!
controller T1 3/1
 framing esf
 clock source internal
 linecode b8zs
 description to abc
!
 class-map match-all mpls-1
  match mpls experimental topmost 1 
 class-map match-all mpls-0
  match mpls experimental topmost 0 
 class-map match-all mpls-3
  match mpls experimental topmost 3 
 class-map match-all mpls-5
  match mpls experimental topmost 5 
!
!
 policy-map OutToP
  class mpls-premium+
   priority percent 15
  class mpls-premium
   bandwidth percent 20
   random-detect
   random-detect precedence 3   776   1292 
  class mpls-standard
   bandwidth percent 16
   random-detect
   random-detect precedence 1   388   1292
!
!
!
interface Loopback0
 ip address 192.168.2.1 255.255.255.255
!
interface GigabitEthernet0/1
 no ip address
 shutdown
 duplex auto
 speed auto
 media-type rj45
 no negotiation auto
!
interface GigabitEthernet0/2
 no ip address
 shutdown
 duplex auto
 speed auto
 media-type rj45
 no negotiation auto
!
interface GigabitEthernet0/3
 no ip address
 shutdown
 duplex auto
 speed auto
 media-type rj45
 no negotiation auto
!
interface Serial2/0
 description - To p1
 ip address 172.16.1.1 255.255.255.254
 no ip redirects
 no ip proxy-arp
 service-policy output OutToP
 mpls traffic-eng tunnels
 tag-switching ip
 dsu bandwidth 44210
 scramble
 framing c-bit
 cablelength 10
 crc 32
 serial restart_delay 0
 ip rsvp bandwidth 11052 11052 sub-pool 5526
!
interface Serial2/1
 description - To p2
 ip address 172.16.1.3 255.255.255.254
 no ip redirects
 no ip proxy-arp
 service-policy output OutToP
 mpls traffic-eng tunnels
 tag-switching ip
 dsu bandwidth 44210
 scramble
 framing c-bit
 cablelength 10
 crc 32
 serial restart_delay 0
 ip rsvp bandwidth 11052 11052 sub-pool 5526
!
interface Serial3/0:0
 no ip address
 shutdown
!
interface Serial3/0:1
 no ip address
 shutdown
!
interface POS6/0
 description - To p1
 ip address 172.16.1.5 255.255.255.254
 no ip redirects
 no ip proxy-arp
 service-policy output OutToP
 mpls traffic-eng tunnels
 tag-switching ip
 crc 32
 pos scramble-atm
 pos flag c2 22
 ip rsvp bandwidth 77500 77500 sub-pool 38750
!
router ospf 1
 mpls traffic-eng router-id Loopback0
 mpls traffic-eng area 0
 router-id 192.168.1.2
 log-adjacency-changes
 auto-cost reference-bandwidth 10000
 network 192.168.1.2 0.0.0.0 area 0
 network 172.16.1.1 0.0.0.0 area 0
 network 172.16.1.3 0.0.0.0 area 0
 network 172.16.1.5 0.0.0.0 area 0
!
router bgp 65000
 no synchronization
 bgp router-id 192.168.1.2
 no bgp default ipv4-unicast
 bgp log-neighbor-changes
 neighbor RR-UK-FR peer-group
 neighbor RR-UK-FR remote-as 65000
 neighbor RR-UK-FR update-source Loopback0
 neighbor 192.168.10.1 peer-group RR-UK-FR
 neighbor 192.168.10.2 peer-group RR-UK-FR
 no auto-summary
 !
 address-family ipv4 multicast
 no auto-summary
 no synchronization
 exit-address-family
 !
 address-family vpnv4
 neighbor RR-UK-FR activate
 neighbor RR-UK-FR send-community both
 neighbor 192.168.10.1 peer-group RR-UK-FR
 neighbor 192.168.10.2 peer-group RR-UK-FR
 no auto-summary
 exit-address-family
 !
 address-family ipv4
 no auto-summary
 no synchronization
 exit-address-family
 !
 address-family ipv4 vrf MyFavoriteVRF
 redistribute connected
 redistribute static
 neighbor 40.1.1.2 remote-as 2
 neighbor 40.1.1.2 activate
 neighbor 40.1.1.2 maximum-prefix 100
 no auto-summary
 no synchronization
 exit-address-family
!
ip classless
no ip http server
ip tacacs source-interface Loopback0
!
ip bgp-community new-format
!
!
logging source-interface Loopback0
logging 192.168.1.1
!
!
call rsvp-sync
!
!
mgcp profile default
!
dial-peer cor custom
!
!
!
line con 0
 exec-timeout 720 0
 password 7 hohoho
 login
 stopbits 1
line aux 0
line vty 0 4
 exec-timeout 720 0
 password 7 twinky
 login
 transport input telnet
 transport output telnet
line vty 5 15
 exec-timeout 720 0
 password 7 snicker
 login
 transport input telnet
 transport output telnet
!
ntp clock-period 17179897
ntp source Loopback0
ntp update-calendar
ntp server 192.168.1.2
!
end
