#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::PacketForwarder;

$AnyEvent::PacketReader::debug = -1;

use IPC::Open2;

@ARGV or die <<EOU;
Usage:
    $0 cmd arg1 arg2 ...

EOU

sub _hexdump {
    no warnings qw(uninitialized);
    while ($_[0] =~ /(.{1,32})/smg) {
        my $line = $1;
        my @c= (( map { sprintf "%02x",$_ } unpack('C*', $line)),
                (("  ") x 32))[0..31];
        $line=~s/(.)/ my $c=$1; unpack("c",$c)>=32 ? $c : '.' /egms;
        print STDERR "$_[1] ", join(" ", @c, '|', $line), "\n";
    }
    print STDERR "\n";

}
my $pid = open2(my($slave_out, $slave_in), @ARGV);

my $done = AnyEvent->condvar;

sub pkt_dump {
    my (undef, $dir, $fatal) = @_;
    if (defined $_[0]) {
        _hexdump($_[0], $dir);
        return 1;
    }
    else {
        if ($fatal) {
            print STDERR "forwarder $dir closed: $!\n";
            if ($dir eq '>') {
                close STDIN;
                close $slave_in;
            }
            else {
                close STDOUT;
                close $slave_out;
            }
            $done->end;
        }
        else {
            print STDERR "reading side of forwarder $dir closed: $!\n";
        }
    }
}

my $req_fwdr = packet_forwarder(\*STDIN,    $slave_in, sub { pkt_dump($_[0], '>', $_[1]) });
$done->begin;
my $res_fwdr = packet_forwarder($slave_out, \*STDOUT , sub { pkt_dump($_[0], '<', $_[1]) });
$done->begin;

$done->recv;

