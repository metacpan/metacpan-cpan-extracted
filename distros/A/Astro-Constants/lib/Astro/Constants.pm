package Astro::Constants;
# ABSTRACT: this library provides physical constants for use in Astronomy
$Astro::Constants::VERSION = '0.1100';
use strict;
use warnings;

  'They are not constant but are changing still. - Cymbeline, Act II, Scene 5';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Constants - this library provides physical constants for use in Astronomy

=head1 VERSION

version 0.1100

=head1 SYNOPSIS

    use strict;		# important!
    use Astro::Constants::MKS qw/:long/;

    # to calculate the gravitational force of the Sun on the Earth in Newtons, use GMm/r^2
    my $force_sun_earth = GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2;

=head1 DESCRIPTION

This module provides physical and mathematical constants for use
in Astronomy and Astrophysics.  The two metric systems of units,
MKS and CGS, are kept in two separate modules and are called by
name explicitly.
It allows you to choose between constants in units of
centimetres /grams /seconds
with B<Astro::Constants::CGS> and metres /kilograms /seconds with
B<Astro::Constants::MKS>.

Short forms of the constant names are included to provide backwards
compatibility with older versions based on Jeremy Bailin's Astroconst
library and are available through the import tag C<:short>.

The values are stored in F<Physical_Constants.xml> in the B<data> directory
and are mostly based on the 2014 CODATA values from NIST.

Long name constants are constructed with the L<constant> pragma and
are not interpolated in double quotish situations because they are 
really inlined functions.
Short name constants are constructed with the age-old idiom of fiddling
with the symbol table using typeglobs, e.g. C<*PI = \3.14159>,
and may be slower than the long name constants.
I<This could do with some benchmarking.>

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
to check your work?

=head1 METHODS

=head2 SPEED_LIGHT

    2.99792458e8	MKS
    2.99792458e10	CGS

speed of light in a vacuum

This constant is also available using the short name C<$A_c>
as well as the alternate name C<LIGHT_SPEED> (imported using the :alternate tag for backwards compatibility)

=head2 BOLTZMANN

    1.38064852e-23	MKS
    1.38064852e-16	CGS

Boltzmann's constant

This constant is also available using the short name C<$A_k>

=head2 GRAVITATIONAL

    6.67408e-11	MKS
    6.67408e-8	CGS

universal gravitational constant

This constant is also available using the short name C<$A_G>

=head2 ELECTRON_VOLT

    1.6021766208e-19	MKS
    1.6021766208e-12	CGS

electron volt

This constant is also available using the short name C<$A_eV>

=head2 PLANCK

    6.626070040e-34	MKS
    6.626070040e-27	CGS

Planck constant

This constant is also available using the short name C<$A_h>

=head2 H_BAR

    1.054571800e-34	MKS
    1.054571800e-27	CGS

Planck's constant /2pi

This constant is also available using the short name C<$A_hbar>
as well as the alternate name C<HBAR> (imported using the :alternate tag for backwards compatibility)

=head2 ELECTRON_CHARGE

    1.6021766208e-19	MKS
    4.8032046729e-10	CGS

electron charge (defined positive)

This constant is also available using the short name C<$A_e>
as well as the alternate name C<CHARGE_ELEMENTARY> (imported using the :alternate tag for backwards compatibility)

=head2 STEFAN_BOLTZMANN

    5.670367e-8	MKS
    5.670367e-5	CGS

Stefan-Boltzmann constant

This constant is also available using the short name C<$A_sigma>

=head2 DENSITY_RADIATION

    7.565723e-16	MKS
    7.565723e-15	CGS

radiation density constant, 4 * sigma / c

This constant is also available using the short name C<$A_arad>
as well as the alternate name C<A_RAD> (imported using the :alternate tag for backwards compatibility)

=head2 WIEN

    2.8977729e-3	MKS
    2.8977729e-1	CGS

Wien wavelength displacement law constant

This constant is also available using the short name C<$A_Wien>

=head2 ALPHA

    7.2973525664e-3	MKS
    7.2973525664e-3	CGS

fine structure constant

This constant is also available using the short name C<$A_alpha>

=head2 IMPEDANCE_VACUUM

    376.730313461

characteristic impedance of vacuum

This constant is also available using the short name C<$A_Z0>
as well as the alternate name C<VACUUM_IMPEDANCE> (imported using the :alternate tag for backwards compatibility)

