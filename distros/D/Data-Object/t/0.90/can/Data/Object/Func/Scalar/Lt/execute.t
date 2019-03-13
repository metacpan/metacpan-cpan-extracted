use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $data = Data::Object::Scalar->new(\*main);

  my $func = Data::Object::Func::Scalar::Lt->new(
    arg1 => $data,
    arg2 => ''
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

no warnings 'once';

use Data::Object::Scalar;
use Data::Object::Func::Scalar::Lt;

can_ok "Data::Object::Func::Scalar::Lt", "execute";

my $data;
my $func;

$data = Data::Object::Scalar->new(\*main);
$func = Data::Object::Func::Scalar::Lt->new(
  arg1 => $data,
  arg2 => ''
);

ok !eval { $func->execute } && $@ =~ m{ not supported };

ok 1 and done_testing;
