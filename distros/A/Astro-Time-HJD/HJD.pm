package Astro::Time::HJD;

use 5.006;
use strict;
use warnings;

use Math::Trig qw( atan );
use Time::JulianDay;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT_OK = ( qw( correction ) );

our $VERSION = '0.02';

use constant PI  => 3.1415926535897932384626433832795028841971693993751;
use constant PI2 => PI * 2.0;
use constant DEG2RAD => PI / 180.0;
use constant AS2RAD => PI / ( 180.0 * 3600.0 );
use constant SPEED => 1.9913e-7;
use constant REMB => 3.12e-5;
use constant SEMB => 8.31e-11;

sub arctan { return atan( shift ); }

sub mod
   {
   my ( $A, $B ) = @_;
   ( ( $B ) != 0.0 ?
      ( ( $A ) * ( $B ) > 0.0 ? ( $A ) - ( $B ) * int( ( $A ) / ( $B ) ) :
      ( $A ) + ( $B ) * int( -( $A ) / ( $B ) ) ) : ( $A ) );
   }

sub floor
   {
   return int( shift );
   }

sub frac
   {
   my $a = shift;
   return $a - floor( $a );
   }

sub correction
   {
   my $date = shift;
   my $ra = ( shift ) * DEG2RAD;
   my $dec = ( shift ) * DEG2RAD;
   my( @ymd, $jd, $year );

   if ( $date =~ /^[\d.]+$/)
      {
      $jd = $date;
      @ymd = inverse_julian_day( $jd );
      $year = $ymd[0];
      }
   else
      {
      $date =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/i;
      @ymd = ( $1, $2, $3 );
      $year = $1;
      $jd = julian_day( @ymd ) - .5 + $4 / 24.0 + $5 / 1440.0 + $6 / 86400.0;
      }

   my $bjd      = julian_day( $year, 1, 1 ) - .5;
   #
   #  First routine wants the day to start at 1, not zero
   my $day      = floor( $jd - $bjd + 1.0 );
   my $frac_day = frac( $jd - $bjd );
   #
   # The julian year should start at 0, not 1, so we subtract 1 from the
   # day here
   my $jy = $year + (($day - 1.0) + $frac_day) / 365.25;

   my @earth = earth( $year, $day, $frac_day );
   my @precmat = prec( 2000.0, $jy );
   my @v = dcs2c( $ra, $dec );
   my @star = dmxv( \@precmat, \@v );
   my $correction =
      ( $earth[ 0 ] * $star[ 0 ] + $earth[ 1 ] * $star[ 1 ] + $earth[ 2 ] *
      $star[ 2 ] ) * ( 499.004782 / 86400.0 );
   #
   # Return all the info if desired
   if ( wantarray )
      {
      return ( $correction, $jd, $jd + $correction );
      }
   #
   # otherwise, just return the correction
   else
      {
      return $correction;
      }
   }

sub earth
   {
   my ( $iy, $id, $fd ) = @_;
   my @pv;

   my $yi  = $iy - 1900.0;
   my $iy4 = $iy >= 0.0 ? $iy % 4.0 : 3.0 - ( -$iy - 1.0 ) % 4.0;
   my $yf  =
      ( ( 4.0 * ( $id - floor( 1.0 / ( $iy4 + 1.0 ) ) ) - $iy4 - 2.0 ) + 4.0 *
      $fd ) / 1461.0;
   my $t = $yi + $yf;
   my $elm = mod( 4.881627938 + PI2 * $yf + 0.00013420 * $t, PI2 );
   my $gam = 4.90823 + 3.0005e-4 * $t;
   my $em = $elm - $gam;
   my $eps0 = 0.40931975 - 2.27e-6 * $t;
   my $e   = 0.016751 - 4.2e-7 * $t;
   my $esq = $e * $e;
   my $v = $em + 2.0 * $e * sin( $em ) + 1.25 * $esq * sin( 2.0 * $em );
   my $elt = $v + $gam;
   my $r = ( 1.0 - $esq ) / ( 1.0 + $e * cos( $v ) );
   my $elmm = mod( 4.72 + 83.9971 * $t, PI2 );
   my $coselt = cos( $elt );
   my $sineps = sin( $eps0 );
   my $coseps = cos( $eps0 );
   my $w1     = -$r * sin( $elt );
   my $w2     = -( SPEED ) * ( $coselt + $e * cos( $gam ) );
   my $selmm  = sin( $elmm );
   my $celmm  = cos( $elmm );
   $pv[ 0 ] = -$r * $coselt - REMB * $celmm;
   $pv[ 1 ] = ( $w1 - REMB * $selmm ) * $coseps;
   $pv[ 2 ] = $w1 * $sineps;
   $pv[ 3 ] = SPEED * ( sin( $elt ) + $e * sin( $gam ) ) + SEMB * $selmm;
   $pv[ 4 ] = ( $w2 - SEMB * $celmm ) * $coseps;
   $pv[ 5 ] = $w2 * $sineps;
   return @pv;
   }

sub prec
   {
   my ( $ep0, $ep1 ) = @_;
   my $t0 = ( $ep0 - 2000.0 ) / 100.0;
   my $t = ( $ep1 - $ep0 ) / 100.0;
   my $tas2r = $t * AS2RAD;
   my $w     = 2306.2181 + ( ( 1.39656 - ( 0.000139 * $t0 ) ) * $t0 );
   my $zeta  =
      ( $w + ( ( 0.30188 - 0.000344 * $t0 ) + 0.017998 * $t ) * $t ) * $tas2r;
   my $z =
      ( $w + ( ( 1.09468 + 0.000066 * $t0 ) + 0.018203 * $t ) * $t ) * $tas2r;
   my $theta =
      ( ( 2004.3109 + ( -0.85330 - 0.000217 * $t0 ) * $t0 ) +
      ( ( -0.42665 - 0.000217 * $t0 ) - 0.041833 * $t ) * $t ) * $tas2r;
   return deuler( "ZYZ", -$zeta, $theta, -$z, );
   }

