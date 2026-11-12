use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_exists shared_push);

my $probe = Data::Shared->new(tempdir(CLEANUP => 1));
eval { $probe->mount('p', ['hashmap:ss', 64, ['hashmap:ss', 8], { max_children => 64 }]); 1 }
    or plan skip_all => "composite backends unavailable: $@";

sub store {
    my (%o) = @_;
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('cache', 'hashmap:ii', undef, 64);
    $root->mount('users', ['hashmap:ss', 256, ['hashmap:ss', 8],
                           { max_children => 256, %{ $o{opts} || {} } }]);
    shared_set($root, "/users/u$_/k", 1) for 1 .. ($o{children} || 1);
    return ($root, $dir);
}

# A child outside the open-child cache is reopened to be frozen, and a frozen
# file refuses the writable constructor.
subtest 'freeze_all is idempotent past the child cache' => sub {
    my ($root) = store(children => 40);                 # default cache_size 32
    cmp_ok $root->freeze_all, '>=', 42, 'first pass seals children, parent and index';
    is $root->freeze_all, 0, 'second pass seals nothing and does not croak';
    is $root->freeze_all, 0, 'and stays idempotent';
};

subtest 'a child frozen directly does not block the walk' => sub {
    my ($root, $dir) = store(children => 1, opts => { cache_size => 1 });
    $root->node('/users/u1')->call('freeze');
    shared_set($root, '/users/u2/k', 1);                # evicts u1
    cmp_ok $root->freeze_all, '>=', 1, 'freeze_all completes over the frozen child';
    ok $root->frozen, 'and reports the store sealed';
    undef $root;
    my $ro = Data::Shared->open_readonly($dir);
    is shared_get($ro, '/users/u1/k'), 1, 'shipped store reads the frozen child';
};

subtest 'the sealing root can still read every child' => sub {
    my ($root) = store(children => 5, opts => { cache_size => 2 });
    $root->freeze_all;
    for my $i (1 .. 5) {
        is shared_get($root, "/users/u$i/k"), 1, "u$i reads after sealing";
        is shared_exists($root, "/users/u$i/k"), 1, "u$i exists answers 1, not a croak";
    }
    my $dir = tempdir(CLEANUP => 1);
    {
        my $producer = Data::Shared->new($dir);
        $producer->mount('u', ['hashmap:ss', 64, ['hashmap:ss', 8]]);
        shared_set($producer, '/u/a/k', 1);
        $producer->freeze_all;
    }
    ok !eval { Data::Shared->open($dir); 1 }, 'a writable reopen of a sealed store is still refused';
    like $@, qr/is frozen \(read-only\)/, 'by the leaf, for the reason that matters';
    ok eval { Data::Shared->open_readonly($dir); 1 }, 'and a read-only one works';
};

subtest 'frozen reports whether the store can be shipped' => sub {
    my ($root) = store(children => 2);
    ok !$root->frozen, 'not frozen before';
    $root->freeze_all;
    ok $root->frozen, 'frozen after';
    is_deeply [$root->frozen], [1], 'and the answer is one boolean, not a list';

    my $mixed = Data::Shared->new(tempdir(CLEANUP => 1));
    $mixed->mount('cache', 'hashmap:ii', undef, 64);
    if (eval { require Data::Queue::Shared; 1 }) {
        $mixed->mount('jobs', 'queue:int', undef, 8);
        $mixed->handle('/cache')->freeze;
        ok !$mixed->frozen, 'a store with an unfreezable mount is never shippable';
    }
    my $empty = Data::Shared->new(tempdir(CLEANUP => 1));
    ok !$empty->frozen, 'an empty store is not shippable';

    # freeze_all's 0 means already sealed or nothing sealable; frozen tells them apart.
    my ($sealed) = store(children => 1);
    $sealed->freeze_all;
    is $sealed->freeze_all, 0, 'sealed store seals nothing more';
    ok $sealed->frozen, 'and reports sealed';
};

subtest 'a transient mount is not part of the store frozen answers for' => sub {
    my ($root, $dir) = store(children => 1);
    $root->freeze_all;
    my $q = Data::Shared->new;
    plan skip_all => 'queue unavailable' unless eval { require Data::Queue::Shared; 1 };
    $q->mount('q', 'queue:int', undef, 8);
    $root->mount('jobs', $q->handle('/q'));
    ok $root->frozen, 'an unsealable handle the caller attached does not unship it';
    ok eval { Data::Shared->open_readonly($dir, strict => 1); 1 }, 'which strict reopening agrees with'
        or diag $@;
    my $only = Data::Shared->new;
    $only->mount('jobs', $q->handle('/q'));
    ok !$only->frozen, 'and transient mounts alone are an empty store';
};

