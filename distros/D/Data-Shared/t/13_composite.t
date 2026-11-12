use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_delete shared_exists shared_call
                    shared_compile sharedc_get sharedc_exists shared_node shared_children
                    shared_incr shared_push shared_pop shareda_get sharedc_set);

sub mount_or_skip {
    my ($root, $name, @spec) = @_;
    my $h = eval { $root->mount($name, @spec) };
    return $h if $h;
    my $err = $@;
    plan skip_all => "backend unavailable: $err"
        if $err =~ /is not available; install the|Can't locate \S+\.pm/;
    BAIL_OUT("mounting '$name' failed for a reason other than a missing backend: $err");
}

subtest 'hashmap:ss of bloomfilter' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'users', ['hashmap:ss', 1000, ['bloomfilter', 10000, 0.01]]);
    ok $r->mount_info('users')->{composite}, 'composite flag';
    is_deeply [$r->children('/users')], [], 'no children initially';
    is shared_get($r, '/users/alice/event-1'), undef, 'missing deep get undef';
    is_deeply [$r->children('/users')], [], 'read does not create';
    is shared_exists($r, '/users/alice'), 0, 'missing child exists 0';
    is shared_get($r, '/users/alice'), undef, 'missing child get is undef, not a cursor';

    shared_set($r, '/users/alice/event-42', 1);
    is shared_exists($r, '/users/alice'), 1, 'child exists after write';
    is shared_exists($r, '/users/alice/event-42'), 1, 'deep exists';
    is shared_exists($r, '/users/alice/event-99'), 0, 'deep absent';
    is_deeply [$r->children('/users')], ['alice'], 'children lists alice';
    is_deeply [shared_children($r, '/users')], ['alice'], 'shared_children';

    my $node = shared_get($r, '/users/alice');
    isa_ok $node, 'Data::Shared::Node', 'intermediate get is node';
    is $node->path, '/users/alice', 'node path';
    is $node->call('count'), 1, 'node call count';
    is $node->exists('/event-42'), 1, 'node relative exists';
    is $r->node('/users/alice')->call('count'), 1, 'root node call';
    isa_ok shared_node($r, '/users'), 'Data::Shared::Node', 'shared_node';
    is ref($r->handle('/users/alice')), 'Data::BloomFilter::Shared', 'handle is child leaf';
    isa_ok $r->handle('/users'), 'Data::Shared::Node', 'handle of composite is node';

    shared_set($r, '/users/bob/event-1', 1);
    is_deeply [$r->children('/users')], ['alice', 'bob'], 'two children sorted';
    ok !eval { shared_set($r, '/users/alice', 1); 1 }, 'set at hashmap child croaks';
    like $@, qr/cannot set a composite child/, 'set child error';
    shared_delete($r, '/users/alice');
    is shared_exists($r, '/users/alice'), 0, 'subtree deleted';
    is shared_exists($r, '/users/alice/event-42'), 0, 'subtree deep gone';
    is_deeply [$r->children('/users')], ['bob'], 'children after delete';
    is shared_delete($r, '/users/nobody'), undef, 'delete missing subtree undef';
};

subtest 'hashmap:ii of hashmap:ss with int address validation' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'byid', ['hashmap:ii', 1000, ['hashmap:ss', 1000]]);
    shared_set($r, '/byid/42/name', 'alice');
    is shared_get($r, '/byid/42/name'), 'alice', 'deep map get';
    is_deeply [$r->children('/byid')], ['42'], 'int child listed as string';
    shared_set($r, '/byid/10/name', 'ten');
    shared_set($r, '/byid/2/name', 'two');
    is_deeply [$r->children('/byid')], ['2', '10', '42'], 'int children sorted numerically';
    ok !eval { shared_set($r, '/byid/alice/name', 'x'); 1 }, 'non-int address croaks on write';
    like $@, qr/invalid composite address/, 'address error';
    is shared_get($r, '/byid/alice/name'), undef, 'non-int read is undef';
    is shared_exists($r, '/byid/alice'), 0, 'non-int exists 0';
};

