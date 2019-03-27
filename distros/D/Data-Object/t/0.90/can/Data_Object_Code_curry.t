use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

curry

=usage

  # given sub { [@_] }

  $code = $code->curry(1,2,3);
  $code->(4,5,6); # [1,2,3,4,5,6]

=description

The curry method returns a code reference which executes the code passing it
the arguments and any additional parameters when executed. This method returns a
L<Data::Object::Code> object.

=signature

curry(CodeRef $arg1) : CodeObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub { [@_] });

$data = $data->curry(1,2,3);

is_deeply $data->(4,5,6), [1,2,3,4,5,6];

ok 1 and done_testing;
