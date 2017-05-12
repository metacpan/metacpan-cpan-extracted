package Array::Each;
$VERSION = 0.03;
use strict;
use warnings;

=head1 NAME

Array::Each - iterate over one or more arrays, returning one or more
elements from each array followed by the array index.

=head1 VERSION

This document refers to version 0.03 of Array::Each,
released March 26, 2004.

=head1 SYNOPSIS

 use Array::Each;

 # one array
 my @x = qw( a b c d e );

 my $one = Array::Each->new( \@x );
 while( my( $x, $i ) = $one->each() ) {
     printf "%3d: %s\n", $i, $x;
 }

 # multiple arrays
 my @y = ( 1,2,3,4,5 );

 my $set = Array::Each->new( \@x, \@y );
 while( my( $x, $y, $i ) = $set->each() ) {
     printf "%3d: %s %s\n", $i, $x, $y;
 }

 # groups of elements (note set=> parm syntax)
 my @z = ( a=>1, b=>2, c=>3, d=>4, e=>5 );

 my $hash_like = Array::Each->new( set=>[\@z], group=>2 );
 while( my( $key, $val ) = $hash_like->each() ) {
     printf "%s => %s\n", $key, $val;
 }

=cut

### more POD follows the __END__

use Carp;

# object attributes subscript mappings
use constant EACH     => 0; # sub ref to object's each()
use constant SET      => 1; # ref to array of array_refs
use constant ITERATOR => 2; # integer, used as array index
use constant REWIND   => 3; # integer, used as array index
use constant BOUND    => 4; # boolean, default is true
use constant UNDEF    => 5; # scalar value for non-existing elements
use constant STOP     => 6; # integer, will compare to iterator
use constant GROUP    => 7; # integer, number of elements per group
use constant COUNT    => 8; # integer, returned instead of iterator
use constant USER     => 9; # reserved for child classes(?)

# references => names mapping
my %_each_subs = (
    \&each_default  => '&Array::Each::each_default',
    \&each_unbound  => '&Array::Each::each_unbound',
    \&each_group    => '&Array::Each::each_group',
    \&each_complete => '&Array::Each::each_complete',
    );

# mappings of named arguments
my %_index_for;
@_index_for{ qw( _each set iterator rewind bound undef stop group count user ) } =
    ( EACH, SET, ITERATOR, REWIND, BOUND, UNDEF, STOP, GROUP, COUNT, USER );

my @_default;  # see also _set_each() for expectations about defaults
@_default[ EACH, SET, ITERATOR, REWIND, BOUND, UNDEF, STOP, GROUP, COUNT, USER ] =
    ( undef, [[]], 0, 0, 1, undef, undef, undef, undef, undef );

# attribute validations
my @_validate;
@_validate[ EACH, SET, ITERATOR, REWIND, BOUND, UNDEF, STOP, GROUP, COUNT, USER ] = (
    sub{ !defined $_[0] or exists $_each_subs{$_[0]} or
        croak "Invalid _each: '$_[0]'" },
    sub{ UNIVERSAL::isa( $_[0], 'ARRAY' ) and
        UNIVERSAL::isa( $_[0]->[0], 'ARRAY' ) or
        croak "Invalid set: '$_[0]'" },
    sub{ $_[0] =~ /^\d+$/ or
        croak "Invalid iterator: '$_[0]'" },
    sub{ $_[0] =~ /^\d+$/ or
        croak "Invalid rewind: '$_[0]'" },
    sub{ $_[0] =~ /[01]/ or
        croak "Invalid bound: '$_[0]'" },
    sub{ # Undef value can be anything
        },
    sub{ !defined $_[0] or $_[0] =~ /^\d+$/ or
        croak "Invalid stop: '$_[0]'" },
    sub{ !defined $_[0] or ($_[0] =~ /^\d+$/ and $_[0] > 0) or
        croak "Invalid group: '$_[0]'" },
    sub{ !defined $_[0] or $_[0] =~ /^\d+$/ or
        croak "Invalid count: '$_[0]'" },
    sub {}, # To be defined by child classes
    );

