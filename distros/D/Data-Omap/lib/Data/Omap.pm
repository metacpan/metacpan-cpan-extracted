#---------------------------------------------------------------------
  package Data::Omap;
#---------------------------------------------------------------------

=head1 NAME

Data::Omap - Perl module to implement ordered mappings

=head1 SYNOPSIS

 use Data::Omap;
 
 # Simple OO style
 
 my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );
 
 $omap->set( a => 0 );
 $omap->add( b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
 my $value  = $omap->get_values( 'c' );    # 3
 my @keys   = $omap->get_keys();           # (a, b, b2, c)
 my @values = $omap->get_values();         # (0, 2, 2.5, 3)
 my @subset = $omap->get_values(qw(c b));  # (2, 3) (values are data-ordered)
 
 # Tied style
 
 my %omap;
 # recommend saving an object reference, too.
 my $omap = tie %omap, 'Data::Omap', [{a=>1},{b=>2},{c=>3}];
 
 $omap{ a } = 0;
 $omap->add( b2 => 2.5, 2 );  # there's no tied hash equivalent
 
 my $value  = $omap{ c };
 my @keys   = keys %omap;      # $omap->get_keys() is faster 
 my @values = values %omap;    # $omap->get_values() is faster
 my @slice  = @omap{qw(c b)};  # (3, 2) (slice values are parameter-ordered)

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

=head1 DESCRIPTION

This module implements the Data::Omap class.  Objects in this class
are ordered mappings, i.e., they are hashes in which the key/value
pairs are in order. This is defined in shorthand as C<!!omap> in the
YAML tag repository:  http://yaml.org/type/omap.html.

The keys in Data::Omap objects are unique, like regular hashes.

A closely related class, Data::Pairs, implements the YAML C<!!pairs>
data type, http://yaml.org/type/pairs.html.  Data::Pairs objects are
also ordered sequences of key:value pairs but they allow duplicate
keys.

While ordered mappings are in order, they are not necessarily in a
I<particular> order, i.e., they are not necessarily sorted in any
way.  They simply have a predictable set order (unlike regular hashes
whose key/value pairs are in no set order).

By default, Data::Omap will add new key/value pairs at the end of the
mapping, but you may request that they be merged in a particular
order with the C<order()> class method.

However, even though Data::Omap will honor the requested order, it
will not attempt to I<keep> the mapping in that order.  By passing
position values to the C<set()> and C<add()> methods, you may insert
new pairs anywhere in the mapping and Data::Omap will not complain.

=head1 IMPLEMENTATION

Normally, the underlying structure of an OO object is encapsulated
and not directly accessible (when you play nice). One key
implementation detail of Data::Omap is the desire that the underlying
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

Data::Omap version 0.06

=cut

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.06';

use Scalar::Util qw( reftype looks_like_number );
use Carp;
use Exporter qw( import );
our @EXPORT_OK = qw(
    omap_set    omap_get_values omap_get_keys
    omap_exists omap_delete     omap_clear 
    omap_add    omap_order      omap_get_pos
    omap_get_pos_hash omap_get_array
    omap_is_valid     omap_errstr
    );
our %EXPORT_TAGS = (
    STD => [qw( 
    omap_set    omap_get_values omap_get_keys
    omap_exists omap_delete     omap_clear )],
    ALL => [qw(
    omap_set    omap_get_values omap_get_keys
    omap_exists omap_delete     omap_clear 
    omap_add    omap_order      omap_get_pos
    omap_get_pos_hash omap_get_array
    omap_is_valid     omap_errstr )],
    );

my $order;   # package global, see order() accessor
our $errstr; # error message

#---------------------------------------------------------------------

=head1 CLASS METHODS

=head2 Data::Omap->new();

Constructs a new Data::Omap object.

Accepts array ref containing single-key hash refs, e.g.,

 my $omap = Data::Omap->new( [ { a => 1 }, { b => 2 }, { c => 3 } ] );

When provided, this data will be loaded into the object.

Returns a reference to the Data::Omap object.

=cut

sub new {
    my( $class, $aref ) = @_;
    return bless [], $class unless $aref;

    croak omap_errstr() unless omap_is_valid( $aref );
    bless $aref, $class;
}

sub omap_is_valid {
    my( $aref ) = @_;
    unless( $aref and ref( $aref ) and reftype( $aref ) eq 'ARRAY' ) {
        $errstr = "Invalid omap: Not an array reference";
        return;
    }
    my %seen;
    for my $href ( @$aref ) {
        unless( ref( $href ) eq 'HASH' ) {
            $errstr = "Invalid omap: Not a hash reference";
            return;
        }
        my @keys = keys %$href;
        if( @keys > 1 ) {
            $errstr = "Invalid omap: Not a single-key hash";
            return;
        }
        if( $seen{ $keys[0] }++ ) {
            $errstr = "Invalid omap: Duplicate key: '$keys[0]'";
            return;
        }
    }
    return 1;  # is valid
}

sub omap_errstr {
    my $msg = $errstr;
    $errstr = "";
    $msg;  # returned
}

#---------------------------------------------------------------------

=head2 Data::Omap->order( [$predefined_ordering | coderef] );

When ordering is ON, new key/value pairs will be added in the
specified order.  When ordering is OFF (the default), new pairs
will be added to the end of the mapping.

When called with no parameters, C<order()> returns the current code
reference (if ordering is ON) or a false value (if ordering is OFF);
it does not change the ordering.

 Data::Omap->order();         # leaves ordering as is

When called with the null string, C<''>, ordering is turned OFF.

 Data::Omap->order( '' );     # turn ordering OFF (the default)

Otherwise, accepts the predefined orderings: 'na', 'nd', 'sa', 'sd',
'sna', and 'snd', or a custom code reference, e.g.

 Data::Omap->order( 'na' );   # numeric ascending
 Data::Omap->order( 'nd' );   # numeric descending
 Data::Omap->order( 'sa' );   # string  ascending
 Data::Omap->order( 'sd' );   # string  descending
 Data::Omap->order( 'sna' );  # string/numeric ascending
 Data::Omap->order( 'snd' );  # string/numeric descending
 Data::Omap->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # code

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

*omap_order = \&order;
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

=head2 $omap->set( $key => $value[, $pos] );

Sets the value if C<$key> exists; adds a new key/value pair if not.

Accepts C<$key>, C<$value>, and optionally, C<$pos>.

If C<$pos> is given, and there is a key/value pair at that position,
it will be set to C<$key> and C<$value>, I<even if the key is
different>.  For example:

 my $omap = Data::Omap->new( [{a=>1},{b=>2}] );
 $omap->set( c => 3, 0 );  # omap is now [{c=>3},{b=>2}]

(As implied by the example, positions start at 0.)

If C<$pos> is given, and there isn't a pair there, a new pair is
added there (perhaps overriding a defined ordering).

If C<$pos> is not given, the key will be located and if found,
the value set. If the key is not found, a new pair is added to the
end or merged according to the defined C<order()>.

Note that C<set()> will croak if a duplicate key would result.  This
would only happen if C<$pos> is given and the C<$key> is found--but
not at that position.

Returns C<$value> (as a nod toward $hash{$key}=$value, which
"returns" $value).

=cut

*omap_set = \&set;
sub set {
    my( $self, $key, $value, $pos ) = @_;
    return unless defined $key;

    # you can give a $pos to change a member including changing its key
    # ... but not if doing so would duplicate a key in the object

    # pos   found    action
    # ----- -----    ------
    # def   def   -> set key/value at pos (if pos == found)
    # def   undef -> set key/value at pos
    # undef def   -> set key/value at found
    # undef undef -> add key/value (according to order)

    my $found = omap_get_pos( $self, $key );
    my $elem = { $key => $value };

    if( defined $pos and defined $found ) {
        croak "\$pos($pos) too large" if $pos > $#$self+1;
        croak "\$key($key) found, but not at \$pos($pos): duplicate keys not allowed"
            if $found != $pos;
        $self->[ $pos ] = $elem;  # pos == found
    }
    elsif( defined $pos )   {
        croak "\$pos($pos) too large" if $pos > $#$self+1;
        $self->[ $pos ]   = $elem;
    }
    elsif( defined $found ) { $self->[ $found ] = $elem }
    else                    { omap_add_ordered( $self, $key, $value ) }

    $value;  # returned
}

#---------------------------------------------------------------------

=head2 $omap->get_values( [$key[, @keys]] );

Get a value or values.

Regardless of parameters, if the object is empty, undef is returned in
scalar context, an empty list in list context.

If no parameters, gets all the values.  In scalar context, gives
number of values in the object.

 my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );
 my @values  = $omap->get_values();  # (1, 2, 3)
 my $howmany = $omap->get_values();  # 3

