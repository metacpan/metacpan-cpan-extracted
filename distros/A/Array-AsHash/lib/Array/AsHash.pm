package Array::AsHash;

use warnings;
use strict;
use Clone ();
use Scalar::Util qw(refaddr);

our $VERSION = '0.32';

my ( $_bool, $_to_string );

BEGIN {

    # these are defined in a BEGIN block because otherwise, overloading
    # doesn't get them in time.
    $_bool = sub {
        my $self = CORE::shift;
        return $self->acount;
    };

    $_to_string = sub {
        no warnings 'once';
        require Data::Dumper;
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Terse  = 1;
        my $self   = CORE::shift;
        my $string = '';
        return $string unless $self;
        while ( my ( $k, $v ) = $self->each ) {

            foreach ( $k, $v ) {
                $_ = ref $_ ? Data::Dumper::Dumper($_) : $_;
            }
            $string .= "$k\n        $v\n";
        }
        return $string;
    };
}

use overload bool => $_bool, '""' => $_to_string, fallback => 1;

my $_actual_key = sub {
    my ( $self, $key ) = @_;
    if ( ref $key ) {
        my $new_key = $self->{curr_key_of}{ refaddr $key};
        return refaddr $key unless defined $new_key;
        $key = $new_key;
    }
    return $key;
};

# private because it doesn't match expectations.  The "index" of a
# non-existent key is one greater than the current list
my $_index = sub {
    my ( $self, $key ) = @_;
    my $index =
        $self->exists($key)
      ? $self->{index_of}{$key}
      : scalar @{ $self->{array_for} };    # automatically one greater
    return $index;
};

my $_croak = sub {
    my ( $proto, $message ) = @_;
    require Carp;
    Carp::croak($message);
};

my $_validate_kv_pairs = sub {
    my ( $self, $arg_for ) = @_;
    my $sub = $arg_for->{sub} || ( caller(1) )[3];

    if ( @{ $arg_for->{pairs} } % 2 ) {
        $self->$_croak("Arguments to $sub must be an even-sized list");
    }
};

sub new {
    my $class = shift;
    return $class->_initialize(@_);
}

sub _initialize {
    my ( $class, $arg_ref ) = @_;
    my $self = bless {} => $class;
    $self->{array_for} = [];
    return $self unless $arg_ref;
    my $array = $arg_ref->{array} || [];
    $self->{is_strict} = $arg_ref->{strict};
    $array = Clone::clone($array) if $arg_ref->{clone};

    unless ( 'ARRAY' eq ref $array ) {
        $class->$_croak('Argument to new() must be an array reference');
    }
    if ( @$array % 2 ) {
        $class->$_croak('Uneven number of keys in array');
    }

    $self->{array_for} = $array;
    foreach ( my $i = 0; $i < @$array; $i += 2 ) {
        my $key = $array->[$i];
        $self->{index_of}{$key} = $i;
        if ( ref $key ) {
            my $old_address = refaddr $arg_ref->{array}[$i];
            my $curr_key    = "$key";
            $self->{curr_key_of}{$old_address} = $curr_key;
        }
    }
    return $self;
}

sub get {
    my ( $self, @keys ) = @_;
    my @get;
    foreach my $key (@keys) {
        $key = $self->$_actual_key($key);
        next unless defined $key;
        my $exists = $self->exists($key);
        if ( $self->{is_strict} && !$exists ) {
            $self->$_croak("Cannot get non-existent key ($key)");
        }
        if ($exists) {
            CORE::push @get, $self->{array_for}[ $self->$_index($key) + 1 ];
        }
        elsif ( @keys > 1 ) {
            CORE::push @get, undef;
        }
        else {
            return;
        }
    }
    return wantarray ? @get
      : @keys > 1    ? \@get
      : $get[0];
}

