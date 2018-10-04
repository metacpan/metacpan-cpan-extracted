package Astro::Coord::ECI::VSOP87D;

use 5.008;

use strict;
use warnings;

use Astro::Coord::ECI::Utils qw{
    AU PI SECSPERDAY TWOPI
    asin deg2rad jcent2000 julianday
    load_module looks_like_number mod2pi
    rad2deg rad2dms rad2hms tan
};
use Exporter qw{ import };
use Carp;
use POSIX qw{ floor };
use Storable qw{ dclone };

use constant DAYS_PER_JULIAN_MILENNIUM	=> 365250;
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};
use constant SUN_CLASS	=> __PACKAGE__ . '::Sun';

BEGIN {
    __PACKAGE__->can( 'DEBUG' )
	or constant->import( DEBUG => 0 );
}

our $VERSION = '0.001';

my @basic_export = qw{
    SUN_CLASS
    model_cutoff_definition
    nutation obliquity order period time_set year
    __default
    __get_attr
    __mutate_model_cutoff __mutate_nutation_cutoff
};

our @EXPORT_OK = (
    @basic_export,
    qw{
	geometric_longitude
	synodic_period
	__angle_subtended_from_earth
	__longitude_from_sun
	__model
    },
);
our %EXPORT_TAGS = (
    mixin	=> [ @basic_export, qw{
	synodic_period
	__angle_subtended_from_earth
	__longitude_from_sun
	__model
    } ],
    sun		=> [ @basic_export, qw{ geometric_longitude } ],
);

# We want to ensure SUN_CLASS is loaded because it is our default Sun
# implementation, but we do it at run time to avoid a circular
# dependency.
load_module( SUN_CLASS );

