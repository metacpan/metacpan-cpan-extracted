BEGIN { $| = 1; print "1..21\n"; }

# none of the other tests serialise hv's, gross
# also checks text_keys/text_strings

use CBOR::XS;

print "ok 1\n";

$enc = encode_cbor {};
print $enc ne "\xa0" ? "not " : "", "ok 2\n";

$enc = encode_cbor { 5 => 6 };
print $enc ne (pack "H*", "a1413506") ? "not " : "", "ok 3\n";

$enc = encode_cbor { "" => \my $dummy };
print $enc ne (pack "H*", "a140d95652f6") ? "not " : "", "ok 4\n";

$enc = encode_cbor { undef() => \my $dummy };
print $enc ne (pack "H*", "a140d95652f6") ? "not " : "", "ok 5\n";

$enc = encode_cbor { "abc" => "def" };
print $enc ne (pack "H*", "a14361626343646566") ? "not " : "", "ok 6\n";

$enc = encode_cbor { "abc" => "def", "geh" => "ijk" };
print $enc !~ /^\xa2/ ? "not " : "", "ok 7\n";
print 17 ne length $enc ? "not " : "", "ok 8\n";

$enc = encode_cbor { "\x{7f}" => undef };
print $enc ne (pack "H*", "a1417ff6") ? "not " : "", "ok 9\n";

$dec = decode_cbor pack "H*", "a1417ff6";
print +(keys %$dec)[0] ne "\x{7f}" ? "not " : "", "ok 10\n";

$enc = encode_cbor { "\x{100}" => undef };
print $enc ne (pack "H*", "a162c480f6") ? "not " : "", "ok 11\n";

$dec = decode_cbor pack "H*", "a162c480f6";
print +(keys %$dec)[0] ne "\x{100}" ? "not " : "", "ok 12\n";

$enc = encode_cbor { "\x{8f}" => undef };
print $enc ne (pack "H*", "a1418ff6") ? "not " : "", "ok 13\n";

$text_strings = CBOR::XS->new->text_strings;

$enc = $text_strings->encode ({ "\x{7f}" => "\x{3f}" });
print $enc ne (pack "H*", "a1617f613f") ? "not " : "", "ok 14\n";

$enc = $text_strings->encode ({ "\x{8f}" => "\x{c7}" });
print $enc ne (pack "H*", "a162c28f62c387") ? "not " : "", "ok 15\n";

$enc = $text_strings->encode ({ "\x{8f}gix\x{ff}x" => "a\x{80}b\x{fe}y" });
print $enc ne (pack "H*", "a168c28f676978c3bf786761c28062c3be79") ? "not " : "", "ok 16\n";

$dec = decode_cbor pack "H*", "a168c28f676978c3bf78f6";
print +(keys %$dec)[0] ne "\x{8f}gix\x{ff}x" ? "not " : "", "ok 17\n";

$text_keys = CBOR::XS->new->text_keys;

$enc = $text_keys->encode ({ "\x{7f}" => "\x{3f}" });
print $enc ne (pack "H*", "a1617f413f") ? "not " : "", "ok 18\n";

$enc = $text_keys->encode ({ "\x{8f}" => "\x{c7}" });
print $enc ne (pack "H*", "a162c28f41c7") ? "not " : "", "ok 19\n";

$enc = $text_keys->encode ({ "\x{8f}gix\x{ff}x" => "a\x{80}b\x{fe}y" });
print $enc ne (pack "H*", "a168c28f676978c3bf7845618062fe79") ? "not " : "", "ok 20\n";

print "ok 21\n";

