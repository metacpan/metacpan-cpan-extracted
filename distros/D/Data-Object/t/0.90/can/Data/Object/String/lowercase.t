use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lowercase

=usage

  # given 'EXCITING'

  $string->lowercase; # exciting

=description

The lowercase method is an alias to the lc method. This method returns a
string object.

=signature

lowercase() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hEllO World');

is_deeply $data->lowercase(), 'hello world';

ok 1 and done_testing;
