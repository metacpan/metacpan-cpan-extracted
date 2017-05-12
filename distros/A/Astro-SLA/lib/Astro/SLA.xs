/*        -*- C -*-

  perl-SLA glue - 99.9% complete
                                        t.jenness@jach.hawaii.edu

  Copyright (C) 1998-2005 Tim Jenness.  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

  Has been tested with the Sep 2005 release of SLALIB
  (C and Fortran)
 */


#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "XSUB.h"     /* XSUB include */

/* Dummy main required for some fortran compilers */
#ifdef USE_FORTRAN
void MAIN_ () {}
void MAIN__ () {}
#endif

/* Control whether we are using trailing underscores in fortran
   names */
#ifdef HAS_UNDERSCORE
  #define TRAIL(func)  func ## _
#else
  #define TRAIL(func) func
#endif


/* only include slalib.h if we are using C */
#ifdef  USE_FORTRAN
/* Provide alternative prototypes for functions so that we get the
   correct return type from the compiler */
  double TRAIL(sla_airmas)(double * zd);
  double TRAIL(sla_dat)(double * utc);
  double TRAIL(sla_dbear)(double *a1, double *b1, double *a2,
			  double *b2);
  double TRAIL(sla_dpav)(double *v1, double * v2);
  double TRAIL(sla_dranrm)(double * angle);
  double TRAIL(sla_drange)(double * angle);
  double TRAIL(sla_dsep)(double *a1, double *b1, double *a2,
			 double *b2);
  double TRAIL(sla_dt)(double * epoch);
  double TRAIL(sla_dtt)(double * dju);
  double TRAIL(sla_dvdv)(double * va, double *vb);
  double TRAIL(sla_epb)(double * date);
  double TRAIL(sla_epb2d)(double * epb);
  double TRAIL(sla_epco)(char *k0, char *k, double *e, int len1, int len2);
  double TRAIL(sla_epj)(double * date);
  double TRAIL(sla_epj2d)(double * epb);
  double TRAIL(sla_eqeqx)(double * date);
  double TRAIL(sla_gmst)(double * ut1);
  double TRAIL(sla_gmsta)(double *date, double *ut1);
  float  TRAIL(sla_gresid)(float * s);
  double TRAIL(sla_pa)(double * ha, double * dec, double * phi);
  float  TRAIL(sla_random)(float * seed);
  double TRAIL(sla_rcc)(double *tdb, double *ut1, double *wl,
			double *u, double *v);
  float  TRAIL(sla_rverot)(float *phi, float *ra, float *da, float *st);
  float  TRAIL(sla_rvgalc)(float * r2000, float * d2000);
  float  TRAIL(sla_rvlg)(float * r2000, float * d2000);
  float  TRAIL(sla_rvlsrd)(float * r2000, float * d2000);
  float  TRAIL(sla_rvlsrk)(float * r2000, float * d2000);
  double TRAIL(sla_zd)(double * ha, double *dec, double *phi);
# else
#include "slalib.h"
# endif

#include "arrays.h"

#ifdef USE_FORTRAN

/* Internally convert an f77 string to C - must be at least 1 byte long */
/* Could use cnf here */

static void stringf77toC( char *c, int len );
static void myCnfExprt ( const char * source_c,
                         char * dest_f, int dest_len);

static void stringf77toC (char*c, int len) {
   int i;

   if (len==0) {return;} /* Do nothing */

   /* Remove all spurious \0 characters */
   i = 0;

   while(i<len-1) {
     if(*(c+i) == '\0') { *(c+i) = ' ';}
     i++;
   }

   /* Find end of string */
   i = len;

   while((*(c+i-1)==' '||*(c+i-1)=='\0') && i>=0){
       i--;
   }
   if (i<0)       {i=0;}
   if (i==len) {i--;}
   /* And NULL it */;
   *(c+i) = '\0';
}

/* Copy a C string into a buffer and pad that buffer with spaces
   to the requested size suitable for use with Fortran.
   This code is stolen from Starlink CNF routine cnfExprt
   [see SUN/209 - CNF]
*/
static void myCnfExprt ( const char * source_c,
                         char * dest_f, int dest_len) {
   int i;                        /* Loop counter                            */

/* Copy the characters of the input C string to the output FORTRAN string,  */
/* taking care not to go beyond the end of the FORTRAN string.              */
   for( i = 0 ; (i < dest_len ) && ( source_c[i] != '\0' ) ; i++ )
      dest_f[i] = source_c[i];
/* Fill the rest of the output FORTRAN string with blanks.                  */
   for(  ; i < dest_len ; i++ )
      dest_f[i] = ' ';
}

#endif

MODULE = Astro::SLA   PACKAGE = Astro::SLA


# Add a few routines

void
slaAddet(rm, dm, eq, rc, dc)
  double rm
  double dm
  double eq
  double rc = NO_INIT
  double dc = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_addet)(&rm,&dm,&eq,&rc,&dc);
#else
  slaAddet(rm, dm, eq, &rc, &dc);
#endif
 OUTPUT:
  rc
  dc

void
slaAfin(string, nstrt, reslt, jf)
  char * string
  int nstrt
  float reslt = NO_INIT
  int jf = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_afin)(string,&nstrt,&reslt,&jf,strlen(string));
#else
  slaAfin(string, &nstrt, &reslt, &jf);
#endif
 OUTPUT:
  nstrt
  reslt
  jf



double
slaAirmas(zd)
  double zd
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_airmas)(&zd);
#else
  RETVAL = slaAirmas(zd);
#endif
 OUTPUT:
  RETVAL

void
slaAltaz(ha, dec, phi, az, azd, azdd, el, eld, eldd, pa, pad, padd)
  double ha
  double dec
  double phi
  double az = NO_INIT
  double azd = NO_INIT
  double azdd = NO_INIT
  double el = NO_INIT
  double eld = NO_INIT
  double eldd = NO_INIT
  double pa = NO_INIT
  double pad = NO_INIT
  double padd = NO_INIT
 PROTOTYPE: $$$$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_altaz)(&ha, &dec, &phi, &az, &azd, &azdd, &el, &eld,
		   &eldd, &pa, &pad, &padd);
#else
  slaAltaz(ha, dec, phi, &az, &azd, &azdd, &el, &eld, &eldd, &pa, &pad, &padd);
#endif
 OUTPUT:
  az
  azd
  azdd
  el
  eld
  eldd
  pa
  pad
  padd

void
slaAmp(ra, da, date, eq, rm, dm)
  double ra
  double da
  double date
  double eq
  double rm = NO_INIT
  double dm = NO_INIT
 PROTOTYPE: $$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_amp)(&ra, &da, &date, &eq, &rm, &dm);
#else
  slaAmp(ra, da, date, eq, &rm, &dm);
#endif
 OUTPUT:
  rm
  dm

# FLAG: Need to add a check for number of components in amprms

void
slaAmpqk(ra, da, amprms, rm, dm)
  double ra
  double da
  double * amprms
  double rm = NO_INIT
  double dm = NO_INIT
 PROTOTYPE: $$\@$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_ampqk)(&ra,&da,amprms,&rm,&dm);
#else
  slaAmpqk(ra, da, amprms, &rm, &dm);
#endif
 OUTPUT:
  rm
  dm

void
slaAop(rap,dap,date,dut,elongm,phim,hm,xp,yp,tdk,pmb,rh,wl,tlr,aob,zob,hob,dob,rob)
  double rap
  double dap
  double date
  double dut
  double elongm
  double phim
  double hm
  double xp
  double yp
  double tdk
  double pmb
  double rh
  double wl
  double tlr
  double aob = NO_INIT
  double zob = NO_INIT
  double hob = NO_INIT
  double dob = NO_INIT
  double rob = NO_INIT
 PROTOTYPE: $$$$$$$$$$$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_aop)(&rap,&dap,&date,&dut,&elongm,&phim,&hm,&xp,&yp,&tdk,&pmb,
		 &rh,&wl,&tlr,&aob,&zob,&hob,&dob,&rob);
#else
  slaAop(rap,dap,date,dut,elongm,phim,hm,xp,yp,tdk,pmb,rh,wl,tlr,&aob,&zob,&hob,&dob,&rob);
#endif
 OUTPUT:
  aob
  zob
  hob
  dob
  rob

void
slaAoppa(date,dut,elongm,phim,hm,xp,yp,tdk,pmb,rh,wl,tlr,aoprms)
  double date
  double dut
  double elongm
  double phim
  double hm
  double xp
  double yp
  double tdk
  double pmb
  double rh
  double wl
  double tlr
  double * aoprms = NO_INIT
 PROTOTYPE: $$$$$$$$$$$\@
 CODE:
  aoprms = get_mortalspace(14,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_aoppa)(&date,&dut,&elongm,&phim,&hm,&xp,&yp,&tdk,&pmb,&rh,
		   &wl,&tlr,aoprms);
