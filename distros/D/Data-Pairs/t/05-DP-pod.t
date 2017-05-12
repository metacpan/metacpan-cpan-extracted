use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;
$Data::Dumper::Sortkeys=1;

BEGIN { use_ok('Data::Pairs') };

SYNOPSIS_simple: {
 
=head1 SYNOPSIS

 use Data::Pairs;
 
 # Simple OO style
 
 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4}] );
 
 $pairs->set( a => 0 );
 $pairs->add( b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
 my($value) = $pairs->get_values( 'c' );    # 3      (if you just want one)
 my @values = $pairs->get_values( 'b' );    # (2, 4) (one key, multiple values)
 my @keys   = $pairs->get_keys();           # (a, b, b2, c, b)
    @values = $pairs->get_values();         # (0, 2, 2.5, 3, 4)
 my @subset = $pairs->get_values(qw(c b));  # (2, 3, 4) (values are data-ordered)
 
=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "new()" );
 
 $pairs->set( a => 0 );

is( Dumper($pairs), "bless( [{'a' => 0},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "set( a => 0 )" );

 $pairs->add( b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
is( Dumper($pairs), "bless( [{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "add( b2 => 2.5, 2 )" );

 my($value) = $pairs->get_values( 'c' );    # 3      (if you just want one)

is( $value, 3, "get_values( 'c' )" );

 my @values = $pairs->get_values( 'b' );    # (2, 4) (one key, multiple values)

is( "@values", "2 4", "get_values( 'b' )" );

 my @keys   = $pairs->get_keys();           # (a, b, b2, c, b)

is( "@keys", "a b b2 c b", "get_keys()" );

    @values = $pairs->get_values();         # (0, 2, 2.5, 3, 4)

is( "@values", "0 2 2.5 3 4", "get_values()" );

 my @subset = $pairs->get_values(qw(c b));  # (2, 3, 4) (values are data-ordered)

is( "@subset", "2 3 4", "get_values(qw(c b ))" );

}

SYNOPSIS_nonoo: {
 
=pod

 # Non-OO style

 use Data::Pairs ':ALL';
 
 my $pairs = [{a=>1},{b=>2},{c=>3},{b=>4}];  # new-ish, but not blessed

 pairs_set( $pairs, a => 0 );        # (pass pairs as first parameter)
 pairs_add( $pairs, b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
 my($value) = pairs_get_values( $pairs, 'c' );      # 3      (if you just want one)
 my @values = pairs_get_values( $pairs, 'b' );      # (2, 4) (one key, multiple values)
 my @keys   = pairs_get_keys( $pairs );             # (a, b, b2, c, b)
    @values = pairs_get_values( $pairs );           # (0, 2, 2.5, 3, 4)
 my @subset = pairs_get_values( $pairs, qw(c b) );  # (2, 3, 4) (values are data-ordered)
 
 # There are more methods/options, see below.

=cut
 
 use Data::Pairs ':ALL';

 my $pairs = [{a=>1},{b=>2},{c=>3},{b=>4}];  # new-ish, but not blessed

 pairs_set( $pairs, a => 0 );        # (pass pairs as first parameter)

is( Dumper($pairs), "[{'a' => 0},{'b' => 2},{'c' => 3},{'b' => 4}]",
    "pairs_set( ... a => 0 )" );

 pairs_add( $pairs, b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
is( Dumper($pairs), "[{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3},{'b' => 4}]",
    "pairs_add( ... b2 => 2.5, 2 )" );

 my($value) = pairs_get_values( $pairs, 'c' );      # 3      (if you just want one)

is( $value, 3,
    "pairs_get_values( ... 'c' )" );

 my @values = pairs_get_values( $pairs, 'b' );      # (2, 4) (one key, multiple values)

is( "@values", "2 4",
    "pairs_get_values( ... 'b' )" );

 my @keys   = pairs_get_keys( $pairs );             # (a, b, b2, c, b)

is( "@keys", "a b b2 c b",
    "pairs_get_keys()" );

    @values = pairs_get_values( $pairs );           # (0, 2, 2.5, 3, 4)

is( "@values", "0 2 2.5 3 4",
    "pairs_get_values()" );

 my @subset = pairs_get_values( $pairs, qw(c b) );  # (2, 3, 4) (values are data-ordered)

is( "@subset", "2 3 4",
    "pairs_get_values( ... qw(c b) )" );

}


CLASS_new: {

=head2 Data::Pairs->new();

Constructs a new Data::Pairs object.

Accepts array ref containing single-key hash refs, e.g.,

 my $pairs = Data::Pairs->new( [ { a => 1 }, { b => 2 }, { c => 3 }, { b => 4 } ] );

When provided, this data will be loaded into the object.

Returns a reference to the Data::Pairs object.

=cut

 my $pairs = Data::Pairs->new( [ { a => 1 }, { b => 2 }, { c => 3 }, { b => 4 } ] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "new()" );

}

CLASS_order: {

=head2 Data::Pairs->order();

When ordering is ON, new key/value pairs will be added in the
specified order.  When ordering is OFF (the default), new pairs
will be added to the end of the mapping.

When called with no parameters, C<order()> returns the current code
reference (if ordering is ON) or a false value (if ordering is OFF);
it does not change the ordering.

 Data::Pairs->order();         # leaves ordering as is

When called with the null string, C<''>, ordering is turned OFF.

 Data::Pairs->order( '' );     # turn ordering OFF (the default)

Otherwise, accepts the predefined orderings: 'na', 'nd', 'sa', 'sd',
'sna', and 'snd', or a custom code reference, e.g.

 Data::Pairs->order( 'na' );   # numeric ascending
 Data::Pairs->order( 'nd' );   # numeric ascending
 Data::Pairs->order( 'sa' );   # string  ascending
 Data::Pairs->order( 'sd' );   # string  descending
 Data::Pairs->order( 'sna' );  # string/numeric ascending
 Data::Pairs->order( 'snd' );  # string/numeric descending
 Data::Pairs->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # code

The predefined orderings, 'na' and 'nd', compare keys as numbers.
The orderings, 'sa' and 'sd', compare keys as strings.  The
orderings, 'sna' and 'snd', compare keys as numbers when they are
both numbers, as strings otherwise.

When defining a custom ordering, the convention is to use the
operators C<< < >> or C<lt> between (functions of) C<$_[0]> and
C<$_[1]> for ascending and between C<$_[1]> and C<$_[0]> for
descending.

Returns the code reference if ordering is ON, a false value if OFF.

Note, when object-level ordering is implemented, it is expected that
the class-level option will still be available.  In that case, any
new objects will inherite the class-level ordering unless overridden
at the object level.

=cut

 Data::Pairs->order();         # leaves ordering as is

is( Data::Pairs->order(), undef, "order()" );

 Data::Pairs->order( '' );     # turn ordering OFF (the default)

is( Data::Pairs->order(), '', "order( '' )" );

 Data::Pairs->order( 'na' );   # numeric ascending

is( ref(Data::Pairs->order()), 'CODE', "order( 'na' )" );

 Data::Pairs->order( 'nd' );   # numeric ascending

is( ref(Data::Pairs->order()), 'CODE', "order( 'nd' )" );

 Data::Pairs->order( 'sa' );   # string  ascending

is( ref(Data::Pairs->order()), 'CODE', "order( 'sa' )" );

 Data::Pairs->order( 'sd' );   # string  descending

is( ref(Data::Pairs->order()), 'CODE', "order( 'sd' )" );

 Data::Pairs->order( 'sna' );  # string/numeric ascending

is( ref(Data::Pairs->order()), 'CODE', "order( 'sna' )" );

 Data::Pairs->order( 'snd' );  # string/numeric descending

is( ref(Data::Pairs->order()), 'CODE', "order( 'snd' )" );

 Data::Pairs->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # code

is( ref(Data::Pairs->order()), 'CODE', "custom order()" );

}

OBJECT_set: {

=head2 $pairs->set( $key => $value[, $pos] );

Sets the value if C<$key> exists; adds a new key/value pair if not.

Accepts C<$key>, C<$value>, and optionally, C<$pos>.

If C<$pos> is given, and there is a key/value pair at that position,
it will be set to C<$key> and C<$value>, I<even if the key is
different>.  For example:

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2}] );
 $pairs->set( c => 3, 0 );  # pairs is now [{c=>3},{b=>2}]

(As implied by the example, positions start at 0.)

If C<$pos> is given, and there isn't a pair there, a new pair is
added there (perhaps overriding a defined ordering).

If C<$pos> is not given, the key will be located and if found,
the value set. If the key is not found, a new pair is added to the
end or merged according to the defined C<order()>.

Returns C<$value> (as a nod toward $hash{$key}=$value, which
"returns" $value).

=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2}], 'Data::Pairs' )",
    "new()" );

 $pairs->set( c => 3, 0 );  # pairs is now [{c=>3},{b=>2}]

