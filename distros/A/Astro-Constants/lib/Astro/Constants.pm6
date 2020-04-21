unit module Astro::Constants:ver<0.0.4>:auth<github:DUFFEE>;
# ABSTRACT: This library provides physical constants for use in Physics and Astronomy based on values from 2018 CODATA.

# 'They are not constant but are changing still. - Cymbeline, Act II, Scene 5'

=begin pod

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

The C<:long> tag imports all the constants in their long name forms
(i.e. GRAVITATIONAL).  Useful subsets can be imported with these tags:
C<:fundamental> C<:conversion> C<:mathematics> C<:cosmology> 
C<:planetary> C<:electromagnetic> or C<:nuclear>.
Alternate names such as LIGHT_SPEED instead of SPEED_LIGHT or HBAR
instead of H_BAR are imported with C<:alternates>.  I'd like
to move away from their use, but they have been in the module for years.
Short forms of the constant names are included to provide backwards
compatibility with older versions based on Jeremy Bailin's Astroconst
library and are available through the import tag C<:short>.

The values are stored in F<Physical_Constants.xml> in the B<data> directory
and are mostly based on the 2018 CODATA values from NIST.

Long name constants are constructed with the L<constant> pragma and
are not interpolated in double quotish situations because they are 
really inlined functions.
Short name constants are constructed with the age-old idiom of fiddling
with the symbol table using typeglobs, e.g. C<*PI = \3.14159>,
and may be slower than the long name constants.

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

=head3 And plus, it's B<FASTER>

Benchmarking has shown that the imported constants can be more than 3 times
faster than using variables or other constant modules because of the way
the compiler optimizes your code.  So, if you've got a lot of calculating to do,
this is the module to do it with.

=head1 EXPORT

Nothing is exported by default, so the module doesn't clobber any of your variables.  
Select from the following tags:

=item C<:long>                (use this one to get the most constants)
=item C<:short>
=item C<:fundamental>
=item C<:conversion>
=item C<:mathematics>
=item C<:cosmology>
=item C<:planetary>
=item C<:electromagnetic>
=item C<:nuclear>
=item C<:alternates>



=head3 SPEED_LIGHT

    299792458	MKS
    2.99792458e10	CGS

speed of light in a vacuum

This constant is also available using the alternate name C<LIGHT_SPEED> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant SPEED_LIGHT is export(:fundamental :cosmology :electromagnetic) = 299792458;

=head3 BOLTZMANN

    1.380649e-23	MKS
    1.380649e-16	CGS

Boltzmann's constant

=end pod

our constant BOLTZMANN is export(:fundamental :electromagnetic) = 1.380649e-23;

=head3 GRAVITATIONAL

    6.67430e-11	MKS
    6.67430e-8	CGS

universal gravitational constant

=end pod

our constant GRAVITATIONAL is export(:fundamental :cosmology :planetary) = 6.67430e-11;

=head3 ELECTRON_VOLT

    1.602176634e-19	MKS
    1.602176634e-12	CGS

electron volt

=end pod

our constant ELECTRON_VOLT is export(:fundamental :conversion :electromagnetic :nuclear) = 1.602176634e-19;

=head3 PLANCK

    6.62607015e-34	MKS
    6.62607015e-27	CGS

Planck constant

=end pod

our constant PLANCK is export(:fundamental :cosmology :electromagnetic :nuclear) = 6.62607015e-34;

=head3 H_BAR

    1.0545718176763e-34	MKS
    1.054571817e-27	CGS

the reduced Planck constant, Planck's constant (exact) /2pi

This constant is also available using the alternate name C<HBAR> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant H_BAR is export(:fundamental :cosmology :electromagnetic :nuclear) = 1.0545718176763e-34;

=head3 CHARGE_ELEMENTARY

    1.602176634e-19	MKS
    4.8032046729e-10	CGS

electron charge (defined positive)

This constant is also available using the alternate name C<ELECTRON_CHARGE> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant CHARGE_ELEMENTARY is export(:fundamental :electromagnetic :nuclear) = 1.602176634e-19;

=head3 STEFAN_BOLTZMANN

    5.670374419e-8	MKS
    5.670367e-5	CGS

Stefan-Boltzmann constant

=end pod

our constant STEFAN_BOLTZMANN is export(:fundamental :cosmology :electromagnetic :nuclear) = 5.670374419e-8;

=head3 DENSITY_RADIATION

    7.565723e-16	MKS
    7.565723e-15	CGS

radiation density constant, 4 * sigma / c

This constant is also available using the alternate name C<A_RAD> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant DENSITY_RADIATION is export(:fundamental :cosmology :electromagnetic :nuclear) = 7.565723e-16;

=head3 WIEN

    2.897771955e-3	MKS
    2.897771955e-1	CGS

Wien wavelength displacement law constant

=end pod

