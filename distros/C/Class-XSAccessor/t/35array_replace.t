use strict;
use warnings;

package Class::XSAccessor::Test;

use Class::XSAccessor::Array
  getters   => { get_foo => 0 };

sub new {
  my $class = shift;
  bless [ 'baz' ], $class;
}

package main;

use Test::More tests => 4;

my $obj = Class::XSAccessor::Test->new();

ok($obj->can('get_foo'));
is($obj->get_foo(), 'baz');

package Class::XSAccessor::Test;

eval <<'HERE';
  use Class::XSAccessor::Array
    getters   => { get_foo => 0 };
HERE

package main;

ok($@, 'refuses to replace by default');

package Class::XSAccessor::Test;

eval <<'HERE';
  use Class::XSAccessor::Array
    replace => 1,
    getters   => { get_foo => 0 };
HERE

package main;

ok(!$@, 'replacing allowed');

