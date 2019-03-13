use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

postmatched

=usage

  my $postmatched = $result->postmatched();

=description

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=signature

postmatched() : DoStr | DoUndef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Search';

my $data = Data::Object::Search->new(['(?^:(test))', 'best case', 1, [ '0', '0' ], [ '4', '4' ], {}, 'test case']);

is_deeply $data->postmatched(), ' case';

ok 1 and done_testing;
