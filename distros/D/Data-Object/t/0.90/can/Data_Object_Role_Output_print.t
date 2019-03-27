use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

print

=usage

  my $print = $self->print();

=description

Output stringified object data.

=signature

print() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Output';

my $data = 'Data::Object::Role::Output';

can_ok $data, 'print';

ok 1 and done_testing;
