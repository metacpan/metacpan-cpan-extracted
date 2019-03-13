use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rcurry

=usage

  # given sub { [@_] }

  $code = $code->rcurry(1,2,3);
  $code->(4,5,6); # [4,5,6,1,2,3]

=description

The rcurry method returns a code reference which executes the code passing it
the any additional parameters and any arguments when executed. This method
returns a L<Data::Object::Code> object.

=signature

rcurry(Any $arg1) : DoCode

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub { [@_] });

$data = $data->rcurry(1,2,3);

is_deeply $data->(4,5,6), [4,5,6,1,2,3];

ok 1 and done_testing;
