use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;
$Data::Dumper::Sortkeys=1;

BEGIN { use_ok('Data::Omap') };

SYNOPSIS_simple: {
 
     # Simple OO style
 
     my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );
 
     $omap->set( a => 0 );

is( Dumper($omap), "bless( [{'a' => 0},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "set( a => 0 )" );

     $omap->add( b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
is( Dumper($omap), "bless( [{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3}], 'Data::Omap' )",
    "add( b2 => 2.5, 2 )" );

     my $value  = $omap->get_values( 'c' );    # 3

is( $value, 3, "get_values( 'c' )" );

     my @keys   = $omap->get_keys();           # (a, b, b2, c)

is( "@keys", "a b b2 c", "get_keys()" );

     my @values = $omap->get_values();         # (0, 2, 2.5, 3)

is( "@values", "0 2 2.5 3", "get_values()" );

     my @subset = $omap->get_values(qw(c b));  # (2, 3) (values are data-ordered)

is( "@subset", "2 3", "get_values(qw(c b ))" );

}

SYNOPSIS_tied: {
 
     # Tied style
 
     my %omap;
     # recommend saving an object reference, too.
     my $omap = tie %omap, 'Data::Omap', [{a=>1},{b=>2},{c=>3}];
 
is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "tie %omap" );
 
     $omap{ a } = 0;

is( Dumper($omap), "bless( [{'a' => 0},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "$omap{ a } = 0" );
 
     $omap->add( b2 => 2.5, 2 );  # there's no tied hash equivalent
 
is( Dumper($omap), "bless( [{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3}], 'Data::Omap' )",
    "add( b2 => 2.5, 2 )" );

     my $value  = $omap{ c };

is( $value, 3, "\$omap{ c }" );

     my @keys   = keys %omap;      # $omap->get_keys() is faster 

is( "@keys", "a b b2 c", "keys %omap" );

     my @values = values %omap;    # $omap->get_values() is faster

is( "@values", "0 2 2.5 3", "values %omap" );

     my @slice  = @omap{qw(c b)};  # (3, 2) (slice values are parameter-ordered)

is( "@slice", "3 2", "\@omap{qw(c b)}" );
 
}

SYNOPSIS_nonoo: {

=pod

 # Non-OO style

 use Data::Omap ':ALL';
 
 my $omap = [{a=>1},{b=>2},{c=>3}];  # new-ish, but not blessed

 omap_set( $omap, a => 0 );        # (pass omap as first parameter)
 omap_add( $omap, b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
 my $value  = omap_get_values( $omap, 'c' );      # 3
 my @keys   = omap_get_keys( $omap );             # (a, b, b2, c)
 my @values = omap_get_values( $omap );           # (0, 2, 2.5, 3)
 my @subset = omap_get_values( $omap, qw(c b) );  # (2, 3) (values are data-ordered)

 # There are more methods/options, see below.

=cut
     
 use Data::Omap ':ALL';

 my $omap = [{a=>1},{b=>2},{c=>3}];  # new-ish, but not blessed

 omap_set( $omap, a => 0 );        # (pass omap as first parameter)

is( Dumper($omap), "[{'a' => 0},{'b' => 2},{'c' => 3}]",
    "omap_set( ... a => 0 )" );

 omap_add( $omap, b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
is( Dumper($omap), "[{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3}]",
    "omap_add( ... b2 => 2.5, 2 )" );

 my $value  = omap_get_values( $omap, 'c' );      # 3

is( $value, 3,
    "omap_get_values( ... 'c' )" );

 my @keys   = omap_get_keys( $omap );             # (a, b, b2, c)

is( "@keys", "a b b2 c",
    "omap_get_keys()" );

 my @values = omap_get_values( $omap );           # (0, 2, 2.5, 3)

is( "@values", "0 2 2.5 3",
    "omap_get_values()" );

 my @subset = omap_get_values( $omap, qw(c b) );  # (2, 3) (values are data-ordered)

is( "@subset", "2 3",
    "omap_get_values( ... qw(c b ))" );

}

CLASS_new: {

     my $omap = Data::Omap->new( [ { a => 1 }, { b => 2 }, { c => 3 } ] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

}

CLASS_order: {

     Data::Omap->order();         # leaves ordering as is

is( Data::Omap->order(), undef, "order()" );

     Data::Omap->order( '' );     # turn ordering OFF (the default)

is( Data::Omap->order(), '', "order( '' )" );

     Data::Omap->order( 'na' );   # numeric ascending

is( ref(Data::Omap->order()), 'CODE', "order( 'na' )" );

     Data::Omap->order( 'nd' );   # numeric ascending

is( ref(Data::Omap->order()), 'CODE', "order( 'nd' )" );

     Data::Omap->order( 'sa' );   # string  ascending

is( ref(Data::Omap->order()), 'CODE', "order( 'sa' )" );

     Data::Omap->order( 'sd' );   # string  descending

is( ref(Data::Omap->order()), 'CODE', "order( 'sd' )" );

     Data::Omap->order( 'sna' );  # string/numeric ascending

is( ref(Data::Omap->order()), 'CODE', "order( 'sna' )" );

     Data::Omap->order( 'snd' );  # string/numeric descending

is( ref(Data::Omap->order()), 'CODE', "order( 'snd' )" );

     Data::Omap->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # code

is( ref(Data::Omap->order()), 'CODE', "custom order()" );

}

OBJECT_set: {

     my $omap = Data::Omap->new( [{a=>1},{b=>2}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2}], 'Data::Omap' )",
    "new()" );

     $omap->set( c => 3, 0 );  # omap is now [{c=>3},{b=>2}]

is( Dumper($omap), "bless( [{'c' => 3},{'b' => 2}], 'Data::Omap' )",
    "set()" );

}

OBJECT_get_values: {

     my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

     my @values  = $omap->get_values();  # (1, 2, 3)

is( "@values", "1 2 3",
    "get_values(), list" );

     my $howmany = $omap->get_values();  # 3

is( $howmany, 3,
    "get_values(), scalar" );

     @values   = $omap->get_values( 'b' );  # (2)

is( "@values", 2,
    "get_values( 'b' ), list" );

     my $value = $omap->get_values( 'b' );  # 2

is( $value, 2,
    "get_values( 'b' ), scalar" );

     @values  = $omap->get_values( 'c', 'b', 'A' );  # (2, 3)

is( "@values", "2 3",
    "get_values( 'c', 'b', 'A' ), list" );

     $howmany = $omap->get_values( 'c', 'b', 'A' );  # 2

is( $howmany, 2,
    "get_values( 'c', 'b', 'A' ), scalar" );

}

OBJECT_add: {

     my $omap = Data::Omap->new( [{a=>1},{b=>2}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2}], 'Data::Omap' )",
    "new()" );

     $omap->add( c => 3, 1 );  # omap is now [{a=>1},{c=>3},{b=>2}]

is( Dumper($omap), "bless( [{'a' => 1},{'c' => 3},{'b' => 2}], 'Data::Omap' )",
    "add( c => 3, 1 )" );

}

