use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

captures

=usage

  my $captures = $result->captures();

=description

The captures method returns the capture groups from the result object which
contains information about the results of the regular expression operation.

=signature

captures() : DoArray

=type

method

=cut

# TESTING

use_ok 'Data::Object::Search';

my $data = Data::Object::Search->new(['(?^:(test))', 'best case', 1, [ '0', '0' ], [ '4', '4' ], {}, 'test case']);

is_deeply $data->captures(), ['test'];

ok 1 and done_testing;
