package Astro::Constants::2019;
# ABSTRACT: Perl library to provide physical constants for use in Physics and Astronomy based on values from 2018 CODATA.
#
#  They are not constant but are changing still. - Cymbeline, Act II, Scene 5
$Astro::Constants::2019::VERSION = '0.14051';
use 5.006;
use strict;
use warnings;

use base qw(Exporter);


use constant SPEED_LIGHT => 299792458;
use constant LIGHT_SPEED => 299792458;
use constant BOLTZMANN => 1.380649e-23;
use constant GRAVITATIONAL => 6.67430e-11;
use constant ELECTRON_VOLT => 1.602176634e-19;
use constant PLANCK => 6.62607015e-34;
use constant H_BAR => 1.0545718176763e-34;
use constant HBAR => 1.0545718176763e-34;
use constant CHARGE_ELEMENTARY => 1.602176634e-19;
use constant ELECTRON_CHARGE => 1.602176634e-19;
use constant STEFAN_BOLTZMANN => 5.670374419e-8;
use constant DENSITY_RADIATION => 7.565723e-16;
use constant A_RAD => 7.565723e-16;
use constant WIEN => 2.897771955e-3;
use constant ALPHA => 7.2973525693e-3;
use constant IMPEDANCE_VACUUM => 376.730313461;
use constant VACUUM_IMPEDANCE => 376.730313461;
use constant PERMITIV_FREE_SPACE => 8.8541878128e-12;
use constant PERMITIVITY_0 => 8.8541878128e-12;
use constant PERMEABL_FREE_SPACE => 1.25663706212e-6;
use constant PERMEABILITY_0 => 1.25663706212e-6;
use constant CONSTANT_MAGNETIC => 1.25663706212e-6;
use constant PI => 3.14159265358979324;
use constant FOUR_PI => 12.5663706143592;
use constant FOURPI => 12.5663706143592;
use constant STERADIAN => 3282.80635001174;
use constant EXP => 2.71828182846;
use constant ATOMIC_MASS_UNIT => 1.66053906660e-27;
use constant PARSEC => 3.08567758149e16;
use constant ASTRONOMICAL_UNIT => 149597870700;
use constant LIGHT_YEAR => 9460730472580800;
use constant ANGSTROM => 1e-10;
use constant JANSKY => 1e-26;
use constant AVOGADRO => 6.02214076e23;
use constant YEAR => 31557600;
use constant YEAR_JULIAN => 31557600;
use constant YEAR_TROPICAL => 31556925.1;
use constant YEAR_SIDEREAL => 31558149.8;
use constant YEAR_ANOMALISTIC => 31558432.6;
use constant YEAR_ECLIPSE => 29947974.3;
use constant MASS_SOLAR => 1.9884e30;
use constant SOLAR_MASS => 1.9884e30;
use constant LUMINOSITY_SOLAR => 3.828e26;
use constant SOLAR_LUMINOSITY => 3.828e26;
use constant DENSITY_CRITICAL_RHOC => 1.87834e-26;
use constant RHO_C => 1.87834e-26;
sub HUBBLE_TIME { warn "HUBBLE_TIME deprecated"; return 3.0853056e17; }
use constant TEMPERATURE_CMB => 2.72548;
use constant CMB_TEMPERATURE => 2.72548;
use constant MAGNITUDE_SOLAR_V => -26.74;
use constant SOLAR_V_MAG => -26.74;
use constant MAGNITUDE_SOLAR_V_ABSOLUTE => 4.83;
use constant SOLAR_V_ABS_MAG => 4.83;
use constant RADIUS_SOLAR => 6.96e8;
use constant SOLAR_RADIUS => 6.96e8;
use constant MASS_EARTH => 5.9722e24;
use constant EARTH_MASS => 5.9722e24;
use constant RADIUS_EARTH => 6.3781366e6;
use constant EARTH_RADIUS => 6.3781366e6;
use constant TEMPERATURE_SOLAR_SURFACE => 5772;
use constant SOLAR_TEMPERATURE => 5772;
use constant DENSITY_SOLAR => 1408;
use constant SOLAR_DENSITY => 1408;
use constant DENSITY_EARTH => 5515;
use constant EARTH_DENSITY => 5515;
use constant GRAVITY_SOLAR => 274.78;
use constant SOLAR_GRAVITY => 274.78;
use constant GRAVITY_EARTH => 9.80665;
use constant EARTH_GRAVITY => 9.80665;
use constant RADIUS_LUNAR => 1.7381e6;
use constant LUNAR_RADIUS => 1.7381e6;
use constant MASS_LUNAR => 7.346e22;
use constant LUNAR_MASS => 7.346e22;
use constant AXIS_SM_LUNAR => 3.84402e8;
use constant LUNAR_SM_AXIS => 3.84402e8;
use constant ECCENTRICITY_LUNAR => 0.0549;
use constant LUNAR_ECCENTRICITY => 0.0549;
use constant THOMSON_CROSS_SECTION => 6.6524587321e-29;
use constant THOMSON_XSECTION => 6.6524587321e-29;
use constant MASS_ELECTRON => 9.1093837015e-31;
use constant ELECTRON_MASS => 9.1093837015e-31;
use constant MASS_PROTON => 1.67262192369e-27;
use constant PROTON_MASS => 1.67262192369e-27;
use constant MASS_NEUTRON => 1.67492749804e-27;
use constant NEUTRON_MASS => 1.67492749804e-27;
use constant MASS_HYDROGEN => 1.6738e-27;
use constant HYDROGEN_MASS => 1.6738e-27;
use constant MASS_ALPHA => 6.6446573357e-27;
use constant RADIUS_ELECTRON => 2.8179403262e-15;
use constant ELECTRON_RADIUS => 2.8179403262e-15;
use constant RADIUS_BOHR => 5.29177210903e-11;
use constant BOHR_RADIUS => 5.29177210903e-11;
use constant RADIUS_JUPITER => 69911000;
use constant MASS_JUPITER => 1.89819e27;

