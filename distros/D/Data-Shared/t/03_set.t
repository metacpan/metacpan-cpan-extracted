use strict;
use warnings;
use Test::More;
use Data::Shared qw(shared_get shared_set shared_delete shared_exists shared_call);

subtest 'bloomfilter' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('seen', 'bloomfilter', undef, 10000, 0.01) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/seen/alice', 1);
    ok shared_exists($r, '/seen/alice'), 'contains';
    is shared_get($r, '/seen/alice'), 1, 'get is contains';
    is shared_exists($r, '/seen/carol'), 0, 'absent';
    ok !eval { shared_delete($r, '/seen/alice'); 1 }, 'bloom delete croaks honestly';
    like $@, qr/not supported.*shared_call/, 'delete guidance';
};

subtest 'counting bloom and cuckoo delete' => sub {
    my $r = Data::Shared->new;
    my $ok1 = eval { $r->mount('cbf', 'countingbloomfilter', undef, 10000, 0.01); 1 };
    my $why1 = $@;
    my $ok2 = eval { $r->mount('cf', 'cuckoofilter', undef, 10000); 1 };
    my $why2 = $@;
    for my $probe ([$ok1, $why1, 'countingbloomfilter'], [$ok2, $why2, 'cuckoofilter']) {
        my ($ok, $why, $what) = @$probe;
        next if $ok;
        fail "$what mount failed: $why"
            if $why !~ /is not available; install the|Can't locate \S+\.pm/;
    }
    if (!$ok1 && !$ok2) { plan skip_all => "backends unavailable"; return }
    if ($ok1) {
        shared_set($r, '/cbf/x', 1); shared_set($r, '/cbf/x', 1);
        is shared_get($r, '/cbf/x'), 2, 'counting get is count_of';
        shared_delete($r, '/cbf/x');
        ok shared_exists($r, '/cbf/x'), 'one copy remains';
    }
    if ($ok2) {
        shared_set($r, '/cf/y', 1);
        ok shared_exists($r, '/cf/y'), 'cuckoo contains';
        shared_delete($r, '/cf/y');
        is shared_exists($r, '/cf/y'), 0, 'cuckoo removed';
    }
};

subtest 'bitset' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('bits', 'bitset', undef, 256) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/bits/10', 1);
    is shared_get($r, '/bits/10'), 1, 'test set bit';
    is shared_get($r, '/bits/11'), 0, 'test clear bit';
    shared_set($r, '/bits/10', 0);
    is shared_get($r, '/bits/10'), 0, 'falsy set clears';
    shared_set($r, '/bits/42', 1);
    shared_delete($r, '/bits/42');
    is shared_get($r, '/bits/42'), 0, 'delete clears';
    is shared_call($r, '/bits', 'count'), 0, 'count via call';
};

subtest 'roaringbitmap' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('m', 'roaringbitmap', undef, 256) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/m/70000', 1);
    ok shared_exists($r, '/m/70000'), 'contains';
    shared_delete($r, '/m/70000');
    is shared_exists($r, '/m/70000'), 0, 'removed';
};

subtest 'sortedset' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('board', 'sortedset', undef, 1000) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/board/42', 1500);
    is shared_get($r, '/board/42'), 1500, 'score';
    ok shared_exists($r, '/board/42'), 'exists';
    shared_delete($r, '/board/42');
    is shared_exists($r, '/board/42'), 0, 'removed';
};

subtest 'disjointset' => sub {
    my $r = Data::Shared->new;
    eval { $r->mount('ds', 'disjointset', undef, 100) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/ds/0', 1);
    is shared_get($r, '/ds/0'), shared_get($r, '/ds/1'), 'union via set, find via get';
    ok shared_exists($r, '/ds/0'), 'exists in range';
    is shared_exists($r, '/ds/9999'), 0, 'exists out of range';
    is shared_call($r, '/ds', 'connected', 0, 1), 1, 'connected via call';
};

done_testing;
