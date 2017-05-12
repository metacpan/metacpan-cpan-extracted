
# ======================================================================
#                   U t i l i t y   f u n c t i o n s
# These are functions that may be used by other local modules. 
package Util;
use Math::Trig;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(circle radians frac);

my $PI = 4.0 * atan2(1.0,1.0);
use strict;

# Rationalize the argument in gegrees into range 0...360.
sub circle{
  my $angle = shift;
  $angle = $angle - int($angle/360)*360;
  if ($angle < 0.0) {$angle += 360.0;}
  return $angle;
}

# convert degrees to radians, rationalizing as needed.
sub radians{
  my $angle = shift;
  $angle = $angle - int($angle/360)*360;
  if ($angle < 0.0) {$angle += 360.0;}
  return $angle * $PI/180.0;
}

# what does it do exactly?
sub frac{
  my $x = shift;
  my $a;
  $a = $x - int($x);
  $a += 1 if ($a < 0);
  return $a;
}

1;
# ======================================================================
#           B a s e   c l a s s   f o r   L u m i n i r i e s
package Luminary;
use strict;
sub circle{return Util::circle(@_)};
#my $PI = 4.0 * atan2(1.0,1.0);
my $rad = $PI/180.0;
sub new{
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { @_ };
  bless $self, $class;
  return $self;
}
sub sinalt{
  my $self = shift;
  my $dayid = shift || 0;
  my $hour = shift;
  my $d = $self->{jdate} -2451545 +$dayid;
  my $t = ($d + $hour/24.0 - $self->{tzone}/24.0 )/36525.0;
  $d = $t * 36525.0;
  my ($ra,$dec) = $self->radec($t);
  my $lmst = circle(280.46061837 + 360.98564736629* $d +
    0.000387933 *$t*$t - $t*$t*$t / 38710000)/15.0 +
    $self->{longitude}/15.0;
  my $tau = 15.0 * ($lmst - $ra);
  return  sin($rad*$self->{latitude}) * sin($rad*$dec) + 
         cos($rad*$self->{latitude}) * cos($rad*$dec) * 
         cos($rad * $tau);
}
sub riseset{
  my $self = shift;
  my $dayid = shift || 0;
  my $above = undef;
  my $hour = 1.0;
  my $utrise = undef;
  my $utset = undef;
  my $rads = 0.0174532925;
  my $sinho = $self->sinho(); #sin($rads * -0.833);
  my $ym = $self->sinalt($dayid,$hour - 1.0) - $sinho;
  $above = 'always above'  if ($ym > 0.0); 
  while($hour < 25 && (not defined($utset) or not defined($utrise))) {
    my $yz = $self->sinalt($dayid,$hour) - $sinho;
    my $yp = $self->sinalt($dayid,$hour + 1.0) - $sinho;
    my ($nz, $z1, $z2, $xe, $ye)  = quad($ym, $yz, $yp);
    # case when one event is found in the interval
    if ($nz == 1) {
      if ($ym < 0.0) { $utrise = $hour + $z1; }
    else { $utset = $hour + $z1; }
    } # end of nz = 1 case
    # case where two events are found in this interval
    # (rare but whole reason we are not using simple iteration)
    if ($nz == 2) {
      if ($ye < 0.0) {
        $utrise = $hour + $z2; $utset = $hour + $z1;
      }else{
        $utrise = $hour + $z1; $utset = $hour + $z2;
      }
    }
    # set up the next search interval
    $ym = $yp;
    $hour += 2.0;
  } # end of while loop
  return ($utrise,$utset,$above);
}
# quad finds the parabola throuh the three points (-1,ym), (0,yz), (1, yp)
# and returns the coordinates of the max/min (if any) xe, ye
# the values of x where the parabola crosses zero (roots of the quadratic)
# and the number of roots (0, 1 or 2) within the interval [-1, 1]
#  results passed as array [nz, z1, z2, xe, ye]
sub quad{
  my $ym = shift;
  my $yz = shift;
  my $yp = shift;
  my $nz = 0;
  my $a = 0.5 * ($ym + $yp) - $yz;
  my $b = 0.5 * ($yp - $ym);
  my $c = $yz;
  my $xe = -$b / (2 * $a);
  my $ye = ($a * $xe + $b) * $xe + $c;
  my $dis = $b * $b - 4.0 * $a * $c;
  my ($z1,$z2);
  if ($dis > 0){
    my $dx = 0.5 * sqrt($dis) / abs($a);
    $z1 = $xe - $dx;
    $z2 = $xe + $dx;
    if (abs($z1) <= 1.0) {$nz += 1;}
    if (abs($z2) <= 1.0) {$nz += 1;}
    if ($z1 < -1.0) {$z1 = $z2;}
  }
  return ($nz,$z1,$z2,$xe,$ye);
}
sub ayanamsa{
  # Source: http://www.jyotishtools.com/JScripts/bhavcalc.htm
  #Calculate the Lahiri Ayanamsa by using 
  #Erlewine Fagan-Bradley sidereal calculation
  # with correction using Lahiri 1900 value in minutes (see below)
  # Correct jd with hr and tz values and reduce to fract of centuries.
  my $self = shift;
  my $d2r = 0.0174532925;
  my $t = (($self->{jdate} - 2415020) - 0.5)/36525;
  my $ln = ((933060-6962911*$t+7.5*$t*$t)/3600.0) % 360.0;  # Mean lunar node
  my $off = (259205536.0*$t+2013816.0)/3600.0;            # Mean Sun
  $off = 17.23*sin($d2r * $ln)+1.27*sin($d2r * $off)-(5025.64+1.11*$t)*$t;
  $off = ($off- 80861.27)/3600.0;  # 84038.27 = Fagan-Bradley 80861.27 = Lahiri
  return $off;
}
sub longitude{
	my $self = shift;
	my $time = shift || 0.0;
	$self->setLongitude($time) unless exists $self->{gclong};
	return $self ->{gclong};
}

