use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

codify

=usage

  my $codify = $self->codify('($a * $b) + 1_000_000');

=description

Returns a parameterized coderef from a string.

=signature

codify(Object $arg1, Any @args) : CodeRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Codifiable';

my $data = 'Data::Object::Role::Codifiable';

can_ok $data, 'codify';

ok 1 and done_testing;
