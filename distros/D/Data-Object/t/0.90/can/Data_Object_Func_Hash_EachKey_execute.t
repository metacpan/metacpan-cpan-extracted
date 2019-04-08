use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..8,9,undef});

  my $sets = [];

  my $func = Data::Object::Func::Hash::EachKey->new(
    arg1 => $data,
    arg2 => sub { push @$sets, [@_] }
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
use Data::Object::Func::Hash::EachKey;

can_ok "Data::Object::Func::Hash::EachKey", "execute";

my $data;
my $func;

my $sets = [];

$data = Data::Object::Hash->new({1..8,9,undef});
$func = Data::Object::Func::Hash::EachKey->new(
  arg1 => $data,
  arg2 => sub { push @$sets, @_ }
);

my $result = $func->execute;

is_deeply $result, [1,2,3,4,5];

is_deeply [sort @$sets], [1,3,5,7,9];

ok 1 and done_testing;
