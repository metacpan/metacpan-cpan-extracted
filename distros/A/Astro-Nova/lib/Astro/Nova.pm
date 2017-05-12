package Astro::Nova;

use 5.008;
use strict;
use warnings;

# note: internal modules loaded after XS below.

our $VERSION = '0.07';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    get_equ_aber
    get_ecl_aber
    get_airmass
    get_alt_from_airmass
    get_angular_separation
    get_rel_posn_angle
    get_apparent_posn
    get_asteroid_mag
    get_asteroid_sdiam_km
    get_asteroid_sdiam_arc
    get_ell_comet_mag
    get_par_comet_mag
    get_dynamical_time_diff
    get_jde
    get_mean_sidereal_time
    get_apparent_sidereal_time
    get_earth_helio_coords
    get_earth_solar_dist
    get_earth_rect_helio
    get_earth_centre_dist
    solve_kepler
    get_ell_mean_anomaly
    get_ell_true_anomaly
    get_ell_radius_vector
    get_ell_smajor_diam
    get_ell_sminor_diam
    get_ell_mean_motion
    get_ell_geo_rect_posn
    get_ell_helio_rect_posn
    get_ell_orbit_len
    get_ell_orbit_vel
    get_ell_orbit_pvel
    get_ell_orbit_avel
    get_ell_body_phase_angle
    get_ell_body_elong
    get_ell_body_solar_dist
    get_ell_body_earth_dist
    get_ell_body_equ_coords
    get_ell_body_rst
    get_ell_body_rst_horizon
    get_ell_body_next_rst
    get_ell_body_next_rst_horizon
    get_ell_body_next_rst_horizon_future
    get_ell_last_perihelion
    get_heliocentric_time_diff
    solve_hyp_barker
    get_hyp_true_anomaly
    get_hyp_radius_vector
    get_hyp_geo_rect_posn
    get_hyp_helio_rect_posn
    get_hyp_body_equ_coords
    get_hyp_body_earth_dist
    get_hyp_body_solar_dist
    get_hyp_body_phase_angle
    get_hyp_body_elong
    get_hyp_body_rst
    get_hyp_body_rst_horizon
    get_hyp_body_next_rst
    get_hyp_body_next_rst_horizon
    get_hyp_body_next_rst_horizon_future
    get_julian_day
    get_date
    get_date_from_timet
    get_local_date
    get_day_of_week
    get_julian_from_sys
    get_date_from_sys
    get_julian_from_timet
    get_timet_from_julian
    get_julian_local_date
    date_to_zonedate
    zonedate_to_date
    get_jupiter_equ_sdiam
    get_jupiter_pol_sdiam
    get_jupiter_rst
    get_jupiter_helio_coords
    get_jupiter_equ_coords
    get_jupiter_earth_dist
    get_jupiter_solar_dist
    get_jupiter_magnitude
    get_jupiter_disk
    get_jupiter_phase
    get_jupiter_rect_helio
    get_saturn_equ_sdiam
    get_saturn_pol_sdiam
    get_saturn_rst
    get_saturn_helio_coords
    get_saturn_equ_coords
    get_saturn_earth_dist
    get_saturn_solar_dist
    get_saturn_magnitude
    get_saturn_disk
    get_saturn_phase
    get_saturn_rect_helio
    get_lunar_sdiam
    get_lunar_rst
    get_lunar_geo_posn
    get_lunar_equ_coords_prec
    get_lunar_equ_coords
    get_lunar_ecl_coords
    get_lunar_phase
    get_lunar_disk
    get_lunar_earth_dist
    get_lunar_bright_limb
    get_lunar_long_asc_node
    get_lunar_long_perigee

    get_mars_sdiam
    get_mars_rst
    get_mars_helio_coords
    get_mars_equ_coords
    get_mars_earth_dist
    get_mars_solar_dist
    get_mars_magnitude
    get_mars_disk
    get_mars_phase
    get_mars_rect_helio
  
    get_mercury_sdiam
    get_mercury_rst
    get_mercury_helio_coords
    get_mercury_equ_coords
    get_mercury_earth_dist
    get_mercury_solar_dist
    get_mercury_magnitude
    get_mercury_disk
    get_mercury_phase
    get_mercury_rect_helio
    get_neptune_sdiam
    get_neptune_rst
    get_neptune_helio_coords
    get_neptune_equ_coords
    get_neptune_earth_dist
    get_neptune_solar_dist
    get_neptune_magnitude
    get_neptune_disk
    get_neptune_phase
    get_neptune_rect_helio
  
    get_uranus_sdiam
    get_uranus_rst
    get_uranus_helio_coords
    get_uranus_equ_coords
    get_uranus_earth_dist
    get_uranus_solar_dist
    get_uranus_magnitude
    get_uranus_disk
    get_uranus_phase
    get_uranus_rect_helio
    get_venus_sdiam
    get_venus_rst
    get_venus_helio_coords
    get_venus_equ_coords
    get_venus_earth_dist
    get_venus_solar_dist
    get_venus_magnitude
    get_venus_disk
    get_venus_phase
    get_venus_rect_helio

    get_nutation
  
    solve_barker
    get_par_true_anomaly
    get_par_radius_vector
    get_par_geo_rect_posn
    get_par_helio_rect_posn
    get_par_body_equ_coords
    get_par_body_earth_dist
    get_par_body_solar_dist
    get_par_body_phase_angle
    get_par_body_elong
    get_par_body_rst
    get_par_body_rst_horizon
    get_par_body_next_rst
    get_par_body_next_rst_horizon
    get_par_body_next_rst_horizon_future
    get_parallax
    get_parallax_ha
    get_equ_prec
    get_equ_prec2
    get_ecl_prec
    get_equ_pm
    get_equ_pm
    get_refraction_adj
    get_object_rst
    get_object_rst_horizon
    get_object_next_rst
    get_object_next_rst_horizon
    get_solar_rst
    get_solar_rst_horizon
    get_solar_geom_coords
    get_solar_equ_coords
    get_solar_ecl_coords
    get_solar_geo_coords
    get_solar_sdiam
    get_hrz_from_equ
    get_hrz_from_equ_sidereal_time
    get_equ_from_ecl
    get_ecl_from_equ
    get_equ_from_hrz
    get_rect_from_helio
    get_ecl_from_rect
    get_equ_from_gal
    get_equ2000_from_gal
    get_gal_from_equ
    get_gal_from_equ2000
    get_version
    get_dec_location
    get_humanr_location
    get_rect_distance
    rad_to_deg
    deg_to_rad
    hms_to_deg
    deg_to_hms
    hms_to_rad
    rad_to_hms
    dms_to_deg
    deg_to_dms
    dms_to_rad
    rad_to_dms
    hequ_to_equ
    equ_to_hequ
    hhrz_to_hrz
    hrz_to_hhrz
    hlnlat_to_lnlat
    lnlat_to_hlnlat
    add_secs_hms
    add_hms
    get_light_time
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

