use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Data::Graph::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.graph";

my $N     = 150;     # nodes -- "many" nodes+edges, walked in full on both sides of the freeze
my $SPARE = 10;      # extra unallocated node slots, for a real "does not exist" probe
my $MAXE  = 3 * $N;  # edge-slot headroom

my (%ids, %adj, %deg);   # i => node_id; node_id => [[dst,weight],...]; node_id => degree

# ---- producer: build a graph with many nodes+edges, freeze ----
{
    my $g = Data::Graph::Shared->new($path, $N + $SPARE, $MAXE);
    ok !$g->frozen,   'freshly created graph is not frozen';
    ok !$g->readonly, 'read-write handle is not read-only';

    for my $i (0 .. $N - 1) {
        my $id = $g->add_node($i * 10);
        ok defined $id, "add_node $i";
        $ids{$i} = $id;
    }

    for my $i (0 .. $N - 2) {                       # chain: i -> i+1
        my $w = $i + 1;
        ok $g->add_edge($ids{$i}, $ids{$i + 1}, $w), "chain edge $i -> @{[$i+1]}";
        push @{ $adj{ $ids{$i} } }, [ $ids{$i + 1}, $w ];
    }
    for my $i (0 .. $N - 1) {                       # cross edges: varied fan-out/degree per node
        my $j = ($i * 7 + 3) % $N;
        next if $j == $i;
        my $w = -($i + 1);
        ok $g->add_edge($ids{$i}, $ids{$j}, $w), "cross edge $i -> $j";
        push @{ $adj{ $ids{$i} } }, [ $ids{$j}, $w ];
    }
    $deg{ $ids{$_} } = scalar @{ $adj{ $ids{$_} } || [] } for 0 .. $N - 1;

    $g->set_node_data($ids{0}, 999);                # one node's data diverges from i*10

    my $missing_id = $N;                             # in max_nodes range, never allocated
    ok !$g->has_node($missing_id), 'spare slot not allocated (producer)';

    my $nc = $g->node_count;
    my $ec = $g->edge_count;

    $g->freeze;
    ok $g->frozen,   'frozen after ->freeze';
    ok $g->readonly, 'freezing handle becomes read-only';
    is $g->node_count, $nc, 'node_count unchanged by freeze';
    is $g->edge_count, $ec, 'edge_count unchanged by freeze';

    like exception(sub { $g->add_node(1) }),                   qr/frozen|read-only/, 'add_node on frozen handle croaks';
    like exception(sub { $g->add_edge($ids{0}, $ids{1}, 1) }), qr/frozen|read-only/, 'add_edge on frozen handle croaks';
    like exception(sub { $g->remove_node($ids{0}) }),          qr/frozen|read-only/, 'remove_node on frozen handle croaks';
    like exception(sub { $g->remove_node_full($ids{0}) }),     qr/frozen|read-only/, 'remove_node_full on frozen handle croaks';
    like exception(sub { $g->set_node_data($ids{0}, 1) }),     qr/frozen|read-only/, 'set_node_data on frozen handle croaks';
    like exception(sub { $g->freeze }),                        qr/read-only/,        'freeze on a read-only handle croaks';

    # the freezing handle itself flips readonly=1, so its own reads now take
    # the lock-free path too -- confirm it is still fully readable.
    is $g->node_data($ids{0}), 999, 'node_data readable on the freezing handle after freeze';
}

