/* $Id: DBIXS.h,v 1.25 1995/08/26 17:23:16 timbo Rel $
 *
 * Copyright (c) 1994, 1995 Tim Bunce
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

/* DBI Interface Definitions for DBD Modules */

/* first pull in the standard Perl header files for extensions */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* Perl5.00[01] should include this if I_MEMORY set but doesn't */
#ifdef I_MEMORY
#include <memory.h>
#endif


/* The DBIXS_VERSION value will be incremented whenever new code is
 * added to the interface (this file) or significant changes are made.
 * It's primary goal is to allow newer drivers to compile against an
 * older installed DBI. This is mainly an issue whilst the API grows
 * and learns from the needs of various drivers.  See also the
 * DBISTATE_VERSION macro below. You can think of DBIXS_VERSION as
 * being a compile time check and DBISTATE_VERSION as a runtime check.
 */
#define DBIXS_VERSION 7

#ifdef NEED_DBIXS_VERSION
#if NEED_DBIXS_VERSION > DBIXS_VERSION
#error You need to upgrade your DBI module before building this driver.
#endif
#endif


/* forward declaration of 'DBI Handle Common Data', see below		*/

/* implementor needs to define actual struct { dbih_??c_t com; ... }*/
typedef struct imp_drh_st imp_drh_t;	/* driver			*/
typedef struct imp_dbh_st imp_dbh_t;	/* database			*/
typedef struct imp_sth_st imp_sth_t;	/* statement			*/
typedef struct imp_xxh_st imp_xxh_t;	/* any (defined below)		*/



/* --- DBI Handle Common Data Structure (all handles have one) ---	*/

/* Handle types. Code currently assumes child = parent + 1.		*/
#define DBIt_DR		1
#define DBIt_DB		2
#define DBIt_ST		3

/* component structures */

typedef struct dbih_com_std_st {
    U16  flags;
    U16  type;		/* DBIt_DR, DBIt_DB, DBIt_ST			*/
    SV   *my_h;		/* copy of owner inner handle (NO r.c.inc)	*/
    SV   *parent_h;	/* parent inner handle (RV(HV)) (r.c.inc)	*/
    imp_xxh_t *parent_com;	/* parent com struct shortcut		*/

    HV   *imp_stash;	/* who is the implementor for this handle	*/
    SV   *imp_data;	/* optional implementors data (for perl imp's)	*/

    I32  kids;		/* count of db's for dr's, st's for db's etc	*/
    char *last_method;	/* name of last method called, set by dispatch	*/
} dbih_com_std_t;

typedef struct dbih_com_attr_st {
    /* these are copies of the Hash values (r.c.inc)		*/
    /* many of the hash values are themselves references	*/
    SV *Debug;
    SV *Err;
    SV *Errstr;
    SV *Handlers;
} dbih_com_attr_t;


struct dbih_com_st {	/* complete core structure (typedef'd above)	*/
    dbih_com_std_t	std;
    dbih_com_attr_t	attr;
};

/* This 'implementors' type the DBI defines by default as a way to	*/
/* refer to the imp_??h data of a handle without considering its type.	*/
struct imp_xxh_st { struct dbih_com_st com; };

/* Define handle-type specific structures for implementors to include	*/
/* at the start of their private structures.				*/

typedef struct			/* -- DRIVER --				*/
    dbih_com_st			/* standard structure only		*/
dbih_drc_t;

typedef struct {		/* -- DATABASE --			*/
    dbih_com_std_t	std;	/* \__ standard structure		*/
    dbih_com_attr_t	attr;	/* /   plus ...	(nothing right now)	*/
} dbih_dbc_t;

typedef struct {		/* -- STATEMENT --			*/
    dbih_com_std_t	std;	/* \__ standard structure		*/
    dbih_com_attr_t	attr;	/* /   plus ...				*/

    int 	num_params;	/* number of placeholders		*/
    int 	num_fields;	/* NUM_OF_FIELDS, must be set		*/
    AV  	*fields_av;	/* special row buffer (inc bind_cols)	*/

} dbih_stc_t;


#define _imp2com(p,f)      	((p)->com.f)
#define _imp2std(p,f)      	((p)->com.std.f)
#define _imp2atr(p,f)      	((p)->com.attr.f)