sub deuler
   {
   my ( $order, $phi, $theta, $psi ) = @_;
   my @rmat;
   my @result = ( [ 1.0, 0.0, 0.0 ], [ 0.0, 1.0, 0.0 ], [ 0.0, 0.0, 1.0 ] );
   my $l = length $order;
   for ( my $n = 0; $n < 3; ++$n )
      {
      if ( $n <= $l )
         {
         my @rotn = (
                      [ 1.0, 0.0, 0.0 ], [ 0.0, 1.0, 0.0 ],
                      [ 0.0, 0.0, 1.0 ]
         );
         my $angle;
         $_ = $n;
         SWITCH:
            {
            /0/ && do { $angle = $phi;   last SWITCH };
            /1/ && do { $angle = $theta; last SWITCH };
            /2/ && do { $angle = $psi;   last SWITCH };
            die "unknown value: '$_'";
            }
         my $s = sin( $angle );
         my $c = cos( $angle );
         $_ = substr $order, $n, 1;
         SWITCH:
            {
            /[x1]/i && do
               {
               $rotn[ 1 ][ 1 ] = $c;
               $rotn[ 1 ][ 2 ] = $s;
               $rotn[ 2 ][ 1 ] = -$s;
               $rotn[ 2 ][ 2 ] = $c;
               last SWITCH;
            };
            /[y2]/i && do
               {
               $rotn[ 0 ][ 0 ] = $c;
               $rotn[ 0 ][ 2 ] = -$s;
               $rotn[ 2 ][ 0 ] = $s;
               $rotn[ 2 ][ 2 ] = $c;
               last SWITCH;
            };
            /[z3]/i && do
               {
               $rotn[ 0 ][ 0 ] = $c;
               $rotn[ 0 ][ 1 ] = $s;
               $rotn[ 1 ][ 0 ] = -$s;
               $rotn[ 1 ][ 1 ] = $c;
               last SWITCH;
            };
            die "unknown character: '$_'";
            }
         my @wm;
         for ( my $i = 0; $i < 3; ++$i )
            {
            for ( my $j = 0; $j < 3; ++$j )
               {
               my $w = 0.0;
               for ( my $k = 0; $k < 3; ++$k )
                  {
                  $w += $rotn[ $i ][ $k ] * $result[ $k ][ $j ];
                  }
               $wm[ $i ][ $j ] = $w;
               }
            }
         for ( my $j = 0; $j < 3; ++$j )
            {
            for ( my $i = 0; $i < 3; ++$i )
               {
               $result[ $i ][ $j ] = $wm[ $i ][ $j ];
               }
            }
         }
      }
   for ( my $j = 0; $j < 3; ++$j )
      {
      for ( my $i = 0; $i < 3; ++$i )
         {
         $rmat[ $i ][ $j ] = $result[ $i ][ $j ];
         }
      }
   return @rmat;
   }

sub dmxv
   {
   my ( $dm, $va ) = @_;
   my ( @vb, @vw );
   for ( my $j = 0; $j < 3; ++$j )
      {
      my $w = 0.0;
      for ( my $i = 0; $i < 3; ++$i )
         {
         $w += $dm->[ $j ][ $i ] * $va->[ $i ];
         }
      $vw[ $j ] = $w;
      }
   for ( my $j = 0; $j < 3; ++$j )
      {
      $vb[ $j ] = $vw[ $j ];
      }
   return @vb;
   }

sub dcs2c
   {
   my ( $a, $b ) = @_;
   my @v;
   my $cosb = cos( $b );
   $v[ 0 ] = cos( $a ) * $cosb;
   $v[ 1 ] = sin( $a ) * $cosb;
   $v[ 2 ] = sin( $b );
   return @v;
   }

"Should you really be looking here?";
__END__

=head1 NAME

Astro::Time::HJD - Perl extension for calculating heliocentric julian date
adjustment.

=head1 SYNOPSIS

 use Astro::Time::HJD qw( correction );
 ($correction, $jd, $hjd ) = correction( $jd, $ra, $dec );
 $correction = correction( $jd, $ra, $dec );

=head1 DESCRIPTION

Given an observation date, right ascention and declination, calculates the
correction to be added to the julian date of the observation to adjust it's
observation time to a heliocentric julian date.

=head1 USAGE

=over

=item B<correction>

=over

=item C<(SCALAR, SCALAR, SCALAR) = correction( SCALAR, SCALAR, SCALAR )>

=item C<SCALAR = correction( SCALAR, SCALAR, SCALAR )>

The first form returns the heliocentric correction (in julian days),
the original julian date and the adjusted julian date for the given
observation time and RA/DEC location.  
The second form returns just the heliocentric correction.
The correction should be added from the julian date of the observation.
The first argument to the function is the date
of the observation. The date can be either a
julian date or a zero padded date time string of the form
'YYYY-MM-DDTHH:MM:SS'.  The second and third arguments are the RA and
DEC, respectively, given in decimal degrees.

=back

=back

=head1 ACCURACY

The algorithms implemented have a stated accuracy of "better than .1 seconds
from 1900 through 2050" per Patrick Wallace.  Write me in 2049 and I'll see
about updating this.

=head1 AUTHOR

Robert Creager E<lt>Astro-HJD@LogicalChaos.orgE<gt>

Patrick Wallace, personal communication
Michael Koppelman, personal communication

=cut