=head2 PERMITIV_FREE_SPACE

    8.854187817e-12	MKS
    1	CGS

permittivity of free space, epsilon_0, the electric constant

This constant is also available using the short name C<$A_eps0>
as well as the alternate name C<PERMITIVITY_0> (imported using the :alternate tag for backwards compatibility)

=head2 PERMEABL_FREE_SPACE

    1.2566370614e-6	MKS
    1	CGS

permeability of free space, mu_0, the magnetic constant

This constant is also available using the short name C<$A_mu0>
as well as these alternate names (imported using the :alternate tag): PERMEABILITY_0, CONSTANT_MAGNETIC

=head2 PI

    3.14159265358979324

trig constant pi

This constant is also available using the short name C<$A_pi>

=head2 FOUR_PI

    12.5663706143592

trig constant pi times 4 (shorthand for some calculations)

This constant is also available using the short name C<$A_4pi>
as well as the alternate name C<FOURPI> (imported using the :alternate tag for backwards compatibility)

=head2 STERADIAN

    57.2957795130823

a measure of solid angle in square degrees

This constant is also available using the short name C<$A_ster>

=head2 EXP

    2.71828182846

base of natural logarithm

This constant is also available using the short name C<$A_exp>

=head2 ATOMIC_MASS_UNIT

    1.660539040e-27	MKS
    1.660539040e-24	CGS

atomic mass unit, 1 u

This constant is also available using the short name C<$A_amu>

=head2 PARSEC

    3.08567758149e16	MKS
    3.08567758149e18	CGS

parsec

This constant is also available using the short name C<$A_pc>

=head2 ASTRONOMICAL_UNIT

    149_597_870_700	MKS
    1.496e13	CGS

astronomical unit

This constant is also available using the short name C<$A_AU>

=head2 LIGHT_YEAR

    9_460_730_472_580_800	MKS
    9.4607304725808e17	CGS

the distance that light travels in vacuum in one Julian year

This constant is also available using the short name C<$A_ly>

=head2 ANGSTROM

    1e-10	MKS
    1e-8	CGS

Angstrom

This constant is also available using the short name C<$A_AA>

=head2 JANSKY

    1e-26	MKS
    1e-23	CGS

Jansky

This constant is also available using the short name C<$A_Jy>

=head2 AVOGADRO

    6.022140857e23

Avogadro's number

This constant is also available using the short name C<$A_NA>

=head2 YEAR

    31_557_600

defined as exactly 365.25 days of 86400 SI seconds

This constant is also available using the short name C<$A_yr>
as well as the alternate name C<YEAR_JULIAN> (imported using the :alternate tag for backwards compatibility)

=head2 YEAR_TROPICAL

    31_556_925.1

the period of time for the ecliptic longitude of the Sun to increase 360 degrees, approximated by the Gregorian calendar

=head2 YEAR_SIDEREAL

    31_558_149.8

the period of revolution of the Earth around the Sun in a fixed reference frame

=head2 YEAR_ANOMALISTIC

    31_558_432.6

the period between successive passages of the Earth through perihelion

=head2 YEAR_ECLIPSE

    29_947_974.3

the period between successive passages of the Sun (as seen from the geocenter) through the same lunar node

=head2 MASS_SOLAR

    1.9884e30	MKS
    1.9884e33	CGS

solar mass

This constant is also available using the short name C<$A_msun>
as well as the alternate name C<SOLAR_MASS> (imported using the :alternate tag for backwards compatibility)

=head2 LUMINOSITY_SOLAR

    3.846e26	MKS
    3.846e33	CGS

solar luminosity

This constant is also available using the short name C<$A_Lsun>
as well as the alternate name C<SOLAR_LUMINOSITY> (imported using the :alternate tag for backwards compatibility)

=head2 DENSITY_CRITICAL_RHOc

    1.8791e-26	MKS
    1.8791e-29	CGS

critical density /h^2

This constant is also available using the short name C<$A_rhoc>
as well as the alternate name C<RHO_C> (imported using the :alternate tag for backwards compatibility)

=head2 HUBBLE_TIME

    3.0853056e17

Hubble time *h, the inverse of Hubble's constant valued at 100 km/s/Mpc (DEPRECATED - see ChangeLog)