our constant WIEN is export(:fundamental :electromagnetic :cosmology :planetary :nuclear) = 2.897771955e-3;

=head3 ALPHA

    7.2973525693e-3	MKS
    7.2973525693e-3	CGS

fine structure constant

=end pod

our constant ALPHA is export(:fundamental :cosmology :electromagnetic :nuclear) = 7.2973525693e-3;

=head3 IMPEDANCE_VACUUM

    376.730313461

characteristic impedance of vacuum

This constant is also available using the alternate name C<VACUUM_IMPEDANCE> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant IMPEDANCE_VACUUM is export(:fundamental :cosmology :electromagnetic :nuclear) = 376.730313461;

=head3 PERMITIV_FREE_SPACE

    8.8541878128e-12	MKS
    1	CGS

permittivity of free space, epsilon_0, the electric constant

This constant is also available using the alternate name C<PERMITIVITY_0> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant PERMITIV_FREE_SPACE is export(:fundamental :electromagnetic :nuclear) = 8.8541878128e-12;

=head3 PERMEABL_FREE_SPACE

    1.25663706212e-6	MKS
    1	CGS

permeability of free space, mu_0, the magnetic constant

This constant is also available using these alternate names (imported using the :alternate tag): PERMEABILITY_0, CONSTANT_MAGNETIC

=end pod

our constant PERMEABL_FREE_SPACE is export(:fundamental :electromagnetic :nuclear) = 1.25663706212e-6;

=head3 PI

    3.14159265358979324

trig constant pi

=end pod

our constant PI is export(:mathematical) = 3.14159265358979324;

=head3 FOUR_PI

    12.5663706143592

trig constant pi times 4 (shorthand for some calculations)

This constant is also available using the alternate name C<FOURPI> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant FOUR_PI is export(:mathematical) = 12.5663706143592;

=head3 STERADIAN

    3282.80635001174

a measure of solid angle in square degrees and a SI derived unit

=end pod

our constant STERADIAN is export(:conversion) = 3282.80635001174;

=head3 EXP

    2.71828182846

base of natural logarithm

=end pod

our constant EXP is export(:mathematical) = 2.71828182846;

=head3 ATOMIC_MASS_UNIT

    1.66053906660e-27	MKS
    1.66053906660e-24	CGS

unified atomic mass unit, 1 u

=end pod

our constant ATOMIC_MASS_UNIT is export(:conversion :nuclear) = 1.66053906660e-27;

=head3 PARSEC

    3.08567758149e16	MKS
    3.08567758149e18	CGS

parsec

=end pod

our constant PARSEC is export(:conversion :cosmology :planetary) = 3.08567758149e16;

=head3 ASTRONOMICAL_UNIT

    149_597_870_700	MKS
    1.496e13	CGS

astronomical unit

=end pod

our constant ASTRONOMICAL_UNIT is export(:conversion :cosmology :planetary) = 149_597_870_700;

=head3 LIGHT_YEAR

    9_460_730_472_580_800	MKS
    9.4607304725808e17	CGS

the distance that light travels in vacuum in one Julian year

=end pod

our constant LIGHT_YEAR is export(:conversion :cosmology :planetary) = 9_460_730_472_580_800;

=head3 ANGSTROM

    1e-10	MKS
    1e-8	CGS

Angstrom

=end pod

our constant ANGSTROM is export(:conversion :electromagnetic :nuclear) = 1e-10;

=head3 JANSKY

    1e-26	MKS
    1e-23	CGS

Jansky, a unit of flux density

=end pod

our constant JANSKY is export(:conversion :cosmology :electromagnetic) = 1e-26;

=head3 AVOGADRO

    6.02214076e23

Avogadro's number

=end pod

our constant AVOGADRO is export(:conversion :nuclear) = 6.02214076e23;

=head3 YEAR

    31_557_600

defined as exactly 365.25 days of 86400 SI seconds

This constant is also available using the alternate name C<YEAR_JULIAN> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant YEAR is export(:conversion :cosmology) = 31_557_600;

=head3 YEAR_TROPICAL

    31_556_925.1

the period of time for the ecliptic longitude of the Sun to increase 360 degrees, approximated by the Gregorian calendar

=end pod

our constant YEAR_TROPICAL is export(:conversion :cosmology) = 31_556_925.1;

=head3 YEAR_SIDEREAL

    31_558_149.8

the period of revolution of the Earth around the Sun in a fixed reference frame

=end pod

our constant YEAR_SIDEREAL is export(:conversion :cosmology) = 31_558_149.8;

=head3 YEAR_ANOMALISTIC

    31_558_432.6

the period between successive passages of the Earth through perihelion

=end pod

our constant YEAR_ANOMALISTIC is export(:conversion :planetary) = 31_558_432.6;

=head3 YEAR_ECLIPSE

    29_947_974.3

