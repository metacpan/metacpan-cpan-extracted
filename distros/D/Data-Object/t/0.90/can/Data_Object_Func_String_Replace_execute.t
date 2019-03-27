use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("hello");

  my $func = Data::Object::Func::String::Replace->new(
    arg1 => $data,
    arg2 => 'ello',
    arg3 => 'ey'
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
use Data::Object::Func::String::Replace;

can_ok "Data::Object::Func::String::Replace", "execute";

my $data;
my $func;

$data = Data::Object::String->new("hello");
$func = Data::Object::Func::String::Replace->new(
  arg1 => $data,
  arg2 => 'ello',
  arg3 => 'ey'
);

my $result = $func->execute;

is_deeply $result, 'hey';

ok 1 and done_testing;
