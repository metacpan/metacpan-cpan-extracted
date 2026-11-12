use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Data::Shared qw(shared_get shared_set shared_exists shared_call shared_push shared_pop shared_incr);
use Data::Shared::Registry ();

# The parent seeds and the child only reads, so a child that opened an
# unrelated store cannot pass.

my %CASE = (
    bitset       => { args => [undef, 256],
        seed => sub { shared_set($_[0], '/x/10', 1) },
        read => sub { shared_get($_[0], '/x/10') }, want => 1 },
    bloomfilter  => { args => [undef, 10000, 0.01],
        seed => sub { shared_set($_[0], '/x/alice', 1) },
        read => sub { shared_exists($_[0], '/x/alice') }, want => 1 },
    buffer       => { args => [undef, 100], variant => 'buffer:i64',
        seed => sub { shared_set($_[0], '/x/0', 42) },
        read => sub { shared_get($_[0], '/x/0') }, want => 42 },
    countingbloomfilter => { args => [undef, 10000, 0.01],
        seed => sub { shared_set($_[0], '/x/a', 1) },
        read => sub { shared_get($_[0], '/x/a') }, want => 1 },
    countminsketch => { args => [undef, 0.001, 0.001],
        seed => sub { shared_set($_[0], '/x/a', 3) },
        read => sub { shared_get($_[0], '/x/a') }, want => 3 },
    cuckoofilter => { args => [undef, 10000],
        seed => sub { shared_set($_[0], '/x/a', 1) },
        read => sub { shared_exists($_[0], '/x/a') }, want => 1 },
    ddsketch     => { args => [undef, 0.01],
        seed => sub { shared_call($_[0], '/x', 'add', 10) for 1 .. 3 },
        read => sub { int shared_call($_[0], '/x', 'quantile', 0.5) }, want => 10 },
    deque        => { args => [undef, 100], variant => 'deque:int',
        seed => sub { shared_push($_[0], '/x', 7) },
        read => sub { shared_pop($_[0], '/x') }, want => 7 },
    disjointset  => { args => [undef, 100],
        seed => sub { shared_set($_[0], '/x/0', 1) },
        read => sub { shared_get($_[0], '/x/0') == shared_get($_[0], '/x/1') ? 1 : 0 }, want => 1 },
    fenwick      => { args => [undef, 100],
        seed => sub { shared_incr($_[0], '/x/5', 3) },
        read => sub { shared_get($_[0], '/x/5') }, want => 3 },
    fenwick2d    => { args => [undef, 10, 10],
        seed => sub { shared_set($_[0], '/x/2/3', 9) },
        read => sub { shared_get($_[0], '/x/2/3') }, want => 9 },
    graph        => { args => [undef, 100, 500],
        seed => sub { $_[1]{id} = shared_call($_[0], '/x', 'add_node', 10) },
        read => sub { shared_get($_[0], "/x/$_[1]{id}") }, want => 10 },
    hashmap      => { args => [undef, 1000], variant => 'hashmap:ii',
        seed => sub { shared_set($_[0], '/x/1', 2) },
        read => sub { shared_get($_[0], '/x/1') }, want => 2 },
    heap         => { args => [undef, 100],
        seed => sub { shared_push($_[0], '/x', 1, 100) },
        read => sub { (shared_pop($_[0], '/x'))[1] }, want => 100 },
    hiertimingwheel => { args => [undef, 256, 4, 1000],
        seed => sub { shared_call($_[0], '/x', 'add', 5, 77) },
        read => sub { (grep { $_ == 77 } shared_call($_[0], '/x', 'advance', 5)) ? 1 : 0 }, want => 1 },
    histogram    => { args => [undef, 1, 3600000000, 3],
        seed => sub { shared_call($_[0], '/x', 'record', 120) },
        read => sub { shared_call($_[0], '/x', 'total_count') }, want => 1 },
    hyperloglog  => { args => [undef, 14],
        seed => sub { shared_call($_[0], '/x', 'add', 'a') },
        read => sub { shared_call($_[0], '/x', 'count') >= 1 ? 1 : 0 }, want => 1 },
    intern       => { args => [undef, 1000, 65536],
        seed => sub { $_[1]{id} = shared_set($_[0], '/x/alice') },
        read => sub { shared_call($_[0], '/x', 'string', $_[1]{id}) }, want => 'alice' },
    intervaltree => { args => [undef, 1000],
        seed => sub { shared_call($_[0], '/x', 'add', 10, 20, 42) },
        read => sub { (shared_call($_[0], '/x', 'stab', 15))[0]{id} }, want => 42 },
    kdtree       => { args => [undef, 2, 1000],
        seed => sub { shared_call($_[0], '/x', 'add', [1, 2], 9) },
        read => sub { shared_call($_[0], '/x', 'nearest', [1, 2])->{id} }, want => 9 },
    log          => { args => [undef, 100000],
        seed => sub { shared_push($_[0], '/x', 'entry') },
        read => sub { shared_call($_[0], '/x', 'entry_count') }, want => 1 },
    ndarray      => { args => [undef, 'f64', 2, 2],
        seed => sub { shared_set($_[0], '/x/0/1', 3) },
        read => sub { shared_get($_[0], '/x/0/1') }, want => 3 },
    # Membership comes from the mount spec, so this cannot tell a read of the
    # parent's file from a rebuild of an identical one.
    perfecthash  => { args => [{ build_int => [1, 2, 3, 5, 8, 13] }],
        seed => sub { 1 },
        read => sub { shared_exists($_[0], '/x/13') }, want => 1 },
    pool         => { args => [undef, 100], variant => 'pool:i64',
        seed => sub { $_[1]{id} = shared_call($_[0], '/x', 'alloc');
                      shared_set($_[0], "/x/$_[1]{id}", 5) },
        read => sub { shared_get($_[0], "/x/$_[1]{id}") }, want => 5 },
    queue        => { args => [undef, 1024], variant => 'queue:int',
        seed => sub { shared_push($_[0], '/x', 42) },
        read => sub { shared_pop($_[0], '/x') }, want => 42 },
    radixtree    => { args => [undef, 4096, 65536],
        seed => sub { shared_set($_[0], '/x/foo', 1) },
        read => sub { shared_get($_[0], '/x/foo') }, want => 1 },
    reservoir    => { args => [undef, 100],
        seed => sub { shared_call($_[0], '/x', 'add', 1) },
        read => sub { shared_call($_[0], '/x', 'seen') }, want => 1 },
    ringbuffer   => { args => [undef, 100], variant => 'ringbuffer:int',
        seed => sub { shared_push($_[0], '/x', 42) },
        read => sub { shared_get($_[0], '/x') }, want => 42 },
    roaringbitmap => { args => [undef, 256],
        seed => sub { shared_set($_[0], '/x/5', 1) },
        read => sub { shared_exists($_[0], '/x/5') }, want => 1 },
    segmenttree  => { args => [undef, 100],
        seed => sub { shared_set($_[0], '/x/10', 42) },
        read => sub { shared_get($_[0], '/x/10') }, want => 42 },
    sortedset    => { args => [undef, 1000],
        seed => sub { shared_set($_[0], '/x/42', 1500) },
        read => sub { shared_get($_[0], '/x/42') }, want => 1500 },
    spatialhash  => { args => [undef, 1000, 0, 1.0],
        seed => sub { shared_call($_[0], '/x', 'insert', 10.5, 20.5, 42) },
        read => sub { (grep { $_ == 42 } shared_call($_[0], '/x', 'query_radius', 10, 20, 5)) ? 1 : 0 },
        want => 1 },
    stack        => { args => [undef, 100], variant => 'stack:int',
        seed => sub { shared_push($_[0], '/x', 42) },
        read => sub { shared_pop($_[0], '/x') }, want => 42 },
    # The parent took one of two permits.
    sync         => { args => [undef, 2], variant => 'sync:semaphore',
        seed => sub { shared_call($_[0], '/x', 'try_acquire') },
        read => sub { shared_call($_[0], '/x', 'try_acquire')
                      && !shared_call($_[0], '/x', 'try_acquire') ? 1 : 0 }, want => 1 },
    timingwheel  => { args => [undef, 512, 1000],
        seed => sub { shared_call($_[0], '/x', 'add', 5, 77) },
        read => sub { (grep { $_ == 77 } shared_call($_[0], '/x', 'advance', 5)) ? 1 : 0 }, want => 1 },
    topk         => { args => [undef, 100],
        seed => sub { shared_set($_[0], '/x/popular') },
        read => sub { shared_get($_[0], '/x/popular') >= 1 ? 1 : 0 }, want => 1 },
    # Two empty MinHashes have similarity 1, so a child that saw nothing fails.
    minhash      => { args => [undef, 256],
        extra => sub { $_[0]->mount('y', 'minhash', undef, 256) },
        seed => sub { shared_call($_[0], '/x', 'add', 'a') },
        read => sub { shared_call($_[0], '/x', 'similarity', $_[0]->handle('/y')) < 1 ? 1 : 0 },
        want => 1 },
    # Live protocols, not stores: the child acts and the parent observes.
    pubsub       => { args => [undef, 1024], variant => 'pubsub:int',
        setup => sub { $_[1]{sub} = shared_call($_[0], '/x', 'subscribe') },
        child => sub { shared_push($_[0], '/x', 42) },
        after => sub { $_[1]{sub}->poll }, want => 42 },
    reqrep       => { args => [undef, 1024, 64], variant => 'reqrep:int',
        child => sub {
            my $cli = Data::ReqRep::Shared::Int::Client->new($_[0]->mount_info('x')->{file});
            $cli->send(7);
        },
        after => sub { my ($req, $id) = shared_call($_[0], '/x', 'recv'); $req }, want => 7 },
);