my $_insert = sub {
    my ( $self, $key, $label, $index ) = splice @_, 0, 4;

    $self->$_validate_kv_pairs(
        { pairs => \@_, sub => "Array::AsHash::insert_$label" } );
    $key = $self->$_actual_key($key);

    unless ( $self->exists($key) ) {
        $self->$_croak("Cannot insert $label non-existent key ($key)");
    }
    foreach ( my $i = 0; $i < @_; $i += 2 ) {
        my $new_key = $_[$i];
        if ( $self->exists($new_key) ) {
            $self->$_croak("Cannot insert duplicate key ($new_key)");
        }
        $self->{index_of}{$new_key} = $index + $i;
    }

    my @tail = splice @{ $self->{array_for} }, $index;
    push @{ $self->{array_for} }, @_, @tail;
    my %seen = @_;
    foreach my $curr_key ( CORE::keys %{ $self->{index_of} } ) {
        if ( $self->{index_of}{$curr_key} >= $index
            && !exists $seen{$curr_key} )
        {
            $self->{index_of}{$curr_key} += @_;
        }
    }
    return $self;
};

sub strict {
    my $self = shift;
    return $self->{is_strict} unless @_;
    $self->{is_strict} = !!shift;
    return $self;
}

sub clone {
    my $self = CORE::shift;
    return ( ref $self )->new(
        {   array => scalar $self->get_array,
            clone => 1,
        }
    );
}

sub unshift {
    my ( $self, @kv_pairs ) = @_;
    $self->$_validate_kv_pairs( { pairs => \@kv_pairs } );
    foreach my $curr_key ( CORE::keys %{ $self->{index_of} } ) {
        $self->{index_of}{$curr_key} += @kv_pairs;
    }
    for ( my $i = 0; $i < @kv_pairs; $i += 2 ) {
        my ( $key, $value ) = @kv_pairs[ $i, $i + 1 ];
        if ( $self->exists($key) ) {
            $self->$_croak("Cannot unshift an existing key ($key)");
        }
        $self->{index_of}{$key} = $i;
    }
    unshift @{ $self->{array_for} }, @kv_pairs;
}

sub push {
    my ( $self, @kv_pairs ) = @_;
    $self->$_validate_kv_pairs( { pairs => \@kv_pairs } );
    my @array = $self->get_array;
    for ( my $i = 0; $i < @kv_pairs; $i += 2 ) {
        my ( $key, $value ) = @kv_pairs[ $i, $i + 1 ];
        if ( $self->exists($key) ) {
            $self->$_croak("Cannot push an existing key ($key)");
        }
        $self->{index_of}{$key} = @array + $i;
    }
    CORE::push @{ $self->{array_for} }, @kv_pairs;
}

sub pop {
    my $self = shift;
    return unless $self;
    my ( $key, $value ) = splice @{ $self->{array_for} }, -2;
    delete $self->{index_of}{$key};
    return wantarray ? ( $key, $value ) : [ $key, $value ];
}

sub shift {
    my $self = CORE::shift;
    return unless $self;
    foreach my $curr_key ( CORE::keys %{ $self->{index_of} } ) {
        $self->{index_of}{$curr_key} -= 2;
    }
    my ( $key, $value ) = splice @{ $self->{array_for} }, 0, 2;
    delete $self->{index_of}{$key};
    return wantarray ? ( $key, $value ) : [ $key, $value ];
}

sub hcount {
    my $self  = CORE::shift;
    my $count = $self->acount;
    return $count / 2;
}

sub acount {
    my $self  = CORE::shift;
    my @array = $self->get_array;
    return scalar @array;
}

sub hindex {
    my $self  = CORE::shift;
    my $index = $self->aindex(CORE::shift);
    return defined $index ? $index / 2 : ();
}

sub aindex {
    my $self = CORE::shift;
    my $key  = $self->$_actual_key(CORE::shift);
    return unless $self->exists($key);
    return $self->$_index($key);
}

