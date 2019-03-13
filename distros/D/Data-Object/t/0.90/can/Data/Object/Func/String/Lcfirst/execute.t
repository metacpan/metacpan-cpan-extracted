use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::String->new("Hello world");

  my $func = Data::Object::Func::String::Lcfirst->new(
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
use Data::Object::Func::String::Lcfirst;

can_ok "Data::Object::Func::String::Lcfirst", "execute";

my $data;
my $func;

$data = Data::Object::String->new("Hello world");
$func = Data::Object::Func::String::Lcfirst->new(
  arg1 => $data
);

my $result = $func->execute;

is_deeply $result, 'hello world';

ok 1 and done_testing;
