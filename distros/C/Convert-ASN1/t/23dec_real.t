#!/usr/bin/perl
# Tests for _dec_real exponent bounds fix (F4).

use strict;
use warnings;
use lib 'lib';
use Convert::ASN1;
BEGIN { require './t/funcs.pl' }

print "1..15\n";

my ($asn, $ret);

btest 1, $asn = Convert::ASN1->new;
btest 2, $asn->prepare('r REAL') or warn $asn->error;

# Helper: build a BER REAL from raw content bytes.
sub make_real { "\x09" . chr(length $_[0]) . $_[0] }

# --- 3: zero-length REAL decodes to 0.0 ---
btest 3, $ret = $asn->decode(make_real('')) or warn $asn->error;
btest 4, $ret->{r} == 0.0;

# --- 5: valid binary REAL (1.0 base-2: first=0x80, exp=0, mant=1) ---
# 09 03 80 00 01  -> binary, exp=0, mant=1 -> 1.0
my $one = make_real("\x80\x00\x01");
btest 5, $ret = $asn->decode($one) or warn $asn->error;
btest 6, $ret->{r} == 1.0;

# --- 7: expLen > content length is rejected (buffer overread / quadratic) ---
# 09 01 80  -> binary, expLen=1, but content is only 1 byte (the first byte) -> invalid
my $overread = make_real("\x80");
btest 7, !defined($asn->decode($overread));
btest 8, ($asn->error || '') =~ /REAL decode error/;

# --- 9: long-form exponent off-by-one fix: valid encoding gives correct value ---
# Binary REAL, long-form exponent (bits 0-1 = 11 = 3 -> long form):
# first = 0x83 (binary, base-2, long-exp), expLen-byte = 0x01, exp = 0x00, mant = 0x01
# -> 1.0
my $longexp = make_real("\x83\x01\x00\x01");
btest 9, $ret = $asn->decode($longexp) or warn $asn->error;
btest 10, $ret->{r} == 1.0;

# --- 11-12: a 4-byte long-form exponent still decodes ---
# first = 0x83, expLen-byte = 0x04, exp = 0, mant = 0x01 -> 1.0
btest 11, $ret = $asn->decode(make_real("\x83\x04\x00\x00\x00\x00\x01")) or warn $asn->error;
btest 12, $ret && $ret->{r} == 1.0;

# --- 13-15: an exponent longer than 4 bytes is rejected; decoding it as a
# bigint would make pow() compute an enormous exact power ---
my $t = time;
local $SIG{ALRM} = sub { die "timeout\n" };
eval { alarm 10 };    # fail rather than hang if the check is lost
btest 13, !defined($asn->decode(make_real("\x83\x05\x01\x01\x01\x01\x01\xff")));
eval { alarm 0 };
btest 14, ($asn->error || '') =~ /REAL decode error/;
btest 15, time - $t < 2;
