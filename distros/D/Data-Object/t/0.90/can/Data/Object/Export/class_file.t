use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

class_file

=usage

  # given 'Foo::Bar'

  class_file('Foo::Bar'); # foo_bar

=description

The class_file function convertss a class name to a class file.

=signature

class_file(Str $arg1) : Str

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'class_file';

is Data::Object::Export::class_file('Foo::Bar'), 'foo_bar';

ok 1 and done_testing;