#define DBIc_FLAGS(imp)		_imp2com(imp, std.flags)
#define DBIc_TYPE(imp)		_imp2com(imp, std.type)
#define DBIc_MY_H(imp)  	_imp2com(imp, std.my_h)
#define DBIc_PARENT_H(imp)  	_imp2com(imp, std.parent_h)
#define DBIc_PARENT_COM(imp)  	_imp2com(imp, std.parent_com)
#define DBIc_IMP_STASH(imp)  	_imp2com(imp, std.imp_stash)
#define DBIc_IMP_DATA(imp)  	_imp2com(imp, std.imp_data)
#define DBIc_KIDS(imp)  	_imp2com(imp, std.kids)
#define DBIc_LAST_METHOD(imp)  	_imp2com(imp, std.last_method)

#define DBIc_ATTR(imp, field)	_imp2atr(imp, field)

#define DBIc_DEBUGIV(imp)	SvIV(DBIc_ATTR(imp, Debug))
#define DBIc_ERR(imp)		SvRV(DBIc_ATTR(imp, Err))
#define DBIc_ERRSTR(imp)	SvRV(DBIc_ATTR(imp, Errstr))
#define DBIc_HANDLERS(imp)	SvRV(DBIc_ATTR(imp, Handlers))

/* sub-type specific fields						*/
#define DBIc_NUM_FIELDS(imp)  	_imp2com(imp, num_fields)
#define DBIc_FIELDS_AV(imp)  	_imp2com(imp, fields_av)
#define DBIc_NUM_PARAMS(imp)  	_imp2com(imp, num_params)

#define DBIcf_COMSET	0x0001	/* needs to be clear'd before free'd	*/
#define DBIcf_IMPSET	0x0002	/* has implementor data to be clear'd	*/
#define DBIcf_ACTIVE	0x0004	/* needs finish/disconnect before clear	*/
#define DBIcf_spare	0x0008	/*					*/
#define DBIcf_WARN  	0x0010	/* warn about poor practice etc		*/
#define DBIcf_COMPAT  	0x0020	/* compat/emulation mode (eg oraperl)	*/

#define DBIcf_INHERITMASK 	/* what flags to pass on to children	*/ \
	(DBIcf_WARN | DBIcf_COMPAT)

#define DBIc_COMSET(imp)	(DBIc_FLAGS(imp) &   DBIcf_COMSET)
#define DBIc_COMSET_on(imp)	(DBIc_FLAGS(imp) |=  DBIcf_COMSET)
#define DBIc_COMSET_off(imp)	(DBIc_FLAGS(imp) &= ~DBIcf_COMSET)

#define DBIc_IMPSET(imp)	(DBIc_FLAGS(imp) &   DBIcf_IMPSET)
#define DBIc_IMPSET_on(imp)	(DBIc_FLAGS(imp) |=  DBIcf_IMPSET)
#define DBIc_IMPSET_off(imp)	(DBIc_FLAGS(imp) &= ~DBIcf_IMPSET)

#define DBIc_ACTIVE(imp)	(DBIc_FLAGS(imp) &   DBIcf_ACTIVE)
#define DBIc_ACTIVE_on(imp)	(DBIc_FLAGS(imp) |=  DBIcf_ACTIVE)
#define DBIc_ACTIVE_off(imp)	(DBIc_FLAGS(imp) &= ~DBIcf_ACTIVE)

#define DBIc_WARN(imp)   	(DBIc_FLAGS(imp) &   DBIcf_WARN)
#define DBIc_WARN_on(imp)	(DBIc_FLAGS(imp) |=  DBIcf_WARN)
#define DBIc_WARN_off(imp)	(DBIc_FLAGS(imp) &= ~DBIcf_WARN)

#define DBIc_COMPAT(imp)   	(DBIc_FLAGS(imp) &   DBIcf_COMPAT)
#define DBIc_COMPAT_on(imp)	(DBIc_FLAGS(imp) |=  DBIcf_COMPAT)
#define DBIc_COMPAT_off(imp)	(DBIc_FLAGS(imp) &= ~DBIcf_COMPAT)


#ifdef IN_DBI_XS		/* get Handle Common Data Structure	*/
#define DBIh_COM(h)         	(dbih_getcom(h))
#else
#define DBIh_COM(h)         	(DBIS->getcom(h))
#endif


/* --- Implementors Private Data Support --- */

#define D_impdata(name,type,h)	type *name = (type*)(DBIh_COM(h))
#define D_imp_drh(h) D_impdata(imp_drh, imp_drh_t, h)
#define D_imp_dbh(h) D_impdata(imp_dbh, imp_dbh_t, h)
#define D_imp_sth(h) D_impdata(imp_sth, imp_sth_t, h)
#define D_imp_xxh(h) D_impdata(imp_xxh, imp_xxh_t, h)

#define D_imp_from_child(name,type,child)	\
				type *name = (type*)(DBIc_PARENT_COM(child))