If one key is given, that value is returned--regardless of
context--or if not found, C<undef>.

 @values   = $omap->get_values( 'b' );  # (2)
 my $value = $omap->get_values( 'b' );  # 2

If multiple keys given, their values are returned in the order found
in the object, not the order of the given keys (unlike hash slices
which return values in the order requested).

In scalar context, gives the number of values found, e.g.,

 @values  = $omap->get_values( 'c', 'b', 'A' );  # (2, 3)
 $howmany = $omap->get_values( 'c', 'b', 'A' );  # 2

The hash slice behavior is available if you use C<tie>, see below.

=cut

*omap_get_values = \&get_values;
sub get_values {
    my( $self, @keys ) = @_;
    return unless @$self;

    if( @keys == 1 ) {  # most common case
        my $wantkey = $keys[0];
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            if( $key eq $wantkey ) {
                my ( $value ) = values %$href;
                return $value;
            }
        }
        return;  # key not found
    }

    elsif( @keys ) {
        my @ret;
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
        return @ret;
    }

    else {
        my @ret;
        for my $href ( @$self ) {
            my ( $value ) = values %$href;
            push @ret, $value;
        }
        return @ret;
    }
}

#---------------------------------------------------------------------

=head2 $omap->add( $key => $value[, $pos] );

Adds a key/value pair to the object.

