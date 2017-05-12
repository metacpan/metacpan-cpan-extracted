/*
# $Id: PrimeBase.h,v 1.4001 2001/07/30 19:29:50
# Copyright (c) 2001  Snap Innovation
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
*/


#define NEED_DBIXS_VERSION 9

#include <DBIXS.h>
#include "dbdimp.h"
#include <dbd_xsh.h>

int     PB_get_type_info _((SV *dbh, SV *sth, int ftype));
SV		*PB_col_attributes _((SV *sth, int colno, int desctype));
SV		*PB_cancel _((SV *sth));
int	 	PB_db_columns _((SV *dbh, SV *sth,
	    char *catalog, char *schema, char *table, char *column));