subtest 'freeze_all leaves a transient handle to its owner' => sub {
    my $donor = Data::Shared->new;
    my $handle = $donor->mount('h', 'hashmap:ii', undef, 16);
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('cache', 'hashmap:ii', undef, 16);
    $root->mount('borrowed', $handle);
    is $root->freeze_all, 1, 'only the store\'s own mount is sealed and counted';
    ok !$handle->frozen, 'the borrowed handle is not';
    ok eval { shared_set($donor, '/h/1', 7); 1 }, 'so its owner still writes through it' or diag $@;
    ok $root->frozen, 'and the store reports itself sealed';
};

subtest 'freeze_all seals in mount order' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount("m$_", 'hashmap:ii', undef, 16) for 1 .. 6;
    shared_set($root, "/m$_/1", 1) for 1 .. 6;
    my $target = $root->{mounts}{m4}{handle};
    no warnings 'redefine';
    my $orig = \&Data::HashMap::Shared::II::freeze;
    local *Data::HashMap::Shared::II::freeze = sub {
        die "injected failure\n" if $_[0] == $target;
        $orig->(@_);
    };
    ok !eval { $root->freeze_all; 1 }, 'a failing mount aborts the pass';
    my @state = map { $root->{mounts}{"m$_"}{handle}->frozen ? 1 : 0 } 1 .. 6;
    is_deeply \@state, [1, 1, 1, 0, 0, 0], 'everything before it is sealed, nothing after';
    # The file's only partly sealed store: a frozen() that asked the first or
    # any one mount rather than all of them would pass every other check.
    ok !$root->frozen, 'and the store does not report itself sealed';
};

subtest 'freeze_all refuses a store it cannot seal whole' => sub {
    plan skip_all => 'queue unavailable' unless eval { require Data::Queue::Shared; 1 };
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('cache', 'hashmap:ii', undef, 16);
    $root->mount('jobs', 'queue:int', undef, 8);
    ok !eval { $root->freeze_all; 1 }, 'an unsealable mount is refused';
    like $@, qr/mount 'jobs' \(Data::Queue::Shared::Int\) cannot be sealed; nothing was frozen/,
        'naming the mount and its class';
    ok !$root->handle('/cache')->frozen, 'and the mount before it stays writable';
    $root->unmount('jobs');
    is $root->freeze_all, 1, 'without it the store seals';
    ok $root->frozen, 'and ships';

    my $comp = Data::Shared->new(tempdir(CLEANUP => 1));
    $comp->mount('cache', 'hashmap:ii', undef, 16);
    $comp->mount('q', ['hashmap:ss', 16, ['queue:int', 8]]);
    shared_push($comp, '/q/a', 1);
    ok !eval { $comp->freeze_all; 1 }, 'an unsealable composite level is refused';
    like $@, qr/mount 'q' \(Data::Queue::Shared::Int\)/, 'naming the mount and the level';
    my $c = $comp->{mounts}{q}{composite};
    ok !$comp->handle('/cache')->frozen && !$c->{parent_handle}->frozen && !$c->_index_frozen,
        'and nothing in the store is sealed';
};

# Entering the lifecycle lock clears a pending marker while the index is still
# writable, so this state needs the index handle to reach.
subtest 'a sealed index with a pending marker does not break the walk' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('org', ['hashmap:ss', 64, ['hashmap:ss', 64, ['hashmap:ss', 8]]]);
    shared_set($root, '/org/a/b/k', 1);
    my $inner = $root->{mounts}{org}{composite}{cache}{0}{comp};
    $inner->{index}->put('p:', 1);
    $inner->{index}->freeze;
    cmp_ok $root->freeze_all, '>=', 1, 'freeze_all completes';
    ok $root->frozen, 'and the store is sealed';
    undef $root;
    my $ro = Data::Shared->open_readonly($dir);
    is shared_get($ro, '/org/a/b/k'), 1, 'and ships';
};

subtest 'the rebuild guard does not depend on shippability' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    plan skip_all => 'queue backend unavailable'
        unless eval { $root->mount('q', ['hashmap:ss', 64, ['queue:int', 8]]); 1 };
    shared_push($root, '/q/a', 42);     # not node->push(42): that reads 42 as a path
    my $comp = $root->{mounts}{q}{composite};
    $comp->{index}->put('p:', 1);
    $comp->{index}->freeze;
    ok !$comp->frozen, 'the subtree is not shippable, because a level is not';
    ok eval { $root->stats; 1 }, 'but taking its lock does not try to repair the index' or diag $@;
};

