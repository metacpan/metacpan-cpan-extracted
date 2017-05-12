#include <isam.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined (CISAM4)
int isreclen;
#endif

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
        if (strEQ(name, "AUDGETNAME"))
#ifdef AUDGETNAME
            return AUDGETNAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "AUDHEADSIZE"))
#ifdef AUDHEADSIZE
            return AUDHEADSIZE;
#else
            goto not_there;
#endif
        if (strEQ(name, "AUDINFO"))
#ifdef AUDINFO
            return AUDINFO;
#else
            goto not_there;
#endif
        if (strEQ(name, "AUDSETNAME"))
#ifdef AUDSETNAME
            return AUDSETNAME;
#else
            goto not_there;
#endif
        if (strEQ(name, "AUDSTART"))
#ifdef AUDSTART
            return AUDSTART;
#else
            goto not_there;
#endif
        if (strEQ(name, "AUDSTOP"))
#ifdef AUDSTOP
            return AUDSTOP;
#else
            goto not_there;
#endif                                                                  
	break;
    case 'B':
	break;
    case 'C':
	if (strEQ(name, "CHARTYPE"))
#ifdef CHARTYPE
	    return CHARTYPE;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DECIMALTYPE"))
#ifdef DECIMALTYPE
	    return DECIMALTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DOUBLETYPE"))
#ifdef DOUBLETYPE
	    return DOUBLETYPE;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	break;
    case 'F':
	if (strEQ(name, "FLOATTYPE"))
#ifdef FLOATTYPE
	    return FLOATTYPE;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	if (strEQ(name, "INTTYPE"))
#ifdef INTTYPE
	    return INTTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISAUTOLOCK"))
#ifdef ISAUTOLOCK
	    return ISAUTOLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISCLOSED"))
#ifdef ISCLOSED
	    return ISCLOSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISCURR"))
#ifdef ISCURR
	    return ISCURR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISD1"))
#ifdef ISD1
	    return ISD1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISD2"))
#ifdef ISD2
	    return ISD2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISDD"))
#ifdef ISDD
	    return ISDD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISDESC"))
#ifdef ISDESC
	    return ISDESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISDUPS"))
#ifdef ISDUPS
	    return ISDUPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISEQUAL"))
#ifdef ISEQUAL
	    return ISEQUAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISEXCLLOCK"))
#ifdef ISEXCLLOCK
	    return ISEXCLLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISFIRST"))
#ifdef ISFIRST
	    return ISFIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISFIXLEN"))
#ifdef ISFIXLEN
	    return ISFIXLEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISGREAT"))
#ifdef ISGREAT
	    return ISGREAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISGTEQ"))
#ifdef ISGTEQ
	    return ISGTEQ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISINOUT"))
#ifdef ISINOUT
	    return ISINOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISINPUT"))
#ifdef ISINPUT
	    return ISINPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISLAST"))
#ifdef ISLAST
	    return ISLAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISLCKW"))
#ifdef ISLCKW
	    return ISLCKW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISLOCK"))
#ifdef ISLOCK
	    return ISLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISMANULOCK"))
#ifdef ISMANULOCK
	    return ISMANULOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISMASKED"))
#ifdef ISMASKED
	    return ISMASKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISNEXT"))
#ifdef ISNEXT
	    return ISNEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISNOCARE"))
#ifdef ISNOCARE
	    return ISNOCARE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISNODUPS"))
#ifdef ISNODUPS
	    return ISNODUPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISNOLOG"))
#ifdef ISNOLOG
	    return ISNOLOG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISOUTPUT"))
#ifdef ISOUTPUT
	    return ISOUTPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISPREV"))
#ifdef ISPREV
	    return ISPREV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISRDONLY"))
#ifdef ISRDONLY
	    return ISRDONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISSYNCWR"))
#ifdef ISSYNCWR
	    return ISSYNCWR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISTRANS"))
