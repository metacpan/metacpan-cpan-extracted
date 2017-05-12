// ***************************************************************************
// Copyright (c) 2015 SAP SE or an SAP affiliate company. All rights reserved.
// ***************************************************************************
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//   While not a requirement of the license, if you do modify this file, we
//   would appreciate hearing about it. Please email
//   sqlany_interfaces@sybase.com
//
//====================================================

#define _WIN32_WINNT 0x0501
#include "SQLAnywhere.h"
#include "perlapi.h"

DBISTATE_DECLARE;

#ifndef PerlIO
#  define PerlIO FILE
#  define PerlIO_printf fprintf
#  define PerlIO_stderr() stderr
#  define PerlIO_stdout() stdout
#endif

/* XXX DBI should provide a better version of this */
#define IS_DBI_HANDLE(h) \
    (SvROK(h) && SvTYPE(SvRV(h)) == SVt_PVHV && \
	SvRMAGICAL(SvRV(h)) && (SvMAGIC(SvRV(h)))->mg_type == 'P')

#define _min( a, b ) (((a)<(b))?(a):(b))
#define _max( a, b ) (((a)>=(b))?(a):(b))

#define IS_SACAPI_V2() ((sacapi->api.sqlany_init_ex) != NULL)

SACAPI *StaticAPI_V1;

// DBI can free dbh handles _after_ freeing the driver handle so we use refcounting for the
// driver-related things that are still needed at dbh destruction time

SACAPI *
SACAPI_Alloc()
/************/
{
    SACAPI	*sacapi = (SACAPI *)safemalloc( sizeof(SACAPI) );
    memset( sacapi, 0, sizeof( SACAPI ) );
    sacapi->refcount = 1;
    if( sqlany_initialize_interface( &sacapi->api, NULL ) ) {
	unsigned	max_api_ver;
	if( IS_SACAPI_V2() ) {
	    sacapi->context = sacapi->api.sqlany_init_ex( "PerlDBD", SQLANY_API_VERSION_2, &max_api_ver );
	    if( sacapi->context == NULL ) {
		sqlany_finalize_interface( &sacapi->api );
		Safefree( sacapi );
		sacapi = NULL;
	    }
	} else {
	    // V1 uses a single global context within dbcapi.dll so we need our own global context
	    LOCK_DOLLARZERO_MUTEX;
	    if( StaticAPI_V1 == NULL ) {
		if( sacapi->api.sqlany_init( "PerlDBD", SQLANY_API_VERSION_1, &max_api_ver ) ) {
		    StaticAPI_V1 = sacapi;
		} else {
		    sqlany_finalize_interface( &sacapi->api );
		    Safefree( sacapi );
		    sacapi = NULL;
		}
	    } else {
		sqlany_finalize_interface( &sacapi->api );
		Safefree( sacapi );
		sacapi = StaticAPI_V1;
		sacapi->refcount++;
	    }
	    UNLOCK_DOLLARZERO_MUTEX;
	}
    } else {
	Safefree( sacapi );
	sacapi = NULL;
    }
    return( sacapi );
}

SACAPI *
SACAPI_AddRef( SACAPI *sacapi )
/*****************************/
{
    LOCK_DOLLARZERO_MUTEX;
    ++sacapi->refcount;
    UNLOCK_DOLLARZERO_MUTEX;
    return( sacapi );
}

void
SACAPI_Release( SACAPI *sacapi )
/******************************/
{
    LOCK_DOLLARZERO_MUTEX;
    if( sacapi->refcount ) {
	if( --sacapi->refcount == 0 ) {
	    if( sacapi->api.initialized ) {
		if( IS_SACAPI_V2() ) {
		    sacapi->api.sqlany_fini_ex( sacapi->context );
		    sacapi->context = NULL;
		} else {
		    sacapi->api.sqlany_fini();
		}
		sqlany_finalize_interface( &sacapi->api );
	    }
	    memset( sacapi, 0, sizeof(SACAPI) );
	    Safefree( sacapi );
	    if( sacapi == StaticAPI_V1 ) {
		StaticAPI_V1 = NULL;
	    }
	}
    } else {
	croak( "SACAPI refcount is already zero" );
    }
    UNLOCK_DOLLARZERO_MUTEX;
}

void
dbd_init( dbistate_t *dbistate )
/******************************/
// Called at boot (library load) time
// *CAN* be called concurrently by two threads loading the driver 
// at the same time!
{
    dTHX;
    DBISTATE_INIT;
//DBIS->debug = 3;
//DBILOGFP = PerlIO_stdout();
}

int
dbd_dr_init( SV *drh )
/********************/
// Called once when each driver object is created and locked so there
// is no concurrent access.
{
    dTHX;
    D_imp_drh( drh );

    imp_drh->sacapi = SACAPI_Alloc();
    if( imp_drh->sacapi == NULL ) {
	return( FALSE );
    }

    DBIc_IMPSET_on( imp_drh );	// imp_drh set up now
    return( TRUE );
}

int
dbd_dr_destroy( SV *drh )
/***********************/
// Called once when each driver object is created and locked so there
// is no concurrent access.
{
    dTHX;
    D_imp_drh( drh );
    if( DBIc_IMPSET( imp_drh ) ) {
	if( imp_drh->sacapi != NULL ) {
	    SACAPI_Release( imp_drh->sacapi );
	}
	DBIc_IMPSET_off( imp_drh );
    }
    return( TRUE );
}

int
dbd_discon_all( SV *drh, imp_drh_t *imp_drh )
/*******************************************/
{
    dTHR;
    dTHX;

    /* The disconnect_all concept is flawed and needs more work */
    if( !PL_dirty && !SvTRUE(perl_get_sv("DBI::PERL_ENDING",0)) ) {
	sv_setiv( DBIc_ERR(imp_drh), (IV)1 );
	sv_setpv( DBIc_ERRSTR(imp_drh),
		  (char *)"disconnect_all not implemented");
	DBIh_EVENT2( drh, ERROR_event,
		     DBIc_ERR(imp_drh), DBIc_ERRSTR(imp_drh) );
	return( FALSE );
    }
    if( PL_perl_destruct_level ) {
	PL_perl_destruct_level = 0;
    }
    return( FALSE );
}

/* Database specific error handling.
	This will be split up into specific routines
	for dbh and sth level.
	Also split into helper routine to set number & string.
	Err, many changes needed, ramble ...
*/

