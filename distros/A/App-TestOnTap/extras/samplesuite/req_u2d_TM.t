use strict;
use warnings;

use Test::More;

plan(skip_all => "The Test::More version is too old: $Test::More::VERSION < 0.88") if $Test::More::VERSION < 0.88;
 
plan(tests => 1);

pass($0);

done_testing();
