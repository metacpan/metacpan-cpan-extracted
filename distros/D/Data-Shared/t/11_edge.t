use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd ();
use Data::Shared qw(shared_get shared_set shared_delete shared_exists shared_incr
                    shared_call shared_push shared_pop
                    shareda_get shareda_set shareda_delete shareda_exists shareda_incr
                    shareda_call shareda_push shareda_pop
                    shared_compile sharedc_get sharedc_set sharedc_delete sharedc_exists
                    sharedc_incr sharedc_call sharedc_push sharedc_pop);

sub mount_or_skip {
    my ($root, $name, @spec) = @_;
    my $h = eval { $root->mount($name, @spec) };
    return $h if $h;
    my $err = $@;
    plan skip_all => "backend unavailable: $err"
        if $err =~ /is not available; install the|Can't locate \S+\.pm/;
    BAIL_OUT("mounting '$name' failed for a reason other than a missing backend: $err");
}

subtest 'invalid inputs' => sub {
    my $r = Data::Shared->new;
    my $mounted = mount_or_skip($r, 'cache', 'hashmap:ii', undef, 100);
    ok !eval { shared_get($r, undef); 1 }, 'undef path croaks';
    like $@, qr/defined string/, 'undef path error';
    ok !eval { shared_get($r, ['cache']); 1 }, 'ref path croaks for string tier';
    like $@, qr/must not be a reference/, 'ref path error';
    ok !eval { shareda_get($r, 'cache/1'); 1 }, 'non-array array path croaks';
    like $@, qr/ARRAY reference/, 'array path error';
    ok !eval { shared_get({}, '/cache/1'); 1 }, 'non-root croaks';
    like $@, qr/must be a Data::Shared root/, 'root error';
    ok !eval { shared_call($r, '/cache', undef); 1 }, 'call without method croaks';
    ok !eval { shared_call($r, '', 'get'); 1 }, 'call on root path croaks';
    ok !eval { shared_call($r, '/cache', 'no_such_method_xyz'); 1 }, 'call unknown method croaks';
    like $@, qr/has no method/, 'unknown method error';
    ok !eval { shared_get($r, '/cache'); 1 }, 'map get without key croaks';
    like $@, qr/no key/, 'too short error';
    ok !eval { $r->mount('', 'hashmap:ii', undef, 10); 1 }, 'empty mount name croaks';
    ok !eval { $r->mount('///', 'hashmap:ii', undef, 10); 1 }, 'slash-only name croaks';
    ok !eval { $r->mount('x'); 1 }, 'mount without spec croaks';
    ok !eval { $r->mount('y', sub { return 42 }); 1 }, 'factory returning non-handle croaks';
    like $@, qr/did not return a handle/, 'factory error';
    ok !eval { $r->mount('z', {}); 1 }, 'empty hashref spec croaks';
    like $@, qr/needs spec\/class\/key/, 'hashref error';
    ok !eval { $r->mount('z', { spec => 'nosuchthing' }); 1 }, 'hashref unknown spec croaks';
    ok !eval { $r->mount('z', 'Data::NoSuchClassXYZ'); 1 }, 'missing backend croaks';
    like $@, qr/backend .* is not available/, 'backend error';
    is $r->mount_info('nope'), undef, 'mount_info missing is undef';
    is $r->unmount('nope'), 0, 'unmount missing is 0';
    is $r->handle('/'), $r, 'handle slash is root';
    is $r->handle(undef), $r, 'handle undef is root';
    is $r->handle(['cache']), $mounted, 'handle by arrayref';
    my $cp = shared_compile('/cache/1');
    is $r->handle(shared_compile('/cache')), $mounted, 'handle by compiled';
    is $r->handle('/cache'), $mounted, 'handle by string';
    is_deeply $cp->components, ['cache', '1'], 'compiled components';
    is $cp->raw, '/cache/1', 'compiled raw';
    ok !$cp->is_array, 'compiled string not array';
    ok shared_compile(['cache'])->is_array, 'compiled array is_array';
    is(Data::Shared->CLONE_SKIP, 1, 'root CLONE_SKIP');
    is $r->dir, undef, 'anonymous dir undef';
    is $r->manifest_path, undef, 'anonymous manifest undef';
    ok !$r->readonly, 'rw root not readonly';
    is_deeply [$r->mount_names], ['cache'], 'mount_names lists the mount';
    is_deeply [$r->mounts], ['cache'], 'and mounts agrees with it';
    my $reg = Data::Shared->registry;
    is $reg->{hashmap}{key}, 'hashmap', 'registry method';
    is Data::Shared::Registry::entry_for_key('HASHMAP')->{key}, 'hashmap', 'entry_for_key lc';
    is Data::Shared::Registry::entry_for_class('Data::HashMap::Shared::SS')->{key}, 'hashmap', 'entry_for_class variant';
    is Data::Shared::Registry::resolve_spec('hashmap:default')->{class}, 'Data::HashMap::Shared::II', 'resolve default variant';
    my $gen = Data::Shared::Registry::resolve_spec('Data::NoSuchClassXYZ');
    is $gen->{class}, 'Data::NoSuchClassXYZ', 'generic Data:: resolve';
    is $gen->{entry}, undef, 'generic entry undef';
    ok !Data::Shared::Registry::resolve_spec(undef), 'resolve undef';
};

