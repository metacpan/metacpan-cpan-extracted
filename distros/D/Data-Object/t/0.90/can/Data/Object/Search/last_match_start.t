use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

last_match_start

=usage

  my $last_match_start = $result->last_match_start();

=description

The last_match_start method returns an array of offset positions into the
string where the capture(s) matched from the result object which contains
information about the results of the regular expression operation.

=signature

last() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Search';

my $data = Data::Object::Search->new(['(?^:(test))', 'best case', 1, [ '0', '0' ], [ '4', '4' ], {}, 'test case']);

is_deeply $data->last_match_start(), [0,0];

ok 1 and done_testing;
