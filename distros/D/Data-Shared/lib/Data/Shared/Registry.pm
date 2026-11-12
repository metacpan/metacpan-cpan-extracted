package Data::Shared::Registry;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared Data::Shared::Adapter::Map
                   Data::Shared::Adapter::Set Data::Shared::Adapter::Indexed
                   Data::Shared::Adapter::Sketch);

# ASCII digits only: \d accepts Unicode digits that the backend can numify to 0.
my $INDEX_SHAPE = qr/\A-?[0-9]+\z/;

sub _index_shape_ok {
    return defined $_[0] && $_[0] =~ $INDEX_SHAPE ? 1 : 0;
}

# Adapters validate key_int for every verb except the boolean exists probe.
sub _assert_index {
    my ($key, $idx) = @_;
    Carp::croak("Data::Shared: $key: index must be an integer, not '" . (defined $idx ? $idx : 'undef') . "'")
        unless defined $idx && $idx =~ $INDEX_SHAPE;
    return $idx;
}

# Set-like leaves store no value: set means add, and the value is dropped.
my $ADD_KEY = sub { my ($h, $k, $v) = @_; return $h->add($k) };
my $SET_ZERO = sub { my ($h, $i) = @_; return $h->set($i, 0) };
my $ESTIMATE_EXISTS = sub { my ($h, $k) = @_; return $h->estimate($k) > 0 ? 1 : 0 };

my $CAPACITY_EXISTS = sub {
    my ($h, $idx) = @_;
    return 0 unless _index_shape_ok($idx);
    return 0 if $idx < 0;
    return $idx < $h->capacity ? 1 : 0;
};

# An omitted delta uses the backend default; explicit undef is a missing argument.
sub _assert_delta {
    my ($key, @args) = @_;
    Carp::croak("Data::Shared: $key: incr delta must be a number, not undef")
        if @args && !defined $args[0];
    return;
}

# add() requires a delta and incr() accepts none.
sub _incr_or_add {
    my ($family) = @_;
    return sub {
        my ($h, $i, @delta) = @_;
        return $h->add($i, $delta[0]) if @delta && $h->can('add');
        return $h->incr($i) if !@delta && $h->can('incr');
        Carp::croak("Data::Shared: $family: " . ref($h) . " does not support 'incr'"
            . (@delta ? ' with a delta' : ' without a delta')
            . ' (use shared_call for operations outside the generic verbs)');
    };
}

# Graph's unsigned node-index ceiling; out-of-range native probes croak.
my $GRAPH_INDEX_MAX = 0xFFFFFFFF;
sub _nonneg_exists {
    my ($method) = @_;
    return sub {
        my ($h, $idx) = @_;
        return 0 unless _index_shape_ok($idx);
        return 0 if $idx < 0 || $idx > $GRAPH_INDEX_MAX;
        return $h->$method($idx) ? 1 : 0;
    };
}

# The backend's native existence test croaks outside capacity.
sub _bounded_exists {
    my ($method) = @_;
    return sub {
        my ($h, $idx) = @_;
        return 0 unless _index_shape_ok($idx);
        return 0 if $idx < 0 || $idx >= $h->capacity;
        return $h->$method($idx) ? 1 : 0;
    };
}

