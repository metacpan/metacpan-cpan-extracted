/*
@(#)File:           $RCSfile: esqlcver.ec,v $
@(#)Version:        $Revision: 2003.1 $
@(#)Last changed:   $Date: 2003/04/22 18:02:48 $
@(#)Purpose:        Verify that library is built with correct version of ESQL/C
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1998,2003
@(#)Product:        Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
*/

/*TABSTOP=4*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

#include "esqlutil.h"

#ifndef lint
static const char rcs[] = "@(#)$Id: esqlcver.ec,v 2003.1 2003/04/22 18:02:48 jleffler Exp $";
#endif

int ESQLC_VERSION_CHECKER(void)
{
	return(ESQLC_VERSION);
}
