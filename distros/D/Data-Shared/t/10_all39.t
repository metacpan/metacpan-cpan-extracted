use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_exists shared_call shared_push shared_pop shared_incr);

my %CASE = (
    bitset => { args => [undef, 256], run => sub { my ($r) = @_;
        shared_set($r, '/x/10', 1); is shared_get($r, '/x/10'), 1, 'bitset' } },
    bloomfilter => { args => [undef, 10000, 0.01], run => sub { my ($r) = @_;
        shared_set($r, '/x/alice', 1); ok shared_exists($r, '/x/alice'), 'bloom' } },
    buffer => { args => [undef, 100], variant => 'buffer:i64', run => sub { my ($r) = @_;
        shared_set($r, '/x/0', 42); is shared_get($r, '/x/0'), 42, 'buffer' } },
    countingbloomfilter => { args => [undef, 10000, 0.01], run => sub { my ($r) = @_;
        shared_set($r, '/x/a', 1); is shared_get($r, '/x/a'), 1, 'countingbloom' } },
    countminsketch => { args => [undef, 0.001, 0.001], run => sub { my ($r) = @_;
        shared_set($r, '/x/a', 3); cmp_ok shared_get($r, '/x/a'), '>=', 3, 'cms' } },
    cuckoofilter => { args => [undef, 10000], run => sub { my ($r) = @_;
        shared_set($r, '/x/a', 1); ok shared_exists($r, '/x/a'), 'cuckoo' } },
    ddsketch => { args => [undef, 0.01], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'add', 10); ok defined shared_call($r, '/x', 'quantile', 0.5), 'ddsketch' } },
    deque => { args => [undef, 100], variant => 'deque:int', run => sub { my ($r) = @_;
        shared_push($r, '/x', 7); is shared_pop($r, '/x'), 7, 'deque' } },
    disjointset => { args => [undef, 100], run => sub { my ($r) = @_;
        shared_set($r, '/x/0', 1); is shared_get($r, '/x/0'), shared_get($r, '/x/1'), 'disjointset' } },
    fenwick => { args => [undef, 100], run => sub { my ($r) = @_;
        shared_incr($r, '/x/5', 3); is shared_get($r, '/x/5'), 3, 'fenwick' } },
    fenwick2d => { args => [undef, 10, 10], run => sub { my ($r) = @_;
        shared_set($r, '/x/2/3', 9); is shared_get($r, '/x/2/3'), 9, 'fenwick2d' } },
    graph => { args => [undef, 100, 500], run => sub { my ($r) = @_;
        my $a = shared_call($r, '/x', 'add_node', 10); is shared_get($r, "/x/$a"), 10, 'graph' } },
    hashmap => { args => [undef, 1000], variant => 'hashmap:ii', run => sub { my ($r) = @_;
        shared_set($r, '/x/1', 2); is shared_get($r, '/x/1'), 2, 'hashmap' } },
    heap => { args => [undef, 100], run => sub { my ($r) = @_;
        shared_push($r, '/x', 1, 100); my ($p, $v) = shared_pop($r, '/x'); is $v, 100, 'heap' } },
    hiertimingwheel => { args => [undef, 256, 4, 1000], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'add', 5, 77); my @d = shared_call($r, '/x', 'advance', 5);
        ok((grep { $_ == 77 } @d), 'hiertimingwheel') } },
    histogram => { args => [undef, 1, 3600000000, 3], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'record', 120); ok shared_call($r, '/x', 'total_count') >= 1, 'histogram' } },
    hyperloglog => { args => [undef, 14], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'add', 'a'); cmp_ok shared_call($r, '/x', 'count'), '>=', 1, 'hll' } },
    intern => { args => [undef, 1000, 65536], run => sub { my ($r) = @_;
        is shared_set($r, '/x/alice'), 0, 'intern' } },
    intervaltree => { args => [undef, 1000], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'add', 10, 20, 42); my @h = shared_call($r, '/x', 'stab', 15);
        is $h[0]{id}, 42, 'intervaltree' } },
    kdtree => { args => [undef, 2, 1000], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'add', [1, 2], 9); is shared_call($r, '/x', 'nearest', [1, 2])->{id}, 9, 'kdtree' } },
    log => { args => [undef, 100000], run => sub { my ($r) = @_;
        shared_push($r, '/x', 'entry'); is shared_call($r, '/x', 'entry_count'), 1, 'log' } },
    minhash => { args => [undef, 256], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'add', 'a'); is shared_call($r, '/x', 'size'), 256, 'minhash' } },
    ndarray => { args => [undef, 'f64', 2, 2], run => sub { my ($r) = @_;
        shared_set($r, '/x/0/1', 3); is shared_get($r, '/x/0/1'), 3, 'ndarray' } },
    perfecthash => { args => [], run => sub { my ($r) = @_;
        ok shared_exists($r, '/x/13'), 'perfecthash' } },
    pool => { args => [undef, 100], variant => 'pool:i64', run => sub { my ($r) = @_;
        my $i = shared_call($r, '/x', 'alloc'); shared_set($r, "/x/$i", 5);
        is shared_get($r, "/x/$i"), 5, 'pool' } },
    pubsub => { args => [undef, 1024], variant => 'pubsub:int', run => sub { my ($r) = @_;
        my $s = shared_call($r, '/x', 'subscribe'); shared_push($r, '/x', 42);
        is $s->poll, 42, 'pubsub' } },
    queue => { args => [undef, 1024], variant => 'queue:int', run => sub { my ($r) = @_;
        shared_push($r, '/x', 42); is shared_pop($r, '/x'), 42, 'queue' } },
    radixtree => { args => [undef, 4096, 65536], run => sub { my ($r) = @_;
        shared_set($r, '/x/foo', 1); is shared_get($r, '/x/foo'), 1, 'radixtree' } },
    reqrep => { args => [undef, 1024, 64, 4096], run => sub { my ($r) = @_;
        ok $r->handle('/x')->can('stats'), 'reqrep mounted' } },
    reservoir => { args => [undef, 100], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'add', 1); is shared_call($r, '/x', 'seen'), 1, 'reservoir' } },
    ringbuffer => { args => [undef, 100], variant => 'ringbuffer:int', run => sub { my ($r) = @_;
        shared_push($r, '/x', 42); is shared_get($r, '/x'), 42, 'ringbuffer' } },
    roaringbitmap => { args => [undef, 256], run => sub { my ($r) = @_;
        shared_set($r, '/x/5', 1); ok shared_exists($r, '/x/5'), 'roaring' } },
    segmenttree => { args => [undef, 100], run => sub { my ($r) = @_;
        shared_set($r, '/x/10', 42); is shared_get($r, '/x/10'), 42, 'segmenttree' } },
    sortedset => { args => [undef, 1000], run => sub { my ($r) = @_;
        shared_set($r, '/x/42', 1500); is shared_get($r, '/x/42'), 1500, 'sortedset' } },
    spatialhash => { args => [undef, 1000, 0, 1.0], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'insert', 10.5, 20.5, 42);
        my @h = shared_call($r, '/x', 'query_radius', 10, 20, 5);
        ok((grep { $_ == 42 } @h), 'spatialhash') } },
    stack => { args => [undef, 100], variant => 'stack:int', run => sub { my ($r) = @_;
        shared_push($r, '/x', 42); is shared_pop($r, '/x'), 42, 'stack' } },
    sync => { args => [undef, 2], variant => 'sync:semaphore', run => sub { my ($r) = @_;
        ok shared_call($r, '/x', 'try_acquire'), 'sync' } },
    timingwheel => { args => [undef, 512, 1000], run => sub { my ($r) = @_;
        shared_call($r, '/x', 'add', 5, 77); my @d = shared_call($r, '/x', 'advance', 5);
        ok((grep { $_ == 77 } @d), 'timingwheel') } },
    topk => { args => [undef, 100], run => sub { my ($r) = @_;
        shared_set($r, '/x/popular'); cmp_ok shared_get($r, '/x/popular'), '>=', 1, 'topk' } },
);