# constructor methods: new(), copy()
# Note, the code for new() is taken not quite in whole
# cloth from section 4.2 of "Object Oriented Perl"[1].
sub new {
    my $caller = shift;
    my $caller_is_obj = ref $caller;
    my $class = $caller_is_obj || $caller;
    my %arg;

    ### if only array refs are passed to new() ...
    if( ref $_[0] ) { $arg{ 'set' } = [@_] }
    else            { %arg = @_ }

    my $self = bless [], $class;
    foreach my $member ( keys %_index_for ) {
        my $index = $_index_for{ $member };
        if ( exists $arg{ $member } ) {
            $self->[ $index ] = $arg{ $member } }
        elsif ($caller_is_obj) {
            $self->[ $index ] = $caller->[ $index ] }
        else {
            $self->[ $index ] = $_default[ $index ] }
        $_validate[ $index ]->( $self->[ $index ] );
    }
    $self->_set_each() unless defined $self->[EACH];
    $self;
}

### do not rely on copy() being an alias of new(), see POD
*copy = \&new;

# accessor methods
sub _get_each_name { $_each_subs{$_[0]->[EACH]}; }
sub _get_each_ref  { $_[0]->[EACH]     }
sub get_set        { @{$_[0]->[SET]}   }
sub get_iterator   { $_[0]->[ITERATOR] }
sub get_rewind     { $_[0]->[REWIND]   }
sub get_bound      { $_[0]->[BOUND]    }
sub get_undef      { $_[0]->[UNDEF]    }
sub get_stop       { $_[0]->[STOP]     }
sub get_group      { $_[0]->[GROUP]    }
sub get_count      { $_[0]->[COUNT]    }
sub get_user       { $_[0]->[USER]     }

sub _set_each {
    my $self = shift;
    if( defined $_[0] ) {
        $self->[EACH] = $_[0];
        $_validate[EACH]->( $self->[EACH] );
        return $self->[EACH];
    }

    # are these set to defaults?
    my $r = ( $self->[REWIND] == $_default[REWIND] );
    my $b = ( $self->[BOUND]  == $_default[BOUND]  );
    my $s = ( !defined $self->[STOP]  );  # default is undef
    my $g = ( !defined $self->[GROUP] );  # default is undef
    my $c = ( !defined $self->[COUNT] );  # default is undef
    CASE: {
        # all are defaults
        ($r && $b && $s && $g && $c) and
            $self->[EACH] = \&each_default, last CASE;
        # all except bound
        ($r && $s && $g && $c) and
            $self->[EACH] = \&each_unbound, last CASE;
        # all except group
        ($r && $b && $s && $c) and
            $self->[EACH] = \&each_group, last CASE;
        # else
        $self->[EACH] = \&each_complete;
    }
    $self->[EACH];
}

sub set_set {
    my $self = shift;
    $self->[SET] = [@_];
    $_validate[SET]->( $self->[SET] );
    @{$self->[SET]};
}
sub set_iterator {
    my $self = shift;
    $self->[ITERATOR] = $_[0];
    $_validate[ITERATOR]->( $self->[ITERATOR] );
    $self->[ITERATOR];
}
sub set_rewind {
    my $self = shift;
    $self->[REWIND] = $_[0];
    $_validate[REWIND]->( $self->[REWIND] );
    $self->_set_each;
    $self->[REWIND];
}
sub set_bound {
    my $self = shift;
    $self->[BOUND] = $_[0];
    $_validate[BOUND]->( $self->[BOUND] );
    $self->_set_each;
    $self->[BOUND];
}
sub set_undef {
    my $self = shift;
    $self->[UNDEF] = $_[0];
    $_validate[UNDEF]->( $self->[UNDEF] );
    $self->[UNDEF];
}
sub set_stop {
    my $self = shift;
    $self->[STOP] = $_[0];
    $_validate[STOP]->( $self->[STOP] );
    $self->_set_each;
    $self->[STOP];
}
sub set_group {
    my $self = shift;
    $self->[GROUP] = $_[0];
    $_validate[GROUP]->( $self->[GROUP] );
    $self->_set_each;
    $self->[GROUP];
}
sub set_count {
    my $self = shift;
    $self->[COUNT] = $_[0];
    $_validate[COUNT]->( $self->[COUNT] );
    $self->_set_each;
    $self->[COUNT];
}