#else
  slaAoppa(date,dut,elongm,phim,hm,xp,yp,tdk,pmb,rh,wl,tlr,aoprms);
#endif
  unpack1D( (SV*)ST(12), (void *)aoprms, 'd', 14);

### FLAG: Can give 13 input arguments and receive 14 for slaAoppat
### Must make absolutely sure that we have 14 args going in.
### Too lazy for now

void
slaAoppat(date, aoprms)
  double date
  double * aoprms
 PROTOTYPE: $\@
 CODE:
  /* Should probably allocate [14] doubles here and copy the array
     myself */
#ifdef USE_FORTRAN
  TRAIL(sla_aoppat)(&date,aoprms);
#else
  slaAoppat(date, aoprms);
#endif
  unpack1D( (SV*)ST(1), (void *)aoprms, 'd', 14);

void
slaAopqk(rap, dap, aoprms, aob, zob, hob, dob, rob)
  double rap
  double dap
  double * aoprms
  double aob = NO_INIT
  double zob = NO_INIT
  double hob = NO_INIT
  double dob = NO_INIT
  double rob = NO_INIT
 PROTOTYPE: $$\@$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_aopqk)(&rap, &dap, aoprms, &aob,&zob,&hob,&dob,&rob);
#else
  slaAopqk(rap, dap, aoprms, &aob,&zob,&hob,&dob,&rob);
#endif
 OUTPUT:
  aob
  zob
  hob
  dob
  rob

void
slaAtmdsp(tdk, pmb, rh, wl1, a1, b1, wl2, a2, b2)
  double tdk
  double pmb
  double rh
  double wl1
  double a1
  double b1
  double wl2
  double a2 = NO_INIT
  double b2 = NO_INIT
 PROTOTYPE:
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_atmdsp)(&tdk, &pmb, &rh, &wl1, &a1, &b1, &wl2, &a2, &b2);
#else
  slaAtmdsp(tdk, pmb, rh, wl1, a1, b1, wl2, &a2, &b2);
#endif
 OUTPUT:
  a2
  b2

#### FLAG: Need to check return array
#### Should really be a PDL function

void
slaAv2m(axvec, rmat)
  float * axvec
  float * rmat = NO_INIT
 PROTOTYPE: \@\@
 CODE:
  rmat = get_mortalspace(9,'f');
#ifdef USE_FORTRAN
  TRAIL(sla_av2m)(axvec, rmat);
#else
  slaAv2m(axvec, (void*)rmat);
#endif
  unpack1D( (SV*)ST(1), (void *)rmat, 'f', 9);

### SKIP: slaBear - use DOUBLE precisions version - slaDbear

### SKIP: slaCaf2r - use DOUBLE precisions version - slaDaf2r


void
slaCaldj(iy, im, id, djm, j)
  int iy
  int im
  int id
  double djm = NO_INIT
  int j = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_caldj)(&iy, &im, &id, &djm, &j);
#else
  slaCaldj(iy, im, id, &djm, &j);
#endif
 OUTPUT:
  djm
  j

void
slaCalyd(iy, im, id, ny, nd, j)
  int iy
  int im
  int id
  int ny = NO_INIT
  int nd = NO_INIT
  int j = NO_INIT
 PROTOTYPE: $$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_calyd)(&iy, &im, &id, &ny, &nd, &j);
#else
  slaCalyd(iy, im, id, &ny, &nd, &j);
#endif
 OUTPUT:
  ny
  nd
  j

### SKIP: slaCc2s - use Double precision version - slaDc2s
### SKIP: slaCc62s - use Double precision version - slaDc62s
### SKIP: slaCd2tf - use Double precision version - slaDd2tf

# Calendar to MJD

void
slaCldj(iy, im, id, djm, status)
  int iy
  int im
  int id
  double djm = NO_INIT
  int status = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_cldj)(&iy,&im,&id,&djm,&status);
#else
  slaCldj(iy, im, id, &djm, &status);
#endif
 OUTPUT:
  djm
  status



void
slaClyd(iy, im, id, ny, nd, j)
  int iy
  int im
  int id
  int ny = NO_INIT
  int nd = NO_INIT
  int j = NO_INIT
 PROTOTYPE: $$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_clyd)(&iy, &im, &id, &ny, &nd, &j);
#else
  slaClyd(iy, im, id, &ny, &nd, &j);
#endif
 OUTPUT:
  ny
  nd
  j


### SKIP: slaCr2af - use DOUBLE instead - slaDr2af
### SKIP: slaCr2tf - use DOUBLE instead - slaDr2tf
### SKIP: slaCs2c - use DOUBLE instead
### SKIP: slaCs2c6 - use DOUBLE instead - slaDs2c6
### SKIP: slaCtf2d - use DOUBLE instead
### SKIP: slaCtf2r - use DOUBLE instead


## Up to slaDaf2r
#   Converts DMS to radians

void
slaDaf2r(ideg, iamin, asec, rad, j)
  int ideg
  int iamin
  double asec
  double  rad = NO_INIT
  int  j = NO_INIT
 ALIAS:
  slaCaf2r = 1
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_daf2r)(&ideg, &iamin, &asec, &rad,&j);
#else
  slaDaf2r(ideg, iamin, asec, &rad, &j);
#endif
 OUTPUT:
 rad
 j


void
slaDafin(string, nstrt, dreslt, jf)
  char * string
  int nstrt
  double dreslt = NO_INIT
  int jf = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_dafin)(string,&nstrt,&dreslt,&jf,strlen(string));
#else
  slaDafin(string, &nstrt, &dreslt, &jf);
#endif
 OUTPUT:
  nstrt
  dreslt
  jf


# Added 5/5/98

double
slaDat(utc)
  double utc
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_dat)(&utc);
#else
  RETVAL = slaDat(utc);
#endif
 OUTPUT:
  RETVAL




#### Should really be a PDL function

void
slaDav2m(axvec, rmat)
  double * axvec
  double * rmat = NO_INIT
 PROTOTYPE: \@\@
 CODE:
  rmat = get_mortalspace(9,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_dav2m)(axvec,rmat);
#else
  slaDav2m(axvec, (void*)rmat);
#endif
  unpack1D( (SV*)ST(1), (void *)rmat, 'd', 9);

double
slaDbear(a1, b1, a2, b2)
  double a1
  double b1
  double a2
  double b2
 ALIAS:
  slaBear = 1
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_dbear)(&a1, &b1, &a2, &b2);
#else
  RETVAL = slaDbear(a1, b1, a2, b2);
#endif
 OUTPUT:
  RETVAL

void
slaDbjin(string, nstrt, dreslt, j1, j2)
  char * string
  int nstrt
  double dreslt = NO_INIT
  int j1 = NO_INIT
  int j2 = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dbjin)(string, &nstrt, &dreslt, &j1, &j2,strlen(string));
#else
  slaDbjin(string, &nstrt, &dreslt, &j1, &j2);
#endif
 OUTPUT:
  nstrt
  dreslt
  j1
  j2

void
slaDc62s(v, a, b, r, ad, bd, rd)
  double * v
  double a = NO_INIT
  double b = NO_INIT
  double r = NO_INIT
  double ad = NO_INIT
  double bd = NO_INIT
  double rd = NO_INIT
 ALIAS:
  slaCc62s = 1
 PROTOTYPE: \@$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dc62s)(v, &a, &b, &r, &ad, &bd, &rd);
#else
  slaDc62s(v, &a, &b, &r, &ad, &bd, &rd);
#endif
 OUTPUT:
  a
  b
  r
  ad
  bd
  rd


void
slaDcc2s(v,a,b)
  double * v
  double a = NO_INIT
  double b = NO_INIT
 ALIAS:
  slaCc2s = 1
 PROTOTYPE: \@$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dcc2s)(v,&a,&b);
#else
  slaDcc2s(v, &a, &b);
#endif
 OUTPUT:
  a
  b


void
slaDcmpf(coeffs, xy, yz, xs, ys, perp, orient)
  double * coeffs
  double xy = NO_INIT
  double yz = NO_INIT
  double xs = NO_INIT
  double ys = NO_INIT
  double perp = NO_INIT
  double orient = NO_INIT
 PROTOTYPE: \@$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dcmpf)(coeffs, &xy, &yz, &xs, &ys, &perp, &orient);
