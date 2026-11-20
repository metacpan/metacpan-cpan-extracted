#!/usr/bin/perl
# Tests for asn_recv truncated-header (F2) and datagram-wedge (F3) fixes.
# A truncated packet must return '' rather than OOM, and must be consumed
# so that subsequent valid packets are delivered.

use strict;
use warnings;
use lib 'lib';
use Socket;
use Convert::ASN1 qw(:io);
BEGIN { require './t/funcs.pl' }

print "1..19\n";

# Create a connected UDP socketpair over loopback.
sub udp_pair {
    socket(my $a, AF_INET, SOCK_DGRAM, 0) or die "socket: $!";
    socket(my $b, AF_INET, SOCK_DGRAM, 0) or die "socket: $!";
    bind($a, sockaddr_in(0, inet_aton('127.0.0.1'))) or die "bind a: $!";
    bind($b, sockaddr_in(0, inet_aton('127.0.0.1'))) or die "bind b: $!";
    my $addr_a = getsockname($a);
    my $addr_b = getsockname($b);
    connect($a, $addr_b) or die "connect a: $!";
    connect($b, $addr_a) or die "connect b: $!";
    return ($a, $b);
}

# --- 1-2: single-byte tag \x30 returns '' without OOM ---
{
    my ($sender, $receiver) = udp_pair();
    send($sender, "\x30", 0) or die "send: $!";
    my $buf;
    my $peer = asn_recv($receiver, $buf, 0);
    btest 1, defined $peer;
    btest 2, defined($buf) && $buf eq '';
    close $sender; close $receiver;
}

# --- 3-4: two-byte truncated long-form length \x30\x84 returns '' without OOM ---
{
    my ($sender, $receiver) = udp_pair();
    send($sender, "\x30\x84", 0) or die "send: $!";
    my $buf;
    my $peer = asn_recv($receiver, $buf, 0);
    btest 3, defined $peer;
    btest 4, defined($buf) && $buf eq '';
    close $sender; close $receiver;
}

# --- 5-6: a valid element is still delivered correctly ---
{
    my ($sender, $receiver) = udp_pair();
    my $pdu = "\x30\x03\x02\x01\x05";   # SEQUENCE { INTEGER 5 }
    send($sender, $pdu, 0) or die "send: $!";
    my $buf;
    asn_recv($receiver, $buf, 0);
    btest 5, defined $buf;
    btest 6, $buf eq $pdu;
    close $sender; close $receiver;
}

# --- 7-8: bad datagram is consumed; good datagram following it is delivered (F3) ---
{
    my ($sender, $receiver) = udp_pair();
    my $pdu = "\x30\x03\x02\x01\x05";
    send($sender, "\x30", 0)  or die "send: $!";   # bad: truncated tag
    send($sender, $pdu, 0)    or die "send: $!";   # good: follows immediately
    my $buf;
    asn_recv($receiver, $buf, 0);                  # consumes the bad datagram
    btest 7, defined($buf) && $buf eq '';
    asn_recv($receiver, $buf, 0);                  # delivers the good one
    btest 8, defined($buf) && $buf eq $pdu;
    close $sender; close $receiver;
}

# --- 9-10: truncated long-form length consumed; good datagram following delivered ---
{
    my ($sender, $receiver) = udp_pair();
    my $pdu = "\x30\x03\x02\x01\x07";
    send($sender, "\x30\x84", 0) or die "send: $!";
    send($sender, $pdu, 0)       or die "send: $!";
    my $buf;
    asn_recv($receiver, $buf, 0);
    btest 9, defined($buf) && $buf eq '';
    asn_recv($receiver, $buf, 0);
    btest 10, defined($buf) && $buf eq $pdu;
    close $sender; close $receiver;
}

# --- 11-14: MSG_PEEK on a bad datagram leaves it queued; a normal read then
# consumes it and the following good datagram is delivered ---
{
    my ($sender, $receiver) = udp_pair();
    my $pdu = "\x30\x03\x02\x01\x09";
    send($sender, "\x30", 0) or die "send: $!";
    send($sender, $pdu, 0)   or die "send: $!";
    my $buf;
    asn_recv($receiver, $buf, MSG_PEEK);
    btest 11, defined($buf) && $buf eq '';
    recv($receiver, my $raw, 64, MSG_PEEK);
    btest 12, defined($raw) && $raw eq "\x30";      # still at the head of the queue
    asn_recv($receiver, $buf, 0);
    btest 13, defined($buf) && $buf eq '';
    my $rin = '';
    vec($rin, fileno($receiver), 1) = 1;
    $buf = undef;
    asn_recv($receiver, $buf, 0) if select($rin, undef, undef, 1);
    btest 14, defined($buf) && $buf eq $pdu;
    close $sender; close $receiver;
}

# --- 15-17: a complete header declaring a huge length must not make perl
# allocate a buffer of that size ---
{
    my $vmpeak = sub {
        open(my $fh, '<', '/proc/self/status') or return;
        while (<$fh>) { return $1 if /^VmPeak:\s+(\d+)/ }
        return;
    };
    my ($sender, $receiver) = udp_pair();
    my $pdu = "\x30\x03\x02\x01\x0b";
    send($sender, "\x30\x84\x7f\xff\xff\xff", 0) or die "send: $!";   # declares ~2GB
    send($sender, $pdu, 0)                       or die "send: $!";
    my $before = $vmpeak->();
    my $buf;
    asn_recv($receiver, $buf, 0);
    my $after = $vmpeak->();
    btest 15, defined($buf) && $buf eq '';
    asn_recv($receiver, $buf, 0);
    btest 16, defined($buf) && $buf eq $pdu;
    if (defined $before && defined $after) {
        btest 17, $after - $before < 64 * 1024;     # kB
    }
    else {
        print "ok 17 # skip no /proc/self/status\n";
    }
    close $sender; close $receiver;
}

# --- 18-19: an element larger than the first peek is still delivered whole,
# and one whose declared length exceeds the datagram is rejected ---
{
    my ($sender, $receiver) = udp_pair();
    my $pdu = "\x30\x82\x13\x88" . ("\x05\x00" x 2500);     # 5004 bytes
    send($sender, $pdu, 0) or die "send: $!";
    my $buf;
    asn_recv($receiver, $buf, 0);
    btest 18, defined($buf) && $buf eq $pdu;
    send($sender, substr($pdu, 0, 300), 0) or die "send: $!";
    asn_recv($receiver, $buf, 0);
    btest 19, defined($buf) && $buf eq '';
    close $sender; close $receiver;
}
