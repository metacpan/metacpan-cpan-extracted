
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

double
ln_solve_kepler(double e, double M)

double
ln_get_ell_mean_anomaly(double n, double delta_JD)

double
ln_get_ell_true_anomaly(double e, double E)

double
ln_get_ell_radius_vector(double a, double e, double E)

double
ln_get_ell_smajor_diam(double e, double q)

double
ln_get_ell_sminor_diam(double e, double a)

double
ln_get_ell_mean_motion(double a)

struct ln_rect_posn*
ln_get_ell_geo_rect_posn(struct ln_ell_orbit* orbit, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_ell_geo_rect_posn(orbit, JD, RETVAL);
    OUTPUT:
      RETVAL

struct ln_rect_posn*
ln_get_ell_helio_rect_posn(struct ln_ell_orbit* orbit, double JD)
    INIT:
      const char* CLASS = "Astro::Nova::RectPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_rect_posn);
      ln_get_ell_helio_rect_posn(orbit, JD, RETVAL);
    OUTPUT:
      RETVAL

double
ln_get_ell_orbit_len(struct ln_ell_orbit* orbit)

double
ln_get_ell_orbit_vel(double JD, struct ln_ell_orbit* orbit)

double
ln_get_ell_orbit_pvel(struct ln_ell_orbit* orbit)

double
ln_get_ell_orbit_avel(struct ln_ell_orbit* orbit);

double
ln_get_ell_body_phase_angle(double JD, struct ln_ell_orbit* orbit)

double
ln_get_ell_body_elong(double JD, struct ln_ell_orbit* orbit)

double
ln_get_ell_body_solar_dist(double JD, struct ln_ell_orbit* orbit)

double
ln_get_ell_body_earth_dist(double JD, struct ln_ell_orbit* orbit)

struct ln_equ_posn*
ln_get_ell_body_equ_coords(double JD, struct ln_ell_orbit* orbit)
    INIT:
      const char* CLASS = "Astro::Nova::EquPosn";
    CODE:
      Newx(RETVAL, 1, struct ln_equ_posn);
      ln_get_ell_body_equ_coords(JD, orbit, RETVAL);
    OUTPUT:
      RETVAL

void
ln_get_ell_body_rst(double JD, struct ln_lnlat_posn* observer, struct ln_ell_orbit* orbit)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_ell_body_rst(JD, observer, orbit, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_ell_body_rst_horizon(double JD, struct ln_lnlat_posn* observer, struct ln_ell_orbit* orbit, double horizon)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_ell_body_rst_horizon(JD, observer, orbit, horizon, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_ell_body_next_rst(double JD, struct ln_lnlat_posn* observer, struct ln_ell_orbit* orbit)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_ell_body_next_rst(JD, observer, orbit, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_ell_body_next_rst_horizon(double JD, struct ln_lnlat_posn* observer, struct ln_ell_orbit* orbit, double horizon)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_ell_body_next_rst_horizon(JD, observer, orbit, horizon, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

void
ln_get_ell_body_next_rst_horizon_future(double JD, struct ln_lnlat_posn* observer, struct ln_ell_orbit* orbit, double horizon, int day_limit)
    INIT:
      struct ln_rst_time* rst;
    PPCODE:
      Newx(rst, 1, struct ln_rst_time);
      int res = ln_get_ell_body_next_rst_horizon_future(JD, observer, orbit, horizon, day_limit, rst);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(res)));
      PUSHs(sv_newmortal());
      sv_setref_pv(ST(1), "Astro::Nova::RstTime", (void*)rst);

double
ln_get_ell_last_perihelion(double epoch_JD, double M, double n)

