use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Float->new(1.23);

  my $func = Data::Object::Func::Float::Lt->new(
    arg1 => $data,
    arg2 => 1.24
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

use Data::Object::Float;
use Data::Object::Func::Float::Lt;

can_ok "Data::Object::Func::Float::Lt", "execute";

my $data;
my $func;

$data = Data::Object::Float->new(1.23);
$func = Data::Object::Func::Float::Lt->new(
  arg1 => $data,
  arg2 => 1.24
);

my $result = $func->execute;

is_deeply $result, 1;

ok 1 and done_testing;
