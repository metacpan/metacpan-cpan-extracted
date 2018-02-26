package # hide from pause
  MyModule::Plugin::Foo;
use strict;
use warnings;

use MRO::Compat;
use mro 'c3';

sub message {
  "Foo";
}

1;
