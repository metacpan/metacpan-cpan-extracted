
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

struct ln_helio_posn*
ln_get_earth_helio_coords(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::HelioPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_helio_posn);
      ln_get_earth_helio_coords(JD, RETVAL);
    OUTPUT:
      RETVAL

double
ln_get_earth_solar_dist(JD)
  double JD

struct ln_rect_posn*
ln_get_earth_rect_helio(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_earth_rect_helio(JD, RETVAL);
    OUTPUT:
      RETVAL

void
ln_get_earth_centre_dist(float height, double latitude, OUTLIST double p_sin_o, OUTLIST double p_cos_o)

