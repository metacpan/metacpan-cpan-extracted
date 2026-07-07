package App::Greple::xlate::Cache;

use v5.14;
use warnings;

use Data::Dumper;
use JSON;
use List::Util qw(pairmap mesh);
use Hash::Util qw(lock_keys);

sub TIEHASH {
    my $self = shift;
    my $obj = $self->new(name => @_);
    $obj;
}

sub EXISTS {
    my($obj, $key) = @_;
    $obj->access($key);
    exists $obj->current->{$key} or exists $obj->saved->{$key};
}

sub FETCH {
    my($obj, $key) = @_;
    $obj->access($key);
    $obj->get($key);
}

sub STORE {
    my($obj, $key, $val) = @_;
    $obj->access($key);
    $obj->set($key, $val);
}

sub DESTROY {
    my $obj = shift;
    $obj->update;
}

my %default = (
    name => '',		# cache filename
    saved => undef,	# saved hash
    saved_order => [],  # keys of saved data in file order
    current => undef,	# current using hash
    clear => 0,		# clean up cache data
    accessed => {},	# accessed keys
    order => [],	# accessed keys in order
    accumulate => 0,	# do not delete unused entry
    force_update => 0,	# update cache file anyway
    updated => 0,	# number of updated entries
    format => 'list',	# saving cache file format
    old_pos => undef,   # memoized key-to-position map of saved_order
    # NOTE: reference-valued defaults must get fresh copies in new()
    seed => undef,      # seed cache file for a fresh cache
    seeded => 0,        # true when the seed was actually loaded
    readonly => 0,   # suppress all cache file writes
);

for my $key (keys %default) {
    no strict 'refs';
    *{$key} = sub :lvalue { $_[0]->{$key} }
}

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    $obj->{accessed} = {};
    $obj->{order} = [];
    $obj->{saved_order} = [];
    lock_keys %{$obj};
    pairmap { $obj->{$a} = $b } @_;
    $obj->open if $obj->name;
    $obj;
}

sub access {
    my $obj = shift;
    my $key = shift;
    push @{$obj->order}, $key if not $obj->accessed->{$key}++;
}

sub get {
    my $obj = shift;
    my $key = shift;
    $obj->current->{$key} //= delete $obj->saved->{$key};
}

sub set {
    my $obj = shift;
    pairmap {
        if (ref $a eq 'ARRAY' and ref $b eq 'ARRAY') {
            @$a == @$b or die;
            $obj->set(mesh $a, $b);
        } else {
            my $c = $obj->current->{$a} //= delete $obj->saved->{$a};
            if (not defined $c or $c ne $b) {
                $obj->current->{$a} = $b;
                $obj->updated++;
            }
        }
    } @_;
    $obj;
}

sub json {
    JSON->new->utf8->canonical->pretty;
}

sub open {
    my $obj = shift;
    my $file = $obj->name || return;
    if ($obj->clear) {
        warn "created $file\n" unless -f $file;
        CORE::open my $fh, '>', $file or die "$file: $!\n";
        print $fh "{}\n";
    }
    $obj->{saved} = {};
    $obj->{saved_order} = [];
    if (CORE::open my $fh, $file) {
        my $data = do { local $/; <$fh> };
        $obj->load_data($data) if $data ne '';
        warn "read cache from $file\n";
    }
    if (my $seed = $obj->seed) {
        if (%{$obj->saved}) {
            warn "$seed: seed ignored (cache exists)\n";
        } elsif (CORE::open my $fh, $seed) {
            my $data = do { local $/; <$fh> };
            if ($data ne '') {
                $obj->load_data($data);
                $obj->seeded = 1;
                warn "seed cache from $seed\n";
            }
        } else {
            warn "$seed: $!\n";
        }
    }
    $obj;
}

sub load_data {
    my($obj, $data) = @_;
    my $json = &json->decode($data);
    if (ref $json eq 'HASH') {
        $obj->{saved} = $json;
        $obj->{saved_order} = [];   # legacy format: no order info
    } elsif (ref $json eq 'ARRAY') {
        $obj->{saved} = +{ map @{$_}[0,1], @$json };
        $obj->{saved_order} = [ map $_->[0], @$json ];
    } else {
        die "unexpected json data.";
    }
    $obj->{old_pos} = undef;    # invalidate memoized position map
}

