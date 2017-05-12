#!perl -w

use strict;
use Test qw(plan ok);
plan tests => 32;

use Data::Dump::Perl6 qw(dump_perl6);

ok(dump_perl6(), "()");
ok(dump_perl6("abc"), qq("abc"));
ok(dump_perl6("1\n"), qq("1\\n"));
ok(dump_perl6(undef), "Nil");
ok(dump_perl6(0), "0");
ok(dump_perl6(1234), "1234");
ok(dump_perl6(12345), "12345");
ok(dump_perl6(12345678), "12345678");
ok(dump_perl6(123456789012345), "123456789012345");
ok(dump_perl6(0.333), "0.333");
ok(dump_perl6(1/3), qr/^0\.3+\z/);
ok(dump_perl6(-33), "-33");
ok(dump_perl6(-1.5), "-1.5");
ok(dump_perl6("0123"), qq("0123"));
ok(dump_perl6(1..2), "(1, 2)");
ok(dump_perl6(1..3), "(1, 2, 3)");
ok(dump_perl6(1..4), "(1 .. 4)");
ok(dump_perl6(1..5,6,8,9), "(1 .. 6, 8, 9)");
ok(dump_perl6(1..5,4..8), "(1 .. 5, 4 .. 8)");
ok(dump_perl6([-2..2]), "[-2 .. 2]");
ok(dump_perl6(["a0" .. "z9"]), qq(["a0" .. "z9"]));
ok(dump_perl6(["x", 0, 1, 2, 3, "a", "b", "c", "d"]), qq(["x", 0 .. 3, "a" .. "d"]));
ok(dump_perl6({ a => 1, b => 2 }), "{ a => 1, b => 2 }");
ok(dump_perl6({ 1 => 1, 2 => 1, 10 => 1 }), "{ 1 => 1, 2 => 1, 10 => 1 }");
ok(dump_perl6({ 0.14 => 1, 1.8 => 1, -0.5 => 1 }), qq({ "-0.5" => 1, "0.14" => 1, "1.8" => 1 }));
ok(dump_perl6({ "1,1" => 1, "1,2" => 1 }), qq({ "1,1" => 1, "1,2" => 1 }));
ok(dump_perl6({ a => 1, aa => 2, aaa => join("", "a" .. "z", "a" .. "z")}) . "\n", <<EOT);
{
  a   => 1,
  aa  => 2,
  aaa => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
}
EOT

ok(dump_perl6({ a => 1, aa => 2, aaaaaaaaaaaaaa => join("", "a" .. "z", "a" .. "z")}) . "\n", <<EOT);
{
  a => 1,
  aa => 2,
  aaaaaaaaaaaaaa => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
}
EOT

ok(dump_perl6(bless {}, "foo"), "foo.bless(content => {})");
ok(dump_perl6(bless [], "foo"), "foo.bless(content => [])");
my $sv = [];
ok(dump_perl6(bless \$sv, "foo"), "foo.bless(content => [])");
ok(dump_perl6(bless { a => 1, aa => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz", aaa => \$sv}, "foo") . "\n", <<'EOT');
foo.bless(content => {
  a   => 1,
  aa  => "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz",
  aaa => foo.bless(content => []),
})
EOT
