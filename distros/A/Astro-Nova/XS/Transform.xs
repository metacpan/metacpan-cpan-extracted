
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

struct ln_hrz_posn*
ln_get_hrz_from_equ(struct ln_equ_posn* object, struct ln_lnlat_posn* observer, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::HrzPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_hrz_posn);
      ln_get_hrz_from_equ(object, observer, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_hrz_posn*
ln_get_hrz_from_equ_sidereal_time(struct ln_equ_posn* object, struct ln_lnlat_posn* observer, double sidereal)
    INIT:
      const char* CLASS = "Astro::Nova::HrzPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_hrz_posn);
      ln_get_hrz_from_equ_sidereal_time(object, observer, sidereal, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_equ_from_ecl(struct ln_lnlat_posn* object, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_equ_from_ecl(object, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_lnlat_posn*
ln_get_ecl_from_equ(struct ln_equ_posn* object, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::LnLatPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_lnlat_posn);
      ln_get_ecl_from_equ(object, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_equ_from_hrz(struct ln_hrz_posn* object, struct ln_lnlat_posn* observer, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_equ_from_hrz(object, observer, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_rect_posn*
ln_get_rect_from_helio(struct ln_helio_posn* helio)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_rect_from_helio(helio, RETVAL);
    OUTPUT:
      RETVAL

struct ln_lnlat_posn*
ln_get_ecl_from_rect(struct ln_rect_posn* rect)
    INIT:
      const char* CLASS = "Astro::Nova::LnLatPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_lnlat_posn);
      ln_get_ecl_from_rect(rect, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_equ_from_gal(struct ln_gal_posn* gal)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_equ_from_gal(gal, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_get_equ2000_from_gal(struct ln_gal_posn* gal)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_equ2000_from_gal(gal, RETVAL);
    OUTPUT:
      RETVAL

struct ln_gal_posn*
ln_get_gal_from_equ(struct ln_equ_posn* equ)
    INIT:
      const char* CLASS = "Astro::Nova::GalPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_gal_posn);
      ln_get_gal_from_equ(equ, RETVAL);
    OUTPUT:
      RETVAL

struct ln_gal_posn*
ln_get_gal_from_equ2000(struct ln_equ_posn* equ)
    INIT:
      const char* CLASS = "Astro::Nova::GalPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_gal_posn);
      ln_get_gal_from_equ2000(equ, RETVAL);
    OUTPUT:
      RETVAL