sub keys {
    my $self  = CORE::shift;
    my @array = $self->get_array;
    my @keys;
    for ( my $i = 0; $i < @array; $i += 2 ) {
        CORE::push @keys, $array[$i];
    }
    return wantarray ? @keys : \@keys;
}

sub values {
    my $self  = CORE::shift;
    my @array = $self->get_array;
    my @values;
    for ( my $i = 1; $i < @array; $i += 2 ) {
        CORE::push @values, $array[$i];
    }
    return wantarray ? @values : \@values;
}

sub first {
    my $self  = CORE::shift;
    my $index = $self->{current_index_for};
    return defined $index && 2 == $index;
}

sub last {
    my $self  = CORE::shift;
    my $index = $self->{current_index_for};
    return defined $index && $self->acount == $index;
}

sub each {
    my $self = CORE::shift;

    my $each = sub {
        my $index = $self->{current_index_for} || 0;
        my @array = $self->get_array;
        if ( $index >= @array ) {
            $self->reset_each;
            return;
        }
        my ( $key, $value ) = @array[ $index, $index + 1 ];
        no warnings 'uninitialized';
        $self->{current_index_for} += 2;
        return ( $key, $value );
    };

    if (wantarray) {
        return $each->();
    }
    else {
        require Array::AsHash::Iterator;
        return Array::AsHash::Iterator->new(
            {   parent   => $self,
                iterator => $each,
            }
        );
    }
}
{
    no warnings 'once';
    *kv = \&each;
}

sub reset_each { CORE::shift->{current_index_for} = undef }

sub insert_before {
    my $self  = CORE::shift;
    my $key   = CORE::shift;
    my $index = $self->$_index($key);
    $self->$_insert( $key, 'before', $index, @_ );
}

sub insert_after {
    my $self  = CORE::shift;
    my $key   = CORE::shift;
    my $index = $self->$_index($key) + 2;
    $self->$_insert( $key, 'after', $index, @_ );
}

sub key_at {
    my $self = CORE::shift;
    my @keys;
    foreach my $index ( my @copy = @_ ) {    # prevent aliasing
        $index *= 2;
        CORE::push @keys => $self->{array_for}[$index];
    }
    return wantarray ? @keys
      : 1 == @_      ? $keys[0]
      : \@keys;
}

sub value_at {
    my $self = CORE::shift;
    my @values;
    foreach my $index ( my @copy = @_ ) {    # prevent aliasing
        $index = $index * 2 + 1;
        CORE::push @values => $self->{array_for}[$index];
    }
    return wantarray ? @values
      : 1 == @_      ? $values[0]
      : \@values;
}

sub delete {
    my $self     = CORE::shift;
    my $num_args = @_;
    my $key      = $self->$_actual_key(CORE::shift);
    my @value;

    if ( $self->exists($key) ) {
        my $index = $self->$_index($key);
        delete $self->{index_of}{$key};
        my ( undef, $value ) = splice @{ $self->{array_for} }, $index, 2;
        CORE::push @value, $value;
        foreach my $curr_key ( CORE::keys %{ $self->{index_of} } ) {
            if ( $self->{index_of}{$curr_key} >= $index ) {
                $self->{index_of}{$curr_key} -= 2;
            }
        }
    }
    elsif ( $self->{is_strict} ) {
        $self->$_croak("Cannot delete non-existent key ($key)");
    }
    if (@_) {
        CORE::push @value, $self->delete(@_);
    }
    return wantarray  ? @value
      : $num_args > 1 ? \@value
      : $value[0];
}

sub clear {
    my $self = CORE::shift;
    for my $spec (qw<index_of current_index_for curr_key_of>) {
        $self->{$spec} = undef;
    }
    @{ $self->{array_for} } = ();
    return $self;
}

sub exists {
    my ( $self, $key ) = @_;
    $key = $self->$_actual_key($key);
    return unless defined $key;

    return exists $self->{index_of}{$key};
}

