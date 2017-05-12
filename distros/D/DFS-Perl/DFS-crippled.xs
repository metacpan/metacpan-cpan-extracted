/*
 * DFS-Perl version 0.35
 *
 * Paul Henson <henson@acm.org>
 * California State Polytechnic University, Pomona
 *
 * Copyright (c) 1997,1998,1999 Paul Henson -- see COPYRIGHT file for details
 *
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
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = DCE::DFS		PACKAGE = DCE::DFS

void
dummy()
     CODE:

