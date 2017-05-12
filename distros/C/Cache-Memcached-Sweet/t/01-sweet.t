#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;



if ($ENV{MEMCACHED_TESTS}) {
	plan tests => 7;
} else {
	plan skip_all => 'Need to set MEMCACHED_TESTS => 1 to actually test against memcached'

}

use_ok('Cache::Memcached::Sweet');


my $struct = { hey =>'ho',"yo"=>2};
my $key1 = "TEST:abc".$$;
my $key2 = "TEST:cbc".$$;

my $key = { ab => 1, bc => 2 };

my $number = 0;
my $subref = sub { 42 + $number; };


is(ref(memcached()),'Cache::Memcached');

memcached()->delete($key1);
memcached()->delete($key2);

memcached($key1, $struct, 90);

is(memcached($key1)->{hey}, 'ho');



is(memcached($key2, $subref, 900), 42, 'setting and returning value');
$number++;
is(memcached($key2, $subref, 900), 42, 'closure should still return cached value'); # should still be 42
$number++;
is(memcached($key2, $subref, 900), 42, 'closure should still return cached value again'); # should still be 42

my $e2 = memcached($key2);
is($e2,42);


done_testing;





