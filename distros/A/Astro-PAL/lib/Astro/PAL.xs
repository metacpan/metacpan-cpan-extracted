/*        -*- C -*-

  perl-PAL glue
                                        t.jenness@jach.hawaii.edu

  Copyright (C) 2012, 2014 Tim Jenness.  All rights reserved.

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3 of
  the License, or (at your option) any later version.

  This program is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY; without even the implied
  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
  USA.

  PAL does not have the single precision SLA variants.

 */


#include "EXTERN.h"   /* std perl include */
#include "perl.h"     /* std perl include */
#include "XSUB.h"     /* XSUB include */


#include "pal.h"
#include "arrays.h"

/* macros to return C arrays of fixed size to list on stack */

#define RETMATRIX(rmat) {				\
    int ii;						\
    for (ii=0; ii<3; ii++) {				\
      int jj;						\
      for (jj=0; jj<3; jj++) {				\
	XPUSHs(sv_2mortal(newSVnv(rmat[ii][jj])));	\
      }							\
    }							\
  }

/* type is "nv" for floats and "iv" for ints */

#define RETVEC(vec,n,type) {			\
    int ii;					\
    for (ii=0; ii<n; ii++) {			\
      XPUSHs(sv_2mortal(newSV##type(vec[ii])));	\
    }						\
  }

/* Copy 9 element vector to 3x3 matrix */

#define VECTOMAT(vec,mat) {				\
    int ii;						\
    for (ii=0; ii<3; ii++) {				\
      int jj;						\
      for (jj=0; jj<3; jj++) {				\
	mat[ii][jj] = vec[ii*3+jj];			\
      }							\
    }							\
  }



MODULE = Astro::PAL   PACKAGE = Astro::PAL


# Add a few routines

void
palAddet(rm, dm, eq)
  double rm
  double dm
  double eq
 PREINIT:
  double rc;
  double dc;
 PPCODE:
  palAddet(rm, dm, eq, &rc, &dc);
  XPUSHs(sv_2mortal(newSVnv(rc)));
  XPUSHs(sv_2mortal(newSVnv(dc)));

double
palAirmas(zd)
  double zd
 CODE:
  RETVAL = palAirmas(zd);
 OUTPUT:
  RETVAL

void
palAmp(ra, da, date, eq)
  double ra
  double da
  double date
  double eq
 PREINIT:
  double rm;
  double dm;
 PPCODE:
  palAmp(ra, da, date, eq, &rm, &dm);
  XPUSHs(sv_2mortal(newSVnv(rm)));
  XPUSHs(sv_2mortal(newSVnv(dm)));


# FLAG: Need to add a check for number of components in amprms

void
palAmpqk(ra, da, amprms)
  double ra
  double da
  double * amprms
 PREINIT:
  double rm;
  double dm;
 PPCODE:
  palAmpqk(ra, da, amprms, &rm, &dm);
  XPUSHs(sv_2mortal(newSVnv(rm)));
  XPUSHs(sv_2mortal(newSVnv(dm)));

void
palAop(rap,dap,date,dut,elongm,phim,hm,xp,yp,tdk,pmb,rh,wl,tlr)
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
 PREINIT:
  double aob;
  double zob;
  double hob;
  double dob;
  double rob;
 PPCODE:
  palAop(rap,dap,date,dut,elongm,phim,hm,xp,yp,tdk,pmb,rh,wl,tlr,&aob,&zob,&hob,&dob,&rob);
  XPUSHs(sv_2mortal(newSVnv(aob)));
  XPUSHs(sv_2mortal(newSVnv(zob)));
  XPUSHs(sv_2mortal(newSVnv(hob)));
  XPUSHs(sv_2mortal(newSVnv(dob)));
  XPUSHs(sv_2mortal(newSVnv(rob)));

void
palAoppa(date,dut,elongm,phim,hm,xp,yp,tdk,pmb,rh,wl,tlr)
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
 PREINIT:
  double aoprms[14];
  int i;
 PPCODE:
  palAoppa(date,dut,elongm,phim,hm,xp,yp,tdk,pmb,rh,wl,tlr,aoprms);
  RETVEC( aoprms, 14, nv );

# Documented to update element 13 of AOPRMS by using
# the information in element 12. To make things easy in the XS
# layer we do all this on the perl side and just pass the
# relevant information in.

void
pal_Aoppat(date, elem12)
  double date
  double elem12
 PREINIT:
  double aoprms[14];
  int i;
 PPCODE:
  aoprms[12] = elem12;
  palAoppat(date, aoprms);
  XPUSHs(sv_2mortal(newSVnv(aoprms[13])));

