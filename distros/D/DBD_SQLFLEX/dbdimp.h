/*
 * @(#)$Id: dbdimp.h,v 58.1 1998/01/06 02:53:23 johnl Exp $ 
 *
 * Copyright (c) 1994-95 Tim Bunce
 *           (c) 1996-98 Jonathan Leffler
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#ifndef DBDIMP_H
#define DBDIMP_H

#include "dbdixmap.h"	/* Defines for functions called in Sqlflex.xs */
#include "esqlc.h"		/* Prototypes for ESQL/C version 5.0x etc */
#include "esqlperl.h"	/* Declarations for code used in esqltest.ec */

#ifndef DBD_SQLFLEX_NO_ASSERTS
#undef NDEBUG
/* #include <assert.h> */
#endif /* DBD_SQLFLEX_NO_ASSERTS */

#define NAMESIZE 19				/* 18 character name plus '\0' */
#define DEFAULT_DATABASE	".DEFAULT."

/* Different states for a statement */
enum State
{
	Unused, Prepared, Allocated, Described, Declared, Opened, Finished
};

typedef enum State State;		/* Cursor/Statement states */
typedef long ErrNum;			/* Sqlflex Error Number */
typedef char Name[NAMESIZE];

/* Doubly linked list for tracking connections and statements */
typedef struct Link Link;

struct Link
{
	Link	*next;
	Link	*prev;
	void	*data;
};

/* Define drh implementor data structure */
struct imp_drh_st
{
	dbih_drc_t      com;		/* MUST be first element in structure   */
	Boolean         multipleconnections;/* Supports multiple connections */
	int             n_connections;		/* Number of active connections */
	const char     *current_connection;	/* Name of current connection */
	Link            head;               /* Head of list of connections */
};

enum BlobLocn
{
        BLOB_DEFAULT, BLOB_IN_MEMORY, BLOB_IN_ANONFILE, BLOB_IN_NAMEFILE
};
typedef enum BlobLocn BlobLocn;

/* Define dbh implementor data structure */
struct imp_dbh_st
{
	dbih_dbc_t      com;            /* MUST be first element in structure */
	char           *database;       /* Name of database */
	Name            nm_connection;  /* Name of connection */
	Boolean         is_connected;   /* Is connection open */
	Boolean         is_onlinedb;    /* Is OnLine Engine */
	Boolean         is_modeansi;    /* Is MODE ANSI Database */
	Boolean         is_loggeddb;    /* Has transaction log */
	Boolean         is_txactive;    /* Is inside transaction */
	BlobLocn        blob_bind;      /* Blob binding */
	Sqlca           ix_sqlca;       /* Last SQLCA record for connection */
	Link            chain;          /* Link in list of connections */
	Link            head;           /* Head of list of statements */
};

/* Define sth implementor data structure */
struct imp_sth_st
{
	dbih_stc_t      com;		/* MUST be first element in structure   */
	Name            nm_stmnt;	/* Name of prepared statement */
	Name            nm_obind;	/* Name of allocated descriptor */
	Name            nm_cursor;	/* Name of declared cursor */
	Name            nm_ibind;	/* Name of input (bind) descriptor */
	State           st_state;	/* State of statement */
	int             st_type;	/* Type of statement */
	BlobLocn        blob_bind;	/* Blob Binding */
	int             n_blobs;	/* Number of blobs for statement */
	int             n_columns;	/* Number of output fields */
	int             n_bound;	/* Number of input fields */
	int             n_rows;		/* Number of rows processed */
	imp_dbh_t	   *dbh;		/* Database handle for statement */
	Link            chain;      /* Link in list of statements */
};

#define DBI_AutoCommit(dbh)	(DBIc_is(dbh, DBIcf_AutoCommit) ? True : False)

#ifndef DBD_IX_MODULE
#define DBD_IX_MODULE "DBD::Sqlflex"
#endif /* DBD_IX_MODULE */

/* Standard driver entry points */
extern int dbd_ix_dr_discon_all(SV *, imp_drh_t *);
extern void dbd_ix_dr_init(dbistate_t *);

/* Non-standard driver entry points */
extern SV *dbd_ix_dr_FETCH_attrib(imp_drh_t *drh, SV *keysv);
extern int dbd_ix_dr_driver(SV *drh);

/* Standard database entry points */
extern SV *dbd_ix_db_FETCH_attrib(SV *, imp_dbh_t *, SV *);
extern int dbd_ix_db_STORE_attrib(SV *, imp_dbh_t *, SV *, SV *);
extern int dbd_ix_db_commit(SV *, imp_dbh_t *);
extern int dbd_ix_db_disconnect(SV *, imp_dbh_t *imp_dbh);
extern int dbd_ix_db_login(SV *, imp_dbh_t *, char *, char *, char *);
extern int dbd_ix_db_rollback(SV *, imp_dbh_t *imp_dbh);
extern void dbd_ix_db_destroy(SV *, imp_dbh_t *imp_dbh);

/* Non-standard database entry points */
extern int dbd_ix_db_begin(imp_dbh_t *);
extern int dbd_ix_db_preset(imp_dbh_t *, SV *);

/* Standard statement entry points */
extern AV *dbd_ix_st_fetch(SV *, imp_sth_t *);
extern SV *dbd_ix_st_FETCH_attrib(SV *, imp_sth_t *, SV *);
extern int dbd_ix_st_STORE_attrib(SV *, imp_sth_t *, SV *, SV *);
extern int dbd_ix_st_bind_ph(SV *, imp_sth_t *, SV *, SV *, IV, SV *, int, IV);
extern int dbd_ix_st_blob_read(SV *, imp_sth_t *, int, long, long, SV *, long);
extern int dbd_ix_st_execute(SV *, imp_sth_t *);
extern int dbd_ix_st_finish(SV *, imp_sth_t *);
extern int dbd_ix_st_prepare(SV *, imp_sth_t *, char *, SV *);
extern int dbd_ix_st_rows(SV *, imp_sth_t *);
extern void dbd_ix_st_destroy(SV *, imp_sth_t *);

/* Other non-standard entry points */
extern const char *dbd_ix_module(void);
extern void dbd_ix_seterror(ErrNum rc);
extern void add_link(Link *link_1, Link *link_n);
extern void delete_link(Link *link_d, void (*function)(void *));
extern void destroy_chain(Link *head, void (*function)(void *));
extern void new_headlink(Link *link);

#endif	/* DBDIMP_H */
