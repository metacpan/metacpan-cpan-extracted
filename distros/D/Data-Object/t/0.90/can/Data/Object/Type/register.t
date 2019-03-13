use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

register

=usage

  my $register = $data->register();

=description

The register method registers the built type constraint in the specified type
library.

=signature

register() : DoType

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'register';

ok 1 and done_testing;