#else
  slaDcmpf(coeffs, &xy, &yz, &xs, &ys, &perp, &orient);
#endif
 OUTPUT:
  xy
  yz
  xs
  ys
  perp
  orient

void
slaDcs2c(a, b, v)
  double a
  double b
  double * v = NO_INIT
 PROTOTYPE: $$\@
 CODE:
  v = get_mortalspace(3,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_dcs2c)(&a,&b,v);
#else
  slaDcs2c(a, b, v);
#endif
  unpack1D( (SV*)ST(2), (void *)v, 'd', 3);

#   Converts decimal day to hours minutes and seconds

void
slaDd2tf(ndp, days, sign, ihmsf)
  int ndp
  double  days
  char sign = NO_INIT
  int * ihmsf = NO_INIT
 ALIAS:
  slaCd2tf = 1
 PROTOTYPE: $$$\@
 CODE:
  ihmsf = get_mortalspace(4,'i');
#ifdef USE_FORTRAN
  TRAIL(sla_dd2tf)(&ndp,&days,&sign,ihmsf,1);
#else
  slaDd2tf(ndp, days, &sign, ihmsf);
#endif
  unpack1D( (SV*)ST(3), (void *)ihmsf, 'i', 4);
 OUTPUT:
  sign

# Equatorial to horizontal

void
slaDe2h(ha, dec, phi, az, el)
  double ha
  double dec
  double phi
  double az = NO_INIT
  double el = NO_INIT
 PROTOTYPE: $$$$$
 ALIAS:
  slaE2h = 1
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_de2h)(&ha, &dec, &phi, &az, &el);
#else
  slaDe2h(ha, dec, phi, &az, &el);
#endif
 OUTPUT:
  az
  el


void
slaDeuler(order, phi, theta, psi, rmat)
  char * order
  double phi
  double theta
  double psi
  double * rmat = NO_INIT
 PROTOTYPE: $$$$\@
 ALIAS:
  slaEuler = 1
 CODE:
  rmat = get_mortalspace(9,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_deuler)(order, &phi, &theta, &psi, rmat,strlen(order));
#else
  slaDeuler(order, phi, theta, psi, (void*)rmat);
#endif
  unpack1D( (SV*)ST(4), (void *)rmat, 'd', 9);

void
slaDfltin(string, nstrt, dreslt, jflag)
  char * string
  int nstrt
  double dreslt
  int jflag = NO_INIT
 PROTOTYPE: $$$$
 ALIAS:
  slaFloatin = 1
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dfltin)(string, &nstrt, &dreslt, &jflag,strlen(string));
#else
  slaDfltin(string, &nstrt, &dreslt, &jflag);
#endif
 OUTPUT:
  nstrt
  dreslt
  jflag

# Horizontal to equatorial

void
slaDh2e(az, el, phi, ha, dec)
  double az
  double el
  double phi
  double ha = NO_INIT
  double dec = NO_INIT
 PROTOTYPE: $$$$$
 ALIAS:
  slaH2e = 1
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dh2e)(&az, &el, &phi, &ha, &dec);
#else
  slaDh2e(az, el, phi, &ha, &dec);
#endif
OUTPUT:
  ha
  dec

void
slaDimxv(dm, va, vb)
  double * dm
  double * va
  double * vb = NO_INIT
 PROTOTYPE: \@\@\@
 CODE:
  vb = get_mortalspace(3,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_dimxv)(dm,va,vb);
#else
  slaDimxv((void*)dm, va, vb);
#endif
  unpack1D( (SV*)ST(2), (void *)vb, 'd', 3);

void
slaDjcal(ndp, djm, iymdf, j)
  int ndp
  double djm
  int * iymdf = NO_INIT
  int j
 PROTOTYPE: $$\@$
 CODE:
   iymdf =  get_mortalspace(4,'i');
#ifdef USE_FORTRAN
   TRAIL(sla_djcal)(&ndp, &djm, iymdf, &j);
#else
   slaDjcal(ndp, djm, iymdf, &j);
#endif
   unpack1D( (SV*)ST(2), (void *)iymdf, 'i', 4);
 OUTPUT:
  j

# MJD to UT

void
slaDjcl(mjd, iy, im, id, fd, j)
  double mjd
  int iy = NO_INIT
  int im = NO_INIT
  int id = NO_INIT
  double fd = NO_INIT
  int j = NO_INIT
 PROTOTYPE: $$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_djcl)(&mjd,&iy,&im,&id,&fd,&j);
#else
  slaDjcl(mjd, &iy, &im, &id, &fd, &j);
#endif
 OUTPUT:
  iy
  im
  id
  fd
  j

void
slaDm2av(rmat, axvec)
  double * rmat
  double * axvec = NO_INIT
 PROTOTYPE: \@\@
 ALIAS:
  slaM2av = 1
 CODE:
  axvec = get_mortalspace(3,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_dm2av)(rmat,axvec);
#else
  slaDm2av((void*)rmat, axvec);
#endif
  unpack1D( (SV*)ST(1), (void *)axvec, 'd', 3);

###### FLAG:   Do slaDmat at the end

void
slaDmoon(date, pv)
  double date
  double * pv = NO_INIT
 PROTOTYPE: $\@
 CODE:
   pv = get_mortalspace(6,'d');
#ifdef USE_FORTRAN
   TRAIL(sla_dmoon)(&date,pv);
#else
   slaDmoon(date, pv);
#endif
   unpack1D( (SV*)ST(1), (void *)pv, 'd', 6);

#### FLAG : Matrix manipulation should be using PDLs

void
slaDmxm(a, b, c)
  double * a
  double * b
  double * c = NO_INIT
 PROTOTYPE: \@\@\@
 ALIAS:
  slaMxm = 1
 CODE:
  c = get_mortalspace(9, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_dmxm)(a,b,c);
#else
  slaDmxm((void*)a,(void*)b,(void*)c);
#endif
  unpack1D( (SV*)ST(2), (void *)c, 'd', 9);

void
slaDmxv(dm, va, vb)
  double * dm
  double * va
  double * vb = NO_INIT
 PROTOTYPE: \@\@\@
 ALIAS:
  slaMxv = 1
 CODE:
  vb = get_mortalspace(3, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_dmxv)(dm,va,vb);
#else
  slaDmxv((void*)dm, va, vb);
#endif
  unpack1D( (SV*)ST(2), (void *)vb, 'd', 3);

double
slaDpav(v1, v2)
  double * v1
  double * v2
 PROTOTYPE: \@\@
 ALIAS:
  slaPav = 1
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_dpav)(v1,v2);
#else
  RETVAL = slaDpav(v1, v2);
#endif
 OUTPUT:
  RETVAL

#   Converts radians to HMS

void
slaDr2tf(ndp, angle, sign, ihmsf)
  int ndp
  double angle
  char sign = NO_INIT
  int * ihmsf = NO_INIT
 ALIAS:
  slaCr2tf = 1
 PROTOTYPE: $$$\@
 CODE:
  ihmsf = get_mortalspace(4,'i');
#ifdef USE_FORTRAN
  TRAIL(sla_dr2tf)(&ndp,&angle,&sign,ihmsf,1);
#else
  slaDr2tf(ndp, angle, &sign, ihmsf);
#endif
  unpack1D( (SV*)ST(3), (void *)ihmsf, 'i', 4);
 OUTPUT:
  sign

double
slaDrange(angle)
  double angle
 PROTOTYPE: $
 ALIAS:
  slaRange = 1
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_drange)(&angle);
#else
  RETVAL = slaDrange(angle);
#endif
 OUTPUT:
  RETVAL

double
slaDranrm(angle)
  double angle
 PROTOTYPE: $
 ALIAS:
  slaRanorm = 1
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_dranrm)(&angle);
#else
  RETVAL = slaDranrm(angle);
#endif
 OUTPUT:
  RETVAL


#   Converts radians to DMS

void
slaDr2af(ndp, angle, sign, idmsf)
  int ndp
  double angle
  char sign = NO_INIT
  int * idmsf = NO_INIT
 ALIAS:
  slaCr2af = 1
 PROTOTYPE: $$$\@
 CODE:
  idmsf = get_mortalspace(4,'i');
#ifdef USE_FORTRAN
  TRAIL(sla_dr2af)(&ndp,&angle,&sign,idmsf,1);
#else
  slaDr2af(ndp, angle, &sign, idmsf);
#endif
  unpack1D( (SV*)ST(3), (void *)idmsf, 'i', 4);
 OUTPUT:
  sign