subtest 'sortedset:strings of bloomfilter keeps score' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'leaders', ['sortedset:strings', { max => 1000 }, ['bloomfilter', 10000, 0.01]]);
    shared_set($r, '/leaders/alice', 1500);
    is shared_get($r, '/leaders/alice'), 1500, 'score at child path';
    is_deeply [$r->children('/leaders')], ['alice'], 'score set registers child';
    shared_set($r, '/leaders/alice/event-9', 1);
    is shared_exists($r, '/leaders/alice/event-9'), 1, 'child event';
    is shared_get($r, '/leaders/alice'), 1500, 'score preserved after child write';
    is shared_call($r, '/leaders', 'child_count'), 1, 'child_count via call';
    my @kids = shared_call($r, '/leaders', 'children');
    is_deeply \@kids, ['alice'], 'children via call';
    shared_delete($r, '/leaders/alice');
    is shared_get($r, '/leaders/alice'), undef, 'score gone after subtree delete';
};

subtest 'sortedset int of roaringbitmap' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'board', ['sortedset', 1000, ['roaringbitmap', 256]]);
    shared_set($r, '/board/42/70000', 1);
    is shared_exists($r, '/board/42/70000'), 1, 'roaring child member';
    is shared_get($r, '/board/42'), 0, 'auto score 0';
    shared_set($r, '/board/42', 900);
    is shared_get($r, '/board/42'), 900, 'score set after child exists';

    # Registration adds the member at score 0 first, so the backend alone would answer 0.
    is shared_set($r, '/board/7', 1.5), 1, 'a score write to a new child says it wrote';
    is shared_get($r, '/board/7'), '1.5', 'and the score is there';
    is shared_set($r, '/board/7', 2.5), 0, 'writing it again adds no member';
    is shared_get($r, '/board/7'), '2.5', 'and still updates the score';
};

subtest 'three levels: hashmap of kdtree of hashmap' => sub {
    if (!eval { require Data::KDTree::Shared; 1 }) { plan skip_all => 'kdtree backend unavailable'; return }
    my $r = Data::Shared->new;
    mount_or_skip($r, 'atlas', ['hashmap:ss', 1000, ['kdtree', 2, 1000, ['hashmap:ss', 1000]]]);
    my $eu = $r->node('/atlas/europe');
    $eu->call('add', [10.5, 20.5], 42);
    shared_set($r, '/atlas/europe/42/name', 'place-42');
    is shared_get($r, '/atlas/europe/42/name'), 'place-42', 'three level get';
    is_deeply [$r->children('/atlas')], ['europe'], 'level 1 children';
    is_deeply [$r->children('/atlas/europe')], ['42'], 'level 2 children';
    is $eu->call('nearest', [10.0, 20.0])->{id}, 42, 'node call on kdtree child';
    shared_delete($r, '/atlas/europe');
    is shared_get($r, '/atlas/europe/42/name'), undef, 'mid subtree delete clears deep';
};

subtest 'a composite checks its child backend at mount time' => sub {
    eval { require Data::HashMap::Shared::SS; 1 }
        or plan skip_all => 'hashmap backend unavailable, so the child check cannot be isolated';
    my $r = Data::Shared->new(tempdir(CLEANUP => 1));
    ok !eval { $r->mount('c', ['hashmap:ss', 64, ['Data::Shared::NoSuchBackend', 8]]); 1 },
        'an unloadable child class is refused at mount';
    like $@, qr/NoSuchBackend is not available/, 'naming the class it could not load';
    is_deeply [$r->mounts], [], 'and nothing is published';
    ok !eval { $r->mount('f', 'Data::Shared::NoSuchBackend', undef, 8); 1 },
        'as a flat mount already was';
    like $@, qr/NoSuchBackend is not available/, 'with the same message';
};

