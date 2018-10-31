/*
 * @(#)$Id: dbdattr.ec,v 2015.1 2015/11/02 20:18:04 jleffler Exp $
 *
 * @(#)$Product: Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31) $ -- attribute handling
 *
 * Copyright 1997-99 Jonathan Leffler
 * Copyright 2000    Informix Software Inc
 * Copyright 2002-03 IBM
 * Copyright 2004-15 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/*TABSTOP=4*/

#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
const char jlss_id_dbdattr_ec[] = "@(#)$Id: dbdattr.ec,v 2015.1 2015/11/02 20:18:04 jleffler Exp $";
#endif /* lint */

#include <stdio.h>
#include <string.h>

#include "Informix.h"
#include "esqlutil.h"
$include "esqlinfo.h";

/*
** Check whether key defined by key length (kl) and key value (kv)
** matches keyword (kw), which should be a character literal ("KeyWord")!
*/
#define KEY_MATCH(kl, kv, kw) ((kl) == (sizeof(kw) - 1) && strEQ((kv), (kw)))

static const char ix_actconn[] = "ix_ActiveConnections";
static const char ix_blobloc[] = "ix_BlobLocation";
static const char ix_blobsup[] = "ix_BlobSupport";
static const char ix_colleng[] = "ix_ColLength";
static const char ix_coltype[] = "ix_ColType";
static const char ix_conname[] = "ix_ConnectionName";
static const char ix_csrhold[] = "ix_CursorWithHold";
static const char ix_curconn[] = "ix_CurrentConnection";
static const char ix_dbsname[] = "ix_DatabaseName";
static const char ix_fetchab[] = "ix_Fetchable";
static const char ix_instcsr[] = "ix_InsertCursor";
static const char ix_intrans[] = "ix_InTransaction";
static const char ix_ixonlin[] = "ix_InformixOnLine";
static const char ix_loggedb[] = "ix_LoggedDatabase";
static const char ix_modeans[] = "ix_ModeAnsiDatabase";
static const char ix_mulconn[] = "ix_MultipleConnections";
static const char ix_prodnam[] = "ix_ProductName";
static const char ix_prodver[] = "ix_ProductVersion";
static const char ix_scrlcsr[] = "ix_ScrollCursor";
static const char ix_srvrvsn[] = "ix_ServerVersion";
static const char ix_srvrnam[] = "ix_ServerName";
static const char ix_stoproc[] = "ix_StoredProcedures";
static const char ix_typenam[] = "ix_NativeTypeName";
static const char ix_worepln[] = "ix_WithoutReplication";
static const char ix_enable_utf8[] = "ix_EnableUTF8"; /* UTF8 patch */

static const char ix_sqlcode[] = "ix_sqlcode";
static const char ix_sqlerrd[] = "ix_sqlerrd";
static const char ix_sqlerrm[] = "ix_sqlerrm";
static const char ix_sqlerrp[] = "ix_sqlerrp";
static const char ix_sqlwarn[] = "ix_sqlwarn";
static const char ix_serial4[] = "ix_serial";
static const char ix_serial8[] = "ix_serial8";
#ifdef ESQLC_BIGINT
static const char ix_bigser8[] = "ix_bigserial";
#endif /* ESQLC_BIGINT */

static const char esql_prodname[] = "@(#)" ESQLC_VERSION_STRING;
static const int  esql_prodvrsn   = ESQLC_VERSION;

#ifdef USE_DEPRECATED
/* Print message deprecating old attribute and indicating new */
static void dbd_ix_deprecate(const char *old_att, const char *new_att)
{
    croak("%s - do not use deprecated attribute %s (use %s)\n",
         dbd_ix_module(), old_att, new_att);
}
#endif /* USE_DEPRECATED */

/* Convert string into BlobLocn value */
static BlobLocn blob_bindtype(SV *valuesv)
{
    STRLEN vlen;
    char *value = SvPV(valuesv, vlen);
    BlobLocn locn = BLOB_DEFAULT;

    if (KEY_MATCH(vlen, value, "InMemory"))
        locn = BLOB_IN_MEMORY;
    else if (KEY_MATCH(vlen, value, "InFile"))
        locn = BLOB_IN_NAMEFILE;
    else
        locn = BLOB_DEFAULT;
    return(locn);
}