void
slaDs2c6(a, b, r, ad, bd, rd, v)
  double a
  double b
  double r
  double ad
  double bd
  double rd
  double * v = NO_INIT
 ALIAS:
  slaCs2c6 = 1
 PROTOTYPE: $$$$$$\@
 CODE:
  v = get_mortalspace(6,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_ds2c6)(&a, &b, &r, &ad, &bd, &rd, v);
#else
  slaDs2c6(a, b, r, ad, bd, rd, v);
#endif
  unpack1D( (SV*)ST(6), (void *)v, 'd', 6);

void
slaDs2tp(ra, dec, raz, decz, xi, eta, j)
  double ra
  double dec
  double raz
  double decz
  double xi = NO_INIT
  double eta = NO_INIT
  int j = NO_INIT
 PROTOTYPE: $$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_ds2tp)(&ra, &dec, &raz, &decz, &xi, &eta, &j);
#else
  slaDs2tp(ra, dec, raz, decz, &xi, &eta, &j);
#endif
 OUTPUT:
  xi
  eta
  j

double
slaDsep(a1, b1, a2, b2)
  double a1
  double b1
  double a2
  double b2
 PROTOTYPE: $$$$
 ALIAS:
  slaSep = 1
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_dsep)(&a1,&b1,&a2,&b2);
#else
  RETVAL = slaDsep(a1, b1, a2, b2);
#endif
 OUTPUT:
  RETVAL


double
slaDt(epoch)
  double epoch
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_dt)(&epoch);
#else
  RETVAL = slaDt(epoch);
#endif
 OUTPUT:
  RETVAL



void
slaDtf2d(ihour, imin, sec, days, j)
  int ihour
  int imin
  double sec
  double  days = NO_INIT
  int  j = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dtf2d)(&ihour,&imin,&sec,&days,&j);
#else
  slaDtf2d(ihour, imin, sec, &days, &j);
#endif
 OUTPUT:
 days
 j


#  Converts HMS to radians

void
slaDtf2r(ihour, imin, sec, rad, j)
  int ihour
  int imin
  double sec
  double  rad = NO_INIT
  int  j = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dtf2r)(&ihour, &imin, &sec, &rad, &j);
#else
  slaDtf2r(ihour, imin, sec, &rad, &j);
#endif
 OUTPUT:
 rad
 j


void
slaDtp2s(xi, eta, raz, decz, ra, dec)
  double xi
  double eta
  double raz
  double decz
  double ra = NO_INIT
  double dec = NO_INIT
 PROTOTYPE: $$$$$$
 ALIAS:
  slaTp2s = 1
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dtp2s)(&xi, &eta, &raz, &decz, &ra, &dec);
#else
  slaDtp2s(xi, eta, raz, decz, &ra, &dec);
#endif
 OUTPUT:
  ra
  dec


void
slaDtp2v(xi, eta, v0, v)
  double xi
  double eta
  double * v0
  double * v = NO_INIT
 PROTOTYPE: $$\@\@
 ALIAS:
  slaTp2v = 1
 CODE:
  v = get_mortalspace(3, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_dtp2v)(&xi,&eta,v0,v);
#else
  slaDtp2v(xi, eta, v0, v);
#endif
  unpack1D( (SV*)ST(3), (void *)v, 'd', 3);

void
slaDtps2c(xi, eta, ra, dec, raz1, decz1, raz2, decz2, n)
  double xi
  double eta
  double ra
  double dec
  double raz1 = NO_INIT
  double decz1 = NO_INIT
  double raz2 = NO_INIT
  double decz2 = NO_INIT
  int n = NO_INIT
 PROTOTYPE: $$$$$$$$$
 ALIAS:
  slaTps2c = 1
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dtps2c)(&xi, &eta, &ra, &dec, &raz1, &decz1, &raz2, &decz2, &n);
#else
  slaDtps2c(xi, eta, ra, dec, &raz1, &decz1, &raz2, &decz2, &n);
#endif
 OUTPUT:
  raz1
  decz1
  raz2
  decz2
  n

void
slaDtpv2c(xi, eta, v, v01, v02, n)
  double xi
  double eta
  double * v
  double * v01 = NO_INIT
  double * v02 = NO_INIT
  int n = NO_INIT
 PROTOTYPE: $$\@\@\@
 ALIAS:
  slaTpv2c = 1
 CODE:
  v01 = get_mortalspace(3,'d');
  v02 = get_mortalspace(3,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_dtpv2c)(&xi,&eta,v,v01,v02,&n);
#else
  slaDtpv2c(xi, eta, v, v01, v02, &n);
#endif
  unpack1D( (SV*)ST(3), (void *)v01, 'd', 3);
  unpack1D( (SV*)ST(4), (void *)v02, 'd', 3);
 OUTPUT:
  n


double
slaDtt(dju)
  double dju
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_dtt)(&dju);
#else
  RETVAL = slaDtt(dju);
#endif
 OUTPUT:
  RETVAL

void
slaDv2tp(v, v0, xi, eta, j)
  double * v
  double * v0
  double xi = NO_INIT
  double eta = NO_INIT
  int j = NO_INIT
 PROTOTYPE: \@\@$$$
 ALIAS:
  slaV2tp = 1
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_dv2tp)(v,v0,&xi,&eta,&j);
#else
  slaDv2tp(v, v0, &xi, &eta, &j);
#endif
 OUTPUT:
  xi
  eta
  j

double
slaDvdv(va, vb)
  double * va
  double * vb
 PROTOTYPE: \@\@
 ALIAS:
  slaVdv = 1
 CODE:
#ifdef USE_FORTRAN
   RETVAL = TRAIL(sla_dvdv)(va, vb);
#else
   RETVAL = slaDvdv(va, vb);
#endif
 OUTPUT:
  RETVAL

void
slaDvn(v, uv, vm)
  double * v
  double * uv = NO_INIT
  double vm
 PROTOTYPE: \@\@$
 ALIAS:
  slaVn = 1
 CODE:
  uv = get_mortalspace(3,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_dvn)(v, uv, &vm);
#else
  slaDvn(v, uv, &vm);
#endif
  unpack1D( (SV*)ST(1), (void *)uv, 'd', 3);
 OUTPUT:
  vm

void
slaDvxv(va, vb, vc)
  double * va
  double * vb
  double * vc = NO_INIT
 PROTOTYPE: \@\@\@
 ALIAS:
  slaVxv = 1
 CODE:
  vc = get_mortalspace(3,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_dvxv)(va,vb,vc);
#else
  slaDvxv(va,vb,vc);
#endif
  unpack1D( (SV*)ST(2), (void *)vc, 'd', 3);

#### slaE2h - use Double precision


void
slaEarth(iy, id, fd, pv)
  int iy
  int id
  float fd
  float * pv = NO_INIT
 PROTOTYPE: $$$\@
 CODE:
   pv = get_mortalspace(6,'f');
#ifdef USE_FORTRAN
  TRAIL(sla_earth)(&iy,&id,&fd,pv);
#else
   slaEarth(iy, id, fd, pv);
#endif
   unpack1D( (SV*)ST(3), (void *)pv, 'f', 6);

void
slaEcleq(dl, db, date, dr, dd)
  double dl
  double db
  double date
  double dr = NO_INIT
  double dd = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_ecleq)(&dl, &db, &date, &dr, &dd);
#else
  slaEcleq(dl, db, date, &dr, &dd);
#endif
 OUTPUT:
  dr
  dd

void
slaEcmat(date, rmat)
  double date
  double * rmat
 PROTOTYPE: $\@
 CODE:
  rmat = get_mortalspace(9,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_ecmat)(&date,rmat);
#else
  slaEcmat(date, (void*)rmat);
#endif
  unpack1D( (SV*)ST(1), (void *)rmat, 'd', 9);

void
slaEcor(rm, dm, iy, id, fd, rv, tl)
  float rm
  float dm
  int iy
  int id
  float fd
  float rv = NO_INIT
  float tl = NO_INIT
 PROTOTYPE: $$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_ecor)(&rm, &dm, &iy, &id, &fd, &rv, &tl);
#else
  slaEcor(rm, dm, iy, id, fd, &rv, &tl);
#endif
 OUTPUT:
  rv
  tl

void
slaEg50(dr, dd, dl, db)
  double dr
  double dd
  double dl = NO_INIT
  double db = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_eg50)(&dr,&dd,&dl,&db);
#else
   slaEg50(dr, dd, &dl, &db);
#endif
 OUTPUT:
  dl
  db


double
slaEpb(date)
  double date
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_epb)(&date);
#else
  RETVAL = slaEpb(date);
#endif
 OUTPUT:
  RETVAL