void
ssa_error( pTHX_ SV *h, a_sqlany_connection *conn, int sqlcode, char *what )
/**************************************************************************/
{
    D_imp_xxh(h);
    SV *errstr = DBIc_ERRSTR(imp_xxh);
    SV *state = DBIc_STATE(imp_xxh);

    D_imp_drh( h );	// not yet a driver handle!
    while( DBIc_TYPE( imp_drh ) != DBIt_DR ) {
	imp_drh = (imp_drh_t *)(DBIc_PARENT_COM( imp_drh ));
    }

    if( conn ) {	/* is SQLAnywhere error (allow for non-SQLAnywhere errors) */
	char 	msg[256];
	size_t	len;
	char	sqlstate[6];

	sqlcode = imp_drh->sacapi->api.sqlany_error( conn, msg, sizeof(msg) );
	imp_drh->sacapi->api.sqlany_sqlstate( conn, sqlstate, sizeof(sqlstate) );
	len = strlen( msg );
	if( len && msg[len-1] == '\n' )
	    msg[len-1] = '\0'; /* trim off \n from end of message */
	sv_setpv( errstr, msg );

	if( what ) {
	    sv_catpv( errstr, " (DBD: " );
	    sv_catpv( errstr, what );
	    sv_catpv( errstr, ")" );
	}
	sv_setiv( DBIc_ERR(imp_xxh), (IV)sqlcode );
	imp_drh->sacapi->api.sqlany_sqlstate( conn, sqlstate, sizeof(sqlstate) );
	sv_setpv( state, sqlstate );
    } else {
	sv_setpv( errstr, what );
	sv_setiv( DBIc_ERR(imp_xxh), (IV)sqlcode );
	sv_setpv( errstr, (what ? what : "") );
	sv_setpv( state, "" );
    }
    DBIh_EVENT2( h, ERROR_event, DBIc_ERR(imp_xxh), errstr );
    if( DBIS->debug >= 2 ) {
	PerlIO_printf( DBILOGFP, "%s error %d recorded: %s\n",
		       what, sqlcode, SvPV(errstr,PL_na) );
    }
}

/* ================================================================== */
int
dbd_db_login( SV	*dbh,
	       imp_dbh_t *imp_dbh,
	       char	*conn_str,
	       char	*server_side_sqlca_str,
	       char	*ignored )
/********************************/
{
    return( dbd_db_login6( dbh, imp_dbh, conn_str, server_side_sqlca_str, ignored, Nullsv ) );
}

int
dbd_db_login6( SV	*dbh,
	       imp_dbh_t *imp_dbh,
	       char	*conn_str,
	       char	*server_side_sqlca_str,
	       char	*ignored,
	       SV	*attr )
/*****************************/
{
    dTHR;
    dTHX;
    D_imp_drh_from_dbh;
    SACAPI	*sacapi = SACAPI_AddRef( imp_drh->sacapi );

    if( sacapi == NULL || !sacapi->api.initialized ) {
	ssa_error( aTHX_ dbh, NULL, SQLE_ERROR, "SQLAnwyhere C API (dbcapi) could not be loaded." );
	if( sacapi ) {
	    SACAPI_Release( sacapi );
	}
	return( 0 );
    }
	
    // SQLAnywhere.pm will pass a connection pointer in the uid field if this 
    // connect is for server-side perl's default connection.
    imp_dbh->conn = NULL;
    imp_dbh->ss_sqlca = NULL;
    if( server_side_sqlca_str != NULL && *server_side_sqlca_str != '\0' ) {
    	sscanf( server_side_sqlca_str, "%p", &imp_dbh->ss_sqlca );
	if( IS_SACAPI_V2() ) {
	    imp_dbh->conn = sacapi->api.sqlany_make_connection_ex( sacapi->context, 
		    imp_dbh->ss_sqlca );
	} else {
	    imp_dbh->conn = sacapi->api.sqlany_make_connection( imp_dbh->ss_sqlca );
	}
	if( imp_dbh->conn == NULL ) {
	    ssa_error( aTHX_ dbh, NULL, SQLE_ERROR, "failed to establish server-side connection" );
	    SACAPI_Release( sacapi );
	    return( 0 );
	}
    } else {
//	printf( "Connect string: %s\n", conn_str );
	if( IS_SACAPI_V2() ) {
	    imp_dbh->conn = sacapi->api.sqlany_new_connection_ex( sacapi->context );
	} else {
	    imp_dbh->conn = sacapi->api.sqlany_new_connection();
	}
	if( imp_dbh->conn == NULL ) {
	    ssa_error( aTHX_ dbh, NULL, SQLE_ERROR, "failed to allocate connection" );
	    SACAPI_Release( sacapi );
	    return( 0 );
	}
	if( !sacapi->api.sqlany_connect( imp_dbh->conn, conn_str ) ) {
	    ssa_error( aTHX_ dbh, imp_dbh->conn, SQLE_ERROR, "login failed" );
	    sacapi->api.sqlany_free_connection( imp_dbh->conn );
	    SACAPI_Release( sacapi );
	    return( 0 );
	}
    }

    imp_dbh->sacapi = sacapi;
    DBIc_IMPSET_on( imp_dbh );	/* imp_dbh set up now			*/
    DBIc_ACTIVE_on( imp_dbh );	/* call disconnect before freeing	*/
    DBIc_LongReadLen( imp_dbh ) = DEFAULT_LONG_READ_LENGTH;
    DBIc_off( imp_dbh, DBIcf_LongTruncOk );
    DBIc_on( imp_dbh, DBIcf_AutoCommit );

    return( 1 );
}


int
dbd_db_commit( SV *dbh, imp_dbh_t *imp_dbh )
/******************************************/
{
    SACAPI *sacapi = imp_dbh->sacapi;
    if( !sacapi->api.sqlany_commit( imp_dbh->conn ) ) {
	dTHX;
	ssa_error( aTHX_ dbh, imp_dbh->conn, SQLE_ERROR, "commit failed" );
	return( 0 );
    }

    return( 1 );
}

int
dbd_db_rollback( SV *dbh, imp_dbh_t *imp_dbh )
/********************************************/
{
    SACAPI *sacapi = imp_dbh->sacapi;

    if( !sacapi->api.sqlany_rollback( imp_dbh->conn ) ) {
	dTHX;
	ssa_error( aTHX_ dbh, imp_dbh->conn, SQLE_ERROR, "rollback failed" );
	return( 0 );
    }

    return( 1 );
}


int
dbd_db_disconnect( SV *dbh, imp_dbh_t *imp_dbh )
/**********************************************/
{
    dTHR;
    dTHX;
    SACAPI *sacapi = imp_dbh->sacapi;
    
    // don't close the connection if it was opened externally
    if( imp_dbh->ss_sqlca ) {
    	return( 1 );
    }

    /* We assume that disconnect will always work	*/
    /* since most errors imply already disconnected.	*/
    DBIc_ACTIVE_off( imp_dbh );

    if( !sacapi->api.sqlany_disconnect( imp_dbh->conn ) ) {
	ssa_error( aTHX_ dbh, imp_dbh->conn, SQLE_ERROR, "disconnect error" );
	return( 0 );
    }

    /* We don't free imp_dbh since a reference still exists	*/
    /* The DESTROY method is the only one to 'free' memory.	*/
    /* Note that statement objects may still exists for this dbh!	*/
    return( 1 );
}


