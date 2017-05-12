/*
 * $Id: Empress.h,v 0.52 
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#define NEED_DBIXS_VERSION 9

#include <DBIXS.h>	/* from DBI. */

#include "dbdimp.h"

SV*     emp_db_FETCH_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv);
SV*     emp_st_FETCH_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv);
AV*     dbd_st_fetch (SV *sth, imp_sth_t *imp_sth);

/* end of Empress.h */
