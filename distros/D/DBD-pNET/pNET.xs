/*  Hej, Emacs, .xs means -*- C -*- mode
 *
 *  DBD::pNET - DBI network driver
 *
 *  pNET.xs - glue between perl and C
 *
 *
 *  Copyright (c) 1997  Jochen Wiedmann
 *
 *  Based on DBD::Oracle, which is
 *
 *  Copyright (c) 1994,1995,1996,1997 Tim Bunce
 *
 *  You may distribute under the terms of either the GNU General Public
 *  License or the Artistic License, as specified in the Perl README file,
 *  with the exception that it cannot be placed on a CD-ROM or similar media
 *  for commercial distribution without the prior approval of the author.
 *
 *
 *  Author: Jochen Wiedmann
 *          Am Eisteich 9
 *          72555 Metzingen
 *          Germany
 *
 *          Email: wiedmann@neckar-alb.de
 *          Phone: +49 7123 14881
 *
 *
 *  $Id: pNET.xs,v 1.1.1.1 1997/09/19 20:34:23 joe Exp $
 *
 */



#include "dbdimp.h"


/* --- Variables --- */


DBISTATE_DECLARE;

MODULE = DBD::pNET	PACKAGE = DBD::pNET

INCLUDE: pNET.xsi

# end of pNET.xs
