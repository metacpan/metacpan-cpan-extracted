use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

env

=usage

  # given $cli

  $cli->env;

=description

The env method returns the environment variables in the running process.

=signature

env() : HashRef

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok 'Data::Object::Cli', 'env';

ok 1 and done_testing;