the period between successive passages of the Sun (as seen from the geocenter) through the same lunar node

=end pod

our constant YEAR_ECLIPSE is export(:conversion :planetary) = 29_947_974.3;

=head3 MASS_SOLAR

    1.9884e30	MKS
    1.9884e33	CGS

solar mass

This constant is also available using the alternate name C<SOLAR_MASS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MASS_SOLAR is export(:cosmology :planetary) = 1.9884e30;

=head3 LUMINOSITY_SOLAR

    3.828e26	MKS
    3.828e33	CGS

solar luminosity

This constant is also available using the alternate name C<SOLAR_LUMINOSITY> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant LUMINOSITY_SOLAR is export(:cosmology :planetary) = 3.828e26;

=head3 DENSITY_CRITICAL_RHOc

    1.87834e-26	MKS
    1.87834e-29	CGS

Critical Density parameter expressed in terms of
	<math>{ρ<sub>c</sub><over>h<sup>2</sup>} = {3 × (100 km s<sup>−1</sup> Mpc<sup>−1</sup>)<sup>2</sup> <over>8 π G}</math>
	Multiply by the square of the dimensionless Hubble parameter, h, in your calculations to get the actual value

This constant is also available using the alternate name C<RHO_C> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant DENSITY_CRITICAL_RHOc is export(:cosmology) = 1.87834e-26;

=head3 HUBBLE_TIME

    3.0853056e17

Hubble time *h, the inverse of Hubble's constant valued at 100 km/s/Mpc (DEPRECATED - see ChangeLog)

=end pod

our constant HUBBLE_TIME is export(:cosmology) = 3.0853056e17;

=head3 TEMPERATURE_CMB

    2.72548

cosmic microwave background temperature in Kelvin

This constant is also available using the alternate name C<CMB_TEMPERATURE> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant TEMPERATURE_CMB is export(:cosmology) = 2.72548;

=head3 MAGNITUDE_SOLAR_V

    -26.74

visual brightness of the Sun

This constant is also available using the alternate name C<SOLAR_V_MAG> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MAGNITUDE_SOLAR_V is export(:cosmology :planetary) = -26.74;

=head3 MAGNITUDE_SOLAR_V_ABSOLUTE

    4.83

solar absolute V magnitude

This constant is also available using the alternate name C<SOLAR_V_ABS_MAG> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MAGNITUDE_SOLAR_V_ABSOLUTE is export(:cosmology :planetary) = 4.83;

=head3 RADIUS_SOLAR

    6.96e8	MKS
    6.96e10	CGS

solar radius

This constant is also available using the alternate name C<SOLAR_RADIUS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant RADIUS_SOLAR is export(:planetary) = 6.96e8;

=head3 MASS_EARTH

    5.9722e24	MKS
    5.9722e27	CGS

mass of Earth

This constant is also available using the alternate name C<EARTH_MASS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MASS_EARTH is export(:planetary) = 5.9722e24;

=head3 RADIUS_EARTH

    6.378_136_6e6	MKS
    6.378_136_6e8	CGS

radius of Earth

This constant is also available using the alternate name C<EARTH_RADIUS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant RADIUS_EARTH is export(:planetary) = 6.378_136_6e6;

=head3 TEMPERATURE_SOLAR_SURFACE

    5772

surface temperature of sun (photosphere)

This constant is also available using the alternate name C<SOLAR_TEMPERATURE> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant TEMPERATURE_SOLAR_SURFACE is export(:planetary) = 5772;

=head3 DENSITY_SOLAR

    1408	MKS
    1.408	CGS

mean solar density

This constant is also available using the alternate name C<SOLAR_DENSITY> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant DENSITY_SOLAR is export(:planetary) = 1408;

=head3 DENSITY_EARTH

    5515	MKS
    5.515	CGS

mean Earth density

This constant is also available using the alternate name C<EARTH_DENSITY> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant DENSITY_EARTH is export(:planetary) = 5515;

=head3 GRAVITY_SOLAR

    274.78	MKS
    27478	CGS

solar surface gravity

This constant is also available using the alternate name C<SOLAR_GRAVITY> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant GRAVITY_SOLAR is export(:planetary) = 274.78;

=head3 GRAVITY_EARTH

    9.80665	MKS
    980.665	CGS

Earth surface gravity

This constant is also available using the alternate name C<EARTH_GRAVITY> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant GRAVITY_EARTH is export(:planetary) = 9.80665;

=head3 RADIUS_LUNAR

    1.7381e6	MKS
    1.7381e8	CGS

lunar radius

This constant is also available using the alternate name C<LUNAR_RADIUS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant RADIUS_LUNAR is export(:planetary) = 1.7381e6;

=head3 MASS_LUNAR

    7.346e22	MKS
    7.346e25	CGS

lunar mass

