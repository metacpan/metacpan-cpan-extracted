use strict;
use warnings;
use Test::More;
use Data::Shared qw(shared_get shared_set shared_exists shared_call);

sub mounted_or_fail {
    my ($root, $name, @spec) = @_;
    return 1 if eval { $root->mount($name, @spec); 1 };
    my $err = $@;
    fail "mounting '$spec[0]' failed: $err"
        unless $err =~ /is not available; install the|Can't locate \S+\.pm/;
    return 0;
}

subtest 'hyperloglog call only' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('visitors', 'hyperloglog', undef, 14) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_call($r, '/visitors', 'add', 'alice');
    shared_call($r, '/visitors', 'add', 'bob');
    shared_call($r, '/visitors', 'add', 'alice');
    cmp_ok shared_call($r, '/visitors', 'count'), '>=', 1, 'count at least 1';
    cmp_ok shared_call($r, '/visitors', 'count'), '<=', 3, 'count at most 3';
    ok !eval { shared_get($r, '/visitors/alice'); 1 }, 'hll keyed get croaks';
    like $@, qr/use shared_call/, 'guidance';
};

subtest 'countminsketch keyed verbs' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('freq', 'countminsketch', undef, 0.001, 0.001) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/freq/alice', 5);
    shared_set($r, '/freq/bob');
    cmp_ok shared_get($r, '/freq/alice'), '>=', 5, 'estimate at least true';
    ok shared_exists($r, '/freq/alice'), 'exists';
    cmp_ok shared_get($r, '/freq/bob'), '>=', 1, 'a valueless set counts one';
    ok shared_exists($r, '/freq/bob'), 'and the key is there';
};

subtest 'topk keyed verbs' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('hitters', 'topk', undef, 100) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/hitters/popular');
    shared_set($r, '/hitters/popular');
    cmp_ok shared_get($r, '/hitters/popular'), '>=', 1, 'estimate';
    my @top = shared_call($r, '/hitters', 'top', 10);
    ok @top >= 1 && $top[0]{key} eq 'popular', 'top via call';
};

subtest 'ddsketch and histogram call only' => sub {
    my $r = Data::Shared->new;
    my $ok1 = mounted_or_fail($r, 'dd', 'ddsketch', undef, 0.01);
    my $ok2 = mounted_or_fail($r, 'hist', 'histogram', undef, 1, 3600000000, 3);
    if (!$ok1 && !$ok2) { plan skip_all => "backends unavailable"; return }
    if ($ok1) {
        shared_call($r, '/dd', 'add', $_) for (10, 20, 30);
        ok defined shared_call($r, '/dd', 'quantile', 0.5), 'dd quantile';
    }
    if ($ok2) {
        shared_call($r, '/hist', 'record', 120);
        ok shared_call($r, '/hist', 'total_count') >= 1, 'hist total';
    }
};

subtest 'minhash and reservoir call only' => sub {
    my $r = Data::Shared->new;
    my $ok1 = mounted_or_fail($r, 'mh', 'minhash', undef, 256);
    my $ok2 = mounted_or_fail($r, 'rsv', 'reservoir', undef, 100);
    if (!$ok1 && !$ok2) { plan skip_all => "backends unavailable"; return }
    if ($ok1) {
        shared_call($r, '/mh', 'add', 'a');
        is shared_call($r, '/mh', 'size'), 256, 'minhash size via call';
    }
    if ($ok2) {
        shared_call($r, '/rsv', 'add', $_) for 1 .. 10;
        is shared_call($r, '/rsv', 'seen'), 10, 'reservoir seen';
    }
};

subtest 'sync semaphore call only' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('sem', 'sync:semaphore', undef, 2) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    ok shared_call($r, '/sem', 'try_acquire'), 'try_acquire';
    shared_call($r, '/sem', 'release');
    ok !eval { shared_get($r, '/sem'); 1 }, 'sync get croaks';
    like $@, qr/use shared_call/, 'sync guidance';
};

subtest 'timingwheel call only' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('tw', 'timingwheel', undef, 512, 1000) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    my $id = shared_call($r, '/tw', 'add', 5, 1234);
    ok defined $id, 'timer id';
    my @due = shared_call($r, '/tw', 'advance', 5);
    ok((grep { $_ == 1234 } @due), 'timer fired');
};

done_testing;
