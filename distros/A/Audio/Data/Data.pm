package Audio::Data;
use strict;
use AutoLoader qw(AUTOLOAD);
use base 'Exporter';
our @EXPORT_OK = qw(solve_polynomial);

sub solve_polynomial;

# PerlIO calls used in .xs code
require 5.00302;

use XSLoader;
our $VERSION = sprintf '1.%03d', (q$Revision: #14 $ =~ /\D(\d+)\s*$/)[0] + 15;

XSLoader::load 'Audio::Data',$VERSION;

our $epsilon;

BEGIN {
    for ( my $maybe = 0.5 ; 1.0 + $maybe > 1.0 ; $maybe *= 0.5 ) {
        $epsilon = $maybe;
    }
#   warn "epsilon=$epsilon\n";
}

use overload
    'fallback' => 1,
    '""'   => 'asString',
    'bool' => 'samples',
    '0+'   => 'samples',
     '+'   => 'add',
     '~'   => 'conjugate',
     '-'   => 'sub',
     '*'   => 'mpy',
     '/'   => 'div',
     '.'   => 'concat',
     '@{}' => 'getarray';

sub PI () { 3.14159265358979323846 }


sub new
{
 my $class = shift;
 my $obj   = bless $class->create,$class;
 while (@_)
  {
   my $method = shift;
   my $val    = shift;
   $obj->$method($val);
  }
 return $obj;
}

sub getarray
{
 my ($self) = @_;
 my @a;
 tie @a,ref $self,$self;
 return \@a;
}

sub TIEARRAY
{
 my ($class,$audio) = @_;
 return $audio;
}

sub asString
{
 my ($self) = shift;
 my $comment = $self->comment;
 my $val = ref($self).sprintf(" %.3gs \@ %dHz",$self->duration,$self->rate);
 $val .= ":$comment" if defined $comment;
 return $val;
}

sub fft
{
 my ($au,$N,$radix) = @_;
 $radix = 2 if @_ < 3;
 # XS modifies in place to mess with a copy and return that
 $au = $au->clone if defined wantarray;
 $au->length($N);
 my $method = "r${radix}_fft";
 $au->$method();
 return $au;
}

sub ifft
{
 my ($au,$N,$radix) = @_;
 $radix = 2 if @_ < 3;
 $au = $au->clone if defined wantarray;
 $au->length($N);
 my $method = "r${radix}_ifft";
 $au->$method();
 return $au;
}

#Comment BASE is the base of the floating point representation on the machine.
#       It is 16 for base 16 float : for example, IBM system 360/370.
#       It is 2  for base  2 float : for example, IEEE float.
sub BASE ()    { 2 }
sub BASESQR () { BASE * BASE }

1;

__END__

# Perl code to find roots of a polynomial translated by Nick Ing-Simmons
# <Nick@Ing-Simmons.net> from FORTRAN code by Murakami Hiroshi.
# From the netlib archive: http://netlib.bell-labs.com/netlib/search.html
# In particular http://netlib.bell-labs.com/netlib/opt/companion.tgz


#***********************************************************************
#
#  Solve the real coefficient polynomial equation by the QR-method.
#
#***********************************************************************
sub solve_polynomial
{
    my @c = @_;

    # @c  : coefficients of the polynomial.
    #       $i-th degree coefficients is stored in $c[$i].


#***********************************************************************
#
#  build the Companion Matrix of the polynomial.
#
#***********************************************************************
    while (@c) {

        # Get coef of highest order term
        my $cn = pop (@c);
        if ( $cn != 0.0 ) {

            # Non zero we will start from here -
            # divide rest of coef by this coef to get c0+c1*x+...+1.0*x**n
            #
            foreach my $c (@c) {
                $c /= $cn;
            }
            last;
        }
    }
    my $n = @c;
    die "wrong arguments. ($n<=0)" if $n <= 0;
    my @h;
    for my $i ( 1 .. $n ) {
        for my $j ( 1 .. $n ) {
            $h[$i][$j] = 0.0;
        }
    }
    for my $i ( 2 .. $n ) {
        $h[$i][ $i - 1 ] = 1.0;
    }
    for my $i ( 1 .. $n ) {
        $h[$i][$n] = -$c[ $i - 1 ];
    }

    if ( $n > 1 ) {

        # Now we balance the matrix:
        #***********************************************************************
        #
        # Blancing the unsymmetric matrix A.
        # Perl code translated by Nick Ing-Simmons <Nick@Ing-Simmons.net>
        # from FORTRAN code by Murakami Hiroshi.
        #
        #  The fortran code is based on the Algol code "balance" from paper:
        #   "Balancing $h Matrixfor Calculation of Eigenvalues and Eigenvectors"
        #   by B.N.Parlett and C.Reinsch, Numer. Math. 13, 293-304(1969).
        #
        #  Note: The only non-zero elements of the companion matrix are touched.
        #
        #***********************************************************************
        my $noconv = 1;
        while ($noconv) {
            $noconv = 0;
            for my $i ( 1 .. $n ) {
                #Touch only non-zero elements of companion.
                my $c;
                if ( $i != $n ) {
                    $c = abs( $h[ $i + 1 ][$i] );
                }
                else {
                    $c = 0.0;
                    for my $j ( 1 .. $n - 1 ) {
                        $c += abs( $h[$j][$n] );
                    }
                }
                my $r;
                if ( $i == 1 ) {
                    $r = abs( $h[1][$n] );
                }
                elsif ( $i != $n ) {
                    $r = abs( $h[$i][ $i - 1 ] ) + abs( $h[$i][$n] );
                }
                else {
                    $r = abs( $h[$i][ $i - 1 ] );
                }

                next if ( $c == 0.0 || $r == 0.0 );

                my $g = $r / BASE;
                my $f = 1.0;
                my $s = $c + $r;
                while ( $c < $g ) {
                    $f = $f * BASE;
                    $c = $c * BASESQR;
                }
                $g = $r * BASE;
                while ( $c >= $g ) {
                    $f = $f / BASE;
                    $c = $c / BASESQR;
                }

                if ( ( $c + $r ) < 0.95 * $s * $f ) {
                    $g      = 1.0 / $f;
                    $noconv = 1;

                    #C Generic code.
                    #C           do $j=1,$n
                    #C             $h($i,$j)=$h($i,$j)*$g
                    #C           enddo
                    #C           do $j=1,$n
                    #C             $h($j,$i)=$h($j,$i)*$f
                    #C           enddo
                    #C begin specific code. Touch only non-zero elements of companion.
                    if ( $i == 1 ) {
                        $h[1][$n] *= $g;
                    }
                    else {
                        $h[$i][ $i - 1 ] *= $g;
                        $h[$i][$n] *= $g;
                    }
                    if ( $i != $n ) {
                        $h[ $i + 1 ][$i] *= $f;
                    }
                    else {
                        for my $j ( 1 .. $n ) {
                            $h[$j][$i] *= $f;
                        }
                    }
                }
            }    # for $i
        }    # while $noconv
    }

    $n   = $#h;

    #***********************************************************************
    #
    # Eigenvalue Computation by the Householder QR method for the Real Hessenberg matrix.
    # Perl code translated by Nick Ing-Simmons <Nick@Ing-Simmons.net>
    # from FORTRAN code by Murakami Hiroshi.
    # The fortran code is based on the Algol code "hqr" from the paper:
    #       "The QR Algorithm for Real Hessenberg Matrices"
    #       by R.S.Martin, G.Peters and J.H.Wilkinson,
    #       Numer. Math. 14, 219-231(1970).
    #
    #***********************************************************************
    #  Finds the eigenvalues of a real upper Hessenberg matrix,
    #  H, stored in the array $h(1:n,1:n), and returns a list
    #  of alternate real,imaginary parts.

    my ( $p, $q, $r );
    my ( $w, $x, $y );
    my ( $s, $z );
    my $t = 0.0;

    my @w;
    ROOT:
    while ( $n > 0 ) {
        my $its = 0;
        my $na  = $n - 1;

        while ( $its < 61 ) {

            # Look for single small sub-diagonal element;
            my $l;
            for ( $l = $n ; $l >= 2 ; $l-- ) {
                last
                  if (
                    abs( $h[$l][ $l - 1 ] ) <= $epsilon *
                    ( abs( $h[ $l - 1 ][ $l - 1 ] ) + abs( $h[$l][$l] ) ) );
            }
            $x = $h[$n][$n];
            if ( $l == $n ) {

                # one (real) root found;
                push @w, $x + $t, 0.0;
                $n--;
                next ROOT;
            }
            $y = $h[$na][$na];
            $w = $h[$n][$na] * $h[$na][$n];
            if ( $l == $na ) {
                $p = ( $y - $x ) / 2;
                $q = $p * $p + $w;
                $y = sqrt( abs($q) );
                $x = $x + $t;
                if ( $q > 0.0 ) {

                    #real pair;
                    $y = -$y if ( $p < 0.0 );
                    $y += $p;
                    push @w, $x - $w / $y, 0.0;
                    push @w, $x + $y, 0.0;
                }
                else {

                    # Complex or twin pair
                    push @w, $x + $p, $y;
                    push @w, $x + $p, -$y;
                }
                $n -= 2;
                next ROOT;
            }
            if ( $its == 60 ) {
                die "Too many itterations ($its) at n=$n\n";
            }
            elsif ( $its && $its % 10 == 0 ) {

                # form exceptional shift;
                # warn "exceptional shift \@ $its";
                $t = $t + $x;
                for ( my $i = 1 ; $i <= $n ; $i++ ) {
                    $h[$i][$i] -= $x;
                }
                $s = abs( $h[$n][$na] ) + abs( $h[$na][ $n - 2 ] );
                $y = 0.75 * $s;
                $x = $y;
                $w = -0.4375 * $s * $s;
            }
            $its++;

            # Look for two consecutive small sub-diagonal elements;
            my $m;
            for ( $m = $n - 2 ; $m >= $l ; $m-- ) {
                $z = $h[$m][$m];
                $r = $x - $z;
                $s = $y - $z;
                $p = ( $r * $s - $w ) / $h[ $m + 1 ][$m] + $h[$m][ $m + 1 ];
                $q = $h[ $m + 1 ][ $m + 1 ] - $z - $r - $s;
                $r = $h[ $m + 2 ][ $m + 1 ];
                $s = abs($p) + abs($q) + abs($r);
                $p = $p / $s;
                $q = $q / $s;
                $r = $r / $s;
                last if ( $m == $l );
                last
                  if (
                    abs( $h[$m][ $m - 1 ] ) * ( abs($q) + abs($r) ) <=
                    $epsilon * abs($p) * (
                        abs( $h[ $m - 1 ][ $m - 1 ] ) + abs($z) +
                          abs( $h[ $m + 1 ][ $m + 1 ] )
                    )
                  );
            }

            for ( my $i = $m + 2 ; $i <= $n ; $i++ ) {
                $h[$i][ $i - 2 ] = 0.0;
            }
            for ( my $i = $m + 3 ; $i <= $n ; $i++ ) {
                $h[$i][ $i - 3 ] = 0.0;
            }

            # Double QR step involving rows $l to $n and columns $m to $n;
            for ( my $k = $m ; $k <= $na ; $k++ ) {
                my $notlast = ( $k != $na );
                if ( $k != $m ) {
                    $p = $h[$k][ $k - 1 ];
                    $q = $h[ $k + 1 ][ $k - 1 ];
                    $r = ($notlast) ? $h[ $k + 2 ][ $k - 1 ] : 0.0;
                    $x = abs($p) + abs($q) + abs($r);
                    next if ( $x == 0.0 );
                    $p = $p / $x;
                    $q = $q / $x;
                    $r = $r / $x;
                }
                $s = sqrt( $p * $p + $q * $q + $r * $r );
                $s = -$s if ( $p < 0.0 );
                if ( $k != $m ) {
                    $h[$k][ $k - 1 ] = -$s * $x;
                }
                elsif ( $l != $m ) {
                    $h[$k][ $k - 1 ] = -$h[$k][ $k - 1 ];
                }
                $p += $s;
                $x = $p / $s;
                $y = $q / $s;
                $z = $r / $s;
                $q /= $p;
                $r /= $p;

                # row modification;
                for ( my $j = $k ; $j <= $n ; $j++ ) {
                    $p = $h[$k][$j] + $q * $h[ $k + 1 ][$j];
                    if ($notlast) {
                        $p = $p + $r * $h[ $k + 2 ][$j];
                        $h[ $k + 2 ][$j] -= $p * $z;
                    }
                    $h[ $k + 1 ][$j] -= $p * $y;
                    $h[$k][$j] -= $p * $x;
                }
                my $j = $k + 3;
                $j = $n if $j > $n;

                # column modification;
                for ( my $i = $l ; $i <= $j ; $i++ ) {
                    $p = $x * $h[$i][$k] + $y * $h[$i][ $k + 1 ];
                    if ($notlast) {
                        $p += $z * $h[$i][ $k + 2 ];
                        $h[$i][ $k + 2 ] -= $p * $r;
                    }
                    $h[$i][ $k + 1 ] -= $p * $q;
                    $h[$i][$k] -= $p;
                }
            }    # for $k
        }    # while $its
    }    # while $n
    return @w;
}



=head1 NAME

Audio::Data - module for representing audio data to perl

=head1 SYNOPSIS

  use Audio::Data;
  my $audio = Audio::Data->new(rate => , ...);

  $audio->method(...)

  $audio OP ...

=head1 DESCRIPTION

B<Audio::Data> represents audio data to perl in a fairly compact and efficient
manner using C via XS to hold data as a C array of C<float> values.
The use of C<float> avoids many issues with dynamic range, and typical C<float>
has 24-bit mantissa so quantization noise should be acceptable. Many machines
have floating point hardware these days, and in such cases operations on C<float>
should be as fast or faster than some kind of "scaled integer".

Nominally data is expected to be between +1.0 and -1.0 - although only
code which interacts with outside world (reading/writing files or devices)
really cares.

It can also represent elements (samples) which are "complex numbers" which
simplifies many Digital Signal Processing methods.

=head2 Methods

The interface is object-oriented, and provides the methods below.

=over 4

=item $audio = Audio::Data->new([method => value ...])

The "constructor" - takes a list of method/value pairs and calls
$audio->I<method>(I<value>) on the object in order. Typically first "method"
will be B<rate> to set sampling rate of the object.

=item $rate = $audio->rate

Get sampling rate of object.

=item $audio->rate($newrate)

Set sampling rate of the object. If object contains existing data it is
re-sampled to the new rate. (Code to do this was derived from a now dated
version of C<sox>.)

=item $audio->comment($string)

Sets simple string comment associated with data.

=item $string = $audio->comment

Get the comment

=item $time = $audio->duration

Return duration of object (in seconds).

=item $time = $audio->samples

Return number of samples in the object.

=item @data = $audio->data

Return data as list of values - not recommended for large data.

=item $audio->data(@data)

Sets elements from @data.

=item $audio->length($N)

Set number of samples to I<$N> - tuncating or padding with zeros (silence).

=item ($max,$min) = $audio->bounds([$start_time[,$end_time]])

Returns a list of two values representing the limits of the values
between the two times if $end_time isn't specified it defaults to
the duration of the object, and if start time isn't specified it defaults
to zero.

=item $copy = $audio->clone

Creates copy of data carrying over sample rate and complex-ness of data.

=item $slice = $audio->timerange($start_time,$end_time);

Returns a time-slice between specified times.

=item $audio->Load($fh)

Reads Sun/NeXT .au data from the perl file handle (which should
have C<binmode()> applied to it.)

This will eventually change - to allow it to load other formats
and perhaps to return list of Audio::Data objects to represnt
multiple channels (e.g. stereo).

=item $audio->Save($fh[,$comment])

Write a Sun/NeXT .au file to perl file handle. I<$comment> if specified
is used as the comment.

=item $audio->tone($freq,$dur,$amp);

Append a sinusoidal tone of specified freqency (in Hz) and duration (in seconds),
and peak amplitude $amp.

=item $audio->silence($dur);

Append a period of 0 value of specified duration.

=item $audio->noise($dur,$amp);

Append burst of (white) noise of specified duration and peak amplitude.

=item $window = $audio->hamming($SIZE,$start_sample[,$k])

Returns a "raised cosine window" sample of I<$SIZE> samples starting at specified
sample. If I<$k> is specified it overrides the default value of 0.46
(e.g. a value of 0.5 would give a Hanning window as opposed to a Hamming window.)

  windowed = ((1.0-k)+k*cos(x*PI))

=item $freq = $audio->fft($SIZE)

=item $time = $freq->ifft($SIZE);

Perform a Fast Fourier Transform (or its inverse).
(Note that in general result of these methods have complex numbers
as the elements. I<$SIZE> should be a power-of-two (if it isn't next larger
power of two is used). Data is padded with zeros as necessary to get to
I<$SIZE> samples.

=item @values = $audio->amplitude([$N[,$count]])

Return values of amplitude for sample $N..$N+$count inclusive.
if I<$N> is not specified it defaults to zero.
If I<$count> is not specified it defaults to 1 for scalar context
and rest-of-data in array context.

=item @values = $audio->dB([$N[,$count]])

Return amplitude - in deci-Bells.
(0dB is 1/2**15 i.e. least detectable value to 16-bit device.)
Defaults as for amplitude.

=item @values = $audio->phase([$N [,$count]])

Return Phase - (if data are real returns 0).
Defaults as for amplitude.

=item $diff = $audio->difference

Returns the first difference between successive elements of the data -
so result is one sample shorter. This is a simple high-pass filter and
is much used to remove DC offsets.


=item $Avalues = $audio->lpc($NUM_POLES,[$auto [,$refl]])

Perform Linear Predictive Coding analysis of $audio and return coefficents
of resulting All-Pole filter. 0'th Element is I<not> a filter coefficent
(there is no A[0] in such a filter) - but is a measure of the "error"
in the matching process. I<$auto> is an output argument and returns
computed autocorrelation. I<$refl> is also output and are so-called
reflection coefficents used in "lattice" realization of the filter.
(Code for this lifted from "Festival" speech system's speech_tools.)

=item $auto = $audio->autocorrelation($LENGTH)

Returns an (unscaled) autocorrelation function - can be used to cause
peaks when data is periodic - and is used as a precursor to LPC analysis.


=back 4


=head2 Operators

B<Audio::Data> also provides overloaded operators where the B<Audio::Data> object
is treated as a vector in a mathematical sense. The other operand of an
operator can either be another B<Audio::Data> or a scalar which can be
converted to a real number.

=over 4

=item $audio * $scalar

Multiply each element by the scalar - e.g. adjust "volume".

=item $audio * $another

Is ear-marked to perform convolution but does not work yet.

=item $audio / $scalar

Divide each element by the scalar - e.g. adjust "volume".

=item $scalar / $audio

Return a new object with each element being result of dividing scalar
by the corresponding element in original I<$audio>.

=item $audio + $scalar

Add $scalar to each element - i.e. apply a DC offset.

=item $audio + $another

Adds element-by-element - i.e. mixes them.

=item $audio - $scalar

Subtract $scalar from each element.

=item $audio - $another

Subtracts element-by-element

=item $audio . $scalar

Append a new element. (Perhaps if scalar is a string it should
append to comment instead - but what is a string ... )

=item $audio . $another

Appends the two objects to get a longer one.

=item $audio . [ @things ]

Appends contents of array to the object, the contents can
be scalars, Audio::Data objects or (as it recurses) refrences to arrays.

=item $audio->[$N]

access a sample.

=item ~$audio

Takes complex conjugate


=back 4

=head1 SEE ALSO

See code for C<tkscope> to see most of the above in use.

=head1 BUGS AND MISFEATURES

Currently only a single channel can be represented - which is fine for
speech applications I am using it for, but precludes using it for music.

Still lack Windows .wav file support.

=head1 AUTHOR

Nick Ing-Simmons E<lt>Nick@Ing-Simmons.netE<gt>

=cut

