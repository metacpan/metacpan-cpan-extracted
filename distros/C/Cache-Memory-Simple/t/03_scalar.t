use strict;
use warnings;
use utf8;
use Test::More;
use Test::Time time => 1;
use Cache::Memory::Simple::Scalar;
use Time::HiRes qw//;

{
    # CORE::GLOBAL::time() is overrided by Test::Time and use it
    no warnings;
    *Time::HiRes::time = sub { time() };
}

subtest 'get/set' => sub {
    my $cache = Cache::Memory::Simple::Scalar->new();
    is($cache->get(), undef);
    $cache->set('abc');
    is($cache->get(), 'abc');
    sleep 10;
    is($cache->get(), 'abc');
};

subtest 'get/set expiration' => sub {
    my $cache = Cache::Memory::Simple::Scalar->new();
    is($cache->get(), undef);
    $cache->set('abc', 3);
    is($cache->get(), 'abc');
    sleep 10;
    is($cache->get(), undef);
    is($cache->get(), undef, 'run twice');
};

subtest 'delete expiration' => sub {
    my $cache = Cache::Memory::Simple::Scalar->new();
    is($cache->get(), undef);
    $cache->set('abc', 3);
    is($cache->get(), 'abc');
    $cache->delete();
    is($cache->get(), undef, 'removed');
};

done_testing;