#ifdef ISTRANS
	    return ISTRANS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISVARCMP"))
#ifdef ISVARCMP
	    return ISVARCMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISVARLEN"))
#ifdef ISVARLEN
	    return ISVARLEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ISWAIT"))
#ifdef ISWAIT
	    return ISWAIT;
#else
	    goto not_there;
#endif
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	if (strEQ(name, "LONGTYPE"))
#ifdef LONGTYPE
	    return LONGTYPE;
#else
	    goto not_there;
#endif
	break;
    case 'M':
	if (strEQ(name, "MINTTYPE"))
#ifdef MINTTYPE
	    return MINTTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MLONGTYPE"))
#ifdef MLONGTYPE
	    return MLONGTYPE;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	if (strEQ(name, "STRINGTYPE"))
#ifdef STRINGTYPE
	    return STRINGTYPE;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case 'a':
	break;
    case 'b':
	break;
    case 'c':
	break;
    case 'd':
	break;
    case 'e':
	break;
    case 'f':
	break;
    case 'g':
	break;
    case 'h':
	break;
    case 'i':
	break;
    case 'j':
	break;
    case 'k':
	break;
    case 'l':
	break;
    case 'm':
	break;
    case 'n':
	break;
    case 'o':
	break;
    case 'p':
	break;
    case 'q':
	break;
    case 'r':
	break;
    case 's':
	break;
    case 't':
	break;
    case 'u':
	break;
    case 'v':
	break;
    case 'w':
	break;
    case 'x':
	break;
    case 'y':
	break;
    case 'z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = CIsam	PACKAGE = CIsam		


double
constant(name,arg)
	char *		name
	int		arg

int
iserrno_get()
	CODE:
	RETVAL = iserrno;
	OUTPUT:
	RETVAL

void
iserrno_put(val)
	int	val
	CODE:
	iserrno = val;

long
isrecnum_get()
	CODE:
	RETVAL = isrecnum;
	OUTPUT:
	RETVAL

void
isrecnum_put(val)
	long	val
	CODE:
	isrecnum = val;

int
isreclen_get()
	CODE:
	RETVAL = isreclen;
	OUTPUT:
	RETVAL

void
isreclen_put(val)
	int	val
	CODE:
	isreclen = val;

int
iserrio_get()
	CODE:
	RETVAL = iserrio;
	OUTPUT:
	RETVAL

void
iserrio_put(val)
	int	val
	CODE:
	iserrio = val;

int
isaddindex1(fd,k_flags,k_nparts, ...)
	int  	fd
	short	k_flags
	short 	k_nparts
	PREINIT:
	struct keydesc kd;
	int ind;
	int offset;
	CODE:
	kd.k_flags = k_flags;
	kd.k_nparts = k_nparts;
	for (ind = 0; ind < k_nparts; ind++) {
	  offset = 3 + 3*ind;
 	  kd.k_part[ind].kp_start = (short)SvIV(ST(offset));
 	  kd.k_part[ind].kp_leng = (short)SvIV(ST(offset+1));
 	  kd.k_part[ind].kp_type = (short)SvIV(ST(offset+2));
  	}
        RETVAL = isaddindex(fd,&kd);
        if (RETVAL < 0) {
	   printf("cc=%d isaddindex1-iserrno(%d)\n",RETVAL,iserrno);
        }
        OUTPUT:
	RETVAL

int
isaudit1(fd,filename,mode)
	int	fd;
	char *	filename
	int	mode
	CODE:
	RETVAL = isaudit(fd,filename,mode);
  	OUTPUT:
	RETVAL

int
isbegin1()
	CODE:
	RETVAL = isbegin();
  	OUTPUT:
	RETVAL

int
isbuild1(name,len,mode,k_flags,k_nparts, ...)
	char * 	name
	int 	len
	int 	mode
	short	k_flags
	short 	k_nparts
	PREINIT:
