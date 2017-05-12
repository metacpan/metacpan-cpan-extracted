use strict;
use warnings;
use AnyEvent::Pcap;
use Test::More tests => 9;

my $a_pcap = AnyEvent::Pcap->new;

can_ok($a_pcap, 'new');
can_ok($a_pcap, 'run');
can_ok($a_pcap, 'utils');
can_ok($a_pcap, 'device');
can_ok($a_pcap, 'filter');
can_ok($a_pcap, 'packet_handler');

my $utils = $a_pcap->utils;

can_ok($utils, 'new');
can_ok($utils, 'extract_ip_packet');
can_ok($utils, 'extract_tcp_packet');