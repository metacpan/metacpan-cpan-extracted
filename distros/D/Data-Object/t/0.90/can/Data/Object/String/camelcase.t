use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

camelcase

=usage

  # given 'hello world'

  $string->camelcase; # HelloWorld

=description

The camelcase method modifies the string such that it will no longer have any
non-alphanumeric characters and each word (group of alphanumeric characters
separated by 1 or more non-alphanumeric characters) is capitalized. Note, this
method modifies the string. This method returns a L<Data::Object::String>
object.

=signature

camelcase() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->camelcase(), 'HelloWorld';

ok 1 and done_testing;