#if defined (CISAM4)
	int fd;
#endif
	struct keydesc kd;
	int ind;
	int offset;
	CODE:
	kd.k_flags = k_flags;
	kd.k_nparts = k_nparts;
	for (ind = 0; ind < k_nparts; ind++) {
	  offset = 5 + 3*ind;
 	  kd.k_part[ind].kp_start = (short)SvIV(ST(offset));
 	  kd.k_part[ind].kp_leng = (short)SvIV(ST(offset+1));
 	  kd.k_part[ind].kp_type = (short)SvIV(ST(offset+2));
  	}
#if defined (CISAM4)
		fd = isbuild(name, len, &kd, mode);
		if (fd >= 0)
		{
			isclose(fd);
			RETVAL = isopen(name, mode);
		}
		else
		{
			RETVAL = fd;
		}
#else
        RETVAL = isbuild(name,len,&kd,mode);
#endif
        OUTPUT:
	RETVAL

int
iscleanup1()
	CODE:
	RETVAL = iscleanup();
  	OUTPUT:
	RETVAL

int
isclose1(fd)
	int	fd;
	CODE:
	RETVAL = isclose(fd);
  	OUTPUT:
	RETVAL

int
iscluster1(fd,k_flags,k_nparts, ...)
	int  	fd
	short	k_flags
	short 	k_nparts
	PREINIT:
	struct keydesc kd;
	int ind;
	int offset;
	CODE:
	kd.k_flags = k_flags;
	kd.k_nparts = k_nparts;
	for (ind = 0; ind < k_nparts; ind++) {
	  offset = 3 + 3*ind;
 	  kd.k_part[ind].kp_start = (short)SvIV(ST(offset));
 	  kd.k_part[ind].kp_leng = (short)SvIV(ST(offset+1));
 	  kd.k_part[ind].kp_type = (short)SvIV(ST(offset+2));
  	}
        RETVAL = iscluster(fd,&kd);
        OUTPUT:
	RETVAL

int
iscommit1()
	CODE:
	RETVAL = iscommit();
	OUTPUT:
	RETVAL

int
isdelcurr1(fd)
	int	fd;
	CODE:
	RETVAL = isdelcurr(fd);
  	OUTPUT:
	RETVAL

int
isdelete1(fd,data)
	int	fd
	char *	data
	CODE:
	RETVAL = isdelete(fd,data);
	OUTPUT:
	RETVAL

int
isdelindex1(fd,k_flags,k_nparts, ...)
	int  	fd
	short	k_flags
	short 	k_nparts
	PREINIT:
	struct keydesc kd;
	int ind;
	int offset;
	CODE:
	kd.k_flags = k_flags;
	kd.k_nparts = k_nparts;
	for (ind = 0; ind < k_nparts; ind++) {
	  offset = 3 + 3*ind;
 	  kd.k_part[ind].kp_start = (short)SvIV(ST(offset));
 	  kd.k_part[ind].kp_leng = (short)SvIV(ST(offset+1));
 	  kd.k_part[ind].kp_type = (short)SvIV(ST(offset+2));
  	}
        RETVAL = isdelindex(fd,&kd);
        OUTPUT:
	RETVAL

int
isdelrec1(fd,recnum)
	int	fd
	long 	recnum
	CODE:
	RETVAL = isdelrec(fd,recnum);
	OUTPUT:
	RETVAL

int
iserase1(name)
	char *	name
	CODE:
	RETVAL = iserase(name);
	OUTPUT:
	RETVAL

int
isflush1(fd)
	int	fd;
	CODE:
	RETVAL = isflush(fd);
  	OUTPUT:
	RETVAL