void
dbd_db_destroy( SV *dbh, imp_dbh_t *imp_dbh )
/*******************************************/
{
    SACAPI *sacapi = imp_dbh->sacapi;

    if( DBIc_IMPSET( imp_dbh ) ) {
	D_imp_drh_from_dbh;
	// don't close the connection if it was opened externally
	if( imp_dbh->ss_sqlca == NULL ) {
	    if( DBIc_ACTIVE( imp_dbh ) ) {
		dbd_db_disconnect( dbh, imp_dbh );
	    }
	}
	sacapi->api.sqlany_free_connection( imp_dbh->conn );
	SACAPI_Release( imp_dbh->sacapi );
	imp_dbh->sacapi = NULL;

	/* Nothing in imp_dbh to be freed	*/
	DBIc_IMPSET_off( imp_dbh );
    }
}


int
dbd_db_STORE_attrib( SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv )
/************************************************************************/
{
    dTHX;
    STRLEN 	kl;
    char 	*key = SvPV( keysv, kl );
    SV 		*cachesv = NULL;
    int		was_off;
    int 	on = SvTRUE( valuesv );
    SACAPI	*sacapi = imp_dbh->sacapi;

    if( kl==10 && strEQ( key, "AutoCommit" ) ) {
	was_off = !DBIc_has(imp_dbh,DBIcf_AutoCommit);
	if( was_off && on ) {
	    sacapi->api.sqlany_commit( imp_dbh->conn );
	}
	cachesv = (on) ? &PL_sv_yes : &PL_sv_no;	/* cache new state */
	DBIc_set( imp_dbh, DBIcf_AutoCommit, on );
    } else {
	return FALSE;
    }
    if( cachesv ) { /* cache value for later DBI 'quick' fetch? */
	hv_store( (HV*)SvRV(dbh), key, (I32)kl, cachesv, 0 );
    }
    return( TRUE );
}


SV *
dbd_db_FETCH_attrib( SV *dbh, imp_dbh_t *imp_dbh, SV *keysv )
/***********************************************************/
{
    dTHX;
    STRLEN 	kl;
    char 	*key = SvPV(keysv,kl);
    SV 		*retsv = Nullsv;

    /* Default to caching results for DBI dispatch quick_FETCH	*/
    int cacheit = FALSE;

    if( kl==10 && strEQ(key, "AutoCommit") ) {
        retsv = boolSV(DBIc_has(imp_dbh,DBIcf_AutoCommit));
    }
    if( retsv == Nullsv ) {
	return( Nullsv );
    }
    if( cacheit ) {	/* cache for next time (via DBI quick_FETCH)	*/
	SV **svp = hv_fetch( (HV*)SvRV(dbh), key, (I32)kl, 1 );
	sv_free( *svp );
	*svp = retsv;
	(void)SvREFCNT_inc( retsv );	/* so sv_2mortal won't free it	*/
    }
    return( sv_2mortal( retsv ) );
}


/* ================================================================== */

int
dbd_st_prepare( SV *sth, imp_sth_t *imp_sth, char *statement, SV *attribs )
/*************************************************************************/
{
    dTHX;
    D_imp_dbh_from_sth;
    char		*_statement;
    SACAPI		*sacapi = imp_dbh->sacapi;

    /* scan statement for '?', ':1' and/or ':foo' style placeholders	*/
    dbd_preparse( imp_sth, statement );
    _statement = (char *)imp_sth->sql_statement;

    if( DBIS->debug >= 2 ) {
	PerlIO_printf( DBILOGFP, "\n\nPrepare: '%s'\n\n", _statement );
    }
    imp_sth->statement = sacapi->api.sqlany_prepare( imp_dbh->conn, _statement );
    if( imp_sth->statement == NULL ) {
	dTHX;
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "prepare failed" ); 
	return( 0 );
    }
    
    imp_sth->num_bind_params = sacapi->api.sqlany_num_params( imp_sth->statement );
    DBIc_NUM_PARAMS( imp_sth ) = imp_sth->num_bind_params;
    DBIc_NUM_FIELDS( imp_sth ) = 0;	// FIXME: must be replaced with estimated column count

    DBIc_IMPSET_on( imp_sth );

    return( 1 );
}


void
dbd_preparse( imp_sth_t *imp_sth, char *statement )
/*************************************************/
{
    dTHX;
    char 	*src, *start, *dest;
    phs_t 	phs_tpl;
    SV 		*phs_sv;
    int 	idx=0, style=0, laststyle=0;
    int		curr_ordinal = 1;
    char	_ph_name_buf[10];
    char	*ph_name;
    size_t	ph_name_len;
    

    /* allocate room for copy of statement with spare capacity	*/
    /* for editing ':1' into ':p1' so we can use obndrv.	*/
    imp_sth->sql_statement = (char *)safemalloc( strlen(statement) + 1 );
 
    /* initialise phs ready to be cloned per placeholder	*/
    memset( &phs_tpl, '\0', sizeof(phs_tpl) );

    src  = statement;
    dest = imp_sth->sql_statement;
    while( *src ) {
	if( (*src == '-' && src[1] == '-') ||
	    (*src == '/' && src[1] == '/') ) {
	    // Skip to end of line
	    *dest++ = *src++;
	    *dest++ = *src++;
	    while( *src ) {
		if( *src == '\n' ) {
		    *dest++ = *src++;
		    break;
		}
		*dest++ = *src++;
	    }
	} else if( *src == '/' && src[1] == '*' ) {
	    // Skip to end of comment
	    *dest++ = *src++;
	    *dest++ = *src++;
	    while( *src ) {
		if( *src == '*' && src[1] == '/' ) {
		    *dest++ = *src++;
		    *dest++ = *src++;
		    break;
		}
		*dest++ = *src++;
	    }
	} else if( *src == '\'' || *src == '\"' ) {
	    char quote = *src;
	    *dest++ = *src++;
	    while( *src ) {
		if( *src == quote ) {
		    *dest++ = *src++;
		    if( *src == quote ) {
			*dest++ = *src++;
		    } else {
			break;
		    }
		} else {
		    *dest++ = *src++;
		}
	    }
	} else if( *src == ':' || *src == '?' ) {
	    start = dest;			/* save name inc colon	*/ 
	    *dest++ = *src++;
	    ph_name = NULL;
	    ph_name_len = 0;
	    if( *start == '?' ) {		/* X/Open standard	*/
		style = 3;
	    } else if( isDIGIT(*src) ) {	/* ':1'		*/
		*start = '?';

		idx = atoi( src );
		if( idx <= 0 ) {
		    croak( "Placeholder :%d must be a positive number", idx );
		}
		if( idx != curr_ordinal ) {
		    croak( "Cannot handle unordered ':numeric' placeholders" );
		}
		while( isDIGIT(*src) ) {
		    ++src;
		}
		style = 1;
	    } else if( isALNUM(*src) ) {	/* ':foo'	*/
		*start = '?';
		ph_name = src-1;
		++ph_name_len;		// for ':'
		while( isALNUM(*src) ) {	/* includes '_'	*/
		    ++ph_name_len;
		    ++src;
		}
		style = 2;
	    } else {			/* perhaps ':=' PL/SQL construct */
		continue;
	    }
	    *dest = '\0';			/* handy for debugging	*/
	    if( laststyle && style != laststyle ) {
		croak( "Can't mix placeholder styles (%d/%d)", style, laststyle );
	    }
	    laststyle = style;
	    if( imp_sth->bind_names == NULL ) {
		imp_sth->bind_names = newHV();
	    }
	    phs_tpl.ordinal = curr_ordinal;
	    phs_tpl.sv = &PL_sv_undef;
	    phs_sv = newSVpv( (char*)&phs_tpl, sizeof(phs_tpl) );
	    if( ph_name == NULL ) {
		ph_name = _ph_name_buf;
		sprintf( ph_name, ":p%d", curr_ordinal );
		ph_name_len = strlen( ph_name );
	    }
	    hv_store( imp_sth->bind_names, ph_name, (I32)ph_name_len,
		      phs_sv, 0 );
	    ++curr_ordinal;
	    /* warn("bind_names: '%s'\n", start);	*/
	} else {
	    *dest++ = *src++;
	} 
    }
    *dest = '\0';
    if( DBIS->debug >= 2 ) {
	PerlIO_printf( DBILOGFP, "\nPreparse transformed statement: '%s'\n", imp_sth->sql_statement );
    }
    if( imp_sth->bind_names ) {
	imp_sth->num_bind_params_scanned = (int)HvKEYS(imp_sth->bind_names);
	if( DBIS->debug >= 2 ) {
	    PerlIO_printf( DBILOGFP, "scanned %d distinct placeholders\n",
			   imp_sth->num_bind_params_scanned );
	}
    }
}

