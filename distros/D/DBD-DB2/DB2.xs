/*
    engn/perldb2/DB2.xs, engn_perldb2, db2_v82fp9, 1.9 04/09/13 17:17:56

    Copyright (c) 1995-2004 International Business Machines Corp.
*/

#define NEED_newRV_noinc
#include "DB2.h"

/* 
Redefining DBIc_CACHED_KIDS to fix the compile issue in DBD::DB2
which was due to change in definition of DBIc_CACHED_KIDS in DBIv1.55
*/
#ifdef DB2_CACHE_FIX
    #undef DBIc_CACHED_KIDS
    #define DBIc_CACHED_KIDS(imp)    _imp2com(imp, _old_cached_kids)
#endif



/* --- Variables --- */


DBISTATE_DECLARE;


MODULE = DBD::DB2       PACKAGE = DBD::DB2

PROTOTYPES: DISABLE

BOOT:
    items = 0;  /* avoid 'unused variable' warning */
    DBISTATE_INIT;
    /* XXX this interface will change: */
    DBI_IMP_SIZE("DBD::DB2::dr::imp_data_size", sizeof(imp_drh_t));
    DBI_IMP_SIZE("DBD::DB2::db::imp_data_size", sizeof(imp_dbh_t));
    DBI_IMP_SIZE("DBD::DB2::st::imp_data_size", sizeof(imp_sth_t));
    dbd_init(DBIS);


# ------------------------------------------------------------
# driver level interface
# ------------------------------------------------------------
MODULE = DBD::DB2       PACKAGE = DBD::DB2::dr

void
disconnect_all(drh)
    SV *        drh
    CODE:
    if (!PL_dirty && !SvTRUE(perl_get_sv("DBI::PERL_ENDING",0))) {
        D_imp_drh(drh);
        sv_setiv(DBIc_ERR(imp_drh), (IV)1);
        sv_setpv(DBIc_ERRSTR(imp_drh),
                (char*)"disconnect_all not implemented");
        DBIh_EVENT2(drh, ERROR_event,
                DBIc_ERR(imp_drh), DBIc_ERRSTR(imp_drh));
        XSRETURN(0);
    }
    XST_mIV(0, 1);

#ifndef AS400
void
_data_sources( drh, attribs=Nullsv )
    SV *        drh
    SV *        attribs
    CODE:
    {                                                           
      AV *ds = dbd_data_sources( drh );
      ST(0) = sv_2mortal( newRV_noinc( (SV*)ds ) );
    }
                                                          

#endif

# ------------------------------------------------------------
# database level interface
# ------------------------------------------------------------
MODULE = DBD::DB2    PACKAGE = DBD::DB2::db

void
_login(dbh, dbname, username, password, attribs=Nullsv)
    SV *        dbh
    char *      dbname
    SV *        username
    SV *        password
    SV *        attribs
    CODE:
    {
    STRLEN lna;
    D_imp_dbh(dbh);
    char *u = (SvOK(username)) ? SvPV(username,lna) : "";
    char *p = (SvOK(password)) ? SvPV(password,lna) : "";
    ST(0) = dbd_db_login2(dbh, imp_dbh, dbname, u, p, attribs) ? &PL_sv_yes : &PL_sv_no;
    }


void
commit(dbh)
    SV *        dbh
    CODE:
    D_imp_dbh(dbh);
    if (DBIc_has(imp_dbh,DBIcf_AutoCommit))
        warn("commit ineffective with AutoCommit enabled");
    ST(0) = dbd_db_commit(dbh, imp_dbh) ? &PL_sv_yes : &PL_sv_no;

void
rollback(dbh)
    SV *        dbh
    CODE:
    D_imp_dbh(dbh);
    if (DBIc_has(imp_dbh,DBIcf_AutoCommit))
        warn("rollback ineffective with AutoCommit enabled");
    ST(0) = dbd_db_rollback(dbh, imp_dbh) ? &PL_sv_yes : &PL_sv_no;

