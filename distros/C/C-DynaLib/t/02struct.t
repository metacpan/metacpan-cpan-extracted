# -*- perl -*-
use Test::More tests => 5;

use C::DynaLib::Struct;
ok(1);

Define C::DynaLib::Struct('FooBar', "i", ['foo'],
    "dp", [ qw(bar baz) ]);

$pfoobar = tie ($foobar, 'FooBar', 1, 2);
$pfoobar->baz("Hello");
$pfoobar->foo(3);
@expected = (3, 2, "Hello");
@got = unpack("idp", $foobar);
ok("[@got]" eq "[@expected]");

@expected = (-65, 5e9, "string");
$foobar = pack("idp", @expected);
@got = ($pfoobar->foo, (tied $foobar)->bar, $pfoobar->baz);
ok("[@got]" eq "[@expected]");

SKIP: {
  eval "require Convert::Binary::C;" && Convert::Binary::C->import;
  skip "no Convert::Binary::C", 2 unless $Convert::Binary::C::VERSION;

  C::DynaLib::Struct::Parse <<'CCODE';
struct FooBar1 {
    int foo;
    double bar;
    char *baz;
};
struct FooBar2 {
    int foo2;
    double bar2;
    char *baz2;
};
CCODE

  $pfoobar = tie ($foobar1, 'FooBar1', 1, 2);
  $pfoobar->baz("Hello");
  $pfoobar->foo(3);
  @expected = (3, 2, "Hello");
  @got = unpack("idp", $foobar1);
  ok("[@got]" eq "[@expected]");

  $pfoobar = tie ($foobar2, 'FooBar2', 1, 2);
  $pfoobar->baz2("Hello");
  $pfoobar->foo2(3);
  @expected = (3, 2, "Hello");
  @got = unpack("idp", $foobar2);
  ok("[@got]" eq "[@expected]");
}