void
pal_Aopqk(rap, dap, aoprms)
  double rap
  double dap
  double * aoprms
 PREINIT:
  double aob;
  double zob;
  double hob;
  double dob;
  double rob;
 PPCODE:
  palAopqk(rap, dap, aoprms, &aob,&zob,&hob,&dob,&rob);
  XPUSHs(sv_2mortal(newSVnv(aob)));
  XPUSHs(sv_2mortal(newSVnv(zob)));
  XPUSHs(sv_2mortal(newSVnv(hob)));
  XPUSHs(sv_2mortal(newSVnv(dob)));
  XPUSHs(sv_2mortal(newSVnv(rob)));

void
palAtmdsp(tdk, pmb, rh, wl1, a1, b1, wl2)
  double tdk
  double pmb
  double rh
  double wl1
  double a1
  double b1
  double wl2
 PREINIT:
  double a2;
  double b2;
 PPCODE:
  palAtmdsp(tdk, pmb, rh, wl1, a1, b1, wl2, &a2, &b2);
  XPUSHs(sv_2mortal(newSVnv(a2)));
  XPUSHs(sv_2mortal(newSVnv(b2)));

void
palCaldj(iy, im, id)
  int iy
  int im
  int id
 PREINIT:
  double djm;
  int j;
 PPCODE:
  palCaldj(iy, im, id, &djm, &j);
  XPUSHs(sv_2mortal(newSVnv(djm)));
  XPUSHs(sv_2mortal(newSViv(j)));

void
palCldj(iy, im, id)
  int iy
  int im
  int id
 PREINIT:
  double djm;
  int status;
 PPCODE:
  palCldj(iy, im, id, &djm, &status);
  XPUSHs(sv_2mortal(newSVnv(djm)));
  XPUSHs(sv_2mortal(newSViv(status)));

void
palDaf2r(ideg, iamin, asec)
  int ideg
  int iamin
  double asec
 PREINIT:
  double rad;
  int j;
 PPCODE:
  palDaf2r(ideg, iamin, asec, &rad, &j);
  XPUSHs(sv_2mortal(newSVnv(rad)));
  XPUSHs(sv_2mortal(newSViv(j)));

# Note that nstrt is given but also returned
# We return it as a new value rather than modifying in place.
# (nstrt, dreslt, jf) = palDafin( string, nstrt )

void
palDafin(string, nstrt)
  char * string
  int nstrt
 PREINIT:
  double dreslt;
  int jf;
 PPCODE:
  palDafin(string, &nstrt, &dreslt, &jf);
  XPUSHs(sv_2mortal(newSViv(nstrt)));
  XPUSHs(sv_2mortal(newSVnv(dreslt)));
  XPUSHs(sv_2mortal(newSViv(jf)));

double
palDat(utc)
  double utc
 CODE:
  RETVAL = palDat(utc);
 OUTPUT:
  RETVAL


# Return the 9 elements directly so they can be
# captured in an array
#  @rmat = palDav2m( axvec );

void
palDav2m(axvec)
  double * axvec
 PREINIT:
  int i,j;
  double rmat[3][3];
 PPCODE:
  palDav2m(axvec, rmat);
  RETMATRIX(rmat);

double
palDbear(a1, b1, a2, b2)
  double a1
  double b1
  double a2
  double b2
 CODE:
  RETVAL = palDbear(a1, b1, a2, b2);
 OUTPUT:
  RETVAL

void
palDcc2s(v)
  double * v
 PREINIT:
  double a;
  double b;
 PPCODE:
  palDcc2s(v, &a, &b);
  XPUSHs(sv_2mortal(newSVnv(a)));
  XPUSHs(sv_2mortal(newSVnv(b)));


# Returns a list for v[3]

void
palDcs2c(a, b)
  double a
  double b
 PREINIT:
  double v[3];
 PPCODE:
  palDcs2c(a, b, v);
  RETVEC( v, 3, nv );

#   Converts decimal day to hours minutes and seconds

void
palDd2tf(ndp, days)
  int ndp
  double  days
 PREINIT:
  char sign;
  int ihmsf[4];
 PPCODE:
  palDd2tf(ndp, days, &sign, ihmsf);
  XPUSHs(sv_2mortal(newSVpvn(&sign, 1)));
  RETVEC( ihmsf, 4, iv );

# Equatorial to horizontal

void
palDe2h(ha, dec, phi)
  double ha
  double dec
  double phi
 PREINIT:
  double az;
  double el;
 PPCODE:
  palDe2h(ha, dec, phi, &az, &el);
  XPUSHs(sv_2mortal(newSVnv(az)));
  XPUSHs(sv_2mortal(newSVnv(el)));

# Returns 9 elements directly on stack

void
palDeuler(order, phi, theta, psi)
  char * order
  double phi
  double theta
  double psi
 PREINIT:
  double rmat[3][3];
 PPCODE:
  palDeuler(order, phi, theta, psi, rmat);
  RETMATRIX(rmat);

# Note that nstrt is given and then returned on the stack