# note: no set_user() defined in this class

# utility methods
sub rewind {
    my $self = shift;
    $self->set_iterator(
        defined $_[0] ? $_[0] : $self->[REWIND] );
}
sub incr_iterator {
    my $self = shift;
    return $self->[ITERATOR]++ unless $self->[GROUP];
    my $i = $self->[ITERATOR];
    $self->[ITERATOR] += $self->[GROUP];
    $i;
}

# each methods
sub each { &{$_[0]->[EACH]} }  # call this object's each()

sub each_default {  # enough attributes are default
    my $self  = shift;
    my $i = $self->[ITERATOR]++;          # inlined incr_iterator
    $self->[ITERATOR] = $self->[REWIND],  # inlined rewind
        return if grep {$i >= @$_} @{$self->[SET]};
    ( (map $_->[$i], @{$self->[SET]}), $i );
}

sub each_unbound {  # bound not true
    my $self  = shift;
    my $i = $self->[ITERATOR]++;          # inlined incr_iterator
    $self->[ITERATOR] = $self->[REWIND],  # inlined rewind
        return unless grep {$i < @$_} @{$self->[SET]};
    ( (map {$i<@$_ ? $_->[$i] : $self->[UNDEF]} @{$self->[SET]}), $i );
}

sub each_group {  # group is defined
    my $self  = shift;
    my $group = $self->[GROUP];
    my $i = $self->[ITERATOR];            # inlined
    $self->[ITERATOR] += $group;          #     incr_iterator
    $self->[ITERATOR] = $self->[REWIND],  # inlined rewind
        return if grep {$i >= @$_} @{$self->[SET]};
    my @ret;
    foreach my $aref ( @{$self->[SET]} ) {
        push @ret,
            map {$_<@$aref ? $aref->[$_] : $self->[UNDEF]}
            ($i..$i+$group-1) }
    ( @ret, $i );
}

sub each_complete {  # enough attributes aren't default
    my $self  = shift;
    my $i     = $self->incr_iterator();  # increment for next time, use current
    my $set   = $self->[SET];
    my $stop  = $self->[STOP];
    my $undef = $self->[UNDEF];
    my $group = $self->[GROUP];
    my $c;

    # if bound to the shortest array, stop there (or at stop) ...
    if( $self->[BOUND] ) {
        if( defined $stop ) {
            $self->rewind(), return if $i > $stop || grep {$i >= @$_} @$set }
        else {
            $self->rewind(), return if grep {$i >= @$_} @$set }
        $c = defined $self->[COUNT] ? $self->[COUNT]++ : $i;
        return ( (map $_->[$i], @$set), $c ) unless defined $group;
    }

    # else not bound to the shortest array, so (maybe) go farther ...
    else {
        if( defined $stop ) {  # may go past longest array, too
            $self->rewind(), return if $i > $stop }
        else {
            $self->rewind(), return unless grep {$i < @$_} @$set }
        $c = defined $self->[COUNT] ? $self->[COUNT]++ : $i;
        return ( (map {$i<@$_ ? $_->[$i] : $undef} @$set), $c )
            unless defined $group;
    }

    # or return groups of elements, i.e., $group is defined
    my @ret;
    foreach my $aref ( @$set ) {
        push @ret, map {$_<@$aref ? $aref->[$_] : $undef} ($i..$i+$group-1) }
    ( @ret, $c );
}

1;  # true

__END__

=head1 DESCRIPTION

=head2 Overview

Array::Each provides the each() method to iterate over one or more
arrays, returning one or more elements from each, followed by the
array index.

Array::Each has an object oriented interface, so it does not export
any subroutines (or variables) into your program's namespace.

Use the new() method to create an object that will hold the
iterator and other attributes for each set of arrays to iterate over,
e.g.,

 my $set = Array::Each->new( \@x, \@y );