my %_precision = (
    ALPHA => {value => 1.5e-10, type => 'relative'},
    ANGSTROM => {value => 0, type => 'relative'},
    ASTRONOMICAL_UNIT => {value => 0, type => 'relative'},
    ATOMIC_MASS_UNIT => {value => 3.0e-10, type => 'relative'},
    AVOGADRO => {value => 0, type => 'relative'},
    AXIS_SM_LUNAR => {value => 3e-9, type => 'relative'},
    BOLTZMANN => {value => 0, type => 'relative'},
    CHARGE_ELEMENTARY => {value => 0, type => 'relative'},
    DENSITY_CRITICAL_RHOc => {value => 2.3e-5, type => 'relative'},
    DENSITY_EARTH => {value => 0.0002, type => 'relative'},
    DENSITY_RADIATION => {value => 2.3e-6, type => 'relative'},
    DENSITY_SOLAR => {value => 0.001, type => 'relative'},
    ECCENTRICITY_LUNAR => {value => 0.002, type => 'relative'},
    ELECTRON_VOLT => {value => 0, type => 'relative'},
    EXP => {value => 0.00000000001, type => 'relative'},
    FOUR_PI => {value => 0.0000000000001, type => 'relative'},
    GRAVITATIONAL => {value => 2.2e-5, type => 'relative'},
    GRAVITY_EARTH => {value => 0.000001, type => 'relative'},
    GRAVITY_SOLAR => {value => 0.0004, type => 'relative'},
    HUBBLE_TIME => {value => 0.0000001, type => 'relative'},
    H_BAR => {value => 1.5e-9, type => 'relative'},
    IMPEDANCE_VACUUM => {value => 1e-50, type => 'relative'},
    JANSKY => {value => 0, type => 'relative'},
    LIGHT_YEAR => {value => 0, type => 'relative'},
    LUMINOSITY_SOLAR => {value => 0.0003, type => 'relative'},
    MAGNITUDE_SOLAR_V => {value => 0.0004, type => 'relative'},
    MAGNITUDE_SOLAR_V_ABSOLUTE => {value => 0.002, type => 'relative'},
    MASS_ALPHA => {value => 3.0e-10, type => 'relative'},
    MASS_EARTH => {value => 6e20, type => 'absolute'},
    MASS_ELECTRON => {value => 3e-10, type => 'relative'},
    MASS_HYDROGEN => {value => 3.3e-31, type => 'absolute'},
    MASS_JUPITER => {value => 5e-6, type => 'relative'},
    MASS_LUNAR => {value => 0.0002, type => 'relative'},
    MASS_NEUTRON => {value => 5.7e-10, type => 'relative'},
    MASS_PROTON => {value => 3.1e-10, type => 'relative'},
    MASS_SOLAR => {value => 0.0001, type => 'relative'},
    PARSEC => {value => 1e-11, type => 'relative'},
    PERMEABL_FREE_SPACE => {value => 1.5e-10, type => 'relative'},
    PERMITIV_FREE_SPACE => {value => 1.5e-10, type => 'relative'},
    PI => {value => 0.00000000000000001, type => 'relative'},
    PLANCK => {value => 0, type => 'relative'},
    RADIUS_BOHR => {value => 1.5e-10, type => 'relative'},
    RADIUS_EARTH => {value => 0.1, type => 'absolute'},
    RADIUS_ELECTRON => {value => 4.5e-10, type => 'relative'},
    RADIUS_JUPITER => {value => 1.5e-5, type => 'relative'},
    RADIUS_LUNAR => {value => 6e-5, type => 'relative'},
    RADIUS_SOLAR => {value => 0.002, type => 'relative'},
    SPEED_LIGHT => {value => 0, type => 'relative'},
    STEFAN_BOLTZMANN => {value => 1.7e-10, type => 'relative'},
    STERADIAN => {value => 0.00000000000001, type => 'relative'},
    TEMPERATURE_CMB => {value => 0.00057, type => 'absolute'},
    TEMPERATURE_SOLAR_SURFACE => {value => 0.0002, type => 'relative'},
    THOMSON_CROSS_SECTION => {value => 9.1e-10, type => 'relative'},
    WIEN => {value => 1e-10, type => 'relative'},
    YEAR => {value => 0, type => 'relative'},
    YEAR_ANOMALISTIC => {value => 0.1, type => 'absolute'},
    YEAR_ECLIPSE => {value => 0.1, type => 'absolute'},
    YEAR_SIDEREAL => {value => 1, type => 'absolute'},
    YEAR_TROPICAL => {value => 0.1, type => 'absolute'},
);