sub sorted_pairs { sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @{ $_[0] } }

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::Graph::Shared->new_readonly($path);
    isa_ok $ro, 'Data::Graph::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    is $ro->max_nodes, $N + $SPARE, 'max_nodes matches producer read-only';
    is $ro->max_edges, $MAXE, 'max_edges matches producer read-only';
    is $ro->node_count, $N, 'node_count matches producer read-only';

    # has_node + node_data + neighbors + degree for EVERY node -- a full sweep,
    # every call landing on the PROT_READ handle. A method that still takes
    # the mutex here would SIGSEGV.
    for my $i (0 .. $N - 1) {
        my $id = $ids{$i};
        ok $ro->has_node($id), "has_node($id) true via read-only view";
        my $expect_data = $i == 0 ? 999 : $i * 10;
        is $ro->node_data($id), $expect_data, "node_data($id) matches producer via read-only view";
        is $ro->degree($id), $deg{$id}, "degree($id) matches producer via read-only view";
        my @got = map { [ $_->[0], $_->[1] ] } $ro->neighbors($id);
        is_deeply [ sorted_pairs(\@got) ], [ sorted_pairs($adj{$id} || []) ],
            "neighbors($id) matches producer via read-only view";
    }

    # the never-allocated spare slot: has_node false, node_data/degree/neighbors croak
    my $missing_id = $N;
    ok !$ro->has_node($missing_id), 'spare slot not allocated (read-only view)';
    like exception(sub { $ro->node_data($missing_id) }), qr/does not exist/, 'node_data on absent node croaks read-only';
    like exception(sub { $ro->degree($missing_id) }),    qr/does not exist/, 'degree on absent node croaks read-only';
    like exception(sub { $ro->neighbors($missing_id) }), qr/does not exist/, 'neighbors on absent node croaks read-only';

    # full "nodes" iteration (Perl-level, built on has_node)
    my @nodes = $ro->nodes;
    is scalar @nodes, $N, 'nodes() lists exactly the allocated nodes read-only';
    is_deeply [ sort { $a <=> $b } @nodes ], [ sort { $a <=> $b } values %ids ],
        'nodes() matches producer node-id set read-only';

    # full "edges" iteration via each_neighbor (Perl-level, built on neighbors) --
    # visits every edge in the graph exactly once via its source's adjacency list.
    my $edge_visits = 0;
    for my $id (@nodes) {
        $ro->each_neighbor($id, sub { $edge_visits++ });
    }
    is $edge_visits, $ro->edge_count, 'each_neighbor full sweep visits every edge exactly once';

    my $st = $ro->stats;
    is $st->{frozen},     1, 'stats.frozen set';
    is $st->{readonly},   1, 'stats.readonly set';
    is $st->{node_count}, $N, 'stats.node_count matches read-only';
    is $st->{edge_count}, $edge_visits, 'stats.edge_count matches read-only';

    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    like exception(sub { $ro->add_node(1) }),                   qr/read-only/, 'add_node on read-only view croaks';
    like exception(sub { $ro->add_edge($ids{0}, $ids{1}, 1) }), qr/read-only/, 'add_edge on read-only view croaks';
    like exception(sub { $ro->remove_node($ids{0}) }),          qr/read-only/, 'remove_node on read-only view croaks';
    like exception(sub { $ro->remove_node_full($ids{0}) }),     qr/read-only/, 'remove_node_full on read-only view croaks';
    like exception(sub { $ro->set_node_data($ids{0}, 1) }),     qr/read-only/, 'set_node_data on read-only view croaks';
    like exception(sub { $ro->freeze }),                        qr/read-only/, 'freeze on read-only view croaks';
}

# ---- two independent read-only views of the same file, concurrently ----
{
    my $a = Data::Graph::Shared->new_readonly($path);
    my $b = Data::Graph::Shared->new_readonly($path);
    ok $a->has_node($ids{0}) && $b->has_node($ids{0}), 'two read-only views query the same file';
    is_deeply [ sorted_pairs([ $a->neighbors($ids{0}) ]) ], [ sorted_pairs([ $b->neighbors($ids{0}) ]) ],
        'two read-only views agree on neighbors';
}

# ---- refuse a read-write reopen of a sealed file (create-reopen path) ----
like exception(sub { Data::Graph::Shared->new($path, $N + $SPARE, $MAXE) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused';

# ---- refuse a read-write reopen of a sealed file (open_fd path) ----
{
    open my $fh, '+<', $path or die "open $path: $!";
    my $fd = fileno($fh);
    like exception(sub { Data::Graph::Shared->new_from_fd($fd) }),
         qr/frozen|read-only/, 'new_from_fd on a sealed file is refused';
    close $fh;
}

# ---- refuse a read-write reopen of a sealed memfd (open_fd path, memfd route) ----
{
    my $mg = Data::Graph::Shared->new_memfd("frozen_test", 10, 20);
    my $x = $mg->add_node(1);
    my $y = $mg->add_node(2);
    $mg->add_edge($x, $y, 3);
    $mg->freeze;
    my $dup_fd = POSIX::dup($mg->memfd);
    like exception(sub { Data::Graph::Shared->new_from_fd($dup_fd) }),
         qr/frozen|read-only/, 'new_from_fd on a sealed memfd is refused';
    POSIX::close($dup_fd);
}

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.graph";
    { my $g = Data::Graph::Shared->new($u, 10, 20); $g->add_node(1); }
    like exception(sub { Data::Graph::Shared->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}

# ---- new_readonly error paths ----
like exception(sub { Data::Graph::Shared->new_readonly("$dir/does-not-exist.graph") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::Graph::Shared->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';

done_testing;

# minimal exception helper (avoid a Test::Fatal dependency)
sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}