/* Convert string into BlobLocn value */
static char *blob_bindname(BlobLocn locn)
{
    char *value = 0;

    switch (locn)
    {
    case BLOB_IN_MEMORY:
        value =  "InMemory";
        break;
    case BLOB_IN_NAMEFILE:
        value = "InFile";
        break;
    default:
        value = "Default";
        break;
    }
    return(value);
}

SV *dbd_ix_dr_FETCH_attrib(imp_drh_t *imp_drh, SV *keysv)
{
    static const char function[] = "dbd_ix_dr_FETCH_attrib";
    STRLEN          kl;
    char           *key = SvPV(keysv, kl);
    SV             *retsv = Nullsv;

    dbd_ix_enter(function);

    if (KEY_MATCH(kl, key, ix_mulconn))
    {
        retsv = newSViv((IV)imp_drh->multipleconnections);
    }
    else if (KEY_MATCH(kl, key, ix_actconn))
    {
        retsv = newSViv((IV)imp_drh->n_connections);
    }
    else if (KEY_MATCH(kl, key, ix_curconn))
    {
        char *conn = (char *)imp_drh->current_connection;   /* const_cast<char*> */
        if (conn == 0)
            conn = "<<no current connection>>";
        retsv = newSVpv(conn, 0);
    }
    else if (KEY_MATCH(kl, key, ix_prodver))
    {
        retsv = newSViv((IV)esql_prodvrsn);
    }
    else if (KEY_MATCH(kl, key, ix_prodnam))
    {
        retsv = newSVpv((char *)&esql_prodname[4], 0);  /* const_cast<char *> */
    }

    else
    {
        dbd_ix_exit(function);
        return FALSE;
    }

    dbd_ix_exit(function);

    return sv_2mortal(retsv);
}

/* Set database connection attributes */
int dbd_ix_db_STORE_attrib(SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)
{
    static const char function[] = "dbd_ix_db_STORE_attrib";
    STRLEN          kl;
    char           *key = SvPV(keysv, kl);
    int             newval = SvTRUE(valuesv);
    int             retval = True;

    dbd_ix_enter(function);

    if (KEY_MATCH(kl, key, "AutoCommit"))
    {
        if (imp_dbh->is_loggeddb == False)
        {
            assert(DBI_AutoCommit(imp_dbh));
            if (newval == False && SvTRUE(imp_dbh->database))
            {
                croak("%s - Cannot unset AutoCommit for unlogged databases\n",
                        dbd_ix_module());
            }
        }
        else
        {
            int oldval = DBI_AutoCommit(imp_dbh);
            DBIc_set(imp_dbh, DBIcf_AutoCommit, newval);
            if (oldval == False && newval == True)
            {
                /* Commit any outstanding changes (it is AutoCommit!) */
                retval = dbd_ix_db_commit(dbh, imp_dbh);
            }
            else if (oldval == True && newval == False)
            {
                /* AutoCommit turned off - start TX in non-ANSI databases */
                if (imp_dbh->is_modeansi == False)
                    retval = dbd_ix_db_begin(imp_dbh);
            }
            else
            {
                /* AutoCommit state not changed */
                assert(oldval == newval);
            }
        }
    }
    else if (KEY_MATCH(kl, key, ix_blobloc))
    {
        imp_dbh->blob_bind = blob_bindtype(valuesv);
    }
    else if (KEY_MATCH(kl, key, ix_worepln))
    {
        /* Bryan Castillo: set flag for replication */
        imp_dbh->no_replication = SvTRUE(valuesv);
        dbd_ix_db_commit(dbh, imp_dbh); /* start new tran (with|w/o) repl. */
    }
    else if(KEY_MATCH(kl, key, ix_enable_utf8))
    {
        /* UTF8 patch */
        imp_dbh->enable_utf8 = SvTRUE(valuesv);
    }
    else
    {
        retval = FALSE;
    }

    dbd_ix_exit(function);

    return retval;
}

/* Convert sqlca.sqlerrd into a reference to an array */
static SV *newSqlerrd(const Sqlca *psqlca)
{
    int i;
    AV *av = newAV();
    SV *retsv = newRV_inc((SV *)av);
    av_extend(av, (I32)6);
    sv_2mortal((SV *)av);
    for (i = 0; i < 6; i++)
    {
        av_store(av, i, newSViv((IV)psqlca->sqlerrd[i]));
    }
    return(retsv);
}

