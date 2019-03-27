use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("0xaf");

  my $func = Data::Object::Func::String::Hex->new(
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

use Data::Object::String;
use Data::Object::Func::String::Hex;

can_ok "Data::Object::Func::String::Hex", "execute";

my $data;
my $func;

$data = Data::Object::String->new("0xaf");
$func = Data::Object::Func::String::Hex->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, 175;

ok 1 and done_testing;