void
palDfltin(string, nstrt)
  char * string
  int nstrt
 PREINIT:
  double dreslt;
  int jflag;
 PPCODE:
  palDfltin(string, &nstrt, &dreslt, &jflag);
  XPUSHs(sv_2mortal(newSViv(nstrt)));
  XPUSHs(sv_2mortal(newSVnv(dreslt)));
  XPUSHs(sv_2mortal(newSViv(jflag)));

# Horizontal to equatorial

void
palDh2e(az, el, phi)
  double az
  double el
  double phi
 PREINIT:
  double ha;
  double dec;
 PPCODE:
  palDh2e(az, el, phi, &ha, &dec);
  XPUSHs(sv_2mortal(newSVnv(ha)));
  XPUSHs(sv_2mortal(newSVnv(dec)));

# Returned 3-vector on stack

void
palDimxv(dm, va)
  double * dm
  double * va
 PREINIT:
  double vb[3];
  double rmat[3][3];
  int i;
 PPCODE:
  VECTOMAT( dm, rmat );
  palDimxv(rmat, va, vb);
  RETVEC( vb, 3, nv );

# Note that we return j on the stack first

void
palDjcal(ndp, djm)
  int ndp
  double djm
 PREINIT:
  int iymdf[4];
  int j;
 PPCODE:
  palDjcal(ndp, djm, iymdf, &j);
  XPUSHs(sv_2mortal(newSViv(j)));
  RETVEC(iymdf, 4, iv);

# MJD to UT

void
palDjcl(mjd)
  double mjd
 PREINIT:
  int iy;
  int im;
  int id;
  double fd;
  int j;
 PPCODE:
  palDjcl(mjd, &iy, &im, &id, &fd, &j);
  XPUSHs(sv_2mortal(newSViv(iy)));
  XPUSHs(sv_2mortal(newSViv(im)));
  XPUSHs(sv_2mortal(newSViv(id)));
  XPUSHs(sv_2mortal(newSVnv(fd)));
  XPUSHs(sv_2mortal(newSViv(j)));

void
palDm2av(rmatv)
  double * rmatv
 PREINIT:
  double rmat[3][3];
  double axvec[3];
 PPCODE:
  VECTOMAT( rmatv, rmat );
  palDm2av( rmat, axvec);
  RETVEC( axvec, 3, nv );


###### FLAG:   Do palDmat at the end

void
palDmoon(date)
  double date
 PREINIT:
  double pv[6];
 PPCODE:
  palDmoon(date, pv);
  RETVEC( pv, 6, nv );

#### FLAG : Matrix manipulation should be using PDLs

void
palDmxm(a, b)
  double * a
  double * b
 PREINIT:
  double amat[3][3];
  double bmat[3][3];
  double cmat[3][3];
 PPCODE:
  VECTOMAT( a, amat );
  VECTOMAT( b, bmat );
  palDmxm(amat,bmat,cmat);
  RETMATRIX(cmat);

void
palDmxv(dm, va)
  double * dm
  double * va
 PREINIT:
  double dmat[3][3];
  double vb[3];
 PPCODE:
  VECTOMAT( dm, dmat );
  palDmxv(dmat, va, vb);
  RETVEC( vb, 3, nv );

double
palDpav(v1, v2)
  double * v1
  double * v2
 CODE:
  RETVAL = palDpav(v1, v2);
 OUTPUT:
  RETVAL

#   Converts radians to DMS

void
palDr2af(ndp, angle)
  int ndp
  double angle
 PREINIT:
  char sign;
  int idmsf[4];
 PPCODE:
  palDr2af(ndp, angle, &sign, idmsf);
  XPUSHs(sv_2mortal(newSVpvn(&sign, 1)));
  RETVEC( idmsf, 4, iv );

#   Converts radians to HMS

void
palDr2tf(ndp, angle)
  int ndp
  double angle
 PREINIT:
  char sign;
  int ihmsf[4];
 PPCODE:
  palDr2tf(ndp, angle, &sign, ihmsf);
  XPUSHs(sv_2mortal(newSVpvn(&sign, 1)));
  RETVEC( ihmsf, 4, iv );

double
palDrange(angle)
  double angle
 CODE:
  RETVAL = palDrange(angle);
 OUTPUT:
  RETVAL

double
palDranrm(angle)
  double angle
 CODE:
  RETVAL = palDranrm(angle);
 OUTPUT:
  RETVAL

void
palDs2tp(ra, dec, raz, decz)
  double ra
  double dec
  double raz
  double decz
 PREINIT:
  double xi;
  double eta;
  int j;
 PPCODE:
  palDs2tp(ra, dec, raz, decz, &xi, &eta, &j);
  XPUSHs(sv_2mortal(newSVnv(xi)));
  XPUSHs(sv_2mortal(newSVnv(eta)));
  XPUSHs(sv_2mortal(newSViv(j)));

