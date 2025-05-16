use 5.006;
use strict;
use warnings;
use Test::More;
use Cache::File::Simple;

my $key = "foo";
my $val = "bar";

# Init the cache
cache($key, undef); # Clear cache

is(cache($key), undef);                # Get empty value
is(cache($key , $val, time() + 1), 1); # Set value for two seconds
is(cache($key), "bar");                # Fetch value we just set

print "Sleeping a couple seconds to let cache expire\n";
sleep(2);

is(cache($key), undef); # Entry should be expired now

# Expired time should return undef
cache($key, 'donk', time() - 3600);
is(cache($key), undef);

done_testing();
