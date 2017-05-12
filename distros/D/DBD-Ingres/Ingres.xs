/*
#   $Id: //depot/tilpasninger/dbd-ingres/Ingres.xs#2 $
#
#   Copyright (c) 1994,1995,1996,1997  Tim Bunce
#   Modified for DBD::Ingres by Henrik Tougaard <htoug@cpan.org>
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
*/

#include "Ingres.h"

DBISTATE_DECLARE;
 
MODULE = DBD::Ingres    PACKAGE = DBD::Ingres

INCLUDE: Ingres.xsi

MODULE = DBD::Ingres    PACKAGE = DBD::Ingres::db

void
_do(dbh, statement, attribs="", params=Nullsv)
    SV *        dbh
    char *      statement
    char *      attribs
    SV *        params
    PREINIT:
    int		retval;
    CODE:
    retval = dbd_db_do(dbh, statement);
    if (retval < 0) {
        XST_mUNDEF(0);          /* error */
    } else if (retval == 0) {
        XST_mPV(0, "0E0");      /* true but zero */
    } else {
        XST_mIV(0, retval);     /* rowcount */
    }

void
get_dbevent(dbh, wait=Nullsv)
    SV *	dbh
    SV *	wait
    PREINIT:
    D_imp_dbh(dbh);
    CODE:
    ST(0) = (SV*)  dbd_db_get_dbevent(dbh, imp_dbh, wait);

# end of Ingres.xs