is( Dumper($pairs), "bless( [{'c' => 3},{'b' => 2}], 'Data::Pairs' )",
    "set()" );

}

OBJECT_get_values: {

=head2 $pairs->get_values( [$key[, @keys]] );

Get a value or values.

Regardless of parameters, if the object is empty, undef is returned in
scalar context, an empty list in list context.

If no paramaters, gets all the values.  In scalar context, gives
number of values in the object.

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}] );
 my @values  = $pairs->get_values();  # (1, 2, 3, 4, 5)
 my $howmany = $pairs->get_values();  # 5

If keys given, their values are returned in the order found
in the object, not the order of the given keys.

In scalar context, gives the number of values found, e.g.,

 @values  = $pairs->get_values( 'c', 'b' );  # (2, 3, 4, 5)
 $howmany = $pairs->get_values( 'c', 'b' );  # 4

Note, unlike C<Data::Omap::get_values()>, because an object may have
duplicate keys, this method behaves the same if given one key or
many, e.g.,

 @values  = $pairs->get_values( 'b' );  # (2, 4, 5)
 $howmany = $pairs->get_values( 'b' );  # 3

Therefore, always call C<get_values()> in list context to get one
or more values.

=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4},{'b' => 5}], 'Data::Pairs' )",
    "new()" );

 my @values  = $pairs->get_values();  # (1, 2, 3, 4, 5)

