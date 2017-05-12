
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

struct ln_equ_posn*
ln_get_equ_prec(struct ln_equ_posn* mean_position, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_equ_prec(mean_position, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_equ_prec2(struct ln_equ_posn* mean_position, double fromJD, double toJD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_equ_prec2(mean_position, fromJD, toJD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_lnlat_posn*
ln_get_ecl_prec(struct ln_lnlat_posn* mean_position, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::LnLatPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_lnlat_posn);
      ln_get_ecl_prec(mean_position, JD, RETVAL);
    OUTPUT:
      RETVAL

