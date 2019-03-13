use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_yaml

=usage

  my $plans = config_yaml;

=description

The config_yaml function returns plans for configuring the package to have a
C<yaml> function that loads a L<Data::Object::Yaml> object.

=signature

config_yaml() : ArrayRef

=type

function

=cut

# TESTING

use Data::Object::Config;

can_ok 'Data::Object::Config', 'config_yaml';

ok 1 and done_testing;