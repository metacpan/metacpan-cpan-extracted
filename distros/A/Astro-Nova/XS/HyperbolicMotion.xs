
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

double
ln_solve_hyp_barker(double Q1, double G, double t)

double
ln_get_hyp_true_anomaly(double q, double e, double t)

double
ln_get_hyp_radius_vector (double q, double e, double t)


struct ln_rect_posn*
ln_get_hyp_geo_rect_posn(struct ln_hyp_orbit* orbit, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_hyp_geo_rect_posn(orbit, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_rect_posn*
ln_get_hyp_helio_rect_posn(struct ln_hyp_orbit* orbit, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_hyp_helio_rect_posn(orbit, JD, RETVAL);
    OUTPUT:
      RETVAL


struct ln_equ_posn*
ln_get_hyp_body_equ_coords(double JD, struct ln_hyp_orbit* orbit)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_hyp_body_equ_coords(JD, orbit, RETVAL);
    OUTPUT:
      RETVAL

double
ln_get_hyp_body_earth_dist(double JD, struct ln_hyp_orbit* orbit)

double
ln_get_hyp_body_solar_dist(double JD, struct ln_hyp_orbit* orbit)

double
ln_get_hyp_body_phase_angle(double JD, struct ln_hyp_orbit* orbit)

double
ln_get_hyp_body_elong(double JD, struct ln_hyp_orbit* orbit)

void
ln_get_hyp_body_rst(double JD, struct ln_lnlat_posn* observer, struct ln_hyp_orbit* orbit)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_hyp_body_rst(JD, observer, orbit, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_hyp_body_rst_horizon(double JD, struct ln_lnlat_posn* observer, struct ln_hyp_orbit* orbit, double horizon)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_hyp_body_rst_horizon(JD, observer, orbit, horizon, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_hyp_body_next_rst(double JD, struct ln_lnlat_posn* observer, struct ln_hyp_orbit* orbit)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_hyp_body_next_rst(JD, observer, orbit, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_hyp_body_next_rst_horizon(double JD, struct ln_lnlat_posn* observer, struct ln_hyp_orbit* orbit, double horizon)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_hyp_body_next_rst_horizon(JD, observer, orbit, horizon, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_hyp_body_next_rst_horizon_future(double JD, struct ln_lnlat_posn* observer, struct ln_hyp_orbit* orbit, double horizon, int day_limit)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_hyp_body_next_rst_horizon_future(JD, observer, orbit, horizon, day_limit, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

