use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_json

=usage

  my $plans = config_json;

=description

The config_json function returns plans for configuring the package to have a
C<json> function that loads a L<Data::Object::Json> object.

=signature

config_json() : ArrayRef

=type

function

=cut

# TESTING

use Data::Object::Config;

can_ok 'Data::Object::Config', 'config_json';

ok 1 and done_testing;