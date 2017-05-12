use strict;
use lib (-e 't' ? 't' : 'test'), 'inc';

use Test::More tests => 9;

package Foo;
use base 'TestFieldBase';
use Class::Field 'field';

field 'x';
field 'y' => [];
field 'z' => {};
field 'i', -init => '$self->hello';

my $xyz = field 'xyz';

sub hello {
    my $self = shift;
    return 'Howdy';
}

package main;

ok defined(&Foo::field),
    'field is exported';

ok not(defined &Foo::const),
    'const is not exported';

my $foo = Foo->new;

is ref($foo), 'Foo',
    '$foo is an object';

ok not(defined $foo->x),
    'field x starts off undefined';

is ref($foo->y), 'ARRAY',
    'y is an array ref by default';

is ref($foo->z), 'HASH',
    'z is a hash ref by default';

is $foo->i, 'Howdy',
    '-init works';

$foo->i('Goodbye');

is $foo->{i}, 'Goodbye',
    'Setting field works';

is $xyz, <<'...', 'Code generation is right';
sub {
  local *__ANON__ = "Foo::xyz";
  return $_[0]->{xyz} unless $#_ > 0;
  $_[0]->{xyz} = $_[1];
  return $_[0]->{xyz};
}
...
