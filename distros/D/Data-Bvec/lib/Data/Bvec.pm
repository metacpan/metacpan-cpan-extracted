#---------------------------------------------------------------------
package Data::Bvec;

use 5.008003;
use strict;
use warnings;
use Carp;
use Math::Int2Base qw( int2base base2int );

#---------------------------------------------------------------------

=head1 NAME

Data::Bvec - a module to manipulate integer arrays as bit vectors and
"compressed bit strings" (using a simple RLE).

=head1 VERSION

VERSION: 1.01

=cut

our $VERSION;

$VERSION = '1.01';

=head1 SYNOPSIS

    use Data::Bvec;

    my $bv = Data::Bvec::->new( nums=>[1,2,3] );

    my $vec  = $bv->get_bvec();  # 01110000
    my $bstr = $bv->get_bstr();  # '-134'
    my $nums = $bv->get_nums();  # [1,2,3]

    ----

    use Data::Bvec qw( :all );

    my $vec  = num2bit( [1,2,3] );                # 01110000
    set_bit( $vec, 4, 1 );                        # 01111000
    my $bstr = compress bit2str $vec;             # '-143'
    my $nums = bit2num str2bit uncompress $bstr;  # [1,2,3,4]

=head1 DESCRIPTION/DISCUSSION

This module encapsulates some simple routines for manipulating Perl bit
vectors (putting values in; getting values out), but its main goal is
to implement a simple run-length encoding scheme for bit vectors that
compresses them into relatively human-readable and flat-file-storable
strings.

My use case was wanting to prototype a data indexing system, and I
wanted to ease debugging by plopping the bitstrings in a flat file that
I could examine directly.  (Each bit in a vector represents a record in
the database -- true or false whether the term is in that record in the
field being indexed.)  It has worked well enough that I haven't felt
the need to change how the bitstrings are stored (just where they're
stored).

The initial version of the module used a different set of base-62
digits.  In writing Math::Int2Base, I decided to normalize all the
bases from 2 to 62 to use 0-9,A-Z,a-z.  It makes the numbers sort
correctly (ascii-betically == numerically), and it let me say that A
base-16 == A base-36 == A base-62.

So now I'm rewriting this module to use those base conversion routines.

=head1 EXPORTS

Nothing is exported by default.  The following may be exported
individually; all of them may be exported using the C<:all> tag:

    - set_bit
    - howmany
    - bit2str
    - str2bit
    - bit2num
    - num2bit
    - compress
    - uncompress

Examples:

 use Data::Bvec qw( :all );
 use Data::Bvec qw( bit2str str2bit compress uncompress );

However, if you only use the object methods, nothing would need to be
exported.  See below.

=cut

our ( @ISA, @EXPORT_OK, %EXPORT_TAGS );
BEGIN {
    use Exporter;
    @ISA = qw( Exporter );
    @EXPORT_OK = qw(
        set_bit  howmany
        bit2str  str2bit
        bit2num  num2bit
        compress uncompress
        );
    %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );
}


#---------------------------------------------------------------------

=head1 SUBROUTINES

=head2 set_bit( $vec, $num, $zero_or_one )

This is a shallow wrapper around Perl's vec() that simply provides
the third parameter (1) to that routine that says we're working with
a bit vector.

Normally returns $num, if you care.

=head3 Parameters:

=head4 $vec

A Perl bit vector stored in the scalar.

=head4 $num

The number whose bit you want to target in the bit vector.

=head4 $zero_or_one

The value you want to set the bit to: 0 or 1.  If not defined,
1 is assumed.


Examples:

    my $vec = "";  # empty vector

    set_bit $vec, 1, 1; # 01000000
    set_bit $vec, 2, 1; # 01100000
    set_bit $vec, 3;    # 01110000
    set_bit $vec, 1, 0; # 00110000

=cut

sub set_bit {
    if( defined $_[2] ) { vec( $_[0], $_[1], 1 ) = $_[2] }
    else                { vec( $_[0], $_[1], 1 ) = 1     }
}

#---------------------------------------------------------------------

=head2 bit2str( $vec )

This routine is a shallow wrapper around unpack() that unpacks a bit
vector into a string of '0's and '1's, in preparation for compression.

=head3 Parameters:

=head4 $vec

A Perl bit vector.

Example:

    my $vec = "";
    set_bit $vec, 4, 1;      #  00001000
    my $str = bit2str $vec;  # '00001000'

=cut