# Nirayana longitude.
sub n_long{
  my $self = shift;
  my $time = shift || 0.0;
  my $t = $self->longitude($time) + $self->ayanamsa();
  $t += 360.0 if $t < 0.0;
  return $t;
}
1;
# ======================================================================



# ======================================================================
#               T h e    S u n    O b j e c t 
package Sun;
use strict;
our @ISA = qw (Luminary);
use Math::Trig;
use constant PI => 4.0 * atan2(1.0,1.0);
sub circle{return Util::circle(@_)};
sub radians{return Util::radians(@_)};
sub frac{return Util::frac(@_)};

sub setLongitude{
    my $self = shift;
    my $time = shift;
    my $t = ($self->{jdate} -2415020 +$time -$self->{tzone}/24.0) / 36525.0;
    my $dn = $t * 36525.0;
    my $t2 = $t*$t;
    my $t3 = $t2* $t;
    my $mnln  =  radians ( 279.69668 + $t * 36000.76892 + $t2 * 0.0003025 ); 
    my $ecc   =  0.01675104 - $t  * 0.0000418 - $t2 * 0.000000126;  
    my $orbr  =  1.0000002;
    my $anom = radians(358.475833+35999.04975*$t -1.50e-4*$t*$t -3.3e-6*$t*$t*$t);
    my $anmn  =  $anom;
    my $daily =  radians(1.0);
    my $a =  radians ( 153.23 + 22518.7541 * $t );
    my $b =  radians ( 216.57 + 45037.5082 * $t );
    my $c =  radians ( 312.69 + 32964.3577 * $t );
    my $d =  radians ( 350.74 + 445267.1142 * $t - 0.00144 * $t2 );
    my $e =  radians ( 231.19 + 20.20 * $t );
    my $h =  radians ( 353.40 + 65928.7155 * $t );
    my $c1 = radians (( 1.34 * cos ( $a ) + 1.54 * cos ( $b )
      + 2.0  * cos ( $c ) + 1.79 * sin ( $d )
      + 1.78 * sin ( $e ) ) * 1.00e-3);
    my $c2 = radians(( 0.543 *sin ( $a ) + 1.575*sin ( $b )
      + 1.627 *sin ( $c ) + 3.076 * cos ( $d )
      + 0.927 *sin ( $h ) ) * 1.0e-5 );
    my $incl  = 0.0;
    my $ascn  = 0.0;
    my $anec  = 0.0;
    #incl  *= PiBy180 ;
    #ascn  *= PiBy180 ;

    for( my$eold = $anmn; abs( $anec -$eold ) > 1.0e-8; $eold = $anec){
      $anec = $eold +  ( $anmn + $ecc * sin( $eold ) - $eold )
             / ( 1.0 -  $ecc * cos ( $eold ) );
      } 
    my $antr = atan ( sqrt ( (1.0 + $ecc ) / ( 1.0 - $ecc ) )
       *  tan ( $anec  / 2.0 ) ) * 2.0 ;
    $antr  += 2.0*PI  if ( $antr <  0.0 ) ;
  
    #  calculate the helio centric longitude  trlong.
    my $u  =  $mnln + $antr - $anmn - $ascn ;
    $u  -= 2.0*PI if ( $u > 2.0*PI )  ;
    $u  += 2.0*PI if ( $u < 0.0 )  ;
    my $n  = int( $u  *2.0 /  PI );
    my $uu =  atan ( cos ( $incl ) * tan ( $u ) ) ;
    $uu += PI if  $n !=  int ( $uu *2.0/ PI )  ;
    $uu += PI if ( $n == 3 ) ;
    my $trlong   = $uu + $ascn + $c1;
    my $rad   = $orbr * ( 1.0 - $ecc * cos ( $anec ) ) + $c2;
    #my $erad = $rad;
    #my $elong = $trlong;
    $self->{gclong} =  circle($trlong * 180.0 / PI);
    return $self->{gclong};
}
sub sinho{
  my $rads = 0.0174532925;
  my $sinho = sin($rads * -0.833);
}
sub radec{
  my $self = shift;
  my $t = shift; #($self->{jdate} -2451544.5)/36524.0;
  my $p2 = 6.283185307; 
  my $arc = 206264.8062;
  my $coseps = 0.91748;
  my $sineps = 0.39778;
  my $M = $p2 * frac(0.993133 + 99.997361 * $t);
  my $DL = 6893.0 * sin($M) + 72.0 * sin(2 * $M);
  my $L = $p2 * frac(0.7859453 + $M / $p2 + (6191.2 * $t + $DL)/1296000);
  my $SL = sin($L);
  my $X = cos($L);
  my $Y = $coseps * $SL;
  my $Z = $sineps * $SL;
  my $RHO = sqrt(1 - $Z * $Z);
  my $dec = (360.0 / $p2) * atan($Z / $RHO);
  my $ra = (48.0 / $p2) * atan($Y / ($X + $RHO));
  $ra += 24 if ($ra <0 );
  return ($ra,$dec);
}
1;

# ======================================================================


# ======================================================================
#               T h e    M o o n    O b j e c t 

