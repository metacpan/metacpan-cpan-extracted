use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Cache::Memory::Simple;
use Cache::Escalate;

subtest "invalid caches" => sub {
    like exception {
        Cache::Escalate->new( caches => undef );
    }, qr{One more caches required};

    like exception {
        Cache::Escalate->new( caches => [] );
    }, qr{One more caches required};

    like exception {
        Cache::Escalate->new( caches => "foo" );
    }, qr{One more caches required};

    like exception {
        Cache::Escalate->new( caches => ["foo"] );
    }, qr{invalid object};

    like exception {
        Cache::Escalate->new( caches => [bless {}] );
    }, qr{invalid object};

    like exception {
        Cache::Escalate->new( caches => [Cache::Memory::Simple->new(), bless {}] );
    }, qr{invalid object};
};

subtest "set" => sub {
    my $cache1 = Cache::Memory::Simple->new();
    my $cache2 = Cache::Memory::Simple->new();

    my $ce = Cache::Escalate->new( caches => [$cache1, $cache2] );
    $ce->set("foo", "hoge");

    is $cache1->get("foo"), "hoge";
    is $cache2->get("foo"), "hoge";
};

subtest "get sync_level=none" => sub {
    my $caches = prepare_caches();
    my $ce = Cache::Escalate->new(
        caches     => $caches,
        sync_level => $Cache::Escalate::SYNC_LEVEL_NONE,
    );

    $caches->[1]->set("foo", 1);

    is $ce->get("foo"), 1;
    is $caches->[0]->get("foo"), undef;
    is $caches->[1]->get("foo"), 1;
    is $caches->[2]->get("foo"), undef;
};

subtest "get sync_level=missed" => sub {
    my $caches = prepare_caches();
    my $ce = Cache::Escalate->new(
        caches     => $caches,
        sync_level => $Cache::Escalate::SYNC_LEVEL_MISSED,
    );

    $caches->[1]->set("foo", 1);

    is $ce->get("foo"), 1;
    is $caches->[0]->get("foo"), 1;
    is $caches->[1]->get("foo"), 1;
    is $caches->[2]->get("foo"), undef;
};

subtest "sync_level=full" => sub {
    my $caches = prepare_caches();
    my $ce = Cache::Escalate->new(
        caches     => $caches,
        sync_level => $Cache::Escalate::SYNC_LEVEL_FULL,
    );

    $caches->[1]->set("foo", 1);

    is $ce->get("foo"), 1;
    is $caches->[0]->get("foo"), 1;
    is $caches->[1]->get("foo"), 1;
    is $caches->[2]->get("foo"), 1;
};

subtest "delete" => sub {
    my $caches = prepare_caches();
    my $ce = Cache::Escalate->new(
        caches => $caches,
    );

    $_->set("foo", 1) for @$caches;

    $ce->delete("foo");

    is $_->get("foo"), undef for @$caches;
};

sub prepare_caches {
    return [
        Cache::Memory::Simple->new(),
        Cache::Memory::Simple->new(),
        Cache::Memory::Simple->new(),
    ];
}

done_testing;
