#!/usr/bin/perl
# Tests for _decode nesting depth limit (F7).

use strict;
use warnings;
use lib 'lib';
use Convert::ASN1 qw(asn_encode_length);
BEGIN { require './t/funcs.pl' }

print "1..12\n";

# Build a schema with $depth levels of SEQUENCE nesting around an INTEGER.
sub make_schema {
    my $depth = shift;
    my $s = 'n INTEGER';
    $s = "x SEQUENCE { $s }" for 1 .. $depth;
    return $s;
}

# Build matching BER input: $depth levels of SEQUENCE wrapping INTEGER value $v.
sub make_input {
    my ($depth, $v) = @_;
    my $buf = "\x02\x01" . chr($v);
    $buf = pack("C", 0x30) . asn_encode_length(length $buf) . $buf for 1 .. $depth;
    return $buf;
}

my ($asn, $ret);
btest 1, $asn = Convert::ASN1->new;

# --- 2-3: 2 levels passes max_depth => 3 ---
$asn->configure(decode => { max_depth => 3 });
btest 2, $asn->prepare(make_schema(2)) or warn $asn->error;
btest 3, defined($asn->decode(make_input(2, 7))) or warn $asn->error;

# --- 4-6: 3 levels exceeds max_depth => 3 (depth reaches 4) ---
btest 4, $asn->prepare(make_schema(3)) or warn $asn->error;
btest 5, !defined($asn->decode(make_input(3, 7)));
btest 6, ($asn->error || '') =~ /depth/;

# --- 7: max_depth => 0 disables the limit ---
$asn->configure(decode => { max_depth => 0 });
btest 7, defined($asn->decode(make_input(3, 7))) or warn $asn->error;

# --- 8: raising max_depth to 10 allows 3 levels ---
$asn->configure(decode => { max_depth => 10 });
btest 8, defined($asn->decode(make_input(3, 7))) or warn $asn->error;

# --- 9: negative max_depth is a hard error ---
$asn->configure(decode => { max_depth => -1 });
btest 9, !defined($asn->decode(make_input(3, 7))) && ($asn->error || '') =~ /max_depth must not be negative/;

# --- 10-12: depth error inside an untagged CHOICE alternative aborts the decode
# rather than being treated as a non-match; otherwise each level retries every
# alternative and the work grows as 2**max_depth ---
{
    my $levels = 30;
    my $schema = "L0 ::= INTEGER\n";
    $schema .= "L$_ ::= CHOICE { a L" . ($_ - 1) . ", b L" . ($_ - 1) . " }\n" for 1 .. $levels;
    my $choice = Convert::ASN1->new;
    $choice->configure(decode => { max_depth => 22 });
    btest 10, $choice->prepare($schema) or warn $choice->error;
    my $top = $choice->find("L$levels");
    my $t = time;
    btest 11, !defined($top->decode("\x04\x01\x41")) && ($top->error || '') =~ /depth/;
    btest 12, time - $t < 2;
}