subtest 'a repeated separator names the same key' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'm', 'hashmap:ss', undef, 8);
    shared_set($r, 'm/k', 7);
    is shared_get($r, 'm//k'), 7, 'two separators reach the key one reaches';
    is shared_get($r, '//m//k'), 7, 'and so do leading ones';
};

subtest 'array and compiled tiers completeness' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'cache', 'hashmap:ii', undef, 100);
    mount_or_skip($r, 'jobs', 'queue:int', undef, 100);
    shareda_set($r, ['cache', '1'], 10);
    is shareda_get($r, ['cache', '1']), 10, 'array get';
    is shareda_exists($r, ['cache', '1']), 1, 'array exists';
    is shareda_incr($r, ['cache', '1']), 11, 'array incr';
    is shareda_call($r, ['cache'], 'get', 1), 11, 'array call';
    shareda_delete($r, ['cache', '1']);
    is shareda_exists($r, ['cache', '1']), 0, 'array delete';
    shareda_push($r, ['jobs'], 42);
    is shareda_pop($r, ['jobs']), 42, 'array push/pop';

    my $cp = shared_compile('/cache/1');
    sharedc_set($r, $cp, 20);
    is sharedc_get($r, $cp), 20, 'compiled get';
    is sharedc_incr($r, $cp), 21, 'compiled incr';
    is sharedc_exists($r, $cp), 1, 'compiled exists';
    sharedc_delete($r, $cp);
    is sharedc_exists($r, $cp), 0, 'compiled delete';
    is sharedc_call($r, shared_compile('/cache'), 'size'), 0, 'compiled call';

    my $jp = shared_compile('/jobs');
    sharedc_push($r, $jp, 7);
    is sharedc_pop($r, $jp), 7, 'compiled push/pop';

    my $rootcp = shared_compile('');
    is sharedc_get($r, $rootcp), $r, 'compiled root get';
    is sharedc_exists($r, $rootcp), 1, 'compiled root exists';
    ok !eval { sharedc_set($r, $rootcp, 1); 1 }, 'compiled root set croaks';
    ok !eval { sharedc_call($r, $rootcp, 'get'); 1 }, 'compiled root call croaks';

    ok !eval { sharedc_get($r, '/cache/1'); 1 }, 'compiled tier rejects string';
    my $bad = shared_compile('/nope/1');
    ok !eval { sharedc_get($r, $bad); 1 }, 'compiled unknown mount croaks';
    like $@, qr/no mount matches/, 'compiled unknown error';

    my $mp = shared_compile('/cache');
    ok !eval { sharedc_push($r, $mp, 1); 1 }, 'compiled push on map croaks';
};

subtest 'compiled cache invalidates on remount and alternates roots' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'cache', 'hashmap:ii', undef, 100);
    my $cp = shared_compile('/cache/1');
    shared_set($r, '/cache/1', 10);
    is sharedc_get($r, $cp), 10, 'first root value';
    my $r2 = Data::Shared->new;
    $r2->mount('cache', 'hashmap:ii', undef, 100);
    shared_set($r2, '/cache/1', 99);
    is sharedc_get($r2, $cp), 99, 'second root value';
    is sharedc_get($r, $cp), 10, 'back to first root';
    $r->unmount('cache');
    $r->mount('cache', 'hashmap:ii', undef, 100);
    is sharedc_get($r, $cp), undef, 'remounted empty cache not stale';
    shared_set($r, '/cache/1', 55);
    is sharedc_get($r, $cp), 55, 'remounted new value';
};

subtest 'object methods' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'cache', 'hashmap:ii', undef, 100);
    mount_or_skip($r, 'jobs', 'queue:int', undef, 100);
    $r->set('/cache/1', 10);
    is $r->get('/cache/1'), 10, 'obj get';
    is $r->incr('/cache/1'), 11, 'obj incr';
    ok $r->exists('/cache/1'), 'obj exists';
    is $r->call('/cache', 'get', 1), 11, 'obj call';
    $r->push('/jobs', 42);
    is $r->pop('/jobs'), 42, 'obj push/pop';
    isa_ok $r->compile('/cache/1'), 'Data::Shared::Compiled', 'obj compile';
    $r->delete('/cache/1');
    is $r->exists('/cache/1'), 0, 'obj delete';
};

