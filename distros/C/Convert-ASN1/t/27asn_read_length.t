#!/usr/bin/perl
# asn_read and asn_get must not size their read buffer from the length an
# element declares; memory should track the data actually received.

use strict;
use warnings;
use lib 'lib';
use File::Temp qw(tempfile);
use Convert::ASN1 qw(:io);
BEGIN { require './t/funcs.pl' }

print "1..10\n";

sub vmpeak {
    open(my $fh, '<', '/proc/self/status') or return;
    while (<$fh>) { return $1 if /^VmPeak:\s+(\d+)/ }
    return;
}

# Return a read handle on a temporary file holding $data.
sub handle_for {
    my $data = shift;
    my ($fh, $name) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $data;
    close $fh;
    open(my $in, '<', $name) or die "open: $!";
    binmode $in;
    return $in;
}

sub mem_test {
    my ($num, $before, $after) = @_;
    if (defined $before && defined $after) {
        btest $num, $after - $before < 64 * 1024;     # kB
    }
    else {
        print "ok $num # skip no /proc/self/status\n";
    }
}

my $huge = "\x30\x84\x7f\xff\xff\xff" . ("A" x 100);    # declares ~2GB, holds 100 bytes

# --- 1-2: asn_read fails on the short input without a huge allocation ---
{
    my $in = handle_for($huge);
    my $before = vmpeak();
    my $buf;
    my $ret = asn_read($in, $buf);
    my $after = vmpeak();
    btest 1, !defined $ret;
    mem_test 2, $before, $after;
}

# --- 3-4: asn_get fails on the short input without a huge allocation ---
{
    my $in = handle_for($huge);
    my $before = vmpeak();
    my $ret = asn_get($in);
    my $after = vmpeak();
    btest 3, !defined $ret;
    mem_test 4, $before, $after;
}

# An element larger than a single read, followed by a small one.
my $big   = "\x04\x83\x03\x0d\x40" . ("B" x 200_000);
my $small = "\x30\x03\x02\x01\x05";

# --- 5-7: asn_read returns exactly one element at a time ---
{
    my $in = handle_for($big . $small);
    my $buf;
    my $ret = asn_read($in, $buf);
    btest 5, defined($ret) && $ret == length $big;
    btest 6, $buf eq $big;
    asn_read($in, $buf);
    btest 7, $buf eq $small;
}

# --- 8-10: asn_get returns each element whole ---
{
    my $in = handle_for($big . $small);
    my $ret = asn_get($in);
    btest 8, defined($ret) && $ret eq $big;
    $ret = asn_get($in);
    btest 9, defined($ret) && $ret eq $small;
    btest 10, !defined asn_get($in);
}
