use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create({
    min_version => '1.4.4',
    behavior_support_cas => 1,
});

plan skip_all => "cas() unimplemented";

plan tests => 5;

my @keys = ('a' .. 'z');
$cache->set($_, $_) for @keys;
my $cas = $cache->get_cas('a');
ok($cas);

my $h = $cache->get_cas_multi(@keys);
ok($h);
isa_ok($h, 'HASH');

is($h->{a}, $cas);

TODO: {
local $TODO = "cas() unconfirmed";
my $newvalue = 'this used to be a';
$cache->cas('a', $cas, $newvalue);
is($cache->get('a'), $newvalue);
}
