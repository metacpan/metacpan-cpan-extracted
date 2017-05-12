use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor
  getters   => { get_foo => 'foo' };

sub new {
  my $class = shift;
  bless { foo => 'baz' }, $class;
}

package main;

use Test::More tests => 4;

my $obj = Class::XSAccessor::Test->new();

ok($obj->can('get_foo'));
is($obj->get_foo(), 'baz');

package Class::XSAccessor::Test;

eval <<'HERE';
  use Class::XSAccessor
    getters   => { get_foo => 'foo' };
HERE

package main;

ok($@, 'refuses to replace by default');

package Class::XSAccessor::Test;

eval <<'HERE';
  use Class::XSAccessor
    replace => 1,
    getters   => { get_foo => 'foo' };
HERE

package main;

ok(!$@, 'replacing allowed');

