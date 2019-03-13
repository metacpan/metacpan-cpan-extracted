use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

matched

=usage

  my $matched = $result->matched();

=description

The matched method returns the portion of the string that matched from the
result object which contains information about the results of the regular
expression operation.

=signature

matched() : DoStr | DoUndef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Replace';

my $data = Data::Object::Replace->new(['(?^:(test))', 'best case', 1, [ '0', '0' ], [ '4', '4' ], {}, 'test case']);

is_deeply $data->matched(), 'test';

ok 1 and done_testing;
