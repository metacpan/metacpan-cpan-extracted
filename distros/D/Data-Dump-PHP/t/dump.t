#!perl -w

use strict;
use Test qw(plan ok);
plan tests => 23-5;

use Data::Dump::PHP qw(dump_php);

ok(dump_php(), "array()");
ok(dump_php("abc"), qq("abc"));
ok(dump_php(undef), "null");
ok(dump_php(0), "0");
ok(dump_php(1234), "1234");
ok(dump_php(12345), "12345");
ok(dump_php(12345678), "12345678");
ok(dump_php(-33), "-33");
ok(dump_php(-1.5), "\"-1.5\"");
ok(dump_php("0123"), qq("0123"));
ok(dump_php(1..5), "array(1, 2, 3, 4, 5)");
ok(dump_php([1..5]), "array(1, 2, 3, 4, 5)");
ok(dump_php({ a => 1, b => 2 }), qq(array( "a" => 1, "b" => 2 )));
ok(dump_php({ 1 => 1, 2 => 1, 10 => 1 }), qq(array( 1 => 1, 2 => 1, 10 => 1 )));
ok(dump_php({ 0.14 => 1, 1.8 => 1, -0.5 => 1 }), qq(array( "-0.5" => 1, "0.14" => 1, "1.8" => 1 )));
ok(dump_php({ "1,1" => 1, "1,2" => 1 }), qq(array( "1,1" => 1, "1,2" => 1 )));
ok(dump_php({ a => 1, aa => 2, aaa => join("", "a" .. "z", "a" .. "z")}) . "\n", <<EOT);
array(
  "a"   => 1,
  "aa"  => 2,
  "aaa" => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
)
EOT

ok(dump_php({ a => 1, aa => 2, aaaaaaaaaaaaaa => join("", "a" .. "z", "a" .. "z")}) . "\n", <<EOT);
array(
  "a" => 1,
  "aa" => 2,
  "aaaaaaaaaaaaaa" => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
)
EOT

#ok(dump_php(bless {}, "foo"), "bless({}, \"foo\")");
#ok(dump_php(bless [], "foo"), "bless([], \"foo\")");
#my $sv = [];
#ok(dump_php(bless \$sv, "foo"), "bless(do{\\(my \$o = [])}, \"foo\")");
#ok(dump_php(bless { a => 1, aa => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz", aaa => \$sv}, "foo") . "\n", <<'EOT');
#bless({
#  a   => 1,
#  aa  => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
#  aaa => bless(do{\(my $o = [])}, "foo"),
#}, "foo")
#EOT


# stranger stuff
#ok(dump_php({ a => \&Data::Dump::dump, aa => do {require Symbol; Symbol::gensym()}}),
#   "do {\n  require Symbol;\n  { a => sub { \"???\" }, aa => Symbol::gensym() };\n}");