is( "@values", "1 2 3 4 5",
    "get_values(), list" );

 my $howmany = $pairs->get_values();  # 5

is( $howmany, 5,
    "get_values(), scalar" );

 @values  = $pairs->get_values( 'c', 'b' );  # (2, 3, 4, 5)

is( "@values", "2 3 4 5",
    "get_values( 'c', 'b' ), list" );

 $howmany = $pairs->get_values( 'c', 'b' );  # 4

is( $howmany, 4,
    "get_values( 'c', 'b' ), scalar" );

 @values  = $pairs->get_values( 'b' );  # (2, 4, 5)

is( "@values", "2 4 5",
    "get_values( 'b' ), list" );

 $howmany = $pairs->get_values( 'b' );  # 3

is( $howmany, 3,
    "get_values( 'b' ), scalar" );

}

OBJECT_add: {

=head2 $pairs->add( $key => $value[, $pos] );

Adds a key/value pair to the object.

Accepts C<$key>, C<$value>, and optionally, C<$pos>.

If C<$pos> is given, the key/value pair will be added (inserted)
there (possibly overriding a defined order), e.g.,

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2}] );
 $pairs->add( c => 3, 1 );  # pairs is now [{a=>1},{c=>3},{b=>2}]

(Positions start at 0.)

If C<$pos> is not given, a new pair is added to the end or merged
according to the defined C<order()>.

Returns C<$value>.

