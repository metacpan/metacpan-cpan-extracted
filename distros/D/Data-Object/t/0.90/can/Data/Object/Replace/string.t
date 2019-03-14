use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

string

=usage

  my $string = $result->string();

=description

The string method returns the string matched against the regular expression
from the result object which contains information about the results of the
regular expression operation.

=signature

string() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Replace';

my $data = Data::Object::Replace->new(['(?^:test)', 'best case', 1, [ '0' ], [ '4' ], {}, 'test case']);

is_deeply $data->string(), 'best case';

ok 1 and done_testing;
