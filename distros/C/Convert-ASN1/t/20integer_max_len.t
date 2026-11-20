#!/usr/bin/perl
# Tests for the max_int_len cap on INTEGER decode (F1 fix).

use strict;
use warnings;
use lib 'lib';
use Convert::ASN1 qw(asn_encode_length);
BEGIN { require './t/funcs.pl' }

print "1..11\n";

# Build a minimal BER-encoded INTEGER from raw content bytes.
sub make_integer {
    my $content = shift;
    return pack("C", 0x02) . asn_encode_length(length $content) . $content;
}

my ($asn, $ret, $ok);

# --- schema used for all decode tests ---
btest 1, $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare('n INTEGER') or warn $asn->error;

# --- 3: a 5-byte INTEGER (> 4 bytes) passes the default 1024-byte cap ---
$asn->configure(decode => { bigint => 'Math::BigInt' });
my $five = make_integer("\x00" x 4 . "\x05");
btest 3, $ret = $asn->decode($five) or warn $asn->error;

# --- 4: a 1025-byte INTEGER is rejected by the default 1024-byte cap ---
my $big = make_integer("\x00" x 1025);
$asn->configure(decode => { bigint => 'Math::BigInt', max_int_len => 1024 });
btest 4, !defined($asn->decode($big))
    or print "# expected decode to fail on oversized INTEGER\n";

# --- 5: the error message mentions max_int_len ---
$asn->decode($big);
btest 5, (defined $asn->error && $asn->error =~ /max_int_len/);

# --- 6: exactly 1024 bytes is accepted by the default cap ---
my $exact = make_integer("\x01" . "\x00" x 1023);
btest 6, defined($asn->decode($exact)) or warn $asn->error;

# --- 7: raising the cap to 2048 allows a 1025-byte INTEGER ---
my $asn2 = Convert::ASN1->new;
$asn2->prepare('n INTEGER');
$asn2->configure(decode => { bigint => 'Math::BigInt', max_int_len => 2048 });
btest 7, defined($asn2->decode($big)) or warn $asn2->error;

# --- 8: setting max_int_len => 0 disables the cap entirely ---
my $asn3 = Convert::ASN1->new;
$asn3->prepare('n INTEGER');
$asn3->configure(decode => { bigint => 'Math::BigInt', max_int_len => 0 });
my $big2 = make_integer("\x01" . "\x00" x 1500);
btest 8, defined($asn3->decode($big2)) or warn $asn3->error;

# --- 9: cap of 10 rejects an 11-byte INTEGER ---
my $asn4 = Convert::ASN1->new;
$asn4->prepare('n INTEGER');
$asn4->configure(decode => { bigint => 'Math::BigInt', max_int_len => 10 });
my $eleven = make_integer("\x00" x 11);
btest 9, !defined($asn4->decode($eleven));

# --- 10: cap of 10 passes a 4-byte INTEGER (small native path, no os2ip) ---
my $four = make_integer(pack "N", 0x7fffffff);
btest 10, defined($asn4->decode($four)) or warn $asn4->error;

# --- 11: negative max_int_len is a hard error ---
my $asn5 = Convert::ASN1->new;
$asn5->prepare('n INTEGER');
$asn5->configure(decode => { bigint => 'Math::BigInt', max_int_len => -1 });
btest 11, !defined($asn5->decode($five)) && ($asn5->error || '') =~ /max_int_len must not be negative/;
