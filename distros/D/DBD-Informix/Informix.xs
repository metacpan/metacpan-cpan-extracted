/*
 * @(#)$Id: Informix.xs,v 2010.1 2010/08/31 21:25:14 jleffler Exp $
 *
 * Copyright 1994-95 Tim Bunce
 * Copyright 1995-96 Alligator Descartes
 * Copyright 1996-99 Jonathan Leffler
 * Copyright 2000    Informix Software Inc
 * Copyright 2002-03 IBM
 * Copyright 2004-08 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#include "Informix.h"

DBISTATE_DECLARE;

/* Assume string concatenation is available */
#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_informix_xs[] = "@(#)$Id: Informix.xs,v 2010.1 2010/08/31 21:25:14 jleffler Exp $";
#endif /* lint */

MODULE = DBD::Informix PACKAGE = DBD::Informix

I32
constant()
    PROTOTYPE:
    ALIAS:
    IX_SMALLINT   = SQLSMINT
    IX_INTEGER    = SQLINT
    IX_SERIAL     = SQLSERIAL
    IX_INT8       = SQLINT8
    IX_SERIAL8    = SQLSERIAL8
    IX_DECIMAL    = SQLDECIMAL
    IX_MONEY      = SQLMONEY
    IX_FLOAT      = SQLFLOAT
    IX_SMALLFLOAT = SQLSMFLOAT
    IX_CHAR       = SQLCHAR
    IX_VARCHAR    = SQLVCHAR
    IX_NCHAR      = SQLNCHAR
    IX_NVARCHAR   = SQLNVCHAR
    IX_LVARCHAR   = SQLLVARCHAR
    IX_BOOLEAN    = SQLBOOL
    IX_DATE       = SQLDATE
    IX_DATETIME   = SQLDTIME
    IX_INTERVAL   = SQLINTERVAL
    IX_BYTE       = SQLBYTES
    IX_TEXT       = SQLTEXT
    IX_SET        = SQLSET
    IX_MULTISET   = SQLMULTISET
    IX_LIST       = SQLLIST
    IX_ROW        = SQLROW
    IX_COLLECTION = SQLCOLLECTION
    IX_VARUDT     = SQLUDTVAR
    IX_FIXUDT     = SQLUDTFIXED
    IX_BIGINT     = SQLINFXBIGINT
    IX_BIGSERIAL  = SQLBIGSERIAL
    # In the Informix system catalog, CLOB and BLOB types are simply
    # specific cases of a fixed UDT.  They seem to have extended ids
    # 10, 11.  However, they are also base types (opaque), and there
    # is storage information for them in the create table statement
    # (a PUT clause after the column list).  We need to handle them
    # specially, so define unique values for them in dbdimp.h.
    IX_CLOB       = DBD_IX_SQLCLOB
    IX_BLOB       = DBD_IX_SQLBLOB
    CODE:
    RETVAL = ix;
    OUTPUT:
    RETVAL

INCLUDE: Informix.xsi

MODULE = DBD::Informix  PACKAGE = DBD::Informix::dr

# Initialize the DBD::Informix driver data structure
void
driver_init(drh)
    SV *        drh
    CODE:
    ST(0) = dbd_ix_dr_driver(drh) ? &PL_sv_yes : &PL_sv_no;

# Fetch a driver attribute.  The keys are always strings.
# For some reason, not a part of the DBI standard
void
FETCH(drh, keysv)
    SV *        drh
    SV *        keysv
    CODE:
    D_imp_drh(drh);
    SV *valuesv = dbd_ix_dr_FETCH_attrib(imp_drh, keysv);
    if (!valuesv)
        valuesv = DBIc_DBISTATE(imp_drh)->get_attr(drh, keysv);
    ST(0) = valuesv;    /* dbd_dr_FETCH_attrib did sv_2mortal  */

MODULE = DBD::Informix    PACKAGE = DBD::Informix::st

# end of Informix.xs
