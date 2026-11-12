use strict; use warnings; use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_exists shared_incr shared_call);

sub mounted {
    my ($root, $name, @spec) = @_;
    return 1 if eval { $root->mount($name, @spec); 1 };
    my $err = $@;
    return 0 if $err =~ /is not available; install the|Can't locate \S+\.pm/;
    fail "mounting '$spec[0]' failed for a reason other than a missing backend";
    diag $err;
    return 0;
}
my $root = Data::Shared->new;
mounted($root, 'ds', 'disjointset', undef, 100)
    or plan skip_all => 'disjointset unavailable';
# A missing second member must not numify to 0 and union with element 0.
my @w; local $SIG{__WARN__} = sub { push @w, $_[0] };
isnt shared_get($root, '/ds/0'), shared_get($root, '/ds/3'), 'members start apart';
ok !eval { shared_set($root, '/ds/3'); 1 }, 'set without a second member croaks';
like $@, qr/needs a second member/, 'croak explains what is missing';
isnt shared_get($root, '/ds/0'), shared_get($root, '/ds/3'), 'no merge happened';
is scalar @w, 0, 'no uninitialized warning' or diag join '', @w;
shared_set($root, '/ds/8', 9);
is shared_get($root, '/ds/8'), shared_get($root, '/ds/9'), 'the two-member form still unions';

# fenwick is 1-based, the rest 0-based.
subtest 'exists answers correctly at every integer leaf boundary' => sub {
    my @leaf = (
        ['bitset', [1000], sub { shared_set($_[0], '/x/7', 1); ([7, 1]) },
            [[-1, 0], [0, 0], [999, 0], [1000, 0], [1_000_000, 0]]],
        ['buffer', [64], undef,
            [[-1, 0], [0, 1], [63, 1], [64, 0], [1_000_000, 0]]],
        ['disjointset', [64], undef,
            [[-1, 0], [0, 1], [63, 1], [64, 0]]],
        ['fenwick', [64], undef,
            [[-1, 0], [0, 0], [1, 1], [64, 1], [65, 0]]],
        ['segmenttree', [64], undef,
            [[-1, 0], [0, 1], [63, 1], [64, 0]]],
        ['pool', [100, 8], sub { ([scalar shared_call($_[0], '/x', 'alloc'), 1]) },
            [[-1, 0], [100, 0]]],
    );
    my $tested = 0;
    for my $row (@leaf) {
        my ($key, $args, $populate, $pairs) = @$row;
        my $r = Data::Shared->new;
        unless (mounted($r, 'x', $key, undef, @$args)) {
            note "$key unavailable, its bounds are not covered here";
            next;
        }
        $tested++;
        my @extra = $populate ? $populate->($r) : ();
        for my $pair (@$pairs, @extra) {
            my ($idx, $want) = @$pair;
            my $got = eval { shared_exists($r, "/x/$idx") };
            ok !$@, "$key: exists($idx) does not croak" or diag $@;
            is $got, $want, "$key: exists($idx) answers $want";
        }
    }
    plan skip_all => 'no integer leaf available' unless $tested;
};

subtest 'the hashmap key type follows the variant, however it is mounted' => sub {
    my $tested = 0;
    my $made = sub { my $class = "Data::HashMap::Shared::$_[0]"; sub { $class->new(undef, 100) } };
    for my $case (['hashmap', 1], ['hashmap:ii', 1], ['hashmap:is', 1],
                  ['hashmap:ss', 0], ['hashmap:si', 0],
                  ['Data::HashMap::Shared::SS', 0], ['Data::HashMap::Shared::II', 1],
                  ['factory SS', 0, $made->('SS')], ['factory II', 1, $made->('II')]) {
        my ($spec, $integer_keyed, @mount) = @$case;
        @mount = ($spec, undef, 100) unless @mount;
        my $r = Data::Shared->new;
        next if $spec =~ /^factory/ && !Data::HashMap::Shared::SS->can('new');
        next unless mounted($r, 'x', @mount);
        $tested++;
        shared_set($r, '/x/0', 7);
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        my $took = eval { shared_set($r, '/x/abc', 99); 1 };
        my $err = $@;
        if ($integer_keyed) {
            ok !$took, "$spec: a word key is refused";
            like $err, qr/index must be an integer/, "$spec: by the index guard";
            is scalar @warnings, 0, "$spec: without warning its way through";
        }
        else {
            ok $took, "$spec: a word is an ordinary key" or diag $err;
            is eval { shared_get($r, '/x/abc') }, 99, "$spec: stored under that word";
        }
        is shared_get($r, '/x/0'), 7, "$spec: and key 0 is untouched";
    }
    plan skip_all => 'no hashmap variant is installed' unless $tested;
};