Use the each() method to iterate over the values in the array or
arrays.  This is typically done in a while() loop, as with perl's
builtin each() function for hashes.

 while( my( $x, $y, $i ) = $set->each() ) {
     printf "%3d: %s %s\n", $i, $x, $y;
 }

Like perl's, Array::Each's each() returns an empty list (in list
context) when the end of the set of arrays is reached.  At that point,
the iterator is automatically rewound to the beginning, so you can
iterate over the same set of arrays again.


=head2 Initialization

All attributes can be initialized via the call to the new() method.
The attributes are: C<set>, C<iterator>, C<rewind>, C<bound>,
C<undef>, C<stop>, C<group>, and C<count>.  In addition, every
attribute has accessor methods to set and get their values.  These
are explained in detail below.


=head2 Primary Methods

=over 8

=item new( ARRAYREFS )

=item new( set=>[ARRAYREFS] ...other parms... )

=item new()

Normally--assuming all the attribute defaults are what you want--simply
pass a list of array references to the new() method like this:

 my $obj = Array::Each->new( \@x, \@y );

However, if you want to initialize any of the object's other
attributes, pass the array references in an anonymous array using
the B<< set=> >> named parameter, like this:

 my $obj = Array::Each->new( set=>[\@x, \@y] );  # same as above

Then you can pass other attributes by name:

 my $obj = Array::Each->new( set=>[\@x, \@y], bound=>0, undef=>'' );

The attributes are: C<set>, C<iterator>, C<rewind>, C<bound>, C<undef>,
C<stop>, C<group>, and C<count>, and are explained in detail below.


=item copy( ARRAYREFS )

=item copy( set=>[ARRAYREFS] ...other parms... )

=item copy()

This method is similar to new() in that it constructs a new object and
allows you to set any of the attributes.  But copy() is intended to be
called with an existing Array::Each object.  The new copy will take all
of its attribute values from the existing object (in particular, the
set of arrays and current value of the iterator), unless you specify
differently, e.g.,

 my $obj2 = $obj->copy();

Thus we might generate permutations of an array like this:

 sub permute {
     my $set1 = Array::Each->new( @_ );
     my @permutations;
     while ( my @s1 = $set1->each() ) {
         my $set2 = $set1->copy();
         while ( my @s2 = $set2->each() ) {
             # -1 because each() returns array index, too
             push @permutations,
                 [ @s1[0..$#s1-1], @s2[0..$#s2-1] ];
         }
     }
     return @permutations
 }

Note: currently, the copy() method is implemented as an alias of the
new() method.  But do not rely on this always to be the case, because
future versions of Array::Each may change this implementation detail.
So the rules are:

1) use new() when you create a new object using the class name, e.g.,
C<< $obj = Array::Each->new() >>.

2) use copy() when you create a copy of an existing object using the
object reference, e.g., C<< $obj2 = $obj->copy() >>.


=item each()

The each() method for arrays is similar to the builtin perl function of
the same name for hashes.  Perl's each() will iterate over a hash,
returning a key and its value at each pass.  Array::Each's each() will
iterate over one or more arrays, each time returning one or more
values, followed by an array index, e.g.,

 while( my( $x, $y, $i ) = $obj->each() ) {
     printf "%3d: %s %s\n", $i, $x, $y;
 }

In list context, Array::Each's each() returns an empty list when
the end of the set of arrays is reached.  In scalar context, it
returns undef.  At that point, the iterator is automatically rewound
to the beginning, so you can iterate over the same set of arrays
again.

See more examples above and below, and in Array::Each::Tutorial.

Incidentally, for what it's worth, each() returns just the array
index when called in scalar context, e.g.,

 while( defined( my $i = $obj->each() ) ) {
     printf "%3d\n", $i;
 }

As the example implies, be aware that the first index returned will
likely be 0.

=back


=head2 Utility Methods

These methods are used internally and called automatically but can
be called manually as needed.

=over 8

=item rewind( INDEX )

=item rewind()