subtest 'invalid composite parents rejected' => sub {
    my $r = Data::Shared->new;
    ok !eval { $r->mount('bad1', ['bloomfilter', 1000, 0.01, ['hashmap:ss', 100]]); 1 }, 'bloom parent croaks';
    like $@, qr/cannot be a composite parent/, 'bloom parent error';
    ok !eval { $r->mount('bad2', ['queue:int', 100, ['hashmap:ss', 100]]); 1 }, 'queue parent croaks';
    like $@, qr/cannot be a composite parent/, 'queue parent error';
    ok !eval { $r->mount('bad3', ['hashmap:ss', 100, ['nosuchthing', 100]]); 1 }, 'unknown child croaks';
    like $@, qr/unknown mount spec/, 'unknown child error';
    ok !eval { $r->mount('bad4', ['hashmap:ss', 100, ['bloomfilter', 1000, 0.01], { max_children => 0 }]); 1 }, 'max_children 0 croaks on write or mount';
    like $@, qr/max_children must be an integer/, 'max_children error';
    ok !eval { $r->children('/users'); 1 }, 'children on missing mount croaks';
    like $@, qr/no mount matches path/, 'missing mount error';
    my $r2 = Data::Shared->new;
    SKIP: {
        my $handle = eval { $r2->mount('plain', 'hashmap:ii', undef, 100) };
        skip "hashmap backend unavailable: $@", 2 unless $handle;
        ok !eval { $r2->children('/plain'); 1 }, 'children on plain mount croaks';
        like $@, qr/not composite/, 'not composite error';
    }
};

subtest 'child budget and eviction with file storage' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new($dir);
    mount_or_skip($r, 'users', { spec => 'hashmap:ss', args => [1000],
        child => { spec => 'bloomfilter', args => [10000, 0.01] }, max_children => 2, cache_size => 1 });
    shared_set($r, '/users/a/e1', 1);
    shared_set($r, '/users/b/e2', 1);
    is shared_exists($r, '/users/a/e1'), 1, 'evicted child a still readable from storage';
    is shared_exists($r, '/users/b/e2'), 1, 'child b readable';
    ok !eval { shared_set($r, '/users/c/e3', 1); 1 }, 'third child exceeds budget';
    like $@, qr/child limit exceeded/, 'budget error';
    is_deeply [$r->children('/users')], ['a', 'b'], 'budget children unchanged';
};

subtest 'persistence across reopen' => sub {
    my $dir = tempdir(CLEANUP => 1);
    {
        my $r = Data::Shared->new($dir);
        mount_or_skip($r, 'users', ['hashmap:ss', 1000, ['bloomfilter', 10000, 0.01]]);
        shared_set($r, '/users/alice/event-42', 1);
        ok -d "$dir/.children/users", 'children storage dir';
    }
    my $r = Data::Shared->open($dir);
    is shared_exists($r, '/users/alice/event-42'), 1, 'deep data after reopen';
    is_deeply [$r->children('/users')], ['alice'], 'children after reopen';
    my $stats = $r->stats;
    is $stats->{users}{children}, 1, 'stats children count';
    ok $r->sync_all >= 1, 'sync_all with composite';
};

subtest 'compiled deep paths stay correct across delete' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'users', ['hashmap:ss', 1000, ['hashmap:ss', 1000]]);
    shared_set($r, '/users/bob/name', 'x');
    my $cp = shared_compile('/users/bob/name');
    is sharedc_get($r, $cp), 'x', 'compiled deep get';
    is sharedc_exists($r, $cp), 1, 'compiled deep exists';
    shared_delete($r, '/users/bob/name');
    is sharedc_exists($r, $cp), 0, 'compiled deep after inner delete';
    shared_set($r, '/users/bob/name', 'y');
    is sharedc_get($r, $cp), 'y', 'compiled deep after rewrite';
    shared_delete($r, '/users/bob');
    is sharedc_exists($r, $cp), 0, 'compiled deep after subtree delete';
    shared_set($r, '/users/bob/name', 'z');
    is sharedc_get($r, $cp), 'z', 'compiled deep after recreate';
};

subtest 'graph of hashmap by node id' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'net', ['graph', 100, 500, ['hashmap:ss', 100]]);
    my $a = shared_call($r, '/net', 'add_node', 10);
    shared_set($r, "/net/$a/name", 'node-a');
    is shared_get($r, "/net/$a/name"), 'node-a', 'graph child get';
    is_deeply [$r->children('/net')], ["$a"], 'graph children by id';
};

