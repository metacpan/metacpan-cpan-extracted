use strict;
use warnings;

use Test::More;

my $pkg = 'Data::PatternCompare';

use_ok($pkg);

my $obj = new_ok($pkg);

isa_ok($obj, $pkg);

can_ok($obj, qw|pattern_match compare_pattern|);

done_testing;