subtest 'a perfecthash takes its key type from the built file' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $read = sub { open my $fh, '<', "$dir/manifest.json" or die $!; local $/; <$fh> };
    {
        my $r = Data::Shared->new($dir);
        plan skip_all => 'perfecthash unavailable'
            unless mounted($r, 'ph', 'perfecthash', { build_int => [0, 1, 2] });
        is shared_exists($r, '/ph/1'), 1, 'an integer member is a member';
        is shared_exists($r, '/ph/abc'), 0, 'a word is not key 0';
        ok !eval { shared_get($r, '/ph/abc'); 1 }, 'and get refuses it';
        unlike $read->(), qr/build_int/, 'the manifest keeps no key list';
    }
    my $again = Data::Shared->open($dir);
    is shared_exists($again, '/ph/1'), 1, 'replay still finds the members';
    is shared_exists($again, '/ph/abc'), 0, 'and still refuses the word, with no build spec to read';
};

# bitset and graph check the index shape in their own exists closures, the rest
# in the keyed adapter, which a compiled path reaches separately.
subtest 'a non-integer index is not index zero' => sub {
    my $tested = 0;
    my $set_zero = sub { shared_set($_[0], '/x/0', 1) };
    for my $case (['bitset', [1000], $set_zero],
                  ['graph', [100, 500], sub { shared_call($_[0], '/x', 'add_node', 5) }],
                  ['hashmap:ii', [16], $set_zero], ['sortedset', [100], $set_zero],
                  ['roaringbitmap', [256], $set_zero]) {
        my ($key, $args, $seed) = @$case;
        my $r = Data::Shared->new;
        unless (mounted($r, 'x', $key, undef, @$args)) {
            note "$key unavailable";
            next;
        }
        $tested++;
        $seed->($r);
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        is shared_exists($r, '/x/0'), 1, "$key: index 0 is set";
        is shared_exists($r, '/x/foo'), 0, "$key: a word is not index 0";
        is Data::Shared::sharedc_exists($r, Data::Shared::shared_compile('/x/foo')), 0,
            "$key: nor through a compiled path";
        is scalar @warnings, 0, "$key: and nothing reached the backend to warn";
    }
    plan skip_all => 'no integer leaf available' unless $tested;
};

subtest 'a sketch does not claim every key exists' => sub {
    my $tested = 0;
    for my $row (['countminsketch', [0.001, 0.001], 'add'], ['topk', [100], 'add']) {
        my ($key, $args, $add) = @$row;
        my $r = Data::Shared->new;
        unless (mounted($r, 'x', $key, undef, @$args)) {
            note "$key unavailable";
            next;
        }
        $tested++;
        is shared_exists($r, '/x/absent'), 0, "$key: a key never added does not exist";
        shared_call($r, '/x', $add, 'present', 1);
        is shared_exists($r, '/x/present'), 1, "$key: one that was added does";
        is shared_exists($r, '/x/absent'), 0, "$key: and the first still does not";
    }
    plan skip_all => 'no sketch available' unless $tested;
};