subtest 'fixed-width int parents reject aliasing addresses' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'm16', ['hashmap:i16s', 100, ['hashmap:ss', 100]]);
    shared_set($r, "/m16/$_/name", "k$_") for -32768, 32767;
    is shared_get($r, '/m16/32767/name'), 'k32767', 'in-range i16 address works';
    for my $bad (70000, 40000, -32769) {
        ok !eval { shared_set($r, "/m16/$bad/name", 'alias'); 1 }, "i16 parent rejects $bad";
    }
    is_deeply [$r->children('/m16')], [-32768, 32767], 'no aliased children';

    $r->mount('m32', ['hashmap:i32s', 100, ['hashmap:ss', 100]]);
    shared_set($r, '/m32/2147483647/name', 'max');
    is shared_get($r, '/m32/2147483647/name'), 'max', 'in-range i32 address works';
    ok !eval { shared_set($r, '/m32/2147483648/name', 'alias'); 1 }, 'i32 parent rejects 2147483648';

    # Strings, since -9223372036854775809 rounds to the minimum as a double.
    $r->mount('m64', ['hashmap:ii', 100, ['hashmap:ss', 100]]);
    shared_set($r, '/m64/9223372036854775807/name', 'max');
    shared_set($r, '/m64/-9223372036854775808/name', 'min');
    is shared_get($r, '/m64/9223372036854775807/name'), 'max', 'IV_MAX address works';
    for my $bad ('9223372036854775808', '-9223372036854775809', '18446744073709551615') {
        ok !eval { shared_set($r, "/m64/$bad/name", 'alias'); 1 }, "ii parent rejects $bad";
    }

    $r->mount('leaf', 'hashmap:i16s', undef, 100);
    ok eval { shared_set($r, '/leaf/70000', 'wrapped'); 1 }, 'leaf mount still accepts a wrapping key';
};

subtest 'call at a missing child materialises it' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'm', ['hashmap:ss', 100, ['hashmap:ss', 100]]);
    is shared_get($r, '/m/ghost/k'), undef, 'read does not create';
    is shared_exists($r, '/m/ghost'), 0, 'exists does not create';
    is_deeply [$r->children('/m')], [], 'still no children';
    is shared_call($r, '/m/ghost', 'size'), 0, 'read-only call answers';
    is_deeply [$r->children('/m')], ['ghost'], 'the call registered the child';
};

subtest 'id-parents address by integer id' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'net', ['graph', 100, 500, ['hashmap:ss', 100]]);
    shared_set($r, "/net/$_/name", "n$_") for 1, 2, 3, 10, 11, 12;
    is_deeply [$r->children('/net')], [1, 2, 3, 10, 11, 12], 'graph ids list in numeric order';
    for my $bad ('007', "7\n", 'alice', '-0') {
        (my $show = $bad) =~ s/\n/\\n/;
        ok !eval { shared_set($r, "/net/$bad/name", 'phantom'); 1 }, "graph rejects id '$show'";
    }
    is_deeply [$r->children('/net')], [1, 2, 3, 10, 11, 12], 'no phantom children registered';

    if (eval { require Data::KDTree::Shared; 1 }) {
        my $k = Data::Shared->new;
        $k->mount('pts', ['kdtree', 2, 1000, ['hashmap:ss', 100]]);
        shared_set($k, "/pts/$_/name", "p$_") for 1, 2, 10;
        is_deeply [$k->children('/pts')], [1, 2, 10], 'kdtree ids list in numeric order';
        ok !eval { shared_set($k, '/pts/007/name', 'phantom'); 1 }, 'kdtree rejects id 007';
    }
};

subtest 'nested composite: hashmap of sortedset of hashmap' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'org', ['hashmap:ss', 1000, ['sortedset:strings', { max => 1000 }, ['hashmap:ss', 100]]]);
    shared_set($r, '/org/acme/alice/role', 'admin');
    is shared_get($r, '/org/acme/alice/role'), 'admin', 'nested deep get';
    $r->node('/org/acme')->set('/alice', 42);
    is shared_get($r, '/org/acme/alice'), 42, 'nested score via node';
    is shared_get($r, '/org/acme/alice/role'), 'admin', 'role preserved';
};

