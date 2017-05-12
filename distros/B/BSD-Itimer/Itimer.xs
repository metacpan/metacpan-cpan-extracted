/*
# File:		Itimer.xs
# Author:	Daniel Hagerty, hag@linnaean.org
# Date:		Sun Jul  4 17:01:08 1999
# Description:	XS interface to BSD derived {g,s}etitimer() functions.
#
# Copyright (c) 1999 Daniel Hagerty. All rights reserved. This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.
#
# $Id: Itimer.xs,v 1.2 1999/07/28 02:26:50 hag Exp $
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <sys/time.h>

static char *rcs_id = "$Id: Itimer.xs,v 1.2 1999/07/28 02:26:50 hag Exp $";

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'I':
	if (strEQ(name, "ITIMER_PROF"))
#ifdef ITIMER_PROF
	    return ITIMER_PROF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ITIMER_REAL"))
#ifdef ITIMER_REAL
	    return ITIMER_REAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ITIMER_REALPROF"))
#ifdef ITIMER_REALPROF
	    return ITIMER_REALPROF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ITIMER_VIRTUAL"))
#ifdef ITIMER_VIRTUAL
	    return ITIMER_VIRTUAL;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = BSD::Itimer		PACKAGE = BSD::Itimer

PROTOTYPES: enable

double
constant(name,arg)
	char *		name
	int		arg


MODULE = BSD::Itimer		PACKAGE = BSD::Itimer	PREFIX=bsd_

void
bsd_getitimer(which)
	int	which
PREINIT:
	struct itimerval it;
	int err;
PPCODE:
	err = getitimer(which, &it);
	if(err < 0) {
	    XSRETURN_EMPTY;
        }
	EXTEND(sp, 4);
	PUSHs(sv_2mortal(newSViv(it.it_interval.tv_sec)));
	PUSHs(sv_2mortal(newSViv(it.it_interval.tv_usec)));
	PUSHs(sv_2mortal(newSViv(it.it_value.tv_sec)));
	PUSHs(sv_2mortal(newSViv(it.it_value.tv_usec)));

void
bsd_setitimer(which, ival_sec, ival_usec, val_sec, val_usec)
	int	which
	int	ival_sec
	int	ival_usec
	int	val_sec
	int	val_usec
PREINIT:
	struct itimerval setiv, getiv;
	int err;
PPCODE:
	setiv.it_interval.tv_sec = ival_sec;
	setiv.it_interval.tv_usec = ival_usec;
	setiv.it_value.tv_sec = val_sec;
	setiv.it_value.tv_usec = val_usec;
	err = setitimer(which, &setiv, &getiv);
	if(err < 0) {
	    XSRETURN_EMPTY;
        }
	EXTEND(sp, 4);
	PUSHs(sv_2mortal(newSViv(getiv.it_interval.tv_sec)));
	PUSHs(sv_2mortal(newSViv(getiv.it_interval.tv_usec)));
	PUSHs(sv_2mortal(newSViv(getiv.it_value.tv_sec)));
	PUSHs(sv_2mortal(newSViv(getiv.it_value.tv_usec)));
