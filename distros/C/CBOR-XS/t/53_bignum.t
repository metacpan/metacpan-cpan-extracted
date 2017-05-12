BEGIN { $| = 1; print "1..105\n"; }
BEGIN { $^W = 0 } # hate

use CBOR::XS;

use Math::BigInt only => "FastCalc"; # needed for representation stability

print "ok 1\n";

my $t = decode_cbor pack "H*", "82c48221196ab3c5822003";

print $t->[0] eq "273.15" ? "" : "not ", "ok 2 # $t->[0]\n";
print $t->[1] eq    "1.5" ? "" : "not ", "ok 3 # $t->[1]\n";

$t = encode_cbor $t;

print $t eq (pack "H*", "82c48221196ab3c482200f") ? "" : "not ", "ok 4 # ", (unpack "H*", $t), "\n";

# Math::BigFloat must be loaded by now...

for (5..99) {
   my $n = Math::BigFloat->new ((int rand 1e9) . "." . (int rand 1e9) . "e" . ((int rand 1e8) - 0.5e8));
   my $m = decode_cbor encode_cbor $n;

   $n = $n->bsstr;
   $m = $m->bsstr;

   print $n != $m ? "not " : "ok $_ # $n eq $m\n";
}

$t = encode_cbor CBOR::XS::tag 264, [Math::BigInt->new ("99999999999999999998"), Math::BigInt->new ("799999999999999999998")];
$t = decode_cbor $t;
print "799999999999999999998e+99999999999999999998" eq $t->bsstr ? "" : "not ", "ok 100\n";

$t = encode_cbor $t;
print "d9010882c249056bc75e2d63100000c2492b5e3af16b187ffffe" eq (unpack "H*", $t) ? "" : "not ", "ok 101\n";

$t = encode_cbor CBOR::XS::tag 30, [4, 2];
$t = decode_cbor $t;
print $t eq 2 ? "" : "not ", "ok 102 # $t\n";

$t = encode_cbor $t;
print "02" eq (unpack "H*", $t) ? "" : "not ", "ok 103\n";

$t = encode_cbor decode_cbor encode_cbor CBOR::XS::tag 30, [Math::BigInt->new (5), 2];
print "d81e820502" eq (unpack "H*", $t) ? "" : "not ", "ok 104\n";

print "ok 105\n";

