BEGIN { $| = 1; print "1..9\n"; }
BEGIN { $^W = 0 } # hate

use CBOR::XS;

print "ok 1\n";

$dec = CBOR::XS->new->decode ("\x62\xc3\xbc");
print $dec eq "\xfc" ? "" : "not ", "ok 2 # $dec\n";

$dec = eval { CBOR::XS->new->decode ("\x62\xc3\xc3"); 1 };
print $dec eq 1 ? "" : "not ", "ok 3 # $dec\n";

$dec = eval { CBOR::XS->new->decode ("\x61\xc3"); 1 };
print $dec eq 1 ? "" : "not ", "ok 4 # $dec\n";

$dec = eval { CBOR::XS->new->validate_utf8->decode ("\x62\xc3\xc3"); 1 };
print !$dec ? "" : "not ", "ok 5 # $dec\n";

$dec = eval { CBOR::XS->new->validate_utf8->decode ("\x61\xc3"); 1 };
print !$dec ? "" : "not ", "ok 6 # $dec\n";

$dec = CBOR::XS->new->decode ("\xa1\x62\xc3\xbc\xf6");
print "\xfc" eq (keys %$dec)[0] ? "" : "not ", "ok 7 # $dec\n";

$dec = eval { CBOR::XS->new->decode ("\xa1\x62\xc3\xc3\xf6"); 1 };
print $dec eq 1 ? "" : "not ", "ok 8 # $dec\n";

$dec = eval { CBOR::XS->new->validate_utf8->decode ("\xa1\x62\xc3\xc3\xf6"); 1 };
print !$dec ? "" : "not ", "ok 9 # $dec\n";