my @keys = Data::Shared->available_types;
is scalar(@keys), 39, '39 keys';
is_deeply [sort keys %CASE], \@keys, 'case table covers every registry key';

my @absent;

for my $key (@keys) {
    subtest $key => sub {
        my $dir = tempdir(CLEANUP => 1);
        my $root = Data::Shared->new($dir);
        my $case = $CASE{$key};
        my $spec = $case->{variant} // $key;
        my @args = @{ $case->{args} };
        if ($key eq 'perfecthash') {
            @args = ({ build_int => [1, 2, 3, 5, 8, 13] });
        }
        my $resolved = Data::Shared::Registry::resolve_spec($spec);
        if (!eval { Data::Shared::_require_class($resolved->{load}); 1 }) {
            push @absent, $key;
            plan skip_all => "backend unavailable: $@";
            return;
        }
        my $h = $root->mount('x', $spec, @args);
        ok $h, 'mounted';
        is $root->mount_info('x')->{key}, $key, 'mount_info key';
        $case->{run}->($root);
        my $again = Data::Shared->open($dir);
        is $again->mount_info('x')->{key}, $key, 'reopened existing storage';
    };
}

# A skipped subtest still scores a pass, so say how many backends actually ran.
my $ran = @keys - @absent;
diag sprintf 'backends exercised: %d/%d%s', $ran, scalar @keys,
    @absent ? ' (absent: ' . join(', ', @absent) . ')' : '';