sub time_set {
    my ( $self ) = @_;
    my $attr = $self->__get_attr();
    my $time = $self->dynamical();
    my $cutoff = $self->get( 'model_cutoff' );
    my $cutoff_def = $self->model_cutoff_definition();
    my $sun = $self->get( 'sun' );

    DEBUG
	and printf <<'EOD', ref $self, ref $sun, julianday( $time );

self = %s
Sun = %s
JDE = %.5f
EOD

    my $T = jcent2000( $time );

    my ( $Lb, $Bb, $Rb ) = $self->__model( $time,
	model_cutoff_definition	=> $cutoff_def,
    );

    my ( $Le, $Be, $Re );

    if ( $sun->isa( SUN_CLASS ) ) {
	# We call __model as a subroutine because the Earth's model
	# parameters are hung on the Sun, but if we call it as a method
	# we get the Sun's model, which always returns zeroes.
	( $Le, $Be, $Re ) = __model( SUN_CLASS, $time,
	    model_cutoff_definition	=> $sun->model_cutoff_definition( $cutoff ),
	);
    } else {
	confess sprintf 'TODO Sun class %s not supported', ref $sun;
    }

    DEBUG
	and printf <<'EOD', rad2deg( $Le ), rad2deg( $Be ), $Re;

Heliocentric position of the Earth:
L0 = %.5f
B0 = %.5f
R0 = %.6f
EOD

    my ( $lambda, $beta, $Delta, $long_sym );
    if ( $Rb ) {		# Not the Sun

	my $last_tau = 0;

	while ( 1 ) {
	    DEBUG
		and printf <<'EOD', $self->get( 'name' ),

Heliocentric position of %s:
L = %.5f
B = %.5f
R = %.6f
EOD
			rad2deg( $Lb ), rad2deg( $Bb ), $Rb;

	    # Meeus 33.1
	    my $cosBb = cos( $Bb );
	    my $cosBe = cos( $Be );
	    my $x = $Rb * $cosBb * cos( $Lb ) - $Re * $cosBe * cos( $Le );
	    my $y = $Rb * $cosBb * sin( $Lb ) - $Re * $cosBe * sin( $Le );
	    my $z = $Rb * sin( $Bb )          - $Re * sin( $Be );

	    $Delta = sqrt( $x * $x + $y * $y + $z * $z );

	    use constant TAU_FACTOR => 0.005_775_518_3 * SECSPERDAY;
	    my $tau = TAU_FACTOR * $Delta;

	    DEBUG
		and printf <<'EOD', $x, $y, $z, $Delta, $tau / SECSPERDAY;

x = %+.6f
y = %+.6f
z = %+.6f
𝚫 = %.6f
𝛕 = %.7f day
EOD
	    if ( ( my $check = sprintf '%.1f', $tau ) ne $last_tau ) {
		$last_tau = $check;

		DEBUG
		    and printf <<'EOD', julianday( $time - $tau );

new JDE = %.5f
EOD
		( $Lb, $Bb, $Rb ) = $self->__model(
		    $time - $tau,
		    model_cutoff_definition	=> $cutoff_def,
		);
	    } else {

		# Meeus 33.2
		$lambda = atan2( $y, $x );
		$lambda < 0
		    and $lambda += TWOPI;
		$beta = atan2( $z, sqrt( $x * $x + $y * $y ) );
		$long_sym = '𝛌';
		last;
	    }
	}

	DEBUG
	    and printf <<'EOD', $long_sym,

Geocentric ecliptic position:
%s = %.5f
  = %s
𝛃 = %.5f
  = %s
EOD
		rad2deg( $lambda ), rad2dms( $lambda ),
		rad2deg( $beta ), rad2dms( $beta );

	# Meeus corrects for aberration here for a planet, before
	# conversion to FK5. It makes no real difference to the answer,
	# since everything done to the latitude and longitude before
	# conversion to equatorial is just addition and subtraction, and
	# therefore commutes. But it plays merry Hell with the poor slob
	# who is trying to verify code versus the worked examples,
	# because it changes the intermediate results. Sigh.

	# Aberration per Meeus 23.2
	use constant CONSTANT_OF_ABERRATION	=> deg2rad(
	    20.49552 / 3600 );
	# Longitude of the Sun
	my $Ls = mod2pi( $Le + PI );
	# Eccentricity of the Earth's orbit
	my $e = ( - 0.000_000_126_7 * $T - 0.000_042_037 ) * $T +
	    0.016_708_634;
	# Longitude of perihelion of the Earth's orbit
	my $pi = deg2rad( ( 0.000_46 * $T + 1.71946 ) * $T + 102.93735 );

	my $delta_lambda = ( ( $e * cos( $pi - $lambda ) - cos( $Ls -
		    $lambda ) ) / cos $beta ) * CONSTANT_OF_ABERRATION;
	my $delta_beta = - sin( $beta ) * ( sin( $Ls - $lambda ) - $e *
	    sin( $pi - $lambda ) ) * CONSTANT_OF_ABERRATION;
	$lambda += $delta_lambda;
	$beta += $delta_beta;

	DEBUG
	    and printf <<'EOD',

Planetary aberration:
𝚫𝛌 = %s
𝛌 = %.5f
  = %s
𝚫𝛃 = %s
𝛃 = %.5f
  = %s
EOD
	rad2dms( $delta_lambda), rad2deg( $lambda ), rad2dms( $lambda ),
	rad2dms( $delta_beta), rad2deg( $beta ), rad2dms( $beta );


    } else {			# The Sun
	( $lambda, $beta, $Delta ) = ( mod2pi( $Le + PI ), - $Be, $Re );
	$long_sym = '☉';

	DEBUG
	    and printf <<'EOD', $long_sym,

Geocentric ecliptic position:
%s = %.5f
  = %s
𝛃 = %.5f
  = %s
EOD
		rad2deg( $lambda ), rad2dms( $lambda ),
		rad2deg( $beta ), rad2dms( $beta );
    }

    DEBUG
	and printf <<'EOD',

%s = %.6f
𝛃 = %.6f
  = %s
𝚫 = %.6f
EOD
	$long_sym, rad2deg( $lambda ),
	rad2deg( $beta ), rad2dms( $beta ), $Delta;


    # Convert to FK5. Meeus says (ch. 25 pg 166) this is necessary for
    # high accuracy (though not if using his truncated VSOP87D), though
    # Bretagnon & Francou seem to say it is needed only for VSOP87 and
    # VSOP87E.

    # Meeus 32.3
    {
	use constant DYN_TO_FK5_LINEAR	=> deg2rad( 1.397 );
	use constant DYN_TO_FK5_QUADRATIC	=> deg2rad( 0.00031 );
	use constant DYN_TO_FK5_DELTA_LON	=> - deg2rad( 0.09033 / 3600 );
	use constant DYN_TO_FK5_FACTOR	=> deg2rad( 0.03916 / 3600 );
	my $lambda_prime = $lambda - ( DYN_TO_FK5_LINEAR +
	    DYN_TO_FK5_QUADRATIC * $T ) * $T;
	my $factor = DYN_TO_FK5_FACTOR * ( cos( $lambda_prime ) - sin(
		$lambda_prime ) );
	my $delta_lambda = DYN_TO_FK5_DELTA_LON + $factor * tan( $beta );
	my $delta_beta = $factor;

	DEBUG and printf <<'EOD',

Conversion to FK5
𝛌' = %.2f
𝚫%s = %s
𝚫𝛃 = %s
EOD
	    rad2deg( $lambda_prime ), $long_sym,
	    rad2dms( $delta_lambda, 5 ), rad2dms( $delta_beta );

	$lambda += $delta_lambda;
	$beta += $delta_beta;

	DEBUG and printf <<'EOD',

%s = %.5f
  = %s
𝛃 = %.5f
  = %s
EOD
	    $long_sym, rad2deg( $lambda ), rad2dms( $lambda ),
	    rad2deg( $beta ), rad2dms( $beta ),
	    ;

	$attr->{geometric_longitude} = $lambda;
    }

    # Nutation
    my ( $delta_psi, $delta_eps ) = $self->nutation( $time );
    $lambda += $delta_psi;

    DEBUG
	and printf <<"EOD",

Nutation:
𝚫𝛙 = %s
𝚫𝛆 = %s
𝛌 = %.5f
  = %s
EOD
	    rad2dms( $delta_psi ), rad2dms( $delta_eps ),
	    rad2deg( $lambda ), rad2dms( $lambda );

    # Obliquity per Meeus 22.3
    my $epsilon = $self->obliquity( $time );

    # Meeus 25.10

    unless ( $Rb ) {	# The Sun.
	# Aberration
	use constant SOLAR_ABERRATION_FACTOR => - deg2rad( 20.4898 / 3600 );
	my $delta_lambda = SOLAR_ABERRATION_FACTOR / $Delta;
	$lambda += $delta_lambda;

	DEBUG
	    and printf <<'EOD',

Solar aberration:
𝚫𝛌 = %s
𝛌 = %.5f
  = %s
EOD
	rad2dms( $delta_lambda), rad2deg( $lambda ), rad2dms( $lambda );
    }

    DEBUG
	and printf <<'EOD', $long_sym,

Final ecliptic coordinates:
%s = %.5f
  = %s
𝛃 = %.5f
  = %s
EOD
	rad2deg( $lambda ), rad2dms( $lambda ),
	rad2deg( $beta ), rad2dms( $beta );

    # NOTE: I could have stored the ecliptic coordinates at this point,
    # and trusted Astro::Coord::ECI to get the conversion right, but
    # since I was at this point not confident in that code, I decided to
    # see Meeus' example all the way to the end.
    #
    # Once nutation and obliquity became methods, it turns out that my
    # conversion between ecliptic and equatorial is equivalent to Meeus'
    # to his accuracy in the examples. That is, if I store equatorial, I
    # get back exactuly the same ecliptic coordiantes as I calculated
    # above. If I store ecliptic, I get back the same equatorial that
    # Meeus calculated.
    #
    # My current intent is to keep the code as-is, simply because for
    # verification purposes I want it to be as close as possible to
    # Meeus' example.

    my $sin_eps = sin $epsilon;
    my $cos_eps = cos $epsilon;
    my $sin_lam = sin $lambda;
    my $sin_bet = sin $beta;
    my $cos_bet = cos $beta;
    my $alpha = mod2pi( atan2(
	    $sin_lam * $cos_eps - $sin_bet / $cos_bet * $sin_eps,
	    cos $lambda ) );	# Meeus 13.3
    my $delta = asin( $sin_bet * $cos_eps + $cos_bet * $sin_eps *
	$sin_lam );	# Meeus 13.4

    DEBUG
	and printf <<'EOD',

Equatorial coordinates:
𝛂 = %.6f
  = %s
𝛅 = %.6f
  = %s
EOD
	rad2deg( $alpha ), rad2hms( $alpha ),
	rad2deg( $delta ), rad2dms( $delta, 2 );

    $self->equatorial( $alpha, $delta, $Delta * AU );
    $self->equinox_dynamical( $time );

    if ( DEBUG ) {
	my ( $lat, $lon ) = $self->ecliptic();
	printf <<'EOD', $long_sym,

Check -- recovered ecliptic coordinates:
%s = %.5f
  = %s
𝛃 = %.5f
  = %s
EOD
	    rad2deg( $lon ), rad2dms( $lon ),
	    rad2deg( $lat ), rad2dms( $lat );
    }

    return $self;
}

