use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Algorithm::LibLinear::DataSet' }

my $source = do { local $/; <DATA> };
my $data_set = Algorithm::LibLinear::DataSet->load(string => $source);

is $data_set->size, 5;
is $data_set->as_string, $source;

done_testing;

__DATA__
1 2:0.1 3:0.2
1 2:0.1 3:0.3 4:-1.2
-1 1:0.4
-1 1:0.1 4:1.4 5:0.5
-1 1:-0.1 2:-0.2 3:0.1 4:1.1 5:0.1