sub rename {
    my ( $self, @pairs ) = @_;
    $self->$_validate_kv_pairs( { pairs => \@pairs } );

    foreach ( my $i = 0; $i < @pairs; $i += 2 ) {
        my ( $old, $new ) = @pairs[ $i, $i + 1 ];
        unless ( $self->exists($old) ) {
            $self->$_croak("Cannot rename non-existent key ($old)");
        }
        unless ( defined $new ) {
            $self->$_croak("Cannot rename ($old) to an undefined value");
        }
        if ( $self->exists($new) ) {
            $self->$_croak(
                "Cannot rename ($old) to an key which already exists ($new)"
            );
        }
        my $index = delete $self->{index_of}{$old};
        $self->{index_of}{$new} = $index;
        $self->{array_for}[$index] = $new;
    }
    return $self;
}

sub get_pairs {
    my ( $self, @keys ) = @_;

    my @pairs;
    foreach my $key (@keys) {
        if ( $self->exists($key) ) {
            CORE::push @pairs, $key, $self->get($key);
        }
        elsif ( $self->{is_strict} ) {
            $self->$_croak("Cannot get pair for non-existent key ($key)");
        }
    }
    return wantarray ? @pairs : \@pairs;
}

sub default {
    my ( $self, @pairs ) = @_;
    $self->$_validate_kv_pairs( { pairs => \@pairs } );

    for ( my $i = 0; $i < @pairs; $i += 2 ) {
        my ( $k, $v ) = @pairs[ $i, $i + 1 ];
        next if $self->exists($k);
        $self->put( $k, $v );
    }
    return $self;
}

sub add {
    my ( $self, @pairs ) = @_;
    $self->$_validate_kv_pairs( { pairs => \@pairs } );

    for ( my $i = 0; $i < @pairs; $i += 2 ) {
        my ( $key, $value ) = @pairs[ $i, $i + 1 ];
        $key = $self->$_actual_key($key);
        if ( $self->exists($key) ) {
            $self->$_croak("Cannot add existing key ($key)");
        }
        my $index = $self->$_index($key);
        $self->{index_of}{$key}          = $index;
        $self->{array_for}[$index]       = $key;
        $self->{array_for}[ $index + 1 ] = $value;
    }
    return $self;
}

sub put {
    my ( $self, @pairs ) = @_;
    $self->$_validate_kv_pairs( { pairs => \@pairs } );

    for ( my $i = 0; $i < @pairs; $i += 2 ) {
        my ( $key, $value ) = @pairs[ $i, $i + 1 ];
        $key = $self->$_actual_key($key);
        if ( !$self->exists($key) && $self->{is_strict} ) {
            $self->$_croak("Cannot put a non-existent key ($key)");
        }
        my $index = $self->$_index($key);
        $self->{index_of}{$key}          = $index;
        $self->{array_for}[$index]       = $key;
        $self->{array_for}[ $index + 1 ] = $value;
    }
    return $self;
}

sub get_array {
    my $self = CORE::shift;
    return wantarray
      ? @{ $self->{array_for} }
      : $self->{array_for};
}

1;
__END__

=head1 NAME

Array::AsHash - Treat arrays as a hashes, even if you need references for keys.

=head1 VERSION

Version 0.32

=head1 SYNOPSIS

    use Array::AsHash;

    my $array = Array::AsHash->new({
        array => \@array,
        clone => 1, # optional
    });
   
    while (my ($key, $value) = $array->each) {
        # sorted
        ...
    }

    my $value = $array->get($key);
    $array->put($key, $value);
    
    if ( $array->exists($key) ) {
        ...
    }

    $array->delete($key);

=head1 DESCRIPTION

Sometimes we have an array that we need to treat as a hash.  We need the data
ordered, but we don't use an ordered hash because it's already an array.  Or
it's just quick 'n easy to run over array elements two at a time.  This module
allows you to use the array as a hash but also mostly still use it as an array,
too.

Because we directly use the reference you pass to the constructor, you may wish
to copy your data if you do not want it altered (the data are not altered
except through the publicly available methods of this class).  

