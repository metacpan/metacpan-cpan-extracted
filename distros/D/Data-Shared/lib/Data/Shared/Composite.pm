package Data::Shared::Composite;
use strict;
use warnings;
use Carp ();
use Scalar::Util qw(weaken);
use Fcntl qw(:flock O_RDWR O_APPEND O_CREAT);
use Errno ();

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared Data::Shared::Manifest Data::Shared::Storage
                   Data::Shared::Composite);

sub CLONE_SKIP { 1 }

my %PARENT_OK = map { $_ => 1 } qw(hashmap sortedset kdtree graph);

sub _refuse_unknown_keys {
    my ($hash, $what, @allowed) = @_;
    my %ok = map { $_ => 1 } @allowed;
    my @bad = sort grep { !$ok{$_} } keys %$hash;
    return unless @bad;
    Carp::croak("Data::Shared: unknown composite $what"
        . (@bad == 1 ? " '$bad[0]'" : "s '" . join("', '", @bad) . "'")
        . '; expected ' . join(', ', @allowed));
}

sub parse_node {
    my ($node) = @_;
    if (!ref $node) {
        Carp::croak("Data::Shared: composite spec must be a string, arrayref, or hashref") unless defined $node;
        my $resolved = Data::Shared::Registry::resolve_spec($node);
        Carp::croak("Data::Shared: unknown mount spec '$node'") unless $resolved;
        return { spec => $node, resolved => $resolved, args => [], child => undef,
                 max_children => 10_000, cache_size => 32 };
    }
    if (ref $node eq 'HASH') {
        my $spec = $node->{spec} // $node->{type} // $node->{class} // $node->{key};
        Carp::croak("Data::Shared: composite hashref spec needs spec/type/class/key") unless defined $spec;
        _refuse_unknown_keys($node, 'spec key',
            qw(spec type class key args ctor child max_children cache_size));
        my $resolved = Data::Shared::Registry::resolve_spec($spec);
        Carp::croak("Data::Shared: unknown mount spec '$spec'") unless $resolved;
        Carp::croak('Data::Shared: constructor args must be an ARRAY reference')
            if exists $node->{args} && ref $node->{args} ne 'ARRAY';
        Carp::croak('Data::Shared: invalid constructor name')
            if exists $node->{ctor} && (!defined $node->{ctor} || ref $node->{ctor} || $node->{ctor} !~ /\A[A-Za-z_]\w*\z/);
        # ctor_named marks a caller override; the registry sets its own ctor for some families.
        $resolved = { %$resolved, ctor => $node->{ctor}, ctor_named => 1 }
            if defined $node->{ctor};
        my $out = { spec => $spec, resolved => $resolved,
                    args => $node->{args} ? [ @{ $node->{args} } ] : [],
                    child => undef,
                    max_children => $node->{max_children} // 10_000,
                    cache_size => $node->{cache_size} // 32 };
        $out->{child} = parse_node($node->{child}) if defined $node->{child};
        _validate_node($out);
        return $out;
    }
    if (ref $node eq 'ARRAY') {
        my @elems = @$node;
        Carp::croak("Data::Shared: composite arrayref spec is empty") unless @elems;
        my $spec = shift @elems;
        Carp::croak("Data::Shared: composite arrayref spec must start with a spec string") if ref $spec;
        my %opts;
        if (@elems >= 2 && ref $elems[-1] eq 'HASH' && ref $elems[-2] eq 'ARRAY') {
            # A trailing child array and options hash must not fall through to constructor args.
            _refuse_unknown_keys($elems[-1], 'option', qw(max_children cache_size));
            %opts = %{ pop @elems };
        }
        if (@elems && ref $elems[-1] eq 'HASH'
                && grep { exists $elems[-1]{$_} } qw(spec type class key child)) {
            Carp::croak('Data::Shared: a child spec in an arrayref composite spec must be'
                . ' an arrayref; a trailing hashref is read as a constructor argument');
        }
        my $child;
        if (@elems && ref $elems[-1] eq 'ARRAY') {
            $child = parse_node(pop @elems);
        }
        my $resolved = Data::Shared::Registry::resolve_spec($spec);
        Carp::croak("Data::Shared: unknown mount spec '$spec'") unless $resolved;
        my $out = { spec => $spec, resolved => $resolved, args => \@elems, child => $child,
                    max_children => $opts{max_children} // 10_000,
                    cache_size => $opts{cache_size} // 32 };
        _validate_node($out);
        return $out;
    }
    Carp::croak("Data::Shared: composite spec must be a string, arrayref, or hashref");
}

# A leading undef or ':file' is the file placeholder, not an argument; every reader of args must strip it.
sub _strip_placeholder {
    my ($args) = @_;
    my @a = @$args;
    my $placeholder = sub { @a && (!defined $a[0] || (!ref $a[0] && $a[0] eq ':file'))};
    shift @a if $placeholder->();
    Carp::croak("Data::Shared: a spec names the backing-path placeholder"
        . " (undef or ':file') more than once; the facade supplies one file")
        if $placeholder->();
    return \@a;
}

sub _constructor_args {
    my ($resolved, $args) = @_;
    my $a = _strip_placeholder($args);
    return $a if $resolved->{convention} ne 'leading';
    return [undef, @$a];
}

sub construct_node {
    my ($dir, $readonly, $resolved, $name, $args, $mode) = @_;
    return Data::Shared::_construct_with($dir, $readonly, $resolved, $name,
        _constructor_args($resolved, $args), $mode || {});
}

sub _preflight {
    my ($root, $node, $dir, $opening, $name) = @_;
    # Reopening loads only this level, so an untouched child's backend cannot block the store.
    for (my $current = $node; $current; $current = $current->{child}) {
        Data::Shared::Storage::_load($current->{resolved});
        last if $opening;
    }
    # plan touches no filesystem: a malformed child spec is refused before anything is published.
    unless ($opening) {
        my $as_child = bless { dir => defined $dir ? "$dir/child-0" : undef }, 'Data::Shared';
        for (my $c = $node->{child}; $c; $c = $c->{child}) {
            Data::Shared::Storage::plan($as_child, $c->{resolved}, 'child',
                _constructor_args($c->{resolved}, $c->{args}));
        }
    }
    if ($root->{strict_readonly}) {
        for (my $current = $node; $current; $current = $current->{child}) {
            Data::Shared::Storage::check_readonly($current->{resolved}, $name);
        }
    }
    return unless $opening;
    Carp::croak("Data::Shared: missing composite directory '" . ($dir // '') . "'") unless defined $dir && -d $dir;
    my $context = bless { dir => $dir }, 'Data::Shared';
    my $parent = Data::Shared::Storage::plan($context, $node->{resolved}, 'parent',
        _constructor_args($node->{resolved}, $node->{args}));
    my $index = Data::Shared::Storage::plan($context,
        _index_spec(), 'index', _index_args($node));
    Data::Shared::Storage::require_files($_) for ($parent, $index);
}

sub _validate_node {
    my ($node) = @_;
    return unless $node->{child};
    my $entry = $node->{resolved}{entry};
    my $key = $entry ? $entry->{key} : undef;
    Carp::croak("Data::Shared: '" . (defined $key ? $key : $node->{spec})
        . "' cannot be a composite parent (only hashmap, sortedset, kdtree, and graph can); use it as a leaf or a sidecar")
        unless defined $key && $PARENT_OK{$key};
    for my $option (qw(max_children cache_size)) {
        Carp::croak("Data::Shared: composite $option must be an integer >= 1")
            unless defined $node->{$option} && !ref $node->{$option}
                && $node->{$option} =~ /\A[1-9][0-9]*\z/;
    }
    _refuse_shared_child_path($node->{child});
}

sub _refuse_shared_child_path {
    my ($child) = @_;
    my $args = _strip_placeholder($child->{args} || []);
    my $resolved = $child->{resolved};
    my @named;
    my $convention = $resolved->{convention};
    if ($convention eq 'options') {
        my %opt = @$args == 1 && ref $args->[0] eq 'HASH' ? %{ $args->[0] }
                : @$args % 2                              ? ()
                :                                           @$args;
        @named = grep { defined $opt{$_} } qw(set keys);
    }
    elsif ($convention eq 'handle') {
        @named = 'path' if @$args == 1 && ref $args->[0] eq 'HASH'
                        && defined $args->[0]{path};
        @named = 'path' if @$args && defined $args->[0] && !ref $args->[0];
    }
    Carp::croak("Data::Shared: a composite child cannot name its own backing path ("
        . join(', ', @named) . "): one spec serves every child, so they would"
        . " share one file. Leave it out and the facade derives one per child")
        if @named;
    return;
}

sub new {
    my ($class, %o) = @_;
    my $node = $o{node} or Carp::croak('Data::Shared: Composite requires a node');
    my $self = bless { node => $node, dir => $o{dir}, path => [ @{ $o{path} || [] } ],
        name => $o{name}, readonly => $o{readonly} ? 1 : 0,
        _cleanup => $o{cleanup} ? 1 : 0, _frozen_ok => $o{frozen_ok} ? 1 : 0,
        strict_readonly => $o{strict_readonly} ? 1 : 0,
        cache => {}, lru_prev => {}, lru_next => {} }, $class;
    $self->{root_weak} = $o{root};
    weaken($self->{root_weak}) if $self->{root_weak};
    _preflight($self, $node, $self->{dir}, $o{opening}, $self->{name});
    if (defined $self->{dir} && !$o{opening}) {
        require File::Path;
        File::Path::make_path($self->{dir}, { mode => 0700 });
    }
    $self->_with_lock(sub {
        # sealed_ok permits nested children to reopen after sealing; top-level mounts refuse it.
        my %mode = (opening => $o{opening}, strict_readonly => $self->{strict_readonly},
            pending_paths => $o{pending_paths}, cleanup => $self->{_cleanup},
            frozen_ok => ($self->{_frozen_ok} || $o{sealed_ok}) ? 1 : 0);
        my ($parent) = construct_node($self->{dir}, $self->{readonly}, $node->{resolved}, 'parent', $node->{args}, \%mode);
        $self->{parent_handle} = $parent;
        $self->{parent_record} = { handle => $parent, entry => $node->{resolved}{entry}, dt => {} };
        my ($index) = Data::Shared::_construct_with($self->{dir}, $self->{readonly},
            _index_spec(), 'index', _index_args($node), \%mode);
        $self->{index} = $index;
        @{$self}{qw(_index_dev _index_ino)} = (stat _index_file($self))[0, 1]
            if defined $self->{dir};
        Carp::croak('Data::Shared: composite instance was deleted') if $index->get('x:') && !$self->{_cleanup};
        # 's:' is the child count; 'p:' marks an interrupted mutation that requires a recount.
        # _index_frozen, not frozen: only the index's own writability matters here.
        if (!$self->{readonly} && !$self->{_cleanup} && !$self->_index_frozen
            && ($index->get('p:') || !defined $index->get('s:'))) {
            $self->_index_put('s:', $self->_count_addresses);
            $self->_index_remove('p:');
        }
        my $chain = _chain_signature($node);
        my $recorded = $index->get('k:');
        if (defined $recorded && length $recorded) {
            Carp::croak("Data::Shared: composite '$self->{name}' storage was created for"
                . " [$recorded], not [$chain]")
                if $recorded ne $chain;
        }
        elsif (!$self->{readonly} && !$self->{_cleanup} && !$self->_index_frozen) {
            $self->_index_put('k:', $chain);
        }
        # 'b:' records the creation budget; the index's growing slot table cannot reveal it.
        my $budget = $index->get('b:');
        if (defined $budget && $budget =~ /\A[0-9]+\z/ && $budget < $node->{max_children}) {
            # A replayed manifest may ask for more; it gets the stored budget instead.
            Carp::croak("Data::Shared: composite '$self->{name}' storage was created"
                . " for max_children=$budget and cannot serve"
                . " $node->{max_children}; the index is sized when it is created,"
                . " so raising the budget needs unmount(unlink => 1) first")
                unless $o{replaying};
            $self->{_budget} = $budget;
        }
        elsif (!defined $budget && !$self->{readonly} && !$self->{_cleanup}
               && !$self->_index_frozen) {
            $self->_index_put('b:', $node->{max_children});
        }
    }, undef, $o{opening} ? 1 : 0);   # reopening tolerates an unwritable lock; creating does not
    return $self;
}

sub _index_file { my ($self) = @_; return "$self->{dir}/index.shm" }

# Best-effort: a missing or unreadable lock file must not block a shipped store.
sub _with_shared_lock {
    my ($self, $code) = @_;
    my $lockfile = defined $self->{dir} ? "$self->{dir}/.lock" : undef;
    my $fh;
    if (defined $lockfile && -e $lockfile && CORE::open($fh, '<', $lockfile)) {
        until (flock $fh, LOCK_SH) {
            last unless $!{EINTR};
        }
        # Recheck identity after waiting; teardown may have replaced the instance.
        $self->_assert_live_instance if $self->{index};
    }
    local $self->{_locked} = 1;
    return $code->();
}

# Index identity distinguishes incarnations even when frozen mappings cannot record deletion.
# Teardown may meet its own absent index, but must never remove a replacement.
use constant {
    _INDEX_SAME     => 0,
    _INDEX_ABSENT   => 1,   # our own teardown, finished or interrupted
    _INDEX_REPLACED => 2,   # a different incarnation of the store
};

sub _index_replaced {
    my ($self) = @_;
    return _INDEX_SAME unless defined $self->{dir} && defined $self->{_index_ino};
    my ($dev, $ino) = (stat _index_file($self))[0, 1];
    return _INDEX_ABSENT unless defined $ino;
    return ($dev == $self->{_index_dev} && $ino == $self->{_index_ino})
        ? _INDEX_SAME : _INDEX_REPLACED;
}

sub _assert_live_instance {
    my ($self) = @_;
    my $state = $self->_index_replaced;
    Carp::croak('Data::Shared: composite storage belongs to a newer instance')
        if $state == _INDEX_REPLACED;
    return if $self->{_cleanup};
    Carp::croak('Data::Shared: composite instance was deleted')
        if $self->{index}->get('x:') || $state == _INDEX_ABSENT;
    return;
}

sub _chain_signature {
    my ($node) = @_;
    my @levels;
    for (my $level = $node; $level; $level = $level->{child}) {
        push @levels, $level->{resolved}{class} . '->' . ($level->{resolved}{ctor} || 'new');
    }
    return join ' ', @levels;
}

sub _root {
    my ($self, $root) = @_;
    return $root if $root;
    my $r = $self->{root_weak};
    Carp::croak("Data::Shared: root has gone away") unless $r;
    return $r;
}

# The resolved spec is fixed for this instance's lifetime.
sub _key_is_int {
    my ($self) = @_;
    return $self->{_key_is_int} //= _key_is_int_for($self);
}

sub _key_int_bits {
    my ($self) = @_;
    return $self->{_key_int_bits} //= _key_int_bits_for($self);
}

sub _key_probe {
    my ($resolved) = @_;
    return lc $resolved->{variant} if defined $resolved->{variant};
    return $resolved->{class} =~ /::(\w+)\z/ ? lc $1 : '';
}

sub _key_is_int_for {
    my ($self) = @_;
    my $resolved = $self->{node}{resolved};
    # kdtree and graph address children by integer id without an int variant.
    return 1 if $self->_is_index_parent;
    return 0 if $resolved->{class} eq 'Data::SortedSet::Shared::Strings';
    return 1 if $resolved->{entry} && ($resolved->{entry}{key} || '') eq 'sortedset';
    return _key_probe($resolved) =~ /\A(?:i16|i32|ii|is)/ ? 1 : 0;
}

sub _valid_address {
    my ($self, $addr) = @_;
    return 0 unless defined $addr;
    return 1 unless $self->_key_is_int;
    # One canonical spelling per key, and \z not $: the index keys on the string and the
    # parent on its numeric value, so "7\n" would register a second child over one slot.
    my ($neg, $mag) = $addr =~ /\A(-?)(0|[1-9][0-9]*)\z/;
    return 0 if !defined $mag || ($neg && $mag eq '0');
    # Overflow is refused for composite parents only; plain leaves keep backend wrapping.
    if (my $bits = $self->_key_int_bits) {
        my $limit = $bits == 64
            ? ($neg ? '9223372036854775808' : '9223372036854775807')
            : (1 << ($bits - 1)) - ($neg ? 0 : 1);
        # Compare decimal strings to avoid rounding 64-bit bounds through a double.
        return 0 if length($mag) > length($limit)
                 || (length($mag) == length($limit) && $mag gt $limit);
    }
    return 1;
}

sub _key_int_bits_for {
    my ($self) = @_;
    # Id parents have no mirror slot whose fixed-width key could collide.
    return 0 if $self->_is_index_parent;
    my $probe = _key_probe($self->{node}{resolved});
    return 16 if $probe =~ /\Ai16/;
    return 32 if $probe =~ /\Ai32/;
    # Other integer-keyed parents wrap at IV width.
    return $self->_key_is_int ? 64 : 0;
}

sub _with_lock {
    my ($self, $code, $mutating, $read_only) = @_;
    # Check identity before every shortcut, including re-entry and read-only access.
    $self->_assert_live_instance if $self->{index};
    return $code->() if $self->{_locked};
    # Hold a shared lock through child opens so teardown cannot replace their storage.
    return $self->_with_shared_lock($code) if $self->{readonly};
    my $fh;
    if (defined $self->{dir}) {
        my $lockfile = "$self->{dir}/.lock";
        Carp::croak("Data::Shared: missing composite directory '$self->{dir}'") unless -d $self->{dir};
        # $read_only, not !$mutating: freeze and destroy are destructive yet pass no $mutating.
        unless (sysopen $fh, $lockfile, O_RDWR | O_APPEND | O_CREAT, 0600) {
            my $err = $!;
            unless ($read_only && -e $lockfile && CORE::open $fh, '<', $lockfile) {
                $! = $err;
                Carp::croak("Data::Shared: cannot open composite lock '$lockfile': $!");
            }
        }
        until (flock $fh, LOCK_EX) {
            Carp::croak("Data::Shared: cannot lock composite: $!") unless $!{EINTR};
        }
    } else {
        unless ($self->{lock_handle}) {
            # RWLock recovers a lock whose owner died.
            Data::Shared::_require_class('Data::Sync::Shared::RWLock', 'Data-Sync-Shared');
            $self->{lock_handle} = Data::Sync::Shared::RWLock->new(undef);
        }
        $self->{lock_handle}->wrlock;
    }
    local $self->{_locked} = 1;
    my $want = wantarray;
    my (@ret, $ret);
    my $ok = eval {
        if ($self->{index}) {
            $self->_assert_live_instance;
            # A sealed index cannot be repaired.
            if ($self->{index}->get('p:') && !$self->_index_frozen) {
                $self->_index_put('s:', $self->_count_addresses);
                $self->_index_remove('p:');
            }
            $self->_index_put('p:', 1) if $mutating;
        }
        if ($want) { @ret = $code->() } elsif (defined $want) { $ret = $code->() } else { $code->() }
        $self->_index_remove('p:') if $mutating && $self->{index};
        1;
    };
    my $err = $@;
    if ($fh) { close $fh }
    else { $self->{lock_handle}->wrunlock }
    die $err unless $ok;
    return $want ? @ret : $ret;
}

# Each index key needs next_pow2(2 + address length) bytes: the backend's 128-byte
# default covers 126-byte addresses, 272 covers 254. The mapping is sparse.
my $INDEX_ARENA_PER_ENTRY = 272;
my $INDEX_ARENA_MAX       = 0xFFFFFFFF;   # the backend's 32-bit size limit

# No freeze: sealing a composite index would prevent retiring it (freeze_all seals subtrees).
my %LIFECYCLE_METHOD = map { $_ => 1 } qw(stats sync unlink destroy frozen);

# Backends may reject a second freeze.
sub _freeze_once {
    my ($handle) = @_;
    return 0 unless $handle && $handle->can('freeze');
    return 0 if $handle->can('frozen') && $handle->frozen;
    $handle->freeze;
    return 1;
}

# Shared by every composite: nothing may write to it.
my $INDEX_SPEC;
sub _index_spec { return $INDEX_SPEC ||= Data::Shared::Registry::resolve_spec('hashmap:ss') }

sub _index_args {
    my ($node) = @_;
    my $entries = 2 * $node->{max_children} + 16;
    my $arena   = $entries * $INDEX_ARENA_PER_ENTRY;
    $arena = $INDEX_ARENA_MAX if $arena > $INDEX_ARENA_MAX;
    return [undef, $entries, 0, 0, 0, $arena];
}

sub _index_put {
    my ($self, $key, $value) = @_;
    return 1 if $self->{index}->put($key, $value);
    my $s = ($self->{index}->can('stats') ? $self->{index}->stats : undef) || {};
    # HashMap put exhausts capacity, not the smaller max_entries load-factor limit.
    my $shown = length($key) > 72 ? substr($key, 0, 69) . '...' : $key;
    Carp::croak(sprintf
        "Data::Shared: composite registry is full, cannot write '%s'"
        . " (entries %s/%s, string arena %s/%s bytes, max_children=%s)",
        $shown, map { defined $_ ? $_ : '?' }
            $s->{size}, $s->{capacity} // $s->{max_entries},
            $s->{arena_used}, $s->{arena_cap},
            $self->{node}{max_children});
}

sub _index_remove {
    my ($self, $key) = @_;
    $self->{index}->remove($key);
    Carp::croak("Data::Shared: cannot remove composite registry '$key'") if $self->{index}->exists($key);
}

sub _reg_id {
    my ($self, $addr) = @_;
    return $self->{index}->get('a:' . $addr);
}

sub _reg_constructed {
    my ($self, $addr, $id) = @_;
    my $value = $self->{index}->get('c:' . $addr);
    return 0 unless defined $value && length $value;
    # Legacy marker spelling, still read; t/17 covers it.
    return 1 if $value eq '1';
    $id = $self->_reg_id($addr) unless defined $id;
    return defined $id && $value eq "id:$id" ? 1 : 0;
}

sub _count_addresses {
    my ($self) = @_;
    my @keys = $self->{index}->keys;
    return scalar grep { substr($_, 0, 2) eq 'a:' } @keys;
}

sub _child_count {
    my ($self) = @_;
    if (!$self->{_locked} && $self->{index}->get('p:')) {
        return $self->_count_addresses if $self->{readonly};
        return $self->_with_lock(sub { $self->{index}->get('s:') }, undef, 1);
    }
    my $count = $self->{index}->get('s:');
    return defined $count ? $count : $self->_count_addresses;
}

sub _allocate_id {
    my ($self) = @_;
    my $limit = $self->{_budget} // $self->{node}{max_children};
    Carp::croak("Data::Shared: composite child limit exceeded (max_children=$limit) at $self->{name}")
        if $self->_child_count >= $limit;
    my $id = $self->{index}->get('n:') // 0;
    Carp::croak('Data::Shared: invalid composite child sequence') unless $id =~ /\A[0-9]+\z/;
    $self->_index_put('n:', $id + 1); # Child ids are never rolled back or reused.
    return $id;
}

sub _is_index_parent {
    my ($self) = @_;
    my $key = $self->{node}{resolved}{entry}{key} || '';
    return ($key eq 'kdtree' || $key eq 'graph') ? 1 : 0;
}

sub _parent_exists {
    my ($self, $addr) = @_;
    return defined $self->_reg_id($addr) ? 1 : 0 if $self->_is_index_parent;
    my $r = Data::Shared::_dispatch_record('exists', $self->{parent_record}, [$addr]);
    return $r ? 1 : 0;
}

sub _parent_register {
    my ($self, $addr, $id) = @_;
    return if $self->_is_index_parent;
    my $key = $self->{node}{resolved}{entry}{key} || '';
    if ($key eq 'sortedset') {
        if (!$self->_parent_exists($addr)) {
            Data::Shared::_dispatch_record('set', $self->{parent_record}, [$addr], 0);
        }
    } else {
        Data::Shared::_dispatch_record('set', $self->{parent_record}, [$addr], $id);
    }
    return if $self->_parent_exists($addr);
    my $s = ($self->{parent_handle}->can('stats') ? $self->{parent_handle}->stats : undef) || {};
    # SortedSet::Strings reports member capacity under "set".
    $s = $s->{set} if ref $s->{set} eq 'HASH';
    my $size = $s->{size} // $s->{count};
    my $cap = $s->{capacity} // $s->{max_entries} // $s->{max};
    Carp::croak(sprintf
        "Data::Shared: cannot register child '%s' in the %s parent of '%s'"
        . " (parent holds %s of %s; every child is an entry in it, so its own"
        . " capacity bounds max_children=%s)",
        $addr, $key || ref $self->{parent_handle}, $self->{name},
        map { defined $_ ? $_ : '?' }
            $size, $cap, $self->{_budget} // $self->{node}{max_children});
    return;
}

sub _parent_unregister {
    my ($self, $addr) = @_;
    return if $self->_is_index_parent;
    if ($self->_parent_exists($addr)) {
        Data::Shared::_dispatch_record('delete', $self->{parent_record}, [$addr]);
        Carp::croak('Data::Shared: cannot unregister child in parent backend') if $self->_parent_exists($addr);
    }
    return;
}

sub _untouch {
    my ($self, $id) = @_;
    return unless exists $self->{lru_prev}{$id};
    my $prev = delete $self->{lru_prev}{$id};
    my $next = delete $self->{lru_next}{$id};
    if (defined $prev) { $self->{lru_next}{$prev} = $next } else { $self->{lru_head} = $next }
    if (defined $next) { $self->{lru_prev}{$next} = $prev } else { $self->{lru_tail} = $prev }
}

sub _touch {
    my ($self, $id) = @_;
    return unless defined $self->{dir};
    return if defined $self->{lru_tail} && $self->{lru_tail} == $id;
    $self->_untouch($id);
    my $tail = $self->{lru_tail};
    $self->{lru_prev}{$id} = $tail;
    $self->{lru_next}{$id} = undef;
    if (defined $tail) { $self->{lru_next}{$tail} = $id } else { $self->{lru_head} = $id }
    $self->{lru_tail} = $id;
}

sub _forget {
    my ($self, $id) = @_;
    $self->_untouch($id);
    return delete $self->{cache}{$id};
}

sub _evict {
    my ($self) = @_;
    return unless defined $self->{dir};
    while (keys(%{ $self->{cache} }) > $self->{node}{cache_size}) {
        $self->_forget($self->{lru_head});
    }
}

sub _open_child {
    my ($self, $root, $addr, $id, $opening, $pending, $cleanup) = @_;
    if (my $rt = $self->{cache}{$id}) {
        $self->_touch($id);
        return $rt;
    }
    my $node = $self->{node}{child};
    my $dir = defined $self->{dir} ? "$self->{dir}/child-$id" : undef;
    Carp::croak("Data::Shared: child '" . join('/', '', @{ $self->{path} }, $addr)
        . "' exists in the shared index but belongs to another process; an anonymous"
        . " root has no backing file to reopen it (mount a file-backed root)")
        if $opening && !defined $dir;
    if (defined $dir) {
        Carp::croak("Data::Shared: missing composite child directory '$dir'") if $opening && !-d $dir;
        Carp::croak("Data::Shared: unpublished child storage exists at '$dir'; inspect it before retrying") if !$opening && -e $dir;
        if (!$opening) {
            push @$pending, $dir if $pending;
            require File::Path;
            File::Path::make_path($dir, { mode => 0700 });
        }
    }
    # Existing children may be sealed even on a writable root.
    my %mode = (opening => $opening, strict_readonly => $self->{strict_readonly},
        pending_paths => $pending, cleanup => $cleanup, frozen_ok => $self->{_frozen_ok},
        replaying => $opening ? 1 : 0,
        sealed_ok => $opening ? 1 : 0);
    my $rt;
    if ($node->{child}) {
        my $comp = Data::Shared::Composite->new(root => $root, name => $addr, node => $node, dir => $dir,
            path => [ @{ $self->{path} }, $addr ], readonly => $self->{readonly}, %mode);
        $rt = { kind => 'composite', comp => $comp, addr => $addr };
    } else {
        my ($handle) = construct_node($dir, $self->{readonly}, $node->{resolved}, 'child', $node->{args},
            { %mode, frozen_ok => $mode{frozen_ok} || $mode{sealed_ok} });
        my $record = { name => $addr, handle => $handle, entry => $node->{resolved}{entry}
            || { key => $node->{resolved}{class}, dist => 'unknown', path_class => 'map' }, dt => {} };
        $rt = { kind => 'leaf', record => $record, handle => $handle, addr => $addr };
    }
    # Walks and removal opens must not evict the caller's cached handles.
    return $rt if $cleanup || $self->{_walking};
    $self->{cache}{$id} = $rt;
    $self->_touch($id);
    $self->_evict;
    return $rt;
}

sub _existing_child {
    my ($self, $root, $addr) = @_;
    return undef unless $self->_valid_address($addr);
    my $id = $self->_reg_id($addr);
    return undef unless defined $id && $self->_reg_constructed($addr, $id);
    if (my $rt = $self->{cache}{$id}) { $self->_touch($id) unless $self->{_walking}; return $rt }
    return $self->_with_lock(sub {
        my $current = $self->_reg_id($addr);
        return undef unless defined $current && $self->_reg_constructed($addr, $current);
        return $self->_open_child($root, $addr, $current, 1);
    }, undef, 1);       # opens an existing child, writes nothing
}

sub _ensure_child {
    my ($self, $root, $addr) = @_;
    Carp::croak('Data::Shared: composite is read-only, cannot create a child') if $self->{readonly};
    Carp::croak("Data::Shared: invalid composite address '" . (defined $addr ? $addr : 'undef') . "' for $self->{node}{spec}")
        unless $self->_valid_address($addr);
    my $existing = $self->_existing_child($root, $addr);
    return $existing if $existing;
    return $self->_with_lock(sub {
        my $current = $self->_existing_child($root, $addr);
        return $current if $current;
        my $old_id = $self->_reg_id($addr);
        my $old_marker = $self->{index}->get('c:' . $addr);
        my $was_parent = $self->_parent_exists($addr);
        my $old_value = $was_parent && !$self->_is_index_parent
            ? Data::Shared::_dispatch_record('get', $self->{parent_record}, [$addr]) : undef;
        my $count = $self->_child_count;
        my $id = defined $old_id ? $old_id : $self->_allocate_id;
        my @pending;
        my $rt;
        my $ok = eval {
            $rt = $self->_open_child($root, $addr, $id, 0, \@pending);
            $self->_index_put('c:' . $addr, "id:$id");
            $self->_parent_register($addr, $id);
            $self->_index_put('s:', $count + 1) unless defined $old_id;
            $self->_index_put('a:' . $addr, $id) unless defined $old_id;
            1;
        };
        my $err = $@;
        unless ($ok) {
            $self->_forget($id);
            undef $rt;
            my $clean = eval {
                defined $old_marker ? $self->_index_put('c:' . $addr, $old_marker) : $self->_index_remove('c:' . $addr);
                $self->_index_remove('a:' . $addr) unless defined $old_id;
                $self->_parent_unregister($addr) unless $was_parent;
                Data::Shared::_dispatch_record('set', $self->{parent_record}, [$addr], $old_value)
                    if $was_parent && !$self->_is_index_parent;
                $self->_index_put('s:', $count);
                1;
            };
            my $rollback = $clean ? '' : $@;
            my $files = Data::Shared::_cleanup_paths(\@pending);
            _rethrow($err, length($rollback . $files) ? "$rollback $files" : '');
        }
        return $rt;
    }, 1);
}

sub dispatch_verb {
    my ($self, $root, $verb, $rest, @args) = @_;
    $root = $self->_root($root);
    if (!@$rest) {
        return Data::Shared::Node->new($root, [ @{ $self->{path} } ]) if $verb eq 'get';
        return 1 if $verb eq 'exists';
        Carp::croak("Data::Shared: cannot $verb a composite mount itself; address a child");
    }
    my ($addr, @child_rest) = @$rest;
    if (!@child_rest) {
        return $self->_verb_at_child($root, $verb, $addr, @args);
    }
    my $rt;
    if ($verb eq 'exists' || $verb eq 'get' || $verb eq 'delete') {
        $rt = $self->_existing_child($root, $addr);
        return $verb eq 'exists' ? 0 : undef unless $rt;
    } else {
        $rt = $self->_ensure_child($root, $addr);
    }
    if ($rt->{kind} eq 'composite') {
        return $rt->{comp}->dispatch_verb($root, $verb, \@child_rest, @args);
    }
    return Data::Shared::_dispatch_record($verb, $rt->{record}, \@child_rest, @args);
}

sub _verb_at_child {
    my ($self, $root, $verb, $addr, @args) = @_;
    my $key = $self->{node}{resolved}{entry}{key} || '';
    if ($verb eq 'exists') {
        return 0 unless $self->_valid_address($addr);
        return (defined $self->_reg_id($addr) || $self->_parent_exists($addr)) ? 1 : 0;
    }
    if ($verb eq 'get') {
        if ($key eq 'sortedset' && $self->{parent_handle}) {
            return undef unless $self->_valid_address($addr) && $self->_parent_exists($addr);
            return Data::Shared::_dispatch_record('get', $self->{parent_record}, [$addr]);
        }
        return undef unless $self->_valid_address($addr);
        return undef unless defined $self->_reg_id($addr);
        return Data::Shared::Node->new($root, [ @{ $self->{path} }, $addr ]);
    }
    if ($verb eq 'set' || $verb eq 'incr') {
        Carp::croak("Data::Shared: cannot $verb a composite child of $self->{node}{spec}; $verb a path inside it")
            unless $key eq 'sortedset';
        # Validate before setting the interrupted-mutation marker.
        Carp::croak("Data::Shared: sortedset $verb needs a " . ($verb eq 'set' ? 'score' : 'delta'))
            unless @args;
        Carp::croak('Data::Shared: composite is read-only') if $self->{readonly};
        Carp::croak("Data::Shared: invalid composite address '" . (defined $addr ? $addr : 'undef') . "' for $self->{node}{spec}")
            unless $self->_valid_address($addr);
        return $self->_with_lock(sub {
            my $old_id = $self->_reg_id($addr);
            my $was_parent = $self->_parent_exists($addr);
            my $score = $was_parent ? Data::Shared::_dispatch_record('get', $self->{parent_record}, [$addr]) : undef;
            my $count = $self->_child_count;
            my $result;
            my $ok = eval {
                unless (defined $old_id) {
                    my $id = $self->_allocate_id;
                    $self->_parent_register($addr, $id);
                    $self->_index_put('s:', $count + 1);
                    $self->_index_put('a:' . $addr, $id);
                }
                $result = Data::Shared::_dispatch_record($verb, $self->{parent_record}, [$addr], @args);
                Carp::croak('Data::Shared: parent score operation failed') unless defined $result;
                1;
            };
            my $err = $@;
            unless ($ok) {
                my $clean = eval {
                    $self->_index_remove('a:' . $addr) unless defined $old_id;
                    $self->_index_put('s:', $count);
                    if ($was_parent) { Data::Shared::_dispatch_record('set', $self->{parent_record}, [$addr], $score) }
                    else { $self->_parent_unregister($addr) }
                    1;
                };
                _rethrow($err, $clean ? '' : $@);
            }
            # Registration pre-inserts score 0; report whether the address existed before this call.
            return 1 if $verb eq 'set' && !$was_parent && !$result;
            return $result;
        }, 1);
    }
    if ($verb eq 'delete') {
        return $self->delete_subtree($root, $addr);
    }
    Carp::croak("Data::Shared: operation '$verb' is not supported at a composite child of $self->{node}{spec}");
}

sub dispatch_pushpop {
    my ($self, $root, $which, $rest, @args) = @_;
    $root = $self->_root($root);
    Carp::croak("Data::Shared: cannot $which a composite mount itself; address a child") unless @$rest;
    my ($addr, @child_rest) = @$rest;
    # A missing child is an empty one to pop, not one to create.
    my $rt = $which eq 'pop' ? $self->_existing_child($root, $addr) : $self->_ensure_child($root, $addr);
    return undef unless $rt;
    if ($rt->{kind} eq 'composite') {
        return $rt->{comp}->dispatch_pushpop($root, $which, \@child_rest, @args);
    }
    return Data::Shared::_dispatch_record_pushpop($which, $rt->{record}, \@child_rest, @args);
}

sub dispatch_call {
    my ($self, $root, $rest, $method, @args) = @_;
    $root = $self->_root($root);
    if (!@$rest) {
        return $self->$method(@args)
            if $LIFECYCLE_METHOD{$method} && $self->can($method);
        Carp::croak("Data::Shared: cannot freeze composite mount '$self->{name}' through call();"
            . " sealing the subtree would seal its child index too. Use \$root->freeze_all")
            if $method eq 'freeze';
        if ($self->{parent_handle} && $self->{parent_handle}->can($method)) {
            return $self->{parent_handle}->$method(@args);
        }
        if ($method eq 'children') {
            my @c = $self->children_at($root, []);
            return wantarray ? @c : \@c;
        }
        if ($method eq 'child_count') {
            return $self->_child_count;
        }
        Carp::croak("Data::Shared: composite mount '" . $self->{name} . "' has no method '$method'");
    }
    my ($addr, @child_rest) = @$rest;
    # Retiring must not construct a missing child.
    my $retire = $method eq 'unlink' || $method eq 'destroy';
    return $self->delete_subtree($root, $addr) if $retire && !@child_rest;
    my $rt = $self->{readonly} || $retire
        ? $self->_existing_child($root, $addr) : $self->_ensure_child($root, $addr);
    return undef if $retire && !$rt;
    Carp::croak('Data::Shared: read-only composite has no constructed child at this path') unless $rt;
    if ($rt->{kind} eq 'composite') {
        return $rt->{comp}->dispatch_call($root, \@child_rest, $method, @args);
    }
    # Native leaf unlink/destroy ignore record suffixes and remove the whole file.
    Carp::croak("Data::Shared: '$method' retires a composite child, not the record"
        . " at '$addr/" . join('/', @child_rest) . "' below it;"
        . " use shared_delete to remove a record")
        if $retire;
    return Data::Shared::_dispatch_record_call($rt->{record}, \@child_rest, $method, @args);
}

sub children_at {
    my ($self, $root, $rest) = @_;
    # Must not require a live root: teardown lists children after its root may be gone.
    if (!@$rest) {
        my @addrs = map { substr($_, 2) } grep { substr($_, 0, 2) eq 'a:' } $self->{index}->keys;
        my @sorted = $self->_key_is_int ? (sort { $a <=> $b } @addrs) : (sort @addrs);
        return @sorted;
    }
    $root = $self->_root($root);
    my ($addr, @more) = @$rest;
    my $rt = $self->_existing_child($root, $addr);
    Carp::croak("Data::Shared: no composite child at '" . join('/', @{ $self->{path} }, $addr) . "'")
        unless $rt;
    Carp::croak("Data::Shared: child '$addr' is not composite") unless $rt->{kind} eq 'composite';
    return $rt->{comp}->children_at($root, \@more);
}

sub handle_at {
    my ($self, $root, $rest) = @_;
    $root = $self->_root($root);
    if (!@$rest) {
        return Data::Shared::Node->new($root, [ @{ $self->{path} } ]);
    }
    my ($addr, @more) = @$rest;
    my $rt = $self->_existing_child($root, $addr);
    Carp::croak("Data::Shared: no child at '" . join('/', @{ $self->{path} }, $addr) . "'")
        unless $rt;
    if ($rt->{kind} eq 'composite') {
        return $rt->{comp}->handle_at($root, \@more);
    }
    Carp::croak("Data::Shared: handle() path must name a leaf exactly (got extra components)") if @more;
    return $rt->{handle};
}

# The caller owns registry, cache, and directory cleanup.
sub _remove_child_storage {
    my ($rt) = @_;
    if ($rt->{kind} eq 'composite') { $rt->{comp}->destroy }
    elsif ($rt->{handle}->can('unlink')) { $rt->{handle}->unlink }
    return;
}

sub delete_subtree {
    my ($self, $root, $addr) = @_;
    $root = $self->_root($root);
    Carp::croak('Data::Shared: composite is read-only, cannot delete') if $self->{readonly};
    return undef unless $self->_valid_address($addr);
    return $self->_with_lock(sub {
        my $id = $self->_reg_id($addr);
        my $was_parent = $self->_parent_exists($addr);
        return undef unless defined $id || $was_parent;
        my $cleanup_rt;
        if (defined $id && $self->{node}{child}{child} && $self->_reg_constructed($addr, $id)) {
            $cleanup_rt = $self->_open_child($root, $addr, $id, 1, undef, 1);
        }
        my $marker = $self->{index}->get('c:' . $addr);
        my $count = $self->_child_count;
        my $score = $was_parent && !$self->_is_index_parent
            ? Data::Shared::_dispatch_record('get', $self->{parent_record}, [$addr]) : undef;
        my $ok = eval {
            if (defined $id) {
                # Remove readiness before registration; interruption then leaves a recoverable score-only child.
                $self->_index_remove('c:' . $addr);
                $self->_index_remove('a:' . $addr);
                $self->_index_put('s:', $count - 1);
            }
            $self->_parent_unregister($addr);
            1;
        };
        my $err = $@;
        unless ($ok) {
            my $clean = eval {
                $self->_index_put('c:' . $addr, $marker) if defined $marker;
                $self->_index_put('a:' . $addr, $id) if defined $id;
                $self->_index_put('s:', $count);
                # Restoring an untouched record would fail on a frozen parent.
                Data::Shared::_dispatch_record('set', $self->{parent_record}, [$addr], $score)
                    if $was_parent && !$self->_is_index_parent && !$self->_parent_exists($addr);
                1;
            };
            _rethrow($err, $clean ? '' : $@);
        }
        if (defined $id) {
            my $rt = $self->_forget($id) || $cleanup_rt;
            if ($rt) {
                my $ok = eval {
                    _remove_child_storage($rt);
                    1;
                };
                unless ($ok) {
                    my $why = Data::Shared::_strip_location($@);
                    Carp::croak("Data::Shared: subtree detached but retiring its storage"
                        . " failed: $why");
                }
            }
            if (defined $self->{dir}) {
                my $cleanup = Data::Shared::_cleanup_paths(["$self->{dir}/child-$id"]);
                Carp::croak("Data::Shared: subtree detached but cleanup failed: $cleanup") if length $cleanup;
            }
        }
        return 1;
    }, 1);
}

sub destroy {
    my ($self) = @_;
    Carp::croak('Data::Shared: composite is read-only, cannot destroy') if $self->{readonly};
    return 0 if defined $self->{dir} && !-d $self->{dir};
    # Teardown may retry after removing its own index.
    local $self->{_cleanup} = 1;
    return $self->_with_lock(sub {
        my $frozen = $self->_index_frozen;
        if (!$frozen) {
            # Set 'x:' first: waiters keep the old mapped index and could rebuild the subtree.
            $self->_index_put('x:', 1);
            for my $addr ($self->children_at(undef, [])) {
                my $id = $self->_reg_id($addr);
                my $rt = $self->{cache}{$id};
                if (!$rt && $self->{node}{child}{child} && $self->_reg_constructed($addr, $id)) {
                    $rt = $self->_open_child($self->{root_weak}, $addr, $id, 1, undef, 1);
                }
                $self->_index_remove('a:' . $addr);
                $self->_index_remove('c:' . $addr);
                $self->_forget($id);
                _remove_child_storage($rt) if $rt;
            }
            $self->_index_put('s:', 0);
        } else {
            # Frozen indexes already reject the mutation marker before any creation.
            for my $rt (values %{ $self->{cache} }) {
                _remove_child_storage($rt);
            }
        }
        $self->{parent_handle}->unlink if $self->{parent_handle} && $self->{parent_handle}->can('unlink');
        $self->{index}->unlink if $self->{index} && $self->{index}->can('unlink');
        $self->{cache} = {};
        $self->{lru_prev} = {};
        $self->{lru_next} = {};
        delete @{$self}{qw(lru_head lru_tail)};
        if (defined $self->{dir}) {
            # Lock only the nested dirs: flock via a second descriptor of our held lock would block.
            my @under;
            if (opendir my $dh, $self->{dir}) {
                @under = map { "$self->{dir}/$_" }
                    grep { $_ ne '.' && $_ ne '..' } readdir $dh;
                closedir $dh;
            }
            my $held = Data::Shared::_lock_composite_dirs(\@under);
            my $cleanup = Data::Shared::_cleanup_paths([$self->{dir}]);
            undef $held;
            Carp::croak("Data::Shared: cannot remove retired composite: $cleanup") if length $cleanup;
        }
        return 1;
    });
}

sub _rethrow {
    my ($err, $rollback) = @_;
    die $err if ref $err;
    # Croak here, not in a shared helper, so Carp blames the composite's caller.
    Carp::croak(Data::Shared::_strip_location($err)
        . (defined $rollback && length $rollback ? " (rollback: $rollback)" : ''));
}

sub _sync_once {
    my ($rt) = @_;
    return $rt->{comp}->sync if $rt->{kind} eq 'composite';
    return 0 unless $rt->{handle}->can('sync');
    $rt->{handle}->sync;
    return 1;
}

sub sync {
    my ($self) = @_;
    my $n = 0;
    # Sealed children need no _frozen_ok: _existing_child opens with opening=1,
    # which already permits them.
    local $self->{_walking} = 1;
    my $root = $self->{root_weak};
    if (defined $self->{dir}) {
        # One child open at a time, or a large composite runs out of descriptors.
        for my $addr ($self->children_at(undef, [])) {
            my $rt = $self->_existing_child($root, $addr) or next;
            $n += _sync_once($rt);
        }
    } else {
        # Anonymous roots can flush only children mapped in this process.
        $n += _sync_once($_) for values %{ $self->{cache} };
    }
    # Native sync returns nothing; count the call regardless of its result.
    for my $h ($self->{parent_handle}, $self->{index}) {
        next unless $h && $h->can('sync');
        $h->sync;
        $n++;
    }
    return $n;
}

sub _index_frozen {
    my ($self) = @_;
    return $self->{index} && $self->{index}->can('frozen') && $self->{index}->frozen ? 1 : 0;
}

# The class of the first level that cannot reopen read-only, or undef.
sub _unsealable {
    my ($self) = @_;
    for (my $node = $self->{node}; $node; $node = $node->{child}) {
        return $node->{resolved}{class} unless Data::Shared::Storage::readonly_capable($node->{resolved});
    }
    return;
}

# The index is frozen last, so a frozen index means the subtree is sealed.
sub frozen {
    my ($self) = @_;
    return $self->_index_frozen && !defined $self->_unsealable ? 1 : 0;
}

sub freeze {
    my ($self) = @_;
    Carp::croak("Data::Shared: cannot freeze a read-only composite") if $self->{readonly};
    return $self->_with_lock(sub {
        my $root = $self->{root_weak};
        my $n = 0;
        # Earlier freezes may have sealed uncached children; see sync.
        local $self->{_walking} = 1;
        for my $addr ($self->children_at(undef, [])) {
            my $rt = $self->_existing_child($root, $addr) or next;
            if ($rt->{kind} eq 'composite') { $n += $rt->{comp}->freeze }
            else { $n += _freeze_once($rt->{handle}) }
        }
        $n += _freeze_once($self->{parent_handle});
        $n += _freeze_once($self->{index});
        return $n;
    });
}

sub unlink {
    my ($self) = @_;
    return $self->destroy;
}

sub stats {
    my ($self) = @_;
    my %children;
    for my $id (sort { $a <=> $b } keys %{ $self->{cache} }) {
        my $rt = $self->{cache}{$id};
        $children{ $rt->{addr} } = $rt->{kind} eq 'composite' ? $rt->{comp}->stats
            : ($rt->{handle}->can('stats') ? $rt->{handle}->stats : { class => ref $rt->{handle} });
    }
    return {
        class => 'Data::Shared::Composite',
        spec => $self->{node}{spec},
        children => $self->_child_count,
        open => scalar keys %{ $self->{cache} },
        child_stats => \%children,
    };
}

1;

__END__

=head1 NAME

Data::Shared::Composite - Runtime for composite Data::Shared mounts

=head1 DESCRIPTION

Internal to L<Data::Shared>; not a public API. A composite mount
keeps one child instance per parent address: children are allocated
through a hidden registry, constructed lazily on first write, opened
on demand from per-child storage, and cached with LRU eviction, which
C<cache_size> bounds for a file-backed root only: an anonymous segment
cannot be reopened once evicted, so an anonymous composite keeps every
child it has opened. A read, delete or pop at a missing child never
creates one, but on a writable root C<call> other than C<unlink> or
C<destroy> at a missing address does, because the facade cannot know whether the native method
mutates. See the C<DEEP PATHS> section of
L<Data::Shared>, which is authoritative for both.

Lifecycle mutations are serialized through allocation, construction,
publication, and deletion. Exception rollback preserves existing scores and
reservations. Shared counts and cache-order updates take constant time.
Legacy readiness flags remain readable. An interrupted mutation leaves a
marker, and the count is rebuilt from it on the next writable open or lock.
Freezing and flushing walk every registered child, reopening an evicted one
read-only where it is already sealed. Unpublished files require explicit recovery;
the module does not implement a power-loss transaction journal.

=cut