void
disconnect(dbh)
    SV *        dbh
    SV **svp = hv_fetch((HV*)SvRV(dbh), "CachedKids", 10, 0);
    CODE:
    D_imp_dbh(dbh);
    if ( !DBIc_ACTIVE(imp_dbh) ) {
        XSRETURN_YES;
    }

    /* pre-disconnect checks and tidy-ups */
    if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
        hv_clear((HV*)SvRV(dbh));
    }
    if (DBIc_CACHED_KIDS(imp_dbh)) {
        SvREFCNT_dec(DBIc_CACHED_KIDS(imp_dbh));      /* cast them to the winds */
        DBIc_CACHED_KIDS(imp_dbh) = Nullhv;
    }
    /* Check for disconnect() being called whilst refs to cursors       */
    /* still exists. This possibly needs some more thought.             */
    if (DBIc_ACTIVE_KIDS(imp_dbh) && DBIc_WARN(imp_dbh) && !PL_dirty) {
        STRLEN lna;
        char *plural = (DBIc_ACTIVE_KIDS(imp_dbh)==1) ? "" : "s";
        warn("%s->disconnect invalidates %d active statement handle%s %s",
            SvPV(dbh,lna), (int)DBIc_ACTIVE_KIDS(imp_dbh), plural,
            "(either destroy statement handles or call finish on them before disconnecting)");
    }
    ST(0) = dbd_db_disconnect(dbh, imp_dbh) ? &PL_sv_yes : &PL_sv_no;
    /* The connection will not be deactivated if there is an invalid */
    /* transaction state, this is handled in dbd_db_disconnect       */
    /*DBIc_ACTIVE_off(imp_dbh);*/  /* ensure it's off, regardless */


void
STORE(dbh, keysv, valuesv)
    SV *        dbh
    SV *        keysv
    SV *        valuesv
    CODE:
    D_imp_dbh(dbh);
    if (SvGMAGICAL(valuesv))
        mg_get(valuesv);
    ST(0) = &PL_sv_yes;
    if (!dbd_db_STORE_attrib(dbh, imp_dbh, keysv, valuesv))
        if (!DBIS->set_attr(dbh, keysv, valuesv))
            ST(0) = &PL_sv_no;

void
FETCH(dbh, keysv)
    SV *        dbh
    SV *        keysv
    CODE:
    D_imp_dbh(dbh);
    SV *valuesv = dbd_db_FETCH_attrib(dbh, imp_dbh, keysv);
    if (!valuesv)
        valuesv = DBIS->get_attr(dbh, keysv);
    ST(0) = valuesv;    /* dbd_db_FETCH_attrib did sv_2mortal   */


void
DESTROY(dbh)
    SV *        dbh
    PPCODE:
    D_imp_dbh(dbh);
    ST(0) = &PL_sv_yes;
    if (!DBIc_IMPSET(imp_dbh)) {        /* was never fully set up       */
        STRLEN lna;
        if (DBIc_WARN(imp_dbh) && !PL_dirty && DBIS->debug >= 2)
             PerlIO_printf(DBILOGFP,
                "         DESTROY for %s ignored - handle not initialised\n",
                        SvPV(dbh,lna));
    }
    else {
        /* pre-disconnect checks and tidy-ups */
        SV **svp = hv_fetch((HV*)SvRV(dbh), "CachedKids", 10, 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
            hv_clear((HV*)SvRV(dbh));
        }
        if (DBIc_CACHED_KIDS(imp_dbh)) {
            SvREFCNT_dec(DBIc_CACHED_KIDS(imp_dbh));  /* cast them to the winds */
            DBIc_CACHED_KIDS(imp_dbh) = Nullhv;
        }
        if (DBIc_IADESTROY(imp_dbh)) {            /* want's ineffective destroy */
            DBIc_ACTIVE_off(imp_dbh);
        }
        if (DBIc_ACTIVE(imp_dbh)) {
            /* The application has not explicitly disconnected. That's bad.     */
            /* To ensure integrity we *must* issue a rollback. This will be     */
            /* harmless if the application has issued a commit. If it hasn't    */
            /* then it'll ensure integrity. Consider a Ctrl-C killing perl      */
            /* between two statements that must be executed as a transaction.   */
            /* Perl will call DESTROY on the dbh and, if we don't rollback,     */
            /* the server may automatically commit! Bham! Corrupt database!     */
            if (!DBIc_has(imp_dbh,DBIcf_AutoCommit)) {
                if (DBIc_WARN(imp_dbh) && (!PL_dirty || DBIS->debug >= 3))
                     warn("Issuing rollback() for database handle being DESTROY'd without explicit disconnect()");
                dbd_db_rollback(dbh, imp_dbh);                  /* ROLLBACK! */
            }
            dbd_db_disconnect(dbh, imp_dbh);
            DBIc_ACTIVE_off(imp_dbh);   /* ensure it's off, regardless */
        }
        dbd_db_destroy(dbh, imp_dbh);
    }


