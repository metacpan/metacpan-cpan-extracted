use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rindex

=usage

  # given 'explain the unexplainable'

  $string->rindex('explain'); # 14
  $string->rindex('explain', 0); # 0
  $string->rindex('explain', 21); # 14
  $string->rindex('explain', 22); # 14
  $string->rindex('explain', 23); # 14
  $string->rindex('explain', 20); # 14
  $string->rindex('explain', 14); # 0
  $string->rindex('explain', 13); # 0
  $string->rindex('explain', 0); # 0
  $string->rindex('explained'); # -1

=description

The rindex method searches for the argument within the string and returns the
position of the last occurrence of the argument. This method optionally takes a
second argument which would be the position within the string to start
searching from (beginning at or before the position). By default, starts
searching from the end of the string. This method returns a data type object to
be determined after execution.

=signature

rindex(Str $arg1, Num $arg2) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('explain the unexplainable');

is_deeply $data->rindex('explain'), 14;

is_deeply $data->rindex('explain', 0), 0;

is_deeply $data->rindex('explain', 21), 14;

is_deeply $data->rindex('explain', 22), 14;

is_deeply $data->rindex('explain', 23), 14;

is_deeply $data->rindex('explain', 20), 14;

is_deeply $data->rindex('explain', 14), 14;

is_deeply $data->rindex('explain', 13), 0;

is_deeply $data->rindex('explain', 0), 0;

is_deeply $data->rindex('explained'), -1;

ok 1 and done_testing;