=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2}], 'Data::Pairs' )",
    "new()" );

 $pairs->add( c => 3, 1 );  # pairs is now [{a=>1},{c=>3},{b=>2}]

is( Dumper($pairs), "bless( [{'a' => 1},{'c' => 3},{'b' => 2}], 'Data::Pairs' )",
    "add( c => 3, 1 )" );

}

OBJECT_get_pos: {
#---------------------------------------------------------------------

=head2 $pairs->get_pos( $key );

Gets position(s) where a key is found.

Accepts one key (any extras are silently ignored).  

In list context, returns a list of positions where the keys is found.

In scalar context, if the key only appears once, that position is
returned.  If the key appears more than once, an array ref is returned,
which contains all the positions, e.g.,

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4}] );

 my @pos   = $pairs->get_pos( 'c' );  # (2)
 my $pos   = $pairs->get_pos( 'c' );  # 2

 @pos   = $pairs->get_pos( 'b' );  # (1, 3)
 $pos   = $pairs->get_pos( 'b' );  # [1, 3]

Returns C<()/undef> if no key given, no keys found, or object is empty.

=cut

 my $pairs = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "new()" );

 my @pos   = $pairs->get_pos( 'c' );  # (2)

is( "@pos", 2,
    "get_pos( 'c' ), list" );

 my $pos   = $pairs->get_pos( 'c' );  # 2

is( $pos, 2,
    "get_pos( 'c' ), scalar" );

 @pos   = $pairs->get_pos( 'b' );  # (1, 3)

is( "@pos", "1 3",
    "get_pos( 'b' ), list, duplicate key" );

 $pos   = $pairs->get_pos( 'b' );  # [1, 3]

is( Dumper($pos), "[1,3]",
    "get_pos( 'b' ), scalar, duplicate key" );

}

OBJECT_get_pos_hash: {
#---------------------------------------------------------------------

=head2 $pairs->get_pos_hash( @keys );

Gets positions where keys are found.

Accepts zero or more keys.

In list context, returns a hash of keys/positions found.  In scalar
context, returns a hash ref to this hash.  If no keys given, all the
positions are mapped in the hash.  Since keys may appear more than
once, the positions are stored as arrays.

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4}] );
 my %pos      = $pairs->get_pos_hash( 'c', 'b' );  # %pos      is (b=>[1,3],c=>[2])
 my $pos_href = $pairs->get_pos_hash( 'c', 'b' );  # $pos_href is {b=>[1,3],c=>[2]}

If a given key is not found, it will not appear in the returned hash.

Returns C<undef/()> if no keys given or object is empty.

=cut

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4}], 'Data::Pairs' )",
    "new()" );

 my %pos      = $pairs->get_pos_hash( 'c', 'b' );  # %pos      is (b=>[1,3],c=>[2])

is( Dumper(\%pos), "{'b' => [1,3],'c' => [2]}",
    "get_pos_hash( 'c', 'b' ), list" );

 my $pos_href = $pairs->get_pos_hash( 'c', 'b' );  # $pos_href is {b=>[1,3],c=>[2]}

is( Dumper($pos_href), "{'b' => [1,3],'c' => [2]}",
    "get_pos_hash( 'c', 'b' ), scalar" );

}

OBJECT_get_keys: {

=head2 $pairs->get_keys( @keys );

Gets keys.

Accepts zero or more keys.  If no keys are given, returns all the
keys in the object (list context) or the number of keys (scalar
context), e.g.,

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}] );
 my @keys    = $pairs->get_keys();  # @keys is (a, b, c, b, b)
 my $howmany = $pairs->get_keys();  # $howmany is 5

If one or more keys are given, returns all the keys that are found
(list) or the number found (scalar).  Keys returned are listed in the
order found in the object, e.g.,

 @keys    = $pairs->get_keys( 'c', 'b', 'A' );  # @keys is (b, c, b, b)
 $howmany = $pairs->get_keys( 'c', 'b', 'A' );  # $howmany is 4

