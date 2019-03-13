use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

run

=usage

  # given $cli

  $cli->run;

=description

The run method automatically executes the subclass unless it's being imported
by another package.

=signature

run() : Any

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok 'Data::Object::Cli', 'run';

ok 1 and done_testing;