int
dbd_bind_ph( SV		*sth,
	     imp_sth_t 	*imp_sth,
	     SV 	*ph_namesv,
	     SV 	*newvalue, 
	     IV 	sql_type,
	     SV 	*attribs,
	     int 	is_inout,
	     IV 	maxlen )
/******************************/
{
    dTHX;
    D_imp_dbh_from_sth;
    SV 			**svp;
    STRLEN 		name_len;
    char 		*name;
    phs_t 		*phs;
    char 		buf[10];

    if( SvNIOK( ph_namesv ) ) {	/* passed as a number	*/
	name = buf;
	sprintf( name, ":p%d", (int)SvIV( ph_namesv ) );
	name_len = strlen(name);
    } else {
	name = SvPV( ph_namesv, name_len );
    }

    // FIXME: Why croak() and not just report an error?
    if( SvTYPE(newvalue) > SVt_PVLV ) { /* hook for later array logic	*/
	croak( "Can't bind a non-scalar value" );
    }

    if( SvROK(newvalue) && !IS_DBI_HANDLE(newvalue) ) {
	/* dbi handle allowed for cursor variables */
	croak( "Can't bind a reference (%s)", neatsvpv(newvalue,0) );
    }

    if( SvTYPE(newvalue) == SVt_PVLV && is_inout ) {	/* may allow later */
	croak( "Can't bind ``lvalue'' mode scalar as inout parameter" );
    }

    if( DBIS->debug >= 2 ) {
	PerlIO_printf( DBILOGFP, "         bind %s <== %s (type %ld",
		       name, neatsvpv(newvalue,0), (long)sql_type );
	if( is_inout ) {
	    PerlIO_printf( DBILOGFP, ", inout 0x%p", newvalue );
	}
	if( attribs ) {
	    PerlIO_printf( DBILOGFP, ", attribs: %s", SvPV(attribs,PL_na) );
	}
	PerlIO_printf( DBILOGFP, ")\n" );
    }

    svp = hv_fetch( imp_sth->bind_names, name, (I32)name_len, 0 );
    if( svp == NULL ) {
	croak( "Can't bind unknown placeholder '%s' (%s)", name, neatsvpv(ph_namesv,0) );
    }

    if( is_inout && SvREADONLY( newvalue ) ) {
	croak( "%s", PL_no_modify );
    }

    phs = (phs_t *)((void*)SvPVX(*svp));		/* placeholder struct	*/
    if( phs->ordinal == 0 ) {
	croak( "bind_param internal error: unknown ordinal for '%s'\n", name );
    }

    if( phs->sv != &PL_sv_undef ) {	 /* first bind for this placeholder	*/
	SvREFCNT_dec( phs->sv );
    }
    
    phs->sv = SvREFCNT_inc( newvalue );

    phs->is_inout = is_inout;
    phs->maxlen = maxlen;
    phs->sql_type = (int)sql_type;

    if( DBIS->debug >= 2 ) {
	PerlIO_printf( DBILOGFP, "Binding input hostvar '%s' to ordinal %d\n",
		       name, phs->ordinal );
    }

    return( 1 );
}

static int
assign_from_result_set( pTHX_ SV *sth, imp_sth_t *imp_sth, SV *sv, int index )
/****************************************************************************/
{
    D_imp_dbh_from_sth;
    a_sqlany_data_info		dinfo;
    SACAPI			*sacapi = imp_dbh->sacapi;

    if( !sacapi->api.sqlany_get_data_info( imp_sth->statement, index, &dinfo ) ) {
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "get_data_info failed" );
	return( FALSE );
    }

    if( dinfo.is_null ) {
	SvOK_off( sv );
    } else if( dinfo.type == A_STRING || dinfo.type == A_BINARY ) {
	IV	len = dinfo.data_size;
	IV	longreadlen = DBIc_LongReadLen( imp_dbh );
	char	*dest;
	
	if( len > longreadlen ) {
	    if( !DBIc_has( imp_sth, DBIcf_LongTruncOk ) ) {
		ssa_error( aTHX_ sth, NULL, SQLE_TRUNCATED, "long value truncated" );
		return( FALSE );
	    }
	    len = DBIc_LongReadLen( imp_dbh );
	}
	SvUPGRADE( sv, SVt_PV );
	dest = SvGROW( sv, (STRLEN)len+1 );
	if( len != 0 && sacapi->api.sqlany_get_data( imp_sth->statement, index, 0, dest, len ) < 0 ) {
	    ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "get_data failed" );
	    return( FALSE );
	}
	SvCUR_set( sv, len );
	*SvEND( sv ) = '\0';
	SvPOK_only( sv );
    } else {
	a_sqlany_data_value		val;
	char				numbuf[40];
	if( !sacapi->api.sqlany_get_column( imp_sth->statement, index, &val ) ) {
	    SvOK_off( sv );	// shouldn't get here
	    ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "get_column failed" );
	    return( FALSE );
	}
	switch(	dinfo.type ) {
	    case A_VAL8			:
		sv_setiv( sv, (IV)*(signed char *)val.buffer );
		break;

	    case A_VAL16		:
		sv_setiv( sv, (IV)*(short *)val.buffer );
		break;

	    case A_VAL32		:
		sv_setiv( sv, (IV)*(int *)val.buffer );
		break;

	    case A_UVAL8		:
		sv_setuv( sv, (UV)*(unsigned char *)val.buffer );
		break;

	    case A_UVAL16		:
		sv_setuv( sv, (UV)*(unsigned short *)val.buffer );
		break;

	    case A_UVAL32		:
		sv_setuv( sv, (UV)*(unsigned *)val.buffer );
		break;

	    case A_VAL64		:
#if defined( _MSC_VER )
		sprintf( numbuf, "%I64d", *(__int64 *)val.buffer );
#else
		sprintf( numbuf, "%lld", *(long long *)val.buffer );
#endif
		sv_setpv( sv, numbuf );
		break;

	    case A_UVAL64		:
#if defined( _MSC_VER )
		sprintf( numbuf, "%I64u", *(unsigned __int64 *)val.buffer );
#else
		sprintf( numbuf, "%llu", *(unsigned long long *)val.buffer );
#endif
		sv_setpv( sv, numbuf );
		break;

	    case A_DOUBLE		:
		sv_setnv( sv, *(double *)val.buffer );
		break;

	    default			:
		ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "internal error: unhandled SA data type" );
		SvOK_off( sv );
		return( FALSE );
	}
    }

    if( DBIS->debug >= 3 ) {
	PerlIO_printf( DBILOGFP, "        %d: '%s'\n",
		       index, SvOK(sv) ? SvPV(sv,PL_na) : "NULL" );
    }
    return( TRUE );
}

