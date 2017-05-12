
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

void
ln_get_solar_rst_horizon(double JD, struct ln_lnlat_posn* observer, double horizon)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_solar_rst_horizon(JD, observer, horizon, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_solar_rst(double JD, struct ln_lnlat_posn* observer)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_solar_rst(JD, observer, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);
        

struct ln_helio_posn*
ln_get_solar_geom_coords(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::HelioPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_helio_posn);
      ln_get_solar_geom_coords(JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_solar_equ_coords(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_solar_equ_coords(JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_lnlat_posn*
ln_get_solar_ecl_coords(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::LnLatPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_lnlat_posn);
      ln_get_solar_ecl_coords(JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_rect_posn*
ln_get_solar_geo_coords(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_solar_geo_coords(JD, RETVAL);
    OUTPUT:
      RETVAL

double
ln_get_solar_sdiam(double JD)