void
_do( dbh, stmt )
    SV *        dbh
    SV *        stmt
    CODE:
    {
      STRLEN lna;
      char *pstmt = SvOK(stmt) ? SvPV(stmt,lna) : "";
      ST(0) = sv_2mortal(                                        
                newSViv( (IV)dbd_db_do( dbh, pstmt ) ) );
    }


void
_ping( dbh )
    SV *        dbh
    CODE:
    {                                                           
      ST(0) = sv_2mortal( newSViv( (IV)dbd_db_ping( dbh ) ) );   
    }                                                           


void
_get_info( dbh, infotype=-1 )
   SV *     dbh
   short    infotype
   CODE:
   {
      D_imp_dbh(dbh);
      SV *sv = dbd_db_get_info( dbh, imp_dbh, infotype );        
      ST(0) = sv;
   }


# -- end of DBD::DB2::db


# ------------------------------------------------------------
# statement interface
# ------------------------------------------------------------
MODULE = DBD::DB2    PACKAGE = DBD::DB2::st


void
_prepare(sth, statement, attribs=Nullsv)
    SV *        sth
    char *      statement
    SV *        attribs
    CODE:
    {
    D_imp_sth(sth);
    DBD_ATTRIBS_CHECK("_prepare", sth, attribs);
    ST(0) = dbd_st_prepare(sth, imp_sth, statement, attribs) ? &PL_sv_yes : &PL_sv_no;
    }


void
rows(sth)
    SV *        sth
    CODE:
    D_imp_sth(sth);
    XST_mIV(0, dbd_st_rows(sth, imp_sth));


void
bind_param(sth, param, value, attribs=Nullsv)
    SV *        sth
    SV *        param
    SV *        value
    SV *        attribs
    CODE:
    {
    IV sql_type = 0;
    D_imp_sth(sth);
    if (SvGMAGICAL(value))
        mg_get(value);
    if (attribs) {
        if (SvNIOK(attribs)) {
            sql_type = SvIV(attribs);
            attribs = Nullsv;
        }
        else {
            DBD_ATTRIBS_CHECK("bind_param", sth, attribs);
            /* XXX we should perhaps complain if TYPE is not SvNIOK */
            /*DBD_ATTRIB_GET_IV(attribs, "TYPE",4, svp, sql_type);*/
        }
    }
    ST(0) = dbd_bind_ph(sth, imp_sth, param, value, sql_type, attribs, FALSE, 0)
                ? &PL_sv_yes : &PL_sv_no;
    }


void
bind_param_inout(sth, param, value_ref, maxlen, attribs=Nullsv)
    SV *        sth
    SV *        param
    SV *        value_ref
    IV          maxlen
    SV *        attribs
    CODE:
    {
    IV sql_type = 0;
    D_imp_sth(sth);
    SV *value;
    if (!SvROK(value_ref) || SvTYPE(SvRV(value_ref)) > SVt_PVMG)
        croak("bind_param_inout needs a reference to a scalar value");
    value = SvRV(value_ref);
    if (SvREADONLY(value))
        croak("Modification of a read-only value attempted");
    if (SvGMAGICAL(value))
        mg_get(value);
    if (attribs) {
        if (SvNIOK(attribs)) {
            sql_type = SvIV(attribs);
            attribs = Nullsv;
        }
        else {
            DBD_ATTRIBS_CHECK("bind_param_inout", sth, attribs);
            /*DBD_ATTRIB_GET_IV(attribs, "TYPE",4, svp, sql_type);*/
        }
    }
    ST(0) = dbd_bind_ph(sth, imp_sth, param, value, sql_type, attribs, TRUE, maxlen)
                ? &PL_sv_yes : &PL_sv_no;
    }


