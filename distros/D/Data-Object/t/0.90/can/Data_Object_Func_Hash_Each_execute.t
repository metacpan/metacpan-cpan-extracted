use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Hash->new({1..8});

  my $sets = [];

  my $func = Data::Object::Func::Hash::Each->new(
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
use Data::Object::Func::Hash::Each;

can_ok "Data::Object::Func::Hash::Each", "execute";

my $data;
my $func;

my $sets = [];

$data = Data::Object::Hash->new({1..8});
$func = Data::Object::Func::Hash::Each->new(
  arg1 => $data,
  arg2 => sub { push @$sets, [@_] }
);

my $result = $func->execute;

is_deeply $result, $data;
is_deeply $result, { map { @$_ } @$sets };

ok 1 and done_testing;