{
    my $earth;

    # NOTE that the sign of the angle returned is the same as the sign
    # of the result of __longitude_from_sun().
    sub __angle_subtended_from_earth {
	my ( $self, $time ) = @_;
	defined $time
	    or $time = $self->universal();
	$earth ||= Astro::Coord::ECI->new()->eci( 0, 0, 0 );
	$self->universal( $time );
	my $sun = $self->get( 'sun' )->universal( $time );
	$earth->universal( $time );
	my $lon = $self->__longitude_from_sun();
	my $angle = $earth->angle( $self, $sun );
	return $lon < 0 ? -$angle : $angle;
    }
}

sub geometric_longitude {
    my ( $self ) = @_;
    my $attr = $self->__get_attr();
    defined $attr->{geometric_longitude}
	and return $attr->{geometric_longitude};
    croak 'Geometric longitude undefined -- time not set';
}

sub __longitude_from_sun {
    my ( $self, $time, $offset ) = @_;
    $offset ||= 0;

    if ( defined $time ) {
	$self->universal( $time );
    } else {
	$time = $self->universal();
    }

    my $sun = $self->get( 'sun' )->universal( $time );

    my ( undef, $lon_b ) = $self->ecliptic();
    my ( undef, $lon_s ) = $sun->ecliptic();

    return mod2pi( $lon_b - $lon_s - $offset + PI ) - PI;
}