subtest 'exists is bounded for graph too, which has no capacity to read' => sub {
    my $r = Data::Shared->new;
    mounted($r, 'g', 'graph', undef, 16, 16)
        or plan skip_all => 'graph unavailable';
    for my $idx (-1, 0, 3, 4294967295, 4294967296, 99999999999999) {
        my $got = eval { shared_exists($r, "/g/$idx") };
        ok !$@, "exists($idx) does not croak" or diag $@;
        is $got, 0, "exists($idx) is 0 on an empty graph";
    }
    my $id = shared_call($r, '/g', 'add_node', 7);
    is shared_exists($r, "/g/$id"), 1, 'and still answers 1 for a node that is there';
};
subtest 'every indexed leaf refuses a non-integer index' => sub {
    my $digit = "\x{661}";                      # ARABIC-INDIC DIGIT ONE
    # graph has no set verb.
    my @cases = (['ndarray', ['f64', 2, 3], 2, 'set'], ['fenwick2d', [24, 7], 2, 'set'],
                 ['graph', [100, 500], 1, 'get'], ['fenwick', [100], 1, 'set'],
                 ['segmenttree', [100], 1, 'set'], ['bitset', [1000], 1, 'set'],
                 ['pool', [100, 8], 1, 'set']);
    my $tested = 0;
    for my $case (@cases) {
        my ($key, $args, $dims, $verb) = @$case;
        my $r = Data::Shared->new;
        next unless mounted($r, 'x', $key, undef, @$args);
        $tested++;
        my $call = $verb eq 'set' ? sub { shared_set($r, $_[0], 7) } : sub { shared_get($r, $_[0]) };
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        my $path = '/x/' . join('/', ($digit) x $dims);
        ok !eval { $call->($path); 1 }, "$key: a non-ASCII digit index is refused";
        like $@, qr/index must be an integer/, "$key: by the index guard";
        is scalar @warnings, 0, "$key: and does not warn its way through"
            or diag join '', @warnings;
        my $ok = '/x/' . join('/', (1) x $dims);
        my $went = eval { $call->($ok); 1 };
        my $err = $@;
        if ($key eq 'graph') {
            ok !$went, 'graph: reading a node that was never added fails';
            like $err, qr/does not exist/, 'graph: at the backend, not the guard';
        }
        elsif ($key eq 'pool') {
            ok !$went, 'pool: writing an unallocated slot fails';
            like $err, qr/not allocated/, 'pool: at the backend, not the guard';
        }
        else {
            ok $went, "$key: an ordinary index works" or diag $err;
        }
    }
    plan skip_all => 'no indexed backend available' unless $tested;
};

subtest 'sortedset incr requires a delta' => sub {
    my $tested = 0;
    for my $spec ('sortedset', 'sortedset:strings') {
        my $r = Data::Shared->new;
        my @args = $spec eq 'sortedset' ? (undef, 100) : ({ max => 100 });
        next unless mounted($r, 's', $spec, @args);
        $tested++;
        my $member = $spec eq 'sortedset' ? 1 : 'a';
        shared_set($r, "/s/$member", 10);
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        ok !eval { shared_incr($r, "/s/$member"); 1 }, "$spec: a bare incr is refused";
        is scalar @warnings, 0, "$spec: without warning its way through"
            or diag join '', @warnings;
        is shared_get($r, "/s/$member"), 10, "$spec: and the score is untouched";
        my $ghost = $spec eq 'sortedset' ? 99 : 'ghost';
        ok !eval { shared_incr($r, "/s/$ghost"); 1 },
            "$spec: a bare incr on an absent member is refused too";
        ok !shared_exists($r, "/s/$ghost"), "$spec: a refused incr leaves no member";
        ok eval { shared_incr($r, "/s/$member", 5); 1 }, "$spec: a delta still works" or diag $@;
        is shared_get($r, "/s/$member"), 15, "$spec: and applies it";
    }
    plan skip_all => 'no sortedset backend available' unless $tested;
};