subtest 'root lifecycle: create, replay via new, sync/stats/unlink' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $dir = "$base/nested/app.shared";
    my $r = Data::Shared->new($dir);
    ok -d $dir, 'new creates nested dir';
    is $r->dir, $dir, 'dir accessor';
    ok -e $r->manifest_path, 'manifest path exists';
    mount_or_skip($r, 'seen', 'bloomfilter', undef, 1000, 0.01);
    shared_set($r, '/seen/alice', 1);
    ok $r->sync_all >= 1, 'sync_all';
    my $stats = $r->stats;
    ok exists $stats->{seen}, 'stats has mount';
    my $again = Data::Shared->new($dir);
    is_deeply [$again->mounts], ['seen'], 'new replays existing manifest';
    ok shared_exists($again, '/seen/alice'), 'replayed data visible';
    my $n = $again->unlink_all;
    ok $n >= 1, 'unlink_all count';
    ok !-e "$dir/manifest.json", 'unlink_all removes manifest';
    ok !eval { Data::Shared->open("$base/missing"); 1 }, 'open missing croaks';
    ok !eval { Data::Shared->open_readonly("$base/missing"); 1 }, 'open_readonly missing croaks';
    ok !eval { Data::Shared->open(undef); 1 }, 'open undef croaks';
};

subtest 'stats fallback for handle without stats' => sub {
    package DummyHandle;
    sub new { bless {}, shift }
    package main;
    my $r = Data::Shared->new;
    $r->mount('dummy', DummyHandle->new);
    my $stats = $r->stats;
    is $stats->{dummy}{class}, 'DummyHandle', 'stats falls back to class';
    ok $r->mount_info('dummy')->{transient}, 'dummy mount transient';
};

