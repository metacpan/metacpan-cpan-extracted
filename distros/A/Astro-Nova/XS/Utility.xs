
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_


const char*
ln_get_version()

double
ln_get_dec_location(char* s)

const char*
ln_get_humanr_location(double location)

double
ln_get_rect_distance(struct ln_rect_posn* a, struct ln_rect_posn* b)

double
ln_rad_to_deg(double radians)

double
ln_deg_to_rad(double degrees)

double
ln_hms_to_deg(struct ln_hms* hms)

struct ln_hms*
ln_deg_to_hms(double degrees)
    INIT:
      const char* CLASS = "Astro::Nova::HMS";
    CODE:
      Newx(RETVAL, 1, struct ln_hms);
      ln_deg_to_hms(degrees, RETVAL);
    OUTPUT:
      RETVAL

double
ln_hms_to_rad(struct ln_hms* hms)

struct ln_hms*
ln_rad_to_hms(double radians)
    INIT:
      const char* CLASS = "Astro::Nova::HMS";
    CODE:
      Newx(RETVAL, 1, struct ln_hms);
      ln_rad_to_hms(radians, RETVAL);
    OUTPUT:
      RETVAL

double
ln_dms_to_deg(struct ln_dms* dms)

struct ln_dms*
ln_deg_to_dms(double degrees)
    INIT:
      const char* CLASS = "Astro::Nova::DMS";
    CODE:
      Newx(RETVAL, 1, struct ln_dms);
      ln_deg_to_dms(degrees, RETVAL);
    OUTPUT:
      RETVAL

double
ln_dms_to_rad(struct ln_dms* dms)

struct ln_dms*
ln_rad_to_dms(double radians)
    INIT:
      const char* CLASS = "Astro::Nova::DMS";
    CODE:
      Newx(RETVAL, 1, struct ln_dms);
      ln_rad_to_dms(radians, RETVAL);
    OUTPUT:
      RETVAL

struct ln_equ_posn*
ln_hequ_to_equ(struct lnh_equ_posn* hpos);
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_hequ_to_equ(hpos, RETVAL);
    OUTPUT:
      RETVAL

struct lnh_equ_posn*
ln_equ_to_hequ(struct ln_equ_posn* pos);
    INIT:
      const char* CLASS = "Astro::Nova::HEquPosn";
    CODE:
      Newx(RETVAL, 1, struct lnh_equ_posn);
      ln_equ_to_hequ(pos, RETVAL);
    OUTPUT:
      RETVAL
        
struct ln_hrz_posn*
ln_hhrz_to_hrz(struct lnh_hrz_posn* hpos);
    INIT:
      const char* CLASS = "Astro::Nova::HrzPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_hrz_posn);
      ln_hhrz_to_hrz(hpos, RETVAL);
    OUTPUT:
      RETVAL

struct lnh_hrz_posn*
ln_hrz_to_hhrz(struct ln_hrz_posn* pos);
    INIT:
      const char* CLASS = "Astro::Nova::HHrzPosn";
    CODE:
      Newx(RETVAL, 1, struct lnh_hrz_posn);
      ln_hrz_to_hhrz(pos, RETVAL);
    OUTPUT:
      RETVAL

 ### const char * ln_hrz_to_nswe (struct ln_hrz_posn * pos);
        
struct ln_lnlat_posn*
ln_hlnlat_to_lnlat(struct lnh_lnlat_posn* hpos);
    INIT:
      const char* CLASS = "Astro::Nova::LnLatPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_lnlat_posn);
      ln_hlnlat_to_lnlat(hpos, RETVAL);
    OUTPUT:
      RETVAL
        
struct lnh_lnlat_posn*
ln_lnlat_to_hlnlat(struct ln_lnlat_posn* pos);
    INIT:
      const char* CLASS = "Astro::Nova::HLnLatPosn";
    CODE:
      Newx(RETVAL, 1, struct lnh_lnlat_posn);
      ln_lnlat_to_hlnlat(pos, RETVAL);
    OUTPUT:
      RETVAL

void
ln_add_secs_hms (struct ln_hms* hms, double seconds)

void
ln_add_hms(struct ln_hms* source, struct ln_hms* dest)

double
ln_get_light_time(double dist)


