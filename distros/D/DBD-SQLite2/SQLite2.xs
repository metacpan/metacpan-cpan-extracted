/* $Id: SQLite2.xs,v 1.2 2004/08/09 13:23:55 matt Exp $ */

#include "SQLiteXS.h"

DBISTATE_DECLARE;

MODULE = DBD::SQLite2          PACKAGE = DBD::SQLite2::db

PROTOTYPES: DISABLE

AV *
list_tables(dbh)
    SV *dbh
    CODE:
    {
        RETVAL = newAV();
    }
    OUTPUT:
        RETVAL

int
last_insert_rowid(dbh)
    SV *dbh
    CODE:
    {
        D_imp_dbh(dbh);
        RETVAL = sqlite_last_insert_rowid(imp_dbh->db);
    }
    OUTPUT:
        RETVAL

void
create_function(dbh, name, argc, func)
    SV *dbh
    char *name
    int argc
    SV *func
    CODE:
    {
        sqlite2_db_create_function( dbh, name, argc, func );
    }

void
create_aggregate(dbh, name, argc, aggr)
    SV *dbh
    char *name
    int argc
    SV *aggr
    CODE:
    {
        sqlite2_db_create_aggregate( dbh, name, argc, aggr );
    }

int 
busy_timeout(dbh, timeout=0)
  SV *dbh
  int timeout
  CODE:
    RETVAL = sqlite2_busy_timeout( dbh, timeout );
  OUTPUT:
    RETVAL

MODULE = DBD::SQLite2          PACKAGE = DBD::SQLite2::st

PROTOTYPES: DISABLE

MODULE = DBD::SQLite2          PACKAGE = DBD::SQLite2

INCLUDE: SQLite2.xsi