subtest 'pool incr works with and without a delta' => sub {
    my $tested = 0;
    for my $variant (qw(i64 i32 f64 str)) {
        my $r = Data::Shared->new;
        next unless mounted($r, 'p', "pool:$variant", undef, 100, 8);
        $tested++;
        my $slot = shared_call($r, '/p', 'alloc');
        my $handle = $r->handle('/p');
        ok eval { shared_set($r, "/p/$slot", 10); 1 }, "pool:$variant: the fixture writes"
            or do { diag $@; next };
        if ($handle->can('incr')) {
            my $bare = eval { shared_incr($r, "/p/$slot"); 1 };
            ok $bare, "pool:$variant: a bare incr works" or diag $@;
            is shared_get($r, "/p/$slot"), 11, "pool:$variant: and adds one";
            ok eval { shared_incr($r, "/p/$slot", 5); 1 }, "pool:$variant: a delta works" or diag $@;
            is shared_get($r, "/p/$slot"), 16, "pool:$variant: and adds the delta";
        }
        else {
            my $bare = eval { shared_incr($r, "/p/$slot"); 1 };
            my $err = $@;
            ok !$bare, "pool:$variant: supports neither form, so it is refused";
            like $err, qr/does not support 'incr'/, "pool:$variant: and says so";
        }
    }
    plan skip_all => 'no pool backend available' unless $tested;
};

subtest 'buffer incr takes a delta on integer variants' => sub {
    my $tested = 0;
    for my $variant (qw(i8 u16 i32 u64 i64)) {
        my $r = Data::Shared->new;
        next unless mounted($r, 'b', "buffer:$variant", undef, 10);
        $tested++;
        is shared_incr($r, '/b/3'), 1, "buffer:$variant: a bare incr adds one";
        is shared_incr($r, '/b/3', 5), 6, "buffer:$variant: a delta is added";
    }
    my $r = Data::Shared->new;
    if (mounted($r, 'f', 'buffer:f64', undef, 10)) {
        $tested++;
        ok !eval { shared_incr($r, '/f/3', 5); 1 }, 'buffer:f64: no integer to count in';
        like $@, qr/does not support 'incr' with a delta/, 'and says so';
    }
    plan skip_all => 'no buffer backend available' unless $tested;
};

subtest 'graph exists answers rather than croaking' => sub {
    my $r = Data::Shared->new;
    mounted($r, 'g', 'graph', undef, 100, 500) or plan skip_all => 'graph unavailable';
    my $id = shared_call($r, '/g', 'add_node', 1);
    is shared_exists($r, "/g/$id"), 1, 'a node that exists';
    is shared_exists($r, '/g/99'), 0, 'and one that does not';
};

subtest 'a one-dimensional leaf refuses a second index' => sub {
    my $r = Data::Shared->new;
    mounted($r, 'arr', 'segmenttree', undef, 100) or plan skip_all => 'segmenttree unavailable';
    shared_set($r, '/arr/10', 55);
    is shared_get($r, '/arr/10'), 55, 'the point query works';
    ok !eval { shared_get($r, '/arr/10/20'); 1 }, 'a second index is refused';
    like $@, qr/takes one index/, 'and says so';
};

subtest 'an explicit undef incr delta is refused on every tier' => sub {
    my $r = Data::Shared->new;
    mounted($r, 'c', 'hashmap:ii', undef, 64) or plan skip_all => 'hashmap unavailable';
    shared_set($r, '/c/1', 10);

    is shared_incr($r, '/c/1'), 11, 'a delta left out still means the default';
    for my $tier (['string', sub { shared_incr($r, '/c/1', undef) }],
                  ['array', sub { Data::Shared::shareda_incr($r, ['c', 1], undef) }],
                  ['compiled', sub {
                      Data::Shared::sharedc_incr($r, Data::Shared::shared_compile('/c/1'), undef) }]) {
        my ($name, $call) = @$tier;
        ok !eval { $call->(); 1 }, "the $name tier refuses an undef delta";
        like $@, qr/incr delta must be a number, not undef/, "and says so ($name)";
    }
    is shared_get($r, '/c/1'), 11, 'and none of them changed the value';
    is shared_incr($r, '/c/1', 5), 16, 'a real delta still applies';
};

done_testing;