int
isisaminfo1(fd)
	int	fd
	PREINIT:
	struct dictinfo di;
	int cc;
	PPCODE:
	cc = isindexinfo(fd,&di,0);
	EXTEND(SP, 5);
   	PUSHs(sv_2mortal(newSViv(cc)));
   	PUSHs(sv_2mortal(newSViv(di.di_nkeys)));
   	PUSHs(sv_2mortal(newSViv(di.di_recsize)));
   	PUSHs(sv_2mortal(newSViv(di.di_idxsize)));
   	PUSHs(sv_2mortal(newSViv(di.di_nrecords)));

int
isindexinfo1(fd,idx)
	int	fd
	int	idx
	PREINIT:
	struct keydesc kd;
	int cc;
	int i, j;
	PPCODE:
	cc = isindexinfo(fd,&kd,idx);
	EXTEND(SP,1+2+3*kd.k_nparts);
	PUSHs(sv_2mortal(newSViv(cc))); 
	PUSHs(sv_2mortal(newSViv(kd.k_flags)));
	PUSHs(sv_2mortal(newSViv(kd.k_nparts))); 
	for (i=0; i<kd.k_nparts; i++) {
	   PUSHs(sv_2mortal(newSViv(kd.k_part[i].kp_start))); 
	   PUSHs(sv_2mortal(newSViv(kd.k_part[i].kp_leng))); 
	   PUSHs(sv_2mortal(newSViv(kd.k_part[i].kp_type))); 
	}

int
islock1(fd)
	int	fd;
	CODE:
	RETVAL = islock(fd);
  	OUTPUT:
	RETVAL

int
islogclose1()
	CODE:
	RETVAL = islogclose();
	OUTPUT:
	RETVAL

int
islogopen1(name)
	char *	name
	CODE:
	RETVAL = islogopen(name);
	OUTPUT:
	RETVAL

int
isopen1(name,mode)
	char * 	name
	int	mode
	CODE:
	RETVAL = isopen(name,mode);
	OUTPUT:
	RETVAL

int
isread1(fd,data,mode)
	int	fd
	char *	data
	int 	mode
	PREINIT:
	int foo;
#if defined (CISAM4)
	struct dictinfo info;
#endif
	CODE:
#if defined (CISAM4)
	isindexinfo(fd, &info, 0);
	isreclen = info.di_recsize;
#endif
	RETVAL = isread(fd,data,mode);
	sv_setpvn((SV*)ST(1), data, isreclen);
	OUTPUT:
	RETVAL

int
isrecover1()
	CODE:
	RETVAL = isrecover();
	OUTPUT:
	RETVAL

int
isrelease1(fd)
	int	fd;
	CODE:
	RETVAL = isrelease(fd);
  	OUTPUT:
	RETVAL

int
isrename1(oldname,newname)
	char *	oldname
	char *	newname
	CODE:
	RETVAL = isrename(oldname,newname);
	OUTPUT:
	RETVAL

int
isrewcurr1(fd,data)
	int 	fd
	char *	data
	CODE:
	RETVAL = isrewcurr(fd,data);
	OUTPUT:
	RETVAL

int
isrewrec1(fd,recnum,data)
	int 	fd
	long	recnum
	char *	data
	CODE:
	RETVAL = isrewrec(fd,recnum,data);
	OUTPUT:
	RETVAL

int
isrewrite1(fd,data)
	int 	fd
	char *	data
	CODE:
	RETVAL = isrewrite(fd,data);
	OUTPUT:
	RETVAL

int
isrollback1()
	CODE:
	RETVAL = isrollback();
	OUTPUT:
	RETVAL

int
issetunique1(fd,uniqueid)
	int 	fd
	long	uniqueid
	CODE:
	RETVAL = issetunique(fd,uniqueid);
	OUTPUT:
	RETVAL

