use 5.006;
use strict;
use warnings;
use Test::More;
use Cache::File::Simple;

my $key = "foo";

# Init the cache
cache($key, [1,2,3,4,5,9]);

# Get
my $ret = cache($key);

is(scalar(@$ret), 6);
is($ret->[5], 9);

done_testing();