double
slaEpb2d(epb)
  double epb
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_epb2d)(&epb);
#else
  RETVAL = slaEpb2d(epb);
#endif
 OUTPUT:
  RETVAL

double
slaEpco(k0, k, e)
  char  k0
  char  k
  double e
 PROTOTYPE: $$$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_epco)(&k0,&k,&e,1,1);
#else
  RETVAL = slaEpco(k0, k, e);
#endif
 OUTPUT:
  RETVAL

double
slaEpj(date)
  double date
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_epj)(&date);
#else
  RETVAL = slaEpj(date);
#endif
 OUTPUT:
  RETVAL


double
slaEpj2d(epj)
  double epj
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_epj2d)(&epj);
#else
  RETVAL = slaEpj2d(epj);
#endif
 OUTPUT:
  RETVAL

void
slaEqecl(dr, dd, date, dl, db)
  double dr
  double dd
  double date
  double dl = NO_INIT
  double db = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_eqecl)(&dr,&dd,&date,&dl,&db);
#else
   slaEqecl(dr, dd, date, &dl, &db);
#endif
 OUTPUT:
  dl
  db

# Equation of the equinoxes

double
slaEqeqx(date)
  double date
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_eqeqx)(&date);
#else
  RETVAL = slaEqeqx(date);
#endif
 OUTPUT:
  RETVAL

void
slaEqgal(dr, dd, dl, db)
  double dr
  double dd
  double dl = NO_INIT
  double db = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_eqgal)(&dr,&dd,&dl,&db);
#else
   slaEqgal(dr, dd, &dl, &db);
#endif
 OUTPUT:
  dl
  db


void
slaEtrms(ep, ev)
  double ep
  double * ev
 PROTOTYPE: $\@
 CODE:
  ev = get_mortalspace(3, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_etrms)(&ep,ev);
#else
  slaEtrms(ep, ev);
#endif
  unpack1D( (SV*)ST(1), (void *)ev, 'd', 3);

#### FLAG:: slaEuler skipped in favcour of double prec version


void
slaEvp(date, deqx, dvb, dpb, dvh, dph)
  double date
  double deqx
  double * dvb = NO_INIT
  double * dpb = NO_INIT
  double * dvh = NO_INIT
  double * dph = NO_INIT
  PROTOTYPE: $$\@\@\@\@
  CODE:
   dvb = get_mortalspace(3,'d');
   dpb = get_mortalspace(3,'d');
   dvh = get_mortalspace(3,'d');
   dph = get_mortalspace(3,'d');
#ifdef USE_FORTRAN
   TRAIL(sla_evp)(&date,&deqx,dvb,dpb,dvh,dph);
#else
   slaEvp(date, deqx, dvb, dpb, dvh, dph);
#endif
   unpack1D( (SV*)ST(2), (void *)dvb, 'd', 3);
   unpack1D( (SV*)ST(3), (void *)dpb, 'd', 3);
   unpack1D( (SV*)ST(4), (void *)dvh, 'd', 3);
   unpack1D( (SV*)ST(5), (void *)dph, 'd', 3);

##### FLAG: Do slaFitxy some other time

void
slaFk425(r1950,d1950,dr1950,dd1950,p1950,v1950,r2000,d2000,dr2000,dd2000,p2000,v2000)
  double r1950
  double d1950
  double dr1950
  double dd1950
  double p1950
  double v1950
  double r2000 = NO_INIT
  double d2000 = NO_INIT
  double dr2000 = NO_INIT
  double dd2000 = NO_INIT
  double p2000 = NO_INIT
  double v2000 = NO_INIT
 PROTOTYPE: $$$$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_fk425)(&r1950,&d1950,&dr1950,&dd1950,&p1950,&v1950,
		   &r2000,&d2000,&dr2000,&dd2000,&p2000,&v2000);
#else
  slaFk425(r1950,d1950,dr1950,dd1950,p1950,v1950,&r2000,&d2000,&dr2000,&dd2000,&p2000,&v2000);
#endif
 OUTPUT:
  r2000
  d2000
  dr2000
  dd2000
  p2000
  v2000




#  B1950 to J2000

void
slaFk45z(r1950, d1950, bepoch, r2000, d2000)
  double r1950
  double d1950
  double bepoch
  double r2000 = NO_INIT
  double d2000 = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_fk45z)(&r1950,&d1950,&bepoch,&r2000,&d2000);
#else
  slaFk45z(r1950, d1950, bepoch, &r2000, &d2000);
#endif
 OUTPUT:
 r2000
 d2000


void
slaFk524(r2000,d2000,dr2000,dd2000,p2000,v2000,r1950,d1950,dr1950,dd1950,p1950,v1950)
  double r2000
  double d2000
  double dr2000
  double dd2000
  double p2000
  double v2000
  double r1950 = NO_INIT
  double d1950 = NO_INIT
  double dr1950 = NO_INIT
  double dd1950 = NO_INIT
  double p1950 = NO_INIT
  double v1950 = NO_INIT
 PROTOTYPE: $$$$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_fk524)(&r2000,&d2000,&dr2000,&dd2000,&p2000,&v2000,
		   &r1950,&d1950,&dr1950,&dd1950,&p1950,&v1950);
#else
  slaFk524(r2000,d2000,dr2000,dd2000,p2000,v2000,
	   &r1950,&d1950,&dr1950,&dd1950,&p1950,&v1950);
#endif
 OUTPUT:
  r1950
  d1950
  dr1950
  dd1950
  p1950
  v1950

void
slaFk54z(r2000, d2000, bepoch, r1950, d1950, dr1950, dd1950)
  double r2000
  double d2000
  double bepoch
  double r1950 = NO_INIT
  double d1950 = NO_INIT
  double dr1950 = NO_INIT
  double dd1950 = NO_INIT
 PROTOTYPE: $$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_fk54z)(&r2000, &d2000, &bepoch, &r1950, &d1950, &dr1950, &dd1950);
#else
  slaFk54z(r2000, d2000, bepoch, &r1950, &d1950, &dr1950, &dd1950);
#endif
 OUTPUT:
 r1950
 d1950
 dr1950
 dd1950


##### FLAG: SKIP slaFloatin - use slaDfltin instead

void
slaGaleq(dl, db, dr, dd)
  double dl
  double db
  double dr = NO_INIT
  double dd = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_galeq)(&dl,&db,&dr,&dd);
#else
   slaGaleq(dl, db, &dr, &dd);
#endif
 OUTPUT:
  dr
  dd


void
slaGalsup(dl, db, dsl, dsb)
  double dl
  double db
  double dsl = NO_INIT
  double dsb = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_galsup)(&dl,&db,&dsl,&dsb);
#else
   slaGalsup(dl, db, &dsl, &dsb);
#endif
 OUTPUT:
  dsl
  dsb

void
slaGe50(dl, db, dr, dd)
  double dl
  double db
  double dr = NO_INIT
  double dd = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_ge50)(&dl,&db,&dr,&dd);
#else
   slaGe50(dl, db, &dr, &dd);
#endif
 OUTPUT:
  dr
  dd


void
slaGeoc(p, h, r, z)
  double p
  double h
  double r = NO_INIT
  double z = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_geoc)(&p,&h,&r,&z);
#else
   slaGeoc(p, h, &r, &z);
#endif
 OUTPUT:
  r
  z


# UT to GMST

double
slaGmst(ut1)
  double ut1
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_gmst)(&ut1);
#else
  RETVAL = slaGmst(ut1);
#endif
 OUTPUT:
  RETVAL


double
slaGmsta(date, ut1)
  double date
  double ut1
 PROTOTYPE: $$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_gmsta)(&date,&ut1);
#else
  RETVAL = slaGmsta(date, ut1);
#endif
 OUTPUT:
  RETVAL


# slaGresid is not in C version

float
slaGresid(s)
  float s
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_gresid)(&s);
#else
  /* RETVAL = slaGresid(s); */
  Perl_croak(aTHX_ "NOT implemented: slaGresid is not implemented in C slalib\n");
#endif
 OUTPUT:
  RETVAL


##### SKIP::  slaH2e use slaDh2e instead

void
slaImxv(rm, va, vb)
  float * rm
  float * va
  float * vb = NO_INIT
 PROTOTYPE: \@\@\@
 CODE:
  vb = get_mortalspace(3,'f');
#ifdef USE_FORTRAN
  TRAIL(sla_imxv)((void*)rm, va, vb);
#else
  slaImxv((void*)rm, va, vb);
#endif
  unpack1D( (SV*)ST(2), (void *)vb, 'f', 3);

