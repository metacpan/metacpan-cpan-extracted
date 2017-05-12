#!perl -w

use strict;
use Test qw(plan ok skip);

plan tests => 15;

use Data::Dump::Perl6 qw(dump_perl6 quote_perl6);

ok(dump_perl6(""), qq(""));
ok(dump_perl6("\n"), qq("\\n"));
ok(dump_perl6("\0\1\x1F\0" . 3), q("\x[0]\x[1]\x[1f]\x[0]3"));
ok(dump_perl6("xx" x 30), qq(("x" x 60)));
ok(dump_perl6("xy" x 30), qq(("xy" x 30)));
ok(dump_perl6("\0" x 1024), qq(("\\x[0]" x 1024)));
ok(dump_perl6("\$" x 1024), qq(("\\\$" x 1024)));
ok(dump_perl6("\n" x (1024 * 1024)), qq(("\\n" x 1048576)));
ok(dump_perl6("\x7F\x80\xFF"), qq("\\x[7f]\\x[80]\\x[ff]"));
ok(dump_perl6(join("", map chr($_), 0..255)), qq("\\x[0]\\x[1]\\x[2]\\x[3]\\x[4]\\x[5]\\x[6]\\a\\b\\t\\n\\x[b]\\f\\r\\x[e]\\x[f]\\x[10]\\x[11]\\x[12]\\x[13]\\x[14]\\x[15]\\x[16]\\x[17]\\x[18]\\x[19]\\x[1a]\\e\\x[1c]\\x[1d]\\x[1e]\\x[1f] !\\\"#\\\$%&'()*+,-./0123456789:;<=>?\\\@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz\\{|\\}~\\x[7f]\\x[80]\\x[81]\\x[82]\\x[83]\\x[84]\\x[85]\\x[86]\\x[87]\\x[88]\\x[89]\\x[8a]\\x[8b]\\x[8c]\\x[8d]\\x[8e]\\x[8f]\\x[90]\\x[91]\\x[92]\\x[93]\\x[94]\\x[95]\\x[96]\\x[97]\\x[98]\\x[99]\\x[9a]\\x[9b]\\x[9c]\\x[9d]\\x[9e]\\x[9f]\\x[a0]\\x[a1]\\x[a2]\\x[a3]\\x[a4]\\x[a5]\\x[a6]\\x[a7]\\x[a8]\\x[a9]\\x[aa]\\x[ab]\\x[ac]\\x[ad]\\x[ae]\\x[af]\\x[b0]\\x[b1]\\x[b2]\\x[b3]\\x[b4]\\x[b5]\\x[b6]\\x[b7]\\x[b8]\\x[b9]\\x[ba]\\x[bb]\\x[bc]\\x[bd]\\x[be]\\x[bf]\\x[c0]\\x[c1]\\x[c2]\\x[c3]\\x[c4]\\x[c5]\\x[c6]\\x[c7]\\x[c8]\\x[c9]\\x[ca]\\x[cb]\\x[cc]\\x[cd]\\x[ce]\\x[cf]\\x[d0]\\x[d1]\\x[d2]\\x[d3]\\x[d4]\\x[d5]\\x[d6]\\x[d7]\\x[d8]\\x[d9]\\x[da]\\x[db]\\x[dc]\\x[dd]\\x[de]\\x[df]\\x[e0]\\x[e1]\\x[e2]\\x[e3]\\x[e4]\\x[e5]\\x[e6]\\x[e7]\\x[e8]\\x[e9]\\x[ea]\\x[eb]\\x[ec]\\x[ed]\\x[ee]\\x[ef]\\x[f0]\\x[f1]\\x[f2]\\x[f3]\\x[f4]\\x[f5]\\x[f6]\\x[f7]\\x[f8]\\x[f9]\\x[fa]\\x[fb]\\x[fc]\\x[fd]\\x[fe]\\x[ff]"));

ok(quote_perl6(""), qq(""));
ok(quote_perl6(42), qq("42"));
ok(quote_perl6([]) =~ /^"ARRAY\(/);
ok(quote_perl6('"'), qq("\\""));
ok(quote_perl6("\0" x 1024), join("", '"', ("\\x[0]") x 1024, '"'));