subtest 'freeze then readonly deep reads' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new($dir);
    mount_or_skip($r, 'users', ['hashmap:ss', 1000, ['bloomfilter', 10000, 0.01]]);
    shared_set($r, '/users/alice/event-1', 1);
    $r->freeze_all;
    my $ro = Data::Shared->open_readonly($dir);
    is shared_exists($ro, '/users/alice/event-1'), 1, 'readonly deep exists';
    is_deeply [$ro->children('/users')], ['alice'], 'readonly children';
    ok !eval { shared_set($ro, '/users/bob/event-1', 1); 1 }, 'readonly deep write croaks';
};

subtest 'child write from a second process' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new($dir);
    mount_or_skip($r, 'users', ['hashmap:ss', 1000, ['bloomfilter', 10000, 0.01]]);
    my $pid = fork();
    plan skip_all => 'fork not available' unless defined $pid;
    if ($pid == 0) {
        my $c = Data::Shared->open($dir);
        shared_set($c, '/users/childproc/event-1', 1);
        exit(shared_exists($c, '/users/childproc/event-1') ? 0 : 1);
    }
    waitpid $pid, 0;
    is $?, 0, 'child process wrote';
    is shared_exists($r, '/users/childproc/event-1'), 1, 'parent sees child write';
};

subtest 'queue child under hashmap' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'queues', ['hashmap:ss', 1000, ['queue:int', 100]]);
    $r->push('/queues/alice', 42);
    is $r->pop('/queues/alice'), 42, 'push/pop into child queue';
    is_deeply [$r->children('/queues')], ['alice'], 'queue child registered';
    # The compiled tier binds composite push and pop through a dispatcher of their own.
    my $cp = Data::Shared::shared_compile('/queues/alice');
    Data::Shared::sharedc_push($r, $cp, 7);
    is Data::Shared::sharedc_pop($r, $cp), 7, 'and through a compiled path too';
};