=cut

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3},{'b' => 4},{'b' => 5}], 'Data::Pairs' )",
    "new()" );

 my @keys    = $pairs->get_keys();  # @keys is (a, b, c, b, b)

is( "@keys", "a b c b b",
    "get_keys(), list" );

 my $howmany = $pairs->get_keys();  # $howmany is 5

is( $howmany, 5,
    "get_keys(), scalar" );

 @keys    = $pairs->get_keys( 'c', 'b', 'A' );  # @keys is (b, c, b, b)

is( "@keys", "b c b b",
    "get_keys( 'c', 'b', 'A' ), list" );

 $howmany = $pairs->get_keys( 'c', 'b', 'A' );  # $howmany is 4

is( $howmany, 4,
    "get_keys( 'c', 'b', 'A' ), scalar" );

}

OBJECT_get_array: {

=head2 $pairs->get_array( @keys );

Gets an array of key/value pairs.

Accepts zero or more keys.  If no keys are given, returns a list of
all the key/value pairs in the object (list context) or an array
reference to that list (scalar context), e.g.,

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3}] );
 my @array   = $pairs->get_array();  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = $pairs->get_array();  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

If one or more keys are given, returns a list of key/value pairs for
all the keys that are found (list) or an aref to that list (scalar).
Pairs returned are in the order found in the object, e.g.,

 @array = $pairs->get_array( 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = $pairs->get_array( 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

Note, conceivably this method might be used to make a copy
(unblessed) of the object, but it would not be a deep copy (if values
are references, the references would be copied, not the referents).

=cut

 my $pairs    = Data::Pairs->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($pairs), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Pairs' )",
    "new()" );

 my @array   = $pairs->get_array();  # @array is ({a=>1}, {b=>2}, {c=>3})

is( Dumper(\@array), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "get_array(), list" );

 my $aref    = $pairs->get_array();  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

is( Dumper($aref), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "get_array(), scalar" );

 @array = $pairs->get_array( 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})

is( Dumper(\@array), "[{'b' => 2},{'c' => 3}]",
    "get_array( 'c', 'b', 'A' ), list" );

 $aref  = $pairs->get_array( 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

is( Dumper($aref), "[{'b' => 2},{'c' => 3}]",
    "get_array( 'c', 'b', 'A' ), scalar" );

}

NONOO: {

=head2 Exporting

Nothing is exported by default.  All subroutines may be exported
using C<:ALL>, e.g.,

 use Data::Pairs ':ALL';

They are shown below.

A subset may be exported using C<:STD>, e.g.,

 use Data::Pairs ':STD';

This subset includes
C<pairs_set()>
C<pairs_get_values()>
C<pairs_get_keys()>
C<pairs_exists()>
C<pairs_delete()>
C<pairs_clear()>

=cut

BEGIN{ use_ok( 'Data::Pairs', ':STD' ); }
BEGIN{ use_ok( 'Data::Pairs', ':ALL' ); } # last so we have all below

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;
$Data::Dumper::Sortkeys=1;

=head2 C<new> without C<new()>

To create a pairs ordered mapping from scratch, simply assign an
empty array ref, e.g.,

 my $pairs = [];

=cut

{
 my $pairs = [];
is( Dumper($pairs), "[]",
    "new without new()" );
}

=head2 pairs_set( $pairs, $key => $value[, $pos] );

(See C<< $pairs->set() >> above.)

 my $pairs = [{a=>1},{b=>2}];
 pairs_set( $pairs, c => 3, 0 );  # pairs is now [{c=>3},{b=>2}]

=cut

{
 my $pairs = [{a=>1},{b=>2}];
 pairs_set( $pairs, c => 3, 0 );  # pairs is now [{c=>3},{b=>2}]
is( Dumper($pairs), "[{'c' => 3},{'b' => 2}]",
    "pairs_set()" );
}

=head2 pairs_get_values( $pairs[, $key[, @keys]] );

(See C<< $pairs->get_values() >> above.)

 my $pairs = [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}];
 my @values  = pairs_get_values( $pairs );  # (1, 2, 3, 4, 5)
 my $howmany = pairs_get_values( $pairs );  # 5
 
 @values  = pairs_get_values( $pairs, 'c', 'b' );  # (2, 3, 4, 5)
 $howmany = pairs_get_values( $pairs, 'c', 'b' );  # 4

 @values  = pairs_get_values( $pairs, 'b' );  # (2, 4, 5)
 $howmany = pairs_get_values( $pairs, 'b' );  # 3
 