require XSLoader;
XSLoader::load('Astro::Nova', $VERSION);

require Astro::Nova::ZoneDate;
require Astro::Nova::DMS;
require Astro::Nova::HMS;
require Astro::Nova::LnLatPosn;
require Astro::Nova::GalPosn;
require Astro::Nova::EquPosn;

1;
__END__

=head1 NAME

Astro::Nova - Perl interface to libnova

=head1 SYNOPSIS

  use Astro::Nova qw(functions ...);
  my $hms = Astro::Nova::HMS->new();
  $hms->set_hours(12);
  ...

=head1 DESCRIPTION

A libnova wrapper that includes a copy of libnova 0.15.0 itself for static linking.
See L</COPYRIGHT AND LICENSE> for licensing details.
The goal of this documentation is to document the Perl wrapper,
not to reproduce the entire libnova documentation. Please find the documentation
at L<http://libnova.sourceforge.net/>.

In general, the available functions have the same name as the libnova functions, but with
the C<ln_> prefix removed. That means C<ln_get_mean_sidereal_time(JD)> becomes in Perl either
C<Astro::Nova::get_mean_sidereal_time($jd)> or if exported C<get_mean_sidereal_time($jd)>.

The functions' interfaces will be mostly the same as in C,
except that the libnova structs are available as Perl classes. See L</STRUCTS>.
If there are other changes to the interface, the changes will be documented in the
list of exported functions below.

