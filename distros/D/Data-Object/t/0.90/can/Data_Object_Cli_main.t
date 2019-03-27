use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

main

=usage

  # given $cli

  $cli->main(%args);

=description

The main method is (by convention) the starting point for an automatically
executed subclass, i.e. this method is run by default if the subclass is run as
a script. This method should be overriden by the subclass. This method is
called with the named arguments C<env>, C<args> and C<opts>.

=signature

main(HashRef :$env, ArrayRef :$args, HashRef :$opts) : Any

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok 'Data::Object::Cli', 'main';

ok 1 and done_testing;
