
use Test::More tests => 7;
BEGIN { use_ok('Data::VString', 'parse_vstring') };

is(parse_vstring('0'), "\0", "'0' parses right");
is(parse_vstring('1.2.3'), "\x{1}\x{2}\x{3}", "'1.2.3' parses right");
is(parse_vstring('15.7_8'), "\x{F}\x{7}\x{8}", "'15.7_8' parses right");

is(parse_vstring(''), undef, "'' returns undef");
is(parse_vstring('a.b'), undef, "'a.b' returns undef");

is(parse_vstring('65536'), "\0", "'15.7_8' parses right");


