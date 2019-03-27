use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Array->new([1..5]);

  my $func = Data::Object::Func::Array::Keyed->new(
    arg1 => $data,
    args => ['a'..'d']
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
use Data::Object::Func::Array::Keyed;

can_ok "Data::Object::Func::Array::Keyed", "execute";

my $data;
my $func;

$data = Data::Object::Array->new([1..5]);
$func = Data::Object::Func::Array::Keyed->new(
  arg1 => $data,
  args => ['a'..'d']
);

my $result = $func->execute;

is_deeply $result, {a=>1,b=>2,c=>3,d=>4};

ok 1 and done_testing;
