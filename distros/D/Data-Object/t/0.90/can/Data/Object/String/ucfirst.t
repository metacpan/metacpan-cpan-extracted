use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ucfirst

=usage

  # given 'exciting'

  $string->ucfirst; # Exciting

=description

The ucfirst method returns a the string with the first character uppercased.
This method returns a string value.

=signature

uc() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->ucfirst(), 'Hello world';

ok 1 and done_testing;