OBJECT_get_pos: {
#---------------------------------------------------------------------

=head2 $omap->get_pos( $key );

Gets position where a key is found.

Accepts one key (any extras are silently ignored).  

Returns the position or undef (if key not found), regardless of context, e.g.,

 my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );
 my @pos  = $omap->get_pos( 'b' );  # (1)
 my $pos  = $omap->get_pos( 'b' );  # 1

Returns C<undef/()> if no key given or object is empty.

=cut

 my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

 my @pos  = $omap->get_pos( 'b' );  # (1)

is( "@pos", 1,
    "get_pos( 'b' ), list" );

 my $pos  = $omap->get_pos( 'b' );  # 1

is( $pos, 1,
    "get_pos( 'b' ), scalar" );

}

OBJECT_get_pos_hash: {
#---------------------------------------------------------------------

=head2 $omap->get_pos_hash( @keys );

Gets positions where keys are found.

Accepts zero or more keys.

In list context, returns a hash of keys/positions found.  In scalar
context, returns a hash ref to this hash.  If no keys given, all the
positions are mapped in the hash.

 my $omap     = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );
 my %pos      = $omap->get_pos_hash( 'c', 'b' ); # %pos      is (b=>1,c=>2)
 my $pos_href = $omap->get_pos_hash( 'c', 'b' ); # $pos_href is {b=>1,c=>2}
                                                                                                                                 
If a given key is not found, it will not appear in the returned hash.

Returns C<undef/()> if no keys given or object is empty.

=cut

 my $omap     = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

 my %pos      = $omap->get_pos_hash( 'c', 'b' ); # %pos      is (b=>1,c=>2)

is( Dumper(\%pos), "{'b' => 1,'c' => 2}",
    "get_pos_hash, list context" );

 my $pos_href = $omap->get_pos_hash( 'c', 'b' ); # $pos_href is {b=>1,c=>2}

is( Dumper($pos_href), "{'b' => 1,'c' => 2}",
    "get_pos_hash, scalar context" );

}