my @keys = Data::Shared->available_types;
is_deeply [sort keys %CASE], [sort @keys], 'every registry key has a fork case';

my @absent;
for my $key (@keys) {
    my $case = $CASE{$key};
    subtest "$key crosses a fork" => sub {
        my $spec = $case->{variant} // $key;
        my $resolved = Data::Shared::Registry::resolve_spec($spec);
        unless (eval { Data::Shared::_require_class($resolved->{load}); 1 }) {
            push @absent, $key;
            plan skip_all => "backend unavailable: $@";
            return;
        }
        my $dir = tempdir(CLEANUP => 1);
        my $root = Data::Shared->new($dir);
        $root->mount('x', $spec, @{ $case->{args} });
        $case->{extra}->($root) if $case->{extra};
        my %state;
        $case->{setup}->($root, \%state) if $case->{setup};
        $case->{seed}->($root, \%state) if $case->{seed};

        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            my $status = 1;
            eval {
                undef $root;
                my $own = Data::Shared->open($dir);
                if ($case->{child}) { $case->{child}->($own, \%state); $status = 0 }
                else {
                    my $got = $case->{read}->($own, \%state);
                    $status = (defined $got && $got eq $case->{want}) ? 0 : 1;
                    print STDERR "child $key: got "
                        . (defined $got ? "'$got'" : 'undef')
                        . ", wanted '$case->{want}'\n" if $status;
                }
                1;
            } or do { print STDERR "child $key died: $@" };
            POSIX::_exit($status);
        }
        is waitpid($pid, 0), $pid, 'child reaped';
        is $?, 0, $case->{child} ? 'the child acted on the shared store'
                                 : 'the child read what this process wrote';
        if ($case->{after}) {
            is $case->{after}->($root, \%state), $case->{want},
                'and this process observes what the child did';
        }
    };
}

my $ran = @keys - @absent;
diag sprintf 'families crossing a fork: %d/%d%s', $ran, scalar @keys,
    @absent ? ' (absent: ' . join(', ', @absent) . ')' : '';
if ($ENV{DS_ALL_BACKENDS}) {
    is scalar @absent, 0, 'DS_ALL_BACKENDS: every family crossed a fork'
        or diag 'absent: ' . join(', ', @absent);
}

done_testing;