This constant is also available using the short name C<$A_tH>

=head2 TEMPERATURE_CMB

    2.725

cosmic microwave background temperature in Kelvin

This constant is also available using the short name C<$A_TCMB>
as well as the alternate name C<CMB_TEMPERATURE> (imported using the :alternate tag for backwards compatibility)

=head2 MAGNITUDE_SOLAR_V

    -26.74

solar V magnitude

This constant is also available using the short name C<$A_Vsun>
as well as the alternate name C<SOLAR_V_MAG> (imported using the :alternate tag for backwards compatibility)

=head2 MAGNITUDE_SOLAR_V_ABSOLUTE

    4.83

solar absolute V magnitude

This constant is also available using the short name C<$A_MVsun>
as well as the alternate name C<SOLAR_V_ABS_MAG> (imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_SOLAR

    6.96e8	MKS
    6.96e10	CGS

solar radius

This constant is also available using the short name C<$A_rsun>
as well as the alternate name C<SOLAR_RADIUS> (imported using the :alternate tag for backwards compatibility)

=head2 MASS_EARTH

    5.9722e24	MKS
    5.9722e27	CGS

mass of Earth

This constant is also available using the short name C<$A_mearth>
as well as the alternate name C<EARTH_MASS> (imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_EARTH

    6.378_136_6e6	MKS
    6.378_136_6e8	CGS

radius of Earth

This constant is also available using the short name C<$A_rearth>
as well as the alternate name C<EARTH_RADIUS> (imported using the :alternate tag for backwards compatibility)

=head2 TEMPERATURE_SOLAR_SURFACE

    5778

surface temperature of sun

This constant is also available using the short name C<$A_Tsun>
as well as the alternate name C<SOLAR_TEMPERATURE> (imported using the :alternate tag for backwards compatibility)

=head2 DENSITY_SOLAR

    1408	MKS
    1.408	CGS

mean solar density

This constant is also available using the short name C<$A_dsun>
as well as the alternate name C<SOLAR_DENSITY> (imported using the :alternate tag for backwards compatibility)

=head2 DENSITY_EARTH

    5514	MKS
    5.514	CGS

mean Earth density

This constant is also available using the short name C<$A_dearth>
as well as the alternate name C<EARTH_DENSITY> (imported using the :alternate tag for backwards compatibility)

=head2 GRAVITY_SOLAR

    274.0	MKS
    27400	CGS

solar surface gravity

This constant is also available using the short name C<$A_gsun>
as well as the alternate name C<SOLAR_GRAVITY> (imported using the :alternate tag for backwards compatibility)

=head2 GRAVITY_EARTH

    9.78	MKS
    978	CGS

Earth surface gravity

This constant is also available using the short name C<$A_gearth>
as well as the alternate name C<EARTH_GRAVITY> (imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_LUNAR

    1.7381e6	MKS
    1.7381e8	CGS

lunar radius

This constant is also available using the short name C<$A_rmoon>
as well as the alternate name C<LUNAR_RADIUS> (imported using the :alternate tag for backwards compatibility)

=head2 MASS_LUNAR

    7.342e22	MKS
    7.342e25	CGS

lunar mass

This constant is also available using the short name C<$A_mmoon>
as well as the alternate name C<LUNAR_MASS> (imported using the :alternate tag for backwards compatibility)

=head2 AXIS_SM_LUNAR

    3.844e8	MKS
    3.844e10	CGS

lunar orbital semi-major axis

This constant is also available using the short name C<$A_amoon>
as well as the alternate name C<LUNAR_SM_AXIS> (imported using the :alternate tag for backwards compatibility)

=head2 ECCENTRICITY_LUNAR

    0.0549

lunar orbital eccentricity

This constant is also available using the short name C<$A_emoon>
as well as the alternate name C<LUNAR_ECCENTRICITY> (imported using the :alternate tag for backwards compatibility)

=head2 THOMSON_CROSS_SECTION

    6.6524587158e-29	MKS
    6.6524587158e-25	CGS

Thomson cross-section

This constant is also available using the short name C<$A_sigmaT>
as well as the alternate name C<THOMSON_XSECTION> (imported using the :alternate tag for backwards compatibility)

=head2 MASS_ELECTRON

    9.10938356e-31	MKS
    9.10938356e-28	CGS

mass of electron

This constant is also available using the short name C<$A_me>
as well as the alternate name C<ELECTRON_MASS> (imported using the :alternate tag for backwards compatibility)

=head2 MASS_PROTON

    1.672621898e-27	MKS
    1.672621898e-24	CGS

mass of proton

This constant is also available using the short name C<$A_mp>
as well as the alternate name C<PROTON_MASS> (imported using the :alternate tag for backwards compatibility)

=head2 MASS_NEUTRON

    1.674927471e-27	MKS
    1.674927471e-24	CGS

neutron mass

This constant is also available using the short name C<$A_mn>
as well as the alternate name C<NEUTRON_MASS> (imported using the :alternate tag for backwards compatibility)

=head2 MASS_HYDROGEN

    1.67372e-24

mass of Hydrogen atom

This constant is also available using the short name C<$A_mH>
as well as the alternate name C<HYDROGEN_MASS> (imported using the :alternate tag for backwards compatibility)

=head2 MASS_ALPHA

    6.644_657_230e-27

mass of alpha particle

This constant is also available using the short name C<$A_ma>

=head2 RADIUS_ELECTRON

    2.8179403227e-15	MKS
    2.8179403227e-13	CGS

classical electron radius

This constant is also available using the short name C<$A_re>
as well as the alternate name C<ELECTRON_RADIUS> (imported using the :alternate tag for backwards compatibility)

=head2 RADIUS_BOHR

    5.2917721067e-11	MKS
    5.2917721067e-9	CGS

Bohr radius

This constant is also available using the short name C<$A_a0>
as well as the alternate name C<BOHR_RADIUS> (imported using the :alternate tag for backwards compatibility)

=head2 pretty

This is a helper function that rounds a value or list of values to 5 significant figures.

=head2 precision

Give this method the string of the constant and it returns the precision or uncertainty
listed.

  $rel_precision = precision('GRAVITATIONAL');
  $abs_precision = precision('MASS_EARTH');

At the moment you need to know whether the uncertainty is relative or absolute.
Looking to fix this in future versions.

=head1 EXPORT

Nothing is exported by default, so the module doesn't clobber any of your variables.  
Select from the following tags:

-=for :list
-* :long                (use this one to get the most constants)
-* :short
-* :fundamental
-* :conversion
-* :mathematics
-* :cosmology
-* :planetary
-* :electromagnetic
-* :nuclear
-* :alternates

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

L<Astronomical Constants 2016.pdf|http://asa.usno.navy.mil/static/files/2016/Astronomical_Constants_2016.pdf>

=item *

L<IAU recommendations concerning units|https://www.iau.org/publications/proceedings_rules/units>

=item *

L<Re-definition of the Astronomical Unit|http://syrte.obspm.fr/IAU_resolutions/Res_IAU2012_B2.pdf>

=back

=head1 REPOSITORY

* L<https://github.com/duffee/Astro-Constants>

=head1 ISSUES

File issues/suggestions at the Github repository L<https://github.com/duffee/Astro-Constants>.
The venerable L<RT|https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=Astro-Constants>
is the canonical bug tracker that is clocked by L<meta::cpan|https://metacpan.org/pod/Astro::Constants>.

Using C<strict> is a must with this code.  Any constants you forgot to import will
evaluate to 0 and silently introduce errors in your code.  Caveat Programmer.

If you are using this module, drop me a line using any available means at your 
disposal, including
*gasp* email (address in the Author section), to let me know how you're using it. 
What new features would you like to see?
If you've had an experience with using the module, let other people know what you
think, good or bad, by rating it at
L<cpanratings|http://cpanratings.perl.org/rate/?distribution=Astro-Constants>.

=head2 Extending the data set

If you want to add in your own constants or override the factory defaults,
run make, edit the F<PhysicalConstants.xml> file and then run C<dzil build> again.
If you have a pre-existing F<PhysicalConstants.xml> file, drop it in place
before running C<dzil build>.

=head2 Availability

the original astroconst sites have disappeared

=head1 ROADMAP

I plan to deprecate the short names and change the order in which
long names are constructed, moving to a I<noun_adjective> format.
LIGHT_SPEED and SOLAR_MASS become SPEED_LIGHT and MASS_SOLAR.
This principle should make the code easier to read with the most
important information coming at the beginning of the name.

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

This software is copyright (c) 2017 by Boyd Duffee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