subtest 'sync covers every registered child' => sub {
    my $calls = 0;
    my $orig = \&Data::HashMap::Shared::SS::sync;
    no warnings 'redefine';
    local *Data::HashMap::Shared::SS::sync = sub { $calls++; $orig->(@_) };

    my ($root) = store(children => 40);                 # default cache_size 32
    my $stats = $root->stats->{users};
    is $stats->{children}, 40, '40 children registered';
    # undef numifies to 0, which would pass the comparison below.
    ok defined $stats->{open}, 'the open-child counter is reported';
    cmp_ok $stats->{open}, '<', 40, 'and fewer than that are open';
    $calls = 0;
    my $n = $root->node('/users')->call('sync');
    is $n, 42, 'sync reports children plus parent and index';
    is $calls, 42, 'and really flushed that many';
};

subtest 'sync recurses into a child that is itself a composite' => sub {
    my $calls = 0;
    my $orig = \&Data::HashMap::Shared::SS::sync;
    no warnings 'redefine';
    local *Data::HashMap::Shared::SS::sync = sub { $calls++; $orig->(@_) };

    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('users', { spec => 'hashmap:ss', args => [128],
        child => { spec => 'hashmap:ss', args => [128],
                   child => { spec => 'hashmap:ss', args => [64] } },
        max_children => 32 });
    for my $u (qw(alice bob)) { shared_set($root, "/users/$u/$_/name", $_) for qw(x y) }
    $calls = 0;
    # Three composites give a parent and an index each, four leaves one handle each.
    is $root->node('/users')->call('sync'), 10, 'every level is reached';
    is $calls, 10, 'and really flushed that many';
};

subtest 'a shipped store opens read-only without its lock file' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $root = Data::Shared->new($dir);
        $root->mount('cache', 'hashmap:ss', undef, 8);
        shared_set($root, '/cache/k', 'v');
        $root->freeze_all;
    }
    ok unlink("$dir/.manifest.lock"), 'the lock file is gone, as a glob copy leaves it';
    my $ro = Data::Shared->open_readonly($dir);
    is shared_get($ro, '/cache/k'), 'v', 'the store still reads';
    ok !-e "$dir/.manifest.lock", 'and reading did not create one';
};

subtest 'a shipped store can still be torn down' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $producer = Data::Shared->new($dir);
        $producer->mount('cache', 'hashmap:ii', undef, 64);
        $producer->mount('users', ['hashmap:ss', 64, ['hashmap:ss', 64]]);
        $producer->set('/cache/1', 1);
        $producer->set('/users/alice/k', 'v');
        $producer->freeze_all;
    }
    ok !eval { Data::Shared->open($dir); 1 }, 'a writable open is refused, as the leaves require';
    my $ro = Data::Shared->open_readonly($dir);
    ok !eval { $ro->unlink_all; 1 }, 'and a read-only root will not reclaim it';
    undef $ro;

    my $sealed = Data::Shared->open_sealed($dir);
    ok $sealed, 'open_sealed attaches the sealed leaves';
    is $sealed->get('/cache/1'), 1, 'reads still work';
    is $sealed->get('/users/alice/k'), 'v', 'through the composite too';
    ok !eval { $sealed->set('/cache/2', 2); 1 }, 'a data write is still refused';
    ok $sealed->unlink_all, 'and the storage can finally be reclaimed';
    is scalar(() = glob "$dir/*.shm"), 0, 'no backing files are left';
    ok !-d "$dir/.children", 'no child directories are left';
    ok !-e "$dir/manifest.json", 'and no manifest';
};

subtest 'the freezability split the POD publishes is the one the registry has' => sub {
    my $registry = Data::Shared::Registry::registry();
    my %by;
    for my $key (keys %$registry) {
        my $e = $registry->{$key};
        push @{ $by{ $e->{freeze} ? 'sealable' : $e->{immutable} ? 'immutable' : 'neither' } }, $key;
    }
    is scalar keys %$registry, 39, '39 families';
    is scalar @{ $by{sealable} }, 21, '21 can be sealed';
    is_deeply $by{immutable}, ['perfecthash'], 'perfecthash is the only immutable one';
    is scalar @{ $by{neither} }, 17, 'and 17 block the predicate';

    my $pod = do {
        open my $fh, '<', $INC{'Data/Shared.pm'} or die $!;
        local $/; <$fh>;
    };
    # Every family name also appears elsewhere in the POD, so only the list itself is searched.
    my ($sealable, $total) = $pod =~ /only\s+([0-9]+)\s+of\s+the\s+([0-9]+)\s+families\s+can\s+be/;
    is $sealable, scalar @{ $by{sealable} }, 'the POD states how many can be sealed';
    is $total, scalar keys %$registry, 'out of the right total';
    my ($stated, $list) = $pod =~ /any\s+of\s+the\s+other\s+([0-9]+)\s*\((.*?)\)/s;
    is $stated, scalar @{ $by{neither} }, 'and how many block the predicate';
    my @named = $list ? $list =~ /C<([^>]+)>/g : ();
    is_deeply [sort @named], [sort @{ $by{neither} }],
        'and the list it prints is exactly the registry blockers';
};

