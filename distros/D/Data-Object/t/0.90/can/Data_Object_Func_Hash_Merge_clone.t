use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

clone

=usage

  my $clone = $self->clone();

=description

Returns a cloned data structure.

=signature

clone(Any $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Merge';

my $data = 'Data::Object::Func::Hash::Merge';

can_ok $data, 'clone';

ok 1 and done_testing;