static int
really_bind( pTHX_ SV *sth, imp_sth_t *imp_sth )
/**********************************************/
{
    D_imp_dbh_from_sth;
    HE		*he;
    HV		*hv;
    SV		*sv;
    phs_t	*phs;
    SACAPI	*sacapi = imp_dbh->sacapi;

    hv = imp_sth->bind_names;
    if( hv == NULL ) {
	return( TRUE );
    }
    hv_iterinit( hv );
    while( (he=hv_iternext( hv )) != NULL ) {
	sv = hv_iterval( hv, he );
	phs = (phs_t *)((void *)SvPVX(sv));		/* placeholder struct	*/
	if( phs->ordinal != 0 && phs->ordinal <= imp_sth->num_bind_params ) {
	    a_sqlany_bind_param		desc;
	    a_sqlany_data_type		bind_type;
	    if( !sacapi->api.sqlany_describe_bind_param( imp_sth->statement, phs->ordinal-1, &desc ) ) {
		ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "failed to get description for bind param" );
		return( FALSE );
	    }
	    if( phs->sql_type == SQL_BINARY 	||
		phs->sql_type == SQL_VARBINARY 	||
		phs->sql_type == SQL_LONGVARBINARY ) {
		bind_type = A_BINARY;
	    } else {
		bind_type = A_STRING;
	    }

	    if( phs->is_inout && (desc.direction&DD_OUTPUT) ) {
		a_sqlany_bind_param	bp = desc;
		SV	*lcl_undef = &PL_sv_undef;
		char	*lcl_p = NULL;
		bp.direction = DD_OUTPUT;
		bp.value.type = bind_type;
		bp.value.length = &phs->out_param_length;
		bp.value.is_null = &phs->out_param_is_null;
		phs->out_param_length = 0;
		phs->out_param_is_null = TRUE;
		// ensure room for result, 28 is magic number (see sv_2pv)
		// We ignore the size given by the server and use the max_size provided by the user
		bp.value.buffer_size = _min( bp.value.buffer_size, (size_t)phs->maxlen );
		bp.value.buffer_size = _max( 28, bp.value.buffer_size );
		SvUPGRADE( phs->sv, SVt_PV );	// Also does a backoff so that SvPVX returns beginning of buffer
		bp.value.buffer = SvGROW( phs->sv, bp.value.buffer_size+1 );

		if( !sacapi->api.sqlany_bind_param( imp_sth->statement, phs->ordinal-1, &bp ) ) {
		    ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "bind for output parameter failed" );
		    return( FALSE );
		}
	    }

	    if( desc.direction&DD_INPUT ) {
		a_sqlany_bind_param	bp = desc;
		bp.direction = DD_INPUT;
		bp.value.type = bind_type;
		bp.value.length = &phs->in_param_length;
		bp.value.is_null = &phs->in_param_is_null;
		if( !SvOK( phs->sv ) ) {
		    bp.value.buffer = NULL;
		    phs->in_param_length = 0;
		    phs->in_param_is_null = TRUE;
		} else {
		    bp.value.buffer = SvPV( phs->sv, PL_na );
		    phs->in_param_length = bp.value.buffer_size = SvCUR( phs->sv );
		    phs->in_param_is_null = FALSE;
		}
		if( !sacapi->api.sqlany_bind_param( imp_sth->statement, phs->ordinal-1, &bp ) ) {
		    ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "bind for input parameter failed" );
		    return( FALSE );
		}
	    }
	}
    }
    return( TRUE );
}

static int
assign_output_parameters( pTHX_ SV *sth, imp_sth_t *imp_sth )
/***********************************************************/
{
    D_imp_dbh_from_sth;
    HE		*he;
    HV		*hv;
    SV		*sv;
    phs_t	*phs;
    SACAPI	*sacapi = imp_dbh->sacapi;

    hv = imp_sth->bind_names;
    if( hv == NULL ) {
	return( TRUE );
    }
    hv_iterinit( hv );
    while( (he=hv_iternext( hv )) != NULL ) {
	sv = hv_iterval( hv, he );
	phs = (phs_t *)((void *)SvPVX(sv));		/* placeholder struct	*/
	if( phs->ordinal != 0 && phs->ordinal <= imp_sth->num_bind_params ) {
	    a_sqlany_bind_param		desc;
	    if( !sacapi->api.sqlany_describe_bind_param( imp_sth->statement, phs->ordinal-1, &desc ) ) {
		ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "failed to get description for bind param" );
		return( FALSE );
	    }
	    if( phs->is_inout && (desc.direction&DD_OUTPUT) ) {
		a_sqlany_bind_param_info	bp;
		if( !sacapi->api.sqlany_get_bind_param_info( imp_sth->statement, phs->ordinal-1, &bp ) ) {
		    ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "failed to get bind param info" );
		    return( FALSE );
		}
		if( phs->out_param_is_null ) {
		    SvOK_off( phs->sv );	// undef
		} else {
		    STRLEN	len = (STRLEN)phs->out_param_length;
		    if( (SvLEN( phs->sv ) < len+1) || (SvPVX( phs->sv ) != bp.output_value.buffer) ) {
			// This shouldn't happen -- we already grew the dest fit the data
			croak( "internal error: output buffer for bind parameter %d changed", phs->ordinal );
		    }
		    SvCUR_set( phs->sv, len );
		    *SvEND( phs->sv ) = '\0';
		    SvPOK_only( phs->sv );
		}
	    }
	}
    }
    return( TRUE );
}

