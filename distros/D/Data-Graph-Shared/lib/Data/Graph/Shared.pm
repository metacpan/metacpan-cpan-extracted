package Data::Graph::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::Graph::Shared', $VERSION);

sub nodes {
    my ($self) = @_;
    my @nodes;
    for my $i (0 .. $self->max_nodes - 1) {
        push @nodes, $i if $self->has_node($i);
    }
    return @nodes;
}

sub each_neighbor {
    my ($self, $node, $cb) = @_;
    for my $pair ($self->neighbors($node)) {
        $cb->($pair->[0], $pair->[1]);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Graph::Shared - Shared-memory directed weighted graph for Linux

=head1 SYNOPSIS

    use Data::Graph::Shared;

    my $g = Data::Graph::Shared->new(undef, 100, 500);  # 100 nodes, 500 edges
    my $a = $g->add_node(10);    # returns node index
    my $b = $g->add_node(20);
    my $c = $g->add_node(30);

    $g->add_edge($a, $b, 5);     # a→b weight 5
    $g->add_edge($a, $c, 3);     # a→c weight 3
    $g->add_edge($b, $c, 1);     # b→c weight 1

    my @nbrs = $g->neighbors($a);  # ([1,5], [2,3]) — [dst, weight] pairs
    say $g->degree($a);            # 2
    say $g->node_data($a);         # 10

    $g->remove_node($b);          # removes node and outgoing edges

=head1 DESCRIPTION

Directed weighted graph in shared memory. Nodes allocated from a
bitmap pool, edges stored as adjacency lists in a separate edge pool.
Mutex-protected mutations with PID-based stale recovery.

B<Note>: C<remove_node> removes the node and its outgoing edges only.
Incoming edges from other nodes are NOT automatically removed (this is
an O(1) design choice) — their C<dst> is left dangling until the slot's
bit is reused. Use C<remove_node_full> when this matters; it additionally
splices incoming edges in O(N+E).

B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $g = Data::Graph::Shared->new($path, $max_nodes, $max_edges);  # file-backed
    my $g = Data::Graph::Shared->new(undef, $max_nodes, $max_edges);  # anonymous
    my $g = Data::Graph::Shared->new_memfd($name, $max_nodes, $max_edges);
    my $g = Data::Graph::Shared->new_from_fd($fd);                    # reopen memfd

=head2 Operations

    my $id = $g->add_node($data);            # returns node index or undef
    $g->add_edge($src, $dst);                # weight defaults to 1
    $g->add_edge($src, $dst, $weight);
    $g->remove_node($id);                    # O(1) — outgoing edges only
    $g->remove_node_full($id);               # O(N+E) — also splices incoming
    $g->has_node($id);
    $g->node_data($id);
    $g->set_node_data($id, $data);
    my @pairs = $g->neighbors($id);          # list of [$dst, $weight]
    $g->each_neighbor($id, sub { my ($dst, $w) = @_ });
    $g->degree($id);
    my @ids = $g->nodes;                     # all node indices
    $g->node_count;  $g->edge_count;
    $g->max_nodes;   $g->max_edges;

=head2 Lifecycle

    $g->path;              # backing file path, or undef for anon/memfd
    $g->memfd;             # memfd fd (-1 for file-backed/anon)
    $g->stats;             # diagnostic hashref
    $g->sync;              # msync mmap to backing store
    $g->unlink;            # remove backing file
    Class->unlink($path);  # class-method form

=head2 Event Loop Integration

    my $fd = $g->eventfd;         # lazy-create eventfd, returns fd
    $g->eventfd_set($fd);         # attach an external eventfd
    my $fd = $g->fileno;          # current eventfd fd, or -1
    $g->notify;                   # write 1 to eventfd (caller signals update)
    my $n = $g->eventfd_consume;  # read+reset eventfd counter

=head1 BENCHMARKS

Single-process (10K ops, x86_64 Linux, Perl 5.40):

    add_node            3.9M/s
    add_edge (random)   2.3M/s
    has_node           13.3M/s
    node_data           5.5M/s
    neighbors           2.6M/s
    degree              5.6M/s

=head1 STATS

C<stats()> returns: C<node_count>, C<edge_count>, C<max_nodes>,
C<max_edges>, C<ops>, C<mmap_size>.

=head1 SECURITY

The mmap region is writable by all processes that open it.
Do not share backing files with untrusted processes.

=head1 SEE ALSO

L<Data::Heap::Shared> - priority queue (for Dijkstra, Prim, etc.)

L<Data::Pool::Shared> - fixed-size object pool

L<Data::HashMap::Shared> - concurrent hash table

L<Data::Buffer::Shared> - typed shared array

L<Data::Queue::Shared> - FIFO queue

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Log::Shared> - append-only log

L<Data::Sync::Shared> - synchronization primitives

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::ReqRep::Shared> - request-reply

L<Data::BitSet::Shared> - shared bitset (lock-free per-bit ops)

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
