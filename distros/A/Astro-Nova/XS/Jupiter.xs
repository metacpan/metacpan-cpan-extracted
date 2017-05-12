
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

double
ln_get_jupiter_equ_sdiam(double JD)

double
ln_get_jupiter_pol_sdiam(double JD)

void
ln_get_jupiter_rst(double JD, struct ln_lnlat_posn* observer)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_jupiter_rst(JD, observer, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

struct ln_helio_posn*
ln_get_jupiter_helio_coords(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::HelioPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_helio_posn);
      ln_get_jupiter_helio_coords(JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_jupiter_equ_coords(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_jupiter_equ_coords(JD, RETVAL);
    OUTPUT:
      RETVAL

double
ln_get_jupiter_earth_dist(double JD)
        
double
ln_get_jupiter_solar_dist(double JD)
        
double
ln_get_jupiter_magnitude(double JD)

double
ln_get_jupiter_disk(double JD)

double
ln_get_jupiter_phase(double JD)

struct ln_rect_posn*
ln_get_jupiter_rect_helio(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_jupiter_rect_helio(JD, RETVAL);
    OUTPUT:
      RETVAL