# some helper functions
sub pretty {
    if (@_ > 1) {
        return map { sprintf("%1.3e", $_) } @_;
    }
    return sprintf("%1.3e", shift);
}

sub precision {
    my ($name, $type) = @_;
    warn "precision() requires a string, not the constant value"
        unless exists $_precision{$name};

    return $_precision{$name}->{value};
}

our @EXPORT_OK = qw(
    LIGHT_SPEED SPEED_LIGHT BOLTZMANN GRAVITATIONAL ELECTRON_VOLT PLANCK HBAR H_BAR ELECTRON_CHARGE CHARGE_ELEMENTARY STEFAN_BOLTZMANN A_RAD DENSITY_RADIATION WIEN ALPHA VACUUM_IMPEDANCE IMPEDANCE_VACUUM PERMITIVITY_0 PERMITIV_FREE_SPACE PERMEABILITY_0 CONSTANT_MAGNETIC PERMEABL_FREE_SPACE PI FOURPI FOUR_PI STERADIAN EXP ATOMIC_MASS_UNIT PARSEC ASTRONOMICAL_UNIT LIGHT_YEAR ANGSTROM JANSKY AVOGADRO YEAR_JULIAN YEAR YEAR_TROPICAL YEAR_SIDEREAL YEAR_ANOMALISTIC YEAR_ECLIPSE SOLAR_MASS MASS_SOLAR SOLAR_LUMINOSITY LUMINOSITY_SOLAR RHO_C DENSITY_CRITICAL_RHOc HUBBLE_TIME CMB_TEMPERATURE TEMPERATURE_CMB SOLAR_V_MAG MAGNITUDE_SOLAR_V SOLAR_V_ABS_MAG MAGNITUDE_SOLAR_V_ABSOLUTE SOLAR_RADIUS RADIUS_SOLAR EARTH_MASS MASS_EARTH EARTH_RADIUS RADIUS_EARTH SOLAR_TEMPERATURE TEMPERATURE_SOLAR_SURFACE SOLAR_DENSITY DENSITY_SOLAR EARTH_DENSITY DENSITY_EARTH SOLAR_GRAVITY GRAVITY_SOLAR EARTH_GRAVITY GRAVITY_EARTH LUNAR_RADIUS RADIUS_LUNAR LUNAR_MASS MASS_LUNAR LUNAR_SM_AXIS AXIS_SM_LUNAR LUNAR_ECCENTRICITY ECCENTRICITY_LUNAR THOMSON_XSECTION THOMSON_CROSS_SECTION ELECTRON_MASS MASS_ELECTRON PROTON_MASS MASS_PROTON NEUTRON_MASS MASS_NEUTRON HYDROGEN_MASS MASS_HYDROGEN MASS_ALPHA ELECTRON_RADIUS RADIUS_ELECTRON BOHR_RADIUS RADIUS_BOHR RADIUS_JUPITER MASS_JUPITER LIGHT_SPEED HBAR ELECTRON_CHARGE A_RAD VACUUM_IMPEDANCE PERMITIVITY_0 PERMEABILITY_0 CONSTANT_MAGNETIC FOURPI YEAR_JULIAN SOLAR_MASS SOLAR_LUMINOSITY RHO_C CMB_TEMPERATURE SOLAR_V_MAG SOLAR_V_ABS_MAG SOLAR_RADIUS EARTH_MASS EARTH_RADIUS SOLAR_TEMPERATURE SOLAR_DENSITY EARTH_DENSITY SOLAR_GRAVITY EARTH_GRAVITY LUNAR_RADIUS LUNAR_MASS LUNAR_SM_AXIS LUNAR_ECCENTRICITY THOMSON_XSECTION ELECTRON_MASS PROTON_MASS NEUTRON_MASS HYDROGEN_MASS ELECTRON_RADIUS BOHR_RADIUS
    pretty precision
);