double
palDsep(a1, b1, a2, b2)
  double a1
  double b1
  double a2
  double b2
 CODE:
  RETVAL = palDsep(a1, b1, a2, b2);
 OUTPUT:
  RETVAL

double
palDsepv( v1, v2 )
  double * v1
  double * v2
 CODE:
  RETVAL = palDsepv( v1, v2 );
 OUTPUT:
  RETVAL

double
palDt(epoch)
  double epoch
 CODE:
  RETVAL = palDt(epoch);
 OUTPUT:
  RETVAL

void
palDtf2d(ihour, imin, sec)
  int ihour
  int imin
  double sec
 PREINIT:
  double days;
  int j;
 PPCODE:
  palDtf2d(ihour, imin, sec, &days, &j);
  XPUSHs(sv_2mortal(newSVnv(days)));
  XPUSHs(sv_2mortal(newSViv(j)));

#  Converts HMS to radians

void
palDtf2r(ihour, imin, sec)
  int ihour
  int imin
  double sec
 PREINIT:
  double rad;
  int j;
 PPCODE:
  palDtf2r(ihour, imin, sec, &rad, &j);
  XPUSHs(sv_2mortal(newSVnv(rad)));
  XPUSHs(sv_2mortal(newSViv(j)));


void
palDtp2s(xi, eta, raz, decz)
  double xi
  double eta
  double raz
  double decz
 PREINIT:
  double ra;
  double dec;
 PPCODE:
  palDtp2s(xi, eta, raz, decz, &ra, &dec);
  XPUSHs(sv_2mortal(newSVnv(ra)));
  XPUSHs(sv_2mortal(newSVnv(dec)));

void
palDtps2c(xi, eta, ra, dec)
  double xi
  double eta
  double ra
  double dec
 PREINIT:
  double raz1;
  double decz1;
  double raz2;
  double decz2;
  int n;
 PPCODE:
  palDtps2c(xi, eta, ra, dec, &raz1, &decz1, &raz2, &decz2, &n);
  XPUSHs(sv_2mortal(newSVnv(raz1)));
  XPUSHs(sv_2mortal(newSVnv(decz1)));
  XPUSHs(sv_2mortal(newSVnv(raz2)));
  XPUSHs(sv_2mortal(newSVnv(decz2)));
  XPUSHs(sv_2mortal(newSVnv(n)));

double
palDtt(dju)
  double dju
 CODE:
  RETVAL = palDtt(dju);
 OUTPUT:
  RETVAL

double
palDvdv(va, vb)
  double * va
  double * vb
 CODE:
   RETVAL = palDvdv(va, vb);
 OUTPUT:
  RETVAL

# vm is returned on the stack first

void
palDvn(v)
  double * v
 PREINIT:
  double uv[3];
  double vm;
 PPCODE:
  palDvn(v, uv, &vm);
  XPUSHs(sv_2mortal(newSVnv(vm)));
  RETVEC(uv, 3, nv );

void
palDvxv(va, vb)
  double * va
  double * vb
 PREINIT:
  double vc[3];
 PPCODE:
  palDvxv(va,vb,vc);
  RETVEC(vc, 3, nv );

void
palEcmat(date)
  double date
 PREINIT:
  double rmat[3][3];
 PPCODE:
  palEcmat(date, rmat);
  RETMATRIX(rmat);

# TODO: palEl2ue goes here


double
palEpb(date)
  double date
 CODE:
  RETVAL = palEpb(date);
 OUTPUT:
  RETVAL

double
palEpb2d(epb)
  double epb
 CODE:
  RETVAL = palEpb2d(epb);
 OUTPUT:
  RETVAL

double
palEpco(k0, k, e)
  char  k0
  char  k
  double e
 CODE:
  RETVAL = palEpco(k0, k, e);
 OUTPUT:
  RETVAL

double
palEpj(date)
  double date
 CODE:
  RETVAL = palEpj(date);
 OUTPUT:
  RETVAL


double
palEpj2d(epj)
  double epj
 CODE:
  RETVAL = palEpj2d(epj);
 OUTPUT:
  RETVAL

# palEpv returns 4 3-vectors so we must put them
# into individual arrays and return references on the stack.

void
palEpv( date )
  double date
 PREINIT:
  double ph[3];
  double vh[3];
  double pb[3];
  double vb[3];
  AV * pph;
  AV * pvh;
  AV * ppb;
  AV * pvb;
 PPCODE:
  palEpv( date, ph, vh, pb, vb );

  pph = newAV();
  unpack1D( newRV_noinc((SV*)pph), ph, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pph));
  pvh = newAV();
  unpack1D( newRV_noinc((SV*)pvh), vh, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pvh));
  ppb = newAV();
  unpack1D( newRV_noinc((SV*)ppb), pb, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)ppb));
  pvb = newAV();
  unpack1D( newRV_noinc((SV*)pvb), vb, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pvb));