Accepts C<$key>, C<$value>, and optionally, C<$pos>.

If C<$pos> is given, the key/value pair will be added (inserted)
there (possibly overriding a defined order), e.g.,

 my $omap = Data::Omap->new( [{a=>1},{b=>2}] );
 $omap->add( c => 3, 1 );  # omap is now [{a=>1},{c=>3},{b=>2}]

(Positions start at 0.)

If C<$pos> is not given, a new pair is added to the end or merged
according to the defined C<order()>.

Note that C<add()> will croak if a duplicate key would result, i.e.,
if the key being added is already in the object.

Returns C<$value>.

=cut

*omap_add = \&add;
sub add {
    my( $self, $key, $value, $pos ) = @_;
    return unless defined $key;

    my $found = omap_get_pos( $self, $key );
    croak "\$key($key) found: duplicate keys not allowed" if defined $found;

    my $elem = { $key => $value };
    if( defined $pos ) {
        croak "\$pos($pos) too large" if $pos > $#$self+1;
        splice @$self, $pos, 0, $elem;
    }
    else {
        omap_add_ordered( $self, $key, $value );
    }

    $value;  # returned
}

#---------------------------------------------------------------------

=head2 omap_add_ordered( $omap, $key => $value );

Private routine used by C<set()> and C<add()>.

Accepts C<$key> and C<$value>.

Adds a new key/value pair to the end or merged according to the
defined C<order()>.

This routine should not be called directly, because it does not
check for duplicates.

Has no defined return value.

=cut

sub omap_add_ordered {
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

=head2 $omap->get_pos( $key );

Gets position where a key is found.

Accepts one key (any extras are silently ignored).  

Returns the position or undef (if key not found), regardless of context, e.g.,

 my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );
 my @pos  = $omap->get_pos( 'b' );  # (1)
 my $pos  = $omap->get_pos( 'b' );  # 1

Returns C<undef/()> if no key given or object is empty.

=cut

*omap_get_pos = \&get_pos;
sub get_pos {
    my( $self, $wantkey ) = @_;
    return unless $wantkey;
    return unless @$self;
    for my $i ( 0 .. $#$self ) {
        my ( $key ) = keys %{$self->[ $i ]};
        if( $key eq $wantkey ) {
            return $i;
        }
    }
    return;  # key not found
}

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

Returns C<undef/()> if object is empty.

=cut