##### does perl need slaIntin?

void
slaIntin(string, nstrt, ireslt, jflag)
  char * string
  int nstrt
  long ireslt
  int jflag = NO_INIT
 PROTOTYPE: $$$$
 PREINIT:
  int iresltf;
 CODE:
#ifdef USE_FORTRAN
  /* Note that the fortran interface uses an int not a long */
  iresltf = ireslt;
  TRAIL(sla_intin)(string, &nstrt, &iresltf, &jflag, strlen(string));
  if (jflag != 1) {
    ireslt = iresltf;
  }
#else
  slaIntin(string, &nstrt, &ireslt, &jflag);
#endif
 OUTPUT:
  nstrt
  ireslt
  jflag

void
slaInvf(fwds, bkwds, j)
  double * fwds
  double * bkwds = NO_INIT
  int j = NO_INIT
 PROTOTYPE: \@\@$
 CODE:
  bkwds = get_mortalspace(6,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_invf)(fwds, bkwds, &j);
#else
  slaInvf(fwds, bkwds, &j);
#endif
  unpack1D( (SV*)ST(1), (void *)bkwds, 'd', 6);
 OUTPUT:
  j


void
slaKbj(jb, e, k, j)
  int jb
  double e
  char * k = NO_INIT
  int j = NO_INIT
 PROTOTYPE: $$$$
 PREINIT:
  char string[256];
 CODE:
  k = string;
#ifdef USE_FORTRAN
  TRAIL(sla_kbj)(&jb,&e,k,&j,256);
  stringf77toC(k,256);
#else
  slaKbj(jb, e, k, &j);
#endif
 OUTPUT:
  k
  j


#### SKIP:: slaM2av - use slaDm2av

void
slaMap(rm, dm, pr, pd, px, rv, eq, date, ra, da)
  double rm
  double dm
  double pr
  double pd
  double px
  double rv
  double eq
  double date
  double ra = NO_INIT
  double da = NO_INIT
 PROTOTYPE: $$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_map)(&rm, &dm, &pr, &pd, &px, &rv, &eq, &date, &ra, &da);
#else
  slaMap(rm, dm, pr, pd, px, rv, eq, date, &ra, &da);
#endif
 OUTPUT:
  ra
  da


void
slaMappa(eq, date, amprms)
  double eq
  double date
  double * amprms = NO_INIT
 PROTOTYPE: $$\@
 CODE:
  amprms = get_mortalspace(21, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_mappa)(&eq,&date,amprms);
#else
  slaMappa(eq, date, amprms);
#endif
  unpack1D( (SV*)ST(2), (void *)amprms, 'd', 21);

void
slaMapqk(rm, dm, pr, pd, px, rv, amprms, ra, da)
   double rm
  double dm
  double pr
  double pd
  double px
  double rv
  double * amprms
  double ra = NO_INIT
  double da = NO_INIT
 PROTOTYPE: $$$$$$\@$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_mapqk)(&rm, &dm, &pr, &pd, &px, &rv, amprms, &ra, &da);
#else
  slaMapqk(rm, dm, pr, pd, px, rv, amprms, &ra, &da);
#endif
 OUTPUT:
  ra
  da

void
slaMapqkz(rm, dm, amprms, ra, da)
  double rm
  double dm
  double * amprms
  double ra = NO_INIT
  double da = NO_INIT
 PROTOTYPE: $$\@$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_mapqkz)(&rm, &dm, amprms, &ra, &da);
#else
   slaMapqkz(rm, dm, amprms, &ra, &da);
#endif
 OUTPUT:
  ra
  da


void
slaMoon(iy, id, fd, pv)
  int iy
  int id
  float fd
  float * pv = NO_INIT
 PROTOTYPE: $$$\@
 CODE:
   pv = get_mortalspace(6,'f');
#ifdef USE_FORTRAN
   TRAIL(sla_moon)(&iy,&id,&fd,pv);
#else
   slaMoon(iy, id, fd, pv);
#endif
   unpack1D( (SV*)ST(3), (void *)pv, 'f', 6);


#### FLAG: Miss slaMxm use slaDmxm instead

#### FLAG: Miss slaMxv use slaDmxv instead


void
slaNut(date, rmatn)
  double date
  double * rmatn = NO_INIT
 PROTOTYPE: $\@
 CODE:
  rmatn = get_mortalspace(9, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_nut)(&date,rmatn);
#else
  slaNut(date, (void*)rmatn);
#endif
  unpack1D( (SV*)ST(1), (void *)rmatn, 'd', 9);

void
slaNutc(date, dpsi, deps, eps0)
  double date
  double dpsi = NO_INIT
  double deps = NO_INIT
  double eps0 = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_nutc)(&date, &dpsi, &deps, &eps0);
#else
  slaNutc(date, &dpsi, &deps, &eps0);
#endif
 OUTPUT:
  dpsi
  deps
  eps0

void
slaOap(type, ob1, ob2, date, dut, elongm, phim, hm, xp, yp, tdk, pmb, rh, wl, tlr, rap, dap)
  char * type
  double ob1
  double ob2
  double date
  double dut
  double elongm
  double phim
  double hm
  double xp
  double yp
  double tdk
  double pmb
  double rh
  double wl
  double tlr
  double rap = NO_INIT
  double dap = NO_INIT
 PROTOTYPE: $$$$$$$$$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_oap)(type, &ob1, &ob2, &date, &dut, &elongm, &phim, &hm, &xp,
		  &yp, &tdk, &pmb, &rh, &wl, &tlr, &rap, &dap, strlen(type));
#else
   slaOap(type, ob1, ob2, date, dut, elongm, phim, hm, xp, yp, tdk, pmb, rh, wl, tlr, &rap, &dap);
#endif
 OUTPUT:
  rap
  dap

void
slaOapqk(type, ob1, ob2, aoprms, rap, dap)
  char * type
  double ob1
  double ob2
  double * aoprms
  double rap = NO_INIT
  double dap = NO_INIT
 PROTOTYPE: $$$\@$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_oapqk)(type, &ob1, &ob2, aoprms, &rap, &dap,strlen(type));
#else
  slaOapqk(type, ob1, ob2, aoprms, &rap, &dap);
#endif
 OUTPUT:
  rap
  dap


# If c is undef we need to convert to a blank since slalib
# will generate segmentation violation if it receieves an undef
# value for the string (the strcpy fails for some reason).
# overcome this by providing a wrapper in the .pm file to check
# for this case. Have not got the time to work out a fix at the
# XS level. 'c' can be an input or output variable but must be
# guaranteed to contain a valid pointer to char.
#  slaObs is now defined in the .pm file

# Since "c" can be both input and output depending on the value
# of n the XS routine is explicit and will write the output to
# outc regardless of inc. We do this to allow slaObs to be called
# with constants that can not handle always being modified in the
# simple XS {could use PPCODE but the multivar approach is easier
# since there are many return values that would need to be specified.)

void
_slaObs(n, inc, outc, name, w, p, h)
  int n
  char * inc
  char * outc = NO_INIT
  char * name = NO_INIT
  double w = NO_INIT
  double p = NO_INIT
  double h = NO_INIT
 PROTOTYPE: $$$$$$$
 PREINIT:
  int  name_len = 40;
  int  code_len = 11;
  char string[name_len];
  char * c;
  char code[code_len];
  char tempc[code_len];
 CODE:
  name = string;
  outc = code;
  outc[0] = '\0';

  /* If n is greater than 1 we need to write the output
     to outc. If n is less than 1 we can be readonly and just
     use inc.
  */
  if (n < 1) {
    /* read from inc. Length must be calculated for Fortran */
    c = inc;
    code_len = strlen(c);
  } else {
    /* write into outc directly. We know the length */
    c = outc;
  }
#ifdef USE_FORTRAN
  /* copy the input code [if any] to temp variable */
  myCnfExprt(c,tempc,code_len);
  TRAIL(sla_obs)(&n,tempc,name,&w,&p,&h,code_len,name_len);
  stringf77toC(name,name_len);
  if (n>0) {
    /* Need to C-ify the string if we were expecting a reply */
    outc = tempc;
    stringf77toC(outc,code_len);
  }
#else
  slaObs(n, c, name, &w, &p, &h);
#endif
 OUTPUT:
  outc
  name
  w
  p
  h


double
slaPa(ha, dec, phi)
  double ha
  double dec
  double phi
 PROTOTYPE: $$$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_pa)(&ha, &dec, &phi);
#else
  RETVAL = slaPa(ha, dec, phi);
#endif
 OUTPUT:
  RETVAL


#### SKIP: slaPav use slaDpav instead (is alias).