void
palEqecl(dr, dd, date)
  double dr
  double dd
  double date
 PREINIT:
  double dl;
  double db;
 PPCODE:
  palEqecl(dr, dd, date, &dl, &db);
  XPUSHs(sv_2mortal(newSVnv(dl)));
  XPUSHs(sv_2mortal(newSVnv(db)));

# Equation of the equinoxes

double
palEqeqx(date)
  double date
 CODE:
  RETVAL = palEqeqx(date);
 OUTPUT:
  RETVAL

void
palEqgal(dr, dd)
  double dr
  double dd
 PREINIT:
  double dl;
  double db;
 PPCODE:
  palEqgal(dr, dd, &dl, &db);
  XPUSHs(sv_2mortal(newSVnv(dl)));
  XPUSHs(sv_2mortal(newSVnv(db)));

void
palEtrms(ep)
  double ep
 PREINIT:
  double ev[3];
 PPCODE:
  palEtrms(ep, ev);
  RETVEC(ev, 3, nv );

void
palEvp(date, deqx)
  double date
  double deqx
 PREINIT:
  double dvb[3];
  double dpb[3];
  double dvh[3];
  double dph[3];
  AV * pdvb;
  AV * pdpb;
  AV * pdvh;
  AV * pdph;
 PPCODE:
  palEvp(date, deqx, dvb, dpb, dvh, dph);

  pdvb = newAV();
  unpack1D( newRV_noinc((SV*)pdvb), dvb, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pdvb));
  pdpb = newAV();
  unpack1D( newRV_noinc((SV*)pdpb), dpb, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pdpb));
  pdvh = newAV();
  unpack1D( newRV_noinc((SV*)pdvh), dvh, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pdvh));
  pdph = newAV();
  unpack1D( newRV_noinc((SV*)pdph), dph, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pdph));


void
palFk45z(r1950, d1950, bepoch)
  double r1950
  double d1950
  double bepoch
 PREINIT:
  double r2000;
  double d2000;
 PPCODE:
  palFk45z(r1950, d1950, bepoch, &r2000, &d2000);
  XPUSHs(sv_2mortal(newSVnv(r2000)));
  XPUSHs(sv_2mortal(newSVnv(d2000)));


void
palFk524(r2000,d2000,dr2000,dd2000,p2000,v2000)
  double r2000
  double d2000
  double dr2000
  double dd2000
  double p2000
  double v2000
 PREINIT:
  double r1950;
  double d1950;
  double dr1950;
  double dd1950;
  double p1950;
  double v1950;
 PPCODE:
  palFk524(r2000,d2000,dr2000,dd2000,p2000,v2000,
	   &r1950,&d1950,&dr1950,&dd1950,&p1950,&v1950);
  XPUSHs(sv_2mortal(newSVnv(r1950)));
  XPUSHs(sv_2mortal(newSVnv(d1950)));
  XPUSHs(sv_2mortal(newSVnv(dr1950)));
  XPUSHs(sv_2mortal(newSVnv(dd1950)));
  XPUSHs(sv_2mortal(newSVnv(p1950)));
  XPUSHs(sv_2mortal(newSVnv(v1950)));

void
palFk54z(r2000, d2000, bepoch)
  double r2000
  double d2000
  double bepoch
 PREINIT:
  double r1950;
  double d1950;
  double dr1950;
  double dd1950;
 PPCODE:
  palFk54z(r2000, d2000, bepoch, &r1950, &d1950, &dr1950, &dd1950);
  XPUSHs(sv_2mortal(newSVnv(r1950)));
  XPUSHs(sv_2mortal(newSVnv(d1950)));
  XPUSHs(sv_2mortal(newSVnv(dr1950)));
  XPUSHs(sv_2mortal(newSVnv(dd1950)));


void
palGaleq(dl, db)
  double dl
  double db
 PREINIT:
  double dr;
  double dd;
 PPCODE:
  palGaleq(dl, db, &dr, &dd);
  XPUSHs(sv_2mortal(newSVnv(dr)));
  XPUSHs(sv_2mortal(newSVnv(dd)));


void
palGalsup(dl, db)
  double dl
  double db
 PREINIT:
  double dsl;
  double dsb;
 PPCODE:
  palGalsup(dl, db, &dsl, &dsb);
  XPUSHs(sv_2mortal(newSVnv(dsl)));
  XPUSHs(sv_2mortal(newSVnv(dsb)));

void
palGe50( dl, db )
  double dl
  double db
 PREINIT:
  double dr;
  double dd;
 PPCODE:
  palGe50(dl, db, &dr, &dd);
  XPUSHs(sv_2mortal(newSVnv(dr)));
  XPUSHs(sv_2mortal(newSVnv(dd)));