OBJECT_get_keys: {

     my $omap    = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

     my @keys    = $omap->get_keys();  # @keys is (a, b, c)

is( "@keys", "a b c",
    "get_keys(), list" );

     my $howmany = $omap->get_keys();  # $howmany is 3

is( $howmany, 3,
    "get_keys(), scalar" );

     @keys    = $omap->get_keys( 'c', 'b', 'A' );  # @keys is (b, c)

is( "@keys", "b c",
    "get_keys( 'c', 'b', 'A' ), list" );

     $howmany = $omap->get_keys( 'c', 'b', 'A' );  # $howmany is 2

is( $howmany, 2,
    "get_keys( 'c', 'b', 'A' ), scalar" );

}

OBJECT_get_array: {

     my $omap    = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

     my @array   = $omap->get_array();  # @array is ({a=>1}, {b=>2}, {c=>3})

is( Dumper(\@array), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "get_array(), list" );

     my $aref    = $omap->get_array();  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

is( Dumper($aref), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "get_array(), scalar" );

     @array = $omap->get_array( 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})

is( Dumper(\@array), "[{'b' => 2},{'c' => 3}]",
    "get_array( 'c', 'b', 'A' ), list" );

     $aref  = $omap->get_array( 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

is( Dumper($aref), "[{'b' => 2},{'c' => 3}]",
    "get_array( 'c', 'b', 'A' ), scalar" );

}