/* Convert sqlca.sqlwarn into a reference to an array */
static SV *newSqlwarn(const Sqlca *psqlca)
{
    int i;
    AV             *av = newAV();
    char            warning[2];
    const char     *sqlwarn = &psqlca->sqlwarn.sqlwarn0;
    SV *retsv = newRV_inc((SV *)av);
    av_extend(av, (I32)8);
    sv_2mortal((SV *)av);
    warning[1] = '\0';
    for (i = 0; i < 8; i++)
    {
        warning[0] = *sqlwarn++;
        av_store(av, i, newSVpv(warning, 0));
    }
    return(retsv);
}

/* Argument is not const because ifx_int8toasc() is not declared const */
/* ifx_int8toasc() blank pads but does not null terminate its output. */
static SV *newSerial8(ifx_int8_t *v)
{
    char buffer[24];
    SV *retsv;

    ifx_int8toasc(v, buffer, sizeof(buffer)-1);
    buffer[sizeof(buffer)-1] = '\0';
    retsv = newSVpv(buffer, 0);
    return(retsv);
}

#ifdef ESQLC_BIGINT
static SV *newBigSerial(bigint v)
{
    char buffer[24];
    SV *retsv;

    biginttoasc(v, buffer, sizeof(buffer)-1, 10);
    retsv = newSVpv(buffer, 0);
    return(retsv);
}
#endif /* ESQLC_BIGINT */

static SV *dbd_ix_getsqlca(imp_dbh_t *imp_dbh, STRLEN kl, char *key)
{
    SV *retsv = NULL;

    /* Preferred versions */
    if (KEY_MATCH(kl, key, ix_sqlcode))
    {
        retsv = newSViv((IV)imp_dbh->ix_sqlca.sqlcode);
    }
    else if (KEY_MATCH(kl, key, ix_sqlerrm))
    {
        retsv = newSVpv(imp_dbh->ix_sqlca.sqlerrm, 0);
    }
    else if (KEY_MATCH(kl, key, ix_sqlerrp))
    {
        retsv = newSVpv(imp_dbh->ix_sqlca.sqlerrp, 0);
    }
    else if (KEY_MATCH(kl, key, ix_sqlerrd))
    {
        retsv = newSqlerrd(&imp_dbh->ix_sqlca);
    }
    else if (KEY_MATCH(kl, key, ix_sqlwarn))
    {
        retsv = newSqlwarn(&imp_dbh->ix_sqlca);
    }
    else if (KEY_MATCH(kl, key, ix_serial8))
    {
        retsv = newSerial8(&imp_dbh->ix_serial8);
    }
    else if (KEY_MATCH(kl, key, ix_serial4))
    {
        retsv = newSViv((IV)imp_dbh->ix_sqlca.sqlerrd[1]);
    }
#ifdef ESQLC_BIGINT
    else if (KEY_MATCH(kl, key, ix_bigser8))
    {
        retsv = newBigSerial(imp_dbh->ix_bigserial);
    }
#endif /* ESQLC_BIGINT */

    return(retsv);
}

SV *dbd_ix_db_FETCH_attrib(SV *dbh, imp_dbh_t *imp_dbh, SV *keysv)
{
    static const char function[] = "dbd_ix_db_FETCH_attrib";
    STRLEN          kl;
    char           *key = SvPV(keysv, kl);
    SV             *retsv = Nullsv;

    dbd_ix_enter(function);

    if (KEY_MATCH(kl, key, "AutoCommit"))
    {
        retsv = newSViv((IV)DBI_AutoCommit(imp_dbh));
    }
    else if (KEY_MATCH(kl, key, ix_ixonlin))
    {
        retsv = newSViv((IV)imp_dbh->is_onlinedb);
    }
    else if (KEY_MATCH(kl, key, ix_loggedb))
    {
        retsv = newSViv((IV)imp_dbh->is_loggeddb);
    }
    else if (KEY_MATCH(kl, key, ix_intrans))
    {
        retsv = newSViv((IV)imp_dbh->is_txactive);
    }
    else if (KEY_MATCH(kl, key, ix_modeans))
    {
        retsv = newSViv((IV)imp_dbh->is_modeansi);
    }
    else if (KEY_MATCH(kl, key, ix_srvrvsn))
    {
        retsv = newSViv((IV)imp_dbh->srvr_vrsn);
    }
    else if (KEY_MATCH(kl, key, ix_srvrnam))
    {
        char *srvrname = "";
        if (imp_dbh->srvr_name)
            srvrname = SvPV(imp_dbh->srvr_name, PL_na);
        retsv = newSVpv(srvrname, 0);
    }
    else if (KEY_MATCH(kl, key, ix_stoproc))
    {
        retsv = newSViv((IV)imp_dbh->has_procs);
    }
    else if (KEY_MATCH(kl, key, ix_blobsup))
    {
        retsv = newSViv((IV)imp_dbh->has_blobs);
    }
    else if (KEY_MATCH(kl, key, ix_blobloc))
    {
        retsv = newSVpv(blob_bindname(imp_dbh->blob_bind), 0);
    }
    else if (KEY_MATCH(kl, key, ix_conname))
    {
        retsv = newSVpv(imp_dbh->nm_connection, 0);
    }
    else if (KEY_MATCH(kl, key, ix_worepln))
    {
        /* Bryan Castillo: return value for replication */
        retsv = newSViv((IV)imp_dbh->no_replication);
    }
    else if (KEY_MATCH(kl, key, ix_dbsname))
    {
        char *dbname = "";
        if (imp_dbh->database)
            dbname = SvPV(imp_dbh->database, PL_na);
        retsv = newSVpv(dbname, 0);
    }
    else if ((retsv = dbd_ix_getsqlca(imp_dbh, kl, key)) != NULL)
    {
        /* Nothing to do */
    }
    else
    {
        /* Treat it as a driver query */
        D_imp_drh_from_dbh;
        dbd_ix_exit(function);
        return dbd_ix_dr_FETCH_attrib(imp_drh, keysv);
    }

    dbd_ix_exit(function);

    return sv_2mortal(retsv);
}

