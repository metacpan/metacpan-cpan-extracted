use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

replace

=usage

  # given qr(test)

  $re->replace('this is a test', 'drill');
  $re->replace('test 1 test 2 test 3', 'drill', 'gi');

=description

The replace method performs a regular expression substitution on the given
string. The first argument is the string to match against. The second argument
is the replacement string. The optional third argument might be a string
representing flags to append to the s///x operator, such as 'g' or 'e'.  This
method will always return a L<Data::Object::Replace> object which can be
used to introspect the result of the operation.

=signature

replace(Str $arg1, Str $arg2) : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::Regexp';

my $data = Data::Object::Regexp->new(qr/test/);

is_deeply $data->replace('test case', 'best')->string, 'best case';

ok 1 and done_testing;