package Moon;
use strict;
use Math::Trig;
our @ISA = qw (Luminary);
sub circle{return Util::circle(@_)};
sub radians{return Util::radians(@_)};
sub frac{return Util::frac(@_)};

sub setLongitude {
    my $self = shift;
    my $time = shift;
    #my $t = ($self->{jdate} -2415020 + $self->{time}) / 36525.0;
    my $t = ($self->{jdate} -2415020 +$time -$self->{tzone}/24.0) / 36525.0;
    my $dn = $t * 36525.0;
    my ($A,$B,$C,$D,$E,$F, $l, $M, $mm);
    my $t2 = $t*$t;
    my $t3 = $t2* $t;
    my ($ang,$ang1);
    my $anom = circle(358.475833+35999.04975*$t -1.50e-4*$t2 -3.3e-6*$t3); 
    $A  = 0.003964 * sin ( radians( 346.56 +
          $t * 132.87 - $t2 * 0.0091731) );
    $B  = sin (  radians( 51.2 + 20.2 * $t )  );
    my $omeg  = circle ( 259.183275 - 1934.1420 * $t
       + 0.002078 * $t2 + 0.0000022 * $t3 );
    $C  = sin ( radians($omeg) );

    $l  = circle ( 270.434164 + 481267.8831 * $t - 0.001133 * $t2 + 0.0000019 * $t3 + 0.000233 * $B + $A + 0.001964 * $C );
    $mm = radians ( 296.104608 + 477198.8491 * $t + 0.009192 * $t2 + 1.44e-5 * $t3 + 0.000817 * $B + $A + 0.002541 * $C );
    $D  = radians ( 350.737486 + 445267.1142 * $t - 0.001436 * $t2 + 1.9e-6 * $t3 + $A + 0.002011 * $B + 0.001964  * $C );
    $F  = radians ( 11.250889 + 483202.0251 * $t - 0.003211 * $t2 - 0.0000003 * $t3 + $A - 0.024691 * $C 
          - 0.004328 * sin ( radians ( $omeg + 275.05 - 2.3 * $t ) ) ) ;
    $M  = radians( $anom - 0.001778  * $B );
    $E  = 1.0 - 0.002495 * $t - 0.00000752 * $t2;                    
    $ang =  $l
            + 6.288750  * sin ( $mm )
            + 1.274018 * sin ( $D + $D - $mm )
	    + 0.658309 * sin ( $D + $D )
            + 0.213616 * sin ( $mm + $mm )
	    - 0.114336 * sin ( $F + $F )
	    + 0.058793  * sin ( $D + $D -$mm -$mm );
    $ang = $ang + 0.053320  * sin ( $D + $D + $mm )
           - 0.034718  * sin ( $D )
	   + 0.015326  * sin ( $D + $D - $F - $F )
           - 0.012528  * sin ( $F + $F  + $mm )
	   - 0.010980  * sin ( $F + $F -$mm );
    $ang = $ang + 0.010674  * sin ( 4.0 * $D - $mm  ) 
           + 0.010034  * sin ( 3.0 * $mm )
           + 0.008548  * sin ( 4.0 * $D -$mm -$mm )
           + 0.005162  * sin ( $mm -$D )
	   + 0.003996  * sin ( $mm + $mm +$D + $D )
	   + 0.003862  * sin ( 4.0 * $D );
    $ang = $ang + 0.003665  * sin ( $D +$D - $mm -$mm - $mm )
           + 0.002602  * sin ( $mm - $F - $F - $D - $D )
	   - 0.002349  * sin ( $mm + $D )
           - 0.001773  * sin ( $mm +$D + $D -$F - $F )
	   - 0.001595  * sin ( $F + $F + $D + $D )
	   - 0.001110  * sin ( $mm + $mm + $F + $F );
    $ang1 = -0.185596   * sin ( $M )
            + 0.057212  * sin ( $D + $D - $M - $mm )
	    + 0.045874  * sin ( $D + $D - $M )
            + 0.041024  * sin ( $mm - $M )
	    - 0.030465  * sin ( $mm + $M )
	    - 0.007910  * sin ( $M - $mm + $D + $D )
            - 0.006783  * sin ( $D + $D + $M )
	    + 0.005000  * sin ( $M + $D );
    $ang1 = $ang1 + 0.004049  * sin ( $D +$D + $mm - $M )
            + 0.002695  * sin ( $mm + $mm - $M )
	    + 0.002396  * sin ( $D + $D - $M - $mm - $mm )
            - 0.002125  * sin ( $mm + $mm + $M  )
	    + 0.001220  * sin ( 4.0 * $D - $M - $mm );
    $ang1 = $ang1 + $E * (
	        0.002249  * sin ( $D + $D - $M - $M )
	      - 0.002079  * sin ( $M + $M )
	      + 0.002059  * sin ( $D + $D - $M - $M -$mm )
            );

    $self->{gclong} = circle ($ang  + $E * $ang1);
    }
sub sinho{
  my $rads = 0.0174532925;
  my $sinho = sin($rads * 8.0/60.0);
}