sub old_size {
    my $obj = shift;
    scalar @{$obj->saved_order};
}

sub old_position {
    my($obj, $key) = @_;
    my $pos = $obj->{old_pos} //= do {
        my $order = $obj->saved_order;
        +{ map { $order->[$_] => $_ } 0 .. $#$order };
    };
    $pos->{$key};
}

sub old_entries_slice {
    my($obj, $lo, $hi) = @_;
    my $order = $obj->saved_order;
    $lo = 0 if $lo < 0;
    $hi = $#$order if $hi > $#$order;
    my @out;
    for my $k (@$order[$lo .. $hi]) {
        my $v = $obj->saved->{$k} // $obj->current->{$k};
        push @out, [ $k, $v ] if defined $v;
    }
    @out;
}

sub update {
    my $obj = shift;
    return if $obj->readonly;
    my $file = $obj->name || return;
    if (not $obj->force_update and $obj->updated == 0) {
        # accumulate: nothing changed, disk content is already right.
        # otherwise: return only when there is nothing to purge.
        return if not $obj->seeded and ($obj->accumulate or %{$obj->saved} == 0);
    }
    if ($obj->accumulate) {
        # POD promises unused entries survive: adopt them unconditionally
        for my $k (@{$obj->saved_order}, sort keys %{$obj->saved}) {
            next if $obj->accessed->{$k};
            defined(my $v = delete $obj->saved->{$k}) or next;
            $obj->current->{$k} //= $v;
            $obj->access($k);
        }
    }
    # A key is "used" when it was accessed this run, even if its value
    # was never FETCHed (e.g. the run died before the output callback
    # could read it back).  Adopt such entries so they survive.
    for my $k (grep { $obj->accessed->{$_} } keys %{$obj->saved}) {
        $obj->current->{$k} //= delete $obj->saved->{$k};
    }
    while (my($k, $v) = each %{$obj->current}) {
        delete $obj->current->{$k} if not defined $v;
    }
    if (not %{$obj->current}) {
        # A seeded cache may end its run without any access (e.g.
        # --xlate-cache=create dies right after setup); persist the
        # seed content instead of leaving the created file empty.
        return $obj->checkpoint if $obj->seeded;
        return;
    }
    my $json_obj //= &json; # this is necessary to be called from DESTROY
    if (CORE::open my $fh, '>', $file) {
        my $data = $obj->format eq 'list' ? $obj->list_data : $obj->hash_data;
        my $json = $json_obj->encode($data);
        print $fh $json;
        warn "write cache to $file\n";
    } else {
        warn "$file: $!\n";
    }
}

##
## Write out the merged state (saved and current, current wins)
## WITHOUT purging unused entries.  Called after each translation
## batch so that an interrupted run does not lose paid API results.
## The final write (update) keeps the purging semantics.
##
## Keys stored without going through the tie interface (no access())
## are not visible to checkpoint.
##
sub checkpoint {
    my $obj = shift;
    return if $obj->readonly;
    my $file = $obj->name || return;
    my(@list, %done);
    for my $key (@{$obj->saved_order}) {
        next if $done{$key}++;
        my $v = $obj->current->{$key} // $obj->saved->{$key};
        push @list, [ $key => $v ] if defined $v;
    }
    for my $key (@{$obj->order}) {
        next if $done{$key}++;
        my $v = $obj->current->{$key};
        push @list, [ $key => $v ] if defined $v;
    }
    for my $key (sort keys %{$obj->saved}) {   # legacy HASH caches
        next if $done{$key}++;
        my $v = $obj->saved->{$key};
        push @list, [ $key => $v ] if defined $v;
    }
    if (CORE::open my $fh, '>', $file) {
        print $fh &json->encode(\@list);
    } else {
        warn "$file: $!\n";
    }
}

sub hash_data {
    my $obj = shift;
    $obj->current;
}

sub list_data {
    my $obj = shift;
    my %hash = %{$obj->current};
    my @list;
    for my $key (@{$obj->order}) {
        next unless exists $hash{$key};
        push @list, [ $key => delete $hash{$key} ];
    }
    for my $key (sort keys %hash) {
        warn "$key: not in order list.";
        push @list, [ $key => delete $hash{$key} ];
    }
    die if %hash;
    \@list;
}

1;
