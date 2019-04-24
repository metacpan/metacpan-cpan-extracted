BEGIN { $| = 1; print "1..384\n"; }

use common::sense;
use Convert::BER::XS ':all';

our $test;
sub ok($;$) {
   print $_[0] ? "" : "not ", "ok ", ++$test, " # $_[1]\n";
}

sub fail {
   my ($hex, $match) = @_;

   y/ //d for $hex;

   ok (!eval { ber_decode pack "H*", $hex; 1 }, "# fail $hex");
   $@ =~ s/ at .*//s;
   ok ($@ =~ $match, "# $@ =~ $match");
}

sub roundtrip {
   my ($hex, $is, $hex2) = @_;

   $hex2 ||= $hex;

   y/ //d for $hex, $hex2;

   fail "$hex,", "trailing garbage";

   my $bin  = pack "H*", $hex;
   my $bin2 = pack "H*", $hex2;

   my ($dec0, $len) = ber_decode_prefix $bin . chr rand 256;

   ok ($len == length $bin, "prefix length $len");

   my $dec = ber_decode $bin;
   ok (&ber_is ($dec, @$is), "decode $hex => @$dec");

   my $enc = ber_encode $dec;
   ok ($enc eq $bin2, "encode $hex2 == " . unpack "H*", $enc);

   ok (($enc eq ber_encode $dec0), "identical recode");
}

# extended tags
roundtrip "1f020105", [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], "020105";

# padding
roundtrip "020100", [ASN_UNIVERSAL, ASN_INTEGER, 0, 0];
roundtrip "0201ff", [ASN_UNIVERSAL, ASN_INTEGER, 0, -1];
fail "0202ffff", "X.690 8.3.2";
fail "02020001", "X.690 8.3.2";
fail "0208ffffffffffffffff", "X.690 8.3.2";

# types
roundtrip "020100", [ASN_UNIVERSAL, ASN_INTEGER, 0, 0];
roundtrip "020105", [ASN_UNIVERSAL, ASN_INTEGER, 0, 5];
roundtrip "0201ff", [ASN_UNIVERSAL, ASN_INTEGER, 0, -1];
roundtrip "020200ff", [ASN_UNIVERSAL, ASN_INTEGER, 0, 255];
roundtrip "020500ffffffff", [ASN_UNIVERSAL, ASN_INTEGER, 0, 4294967295];
roundtrip "020488776655", [ASN_UNIVERSAL, ASN_INTEGER, 0, -2005440939];
roundtrip "02050088776655", [ASN_UNIVERSAL, ASN_INTEGER, 0, 2289526357];

# 64 bit tests, clunky
if (8 == length pack "j", 0) {
   roundtrip "0208feffffffffffffff", [ASN_UNIVERSAL, ASN_INTEGER, 0, -72057594037927937];
   roundtrip "020900ffffffffffffffff", [ASN_UNIVERSAL, ASN_INTEGER, 0, 18446744073709551615];
   roundtrip "02087fffffffffffffff", [ASN_UNIVERSAL, ASN_INTEGER, 0, 9223372036854775807];
   roundtrip "0209008fffffffffffffff", [ASN_UNIVERSAL, ASN_INTEGER, 0, 10376293541461622783];
} else  {
   ok (1) for 1 .. 6 * 4;
}

roundtrip "010100", [ASN_UNIVERSAL, ASN_BOOLEAN, 0, 0];
roundtrip "010101", [ASN_UNIVERSAL, ASN_BOOLEAN, 0, 1], "0101ff";
roundtrip "010180", [ASN_UNIVERSAL, ASN_BOOLEAN, 0, 1], "0101ff";
roundtrip "0101ff", [ASN_UNIVERSAL, ASN_BOOLEAN, 0, 1], "0101ff";
fail "0100"    , "BER_TYPE_BOOLEAN value with invalid length";
fail "01020000", "BER_TYPE_BOOLEAN value with invalid length";