BEGIN {
    my @model = (

	# The following are from the IAU SOFA module src/nut80.c, from
	# http://www.iausofa.org/2018_0130_C/sofa_c-20180130.tar.gz
	# The only edit is the change from curly to square brackets and
	# the brute-force conversion of C comments to Perl comments. The
	# columns are:
	#   IAU:  nl nlp  nf  nd nom  sp spt  ce cet
	# Meeus:  M'   M   F   D   𝛀
   # /* 1-10 */
      [  0,  0,  0,  0,  1, -171996.0, -174.2,  92025.0,    8.9 ],
      [  0,  0,  0,  0,  2,    2062.0,    0.2,   -895.0,    0.5 ],
      [ -2,  0,  2,  0,  1,      46.0,    0.0,    -24.0,    0.0 ],
      [  2,  0, -2,  0,  0,      11.0,    0.0,      0.0,    0.0 ],
      [ -2,  0,  2,  0,  2,      -3.0,    0.0,      1.0,    0.0 ],
      [  1, -1,  0, -1,  0,      -3.0,    0.0,      0.0,    0.0 ],
      [  0, -2,  2, -2,  1,      -2.0,    0.0,      1.0,    0.0 ],
      [  2,  0, -2,  0,  1,       1.0,    0.0,      0.0,    0.0 ],
      [  0,  0,  2, -2,  2,  -13187.0,   -1.6,   5736.0,   -3.1 ],
      [  0,  1,  0,  0,  0,    1426.0,   -3.4,     54.0,   -0.1 ],

   # /* 11-20 */
      [  0,  1,  2, -2,  2,    -517.0,    1.2,    224.0,   -0.6 ],
      [  0, -1,  2, -2,  2,     217.0,   -0.5,    -95.0,    0.3 ],
      [  0,  0,  2, -2,  1,     129.0,    0.1,    -70.0,    0.0 ],
      [  2,  0,  0, -2,  0,      48.0,    0.0,      1.0,    0.0 ],
      [  0,  0,  2, -2,  0,     -22.0,    0.0,      0.0,    0.0 ],
      [  0,  2,  0,  0,  0,      17.0,   -0.1,      0.0,    0.0 ],
      [  0,  1,  0,  0,  1,     -15.0,    0.0,      9.0,    0.0 ],
      [  0,  2,  2, -2,  2,     -16.0,    0.1,      7.0,    0.0 ],
      [  0, -1,  0,  0,  1,     -12.0,    0.0,      6.0,    0.0 ],
      [ -2,  0,  0,  2,  1,      -6.0,    0.0,      3.0,    0.0 ],

   # /* 21-30 */
      [  0, -1,  2, -2,  1,      -5.0,    0.0,      3.0,    0.0 ],
      [  2,  0,  0, -2,  1,       4.0,    0.0,     -2.0,    0.0 ],
      [  0,  1,  2, -2,  1,       4.0,    0.0,     -2.0,    0.0 ],
      [  1,  0,  0, -1,  0,      -4.0,    0.0,      0.0,    0.0 ],
      [  2,  1,  0, -2,  0,       1.0,    0.0,      0.0,    0.0 ],
      [  0,  0, -2,  2,  1,       1.0,    0.0,      0.0,    0.0 ],
      [  0,  1, -2,  2,  0,      -1.0,    0.0,      0.0,    0.0 ],
      [  0,  1,  0,  0,  2,       1.0,    0.0,      0.0,    0.0 ],
      [ -1,  0,  0,  1,  1,       1.0,    0.0,      0.0,    0.0 ],
      [  0,  1,  2, -2,  0,      -1.0,    0.0,      0.0,    0.0 ],

   # /* 31-40 */
      [  0,  0,  2,  0,  2,   -2274.0,   -0.2,    977.0,   -0.5 ],
      [  1,  0,  0,  0,  0,     712.0,    0.1,     -7.0,    0.0 ],
      [  0,  0,  2,  0,  1,    -386.0,   -0.4,    200.0,    0.0 ],
      [  1,  0,  2,  0,  2,    -301.0,    0.0,    129.0,   -0.1 ],
      [  1,  0,  0, -2,  0,    -158.0,    0.0,     -1.0,    0.0 ],
      [ -1,  0,  2,  0,  2,     123.0,    0.0,    -53.0,    0.0 ],
      [  0,  0,  0,  2,  0,      63.0,    0.0,     -2.0,    0.0 ],
      [  1,  0,  0,  0,  1,      63.0,    0.1,    -33.0,    0.0 ],
      [ -1,  0,  0,  0,  1,     -58.0,   -0.1,     32.0,    0.0 ],
      [ -1,  0,  2,  2,  2,     -59.0,    0.0,     26.0,    0.0 ],

   # /* 41-50 */
      [  1,  0,  2,  0,  1,     -51.0,    0.0,     27.0,    0.0 ],
      [  0,  0,  2,  2,  2,     -38.0,    0.0,     16.0,    0.0 ],
      [  2,  0,  0,  0,  0,      29.0,    0.0,     -1.0,    0.0 ],
      [  1,  0,  2, -2,  2,      29.0,    0.0,    -12.0,    0.0 ],
      [  2,  0,  2,  0,  2,     -31.0,    0.0,     13.0,    0.0 ],
      [  0,  0,  2,  0,  0,      26.0,    0.0,     -1.0,    0.0 ],
      [ -1,  0,  2,  0,  1,      21.0,    0.0,    -10.0,    0.0 ],
      [ -1,  0,  0,  2,  1,      16.0,    0.0,     -8.0,    0.0 ],
      [  1,  0,  0, -2,  1,     -13.0,    0.0,      7.0,    0.0 ],
      [ -1,  0,  2,  2,  1,     -10.0,    0.0,      5.0,    0.0 ],

   # /* 51-60 */
      [  1,  1,  0, -2,  0,      -7.0,    0.0,      0.0,    0.0 ],
      [  0,  1,  2,  0,  2,       7.0,    0.0,     -3.0,    0.0 ],
      [  0, -1,  2,  0,  2,      -7.0,    0.0,      3.0,    0.0 ],
      [  1,  0,  2,  2,  2,      -8.0,    0.0,      3.0,    0.0 ],
      [  1,  0,  0,  2,  0,       6.0,    0.0,      0.0,    0.0 ],
      [  2,  0,  2, -2,  2,       6.0,    0.0,     -3.0,    0.0 ],
      [  0,  0,  0,  2,  1,      -6.0,    0.0,      3.0,    0.0 ],
      [  0,  0,  2,  2,  1,      -7.0,    0.0,      3.0,    0.0 ],
      [  1,  0,  2, -2,  1,       6.0,    0.0,     -3.0,    0.0 ],
      [  0,  0,  0, -2,  1,      -5.0,    0.0,      3.0,    0.0 ],

   # /* 61-70 */
      [  1, -1,  0,  0,  0,       5.0,    0.0,      0.0,    0.0 ],
      [  2,  0,  2,  0,  1,      -5.0,    0.0,      3.0,    0.0 ],
      [  0,  1,  0, -2,  0,      -4.0,    0.0,      0.0,    0.0 ],
      [  1,  0, -2,  0,  0,       4.0,    0.0,      0.0,    0.0 ],
      [  0,  0,  0,  1,  0,      -4.0,    0.0,      0.0,    0.0 ],
      [  1,  1,  0,  0,  0,      -3.0,    0.0,      0.0,    0.0 ],
      [  1,  0,  2,  0,  0,       3.0,    0.0,      0.0,    0.0 ],
      [  1, -1,  2,  0,  2,      -3.0,    0.0,      1.0,    0.0 ],
      [ -1, -1,  2,  2,  2,      -3.0,    0.0,      1.0,    0.0 ],
      [ -2,  0,  0,  0,  1,      -2.0,    0.0,      1.0,    0.0 ],

   # /* 71-80 */
      [  3,  0,  2,  0,  2,      -3.0,    0.0,      1.0,    0.0 ],
      [  0, -1,  2,  2,  2,      -3.0,    0.0,      1.0,    0.0 ],
      [  1,  1,  2,  0,  2,       2.0,    0.0,     -1.0,    0.0 ],
      [ -1,  0,  2, -2,  1,      -2.0,    0.0,      1.0,    0.0 ],
      [  2,  0,  0,  0,  1,       2.0,    0.0,     -1.0,    0.0 ],
      [  1,  0,  0,  0,  2,      -2.0,    0.0,      1.0,    0.0 ],
      [  3,  0,  0,  0,  0,       2.0,    0.0,      0.0,    0.0 ],
      [  0,  0,  2,  1,  2,       2.0,    0.0,     -1.0,    0.0 ],
      [ -1,  0,  0,  0,  2,       1.0,    0.0,     -1.0,    0.0 ],
      [  1,  0,  0, -4,  0,      -1.0,    0.0,      0.0,    0.0 ],

   # /* 81-90 */
      [ -2,  0,  2,  2,  2,       1.0,    0.0,     -1.0,    0.0 ],
      [ -1,  0,  2,  4,  2,      -2.0,    0.0,      1.0,    0.0 ],
      [  2,  0,  0, -4,  0,      -1.0,    0.0,      0.0,    0.0 ],
      [  1,  1,  2, -2,  2,       1.0,    0.0,     -1.0,    0.0 ],
      [  1,  0,  2,  2,  1,      -1.0,    0.0,      1.0,    0.0 ],
      [ -2,  0,  2,  4,  2,      -1.0,    0.0,      1.0,    0.0 ],
      [ -1,  0,  4,  0,  2,       1.0,    0.0,      0.0,    0.0 ],
      [  1, -1,  0, -2,  0,       1.0,    0.0,      0.0,    0.0 ],
      [  2,  0,  2, -2,  1,       1.0,    0.0,     -1.0,    0.0 ],
      [  2,  0,  2,  2,  2,      -1.0,    0.0,      0.0,    0.0 ],

   # /* 91-100 */
      [  1,  0,  0,  2,  1,      -1.0,    0.0,      0.0,    0.0 ],
      [  0,  0,  4, -2,  2,       1.0,    0.0,      0.0,    0.0 ],
      [  3,  0,  2, -2,  2,       1.0,    0.0,      0.0,    0.0 ],
      [  1,  0,  2, -2,  0,      -1.0,    0.0,      0.0,    0.0 ],
      [  0,  1,  2,  0,  1,       1.0,    0.0,      0.0,    0.0 ],
      [ -1, -1,  0,  2,  1,       1.0,    0.0,      0.0,    0.0 ],
      [  0,  0, -2,  0,  1,      -1.0,    0.0,      0.0,    0.0 ],
      [  0,  0,  2, -1,  2,      -1.0,    0.0,      0.0,    0.0 ],
      [  0,  1,  0,  2,  0,      -1.0,    0.0,      0.0,    0.0 ],
      [  1,  0, -2, -2,  0,      -1.0,    0.0,      0.0,    0.0 ],

   # /* 101-106 */
      [  0, -1,  2,  0,  1,      -1.0,    0.0,      0.0,    0.0 ],
      [  1,  1,  0, -2,  1,      -1.0,    0.0,      0.0,    0.0 ],
      [  1,  0, -2,  2,  0,      -1.0,    0.0,      0.0,    0.0 ],
      [  2,  0,  0,  2,  0,       1.0,    0.0,      0.0,    0.0 ],
      [  0,  0,  2,  4,  2,      -1.0,    0.0,      0.0,    0.0 ],
      [  0,  1,  0,  1,  0,       1.0,    0.0,      0.0,    0.0 ]
    );

    # UNDOCUMENTED AND UNSUPPORTED -- MAY BE CHANGED OR REVOKED WITHOUT
    # WARNING
    # Return the IAU 1980 nutation model, as array references. Each
    # reference contains one term of the model, in the following order
    # in Meeus' terminology:
    # M' M F D Omega delta psi( const, T ), delta # epsilon( const, T ).
    sub __iau1980_nutation_model {
	return @model;
    }

    # This may be a premature optimization, BUT the nutation in
    # longitude and obliquity are used different places, so I anticipate
    # this getting called twice by time_set(), with the same time. So:
    my $memoize_args = '';
    my @memoize_result;

    sub nutation {
	my ( $self, $time, $cutoff ) = @_;

	defined $time
	    or $time = $self->dynamical();

	$cutoff ||= 0;	# milli arc seconds. Meeus is 3

	{
	    ( my $memo = "$time $cutoff" ) eq $memoize_args
		and return @memoize_result;
	    $memoize_args = $memo;
	}

	my $T = jcent2000( $time );	# Meeus 22.1

	# All this from Meeus Ch 22 pp 143ff, expressed in degrees

	# Mean elongation of Moon from Sun
	my $D = ( ( $T / 189_474 - 0.001_914_2 ) * $T + 445_267.111_480
	    ) * $T + 297.850_36;

	# Mean anomaly of the Sun (Earth)
	my $M = ( ( - $T / 300_000 - 0.000_160_3 ) * $T + 35_999.050_340
	    ) * $T + 357.527_72;

	# Mean anomaly of the Moon
	my $M_prime = ( ( $T / 56_250 + 0.008_697_2 ) * $T + 477_198.867_398
	    ) * $T + 134.962_98;

	# Moon's argument of latitude
	my $F = ( ( $T / 327_270 - 0.003_682_5 ) * $T + 483_202.017_538
	    ) * $T + 93.271_91;

	# Logitude of the ascending node of the Moon's mean orbit on the
	# ecliptic, measured from the equinox of the date
	my $Omega = ( ( $T / 450_000 + 0.002_070_8 ) * $T - 1_934.136_261
	    ) * $T + 125.044_52;

	# Convert to radians, and store in same order as model source
	my @arg = map { deg2rad( $_ ) } ( $M_prime, $M, $F, $D, $Omega );

	my ( $delta_psi, $delta_eps ) = ( 0, 0 );
	foreach my $row ( @model ) {
	    my $a = $arg[0] * $row->[0] + $arg[1] * $row->[1] +
	    $arg[2] * $row->[2] + $arg[3] * $row->[3] +
	    $arg[4] * $row->[4];
	    if ( $row->[5] && $cutoff <= abs $row->[5] ) {
		$delta_psi += ( $row->[6] * $T + $row->[5] ) * sin $a;
	    }
	    if ( $row->[7] && $cutoff <= abs $row->[7] ) {
		$delta_eps += ( $row->[8] * $T + $row->[7] ) * cos $a;
	    }

	}

	# The model computes nutations in milli arc seconds, but we
	# return them in radians
	return ( @memoize_result =
	    map { deg2rad( $_ / 3600_0000 ) } $delta_psi, $delta_eps );
    }

}