=cut

{
 my $pairs = [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}];
 my @values  = pairs_get_values( $pairs );  # (1, 2, 3, 4, 5)
 my $howmany = pairs_get_values( $pairs );  # 5

is( "@values", "1 2 3 4 5",
    "pairs_get_values(), no parm, list" );
is( $howmany, 5,
    "pairs_get_values(), no parm, scalar" );
 
 @values  = pairs_get_values( $pairs, 'c', 'b' );  # (2, 3, 4, 5)
 $howmany = pairs_get_values( $pairs, 'c', 'b' );  # 4

is( "@values", "2 3 4 5",
    "pairs_get_values(), multi-parm, list" );
is( $howmany, 4,
    "pairs_get_values(), multi-parm, scalar" );

 @values  = pairs_get_values( $pairs, 'b' );  # (2, 4, 5)
 $howmany = pairs_get_values( $pairs, 'b' );  # 3
 
is( "@values", "2 4 5",
    "pairs_get_values(), single parm, list" );
is( $howmany, 3,
    "pairs_get_values(), single parm, scalar (same as multi-parm" );
 
}

=head2 pairs_add( $pairs, $key => $value[, $pos] );

(See C<< $pairs->add() >> above.)

 my $pairs = [{a=>1},{b=>2}];
 pairs_add( $pairs, c => 3, 1 );  # pairs is now [{a=>1},{c=>3},{b=>2}]

=cut

{
 my $pairs = [{a=>1},{b=>2}];
 pairs_add( $pairs, c => 3, 1 );  # pairs is now [{a=>1},{c=>3},{b=>2}]
is( Dumper($pairs), "[{'a' => 1},{'c' => 3},{'b' => 2}]",
    "pairs_add()" );
}

=head2 pairs_get_pos( $pairs, $key );

(See C<< $pairs->get_pos() >> above.)

 my $pairs = [{a=>1},{b=>2},{c=>3},{b=>4}];
 my @pos   = pairs_get_pos( $pairs, 'c' );  # (2)
 my $pos   = pairs_get_pos( $pairs, 'c' );  # 2
 @pos   = pairs_get_pos( $pairs, 'b' );  # (1, 3)
 $pos   = pairs_get_pos( $pairs, 'b' );  # [1, 3]

=cut

{
 my $pairs = [{a=>1},{b=>2},{c=>3},{b=>4}];
 my @pos   = pairs_get_pos( $pairs, 'c' );  # (2)
 my $pos   = pairs_get_pos( $pairs, 'c' );  # 2

is( "@pos", 2,
    "pairs_get_pos, list" );
is( $pos, 2,
    "pairs_get_pos, scalar" );

 @pos   = pairs_get_pos( $pairs, 'b' );  # (1, 3)
 $pos   = pairs_get_pos( $pairs, 'b' );  # [1, 3]

is( "@pos", "1 3",
    "pairs_get_pos, list" );
is( Dumper($pos), "[1,3]",
    "pairs_get_pos, scalar" );
}

=head2 pairs_get_pos_hash( $pairs[, @keys] );

(See C<< $pairs->get_pos_hash() >> above.)

 my $pairs    = [{a=>1},{b=>2},{c=>3},{b=>4}];
 my %pos      = pairs_get_pos_hash( $pairs, 'c', 'b' );  # %pos      is (b=>[1,3],c=>[2])
 my $pos_href = pairs_get_pos_hash( $pairs, 'c', 'b' );  # $pos_href is {b=>[1,3],c=>[2]}