# One spec serves every child, so a path in it would name one file for all of them.
subtest 'a composite child cannot name its own backing path' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    plan skip_all => 'sortedset:strings unavailable'
        unless eval { $root->mount('probe', 'sortedset:strings', { max => 8 }); 1 };
    plan skip_all => 'hashmap:ss unavailable'
        unless eval { require Data::HashMap::Shared::SS; 1 };

    for my $case (['set alone', { max => 8, set => "$dir/s.set" }],
                  ['keys alone', { max => 8, keys => "$dir/s.keys" }],
                  ['both', { max => 8, set => "$dir/t.set", keys => "$dir/t.keys" }]) {
        my ($label, $opt) = @$case;
        ok !eval { $root->mount("z$label", ['hashmap:ss', 64,
                       ['sortedset:strings', $opt], { max_children => 4 }]); 1 },
            "$label is refused in a child spec";
        like $@, qr/cannot name its own backing path/, "$label says why";
    }

    ok !eval { $root->mount('nested', ['hashmap:ss', 64,
                   ['hashmap:ss', 32, ['sortedset:strings', { max => 8, set => "$dir/n.set" }]],
                   { max_children => 4 }]); 1 },
        'a grandchild spec is refused too';

    # A leading undef or ':file' is the placeholder asking the facade to supply the file.
    my $i = 0;
    for my $case (['undef then an options hash', ['sortedset:strings', undef, { max => 8, set => "$dir/p.set", keys => "$dir/p.keys" }]],
                  ["':file' then an options hash", ['sortedset:strings', ':file', { max => 8, set => "$dir/q.set" }]],
                  ['undef then a key/value list', ['sortedset:strings', undef, 'max', 8, 'set', "$dir/r.set"]],
                  ['undef then a handle hash', ['perfecthash', undef, { build_int => [1, 2], path => "$dir/p.phs" }]],
                  ['undef then a bare path', ['perfecthash', undef, "$dir/q.phs"]]) {
        my ($label, $args) = @$case;
        ok !eval { $root->mount('ph' . $i++, ['hashmap:ss', 64, $args,
                       { max_children => 4 }]); 1 }, "$label is refused too";
        like $@, qr/cannot name its own backing path/, "$label says why";
    }
    SKIP: {
        my $probe = tempdir(CLEANUP => 1);
        skip 'perfecthash unavailable', 5
            unless eval { Data::Shared->new($probe)
                              ->mount('p', 'perfecthash', { build_int => [1, 2] }); 1 };
        ok !eval { $root->mount('placeheld', ['hashmap:ss', 64, ['perfecthash', ':file'],
                       { max_children => 4 }]); 1 }, 'a child with nothing to build from is refused';
        like $@, qr/perfecthash spec takes a built file path/, 'saying what the spec takes';
        ok eval { $root->mount('built', ['hashmap:ss', 64, ['perfecthash', { build_int => [1, 2] }],
                       { max_children => 4 }]); 1 },
            'and the buildable spelling mounts' or diag $@;
        # A read never creates a child and perfecthash has no mutating verb.
        is shared_call($root, '/built/alice', 'count'), 2, 'with a child built from its keys';
        is shared_exists($root, '/built/alice/1'), 1, 'which answers for a key it was built with';
    }

    my $j = 0;
    for my $pre ([undef, undef], [':file', undef], [undef, ':file']) {
        my $label = join ', ', map { defined $_ ? "'$_'" : 'undef' } @$pre;
        ok !eval { $root->mount('two' . $j++, ['hashmap:ss', 64,
                       ['sortedset:strings', @$pre, { max => 8 }],
                       { max_children => 4 }]); 1 }, "a second placeholder ($label) is refused";
        like $@, qr/names the backing-path placeholder .* more than once/,
            "($label) says one placeholder is one file";
    }
    ok eval { $root->mount('oneonly', ['hashmap:ss', 64, ['sortedset:strings', undef, { max => 8 }],
                   { max_children => 4 }]); 1 }, 'one placeholder is still fine' or diag $@;
    shared_call($root, '/oneonly/alice', 'add', 'x', 1);
    is shared_call($root, '/oneonly/alice', 'score', 'x'), 1, 'and its children are created';

    ok eval { $root->mount('fine', ['hashmap:ss', 64, ['sortedset:strings', { max => 8 }],
                   { max_children => 4 }]); 1 }, 'the derived form still mounts' or diag $@;
    shared_call($root, '/fine/alice', 'add', 'x', 1);
    shared_call($root, '/fine/bob', 'add', 'y', 2);
    is shared_call($root, '/fine/bob', 'score', 'x'), undef,
        'and each child keeps its own members';
    # An undef for 'x' is also what a child that lost everything would answer.
    is shared_call($root, '/fine/alice', 'score', 'x'), 1, 'alice still has hers';
    is shared_call($root, '/fine/bob', 'score', 'y'), 2, 'and bob has his';

    ok eval { $root->mount('flat', 'sortedset:strings',
                  { max => 8, set => "$dir/f.set", keys => "$dir/f.keys" }); 1 },
        'a flat mount may still name its path' or diag $@;
};

subtest 'a composite spec says which keys and shapes it takes' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    plan skip_all => 'hashmap:ss unavailable'
        unless eval { $root->mount('probe', 'hashmap:ss', undef, 8); 1 };

    ok !eval { $root->mount('dropped', ['hashmap:ss', 64,
                   ['hashmap:ss', 64, { spec => 'hashmap:ss', args => [16] }]]); 1 },
        'a hashref child inside an arrayref spec is refused';
    like $@, qr/child spec in an arrayref composite spec must be an arrayref/,
        'saying which shape to use';

    ok !eval { $root->mount('typo', { spec => 'hashmap:ss', args => [64],
                   child => ['hashmap:ss', 8], maxchildren => 5 }); 1 },
        'a misspelled key in a hashref spec is refused';
    like $@, qr/unknown composite spec key 'maxchildren'/, 'naming the key';
    ok !eval { $root->mount('typo2', ['hashmap:ss', 64, ['hashmap:ss', 8],
                   { maxchildren => 5 }]); 1 },
        'and the arrayref spelling still refuses one';
    like $@, qr/unknown composite option 'maxchildren'/, 'naming it too';

    SKIP: {
        skip 'sortedset:strings unavailable', 2
            unless eval { Data::Shared->new->mount('p', 'sortedset:strings', { max => 8 }); 1 };
        ok !eval { $root->mount('ctor', { spec => 'hashmap:ss', args => [16],
                       child => { spec => 'sortedset:strings', ctor => 'no_such',
                                  args => [{ max => 8 }] } }); 1 },
            'a ctor named for a hardcoded family is refused';
        like $@, qr/\QData::SortedSet::Shared::Strings\E spec does not take a ctor; it is constructed by new/,
            'saying what constructs it';
    }
    ok eval { $root->mount('fine', { spec => 'hashmap:ss', args => [64],
                   child => ['hashmap:ss', 8], max_children => 5 }); 1 },
        'the spelled-out hashref form still mounts' or diag $@;
    shared_set($root, '/fine/alice/key', 'v');
    is shared_get($root, '/fine/alice/key'), 'v', 'and its children work';
};

