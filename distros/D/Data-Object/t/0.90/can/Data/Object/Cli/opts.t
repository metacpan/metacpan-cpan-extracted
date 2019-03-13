use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

opts

=usage

  # given $cli

  $cli->opts;

=description

The opts method returns the parsed options passed to the constructor or cli,
based on the specifications defined in the specs method.

=signature

opts() : HashRef

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok 'Data::Object::Cli', 'opts';

ok 1 and done_testing;
