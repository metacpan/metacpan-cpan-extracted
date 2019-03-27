use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

options

=usage

  my $options = $data->options();

=description

The options method is used internally to create the options for building the
L<Type::Tiny> type constraint.

=signature

options(Any $arg1) : (Str, Any)

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'options';

ok 1 and done_testing;