sub radec{
  # takes t and returns the geocentric ra and dec in an array mooneq
  # claimed good to 5' (angle) in ra and 1' in dec
  # tallies with another approximate method and with ICE for a couple of dates
  my $self = shift;
  my $t = shift;
  my $p2 = 6.283185307; 
  my $arc = 206264.8062;
  my $coseps = 0.91748;
  my $sineps = 0.39778;
  my $L0 = frac(0.606433 + 1336.855225 * $t);  # mean longitude of moon
  my $L = $p2 * frac(0.374897 + 1325.552410 * $t); #mean anomaly of Moon
  my $LS = $p2 * frac(0.993133 + 99.997361 * $t); #mean anomaly of Sun
  my $D = $p2 * frac(0.827361 + 1236.853086 * $t); #diff in longitude of moon and sun
  my $F = $p2 * frac(0.259086 + 1342.227825 * $t); #mean argument of latitude

  # corrections to mean longitude in arcsec
  my $DL =  22640 * sin($L)  -4586 * sin($L - 2*$D) +2370 * sin(2*$D);
  $DL +=  +769 * sin(2*$L)  -668 * sin($LS) -412 * sin(2*$F);
  $DL +=  -212 * sin(2*$L - 2*$D) -206 * sin($L + $LS - 2*$D);
  $DL +=  +192 * sin($L + 2*$D) -165 * sin($LS - 2*$D);
  $DL +=  -125 * sin($D) -110 * sin($L + $LS) +148 * sin($L - $LS);
  $DL +=   -55 * sin(2*$F - 2*$D);

  # simplified form of the latitude terms
  my $S = $F + ($DL + 412 * sin(2*$F) + 541* sin($LS)) / $arc;
  my $H = $F - 2*$D;
  my $N =   -526 * sin($H)+44 * sin($L + $H) -31 * sin(-$L + $H);
  $N +=   -23 * sin($LS + $H) +11 * sin(-$LS + $H) -25 * sin(-2*$L + $F);
  $N +=   +21 * sin(-$L + $F);

  # ecliptic long and lat of Moon in rads
  my $L_moon = $p2 * frac($L0 + $DL / 1296000);
  my $B_moon = (18520.0 * sin($S) + $N) /$arc;

  # equatorial coord conversion - note fixed obliquity
  my $CB = cos($B_moon);
  my $X = $CB * cos($L_moon);
  my $V = $CB * sin($L_moon);
  my $W = sin($B_moon);
  my $Y = $coseps * $V - $sineps * $W;
  my $Z = $sineps * $V + $coseps * $W;
  my $RHO = sqrt(1.0 - $Z*$Z);
  my $dec = (360.0 / $p2) * atan($Z / $RHO);
  my $ra = (48.0 / $p2) * atan($Y / ($X + $RHO));
  $ra += 24 if ($ra <0 );
  return ($ra,$dec);
}
1;
# ======================================================================


# ======================================================================
#               T h e    I n d i a n    D a t e     O b j e c t 
package Date::Indian;
use strict;
our @ISA = qw (Util);
our $VERSION = '0.01';
use Math::Trig;

#sub circle{return Util::circle(@_)};
#sub radians{return Util::radians(@_)};
#sub sind{return Util::sind(@_)};
#sub cosd{return Util::cosd(@_)};
#sub asind{return Util::asind(@_)};
#sub acosd{return Util::acosd(@_)};
#sub angle{return Util::angle(@_)};

sub new{
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {
    ymd   => undef,   # ex: ymd   => '2003-10-31'
    tz    => undef,   # ex: tz    => '-5:30'
    locn  => undef,   # ex: locn  =>'82:30E 17:25N'
    jdate => undef,   # ex: jdate => 2452850.93055556 (2003-7-30 10:20hrs)
    @_
  };
  bless $self, $class;
  $self->_dotz(); $self->_dolocn();
  if ($self->{jdate}){
    $self->_getdatetime();
  }else{
    $self->_doymd();
  }
  #$self->_getdatetime();
  return $self;
}

sub _doymd{
  my $self = shift;
  my ($y,$m,$d) = split(/-/,$self->{ymd});
  $self -> {year} = $y; $self->{month} = $m; $self->{day} = $d;
  $self->{jdate} = $self->_juliandate();
}

sub _dotz{
  my $self = shift;
  my ($h,$m) = split(/:/,$self->{tz});
  $m *= -1 if $h < 0; $h = $h + $m / 60.0;
  $self->{tzone} = $h;
}

sub _dolocn{
  my $self = shift;
  my ($lon,$lat) = split(/ /,$self->{locn});
  my ($d,$m) = split(/:/,$lon); $m *= -1 if $d < 0; $lon = $d + $m / 60.0;
  ($d,$m) = split(/:/,$lat); $m *= -1 if $d < 0; $lat = $d + $m / 60.0;
  $self->{longitude} = $lon;
  $self->{latitude}  = $lat;
}

sub _juliandate{
  my $self  = shift;
  my $year  = $self->{year};
  my $month = $self->{month};
  my $date  = $self->{day};
  if ( $month > 2 ) {
    $month -= 3;
  }else {
    $month += 9; $year -= 1;
  }
  my $tod = $self->{time} / 24.0;  #part of the curr. day.
  my $c = int($year/100); $year %= 100;
  return (int(146097*$c/4) +
    int(1461*$year/4) +
    int((153*$month +2)/5) +
    $date) +
    1721118.5+ $tod; 
}

sub  _getdatetime{
  my $self = shift;
  my $dayno = $self->{jdate} +0.5 +$self->{tzone}/24.0;
  my $i = int($dayno); my $f = $dayno-$i;
  my $b = $i;
  if ( $i > 2299160 ){
    my $a = int(($i - 1867216.25)/36524.25);
    $b = $i + 1 + $a - int($a/4);
  }
  my $c = $b + 1524;
  my $d = int(($c-122.1)/365.25);
  my $e = int(365.25*$d);
  my $g = int(($c-$e)/30.6001);
  my $day = $c -$e +$f -int(30.6001*$g);
  my $mon = $g -1;
  $mon -= 12 if $g > 13.5;
  my $year = $d - 4715;
  $year -= 1 if $mon > 2.5;
  $self->{time} = $day - int($day);
  $self->{day} = int($day);
  $self->{month} = $mon;
  $self->{year} = $year;
}