our %EXPORT_TAGS = (
    all => [qw( LIGHT_SPEED SPEED_LIGHT BOLTZMANN GRAVITATIONAL ELECTRON_VOLT PLANCK HBAR H_BAR ELECTRON_CHARGE CHARGE_ELEMENTARY STEFAN_BOLTZMANN A_RAD DENSITY_RADIATION WIEN ALPHA VACUUM_IMPEDANCE IMPEDANCE_VACUUM PERMITIVITY_0 PERMITIV_FREE_SPACE PERMEABILITY_0 CONSTANT_MAGNETIC PERMEABL_FREE_SPACE PI FOURPI FOUR_PI STERADIAN EXP ATOMIC_MASS_UNIT PARSEC ASTRONOMICAL_UNIT LIGHT_YEAR ANGSTROM JANSKY AVOGADRO YEAR_JULIAN YEAR YEAR_TROPICAL YEAR_SIDEREAL YEAR_ANOMALISTIC YEAR_ECLIPSE SOLAR_MASS MASS_SOLAR SOLAR_LUMINOSITY LUMINOSITY_SOLAR RHO_C DENSITY_CRITICAL_RHOc HUBBLE_TIME CMB_TEMPERATURE TEMPERATURE_CMB SOLAR_V_MAG MAGNITUDE_SOLAR_V SOLAR_V_ABS_MAG MAGNITUDE_SOLAR_V_ABSOLUTE SOLAR_RADIUS RADIUS_SOLAR EARTH_MASS MASS_EARTH EARTH_RADIUS RADIUS_EARTH SOLAR_TEMPERATURE TEMPERATURE_SOLAR_SURFACE SOLAR_DENSITY DENSITY_SOLAR EARTH_DENSITY DENSITY_EARTH SOLAR_GRAVITY GRAVITY_SOLAR EARTH_GRAVITY GRAVITY_EARTH LUNAR_RADIUS RADIUS_LUNAR LUNAR_MASS MASS_LUNAR LUNAR_SM_AXIS AXIS_SM_LUNAR LUNAR_ECCENTRICITY ECCENTRICITY_LUNAR THOMSON_XSECTION THOMSON_CROSS_SECTION ELECTRON_MASS MASS_ELECTRON PROTON_MASS MASS_PROTON NEUTRON_MASS MASS_NEUTRON HYDROGEN_MASS MASS_HYDROGEN MASS_ALPHA ELECTRON_RADIUS RADIUS_ELECTRON BOHR_RADIUS RADIUS_BOHR RADIUS_JUPITER MASS_JUPITER )],
    alternates => [qw( LIGHT_SPEED HBAR ELECTRON_CHARGE A_RAD VACUUM_IMPEDANCE PERMITIVITY_0 PERMEABILITY_0 CONSTANT_MAGNETIC FOURPI YEAR_JULIAN SOLAR_MASS SOLAR_LUMINOSITY RHO_C CMB_TEMPERATURE SOLAR_V_MAG SOLAR_V_ABS_MAG SOLAR_RADIUS EARTH_MASS EARTH_RADIUS SOLAR_TEMPERATURE SOLAR_DENSITY EARTH_DENSITY SOLAR_GRAVITY EARTH_GRAVITY LUNAR_RADIUS LUNAR_MASS LUNAR_SM_AXIS LUNAR_ECCENTRICITY THOMSON_XSECTION ELECTRON_MASS PROTON_MASS NEUTRON_MASS HYDROGEN_MASS ELECTRON_RADIUS BOHR_RADIUS )],
    conversion => [qw( ELECTRON_VOLT STERADIAN ATOMIC_MASS_UNIT PARSEC ASTRONOMICAL_UNIT LIGHT_YEAR ANGSTROM JANSKY AVOGADRO YEAR YEAR_JULIAN YEAR_TROPICAL YEAR_SIDEREAL YEAR_ANOMALISTIC YEAR_ECLIPSE )],
    cosmology => [qw( SPEED_LIGHT LIGHT_SPEED GRAVITATIONAL PLANCK H_BAR HBAR STEFAN_BOLTZMANN DENSITY_RADIATION A_RAD WIEN ALPHA IMPEDANCE_VACUUM VACUUM_IMPEDANCE PARSEC ASTRONOMICAL_UNIT LIGHT_YEAR JANSKY YEAR YEAR_JULIAN YEAR_TROPICAL YEAR_SIDEREAL MASS_SOLAR SOLAR_MASS LUMINOSITY_SOLAR SOLAR_LUMINOSITY DENSITY_CRITICAL_RHOc RHO_C HUBBLE_TIME TEMPERATURE_CMB CMB_TEMPERATURE MAGNITUDE_SOLAR_V SOLAR_V_MAG MAGNITUDE_SOLAR_V_ABSOLUTE SOLAR_V_ABS_MAG )],
    electromagnetic => [qw( SPEED_LIGHT LIGHT_SPEED BOLTZMANN ELECTRON_VOLT PLANCK H_BAR HBAR CHARGE_ELEMENTARY ELECTRON_CHARGE STEFAN_BOLTZMANN DENSITY_RADIATION A_RAD WIEN ALPHA IMPEDANCE_VACUUM VACUUM_IMPEDANCE PERMITIV_FREE_SPACE PERMITIVITY_0 PERMEABL_FREE_SPACE PERMEABILITY_0 CONSTANT_MAGNETIC ANGSTROM JANSKY THOMSON_CROSS_SECTION THOMSON_XSECTION MASS_ELECTRON ELECTRON_MASS RADIUS_ELECTRON ELECTRON_RADIUS RADIUS_BOHR BOHR_RADIUS )],
    fundamental => [qw( SPEED_LIGHT LIGHT_SPEED BOLTZMANN GRAVITATIONAL ELECTRON_VOLT PLANCK H_BAR HBAR CHARGE_ELEMENTARY ELECTRON_CHARGE STEFAN_BOLTZMANN DENSITY_RADIATION A_RAD WIEN ALPHA IMPEDANCE_VACUUM VACUUM_IMPEDANCE PERMITIV_FREE_SPACE PERMITIVITY_0 PERMEABL_FREE_SPACE PERMEABILITY_0 CONSTANT_MAGNETIC )],
    mathematical => [qw( PI FOUR_PI FOURPI EXP )],
    nuclear => [qw( ELECTRON_VOLT PLANCK H_BAR HBAR CHARGE_ELEMENTARY ELECTRON_CHARGE STEFAN_BOLTZMANN DENSITY_RADIATION A_RAD WIEN ALPHA IMPEDANCE_VACUUM VACUUM_IMPEDANCE PERMITIV_FREE_SPACE PERMITIVITY_0 PERMEABL_FREE_SPACE PERMEABILITY_0 CONSTANT_MAGNETIC ATOMIC_MASS_UNIT ANGSTROM AVOGADRO THOMSON_CROSS_SECTION THOMSON_XSECTION MASS_ELECTRON ELECTRON_MASS MASS_PROTON PROTON_MASS MASS_NEUTRON NEUTRON_MASS MASS_HYDROGEN HYDROGEN_MASS MASS_ALPHA RADIUS_ELECTRON ELECTRON_RADIUS RADIUS_BOHR BOHR_RADIUS )],
    planetary => [qw( GRAVITATIONAL WIEN PARSEC ASTRONOMICAL_UNIT LIGHT_YEAR YEAR_ANOMALISTIC YEAR_ECLIPSE MASS_SOLAR SOLAR_MASS LUMINOSITY_SOLAR SOLAR_LUMINOSITY MAGNITUDE_SOLAR_V SOLAR_V_MAG MAGNITUDE_SOLAR_V_ABSOLUTE SOLAR_V_ABS_MAG RADIUS_SOLAR SOLAR_RADIUS MASS_EARTH EARTH_MASS RADIUS_EARTH EARTH_RADIUS TEMPERATURE_SOLAR_SURFACE SOLAR_TEMPERATURE DENSITY_SOLAR SOLAR_DENSITY DENSITY_EARTH EARTH_DENSITY GRAVITY_SOLAR SOLAR_GRAVITY GRAVITY_EARTH EARTH_GRAVITY RADIUS_LUNAR LUNAR_RADIUS MASS_LUNAR LUNAR_MASS AXIS_SM_LUNAR LUNAR_SM_AXIS ECCENTRICITY_LUNAR LUNAR_ECCENTRICITY RADIUS_JUPITER MASS_JUPITER )],
);

