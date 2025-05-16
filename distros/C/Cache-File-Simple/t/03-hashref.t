use 5.006;
use strict;
use warnings;
use Test::More;
use Cache::File::Simple;

my $key = "foo";

# Init the cache
cache($key, {'one' => 1, 'two' => 'dos', 'three' => 'III'});

# Get
my $ret = cache($key);

is(scalar(keys %$ret), 3);
is($ret->{'two'}, 'dos');

# Set with expiration
cache($key, {'one' => 1, 'two' => 'dos'}, time() + 3600);
ok(defined(cache($key)));

# Set with expired cache time
cache($key, {'one' => 1, 'two' => 'dos'}, time() - 3600);
is(cache($key), undef);

done_testing();
