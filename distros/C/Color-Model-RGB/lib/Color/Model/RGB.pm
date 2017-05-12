# =============================================================================
package Color::Model::RGB;
# -----------------------------------------------------------------------------
$Color::Model::RGB::VERSION = '1.02';
# -----------------------------------------------------------------------------
use warnings;
use strict;

=head1 NAME

Color::Model::RGB - Color model of RGB

=head1 SYNOPSIS

    $navy      = rgb(0, 0, 0.5);
    $limegreen = rgb('#32CD32');

    # use Color::Model::RGB qw(:primary);
    $white   = R + G + B;       # addition (Constant O and W are also prepared)
    $yellow  = $white - $b;     # subtraction
    $midgray = $while / 2;      # divide
    $hilight = $midgray * 1.5;  # multiply
    print qq(<span color="#$hilight">see<span>);    # stringify

    @rgbval = $color->array();      # decimal
    @rgb256 = $color->array256();   # integers

    # applying ...
    @gradation = map { rgb('#010101') << $_ } (0..7);
    @tricolor  = ( $c, rgb(($c->array)[1,2,0]), rgb(($c->array)[2,0,1]) );

    # use Color::Model::RGB qw(:blender);
    $violet = blend_half(R, B);
    $pink   = blend_plus(R, $hilight);

=head1 DESCRIPTION

Color::Model::RGB is a color model of RGB implemented by 3D mathematical
vector.
This provides abstruct calculation for colors with overloding and methods
to convert values to simply hexadecimal string designed for HTML, CSS and etc.

Color::Model::RGB is based on B<Math::VectorReal>.

=cut

# =============================================================================
use Carp;
use POSIX qw(ceil);
use Scalar::Util ();

use base qw(Math::VectorReal Exporter);
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
@EXPORT = qw( rgb rgb256 rgbhex );
@EXPORT_OK = qw( O R G B W
                 set_format get_format
                 blend_alpha blend_half blend_plus blend_minus
             );
%EXPORT_TAGS = (
    primary => [ qw(O R G B W) ], RGB => [ qw(O R G B W) ],
    format  => [ qw(set_format get_format) ],
    blender => [ qw(blend_alpha blend_half blend_plus blend_minus) ],
    all => [@EXPORT, @EXPORT_OK],
);


our $FORMAT = '%02x%02x%02x';
our $FORMAT_HEXED = 1;      # flag of magic to represent hexadecimal numbers.



# =============================================================================

=head1 CONSTANTS

Some primary colors below are defined as constant. To use these, import them
with tag ':primary' or ':RGB' 

    #     R G B
    O = [ 0 0 0 ]
    R = [ 1 0 0 ]
    G = [ 0 1 0 ]
    B = [ 0 0 1 ]
    W = [ 1 1 1 ]

=cut

# -----------------------------------------------------------------------------
sub O() { bless __PACKAGE__->SUPER::O(), __PACKAGE__ }
sub R() { bless __PACKAGE__->SUPER::X(), __PACKAGE__ }
sub G() { bless __PACKAGE__->SUPER::Y(), __PACKAGE__ }
sub B() { bless __PACKAGE__->SUPER::Z(), __PACKAGE__ }
sub W() { bless [ [[1,1,1]], 1,3 ], __PACKAGE__; }




# =============================================================================

=head1 CONSTRUCTORS

    $col1 = Color::Model::RGB->new(0.1, 0.2, 0.3);
    $col2 = rgb(0.5,0.6,0.7);
    $col3 = rgb256(128,128,255);
    $col3 = rgbhex('0080ff');   # rgbhex('#0080ff') is also ok.
                                # and rgb($hexstr) is also ok.
    $col4 = $col1->clone();

There are functions to make an object.

Method I<rgb()>, I<rgb256()> and I<rgbhex()> are defalut exported functions
returns new Color::Model::RGB object as I<new()>.

Method I<new()> and I<rgb()> require three decimal values as arguments. Values
out of a range, from -1.0 to 1.0, will be set -1.0 or 1.0.
If one argument is given to I<rgb()>, it will be treated as a hexadecimal
string and call I<reghex()> internaly.

