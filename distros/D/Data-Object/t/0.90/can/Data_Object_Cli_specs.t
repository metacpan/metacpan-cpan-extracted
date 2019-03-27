use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

specs

=usage

  # given $cli

  $cli->specs;

=description

The specs method (if present) returns a list of L<Getopt::Long> option
specifications. This method should be overriden by the subclass.

=signature

specs() : (Str)

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok 'Data::Object::Cli', 'specs';

ok 1 and done_testing;