sub ymd{
  my $self = shift;
  $self->_getdatetime unless $self->{year};
  return ($self->{year}, $self->{month}, 
  $self->{day}, $self->{time}*24.0);
}

sub jdate{
  my $self = shift;
  return $self->{jdate};
}

sub moon{
  my $self = shift;
  my $time = shift || 0.0;
  return  Moon->new(
    jdate     => $self->{jdate},
    tzone     => $self->{tzone},
    latitude  => $self->{latitude},
    longitude => $self->{longitude},
  );
  return $self->{Moon};
};

sub sun{
  my $self = shift;
  my $time = shift || 0.0;
  return Sun->new(
    jdate     => $self->{jdate},
    tzone     => $self->{tzone},
    latitude  => $self->{latitude},
    longitude => $self->{longitude},
  );
};

# =========================================================================================
#                           S e r v i c e :  D a y  o f  t h e  w e e k 
# =========================================================================================
sub weekday{
  my $self = shift;
  return int($self->{jdate}+2) % 7;
}

# =========================================================================================
#                           S e r v i c e :  S u n  r i s e / s e t
# =========================================================================================
sub sunriseset{
  my $self = shift;
  my $sun  = $self->sun;
  my $offset = shift || 0.0;
  return $sun->riseset($offset);
}

# =========================================================================================
#                           S e r v i c e :  M o o n  r i s e / s e t
# =========================================================================================
sub moonriseset{
  my $self = shift;
  my $moon  = $self->moon;
  my $offset = shift || 0.0;
  return $moon->riseset($offset);
}

# =========================================================================================
#                           T i t h i    S e r v i c e
# =========================================================================================
sub tithi{
  my $self = shift;
  my $time = shift;
  my $sun   = $self->sun();
  my $moon  = $self->moon();
  my $t;
  $t = $moon->longitude($time) - $sun->longitude($time);
  $t += 360 if $t < 0.0;
  return $t / 12.0;
}

# Compute tithi endings. At times there are two though most often just one.
# for example: Aug 6, 2003
sub tithi_endings{
  my $self = shift;
  my %th; # Hash of tithi endings at most 2 entries.
  my ($t1, $tm1) = $self->_endtithi(-0.5); $th{$t1} = $tm1 if $tm1;
  my ($t2, $tm2) = $self->_endtithi( 0.0); $th{$t2} = $tm2 if $tm2;
  my ($t3, $tm3) = $self->_endtithi(+0.5); $th{$t3} = $tm3 if $tm3;
  return %th;
}

sub _endtithi{
  my $self  = shift;
  my $st = shift;
  my $t1 = $self -> tithi($st);   # At the start of the cal. date.
  my $tid = (int($t1))%30;
  my $cnt = 0;
  my $et = $st;
  for (my $togo = 1.0; abs($togo) > 0.00001;){
    if (int($t1) == $tid){
     $togo =  1 - ($t1 - int($t1));
    }else{
      $togo = -($t1 - int($t1));
    }
    $et += $togo*27.5/24.0;
    $t1 = $self->tithi($et);
    $cnt ++;
  }
  return ($tid, $et*24.0) if $et >= 0.0 && $et < 1.0;
  return (undef,undef);
}

# =========================================================================================
#                           N a k s h y a t r a    S e r v i c e
# =========================================================================================
sub nakshyatram{
  my $self = shift;
  my $time = shift;
  my $moon  = $self->moon();
  my $t;
  my $ay = $moon -> ayanamsa();
  $t = $moon->longitude($time) + $ay;
  $t += 360 if $t < 0.0;
  return $t * 3.0 / 40.0 ;
}

sub nakshyatra_endings{
  my $self = shift;
  my %th ; # Hash of nakshyatra endings at most 2 entries.
  my ($t0, $tm0) = $self->_endnakshyatra(-1); $th{$t0} = $tm0 if $tm0;
  my ($t1, $tm1) = $self->_endnakshyatra(-0.5); $th{$t1} = $tm1 if $tm1;
  my ($t2, $tm2) = $self->_endnakshyatra( 0.0); $th{$t2} = $tm2 if $tm2;
  my ($t3, $tm3) = $self->_endnakshyatra(+0.5); $th{$t3} = $tm3 if $tm3;
  my ($t4, $tm4) = $self->_endnakshyatra(+1); $th{$t4} = $tm4 if $tm4;
  return %th;
}

sub _endnakshyatra{
  my $self  = shift;
  my $st = shift;
  my $t1 = $self -> nakshyatram($st);   # At the start of the cal. date.
  my $tid = (int($t1))%27;
  my $cnt = 0;
  my $et = $st;
  for (my $togo = 1.0; abs($togo) > 0.00001;){
    if (int($t1) == $tid){
     $togo =  1 - ($t1 - int($t1));
    }else{
      $togo = -($t1 - int($t1));
    }
    $et += $togo*30/24.0;
    $t1 = $self->nakshyatram($et);
    $cnt ++;
  }
  return ($tid, $et*24.0);# if $et >= 0.0 && $et < 1.0;
  return (undef,undef);
}

