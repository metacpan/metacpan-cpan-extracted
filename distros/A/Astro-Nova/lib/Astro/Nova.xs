#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
/* cargo-cult fix for clashes */
#undef do_open
#undef do_close


#include <libnova/aberration.h>
#include <libnova/airmass.h>
#include <libnova/angular_separation.h>
#include <libnova/apparent_position.h>
#include <libnova/asteroid.h>
#include <libnova/comet.h>
#include <libnova/dynamical_time.h>
#include <libnova/earth.h>
#include <libnova/elliptic_motion.h>
#include <libnova/heliocentric_time.h>
#include <libnova/hyperbolic_motion.h>
#include <libnova/julian_day.h>
#include <libnova/jupiter.h>
#include <libnova/libnova.h>
#include <libnova/ln_types.h>
#include <libnova/lunar.h>
#include <libnova/mars.h>
#include <libnova/mercury.h>
#include <libnova/neptune.h>
#include <libnova/nutation.h>
#include <libnova/parabolic_motion.h>
#include <libnova/parallax.h>
#include <libnova/pluto.h>
#include <libnova/precession.h>
#include <libnova/proper_motion.h>
#include <libnova/refraction.h>
#include <libnova/rise_set.h>
#include <libnova/saturn.h>
#include <libnova/sidereal_time.h>
#include <libnova/solar.h>
#include <libnova/transform.h>
#include <libnova/uranus.h>
#include <libnova/utility.h>
#include <libnova/venus.h>
#include <libnova/vsop87.h>

#include <time.h>

MODULE = Astro::Nova		PACKAGE = Astro::Nova	PREFIX=ln_

TYPEMAP: <<HERE
struct ln_date*	O_OBJECT
struct ln_dms* O_OBJECT
struct ln_ell_orbit* O_OBJECT
struct ln_equ_posn* O_OBJECT
struct ln_gal_posn* O_OBJECT
struct ln_helio_posn* O_OBJECT
struct ln_hms* O_OBJECT
struct ln_hrz_posn* O_OBJECT
struct ln_hyp_orbit* O_OBJECT
struct ln_lnlat_posn* O_OBJECT
struct ln_nutation* O_OBJECT
struct ln_par_orbit* O_OBJECT
struct ln_rect_posn* O_OBJECT
struct ln_rst_time* O_OBJECT
struct ln_zonedate* O_OBJECT
struct lnh_equ_posn* O_OBJECT
struct lnh_hrz_posn* O_OBJECT
struct lnh_lnlat_posn* O_OBJECT

time_t	T_IV

OUTPUT

# The Perl object is blessed into 'CLASS', which should be a
# char* having the name of the package for the blessing.
O_OBJECT
	sv_setref_pv( $arg, CLASS, (void*)$var );

INPUT

O_OBJECT
	if( sv_isobject($arg) && (SvTYPE(SvRV($arg)) == SVt_PVMG) )
		$var = ($type)SvIV((SV*)SvRV( $arg ));
	else{
		warn( \"${Package}::$func_name() -- $var is not a blessed SV reference\" );
		XSRETURN_UNDEF;
	}
HERE


INCLUDE: ../../XS/Structs.xs

INCLUDE: ../../XS/Abberation.xs

#### airmass.h
double
ln_get_airmass(alt, airmass_scale)
  double alt
  double airmass_scale

double ln_get_alt_from_airmass(double X, double airmass_scale)


INCLUDE: ../../XS/AngularSeparation.xs

INCLUDE: ../../XS/ApparentPosition.xs

INCLUDE: ../../XS/Asteroid.xs

INCLUDE: ../../XS/Comet.xs

INCLUDE: ../../XS/DynamicalTime.xs

INCLUDE: ../../XS/Earth.xs

INCLUDE: ../../XS/EllipticMotion.xs

#### heliocentric_time.h
double
ln_get_heliocentric_time_diff(double JD, struct ln_equ_posn* object)

INCLUDE: ../../XS/HyperbolicMotion.xs

INCLUDE: ../../XS/JulianDay.xs

INCLUDE: ../../XS/Jupiter.xs

INCLUDE: ../../XS/Lunar.xs

#### Note: Mars, Mercury, Neptune, Pluto are really the same (apart from s/mars/mercury/g). Jupiter is only slightly different

INCLUDE: ../../XS/Mars.xs

INCLUDE: ../../XS/Mercury.xs

INCLUDE: ../../XS/Neptune.xs

#### nutation.h
struct ln_nutation*
ln_get_nutation(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::Nutation";
    CODE:
      Newx(RETVAL, 1, struct ln_nutation);
      ln_get_nutation(JD, RETVAL);
    OUTPUT:
      RETVAL

INCLUDE: ../../XS/ParabolicMotion.xs

INCLUDE: ../../XS/Parallax.xs

INCLUDE: ../../XS/Pluto.xs

INCLUDE: ../../XS/Precession.xs

INCLUDE: ../../XS/ProperMotion.xs

#### refraction.h
double
ln_get_refraction_adj(double altitude, double atm_pres, double temp)

INCLUDE: ../../XS/RiseSet.xs

INCLUDE: ../../XS/Saturn.xs

INCLUDE: ../../XS/Sidereal.xs

INCLUDE: ../../XS/Solar.xs

INCLUDE: ../../XS/Transform.xs

INCLUDE: ../../XS/Uranus.xs

INCLUDE: ../../XS/Utility.xs

INCLUDE: ../../XS/Venus.xs


