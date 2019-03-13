use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_path

=usage

  my $plans = config_path;

=description

The config_path function returns plans for configuring the package to have a
C<path> function that loads a L<Data::Object::Path> object.

=signature

config_path() : ArrayRef

=type

function

=cut

# TESTING

use Data::Object::Config;

can_ok 'Data::Object::Config', 'config_path';

ok 1 and done_testing;