1; # Perl is my Igor

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Constants::2019 - Perl library to provide physical constants for use in Physics and Astronomy based on values from 2018 CODATA.

=head1 VERSION

version 0.14051

=head1 SYNOPSIS

    use strict;
    use Astro::Constants qw( :all );

    # to calculate the gravitational force of the Sun on the Earth
    # in Newtons, use GMm/r^2
    my $force_sun_earth = GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2;

=head1 DESCRIPTION

This module provides physical and mathematical constants for use
in Astronomy and Astrophysics.

The values are stored in F<Physical_Constants.xml> in the B<data> directory
and are mostly based on the 2018 CODATA values from NIST.

B<NOTE:> Other popular languages are still using I<2014> CODATA values
for their constants and may produce different results in comparison.
On the roadmap is a set of modules to allow you to specify the year or
data set for the values of constants, defaulting to the most recent.

The C<:all> tag imports all the constants in their long name forms
(i.e. GRAVITATIONAL).  Useful subsets can be imported with these tags:
C<:fundamental> C<:conversion> C<:mathematics> C<:cosmology>
C<:planetary> C<:electromagnetic> or C<:nuclear>.
Alternate names such as LIGHT_SPEED instead of SPEED_LIGHT or HBAR
instead of H_BAR are imported with C<:alternates>.  I'd like
to move away from their use, but they have been in the module for years.

Long name constants are constructed with the L<constant> pragma and
are not interpolated in double quotish situations because they are
really inlined functions.
Short name constants were constructed with the age-old idiom of fiddling
with the symbol table using typeglobs, e.g. C<*PI = \3.14159>,
and can be slower than the long name constants.

=head2 Why use this module

You are tired of typing in all those numbers and having to make sure that they are
all correct.  How many significant figures is enough or too much?  Where's the
definitive source, Wikipedia?  And which mass does "$m1" refer to, solar or lunar?

The constant values in this module are protected against accidental re-assignment
in your code.  The test suite protects them against accidental finger trouble in my code.
Other people are using this module, so more eyeballs are looking for errors
and we all benefit.  The constant names are a little longer than you might like,
but you gain in the long run from readable, sharable code that is clear in meaning.
Your programming errors are a little easier to find when you can see that the units
don't match.  Isn't it reassuring that you can verify how a number is produced
and which meeting of which standards body is responsible for its value?