sub __get_attr {
    my ( $self ) = @_;
    my $ref = ref $self
	or confess 'Can not call as static method';
    return $self->{$ref} ||= {
	model_cutoff_definition	=> dclone( $self->__model_definition(
		'default_model_cutoff' ) ),
    };
}

sub __default {
    my ( $class, $arg ) = @_;

    my $name = $class->__model_definition( 'body' );
    defined $arg->{id}
	or $arg->{id} = $name;
    defined $arg->{name}
	or $arg->{name} = $name;

    defined $arg->{diameter}
	or $arg->{diameter} = $class->__model_definition( 'diameter' );

    defined $arg->{model_cutoff}
	or $arg->{model_cutoff} = 'Meeus';

    defined $arg->{nutation_cutoff}
	or $arg->{nutation_cutoff} = 3;

    return;
}

sub __mutate_model_cutoff {
    my ( $self, $name, $val ) = @_;
    defined $val
	or croak "model cutoff must be defined";
    $self->model_cutoff_definition( $val )
	or croak "model cutoff '$val' is unknown";
    $self->__get_attr()->{$name} = $val;
    return $self;
}

sub model_cutoff_definition {
    my ( $self, $name, @arg ) = @_;
    defined $name
	or $name = $self->get( 'model_cutoff' );
    my $attr = $self->__get_attr();
    if ( @arg ) {
	if ( defined( my $val = $arg[0] ) ) {
	    unless ( ref $val ) {
		looks_like_number( $val )
		    and $val !~ m/ \A Inf (?: inity )? | NaN \z /smx
		    or croak 'Scalar model cutoff definition must be a number';
		my $num = $val;
		$val = sub {
		    my ( @model ) = @_;
		    my %cutoff;
		    foreach my $series ( @model ) {
			my $count = 0;
			foreach my $term ( @{ $series->{terms} } ) {
			    last if $term->[0] < $num;
			    $count++;
			}
			$count
			    and $cutoff{$series->{series}} = $count;
		    }
		    return \%cutoff;
		};
	    }
	    if ( CODE_REF eq ref $val ) {
		$val = $val->(
		    map { @{ $_ } } @{
			$self->__model_definition( 'model' ) }
		);
		$val->{name} = $name;
	    }
	    HASH_REF eq ref $val
		or croak 'The model cutoff definition value must be a hash ref';
	    my $terms = $self->__model_definition(
		'default_model_cutoff')->{none};
	    foreach my $name ( keys %{ $val } ) {
		'name' eq $name
		    and next;
		exists $terms->{$name}
		    or croak "Series '$name' not in this model";
		$val->{$name} > $terms->{$name}
		    and croak "Series '$name' has only $terms->{$name} terms";
	    }
	    $attr->{model_cutoff_definition}{$name} = $val;
	} else {
	    $self->__model_definition( 'default_model_cutoff' )->{$name}
		and croak "You may not delete model cutoff definition '$name'";
	    delete $attr->{model_cutoff_definition}{$name};
	}
	return $self;
    } else {
	return $attr->{model_cutoff_definition}{$name};
    }
}