void
execute(sth, ...)
    SV *        sth
    CODE:
    D_imp_sth(sth);
    int retval;
    if (items > 1) {
        /* Handle binding supplied values to placeholders       */
        int i;
        SV *idx;
        if (items-1 != DBIc_NUM_PARAMS(imp_sth)
#ifdef DBIc_NUM_PARAMS_AT_EXECUTE /* added sometime between DBI 0.93 and 1.08 */
            && DBIc_NUM_PARAMS(imp_sth) != DBIc_NUM_PARAMS_AT_EXECUTE
#endif
        ) {
            char errmsg[99];
            sprintf(errmsg,"execute called with %ld bind variables when %d are needed",
                    items-1, DBIc_NUM_PARAMS(imp_sth));
            sv_setpv(DBIc_ERRSTR(imp_sth), errmsg);
            sv_setiv(DBIc_ERR(imp_sth), (IV)-1);
            XSRETURN_UNDEF;
        }
        idx = sv_2mortal(newSViv(0));
        for(i=1; i < items ; ++i) {
            SV* value = ST(i);
            if (SvGMAGICAL(value))
                mg_get(value);  /* trigger magic to FETCH the value     */
            sv_setiv(idx, i);
            if (!dbd_bind_ph(sth, imp_sth, idx, value, 0, Nullsv, FALSE, 0)) {
                XSRETURN_UNDEF; /* dbd_bind_ph already registered error */
            }
        }
    }
#ifdef DBIc_ROW_COUNT             /* added sometime between DBI 0.93 and 1.08 */
    if (DBIc_ROW_COUNT(imp_sth) > 0) /* reset for re-execute */
        DBIc_ROW_COUNT(imp_sth) = 0;
#endif
    retval = dbd_st_execute(sth, imp_sth);
    /* remember that dbd_st_execute must return <= -2 for error */
    if (retval == 0)            /* ok with no rows affected     */
        XST_mPV(0, "0E0");      /* (true but zero)              */
    else if (retval < -1)       /* -1 == unknown number of rows */
        XST_mUNDEF(0);          /* <= -2 means error            */
    else
        XST_mIV(0, retval);     /* typically 1, rowcount or -1  */


void
fetchrow_arrayref(sth)
    SV *        sth
    ALIAS:
        fetch = 1
    CODE:
    D_imp_sth(sth);
    AV *av = dbd_st_fetch(sth, imp_sth);
    ST(0) = (av) ? sv_2mortal(newRV((SV *)av)) : &PL_sv_undef;


void
fetchrow_array(sth)
    SV *        sth
    ALIAS:
        fetchrow = 1
    PPCODE:
    D_imp_sth(sth);
    AV *av = dbd_st_fetch(sth, imp_sth);
    if (av) {
        int num_fields = AvFILL(av)+1;
        int i;
        EXTEND(sp, num_fields);
        for(i=0; i < num_fields; ++i) {
            PUSHs(AvARRAY(av)[i]);
        }
    }


void
cancel(sth)
    SV *        sth
    CODE:
    D_imp_sth(sth);
    ST(0) = dbd_st_cancel(sth,imp_sth) ? &PL_sv_yes : &PL_sv_no;


void
finish(sth)
    SV *        sth
    CODE:
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    if (!DBIc_ACTIVE(imp_sth)) {
        /* No active statement to finish        */
        XSRETURN_YES;
    }
    if (!DBIc_ACTIVE(imp_dbh)) {
        /* Either an explicit disconnect() or global destruction        */
        /* has disconnected us from the database. Finish is meaningless */
        DBIc_ACTIVE_off(imp_sth);
        XSRETURN_YES;
    }
    ST(0) = dbd_st_finish(sth, imp_sth) ? &PL_sv_yes : &PL_sv_no;


void
blob_read(sth, field, offset, len, destrv=Nullsv, destoffset=0)
    SV *        sth
    int field
    long        offset
    long        len
    SV *        destrv
    long        destoffset
    CODE:
    {
    D_imp_sth(sth);
    if (!destrv)
        destrv = sv_2mortal(newRV(sv_2mortal(newSV(0))));
    if (dbd_st_blob_read(sth, imp_sth, field, offset, len, destrv, destoffset))
         ST(0) = SvRV(destrv);
    else ST(0) = &PL_sv_undef;
    }


