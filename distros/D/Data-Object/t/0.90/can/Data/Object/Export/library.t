use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

library

=usage

  library; # Type::Library

=description

The library function returns the default L<Type::Library> object where all core
type constraints are registered.

=signature

library() : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'library';

isa_ok ref(Data::Object::Export::library()), 'Type::Library';

ok 1 and done_testing;