# No `verbs` table means no generic verbs: every operation on that family goes
# through shared_call.
our %REGISTRY = (
    bitset => {
        dist => 'Data-BitSet-Shared',
        class => 'Data::BitSet::Shared', path_class => 'set',
        key_int => 1,
        verbs => {
            get    => 'test',
            exists => _bounded_exists('test'),
            # Explicit undef is a value; an omitted value must not clear the bit.
            set    => sub { my ($h, $idx, $v) = @_;
                Carp::croak("Data::Shared: bitset set needs a value (1 to set, 0 to clear)") if @_ < 3;
                return $v ? $h->set($idx) : $h->clear($idx) },
            delete => 'clear',
        },
    },
    bloomfilter => {
        dist => 'Data-BloomFilter-Shared',
        class => 'Data::BloomFilter::Shared', path_class => 'set',
        verbs => {
            get => 'contains', exists => 'contains',
            set => $ADD_KEY,
        },
    },
    buffer => {
        dist => 'Data-Buffer-Shared',
        class => 'Data::Buffer::Shared::I64', path_class => 'map',
        key_int => 1,
        variants => { map { $_ => { class => "Data::Buffer::Shared::$_" } }
                      qw(I8 I16 I32 I64 U8 U16 U32 U64 F32 F64 Str) },
        verbs => {
            get => 'get', set => 'set',
            exists => $CAPACITY_EXISTS,
            delete => $SET_ZERO,
            incr => _incr_or_add('buffer'),
        },
    },
    countingbloomfilter => {
        dist => 'Data-CountingBloomFilter-Shared',
        class => 'Data::CountingBloomFilter::Shared', path_class => 'set',
        verbs => {
            get => 'count_of', exists => 'contains',
            set => $ADD_KEY,
            delete => 'remove',
        },
    },
    countminsketch => {
        dist => 'Data-CountMinSketch-Shared',
        class => 'Data::CountMinSketch::Shared', path_class => 'sketch',
        verbs => {
            get => 'estimate',
            exists => $ESTIMATE_EXISTS,
            set => sub { my ($h, $k, $v) = @_; return $h->add($k, defined $v ? $v : 1) },
        },
    },
    cuckoofilter => {
        dist => 'Data-CuckooFilter-Shared',
        class => 'Data::CuckooFilter::Shared', path_class => 'set',
        verbs => {
            get => 'count_of', exists => 'contains',
            set => $ADD_KEY,
            delete => 'remove',
        },
    },
    ddsketch => {
        dist => 'Data-DDSketch-Shared',
        class => 'Data::DDSketch::Shared', path_class => 'sketch',
    },
    deque => {
        dist => 'Data-Deque-Shared',
        class => 'Data::Deque::Shared::Int', load => 'Data::Deque::Shared',
        path_class => 'queue',
        variants => {
            Int => { class => 'Data::Deque::Shared::Int' },
            Str => { class => 'Data::Deque::Shared::Str' },
        },
        push => 'push_back', pop => 'pop_front',
    },
    disjointset => {
        dist => 'Data-DisjointSet-Shared',
        class => 'Data::DisjointSet::Shared', path_class => 'set',
        key_int => 1,
        verbs => {
            get => 'find',
            exists => $CAPACITY_EXISTS,
            # DisjointSet numifies an omitted peer to 0 and cannot undo a merge.
            set => sub {
                my ($h, $m, $other) = @_;
                Carp::croak("Data::Shared: disjointset set needs a second member to union with")
                    unless _index_shape_ok($other);
                return $h->union($m, $other);
            },
        },
    },
    fenwick => {
        dist => 'Data-Fenwick-Shared',
        class => 'Data::Fenwick::Shared', path_class => 'indexed',
        key_int => 1, dims => 1,
        verbs => {
            get => 'point', set => 'set', incr => 'update',
            exists => sub { my ($h, $p) = @_;
                return (_index_shape_ok($p) && $p >= 1 && $p <= $h->size) ? 1 : 0 },
            delete => $SET_ZERO,
        },
    },
    fenwick2d => {
        dist => 'Data-Fenwick2D-Shared',
        class => 'Data::Fenwick2D::Shared', path_class => 'indexed',
        key_int => 1, dims => 2,
        verbs => { get => 'point', set => 'set', incr => 'update' },
    },
    graph => {
        dist => 'Data-Graph-Shared',
        class => 'Data::Graph::Shared', path_class => 'indexed',
        key_int => 1, dims => 1,
        # Graph get croaks for absent nodes; has_node supplies a safe probe.
        verbs => { get => 'node_data', delete => 'remove_node',
                   exists => _nonneg_exists('has_node') },
    },
    hashmap => {
        dist => 'Data-HashMap-Shared',
        class => 'Data::HashMap::Shared::II', path_class => 'map',
        key_int => 1,
        variants => { map { $_ => { class => "Data::HashMap::Shared::$_",
                                    key_int => /\AI/ ? 1 : 0 } }
                      qw(I16 I16S I32 I32S II IS SI SI16 SI32 SS) },
        verbs => {
            get => 'get', set => 'put', delete => 'remove',
            exists => 'exists', incr => 'incr',
        },
    },
    heap => {
        dist => 'Data-Heap-Shared',
        class => 'Data::Heap::Shared', path_class => 'queue',
        push => 'push', pop => 'pop',
    },
    hiertimingwheel => {
        dist => 'Data-HierTimingWheel-Shared',
        class => 'Data::HierTimingWheel::Shared', path_class => 'sync',
    },
    histogram => {
        dist => 'Data-Histogram-Shared',
        class => 'Data::Histogram::Shared', path_class => 'sketch',
    },
    hyperloglog => {
        dist => 'Data-HyperLogLog-Shared',
        class => 'Data::HyperLogLog::Shared', path_class => 'sketch',
    },
    intern => {
        dist => 'Data-Intern-Shared',
        class => 'Data::Intern::Shared', path_class => 'map',
        verbs => {
            get => 'id_of',
            set => sub { my ($h, $k, $v) = @_; return $h->intern($k) },
            exists => 'exists',
        },
    },
    intervaltree => {
        dist => 'Data-IntervalTree-Shared',
        class => 'Data::IntervalTree::Shared', path_class => 'indexed',
    },
    kdtree => {
        dist => 'Data-KDTree-Shared',
        class => 'Data::KDTree::Shared', path_class => 'indexed',
    },
    log => {
        dist => 'Data-Log-Shared',
        class => 'Data::Log::Shared', path_class => 'queue',
        push => 'append',
    },
    minhash => {
        dist => 'Data-MinHash-Shared',
        class => 'Data::MinHash::Shared', path_class => 'sketch',
    },
    ndarray => {
        dist => 'Data-NDArray-Shared',
        class => 'Data::NDArray::Shared', path_class => 'indexed',
        key_int => 1,
        verbs => { get => 'get', set => 'set' },
    },
    perfecthash => {
        dist => 'Data-PerfectHash-Shared',
        class => 'Data::PerfectHash::Shared', path_class => 'map',
        ctor => 'handle_only', immutable => 1,
        # Read from the built file: a replayed mount need not carry the build spec.
        key_int_from => sub { $_[0]->type eq 'int' },
        verbs => { get => 'has', exists => 'has' },
    },
    pool => {
        dist => 'Data-Pool-Shared',
        class => 'Data::Pool::Shared', load => 'Data::Pool::Shared',
        path_class => 'map',
        key_int => 1,
        variants => {
            I64 => { class => 'Data::Pool::Shared::I64' },
            I32 => { class => 'Data::Pool::Shared::I32' },
            F64 => { class => 'Data::Pool::Shared::F64' },
            Str => { class => 'Data::Pool::Shared::Str' },
        },
        verbs => {
            get => 'get', set => 'set', delete => 'free',
            exists => _bounded_exists('is_allocated'),
            incr => _incr_or_add('pool'),
        },
    },
    pubsub => {
        dist => 'Data-PubSub-Shared',
        class => 'Data::PubSub::Shared::Int', path_class => 'queue',
        variants => { map { $_ => { class => "Data::PubSub::Shared::$_" } }
                      qw(Int Int32 Int16 Str) },
        push => 'publish',
    },
    queue => {
        dist => 'Data-Queue-Shared',
        class => 'Data::Queue::Shared::Int', path_class => 'queue',
        variants => { map { $_ => { class => "Data::Queue::Shared::$_" } }
                      qw(Int Int32 Int16 Str) },
        push => 'push', pop => 'pop',
    },
    radixtree => {
        dist => 'Data-RadixTree-Shared',
        class => 'Data::RadixTree::Shared', path_class => 'map',
        key_join => '/',
        verbs => {
            get => 'lookup',
            set => sub { my ($h, $k, $v) = @_;
                Carp::croak("Data::Shared: radixtree set needs a value") if @_ < 3;
                return $h->insert($k, $v) },
            delete => 'delete', exists => 'exists',
        },
    },
    reqrep => {
        dist => 'Data-ReqRep-Shared',
        class => 'Data::ReqRep::Shared', path_class => 'sync',
        variants => {
            Int => { class => 'Data::ReqRep::Shared::Int' },
        },
    },
    reservoir => {
        dist => 'Data-Reservoir-Shared',
        class => 'Data::Reservoir::Shared', path_class => 'sketch',
        variants => {
            weighted => { class => 'Data::Reservoir::Shared', ctor => 'new_weighted' },
        },
    },
    ringbuffer => {
        dist => 'Data-RingBuffer-Shared',
        class => 'Data::RingBuffer::Shared::Int', load => 'Data::RingBuffer::Shared',
        path_class => 'queue',
        variants => {
            Int => { class => 'Data::RingBuffer::Shared::Int' },
            F64 => { class => 'Data::RingBuffer::Shared::F64' },
        },
        verbs => {
            # The queue adapter checks no index, so this one checks its own.
            get => sub { my ($h, @rest) = @_;
                return $h->latest unless @rest;
                return $h->read_seq(_assert_index('ringbuffer', $rest[0])) },
        },
        push => 'write',
    },
    roaringbitmap => {
        dist => 'Data-RoaringBitmap-Shared',
        class => 'Data::RoaringBitmap::Shared', path_class => 'set',
        key_int => 1,
        verbs => {
            get => 'contains', exists => 'contains',
            set => $ADD_KEY,
            delete => 'remove',
        },
    },
    segmenttree => {
        dist => 'Data-SegmentTree-Shared',
        class => 'Data::SegmentTree::Shared', path_class => 'indexed',
        key_int => 1, dims => 1,
        verbs => {
            # A point read; a range needs shared_call.
            get => sub { my ($h, $i) = @_; return $h->sum($i, $i) },
            set => 'set', incr => 'add',
            # Shape-checked: a non-numeric index would numify to 0, which is in range.
            exists => sub { my ($h, $p) = @_;
                return (_index_shape_ok($p) && $p >= 0 && $p < $h->size) ? 1 : 0 },
            delete => $SET_ZERO,
        },
    },
    sortedset => {
        dist => 'Data-SortedSet-Shared',
        class => 'Data::SortedSet::Shared', path_class => 'set',
        key_int => 1,
        variants => {
            Strings => { class => 'Data::SortedSet::Shared::Strings', key_int => 0 },
        },
        verbs => {
            get => 'score', exists => 'exists',
            set => sub { my ($h, $m, $score) = @_;
                Carp::croak("Data::Shared: sortedset set needs a score") if @_ < 3;
                return $h->add($m, $score) },
            delete => 'remove',
            # SortedSet::Strings accepts an omitted delta and may intern a ghost member.
            incr => sub { my ($h, $m, @delta) = @_;
                Carp::croak('Data::Shared: sortedset incr needs a delta') unless @delta;
                return $h->incr($m, $delta[0]) },
        },
    },
    spatialhash => {
        dist => 'Data-SpatialHash-Shared',
        class => 'Data::SpatialHash::Shared', path_class => 'indexed',
    },
    stack => {
        dist => 'Data-Stack-Shared',
        class => 'Data::Stack::Shared::Int', load => 'Data::Stack::Shared',
        path_class => 'queue',
        variants => {
            Int => { class => 'Data::Stack::Shared::Int' },
            Str => { class => 'Data::Stack::Shared::Str' },
        },
        push => 'push', pop => 'pop',
    },
    sync => {
        dist => 'Data-Sync-Shared',
        class => 'Data::Sync::Shared::Semaphore', path_class => 'sync',
        variants => { map { $_ => { class => "Data::Sync::Shared::$_" } }
                      qw(Semaphore Barrier RWLock Condvar Once) },
    },
    timingwheel => {
        dist => 'Data-TimingWheel-Shared',
        class => 'Data::TimingWheel::Shared', path_class => 'sync',
    },
    topk => {
        dist => 'Data-TopK-Shared',
        class => 'Data::TopK::Shared', path_class => 'sketch',
        variants => {
            decayed => { class => 'Data::TopK::Shared', ctor => 'new_decayed' },
        },
        verbs => {
            get => 'estimate',
            exists => $ESTIMATE_EXISTS,
            set => $ADD_KEY,
        },
    },
);

