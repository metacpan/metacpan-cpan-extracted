use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $func = Data::Object::Func->new();

  my $result = $func->execute;

=description

Executes the function logic and returns the result.

=signature

execute() : Object

=type

method

=cut

# TESTING

use Data::Object::Func;

can_ok "Data::Object::Func", "execute";

my $func = Data::Object::Func->new;

ok !$func->execute;

ok 1 and done_testing;