Method I<rgb256()> requires three integer values from -255 to 255. Out of range
value will be set -255 or 255.

Method I<rgbhex()> requires a hexadecimal string like HTML format. An argument
starts with '#' is also allowed.

I<clone()> returns new copy of object.

=cut

# -----------------------------------------------------------------------------
sub new
{
    my $class = shift;
    my $ref = ref($class) || __PACKAGE__;
    return bless __PACKAGE__->SUPER::new(@_), $ref;
}

sub rgb
{
    if ( !ref($_[0]) ){
        if ( @_ == 1 ){
            # Assume hex string is given
            return rgbhex($_[0]);
        }
    } else {
        shift;
    }
    my @rgb = map {
        ($_ < -1)? -1:
        ($_ >  1)?  1:
        $_
    } @_;
    return bless __PACKAGE__->SUPER::new(@rgb), __PACKAGE__;
}

sub rgb256
{
    shift if ( @_ == 4 );
    my @rgb = map {
        ($_ < -255)? -1:
        ($_ >  255)?  1:
        ($_/255)
    } @_;
    return bless __PACKAGE__->SUPER::new(@rgb), __PACKAGE__;
}

sub rgbhex
{
    my $h = lc(shift);
    if ( defined($h) && $h =~ /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/ ){
        return bless __PACKAGE__->SUPER::new(
                   map { hex($_)/255 } ($1,$2,$3)
               ), __PACKAGE__;
    } else {
        Carp::croak("rgbHex() needs a hex values argument. ($h was given)");
    }
}


# =============================================================================

=head1 METHODS

=over

=item r(), g(), b()

Returns decimal value of an element.

=item r256(), g256(), b256()

Returns integer value of an element, which is multiplyed by 255 and rounded by
I<POSIX::ceil()>.

=item array()
=item array256()

These methods return an array contains values of elements. I<array256()>
returns values multiplyed by 255 and rounded by I<POSIX::ceil()>.

=item hexstr([ $head_letter ])

Returns 6 digits hexadecimal string. If some string is given as argument,
value starting with it returns.

=item truncate(), limit()

These methods return new clone object, values of elements of which are set in
regulated range. I<truncate()> makes a values lesser than 0 set to 0, and
grater than 1 set to 1. And I<limit()> set values from -1 to 1 similarly. 

=item stringify( [ $format [, $flag2hex] ] )

This method can take 2 arguments. The first is format string for I<sprintf()>,
and the second is a boolean flag to convert to hexadecimal or not. If this
flag is true, values multiplyed by 255 will be used at outputing.
Default values of the format and the flag are keeped by package variable;

    $Color::Model::RGB::FORMAT       = "%02x%02x%02x";
    $Color::Model::RGB::FORMAT_HEXED = 1;

Arguments are omitted at I<stringify()> calling, these defalut values will be
used.

Function I<set_format()> and I<get_format()> describing below gives a way to
change these defalut values simply.

=back

=cut

# -----------------------------------------------------------------------------
sub _treat_elem
{
    my $self = shift;
    my $colno= shift;
    if ( !@_ ){
        return $self->[0][0][$colno];
    } elsif ( @_ == 1 ){
        $self->[0][0][$colno] = $_[0];
    } else {
        Carp::carp("Too many arguments. Ignored");
    }
}

sub r { my $self = shift; return _treat_elem($self,0,@_) }
sub g { my $self = shift; return _treat_elem($self,1,@_) }
sub b { my $self = shift; return _treat_elem($self,2,@_) }

sub r256 { ceil($_[0]->r * 255) }
sub g256 { ceil($_[0]->g * 255) }
sub b256 { ceil($_[0]->b * 255) }


sub array256
{
    my $v = shift;
    return map {ceil($_ * 255)} @{$v->[0][0]};
}

sub hexstr
{
    my( $v, $head ) = @_;
    $head ||= '';
    return $v->stringify("$head%02x%02x%02x",1);
}

