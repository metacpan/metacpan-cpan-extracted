use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

initial

=usage

  my $initial = $result->initial();

=description

The initial method returns the unaltered string from the result object which
contains information about the results of the regular expression operation.

=signature

initial() : DoStr

=type

method

=cut

# TESTING

use_ok 'Data::Object::Replace';

my $data = Data::Object::Replace->new(['(?^:(test))', 'best case', 1, [ '0', '0' ], [ '4', '4' ], {}, 'test case']);

is_deeply $data->initial(), 'test case';

ok 1 and done_testing;
