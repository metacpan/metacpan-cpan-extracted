BEGIN { $| = 1; print "1..14\n"; }

use common::sense;
use Convert::BER::XS ':all';

$Convert::BER::XS::SNMP_PROFILE->_set_default;

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

roundtrip "400416583721", [ASN_APPLICATION, SNMP_IPADDRESS, 0, "22.88.55.33"];
fail "4003165837", "invalid length 3";
roundtrip "42050087654321", [ASN_APPLICATION, SNMP_UNSIGNED32, 0, 0x87654321];




