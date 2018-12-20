/*
 *  DBD::mysqlx - DBI X Protocol driver for the MySQL database
 *
 *  Copyright (c) 2018 Daniël van Eeden
 *
 *  You may distribute this under the terms of either the GNU General Public
 *  License or the Artistic License, as specified in the Perl README file.
 */

#include "mysqlx.h"
 
DBISTATE_DECLARE;

MODULE = DBD::mysqlx PACKAGE = DBD::mysqlx
 
INCLUDE: mysqlx.xsi

MODULE = DBD::mysqlx PACKAGE = DBD::mysqlx::db

SV*
ping(dbh)
  SV* dbh;
  PROTOTYPE: $
  CODE:
    int retval = 0;
    D_imp_dbh(dbh);

    mysqlx_result_t *result =
      mysqlx_sql(imp_dbh->sess, "/* DBD::mysqlx ping */", MYSQLX_NULL_TERMINATED);
    if (result != NULL) retval=1;
    RETVAL = boolSV(retval);
  OUTPUT:
    RETVAL
