
MODULE = Astro::Nova		PACKAGE = Astro::Nova		PREFIX=ln_

double
ln_get_asteroid_mag(JD, orbit, H, G)
  double JD
  struct ln_ell_orbit* orbit
  double H
  double G

double
ln_get_asteroid_sdiam_km(H, A)
  double H
  double A

double
ln_get_asteroid_sdiam_arc(JD, orbit, H, A)
  double JD
  struct ln_ell_orbit* orbit
  double H
  double A

