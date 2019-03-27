use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..8,9,undef});

  my $func = Data::Object::Func::Hash::Merge->new(
    arg1 => $data,
    args => [{7,7,9,9}]
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
use Data::Object::Func::Hash::Merge;

can_ok "Data::Object::Func::Hash::Merge", "execute";

my $data;
my $func;

$data = Data::Object::Hash->new({1..8,9,undef});
$func = Data::Object::Func::Hash::Merge->new(
  arg1 => $data,
  args => [{7,7,9,9}]
);

my $result = $func->execute;

is_deeply $result, {1=>2,3=>4,5=>6,7=>7,9=>9};

ok 1 and done_testing;