sub truncate
{
    my $v = shift;
    my $c = $v->clone();
    for ( 0 .. 2 ) {
        $c->[0][0][$_] = 0 if $c->[0][0][$_] < 0;
        $c->[0][0][$_] = 1 if $c->[0][0][$_] > 1;
    }
    $#{$c} = 2;
    return $c;
}

sub limit
{
    my $v = shift;
    for ( 0 .. 2 ) {
        $v->[0][0][$_] = -1 if $v->[0][0][$_] < -1;
        $v->[0][0][$_] =  1 if $v->[0][0][$_] > 1;
    }
    $#{$v} = 2;
    return $v;
}

sub stringify
{
    my( $v, $fmt, $hexed ) = @_;
    $fmt   = $FORMAT unless defined $fmt;  # if not given use current default
    $hexed = $FORMAT_HEXED unless defined $hexed;
    if ( $hexed ){
        return sprintf($fmt, $v->truncate->array256());
    } else {
        return sprintf($fmt, $v->array());
    }
}




# =============================================================================

=head1 OPERATOR OVERLOAD

Color::Model::RGB inherits operators overloading from Math::VextorReal. These
functions are so useful for mathematical calculation of colors.

Note: for avoiding error of conflcting with File Test Operation, put a constant
object,
R, B, W or O, in blanckets"()" or separate with space when using expression
with muinus and them.

    $c = -(W)       # OK
    $c = W - R      # OK
    $c = -W         # error or raises bug. ( Perl thinks as "-W $_" )
    $c = W-R        # error too.

=over

=item Negation (unary minus)

    $c = -$x        # -object -> rgb(-r,-b,-c)

A Color::Model::RGB object some values of which are minus is allowed for
calculation. When stringifying such object, minus value will be represented as
0.

=item Addition (+)

    $c = R + G;     # object1 + object2 -> rgb(r1+r2, g1+g2, b1+b2)
    $c = B + 10;    # object  + scalar  -> rgb(r +x,  g +x,  b +x)

=item Subtraction (-)

    $c = W - B;     # object1 - objext2 -> rgb(r1-r2, g1-g2, b1-b2)
    $c = W - 10;    # object  - scalar  -> rgb(r1-x,  g1-x,  b1-x)

=item Object scalar multiplication (*)

    $c = W * 0.5    # object * scalar  -> rgb(r1*x,  g1*x,  b1*x)
    # use Math::MatrixReal
    $c = $col * $m  # Color::Model::RGB * Math::MatrixReal