*omap_get_pos_hash = \&get_pos_hash;
sub get_pos_hash {
    my( $self, @keys ) = @_;
    return unless @$self;
    my %ret;
    if( @keys ) {
        for my $i ( 0 .. $#$self ) {
            my ( $key ) = keys %{$self->[ $i ]};
            for ( @keys ) {
                if( $key eq $_ ) {
                    $ret{ $key } = $i;
                    last;
                }
            }
        }
    }
    else {
        for my $i ( 0 .. $#$self ) {
            my ( $key ) = keys %{$self->[ $i ]};
            $ret{ $key } = $i;
        }
    }
    return %ret if wantarray;
    \%ret;  # returned
}

#---------------------------------------------------------------------

=head2 $omap->get_keys( @keys );

Gets keys.

Accepts zero or more keys.  If no keys are given, returns all the
keys in the object (list context) or the number of keys (scalar
context), e.g.,

 my $omap    = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );
 my @keys    = $omap->get_keys();  # @keys is (a, b, c)
 my $howmany = $omap->get_keys();  # $howmany is 3

If one or more keys are given, returns all the keys that are found
(list) or the number found (scalar).  Keys returned are listed in the
order found in the object, e.g.,

 @keys    = $omap->get_keys( 'c', 'b', 'A' );  # @keys is (b, c)
 $howmany = $omap->get_keys( 'c', 'b', 'A' );  # $howmany is 2

=cut

*omap_get_keys = \&get_keys;
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

=head2 $omap->get_array( @keys );

Gets an array of key/value pairs.

Accepts zero or more keys.  If no keys are given, returns a list of
all the key/value pairs in the object (list context) or an array
reference to that list (scalar context), e.g.,

 my $omap    = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );
 my @array   = $omap->get_array();  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = $omap->get_array();  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

