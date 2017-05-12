#---------------------------------------------------------------------
  package Data::Pairs;
#---------------------------------------------------------------------

=head1 NAME

Data::Pairs - Perl module to implement ordered mappings with possibly
duplicate keys.

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
 
 # Tied style

 # Alas, because of duplicate keys, tying to a %hash is not supported.
 
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

=head1 DESCRIPTION

This module implements the Data::Pairs class.  Objects in this class
are ordered mappings, i.e., they are hashes in which the key/value
pairs are in order. This is defined in shorthand as C<!!pairs> in the
YAML tag repository:  http://yaml.org/type/pairs.html.

The keys in Data::Pairs objects are not necessarily unique, unlike
regular hashes.

A closely related class, Data::Omap, implements the YAML C<!!omap>
data type, http://yaml.org/type/omap.html.  Data::Omap objects are
also ordered sequences of key/value pairs but they do not allow
duplicate keys.

While ordered mappings are in order, they are not necessarily in a
I<particular> order, i.e., they are not necessarily sorted in any
way.  They simply have a predictable set order (unlike regular hashes
whose key/value pairs are in no set order).

By default, Data::Pairs will add new key/value pairs at the end of the
mapping, but you may request that they be merged in a particular
order with the C<order()> class method.

However, even though Data::Pairs will honor the requested order, it
will not attempt to I<keep> the mapping in that order.  By passing
position values to the C<set()> and C<add()> methods, you may insert
new pairs anywhere in the mapping and Data::Pairs will not complain.

=head1 IMPLEMENTATION

Normally, the underlying structure of an OO object is encapsulated
and not directly accessible (when you play nice). One key
implementation detail of Data::Pairs is the desire that the underlying
ordered mapping data structure (an array of single-key hashes) be
publically maintained as such and directly accessible if desired.

To that end, no attributes but the data itself are stored in the
objects.  In the current version, that is why C<order()> is a class
method rather than an object method.  In the future, inside-out
techniques may be used to enable object-level ordering.

This data structure is inefficient in several ways as compared to
regular hashes: rather than one hash, it contains a separate hash per
key/value pair; because it's an array, key lookups (in the current
version) have to loop through it.

The advantage if using this structure is simply that it "natively"
matches the structure defined in YAML.  So if the (unblessed)
structure is dumped using YAML (or perhaps JSON), it may be read as
is by another program, perhaps in another language.  It is true that
this could be accomplished by passing the object through a formatting
routine, but I wanted to see first how this implementation might work.

=head1 VERSION

Data::Pairs version 0.07

=cut

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.07';

use Scalar::Util qw( reftype looks_like_number );
use Carp;
use Exporter qw( import );
our @EXPORT_OK = qw(
    pairs_set    pairs_get_values pairs_get_keys
    pairs_exists pairs_delete     pairs_clear 
    pairs_add    pairs_order      pairs_get_pos
    pairs_get_pos_hash pairs_get_array
    pairs_is_valid     pairs_errstr
    );
our %EXPORT_TAGS = (
    STD => [qw( 
    pairs_set    pairs_get_values pairs_get_keys
    pairs_exists pairs_delete     pairs_clear )],
    ALL => [qw(
    pairs_set    pairs_get_values pairs_get_keys
    pairs_exists pairs_delete     pairs_clear 
    pairs_add    pairs_order      pairs_get_pos
    pairs_get_pos_hash pairs_get_array
    pairs_is_valid     pairs_errstr )],
    );

my $order;    # package global, see order() accessor
our $errstr;  # error message

#---------------------------------------------------------------------

=head1 CLASS METHODS

=head2 Data::Pairs->new();

Constructs a new Data::Pairs object.

Accepts array ref containing single-key hash refs, e.g.,

 my $pairs = Data::Pairs->new( [ { a => 1 }, { b => 2 }, { c => 3 }, { b => 4 } ] );

When provided, this data will be loaded into the object.

Returns a reference to the Data::Pairs object.

=cut

sub new {
    my( $class, $aref ) = @_;
    return bless [], $class unless $aref;

    croak pairs_errstr() unless pairs_is_valid( $aref );
    bless $aref, $class;
}

sub pairs_is_valid {
    my( $aref ) = @_;
    unless( $aref and ref( $aref ) and reftype( $aref ) eq 'ARRAY' ) {
        $errstr = "Invalid pairs: Not an array reference";
        return;
    }
    for my $href ( @$aref ) {
        unless( ref( $href ) eq 'HASH' ) {
            $errstr = "Invalid pairs: Not a hash reference";
            return;
        }
        my @keys = keys %$href;
        if( @keys > 1 ) {
            $errstr = "Invalid pairs: Not a single-key hash";
            return;
        }
    }
    return 1;  # is valid
}

