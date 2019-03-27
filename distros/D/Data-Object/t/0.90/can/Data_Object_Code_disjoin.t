use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

disjoin

=usage

  # given sub { $_[0] % 2 }

  $code = $code->disjoin(sub { -1 });
  $code->(0); # -1
  $code->(1); #  1
  $code->(2); # -1
  $code->(3); #  1
  $code->(4); # -1

=description

The disjoin method creates a code reference which execute the code and the
argument in a logical OR operation having the code as the lvalue and the
argument as the rvalue. This method returns a L<Data::Object::Code> object.

=signature

disjoin(CodeRef $arg1) : CodeRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub { $_[0] % 2 });

$data = $data->disjoin(sub { -1 });

is_deeply $data->(0), -1;

is_deeply $data->(1), 1;

is_deeply $data->(2), -1;

is_deeply $data->(3), 1;

is_deeply $data->(4), -1;

ok 1 and done_testing;
