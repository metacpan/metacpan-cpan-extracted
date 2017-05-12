
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

double
ln_get_lunar_sdiam (double JD)

void
ln_get_lunar_rst(double JD, struct ln_lnlat_posn* observer)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_lunar_rst(JD, observer, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

struct ln_rect_posn*
ln_get_lunar_geo_posn(double JD, double precision)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_lunar_geo_posn(JD, RETVAL, precision);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_lunar_equ_coords_prec(double JD, double precision)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_lunar_equ_coords_prec(JD, RETVAL, precision);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_lunar_equ_coords(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_lunar_equ_coords(JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_lnlat_posn*
ln_get_lunar_ecl_coords(double JD, double precision)
    INIT:
      const char* CLASS = "Astro::Nova::LnLatPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_lnlat_posn);
      ln_get_lunar_ecl_coords(JD, RETVAL, precision);
    OUTPUT:
      RETVAL

double
ln_get_lunar_phase(double JD)

double
ln_get_lunar_disk(double JD)
        
double
ln_get_lunar_earth_dist(double JD)
        
double
ln_get_lunar_bright_limb(double JD)

double
ln_get_lunar_long_asc_node(double JD)

double
ln_get_lunar_long_perigee(double JD)

