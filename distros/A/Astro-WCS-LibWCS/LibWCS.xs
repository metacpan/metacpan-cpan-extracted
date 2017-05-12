#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "fitsfile.h"
#include "wcs.h"
#include "wcscat.h"
#include "util.h"

typedef struct WorldCoor WCS;
typedef struct StarCat   StarCat;
typedef struct Star   Star;
typedef struct TabTable   TabTable;
typedef struct Range Range;
typedef struct Keyword Keyword;
typedef struct Tokens Tokens;

/* declarations which are not in libwcs headers */
#include "wcsdecl.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	if (strEQ(name, "PI"))
#ifdef PI
	    return PI;
#else
	    goto not_there;
#endif
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	if (strEQ(name, "TNX_CHEBYSHEV"))
#ifdef TNX_CHEBYSHEV
	    return TNX_CHEBYSHEV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TNX_LEGENDRE"))
#ifdef TNX_LEGENDRE
	    return TNX_LEGENDRE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TNX_POLYNOMIAL"))
#ifdef TNX_POLYNOMIAL
	    return TNX_POLYNOMIAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TNX_XFULL"))
#ifdef TNX_XFULL
	    return TNX_XFULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TNX_XHALF"))
#ifdef TNX_XHALF
	    return TNX_XHALF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TNX_XNONE"))
#ifdef TNX_XNONE
	    return TNX_XNONE;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	if (strEQ(name, "WCS_AIR"))
#ifdef WCS_AIR
	    return WCS_AIR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_AIT"))
#ifdef WCS_AIT
	    return WCS_AIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_ALTAZ"))
#ifdef WCS_ALTAZ
	    return WCS_ALTAZ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_ARC"))
#ifdef WCS_ARC
	    return WCS_ARC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_AZP"))
#ifdef WCS_AZP
	    return WCS_AZP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_B1950"))
#ifdef WCS_B1950
	    return WCS_B1950;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_BON"))
#ifdef WCS_BON
	    return WCS_BON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_CAR"))
#ifdef WCS_CAR
	    return WCS_CAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_CEA"))
#ifdef WCS_CEA
	    return WCS_CEA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_COD"))
#ifdef WCS_COD
	    return WCS_COD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_COE"))
#ifdef WCS_COE
	    return WCS_COE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_COO"))
#ifdef WCS_COO
	    return WCS_COO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_CPS"))
#ifdef WCS_CPS
	    return WCS_CPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_CSC"))
#ifdef WCS_CSC
	    return WCS_CSC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_CYP"))
#ifdef WCS_CYP
	    return WCS_CYP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_DSS"))
#ifdef WCS_DSS
	    return WCS_DSS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_ECLIPTIC"))
#ifdef WCS_ECLIPTIC
	    return WCS_ECLIPTIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_GALACTIC"))
#ifdef WCS_GALACTIC
	    return WCS_GALACTIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_GLS"))
#ifdef WCS_GLS
	    return WCS_GLS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_J2000"))
#ifdef WCS_J2000
	    return WCS_J2000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_LIN"))
#ifdef WCS_LIN
	    return WCS_LIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_LINEAR"))
#ifdef WCS_LINEAR
	    return WCS_LINEAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_MER"))
#ifdef WCS_MER
	    return WCS_MER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_MOL"))
#ifdef WCS_MOL
	    return WCS_MOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_NCP"))
#ifdef WCS_NCP
	    return WCS_NCP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_NPOLE"))
#ifdef WCS_NPOLE
	    return WCS_NPOLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_PAR"))
#ifdef WCS_PAR
	    return WCS_PAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_PCO"))
#ifdef WCS_PCO
	    return WCS_PCO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_PIX"))
#ifdef WCS_PIX
	    return WCS_PIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_PLANET"))
#ifdef WCS_PLANET
	    return WCS_PLANET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_PLT"))
#ifdef WCS_PLT
	    return WCS_PLT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_QSC"))
#ifdef WCS_QSC
	    return WCS_QSC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_SIN"))
#ifdef WCS_SIN
	    return WCS_SIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_SPA"))
#ifdef WCS_SPA
	    return WCS_SPA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_STG"))
#ifdef WCS_STG
	    return WCS_STG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_TAN"))
#ifdef WCS_TAN
	    return WCS_TAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_TNX"))
#ifdef WCS_TNX
	    return WCS_TNX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_TSC"))
#ifdef WCS_TSC
	    return WCS_TSC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_ZEA"))
#ifdef WCS_ZEA
	    return WCS_ZEA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "WCS_ZPN"))
#ifdef WCS_ZPN
	    return WCS_ZPN;
#else
	    goto not_there;
#endif
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Astro::WCS::LibWCS		PACKAGE = Astro::WCS::LibWCS
PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg

##
##
## wcsinit.c
##
##

WCS *
wcsninit(hstring,len)
	char * hstring
	int len

WCS *
wcsinit(hstring)
	char * hstring

WCS *
wcsninitn(hstring, len, wcsname)
	char * hstring
	int len
	char * wcsname

WCS *
wcsinitn(hstring, wcsname)
	char * hstring
	char * wcsname

WCS *
wcsninitc(hstring, len, wcschar)
	char * hstring
	int len
	char &wcschar

WCS *
wcsinitc(hstring, wcschar)
	char * hstring
	char &wcschar

##
##
## wcs.c
##
##