sub bit2str { unpack "b*", $_[0] }

#---------------------------------------------------------------------

=head2 str2bit( $str )

This routine is a shallow wrapper around pack() that packs a string
of '0's and '1's (following uncompression) into a bit vector.

=head3 Parameters:

=head4 $str

A string of '0's and '1's, e.g., "00001000".

Example:

    my $vec = str2bit '00001000';

=cut

sub str2bit { pack "b*", $_[0] }

#---------------------------------------------------------------------

=head2 num2bit( \@integers )

This routine accepts an array ref of integers and returns a bit
vector with those integer's bits turned on.

=head3 Parameters:

=head4 \@integers

A reference to an array of integers.

Examples:

    my $vec = num2bit [1,2,3];  # 01110000
    my $vec = num2bit [3,2,1];  # 01110000

The second example is intended to make clear that the order of the
integers in the array is not retained (for obvious reasons), and
calling bit2num( $vec ) will always return the integers in ascending
order (see bit2num() below).

=cut

sub num2bit {
    my $bvec = "";
    vec( $bvec, $_, 1 ) = 1 for @{$_[0]};
    $bvec;  # returned
}

#---------------------------------------------------------------------

=head2 bit2num( $vec, $beg, $cnt )

This routine accepts a bit vector and returns an array of integers
represented by the 1 bits.

The parameters $beg and $cnt are to support retrieving subsets of
integers from a large vector -- in essence, to support "paging" through
the set.

In scalar context, returns a reference to the array.

=head3 Parameters:

=head4 $vec

A bit vector.

=head4 $beg

The first integer (where the bit is 1) to return.  Unlike array
subscripts, the $beg positions start with 1, not 0.

=head4 $cnt

The maximum number of integers (including the first) to return.

Examples:

    #                   0----+----1----+----2----+----3-
    my $vec  = str2bit '01110011110001111100001111110001';

    my $set1 = bit2num $vec,  1, 5;  # [  1,  2,  3,  6,  7 ]
    my $set2 = bit2num $vec,  6, 5;  # [  8,  9, 13, 14, 15 ]
    my $set3 = bit2num $vec, 11, 5;  # [ 16, 17, 22, 23, 24 ]
    my $set4 = bit2num $vec, 16, 5;  # [ 25, 26, 27, 31     ]

=cut

sub bit2num {
    my( $vec, $beg, $cnt ) = @_;

    my( @num, $count );

    if( $beg ) {

        if( $cnt ) {
            my $end = $beg + $cnt - 1;
            for( my $i = 0; $i < 8 * length $vec; ++$i ) {
                if( vec $vec, $i, 1 and ++$count >= $beg and $count <= $end ) {
                    push @num, $i } }
        }
        else {
            for( my $i = 0; $i < 8 * length $vec; ++$i ) {
                if( vec $vec, $i, 1 and ++$count >= $beg ) {
                    push @num, $i } }
        }

    }
    else {
        for( my $i = 0; $i < 8 * length $vec; ++$i ) {
            push @num, $i if vec $vec, $i, 1 }
    }

    return  @num if wantarray;
    return \@num;

}

#---------------------------------------------------------------------

=head2 compress( $str )

This routine takes a string of '0's and '1's and compresses it using a
simple run-length encoding (RLE).  It returns this "compressed bit
string".

=head3 Parameters:

=head4 $str

A string of '0's and '1's, e.g., "01110".

Note: the length of the string need not be a multiple of 8.

Example:

    my $bstr;
    $bstr = compress '01110000';  # '-134'
    my $str = ('1'x100).('0'x30).('1'x6);
    $bstr = compress $str;        # '+@1cU6'

=head3 Compression Scheme

The compression scheme counts the number of consecutive '0's and '1's
and concatenates that count (in base-62) to the compressed bit string.

If the first bit is '0', the compressed bit string begins with '-'.  If
the first bit is '1', it begins with '+'.  The digit following that
represents that many of those bits.  The next digit represents that
many of the "other" bits, and so on.  (A "digit" matches /[0-9A-Za-z]/.)

So in the first example, '-134' means 1 '0' bit, then 3 '1' bits, then
4 '0' bits, i.e., '01110000'.

The second example includes a 2-digit number, 1c base-62 (100 decimal,
as defined by Math::Int2base).

Any multi-digit number is preceded by a non-digit:

 '@' for a 2-digit number
 '#' for 3 digits
 '$' for 4 digits
 '%' for 5 digits, and
 '^' for 6 digits

