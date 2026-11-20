#!/usr/bin/perl
# Tests for _enc_integer exponent-string validation fix (F5).

use strict;
use warnings;
use lib 'lib';
use Convert::ASN1;
use Math::BigInt;
BEGIN { require './t/funcs.pl' }

print "1..23\n";

my ($asn, $ret);
btest 1, $asn = Convert::ASN1->new;
btest 2, $asn->prepare('n INTEGER') or warn $asn->error;

# --- 3-4: non-numeric strings are rejected ---
btest 3, do { local $SIG{__WARN__} = sub {}; !defined($asn->encode(n => "12345678901abc")) };
btest 4, ($asn->error || '') =~ /not an integer/;

# --- 5: plain large integer string encodes correctly ---
btest 5, defined($asn->encode(n => "10000000000")) or warn $asn->error;

# --- 6: Math::BigInt object encodes correctly ---
btest 6, defined($asn->encode(n => Math::BigInt->new("100000000000"))) or warn $asn->error;

# --- 7: negative large integer string encodes correctly ---
btest 7, defined($asn->encode(n => "-10000000000")) or warn $asn->error;

# --- 8: round-trip of a large integer ---
$asn->configure(decode => { bigint => 'Math::BigInt' });
my $big = Math::BigInt->new("1092509802939879587398450394850984098031948509");
my $enc = $asn->encode(n => $big);
btest 8, defined $enc or warn $asn->error;
$ret = $asn->decode($enc);
btest 9, defined $ret or warn $asn->error;
btest 10, $ret->{n} == $big;

# --- 11-12: default max_int_len=1025 rejects integers > 1025 BER bytes ---
# 2^8200 encodes to 1026 bytes (no sign pad needed; i2osp msb is clear)
my $huge = Math::BigInt->new(2)->bpow(8200);
btest 11, !defined($asn->encode(n => $huge));
btest 12, ($asn->error || '') =~ /too large/;

# --- 13: max_int_len => 0 disables the cap ---
$asn->configure(encode => { max_int_len => 0 });
btest 13, defined($asn->encode(n => $huge)) or warn $asn->error;

# --- 14: max_int_len => 2048 allows 1026-byte integer ---
$asn->configure(encode => { max_int_len => 2048 });
btest 14, defined($asn->encode(n => $huge)) or warn $asn->error;

# --- 15: negative max_int_len is a hard error ---
$asn->configure(encode => { max_int_len => -1 });
btest 15, !defined($asn->encode(n => Math::BigInt->new("100000000000"))) &&
          ($asn->error || '') =~ /max_int_len must not be negative/;

# --- 16-23: exponent-form and '+'-signed values encode as they did before the
# integer check was added; huge exponents are rejected before bigint expansion ---
{
    my $e = Convert::ASN1->new;
    $e->prepare('n INTEGER') or warn $e->error;
    $e->configure(decode => { bigint => 'Math::BigInt' });

    my $r = $e->decode($e->encode(n => "1e20") || '');
    btest 16, $r && $r->{n} == Math::BigInt->new("100000000000000000000") or warn $e->error;

    $r = $e->decode($e->encode(n => "+5000000000") || '');
    btest 17, $r && $r->{n} == 5000000000 or warn $e->error;

    $r = $e->decode($e->encode(n => "-3e15") || '');
    btest 18, $r && $r->{n} == Math::BigInt->new("-3000000000000000") or warn $e->error;

    btest 19, defined($e->encode(n => 2**64)) or warn $e->error;

    my $t = time;
    btest 20, !defined($e->encode(n => "1e100000000"));
    btest 21, ($e->error || '') =~ /too large/;
    btest 22, time - $t < 2;

    btest 23, !defined($e->encode(n => "12345678901.5")) &&
              ($e->error || '') =~ /not an integer/;
}