if ($ENV{DS_ALL_BACKENDS}) {
    is scalar @absent, 0,
        'DS_ALL_BACKENDS: every backend was exercised'
        or diag 'absent: ' . join(', ', @absent);
}

subtest 'every variant mounts as the class the registry names' => sub {
    my %override = (
        'buffer:str'        => [undef, 100, 32],
        'deque:str'         => [undef, 100, 32],
        'pool:str'          => [undef, 100, 32],
        'stack:str'         => [undef, 100, 32],
        'reqrep:int'        => [undef, 1024, 64],
        'sortedset:strings' => [{ max => 100 }],
        'topk:decayed'      => [undef, 16, 32, 60],
    );
    my $table = Data::Shared::Registry::registry();
    my (@absent, $ran);
    for my $key (sort keys %$table) {
        my $variants = $table->{$key}{variants} or next;
        for my $vname (sort keys %$variants) {
            my $spec = lc "$key:$vname";
            my $want = Data::Shared::Registry::resolve_spec($spec)
                or do { fail "$spec resolves"; next };
            my $args = $override{$spec} || ($CASE{$key} && $CASE{$key}{args})
                or do { fail "$spec has an argument row"; next };
            my $mod = $want->{load} || $want->{class};
            (my $file = "$mod.pm") =~ s{::}{/}g;
            unless (eval { require $file; 1 }) { push @absent, $spec; next }
            $ran++;
            my $root = Data::Shared->new(tempdir(CLEANUP => 1));
            ok eval { $root->mount('x', $spec, @$args); 1 }, "$spec mounts"
                or do { diag $@; next };
            is $root->mount_info('x')->{class}, $want->{class},
                "$spec is the class the registry names";
        }
    }
    diag sprintf 'variants exercised: %d%s', $ran,
        @absent ? ' (absent: ' . join(', ', @absent) . ')' : '';
    # A subtest that runs no test is a failure rather than a skip.
    plan skip_all => 'no variant backend is installed' unless $ran;
    if ($ENV{DS_ALL_BACKENDS}) {
        is scalar @absent, 0, 'DS_ALL_BACKENDS: every variant was exercised'
            or diag 'absent: ' . join(', ', @absent);
    }
};

done_testing;