int
dbd_st_execute( SV *sth, imp_sth_t *imp_sth )
/*******************************************/
// return value <= -2:error, >=0:ok row count, (-1=unknown count) */
{
    dTHR;
    dTHX;
    D_imp_dbh_from_sth;
    int			do_commit = FALSE;
    int			sqlcode;
    int			num_cols;
    SACAPI		*sacapi = imp_dbh->sacapi;

    // If a cursor is still open, it must be closed before we open another
    // one on the same handle.
    dbd_st_finish( sth, imp_sth );
    
    if( !really_bind( aTHX_ sth, imp_sth ) ) {
	return( -2 );
    }

    sacapi->api.sqlany_execute( imp_sth->statement );
    sqlcode = sacapi->api.sqlany_error( imp_dbh->conn, NULL, 0 );
    num_cols = sacapi->api.sqlany_num_cols( imp_sth->statement );

    // A failure to execute or there is no cursor open
    if( sqlcode == SQLE_NOTFOUND ) {
	// num_cols == 0 implies it was execute-only (and no cursor)
	if( num_cols == 0 && !assign_output_parameters( aTHX_ sth, imp_sth ) ) {
	    return( -2 );
	}
	sv_setpv( DBIc_ERR(imp_sth), "" );
	return( 0 );	// No rows affected
    }

    // This error case for SQLE_TRUNCATED as well because there is no
    // way to call GET DATA without a cursor.
    if( sqlcode < 0 ) {
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "execute failed" );
	if( DBIS->debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "    dbd_st_execute failed, rc=%d", sqlcode );
	}
	return( -2 );
    }


    if( sqlcode > 0 ) {
	// Just a warning
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "warning during execute" );
	if( DBIS->debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "    dbd_st_execute warning, rc=%d", sqlcode );
	}
    }

    if( num_cols == 0 ) {
	// executed already & no cursor
	if( !assign_output_parameters( aTHX_ sth, imp_sth ) ) {
	    return( -2 );
	}
	imp_sth->row_count = sacapi->api.sqlany_affected_rows( imp_sth->statement );
	if( DBIc_has(imp_dbh,DBIcf_AutoCommit) ) {
	    sacapi->api.sqlany_commit( imp_dbh->conn );
	}
    } else {
	// A cursor is open
	if( DBIS->debug >= 2 ) {
	    PerlIO_printf( DBILOGFP, "Cursor opened\n" );
	}
	imp_sth->row_count = sacapi->api.sqlany_num_rows( imp_sth->statement );
    }

    DBIc_NUM_FIELDS(imp_sth) = num_cols;
    DBIc_ACTIVE_on(imp_sth);

    // Negative row-counts are estimates but dbperl wants a positive
    return( imp_sth->row_count < 0 ? -imp_sth->row_count : imp_sth->row_count );
}

AV *
dbd_st_fetch( SV *sth, imp_sth_t *imp_sth )
/*****************************************/
{
    dTHX;
    D_imp_dbh_from_sth;
    int 			debug = DBIS->debug;
    int 			num_fields;
    int 			i;
    AV 				*av;
    int				sqlcode;
    SACAPI			*sacapi = imp_dbh->sacapi;

    /* Check that execute() was executed sucessfuly. */
    if( !DBIc_ACTIVE(imp_sth) ) {
	ssa_error( aTHX_ sth, NULL, SQLE_CURSOR_NOT_OPEN, "no statement executing" );
	return( Nullav );
    }

    if( imp_sth->statement == NULL || DBIc_NUM_FIELDS(imp_sth) == 0 ) {
	return( Nullav );	// we figured it was just an EXECUTE
    }

    // printf( "Fetch (%p)\n", imp_sth ); fflush( stdout );
    sacapi->api.sqlany_fetch_next( imp_sth->statement );
    sqlcode = sacapi->api.sqlany_error( imp_dbh->conn, NULL, 0 );
    if( sqlcode == SQLE_NOTFOUND ) {
	sv_setpv( DBIc_ERR(imp_sth), "" );	/* just end-of-fetch	*/
	return( Nullav );
    } else if( sqlcode < 0 ) {
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "fetch failed" );
	if( debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "    dbd_st_fetch failed, rc=%d", sqlcode );
	}
	return( Nullav );
    }


    if( sqlcode > 0 ) {
	// Just a warning
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "warning during fetch" );
	if( DBIS->debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "    dbd_st_fetch warning, rc=%d", sqlcode );
	}
    }

    av = DBIS->get_fbav( imp_sth );
    num_fields = DBIc_NUM_FIELDS( imp_sth );
    av_fill( av, num_fields - 1 );	// -1 is Okay here

    if( debug >= 3 ) {
	PerlIO_printf( DBILOGFP, "    dbd_st_fetch %d fields\n", num_fields );
    }

    for( i=0; i < num_fields; ++i ) {
	SV 		*sv = AvARRAY(av)[i]; /* Note: we (re)use the SV in the AV	*/

	if( !assign_from_result_set( aTHX_ sth, imp_sth, sv, i ) ) {
	    return( Nullav );
	}
    }
    return( av );
}

int
dbd_st_more_results( SV *sth, imp_sth_t *imp_sth )
/************************************************/
{
    dTHX;
    D_imp_dbh_from_sth;
    int 			debug = DBIS->debug;
    int				rescode;
    int				sqlcode;
    SACAPI			*sacapi = imp_dbh->sacapi;

    /* Check that execute() was executed sucessfuly. */
    if( !DBIc_ACTIVE(imp_sth) ) {
	ssa_error( aTHX_ sth, NULL, SQLE_CURSOR_NOT_OPEN, "no statement executing" );
	return( 0 );
    }

    if( imp_sth->statement == NULL ) {
	return( 0 );	// we figured it was just an EXECUTE
    }

    DBIc_NUM_FIELDS(imp_sth) =  0;
    hv_delete((HV*)SvRV(sth), "NAME", 4, G_DISCARD);
    hv_delete((HV*)SvRV(sth), "NULLABLE", 8, G_DISCARD);
    hv_delete((HV*)SvRV(sth), "NUM_OF_FIELDS", 13, G_DISCARD);
    hv_delete((HV*)SvRV(sth), "PRECISION", 9, G_DISCARD);
    hv_delete((HV*)SvRV(sth), "SCALE", 5, G_DISCARD);
    hv_delete((HV*)SvRV(sth), "TYPE", 4, G_DISCARD);
    
    // printf( "More_results (%p)\n", imp_sth ); fflush( stdout );
    rescode = sacapi->api.sqlany_get_next_result( imp_sth->statement );
    sqlcode = sacapi->api.sqlany_error( imp_dbh->conn, NULL, 0 );

    // rescode == 0 means no more results
    if( rescode == 0 ) {
	if( sqlcode == SQLE_NOTFOUND || sqlcode == SQLE_PROCEDURE_COMPLETE ) {
	    sv_setpv( DBIc_ERR(imp_sth), "" );	/* just end-of-results	*/
	    return( -1 );
	} else {
	    ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "more_results failed" );
	    if( debug >= 3 ) {
		PerlIO_printf( DBILOGFP, "    dbd_st_more_results failed, rc=%d", sqlcode );
	    }
	    return( 0 );
	}
    }

    DBIc_NUM_FIELDS(imp_sth) = sacapi->api.sqlany_num_cols( imp_sth->statement );
      DBIS->set_attr_k(sth, sv_2mortal(newSVpvn("NUM_OF_FIELDS",13)), 0,
          sv_2mortal(newSViv(sacapi->api.sqlany_num_cols( imp_sth->statement ))));

    if( sqlcode > 0 ) {
	// Just a warning
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "warning during more_results" );
	if( DBIS->debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "    dbd_st_more_results warning, rc=%d", sqlcode );
	}
    }

    return( 1 );
}