subtest 'hashref specs and special constructors' => sub {
    my $r = Data::Shared->new;
    my $h = eval { $r->mount('w', { spec => 'reservoir', ctor => 'new_weighted', args => [undef, 10] }) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_call($r, '/w', 'add', 'x', 1.0);
    is shared_call($r, '/w', 'seen'), 1, 'hashref spec with ctor';
    # An unweighted reservoir accepts and ignores the weight too.
    ok shared_call($r, '/w', 'is_weighted'), 'and the constructor named is the one that ran';
    $r->mount('wv', 'reservoir:weighted', undef, 10);
    ok shared_call($r, '/wv', 'is_weighted'), 'the registry variant builds one too';
    $r->mount('plain', 'reservoir', undef, 10);
    ok !shared_call($r, '/plain', 'is_weighted'), 'and the plain family does not';
    SKIP: {
        skip 'topk:decayed unavailable', 1
            unless eval { require Data::TopK::Shared; 1 };
        ok eval { $r->mount('td', 'topk:decayed', undef, 16, 32, 60); 1 },
            'a variant whose constructor takes an extra argument mounts' or diag $@;
    }
    SKIP: {
        my $r2 = Data::Shared->new;
        skip 'sortedset:strings unavailable', 3
            unless eval { require Data::SortedSet::Shared::Strings; 1 };
        $r2->mount('board', 'sortedset:strings', max => 100, set => undef, keys => undef);
        shared_set($r2, '/board/alice', 42);
        is shared_get($r2, '/board/alice'), 42, 'strings via list form anonymous';
        ok !eval { $r2->mount('bad', 'sortedset:strings', {}); 1 }, 'strings without max croaks';
        like $@, qr/requires 'max'/, 'max error';
    }
};

subtest 'perfecthash forms' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new($dir);
    my $h = eval { $r->mount('words', 'perfecthash', { build_str => ['apple', 'banana'], path => "$dir/words.phs" }) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    ok shared_exists($r, '/words/banana'), 'build_str exists';
    is shared_exists($r, '/words/durian'), 0, 'build_str absent';
    is shared_get($r, '/words/apple'), 1, 'get is has';
    ok !eval { shared_set($r, '/words/x', 1); 1 }, 'perfecthash set croaks';
    my $r2 = Data::Shared->new;
    $r2->mount('loaded', 'perfecthash', "$dir/words.phs");
    ok shared_exists($r2, '/loaded/apple'), 'load by existing file path';
    ok !eval { $r2->mount('missing', 'perfecthash', { path => "$dir/nope.phs" }); 1 }, 'missing build file croaks';
    like $@, qr/does not exist/, 'missing file error';
    ok !eval { $r2->mount('junk', 'perfecthash', 42); 1 }, 'junk perfecthash args croak';
    my $reopened = Data::Shared->open($dir);
    ok shared_exists($reopened, '/words/banana'), 'perfecthash survives manifest replay';
};

subtest 'buffer explicit path on anonymous root' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new;
    my $h = eval { $r->mount('buf', 'buffer:i64', "$dir/buf.shm", 100) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_set($r, '/buf/0', 42);
    is shared_get($r, '/buf/0'), 42, 'explicit path buffer';
    is $r->mount_info('buf')->{file}, "$dir/buf.shm", 'file recorded from args';
};

subtest 'readonly pushpop and compiled mutators croak' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $r = Data::Shared->new($dir);
    my $h = eval { $r->mount('jobs', 'queue:int', undef, 100) };
    if ($@) { plan skip_all => "backend unavailable: $@"; return }
    shared_push($r, '/jobs', 42);
    # The set cases need a keyed mount (a queue refuses set on any root), and a
    # buffer: a freeze-capable family refuses a read-only open of a live file.
    my $keyed = eval { $r->mount('cache', 'buffer:i64', undef, 64); 1 };
    my $ro = Data::Shared->open_readonly($dir);
    ok $ro->readonly, 'readonly root';
    for my $case (['shared_push',  sub { shared_push($ro, '/jobs', 1) },                  'push'],
                  ['shared_pop',   sub { shared_pop($ro, '/jobs') },                      'pop'],
                  ['sharedc_push', sub { sharedc_push($ro, shared_compile('/jobs'), 1) }, 'push'],
                  ['sharedc_pop',  sub { sharedc_pop($ro, shared_compile('/jobs')) },     'pop'],
                  ($keyed ? (['sharedc_set',    sub { sharedc_set($ro, shared_compile('/cache/1'), 1) },    'set'],
                             ['sharedc_delete', sub { sharedc_delete($ro, shared_compile('/cache/1')) },    'delete'],
                             ['sharedc_incr',   sub { sharedc_incr($ro, shared_compile('/cache/1'), 1) },   'incr'],
                             ['shareda_set',    sub { shareda_set($ro, ['cache', 1], 1) },                  'set']) : ())) {
        my ($name, $code, $verb) = @$case;
        ok !eval { $code->(); 1 }, "readonly $name croaks";
        like $@, qr/\AData::Shared: root is read-only, cannot \Q$verb\E\b/,
            "and it is the facade that refuses $name";
    }
};

subtest 'adapter error branches' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'lat', 'ndarray', undef, 'f64', 2, 2);
    mount_or_skip($r, 'freq', 'countminsketch', undef, 0.001, 0.001);
    mount_or_skip($r, 'sem', 'sync:semaphore', undef, 2);
    mount_or_skip($r, 'cache', 'hashmap:ii', undef, 100);
    ok !eval { shared_get($r, '/lat'); 1 }, 'indexed without index croaks';
    like $@, qr/no index/, 'indexed error';
    ok !eval { shared_get($r, '/freq'); 1 }, 'sketch without key croaks';
    like $@, qr/no key/, 'sketch error';
    ok !eval { shared_push($r, '/sem', 1); 1 }, 'sync push croaks';
    ok !eval { shared_pop($r, '/sem'); 1 }, 'sync pop croaks';
    ok !eval { shared_push($r, '/cache', 1); 1 }, 'map push croaks';
    ok !eval { shared_pop($r, '/cache'); 1 }, 'map pop croaks';
    ok !eval { shared_push($r, '/lat', 1); 1 }, 'indexed push croaks';
    ok !eval { shared_get($r, '/sem'); 1 }, 'sync get via fallback croaks';
    ok !eval { sharedc_get($r, shared_compile('/lat')); 1 }, 'compiled indexed without index croaks';
    ok !eval { sharedc_get($r, shared_compile('/freq')); 1 }, 'compiled sketch without key croaks';
};