sub pairs_errstr {
    my $msg = $errstr;
    $errstr = "";
    $msg;  # returned
}

#---------------------------------------------------------------------

=head2 Data::Pairs->order( [$predefined_ordering | coderef] );

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
 Data::Pairs->order( 'nd' );   # numeric descending
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
new objects will inherit the class-level ordering unless overridden
at the object level.

=cut

*pairs_order = \&order;
sub order {
    my( $class, $spec ) = @_;  # class not actually used ...
    return $order unless defined $spec;

    if( ref( $spec ) eq 'CODE' ) {
        $order = $spec;
    }
    else {
        $order = {
            ''  => '',                     # turn off ordering
            na  => sub{ $_[0] < $_[1] },   # number ascending
            nd  => sub{ $_[1] < $_[0] },   # number descending
            sa  => sub{ $_[0] lt $_[1] },  # string ascending
            sd  => sub{ $_[1] lt $_[0] },  # string descending
            sna => sub{                    # either ascending
                looks_like_number($_[0])&&looks_like_number($_[1])?
                $_[0] < $_[1]: $_[0] lt $_[1] },
            snd => sub{                    # either descending
                looks_like_number($_[0])&&looks_like_number($_[1])?
                $_[1] < $_[0]: $_[1] lt $_[0] },
            }->{ $spec };
        croak "\$spec($spec) not recognized" unless defined $order;
    }
    return $order;
}

#---------------------------------------------------------------------

=head1 OBJECT METHODS

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

*pairs_set = \&set;
sub set {
    my( $self, $key, $value, $pos ) = @_;
    return unless defined $key;

    # you can give a $pos to change a member including changing its key

    # pos   found    action
    # ----- -----    ------
    # def   def   -> set key/value at pos
    # def   undef -> set key/value at pos
    # undef def   -> set key/value at found
    # undef undef -> add key/value (according to order)

    my $elem = { $key => $value };
    if( defined $pos )   {
        croak "\$pos($pos) too large" if $pos > $#$self+1;
        $self->[ $pos ] = $elem;
        return $value;
    }

    my $found = pairs_get_pos( $self, $key );
    if( defined $found ) { $self->[ $found ] = $elem }
    else                 { pairs_add_ordered( $self, $key, $value ) }

    $value;  # returned
}

#---------------------------------------------------------------------

=head2 $pairs->get_values( [$key[, @keys]] );

Get a value or values.

Regardless of parameters, if the object is empty, undef is returned in
scalar context, an empty list in list context.

If no parameters, gets all the values.  In scalar context, gives
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

*pairs_get_values = \&get_values;
sub get_values {
    my( $self, @keys ) = @_;
    return unless @$self;

    my @ret;
    if( @keys ) {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    my ( $value ) = values %$href;
                    push @ret, $value;
                    last;
                }
            }
        }
    }
    else {
        for my $href ( @$self ) {
            my ( $value ) = values %$href;
            push @ret, $value;
        }
    }
    return @ret;
}

#---------------------------------------------------------------------

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

*pairs_add = \&add;
sub add {
    my( $self, $key, $value, $pos ) = @_;
    return unless defined $key;

    my $elem = { $key => $value };
    if( defined $pos ) {
        croak "\$pos($pos) too large" if $pos > $#$self+1;
        splice @$self, $pos, 0, $elem;
    }
    else {
        pairs_add_ordered( $self, $key, $value );
    }

    $value;  # returned
}

#---------------------------------------------------------------------

=head2 pairs_add_ordered( $pairs, $key => $value );

Private routine used by C<set()> and C<add()>; should not be called
directly.

Accepts C<$key> and C<$value>.

Adds a new key/value pair to the end or merged according to the
defined C<order()>.

Has no defined return value.

=cut

sub pairs_add_ordered {
    my( $self, $key, $value ) = @_;
    my $elem = { $key => $value };

    unless( $order ) { push @$self, $elem; return }

    # optimization for when members are added in order
    if( @$self ) {
        my ( $key2 ) = keys %{$self->[-1]};  # at the end
        unless( $order->( $key, $key2 ) ) {
            push @$self, $elem;
            return;
        }
    }

    # else start comparing at the beginning
    for my $i ( 0 .. $#$self ) {
        my ( $key2 ) = keys %{$self->[ $i ]};
        if( $order->( $key, $key2 ) ) {  # XXX can we memoize $key in $order->()?
            splice @$self, $i, 0, $elem;
            return;
        }
    }

    push @$self, $elem;
}

#---------------------------------------------------------------------

=head2 $pairs->get_pos( $key );

Gets position(s) where a key is found.

Accepts one key (any extras are silently ignored).  