When you iterate over a set of arrays and reach the end, the iterator
for that set is automatically "rewound" to index 0 (or to the value of
the C<rewind> attribute; see details about C<rewind> below).

But you can rewind() it manually at any time, e.g.,

 $obj->rewind();

You can also rewind it to a particular point by passing the array INDEX
of the I<next> desired iteration, e.g.,

 $obj->rewind( 10 );

The rewind() method returns the value passed to it, or the value
of the C<rewind> attribute if no value is passed.


=item incr_iterator()

As each() iterates over a set of arrays, it automatically increments
the iterator.  But you can increment it manually with incr_iterator(),
e.g.,

 $obj->incr_iterator();

Note: if the C<group> attribute is set, this method will increment the
iterator by that amount; see details about C<group> below.

The incr_iterator() method returns the value of the iterator I<prior>
to its being incremented.

Currently, incr_iterator() does not take any parameters.  If you
want to increment the iterator by other than the usual amount,
first get its current value and then set the new value explicitly,
e.g.,

 $obj->set_iterator( $obj->get_iterator() + $amount );


=back


=head2 Object Attributes and Accessor Methods

Since all object attributes can be set when new() is called,
ordinarily there is no need to call any of the accessor methods.
They are provided for completeness and for special cases.

=over 8

=item C<set>, set_set( ARRAYREFS ), get_set()

The C<set> attribute is the list of arrays (i.e., the "set" of
arrays) to iterate over.  These arrays must be passed to the new(),
copy(), and set_set() methods as array references.  If no other
attributes are initialized when you call new(), you can pass the
array references "directly", e.g.,

 $obj->Array::Each->new( \@x, \@y );

On the other hand, if you set other attributes when calling new(),
you must pass the array references "indirectly" in an anonymous
array using the B<< set=> >> named parameter, e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y] );  # same as above

If you want to specify the set of arrays separately from the call to
new(), you can do so by calling set_set(), e.g.,

 $obj->Array::Each->new();   # ...
 $obj->set_set( \@x, \@y );  # same as above

Note, always pass the array references "directly" to set_set(), i.e.,
don't pass them inside an anonymous array.

In list context, the set_set() method returns the list of array
references passed to it.  In scalar context, it returns the number
of references.  E.g.,

 my @array_refs = $obj->set_set( \@x, \@y );
 my $num = $obj->set_set( @array_refs );

Get the list of array references by calling get_set(), e.g.,

 my @array_refs = $obj->get_set();

(... yes, the term "set" is somewhat overloaded in this class.
Sorry about that.)


=item C<iterator>, set_iterator( INDEX ), get_iterator()

The C<iterator> value is where the I<next> iteration will begin.
By default, it is set to 0, i.e., the first array index.  To set
a different initial value, pass the B<< iterator=> >> named parameter
to the new() (or copy()) method, e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y], iterator=>10 );

This will start the iteration at array index 10 instead of 0.

(Note, this does I<not> change where rewind() will rewind to.  To
change the rewind value, set the C<rewind> attribute; see below.  Or
you can manually rewind to a particular index by calling the rewind
method with that value, e.g., C<< $obj->rewind( 10 ) >>.)

Set the iterator of an existing object with set_iterator(), e.g.,

 $obj->set_iterator( 10 );

Again, this sets where the I<next> iteration will begin.

The set_iterator() method returns the value passed to it.

Get the value of the iterator with get_iterator(), e.g.,

 my $i = $obj->get_iterator();

This is where the I<next> iteration will begin, I<not> where the last
one happened.

Any integer >= 0 is valid for C<iterator>.


=item C<rewind>, set_rewind( INDEX ), get_rewind()

The C<rewind> attribute is where rewind() will rewind to.  By
default, it is set to 0, i.e., the first array index.  To set a
different value, pass the B<< rewind=> >> named parameter to the
new() (or copy()) method, e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y], rewind=>10, iterator=>10 );

(Note: setting C<rewind> doesn't change where the I<initial> iteration
begins; for that, set the C<iterator> value as shown above.)

Set an object's rewind value with set_rewind(), e.g.,

 $obj->set_rewind( 10 );