Trusting someone else's code does carry some risk, which you I<should> consider,
but have you also considered the risk of doing it yourself with no one else 
to check your work?  And, are you going to check for the latest values from NIST
every 4 years?

=head3 And plus, it's B<FASTER>

Benchmarking has shown that the imported constants can be more than 3 times
faster than using variables or other constant modules because of the way
the compiler optimizes your code.  So, if you've got a lot of calculating to do,
this is the module to do it with.

=head1 CONSTANTS

=head2 SPEED_LIGHT

    299792458

speed of light in a vacuum

This constant is also available using the alternate name C<LIGHT_SPEED>
(imported using the :alternate tag for backwards compatibility)

=head2 BOLTZMANN

    1.380649e-23

Boltzmann's constant

=head2 GRAVITATIONAL

    6.67430e-11

universal gravitational constant

=head2 ELECTRON_VOLT

    1.602176634e-19

electron volt

=head2 PLANCK

    6.62607015e-34

Planck constant

=head2 H_BAR

    1.0545718176763e-34

the reduced Planck constant, Planck's constant (exact) /2pi

This constant is also available using the alternate name C<HBAR>
(imported using the :alternate tag for backwards compatibility)

=head2 CHARGE_ELEMENTARY

    1.602176634e-19

electron charge (defined positive)

This constant is also available using the alternate name C<ELECTRON_CHARGE>
(imported using the :alternate tag for backwards compatibility)

=head2 STEFAN_BOLTZMANN

    5.670374419e-8

Stefan-Boltzmann constant

=head2 DENSITY_RADIATION

    7.565723e-16

radiation density constant, 4 * sigma / c

This constant is also available using the alternate name C<A_RAD>
(imported using the :alternate tag for backwards compatibility)

=head2 WIEN

    2.897771955e-3

Wien wavelength displacement law constant

=head2 ALPHA

    7.2973525693e-3

fine structure constant

=head2 IMPEDANCE_VACUUM

    376.730313461

characteristic impedance of vacuum

This constant is also available using the alternate name C<VACUUM_IMPEDANCE>
(imported using the :alternate tag for backwards compatibility)

=head2 PERMITIV_FREE_SPACE

    8.8541878128e-12

permittivity of free space, epsilon_0, the electric constant

This constant is also available using the alternate name C<PERMITIVITY_0>
(imported using the :alternate tag for backwards compatibility)

=head2 PERMEABL_FREE_SPACE

    1.25663706212e-6

permeability of free space, mu_0, the magnetic constant

This constant is also available using these alternate names (imported using the :alternate tag): PERMEABILITY_0, CONSTANT_MAGNETIC

=head2 PI

    3.14159265358979324

trig constant pi

=head2 FOUR_PI

    12.5663706143592

trig constant pi times 4 (shorthand for some calculations)

This constant is also available using the alternate name C<FOURPI>
(imported using the :alternate tag for backwards compatibility)

=head2 STERADIAN

    3282.80635001174

a measure of solid angle in square degrees and a SI derived unit

=head2 EXP

    2.71828182846

base of natural logarithm

=head2 ATOMIC_MASS_UNIT

    1.66053906660e-27

unified atomic mass unit, 1 u

=head2 PARSEC

    3.08567758149e16

parsec

=head2 ASTRONOMICAL_UNIT

    149597870700

astronomical unit

=head2 LIGHT_YEAR

    9460730472580800

the distance that light travels in vacuum in one Julian year

=head2 ANGSTROM

    1e-10

Angstrom

=head2 JANSKY

    1e-26

Jansky, a unit of flux density

=head2 AVOGADRO

    6.02214076e23

Avogadro's number

=head2 YEAR

    31557600

defined as exactly 365.25 days of 86400 SI seconds

This constant is also available using the alternate name C<YEAR_JULIAN>
(imported using the :alternate tag for backwards compatibility)

=head2 YEAR_TROPICAL

    31556925.1

the period of time for the ecliptic longitude of the Sun to increase 360 degrees, approximated by the Gregorian calendar

=head2 YEAR_SIDEREAL

    31558149.8

the period of revolution of the Earth around the Sun in a fixed reference frame

=head2 YEAR_ANOMALISTIC

    31558432.6

the period between successive passages of the Earth through perihelion

=head2 YEAR_ECLIPSE

    29947974.3

the period between successive passages of the Sun (as seen from the geocenter) through the same lunar node

=head2 MASS_SOLAR

    1.9884e30

solar mass

This constant is also available using the alternate name C<SOLAR_MASS>
(imported using the :alternate tag for backwards compatibility)

=head2 LUMINOSITY_SOLAR

    3.828e26

solar luminosity

This constant is also available using the alternate name C<SOLAR_LUMINOSITY>
(imported using the :alternate tag for backwards compatibility)

=head2 DENSITY_CRITICAL_RHOC

    1.87834e-26

Critical Density parameter expressed in terms of

	      ρ_c / h² = 3 × (100 km s⁻¹ Mpc⁻¹)² / 8πG

Multiply by the square of the dimensionless Hubble parameter, h, in your calculations to get the actual value

