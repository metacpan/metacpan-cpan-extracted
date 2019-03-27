use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Any->new(sub {1});

  my $func = Data::Object::Func::Any::Lt->new(
    arg1 => $data,
    arg2 => ''
  );

  my $result = $func->execute;

=description

Executes the function logic and returns the result.

=signature

execute() : Object

=type

method

=cut

# TESTING

use Data::Object::Any;
use Data::Object::Func::Any::Lt;

can_ok "Data::Object::Func::Any::Lt", "execute";

my $data;
my $func;

$data = Data::Object::Any->new(sub {1});
$func = Data::Object::Func::Any::Lt->new(
  arg1 => $data,
  arg2 => ''
);

ok !eval { $func->execute } && $@ =~ m{ not supported };

ok 1 and done_testing;
