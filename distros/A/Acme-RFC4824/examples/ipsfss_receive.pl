#!/usr/bin/env perl
# 
# Example script for Acme::RFC4824
# receives datagrams on an interface (with a possible pcap filter)
# and converts them into IP over SFSS frames to be signaled
#
# (c) 2007 Alexander Klink
# released under the same terms as Perl itself

use strict;
use warnings;
use bytes;

use Net::Pcap qw( loop );
use Acme::RFC4824;

sub process_packet {
    my ($user_data, $header, $packet) = @_;
    # assuming the packet is ethernet
    my $packet_type = unpack('H*', substr($packet, 12, 2));
    if ($packet_type ne '0800') {
        # not an IP packet, ignore it
        return;
    }
    print "Processing packet ...\n";
    print "Packet length: " . (length($packet) - 14) . "\n";
    my $sfss = Acme::RFC4824->new();
    my $ascii = $sfss->encode({
        TYPE     => 'ASCII',
        PACKET   => substr($packet, 14),
    });
    my @ascii_art = $sfss->encode({
        TYPE     => 'ASCII art',
        PACKET   => substr($packet, 14),
    });
    for (my $i = 0; $i < scalar @ascii_art; $i++) {
        print "Please signal '" . substr($ascii, $i, 1) . "'\n";
        print $ascii_art[$i];
        <STDIN>;
    }
    print "--- Frame completed ---\n";
}

### MAIN ###

my $interface = $ARGV[0];
if (! defined $interface) {
    die "Usage: $0 <interface> [filter]\n";
}

my $filter_str = $ARGV[1];
if (! defined $filter_str) {
    $filter_str = 'ip';
}

my $err;
my $pcap = Net::Pcap::open_live($interface, -1, 1, 100, \$err);
if ($err) {
    die "Can't open '$interface': $err";
}

my $filter;
Net::Pcap::compile($pcap, \$filter, $filter_str, 0, 0);
if ($err) {
    die "Can not compile filter '$filter_str'";
}
Net::Pcap::setfilter($pcap, $filter);

my $user_data;
loop($pcap, -1, \&process_packet, $user_data);

exit 1;
