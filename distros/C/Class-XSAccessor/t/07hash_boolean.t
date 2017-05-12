use strict;
use warnings;

package Foo;

use Class::XSAccessor
  constructor => 'new',
  true        => [qw(t r u e)],
  false       => [qw(f a l s)];

package main;

use Test::More tests => 10;

ok (Foo->can('new'));

my $obj = Foo->new();

can_ok($obj, qw(t r u e f a l s));

ok($obj->$_) for qw(t r u e);
ok(not $obj->$_) for qw(f a l s);