=head1 EXPORT

None.

=head1 CONSTRUCTOR

=head2 new

 my $array = Array::AsHash->new;
 # or
 my $array = Array::AsHash->new( { array => \@array } );

Returns a new C<Array::AsHash> object.  If an array is passed to C<new>, it
must contain an even number of elements.  This array will be treated as a set
of key/value pairs:

 my @array = qw/foo bar one 1/;
 my $array = Array::AsHash->new({array => \@array});
 print $array->get('foo'); # prints 'bar'

Note that the array is stored internally and changes to the C<Array::AsHash>
object will change the array that was passed to the constructor as an argument.
If you do not wish this behavior, clone the array beforehand or ask the
constructor to clone it for you.

 my $array = Array::AsHash->new(
    {
        array  => \@array,
        clone  => 1,
    }
 );

Internally, we use the L<Clone> module to clone the array.  This will not
always work if you are attempting to clone objects (inside-out objects are
particularly difficult to clone).  If you encounter this, you will need to
clone the array yourself.  Most of the time, however, it should work.

Of course, you can simply create an empty object and it will still work.

 my $array = Array::AsHash->new;
 $array->put('foo', 'bar');

You may also specify C<strict> mode in the constructor.

 my @array = qw/foo bar one 1/;
 my $array = Array::AsHash->new(
    {
        array  => \@array,
        strict => 1,
    }
 );
 print $array->get('foo'); # prints 'bar'
 print $array->get('oen'); # croaks

If you specify "strict" mode, the following methods will croak if they
attempt to access a non-existent key:

=over 4

=item * get

=item * put

=item * get_pairs

=item * delete

=back

In strict mode, instead of C<put>, you will want to use the C<add> method to
add new keys to the array.

=head1 HASH-LIKE METHODS

The following methods allow one to treat an L<Array::AsHash> object
more-or-less like a hash.

=head2 keys

  my @keys = $array->keys;

Returns the "keys" of the array.  Returns an array reference in scalar context.

=head2 values

  my @values = $array->values;

Returns the "values" of the array.  Returns an array reference in scalar context.

=head2 delete

 my @values = $array->delete(@keys);

Deletes the given C<@keys> from the array.  Returns the values of the deleted keys.
In scalar context, returns an array reference of the keys.

As a "common-case" optimization, if only one key is requested for deletion,
deletion in scalar context will result in the one value (if any) being
returned instead of an array reference.

 my $deleted = $array->delete($key); # returns the value for $key
 my $deleted = $array->delete($key1, $key2); # returns an array reference

Non-existing keys will be silently ignored unless you are in "strict" mode in which case
non-existent keys are fatal.

=head2 clear

  $array->clear;

Clears all of the values from the array.

=head2 each

 while ( my ($key, $value) = $array->each ) {
    # iterate over array like a hash
 }

Lazily returns keys and values, in order, until no more are left.  Every time
each() is called, will automatically increment to the next key value pair.  If
no more key/value pairs are left, will reset itself to the first key/value
pair.

If called in scalar context, returns an L<Array::AsHash::Iterator> which
behaves the same way (except that the iterator will not return another iterator
if called in scalar context).

 my $each = $array->each;
 while ( my ($key, $value) = $each->next ) {
    # iterate over array like a hash
 }

See the L<Array::AsHash::Iterator> object for available methods.

As with a regular hash, if you do not iterate over all of the data, the internal
pointer will be pointing at the I<next> key/value pair to be returned.  If you need
to restart from the beginning, call the C<reset_each> method.

=head2 kv

 while ( my ($key, $value) = $array->kv ) {
    # iterate over array like a hash
 }

C<kv> is a synonym for C<each>.

=head2 first

 if ($array->first) { ... }

Returns true if we are iterating over the array with C<each()> and we are on the
first iteration.

=head2 last

 if ($array->last) { ... }