(Mnemonic: look above the numbers on a qwerty keyboard.  A 6-digit
number will accommodate 32,590,299,105 consecutive bits.  If you need
more than that, let me know.)

So '+@1cU6' means 1c (100) '1' bits, then U (30) '0' bits, then 6 '1'
bits.

=cut

sub compress {

    # 1st char '-' => 1st bit '0', '+' => '1'
    my( $first_char, @a );
    for( $_[0] ) {
        if( /^0/ ) { $first_char = '-'; @a = /(0*)(1*)/g }
        else       { $first_char = '+'; @a = /(1*)(0*)/g }
    }

    return '' unless @a;

    pop @a while $a[-1] eq '';  # remove trailing nulls

    # return compressed format
    $first_char . join( '',
        map {
            my $chars = int2base( length, 62 );
            ( undef,'','@','#','$','%','^' )[ length $chars ] . $chars;
        } @a );

}

#---------------------------------------------------------------------

=head2 uncompress( $bstr )

This routine uncompresses a compressed bit string (which would have
been compressed by the compress() routine above).

It returns a string of '0's and '1's.  This string will (normally) then
be converted to a bit vector using str2bit() above.

=head3 Parameters:

=head4 $bstr

A compressed bit string (see compress() above).

Example:

    my $bstr = '-134';
    my $str  = uncompress $bstr;  # '01110000'

=cut

sub uncompress {
    my $compressed = shift;

    croak "Undefined" unless defined $compressed;
    my $ret = '';

    # examine first character to determine first bit's value
    my $bit = substr( $compressed, 0, 1 ) eq '+' ? '1' : '0';

    # examine the rest of the characters, expand into 0's & 1's
    for( my $i = 1; $i < length $compressed; ++$i ) {

        my $char = substr( $compressed, $i, 1 );

        # multi-digit number?
        my $len = index '..@#$%^', $char;  # @==2, #==3, etc.
        if( $len > 1 ) {
            $ret .= $bit x (base2int substr( $compressed, $i + 1, $len ), 62);
            $i += $len;
        }
        else {
            $ret .= $bit x (base2int $char, 62);
        }

        $bit = $bit ? '0' : '1';  # toggle between 0/1
    }

    $ret;  # returned
}

#---------------------------------------------------------------------

=head2 howmany( $vec, $zero_or_one )

This routine returns a count of the 0 or 1 bits in a bit vector.

=head3 Parameters:

=head4 $vec

A bit vector.

=head4 $zero_or_one

The value you want a count of: 0 or 1.  Defaults to 1 if not given.

Examples:

    my $vec = str2bit '01010010';
    my $ones_count  = howmany $vec;     # 3
    my $zeros_count = howmany $vec, 0;  # 5

Note that howmany( $vec, 0 ) will include trailing zero bits.

=cut

sub howmany {
    my( $bvec, $bitval ) = @_;

    $bitval = 1 unless defined $bitval;

    my $setbits = unpack "%32b*", $bvec;
    return $setbits if $bitval;
    return 8 * length( $bvec ) - $setbits;  # includes trailing 0's
}

#---------------------------------------------------------------------

=head1 METHODS

=head2 new()

This constructs a Data::Bvec object.  Each object represents a single
array of integers stored either as a bit vector, a compressed bit
string, or an array.

=head3 Parameters:

All parameters to new() are named.

=head4 bvec=>$bit_vector

Stores a Perl bit vector in the object.

    my $vec = str2bit '01110011110001111100001111110001';
    my $bv  = Data::Bvec::->new( bvec => $vec );

=head4 bstr=>$compressed_bit_string

Stores a compressed bit string in the object.

    my $bstr = compress bit2str $vec;
    my $bv   = Data::Bvec::->new( bstr => $bstr );

=head4 nums=>\@integers

Stores an array of integers in the object.  The order of the array is
retained when stored.

    my $nums = bit2num $vec;
    my $bv   = Data::Bvec::->new( nums => $nums );

=head4 bvec2nums=>$bit_vector

Accepts a bit vector and stores it as an array of integers (as
$self->{nums}).

    my $bv = Data::Bvec::->new( bvec2nums => $vec );

=head4 nums2bvec=>\@integers

Accepts an array of integers and stores it as a bit vector (as
$self->{bvec}).  The order of the array is not retained.

    my $bv = Data::Bvec::->new( nums2bvec => $nums );

