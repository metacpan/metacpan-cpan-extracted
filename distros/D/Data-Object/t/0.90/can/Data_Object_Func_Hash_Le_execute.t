use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..8});

  my $func = Data::Object::Func::Hash::Le->new(
    arg1 => $data,
    arg2 => {1..4}
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
use Data::Object::Func::Hash::Le;

can_ok "Data::Object::Func::Hash::Le", "execute";

my $data;
my $func;

$data = Data::Object::Hash->new({1..8});
$func = Data::Object::Func::Hash::Le->new(
  arg1 => $data,
  arg2 => {1..4}
);

ok !eval { $func->execute } && $@ =~ m{ not supported };

ok 1 and done_testing;
