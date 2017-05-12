/*
@(#)File:            $RCSfile: eprintf.c,v $
@(#)Version:         $Revision: 60.1 $
@(#)Last changed:    $Date: 1998/06/16 16:03:30 $
@(#)Purpose:         GCC assert() macro support function __eprintf()
*/

/*TABSTOP=4*/

#undef NULL /* Avoid errors if stdio.h and our stddef.h mismatch.  */

#include <stdio.h>

#ifndef lint
static const char rcs[] = "@(#)$Id: eprintf.c,v 60.1 1998/06/16 16:03:30 jleffler Exp $";
#endif

/* This is used by the `assert' macro.  */
void __eprintf(const char *string,
			   const char *expression,
			   int line,
			   const char *filename)
{
	fprintf(stderr, string, expression, line, filename);
	fflush(stderr);
	abort();
}
