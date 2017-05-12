
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

struct ln_equ_posn*
ln_get_equ_aber(mean_position, JD)
      struct ln_equ_posn* mean_position
      double JD
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_equ_aber(mean_position, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_lnlat_posn*
ln_get_ecl_aber(struct ln_lnlat_posn* mean_position, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::LnLatPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_lnlat_posn);
      ln_get_ecl_aber(mean_position, JD, RETVAL);
    OUTPUT:
      RETVAL