This constant is also available using the alternate name C<RHO_C>
(imported using the :alternate tag for backwards compatibility)

=head2 HUBBLE_TIME

    3.0853056e17

Hubble time *h, the inverse of Hubble's constant valued at 100 km/s/Mpc (DEPRECATED - see ChangeLog)

=head2 TEMPERATURE_CMB

    2.72548

cosmic microwave background temperature in Kelvin

This constant is also available using the alternate name C<CMB_TEMPERATURE>
(imported using the :alternate tag for backwards compatibility)

=head2 MAGNITUDE_SOLAR_V

    -26.74

visual brightness of the Sun

This constant is also available using the alternate name C<SOLAR_V_MAG>
(imported using the :alternate tag for backwards compatibility)

=head2 MAGNITUDE_SOLAR_V_ABSOLUTE

    4.83

solar absolute V magnitude

This constant is also available using the alternate name C<SOLAR_V_ABS_MAG>
(imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_SOLAR

    6.96e8

solar radius

This constant is also available using the alternate name C<SOLAR_RADIUS>
(imported using the :alternate tag for backwards compatibility)

=head2 MASS_EARTH

    5.9722e24

mass of Earth

This constant is also available using the alternate name C<EARTH_MASS>
(imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_EARTH

    6.3781366e6

radius of Earth

This constant is also available using the alternate name C<EARTH_RADIUS>
(imported using the :alternate tag for backwards compatibility)

=head2 TEMPERATURE_SOLAR_SURFACE

    5772

surface temperature of sun (photosphere)

This constant is also available using the alternate name C<SOLAR_TEMPERATURE>
(imported using the :alternate tag for backwards compatibility)

=head2 DENSITY_SOLAR

    1408

mean solar density

This constant is also available using the alternate name C<SOLAR_DENSITY>
(imported using the :alternate tag for backwards compatibility)

=head2 DENSITY_EARTH

    5515

mean Earth density

This constant is also available using the alternate name C<EARTH_DENSITY>
(imported using the :alternate tag for backwards compatibility)

=head2 GRAVITY_SOLAR

    274.78

solar surface gravity

This constant is also available using the alternate name C<SOLAR_GRAVITY>
(imported using the :alternate tag for backwards compatibility)

=head2 GRAVITY_EARTH

    9.80665

Earth surface gravity

This constant is also available using the alternate name C<EARTH_GRAVITY>
(imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_LUNAR

    1.7381e6

lunar radius

This constant is also available using the alternate name C<LUNAR_RADIUS>
(imported using the :alternate tag for backwards compatibility)

=head2 MASS_LUNAR

    7.346e22

lunar mass

This constant is also available using the alternate name C<LUNAR_MASS>
(imported using the :alternate tag for backwards compatibility)

=head2 AXIS_SM_LUNAR

    3.84402e8

lunar orbital semi-major axis

This constant is also available using the alternate name C<LUNAR_SM_AXIS>
(imported using the :alternate tag for backwards compatibility)

=head2 ECCENTRICITY_LUNAR

    0.0549

lunar orbital eccentricity

This constant is also available using the alternate name C<LUNAR_ECCENTRICITY>
(imported using the :alternate tag for backwards compatibility)

=head2 THOMSON_CROSS_SECTION

    6.6524587321e-29

Thomson cross-section

This constant is also available using the alternate name C<THOMSON_XSECTION>
(imported using the :alternate tag for backwards compatibility)

=head2 MASS_ELECTRON

    9.1093837015e-31

mass of electron

This constant is also available using the alternate name C<ELECTRON_MASS>
(imported using the :alternate tag for backwards compatibility)

=head2 MASS_PROTON

    1.67262192369e-27

mass of proton

This constant is also available using the alternate name C<PROTON_MASS>
(imported using the :alternate tag for backwards compatibility)

=head2 MASS_NEUTRON

    1.67492749804e-27

neutron mass

This constant is also available using the alternate name C<NEUTRON_MASS>
(imported using the :alternate tag for backwards compatibility)

=head2 MASS_HYDROGEN

    1.6738e-27

mass of Hydrogen atom --
This value is from the IUPAC and is a little smaller than MASS_PROTON + MASS_ELECTRON, but within the uncertainty given here.  The current value is 1.008u +/- 0.0002 derived from a range of terrestrial materials.  If this is for precision work, you had best understand what you're using.  See https://iupac.org/what-we-do/periodic-table-of-elements/

This constant is also available using the alternate name C<HYDROGEN_MASS>
(imported using the :alternate tag for backwards compatibility)

=head2 MASS_ALPHA

    6.6446573357e-27

mass of alpha particle

=head2 RADIUS_ELECTRON

    2.8179403262e-15

classical electron radius

This constant is also available using the alternate name C<ELECTRON_RADIUS>
(imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_BOHR

    5.29177210903e-11

Bohr radius

This constant is also available using the alternate name C<BOHR_RADIUS>
(imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_JUPITER

    69911000

Volumetric mean radius of Jupiter

=head2 MASS_JUPITER

    1.89819e27

mass of Jupiter

=head1 EXPORT

Nothing is exported by default, so the module doesn't clobber any of your variables.
Select from the following tags:

=over 4

=item *

C<:all>             (everything except :deprecated)

=item *

C<:fundamental>

=item *

C<:conversion>

=item *

C<:mathematics>

=item *

C<:cosmology>

=item *

C<:planetary>

=item *

C<:electromagnetic>

=item *

C<:nuclear>

=item *

C<:alternates>

=item *

C<:deprecated>

=back

=head1 FUNCTIONS

=head2 pretty

This is a helper function that rounds a value or list of values to 5 significant figures.

=head2 precision

Give this method the string of the constant and it returns the precision or uncertainty
listed.

  $rel_precision = precision('GRAVITATIONAL');
  $abs_precision = precision('MASS_EARTH');

At the moment you need to know whether the uncertainty is relative or absolute.
Looking to fix this in future versions.

=head2 Deprecated functions

I've gotten rid of C<list_constants> and C<describe_constants> because they are now in
the documentation.  Use C<perldoc Astro::Constants> for that information.

=head1 SEE ALSO

=over 4

=item *

L<Astro::Cosmology>

=item *

L<Perl Data Language|PDL>

=item *

L<NIST|http://physics.nist.gov>

=item *

L<Astronomical Almanac|http://asa.usno.navy.mil>

=item *

L<IAU 2015 Resolution B3|http://iopscience.iop.org/article/10.3847/0004-6256/152/2/41/meta>

=item *

L<Neil Bower's review on providing read-only values|http://neilb.org/reviews/constants.html>

=item *

L<Test::Number::Delta>

=item *

L<Test::Deep::NumberTolerant> for testing values within objects

=back

Reference Documents:

=over 4

=item *

L<IAU 2009 system of astronomical constants|http://aa.usno.navy.mil/publications/reports/Luzumetal2011.pdf>

=item *

L<Astronomical Constants 2016|http://asa.usno.navy.mil/static/files/2016/Astronomical_Constants_2016.pdf>

=item *

L<IAU recommendations concerning units|https://www.iau.org/publications/proceedings_rules/units>

=item *

L<Re-definition of the Astronomical Unit|http://syrte.obspm.fr/IAU_resolutions/Res_IAU2012_B2.pdf>

=back

=head1 REPOSITORY

* L<github|https://github.com/duffee/Astro-Constants>

=head1 ISSUES

Feel free to file bugs or suggestions in the
L<Issues|https://github.com/duffee/Astro-Constants/issues> section of the Github repository.

Using C<strict> is a must with this code.  Any constants you forgot to import will
evaluate to 0 and silently introduce errors in your code.  Caveat Programmer.

If you are using this module, drop me a line using any available means at your 
disposal, including
*gasp* email (address in the Author section), to let me know how you're using it. 
What new features would you like to see?

Current best method to contact me is via a Github Issue.

=head2 Extending the data set

If you want to add in your own constants or override the factory defaults,
run make, edit the F<PhysicalConstants.xml> file and then run C<dzil build> again.
If you have a pre-existing F<PhysicalConstants.xml> file, drop it in place
before running C<dzil build>.

=head2 Availability

the original astroconst sites have disappeared

=head1 ROADMAP

I have moved to a I<noun_adjective> format for long names.
LIGHT_SPEED and SOLAR_MASS become SPEED_LIGHT and MASS_SOLAR.
This principle should make the code easier to read with the most
important information coming at the beginning of the name.
See also L<Astro::Constants::Roadmap>

=head1 ASTROCONST  X<ASTROCONST>

(Gleaned from the Astroconst home page -
L<astroconst.org|http://web.astroconst.org> )

Astroconst is a set of header files in various languages (currently C,
Fortran, Perl, Java, IDL and Gnuplot) that provide a variety of useful
astrophysical constants without constantly needing to look them up.

The generation of the header files from one data file is automated, so you
can add new constants to the data file and generate new header files in all
the appropriate languages without needing to fiddle with each header file
individually.

This package was created and is maintained by Jeremy Bailin.  It's license
states that it I<is completely free, both as in speech and as in beer>.

=head1 DISCLAIMER

No warranty expressed or implied.  This is free software.  If you
want someone to assume the risk of an incorrect value, you better
be paying them.

(What would you want me to test in order for you to depend on this module?)

I<from Jeremy Bailin's astroconst header files>

The Astroconst values have been gleaned from a variety of sources,
and have quite different precisions depending both on the known
precision of the value in question, and in some cases on the
precision of the source I found it from. These values are not
guaranteed to be correct. Astroconst is not certified for any use
whatsoever. If your rocket crashes because the precision of the
lunar orbital eccentricity isn't high enough, that's too bad.

=head1 ACKNOWLEDGMENTS

Jeremy Balin, for writing the astroconst package and helping
test and develop this module.

Doug Burke, for giving me the idea to write this module in the
first place, tidying up Makefile.PL, testing and improving the
documentation.

=head1 AUTHOR

Boyd Duffee <duffee@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Boyd Duffee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
