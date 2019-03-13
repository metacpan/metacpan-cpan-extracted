use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

namespace

=usage

  my $namespace = $data->namespace();

=description

The namespace method returns the name of the data type.

=signature

name() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'namespace';

ok 1 and done_testing;
