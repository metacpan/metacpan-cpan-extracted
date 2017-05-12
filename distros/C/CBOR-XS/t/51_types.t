BEGIN { $| = 1; print "1..21\n"; }

use Types::Serialiser;
use CBOR::XS;

print "ok 1\n";

$enc = encode_cbor Types::Serialiser::false;
print $enc ne "\xf4" ? "not " : "", "ok 2\n";

$dec = decode_cbor $enc;
print Types::Serialiser::is_false $dec ? "" : "not ", "ok 3\n";
print Types::Serialiser::is_bool  $dec ? "" : "not ", "ok 4\n";

$enc = encode_cbor Types::Serialiser::true;
print $enc ne "\xf5" ? "not " : "", "ok 5\n";

$dec = decode_cbor $enc;
print Types::Serialiser::is_true  $dec ? "" : "not ", "ok 6\n";
print Types::Serialiser::is_bool  $dec ? "" : "not ", "ok 7\n";

$enc = encode_cbor Types::Serialiser::error;
print $enc ne "\xf7" ? "not " : "", "ok 8\n";

$dec = decode_cbor $enc;
print Types::Serialiser::is_error $dec ? "" : "not ", "ok 9\n";

$enc = encode_cbor undef;
print $enc ne "\xf6" ? "not " : "", "ok 10\n";

$dec = decode_cbor $enc;
print !defined $dec ? "" : "not ", "ok 11\n";

my $c = CBOR::XS->new->allow_sharing;

$enc = $c->encode (Types::Serialiser::false);
print $enc ne "\xf4" ? "not " : "", "ok 12\n";

$dec = $c->decode ($enc);
print Types::Serialiser::is_false $dec ? "" : "not ", "ok 13\n";
print Types::Serialiser::is_bool  $dec ? "" : "not ", "ok 14\n";

$enc = $c->encode (Types::Serialiser::true);
print $enc ne "\xf5" ? "not " : "", "ok 15\n";

$dec = $c->decode ($enc);
print Types::Serialiser::is_true  $dec ? "" : "not ", "ok 16\n";
print Types::Serialiser::is_bool  $dec ? "" : "not ", "ok 17\n";

$enc = $c->encode (Types::Serialiser::error);
print $enc ne "\xf7" ? "not " : "", "ok 18\n";

$dec = $c->decode ($enc);
print Types::Serialiser::is_error $dec ? "" : "not ", "ok 19\n";

$enc = $c->encode (undef);
print $enc ne "\xf6" ? "not " : "", "ok 20\n";

$dec = $c->decode ($enc);
print !defined $dec ? "" : "not ", "ok 21\n";