void
palGeoc(p, h)
  double p
  double h
 PREINIT:
  double r;
  double z;
 PPCODE:
  palGeoc(p, h, &r, &z);
  XPUSHs(sv_2mortal(newSVnv(r)));
  XPUSHs(sv_2mortal(newSVnv(z)));

# UT to GMST

double
palGmst(ut1)
  double ut1
 CODE:
  RETVAL = palGmst(ut1);
 OUTPUT:
  RETVAL

double
palGmsta(date, ut)
  double date
  double ut
 CODE:
  RETVAL = palGmsta(date, ut);
 OUTPUT:
  RETVAL

void
palHfk5z(rh, dh, epoch)
  double rh
  double dh
  double epoch
 PREINIT:
  double r5;
  double d5;
  double dr5;
  double dd5;
 PPCODE:
  palHfk5z(rh,dh,epoch,&r5,&d5,&dr5,&dd5);
  XPUSHs(sv_2mortal(newSVnv(r5)));
  XPUSHs(sv_2mortal(newSVnv(d5)));
  XPUSHs(sv_2mortal(newSVnv(dr5)));
  XPUSHs(sv_2mortal(newSVnv(dd5)));

# Note that nstrt is given and then returned on the stack

void
palIntin(string, nstrt)
  char * string
  int nstrt
 PREINIT:
  long ireslt;
  int jflag;
 PPCODE:
  palIntin(string, &nstrt, &ireslt, &jflag);
  XPUSHs(sv_2mortal(newSViv(nstrt)));
  XPUSHs(sv_2mortal(newSViv(ireslt)));
  XPUSHs(sv_2mortal(newSViv(jflag)));

void
palMap(rm, dm, pr, pd, px, rv, eq, date)
  double rm
  double dm
  double pr
  double pd
  double px
  double rv
  double eq
  double date
 PREINIT:
  double ra;
  double da;
 PPCODE:
  palMap(rm, dm, pr, pd, px, rv, eq, date, &ra, &da);
  XPUSHs(sv_2mortal(newSVnv(ra)));
  XPUSHs(sv_2mortal(newSVnv(da)));


void
palMappa(eq, date)
  double eq
  double date
 PREINIT:
  double amprms[21];
 PPCODE:
  palMappa(eq, date, amprms);
  RETVEC( amprms, 21, nv );

void
palMapqk(rm, dm, pr, pd, px, rv, amprms)
  double rm
  double dm
  double pr
  double pd
  double px
  double rv
  double * amprms
 PREINIT:
  double ra;
  double da;
 PPCODE:
  palMapqk(rm, dm, pr, pd, px, rv, amprms, &ra, &da);
  XPUSHs(sv_2mortal(newSVnv(ra)));
  XPUSHs(sv_2mortal(newSVnv(da)));

void
palMapqkz(rm, dm, amprms)
  double rm
  double dm
  double * amprms
 PREINIT:
  double ra;
  double da;
 PPCODE:
  palMapqkz(rm, dm, amprms, &ra, &da);
  XPUSHs(sv_2mortal(newSVnv(ra)));
  XPUSHs(sv_2mortal(newSVnv(da)));

void
palNut(date)
  double date
 PREINIT:
  double rmatn[3][3];
 PPCODE:
  palNut(date, rmatn);
  RETMATRIX(rmatn);

void
palNutc(date)
  double date
 PREINIT:
  double dpsi;
  double deps;
  double eps0;
 PPCODE:
  palNutc(date, &dpsi, &deps, &eps0);
  XPUSHs(sv_2mortal(newSVnv(dpsi)));
  XPUSHs(sv_2mortal(newSVnv(deps)));
  XPUSHs(sv_2mortal(newSVnv(eps0)));


void
palOap(type, ob1, ob2, date, dut, elongm, phim, hm, xp, yp, tdk, pmb, rh, wl, tlr)
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
 PREINIT:
  double rap;
  double dap;
 PPCODE:
  palOap(type, ob1, ob2, date, dut, elongm, phim, hm, xp, yp, tdk, pmb, rh, wl, tlr, &rap, &dap);
  XPUSHs(sv_2mortal(newSVnv(rap)));
  XPUSHs(sv_2mortal(newSVnv(dap)));

void
palOapqk(type, ob1, ob2, aoprms)
  char * type
  double ob1
  double ob2
  double * aoprms
 PREINIT:
  double rap;
  double dap;
 PPCODE:
  palOapqk(type, ob1, ob2, aoprms, &rap, &dap);
  XPUSHs(sv_2mortal(newSVnv(rap)));
  XPUSHs(sv_2mortal(newSVnv(dap)));

# Note that we have a perl layer on top to handle
# the input arguments. Also note that we return
# an empty list if status is not good.

