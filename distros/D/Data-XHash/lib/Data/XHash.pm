package Data::XHash;

use 5.006;
use strict;
use warnings;
use base qw/Exporter/;
use subs qw/clear delete exists fetch first_key next_key
  scalar store xhash xhashref/;
use Carp;
use Scalar::Util qw/blessed/;

our @EXPORT_OK = (qw/&xhash &xhashref &xh &xhn &xhr &xhrn/);

# XHash values are stored internally using a ring doubly-linked with
# unweakened references:
# {hash}{$key} => [$previous_link, $next_link, $value, $key]

=head1 NAME

Data::XHash - Extended, ordered hash (commonly known as an associative array
or map) with key-path traversal and automatic index keys

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

    use Data::XHash;
    use Data::XHash qw/xhash xhashref/;
    use Data::XHash qw/xh xhn xhr xhrn/;

    $tiedhref = Data::XHash->new(); # A blessed and tied hashref
    # Note: Don't call "tie" yourself!

    # Exports are shortcuts to call Data::XHash->new()->push()
    # or Data::XHash->new()->pushref() for you.
    $tiedhref = xh('auto-indexed', { key => 'value' });
    $tiedhref = xhash('auto-indexed', { key => 'value' });
    $tiedhref = xhashref([ 'auto-indexed', { key => 'value' } ]);
    $tiedhref = xhn('hello', { root => { branch =>
      [ { leaf => 'value' }, 'world' ] } }); # (nested)
    $tiedhref = xhr([ 'auto-indexed', { key => 'value' } ]);
    $tiedhref = xhrn([ 'hello', { root => { branch =>
      [ { leaf => 'value' }, 'world' ] } } ]); # (nested)

    # Note: $xhash means you can use either $tiedhref or the
    # underlying object at tied(%$tiedhref)

    ## Hash-like operations

    # Getting keys or paths
    $value = $tiedhref->{$key};
    $value = $tiedhref->{\@path};
    $value = $xhash->fetch($key);
    $value = $xhash->fetch(\@path);

    # Auto-vivify a Data::XHash at the end of the path
    $tiedhref2 = $tiedhref1->{ [ @path, {} ] };
    $tiedhref->{ [ @path, {} ] }->$some_xh_method(...);
    $tiedhref = $xhash->fetch( [ @path, {} ] );
    $xhash->fetch( [ @path, {} ] )->$some_xh_method(...);

    # Setting keys or paths
    $tiedhref->{$key} = $value;
    $tiedhref->{\@path} = $value;
    $xhash->store($key, $value, %options);
    $xhash->store(\@path, $value, %options);

    # Setting the next auto-index key
    $tiedhref->{[]} = $value; # Recommended syntax
    $tiedhref->{+undef} = $value;
    $tiedhref->{[ undef ]} = $value; # Any path key may be undef
    $xhash->store([], $value, %options);
    $xhash->store(undef, $value, %options);
    $xhash->store([ undef ], $value, %options);

    # Clear the xhash
    %$tiedhref = ();
    $xhash->clear();

    # Delete a key and get its value
    $value = delete $tiedhref->{$key}; # or \@path
    $value = $xhash->delete($key); # or \@path
    $value = $xhash->delete(\%options?, @local_keys);

    # Does a key exist?
    $boolean = exists $tiedhref->{$key}; # or \@path
    $boolean = $xhash->exists($key); # or \@path

    # Keys and lists of keys
    @keys = keys %$tiedhref; # All keys using iterator
    @keys = $xhash->keys(%options); # Faster, without iterator
    $key = $xhash->FIRSTKEY(); # Uses iterator
    $key = $xhash->first_key();
    $key1 = $xhash->previous_key($key2);
    $key = $xhash->NEXTKEY(); # Uses iterator
    $key2 = $xhash->next_key($key1);
    $key = $xhash->last_key();
    $key = $xhash->next_index(); # The next auto-index key

    # Values
    @all_values = values %$tiedhref; # Uses iterator
    @all_values = $xhash->values(); # Faster, without iterator
    @some_values = @{%$tiedhref}{@keys}; # or pathrefs
    @some_values = $xhash->values(\@keys); # or pathrefs

    ($key, $value) = each(%$tiedhref); # Keys/values using iterator

    # Call coderef with ($xhash, $key, $value, @more_args) for
    # each key/value pair and then undef/undef.
    @results = $xhash->foreach(\&coderef, @more_args);

    # Does the hash contain any key/value pairs?
    $boolean = scalar(%$tiedhref);
    $boolean = $xhash->scalar();

    ## Array-like operations

    $value = $xhash->pop(); # last value
    ($key, $value) = $xhash->pop(); # last key/value
    $value = $xhash->shift(); # first value
    ($key, $value) = $xhash->shift(); # first key/value

    # Append values or { keys => values }
    $xhash->push(@elements);
    $xhash->pushref(\@elements, %options);

    # Insert values or { keys => values }
    $xhash->unshift(@elements);
    $xhash->unshiftref(\@elements, %options);

    # Merge in other XHashes (recursively)
    $xhash->merge(\%options?, @xhashes);

    # Export in array-like fashion
    @list = $xhash->as_array(%options);
    $list = $xhash->as_arrayref(%options);

    # Export in hash-like fasion
    @list = $xhash->as_hash(%options);
    $list = $xhash->as_hashref(%options);

    # Reorder elements
    $xhash->reorder($reference, @keys); # [] = sorted index_only

    # Remap elements
    $xhash->remap(%mapping); # or \%mapping
    $xhash->renumber(%options);

    ## TIEHASH methods - see perltie

    # TIEHASH, FETCH, STORE, CLEAR, DELETE, EXISTS
    # FIRSTKEY, NEXTKEY, UNTIE, DESTROY