=head2 EXPORT

None by default.

Many functions can be exported on demand. They will be added to the list
as they become available. The function list will look remotely like a C-level
signature but refer to classes instead of C structs. Some of the interfaces
have been changed to I<return> a value instead of passing pointers as arguments.
The C<ln_> prefix has been stripped.

  abberation.h
    Astro::Nova::EquPosn get_equ_aber(Astro::Nova::EquPosn mean_position, double JD)
    Astro::Nova::LnLatPosn get_ecl_aber(Astro::Nova::LnLatPosn mean_position, double JD)
  
  airmass.h
    double get_airmass(double alt, double airmass_scale)
    double get_alt_from_airmass(double X, double airmass_scale)
  
  angular_separation.h
    double get_angular_separation(Astro::Nova::EquPosn posn1, Astro::Nova::EquPosn posn2)
    double get_rel_posn_angle(Astro::Nova::EquPosn posn1, Astro::Nova::EquPosn posn2)
  
  apparent_position.h
    Astro::Nova::EquPosn get_apparent_posn(Astro::Nova::EquPosn mean_position,
                                           Astro::Nova::EquPosn proper_motion,
                                           double JD)
  
  asteroid.h
    double get_asteroid_mag(double JD, Astro::Nova::EllOrbit orbit, double H, double G)
    double get_asteroid_sdiam_km(double H, double A)
    double get_asteroid_sdiam_arc(double JD, Astro::Nova::EllOrbit orbit, double H, double A)
  
  comet.h
    double get_ell_comet_mag(double JD, Astro::Nova::EllOrbit orbit, double g, double k)
    double get_par_comet_mag(double JD, Astro::Nova::ParOrbit orbit, double g, double k)
  
  dynamical_time.h
    double get_dynamical_time_diff(double JD)
    double get_jde(double JD)
  
  sidereal_time.h
    double get_mean_sidereal_time(double JD)
    double get_apparent_sidereal_time(double JD)
  
  earth.h
    Astro::Nova::HelioPosn get_earth_helio_coords(double JD)
    double get_earth_solar_dist(double JD)
    Astro::Nova::RectPosn get_earth_rect_helio(double JD)
    (double $p_sin_o, double $p_cos_o) = get_earth_centre_dist(float height, double latitude)
  
  elliptic_motion.h
    double solve_kepler(double e, double M)
    double get_ell_mean_anomaly(double n, double delta_JD)
    double get_ell_true_anomaly(double e, double E)
    double get_ell_radius_vector(double a, double e, double E)
    double get_ell_smajor_diam(double e, double q)
    double get_ell_sminor_diam(double e, double a)
    double get_ell_mean_motion(double a)
    Astro::Nova::RectPosn get_ell_geo_rect_posn(Astro::Nova::EllOrbit orbit, double JD)
    Astro::Nova::RectPosn get_ell_helio_rect_posn(Astro::Nova::EllOrbit orbit, double JD)
    double get_ell_orbit_len(Astro::Nova::EllOrbit orbit)
    double get_ell_orbit_vel(double JD, Astro::Nova::EllOrbit orbit)
    double get_ell_orbit_pvel(Astro::Nova::EllOrbit orbit)
    double get_ell_orbit_avel(Astro::Nova::EllOrbit orbit)
    double get_ell_body_phase_angle(double JD, Astro::Nova::EllOrbit orbit)
    double get_ell_body_elong(double JD, Astro::Nova::EllOrbit orbit)
    double get_ell_body_solar_dist(double JD, Astro::Nova::EllOrbit orbit)
    double get_ell_body_earth_dist(double JD, Astro::Nova::EllOrbit orbit)
    Astro::Nova::EquPosn get_ell_body_equ_coords(double JD, Astro::Nova::EllOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::EllOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                               Astro::Nova::EllOrbit orbit, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_next_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::EllOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_next_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                                    Astro::Nova::EllOrbit orbit, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_next_rst_horizon_future(double JD, Astro::Nova::LnLatPosn observer,
                                           Astro::Nova::EllOrbit orbit, double horizon,
                                           int day_limit)
    double get_ell_last_perihelion(double epoch_JD, double M, double n)
  
  heliocentric_time.h
    double get_heliocentric_time_diff(double JD, Astro::Nova::EquPosn object)
  
  hyperbolic_motion.h
    double solve_hyp_barker(double Q1, double G, double t)
    double get_hyp_true_anomaly(double q, double e, double t)
    double get_hyp_radius_vector(double q, double e, double t)
    Astro::Nova::RectPosn get_hyp_geo_rect_posn(Astro::Nova::HypOrbit orbit, double JD)
    Astro::Nova::RectPosn get_hyp_helio_rect_posn(Astro::Nova::HypOrbit orbit, double JD)
    Astro::Nova::EquPosn get_hyp_body_equ_coords(double JD, Astro::Nova::HypOrbit orbit)
    double get_hyp_body_earth_dist(double JD, Astro::Nova::HypOrbit orbit)
    double get_hyp_body_solar_dist(double JD, Astro::Nova::HypOrbit orbit)
    double get_hyp_body_phase_angle(double JD, Astro::Nova::HypOrbit orbit)
    double get_hyp_body_elong(double JD, Astro::Nova::HypOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::HypOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                               Astro::Nova::HypOrbit orbit, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_next_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::HypOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_next_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                                    Astro::Nova::HypOrbit orbit, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_next_rst_horizon_future(double JD, Astro::Nova::LnLatPosn observer,
                                           Astro::Nova::HypOrbit orbit, double horizon,
                                           int day_limit)
  
  julian_day.h
    double get_julian_day(Astro::Nova::Date date)
    Astro::Nova::Date get_date(double JD)
    Astro::Nova::Date get_date_from_timet(time_t t) (time_t is an integer)
    Astro::Nova::ZoneDate get_local_date(double JD)
    unsigned int get_day_of_week(Astro::Nova::Date date)
    double get_julian_from_sys()
    Astro::Nova::Date get_date_from_sys()
    double get_julian_from_timet(time_t t) (time_t is an integer)
    time_t get_timet_from_julian(double JD) (time_t is an integer)
    double get_julian_local_date(Astro::Nova::ZoneDate zonedate)
    Astro::Nova::ZoneDate date_to_zonedate(Astro::Nova::Date date, long gmtoff)
    Astro::Nova::Date zonedate_to_date(Astro::Nova::ZoneDate zonedate)
  
  jupiter.h
    double get_jupiter_equ_sdiam(double JD)
    double get_jupiter_pol_sdiam(double JD)
    Astro::Nova::RstTime get_jupiter_rst(double JD)
    Astro::Nova::HelioPosn get_jupiter_helio_coords(double JD)
    Astro::Nova::EquPosn get_jupiter_equ_coords(double JD)
    double get_jupiter_earth_dist(double JD)
    double get_jupiter_solar_dist(double JD)
    double get_jupiter_magnitude(double JD)
    double get_jupiter_disk(double JD)
    double get_jupiter_phase(double JD)
    Astro::Nova::RectPosn get_jupiter_rect_helio(double JD)
  
  lunar.h
    double get_lunar_sdiam(double JD)
    Astro::Nova::RstTime get_lunar_rst(double JD, Astro::Nova::LnLatPosn observer)
    Astro::Nova::RectPosn get_lunar_geo_posn(double JD, double precision)
    Astro::Nova::EquPosn get_lunar_equ_coords_prec(double JD, double precision)
    Astro::Nova::EquPosn get_lunar_equ_coords(double JD)
    Astro::Nova::LnLatPosn get_lunar_ecl_coords(double JD, double precision)
    double get_lunar_phase(double JD)
    double get_lunar_disk(double JD)
    double get_lunar_earth_dist(double JD)
    double get_lunar_bright_limb(double JD)
    double get_lunar_long_asc_node(double JD)
    double get_lunar_long_perigee(double JD)
  
  mars.h
    double get_mars_sdiam(double JD)
    Astro::Nova::RstTime get_mars_rst(double JD)
    Astro::Nova::HelioPosn get_mars_helio_coords(double JD)
    Astro::Nova::EquPosn get_mars_equ_coords(double JD)
    double get_mars_earth_dist(double JD)
    double get_mars_solar_dist(double JD)
    double get_mars_magnitude(double JD)
    double get_mars_disk(double JD)
    double get_mars_phase(double JD)
    Astro::Nova::RectPosn get_mars_rect_helio(double JD)
  
  mercury.h
  neptune.h
  uranus.h
  venus.h
    Same as mars, except the planet name is replaced in the method names.
  
  nutation.h
    Astro::Nova::Nutation get_nutation(double JD)
  
  parabolic_motion.h
    double solve_barker(double q, double t)
    double get_par_true_anomaly(double q, double t)
    double get_par_radius_vector(double q, double t)
    Astro::Nova::RectPosn get_par_geo_rect_posn(Astro::Nova::ParOrbit orbit, double JD)
    Astro::Nova::RectPosn get_par_helio_rect_posn(Astro::Nova::ParOrbit orbit, double JD)
    Astro::Nova::EquPosn get_par_body_equ_coords(double JD, Astro::Nova::ParOrbit orbit)
    double get_par_body_earth_dist(double JD, Astro::Nova::ParOrbit orbit)
    double get_par_body_solar_dist(double JD, Astro::Nova::ParOrbit orbit)
    double get_par_body_phase_angle(double JD, Astro::Nova::ParOrbit orbit)
    double get_par_body_elong(double JD, Astro::Nova::ParOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_par_body_rst(double JD, Astro::Nova::LnLatPosn observer)
    (int $status, Astro::Nova::RstTime $rst) =
      get_par_body_rst_horizon(double JD, Astro::Nova::LnLatPosn observer, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_par_body_next_rst(double JD, Astro::Nova::LnLatPosn observer)
    (int $status, Astro::Nova::RstTime $rst) =
      get_par_body_next_rst_horizon(double JD, Astro::Nova::LnLatPosn observer, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_par_body_next_rst_horizon_future(double JD, Astro::Nova::LnLatPosn observer,
                                           double horizon, int day_limit)
  
  parallax.h
    Astro::Nova::EquPosn get_parallax(Astro::Nova::EquPosn object, double au_distance,
                                      Astro::Nova::LnLatPosn observer, double height, double JD)
    Astro::Nova::EquPosn get_parallax_ha(Astro::Nova::EquPosn object, double au_distance,
                                         Astro::Nova::LnLatPosn observer, double height, double H)
  
  precession.h
    Astro::Nova::EquPosn get_equ_prec(Astro::Nova::EquPosn mean_position, double JD)
    Astro::Nova::EquPosn get_equ_prec2(Astro::Nova::EquPosn mean_position, double fromJD, double toJD)
    Astro::Nova::LnLatPosn get_ecl_prec(Astro::Nova::LnLatPosn mean_position, double JD)
  
  proper_motion.h
    Astro::Nova::EquPosn get_equ_pm(Astro::Nova::EquPosn mean_position,
                                    Astro::Nova::EquPosn proper_motion, double JD)
    Astro::Nova::EquPosn get_equ_pm(Astro::Nova::EquPosn mean_position,
                                    Astro::Nova::EquPosn proper_motion, double JD, double epoch_JD)
  
  refraction.h
    double get_refraction_adj(double altitude, double atm_pres, double temp)
  
  rise_set.h
    (int $status, Astro::Nova::RstTime $rst) =
      get_object_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::EquPosn object)
    (int $status, Astro::Nova::RstTime $rst) =
      get_object_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                             Astro::Nova::EquPosn object, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_object_next_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::EquPosn object)
    (int $status, Astro::Nova::RstTime $rst) =
      get_object_next_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                                  Astro::Nova::EquPosn object, double horizon)
  
  saturn.h
    Same as jupiter, except the planet name is replaced in the method names.
  
  solar.h
    (int $status, Astro::Nova::RstTime $rst) =
      get_solar_rst(double JD, Astro::Nova::LnLatPosn observer)
    (int $status, Astro::Nova::RstTime $rst) =
      get_solar_rst_horizon(double JD, Astro::Nova::LnLatPosn observer, double horizon)
    Astro::Nova::HelioPosn get_solar_geom_coords(double JD)
    Astro::Nova::EquPosn get_solar_equ_coords(double JD)
    Astro::Nova::LnLatPosn get_solar_ecl_coords(double JD)
    Astro::Nova::RectPosn get_solar_geo_coords(double JD)
    double get_solar_sdiam(double JD)
  
  transform.h
    Astro::Nova::HrzPosn get_hrz_from_equ(Astro::Nova::EquPosn object, Astro::Nova::LnLatPosn observer, double JD)
    Astro::Nova::HrzPosn get_hrz_from_equ_sidereal_time(Astro::Nova::EquPosn object, Astro::Nova::LnLatPosn observer, double sidereal)
    Astro::Nova::EquPosn get_equ_from_ecl(Astro::Nova::LnLatPosn object, double JD)
    Astro::Nova::LnLatPosn get_ecl_from_equ(Astro::Nova::EquPosn object, double JD)
    Astro::Nova::EquPosn get_equ_from_hrz(Astro::Nova::HrzPosn object, Astro::Nova::LnLatPosn observer, double JD)
    Astro::Nova::RectPosn get_rect_from_helio(Astro::Nova::HelioPosn helio)
    Astro::Nova::LnLatPosn get_ecl_from_rect(Astro::Nova::RectPosn rect)
    Astro::Nova::EquPosn get_equ_from_gal(Astro::Nova::GalPosn gal)
    Astro::Nova::EquPosn get_equ2000_from_gal(Astro::Nova::GalPosn gal)
    Astro::Nova::GalPosn get_gal_from_equ(Astro::Nova::EquPosn equ)
    Astro::Nova::GalPosn get_gal_from_equ2000(Astro::Nova::EquPosn equ)
  
  utility.h
    const char* get_version()
    double get_dec_location(char* s)
    const char* get_humanr_location(double location)
    double get_rect_distance(Astro::Nova::RectPosn a, Astro::Nova::RectPosn b)
    double rad_to_deg(double radians)
    double deg_to_rad(double degrees)
    double hms_to_deg(Astro::Nova::HMS hms)
    Astro::Nova::HMS deg_to_hms(double degrees)
    double hms_to_rad(Astro::Nova::HMS hms)
    Astro::Nova::HMS rad_to_hms(double radians)
    double dms_to_deg(Astro::Nova::DMS dms)
    Astro::Nova::DMS deg_to_dms(double degrees)
    double dms_to_rad(Astro::Nova::DMS dms)
    Astro::Nova::DMS rad_to_dms(double radians)
    Astro::Nova::EquPosn hequ_to_equ(Astro::Nova::HEquPosn hpos)
    Astro::Nova::HEquPosn equ_to_hequ(Astro::Nova::EquPosn pos)
    Astro::Nova::HrzPosn hhrz_to_hrz(Astro::Nova::HHrzPosn hpos)
    Astro::Nova::HHrzPosn hrz_to_hhrz(Astro::Nova::HrzPosn pos)
    Astro::Nova::LnLatPosn hlnlat_to_lnlat(Astro::Nova::HLnLatPosn hpos)
    Astro::Nova::HLnLatPosn lnlat_to_hlnlat(Astro::Nova::hLnLatPosn pos)
    void add_secs_hms(Astro::Nova::HMS hms, double seconds)
    void add_hms(Astro::Nova::HMS source, Astro::Nova::HMS dest)
    double get_light_time(double dist)

=head2 STRUCTS / CLASSES

libnova defines several structs for passing data to or receiving results from the
functions. These have been wrapped as Perl classes. Below is a list of the struct names,
their Perl class names, and their data members (including the C types). The class
constructors optionally take key/value pairs as argument that correspond to the
struct members. Any extra parameters that aren't struct members are currently simply
ignored. Any struct members that aren't explicitly set will be set to zero.

If a member is called C<L>, then there will be
two methods C<get_L> and C<set_L> for getting/setting the data. All numeric data
is intialized to zero.

=over 2

=item C<ln_date>

Implemented as C<Astro::Nova::Date>.

    int years
    int months
    int days
    int hours
    int minutes
    double seconds

=item C<ln_dms>

Implemented as L<Astro::Nova::DMS>.

    unsigned short  neg
    unsigned short  degrees
    unsigned short  minutes
    double  seconds

=item C<ln_ell_orbit>

Implemented as C<Astro::Nova::EllOrbit>.

    double  a
    double  e
    double  i
    double  w
    double  omega
    double  n
    double  JD

=item C<ln_equ_posn>

Implemented as L<Astro::Nova::EquPosn>.

    double  ra
    double  dec

=item C<ln_gal_posn>

Implemented as L<Astro::Nova::GalPosn>.

    double  l
    double  b

=item C<ln_helio_posn>

Implemented as C<Astro::Nova::HelioPosn>.

    double  L
    double  B
    double  R

=item C<ln_hms>

Implemented as L<Astro::Nova::HMS>.

    unsigned short  hours
    unsigned short  minutes
    double  seconds

=item C<ln_hrz_posn>

Implemented as C<Astro::Nova::HrzPosn>.

    double  az
    double  alt

=item C<ln_hyp_orbit>

Implemented as C<Astro::Nova::HypOrbit>.

    double  q
    double  e
    double  i
    double  w
    double  omega
    double  JD

=item C<ln_lnlat_posn>

Implemented as L<Astro::Nova::LnLatPosn>.

    double  lng
    double  lat

=item C<ln_nutation>

Implemented as C<Astro::Nova::Nutation>.

    double  longitude
    double  obliquity
    double  ecliptic

=item C<ln_par_orbit>

Implemented as C<Astro::Nova::ParOrbit>.

    double  q
    double  i
    double  w
    double  omega
    double  JD

=item C<ln_rect_posn>

Implemented as C<Astro::Nova::RectPosn>.

    double  X
    double  Y
    double  Z

=item C<ln_rst_time>

Implemented as C<Astro::Nova::RstTime>.

    double  rise
    double  set
    double  transit

=item C<ln_zonedate>

Implemented as L<Astro::Nova::ZoneDate>.

    int  years
    int  months
    int  days
    int  hours
    int  minutes
    double  seconds
    long  gmtoff

=back

These are "human readable" composite structs that contain
others. Accessing their memebers with a getter method will
return a B<new copy> of the contained structure.

=over 2

=item C<lnh_equ_posn>

Implemented as C<Astro::Nova::HEquPosn>.

    struct ln_hms ra
    struct ln_dms dec

=item C<lnh_hrz_posn>

Implemented as C<Astro::Nova::HHrzPosn>.

    struct ln_dms az
    struct ln_dms alt

=item C<lnh_lnlat_posn>

Implemented as C<Astro::Nova::HLnLatPosn>.

    struct ln_dms lng
    struct ln_dms lat

=back

=head1 SEE ALSO

libnova website: L<http://libnova.sourceforge.net/>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The Astro::Nova wrapper of libnova is copyright (C) 2009-2013 by Steffen Mueller.

The wrapper code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

libnova is maintained by Liam Girdwood and Petr Kubanek.

libnova is released under the GNU LGPL. This may limit the licensing
terms of the wrapper code. If in doubt, ask a lawyer.

=cut