void
slaPcd(disco, x, y)
  double disco
  double x
  double y
 PROTOTYPE: $$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_pcd)(&disco, &x, &y);
#else
  slaPcd(disco, &x, &y);
#endif
 OUTPUT:
  x
  y


void
slaPda2h(p, d, a, h1, j1, h2, j2)
  double p
  double d
  double a
  double h1  = NO_INIT
  int j1 = NO_INIT
  double h2 = NO_INIT
  int j2 = NO_INIT
 PROTOTYPE: $$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_pda2h)(&p, &d, &a, &h1, &j1, &h2, &j2);
#else
  slaPda2h(p, d, a, &h1, &j1, &h2, &j2);
#endif
 OUTPUT:
  h1
  j1
  h2
  j2


void
slaPdq2h(p, d, q, h1, j1, h2, j2)
  double p
  double d
  double q
  double h1  = NO_INIT
  int j1 = NO_INIT
  double h2 = NO_INIT
  int j2 = NO_INIT
 PROTOTYPE: $$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_pdq2h)(&p, &d, &q, &h1, &j1, &h2, &j2);
#else
  slaPdq2h(p, d, q, &h1, &j1, &h2, &j2);
#endif
 OUTPUT:
  h1
  j1
  h2
  j2

void
slaPertel(jform,date0,date1,epoch0,orbi0,anode0,perih0,aorq0,e0,am0,epoch1,orbi1,anode1,perih1,aorq1,e1,am1,jstat)
  int jform
  double date0
  double date1
  double epoch0
  double orbi0
  double anode0
  double perih0
  double aorq0
  double e0
  double am0
  double epoch1 = NO_INIT
  double orbi1 = NO_INIT
  double anode1 = NO_INIT
  double perih1 = NO_INIT
  double aorq1 = NO_INIT
  double e1 = NO_INIT
  double am1 = NO_INIT
  int    jstat = NO_INIT
 PROTOTYPE: $$$$$$$$$$$$$$$$$$
 CODE:
  jstat = 0;
#ifdef USE_FORTRAN
  TRAIL(sla_pertel)(&jform,&date0,&date1,&epoch0,&orbi0,&anode0,&perih0,
		    &aorq0,&e0,&am0,&epoch1,&orbi1,&anode1,&perih1,
		    &aorq1,&e1,&am1,&jstat);
#else
  slaPertel(jform,date0,date1,epoch0,orbi0,anode0,perih0,aorq0,e0,am0,
	    &epoch1,&orbi1,&anode1,&perih1,&aorq1,&e1,&am1,&jstat);
#endif
 OUTPUT:
  epoch1
  orbi1
  anode1
  perih1
  aorq1
  e1
  am1
  jstat

void
slaPertue(date,u,jstat)
  double date
  double * u
  int    jstat = NO_INIT
 PROTOTYPE: $\@$
 CODE:
  jstat = 0;
#ifdef USE_FORTRAN
  TRAIL(sla_pertue)(&date,u,&jstat);
#else
  slaPertue(date,u,&jstat);
#endif
  unpack1D( (SV*)ST(1), (void *)u, 'd', 13);
 OUTPUT:
  jstat


void
slaPlanel(date, jform, epoch, orbinc, anode, perih, aorq, e, aorl, dm, pv, jstat)
  double date
  int jform
  double epoch
  double orbinc
  double anode
  double perih
  double aorq
  double e
  double aorl
  double dm
  double * pv = NO_INIT
  int jstat = NO_INIT
 PROTOTYPE: $$$$$$$$$$\@$
 CODE:
  pv = get_mortalspace(6, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_planel)(&date, &jform, &epoch, &orbinc, &anode, &perih, &aorq, &e,
		    &aorl, &dm, pv, &jstat);
#else
  slaPlanel(date, jform, epoch, orbinc, anode, perih, aorq, e, aorl, dm, pv, &jstat);
#endif
  unpack1D( (SV*)ST(10), (void *)pv, 'd', 6);
 OUTPUT:
  jstat

void
slaPlanet(date, np, pv, jstat)
  double date
  int np
  double * pv = NO_INIT
  int jstat = NO_INIT
 PROTOTYPE: $$\@$
 CODE:
   pv = get_mortalspace(6, 'd');
#ifdef USE_FORTRAN
   TRAIL(sla_planet)(&date, &np, pv, &jstat);
#else
   slaPlanet(date, np, pv, &jstat);
#endif
   unpack1D( (SV*)ST(2), (void *)pv, 'd', 6);
 OUTPUT:
  jstat

void
slaPlante(date, elong, phi, jform, epoch, orbinc, anode, perih, aorq,e, aorl, dm, ra,dec, r, jstat)
  double date
  double elong
  double phi
  int jform
  double epoch
  double orbinc
  double anode
  double perih
  double aorq
  double e
  double aorl
  double dm
  double ra = NO_INIT
  double dec = NO_INIT
  double r = NO_INIT
  int jstat = NO_INIT
 PROTOTYPE: $$$$$$$$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_plante)(&date, &elong, &phi, &jform, &epoch, &orbinc, &anode,
		    &perih, &aorq,&e, &aorl, &dm, &ra, &dec, &r, &jstat);
#else
  slaPlante(date, elong, phi, jform, epoch, orbinc, anode, perih, aorq,e, aorl, dm, &ra, &dec, &r, &jstat);
#endif
 OUTPUT:
  ra
  dec
  r
  jstat


void
slaPm(r0,d0,pr,pd,px,rv,ep0,ep1,r1,d1)
  double r0
  double d0
  double pr
  double pd
  double px
  double rv
  double ep0
  double ep1
  double r1 = NO_INIT
  double d1 = NO_INIT
 PROTOTYPE: $$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_pm)(&r0,&d0,&pr,&pd,&px,&rv,&ep0,&ep1,&r1,&d1);
#else
  slaPm(r0,d0,pr,pd,px,rv,ep0,ep1,&r1,&d1);
#endif
 OUTPUT:
  r1
  d1


void
slaPolmo(elongm, phim, xp, yp, elong, phi, daz)
  double elongm
  double phim
  double xp
  double yp
  double elong = NO_INIT
  double phi = NO_INIT
  double daz = NO_INIT
 PROTOTYPE: $$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_polmo)(&elongm, &phim, &xp, &yp, &elong, &phi, &daz);
#else
  slaPolmo(elongm, phim, xp, yp, &elong, &phi, &daz);
#endif
 OUTPUT:
  elong
  phi
  daz


##### Problem with slaPrebn - dont know the return args
# Think it is (3,3) - see slaPrec
void
slaPrebn(bep0, bep1, rmatp)
  double bep0
  double bep1
  double * rmatp
 PROTOTYPE: $$\@
 CODE:
  rmatp = get_mortalspace(9,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_prebn)(&bep0,&bep1,rmatp);
#else
  slaPrebn(bep0, bep1, (void*)rmatp);
#endif
  unpack1D( (SV*)ST(2), (void *)rmatp, 'd', 9);

void
slaPrec(ep0, ep1, rmatp)
  double ep0
  double ep1
  double * rmatp
 PROTOTYPE: $$\@
 CODE:
  rmatp = get_mortalspace(9,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_prec)(&ep0, &ep1, rmatp);
#else
  slaPrec(ep0, ep1, (void*)rmatp);
#endif
  unpack1D( (SV*)ST(2), (void *)rmatp, 'd', 9);

# Precession

void
slaPreces(system, ep0, ep1, ra, dc)
  char *system
  double ep0
  double ep1
  double ra
  double dc
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_preces)(system,&ep0,&ep1,&ra,&dc,strlen(system));
#else
  slaPreces(system, ep0, ep1, &ra, &dc);
#endif
 OUTPUT:
 ra
 dc


void
slaPrecl(ep0, ep1, rmatp)
  double ep0
  double ep1
  double * rmatp
 PROTOTYPE: $$\@
 CODE:
  rmatp = get_mortalspace(9,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_precl)(&ep0, &ep1, rmatp);
#else
  slaPrecl(ep0, ep1, (void*)rmatp);
#endif
  unpack1D( (SV*)ST(2), (void *)rmatp, 'd', 9);

void
slaPrenut(epoch, date, rmatpn)
  double epoch
  double date
  double * rmatpn
 PROTOTYPE: $$\@
 CODE:
  rmatpn = get_mortalspace(9,'d');
#ifdef USE_FORTRAN
  TRAIL(sla_prenut)(&epoch, &date, rmatpn);
#else
  slaPrenut(epoch, date, (void*)rmatpn);
