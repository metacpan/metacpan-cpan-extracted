use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

class_name

=usage

  # given 'foo-bar'

  class_name('foo-bar'); # Foo::Bar

=description

The class_name function converts a string to a class name.

=signature

class_name(Str $arg1) : Str

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'class_name';

is Data::Object::Export::class_name('foo-bar'), 'Foo::Bar';

ok 1 and done_testing;