subtest 'a malformed child spec is refused before the composite publishes' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    plan skip_all => 'sortedset:strings unavailable'
        unless eval { $root->mount('probe', 'sortedset:strings', { max => 8 }); 1 };
    plan skip_all => 'hashmap:ss unavailable'
        unless eval { require Data::HashMap::Shared::SS; 1 };
    my $i = 0;
    for my $case (['an empty option hash', ['sortedset:strings', {}], qr/requires 'max'/],
                  ['an odd option list', ['sortedset:strings', 'max', 8, 'set'],
                   qr/must be a hashref or key\/value pairs/],
                  ['a hash with a stray extra', ['sortedset:strings', { max => 8 }, 'extra'],
                   qr/requires 'max'/]) {
        my ($label, $child, $says) = @$case;
        ok !eval { $root->mount('bad' . $i++, ['hashmap:ss', 64, $child,
                       { max_children => 4 }]); 1 }, "$label is refused at mount";
        like $@, $says, "$label: with the backend's own words";
    }
    is_deeply [grep { /^bad/ } $root->mounts], [], 'and none of them is a mount';
    ok eval { $root->mount('ok', ['hashmap:ss', 64, ['sortedset:strings', { max => 8 }],
                   { max_children => 4 }]); 1 }, 'a well-formed child still mounts' or diag $@;
    shared_call($root, '/ok/alice', 'add', 'x', 1);
    is shared_call($root, '/ok/alice', 'score', 'x'), 1, 'and its children work';
};

subtest 'a verb at the composite mount itself' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    mount_or_skip($root, 'u', ['hashmap:ss', 64, ['hashmap:ii', 64], { max_children => 8 }]);
    shared_set($root, '/u/alice/1', 42);
    my $cp = shared_compile('/u');

    for my $tier (['shared_get',  sub { shared_get($root, '/u') }],
                  ['shareda_get', sub { shareda_get($root, ['u']) }],
                  ['sharedc_get', sub { sharedc_get($root, $cp) }],
                  ['node get',    sub { $root->node('/u')->get('') }]) {
        my ($name, $code) = @$tier;
        my $node = eval { $code->() };
        isa_ok $node, 'Data::Shared::Node', "$name returns a cursor" or diag $@;
        is_deeply $node->components, ['u'], "$name: addressing the mount"
            if ref $node;
    }
    is eval { shared_exists($root, '/u') }, 1, 'exists answers 1, not the mount record';
    is eval { sharedc_exists($root, $cp) }, 1, 'and the compiled tier agrees';

    for my $verb (['set', sub { shared_set($root, '/u', 1) }],
                  ['set', sub { sharedc_set($root, $cp, 1) }],
                  ['delete', sub { shared_delete($root, '/u') }],
                  ['incr', sub { shared_incr($root, '/u') }],
                  ['push', sub { shared_push($root, '/u', 1) }],
                  ['pop', sub { shared_pop($root, '/u') }]) {
        my ($name, $code) = @$verb;
        ok !eval { $code->(); 1 }, "$name at the mount itself is refused";
        like $@, qr/\AData::Shared: cannot \Q$name\E a composite mount itself; address a child/,
            "$name: naming the verb and what to do instead";
    }
    is shared_get($root, '/u/alice/1'), 42, 'and the child is still readable';
};

done_testing;