#define D_imp_drh_from_dbh D_imp_from_child(imp_drh, imp_drh_t, imp_dbh)
#define D_imp_dbh_from_sth D_imp_from_child(imp_dbh, imp_dbh_t, imp_sth)

#define DBI_IMP_SIZE(n,s) sv_setiv(perl_get_sv((n), GV_ADDMULTI), (s)) /* XXX */


/* --- Event Support (VERY LIABLE TO CHANGE) --- */

#define DBIh_EVENTx(h,t,a1,a2)	(DBIS->event((h), (t), (a1), (a2)))
#define DBIh_EVENT0(h,t)	DBIh_EVENTx((h), (t), &sv_undef, &sv_undef)
#define DBIh_EVENT1(h,t, a1)	DBIh_EVENTx((h), (t), (a1),      &sv_undef)
#define DBIh_EVENT2(h,t, a1,a2)	DBIh_EVENTx((h), (t), (a1),      (a2))

#define ERROR_event	"ERROR"
#define WARN_event	"WARN"
#define MSG_event	"MESSAGE"
#define DBEVENT_event	"DBEVENT"
#define UNKNOWN_event	"UNKNOWN"


/* --- DBI State Structure --- */

typedef struct {
    /* version and size are used to check for DBI/DBD version mis-match	*/
    U16 version;	/* version of this structure			*/
    U16 size;
    U16 xs_version;	/* version of the overall DBIXS / DBD interface	*/

    int debug;
    int debugpvlen;	/* only show dbgpvlen chars when debugging pv's	*/
    FILE *logfp;

    /* pointers to DBI functions which the DBD's will want to use	*/
    imp_xxh_t  * (*getcom)   _((SV *h));	/* see DBIh_COM macro	*/
    void         (*clearcom) _((imp_xxh_t *imp_xxh));
    SV         * (*event)    _((SV *h, char *name, SV*, SV*));
    int          (*set_attr) _((SV *h, SV *keysv, SV *valuesv));
    SV         * (*get_attr) _((SV *h, SV *keysv));
    AV         * (*get_fbav) _((imp_sth_t *imp_sth));

    SV *pad1;
    SV *pad2;

} dbistate_t;
#define DBISTATE_VERSION  7	/* Must change whenever dbistate_t does	*/

#define DBIS              dbis /* default name for dbistate_t variable	*/
#define DBISTATE_DECLARE  static dbistate_t *DBIS
#define DBISTATE_PERLNAME "DBI::_dbistate"
#define DBISTATE_ADDRSV   (perl_get_sv(DBISTATE_PERLNAME, 0x05))

#define DBISTATE_INIT_DBIS (DBIS = (dbistate_t*)SvIV(DBISTATE_ADDRSV))

#define DBISTATE_INIT {		/* typically use in BOOT: of XS file	*/    \
    DBISTATE_INIT_DBIS;	\
    if (DBIS == NULL)	\
	croak("Unable to get DBI state. DBI not loaded."); \
    if (DBIS->version < DBISTATE_VERSION || DBIS->size < sizeof(*DBIS))	      \
	croak("DBI version mismatch (DBI actual v%d/s%d, expected v%d/s%d)",  \
	    DBIS->version, DBIS->size, DBISTATE_VERSION, (int)sizeof(*DBIS)); \
}

#define DBILOGFP	(DBIS->logfp)

/* --- Assorted Utility Macros	--- */

#define DBI_INTERNAL_ERROR(msg)	\
	croak("%s: file \"%s\", line %d", msg, __FILE__, __LINE__);

#define DBD_ATTRIBS_CHECK(func, h, attribs)	\
    if ((attribs) && SvOK(attribs)) {		\
	if (!SvROK(attribs) || SvTYPE(SvRV(attribs))!=SVt_PVHV)		\
	    croak("%s->%s(...): attribute parameter is not a hash ref",	\
		    SvPV(h,na), func);		\
    } else (attribs) = Nullsv

#define DBD_ATTRIB_GET_SVP(attribs, key, klen)	\
        hv_fetch((HV*)SvRV(attribs), key, klen, 0)
	
#define DBD_ATTRIB_GET_BOOL(attribs, key,klen, svp, var)		\
	if ( (svp=DBD_ATTRIB_GET_SVP(attribs, key,klen)) != NULL)	\
	    var = SvTRUE(*svp)

#define DBD_ATTRIB_GET_IV(attribs, key,klen, svp, var)			\
	if ( (svp=DBD_ATTRIB_GET_SVP(attribs, key,klen)) != NULL)	\
	    var = SvIV(*svp)


/* end of DBIXS.h */
