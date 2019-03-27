use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

path_class

=usage

  # given 'foo/bar_baz'

  path_class('foo/bar_baz'); # Foo::BarBaz

=description

The path_class function converts a path to a class name.

=signature

path_class(Str $arg1) : Str

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'path_class';

is Data::Object::Export::path_class('foo/bar_baz'), 'Foo::BarBaz';

ok 1 and done_testing;