roundtrip "0303353637", [ASN_UNIVERSAL, ASN_BIT_STRING, 0, "567"];
roundtrip "0403353637", [ASN_UNIVERSAL, ASN_OCTET_STRING, 0, "567"];
roundtrip "0402a0ff", [ASN_UNIVERSAL, ASN_OCTET_STRING, 0, "\xa0\xff"];
roundtrip "0400", [ASN_UNIVERSAL, ASN_OCTET_STRING, 0, ""];
fail "040201", "unexpected end of message buffer";
roundtrip "0500", [ASN_UNIVERSAL, ASN_NULL, 0];
roundtrip "0500", [ASN_UNIVERSAL, ASN_NULL, 0];
fail "050101", "BER_TYPE_NULL value with non-zero length";

roundtrip "06053305818219", [ASN_UNIVERSAL, ASN_OBJECT_IDENTIFIER, 0, "1.11.5.16665"];
fail "06053305818299", "unexpected end of message buffer";
roundtrip "0d053305818219", [ASN_UNIVERSAL, ASN_RELATIVE_OID, 0, "51.5.16665"];
fail "0600", "BER_TYPE_OID length";
roundtrip "0603818055", [ASN_UNIVERSAL, ASN_OID, 0, "2.16389"];
fail "06028001", "illegal BER padding";
# first component
roundtrip "06022777", [ASN_UNIVERSAL, ASN_OID, 0, "0.39.119"];
roundtrip "06022877", [ASN_UNIVERSAL, ASN_OID, 0, "1.0.119"];
roundtrip "06024f77", [ASN_UNIVERSAL, ASN_OID, 0, "1.39.119"];
roundtrip "06025077", [ASN_UNIVERSAL, ASN_OID, 0, "2.0.119"];
roundtrip "06027777", [ASN_UNIVERSAL, ASN_OID, 0, "2.39.119"];
roundtrip "06027877", [ASN_UNIVERSAL, ASN_OID, 0, "2.40.119"];
roundtrip "0603817877", [ASN_UNIVERSAL, ASN_OID, 0, "2.168.119"];
roundtrip "06028837", [ASN_UNIVERSAL, ASN_OID, 0, "2.999"];

roundtrip "0703353739", [ASN_UNIVERSAL, ASN_OBJECT_DESCRIPTOR, 0, "579"];
roundtrip "0a0177", [ASN_UNIVERSAL, ASN_ENUMERATED, 0, 0x77];
roundtrip "2b00", [ASN_UNIVERSAL, ASN_EMBEDDED_PDV, 1];
roundtrip "0c04c2a0c3bf", [ASN_UNIVERSAL, ASN_UTF8_STRING, 0, "\xa0\xff"];
roundtrip "3000", [ASN_UNIVERSAL, ASN_SEQUENCE, 1];
roundtrip "3100", [ASN_UNIVERSAL, ASN_SET, 1];
roundtrip "1603393334", [ASN_UNIVERSAL, ASN_ASCII_STRING, 0, "934"];

roundtrip "1c0400000031", [ASN_UNIVERSAL, ASN_UNIVERSAL_STRING, 0, "1"];
roundtrip "1c0411223344", [ASN_UNIVERSAL, ASN_UNIVERSAL_STRING, 0, chr 0x11223344];
fail "1c0111", "BER_TYPE_UCS has an invalid number of octets";
fail "1c021122", "BER_TYPE_UCS has an invalid number of octets";
fail "1c03112234", "BER_TYPE_UCS has an invalid number of octets";

roundtrip "1e0400310037", [ASN_UNIVERSAL, ASN_BMP_STRING, 0, "17"];
roundtrip "1e0411223344", [ASN_UNIVERSAL, ASN_BMP_STRING, 0, "\x{1122}\x{3344}"];
fail "1e0111", "BER_TYPE_UCS has an invalid number of octets";
fail "1e03112234", "BER_TYPE_UCS has an invalid number of octets";

for my $type (
   ASN_NUMERIC_STRING, ASN_PRINTABLE_STRING, ASN_TELETEX_STRING, ASN_T61_STRING, ASN_VIDEOTEX_STRING,
   ASN_IA5_STRING, ASN_UTC_TIME, ASN_GENERALIZED_TIME, ASN_GRAPHIC_STRING, ASN_VISIBLE_STRING,
   ASN_ISO646_STRING, ASN_GENERAL_STRING, ASN_CHARACTER_STRING
) {
   roundtrip +(unpack "H*", pack "C C/a", $type, "234"), [ASN_UNIVERSAL, $type, 0, "234"];
}