void
wcsfree(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::wcsfree = 1
		WCSPtr::wcsfree = 2
		WCSPtr::free = 3

WCS *
wcsxinit(cra,cdec,secpix,xrpix,yrpix,nxpix,nypix,rotate,equinox,epoch,proj)
	double cra
	double cdec
	double secpix
	double xrpix
	double yrpix
	int nxpix
	int nypix
	double rotate
	int equinox
	double epoch
	char * proj

WCS *
wcskinit(naxis1,naxis2,ctype1,ctype2,crpix1,crpix2,crval1,crval2,cd,cdelt1,cdelt2,crota,equinox,epoch)
	int naxis1
	int naxis2
	char * ctype1
	char * ctype2
	double crpix1
	double crpix2
	double crval1
	double crval2
	double * cd
	double cdelt1
	double cdelt2
	double crota
	int equinox
	double epoch

int
wcstype(wcs,ctype1,ctype2)
	WCS * wcs
	char * ctype1
	char * ctype2
	ALIAS:
		Astro::WCS::LibWCS::wcstype = 1
		WCSPtr::wcstype = 2
		WCSPtr::type = 3

int
wcsreset(wcs,crpix1,crpix2,crval1,crval2,cdelt1,cdelt2,crota,cd)
	WCS * wcs
	double crpix1
	double crpix2
	double crval1
	double crval2
	double cdelt1
	double cdelt2
	double crota
	double * cd
	ALIAS:
		Astro::WCS::LibWCS::wcsreset = 1
		WCSPtr::wcsreset = 2
		WCSPtr::reset = 3

void
wcseqset(wcs,equinox)
	WCS * wcs
	double equinox
	ALIAS:
		Astro::WCS::LibWCS::wcseqset = 1
		WCSPtr::wcseqset = 2
		WCSPtr::eqset = 3

void
wcscdset(wcs,cd)
	WCS * wcs
	double * cd
	ALIAS:
		Astro::WCS::LibWCS::wcscdset = 1
		WCSPtr::wcscdset = 2
		WCSPtr::cdset = 3

void
wcsdeltset(wcs,cdelt1,cdelt2,crota)
	WCS * wcs
	double cdelt1
	double cdelt2
	double crota
	ALIAS:
		Astro::WCS::LibWCS::wcsdeltset = 1
		WCSPtr::wcsdeltset = 2
		WCSPtr::deltset = 3

void
wcspcset(wcs,cdelt1,cdelt2,pc)
	WCS * wcs
	double cdelt1
	double cdelt2
	double * pc
	ALIAS:
		Astro::WCS::LibWCS::wcspcset = 1
		WCSPtr::wcspcset = 2
		WCSPtr::pcset = 3

void
wcsrotset(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::wcsrotset = 1
		WCSPtr::wcsrotset = 2
		WCSPtr::rotset = 3

int
iswcs(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::iswcs = 1
		WCSPtr::iswcs = 2

int
nowcs(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::nowcs = 1
		WCSPtr::nowcs = 2

void
wcsshift(wcs,rra,rdec,coorsys)
	WCS * wcs
	double rra
	double rdec
	char * coorsys
	ALIAS:
		Astro::WCS::LibWCS::wcsshift = 1
		WCSPtr::wcsshift = 2
		WCSPtr::shift = 3

void
wcscent(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::wcscent = 1
		WCSPtr::wcscent = 2
		WCSPtr::cent = 3

void
wcssize(wcs,cra,cdec,dra,ddec)
	WCS * wcs
	double &cra = NO_INIT
	double &cdec = NO_INIT
	double &dra = NO_INIT
	double &ddec = NO_INIT
	ALIAS:
		Astro::WCS::LibWCS::wcssize = 1
		WCSPtr::wcssize = 2
		WCSPtr::size = 3
	OUTPUT:
		cra
		cdec
		dra
		ddec

void
wcsfull(wcs,cra,cdec,width,height)
	WCS * wcs
	double &cra = NO_INIT
	double &cdec = NO_INIT
	double &width = NO_INIT
	double &height = NO_INIT
	ALIAS:
		Astro::WCS::LibWCS::wcsfull = 1
		WCSPtr::wcsfull = 2
		WCSPtr::full = 3
	OUTPUT:
		cra
		cdec
		width
		height

void
wcsrange(wcs,ra1,ra2,dec1,dec2)
	WCS * wcs
	double &ra1 = NO_INIT
	double &ra2 = NO_INIT
	double &dec1 = NO_INIT
	double &dec2 = NO_INIT
	ALIAS:
		Astro::WCS::LibWCS::wcsrange = 1
		WCSPtr::wcsrange = 2
		WCSPtr::range = 3
	OUTPUT:
		ra1
		ra2
		dec1
		dec2

double
wcsdist(x1,y1,x2,y2)
	double x1
	double y1
	double x2
	double y2

void
wcscominit(wcs,i,command)
	WCS * wcs
	int i
	char * command
	ALIAS:
		Astro::WCS::LibWCS::wcscominit = 1
		WCSPtr::wcscominit = 2
		WCSPtr::cominit = 3

void
wcscom(wcs,i,filename,xfile,yfile,wcstring)
	WCS * wcs
	int i
	char * filename
	double xfile
	double yfile
	char * wcstring
	ALIAS:
		Astro::WCS::LibWCS::wcscom = 1
		WCSPtr::wcscom = 2
		WCSPtr::com = 3

void
wcsoutinit(wcs,coorsys)
	WCS * wcs
	char * coorsys
	ALIAS:
		Astro::WCS::LibWCS::wcsoutinit = 1
		WCSPtr::wcsoutinit = 2
		WCSPtr::outinit = 3

char *
getwcsout(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::getwcsout = 1
		WCSPtr::getwcsout = 2

void
wcsininit(wcs,coorsys)
	WCS * wcs
	char * coorsys
	ALIAS:
		Astro::WCS::LibWCS::wcsininit = 1
		WCSPtr::wcsininit = 2
		WCSPtr::ininit = 3

char *
getwcsin(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::getwcsin = 1
		WCSPtr::getwcsin = 2

int
setwcsdeg(wcs,new)
	WCS * wcs
	int new
	ALIAS:
		Astro::WCS::LibWCS::setwcsdeg = 1
		WCSPtr::setwcsdeg = 2

int
wcsndec(wcs,ndec)
	WCS * wcs
	int ndec
	ALIAS:
		Astro::WCS::LibWCS::wcsndec = 1
		WCSPtr::wcsndec = 2
		WCSPtr::ndec = 3

char *
getradecsys(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::getradecsys = 1
		WCSPtr::getradecsys = 2

void
setwcslin(wcs,mode)
	WCS * wcs
	int mode
	ALIAS:
		Astro::WCS::LibWCS::setwcslin = 1
		WCSPtr::setwcslin = 2

##
## 'lstr' argument in C function taken care of automagically
##
int
pix2wcst(wcs,xpix,ypix,wcstring)
	WCS * wcs
	double xpix
	double ypix
	char * wcstring = NO_INIT
	ALIAS:
		Astro::WCS::LibWCS::pix2wcst = 1
		WCSPtr::pix2wcst = 2
	PREINIT:
		int lstr;
	CODE:
		lstr = 32;
		wcstring = (char *)get_mortalspace(lstr,TBYTE);
		RETVAL = pix2wcst(wcs,xpix,ypix,wcstring,lstr);
	OUTPUT:
		wcstring
		RETVAL

void
pix2wcs(wcs,xpix,ypix,xpos,ypos)
	WCS * wcs
	double xpix
	double ypix
	double &xpos = NO_INIT
	double &ypos = NO_INIT
	ALIAS:
		Astro::WCS::LibWCS::pix2wcs = 1
		WCSPtr::pix2wcs = 2
	OUTPUT:
		xpos
		ypos

void
wcs2pix(wcs,xpos,ypos,xpix,ypix,offscl)
	WCS * wcs
	double xpos
	double ypos
	double &xpix = NO_INIT
	double &ypix = NO_INIT
	int &offscl = NO_INIT
	ALIAS:
		Astro::WCS::LibWCS::wcs2pix = 1
		WCSPtr::wcs2pix = 2
	OUTPUT:
		xpix
		ypix
		offscl

void
wcsc2pix(wcs,xpos,ypos,coorsys,xpix,ypix,offscl)
	WCS * wcs
	double xpos
	double ypos
	char * coorsys
	double &xpix = NO_INIT
	double &ypix = NO_INIT
	int &offscl = NO_INIT
	ALIAS:
		Astro::WCS::LibWCS::wcsc2pix = 1
		WCSPtr::wcsc2pix = 2
	OUTPUT:
		xpix
		ypix
		offscl

int
wcspos(xpix,ypix,wcs,xpos,ypos)
	double xpix
	double ypix
	WCS * wcs
	double &xpos = NO_INIT
	double &ypos = NO_INIT

int
wcspix(xpos,ypos,wcs,xpix,ypix)
	double xpos
	double ypos
	WCS * wcs
	double &xpix = NO_INIT
	double &ypix = NO_INIT

int
wcszin(izpix)
	int izpix

int
wcszout(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::wcszout = 1
		WCSPtr::wcszout = 2
		WCSPtr::zout = 3

void
setwcsfile(filename)
	char * filename

void
setwcserr(errmsg)
	char * errmsg

void
wcserr()

void
setdefwcs(oldwcs)
	int oldwcs

int
getdefwcs()

void
savewcscoor(wcscoor)
	char * wcscoor

char *
getwcscoor()

void
savewcscom(i,wcscom)
	int i
	char * wcscom

void
setwcscom(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::setwcscom = 1
		WCSPtr::setwcscom = 2

char *
getwcscom(i)
	int i

void
freewcscom(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::freewcscom = 1
		WCSPtr::freewcscom = 2

##
##
## wcscon.c
##
##

void
wcsconp(sys1,sys2,eq1,eq2,ep1,ep2,dtheta,dphi,ptheta,pphi)
	int sys1
	int sys2
	double eq1
	double eq2
	double ep1
	double ep2
	double &dtheta = NO_INIT
	double &dphi = NO_INIT
	double &ptheta = NO_INIT
	double &pphi = NO_INIT
	OUTPUT:
		dtheta
		dphi
		ptheta
		pphi

void
wcsconv(sys1,sys2,eq1,eq2,ep1,ep2,dtheta,dphi,ptheta,pphi,px,rv)
	int sys1
	int sys2
	double eq1
	double eq2
	double ep1
	double ep2
	double &dtheta = NO_INIT
	double &dphi = NO_INIT
	double &ptheta = NO_INIT
	double &pphi = NO_INIT
	double &px = NO_INIT
	double &rv = NO_INIT
	OUTPUT:
		dtheta
		dphi
		ptheta
		pphi
		px
		rv

void
wcscon(sys1,sys2,eq1,eq2,dtheta,dphi,epoch)
	int sys1
	int sys2
	double eq1
	double eq2
	double &dtheta = NO_INIT
	double &dphi = NO_INIT
	double epoch
	OUTPUT:
		dtheta
		dphi

int
wcscsys(wcstring)
	char * wcstring

double
wcsceq(wcstring)
	char * wcstring

void
wcscstr(cstr,syswcs,equinox,epoch)
	char * cstr
	int syswcs
	double equinox
	double epoch

void
fk524(ra,dec)
	double &ra
	double &dec
	OUTPUT:
		ra
		dec

void
fk524e(ra,dec,epoch)
	double &ra
	double &dec
	double epoch
	OUTPUT:
		ra
		dec

void
fk524m(ra,dec,rapm,decpm)
	double &ra
	double &dec
	double &rapm
	double &decpm
	OUTPUT:
		ra
		dec
		rapm
		decpm

void
fk524pv(ra,dec,rapm,decpm,parallax,rv)
	double &ra
	double &dec
	double &rapm
	double &decpm
	double &parallax
	double &rv
	OUTPUT:
		ra
		dec
		rapm
		decpm
		parallax
		rv

void
fk425(ra,dec)
	double &ra
	double &dec
	OUTPUT:
		ra
		dec

void
fk425e(ra,dec,epoch)
	double &ra
	double &dec
	double epoch
	OUTPUT:
		ra
		dec

void
fk425m(ra,dec,rapm,decpm)
	double &ra
	double &dec
	double &rapm
	double &decpm
	OUTPUT:
		ra
		dec
		rapm
		decpm

void
fk425pv(ra,dec,rapm,decpm,parallax,rv)
	double &ra
	double &dec
	double &rapm
	double &decpm
	double &parallax
	double &rv
	OUTPUT:
		ra
		dec
		rapm
		decpm
		parallax
		rv

void
fk42gal(dtheta,dphi)
	double &dtheta
	double &dphi
	OUTPUT:
		dtheta
		dphi

void
gal2fk4(dtheta,dphi)
	double &dtheta
	double &dphi
	OUTPUT:
		dtheta
		dphi

void
fk52gal(dtheta,dphi)
	double &dtheta
	double &dphi
	OUTPUT:
		dtheta
		dphi

void
gal2fk5(dtheta,dphi)
	double &dtheta
	double &dphi
	OUTPUT:
		dtheta
		dphi

SV *
eqstrn(dra,ddec)
	double dra
	double ddec
	PREINIT:
		char * temp;
	CODE:
		temp = eqstrn(dra,ddec);
		ST(0) = sv_newmortal();
		if (temp)
		{
			sv_setpv((SV *)ST(0), temp);
			free(temp);
		}

void
v2s3(pos,rra,rdec,r)
	double * pos
	double &rra
	double &rdec
	double &r
	OUTPUT:
		rra
		rdec
		r

void
s2v3(rra,rdec,r,pos)
	double rra
	double rdec
	double r
	double * pos = NO_INIT
	CODE:
		pos = (double *)get_mortalspace(3,TDOUBLE);
		s2v3(rra,rdec,r,pos);
		unpack1D(ST(3),pos,3,TDOUBLE);

void
fk42ecl(dtheta,dphi,epoch)
	double &dtheta
	double &dphi
	double epoch
	OUTPUT:
		dtheta
		dphi

void
fk52ecl(dtheta,dphi,epoch)
	double &dtheta
	double &dphi
	double epoch
	OUTPUT:
		dtheta
		dphi

void
ecl2fk4(dtheta,dphi,epoch)
	double &dtheta
	double &dphi
	double epoch
	OUTPUT:
		dtheta
		dphi

void
ecl2fk5(dtheta,dphi,epoch)
	double &dtheta
	double &dphi
	double epoch
	OUTPUT:
		dtheta
		dphi

void
fk4prec(ep0,ep1,ra,dec)
	double ep0
	double ep1
	double &ra
	double &dec
	OUTPUT:
		ra
		dec

void
fk5prec(ep0,ep1,ra,dec)
	double ep0
	double ep1
	double &ra
	double &dec
	OUTPUT:
		ra
		dec

void
mprecfk4(bep0,bep1,rmat)
	double bep0
	double bep1
	SV * rmat = NO_INIT
	PREINIT:
		double *rmatp[3];
		double data[9];
		long dims[] = {3,3};
		long i;
	CODE:
		for (i=0;i<3;i++)
			rmatp[i] = data + i*3;
		mprecfk4(bep0,bep1,rmatp);
		unpack2D(ST(2),data,dims,TDOUBLE);

void
mprecfk5(bep0,bep1,rmat)
	double bep0
	double bep1
	SV * rmat = NO_INIT
	PREINIT:
		double *rmatp[3];
		double data[9];
		long dims[] = {3,3};
		long i;
	CODE:
		for (i=0;i<3;i++)
			rmatp[i] = data + i*3;
		mprecfk5(bep0,bep1,rmatp);
		unpack2D(ST(2),data,dims,TDOUBLE);

##
##
## hget.c
##
##

int
hlength(header,lhead)
	char * header
	int lhead

int
gethlength(header)
	char * header

int
hgeti4(hstring,keyword,ival)
	char * hstring
	char * keyword
	int &ival = NO_INIT
	OUTPUT:
		ival
		RETVAL

int
hgeti2(hstring,keyword,ival)
	char * hstring
	char * keyword
	short &ival = NO_INIT
	OUTPUT:
		ival
		RETVAL

int
hgetr4(hstring,keyword,rval)
	char * hstring
	char * keyword
	float &rval = NO_INIT
	OUTPUT:
		rval
		RETVAL

int
hgetra(hstring,keyword,dval)
	char * hstring
	char * keyword
	double &dval = NO_INIT
	OUTPUT:
		dval
		RETVAL

int
hgetdec(hstring,keyword,dval)
	char * hstring
	char * keyword
	double &dval = NO_INIT
	OUTPUT:
		dval
		RETVAL

int
hgetr8c(hstring,keyword,wchar,dval)
	char * hstring
	char * keyword
	char &wchar
	double &dval = NO_INIT
	OUTPUT:
		dval
		RETVAL

int
hgetr8(hstring,keyword,dval)
	char * hstring
	char * keyword
	double &dval = NO_INIT
	OUTPUT:
		dval
		RETVAL

int
hgetl(hstring,keyword,ival)
	char * hstring
	char * keyword
	int &ival = NO_INIT
	OUTPUT:
		ival
		RETVAL

int
hgetdate(hstring,keyword,dval)
	char * hstring
	char * keyword
	double &dval = NO_INIT
	OUTPUT:
		dval
		RETVAL

int
hgetm(hstring,keyword,lstr,str)
	char * hstring
	char * keyword
	int lstr
	char * str = NO_INIT
	CODE:
		if (lstr <= 0)
			lstr = 2880;
		str = get_mortalspace(lstr,TBYTE);
		RETVAL = hgetm(hstring,keyword,lstr,str);
	OUTPUT:
		RETVAL
		str

int
hgetsc(hstring,keyword,wchar,lstr,str)
	char * hstring
	char * keyword
	char wchar
	int lstr
	char * str = NO_INIT
	CODE:
		if (lstr <= 0)
			lstr = 2880;
		str = get_mortalspace(lstr,TBYTE);
		RETVAL = hgetsc(hstring,keyword,&wchar,lstr,str);
	OUTPUT:
		RETVAL
		str

int
hgets(hstring,keyword,lstr,str)
	char * hstring
	char * keyword
	int lstr
	char * str = NO_INIT
	CODE:
		if (lstr <= 0)
			lstr = 2880;
		str = get_mortalspace(lstr,TBYTE);
		RETVAL = hgets(hstring,keyword,lstr,str);
	OUTPUT:
		RETVAL
		str

int
hgetndec(hstring,keyword,ndec)
	char * hstring
	char * keyword
	int &ndec = NO_INIT
	OUTPUT:
		ndec
		RETVAL

char *
hgetc(hstring,keyword)
	char *hstring
	char *keyword

char *
blsearch(hstring,keyword)
	char * hstring
	char * keyword

char *
ksearch(hstring,keyword)
	char * hstring
	char * keyword

double
str2ra(in)
	char * in

double
str2dec(in)
	char * in

char *
strsrch(s1,s2)
	char * s1
	char * s2

char *
strnsrch(s1,s2,ls1)
	char * s1
	char * s2
	int ls1

char *
strcsrch(s1,s2)
	char * s1
	char * s2

char *
strncsrch(s1,s2,ls1)
	char * s1
	char * s2
	int ls1

int
notnum(string)
	char * string

int
isnum(string)
	char * string

##
##
## dsspos.c
##
##

int
dsspos(xpix,ypix,wcs,xpos,ypos)
	double xpix
	double ypix
	WCS * wcs
	double &xpos = NO_INIT
	double &ypos = NO_INIT
	OUTPUT:
		xpos
		ypos
		RETVAL

int
dsspix(xpos,ypos,wcs,xpix,ypix)
	double xpos
	double ypos
	WCS * wcs
	double &xpix = NO_INIT
	double &ypix = NO_INIT
	OUTPUT:
		xpix
		ypix
		RETVAL

##
##
## platepos.c
##
##

int
platepos(xpix,ypix,wcs,xpos,ypos)
	double xpix
	double ypix
	WCS * wcs
	double &xpos = NO_INIT
	double &ypos = NO_INIT
	OUTPUT:
		xpos
		ypos
		RETVAL

int
platepix(xpos,ypos,wcs,xpix,ypix)
	double xpos
	double ypos
	WCS * wcs
	double &xpix = NO_INIT
	double &ypix = NO_INIT
	OUTPUT:
		xpix
		ypix
		RETVAL

int
SetPlate(wcs,ncoeff1,ncoeff2,coeff)
	WCS * wcs
	int ncoeff1
	int ncoeff2
	double * coeff
	ALIAS:
		Astro::WCS::LibWCS::SetPlate = 1
		WCSPtr::SetPlate = 2

int
GetPlate(wcs,ncoeff1,ncoeff2,coeff)
	WCS * wcs
	int ncoeff1 = NO_INIT
	int ncoeff2 = NO_INIT
	double * coeff = NO_INIT
	ALIAS:
		Astro::WCS::LibWCS::GetPlate = 1
		WCSPtr::GetPlate = 2
	CODE:
		/* bit of a hack, I'm afraid */
		ncoeff1 = wcs->ncoeff1;
		ncoeff2 = wcs->ncoeff2;
		coeff = (double *) get_mortalspace(ncoeff1 + ncoeff2, TDOUBLE);
		RETVAL = GetPlate(wcs, &ncoeff1, &ncoeff2, coeff);
		unpack1D(ST(3),coeff,ncoeff1+ncoeff2,TDOUBLE);
	OUTPUT:
		ncoeff1
		ncoeff2
		RETVAL

void
SetFITSPlate(header, wcs)
	char * header
	WCS * wcs

##
##
## tnxpos.c
##
##

int
tnxinit(header,wcs)
	char * header
	WCS * wcs

int
tnxpos(xpix,ypix,wcs,xpos,ypos)
	double xpix
	double ypix
	WCS * wcs
	double &xpos = NO_INIT
	double &ypos = NO_INIT
	OUTPUT:
		xpos
		ypos
		RETVAL

int
tnxpix(xpos,ypos,wcs,xpix,ypix)
	double xpos
	double ypos
	WCS * wcs
	double &xpix = NO_INIT
	double &ypix = NO_INIT
	OUTPUT:
		xpix
		ypix
		RETVAL

void
tnxclose(wcs)
	WCS * wcs
	ALIAS:
		Astro::WCS::LibWCS::tnxclose = 1
		WCSPtr::tnxclose = 2

int
tnxpset(wcs,xorder,yorder,xterms,coeffs)
	WCS * wcs
	int xorder
	int yorder
	int xterms
	double * coeffs
	ALIAS:
		Astro::WCS::LibWCS::tnxpset = 1
		WCSPtr::tnxpset = 2

##
##
## worldpos.c
##
##

int
worldpos(xpix,ypix,wcs,xpos,ypos)
	double xpix
	double ypix
	WCS * wcs
	double &xpos = NO_INIT
	double &ypos = NO_INIT
	OUTPUT:
		xpos
		ypos
		RETVAL

int
worldpix(xpos,ypos,wcs,xpix,ypix)
	double xpos
	double ypos
	WCS * wcs
	double &xpix = NO_INIT
	double &ypix = NO_INIT
	OUTPUT:
		xpix
		ypix
		RETVAL

##
##
## hput.c
##
##

int
hputi4(hstring,keyword,ival)
	char * hstring
	char * keyword
	int ival
	OUTPUT:
		hstring
		RETVAL

int
hputr4(hstring,keyword,rval)
	char * hstring
	char * keyword
	float &rval
	OUTPUT:
		hstring
		RETVAL

int
hputr8(hstring,keyword,dval)
	char * hstring
	char * keyword
	double dval
	OUTPUT:
		hstring
		RETVAL

int
hputnr8(hstring,keyword,ndec,dval)
	char * hstring
	char * keyword
	int ndec
	double dval
	OUTPUT:
		hstring
		RETVAL

int
hputra(hstring,keyword,ra)
	char * hstring
	char * keyword
	double ra
	OUTPUT:
		hstring
		RETVAL

int
hputdec(hstring,keyword,dec)
	char * hstring
	char * keyword
	double dec
	OUTPUT:
		hstring
		RETVAL

int
hputl(hstring,keyword,lval)
	char * hstring
	char * keyword
	int lval
	OUTPUT:
		hstring
		RETVAL

int
hputs(hstring,keyword,cval)
	char * hstring
	char * keyword
	char * cval
	OUTPUT:
		hstring
		RETVAL

int
hputm(hstring,keyword,cval)
	char * hstring
	char * keyword
	char * cval
	OUTPUT:
		hstring
		RETVAL

int
hputc(hstring,keyword,value)
	char * hstring
	char * keyword
	char * value
	OUTPUT:
		hstring
		RETVAL

int
hputcom(hstring,keyword,comment)
	char * hstring
	char * keyword
	char * comment
	OUTPUT:
		hstring
		RETVAL

int
hdel(hstring,keyword)
	char * hstring
	char * keyword
	OUTPUT:
		hstring
		RETVAL

int
hadd(hplace,keyword)
	char * hplace
	char * keyword
	OUTPUT:
		hplace
		RETVAL

int
hchange(hstring,keyword1,keyword2)
	char * hstring
	char * keyword1
	char * keyword2
	OUTPUT:
		hstring
		RETVAL

void
ra2str(string,lstr,ra,ndec)
	char * string = NO_INIT
	int lstr
	double ra
	int ndec
	CODE:
		if (lstr < 0)
			lstr = 0;
		string = (char *)get_mortalspace(lstr+1,TBYTE);
		ra2str(string,lstr,ra,ndec);
	OUTPUT:
		string

void
dec2str(string,lstr,dec,ndec)
	char * string = NO_INIT
	int lstr
	double dec
	int ndec
	CODE:
		if (lstr < 0)
			lstr = 0;
		string = (char *)get_mortalspace(lstr+1,TBYTE);
		dec2str(string,lstr,dec,ndec);
	OUTPUT:
		string

void
deg2str(string,lstr,deg,ndec)
	char * string = NO_INIT
	int lstr
	double deg
	int ndec
	CODE:
		if (lstr < 0)
			lstr = 0;
		string = (char *)get_mortalspace(lstr+1,TBYTE);
		deg2str(string,lstr,deg,ndec);
	OUTPUT:
		string

void
num2str(string,num,field,ndec)
	char * string = NO_INIT
	double num
	int field
	int ndec
	CODE:
		int nchars; /* have to decide how big output buffer will be */
		if (field > 0)
			nchars = field + 1;
		else {
			nchars = 1024;
			if (ndec > 0)
				nchars += ndec; /* this is just plain silly... */
		}
		string = (char *)get_mortalspace(nchars,TBYTE);
		num2str(string,num,field,ndec);
	OUTPUT:
		string


##
##
## actread.c
##
##

StarCat *
actopen(regnum)
	int regnum

void
actclose(sc)
	StarCat * sc
	ALIAS:
		Astro::WCS::LibWCS::actclose = 1
		StarCatPtr::actclose = 2

##
##
## tabread.c
##
##

int
tabread(tabcatname,distsort,cra,cdec,dra,ddec,drad,dradi,sysout,eqout,epout,mag1,mag2,sortmag,nstarmax,starcat,tnum,tra,tdec,tpra,tpdec,tmag,tpeak,tkey,nlog)
	char * tabcatname
	double cra
	double cdec
	double dra
	double ddec
	double drad
	double dradi
	int distsort
	int sysout
	double eqout
	double epout
	double mag1
	double mag2
	int sortmag
	int nstarmax
	StarCat * starcat = NO_INIT
	double * tnum = NO_INIT
	double * tra = NO_INIT
	double * tdec = NO_INIT
	double * tpra = NO_INIT
	double * tpdec = NO_INIT
	double ** tmag = NO_INIT
	int * tpeak = NO_INIT
	char ** tkey = NO_INIT
	int nlog
	PREINIT:
		long nmag, nstar, i, j, *tmagdims;
		double *mag, *mag_, **tmag_;
	CODE:
		if (nstarmax < 0)
			nstarmax = 0;

		/* C routine creates the starcat if it's NULL, from
		   which it then gets the number of magnitudes. We'll
		   do the same here.
		*/
		if (sv_derived_from(ST(15), "StarCatPtr")) {
		   starcat = (StarCat*)SvIV((SV*)SvRV(ST(15)));
		   nmag = starcat->nmag;
		}
		else {
		     ST(15) = sv_newmortal();
		     starcat = tabcatopen (tabcatname, NULL, 0);
		     if (starcat) {
			nmag = starcat->nmag;
			sv_setref_pv(ST(15),"StarCatPtr",starcat);
		     }
		}
		
		tnum = (double *) get_mortalspace(nstarmax, TDOUBLE);
		tra = (double *) get_mortalspace(nstarmax, TDOUBLE);
		tdec = (double *) get_mortalspace(nstarmax, TDOUBLE);
		tpra = (double *) get_mortalspace(nstarmax, TDOUBLE);
		tpdec = (double *) get_mortalspace(nstarmax, TDOUBLE);
		tpeak = (int *) get_mortalspace(nstarmax, TINT);
		tkey = (char **) get_mortalspace(nstarmax, TSTRING);

		mag = (double *) get_mortalspace(nmag * nstarmax, TDOUBLE);
		tmag = malloc(nmag * sizeof(double*));

		for (i=0; i<nmag; ++i)
			tmag[i] = mag + i * nstarmax;

		RETVAL = tabread(tabcatname,distsort,cra,cdec,dra,ddec,drad,dradi,sysout,eqout,epout,mag1,mag2,nstarmax,sortmag,&starcat,tnum,tra,tdec,tpra,tpdec,tmag,tpeak,tkey,nlog);

		nstar = RETVAL;

		tmagdims[0] = nmag;
		tmagdims[1] = nstar;

		mag_ = (double *) get_mortalspace(nmag * nstar, TDOUBLE);
		tmag_ = malloc(nmag * sizeof(double*));

		for (i=0; i<nmag; ++i)
			tmag_[i] = mag_ + i * nstar;
			for (j=0; j<nstar; ++j)
				tmag_[i][j] = tmag[i][j];

		free(tmag);
		free(tmag_);

		unpack1D(ST(16), tnum, nstar, TDOUBLE);
		unpack1D(ST(17), tra, nstar, TDOUBLE);
		unpack1D(ST(18), tdec, nstar, TDOUBLE);
		unpack1D(ST(19), tpra, nstar, TDOUBLE);
		unpack1D(ST(20), tpdec, nstar, TDOUBLE);
		unpack2D(ST(21), mag_, tmagdims, TDOUBLE);
		unpack1D(ST(22), tpeak, nstar, TINT);
		unpack1D(ST(23), tkey, nstar, TSTRING);

		for (i=0; i<nstar; i++)
			free(tkey[i]);

	OUTPUT:
		RETVAL

int
tabrnum(tabcatname,nnum,sysout,eqout,epout,starcat,match,tnum,tra,tdec,tpra,tpdec,tmag,tpeak,tkey,nlog)
	char * tabcatname
	int nnum
	int sysout
	double eqout
	double epout
	StarCat * starcat = NO_INIT
	int match
	double * tnum
	double * tra = NO_INIT
	double * tdec = NO_INIT
	double * tpra = NO_INIT
	double * tpdec = NO_INIT
	double ** tmag = NO_INIT
	int * tpeak = NO_INIT
	char **tkey = NO_INIT	
	int nlog
	PREINIT:
		long tmagdims[2];
	CODE:
		if (nnum < 0)
			nnum = 0;

		/* C routine creates the starcat if it's NULL, from
		   which it then gets the number of magnitudes. We'll
		   do the same here.
		*/
		tmagdims[0] = 0;
		if (sv_derived_from(ST(5), "StarCatPtr")) {
		   starcat = (StarCat*)SvIV((SV*)SvRV(ST(5)));
		   tmagdims[0] = starcat->nmag;
		}
		else {
		     ST(5) = sv_newmortal();
		     starcat = tabcatopen (tabcatname, NULL, 0);
		     if (starcat) {
			tmagdims[0] = starcat->nmag;
			sv_setref_pv(ST(5),"StarCatPtr",starcat);
		     }
		}
		
		tra = (double *)get_mortalspace(nnum,TDOUBLE);
		tdec = (double *)get_mortalspace(nnum,TDOUBLE);
		tpra = (double *)get_mortalspace(nnum,TDOUBLE);
		tpdec = (double *)get_mortalspace(nnum,TDOUBLE);
		tmag = (double **)get_mortalspace(tmagdims[0]*nnum,TDOUBLE);
		tpeak = (int *)get_mortalspace(nnum,TINT);
		tkey = (char **)get_mortalspace(nnum,TSTRING);

		RETVAL = tabrnum(tabcatname,nnum,sysout,eqout,epout,&starcat,match,tnum,tra,tdec,tpra,tpdec,tmag,tpeak,tkey,nlog);

		tmagdims[1] = RETVAL;

		unpack1D(ST(8),tra,RETVAL,TDOUBLE);
		unpack1D(ST(9),tdec,RETVAL,TDOUBLE);
		unpack1D(ST(10),tpra,RETVAL,TDOUBLE);
		unpack1D(ST(11),tpdec,RETVAL,TDOUBLE);
		unpack2D(ST(12),tmag,tmagdims,TDOUBLE);
		unpack1D(ST(13),tpeak,RETVAL,TINT);
		unpack1D(ST(14),tkey,RETVAL,TSTRING);
		{
			int i;
			for (i=0; i<RETVAL; i++)
				free(tkey[i]);
		}
	OUTPUT:
		RETVAL

int
tabxyread(tabcatname,xa,ya,ba,pa,nlog)
	char * tabcatname
	double * xa = NO_INIT
	double * ya = NO_INIT
	double * ba = NO_INIT
	int * pa = NO_INIT
	int nlog
	CODE:
		RETVAL = tabxyread(tabcatname,&xa,&ya,&ba,&pa,nlog);
		unpack1D(ST(1),xa,RETVAL,TDOUBLE);
		unpack1D(ST(2),ya,RETVAL,TDOUBLE);
		unpack1D(ST(3),ba,RETVAL,TDOUBLE);
		unpack1D(ST(4),pa,RETVAL,TINT);
		free(xa);
		free(ya);
		free(ba);
		free(pa);
	OUTPUT:
		RETVAL

int
tabrkey(tabcatname,starcat,nnum,tnum,keyword,tval)
	char * tabcatname
	StarCat * starcat = NO_INIT;
	int nnum
	double * tnum
	char * keyword
	char ** tval = NO_INIT
	CODE:
		/* C routine creates the starcat if it's NULL, from
		   which it then gets the number of magnitudes. We'll
		   do the same here.
		*/
		if (sv_derived_from(ST(1), "StarCatPtr")) {
		   starcat = (StarCat*)SvIV((SV*)SvRV(ST(1)));
		}
		else {
		     ST(1) = sv_newmortal();
		     starcat = tabcatopen (tabcatname, NULL, 0);
		     if (starcat)
			sv_setref_pv(ST(1),"StarCatPtr",starcat);
		}
		
		tval = (char **)get_mortalspace(nnum,TSTRING);
		RETVAL = tabrkey(tabcatname,&starcat,nnum,tnum,keyword,tval);
		unpack1D(ST(5),tval,RETVAL,TSTRING);
		{
			int i;
			for (i=0; i<RETVAL; i++)
				free(tval[i]);
		}
	OUTPUT:
		RETVAL

StarCat *
tabcatopen(tabfile, tabtable, nbbuff)
	char * tabfile
	TabTable * tabtable
	int nbbuff

void
tabcatclose(sc)
	StarCat * sc
	ALIAS:
		Astro::WCS::LibWCS::tabcatclose = 1
		StarCatPtr::tabcatclose = 2
		StarCatPtr::close = 3

int
tabstar(istar,sc,st,verbose)
	int istar
	StarCat * sc
	Star * st
	int verbose

TabTable *
tabopen(tabfile, nbbuff)
	char * tabfile
	int nbbuff

void
tabclose(tabtable)
	TabTable * tabtable
	ALIAS:
		Astro::WCS::LibWCS::tabclose = 1
		TabTablePtr::tabclose = 2
		TabTablePtr::close = 3

char *
gettabline(tabtable,iline)
	TabTable * tabtable
	int iline
	ALIAS:
		Astro::WCS::LibWCS::gettabline = 1
		TabTablePtr::gettabline = 2
		TabTablePtr::getline = 3

int
tabgetk(tabtable,tabtok,keyword,string,maxchar)
	TabTable * tabtable
	Tokens * tabtok
	char * keyword
	char * string = NO_INIT
	int maxchar
	ALIAS:
		Astro::WCS::LibWCS::tabgetk = 1
		TabTablePtr::tabgetk = 2
		TabTablePtr::getk = 3
	CODE:
		if (maxchar < 0)
			maxchar = 0;
		string = (char *)get_mortalspace(maxchar,TBYTE);
		RETVAL = tabgetk(tabtable,tabtok,keyword,string,maxchar);
	OUTPUT:
		RETVAL
		string
	
int
tabgetc(tabtok,ientry,string,maxchar)
	Tokens * tabtok
	int ientry
	char * string = NO_INIT
	int maxchar
	ALIAS:
		Astro::WCS::LibWCS::tabgetc = 1
		TabTablePtr::tabgetc = 2
		TabTablePtr::getc = 3
	CODE:
		if (maxchar < 0)
			maxchar = 0;
		string = (char *)get_mortalspace(maxchar,TBYTE);
		RETVAL = tabgetc(tabtok,ientry,string,maxchar);
	OUTPUT:
		RETVAL
		string

int
tabparse(tabtable)
	TabTable * tabtable
	ALIAS:
		Astro::WCS::LibWCS::tabparse = 1
		TabTablePtr::tabparse = 2
		TabTablePtr::parse = 3

int
tabcol(tabtable,keyword)
	TabTable * tabtable
	char * keyword
	ALIAS:
		Astro::WCS::LibWCS::tabcol = 1
		TabTablePtr::tabcol = 2
		TabTablePtr::col = 3

int
istab(filename)
	char * filename

##
##
## catutil.c
##
##

int
RefCat(refcatname,title,syscat,eqcat,epcat,catprop,nmag)
	char * refcatname
	char * title = NO_INIT
	int syscat = NO_INIT
	double eqcat = NO_INIT
	double epcat = NO_INIT
	int catprop = NO_INIT
	int nmag = NO_INIT
	CODE:
		title = get_mortalspace(1024,TBYTE); /* arbitrary buffer size... */
		RETVAL = RefCat(refcatname,title,&syscat,&eqcat,&epcat,&catprop,&nmag);
	OUTPUT:
		RETVAL
		title
		syscat
		eqcat
		epcat
		catprop
		nmag

int
CatCode(refcatname)
	char *refcatname

void
CatID(catid, refcat)
	char &catid = NO_INIT
	int refcat
	OUTPUT:
		catid

void
CatNum(refcat,nnfld,nndec,dnum,numstr)
	int refcat
	int nnfld
	int nndec
	double dnum
	char * numstr = NO_INIT
	CODE:
		numstr = (char *)get_mortalspace(80,TBYTE); /* arbitrary buffer size */
		CatNum(refcat,nnfld,nndec,dnum,numstr);
	OUTPUT:
		numstr

int
CatNumLen(refcat,maxnum,nndec)
	int refcat
	double maxnum
	int nndec

int
CatNdec(refcat)
	int refcat

void
CatMagName(imag, refcat, magname)
	int imag
	int refcat
	char * magname = NO_INIT
	CODE:
		/* FIXME: will magname ever be more then 5 chars? */
		magname = (char *)get_mortalspace(11, TBYTE);
		CatMagName(imag,refcat,magname);
	OUTPUT:
		magname

int
CatMagNum(imag,refcat)
	int imag
	int refcat

int
StrNdec(string)
	char * string

int
NumNdec(number)
	double number

void
SearchLim(cra,cdec,dra,ddec,syscorr,ra1,ra2,dec1,dec2,verbose)
	double cra
	double cdec
	double dra
	double ddec
	int syscorr
	double &ra1 = NO_INIT
	double &ra2 = NO_INIT
	double &dec1 = NO_INIT
	double &dec2 = NO_INIT
	int verbose
	OUTPUT:
		ra1
		ra2
		dec1
		dec2

void
RefLim(cra,cdec,dra,ddec,sysc,sysr,eqc,eqr,epc,epr,secmarg,ramin,ramax,decmin,decmax,wrap,verbose)
	double cra
	double cdec
	double dra
	double ddec
	int sysc
	int sysr
	double eqc
	double eqr
	double epc
	double epr
	double secmarg
	double &ramin = NO_INIT
	double &ramax = NO_INIT
	double &decmin = NO_INIT
	double &decmax = NO_INIT
	int &wrap = NO_INIT
	int verbose
	OUTPUT:
		ramin
		ramax
		decmin
		decmax
		wrap

Range *
RangeInit(string,ndef)
	char * string
	int ndef

int
isrange(string)
	char * string

void
rstart(range)
	Range * range
	ALIAS:
		Astro::WCS::LibWCS::rstart = 1
		RangePtr::rstart = 2
		RangePtr::start = 3

int
rgetn(range)
	Range * range
	ALIAS:
		Astro::WCS::LibWCS::rgetn = 1
		RangePtr::rgetn = 2
		RangePtr::getn = 3

double
rgetr8(range)
	Range * range
	ALIAS:
		Astro::WCS::LibWCS::rgetr8 = 1
		RangePtr::rgetr8 = 2
		RangePtr::getr8 = 3

int
rgeti4(range)
	Range * range
	ALIAS:
		Astro::WCS::LibWCS::rgeti4 = 1
		RangePtr::rgeti4 = 2
		RangePtr::geti4 = 3

##
##
## dateutil.c
##
##

void
ang2hr(angle,lstr,string)
	double angle
	int lstr
	char * string = NO_INIT
	CODE:
		if (lstr <= 0)
			lstr = 2880;
		string = get_mortalspace(lstr,TBYTE);
		ang2hr(angle, lstr, string );
	OUTPUT:
		string

void
ang2deg(angle,lstr,string)
	double angle
	int lstr
	char * string = NO_INIT
	CODE:
		if (lstr <= 0)
			lstr = 2880;
		string = get_mortalspace(lstr,TBYTE);
		ang2deg(angle, lstr, string );
	OUTPUT:
		string


double
deg2ang( angle )
	 char * angle


double
hr2ang( angle )
	char *angle

char *
dt2fd(date,time)
	double date
	double time

double
dt2jd(date,time)
	double date
	double time

double
dt2mjd(date,time)
	double date
	double time

double
hjd2jd(hjd, ra, dec, sys )
	double hjd
	double ra
	double dec
	int sys

double
jd2hjd(jd, ra, dec, sys )
	double jd
	double ra
	double dec
	int sys

double
mhjd2mjd(mhjd, ra, dec, sys )
	double mhjd
	double ra
	double dec
	int sys

double
mjd2mhjd(mjd, ra, dec, sys )
	double mjd
	double ra
	double dec
	int sys

void
jd2dt(jd,date,time)
	double jd
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

void
jd2i(jd,iyr,imon,iday,ihr,imn,sec,ndsec)
	double jd
	int &iyr = NO_INIT
	int &imon = NO_INIT
	int &iday = NO_INIT
	int &ihr = NO_INIT
	int &imn = NO_INIT
	double &sec = NO_INIT
	int ndsec
	OUTPUT:
		iyr
		imon
		iday
		ihr
		imn
		sec

double
jd2mjd(jd)
	double jd

double
jd2ep(jd)
	double jd

double
jd2epb(jd)
	double jd

double
jd2epj(jd)
	double jd

void
lt2dt(date,time)
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

char *
lt2fd()

int
lt2tsi()

long
lt2tsu()

double
lt2ts()

void
mjd2dt(jd,date,time)
	double jd
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

void
mjd2i(jd,iyr,imon,iday,ihr,imn,sec,ndsec)
	double jd
	int &iyr = NO_INIT
	int &imon = NO_INIT
	int &iday = NO_INIT
	int &ihr = NO_INIT
	int &imn = NO_INIT
	double &sec = NO_INIT
	int ndsec
	OUTPUT:
		iyr
		imon
		iday
		ihr
		imn
		sec

void
mjd2doy(jd, year, doy)
	double jd
	int &year = NO_INIT
	double &doy = NO_INIT
	OUTPUT:
		year
		doy

double
mjd2jd(jd)
	double jd

double
mjd2ep(jd)
	double jd

double
mjd2epb(jd)
	double jd

double
mjd2epj(jd)
	double jd

char *
mjd2fd(jd)
	double jd

double
mjd2ts(jd)
	double jd

char *
ep2fd(epoch)
	double epoch

char *
epb2fd(epoch)
	double epoch

char *
epj2fd(epoch)
	double epoch

double
ep2ts(epoch)
	double epoch

double
epb2ts(epoch)
	double epoch

double
epj2ts(epoch)
	double epoch

double
epb2ep(epoch)
	double epoch

double
ep2epb(epoch)
	double epoch

double
epj2ep(epoch)
	double epoch

double
ep2epj(epoch)
	double epoch

void
ep2i(epoch,iyr,imon,iday,ihr,imn,sec,ndsec)
	double epoch
	int &iyr = NO_INIT
	int &imon = NO_INIT
	int &iday = NO_INIT
	int &ihr = NO_INIT
	int &imn = NO_INIT
	double &sec = NO_INIT
	int ndsec
	OUTPUT:
		iyr
		imon
		iday
		ihr
		imn
		sec

void
epb2i(epoch,iyr,imon,iday,ihr,imn,sec,ndsec)
	double epoch
	int &iyr = NO_INIT
	int &imon = NO_INIT
	int &iday = NO_INIT
	int &ihr = NO_INIT
	int &imn = NO_INIT
	double &sec = NO_INIT
	int ndsec
	OUTPUT:
		iyr
		imon
		iday
		ihr
		imn
		sec

void
epj2i(epoch,iyr,imon,iday,ihr,imn,sec,ndsec)
	double epoch
	int &iyr = NO_INIT
	int &imon = NO_INIT
	int &iday = NO_INIT
	int &ihr = NO_INIT
	int &imn = NO_INIT
	double &sec = NO_INIT
	int ndsec
	OUTPUT:
		iyr
		imon
		iday
		ihr
		imn
		sec

double
ep2jd(epoch)
	double epoch

double
epb2jd(epoch)
	double epoch

double
epj2jd(epoch)
	double epoch

double
ep2mjd(epoch)
	double epoch

double
epb2mjd(epoch)
	double epoch

double
epj2mjd(epoch)
	double epoch

double
epb2epj(epoch)
	double epoch

double
epj2epb(epoch)
	double epoch

char *
jd2fd(jd)
	double jd

double
jd2ts(jd)
	double jd

int
jd2tsi(jd)
	double jd

time_t
jd2tsu(jd)
	double jd

void
dt2doy(date,time,year,doy)
	double date
	double time
	int &year = NO_INIT
	double &doy = NO_INIT
	OUTPUT:
		year
		doy

void
doy2dt(year, doy, date, time)
	int year
	double doy
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

double
doy2ep(year,doy)
	int year
	double doy

double
doy2epb(year,doy)
	int year
	double doy

double
doy2epj(year,doy)
	int year
	double doy

char *
doy2fd(year,doy)
	int year
	double doy

double
doy2jd(year,doy)
	int year
	double doy

double
doy2mjd(year,doy)
	int year
	double doy

time_t
doy2tsu(year,doy)
	int year
	double doy

int
doy2tsi(year,doy)
	int year
	double doy

double
doy2ts(year,doy)
	int year
	double doy

void
fd2doy(string,year,doy)
	char *string
	int &year = NO_INIT
	double &doy = NO_INIT
	OUTPUT:
		year
		doy

void
jd2doy(jd,year,doy)
	double jd
	int &year = NO_INIT
	double &doy = NO_INIT
	OUTPUT:
		year
		doy

double
ts2jd(tsec)
	double tsec

double
ts2mjd(tsec)
	double tsec

double
ts2ep(tsec)
	double tsec

double
ts2epb(tsec)
	double tsec

double
ts2epj(tsec)
	double tsec

double
dt2ep(date,time)
	double date
	double time

double
dt2epb(date,time)
	double date
	double time

double
dt2epj(date,time)
	double date
	double time

void
ep2dt(epoch,date,time)
	double epoch
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

void
epb2dt(epoch,date,time)
	double epoch
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

void
epj2dt(epoch,date,time)
	double epoch
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

double
fd2jd(string)
	char * string

double
fd2mjd(string)
	char * string

long
fd2tsu(string)
	char * string

int
fd2tsi(string)
	char * string

double
fd2ts(string)
	char * string

char *
fd2fd(string)
	char * string

char *
fd2of(string)
	char * string

char *
et2fd(string)
	char * string

char *
fd2et(string)
	char * string

void
dt2et(date,time)
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

void
edt2dt(date,time)
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

double
jd2jed(jd)
	double jd

double
jed2jd(jed)
	double jed

double
ts2ets(tsec)
	double tsec

double
ets2ts(tsec)
	double tsec

double
utdt(tsec)
	double tsec

char *
fd2ofd(string)
	char * string

char *
fd2oft(string)
	char * string

void
fd2dt(string,date,time)
	char * string
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

double
fd2ep(string)
	char * string

double
fd2epb(string)
	char * string

double
fd2epj(string)
	char * string

long
dt2tsu(date,time)
	double date
	double time

int
dt2tsi(date,time)
	double date
	double time

double
dt2ts(date,time)
	double date
	double time

void
ts2dt(tsec,date,time)
	double tsec
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

void
tsi2dt(isec,date,time)
	int isec
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

char *
tsi2fd(isec)
	int isec

double
tsi2ts(isec)
	int isec

char *
tsu2fd(isec)
	long isec

void
tsu2dt(isec,date,time)
	long isec
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

double
tsu2ts(isec)
	long isec

int
tsu2tsi(isec)
	long isec

char *
ts2fd(sec)
	double sec

void
dt2i(date, time, iyr, imon, iday, ihr, imin, sec, ndsec)
	double date
	double time
	int &iyr = NO_INIT
	int &imon = NO_INIT
	int &iday = NO_INIT
	int &ihr = NO_INIT
	int &imin = NO_INIT
	double &sec = NO_INIT
	int ndsec
	OUTPUT:
		iyr
		imon
		iday
		ihr
		imin
		sec

void
fd2i(string, iyr, imon, iday, ihr, imin, sec, ndsec)
	char * string
	int &iyr = NO_INIT
	int &imon = NO_INIT
	int &iday = NO_INIT
	int &ihr = NO_INIT
	int &imin = NO_INIT
	double &sec = NO_INIT
	int ndsec
	OUTPUT:
		iyr
		imon
		iday
		ihr
		imin
		sec

void
ts2i(tsec,iyr,imon,iday,ihr,imn,sec,ndsec)
	double tsec
	int &iyr = NO_INIT
	int &imon = NO_INIT
	int &iday = NO_INIT
	int &ihr = NO_INIT
	int &imn = NO_INIT
	double &sec = NO_INIT
	int ndsec
	OUTPUT:
		iyr
		imon
		iday
		ihr
		imn
		sec

void
ut2doy(year,doy)
	int &year = NO_INIT
	double &doy = NO_INIT
	OUTPUT:
		year
		doy

void
ut2dt(date,time)
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

double
ut2ep()

double
ut2epb()

double
ut2epj()

char *
ut2fd()

double
ut2jd()

double
ut2mjd()

double
ut2ts()

int
ut2tsi()

long
ut2tsu()

char *
fd2gst(string)
	char * string

void
dt2gst(date,time)
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

double
ts2gst(tsec)
	double tsec

char *
fd2mst(string)
	char * string

void
dt2mst(date,time)
	double &date = NO_INIT
	double &time = NO_INIT
	OUTPUT:
		date
		time

double
ts2mst(tsec)
	double tsec

double
jd2mst2(dj)
	double dj

double
mjd2mst(dj)
	double dj

void
compnut(jd, dpsi, deps, eps0)
	double jd
	double &dpsi = NO_INIT
	double &deps = NO_INIT
	double &eps0 = NO_INIT
	OUTPUT:
		dpsi
		deps
		eps0

int
isdate(string)
	char * string

##
##
## findstar.c
##
##

int
FindStars(header,image,xa,ya,ba,pa,verbose,zap)
	char * header
	char * image
	double * xa = NO_INIT
	double * ya = NO_INIT
	double * ba = NO_INIT
	int * pa = NO_INIT
	int verbose
	int zap
	CODE:
		RETVAL = FindStars(header,image,&xa,&ya,&ba,&pa,verbose,zap);
		unpack1D(ST(2),xa,RETVAL,TDOUBLE);
		unpack1D(ST(3),ya,RETVAL,TDOUBLE);
		unpack1D(ST(4),ba,RETVAL,TDOUBLE);
		unpack1D(ST(5),pa,RETVAL,TINT);
		free(xa);
		free(ya);
		free(ba);
		free(pa);
	OUTPUT:
		RETVAL

void
setparm(parstring)
	char * parstring

##
##
## imsetwcs.c
##
##

int
SetWCSFITS (filename,header,image,refcatname,verbose)
	char * filename
	char * header
	char * image
	char * refcatname
	int verbose

void
settolerance(tol)
	double tol

void
setirafout()

void
setmatch(cat)
	char * cat

void
setreflim(lim1,lim2)
	double lim1
	double lim2

void
setfitwcs(wfit)
	int wfit

void
setfitplate(nc)
	int nc

void
setminstars(minstars)
	int minstars

void
setnofit()

void
setfrac(frac0)
	double frac0

void
setimfrac(frac0)
	double frac0

void
setmaxcat(ncat)
	int ncat

void
setiterate(iter)
	int iter

void
setnfiterate(iter)
	int iter

void
setiteratet(iter)
	int iter

void
setrecenter(recenter)
	int recenter

void
setsortmag(imag)
	int imag

void
setmagfit()

##
##
## matchstar.c
##
##

int
StarMatch(ns,sx,sy,refcat,ng,gnum,gra,gdec,goff,gx,gy,tol,wcs,debug)
	int ns
	double * sx
	double * sy
	int refcat
	int ng
	double * gnum
	double * gra
	double * gdec
	int * goff
	double * gx
	double * gy
	double tol
	WCS * wcs = NO_INIT
	int     debug
	CODE:
		wcs = malloc(sizeof(WCS));
		RETVAL = StarMatch(ns,sx,sy,refcat,ng,gnum,gra,gdec,goff,gx,gy,tol,wcs,debug);
	OUTPUT:
		RETVAL
		wcs

int
ParamFit(nbin)
	int nbin

int
NParamFit(nbin)
	int nbin

int
ReadMatch(filename,sbx,sby,gbra,gbdec,debug)
	char * filename
	double * sbx = NO_INIT
	double * sby = NO_INIT
	double * gbra = NO_INIT
	double * gbdec = NO_INIT
	int debug
	CODE:
		RETVAL = ReadMatch(filename,&sbx,&sby,&gbra,&gbdec,debug);
		unpack1D(ST(1),sbx,RETVAL,TDOUBLE);
		unpack1D(ST(2),sby,RETVAL,TDOUBLE);
		unpack1D(ST(3),gbra,RETVAL,TDOUBLE);
		unpack1D(ST(4),gbdec,RETVAL,TDOUBLE);
		free(sbx);
		free(sby);
		free(gbra);
		free(gbdec);
	OUTPUT:
		RETVAL
		

void
WCSMatch(nmatch,sbx,sby,gbra,gbdec,debug)
	int nmatch
	double * sbx
	double * sby
	double * gbra
	double * gbdec
	int debug

int
FitMatch(nmatch, sbx, sby, gbra, gbdec, wcs, debug)
	int nmatch
	double * sbx
	double * sby
	double * gbra
	double * gbdec
	WCS * wcs = NO_INIT
	int     debug
	CODE:
		wcs = malloc(sizeof(WCS));
		RETVAL = FitMatch(nmatch, sbx, sby, gbra, gbdec, wcs, debug);
	OUTPUT:
		RETVAL
		wcs

void
setresid_refine(refine)
	int refine

int
getresid_refine()

void
setnfit(nfit)
	int nfit

int
getnfit()

int
iscdfit()

void
setminmatch(minmatch)
	int minmatch

void
setminbin(minbin1)
	int minbin1

void
setnitmax(nitmax)
	int nitmax

##
##
## sortstar.c
##
##

void
FluxSortStars(sx,sy,sb,sc,ns)
	double * sx
	double * sy
	double * sb
	int * sc
	int ns
	CODE:
		FluxSortStars(sx,sy,sb,sc,ns);
		unpack1D(ST(0),sx,ns,TDOUBLE);
		unpack1D(ST(1),sy,ns,TDOUBLE);
		unpack1D(ST(2),sb,ns,TDOUBLE);
		unpack1D(ST(3),sc,ns,TINT);

void
MagSortStars(sn,sra,sdec,spra,spdec,sx,sy,sm,sc,sobj,ns,nm,ms)
	double * sn
	double * sra
	double * sdec
	double * spra
	double * spdec
	double * sx
	double * sy
	double * sm
	int * sc
	char ** sobj
	int ns
	int nm
	int ms
	PREINIT:
		long magdims[2];
	CODE:
		MagSortStars(sn,sra,sdec,spra,spdec,sx,sy,&sm,sc,sobj,ns,nm,ms);

		magdims[0] = nm;
		magdims[1] = ns;

		unpack1D(ST(0),sn,ns,TDOUBLE);
		unpack1D(ST(1),sra,ns,TDOUBLE);
		unpack1D(ST(2),sdec,ns,TDOUBLE);
		unpack1D(ST(3),spra,ns,TDOUBLE);
		unpack1D(ST(4),spdec,ns,TDOUBLE);
		unpack1D(ST(5),sx,ns,TDOUBLE);
		unpack1D(ST(6),sy,ns,TDOUBLE);
		unpack2D(ST(7),sm,magdims,TDOUBLE);
		unpack1D(ST(8),sc,ns,TINT);
		unpack1D(ST(9),sobj,ns,TSTRING);

void
RASortStars(sn,sra,sdec,spra,spdec,sx,sy,sm,sc,sobj,ns,nm)
	double * sn
	double * sra
	double * sdec
	double * spra
	double * spdec
	double * sx
	double * sy
	double * sm
	int * sc
	char ** sobj
	int ns
	int nm
	PREINIT:
		long magdims[2];
	CODE:
		RASortStars(sn,sra,sdec,spra,spdec,sx,sy,&sm,sc,sobj,ns,nm);

		magdims[0] = nm;
		magdims[1] = ns;

		unpack1D(ST(0),sn,ns,TDOUBLE);
		unpack1D(ST(1),sra,ns,TDOUBLE);
		unpack1D(ST(2),sdec,ns,TDOUBLE);
		unpack1D(ST(3),spra,ns,TDOUBLE);
		unpack1D(ST(4),spdec,ns,TDOUBLE);
		unpack1D(ST(5),sx,ns,TDOUBLE);
		unpack1D(ST(6),sy,ns,TDOUBLE);
		unpack2D(ST(7),sm,magdims,TDOUBLE);
		unpack1D(ST(8),sc,ns,TINT);
		unpack1D(ST(9),sobj,ns,TSTRING);

void
XSortStars(sn,sra,sdec,spra,spdec,sx,sy,sm,sc,sobj,ns,nm)
	double * sn
	double * sra
	double * sdec
	double * spra
	double * spdec
	double * sx
	double * sy
	double * sm
	int * sc
	char ** sobj
	int ns
	int nm
	PREINIT:
		long magdims[2];
	CODE:
		XSortStars(sn,sra,sdec,spra,spdec,sx,sy,&sm,sc,sobj,ns,nm);

		magdims[0] = nm;
		magdims[1] = ns;

		unpack1D(ST(0),sn,ns,TDOUBLE);
		unpack1D(ST(1),sra,ns,TDOUBLE);
		unpack1D(ST(2),sdec,ns,TDOUBLE);
		unpack1D(ST(3),spra,ns,TDOUBLE);
		unpack1D(ST(4),spdec,ns,TDOUBLE);
		unpack1D(ST(5),sx,ns,TDOUBLE);
		unpack1D(ST(6),sy,ns,TDOUBLE);
		unpack2D(ST(7),sm,magdims,TDOUBLE);
		unpack1D(ST(8),sc,ns,TINT);
		unpack1D(ST(9),sobj,ns,TSTRING);

##
##
## fitsfile.c
##
##

SV *
fitsrhead(filename,lhead,nbhead)
	char * filename
	int lhead = NO_INIT
	int nbhead = NO_INIT
	PREINIT:
		char * header;
	CODE:
		header = fitsrhead(filename,&lhead,&nbhead);
		ST(0) = sv_newmortal();
		if (!header) {
			ST(0) = &PL_sv_undef;
			lhead = nbhead = 0;
		}
		else {
			sv_setpvn(ST(0), header, lhead);
			free(header);
		}
	OUTPUT:
		lhead
		nbhead

int
fitsropen(inpath)
	char * inpath

int
fitsrtopen(inpath,nk,kw,nrows,nchar,nbhead)
	char * inpath
	int nk
	Keyword *kw = NO_INIT
	int nrows = NO_INIT
	int nchar = NO_INIT
	int nbhead = NO_INIT
	CODE:
		RETVAL = fitsrtopen(inpath,&nk,&kw,&nrows,&nchar,&nbhead);
		if (!kw)
			ST(0) = &PL_sv_undef;
		else {
			sv_setref_pv(ST(2),"KeywordPtr",kw);
			free(kw);
		}
	OUTPUT:
		RETVAL
		nk
		nrows
		nchar
		nbhead

int
fitsrthead(header,nk,kw,nrows,nchar)
	char * header
	int nk
	Keyword *kw = NO_INIT
	int nrows = NO_INIT
	int nchar = NO_INIT
	CODE:
		RETVAL = fitsrthead(header,&nk,&kw,&nrows,&nchar);
		if (!kw)
			ST(0) = &PL_sv_undef;
		else {
			sv_setref_pv(ST(2),"KeywordPtr",kw);
			free(kw);
		}
	OUTPUT:
		RETVAL
		nk
		nrows
		nchar

##
## routines for getting struct info from the WCSPtr (WorldCoor)
##

MODULE = Astro::WCS::LibWCS		PACKAGE = WCSPtr

double
xref(wcs)
	WCS * wcs
	CODE:
		RETVAL = wcs->xref;
	OUTPUT:
		RETVAL

double
yref(wcs)
	WCS * wcs
	CODE:
		RETVAL = wcs->yref;
	OUTPUT:
		RETVAL

double
xrefpix(wcs)
	WCS * wcs
	CODE:
		RETVAL = wcs->xrefpix;
	OUTPUT:
		RETVAL

double
yrefpix(wcs)
	WCS * wcs
	CODE:
		RETVAL = wcs->yrefpix;
	OUTPUT:
		RETVAL

double
xinc(wcs)
	WCS * wcs
	CODE:
		RETVAL = wcs->xinc;
	OUTPUT:
		RETVAL

double
yinc(wcs)
	WCS * wcs
	CODE:
		RETVAL = wcs->yinc;
	OUTPUT:
		RETVAL

##
## routines for getting data out of StarCatPtr objects
##

MODULE = Astro::WCS::LibWCS		PACKAGE = StarCatPtr

int
nstars(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->nstars;
	OUTPUT:
		RETVAL


int
rasorted(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->rasorted;
	OUTPUT:
		RETVAL

int
coorsys(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->coorsys;
	OUTPUT:
		RETVAL

double
epoch(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->epoch;
	OUTPUT:
		RETVAL

double
equinox(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->equinox;
	OUTPUT:
		RETVAL

int
istar(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->istar;
	OUTPUT:
		RETVAL

char *
dir(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->incdir;
	OUTPUT:
		RETVAL

char *
file(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->incfile;
	OUTPUT:
		RETVAL

char *
name(sc)
	StarCat * sc
	CODE:
		RETVAL = sc->isname;
	OUTPUT:
		RETVAL


##
## routines for getting data out of TabTablePtr objects
##

MODULE = Astro::WCS::LibWCS		PACKAGE = TabTablePtr



# catread.c doesn't seem to be compiled into the library

####
####
#### catread.c
####
####
##
##int
##catread(catfile,refcat,distsort,cra,cdec,dra,ddec,drad,sysout,eqout,epout,mag1,mag2,nsmax,tnum,tra,tdec,tmag,tmagb,tc,tobj,nlog)
##	char * catfile
##	int refcat
##	int distsort
##	double cra
##	double cdec
##	double dra
##	double ddec
##	double drad
##	int sysout
##	double eqout
##	double epout
##	double mag1
##	double mag2
##	int nsmax
##	double * tnum = NO_INIT
##	double * tra = NO_INIT
##	double * tdec = NO_INIT
##	double * tmag = NO_INIT
##	double * tmagb = NO_INIT
##	int * tc = NO_INIT
##	char **tobj = NO_INIT
##	int nlog
##	CODE:
##		if (nsmax < 0)
##			nsmax = 0;
##		tnum = (double *)get_mortalspace(nsmax,TDOUBLE);
##		tra = (double *)get_mortalspace(nsmax,TDOUBLE);
##		tdec = (double *)get_mortalspace(nsmax,TDOUBLE);
##		tmag = (double *)get_mortalspace(nsmax,TDOUBLE);
##		tmagb = (double *)get_mortalspace(nsmax,TDOUBLE);
##		tc = (int *)get_mortalspace(nsmax,TINT);
##		tobj = (char **)get_mortalspace(nsmax,TSTRING);
##		RETVAL = catread(catfile,refcat,distsort,cra,cdec,dra,ddec,drad,sysout,eqout,epout,mag1,mag2,nsmax,tnum,tra,tdec,tmag,tmagb,tc,tobj,nlog);
##		unpack1D(ST(14),tnum,RETVAL,TDOUBLE);
##		unpack1D(ST(15),tra,RETVAL,TDOUBLE);
##		unpack1D(ST(16),tdec,RETVAL,TDOUBLE);
##		unpack1D(ST(17),tmag,RETVAL,TDOUBLE);
##		unpack1D(ST(18),tmagb,RETVAL,TDOUBLE);
##		unpack1D(ST(19),tc,RETVAL,TINT);
##		unpack1D(ST(20),tobj,RETVAL,TSTRING);
##		{
##			int i;
##			for (i=0; i<RETVAL; i++)
##				free(tobj[i]);
##		}
##	OUTPUT:
##		RETVAL
##
##int
##catrnum(catfile,refcat,nnum,sysout,eqout,epout,match,tnum,tra,tdec,tmag,tmagb,tc,tobj,nlog)
##	char * catfile
##	int refcat
##	int nnum
##	int sysout
##	double eqout
##	double epout
##	int match
##	double * tnum = NO_INIT
##	double * tra = NO_INIT
##	double * tdec = NO_INIT
##	double * tmag = NO_INIT
##	double * tmagb = NO_INIT
##	int * tc = NO_INIT
##	char **tobj = NO_INIT	
##	int nlog
##	CODE:
##		if (nnum < 0)
##			nnum = 0;
##		tnum = (double *)get_mortalspace(nnum,TDOUBLE);
##		tra = (double *)get_mortalspace(nnum,TDOUBLE);
##		tdec = (double *)get_mortalspace(nnum,TDOUBLE);
##		tmag = (double *)get_mortalspace(nnum,TDOUBLE);
##		tmagb = (double *)get_mortalspace(nnum,TDOUBLE);
##		tc = (int *)get_mortalspace(nnum,TINT);
##		tobj = (char **)get_mortalspace(nnum,TSTRING);
##		RETVAL = catrnum(catfile,refcat,nnum,sysout,eqout,epout,match,tnum,tra,tdec,tmag,tmagb,tc,tobj,nlog);
##		unpack1D(ST(7),tnum,RETVAL,TDOUBLE);
##		unpack1D(ST(8),tra,RETVAL,TDOUBLE);
##		unpack1D(ST(9),tdec,RETVAL,TDOUBLE);
##		unpack1D(ST(10),tmag,RETVAL,TDOUBLE);
##		unpack1D(ST(11),tmagb,RETVAL,TDOUBLE);
##		unpack1D(ST(12),tc,RETVAL,TINT);
##		unpack1D(ST(13),tobj,RETVAL,TSTRING);
##		{
##			int i;
##			for (i=0; i<RETVAL; i++)
##				free(tobj[i]);
##		}
##	OUTPUT:
##		RETVAL
##
##SV *
##catopen(catfile,refcat)
##	char * catfile
##	int  refcat
##	PREINIT:
##		StarCat * sc;
##	CODE:
##		sc = catopen(catfile,refcat);
##		ST(0) = sv_newmortal();
##		if (!sc)
##			ST(0) = &PL_sv_undef;
##		else
##			sv_setref_pv(ST(0),"StarCatPtr",sc);
##
##void
##catclose(sc,refcat)
##	StarCat * sc
##	int refcat
##	ALIAS:
##		Astro::WCS::LibWCS::catclose = 1
##		StarCatPtr::catclose = 2
##
##
##