NONOO: {

=head2 Exporting

Nothing is exported by default.  All subroutines may be exported
using C<:ALL>, e.g.,

 use Data::Omap ':ALL';

They are shown below.

A subset may be exported using C<:STD>, e.g.,

 use Data::Omap ':STD';

=cut

BEGIN{ use_ok( 'Data::Omap', ':STD' ); }
BEGIN{ use_ok( 'Data::Omap', ':ALL' ); } # last so we have all below

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;
$Data::Dumper::Sortkeys=1;

=head2 C<new> without C<new()>

To create an ordered mapping from scratch, simply assign an empty
array ref, e.g.,

 my $omap = [];

=cut

{
 my $omap = [];
is( Dumper($omap), "[]",
    "new without new()" );
}


=head2 omap_set( $omap, $key => $value[, $pos] );

 my $omap = [{a=>1},{b=>2}];
 omap_set( $omap, c => 3, 0 );  # omap is now [{c=>3},{b=>2}]

=cut

{
 my $omap = [{a=>1},{b=>2}];
 omap_set( $omap, c => 3, 0 );  # omap is now [{c=>3},{b=>2}]
is( Dumper($omap), "[{'c' => 3},{'b' => 2}]",
    "omap_set()" );
}

=head2 omap_get_values( $omap[, $key[, @keys]] );

 my $omap = [{a=>1},{b=>2},{c=>3}];
 my @values  = omap_get_values( $omap );  # (1, 2, 3)
 my $howmany = omap_get_values( $omap );  # 3
 
 @values   = omap_get_values( $omap, 'b' );  # (2)
 my $value = omap_get_values( $omap, 'b' );  # 2
 
 @values  = omap_get_values( $omap, 'c', 'b', 'A' );  # (2, 3)
 $howmany = omap_get_values( $omap, 'c', 'b', 'A' );  # 2

=cut

{
 my $omap = [{a=>1},{b=>2},{c=>3}];
 my @values  = omap_get_values( $omap );  # (1, 2, 3)
 my $howmany = omap_get_values( $omap );  # 3

is( "@values", "1 2 3",
    "omap_get_values(), no parm, list" );
is( $howmany, 3,
    "omap_get_values(), no parm, scalar" );
 
 @values   = omap_get_values( $omap, 'b' );  # (2)
 my $value = omap_get_values( $omap, 'b' );  # 2
 
is( "@values", 2,
    "omap_get_values(), single parm, list" );
is( $value, 2,
    "omap_get_values(), single parm, scalar" );
 
 @values  = omap_get_values( $omap, 'c', 'b', 'A' );  # (2, 3)
 $howmany = omap_get_values( $omap, 'c', 'b', 'A' );  # 2

is( "@values", "2 3",
    "omap_get_values(), multi-parm, list" );
is( $howmany, 2,
    "omap_get_values(), multi-parm, scalar" );
}

=head2 omap_add( $omap, $key => $value[, $pos] );

 my $omap = [{a=>1},{b=>2}];
 omap_add( $omap, c => 3, 1 );  # omap is now [{a=>1},{c=>3},{b=>2}]

=cut

{
 my $omap = [{a=>1},{b=>2}];
 omap_add( $omap, c => 3, 1 );  # omap is now [{a=>1},{c=>3},{b=>2}]
is( Dumper($omap), "[{'a' => 1},{'c' => 3},{'b' => 2}]",
    "omap_add()" );
}

=head2 omap_get_pos( $omap, $key );

 my $omap = [{a=>1},{b=>2},{c=>3}];
 my @pos  = omap_get_pos( $omap, 'b' );  # (1)
 my $pos  = omap_get_pos( $omap, 'b' );  # 1

=cut

{
 my $omap = [{a=>1},{b=>2},{c=>3}];
 my @pos  = omap_get_pos( $omap, 'b' );  # (1)
 my $pos  = omap_get_pos( $omap, 'b' );  # 1
is( "@pos", 1,
    "omap_get_pos, list" );
is( $pos, 1,
    "omap_get_pos, scalar" );
}

=head2 omap_get_pos_hash( $omap[, @keys] );

 my $omap     = [{a=>1},{b=>2},{c=>3}];
 my %pos      = omap_get_pos_hash( $omap, 'c', 'b' ); # %pos      is (b=>1,c=>2)
 my $pos_href = omap_get_pos_hash( $omap, 'c', 'b' ); # $pos_href is {b=>1,c=>2}

=cut

{
 my $omap     = [{a=>1},{b=>2},{c=>3}];
 my %pos      = omap_get_pos_hash( $omap, 'c', 'b' ); # %pos      is (b=>1,c=>2)
 my $pos_href = omap_get_pos_hash( $omap, 'c', 'b' ); # $pos_href is {b=>1,c=>2}
is( Dumper(\%pos), "{'b' => 1,'c' => 2}",
    "omap_get_pos_hash(), list" );
is( Dumper($pos_href), "{'b' => 1,'c' => 2}",
    "omap_get_pos_hash(), scalar" );
}

=head2 omap_get_keys( $omap[, @keys] );

 my $omap    = [{a=>1},{b=>2},{c=>3}];
 my @keys    = omap_get_keys( $omap );  # @keys is (a, b, c)
 my $howmany = omap_get_keys( $omap );  # $howmany is 3

 @keys    = omap_get_keys( $omap, 'c', 'b', 'A' );  # @keys is (b, c)
 $howmany = omap_get_keys( $omap, 'c', 'b', 'A' );  # $howmany is 2

=cut

{
 my $omap    = [{a=>1},{b=>2},{c=>3}];
 my @keys    = omap_get_keys( $omap );  # @keys is (a, b, c)
 my $howmany = omap_get_keys( $omap );  # $howmany is 3
is( "@keys", "a b c",
    "omap_get_keys(), list" );
is( $howmany, 3,
    "omap_get_keys(), scalar" );

 @keys    = omap_get_keys( $omap, 'c', 'b', 'A' );  # @keys is (b, c)
 $howmany = omap_get_keys( $omap, 'c', 'b', 'A' );  # $howmany is 2
is( "@keys", "b c",
    "omap_get_keys(), list" );
is( $howmany, 2,
    "omap_get_keys(), scalar" );

}

=head2 omap_get_array( $omap[, @keys] );

 my $omap    = [{a=>1},{b=>2},{c=>3}];
 my @array   = omap_get_array( $omap );  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = omap_get_array( $omap );  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

 @array = omap_get_array( $omap, 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = omap_get_array( $omap, 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

=cut

{
 my $omap    = [{a=>1},{b=>2},{c=>3}];
 my @array   = omap_get_array( $omap );  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = omap_get_array( $omap );  # $aref  is [{a=>1}, {b=>2}, {c=>3}]
is( Dumper(\@array), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "omap_get_array(), list" );
is( Dumper($aref), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "omap_get_array(), scalar" );

 @array = omap_get_array( $omap, 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = omap_get_array( $omap, 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]
is( Dumper(\@array), "[{'b' => 2},{'c' => 3}]",
    "omap_get_array(), list" );
is( Dumper($aref), "[{'b' => 2},{'c' => 3}]",
    "omap_get_array(), scalar" );

}


=head2 omap_exists( $omap, $key );

 my $bool = omap_exists( $omap, 'a' );

=cut

 my $omap = [{a=>1},{b=>2},{c=>3}];
 my $bool = omap_exists( $omap, 'a' );
is( $bool, 1,
    "omap_exists()" );

=head2 omap_delete( $omap, $key );

 omap_delete( $omap, 'a' );

=cut

 omap_delete( $omap, 'a' );
is( Dumper( $omap ), "[{'b' => 2},{'c' => 3}]",
    "omap_delete()" );

=head2 omap_clear( $omap );

 omap_clear( $omap );

=cut

 omap_clear( $omap );
is( Dumper( $omap ), "[]",
    "omap_clear()" );

}