=cut

{
 my $pairs    = [{a=>1},{b=>2},{c=>3},{b=>4}];
 my %pos      = pairs_get_pos_hash( $pairs, 'c', 'b' );  # %pos      is (b=>[1,3],c=>[2])
 my $pos_href = pairs_get_pos_hash( $pairs, 'c', 'b' );  # $pos_href is {b=>[1,3],c=>[2]}

is( Dumper(\%pos), "{'b' => [1,3],'c' => [2]}",
    "pairs_get_pos_hash(), list" );
is( Dumper($pos_href), "{'b' => [1,3],'c' => [2]}",
    "pairs_get_pos_hash(), scalar" );
}

=head2 pairs_get_keys( $pairs[, @keys] );

(See C<< $pairs->get_keys() >> above.)

 my $pairs    = [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}];
 my @keys    = pairs_get_keys( $pairs );  # @keys is (a, b, c, b, b)
 my $howmany = pairs_get_keys( $pairs );  # $howmany is 5

 @keys    = pairs_get_keys( $pairs, 'c', 'b', 'A' );  # @keys is (b, c, b, b)
 $howmany = pairs_get_keys( $pairs, 'c', 'b', 'A' );  # $howmany is 4

=cut

{
 my $pairs    = [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}];
 my @keys    = pairs_get_keys( $pairs );  # @keys is (a, b, c, b, b)
 my $howmany = pairs_get_keys( $pairs );  # $howmany is 5

is( "@keys", "a b c b b",
    "pairs_get_keys(), list" );
is( $howmany, 5,
    "pairs_get_keys(), scalar" );

 @keys    = pairs_get_keys( $pairs, 'c', 'b', 'A' );  # @keys is (b, c, b, b)
 $howmany = pairs_get_keys( $pairs, 'c', 'b', 'A' );  # $howmany is 4

is( "@keys", "b c b b",
    "pairs_get_keys(), list" );
is( $howmany, 4,
    "pairs_get_keys(), scalar" );

}

=head2 pairs_get_array( $pairs[, @keys] );

(See C<< $pairs->get_array() >> above.)

 my $pairs    = [{a=>1},{b=>2},{c=>3}];
 my @array   = pairs_get_array( $pairs );  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = pairs_get_array( $pairs );  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

 @array = pairs_get_array( $pairs, 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = pairs_get_array( $pairs, 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

=cut

{
 my $pairs    = [{a=>1},{b=>2},{c=>3}];
 my @array   = pairs_get_array( $pairs );  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = pairs_get_array( $pairs );  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

is( Dumper(\@array), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "pairs_get_array(), list" );
is( Dumper($aref), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "pairs_get_array(), scalar" );

 @array = pairs_get_array( $pairs, 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = pairs_get_array( $pairs, 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

is( Dumper(\@array), "[{'b' => 2},{'c' => 3}]",
    "pairs_get_array(), list" );
is( Dumper($aref), "[{'b' => 2},{'c' => 3}]",
    "pairs_get_array(), scalar" );
}

=head2 pairs_exists( $pairs, $key );

(See C<< $pairs->exists() >> above.)

 my $bool = pairs_exists( $pairs, 'a' );

=cut

 my $pairs = [{a=>1},{b=>2},{c=>3}];
 my $bool = pairs_exists( $pairs, 'a' );
is( $bool, 1,
    "pairs_exists()" );

=head2 pairs_delete( $pairs, $key );

(See C<< $pairs->delete() >> above.)

 pairs_delete( $pairs, 'a' );

=cut

 pairs_delete( $pairs, 'a' );
is( Dumper( $pairs ), "[{'b' => 2},{'c' => 3}]",
    "pairs_delete()" );

=head2 pairs_clear( $pairs );

(See C<< $pairs->clear() >> above.)

 pairs_clear( $pairs );

=cut

 pairs_clear( $pairs );
is( Dumper( $pairs ), "[]",
    "pairs_clear()" );

}

