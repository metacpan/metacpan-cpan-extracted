use lib 't';

use utf8;
use Test::Most 0.22;
use Test::FailWarnings;
use Date::Utility;
use JSON::MaybeXS;
use RedisServer;
use Cache::RedisDB;
use strict;
use version;

my $server = RedisServer->start;
plan(skip_all => "Can't start redis-server") unless $server;

$ENV{REDIS_CACHE_SERVER} = 'localhost:' . $server->{port};

my $cache = Cache::RedisDB->redis;

plan(skip_all => 'Redis Server Not Found')                     unless $cache;
plan(skip_all => "Test requires redis-server at least 1.3.15") unless $cache->version ge 1.003015;

diag "Redis server version: " . $cache->info->{redis_version};

my @version            = split(/\./, $cache->info->{redis_version});
my $sufficient_version = (version->parse($cache->info->{redis_version}) > version->parse("2.6.12")) ? 1 : 0;

plan(skip_all => 'Skipping full cache test due to Redis being below 2.6.12')
    unless $sufficient_version;
$cache->flushdb;

isa_ok($cache, 'RedisDB', "RedisDB is used for cache");
can_ok($cache, 'flushall');

my $cache2 = Cache::RedisDB->redis;
is $cache2, $cache, "Got the same cache object";

my $now     = Date::Utility->new;
my @now_exp = ($now->year, $now->month, $now->second, $now->timezone);

if (fork) {
    wait;
    is $?, 0, "Child tests passed";
} else {
    my $child  = Test::More->builder->child("forked process");
    my $cache3 = Cache::RedisDB->redis;
    $child->ok(Cache::RedisDB->set("Test", "key1", "value1"),        "Set Test::key1");
    $child->ok(Cache::RedisDB->set_nw("", "Testkey1", "testvalue1"), "Set Testkey1 (no wait version)");
    $child->ok(Cache::RedisDB->set("-", "-", "-- it works! 它的工程！"),  "Set dash prefixed string");
    SKIP: {
        skip 'Redis 2.6.12 or higher', 2 unless $sufficient_version;
        $child->ok(
            Cache::RedisDB->set(
                "Hash", "Ref",
                {
                    a => 1,
                    b => 2,
                    c => "你好",
                }
            ),
            "Set Hash::Ref"
        );
        $child->ok(Cache::RedisDB->set("Date", "Utility", $now), "Set Date::Utility");
    }
    $child->is_eq(Cache::RedisDB->get("Test", "key1"), "value1", "Got value1 for Test::key1");
    $child->ok($child->is_passing, 'Child is passing, new test to track down concurrency issues');
    die unless $child->is_passing;
    exit 0;
}

my $cache3 = Cache::RedisDB->redis;
is $cache3, $cache, "Got the same cache object again in the parent";
my $new_cache = Cache::RedisDB->redis_connection;
isa $new_cache, 'RedisDB';
isnt $new_cache, $cache, "Got new cache object";

ok(Cache::RedisDB->set("Test", "TTL", "I will expire", 60), "Set TTL test key for 60 second expiration.");
is(Cache::RedisDB->get("Test", "key1"), "value1", "Got value1 for Test::key1");
is(Cache::RedisDB->ttl("Test", "key1"), 0,        "Unexpiring key Test::key1 appears to expire now.");
eq_or_diff([sort @{Cache::RedisDB->keys("Test")}], [sort "TTL", "key1"], "Got correct arrayref for keys in Test namespace");
is(Cache::RedisDB->del("Test", "key33", "key8", "key1"), 1, "Deleted Test::key1");
is(Cache::RedisDB->get("Test", "key1"),     undef,                "Got undef for Test::key1");
is(Cache::RedisDB->get("",     "Testkey1"), "testvalue1",         "Got testvalue1 for Testkey1");
is(Cache::RedisDB->get("-",    "-"),        "-- it works! 它的工程！", "Got dash prefixed string");
ok(Cache::RedisDB->set("Test", "Undef", undef), "Set undef");
ok(Cache::RedisDB->set("Test", "Empty", ""),    "Set empty string");
eq_or_diff([sort @{Cache::RedisDB->keys("Test")}], [sort "TTL", "Undef", "Empty"], "Got correct arrayref for keys in Test namespace");
is(Cache::RedisDB->get("Test", "Undef"), undef, "Got undef");
is(Cache::RedisDB->get("Test", "Empty"), "",    "Got empty string");

SKIP: {
    skip 'Redis 2.6.12 or higher', 2 unless $sufficient_version;
    eq_or_diff(
        Cache::RedisDB->get("Hash", "Ref"),
        {
            a => 1,
            b => 2,
            c => "你好",
        },
        "Got hash from the cache"
    );
    my $now2 = Cache::RedisDB->get("Date", "Utility");
    eq_or_diff [$now2->year, $now2->month, $now2->second, $now2->timezone], \@now_exp, "Got correct Date::Time object from cache";

}

is(Cache::RedisDB->get("NonExistent", "Key"), undef, "Got undef value for non-existing key");

ok(Cache::RedisDB->set("This",      "expires", "In a second", 1),   "Set with expire");
ok(Cache::RedisDB->set("Even this", "键",       "Oops...",     0.5), "Spaces and utf8 in keys are Ok");
is(Cache::RedisDB->get("Even this", "键"), "Oops...", "Got value for unicode key");
sleep 1;
is(Cache::RedisDB->get("Even this", "键"), undef, "unicode key value expired in 1s");
cmp_ok(Cache::RedisDB->ttl('Test', 'TTL'),  '<=', 59, 'Our TTL key still exists and expiring in the future');
cmp_ok(Cache::RedisDB->ttl('Test', 'TTL2'), '==', 0,  'Our non-existent TTL key expires "now"');

$cache->set("Test::Number", -33);
is(Cache::RedisDB->get("Test", "Number"), -33, "Got negative number from cache");
ok(Cache::RedisDB->set("Test", "Num2", -55), "Set negative number");
is($cache->get("Test::Num2"), -55, "It is stored as number");

subtest 'JSON' => sub {
    plan tests => 6;
    SKIP: {
        skip 'Redis 2.6.12 or higher', 6 unless $sufficient_version;
        my $json_string = '{"should_be_true" : true, "should_be_false" : false}';
        my $json_obj    = JSON::MaybeXS->new->decode($json_string);
        ok($json_obj->{should_be_true},                     'True is true');
        ok(!$json_obj->{should_be_false},                   'False is false');
        ok(Cache::RedisDB->set('Test', 'JSON', $json_obj),  'Stored JSON successfully');
        ok($json_obj = Cache::RedisDB->get('Test', 'JSON'), 'Retrieved JSON successfully');
        ok($json_obj->{should_be_true},                     'True is true');
        ok(!$json_obj->{should_be_false},                   'False is false');
    }
};

is(Cache::RedisDB->flushall, 'OK', "Flushed DB");
eq_or_diff(Cache::RedisDB->keys("Test"), [], "Got empty arrayref for keys in Test namespace");
is(Cache::RedisDB->get("Test", "Num2"), undef, "Really flushed");

ok(Cache::RedisDB->set('mget_ns', 'one',   1), 'set first key');
ok(Cache::RedisDB->set('mget_ns', 'two',   2), 'set second key');
ok(Cache::RedisDB->set('mget_ns', 'three', 3), 'set third key');
ok(Cache::RedisDB->set('mget_ns', 'four',  4), 'set fourth key');
is_deeply(Cache::RedisDB->mget('mget_ns', qw(one two cats three four)), [qw(1 2), undef, qw(3 4)], 'could read keys via ->mget');
done_testing;
