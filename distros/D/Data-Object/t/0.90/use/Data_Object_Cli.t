use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Cli

=abstract

Data-Object Cli Class

=synopsis

  package Cli;

  use Data::Object::Class;

  extends 'Data::Object::Cli';

  method main(:$args) {
    # do something with $args, $opts, $env
  }

  run Cli;

=description

Data::Object::Cli provides an abstract base class for defining command-line
interface classes, which can be run as scripts or passed as objects in a more
complex system.

=cut

use_ok "Data::Object::Cli";

ok 1 and done_testing;
