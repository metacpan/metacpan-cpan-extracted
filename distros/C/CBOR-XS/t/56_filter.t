BEGIN { $| = 1; print "1..8\n"; }
BEGIN { $^W = 0 } # hate

use CBOR::XS;

print "ok 1\n";

$dec = (decode_cbor encode_cbor CBOR::XS::tag 0, "2003-12-13T18:30:02Z")->epoch;
print $dec == 1071340202    ? "" : "not ", "ok 2 # $dec\n";

$dec = (decode_cbor encode_cbor CBOR::XS::tag 0, "2003-12-13T18:30:02.25Z")->epoch;
print $dec == 1071340202.25 ? "" : "not ", "ok 3 # $dec\n";

$dec = (decode_cbor encode_cbor CBOR::XS::tag 0, "2003-12-13T18:30:02+01:00")->epoch;
print $dec == 1071336602    ? "" : "not ", "ok 4 # $dec\n";

$dec = (decode_cbor encode_cbor CBOR::XS::tag 0, "2003-12-13T18:30:02.25+01:00")->epoch;
print $dec == 1071336602.25 ? "" : "not ", "ok 5 # $dec\n";

$dec = (decode_cbor encode_cbor CBOR::XS::tag 1, 123456789)->epoch;
print $dec == 123456789     ? "" : "not ", "ok 6 # $dec\n";

$dec = (decode_cbor encode_cbor CBOR::XS::tag 1, 123456789.75)->epoch;
print $dec == 123456789.75  ? "" : "not ", "ok 7 # $dec\n";

$dec = (decode_cbor encode_cbor decode_cbor encode_cbor CBOR::XS::tag 1, 123456789.75)->epoch;
print $dec == 123456789.75  ? "" : "not ", "ok 8 # $dec\n";


