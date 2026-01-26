/*   Copyright (c) 1994,1995,1996,1997  Tim Bunce
 *   Modified for DBD::Unify by H.Merijn Brand <hmbrand@cpan.org>
 *
 *   You may distribute under the terms of either the GNU General Public
 *   License or the Artistic License, as specified in the Perl README file.
 */

#include "Unify.h"

DBISTATE_DECLARE;

MODULE = DBD::Unify    PACKAGE = DBD::Unify

void
_uni2sql_type (x)
    IV		x
    CODE:
	XST_mIV (0, uni2sql_type (x));

INCLUDE: Unify.xsi

MODULE = DBD::Unify    PACKAGE = DBD::Unify::db

void
_do (dbh, statement, attribs = "", params = NULL)
    SV *        dbh
    char *      statement
    char *      attribs
    SV *        params

  PREINIT:
    int	retval;
  CODE:
    retval = dbd_db_do (dbh, statement);
    if (retval < 0) {
	XST_mUNDEF (0);		/* error */
	}
    else if (retval == 0) {
	XST_mPV (0, "0E0");		/* true but zero */
	}
    else {
	XST_mIV (0, retval);	/* rowcount: NYI */
	}

void
db_dict (dbh, reload = 0)
    SV *	dbh
    int		reload

  PPCODE:
    dbd_db_dict (dbh, reload);
    EXTEND (SP, 1);
    ST (0) = DEFSV;
    XSRETURN (1);

MODULE = DBD::Unify    PACKAGE = DBD::Unify::st

# end of Unify.xs
