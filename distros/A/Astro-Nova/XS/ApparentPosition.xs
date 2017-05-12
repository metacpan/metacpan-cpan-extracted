
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

struct ln_equ_posn*
ln_get_apparent_posn(struct ln_equ_posn* mean_position, struct ln_equ_posn* proper_motion, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_apparent_posn(mean_position, proper_motion, JD, RETVAL);
    OUTPUT:
      RETVAL