#endif
  unpack1D( (SV*)ST(2), (void *)rmatpn, 'd', 9);

void
slaPvobs(p, h, stl, pv)
  double p
  double h
  double stl
  double * pv = NO_INIT
 PROTOTYPE: $$$\@
 CODE:
   pv = get_mortalspace(6, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_pvobs)(&p,&h,&stl,pv);
#else
   slaPvobs(p, h, stl, pv);
#endif
   unpack1D( (SV*)ST(3), (void *)pv, 'd', 6);


###### Skip slaPxy - do later


##### slaRandom is not implemented in C version
float
slaRandom(seed)
  float seed
 PROTOTYPE: $
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_random)(&seed);
#else
  /* RETVAL = slaRandom(&seed); */
  Perl_croak(aTHX_ "NOT implemented: slaRandom is not implemented in C slalib\n");
#endif
 OUTPUT:
  RETVAL
  seed

##### Skip: slaRange - use slaDrange
##### Skip: slaRanorm  use slaDranrm


double
slaRcc(tdb, ut1, wl, u, v)
  double tdb
  double ut1
  double wl
  double u
  double v
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_rcc)(&tdb,&ut1,&wl,&u,&v);
#else
  RETVAL = slaRcc(tdb, ut1, wl, u, v);
#endif
 OUTPUT:
  RETVAL


void
slaRdplan(date, np, elong, phi, ra, dec, diam)
  double date
  int np
  double elong
  double phi
  double ra = NO_INIT
  double dec = NO_INIT
  double diam = NO_INIT
 PROTOTYPE: $$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_rdplan)(&date, &np, &elong, &phi, &ra, &dec, &diam);
#else
  slaRdplan(date, np, elong, phi, &ra, &dec, &diam);
#endif
 OUTPUT:
  ra
  dec
  diam


void
slaRefco(hm, tdk, pmb, rh, wl, phi, tlr, eps, refa, refb)
  double hm
  double tdk
  double pmb
  double rh
  double wl
  double phi
  double tlr
  double eps
  double refa = NO_INIT
  double refb = NO_INIT
 PROTOTYPE: $$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_refco)(&hm, &tdk, &pmb, &rh, &wl, &phi, &tlr, &eps, &refa, &refb);
#else
  slaRefco(hm, tdk, pmb, rh, wl, phi, tlr, eps, &refa, &refb);
#endif
 OUTPUT:
  refa
  refb

void
slaRefcoq(tdk, pmb, rh, wl, refa, refb)
  double tdk
  double pmb
  double rh
  double wl
  double refa = NO_INIT
  double refb = NO_INIT
 PROTOTYPE: $$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_refcoq)(&tdk, &pmb, &rh, &wl, &refa, &refb);
#else
  slaRefcoq(tdk, pmb, rh, wl, &refa, &refb);
#endif
 OUTPUT:
  refa
  refb



void
slaRefro(zobs, hm, tdk, pmb, rh, wl, phi, tlr, eps, ref)
  double zobs
  double hm
  double tdk
  double pmb
  double rh
  double wl
  double phi
  double tlr
  double eps
  double ref = NO_INIT
 PROTOTYPE: $$$$$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_refro)(&zobs, &hm, &tdk, &pmb, &rh, &wl, &phi, &tlr, &eps, &ref);
#else
  slaRefro(zobs, hm, tdk, pmb, rh, wl, phi, tlr, eps, &ref);
#endif
 OUTPUT:
  ref

void
slaRefv(vu, refa, refb, vr)
  double * vu
  double refa
  double refb
  double * vr = NO_INIT
 PROTOTYPE:  \@$$\@
 CODE:
  vr = get_mortalspace(3, 'd');
#ifdef USE_FORTRAN
  TRAIL(sla_refv)(vu, &refa, &refb, vr);
#else
  slaRefv(vu, refa, refb, vr);
#endif
  unpack1D( (SV*)ST(3), (void *)vr, 'd', 3);

void
slaRefz(zu, refa, refb, zr)
  double zu
  double refa
  double refb
  double zr = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_refz)(&zu, &refa, &refb, &zr);
#else
   slaRefz(zu, refa, refb, &zr);
#endif
 OUTPUT:
  zr


float
slaRverot(phi, ra, da, st)
  float phi
  float ra
  float da
  float st
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_rverot)(&phi,&ra,&da,&st);
#else
  RETVAL = slaRverot(phi, ra, da, st);
#endif
 OUTPUT:
  RETVAL


float
slaRvgalc(r2000, d2000)
  float r2000
  float d2000
 PROTOTYPE: $$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_rvgalc)(&r2000,&d2000);
#else
  RETVAL = slaRvgalc(r2000, d2000);
#endif
 OUTPUT:
  RETVAL

float
slaRvlg(r2000, d2000)
  float r2000
  float d2000
 PROTOTYPE: $$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_rvlg)(&r2000,&d2000);
#else
  RETVAL = slaRvlg(r2000, d2000);
#endif
 OUTPUT:
  RETVAL


float
slaRvlsrd(r2000, d2000)
  float r2000
  float d2000
 PROTOTYPE: $$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_rvlsrd)(&r2000,&d2000);
#else
  RETVAL = slaRvlsrd(r2000, d2000);
#endif
 OUTPUT:
  RETVAL

float
slaRvlsrk(r2000, d2000)
  float r2000
  float d2000
 PROTOTYPE: $$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_rvlsrk)(&r2000,&d2000);
#else
  RETVAL = slaRvlsrk(r2000, d2000);
#endif
 OUTPUT:
  RETVAL

void
slaS2tp(ra, dec, raz, decz, xi, eta, j)
  float ra
  float dec
  float raz
  float decz
  float xi = NO_INIT
  float eta = NO_INIT
  int   j = NO_INIT
 PROTOTYPE: $$$$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_s2tp)(&ra, &dec, &raz, &decz, &xi, &eta, &j);
#else
  slaS2tp(ra, dec, raz, decz, &xi, &eta, &j);
#endif
 OUTPUT:
  xi
  eta
  j

###### SKIP slaSep - use SlaDsep instead

###### Skip slaSmat

void
slaSubet(rc, dc, eq, rm, dm)
  double rc
  double dc
  double eq
  double rm = NO_INIT
  double dm = NO_INIT
 PROTOTYPE: $$$$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_subet)(&rc, &dc, &eq, &rm, &dm);
#else
  slaSubet(rc, dc, eq, &rm, &dm);
#endif
 OUTPUT:
  rm
  dm

void
slaSupgal(dsl, dsb, dl, db)
  double dsl
  double dsb
  double dl = NO_INIT
  double db = NO_INIT
 PROTOTYPE: $$$$
 CODE:
#ifdef USE_FORTRAN
   TRAIL(sla_supgal)(&dsl,&dsb,&dl,&db);
#else
   slaSupgal(dsl, dsb, &dl, &db);
#endif
 OUTPUT:
  dl
  db


##### SDkip slaSVD

###### Skip slaSvdcov

###### Skip slaSvdsol

##### Skip slaTp2s - use slaDtp2s
##### Skip slaTp2v - use slaDtp2v
##### Skip slaTps2c - use slaDtps2c
##### Skip slaTpv2c - use slaDtpv2c

void
slaUnpcd(disco, x, y)
  double disco
  double x
  double y
 PROTOTYPE: $$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_unpcd)(&disco, &x, &y);
#else
  slaUnpcd(disco, &x, &y);
#endif
 OUTPUT:
  x
  y


##### Skip slaV2tp - use slaDv2tp
##### Skip slaVdv - use slaDvdv
##### Skip slaVn - use slaDvn
##### Skip slaVxv - use slaDvxv

# slaWait Not in C library -- implemented in perl via select()

##### Skip slaXy2xy for now

void
slaXy2xy(x1, y1, coeffs, x2, y2)
  double x1
  double y1
  double * coeffs
  double x2 = NO_INIT
  double y2 = NO_INIT
 PROTOTYPE: $$\@$$
 CODE:
#ifdef USE_FORTRAN
  TRAIL(sla_xy2xy)(&x1, &y1, coeffs, &x2, &y2);
#else
  slaXy2xy(x1, y1, coeffs, &x2, &y2);
#endif
 OUTPUT:
  x2
  y2


double
slaZd(ha, dec, phi)
  double ha
  double dec
  double phi
 PROTOTYPE: $$$
 CODE:
#ifdef USE_FORTRAN
  RETVAL = TRAIL(sla_zd)(&ha, &dec, &phi);
#else
  RETVAL = slaZd(ha, dec, phi);
#endif
 OUTPUT:
  RETVAL
