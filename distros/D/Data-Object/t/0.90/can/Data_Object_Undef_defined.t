use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

defined

=usage

  # given undef

  $undef->defined ? 'Yes' : 'No'; # No

=description

The defined method always returns false. This method returns a
L<Data::Object::Number> object.

=signature

defined() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Undef';

my $data = Data::Object::Undef->new(undef);

is_deeply $data->defined(), 0;

ok 1 and done_testing;
