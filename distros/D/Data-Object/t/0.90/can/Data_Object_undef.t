use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

undef

=usage

  # given undef

  my $object = Data::Object->undef(undef);

=description

The C<undef> constructor function returns a L<Data::Object::Undef> object for given
argument.

=signature

undef(Undef $arg?) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object';

my $object;

$object = Data::Object->undef;

isa_ok $object, 'Data::Object::Undef';

$object = Data::Object->undef(undef);

isa_ok $object, 'Data::Object::Undef';

ok 1 and done_testing;
