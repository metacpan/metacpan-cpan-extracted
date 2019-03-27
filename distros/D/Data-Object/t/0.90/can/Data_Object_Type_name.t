use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

name

=usage

  my $name = $data->name();

=description

The name method returns the name of the data type.

=signature

name() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'name';

ok 1 and done_testing;