In list context, returns a list of positions where the key is found.

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

*pairs_get_pos = \&get_pos;
sub get_pos {
    my( $self, $wantkey ) = @_;
    return unless $wantkey;
    return unless @$self;
    my @ret;
    for my $i ( 0 .. $#$self ) {
        my ( $key ) = keys %{$self->[ $i ]};
        if( $key eq $wantkey ) {
            push @ret, $i;
        }
    }
    return unless @ret;
    return @ret if wantarray;
    return $ret[0] if @ret == 1;
    \@ret;  # returned
}

#---------------------------------------------------------------------

=head2 $pairs->get_pos_hash( [@keys] );

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

Returns C<undef/()> if object is empty.

=cut

*pairs_get_pos_hash = \&get_pos_hash;
sub get_pos_hash {
    my( $self, @keys ) = @_;
    return unless @$self;
    my %ret;
    if( @keys ) {
        for my $i ( 0 .. $#$self ) {
            my ( $key ) = keys %{$self->[ $i ]};
            for ( @keys ) {
                if( $key eq $_ ) {
                    push @{$ret{ $key }}, $i;
                    last;
                }
            }
        }
    }
    else {
        for my $i ( 0 .. $#$self ) {
            my ( $key ) = keys %{$self->[ $i ]};
            push @{$ret{ $key }}, $i;
        }
    }
    return %ret if wantarray;
    \%ret;  # returned
}

#---------------------------------------------------------------------

=head2 $pairs->get_keys( [@keys] );

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

*pairs_get_keys = \&get_keys;
sub get_keys {
    my( $self, @keys ) = @_;
    return unless @$self;
    my @ret;
    if( @keys ) {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    push @ret, $key;
                    last;
                }
            }
        }
    }
    else {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            push @ret, $key;
        }
    }
    @ret;  # returned
}

#---------------------------------------------------------------------

=head2 $pairs->get_array( [@keys] );

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

*pairs_get_array = \&get_array;
sub get_array {
    my( $self, @keys ) = @_;
    return unless @$self;
    my @ret;
    if( @keys ) {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    push @ret, { %$href };
                    last;
                }
            }
        }
    }
    else {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            push @ret, { %$href };
        }
    }
    return wantarray? @ret: [ @ret ];
}

#---------------------------------------------------------------------

=head2 $pairs->exists( $key );

Accepts one key.

Returns true if key is found in object, false if not.

=cut

*pairs_exists = \&exists;
sub exists {
    my( $self, $key ) = @_;
    return unless @$self;
    return defined pairs_get_pos( $self, $key );
}

#---------------------------------------------------------------------

=head2 $pairs->delete( $key[, $pos] );

Accepts one key and an optional position.

If C<$pos> is given and the key at that position equals C<$key>, that
key/value pair will be deleted.  Otherwise, the I<first> key/value
pair that matches C<$key> will be deleted.

If C<$key> occurs multiple times, C<delete()> must be called multiple
times to delete them all.

Returns the value from the deleted pair.

=cut

*pairs_delete = \&delete;
sub delete {
    my( $self, $key, $pos ) = @_;
    return unless defined $key;
    return unless @$self;

    if( defined $pos ) {
        my( $foundkey ) = keys %{$self->[ $pos ]};
        return unless $foundkey eq $key;
    }
    else {
        $pos = pairs_get_pos( $self, $key );
        return unless defined $pos;
    }

    my $value = $self->[ $pos ]{ $key };
    splice @$self, $pos, 1;  # delete it
    $value;  # returned
}

#---------------------------------------------------------------------

=head2 $pairs->clear();

Expects no parameters.  Removes all key/value pairs from the object.

Returns an empty list.

=cut

*pairs_clear = \&clear;
sub clear {
    my( $self ) = @_;
    @$self = ();
}

1;  # 'use module' return value

__END__

=head1 NON-OO STYLE

Pairs, ordered mappings with duplicate keys (as defined here), is an
array of single-key hashes.  It is possible to manipulate a pairs
ordered mapping directly without first blessing it with C<new()>.
Most methods have a corresponding exportable subroutine named with
the prefix, C<pairs_>, e.g., C<pairs_set()>, C<pairs_get_keys()>,
etc.

To call these subroutines, pass the array reference as the first
parameter, e.g., instead of doing C<< $pairs->set( a => 1) >>, do C<<
pairs_set( $pairs, a => 1) >>.

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

=head2 C<new> without C<new()>

To create a pairs ordered mapping from scratch, simply assign an
empty array ref, e.g.,

 my $pairs = [];

=head2 pairs_order( $pairs[, $predefined_ordering | coderef] );

