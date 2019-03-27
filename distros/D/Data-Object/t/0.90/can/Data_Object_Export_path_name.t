use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

path_name

=usage

  # given 'Foo::BarBaz'

  path_name('Foo::BarBaz'); # foo-bar_baz

=description

The path_name function converts a class name to a path.

=signature

path_name(Str $arg1) : Str

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'path_name';

is Data::Object::Export::path_name('Foo::BarBaz'), 'foo-bar_baz';

ok 1 and done_testing;
