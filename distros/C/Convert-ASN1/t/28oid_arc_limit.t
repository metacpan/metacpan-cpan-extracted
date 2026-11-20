#!/usr/bin/perl
# OBJECT IDENTIFIER and RELATIVE-OID arcs are limited in size, because
# pack/unpack "w" take quadratic time on a very large arc.

use strict;
use warnings;
use lib 'lib';
use Convert::ASN1 qw(asn_encode_length);
BEGIN { require './t/funcs.pl' }

print "1..28\n";

sub tlv { pack("C", $_[0]) . asn_encode_length(length $_[1]) . $_[1] }

my ($asn, $rel, $ret, $enc, $t);
btest 1, $asn = Convert::ASN1->new;
btest 2, $asn->prepare('o OBJECT IDENTIFIER') or warn $asn->error;
btest 3, $rel = Convert::ASN1->new;
btest 4, $rel->prepare('o RELATIVE-OID') or warn $rel->error;

# --- 5-6: ordinary and UUID-arc OIDs still round-trip ---
for my $case ([5, '1.2.840.113549.1.1.11'],
              [6, '2.25.329800735698586629295641978511506172918']) {
    $enc = $asn->encode(o => $case->[1]);
    $ret = defined $enc ? $asn->decode($enc) : undef;
    btest $case->[0], $ret && $ret->{o} eq $case->[1] or warn $asn->error;
}

# --- 7-9: a huge arc is rejected on decode, quickly ---
$t = time;
btest 7, !defined($asn->decode(tlv(0x06, "\x2a" . ("\xff" x 60_000) . "\x7f")));
btest 8, ($asn->error || '') =~ /arc too large/;
btest 9, time - $t < 2;

# --- 10-11: a 32-byte arc decodes, a 33-byte arc does not ---
btest 10, defined($asn->decode(tlv(0x06, "\x2a" . ("\x81" x 31) . "\x01"))) or warn $asn->error;
btest 11, !defined($asn->decode(tlv(0x06, "\x2a" . ("\x81" x 32) . "\x01")));

# --- 12-13: RELATIVE-OID uses the same limit ---
btest 12, !defined($rel->decode(tlv(0x0d, ("\xff" x 60_000) . "\x7f")));
btest 13, ($rel->error || '') =~ /arc too large/;

# --- 14-16: a huge arc is rejected on encode, quickly ---
$t = time;
btest 14, !defined($asn->encode(o => '1.2.' . ('9' x 80_000)));
btest 15, ($asn->error || '') =~ /arc too large/;
btest 16, time - $t < 2;

# --- 17-18: a 67-digit arc encodes and decodes back, a 68-digit arc does not ---
my $oid67 = '1.2.' . ('9' x 67);
$enc = $asn->encode(o => $oid67);
$ret = defined $enc ? $asn->decode($enc) : undef;
btest 17, $ret && $ret->{o} eq $oid67 or warn $asn->error;
btest 18, !defined($asn->encode(o => '1.2.' . ('9' x 68)));

# --- 19: RELATIVE-OID encode uses the same limit ---
btest 19, !defined($rel->encode(o => '5.' . ('9' x 80_000)));

# --- 20-28: the limit is configurable through max_oid_arc_len ---
my $arc33 = tlv(0x06, "\x2a" . ("\x81" x 32) . "\x01");     # one 33-byte arc
my $oid68 = '1.2.' . ('9' x 68);

my $cfg = Convert::ASN1->new;
$cfg->prepare('o OBJECT IDENTIFIER') or warn $cfg->error;

$cfg->configure(decode => { max_oid_arc_len => 64 }, encode => { max_oid_arc_len => 64 });
btest 20, defined($cfg->decode($arc33)) or warn $cfg->error;
btest 21, defined($cfg->encode(o => $oid68)) or warn $cfg->error;
btest 22, !defined($cfg->decode(tlv(0x06, "\x2a" . ("\x81" x 64) . "\x01")));

$cfg->configure(decode => { max_oid_arc_len => 0 }, encode => { max_oid_arc_len => 0 });
btest 23, defined($cfg->decode(tlv(0x06, "\x2a" . ("\x81" x 500) . "\x01"))) or warn $cfg->error;
btest 24, defined($cfg->encode(o => '1.2.' . ('9' x 1000))) or warn $cfg->error;

$cfg->configure(decode => { max_oid_arc_len => 8 }, encode => { max_oid_arc_len => 8 });
btest 25, !defined($cfg->decode(tlv(0x06, "\x2a" . ("\x81" x 8) . "\x01")));
btest 26, !defined($cfg->encode(o => '1.2.' . ('9' x 17)));

$cfg->configure(decode => { max_oid_arc_len => -1 }, encode => { max_oid_arc_len => -1 });
btest 27, !defined($cfg->decode($arc33)) && ($cfg->error || '') =~ /max_oid_arc_len must not be negative/;
btest 28, !defined($cfg->encode(o => '1.2.3')) && ($cfg->error || '') =~ /max_oid_arc_len must not be negative/;
