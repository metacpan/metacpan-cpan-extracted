use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('Class::XSAccessor') };

package Foo;
use Class::XSAccessor
  lvalue_accessors => {
    "bar" => "bar2"
  };

package main;

BEGIN {pass();}

ok( Foo->can('bar') );

my $foo = bless  {bar2 => 'b'} => 'Foo';
my $x = $foo->bar();
ok($x eq 'b');
$foo->bar = "buz";
ok($x eq 'b');
ok($foo->bar() eq 'buz');

{ # SCOPE
  my $baz = bless  {} => 'Foo';
  eval {
    $baz->bar = 12;
  };
  ok(!$@, 'assignment to !exists hash element is okay');
  is($baz->bar, 12);
}

{ # SCOPE
  my $baz = bless {} => 'Foo';
  my $baz2 = bless {} => 'Foo';
  eval {
    $baz->bar = $baz2;
  };
  ok(!$@, 'assignment to !exists hash element is okay');
  eval {
    $baz->bar->bar = 12;
  };
  ok(!$@, 'assignment to !exists hash element is okay');
  is($baz->bar->bar, 12);
}