int
isstart1(fd,len,data,mode,k_flags,k_nparts, ...)
	int  	fd
	int	len
	char *	data
	int	mode
	short	k_flags
	short 	k_nparts
	PREINIT:
	struct keydesc kd;
	int ind;
	int offset;
	CODE:
	kd.k_flags = k_flags;
	kd.k_nparts = k_nparts;
	for (ind = 0; ind < k_nparts; ind++) {
	  offset = 6 + 3*ind;
 	  kd.k_part[ind].kp_start = (short)SvIV(ST(offset));
 	  kd.k_part[ind].kp_leng = (short)SvIV(ST(offset+1));
 	  kd.k_part[ind].kp_type = (short)SvIV(ST(offset+2));
  	}
        RETVAL = isstart(fd,&kd,len,data,mode);
        OUTPUT:
	RETVAL

int
isuniqueid1(fd,uniqueid)
	int	fd
	long	uniqueid
	CODE:
	RETVAL = isuniqueid(fd,&uniqueid);
	OUTPUT:
	RETVAL
	uniqueid

int
isunlock1(fd)
	int	fd;
	CODE:
	RETVAL = isunlock(fd);
  	OUTPUT:
	RETVAL

int
iswrcurr1(fd,data)
	int 	fd
	char *	data
	CODE:
	RETVAL = iswrcurr(fd,data);
	OUTPUT:
	RETVAL

int
iswrite1(fd,data)
	int 	fd
	char *	data
	CODE:
	RETVAL = iswrite(fd,data);
	OUTPUT:
	RETVAL

double
lddbl1(p)
	char *p
	CODE:
	RETVAL = lddbl(p);
	OUTPUT:
	RETVAL

void
stdbl1(p, length_of_field)
	char *p
	int length_of_field
	PREINIT:
	char string[200];
	char return_val[2];
	double d;
	int i;
	PPCODE:
	EXTEND(SP, length_of_field);
	d = atof(p);
	stdbl(d,string);

	/* The next steps of magic are done because Perl treats
	   treats everything as string */

	return_val[1]='\000';
	for(i = 0; i < length_of_field; i++)
	{
		return_val[0] = string[i];	
		PUSHs(sv_2mortal(newSVpv(return_val, 2)));
	}
	
int
ldint1(p)
	char *p
	CODE:
	RETVAL = ldint(p);
	OUTPUT:
	RETVAL

void
stint1(p, length_of_field)
	char *p
	int length_of_field
	PREINIT:
	char string[20];
	char return_val[2];
	int d;
	int i;
	PPCODE:
	EXTEND(SP, length_of_field);
	d = atoi(p);
	stint(d,string);

	/* The next steps of magic are done because Perl treats
	   treats everything as string */

	return_val[1]='\000';
	for(i = 0; i < length_of_field; i++)
	{
		return_val[0] = string[i];	
		PUSHs(sv_2mortal(newSVpv(return_val, 2)));
	}
	

long
ldlong1(p)
	char *p
	CODE:
	RETVAL = ldlong(p);
	OUTPUT:
	RETVAL

void
stlong1(p, length_of_field)
	char *p
	int length_of_field
	PREINIT:
	char string[20];
	char return_val[2];
	long d;
	int i;
	PPCODE:
	EXTEND(SP, length_of_field);
	d = atol(p);
	stlong(d,string);
	/* The next steps of magic are done because Perl treats
	   treats everything as string */
	return_val[1]='\000';
	for(i = 0; i < length_of_field; i++)
	{
		return_val[0] = string[i];	
		PUSHs(sv_2mortal(newSVpv(return_val, 2)));
	}
	

void
stfloat1(p, length_of_field)
	char *p
	int length_of_field
	PREINIT:
	char string[20];
	char return_val[2];
	float d;
	int i;
	PPCODE:
	EXTEND(SP, length_of_field);
	d = atof(p);
	stfloat(d,string);

	/* The next steps of magic are done because Perl treats
	   treats everything as string */

	return_val[1]='\000';
	for(i = 0; i < length_of_field; i++)
	{
		return_val[0] = string[i];	
		PUSHs(sv_2mortal(newSVpv(return_val, 2)));
	}
	
double
ldfloat1(p)
	char *p
	CODE:
	RETVAL = (double) ldfloat(p);
	OUTPUT:
	RETVAL
