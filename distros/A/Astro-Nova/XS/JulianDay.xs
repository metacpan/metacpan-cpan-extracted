
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

double
ln_get_julian_day(struct ln_date* date)

struct ln_date*
ln_get_date(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::Date";
    CODE:
      Newx(RETVAL, 1, struct ln_date);
      ln_get_date(JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_date*
ln_get_date_from_timet(time_t t)
    INIT:
      const char* CLASS = "Astro::Nova::Date";
    CODE:
      Newx(RETVAL, 1, struct ln_date);
      ln_get_date_from_timet(&t, RETVAL);
    OUTPUT:
      RETVAL

 ## void ln_get_date_from_tm (struct tm * t, struct ln_date * date);

struct ln_zonedate*
ln_get_local_date(double JD)
    INIT:
      const char* CLASS = "Astro::Nova::ZoneDate";
    CODE:
      Newx(RETVAL, 1, struct ln_zonedate);
      ln_get_local_date(JD, RETVAL);
    OUTPUT:
      RETVAL

unsigned int
ln_get_day_of_week(struct ln_date* date)
        
double
ln_get_julian_from_sys()

struct ln_date*
ln_get_date_from_sys()
    INIT:
      const char* CLASS = "Astro::Nova::Date";
    CODE:
      Newx(RETVAL, 1, struct ln_date);
      ln_get_date_from_sys( RETVAL);
    OUTPUT:
      RETVAL
        
double
ln_get_julian_from_timet(time_t t)
    CODE:
      RETVAL = ln_get_julian_from_timet(&t);
    OUTPUT:
      RETVAL

time_t
ln_get_timet_from_julian(double JD)
    CODE:
      ln_get_timet_from_julian(JD, &RETVAL);
    OUTPUT:
      RETVAL

double
ln_get_julian_local_date(struct ln_zonedate* zonedate)
        
 ## int ln_get_date_from_mpc (struct ln_date* date, char* mpc_date);
        
 ## double ln_get_julian_from_mpc (char* mpc_date);

struct ln_zonedate*
ln_date_to_zonedate(struct ln_date* date, long gmtoff)
    INIT:
      const char* CLASS = "Astro::Nova::ZoneDate";
    CODE:
      Newx(RETVAL, 1, struct ln_zonedate);
      ln_date_to_zonedate(date, RETVAL, gmtoff);
    OUTPUT:
      RETVAL

struct ln_date*
ln_zonedate_to_date(struct ln_zonedate* zonedate)
    INIT:
      const char* CLASS = "Astro::Nova::Date";
    CODE:
      Newx(RETVAL, 1, struct ln_date);
      ln_zonedate_to_date(zonedate, RETVAL);
    OUTPUT:
      RETVAL