(See C<< Data::Pairs->order() >> above.)

 pairs_order( $pairs, 'na' );   # numeric ascending
 pairs_order( $pairs, 'nd' );   # numeric descending
 pairs_order( $pairs, 'sa' );   # string  ascending
 pairs_order( $pairs, 'sd' );   # string  descending
 pairs_order( $pairs, 'sna' );  # string/numeric ascending
 pairs_order( $pairs, 'snd' );  # string/numeric descending
 pairs_order( $pairs, sub{ int($_[0]/100) < int($_[1]/100) } );  # code

=head2 pairs_set( $pairs, $key => $value[, $pos] );

(See C<< $pairs->set() >> above.)

 my $pairs = [{a=>1},{b=>2}];
 pairs_set( $pairs, c => 3, 0 );  # pairs is now [{c=>3},{b=>2}]

=head2 pairs_get_values( $pairs[, $key[, @keys]] );

(See C<< $pairs->get_values() >> above.)

 my $pairs = [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}];
 my @values  = pairs_get_values( $pairs );  # (1, 2, 3, 4, 5)
 my $howmany = pairs_get_values( $pairs );  # 5
 
 @values  = pairs_get_values( $pairs, 'c', 'b' );  # (2, 3, 4, 5)
 $howmany = pairs_get_values( $pairs, 'c', 'b' );  # 4

 @values  = pairs_get_values( $pairs, 'b' );  # (2, 4, 5)
 $howmany = pairs_get_values( $pairs, 'b' );  # 3
 
=head2 pairs_add( $pairs, $key => $value[, $pos] );

(See C<< $pairs->add() >> above.)

 my $pairs = [{a=>1},{b=>2}];
 pairs_add( $pairs, c => 3, 1 );  # pairs is now [{a=>1},{c=>3},{b=>2}]

=head2 pairs_get_pos( $pairs, $key );

(See C<< $pairs->get_pos() >> above.)

 my $pairs = [{a=>1},{b=>2},{c=>3},{b=>4}];
 my @pos   = pairs_get_pos( $pairs, 'c' );  # (2)
 my $pos   = pairs_get_pos( $pairs, 'c' );  # 2
 @pos   = pairs_get_pos( $pairs, 'b' );  # (1, 3)
 $pos   = pairs_get_pos( $pairs, 'b' );  # [1, 3]

=head2 pairs_get_pos_hash( $pairs[, @keys] );

(See C<< $pairs->get_pos_hash() >> above.)

 my $pairs    = [{a=>1},{b=>2},{c=>3},{b=>4}];
 my %pos      = pairs_get_pos_hash( $pairs, 'c', 'b' );  # %pos      is (b=>[1,3],c=>[2])
 my $pos_href = pairs_get_pos_hash( $pairs, 'c', 'b' );  # $pos_href is {b=>[1,3],c=>[2]}

=head2 pairs_get_keys( $pairs[, @keys] );

(See C<< $pairs->get_keys() >> above.)

 my $pairs    = [{a=>1},{b=>2},{c=>3},{b=>4},{b=>5}];
 my @keys    = pairs_get_keys( $pairs );  # @keys is (a, b, c, b, b)
 my $howmany = pairs_get_keys( $pairs );  # $howmany is 5

 @keys    = pairs_get_keys( $pairs, 'c', 'b', 'A' );  # @keys is (b, c, b, b)
 $howmany = pairs_get_keys( $pairs, 'c', 'b', 'A' );  # $howmany is 4

=head2 pairs_get_array( $pairs[, @keys] );

(See C<< $pairs->get_array() >> above.)

 my $pairs    = [{a=>1},{b=>2},{c=>3}];
 my @array   = pairs_get_array( $pairs );  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = pairs_get_array( $pairs );  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

 @array = pairs_get_array( $pairs, 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = pairs_get_array( $pairs, 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

=head2 pairs_exists( $pairs, $key );

(See C<< $pairs->exists() >> above.)

 my $bool = pairs_exists( $pairs, 'a' );

=head2 pairs_delete( $pairs, $key );

(See C<< $pairs->delete() >> above.)

 pairs_delete( $pairs, 'a' );

=head2 pairs_clear( $pairs );

(See C<< $pairs->clear() >> above.)

 pairs_clear( $pairs );

Or simply:

 @$pairs = ();

=cut

=head1 SEE ALSO

Data::Omap

=over 8

The code in Data::Omap is the basis for that in the Data::Pairs
module.  Data::Omap also operates on an ordered hash, but does not
allow duplicate keys.

=back

Tie::IxHash

=over 8

Use Tie::IxHash if what you need is an ordered hash in general.  The
Data::Pairs module does repeat many of Tie::IxHash's features.  What
differs is that it operates directly on a specific type of data
structure, and allows duplicate keys.

=back

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