/* Store statement attributes */
int dbd_ix_st_STORE_attrib(SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv)
{
    static const char function[] = "dbd_ix_st_STORE_attrib";
    STRLEN          kl;
    char           *key = SvPV(keysv, kl);
    int             rc = TRUE;

    dbd_ix_enter(function);

    if (KEY_MATCH(kl, key, ix_blobloc))
    {
        imp_sth->blob_bind = blob_bindtype(valuesv);
    }
    else
        rc = FALSE;

    dbd_ix_exit(function);

    return rc;
}

static SV *dbd_ix_st_bound_parameters(imp_sth_t *imp_sth)
{
    SV *retsv = NULL;
    KLUDGE("dbd_ix_st_bound_parameters not implemented yet");
    return retsv;
}

SV *dbd_ix_st_FETCH_attrib(SV *sth, imp_sth_t *imp_sth, SV *keysv)
{
    static const char function[] = "dbd_ix_st_FETCH_attrib";
    STRLEN          kl;
    char           *key = SvPV(keysv, kl);
    SV             *retsv = NULL;
    AV             *av = 0;
    EXEC SQL BEGIN DECLARE SECTION;
    char           *nm_obind = imp_sth->nm_obind;
    long            coltype;
    long            collength;
    long            colnull;
    char            colname[SQL_COLNAMELEN];
    int             i;
    EXEC SQL END DECLARE SECTION;

    dbd_ix_enter(function);

    /* Standard attributes */
    if (KEY_MATCH(kl, key, "NAME"))
    {
        av = newAV();
        retsv = newRV_inc((SV *)av);
        for (i = 1; i <= imp_sth->n_ocols; i++)
        {
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
                :colname = NAME;
            colname[byleng(colname, strlen(colname))] = '\0';
            av_store(av, i - 1, newSVpv(colname, 0));
        }
    }
    else if (KEY_MATCH(kl, key, "NULLABLE"))
    {
        av = newAV();
        retsv = newRV_inc((SV *)av);
        for (i = 1; i <= imp_sth->n_ocols; i++)
        {
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
                :colnull = NULLABLE;
            av_store(av, i - 1, newSViv((IV)colnull));
        }
    }
    else if (KEY_MATCH(kl, key, "TYPE"))
    {
        /* Returns ODBC (CLI) type numbers. */
        av = newAV();
        retsv = newRV_inc((SV *)av);
        for (i = 1; i <= imp_sth->n_ocols; i++)
        {
            SV      *sv;
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
                :coltype = TYPE, :collength = LENGTH;
            sv = newSViv(map_type_ifmx_to_odbc(coltype, collength));
            av_store(av, i - 1, sv);
        }
    }
    else if (KEY_MATCH(kl, key, "PRECISION"))
    {
        /* Should return CLI precision numbers. */
        av = newAV();
        retsv = newRV_inc((SV *)av);
        for (i = 1; i <= imp_sth->n_ocols; i++)
        {
            SV      *sv;
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
                :coltype = TYPE, :collength = LENGTH;
            sv = newSViv(map_prec_ifmx_to_odbc(coltype, collength));
            av_store(av, i - 1, sv);
        }
    }
    else if (KEY_MATCH(kl, key, "SCALE"))
    {
        /* Should return CLI scale numbers. */
        av = newAV();
        retsv = newRV_inc((SV *)av);
        for (i = 1; i <= imp_sth->n_ocols; i++)
        {
            SV      *sv;
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
                :coltype = TYPE, :collength = LENGTH;
            sv = newSViv(map_scale_ifmx_to_odbc(coltype, collength));
            av_store(av, i - 1, sv);
        }
    }
    else if (KEY_MATCH(kl, key, "NUM_OF_PARAMS"))
    {
        retsv = newSViv((IV)DBIc_NUM_PARAMS(imp_sth));
    }
    else if (KEY_MATCH(kl, key, "NUM_OF_FIELDS"))
    {
        assert(imp_sth->n_ocols == DBIc_NUM_FIELDS(imp_sth));

        /* RT#54426: Fix for NUM_OF_FIELDS > 0 test */
        /* Avoid returning non-zero value on INSERT */
        if (imp_sth->st_type == SQ_SELECT ||
            (imp_sth->st_type == SQ_EXECPROC && imp_sth->n_ocols > 0))
            retsv = newSViv((IV)imp_sth->n_ocols);
        else
            retsv = newSViv(0);
    }
    else if (KEY_MATCH(kl, key, "CursorName"))
    {
        retsv = newSVpv(imp_sth->nm_cursor, 0);
    }
    else if (KEY_MATCH(kl, key, "ParamValues"))
    {
        retsv = dbd_ix_st_bound_parameters(imp_sth);
    }

    /* Informix specific attributes */
    else if (KEY_MATCH(kl, key, ix_typenam))
    {
        char buffer[SQLTYPENAME_BUFSIZ];
        SV      *sv;
        av = newAV();
        retsv = newRV_inc((SV *)av);
        for (i = 1; i <= imp_sth->n_ocols; i++)
        {
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
                :coltype = TYPE, :collength = LENGTH;
            sv = newSVpv(sqltypename(coltype, collength, buffer, sizeof(buffer)), 0);
            av_store(av, i - 1, sv);
        }
    }
    else if (KEY_MATCH(kl, key, ix_fetchab))
    {
        Boolean rv = DBD_IX_BOOLEAN((imp_sth->st_type == SQ_SELECT) ||
                        (imp_sth->st_type == SQ_EXECPROC && imp_sth->n_ocols > 0));
        retsv = newSViv((IV)rv);
    }
    else if (KEY_MATCH(kl, key, ix_blobloc))
    {
        retsv = newSVpv(blob_bindname(imp_sth->dbh->blob_bind), 0);
    }
    else if ((retsv = dbd_ix_getsqlca(imp_sth->dbh, kl, key)) != NULL)
    {
        /* Nothing specific to do */
    }
    else if (KEY_MATCH(kl, key, ix_coltype))
    {
        av = newAV();
        retsv = newRV_inc((SV *)av);
        for (i = 1; i <= imp_sth->n_ocols; i++)
        {
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
                :coltype = TYPE;
            av_store(av, i - 1, newSViv((IV)coltype));
        }
    }
    else if (KEY_MATCH(kl, key, ix_colleng))
    {
        av = newAV();
        retsv = newRV_inc((SV *)av);
        for (i = 1; i <= imp_sth->n_ocols; i++)
        {
            EXEC SQL GET DESCRIPTOR :nm_obind VALUE :i
                :collength = LENGTH;
            av_store(av, i - 1, newSViv((IV)collength));
        }
    }
    else if (KEY_MATCH(kl, key, ix_csrhold))
    {
        retsv = newSViv((IV)imp_sth->is_holdcursor);
    }
    else if (KEY_MATCH(kl, key, ix_scrlcsr))
    {
        retsv = newSViv((IV)imp_sth->is_scrollcursor);
    }
    else if (KEY_MATCH(kl, key, ix_instcsr))
    {
        retsv = newSViv((IV)imp_sth->is_insertcursor);
    }
    else
    {
        dbd_ix_exit(function);
        return Nullsv;
    }

    dbd_ix_exit(function);

    if (av != 0)
        sv_2mortal((SV *)av);

    return sv_2mortal(retsv);
}