If one or more keys are given, returns a list of key/value pairs for
all the keys that are found (list) or an aref to that list (scalar).
Pairs returned are in the order found in the object, e.g.,

 @array = $omap->get_array( 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = $omap->get_array( 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

Note, conceivably this method might be used to make a copy
(unblessed) of the object, but it would not be a deep copy (if values
are references, the references would be copied, not the referents).

=cut

*omap_get_array = \&get_array;
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

=head2 $omap->firstkey();

Expects no parameters.  Returns the first key in the object (or undef
if object is empty).

This routine supports the tied hash FIRSTKEY method.

=cut

sub firstkey {
    my( $self ) = @_;
    return unless @$self;
    my ( $firstkey ) = keys %{$self->[0]};
    $firstkey;  # returned
}

#---------------------------------------------------------------------

=head2 $omap->nextkey( $lastkey );

Accepts one parameter, the last key gotten from FIRSTKEY or NEXTKEY.

Returns the next key in the object.

This routine supports the tied hash NEXTKEY method.

=cut

# XXX want a more efficient solution, always loops through the array

sub nextkey {
    my( $self, $lastkey ) = @_;
    return unless @$self;
    for my $i ( 0 .. $#$self ) {
        my ( $key ) = keys %{$self->[ $i ]};
        if( $key eq $lastkey ) {
            return unless defined $self->[ $i+1 ];
            my ( $nextkey ) = keys %{$self->[ $i+1 ]};
            return $nextkey;
        }
    }
}

#---------------------------------------------------------------------

=head2 $omap->exists( $key );

Accepts one key.

Returns true if key is found in object, false if not.

This routine supports the tied hash EXISTS method, but may reasonably
be called directly, too.

=cut

*omap_exists = \&exists;
sub exists {
    my( $self, $key ) = @_;
    return unless @$self;
    return defined omap_get_pos( $self, $key );
}

#---------------------------------------------------------------------

=head2 $omap->delete( $key );

Accepts one key.  If key is found, removes the key/value pair from
the object.

Returns the value from the deleted pair.

This routine supports the tied hash DELETE method, but may be called
directly, too.

=cut

*omap_delete = \&delete;
sub delete {
    my( $self, $key ) = @_;
    return unless defined $key;
    return unless @$self;

    my $found = omap_get_pos( $self, $key );
    return unless defined $found;

    my $value = $self->[ $found ]->{ $key };
    splice @$self, $found, 1;  # delete it

    $value;  # returned
}

#---------------------------------------------------------------------

=head2 $omap->clear();

Expects no parameters.  Removes all key/value pairs from the object.

Returns an empty list.

This routine supports the tied hash CLEAR method, but may be called
directly, too.

=cut

*omap_clear = \&clear;
sub clear {
    my( $self ) = @_;
    @$self = ();
}

#---------------------------------------------------------------------
# perltie methods
#---------------------------------------------------------------------

# XXX Because of the inefficiencies in nextkey(), keys %hash and
# values %hash # may be very slow.
# Consider using (tied %hash)->get_keys() or ->get_values() instead

# TIEHASH classname, LIST
# This is the constructor for the class. That means it is expected to
# return a blessed reference through which the new object (probably but
# not necessarily an anonymous hash) will be accessed.

sub TIEHASH {
    my $class = shift;
    $class->new( @_ );
}

#---------------------------------------------------------------------
# FETCH this, key
# This method will be triggered every time an element in the tied hash
# is accessed (read). 

sub FETCH {
    my $self = shift;
    $self->get_values( @_ );
}

#---------------------------------------------------------------------
# STORE this, key, value
# This method will be triggered every time an element in the tied hash
# is set (written). 

sub STORE {
    my $self = shift;
    $self->set( @_ );
}

#---------------------------------------------------------------------
# DELETE this, key
# This method is triggered when we remove an element from the hash,
# typically by using the delete() function.
# If you want to emulate the normal behavior of delete(), you should
# return whatever FETCH would have returned for this key. 

sub DELETE {
    my $self = shift;
    $self->delete( @_ );
}

#---------------------------------------------------------------------
# CLEAR this
# This method is triggered when the whole hash is to be cleared,
# usually by assigning the empty list to it.

sub CLEAR {
    my $self = shift;
    $self->clear();
}

#---------------------------------------------------------------------
# EXISTS this, key
# This method is triggered when the user uses the exists() function
# on a particular hash.

sub EXISTS {
    my $self = shift;
    $self->exists( @_ );
}

#---------------------------------------------------------------------
# FIRSTKEY this
# This method will be triggered when the user is going to iterate
# through the hash, such as via a keys() or each() call.

sub FIRSTKEY {
    my $self = shift;
    $self->firstkey();
}

#---------------------------------------------------------------------
# NEXTKEY this, lastkey
# This method gets triggered during a keys() or each() iteration.
# It has a second argument which is the last key that had been accessed.

sub NEXTKEY {
    my $self = shift;
    $self->nextkey( @_ );
}

#---------------------------------------------------------------------
# SCALAR this
# This is called when the hash is evaluated in scalar context.
# In order to mimic the behavior of untied hashes, this method should
# return a false value when the tied hash is considered empty.

sub SCALAR {
    my $self = shift;
    $self->get_keys();  # number of keys or undef (scalar context)
}

#---------------------------------------------------------------------
# UNTIE this
# This is called when untie occurs. See "The untie Gotcha".

# sub UNTIE {
# }

#---------------------------------------------------------------------
# DESTROY this
# This method is triggered when a tied hash is about to go out of scope.

# sub DESTROY {
# }

#---------------------------------------------------------------------

1;  # 'use module' return value

__END__

=head1 NON-OO STYLE

An ordered mapping (as defined here) is an array of single-key
hashes.  It is possible to manipulate an ordered mapping directly
without first blessing it with C<new()>.  Most methods have a
corresponding exportable subroutine named with the prefix, C<omap_>,
e.g., C<omap_set()>, C<omap_get_keys()>, etc.

To call these subroutines, pass the array reference as the first
parameter, e.g., instead of doing C<< $omap->set( a => 1) >>, do C<<
omap_set( $omap, a => 1) >>.

=head2 Exporting

Nothing is exported by default.  All subroutines may be exported
using C<:ALL>, e.g.,

 use Data::Omap ':ALL';

They are shown below.

A subset may be exported using C<:STD>, e.g.,

 use Data::Omap ':STD';

This subset includes
C<omap_set()>
C<omap_get_values()>
C<omap_get_keys()>
C<omap_exists()>
C<omap_delete()>
C<omap_clear()>

=head2 C<new> without C<new()>

To create an ordered mapping from scratch, simply assign an empty
array ref, e.g.,

 my $omap = [];

=head2 omap_order( $omap[, $predefined_ordering | coderef] );

(See C<< Data::Omap->order() >> above.)

 omap_order( $omap, 'na' );   # numeric ascending
 omap_order( $omap, 'nd' );   # numeric descending
 omap_order( $omap, 'sa' );   # string  ascending
 omap_order( $omap, 'sd' );   # string  descending
 omap_order( $omap, 'sna' );  # string/numeric ascending
 omap_order( $omap, 'snd' );  # string/numeric descending
 omap_order( $omap, sub{ int($_[0]/100) < int($_[1]/100) } );  # code

=head2 omap_set( $omap, $key => $value[, $pos] );

(See C<< $omap->set() >> above.)

 my $omap = [{a=>1},{b=>2}];
 omap_set( $omap, c => 3, 0 );  # omap is now [{c=>3},{b=>2}]

=head2 omap_get_values( $omap[, $key[, @keys]] );

(See C<< $omap->get_values() >> above.)

 my $omap = [{a=>1},{b=>2},{c=>3}];
 my @values  = omap_get_values( $omap );  # (1, 2, 3)
 my $howmany = omap_get_values( $omap );  # 3
 
 @values   = omap_get_values( $omap, 'b' );  # (2)
 my $value = omap_get_values( $omap, 'b' );  # 2
 
 @values  = omap_get_values( $omap, 'c', 'b', 'A' );  # (2, 3)
 $howmany = omap_get_values( $omap, 'c', 'b', 'A' );  # 2

=head2 omap_add( $omap, $key => $value[, $pos] );

(See C<< $omap->add() >> above.)

 my $omap = [{a=>1},{b=>2}];
 omap_add( $omap, c => 3, 1 );  # omap is now [{a=>1},{c=>3},{b=>2}]

=head2 omap_get_pos( $omap, $key );

(See C<< $omap->get_pos() >> above.)

 my $omap = [{a=>1},{b=>2},{c=>3}];
 my @pos  = omap_get_pos( $omap, 'b' );  # (1)
 my $pos  = omap_get_pos( $omap, 'b' );  # 1

=head2 omap_get_pos_hash( $omap[, @keys] );

(See C<< $omap->get_pos_hash() >> above.)

 my $omap     = [{a=>1},{b=>2},{c=>3}];
 my %pos      = omap_get_pos_hash( $omap, 'c', 'b' ); # %pos      is (b=>1,c=>2)
 my $pos_href = omap_get_pos_hash( $omap, 'c', 'b' ); # $pos_href is {b=>1,c=>2}

=head2 omap_get_keys( $omap[, @keys] );

(See C<< $omap->get_keys() >> above.)

 my $omap    = [{a=>1},{b=>2},{c=>3}];
 my @keys    = omap_get_keys( $omap );  # @keys is (a, b, c)
 my $howmany = omap_get_keys( $omap );  # $howmany is 3

 @keys    = omap_get_keys( $omap, 'c', 'b', 'A' );  # @keys is (b, c)
 $howmany = omap_get_keys( $omap, 'c', 'b', 'A' );  # $howmany is 2

=head2 omap_get_array( $omap[, @keys] );

(See C<< $omap->get_array() >> above.)

 my $omap    = [{a=>1},{b=>2},{c=>3}];
 my @array   = omap_get_array( $omap );  # @array is ({a=>1}, {b=>2}, {c=>3})
 my $aref    = omap_get_array( $omap );  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

 @array = omap_get_array( $omap, 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})
 $aref  = omap_get_array( $omap, 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

=head2 omap_exists( $omap, $key );

(See C<< $omap->exists() >> above.)

 my $bool = omap_exists( $omap, 'a' );

=head2 omap_delete( $omap, $key );

(See C<< $omap->delete() >> above.)

 omap_delete( $omap, 'a' );

=head2 omap_clear( $omap );

(See C<< $omap->clear() >> above.)

 omap_clear( $omap );

Or simply:

 @$omap = ();

=cut

=head1 SEE ALSO

Tie::IxHash

=over 8

Use Tie::IxHash if what you need is an ordered hash in general.  The
Data::Omap module does repeat many of Tie::IxHash's features.  What
differs is that it operates directly on a specific type of data
structure.  Whether this pans out in the long run remains to be seen.

=back

Data::Pairs

=over 8

The code in Data::Omap is the basis for that in the Data::Pairs module.
Data::Pairs also operates on an ordered hash, but allows duplicate keys.

=back

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