# Static method
# Given dynamical time in seconds, return Ecliptic position in Ecliptic
# longitude (radians), Ecliptic latitude (radians), Range (AU) and 
# AU and velocity in AU/day
sub __model {
    my ( $self, $time, %arg ) = @_;

    DEBUG
	and printf <<'EOD',

__model:
    invocant: %s
    model_cutoff: %s
EOD
    $self,
    ( $arg{model_cutoff_definition} ?
	( $arg{model_cutoff_definition}{name} || '<anonymous>' ) :
	'<unspecified>' ),
    ;

    my $jm = jcent2000( $time ) / 10;	# Meeus 32.1
    my @p_vec;
    my @v_vec;
    foreach my $coord ( @{ $self->__model_definition( 'model' ) } ) {
	my $dT = my $exponent = 0;
	my $T = 1;
	my $pos = my $vel = 0;
	foreach my $series ( @{ $coord } ) {
	    my $limit = $arg{model_cutoff_definition} ?
		( $arg{model_cutoff_definition}{$series->{series}} || 0 ) :
		@{ $series->{terms} }
		or next;
	    --$limit;
	    foreach my $inx ( 0 .. $limit ) {
		my $term = $series->{terms}[$inx];
		my $u = $term->[1] + $term->[2] * $jm;
		my $cos_u = cos $u;
		$pos += $term->[0] * $cos_u * $T;
		my $sin_u = sin $u;
		$vel += $dT * $exponent * $term->[0] * $cos_u -
		    $T * $term->[0] * $term->[2] * $sin_u;
	    }
	    $dT = $T;
	    $exponent++;
	    $T *= $jm;
	}
	$vel /= DAYS_PER_JULIAN_MILENNIUM;	# units/millennium -> units/day
	push @p_vec, $pos;
	push @v_vec, $vel;
    }
    $p_vec[0] = mod2pi( $p_vec[0] );
    return ( @p_vec, @v_vec );
}

sub __mutate_nutation_cutoff {
    my ( $self, undef, $val ) = @_;
    defined $val
	or croak 'Nutation cutoff must be defined';
    looks_like_number( $val )
	and $val >= 0
	or croak 'Nutation cutoff must be a non-negative number';
    $self->__get_attr()->{nutation_cutoff} = $val;
    return $self;
}

sub obliquity {
    my ( $self, $time ) = @_;

    defined $time
	or $time = $self->dynamical();
    # Obliquity per Meeus 22.3
    my $U = jcent2000( $time ) / 100;
    my $epsilon_0 = 0;
    $epsilon_0 = $epsilon_0 * $U + $_ for qw{ 2.45 5.79 27.87 7.12
	-39.05 -249.67 -51.38 1999.25 -1.55 -4680.93 84381.448 };
    $epsilon_0 = deg2rad( $epsilon_0 / 3600 );
    my ( undef, $delta_eps ) = $self->nutation( $time );
    my $epsilon = $epsilon_0 + $delta_eps;

    DEBUG
	and printf <<"EOD",

Obliquity:
𝛆₀ = %.7f
𝛆 = %.7f
  = %s
EOD
	rad2deg( $epsilon_0 ), rad2deg( $epsilon ), rad2dms( $epsilon );

    return $epsilon;
}

sub order {
    my ( $self ) = @_;
    return $self->__model_definition( 'order' );
}

# Calculate the period of the orbit. The orbital velocity in radians per
# Julian centutu is just the inverse of the coefficient of the constant
# L1 term -- that is, the A value of the one with B and C both zero,
# since that computes as A * cos( B + C * tau ) = A * cos( 0 ) = A
#
# So the tropical year is just TWOPI divided by this. But we want the
# Siderial year, so we have to add in the precession. I found no
# reference for this, but to a first approximation the additional angle
# to travel is the solar year times the rate of precession, and the
# siderial year is the solar year plus the additional distance divided
# by the orbital velocity.
#
# But this calculation is done when the model parameters are built, and
# period() just returns the resultant value.
#
# The rate of pecession is the IAU 2003 value, taken from fapa03.c.

sub period {
    my ( $self ) = @_;
    return $self->__model_definition( 'sidereal_period' );
}

# https://in-the-sky.org/article.php?term=synodic_period
# Note that I chose NOT to precalculate this because it depends on the
# period of the 'sun' attribute, which may change.
sub synodic_period {
    my ( $self ) = @_;
    return( 1 / abs( 1 / $self->get( 'sun' )->year() - 1 / $self->year() ) );
}

sub year {
    my ( $self ) = @_;
    return $self->__model_definition( 'tropical_period' );
}

1;

__END__

=head1 NAME

Astro::Coord::ECI::VSOP87D - Implement the VSOP87D position model.

=head1 SYNOPSIS

 package My_Object;

 use base qw{ Astro::Coord::ECI };
 use Astro::Coord::ECI::VSOP87D qw{ :mixin };

 sub __model_definition {
     return [
         # VSOP87D coeficients as digested from the distro by
	 # tools/decode
     ];
 }

=head1 DESCRIPTION

This Perl module implements the VSOP87D model of planetary motion in a
manner that is consistent with the
L<Astro::Coord::ECI|Astro::Coord::ECI> hierarchy.

The VSOP87 models calculate the positions of the planets through Neptune
as a series of cosine terms. They were created by Pierre Bretagnon and
Gerard Francou of the Bureau des Longitudes in Paris France. Depending
on the model you select, you can calculate either instantaneous orbital
parameters, Heliocentric ecliptic position in either spherical or
Cartesian coordinates and either current or J2000.0 equinox, or
barycentric ecliptic position.

The models are stated to be within 1 second of arc for varying times
around J2000 (about noon January 1 2000 UT), as follows:

 4000 years for Mercury, Venus, Earth-Moon barycenter, Mars
 2000 years for Jupiter and Saturn
 6000 years for Uranus and Neptune

The actual model coefficients are available from
L<http://cdsarc.u-strasbg.fr/viz-bin/qcat?VI/81/>, as is additional
information the accuracy of the model, and a reference implementation in
Fortran.

VSOP87D provides Heliocentric spherical coordinates referred to the
current equinox. This is consistent with the existing members of the
L<Astro::Coord::ECI|Astro::Coord::ECI> hierarchy, but more importantly
Jean Meeus' Astronomical Algorithms provides worked examples for the Sun
and Venus.

The VSOP87D model itself is simple enough to implement, and occupies
about 50 lines of Perl. Testing shows that the Perl solution for a given
body and time is within C<5e-9> of the Fortran reference implementation
over selected years in the range -4000 to 2300. The units of that
C<5e-9> vary, being radians for longitude and latitude, AU for radius,
and radians/day and AU/day for the corresponding velocities.

One of the advantages of the VSOP87 models over the previous VSOP82
models is that they are easily truncated when less than full precision
is required. Meeus has his own truncation, which is the default one. In
addition, this code provides truncation C<'none'>, which uses the whole
model, and a mechanism to define custom truncations.

