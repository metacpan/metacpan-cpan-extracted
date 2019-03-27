use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Func::Array::Gt->new(
    arg1 => $data,
    arg2 => [1..4]
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

use Data::Object::Array;
use Data::Object::Func::Array::Gt;

can_ok "Data::Object::Func::Array::Gt", "execute";

my $data;
my $func;

$data = Data::Object::Array->new([1..4]);
$func = Data::Object::Func::Array::Gt->new(
  arg1 => $data,
  arg2 => [1..4]
);

ok !eval { $func->execute } && $@ =~ m{ not supported };

ok 1 and done_testing;