Color::Model::RGB multiplication by a object is allowed by 
B<Math::MatrixReal> instance. This function may be good to calculate hue
rotation of a color.

    # hue rotation sample
    $r = 2 * (atan2(1,1)*4) / 10; # for 2pi/10 radian
    ($sin,$cos) = (sin($r), cos($r));
    $p  = (1/3) * (1-$cos);
    $q  = sqrt(1/3) * $sin; # (1/3,1/3,1/3) is norm of W

    $matrix = Math::MatrixReal->new_from_rows([
        [ $p+$cos, $p-$q,   $p+$q,  ],
        [ $p+$q,   $p+$cos, $p-$q,  ],
        [ $p-$q,   $p+$q,   $p+$cos,],
    ]);

    $rgb = R;
    foreach ( 1..10 ){
        print qq(<span style="color:#$rgb">#$rgb</span><br>\n);
        $rgb *= $matrix;
    }

=item Object scalar division (/)

    $c = W / 3      # object  / scalar  -> rgb(r1/x,  g1/x,  b1/x)
    # object1 / object2 is not allowed (croaking)

=item Cross and dot products (x and .)

Calculation corss and dot product are seldom used at color manipulation.
These may be used for hue rotation, too.

    # hue rotation sample 2
    $r = 2 * (atan2(1,1)*4) / 10; # for 2pi/10 radian
    $n = W->norm;
    $rgb = R;
    foreach ( 1..10 ){
        print qq(<span style="color:#$rgb">#$rgb</span><br>\n);
        $p = $n * ($n . $rgb);
        $rgb = $p + ($rgb - $p)*cos($r) - ($rgb x $n)*sin($r);
    }

=item Bitwise operations 

There are bitwise operations in Color::Model::RGB such as '<<', '>>','&',
'|', '^' and '~'.

    $col1 = rgbhex('010101');
    $col2 = $col1 << 7;     # Bit shift left,  becomes 808080
    $col3 = $col2 >> 1;     # Bit shift right, becomes 404040

    $col4 = $col2 | $col3;  # Object-object bit OR,  becomes c0c0c0
    $col5 = $col2 | 0x66;   # Object-scalar bit OR,  becomes e6e6e6

    $col6 = $col4 & $col5   # Object-object bit AND, becomes c0c0c0
    $col7 = $col4 & 0x80    # Object-scalar bit AND, becomes 808080

    $col8 = $col6 ^ $col7   # Object-object bit XOR, becomes 404040
    $col9 = $col6 ^ 0xff;   # Object-scalar bit XOR, becomes 3f3f3f

    $col10 = ~$col8;        # Bit Negate, becomes bfbfbf

In bitwise operation, each element values of Color::Model::RGB are internaly
conveted to integers from 0 to 255 and than caluculated individually, and
converted to decimal again.

Package parameter, $Color::Model::RGB::BIT_SHIFT_RIGID, changes bit shift
operation's result. If this is true value, caluculated value will be ANDed
with 0xff. If it is false, valuse over 0xff will be set to 0xff(255). Default
is false(0).

    $Color::Model::RGB::BIT_SHIFT_RIGID = 1;
    $col = rgbhex('010101')<<8;     # becomes 000000
    $Color::Model::RGB::BIT_SHIFT_RIGID = 0;
    $col = rgbhex('010101')<<8;     # becomes ffffff

=back

=cut

# -----------------------------------------------------------------------------
$Color::Model::RGB::BIT_SHIFT_RIGID = 0;
#$Math::VectorReal::TRACE = 1;

use overload
    '*'  => \&_multiply,
    '<<' => \&_bit_shiftl,
    '>>' => \&_bit_shiftr,
    '&'  => \&_bit_and,
    '|'  => \&_bit_or,
    '^'  => \&_bit_xor,
    '~'  => \&_bit_not,
    'fallback' => undef;

sub _trace
{
    Math::VectorReal::_trace(@_);
}

sub _multiply {
  # copied and improved from Math::VectorReal
  my($object,$argument,$flip) = @_;
  _trace("'*'",$object,$argument,$flip);
  if ( ref($argument) ){
    if ( $argument->isa('Math::MatrixReal') ) {
        # Assume multiply by  Math::MatrixReal object  EG:  $v * $M --> $new_v
        # Order is communicative, but $flip should NOT be true
        if ( ! $flip ) {
            my $v = ( $object->vector2matrix_row($argument)
                            * $argument )->matrix_row2vector;
            return bless $v, __PACKAGE__;
        } else { # just in case flip is true..
            my $v = ( $argument *
                    $object->vector2matrix_row($argument) )->matrix_row2vector;
            return bless $v, __PACKAGE__;
        }
    } else {
        Carp::croak("multiplication(*) is allowed by Math::MatrixReal object or scalar");
    }
  }
  elsif ( defined $argument ) {
    # defined $argument must be a scalar, so Scalar Multiply
    # Communitive - order does not matter, $flip can be ignored
    my $v = $object->clone;
    for ( 0 .. 2 ) { $v->[0][0][$_] *= $argument; }
    $v->[6] *= abs($argument) if defined $v->[6]; # multiply vector length
    return $v;
  }
  Carp::croak("undefined argument given for vector multiply");
}

sub _bit_shiftl
{
    my($object,$argument,$flip) = @_;
    _trace("'<<'",$object,$argument,$flip);
    # $argument must be scalar and plus
    if ( (defined $argument) && !ref($argument) && $argument>=0 ){
        my @rgb = $object->truncate()->array256();
        my $v = rgb256( map {
            $_ <<= $argument;
            $_ &= 0xff if $Color::Model::RGB::BIT_SHIFT_RIGID;
            $_;
        } @rgb );
        $#{$v} = 2;   # any cached vector length is now invalid
        return $v;
    }
    Carp::croak("non-scalar given or minus for vector scalar bit shift left");
}

sub _bit_shiftr
{
    my($object,$argument,$flip) = @_;
    _trace("'>>'",$object,$argument,$flip);
    # $argument must be scalar and plus
    if ( (defined $argument) && ! ref($argument) && $argument>=0 ){
        my @rgb = $object->truncate()->array256();
        my $v = rgb256( map {
            $_ >>= $argument;
        } @rgb );
        $#{$v} = 2;   # any cached vector length is now invalid
        return $v;
    }
    Carp::croak("non-scalar given or minus for vector scalar bit shift right");
}

sub _bit_and
{
    my($object,$argument,$flip) = @_;
    _trace("'&'",$object,$argument,$flip);
    if ( ref($argument) ) {
        # bitwise and of two Color::Model::RGB
        my @vrgb = $object->truncate()->array256();
        my @argb = $argument->truncate()->array256();
        my $v = rgb256(
            $vrgb[0] & $argb[0],
            $vrgb[1] & $argb[1],
            $vrgb[2] & $argb[2]
        );
        $#{$v} = 2;   # any cached vector length is now invalid
        return $v;
    }
    elsif ( defined($argument) ){
        # bitwise and of Color::Model::RGB with scalar
        my @rgb = $object->truncate()->array256();
        my $v = rgb256( map {
            $_ & $argument;
        } @rgb );
        $#{$v} = 2;   # any cached vector length is now invalid
        return $v;
    }
    Carp::croak("undefined argument given for vector bitwise and");
}

sub _bit_or
{
    my($object,$argument,$flip) = @_;
    _trace("'|'",$object,$argument,$flip);
    if ( ref($argument) ) {
        # bitwise or of two Color::Model::RGB
        my @vrgb = $object->truncate()->array256();
        my @argb = $argument->truncate()->array256();
        my $v = rgb256(
            $vrgb[0] | $argb[0],
            $vrgb[1] | $argb[1],
            $vrgb[2] | $argb[2]
        );
        $#{$v} = 2;   # any cached vector length is now invalid
        return $v;
    }
    elsif ( defined($argument) ){
        # bitwise or of Color::Model::RGB with scalar
        my @rgb = $object->truncate()->array256();
        my $v = rgb256( map {
            $_ |= $argument;
            $_ &= 0xff;
        } @rgb );
        $#{$v} = 2;   # any cached vector length is now invalid
        return $v;
    }
    Carp::croak("undefined argument given for vector bitwise or");
}

sub _bit_xor
{
    my($object,$argument,$flip) = @_;
    _trace("'^'",$object,$argument,$flip);
    if ( ref($argument) ) {
        # bitwise exclusive or of two Color::Model::RGB
        my @vrgb = $object->truncate()->array256();
        my @argb = $argument->truncate()->array256();
        my $v = rgb256(
            $vrgb[0] ^ $argb[0],
            $vrgb[1] ^ $argb[1],
            $vrgb[2] ^ $argb[2]
        );
        $#{$v} = 2;   # any cached vector length is now invalid
        return $v;
    }
    elsif ( defined($argument) ){
        # bitwise exclusive or of Color::Model::RGB with scalar
        my @rgb = $object->truncate()->array256();
        my $v = rgb256( map {
            $_ ^= $argument;
            $_ &= 0xff;
        } @rgb );
        $#{$v} = 2;   # any cached vector length is now invalid
        return $v;
    }
    Carp::croak("undefined argument given for vector bitwise exclusive or");
}

sub _bit_not
{
    my($object,$argument,$flip) = @_;
    _trace("'~'",$object,$argument,$flip);
    # bitwise complement of Color::Model::RGB with scalar
    my @rgb = $object->truncate()->array256();
    my $v = rgb256( map {
        $_ = ~$_;
        $_ &= 0xff;
    } @rgb );
    return $v;
}


# =============================================================================

=head1 EXPORTING FUNCTION

There are few froups for exporting.

Defalut exporting functions are I<rgb>, I<rgb256> and I<rgbhex>.

Primary colors, I<R> (R:255,G:0,B:0), I<G> (R:0,G:255,B:0), I<B> (R:0,G:0,B:255),
I<O> (R:0,G:0,B:0) and I<W> (R:255,G:255,B:255), will be exported with tag ':primary'
or ':RGB'.

Functions changes defalut about stringifying, I<set_format> and I<get_format>,
will be exported with tag ':format'.

And color blending functions, I<blend_alpha>, I<blend_half>, I<blend_plus> and
I<blend_minus>, will be exported with tag ':blender'.


=head2 CHANGING STRINGIFYING DEFALUT

=over

=item set_format( $format [, $flag2hex] )

=item get_format()

Set and get defalut values of stringifying. See method I<stringify()> descriped
above.

=back

=cut

# -----------------------------------------------------------------------------
sub set_format
{
    my ($fmt, $hexed) = @_;

    if ( !@_ ) {
        Carp::croak("No argument given");
    }
    if ( @_ == 2 ){
        $FORMAT_HEXED = $hexed? 1: 0;
    }
    if ( @_ >= 1 ){
        $FORMAT = $fmt if defined $fmt;
    }
}

sub get_format
{
    my ($fmt, $hexed) = @_;

    return ($FORMAT,$FORMAT_HEXED);
}




# =============================================================================

=head2 BLENDING FUNCTIONS

Color::Model::RGB has several blending functions which make a new object from
two objects.

    $blend_alpha = blend_alpha($col1,0.3,$col2,0.7); # any transparency rate
    $blend_half  = blend_half($col1,$col2);          # 50%:50%
    $blend_plus  = blend_plus($col1,$col2);          # $col1 + $col2
    $blend_minus = blend_plus($col1,$col2);          # $col1 - $col2

=cut

# -----------------------------------------------------------------------------
sub blend_alpha
{
    my ($src,$src_rate, $dist,$dist_rate) = @_;
    unless ( Scalar::Util::blessed($src) && $src->isa(__PACKAGE__) ){
        Carp::croak("First argumenst must be object of ".__PACKAGE__);
    }
    unless ( !ref($src_rate) && $src_rate =~ /^[0-9\.\-]+$/ &&
        $src_rate >=-1 && $src_rate <= 1 ){
        Carp::croak("Second argumenst must be a number between -1.0 to 1.0");
    }
    unless ( Scalar::Util::blessed($dist) && $dist->isa(__PACKAGE__) ){
        Carp::croak("Third argumenst must be object of ".__PACKAGE__);
    }
    unless ( !ref($dist_rate) && $dist_rate =~ /^[0-9\.\-]+$/ &&
        $dist_rate >=-1 && $dist_rate <= 1 ){
        Carp::croak("Fourth argumenst must be a number between -1.0 to 1.0");
    }

    return ( $src * $src_rate + $dist * $dist_rate )->truncate();
}


sub blend_half
{
    return blend_alpha($_[0], 0.5, $_[1], 0.5);
}


sub blend_plus
{
    return blend_alpha($_[0], 1.0, $_[1], 1.0);
}

sub blend_minus
{
    return blend_alpha($_[0], 1.0, $_[1], -1.0);
}




# =============================================================================
1;

__END__


=head1 BUGS

Please report any bugs or feature requests to C<bug-color-model-rgb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Color-Model-RGB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ASLO 

L<Math::VectorReal|http://search.cpan.org/~anthony/Math-VectorReal-1.02/VectorReal.pm> by Anthony Thyssen.

=head1 AUTHOR

T.Onodera, C<< <ong at garakuta.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 T.Onodera.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