Returns true if we are iterating over the array with C<each()> and we are on the
last iteration.

=head2 reset_each

 $array->reset_each;

Resets the C<each> iterator to point to the beginning of the array.

=head2 exists

 if ($array->exists($thing)) { ... }

Returns true if the given C<$thing> exists in the array as a I<key>.

=head2 get

 my $value = $array->get($key);

Returns the value associated with a given key, if any.  If a single key is
passed and the key does not exist, returns an empty list.  This means that
the following can work correctly:

 if (my @value = $array->get('no_such_key')) { ... }

If passed more than one key, returns a list of values associated with those
keys with C<undef> used for any key whose value does not exist.  That means
the following will probably not work as expected:

 if (my @value = $array->get('no_such_key1', 'no_such_key2') { ... }

If using a strict hash, C<get> will croak if it encounters a non-existent key.

=head2 put

 $array->put($key, $value);

Sets the value for a given C<$key>.  If the key does not already exist, this
pushes two elements onto the end of the array.

Also accepts an even-sized list of key/value pairs:

 $array->put(@kv_pairs);

If using a strict hash, C<put> will croak if it encounters a non-existent key.
You will have to use the C<add> method to add new keys.

=head2 add

 $array->add($key, $value);

C<add> behaves exactly like C<put> except it can only be used for adding keys.
Any attempt to C<add> an existing key will croak regardless of whether you are
in strict mode or not.

=head2 get_pairs

 my $array = Array::AsHash->new({array => [qw/foo bar one 1 two 2/]});
 my @pairs = $array->get_pairs(qw/foo two/); # @pairs = (foo => 'bar', two => 2);
 my $pairs = $array->get_pairs(qw/xxx two/); # $pairs = [ two => 2 ];

C<get_pairs> returns an even-size list of key/value pairs.  It silently discards
non-existent keys.  In scalar context it returns an array reference.

This method is useful for reordering an array.

 my $array  = Array::AsHash->new({array => [qw/foo bar two 2 one 1/]});
 my @pairs  = $array->get_pairs(sort $array->keys);
 my $sorted = Array::AsHash->new({array => \@pairs});

If using a strict hash, C<get_pairs> will croak if it encounters a non-existent
key.

=head2 default

 $array->default(@kv_pairs);

Given an even-sized list of key/value pairs, each key which does not already exist
in the array will be set to the corresponding value.  Keys which already exist will
be silently ignored, even in strict mode.

=head2 rename

 $array->rename($old_key, $new_key);
 $array->rename(@list_of_old_and_new_keys);

Rename C<$old_key> to C<$new_key>.  Will croak if C<$old_key> does not exist,
C<$new_key> already exists or C<$new_key> is undefined.

Can take an even-sized list of old and new keys.

=head2 hcount

 my $pair_count = $array->hcount;

Returns the number of key/value pairs in the array.

=head2 hindex

 my $index = $array->hindex('foo');

Returns the I<hash index> of a given key, if the keys exists.  The hash index
is the array index divided by 2.  In other words, it's the index of the
key/value pair.

=head1 ARRAY-LIKE METHODS

The following methods allow one to treat a L<Array::AsHash> object more-or-less
like an array.

=head2 shift

 my ($key, $value) = $array->shift;

Removes the first key/value pair, if any, from the array and returns it.
Returns an array reference in scalar context.

=head2 pop

 my ($key, $value) = $array->pop;

Removes the last key/value pair, if any, from the array and returns it.
Returns an array reference in scalar context.

=head2 unshift

 $array->unshift(@kv_pairs);

Takes an even-sized list of key/value pairs and attempts to unshift them
onto the front of the array.  Will croak if any of the keys already exists.

=head2 push

 $array->push(@kv_pairs);

Takes an even-sized list of key/value pairs and attempts to push them
onto the end of the array.  Will croak if any of the keys already exists.

=head2 insert_before

 $array->insert_before($key, @kv_pairs);

Similar to splice(), this method takes a given C<$key> and attempts to insert
an even-sized list of key/value pairs I<before> the given key.  Will croak if
C<$key> does not exist or if C<@kv_pairs> is not an even-sized list.

 $array->insert_before($key, this => 'that', one => 1);

=head2 insert_after

 $array->insert_after($key, @kv_pairs);

This method takes a given C<$key> and attempts to insert an even-sized list of
key/value pairs I<after> the given key.  Will croak if C<$key> does not exist
or if C<@kv_pairs> is not an even-sized list.

 $array->insert_after($key, this => 'that', one => 1);

=head2 key_at

 my $key  = $array->key_at($index);
 my @keys = $array->key_at(@indices);

This method takes a given index and returns the key for that index.  If passed
a list of indices, returns all keys for those indices, just like an array
slice.  If passed a single value, always returns a scalar.  Otherwise, returns
an array ref in scalar context.

=head2 value_at

 my $value  = $array->value_at($index);
 my @values = $array->value_at(@indices);

This method takes a given index and returns the value for that index.  If
passed a list of indices, returns all values for those indices, just like an
array slice.  If passed a single value, always returns a scalar.  Otherwise,
returns an array ref in scalar context.

=head2 acount

 my $count = $array->acount;

Returns the number of elements in the array.

=head2 aindex

 my $count = $array->aindex('foo');

Returns the I<array index> of a given key, if the keys exists.

=head1 MISCELLANEOUS METHODS

=head2 strict

 if ($array->strict) {
    ...
 }
 $array->strict(0); # turn off strict mode

Getter/setter for validating strict mode.  If no arguments are passed,
returns a boolean value indicating whether or not strict mode has been
enabled for this array.

If an argument is passed, sets strict mode for the array to the boolean
value of the argument.

=head2 get_array

 my @array = $array->get_array;

Returns the array in the object.  Returns an array reference in scalar context.
Note that altering the returned array can affect the internal state of the
L<Array::AsHash> object and will probably break it.  You should usually only
get the underlying array as the last action before disposing of the object.
Otherwise, attempt to clone the array with the C<clone> method and use I<that>
array.

 my @array = $array->clone->get_array;

=head2 clone

 my $array2 = $array->clone;

Attempts to clone (deep copy) and return a new object.  This may fail if the 
array contains objects which L<Clone> cannot handle.

=head1 OVERLOADING

The boolean value of the object has been overloaded.  An empty array
object will report false in boolean context:

 my $array = Array::AsHash->new;
 if ($array) {
   # never gets here
 }

The string value of the object has been overloaded to ease debugging.  When
printing the reference, the output will be in the following format:

 key1
         value1
 key2
         value2
 key3
         value3

This is a bit unusual but since this object is neither an array nor a hash, a
somewhat unusual format has been chosen.

=head1 CAVEATS

Internally we keep the array an array.  This does mean that things might get a
bit slow if you have a large array, but it also means that you can use
references (including objects) as "keys".  For the general case of fetching and
storing items you'll find the operations are C<O(1)>.  Behaviors which can
affect the entire array are often C<O(N)>.

We achieve C<O(1)> speed for most operations by internally keeping a hash of
key indices.  This means that for common use, it's pretty fast.  If you're
writing to the array a lot, it could be a bit slower for large arrays.  You've
been warned.

=head1 WHY NOT A TIED HASH?

You may very well find that a tied hash fits your purposes better and there's
certainly nothing wrong with them.  Personally, I do not use tied variables
unless absolutely necessary because ties are frequently buggy, they tend to be
slow and they take a perfectly ordinary variable and make it hard to maintain.
Return a tied variable and some poor maintenance programmer is just going to
see a hash and they'll get awfully confused when their code isn't doing quite
what they expect.

Of course, this module provides a richer interface than a tied hash would, but
that's just another benefit of using a proper class instead of a tie.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-array-ashash@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-AsHash>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Clone>, L<Tie::IxHash>.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
