use strict;
use warnings;
use utf8;
use Test::More;
use Cache::Memory::Simple;
use Time::HiRes qw//;

subtest 'available' => sub {
    my $cache = Cache::Memory::Simple->new(use_time_hires=>1);
    $cache->set('foo', 'bar', 0.5);
    Time::HiRes::sleep 0.2;
    is $cache->get('foo'), 'bar';
};

subtest 'expires' => sub {
    my $cache = Cache::Memory::Simple->new(use_time_hires=>1);
    $cache->set('foo', 'bar', 0.1);
    Time::HiRes::sleep 0.2;
    is $cache->get('foo'), undef;
};

done_testing;