my %MIN_VERSION = (
    bitset => '0.08', bloomfilter => '0.07', buffer => '0.09',
    countingbloomfilter => '0.05', countminsketch => '0.06', cuckoofilter => '0.06',
    ddsketch => '0.05', deque => '0.11', disjointset => '0.06',
    fenwick => '0.06', fenwick2d => '0.05', graph => '0.08', hashmap => '0.23',
    heap => '0.10', hiertimingwheel => '0.05', histogram => '0.06',
    hyperloglog => '0.06', intern => '0.06', intervaltree => '0.05',
    kdtree => '0.05', log => '0.08', minhash => '0.06', ndarray => '0.06',
    perfecthash => '0.05', pool => '0.10', pubsub => '0.11', queue => '0.10',
    radixtree => '0.06', reqrep => '0.09', reservoir => '0.06', ringbuffer => '0.07',
    roaringbitmap => '0.06', segmenttree => '0.07', sortedset => '0.07',
    spatialhash => '0.06', stack => '0.09', sync => '0.10', timingwheel => '0.05', topk => '0.07',
);
my %NATIVE_READONLY = map { $_ => 1 } qw(bitset bloomfilter countingbloomfilter countminsketch
    cuckoofilter ddsketch fenwick fenwick2d graph hashmap histogram hyperloglog intern
    intervaltree kdtree minhash ndarray radixtree roaringbitmap sortedset spatialhash);
