use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lc

=usage

  # given 'EXCITING'

  $string->lc; # exciting

=description

The lc method returns a lowercased version of the string. This method returns a
string object. This method is an alias to the lowercase method.

=signature

lc() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('HELLO WORLD');

is_deeply $data->lc(), 'hello world';

ok 1 and done_testing;