As the examples make clear, the devil is in the details, and a
significant amount of work needs to be done to get from Heliocentric
geometric ecliptic coordinates to Geocentric apparent equatorial
coordinates. Meeus' examples are embodied in F<t/meeus_25b.t> and
F<t/meeus_33a.t>.

For the Sun, the Perl implementation agrees pretty well with the worked
example, differing by C<0.001> seconds of right ascension (B<not>
seconds of arc), C<0.007> seconds of declination (seconds of arc) and
C<1e-7> AU in radius.

For Venus, the Perl implementation agrees less well with the worked
example, differing by C<0.14> seconds of right ascension, C<0.07>
seconds of declination, and C<5e-8> AU in radius. I have gone over the
calculation step-by-step, and as of this writing most of the difference
seems to come in at the computation of Geocentric ecliptic position from
its Heliocentric Cartesian ecliptic position.  This is simply a square
root and two C<atan2()> calls, and if it is subtly wrong some way I can
not see it.

Because these are the only two worked examples I found in Meeus, I felt
the need to sanity-check the rest of the distribution in other ways.
These tests are contained in the F<t/planet_*.t> test files.

Rise and set times came from the United States Naval Observatory (USNO)
Rise/Set/Transit Times for Major Solar System Bodies and Bright Stars
page at L<http://aa.usno.navy.mil/data/docs/mrst.php>, and are given to
the nearest minute. These models almost always reproduce the USNO's
times in the cases tested. I have no idea how the USNO data are
calculated or to what accuracy.

Conjunctions and so forth came from Guy Ottewell's Astronomical Calendar
at L<http://www.universalworkshop.com/>, and are given to the nearest
hour. These models usually give the same. The 2018 edition also gives
JDE dates for the phenomena to three decimal places, or an accuracy of
about 90 seconds. These models typically are within about 10 minutes of
the Ottewell figures. Again I have no idea how the Astronomical Calendar
data are calculated or to what accuracy.

=head1 USAGE

This specific module is not intended to be used directly. Instead,
subclass a member of the L<Astro::Coord::ECI|Astro::Coord::ECI>
hierarchy and import methods from this module. In most cases this means
whatever the C<:mixin> tag provides, though for the Sun the C<:sun> tag
should be used instead. You must also provide a
L<__model_definition()|/__model_definition> method that returns the
model parameters you wish to implement. For the Sun, a
L<__model()|/__model> method is also required, since the design of this
distribution hangs the Earth's
L<__model_definition()|/__model_definition> information on the Sun.

But the end user does not do this either. Instead this distribution
provides three such subclasses:

=over

=item L<Astro::Coord::ECI::VSOP87D::Sun|Astro::Coord::ECI::VSOP87D::Sun>

This is a subclass of L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun>.
The L<__model()|/__model> method (private to this distribution) simply
returns zeroes. But this class carries the model parameters for the
Earth, which are subtracted from whatever L<__model()|/__model> returns
to get Geocentric coordinates.

=item L<Astro::Coord::ECI::VSOP87D::_Inferior|Astro::Coord::ECI::VSOP87D::_Inferior>

This is a subclass of L<Astro::Coord::ECI|Astro::Coord::ECI>, which
pulls in everything relevant from this module (i.e. imports C<:mixin>),
and provides almanac methods appropriate to inferior planets. Mercury
and Venus are subclassed from this.

=item L<Astro::Coord::ECI::VSOP87D::_Superior|Astro::Coord::ECI::VSOP87D::_Superior>

This is a subclass of L<Astro::Coord::ECI|Astro::Coord::ECI>, which
pulls in everything relevant from this module (i.e. imports C<:mixin>),
and provides almanac methods appropriate to superior planets. Mars,
Jupiter, Saturn, Uranus, and Neptune are subclassed from this.

=back

=head1 METHODS

This module does not implement a class, and is better regarded as a
mixin. It supports the following methods, which are public and
exportable unless documented otherwise.

=head2 model_cutoff_definition

This method reports, creates, and deletes model cutoff definitions.

The first argument is the name of the model cutoff. If this is the only
argument, a reference to a hash defining the named model cutoff is
returned.  This return is a deep clone of the actual definition.

If the second argument is C<undef>, the named model cutoff is deleted.
If the model cutoff does not exist, the call does nothing. It is an
error to try to delete built-in cutoffs C<'none'> and C<'Meeus'>.

If the second argument is a reference to a hash, this defines or
redefines a model cutoff. The keys to the hash are the names of VSOP87D
series (C<'L0'> through C<'L5'>, C<'B0'> through C<'B5'>, and C<'R0'>
through C<'R5'>), and the value of each key is the number of terms of
that series to use. If one of the keys is omitted or has a false value,
that series is not used.

