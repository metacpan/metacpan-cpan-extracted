use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok("Cache::LRU");
};

my $cache = Cache::LRU->new(
    size => 3,
);

ok ! defined $cache->get('a');

is $cache->set(a => 1), 1;
is $cache->get('a'), 1;

is $cache->set(b => 2), 2;
is $cache->get('a'), 1;
is $cache->get('b'), 2;

is $cache->set(c => 3), 3;
is $cache->get('a'), 1;
is $cache->get('b'), 2;
is $cache->get('c'), 3;

is $cache->set(b => 4), 4;
is $cache->get('a'), 1;
is $cache->get('b'), 4;
is $cache->get('c'), 3;

my $keep;
is +($keep = $cache->get('a')), 1; # the order is now a => c => b
is $cache->set(d => 5), 5;
is $cache->get('a'), 1;
ok ! defined $cache->get('b');
is $cache->get('c'), 3;
is $cache->get('d'), 5; # the order is now d => c => a

is $cache->set('e', 6), 6;
ok ! defined $cache->get('a');
ok ! defined $cache->get('b');
is $cache->get('c'), 3;
is $cache->get('d'), 5;
is $cache->get('e'), 6;

is $cache->remove('d'), 5;
is $cache->get('c'), 3;
ok ! defined $cache->get('d');
is $cache->get('e'), 6;

$cache->clear;
ok ! defined $cache->get('c');
ok ! defined $cache->get('e');

done_testing;
