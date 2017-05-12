#!/usr/bin/perl
#
# Example script for Acme::RFC4824
# receives signaled frames as ASCII on STDIN and outputs them to the
# network
#
# (c) 2007 Alexander Klink
# released under the same terms as Perl itself

use strict;
use warnings;
use bytes;

use Net::Pcap;

use Acme::RFC4824;

### MAIN ###

my $interface = $ARGV[0];
if (! defined $interface) {
    die "Usage: $0 <interface> <source MAC> <destination MAC>\n";
}
my $src_mac = $ARGV[1];
if (! defined $src_mac) {
    die "Usage: $0 <interface> <source MAC> <destination MAC>\n";
}
my $dst_mac = $ARGV[2];
if (! defined $dst_mac) {
    die "Usage: $0 <interface> <source MAC> <destination MAC>\n";
}
$src_mac =~ s/://g;
$dst_mac =~ s/://g;

my $err;
my $pcap = Net::Pcap::open_live($interface, -1, 1, 100, \$err);
if ($err) {
    die "Can't open '$interface': $err";
}

my $sfss = Acme::RFC4824->new();
print "Enter received frames line by line\n";
while (my $line = <STDIN>) {
    chomp($line);
    my $packet = $sfss->decode({
        FRAME => $line,
    });
    my $eth_packet = pack('H12', $src_mac)
                   . pack('H12', $dst_mac)
                   . pack('H4', '0800') . $packet;                
    Net::Pcap::sendpacket($pcap, $eth_packet);
}