If the second argument is a scalar, it is expected to be a number, and a
model cutoff is generated consisting of all terms whose coefficient
(C<'A'> in Meeus' terminology) is equal to or greater than the number.

If the second argument is a code reference, this code is expected to
return a reference to a valid model cutoff hash as described two
paragraphs previously. Its arguments are the individual series hashes,
extracted from the model. Each hash will have the following keys:

=over

=item series

The name of the series (e.g. 'L0').

=item terms

An array reference containing the terms of the series.
Each term is a reference to an array containing in order, in Meeus'
terms, values C<'A'>, C<'B'>, and C<'C'>.

=back

This method is exportable, either by name or via the C<:mixin> or
C<:sun> tags.

=head2 geometric_longitude

This method returns the geometric longitude of the body. This is after
correction for aberration and light time (for bodies other than the Sun)
and conversion to FK5.

This method is exportable, either by name or via the C<:sun> tag.

=head2 nutation

 my ( $delta_psi, $delta_epsilon ) =
     $self->nutation( $dynamical_time, $cutoff );

This method calculates the nutation in ecliptic longitude
(C<$delta_psi>) and latitude (C<$delta_epsilon>) at the given dynamical
time in seconds since the epoch (i.e. Perl time), according to the IAU
1980 model.

The C<$time> argument is optional, and defaults to the object's current
dynamical time.

The C<$cutoff> argument is optional; if specified as a number larger
than C<0>, terms whose amplitudes are smaller than the nutation cutoff
(in milli arc seconds) are ignored. The Meeus version of the algorithm
is specified by a value of C<3>. The default is specified by the
L<nutation_cutoff|/nutation_cutoff> attribute.

The model itself is the IAU 1980 nutation model. Later models exist, but
this was chosen because of the desire to be compatible with Meeus'
examples. The implementation itself actually comes from Meeus chapter
22. The model parameters were not transcribed from that source, however,
but were taken from the source IAU C reference implementation of the
algorithm, F<src/nut80.c>, with the minimum modifications necessary to
make the C code into Perl code. This file is contained in
L<http://www.iausofa.org/2018_0130_C/sofa_c-20180130.tar.gz>.

This method is exportable, either by name or via the C<:mixin> or
C<:sun> tags.

=head2 obliquity

 $epsilon = $self->obliquity( $time );

This method calculates the obliquity of the ecliptic in radians at
the given B<dynamical> time. If the time is omitted or specified as
C<undef>, the current dynamical time of the object is used.

The algorithm is equation 22.3 from Jean Meeus' "Astronomical
Algorithms", 2nd Edition, Chapter 22, pages 143ff.

This method is exportable, either by name or via the C<:mixin> or
C<:sun> tags.

=head2 order

 say 'Order from Sun: ', $self->order();

This method returns the order of the body from the Sun, with the Sun
itself being C<0>. The number C<3> is skipped, since that would
represent the Earth.

This method is exportable, either by name or via the C<:mixin> or
C<:sun> tags.

=head2 period

 $self->period()

This method returns the sidereal period of the object, calculated from
the coefficient of its first C<L1> term.

The algorithm is the author's, and is a first approximation. That is. it
is just the tropical period plus however long it takes the object to
cover the amount of precession during the tropical year.

This method is exportable, either by name or via the C<:mixin> or
C<:sun> tags.

=head2 synodic_period

 $self->synodic_period()

This method returns the synodic period of the object -- that is to say
the mean interval between oppositions or conjunctions of superior
planets or between corresponding conjunctions of inferior planets.

This method is exportable, either by name or via the C<:mixin> tag.

=head2 time_set

 $self->time_set()

This method is not normally called by the user. It is called by
L<Astro::Coord::ECI|Astro::Coord::ECI> to compute the position once the
time has been set.

It returns the invocant.

This method is exportable, either by name or via the C<:mixin> or
C<:sun> tags.

=head2 year

 $self->year()

This method returns the length of the tropical year of the object,
calculated from the coefficient of its first C<L1> term.

This method is exportable, either by name or via the C<:mixin> or
C<:sun> tags.

=head2 __get_attr

This method is B<private> to this distribution, and may be changed or
revoked without notice at any time. Documentation is for the benefit of
the author.

This method returns the hash containing VSOP87D-specific attributes,
creating it if necessary.

This method is exportable, either by name or via the C<:mixin> or
C<:sun> tags.

=head2 __model

 my @state_vector = $class->__model( $time_dynamical, ... );

This static method is B<private> to this package, and may be changed or
revoked without notice at any time. Documentation is for the benefit of
the author.

This static method executes the VSOP87D model returned by
C<< $class->__model_definition() >>, and returns the computed state
vector. The components of the state vector are Heliocentric ecliptic
longitude and latitude in radians, radius in AU, and the associated
velocities in radians/day and AU/day.

Additional optional arguments can be specified as name/value pairs. The
following are defined:

=over

=item debug

If this Boolean argument is true, whatever debug data the author finds
useful at the moment is written to standard error. Only false values of
this argument are supported.

=item model_cutoff_definition

This is the model cutoff definition hash to use in the computation. If
unspecified the whole model is used.

=back

This method is exportable, either by name or via the C<:mixin> tag. It
is not exported by the C<:sun> tag.

=head2 __model_definition

 my $model = $class->__model_definition( 'model' )

This static method is B<private> to this package, and may be changed or
revoked without notice at any time. Documentation is for the benefit of
the author.

This static method returns model-related information. The argument
describes the information to return. The following arguments are valid:

=over

=item default_model_cutoff

This argument returns the default value of C<'model_cutoff_definition'>
for a new object.

=item model

This argument returns the terms of the VSOP87D model, expressed as
nested array references.

The top level is indexed on the zero-based coordinate index (i.e. one
less than the indices documented in F<vsop87.txt>. The next level is
indexed on the exponent of C<T> represented, and is expected to be in
the range C<0-5>.

The third level is a hash describing the individual series. It contains
the following keys:

=over

=item series

This is the name of the individual series (e.g. C<'L0'>.

=item terms

This is a reference to an array containing the terms of the series.
Each term is a reference to an array containing quantities A, B, and C
to be plugged into the equation C<A * cos( B + C * T) * T ** n>.

C<T> is dynamical time in Julian millennia since J2000.0.

=back

=item sidereal_period

This is the sidereal period in seconds, and is returned by period().

=item tropical_period

This is the tropical period, in seconds, and is returned by year().

=back

This method is B<not> exportable. It is expected that each derived class
will implement its own version of this method.

=head1 SEE ALSO

L<Astro::Coord::ECI|Astro::Coord::ECI>

L<https://www.caglow.com/info/compute/vsop87>

=head1 ACKNOWLEDGMENTS

The author wishes to acknowledge and thank the following individuals and
organizations.

Pierre Bretagnon and Gerard Francou of the Bureau des Longitudes, Paris,
France, whose VSOP87 solutions of planetary motion form the basis of
these modules. Both the coefficients for the various VSOP87 models and a
reference implementation in FORTRAN are available from
L<http://cdsarc.u-strasbg.fr/viz-bin/qcat?VI/81/>. Without these, this
module would not exist.

Jean Meeus, whose book "Astronomical Algorithms" (second edition)
contained invaluable worked examples for the Sun and Venus, which
eventually became F<t/meeus_25b.t> and F<t/meeus_33a.t>. Without these I
would never have been able to reduce the Heliocentric ecliptic
coordinates generated by the VSOP87D models to Geocentric equatorial
coordinates.

The International Astronomical Union (IAU), whose SOFA software
collection provided both coefficients and a reference implementation for
the nutation calculation. Formal credit is given them under
L<COPYRIGHT AND LICENSE|/COPYRIGHT AND LICENSE>.

Guy Ottewell, whose Astronomical Calendar has long been part of my life.
Paper publication of this ceased with the 2016 edition, but it continues
on line at L<http://www.universalworkshop.com/>, and formed the basis of
the conjunction portion of the F<t/planet_*.t>.

The United States Naval Observatory, whose Data Services, available at
L<http://aa.usno.navy.mil/data/index.php>, have long been my reference
for daily events involving astronomical bodies.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

Software Routines from the IAU SOFA Collection were used. Copyright (C)
International Astronomical Union Standards of Fundamental Astronomy
(L<http://www.iausofa.org>)

=cut

# ex: set textwidth=72 :
