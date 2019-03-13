use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_try

=usage

  my $plans = config_try;

=description

The config_try function returns plans for configuring the package to have
C<try> and C<catch> constructs for trapping exceptions.

=signature

config_try() : ArrayRef

=type

function

=cut

# TESTING

use Data::Object::Config;

can_ok 'Data::Object::Config', 'config_try';

ok 1 and done_testing;