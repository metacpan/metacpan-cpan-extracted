BEGIN { $| = 1; print "1..11\n"; }
BEGIN { $^W = 0 } # hate

use CBOR::XS;

print "ok 1\n";

sub CBOR::XS::freeze::FREEZE { 77 }
sub CBOR::XS::freeze::THAW { \my $dummy }

$enc = CBOR::XS::encode_cbor_sharing [(bless [], CBOR::XS::freeze::) x 3];
print $enc eq (pack "H*", "83d81cd81a825043424f523a3a58533a3a667265657a65184dd81d00d81d00") ? "" : "not ", "ok 2 ", (unpack "H*", $enc), "\n";

$enc = CBOR::XS->new->allow_sharing->encode ([(bless [], CBOR::XS::freeze::) x 3]);
print $enc eq (pack "H*", "83d81cd81a825043424f523a3a58533a3a667265657a65184dd81d00d81d00") ? "" : "not ", "ok 3 ", (unpack "H*", $enc), "\n";

$dec = decode_cbor $enc;
print @$dec == 3 ? "" : "not ", "ok 4 # $dec\n";
print ref $dec->[0] ? "" : "not ", "ok 5 # $dec->[0]\n";
print $dec->[0] == $dec->[2] ? "" : "not ", "ok 6 # $dec->[0] == $dec->[2]\n";

$enc = eval { CBOR::XS::decode_cbor pack "H*", "d81c81d81d00" };

print defined $enc ? "not " : "", "ok 7\n";
print $@ =~ /^cyclic / ? "" : "not ", "ok 8\n";

$dec = CBOR::XS->new->allow_cycles->decode (pack "H*", "d81c81d81d00");

print ARRAY:: eq ref $dec ? "" : "not ", "ok 9\n";
print $dec == $dec->[0] ? "" : "not ", "ok 10\n";

print "ok 11\n";