int
dbd_st_blob_read( SV *sth, imp_sth_t *imp_sth,
		  int field, long offset, long len, SV *destrv, long destoffset )
/*******************************************************************************/
{
    dTHX;
    D_imp_dbh_from_sth;
    SV			*bufsv;
    a_sqlany_data_info	dinfo;
    char		*dest;
    int			retlen;
    SACAPI		*sacapi = imp_dbh->sacapi;

    /* Check that execute() was executed sucessfuly. This also implies	*/
    /* that dbd_describe() executed sucessfuly so the memory buffers	*/
    /* are allocated and bound.						*/
    if( !DBIc_ACTIVE(imp_sth) ) {
	if( DBIS->debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "blob_read on inactive handle\n" );
	}
	ssa_error( aTHX_ sth, NULL, SQLE_CURSOR_NOT_OPEN, "no statement executing" );
	return( 0 );
    }

    if( imp_sth->statement == NULL ) {
	if( DBIS->debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "blob_read on non-cursor statement\n" );
	}
	return( 0 );	// we figured it was just an EXECUTE
    }

    if( field >= sacapi->api.sqlany_num_cols( imp_sth->statement ) ) {
	if( DBIS->debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "blob_read: field number too large\n" );
	}
	return( 0 );
    }

    if( !sacapi->api.sqlany_get_data_info( imp_sth->statement, field, &dinfo ) ) {
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "get_data_info failed" );
	return( 0 );
    }

    if( dinfo.type != A_STRING && dinfo.type != A_BINARY ) {
	if( DBIS->debug >= 3 ) {
	    PerlIO_printf( DBILOGFP, "blob_read: field is neither string nor binary\n" );
	}
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "blob_read: field is neither string nor binary\n" ); 
	return( 0 );
    }

    if( dinfo.is_null ) {
	return( 0 );
    }

    bufsv = SvRV( destrv );
    sv_setpvn( bufsv, "", 0 );	/* ensure it's writable string	*/

    dest = SvGROW( bufsv, (STRLEN)destoffset+len+1 ); /* SvGROW doesn't do +1	*/
    dest += destoffset;
    
    retlen = sacapi->api.sqlany_get_data( imp_sth->statement, field, offset, dest, len );
    if( retlen < 0 ) {
	ssa_error( aTHX_ sth, imp_dbh->conn, SQLE_ERROR, "get_data failed" );
	return( 0 );
    }

    if( DBIS->debug >= 3 ) {
	PerlIO_printf( DBILOGFP,
		       "    blob_read field %d, type %d, offset %ld (ignored), len %ld, destoffset %ld, retlen %ld\n",
		       field, dinfo.type, offset, len, destoffset, (long)retlen );
    }

    SvCUR_set( bufsv, destoffset + retlen );

    *SvEND(bufsv) = '\0'; /* consistent with perl sv_setpvn etc	*/

    if( retlen == 0 ) {
	return( 0 );
    }
    return( 1 );
}

int
dbd_st_rows( SV *sth, imp_sth_t *imp_sth )
/****************************************/
{
    return( imp_sth->row_count );
}

int
dbd_st_finish( SV *sth, imp_sth_t *imp_sth )
/******************************************/
{
    dTHR;
    dTHX;
    D_imp_dbh_from_sth;
    SACAPI		*sacapi = imp_dbh->sacapi;

    if( DBIc_ACTIVE(imp_dbh) ) {
//printf( "Closing %p\n", imp_sth ); fflush( stdout );
	if( imp_sth->statement && sacapi->api.sqlany_num_cols( imp_sth->statement ) > 0 ) {
	    // Cursor is open
	    sacapi->api.sqlany_reset( imp_sth->statement );
	    if( DBIc_has(imp_dbh,DBIcf_AutoCommit) ) {
		sacapi->api.sqlany_commit( imp_dbh->conn );
	    }
	}
    } 
    DBIc_ACTIVE_off(imp_sth);
    return( 1 );
}

void
release_bind_params( pTHX_ SV *sth, imp_sth_t *imp_sth )
/******************************************************/
{
    D_imp_dbh_from_sth;
    HE		*he;
    HV		*hv;
    SV		*sv;
    phs_t	*phs;

    hv = imp_sth->bind_names;
    if( hv == NULL ) {
	return;
    }
    hv_iterinit( hv );
    while( (he=hv_iternext( hv )) != NULL ) {
	sv = hv_iterval( hv, he );
	phs = (phs_t *)((void *)SvPVX(sv));		/* placeholder struct	*/
	if( phs->sv != &PL_sv_undef ) {
	    SvREFCNT_dec( phs->sv );
	}
    }
    sv_free( (SV *)hv );
    imp_sth->bind_names = NULL;
}

void
dbd_st_destroy( SV *sth, imp_sth_t *imp_sth )
/*******************************************/
{
    D_imp_dbh_from_sth;
    SACAPI		*sacapi = imp_dbh->sacapi;

    dbd_st_finish( sth, imp_sth );

    if( DBIc_ACTIVE(imp_dbh) ) {
	if( imp_sth->statement ) {
	    dTHX;
	    sacapi->api.sqlany_free_stmt( imp_sth->statement );
	    imp_sth->statement = NULL;
	    
	    release_bind_params( aTHX_ sth, imp_sth );
	    Safefree( imp_sth->sql_statement );
	    imp_sth->sql_statement = NULL;
	}
    }

    DBIc_IMPSET_off(imp_sth);		/* let DBI know we've done it	*/
}


int
dbd_st_STORE_attrib( SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv )
/************************************************************************/
{
    // FIXME: NYI
    return( FALSE );
}

#ifndef SQL_DATETIME
    #define SQL_DATETIME 9
#endif

