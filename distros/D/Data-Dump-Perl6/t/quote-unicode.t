#!perl -w

BEGIN {
    if ($] < 5.008) {
    print "1..0 # Skipped: perl-5.8 required\n";
    exit;
    }
}

use strict;
use Test qw(plan ok skip);

plan tests => 6;

use Data::Dump::Perl6 qw(dump_perl6);

ok(dump_perl6("\x{FF}"), q("\x[ff]"));
ok(dump_perl6("\xFF\x{FFF}"), q("\x[ff]\\x[fff]"));
ok(dump_perl6(join("", map chr($_), 400 .. 500)), qq("\\x[190]\\x[191]\\x[192]\\x[193]\\x[194]\\x[195]\\x[196]\\x[197]\\x[198]\\x[199]\\x[19a]\\x[19b]\\x[19c]\\x[19d]\\x[19e]\\x[19f]\\x[1a0]\\x[1a1]\\x[1a2]\\x[1a3]\\x[1a4]\\x[1a5]\\x[1a6]\\x[1a7]\\x[1a8]\\x[1a9]\\x[1aa]\\x[1ab]\\x[1ac]\\x[1ad]\\x[1ae]\\x[1af]\\x[1b0]\\x[1b1]\\x[1b2]\\x[1b3]\\x[1b4]\\x[1b5]\\x[1b6]\\x[1b7]\\x[1b8]\\x[1b9]\\x[1ba]\\x[1bb]\\x[1bc]\\x[1bd]\\x[1be]\\x[1bf]\\x[1c0]\\x[1c1]\\x[1c2]\\x[1c3]\\x[1c4]\\x[1c5]\\x[1c6]\\x[1c7]\\x[1c8]\\x[1c9]\\x[1ca]\\x[1cb]\\x[1cc]\\x[1cd]\\x[1ce]\\x[1cf]\\x[1d0]\\x[1d1]\\x[1d2]\\x[1d3]\\x[1d4]\\x[1d5]\\x[1d6]\\x[1d7]\\x[1d8]\\x[1d9]\\x[1da]\\x[1db]\\x[1dc]\\x[1dd]\\x[1de]\\x[1df]\\x[1e0]\\x[1e1]\\x[1e2]\\x[1e3]\\x[1e4]\\x[1e5]\\x[1e6]\\x[1e7]\\x[1e8]\\x[1e9]\\x[1ea]\\x[1eb]\\x[1ec]\\x[1ed]\\x[1ee]\\x[1ef]\\x[1f0]\\x[1f1]\\x[1f2]\\x[1f3]\\x[1f4]"));
ok(dump_perl6("\x{1_00FF}"), qq("\\x[100ff]"));
ok(dump_perl6("\x{FFF}\x{1_00FF}" x 30), qq(("\\x[fff]\\x[100ff]" x 30)));

# Ensure that displaying long upgraded string does not downgrade
$a = "";
$a .= chr($_) for 128 .. 255;
$a .= "\x{fff}"; chop($a); # upgrade
ok(utf8::is_utf8($a));
