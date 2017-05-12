
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

struct ln_equ_posn*
ln_get_parallax(struct ln_equ_posn* object, double au_distance, struct ln_lnlat_posn* observer, double height, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_parallax(object, au_distance, observer, height, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_parallax_ha(struct ln_equ_posn* object, double au_distance, struct ln_lnlat_posn* observer, double height, double H)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_parallax_ha(object, au_distance, observer, height, H, RETVAL);
    OUTPUT:
      RETVAL