# =========================================================================================
#             S e r v i c e  :     k a r t e  ( S u n   c h a r a )
# =========================================================================================
# sunchara tracks the movement of the Sun on Zondiac of 27 starrs.
# For this we can assume uniform motion of the Sun, no problem.
sub sunchara{
  my $self = shift;
  my $n_sun  = $self->sun->n_long() *108/360.0;
  my $n_sun1 = $self->sun()->n_long(1.0) *108/360.0;
  if (int($n_sun1) > int($n_sun)){ 
    my $t = 24.0 * (int($n_sun1) - $n_sun)/($n_sun1 -$n_sun);
    return ( int($n_sun1), $t );
  }
  return (undef, undef);
}

# =========================================================================================
#             S e r v i c e  :     L e n g t h   o f   d a y t i m e
# =========================================================================================
# How long we have the Sun on a given day?
sub daylength{
  my $self = shift;
  my $sun = $self->sun;
  my ($rise, $set, $flag) = $sun->riseset();
  return $set - $rise;
}

# =========================================================================================
#             S e r v i c e  :     N e w    m o o n    t i m i n g
# =========================================================================================
# Calculation of the moment of the nearest new moon in JD. (the error does not exceed 2 minutes). The result is Julian date/time in UT.
sub newmoon{
  my $self = shift;
  my $arg  = shift;  #  0 => past  1 => next.
  my $knv = int((($self->{jdate} - 2415020.0) / 365.25) * 12.3685) + $arg ;
  my $t = ($self->{jdate} - 2415020.0) / 36525.0;
  my $t2 = $t*$t;
  my $t3 = $t2*$t;
  my $d2r =  atan2(1.0,1.0) / 45.0;
  
  my $jdnv = 2415020.75933 + 29.53058868 * $knv + 0.0001178 * $t2 - 0.000000155 * $t3;
  $jdnv += 0.00033 * sin((166.56 + 132.87 * $t - 0.009173 * $t2) * $d2r);
  my $m = 359.2242 + 29.10535608 * $knv - 0.0000333 * $t2 - 0.00000347 * $t3;
  my $ml = 306.0253 + 385.81691806 * $knv + 0.0107306 * $t2 + 0.00001236 * $t3;
  my $f = 21.2964 + 390.67050646 * $knv - 0.0016528 * $t2 - 0.00000239 * $t3;
  $m *= $d2r; $ml *= $d2r; $f *= $d2r;
  
  my $djd = (0.1734 - 0.000393 * $t) * sin($m) + 0.0021 * sin(2 * $m); 
  $djd = $djd - 0.4068 * sin($ml) + 0.0161 * sin(2 * $ml);
  $djd = $djd - 0.0004 * sin(3 * $ml) + 0.0104 * sin(2 * $f) ;
  $djd = $djd - 0.0051 * sin($m + $ml) - 0.0074 * sin($m - $ml);
  $djd = $djd + 0.0004 * sin(2 * $f + $m) - 0.0004 * sin(2 * $f - $m);
  $djd = $djd - 0.0006 * sin(2 * $f + $ml) + 0.001 * sin(2 * $f - $ml);
  $djd = $djd + 0.0005 * sin($m + 2 * $ml);
  
  $jdnv += $djd;
  return $jdnv;
}

# =========================================================================================
#             S e r v i c e  :  R a h u    k a l a m
# =========================================================================================
sub rahu_kalam{
  my $self = shift;
  my $sun = $self->sun;
  my ($rise, $set, $flag) = $sun->riseset();
  my $d_len = $set - $rise;
  my $weekday = $self->weekday();
  #  week day   Sun  Mon  Tue  Wed  Thu  Fri  Sat
  my $seg =   [   7,   1,   6,   4,   5,   3,   2 ];   
  my $t = $rise + $seg->[$weekday]*$d_len/8 ;
  return ( $t, $t + $d_len/8 );
}
# =========================================================================================
#                S e r v i c e :           G u l i k a    k a l a m
# =========================================================================================

sub gulika_kalam{
  my $self = shift;
  my $sun = $self->sun;
  my ($rise, $set, $flag) = $sun->riseset();
  my $d_len = $set - $rise;
  my $weekday = $self->weekday();
  #  week day   Sun  Mon  Tue  Wed  Thu  Fri  Sat
  my $seg  =  [   6,   5,   4,   3,   2,   1,   0 ];   
  my $t = $rise + $seg->[$weekday]*$d_len/8 ;
  return ( $t, $t + $d_len/8 );
}
# =========================================================================================
#               S e r v i c e :             Y a m a g a n d a    K a l a m
# =========================================================================================

sub yamaganda_kalam{
  my $self = shift;
  my $sun = $self->sun;
  my ($rise, $set, $flag) = $sun->riseset();
  my $d_len = $set - $rise;
  my $weekday = $self->weekday();
  #  week day  Sun  Mon  Tue  Wed  Thu  Fri  Sat
  my $seg  = [   4,   3,   2,   1,   0,   6,   5 ];
  my $t = $rise + $seg->[$weekday]*$d_len/8 ;
  return ( $t, $t + $d_len/8 );
}

# =========================================================================================
#               S e r v  i c e :         D u r m u h u r t a m
# =========================================================================================
sub durmuhurtam{
  my $self = shift;
  my $sun = $self->sun;
  my ($rise, $set, $flag) = $sun->riseset();
  my $d_len = $set - $rise;
  my $weekday = $self->weekday();
  my $d1 = [ 13, 7, 3, 7, 11, 3, 0 ];
  my $d2 = [ undef, 11, 10, undef, 12, 8, 1];
  return (
    $rise + $d1->[$weekday]*$d_len/15.0 ,
      $rise + (1.0 + $d1->[$weekday])*$d_len/15.0 ,
      $d2->[$weekday]? $rise + $d2->[$weekday]*$d_len/15.0 : undef ,
      $d2->[$weekday]? $rise + (1.0 + $d2->[$weekday])*$d_len/15.0 : undef
  );
}