void
_palObs(n, c)
  int n
  char * c
 PREINIT:
  char ident[11];
  char name[41];
  double w;
  double p;
  double h;
  int j;
 PPCODE:
  if (n<0) n = 0; /* palObs uses a size_t */
  j = palObs(n, c, ident, sizeof(ident), name, sizeof(name),
         &w, &p, &h);
  if (j == 0) {
    XPUSHs(sv_2mortal(newSVpvn(ident, strlen(ident))));
    XPUSHs(sv_2mortal(newSVpvn(name, strlen(name))));
    XPUSHs(sv_2mortal(newSVnv(w)));
    XPUSHs(sv_2mortal(newSVnv(p)));
    XPUSHs(sv_2mortal(newSVnv(h)));
  } else {
    XSRETURN_EMPTY;
  }

double
palPa(ha, dec, phi)
  double ha
  double dec
  double phi
 CODE:
  RETVAL = palPa(ha, dec, phi);
 OUTPUT:
  RETVAL


void
palPertel(jform,date0,date1,epoch0,orbi0,anode0,perih0,aorq0,e0,am0)
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
 PREINIT:
  double epoch1;
  double orbi1;
  double anode1;
  double perih1;
  double aorq1;
  double e1;
  double am1;
  int    jstat;
 PPCODE:
  jstat = 0;
  palPertel(jform,date0,date1,epoch0,orbi0,anode0,perih0,aorq0,e0,am0,
	    &epoch1,&orbi1,&anode1,&perih1,&aorq1,&e1,&am1,&jstat);
  XPUSHs(sv_2mortal(newSVnv(epoch1)));
  XPUSHs(sv_2mortal(newSVnv(orbi1)));
  XPUSHs(sv_2mortal(newSVnv(anode1)));
  XPUSHs(sv_2mortal(newSVnv(perih1)));
  XPUSHs(sv_2mortal(newSVnv(aorq1)));
  XPUSHs(sv_2mortal(newSVnv(e1)));
  XPUSHs(sv_2mortal(newSVnv(am1)));
  XPUSHs(sv_2mortal(newSViv(jstat)));

# Returns updated u

void
palPertue(date, u)
  double date
  double * u
 PREINIT:
  int jstat;
 PPCODE:
  jstat = 0;
  palPertue(date,u,&jstat);
  XPUSHs(sv_2mortal(newSViv(jstat)));
  RETVEC( u, 13, nv );

void
palPlanel(date, jform, epoch, orbinc, anode, perih, aorq, e, aorl, dm)
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
 PREINIT:
  double pv[6];
  int jstat;
 PPCODE:
  palPlanel(date, jform, epoch, orbinc, anode, perih, aorq, e, aorl, dm, pv, &jstat);
  XPUSHs(sv_2mortal(newSViv(jstat)));
  RETVEC( pv, 6, nv );

void
palPlanet(date, np)
  double date
  int np
 PREINIT:
  double pv[6];
  int jstat;
 PPCODE:
   palPlanet(date, np, pv, &jstat);
   XPUSHs(sv_2mortal(newSViv(jstat)));
   RETVEC( pv, 6, nv );

void
palPlante(date, elong, phi, jform, epoch, orbinc, anode, perih, aorq,e, aorl, dm)
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
 PREINIT:
  double ra;
  double dec;
  double r;
  int jstat;
 PPCODE:
  palPlante(date, elong, phi, jform, epoch, orbinc, anode, perih, aorq,e, aorl, dm, &ra, &dec, &r, &jstat);
  XPUSHs(sv_2mortal(newSVnv(ra)));
  XPUSHs(sv_2mortal(newSVnv(dec)));
  XPUSHs(sv_2mortal(newSVnv(r)));
  XPUSHs(sv_2mortal(newSViv(jstat)));

# TODO: palPlantu

void
palPm(r0,d0,pr,pd,px,rv,ep0,ep1)
  double r0
  double d0
  double pr
  double pd
  double px
  double rv
  double ep0
  double ep1
 PREINIT:
  double r1;
  double d1;
 PPCODE:
  palPm(r0,d0,pr,pd,px,rv,ep0,ep1,&r1,&d1);
  XPUSHs(sv_2mortal(newSVnv(r1)));
  XPUSHs(sv_2mortal(newSVnv(d1)));

void
palPrebn(bep0, bep1)
  double bep0
  double bep1
 PREINIT:
  double rmatp[3][3];
 PPCODE:
  palPrebn(bep0, bep1, rmatp);
  RETMATRIX(rmatp);

void
palPrec(ep0, ep1)
  double ep0
  double ep1
 PREINIT:
  double rmatp[3][3];
 PPCODE:
  palPrec(ep0, ep1, rmatp);
  RETMATRIX(rmatp);

# Precession

# Note that we return the (ra,dec) on the stack
# and do not modify the input arguments.