for my $key (keys %REGISTRY) {
    $REGISTRY{$key}{key} = $key;
    $REGISTRY{$key}{min_version} = $MIN_VERSION{$key};
    $REGISTRY{$key}{freeze} = $NATIVE_READONLY{$key} ? 1 : 0;
}
# SortedSet::Strings has neither freeze nor new_readonly.
$REGISTRY{sortedset}{variants}{Strings}{freeze} = 0;

# The family entry, with the variant's key_int where it differs.
sub _variant_entry {
    my ($e, $v) = @_;
    return $e unless exists $v->{key_int} && ($v->{key_int} // 0) != ($e->{key_int} // 0);
    return { %$e, key_int => $v->{key_int} };
}

sub registry { return \%REGISTRY }
sub keys_list { my @k = sort keys %REGISTRY; return @k }
sub entry_for_key {
    my ($key) = @_;
    return $REGISTRY{ lc $key };
}

sub entry_for_class {
    my ($class) = @_;
    for my $e (values %REGISTRY) {
        return $e if $e->{class} eq $class;
        if (my $vs = $e->{variants}) {
            for my $v (values %$vs) {
                return _variant_entry($e, $v) if $v->{class} eq $class;
            }
        }
    }
    return undef;
}

# convention is how a family takes its backing path; read it, never re-derive it.
sub resolve_spec {
    my $resolved = _resolve_spec(@_) or return undef;
    $resolved->{convention} =
          $resolved->{class} eq 'Data::SortedSet::Shared::Strings' ? 'options'
        : ($resolved->{entry} && ($resolved->{entry}{ctor} // '') eq 'handle_only') ? 'handle'
        :                                                                             'leading';
    return $resolved;
}

sub _resolve_spec {
    my ($spec) = @_;
    return undef unless defined $spec && !ref $spec;
    if (my $e = $REGISTRY{ lc $spec }) {
        return { entry => $e, class => $e->{class}, load => ($e->{load} // $e->{class}),
                 ctor => ($e->{ctor} // 'new'), variant => undef };
    }
    if ($spec =~ /^([^:]+):(.+)$/) {
        my ($k, $vname) = ($1, $2);
        if (my $e = $REGISTRY{ lc $k }) {
            if (my $vs = $e->{variants}) {
                for my $vn (keys %$vs) {
                    if (lc $vn eq lc $vname) {
                        my $v = $vs->{$vn};
                        return { entry => _variant_entry($e, $v), class => $v->{class},
                                 load => ($v->{load} // $e->{load} // $v->{class}),
                                 ctor => ($v->{ctor} // $e->{ctor} // 'new'),
                                 variant => lc $vn };
                    }
                }
            }
            if (lc $vname eq 'default') {
                return { entry => $e, class => $e->{class}, load => ($e->{load} // $e->{class}),
                         ctor => ($e->{ctor} // 'new'), variant => undef };
            }
        }
    }
    if (my $e = entry_for_class($spec)) {
        my $ctor = $e->{ctor} // 'new';
        my $load = $e->{load} // $spec;
        my $vname;
        if (my $vs = $e->{variants}) {
            for my $vn (sort keys %$vs) {
                if ($vs->{$vn}{class} eq $spec) {
                    next if $e->{class} eq $spec && defined $vs->{$vn}{ctor}
                        && $vs->{$vn}{ctor} ne $ctor;
                    $vname = $vn;
                    $ctor = $vs->{$vn}{ctor} // $ctor;
                    $load = $vs->{$vn}{load} // $load;
                    last;
                }
            }
        }
        return { entry => $e, class => $spec, load => $load, ctor => $ctor, variant => defined $vname ? lc $vname : undef };
    }
    if ($spec =~ /^Data::/) {
        return { entry => undef, class => $spec, load => $spec, ctor => 'new', variant => undef };
    }
    return undef;
}

1;

__END__

=encoding utf8

=head1 NAME

Data::Shared::Registry - Inventory of the 39 Data-*-Shared dists for Data::Shared

=head1 SYNOPSIS

    use Data::Shared::Registry ();
    my $reg = Data::Shared::Registry::registry;
    my $e = $reg->{hashmap};
    # { key, dist, class, variants, path_class, verbs, push, pop, ... }

    my @keys = Data::Shared::Registry::keys_list;   # 39 short names
    my $r = Data::Shared::Registry::resolve_spec('buffer:i64');
    # { entry, class => 'Data::Buffer::Shared::I64', load, ctor, variant }

=head1 DESCRIPTION

This module is the single source of truth that drives
L<Data::Shared>: mount-spec resolution, adapter selection, and
generic verb translation all read it.

Each entry has: C<key> (short mount spec name), C<dist>, C<class>
(default class), optional C<load> (module to require when variant
classes live inside a base F<.pm>), optional C<variants> (name to
C<{class, load, ctor}>), C<path_class> (C<map>, C<set>, C<queue>,
C<indexed>, C<sketch> or C<sync>), C<verbs> (generic verb to native
method name or coderef receiving C<($handle, $key, @args)>, or
C<($handle, @indices, @args)> for indexed leaves), optional
C<push>/C<pop> native method names, optional C<key_join> (join
remaining components with C</> to form the key), optional C<key_int>
(integer-addressed: a non-integer key croaks on every verb but
C<exists>), optional C<ctor> (C<new> by default; C<handle_only> for
PerfectHash), and C<freeze> (whether the leaf supports
freeze/new_readonly).

C<min_version> records the validated backend version used as the supported
minimum by the installer and runtime loader. Strict read-only opens also
inspect the resolved class for its native constructor. C<immutable> marks
build-then-load backends.

A verb absent from C<verbs> means "not honestly expressible
generically"; the facade croaks and points at C<shared_call>. A verb
mapped to a coderef (e.g. BitSet C<set> choosing set-vs-clear by
value, SortedSet C<set> as C<add(member, score)>, Intern C<set> as
C<intern>) wraps the one place where sugar needs a decision.

=head1 FUNCTIONS

=head2 registry

Returns the hashref of all entries keyed by short name.

=head2 keys_list

Sorted list of the 39 short names.

=head2 entry_for_key($key), entry_for_class($class)

Lookups by short name or by Perl class (including variants).

=head2 resolve_spec($spec)

Resolves C<'hashmap'>, C<'hashmap:ii'>, a full class name, or any
C<Data::*> class (unknown classes resolve with C<entry> undef, and
L<Data::Shared> dispatches them call-only) to C<{entry, class, load,
ctor, variant}>, or undef for unknown short specs. Short specs resolve
case-insensitively to a lowercase key, and the returned C<variant> is
always lowercase.

=cut
