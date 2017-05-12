
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

void
ln_get_object_rst(double JD, struct ln_lnlat_posn* observer, struct ln_equ_posn* object)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_object_rst(JD, observer, object, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_object_rst_horizon(double JD, struct ln_lnlat_posn* observer, struct ln_equ_posn* object, double horizon)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_object_rst_horizon(JD, observer, object, horizon, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_object_next_rst(double JD, struct ln_lnlat_posn* observer, struct ln_equ_posn* object)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_object_next_rst(JD, observer, object, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_object_next_rst_horizon(double JD, struct ln_lnlat_posn* observer, struct ln_equ_posn* object, double horizon)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_object_next_rst_horizon(JD, observer, object, horizon, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

####  NOT IMPLEMENTED DUE TO FUNCTION POINTER MADNESS!
#### int LIBNOVA_EXPORT ln_get_body_rst_horizon (double JD, struct ln_lnlat_posn * observer, void (*get_equ_body_coords) (double, struct ln_equ_posn *), double horizon, struct ln_rst_time * rst);
#### int LIBNOVA_EXPORT ln_get_body_next_rst_horizon (double JD, struct ln_lnlat_posn * observer, void (*get_equ_body_coords) (double, struct ln_equ_posn *), double horizon, struct ln_rst_time * rst);
#### int LIBNOVA_EXPORT ln_get_body_next_rst_horizon_future (double JD, struct ln_lnlat_posn * observer, void (*get_equ_body_coords) (double, struct ln_equ_posn *), double horizon, int day_limit, struct ln_rst_time * rst);
#### typedef void (*get_motion_body_coords_t) (double, void * orbit, struct ln_equ_posn *);
#### int LIBNOVA_EXPORT ln_get_motion_body_rst_horizon (double JD, struct ln_lnlat_posn * observer, get_motion_body_coords_t get_motion_body_coords, void * orbit, double horizon, struct ln_rst_time * rst);
#### int LIBNOVA_EXPORT ln_get_motion_body_next_rst_horizon (double JD, struct ln_lnlat_posn * observer, get_motion_body_coords_t get_motion_body_coords, void * orbit, double horizon, struct ln_rst_time * rst);
#### int LIBNOVA_EXPORT ln_get_motion_body_next_rst_horizon_future (double JD, struct ln_lnlat_posn * observer, get_motion_body_coords_t get_motion_body_coords, void * orbit, double horizon, int day_limit, struct ln_rst_time * rst);

