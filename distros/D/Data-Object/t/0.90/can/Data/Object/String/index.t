use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

index

=usage

  # given 'unexplainable'

  $string->index('explain'); # 2
  $string->index('explain', 0); # 2
  $string->index('explain', 1); # 2
  $string->index('explain', 2); # 2
  $string->index('explain', 3); # -1
  $string->index('explained'); # -1

=description

The index method searches for the argument within the string and returns the
position of the first occurrence of the argument. This method optionally takes a
second argument which would be the position within the string to start
searching from (also known as the base). By default, starts searching from the
beginning of the string. This method returns a data type object to be determined
after execution.

=signature

index(Str $arg1, Num $arg2) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('unexplainable');

is_deeply $data->index('explain'), 2;

is_deeply $data->index('explain', 0), 2;

is_deeply $data->index('explain', 1), 2;

is_deeply $data->index('explain', 2), 2;

is_deeply $data->index('explain', 3), -1;

is_deeply $data->index('explained'), -1;

ok 1 and done_testing;
