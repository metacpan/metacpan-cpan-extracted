#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Config::Registry;

ok( 1 );

package Foo1;
  use Moo;
  extends 'Config::Registry';
  __PACKAGE__->document({ bar1=>1 });
package Foo2;
  use Moo;
  extends 'Foo1';
  __PACKAGE__->document({ bar2=>2 });
package Foo3;
  use Moo;
  extends 'Foo1';
  __PACKAGE__->document({ bar3=>3 });
package Foo4;
  use Moo;
  extends 'Foo2';
  __PACKAGE__->document({ bar2=>4 });
package main;

is(
  Foo1->document(),
  { bar1=>1 },
);

is(
  Foo2->document(),
  { bar1=>1, bar2=>2 },
);

is(
  Foo3->document(),
  { bar1=>1, bar3=>3 },
);

is(
  Foo4->document(),
  { bar1=>1, bar2=>4 },
);

done_testing;
