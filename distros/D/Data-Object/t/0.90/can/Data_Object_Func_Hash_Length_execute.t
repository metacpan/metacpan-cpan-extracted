use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..4});

  my $func = Data::Object::Func::Hash::Length->new(
    arg1 => $data
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

use Data::Object::Hash;
use Data::Object::Func::Hash::Length;

can_ok "Data::Object::Func::Hash::Length", "execute";

my $data;
my $func;

$data = Data::Object::Hash->new({1..4});
$func = Data::Object::Func::Hash::Length->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, 2;

ok 1 and done_testing;