The set_rewind() method returns the value passed to it.

Get the rewind value with get_rewind(), e.g.,

 my $rewind_val = $obj->get_rewind();

Any integer >= 0 is valid for C<rewind>.


=item C<bound>, set_bound( 0 or 1 ), get_bound()

The C<bound> attribute is a boolean flag and is 1 (true) by default.
When this attribute is true, the iteration over the set of arrays will
stop when the end of the shortest array is reached.  That is, the
iteration is "bound" by the shortest array.

Note: ordinarily this means that no "non-existing" values will be
returned by each().  However, if the C<group> attribute is set,
"non-existing" values may be returned even if C<bound> is true.
"Non-existing" values are discussed below under C<undef>.

To set C<bound> to 0 (false), pass the B<< bound=> >> named parameter
to the new() (or copy()) method, e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y], bound=>0 );

Or set the value with set_bound(), e.g.,

 $obj->set_bound( 0 );  # now we're not bound by the shortest array

The set_bound() method returns the value passed to it.

Get the value with get_bound(), e.g.,

 my $bound_val = $obj->get_bound();

The valid values for C<bound> are 1 and 0.


=item C<undef>, set_undef( SCALAR or undef ), get_undef()

The C<undef> attribute is a scalar value that will be returned by
each() when a "non-existing" array element is encountered.  By
default, this attribute's value is (perl's) undef.

"Non-existing" array elements may be encountered if C<bound> is false,
and the arrays are of different sizes.  In other words, the iteration
will continue to the end of the longest array.  When the ends of any
shorter arrays are surpassed, the value of the C<undef> attribute will
be returned for the "missing" elements.  (But the shorter arrays will
I<not> be extended.)

"Non-existing" elements may also be encountered if C<group> is set,
even if C<bound> is true.  This is because if the shortest array's
size is not a multiple of the C<group> value, the last iteration
will be "padded" using the value of the C<undef> attribute.

Note: each() will I<not> return the value of the C<undef> attribute for
I<existing> array elements that are undefined.  Instead, it will return
the (perl) undef value, as normal.

To set C<undef>, pass the B<< undef=> >> named parameter to the new()
(or copy()) method, e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y], undef=>'' );

Or set the value with set_undef(), e.g.,

 $obj->set_undef( 0 );

The set_undef() method returns the value passed to it.

Get the value with get_undef(), e.g.,

 my $undef_val = $obj->get_undef();

Any value is valid for C<undef>.


=item C<stop>, set_stop( INDEX ), get_stop()

The C<stop> attribute tells each() where to stop its iterations.  By
default, C<stop> is undefined, meaning each() will stop where it wants,
depending on C<bound>, C<group>, and the sizes of the arrays.

If C<bound> is true and C<stop> is set higher than C<$#shortest_array>,
then C<stop> will have no effect (it will never be reached).  If it is
set lower, then the iteration will stop I<after> that element has been
returned by each().

If C<bound> is false and the C<stop> value is defined, then the
iteration will stop I<after> that element has been returned,
regardless of the sizes of the arrays.  If the end of any or all
of the arrays is surpassed, each() will return the value of the
C<undef> attribute in the place of any "non-existing" element; see
C<undef> above.

To set C<stop>, pass the B<< stop=> >> named parameter to the new()
(or copy()) method, e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y], stop=>99 ); # give me 100

Or set the value with set_stop(), e.g.,

 $obj->set_stop( 49 ); # give me 50 (probably)

The set_stop() method returns the value passed to it.

Get the value with get_stop(), e.g.,

 my $stop_index = $obj->get_stop();

Any integer >= 0 is valid for C<stop>.


=item C<group>, set_group( NUM_ELEMS ), get_group()

The C<group> attribute makes each() return I<multiple> elements from
each array.  For example, if you do this ...

 my $obj = Array::Each->new( set=>[\@x, \@y],
     group=>5, stop=>99, bound=>0 );
 my @a = $obj->each;
 my $i = $obj->get_iterator;