void
palPreces(system, ep0, ep1, ra, dc)
  char *system
  double ep0
  double ep1
  double ra
  double dc
 PPCODE:
  palPreces(system, ep0, ep1, &ra, &dc);
  XPUSHs(sv_2mortal(newSVnv(ra)));
  XPUSHs(sv_2mortal(newSVnv(dc)));

void
palPrenut(epoch, date, rmatpn)
  double epoch
  double date
 PREINIT:
  double rmatpn[3][3];
 PPCODE:
  palPrenut(epoch, date, rmatpn);
  RETMATRIX(rmatpn);

void
palPvobs(p, h, stl)
  double p
  double h
  double stl
 PREINIT:
  double pv[6];
 PPCODE:
  palPvobs(p, h, stl, pv);
  RETVEC(pv, 6, nv);

void
palRdplan(date, np, elong, phi)
  double date
  int np
  double elong
  double phi
 PREINIT:
  double ra;
  double dec;
  double diam;
 PPCODE:
  palRdplan(date, np, elong, phi, &ra, &dec, &diam);
  XPUSHs(sv_2mortal(newSVnv(ra)));
  XPUSHs(sv_2mortal(newSVnv(dec)));
  XPUSHs(sv_2mortal(newSVnv(diam)));

void
palRefco(hm, tdk, pmb, rh, wl, phi, tlr, eps)
  double hm
  double tdk
  double pmb
  double rh
  double wl
  double phi
  double tlr
  double eps
 PREINIT:
  double refa;
  double refb;
 PPCODE:
  palRefco(hm, tdk, pmb, rh, wl, phi, tlr, eps, &refa, &refb);
  XPUSHs(sv_2mortal(newSVnv(refa)));
  XPUSHs(sv_2mortal(newSVnv(refb)));

void
palRefcoq(tdk, pmb, rh, wl)
  double tdk
  double pmb
  double rh
  double wl
 PREINIT:
  double refa;
  double refb;
 PPCODE:
  palRefcoq(tdk, pmb, rh, wl, &refa, &refb);
  XPUSHs(sv_2mortal(newSVnv(refa)));
  XPUSHs(sv_2mortal(newSVnv(refb)));

void
palRefro(zobs, hm, tdk, pmb, rh, wl, phi, tlr, eps)
  double zobs
  double hm
  double tdk
  double pmb
  double rh
  double wl
  double phi
  double tlr
  double eps
 PREINIT:
  double ref;
 PPCODE:
  palRefro(zobs, hm, tdk, pmb, rh, wl, phi, tlr, eps, &ref);
  XPUSHs(sv_2mortal(newSVnv(ref)));

void
palRefv(vu, refa, refb)
  double * vu
  double refa
  double refb
 PREINIT:
   double vr[3];
 PPCODE:
  palRefv(vu, refa, refb, vr);
  RETVEC( vr, 3, nv );


void
palRefz(zu, refa, refb)
  double zu
  double refa
  double refb
 PREINIT:
  double zr;
 PPCODE:
  palRefz(zu, refa, refb, &zr);
  XPUSHs(sv_2mortal(newSVnv(zr)));

double
palRverot(phi, ra, da, st)
  double phi
  double ra
  double da
  double st
 CODE:
  RETVAL = palRverot(phi, ra, da, st);
 OUTPUT:
  RETVAL


double
palRvgalc(r2000, d2000)
  double r2000
  double d2000
 CODE:
  RETVAL = palRvgalc(r2000, d2000);
 OUTPUT:
  RETVAL

double
palRvlg(r2000, d2000)
  double r2000
  double d2000
 CODE:
  RETVAL = palRvlg(r2000, d2000);
 OUTPUT:
  RETVAL


double
palRvlsrd(r2000, d2000)
  double r2000
  double d2000
 CODE:
  RETVAL = palRvlsrd(r2000, d2000);
 OUTPUT:
  RETVAL

double
palRvlsrk(r2000, d2000)
  double r2000
  double d2000
 CODE:
  RETVAL = palRvlsrk(r2000, d2000);
 OUTPUT:
  RETVAL

void
palSubet(rc, dc, eq)
  double rc
  double dc
  double eq
 PREINIT:
  double rm;
  double dm;
 PPCODE:
  palSubet(rc, dc, eq, &rm, &dm);
  XPUSHs(sv_2mortal(newSVnv(rm)));
  XPUSHs(sv_2mortal(newSVnv(dm)));

void
palSupgal(dsl, dsb)
  double dsl
  double dsb
 PREINIT:
  double dl;
  double db;
 PPCODE:
  palSupgal(dsl, dsb, &dl, &db);
  XPUSHs(sv_2mortal(newSVnv(dl)));
  XPUSHs(sv_2mortal(newSVnv(db)));

# TODO: palUe2el

# TODO: palUe2pv
