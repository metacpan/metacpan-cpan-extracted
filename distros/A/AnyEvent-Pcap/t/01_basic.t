use strict;
use warnings;
use AnyEvent::Pcap;
use Test::More tests => 2;

my $a_pcap = AnyEvent::Pcap->new;
isa_ok($a_pcap, 'AnyEvent::Pcap');

my $utils  = $a_pcap->utils;
isa_ok($utils, 'AnyEvent::Pcap::Utils');