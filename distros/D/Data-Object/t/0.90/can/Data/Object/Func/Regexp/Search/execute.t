use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Regexp->new(qr/test/);

  my $func = Data::Object::Func::Regexp::Search->new(
    arg1 => $data,
    arg2 => 'test case'
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

use Data::Object::Regexp;
use Data::Object::Func::Regexp::Search;

can_ok "Data::Object::Func::Regexp::Search", "execute";

my $data;
my $func;

$data = Data::Object::Regexp->new(qr/test/);
$func = Data::Object::Func::Regexp::Search->new(
  arg1 => $data,
  arg2 => 'test case'
);

my $result = $func->execute;

is_deeply $result, [
  ''.qr/test/.'',
  'test case',
  1,
  [
    '0'
  ],
  [
    '4'
  ],
  {},
  'test case'
];

ok 1 and done_testing;