=head1 DESCRIPTION

Data::XHash provides an object-oriented interface to tied, ordered
hashes. Hash elements may be assigned keys explicitly or automatically
in mix-and-match fashion like arrays in PHP.

It also includes support for trees of nested XHashes, tree traversal,
and conversion to and from native Perl data structures.

Suggested uses include structured configuration information or HTTP query
parameters in which order may at least sometimes be significant, for
passing mixed positional and named parameters, sparse arrays, or porting
PHP code.

=head1 EXPORTS

You may export any of the shortcut functions. None are exported by default.

=head1 FUNCTIONS

=head2 $tiedref = xh(@elements)

=head2 $tiedref = xhash(@elements)

=head2 $tiedref = xhashref(\@elements, %options)

=head2 $tiedref = xhn(@elements)

=head2 $tiedref = xhr(\@elements, %options)

=head2 $tiedref = xhrn(\@elements, %options)

These convenience functions call C<< Data::XHash->new() >> and then
C<pushref()> the specified elements. The "r" and "ref" versions take an
arrayref of elements; the others take a list. The "n" versions are
shortcuts for the C<< nested => 1 >> option of C<pushref()>.

    $tiedref = xh('hello', {root=>xh({leaf=>'value'}),
      {list=>xh(1, 2, 3)});
    $tiedref = xhn('hello', {root=>{leaf=>'value'}},
      {list=>[1, 2, 3]});

=cut

sub xh { return __PACKAGE__->new()->pushref(\@_); }

sub xhn { return __PACKAGE__->new()->pushref(\@_, nested => 1); }

sub xhr { return __PACKAGE__->new()->pushref(@_); }

sub xhrn { return __PACKAGE__->new()->pushref(shift, nested => 1, @_); }

*xhash = \&xh;
*xhashref = \&xhr;

=head1 METHODS

=head2 Data::XHash->new( )

=head2 $xhash->new( )

These create a new Data::XHash object and tie it to a new, empty hash. They
bless the hash as well and return a reference to the hash (C<$tiedref>).

Do not use C<< tie %some_hash, 'Data::XHash'; >> - it will croak!

=cut

sub new {
    my $type = shift;
    # Support $xhash->new() for same-class auto-vivification.
    my $class = blessed($type) || $type;
    my $self = bless { }, $class;	# The XHash object
    my %hash;

    $self->clear();
    tie %hash, $class, $self;
    return bless \%hash, $class;	# The XHash tiedref
}

sub TIEHASH {
    my ($class, $self) = @_;

    croak("Use \"${class}->new()\", not \"tie \%hash, '$class'\"") unless $self;
    return $self;
}

=head2 $tiedref->{$key}

=head2 $tiedref->{\@path}

=head2 $xhash->fetch($key)

=head2 $xhash->fetch(\@path)

These return the value for the specified hash key, or C<undef> if the key does
not exist.

If the key parameter is reference to a non-empty array, its elements are
traversed as a path through nested XHashes.

If the last path element is a hashref, the path will be auto-vivified
(Perl-speak for "created when referenced") and made to be an XHash if
necessary (think "fetch a path to a hash"). Otherwise, any missing
element along the path will cause C<undef> to be returned.

    $xhash->{[]}; # undef

    $xhash->{[qw/some path/, {}]}->isa('Data::XHash'); # always true
    # Similar to native Perl: $hash->{some}{path} ||= {};

=cut

sub FETCH {
    my ($self, $key) = @_;

    if (ref($key) eq 'ARRAY' && @$key) {
	# Fetch with path traversal
	return $self->traverse($key, op => 'fetch')->{value};
    }

    # Local fetch
    $self = tied(%$self) || $self;
    my $entry = $self->{hash}{$key};
    return $entry? $entry->[2]: undef;
}

*fetch = \&FETCH;

=head2 $tiedref->{$key} = $value

=head2 $tiedref->{\@path} = $value

=head2 $xhash->store($key, $value, %options)

=head2 $xhash->store(\@path, $value, %options)

These store the value for the specified key in the XHash. Any existing value
for the key is overwritten. New keys are stored at the end of the XHash.

If the key parameter is a reference to a non-empty array, its elements are
traversed as a path through nested XHashes. Path elements will be
auto-vivified as necessary and intermediate ones will be forced to XHashes.

If the key is an empty path or the C<undef> value, or any path key is the
C<undef> value, the next available non-negative integer index in the
corresponding XHash is used instead.

These return the XHash tiedref or object (whichever was used).

Options:

=over

=item nested => $boolean

If this option is true, arrayref and hashref values will be converted into
XHashes.

=back

=cut

sub STORE {
    my ($this, $key, $value, %options) = @_;
    my $array_key = ref($key) eq 'ARRAY';

    if ($array_key && @$key) {
	# Store with path traversal.
	my $path = $this->traverse($key, op => 'store');
	$path->{container}->store($path->{key}, $value, %options);
    } else {
	# Store locally.
	my $self = tied(%$this) || $this;

	# Get the next index for undef or [].
	$key = defined($self->{max_index})? ($self->{max_index} + 1):
	  $self->next_index() if !defined($key) || $array_key;

	if ($options{nested}) {
	    # Convert nested native structures to XHashes.
	    if (ref($value) eq 'HASH') {
		$value = $self->new()->pushref([$value], %options);
	    } elsif (ref($value) eq 'ARRAY') {
		$value = $self->new()->pushref($value, %options);
	    }
	}

	if (my $entry = $self->{hash}{$key}) {
	    # Replace the value for an existing key.
	    $entry->[2] = $value;
	} else {
	    my $link;
	    if (my $tail = $self->{tail}) {
		my $head = $tail->[1];
		# Link an additional element into a non-empty ring.
		$link = $self->{hash}{$key} =
		  $tail->[1] = $head->[0] = [$tail, $head, $value, $key];
	    } else {
		# Start a new key ring.
		$link = $self->{hash}{$key} = [undef, undef, $value, $key];
		$link->[0] = $link->[1] = $link;
	    }
	    $self->{tail} = $link;
	    $self->{max_index} = $key
	      if ($key =~ /^\d+$/ && (defined($self->{max_index})?
	      ($key > $self->{max_index}): ($key >= $self->next_index())));
	}
    }

    return $this;
}

*store = \&STORE;

=head2 %$tiedref = ()

=head2 $xhash->clear( )

These clear the XHash.

Clear returns the XHash tiedref or object (whichever was used).

=cut

sub CLEAR {
    my ($this) = @_;
    my $self = tied(%$this) || $this;

    if ($self->{hash}) {
	# Blow away unweakened refs before tossing the hash.
	@$_ = () foreach (values %{$self->{hash}});
    }
    $self->{hash} = {};
    delete $self->{tail};
    delete $self->{iter};
    $self->{max_index} = -1;
    return $this;
}

*clear = \&CLEAR;

=head2 delete $tiedref->{$key} # or \@path

=head2 $xhash->delete($key) # or \@path

=head2 $xhash->delete(\%options?, @keys)

These remove the element with the specified key and return its value. They
quietly return C<undef> if the key does not exist.

The method call can also delete (and return) multiple local (not path) keys
at once.

Options:

=over

=item to => $destination

If C<$destination> is an arrayref, hashref, or XHash, each deleted
C<< { $key => $value } >> is added to it and the destination is returned
instead of the most recently deleted value.

=back

=cut

sub DELETE : method {
    my $self = shift;
    my %options = ref($_[0]) eq 'HASH'? %{+shift}: ();
    my $key = $_[0];

    if (ref($key) eq 'ARRAY' && @$key) {
	# Delete across the path.
	my $path = $self->traverse($key, op => 'delete');

	return $path->{container}?
	  $path->{container}->delete($path->{key}): undef;
    }

    # Delete locally.
    my $to = $options{to};
    my $return;
    $self = tied(%$self) || $self;

    while (@_) {
	$key = shift;

        if (my $link = $self->{hash}{$key}) {
	    if (ref($to) eq 'ARRAY') {
		push(@$to, { $key => $link->[2] });
	    } elsif (ref($to) eq 'HASH') {
		$to->{$key} = $link->[2];
	    } elsif (blessed($to) && $to->isa(__PACKAGE__)) {
		$to->store($key, $link->[2]);
	    } else {
		$return = $link->[2];
	    }

	    if ($link->[0] != $link) {
		# There are other keys, so unlink this one from the ring.
		$link->[0][1] = $link->[1]; # prev.next = my.next
		$link->[1][0] = $link->[0]; # next.prev = my.prev
		$self->{max_index} = undef
		  if defined($self->{max_index}) && $self->{max_index} eq $key;
		$self->{tail} = $link->[0] if $self->{tail} == $link;
		delete $self->{hash}{$key};
	    } else {
		# We're deleting the last key, so do a full reset.
		$self->clear();
	    }
	}
    }

    return $to? $to: $return;
}

*delete = \&DELETE;

=head2 exists $tiedref->{$key} # or \@path

=head2 $xhash->exists($key) # or \@path

These return true if the key (or path) exists.

=cut

sub EXISTS {
    my ($self, $key) = @_;

    if (ref($key) eq 'ARRAY' && @$key) {
	# Check existence across the path.
	my $path = $self->traverse($key, op => 'exists');

	return $path->{container} && $path->{container}->exists($path->{key});
    }

    # Check existence locally.
    $self = tied(%$self) || $self;
    return exists($self->{hash}{$key});
}

*exists = \&EXISTS;

=head2 $xhash->FIRSTKEY( )

This returns the first key (or C<undef> if the XHash is empty) and resets
the internal iterator.

=cut

sub FIRSTKEY {
    my ($self) = @_;
    $self = tied(%$self) || $self;

    if ($self->{tail}) {
	# The first key is in the head (the tail's next link).
	my $head = $self->{iter} = $self->{tail}[1];
	return $head->[3];
    }

    delete $self->{iter};
    return undef;
}

=head2 $xhash->first_key( )

This returns the first key (or C<undef> if the XHash is empty).

=cut

sub first_key {
    my ($self) = @_;
    $self = tied(%$self) || $self;

    return ($self->{tail}? $self->{tail}[1][3]: undef);
}

=head2 $xhash->previous_key($key)

This returns the key before C<$key>, or C<undef> if C<$key> is the first
key or doesn't exist.

=cut

sub previous_key {
    my ($self, $key) = @_;
    $self = tied(%$self) || $self;

    my $entry = $self->{hash}{$key};
    return (($entry && $entry != $self->{tail}[1])? $entry->[0][3]: undef);
}

=head2 $xhash->NEXTKEY( )

This returns the next key using the internal iterator, or C<undef> if there
are no more keys.

=cut

sub NEXTKEY {
    my ($self) = @_;
    $self = tied(%$self) || $self;

    my $iter = $self->{iter};
    if ($iter && $iter != $self->{tail}) {
	$iter = $self->{iter} = $iter->[1];
	return $iter->[3];
    }

    return undef;
}

=head2 $xhash->next_key($key)

This returns the key after C<$key>, or C<undef> if C<$key> is the last key or
doesn't exist.

Path keys are not supported.

=cut

sub next_key {
    my ($self, $key) = @_;
    $self = tied(%$self) || $self;

    my $entry = $self->{hash}{$key};
    return (($entry && $entry != $self->{tail})? $entry->[1][3]: undef);
}

=head2 $xhash->last_key( )

This returns the last key, or C<undef> if the XHash is empty.

=cut

sub last_key {
    my $self = shift;
    $self = tied(%$self) || $self;

    return ($self->{tail}? $self->{tail}[3]: undef);
}

=head2 $xhash->next_index( )

This returns the next numeric insertion index. This is either "0" or one more
than the current largest non-negative integer index.

=cut

sub next_index {
    my ($self) = @_;
    $self = tied(%$self) || $self;

    if (!defined($self->{max_index})) {
	# Recalculate max_index if that key was previously deleted.
	$self->{max_index} = -1;
	foreach (grep(/^\d+$/, keys %{$self->{hash}})) {
	    $self->{max_index} = $_ if $_ > $self->{max_index};
	}
    }

    return $self->{max_index} + 1;
}

=head2 scalar(%$tiedref)

=head2 $xhash->scalar( )

This returns true if the XHash is not empty.

=cut

sub SCALAR : method {
    my ($self) = @_;

    return defined($self->{tail});
}

*scalar = \&SCALAR;

=head2 $xhash->keys(%options)

This method is equivalent to C<keys(%$tiedref)> but may be called on the
object (and is much faster).

Options:

=over

=item index_only => $boolean

If true, only the integer index keys are returned. If false, all keys are
returned,

=item sorted => $boolean

If index_only mode is true, this option determines whether index keys are
returned in ascending order (true) or XHash insertion order (false).

=back

=cut

sub keys : method {
    my ($self, %options) = @_;
    $self = tied(%$self) || $self;
    my @keys;

    if (my $tail = $self->{tail}) {
	my $link = $tail;
	do {
	    $link = $link->[1];
	    push(@keys, $link->[3]);
	} while ($link != $tail);
    }

    if ($options{index_only}) {
	@keys = grep(/^-?\d+$/, @keys);
	@keys = sort({ $a <=> $b } @keys) if $options{sorted};
    }

    return @keys;
}

=head2 $xhash->values(\@keys?)

This method is equivalent to C<values(%$tiedref)> but may be called on the
object (and, if called without specific keys, is much faster too).

You may optionally pass a reference to an array of keys whose values should
be returned (equivalent to the slice C<@{$tiedref}{@keys}>). Key paths are
allowed, but don't forget that the list of keys/paths must be provided as
an array ref (C<< [ $local_key, \@path ] >>).

=cut

sub values : method {
    my $self = shift;
    my $keys = shift;

    $self = tied(%$self) || $self;
    if (ref($keys) eq 'ARRAY') {
	return map(ref($_)? $self->fetch($_): ($self->{hash}{$_} || [])->[2],
	  @$keys);
    }

    my @values;

    if (my $tail = $self->{tail}) {
	my $link = $tail;
	do {
	    $link = $link->[1];
	    push(@values, $link->[2]);
	} while ($link != $tail);
    }

    return @values;
}

=head2 $xhash->foreach(\&coderef, @more_args)

This method calls the coderef as follows

    push(@results, &$coderef($xhash, $key, $value, @more_args));

once for each key/value pair in the XHash (if any), followed by a
call with both set to C<undef>.

It returns the accumulated list of coderef's return values.

Example:

    # The sum and product across an XHash of numeric values
    %results = $xhash->foreach(sub {
        my ($xhash, $key, $value, $calc) = @_;

        return %$calc unless defined($key);
        $calc->{sum} += $value;
        $calc->{product} *= $value;
        return ();
      }, { sum => 0, product => 1 });

=cut

sub foreach : method {
    my $self = shift;
    my $code = shift;
    my @results;

    $self = tied(%$self) || $self;
    if (my $tail = $self->{tail}) {
	my $link = $tail;

	do {
	    $link = $link->[1];
	    push(@results, &$code($self, $link->[3], $link->[2], @_));
	} while ($link != $tail);
    }

    push(@results, &$code($self, undef, undef, @_));
    return @results;
}

sub UNTIE {}

sub DESTROY { shift->clear(); }

=head2 $xhash->pop( )

=head2 $xhash->shift( )

These remove the first element (shift) or last element (pop) from the XHash
and return its value (in scalar context) or its key and value (in list
context). If the XHash was already empty, C<undef> or C<()> is returned
instead.

=cut

sub pop : method {
    my ($self) = @_;

    $self = tied(%$self) || $self;
    return wantarray? (): undef unless $self->{tail};

    my $key = $self->{tail}[3];
    return wantarray? ($key, $self->delete($key)): $self->delete($key);
}

sub shift : method {
    my ($self) = @_;

    $self = tied(%$self) || $self;
    return wantarray? (): undef unless $self->{tail};

    my $key = $self->{tail}[1][3];
    return wantarray? ($key, $self->delete($key)): $self->delete($key);
}

=head2 $xhash->push(@elements)

=head2 $xhash->pushref(\@elements, %options)

=head2 $xhash->unshift(@elements)

=head2 $xhash->unshiftref(\@elements, %options)

These append elements at the end of the XHash (C<push()> and C<pushref()>)
or insert elements at the beginning of the XHash (C<unshift()> and
C<unshiftref()>).

Scalar elements are automatically assigned a numeric index using
C<next_index()>. Hashrefs are added as key/value pairs. References
to references are dereferenced by one level before being added. (To add
a hashref as a hashref rather than key/value pairs, push or unshift a
reference to the hashref instead.)

These return the XHash tiedref or object (whichever was used).

Options:

=over

=item at_key => $key

This will push after C<$key> instead of at the end of the XHash or unshift
before C<$key> instead of at the beginning of the XHash. This only applies
to the first level of a nested push or unshift.

This must be a local key (not a path), and the operation will croak if
the key is not found.

=item nested => $boolean

If true, values that are arrayrefs (possibly containing hashrefs) or
hashrefs will be recursively converted to XHashes.

=back

=cut

sub push : method { return shift->pushref(\@_); }

sub pushref {
    my ($this, $list, %options) = @_;
    my $self = tied(%$this) || $this;
    my $at_key = delete $options{at_key};
    my $save_tail;

    croak "pushref requires an arrayref" unless ref($list) eq 'ARRAY';

    if (defined($at_key)) {
	my $entry = $self->{hash}{$at_key};
	croak "pushref at_key => key does not exist" unless $entry;
	if ($entry != $self->{tail}) {
	    # Temporarily shift the end of the ring
	    $save_tail = $self->{tail};
	    $self->{tail} = $entry;
	}
    }

    foreach my $item (@$list) {
	if (ref($item) eq 'HASH') {
	    $self->store($_, $item->{$_}, %options) foreach (keys %$item);
	} elsif (ref($item) eq 'REF') {
	    $self->store(undef, $$item, %options, nested => 0);
	} else {
	    $self->store(undef, $item, %options);
	}
    }

    # Restore the ring after an at_key push.
    $self->{tail} = $save_tail if $save_tail;

    return $this;
}

sub unshift : method { return shift->unshiftref(\@_); }

sub unshiftref {
    my ($this, $list, %options) = @_;
    my $self = tied(%$this) || $this;
    my $at_key = delete($options{at_key});

    croak "unshiftref requires an arrayref" unless ref($list) eq 'ARRAY';

    my $save_tail = $self->{tail};

    if (defined($at_key)) {
	my $entry = $self->{hash}{$at_key};
	croak "unshiftref at_key => key does not exist"
	  unless $self->{hash}{$at_key};
	# Temporarily shift the ring
	$self->{tail} = $entry->[0];
    }

    $self->pushref($list, %options);
    $self->{tail} = $save_tail if $save_tail;

    return $this;
}

=head2 $xhash->merge(\%options?, @xhashes)

This recursively merges each of the XHash trees in C<@xhashes> into the
current XHash tree C<$xhash> as follows:

If a key has both existing and new values and both are XHashes, the elements
in the new XHash are added to the existing XHash.

Otherwise, if the new value is an XHash, the value is set to a B<copy> of
the new XHash.

Otherwise the value is set to the new value.

Returns the XHash tiedref or object (whichever was used).

Examples:

    # Clone a tree of nested XHashes (preserving index keys)
    $clone = xh()->merge({ indexed_as => 'hash' }, $xhash);

    # Merge $xhash2 (with new keys) into existing XHash $xhash1
    $xhash1->merge($xhash2);

Options:

=over

=item indexed_as => $type

If C<$type> is C<array> (the default), numerically-indexed items in
each merged XHash are renumbered as they are added (like
C<< push($xhash->as_array()) >>).

If C<$type> is C<hash>, numerically-indexed items are merged without
renumbering (like C<< push($xhash->as_hash()) >>).

=back

=cut

sub merge {
    my $self = shift;
    my %options = (ref($_[0]) eq 'HASH')? %{shift()}: ();

    $options{'indexed_as'} ||= 'array';
    foreach (@_) {
	$_->foreach(sub {
	    my ($xhash, $key, $new_val) = @_;
	    my $cur_val;

	    return () unless defined($key);
	    if ($options{'indexed_as'} ne 'hash' && $key =~ /^-?\d+$/) {
		# Renumber index keys in array mode
		$key = $self->next_index();
		$cur_val = undef;
	    } else {
		$cur_val = $self->fetch($key);
	    }
	    if (blessed($new_val) && $new_val->isa(__PACKAGE__)) {
		$self->store($key, $cur_val = $new_val->new())
		  unless blessed($cur_val) && $cur_val->isa(__PACKAGE__);
		$cur_val->merge(\%options, $new_val);
	    } else {
		$self->store($key, $new_val);
	    }

	    return ();
	});
    }

    return $self;
}

=head2 $xhash->as_array(%options)

=head2 $xhash->as_arrayref(%options)

=head2 $xhash->as_hash(%options)

=head2 $xhash->as_hashref(%options)

These methods export the contents of the XHash as native Perl arrays or
arrayrefs.

The "array" versions return the elements in an "array-like" array or array
reference; elements with numerically indexed keys are returned without their
keys.

The "hash" versions return the elements in an "hash-like" array or array
reference; all elements, including numerically indexed ones, are returned
with keys.

    xh( { foo => 'bar' }, 123, \{ key => 'value' } )->as_arrayref();
    # [ { foo => 'bar' }, 123, \{ key => 'value'} ]

    xh( { foo => 'bar' }, 123, \{ key => 'value' } )->as_hash();
    # ( { foo => 'bar' }, { 0 => 123 }, { 1 => { key => 'value' } } )

    xh(xh({ 3 => 'three' }, { 2 => 'two' })->as_array())->as_hash();
    # ( { 0 => 'three' }, { 1 => 'two' } )

    xh( 'old', { key => 'old' } )->push(
    xh( 'new', { key => 'new' } )->as_array())->as_array();
    # ( 'old', { key => 'new' }, 'new' )

    xh( 'old', { key => 'old' } )->push(
    xh( 'new', { key => 'new' } )->as_hash())->as_hash();
    # ( { 0 => 'new' }, { key => 'new' } )

Options:

=over

=item nested => $boolean

If this option is true, trees of nested XHashes are recursively expanded.

=back

=cut

sub as_array { return @{shift->as_arrayref(@_)}; }

sub as_arrayref {
    my ($self, %options) = @_;
    $self = tied(%$self) || $self;
    my $tail = $self->{tail};

    return [] unless $tail;

    my (@list, $key, $value);
    my $link = $tail;
    do {
	$link = $link->[1];
	($key, $value) = @{$link}[3, 2];

	if ($key =~ /^-?\d+$/) {
	    if ($options{nested} && blessed($value) &&
	      $value->isa(__PACKAGE__)) {
		push(@list, $value->as_arrayref(%options));
	    } else {
		push(@list, ref($value) =~ /HASH|REF/? \$value: $value);
	    }
	} else {
	    if ($options{nested} && blessed($value) &&
	      $value->isa(__PACKAGE__)) {
		push(@list, { $key => $value->as_arrayref(%options) });
	    } else {
		push(@list, { $key => $value });
	    }
	}
    } while ($link != $self->{tail});

    return \@list;
}

sub as_hash { return @{shift->as_hashref(@_)}; }

sub as_hashref {
    my ($self, %options) = @_;
    $self = tied(%$self) || $self;
    my $tail = $self->{tail};

    return [] unless $tail;

    my (@list, $key, $value);
    my $link = $tail;
    do {
	$link = $link->[1];
	($key, $value) = @{$link}[3, 2];

	if ($options{nested} && blessed($value) && $value->isa(__PACKAGE__)) {
	    push(@list, { $key => $value->as_hashref(%options) });
	} else {
	    push(@list, { $key => $value });
	}
    } while ($link != $tail);

    return \@list;
}

=head2 $xhash->reorder($refkey, @keys)

This reorders elements within the XHash relative to the reference element
having key C<$refkey>, which must exist and will not be moved.

If the reference key appears in C<@keys>, the elements with keys preceding
it will be moved immediately before the reference element. All other
elements will be moved immediately following the reference element.

Only the first occurence of any given key in C<@keys> is
considered - duplicates are ignored.

If any key is an arrayref, it is replaced with a sorted list of index keys.

This method returns the XHash tiedref or object (whichever was used).

    # Move some keys to the beginning of the XHash.
    $xhash->reorder($xhash->first_key(), @some_keys,
      $xhash->first_key());

    # Move some keys to the end of the XHash.
    $xhash->reorder($xhash->last_key(), @some_keys);

    # Group numeric index keys in ascending order at the lowest one.
    $xhash->reorder([]);

=cut

sub reorder {
    my ($this, @keys) = @_;
    my $self = tied(%$this) || $this;
    my ($refkey, $before, @after);

    @keys = map(ref($_) eq 'ARRAY'?
      $self->keys(index_only => 1, sorted => 1): $_, @keys);
    $refkey = shift(@keys);

    croak("reorder reference key does not exist")
      unless $self->{hash}{$refkey};

    while (@keys) {
	my $key = shift(@keys);

	if ($key ne $refkey) {
	    push(@after, { $key => $self->delete($key) })
	      if $self->{hash}{$key};
	} elsif (!$before) {
	    $before = [ @after ];
	    @after = ();
	}
    }

    $self->unshiftref($before, at_key => $refkey) if $before;
    $self->pushref(\@after, at_key => $refkey) if @after;

    return $this;
}

=head2 $xhash->remap(\%mapping)

=head2 $xhash->remap(%mapping)

This remaps element keys according to the specified mapping (a hash of
C<< $old_key => $new_key >>). The mapping must map old keys to new keys
one-to-one.

The order of elements in the XHash is unchanged.

The XHash tiedref or object is returned (whichever was used).

=cut

sub remap {
    my $this = shift;
    my $self = tied(%$this) || $this;
    my %map = ref($_[0]) eq 'HASH'? %{$_[0]}: @_;
    my %hash;

    croak "remap mapping must be unique"
      unless keys(%{{ reverse %map }}) == keys(%map);

    my ($key, $new_key, $entry);
    while (($key, $entry) = each(%{$self->{hash}})) {
	$key = $entry->[3] = $new_key if defined($new_key = $map{$key});
	$hash{$key} = $entry;
    }

    $self->{hash} = \%hash;

    return $this;
}

=head2 $xhash->renumber(%options)

This renumbers all elements with an integer index (those returned by
C<< $xhash->keys(index_only => 1) >>). The order of elements is
unchanged.

It returns the XHash tiedref or object (whichever was used).

Options:

=over

=item from => $starting_index

Renumber from C<$starting_index> instead of the default zero.

=item sorted => $boolean

This option is passed to C<< $xhash->keys() >>.

If set to true, keys will be renumbered in sorted sequence. This results
in a "relative" renumbering (previously higher index keys will still be
higher after renumbering, regardless of order in the XHash).

If false or not set, keys will be renumbered in XHash (or "absolute") order.

=back

=cut

sub renumber {
    my ($self, %options) = @_;
    my $start = $options{from} || 0;

    my @keys = $self->keys(index_only => 1, sorted => $options{sorted});
    if (@keys) {
	my %map;

	@map{@keys} = map($_ + $start, 0 .. $#keys);
	$self->remap(\%map);
    }

    return $self;
}

=head2 $xhash->traverse($path, %options?)

This method traverses key paths across nested XHash trees. The path may be
a simple scalar key, or it may be an array reference containing multiple
keys along the path.

An C<undef> value along the path will translate to the next available
integer index at that level in the path. A C<{}> at the end of the path
forces auto-vivification of an XHash at the end of the path if one does not
already exist there.

This method returns a reference to an hash containing the elements
"container", "key", and "value". If the path does not exist, the container
and key values with be C<undef>.

An empty path (C<[]>) is equivalent to a path of C<undef>.

Options:

=over

=item op

This option specifies the operation for which the traversal is being
performed (fetch, store, exists, or delete).

=item xhash

This forces the path to terminate with an XHash (for "fetch" paths ending in
C<{}>).

=item vivify

This will auto-vivify missing intermediate path elements.

=back

=cut

sub traverse {
    my ($self, $path, %options) = @_;
    my @path = (ref($path) eq 'ARRAY')? @$path: ($path);
    my $container = $self;
    my $op = $options{op} || '';
    my ($key, $value);

    if (@path && ref($path[-1]) eq 'HASH') {
	# Vivify to terminal XHash on fetch path [ ... {} ].
	$options{vivify} = $options{xhash} = 1 if $op eq 'fetch';
	pop(@path);
    }

    # Default to vivify on store.
    $options{vivify} = 1 if $op eq 'store' && !exists($options{vivify});

    while (@path) {
	$key = shift(@path);
	if (!defined($key) || !$container->exists($key)) {
	    # This part of the path is missing. Stop or vivify.
	    return { container => undef, key => undef, value => undef }
	      unless $options{vivify};

	    # Use the next available index for undef keys.
	    $key = $container->next_index() unless defined($key);

	    if (@path || $options{xhash}) {
		# Vivify an XHash for intermediates or fetch {}.
		$container->store($key, $value = $self->new());
	    } else {
		$value = undef;
	    }
	} else {
	    $value = $container->fetch($key);
	    $container->store($key, $value = $self->new())
	      if (@path || $options{xhash}) &&
	      (!blessed($value) || !$value->isa(__PACKAGE__));
	}
	$container = $value if @path;
    }

    $key = $container->next_index() unless defined($key);
    return { container => $container, key => $key, value => $value };
}

=head1 AUTHOR

Brian Katzung, C<< <briank at kappacs.com> >>

=head1 BUG TRACKING

Please report any bugs or feature requests to
C<bug-data-xhash at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-XHash>. I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::XHash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-XHash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-XHash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-XHash>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-XHash/>

=back

=head1 SEE ALSO

=over

=item L<Array::AsHash>

An array wrapper to manage elements as key/value pairs.

=item L<Array::Assign>

Allows you to assign names to array indexes.

=item L<Array::OrdHash>

Like L<Array::Assign>, but with native Perl syntax.

=item L<Data::Omap>

An ordered map implementation, currently implementing an array of single-key
hashes stored in key-sorting order.

=item L<Hash::AsObject>

Auto accessors and mutators for hashes and tied hashes.

=item L<Hash::Path>

A basic hash-of-hash traverser. Discovered by the author after writing
Data::XHash.

=item L<Tie::IxHash>

An ordered hash implementation with a different interface and data
structure and without auto-indexed keys and some of Data::XHash's
other features.

Tie::IxHash is probably the "standard" ordered hash module. Its
simpler interface and underlying array-based implementation allow it to
be almost 2.5 times faster than Data::XHash for some operations.
However, its Delete, Shift, Splice, and Unshift methods degrade in
performance with the size of the hash. Data::XHash uses a doubly-linked
list, so its delete, shift, splice, and unshift methods are unaffected
by hash size.

=item L<Tie::Hash::Array>

Hashes stored as arrays in key sorting-order.

=item L<Tie::LLHash>

A linked-list-based hash like L<Data::XHash>, but it doesn't support the
push/pop/shift/unshift array interface and it doesn't have automatic keys.

=item L<Tie::StoredOrderHash>

Hashes with items stored in least-recently-used order.

=back

=for comment
head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Katzung.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::XHash