=head4 bvec2bstr=>$bit_vector

Accepts a bit vector and stores it as a compressed bit string (as
$self->{bstr}).

    my $bv = Data::Bvec::->new( bvec2bstr => $vec );

=head4 bstr2bvec=>$compressed_bit_string

Accepts a compressed bit string and stores it as a bit vector (as
$self->{bvec}).

    my $bv = Data::Bvec::->new( bstr2bvec => $bstr );

=head4 bstr2nums=>$compressed_bit_string

Accepts a compressed bit string and stores it as an array of integers
(as $self->{nums}).

    my $bv = Data::Bvec::->new( bstr2nums => $bstr );

=head4 nums2bstr=>\@integers

Accepts an array of integers and stores it as a compressed bit string
(as $self->{bstr}).  The order of the array is not retained.

    my $bv = Data::Bvec::->new( nums2bstr => $nums );

=cut

sub new {
    my $class = shift;

    die "Too many parameters" if @_ > 2;
    my %parm = @_;
    my $self = {};

    $self->{bvec} = $parm{bvec} if defined $parm{bvec};
    $self->{bstr} = $parm{bstr} if defined $parm{bstr};
    $self->{nums} = $parm{nums} if defined $parm{nums};

    $self->{nums} = bit2num $parm{bvec2nums} if defined $parm{bvec2nums};
    $self->{bvec} = num2bit $parm{nums2bvec} if defined $parm{nums2bvec};

    $self->{bstr} = compress bit2str    $parm{bvec2bstr} if defined $parm{bvec2bstr};
    $self->{bvec} = str2bit  uncompress $parm{bstr2bvec} if defined $parm{bstr2bvec};

    $self->{nums} = bit2num  str2bit uncompress $parm{bstr2nums} if defined $parm{bstr2nums};
    $self->{bstr} = compress bit2str num2bit    $parm{nums2bstr} if defined $parm{nums2bstr};

    bless $self, $class;
}

#---------------------------------------------------------------------

=head2 get_bvec()

This routine takes no parameters.  It returns a bit vector, regardless
how the integers are stored.  The object is not changed.

    my $vec = $bv->get_bvec();

=cut

sub get_bvec {
    my $self = shift;

    return $self->{bvec}                    if defined $self->{bvec};
    return str2bit uncompress $self->{bstr} if defined $self->{bstr};
    return num2bit $self->{nums}            if defined $self->{nums};

}

#---------------------------------------------------------------------

=head2 get_bstr()

This routine takes no parameters.  It returns a compressed bit string,
regardless how the integers are stored.  The object is not changed.

    my $bstr = $bv->get_bstr();

=cut

sub get_bstr {
    my $self = shift;

    return                          $self->{bstr} if defined $self->{bstr};
    return compress bit2str         $self->{bvec} if defined $self->{bvec};
    return compress bit2str num2bit $self->{nums} if defined $self->{nums};

}

#---------------------------------------------------------------------

=head2 get_nums( $beg, $cnt )

This routine returns an array of integers, regardless how the integers
are stored.  The object is not changed.

Note that if the integers are stored as 'nums' (an array), get_nums()
will return them in the same order as the array.  If they are stored
another way, they will be returned in ascending order.

    my @integers = $bv->get_nums();  # list returned in list context
    my $ints     = $bv->get_nums();  # aref returned in scalar context

=head3 Parameters:

=head4 $beg

The first integer to return.  Unlike array subscripts, the $beg
positions start with 1, not 0.  If no $beg is given, 1 is assumed.

=head4 $cnt

The maximum number of integers (including the first) to return.
If no $cnt is given, the rest of the integers are returned.

=cut

sub get_nums {
    my $self = shift;
    my $beg  = shift||1;
    my $cnt  = shift||'';

    my @num;

    if( defined $self->{nums} ) {
        if   ( $cnt      ) { @num = @{$self->{nums}}[--$beg..$beg+$cnt-1]       }
        elsif( $beg == 1 ) { @num = @{$self->{nums}}                            }
        else               { @num = @{$self->{nums}}[--$beg..$#{$self->{nums}}] }
    }
    elsif( defined $self->{bvec} ) {
        @num = bit2num $self->{bvec}, $beg, $cnt;
    }
    elsif( defined $self->{bstr} ) {
        @num = bit2num str2bit( uncompress $self->{bstr} ), $beg, $cnt;
    }

    return  @num if wantarray;
    return \@num;
}


1;  # return true

__END__
