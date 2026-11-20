#!/usr/bin/perl
# Tests for _dec_bitstring zero-length content guard (F6).

use strict;
use warnings;
use lib 'lib';
use Convert::ASN1 qw(asn_encode_length);
BEGIN { require './t/funcs.pl' }

print "1..10\n";

sub make_bitstring {
    my $content = shift;
    return pack("C", 0x03) . asn_encode_length(length $content) . $content;
}

my ($asn, $ret);
btest 1, $asn = Convert::ASN1->new;
btest 2, $asn->prepare('b BIT STRING') or warn $asn->error;

# --- 3-4: zero-length BIT STRING decodes to empty string with 0 bits ---
my $zero = make_bitstring('');
btest 3, $ret = $asn->decode($zero) or warn $asn->error;
btest 4, defined($ret) && $ret->{b}[0] eq '' && $ret->{b}[1] == 0;

# --- 5-6: a valid non-empty BIT STRING still decodes correctly ---
# content: 0x00 (0 unused bits) + 0xA0 (data byte)
my $valid = make_bitstring("\x00\xA0");
btest 5, $ret = $asn->decode($valid) or warn $asn->error;
btest 6, defined($ret) && $ret->{b}[0] eq "\xA0" && $ret->{b}[1] == 8;

# --- 7-8: constructed BIT STRING (tag 0x23) with 500 zero-length fragments
# doesn't cause quadratic memory (mini-PoC scenario) ---
btest 7, $asn->prepare('x BIT STRING') or warn $asn->error;
my $frags = make_bitstring('') x 500;
my $cbs = pack("C", 0x23) . asn_encode_length(length $frags) . $frags;
my $t = time;
$ret = $asn->decode($cbs);
btest 8, time - $t < 5;

# --- 9-10: unused-bits byte > 7 is rejected ---
my $bad_unused = make_bitstring("\x08\xFF");   # 8 unused bits = invalid
btest 9, !defined($asn->decode($bad_unused));
btest 10, ($asn->error || '') =~ /BIT STRING decode error/;
