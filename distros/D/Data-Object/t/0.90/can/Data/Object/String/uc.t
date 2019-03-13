use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

uc

=usage

  # given 'exciting'

  $string->uc; # EXCITING

=description

The uc method returns an uppercased version of the string. This method returns a
string object. This method is an alias to the uppercase method.

=signature

uc() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->uc(), 'HELLO WORLD';

ok 1 and done_testing;