This constant is also available using the alternate name C<LUNAR_MASS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MASS_LUNAR is export(:planetary) = 7.346e22;

=head3 AXIS_SM_LUNAR

    3.84402e8	MKS
    3.84402e10	CGS

lunar orbital semi-major axis

This constant is also available using the alternate name C<LUNAR_SM_AXIS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant AXIS_SM_LUNAR is export(:planetary) = 3.84402e8;

=head3 ECCENTRICITY_LUNAR

    0.0549

lunar orbital eccentricity

This constant is also available using the alternate name C<LUNAR_ECCENTRICITY> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant ECCENTRICITY_LUNAR is export(:planetary) = 0.0549;

=head3 THOMSON_CROSS_SECTION

    6.6524587321e-29	MKS
    6.6524587321e-25	CGS

Thomson cross-section

This constant is also available using the alternate name C<THOMSON_XSECTION> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant THOMSON_CROSS_SECTION is export(:electromagnetic :nuclear) = 6.6524587321e-29;

=head3 MASS_ELECTRON

    9.1093837015e-31	MKS
    9.1093837015e-28	CGS

mass of electron

This constant is also available using the alternate name C<ELECTRON_MASS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MASS_ELECTRON is export(:electromagnetic :nuclear) = 9.1093837015e-31;

=head3 MASS_PROTON

    1.67262192369e-27	MKS
    1.67262192369e-24	CGS

mass of proton

This constant is also available using the alternate name C<PROTON_MASS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MASS_PROTON is export(:nuclear) = 1.67262192369e-27;

=head3 MASS_NEUTRON

    1.67492749804e-27	MKS
    1.67492749804e-24	CGS

neutron mass

This constant is also available using the alternate name C<NEUTRON_MASS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MASS_NEUTRON is export(:nuclear) = 1.67492749804e-27;

=head3 MASS_HYDROGEN

    1.6738e-27

mass of Hydrogen atom --   
This value is from the IUPAC and is a little smaller than MASS_PROTON + MASS_ELECTRON, but within the uncertainty given here.  The current value is 1.008u +/- 0.0002 derived from a range of terrestrial materials.  If this is for precision work, you had best understand what you're using.  See https://iupac.org/what-we-do/periodic-table-of-elements/

This constant is also available using the alternate name C<HYDROGEN_MASS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant MASS_HYDROGEN is export(:nuclear) = 1.6738e-27;

=head3 MASS_ALPHA

    6.6446573357e-27

mass of alpha particle

=end pod

our constant MASS_ALPHA is export(:nuclear) = 6.6446573357e-27;

=head3 RADIUS_ELECTRON

    2.8179403262e-15	MKS
    2.8179403262e-13	CGS

classical electron radius

This constant is also available using the alternate name C<ELECTRON_RADIUS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant RADIUS_ELECTRON is export(:nuclear :electromagnetic) = 2.8179403262e-15;

=head3 RADIUS_BOHR

    5.29177210903e-11	MKS
    5.29177210903e-9	CGS

Bohr radius

This constant is also available using the alternate name C<BOHR_RADIUS> (imported using the :alternate tag for backwards compatibility)

=end pod

our constant RADIUS_BOHR is export(:electromagnetic :nuclear) = 5.29177210903e-11;

=head3 RADIUS_JUPITER

    69_911_000	MKS

Volumetric mean radius of Jupiter

=end pod

our constant RADIUS_JUPITER is export(:planetary) = 69_911_000;

=head3 MASS_JUPITER

    1.89819e27	MKS

mass of Jupiter

=end pod

our constant MASS_JUPITER is export(:planetary) = 1.89819e27;
=begin pod

=head3 pretty

This is a helper function that rounds a value or list of values to 5 significant figures.

=head3 precision

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

=item L<Astro::Cosmology>
=item L<Perl Data Language|PDL>
=item L<NIST|http://physics.nist.gov>
=item L<Astronomical Almanac|http://asa.usno.navy.mil>
=item L<IAU 2015 Resolution B3|http://iopscience.iop.org/article/10.3847/0004-6256/152/2/41/meta>
=item L<Neil Bower's review on providing read-only values|http://neilb.org/reviews/constants.html>
=item L<Test::Number::Delta>
=item L<Test::Deep::NumberTolerant> for testing values within objects

Reference Documents:

=item L<IAU 2009 system of astronomical constants|http://aa.usno.navy.mil/publications/reports/Luzumetal2011.pdf>
=item L<Astronomical Constants 2016.pdf|http://asa.usno.navy.mil/static/files/2016/Astronomical_Constants_2016.pdf>
=item L<IAU recommendations concerning units|https://www.iau.org/publications/proceedings_rules/units>
=item L<Re-definition of the Astronomical Unit|http://syrte.obspm.fr/IAU_resolutions/Res_IAU2012_B2.pdf>

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

=end pod