subtest 'a sealed root caches its children, and a walk still does not' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $maker = Data::Shared->new($dir);
        $maker->mount('u', ['hashmap:ss', 128, ['hashmap:ii', 16], { cache_size => 2 }]);
        $maker->set("/u/c$_/5", $_) for 1 .. 10;
        $maker->get('/u/c9/5');
        my $cache = $maker->{mounts}{u}{composite}{cache};
        is scalar keys %$cache, 2, 'the cache holds what cache_size allows';
        $maker->sync_all;
        is scalar keys %$cache, 2, 'a sync_all walk over all ten does not fill it';
        ok $maker->freeze_all, 'the store seals';
        is scalar keys %$cache, 2, 'nor does a freeze_all walk';
    }

    my $sealed = Data::Shared->open_sealed($dir);
    my $opens = 0;
    my $orig = \&Data::Shared::Composite::_open_child;
    no warnings 'redefine';
    local *Data::Shared::Composite::_open_child = sub { $opens++; $orig->(@_) };

    is Data::Shared::shared_get($sealed, '/u/c1/5'), 1, 'a sealed read works';
    my $cold = $opens;
    Data::Shared::shared_get($sealed, '/u/c1/5') for 1 .. 5;
    is $opens, $cold, 'and five more reads of that child reopen nothing';
    my @h = map { $sealed->handle('/u/c1') } 1 .. 3;
    is scalar(keys %{ { map { ($_ . '') => 1 } @h } }), 1,
        'handle() hands back one object, as the hot-loop advice promises';
    is scalar keys %{ $sealed->{mounts}{u}{composite}{cache} }, 1,
        'because the sealed root caches like any other';
    ok $sealed->unlink_all >= 1, 'and teardown still reclaims it';
};

subtest 'a read-only root does not create the child it was asked for' => sub {
    my ($root, $dir) = store(children => 1);
    $root->freeze_all;
    undef $root;
    my $ro = Data::Shared->open_readonly($dir);
    is shared_get($ro, '/users/u1/k'), 1, 'the child that is there still reads';

    is shared_get($ro, '/users/absent/k'), undef, 'a read of an absent child answers undef';
    is shared_exists($ro, '/users/absent/k'), 0, 'and exists answers 0';
    ok !eval { $ro->call('/users/absent', 'size'); 1 }, 'a call on an absent child is refused';
    like $@, qr/\AData::Shared: read-only composite has no constructed child at this path/,
        'saying why, not what the backend would have said';
    ok !eval { shared_set($ro, '/users/absent/k', 1); 1 }, 'and a write is refused earlier';
    like $@, qr/root is read-only, cannot set/, 'by the facade, which names the verb';

    is_deeply [$ro->children('/users')], ['u1'], 'nothing was registered for it';
    ok !-d "$dir/.children/users/child-1", 'and no directory was created';
};

subtest 'a cold reader does not follow a teardown into the rebuilt store' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $build = sub {
        my ($value) = @_;
        my $w = Data::Shared->new($dir);
        $w->mount('users', ['hashmap:ss', 64, ['hashmap:ss', 8]]);
        shared_set($w, '/users/alice/k', $value);
        return $w->freeze_all;
    };
    cmp_ok $build->('first'), '>=', 3, 'parent, index and child all ship';
    my $cold = Data::Shared->open_readonly($dir, strict => 1);
    ok shared_exists($cold, '/users'), 'a reader attaches without opening the child';

    my $sealed = Data::Shared->open_sealed($dir);
    ok $sealed->unlink_all, 'the store is torn down under it';
    undef $sealed;
    ok !eval { shared_get($cold, '/users/alice/k'); 1 }, 'the cold read is refused';
    like $@, qr/composite instance was deleted/, 'saying the instance is gone';

    cmp_ok $build->('second'), '>=', 3, 'the same directory is rebuilt and sealed';
    ok !eval { shared_get($cold, '/users/alice/k'); 1 }, 'the cold read is refused again';
    like $@, qr/belongs to a newer instance/, 'naming the newer instance, not serving it';
    is shared_get(Data::Shared->open_readonly($dir, strict => 1), '/users/alice/k'),
        'second', 'while a fresh reader sees the rebuilt value';
};

done_testing;
