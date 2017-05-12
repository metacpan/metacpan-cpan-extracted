BEGIN { $| = 1; print "1..20\n"; }
BEGIN { $^W = 0 } # hate

use CBOR::XS;

print "ok 1\n";

sub CBOR::XS::tocbor::TO_CBOR {
   print @_ == 1 ? "" : "not ", "ok 3\n";
   print CBOR::XS::tocbor:: eq ref $_[0] ? "" : "not ", "ok 4\n";
   print $_[0]{k} == 1 ? "" : "not ", "ok 5\n";
   7
}

$obj = bless { k => 1 }, CBOR::XS::tocbor::;

print "ok 2\n";

$enc = encode_cbor $obj;
print $enc eq "\x07" ? "" : "not ", "ok 6\n";

print "ok 7\n";

sub CBOR::XS::freeze::FREEZE {
   print @_ == 2 ? "" : "not ", "ok 8\n";
   print $_[1] eq "CBOR" ? "" : "not ", "ok 9\n";
   print CBOR::XS::freeze:: eq ref $_[0] ? "" : "not ", "ok 10\n";
   print $_[0]{k} == 1 ? "" : "not ", "ok 11\n";
   (3, 1, 2)
}

sub CBOR::XS::freeze::THAW {
   print @_ == 5 ? "" : "not ", "ok 13\n";
   print CBOR::XS::freeze:: eq $_[0] ? "" : "not ", "ok 14\n";
   print $_[1] eq "CBOR" ? "" : "not ", "ok 15\n";
   print $_[2] == 3 ? "" : "not ", "ok 16\n";
   print $_[3] == 1 ? "" : "not ", "ok 17\n";
   print $_[4] == 2 ? "" : "not ", "ok 18\n";
   777
}

$obj = bless { k => 1 }, CBOR::XS::freeze::;
$enc = encode_cbor $obj;
print $enc eq (pack "H*", "d81a845043424f523a3a58533a3a667265657a65030102") ? "" : "not ", "ok 12 ", (unpack "H*", $enc), "\n";

$dec = decode_cbor $enc;
print $dec eq 777 ? "" : "not ", "ok 19\n";

print "ok 20\n";

