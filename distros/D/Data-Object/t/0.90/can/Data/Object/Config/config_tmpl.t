use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_tmpl

=usage

  my $plans = config_tmpl;

=description

The config_tmpl function returns plans for configuring the package to have a
C<tmpl> function that loads a L<Data::Object::Template> object.

=signature

config_tmpl() : ArrayRef

=type

function

=cut

# TESTING

use Data::Object::Config;

can_ok 'Data::Object::Config', 'config_tmpl';

ok 1 and done_testing;