... then C<@a> will contain 11 elements, 5 each from C<@x> and C<@y> and
the value of the iterator when each() was called, namely 0. The
value of C<$i> is 5, because when C<each> was called, the iterator
was incremented by the value of C<group>, i.e., C<0 + 5 == 5>.

By default, C<group> is undefined.  Logically this is the same as
if it were set to 1.  (But leave it undefined if 1 is what you
want.)

To set C<group>, pass the B<< group=> >> named parameter to the new()
(or copy()) method, e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y], group=>5 );

Or set the value with set_group(), e.g.,

 $obj->set_group( 5 );

The set_group() method returns the value passed to it.

Get the value with get_group(), e.g.,

 my $group_val = $obj->get_group();

Any integer > 0 is valid for C<group>.

As discussed above, if C<group> causes each() to surpass the end of any
array, the value of C<undef> will be returned for any "non-existing"
elements.

=item C<count>, set_count( BEGIN_VAL ), get_count()

The C<count> attribute makes each() return a count instead of the
array index.  When used, C<count> will be returned and incremented
by 1 every time each() returns array elements for a given Array::Each
object.  It is not automatically rewound.

By default, C<count> is undefined and each() will ignore it.

To set C<count>, pass the B<< count=> >> named parameter to the new()
(or copy()) method, e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y], count=>1 );

Or set the value with set_count(), e.g.,

 $obj->set_count( 1 );

The set_count() method returns the value passed to it.

Get the value with get_count(), e.g.,

 my $count_val = $obj->get_count();

Any integer >= 0 is valid for C<count>.

See examples of using C<count> in Array::Each::Tutorial.

=back

=head2 Semi-Private Attributes and Accessor Methods

=over 8

=item C<_each>, _set_each( CODE_REF ), _get_each_name(), _get_each_ref()

The C<_each> attribute contains a reference to the subroutine
that will run when each() is called.  Setting this attribute
is handled under the covers, so you needn't do anything.

However, for debugging or testing, you may set the C<_each> attribute
to one of:

 \&Array::Each::each_default
 \&Array::Each::each_unbound
 \&Array::Each::each_group
 \&Array::Each::each_complete

using either the B<< _each=> >> named attribute in the call to new()
or by calling _set_each(), e.g.,

 $obj->Array::Each->new( set=>[\@x, \@y],
     _each=>\&Array::Each::each_default );
 $obj->_set_each( \&Array::Each::each_complete );

The _set_each() method returns the resulting value of C<_each> (a
code reference).

Setting C<_each> this way may result in unexpected warning messages
and/or in some attributes being ignored, so don't do it except for
debugging or testing.  For example, each_default() assumes that
most of the attributes are set to their default values, even if
they're not; each_unbound() assumes C<bound> is false; etc.

Calling _set_each() without parameters will reset the C<_each>
attribute to its appropriate value and correctly honor all of the
attributes.

Get the C<_each> (code ref) value with _get_each_ref(), e.g.,

 my $each_ref = $obj->_get_each_ref();

Get the C<_each> I<stringified> value with _get_each_name(), e.g.,

 my $each_name = $obj->_get_each_name();

While changing parameters may change the value of C<_each>, do not
rely on a certain parameter combination always resulting in a
specific C<_each> subroutine.

=back

=head1 INHERITING

=over 8

=item C<user>

The C<user> attribute is reserved for use by classes that inherit
from Array::Each.  It may be used as needed without fear of colliding
with future versions of Array::Each.

=back


=head1 BUGS

Please feel free to report any bugs or suspected bugs to the author.

=head1 SEE ALSO

Array::Each::Tutorial

=head1 AUTHOR

Brad Baxter, bbaxter@cpan.org

Acknowledgments to Anno Siegel, Ben Morrow, and others on newsgroup
comp.lang.perl.misc, and to Damian Conway, author of "Object Oriented
Perl"[1].


=head1 COPYRIGHT

Copyright (c) 2003-2004, Brad Baxter, All rights reserved.  This module is
free software.  It may be used, redistributed and/or modified under the
same terms as Perl itself.

 __________

 [1] Conway, Damian, Object oriented Perl, Greenwich: Manning, 2000.