void
STORE(sth, keysv, valuesv)
    SV *        sth
    SV *        keysv
    SV *        valuesv
    CODE:
    D_imp_sth(sth);
    if (SvGMAGICAL(valuesv))
        mg_get(valuesv);
    ST(0) = &PL_sv_yes;
    if (!dbd_st_STORE_attrib(sth, imp_sth, keysv, valuesv))
        if (!DBIS->set_attr(sth, keysv, valuesv))
            ST(0) = &PL_sv_no;


void
FETCH(sth, keysv)
    SV *        sth
    SV *        keysv
    CODE:
    D_imp_sth(sth);
    SV *valuesv = dbd_st_FETCH_attrib( sth, imp_sth, keysv );
    if (!valuesv)
        valuesv = DBIS->get_attr(sth, keysv);
    ST(0) = valuesv;    /* dbd_st_FETCH_attrib did sv_2mortal   */


void
DESTROY(sth)
    SV *        sth
    PPCODE:
    D_imp_sth(sth);
    ST(0) = &PL_sv_yes;
    if (!DBIc_IMPSET(imp_sth)) {        /* was never fully set up       */
        STRLEN lna;
        if (DBIc_WARN(imp_sth) && !PL_dirty && DBIS->debug >= 2)
             PerlIO_printf(DBILOGFP,
                "Statement handle %s DESTROY ignored - never set up\n",
                    SvPV(sth,lna));
    }
    else {
        if (DBIc_IADESTROY(imp_sth)) { /* want's ineffective destroy    */
            DBIc_ACTIVE_off(imp_sth);
        }
        if (DBIc_ACTIVE(imp_sth)) {
            D_imp_dbh_from_sth;
            if (DBIc_ACTIVE(imp_dbh)) {
                dbd_st_finish(sth, imp_sth);
            }
            else {
                DBIc_ACTIVE_off(imp_sth);
            }
        }
        dbd_st_destroy(sth, imp_sth);
    }


void
_table_info( sth, attribs=Nullsv  )
    SV *        sth
    SV *        attribs
    CODE:
    {
      D_imp_sth(sth);                                            
      DBD_ATTRIBS_CHECK( "_table_info", sth, attribs );          
      ST(0) = dbd_st_table_info( sth, imp_sth, attribs )         
                ? &PL_sv_yes : &PL_sv_no;                             
    }


void
_primary_key_info( sth, catalog=NULL, schema=NULL, table=NULL )
   SV      *sth
   char    *catalog
   char    *schema
   char    *table
   CODE:
   {
      D_imp_sth(sth);
      ST(0) = dbd_st_primary_key_info( sth,
                                       imp_sth,
                                       catalog,
                                       schema,
                                       table )                   
                 ? &PL_sv_yes : &PL_sv_no;
   }


void
_foreign_key_info( sth, pkCat=NULL, pkSchema=NULL, pkTable=NULL, fkCat=NULL, fkSchema=NULL, fkTable=NULL )
   SV      *sth
   char    *pkCat
   char    *pkSchema
   char    *pkTable
   char    *fkCat
   char    *fkSchema
   char    *fkTable
   CODE:
   {
      D_imp_sth(sth);
      ST(0) = dbd_st_foreign_key_info( sth, imp_sth,
                                       pkCat, pkSchema, pkTable,
                                       fkCat, fkSchema, fkTable) 
                 ? &PL_sv_yes : &PL_sv_no;
   }


void
_column_info( sth, cat=NULL, schema=NULL, table=NULL, column=NULL )
   SV      *sth
   char    *cat
   char    *schema
   char    *table
   char    *column
   CODE:
   {
      D_imp_sth(sth);
      ST(0) = dbd_st_column_info( sth, imp_sth, cat, schema, table, column )
                 ? &PL_sv_yes : &PL_sv_no;                             
   }

void
_type_info_all( sth )
   SV      *sth
   CODE:
   {
      D_imp_sth(sth);
      ST(0) = dbd_st_type_info_all( sth, imp_sth )
                 ? &PL_sv_yes : &PL_sv_no;                             
   }



# end of DB2.xs