# =========================================================================================
#               S e r v  i c e :         K a r a n a
# =========================================================================================
# Karana calculation.
sub karana{
  # Karana is displacement of moon from sun in 6 deg segments.
  # Tithi is displacement of moon from sun in 12 deg segments.
  my $self = shift;
  my $time = shift;
  return 2 * $self->tithi($time) ;
}
sub karana_endings{
  my $self = shift;
  my %th ;
  my ($t1, $tm1) = $self->_endkarana(-0.5); $th{$t1} = $tm1 if $tm1;
  my ($t2, $tm2) = $self->_endkarana( 0.0); $th{$t2} = $tm2 if $tm2;
  my ($t3, $tm3) = $self->_endkarana(+0.5); $th{$t3} = $tm3 if $tm3;
  return %th;
}
sub _endkarana{
  my $self  = shift;
  my $st = shift;
  my $t1 = $self -> karana($st);   # At the start of the cal. date.
  my $tid = (int($t1))%60;
  my $cnt = 0;
  my $et = $st;
  for (my $togo = 1.0; abs($togo) > 0.00001;){
    if (int($t1) == $tid){
     $togo =  1 - ($t1 - int($t1));
    }else{
      $togo = -($t1 - int($t1));
    }
    $et += $togo*27.5/48.0;
    $t1 = $self->karana($et);
    $cnt ++;
  }
  return ($tid, $et*24.0) if $et >= 0.0 && $et < 1.0;
  return (undef,undef);
}
# =========================================================================================
#               S e r v  i c e :         Y o g a
# =========================================================================================
# Yoga calculation.
sub yoga{
  #  yoga is the sum of longitudes of the lights, the Sun and Moon in segments of 12 degrees.
  my $self = shift;
  my $time = shift;
  my $sun   = $self->sun();
  my $moon  = $self->moon();
  my $t;
  $t = $moon->n_long($time) + $sun->n_long($time);
  $t -= 360 if $t > 360.0;
  return $t * 3.0 / 40.0;
}
sub yoga_endings{
  my $self = shift;
  my %th ; # Hash of tithi endings at most 2 entries.
  my ($t1, $tm1) = $self->_endyoga(-0.5); $th{$t1} = $tm1 if $tm1;
  my ($t2, $tm2) = $self->_endyoga( 0.0); $th{$t2} = $tm2 if $tm2;
  my ($t3, $tm3) = $self->_endyoga(+0.5); $th{$t3} = $tm3 if $tm3;
  return %th;
}
sub _endyoga{
  my $self  = shift;
  my $st = shift;
  my $t1 = $self -> yoga($st);   # At the start of the cal. date.
  my $tid = (int($t1))%27;
  my $cnt = 0;
  my $et = $st;
  for (my $togo = 1.0; abs($togo) > 0.00001;){
    if (int($t1) == $tid){
     $togo =  1 - ($t1 - int($t1));
    }else{
      $togo = -($t1 - int($t1));
    }
    $et += $togo*27.5/24.0;
    $t1 = $self->yoga($et);
    $cnt ++;
  }
  return ($tid, $et*24.0) if $et >= 0.0 && $et < 1.0;
  return (undef,undef);
}
# =========================================================================================
#               S e r v  i c e :        V a r j y a m 
# =========================================================================================
# This service returns any varjyas for this day in an array.
# The times given are starting times. Each  varjya ends in 1:30 hrs 
# from the its starting time.
#
# Aswini 50; Bharani 4; Krittika 30; Rohini 40; Mrigasira 14; Aridra 21;
# Punarvasu 30; Pushya 20; Aslesha 32; Makha 30; Pubba 20; Uttara 1; 
# Hasta 21; Chitta 20; Swati 14; Visakha 14; Anuradha 10; Jyeshta 14;
# Moola 20; Poorvashadha 20; Uttarashadha 20; Sravana 10; Dhanishta 10;
# Satabhisha 18; Poorvabhadra 16; Uttarabhadra and Revati 30		     

my $tyajyam =  [
 50,  4,  30,  40,  14,  21, 30, 20,  32,
 30,  20,   1, 21, 20,  14,  14,  10,  14,
 20, 20,  20,  10,  10,  18, 16, 30,  30,
];

sub varjyam{
  my $self = shift;
  my @out;
  my %nk = $self->nakshyatra_endings();
  for my $t (sort keys %nk){
     my $prev = $t -1;
     next unless $nk{$prev};
     my $cur_nk = $t;
     my $dur_nk = $nk{$t} - $nk{$prev};
     my $v = ($tyajyam -> [$t] / 60.0) * $dur_nk;
     $v += $nk{$prev};
     push(@out,$v) if $v > 0 && $v <= 24.00;
  }
  return @out;
}

1;
# ======================================================================

# ======================================================================
__END__

=head1	NAME

	Date::Indian	-A module for Indian calendrical calculations.

=head1	SYNOPSIS

	use	Date::Indian;
	my $date = Indian->date(
		ymd	=> '2003:1:1',
		tz	=> '5:30',
		locn	=> '78:18 17:12'
	);


