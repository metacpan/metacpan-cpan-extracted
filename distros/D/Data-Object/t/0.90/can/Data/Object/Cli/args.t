use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

args

=usage

  # given $cli

  $cli->args;

=description

The args method returns the ordered arguments passed to the constructor or cli.

=signature

args() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok 'Data::Object::Cli', 'args';

ok 1 and done_testing;
