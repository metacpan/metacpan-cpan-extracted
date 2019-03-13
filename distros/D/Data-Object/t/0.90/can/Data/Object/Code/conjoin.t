use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

conjoin

=usage

  # given sub { $_[0] % 2 }

  $code = $code->conjoin(sub { 1 });
  $code->(0); # 0
  $code->(1); # 1
  $code->(2); # 0
  $code->(3); # 1
  $code->(4); # 0

=description

The conjoin method creates a code reference which execute the code and the
argument in a logical AND operation having the code as the lvalue and the
argument as the rvalue. This method returns a L<Data::Object::Code> object.

=signature

conjoin(CodeRef $arg1) : DoCode

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub { $_[0] % 2 });

$data = $data->conjoin(sub { 1 });

is_deeply $data->(0), 0;

is_deeply $data->(1), 1;

is_deeply $data->(2), 0;

is_deeply $data->(3), 1;

is_deeply $data->(4), 0;

ok 1 and done_testing;