static int
native_to_odbc_type( short int sqltype )
/**************************************/
{
    int		odbc_type;

    switch( sqltype ) {
	case DT_BIT		: odbc_type = SQL_BIT; break;
	case DT_TINYINT		: odbc_type = SQL_TINYINT; break;

	case DT_UNSSMALLINT	:
	case DT_SMALLINT	: odbc_type = SQL_SMALLINT; break;

	case DT_UNSINT		:
	case DT_INT		: odbc_type = SQL_INTEGER; break;

	case DT_UNSBIGINT	:
	case DT_BIGINT		: odbc_type = SQL_BIGINT; break;

	case DT_DATE		: odbc_type = SQL_DATE; break;
	case DT_TIME		: odbc_type = SQL_TIME; break;

	case DT_TIMESTAMP	: odbc_type = SQL_TIMESTAMP; break;

	case DT_DECIMAL		: odbc_type = SQL_DECIMAL; break;
	case DT_FLOAT		: odbc_type = SQL_FLOAT; break;
	case DT_DOUBLE		: odbc_type = SQL_DOUBLE; break;

	case DT_STRING		:
	case DT_FIXCHAR		: odbc_type = SQL_CHAR; break;

	case DT_VARCHAR		: odbc_type = SQL_VARCHAR; break;
	case DT_LONGVARCHAR	: odbc_type = SQL_LONGVARCHAR; break;
	case DT_BINARY		: odbc_type = SQL_VARBINARY; break;
	case DT_LONGBINARY	: odbc_type = SQL_LONGVARBINARY; break;

	default:
	    odbc_type = SQL_ALL_TYPES;	// whatever
	    break;
    }
    return( odbc_type );
}

SV *
dbd_st_FETCH_attrib( SV *sth, imp_sth_t *imp_sth, SV *keysv )
/***********************************************************/
{
    dTHX;
    D_imp_dbh_from_sth;
    STRLEN 			kl;
    char 			*key = SvPV(keysv,kl);
    int 			i;
    SV 				*retsv = NULL;
    a_sqlany_column_info	cinfo;
    SACAPI			*sacapi = imp_dbh->sacapi;

    /* Default to caching results for DBI dispatch quick_FETCH	*/
    int cacheit = TRUE;

    if( kl==13 && strEQ(key, "NUM_OF_PARAMS") ) {	/* handled by DBI */
	return( Nullsv );	
    }

    i = DBIc_NUM_FIELDS(imp_sth);

    if( kl == 4 && strEQ( key, "NAME" ) ) {
	AV *av = newAV();
	retsv = newRV( sv_2mortal( (SV*)av ) );
	// FIXME: what if no result set? (ie. stmt not executed yet)
	while( --i >= 0 ) {
	    sacapi->api.sqlany_get_column_info( imp_sth->statement, i, &cinfo );
	    av_store( av, i, newSVpv( cinfo.name, 0 ) );
	}
    } else if( kl == 7 && strEQ( key, "ASATYPE" ) ) {
	// Translating types to ODBC type can be lossy
	AV *av = newAV();
	retsv = newRV( sv_2mortal( (SV*)av ) );
	while( --i >= 0 ) {
	    sacapi->api.sqlany_get_column_info( imp_sth->statement, i, &cinfo );
	    av_store( av, i, newSViv( cinfo.native_type ) );
	}
    } else if( kl == 4 && strEQ( key, "TYPE" ) ) {
	AV *av = newAV();
	retsv = newRV( sv_2mortal( (SV*)av ) );
	while( --i >= 0 ) {
	    sacapi->api.sqlany_get_column_info( imp_sth->statement, i, &cinfo );
	    av_store( av, i, newSViv( native_to_odbc_type( cinfo.native_type ) ) );
	}
    } else if( kl == 5 && strEQ( key, "SCALE" ) ) {
	AV *av = newAV();
	retsv = newRV( sv_2mortal( (SV*)av ) );
	while( --i >= 0 ) {
	    sacapi->api.sqlany_get_column_info( imp_sth->statement, i, &cinfo );
	    switch( cinfo.native_type ) {
		case DT_DECIMAL	:
		    av_store( av, i, newSViv( cinfo.scale ) );
		    break;
		default:
		    // Avoid compiler warnings
		    break;
	    }
	}
    } else if( kl == 9 && strEQ( key, "PRECISION" ) ) {
	AV *av = newAV();
	retsv = newRV( sv_2mortal( (SV*)av ) );
	while( --i >= 0 ) {
	    sacapi->api.sqlany_get_column_info( imp_sth->statement, i, &cinfo );
	    switch( cinfo.native_type ) {
		case DT_DECIMAL	:
		    av_store( av, i, newSViv( cinfo.precision ) );
		    break;
		case DT_FLOAT	:
		    av_store( av, i, newSViv(10) );
		    break;
		case DT_DOUBLE	:
		    av_store( av, i, newSViv(15) );
		    break;
		// For the integer types, I assume I am supposed to return the max field width (which
		// is also the number of significant digits) in base 10, disregarding negative signs
		// (as documented for numerics)
		case DT_BIT		:
		    av_store( av, i, newSViv(1) );
		    break;
		case DT_TINYINT		:
		    av_store( av, i, newSViv(3) );
		    break;
		case DT_SMALLINT	:
		case DT_UNSSMALLINT	:
		    av_store( av, i, newSViv(5) );
		    break;
		case DT_UNSINT		:
		case DT_INT		:
		    av_store( av, i, newSViv(10) );
		    break;
		case DT_BIGINT		:
		case DT_UNSBIGINT	:
		    av_store( av, i, newSViv(20) );
		    break;
		case DT_VARCHAR		:
		case DT_BINARY		:
		case DT_FIXCHAR		:
		case DT_STRING		:
		case DT_LONGVARCHAR	:
		case DT_LONGBINARY	:
		default			:
		    av_store( av, i, newSViv( cinfo.max_size ) );
		    break;
	    }
	}
    } else if( kl == 8 && strEQ( key, "NULLABLE" ) ) {
	AV *av = newAV();
	retsv = newRV( sv_2mortal( (SV*)av ) );
	while( --i >= 0 ) {
	    sacapi->api.sqlany_get_column_info( imp_sth->statement, i, &cinfo );
	    av_store( av, i, boolSV( cinfo.nullable ) );
	}
    } else if( kl == 10 && strEQ( key, "CursorName" ) ) {
	retsv = &PL_sv_undef;
    } else if( kl == 9 && strEQ( key, "Statement" ) ) {
	retsv = newSVpv( (char *)imp_sth->sql_statement, 0 );
    } else if( kl == 11 && strEQ( key, "RowsInCache" ) ) {
	retsv = &PL_sv_undef;
    } else {
	return( Nullsv );
    }
    if( cacheit ) { /* cache for next time (via DBI quick_FETCH)	*/
	SV **svp = hv_fetch( (HV*)SvRV(sth), key, (I32)kl, 1 );
	sv_free( *svp );
	*svp = retsv;
	(void)SvREFCNT_inc( retsv );	/* so sv_2mortal won't free it	*/
    }
    return( sv_2mortal( retsv ) );
}



/* --------------------------------------- */
