use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

words

=usage

  # given "is this a bug we're experiencing"

  $string->words; # ["is","this","a","bug","we're","experiencing"]

=description

The words method splits the string into a list of strings, separating each
group of characters by 1 or more consecutive spaces, and returns that list as an
array reference. This method returns an array value.

=signature

words() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->words(), ['hello', 'world'];

ok 1 and done_testing;