=head1	DESCRIPTION

	This module is not a calander generator. It helps to wirte one by 
	providing essential and auxillary services.
	
	Services offered by this module are:

	 1. Sun rise/set.
	 2. Moon rise/set.
	 3. Tithi at a given time.
	 4. Moon's constallatation at a given time.
	 5. Tithi ending time(s) on a given day.
	 6. Moon's constallation change time(s) on a given day.
	 7. Length of the day (sunrise to sunset).
	 8. Previous / current new moon date and time.
	 9. Next new moon date and time.
	10. Rahu kalam.
	11. Gulika kalam.
	12. Yama gandam.
	13. Durmuhurta periods.
	14. Current yoga.
	15. Current karana.
	16. Yoga change time(s) on given day.
	17. Karana change time(s) on given day.
	18. Weekday.
	19. Julian day.
	20. ymdt ( year, month, day and time values)
	21. Ayanamsa.
	22.

=head1	SERVICES

Here is a description of the services provided by the module.

=over 4

=item Gregorian date and time.

This service provides the date ( and time of the day in hours & fraction of 
hours ) for the given date object.

my (@y, $m, $d, $t ) = $date -> ymd();


=item Sun rise and Sun set

This service is provided by the method sunriseset().

($sunrise, $sunset, $flag) = $date -> sunriseset();

Depending the latitude and time of the year, the Sun may not
rise or set at a given location. This is indicated by the $flag
string data.

=item Moon rise and Moon set

This service is provided by the method moonriseset().

($moonrise, $moonset, $flag) = $date -> moonriseset();

At times the Moon may set or rise more than once on a gicen calendar
day. Also some days the Moon will not rise or set. Such cases are
indicated by the  $flag string.

=item Tithi 

This service is provided by the the following methods.

=over 4

=item  Tithi at a given time.

The method 'tithi' provides this service.

my $tithi = $date -> tithi(<time of the day>);

where the time of the day is expressed as a decimal fraction in the
range 0.0 ..... 1.0 where a 0 value means at 00:00 hrs of the calendar
date and 0.5 the 12:00 noon and 1.0 the begining of the next day.

=item Tithi endings.

The method tithi_endings() provides the service of itentifying when the
a tithi ending occurs on a given date. 

my %t_times = $date->tithi_endings();

At times more than one tithi may end on the same calendar date and on some
days none ends. Hence the method returns an hash where keys are tithi
numbers in the range 0...29 and values corrosponding are times in hours
at local time. Note that the hash may be empty if no tithi ends on a given
calendar date.

=back

=item Nakshatra

=over 4

=item Nakshyatra at a given time.

The method serving is nakshyatra().

$n_time = $date -> nakshyatra(<time of the day>)

=item Nakshyatra endings.

my %n_endings = $date -> nakshyatra_endings ();

This service is analogous to the tithi_endings service.

=back

=item Length of the day

The length of the day is kind of misnomer. It actually is the duration
of the Sun's visibility defined as 
  
     sun set - sun rise

on a given day provied they both are meaningful.

The usage is

$d_length = $date -> daylength();

=item New moon time

The date and time of the most recent new moon is provided by the service.

my $pnm = $date -> newmoon();

The service allowes you to find the 'n' th new moon, if that is needed.

my $next_newmoon = $date -> newmoon(1);

=item Varjyam

This is provided by the method varjyam

my @varjyam = $date -> varjyam();

The array returned provides starting times of varjya periods on the
given date. The ending time of any varjya is always 1.6 hours from
the respective start time. So, ending times are seperately not 
provided by the method.

=item Rahu kalam

This is provided by the method rahu_kalam.

my ($rk_start, $rk_end) = $date -> rahu_kalam ();

The periods of time rahu kalam are controlled by  time of sun rise,
duration of the Sun's visibile time and the week day. 

=item Gulika kalam

This is provided by the method gulika_kalam.

my ($gk_start, $gk_end) = $date -> gulika_kalam();

The periods of time gulika kalam are controlled by  time of sun rise,
duration of the Sun's visibile time and the week day. 

=item Yamaganda kalam

This is provided by the method yamaganda_kalam.

my ($yg_start, $yg_end) = $date -> yamaganda_kalam();

The periods of time yama ganda kalam are controlled by  time of sun rise,
duration of the Sun's visibile time and the week day. 


=item Durmuhurtam

This is provided by the method durmuhurtam.

my ($dm1_start, $dm1_end, $dm2_start, $dm2_end) =
   $date -> drmuhurtam();

The periods of time durmuhurtam are controlled by  time of sun rise,
duration of the Sun's visibile time and the week day.  There may be
one or two durmuhurtha periods on a given day.

=item Karana 

This service is provided by a couple of methods.

=over 4

=item Kanana at a given time

This service is provided by the method karana().
Usage is

my $k = $date -> karana( <time of the day> )

=item Karana ending times

This service works in same way as tithi_endings and nakshyatra_endings.
Note that the karana numbers are in the range 0...,59. But as there are
only 11 karanas, one need to map the karanas to the correct range 0...11
This at present left to the user. ( Consult the demo file for a solution )

=back

=item Sun's position (Karte)

This service is provided by the method sunchara().

my ($nav, $t) = $date -> sunchar();

where $nav is the Sun's navamsa number on the zodiac in the range 0...107.
and $t represents the time of change of navamsa.

Depending on what navamsa number is returned one can understand whether the
Sun is entering a different navamsa, different nakshyatra or a different
sign on the zodiac.

=item Yoga 

The yoga servvice is provided by a couple of methods.

=over 4

=item  Yoga at a given time.

Use yoga() method.

my $yoga = $date -> yoga (<time of the day>);

=item Yoga ending times.

my %y_end = $date -> yoga_endings();

This method works similar to tithi_endings().

=back

=back

=cut

