use strict;
use warnings;
use Test::More;
use Cache::LRU::WithExpires;
use Time::HiRes qw(sleep);

subtest 'avalivele' => sub {
    my $cache = Cache::LRU::WithExpires->new;
    $cache->set('foo', 'bar', 1);
    is $cache->get('foo'), 'bar';
};

subtest 'expires' => sub {
    my $cache = Cache::LRU::WithExpires->new;
    $cache->set('foo', 'bar', 0.1);
    sleep 0.2;
    is $cache->get('foo'), undef;
};

subtest 'no expires' => sub {
    my $cache = Cache::LRU::WithExpires->new;
    $cache->set('foo', 'bar');
    sleep 0.1;
    is $cache->get('foo'), 'bar';
};

subtest '0 equals to no expires' => sub {
    my $cache = Cache::LRU::WithExpires->new;
    $cache->set('foo', 'bar', 0);
    sleep 0.1;
    is $cache->get('foo'), 'bar';
};

subtest 'minus' => sub {
    my $cache = Cache::LRU::WithExpires->new;
    $cache->set('foo', 'bar', -10);
    is $cache->get('foo'), undef;
};

done_testing;