subtest 'a call error names the operation, not one tier' => sub {
    my $r = Data::Shared->new;
    mount_or_skip($r, 'cache', 'hashmap:ii', undef, 64);
    for my $case (['string', sub { shared_call($r, '/cache', undef) }],
                  ['array', sub { Data::Shared::shareda_call($r, ['cache'], undef) }],
                  ['compiled', sub { sharedc_call($r, shared_compile('/cache'), undef) }]) {
        my ($tier, $call) = @$case;
        ok !eval { $call->(); 1 }, "$tier: a missing method name is refused";
        like $@, qr/a call requires a method name/, "$tier: without naming another tier";
        unlike $@, qr/shared_call|shareda_call|sharedc_call/, "$tier: or any one spelling";
    }
    my $croot = shared_compile('/');
    for my $tier (['shared_call',  sub { shared_call($r, '/', 'stats') }],
                  ['shareda_call', sub { shareda_call($r, [], 'stats') }],
                  ['sharedc_call', sub { sharedc_call($r, $croot, 'stats') }],
                  ['node->call',   sub { $r->node('/')->call('stats') }]) {
        my ($name, $code) = @$tier;
        ok !eval { $code->(); 1 }, "$name: the root is not a call target";
        like $@, qr/\AData::Shared: a call path must name a mount\b/,
            "$name: and says so in the same terms";
        like $@, qr/ at \Q$0\E line \d+/, "$name: blaming a line in this file";
    }
    ok !eval { $r->node('/cache')->call(''); 1 }, 'a cursor refuses an empty method name';
    like $@, qr/node call requires a method name/, 'by its own guard';
};

subtest 'an explicit backing path must be absolute' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new("$dir/store");
    ok !eval { $root->mount('stats', 'hashmap:ii', 'stats.shm', 16); 1 },
        'a relative explicit path is refused';
    like $@, qr/must be absolute/, 'and says why';
    for my $bad ([], \my $scalar, sub { }) {
        ok !eval { $root->mount('ref' . (0 + $bad), 'hashmap:ii', $bad, 16); 1 },
            'an ' . ref($bad) . ' reference in the path slot is refused';
        like $@, qr/invalid backing path for/, 'by the path check, not the backend';
    }
    # The refusals above load no backend, so they run unguarded.
    SKIP: {
        eval { require Data::HashMap::Shared::II; 1 }
            or skip 'hashmap backend unavailable', 2;
        ok eval { $root->mount('stats', 'hashmap:ii', "$dir/stats.shm", 16); 1 },
            'the absolute form mounts' or diag $@;
        # chdir so the relative root lands in the temp dir, not the checkout.
        my $start = Cwd::getcwd();
        chdir $dir or die $!;
        my $here = Data::Shared->new('relative-root');
        ok eval { $here->mount('derived', 'hashmap:ii', undef, 16); 1 },
            'a derived path under a relative root still mounts' or diag $@;
        chdir $start or die $!;
    }

    SKIP: {
        eval { require Data::SortedSet::Shared::Strings; 1 }
            or skip 'Data::SortedSet::Shared::Strings not installed', 3;
        my $s = Data::Shared->new("$dir/strings");
        ok !eval { $s->mount('names', 'sortedset:strings',
                             { max => 100, set => 'rel-set.shm' }); 1 },
            'a relative set path is refused too';
        like $@, qr/must be absolute/, 'by the same rule';
        ok eval { $s->mount('names', 'sortedset:strings', { max => 100 }); 1 },
            'and leaving both paths to be derived still mounts' or diag $@;
    }
};

subtest 'a flat spec names the placeholder and the constructor once' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    SKIP: {
        skip 'sortedset:strings unavailable', 4
            unless eval { $root->mount('probe', 'sortedset:strings', { max => 8 }); 1 };
        for my $placeholder (undef, ':file') {
            my $label = defined $placeholder ? "'$placeholder'" : 'undef';
            ok !eval { $root->mount("ph$label", 'sortedset:strings', $placeholder, { max => 8 }); 1 },
                "a $label placeholder is refused";
            like $@, qr/sortedset:strings takes options, not a path placeholder/,
                "$label: with the same words as the other spelling";
        }
    }
    SKIP: {
        skip 'perfecthash unavailable', 2
            unless eval { Data::Shared->new(tempdir(CLEANUP => 1))
                              ->mount('p', 'perfecthash', { build_int => [1, 2] }); 1 };
        ok !eval { $root->mount('pc', { spec => 'perfecthash', ctor => 'no_such',
                       args => [{ build_int => [1, 2] }] }); 1 },
            'a ctor named for perfecthash is refused';
        like $@, qr/\QData::PerfectHash::Shared\E spec does not take a ctor; it is constructed by load/,
            'saying what constructs it';
    }
    SKIP: {
        skip 'hashmap unavailable', 2
            unless eval { $root->mount('probe-hm', 'hashmap:ii', undef, 16); 1 };
        ok eval { $root->mount('plain', { spec => 'hashmap:ii', ctor => 'new',
                       args => [undef, 16] }); 1 },
            'a ctor the family really uses still mounts' or diag $@;
        is shared_set($root, '/plain/1', 7), 1, 'and the mount works';
    }
};

done_testing;
