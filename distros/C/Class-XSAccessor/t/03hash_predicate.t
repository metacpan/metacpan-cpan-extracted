use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor
  accessors           => { bar => 'bar' },
  getters             => { get_foo => 'foo', get_zero => 'zero' },
  setters             => { set_foo => 'foo' },
  predicates          => { has_foo => 'foo', has_bar => 'bar', has_zero => 'zero' },
  defined_predicates  => { has_foo2 => 'foo', has_bar2 => 'bar', has_zero2 => 'zero' },
  exists_predicates   => { has_baz => 'baz', has_buz => 'buz' };

use Class::XSAccessor
  predicates => 'single';
use Class::XSAccessor
  predicates => [qw/mult iple/];

sub new {
  my $class = shift;
  bless { bar => 'baz', zero => 0, buz => undef }, $class;
}

package main;

use Test::More tests => 29;

my $obj = Class::XSAccessor::Test->new();

ok($obj->can('has_foo'));
ok($obj->can('has_bar'));

ok(!$obj->has_foo());
ok(!$obj->has_foo2());
ok(!$obj->has_baz());
ok($obj->has_buz());
ok($obj->has_bar());

is($obj->set_foo('bar'), 'bar');
is($obj->bar('quux'), 'quux');

ok($obj->has_foo());
ok($obj->has_bar());
ok($obj->has_foo2());
ok($obj->has_bar2());

is($obj->set_foo(undef), undef);
is($obj->bar(undef), undef);
$obj->{foo2} = undef;

ok(!$obj->has_foo()); # undef is "doesn't have" for defined_predicates
ok(!$obj->has_foo2()); # undef is "doesn't have" for defined_predicates
delete $obj->{foo};
delete $obj->{foo2};
ok(!$obj->has_foo());
ok(!$obj->has_foo2());

$obj->{baz} = undef;
ok($obj->has_baz(), "exists_predicates on undef elem is true");
delete $obj->{baz};
ok(!$obj->has_baz(), "exists_predicates on non-existant elem is false");

is($obj->get_zero, 0);
ok($obj->has_zero);

ok(!$obj->single);
ok(!$obj->mult);
ok(!$obj->iple);

$obj->{$_} = 1 for qw/single mult/;

ok($obj->single);
ok($obj->mult);
ok(!$obj->iple);

