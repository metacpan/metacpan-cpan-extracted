#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef RPC
#include "db_config.h"
#endif

#include <sys/types.h>
#include <sys/time.h>
#include <time.h>
#include <ctype.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#ifdef PREV41
#include "db_int.h"
#include "db_page.h"
#include "db_shash.h"
#include "lock.h"
#include "mp.h"
#include "clib_ext.h"
#endif

#ifdef V41
#include "dist/db_int.h"
#include "dbinc/db_page.h"
#include "dbinc/db_shash.h"
#include "dbinc/lock.h"
#include "dbinc/mp.h"
#include "dbinc_auto/clib_ext.h"
#endif

#ifdef V42
#include "db_int.h"
#include "dbinc/db_page.h"
#include "dbinc/db_shash.h"
#include "dbinc/lock.h"
#include "dbinc/mp.h"
#include "dbinc_auto/clib_ext.h"
#endif

typedef struct {
	int		Status ;
	/* char		ErrBuff[1000] ; */
	SV *		ErrPrefix ;
	FILE *		ErrHandle ;
	DB_ENV *	Env ;
	int		open_dbs ;
	int		TxnMgrStatus ;
	int		active ;
	bool		txn_enabled ;
	} BerkeleyDB_ENV_type ;

typedef BerkeleyDB_ENV_type *	BerkeleyDB__Env ;

/*
Lock status:
	DB_LSTAT_ABORTED=1,		// Lock belongs to an aborted txn. 
	DB_LSTAT_ERR=2,			// Lock is bad. 
	DB_LSTAT_EXPIRED=3,		// Lock has expired. 
	DB_LSTAT_FREE=4,		// Lock is unallocated. 
	DB_LSTAT_HELD=5,		// Lock is currently held. 
	DB_LSTAT_NOTEXIST=6,		// Object on which lock was waiting
					// was removed 
	DB_LSTAT_PENDING=7,		// Lock was waiting and has been
					// promoted; waiting for the owner
					// to run and upgrade it to held. 
	DB_LSTAT_WAITING=8		// Lock is on the wait queue. 
*/

struct __db_lock* db_lock ( DB_ENV *dbenv, ssize_t lockoffset ) {
	return (struct __db_lock *) R_ADDR( 
			&( (DB_LOCKTAB *) dbenv->lk_handle )->reginfo, 
			lockoffset ) ;
	}


DB_LOCK* db_lock_u ( DB_ENV *dbenv, ssize_t lockoffset, DB_LOCK* lock ) {
	u_int32_t ndx ;

	DB_LOCKTAB* lt ;
	DB_LOCKREGION* lrp ;
	DB_LOCKOBJ* lobj, * op ;

	struct __db_lock *lp ;

	lt = dbenv->lk_handle ;
	lp = (struct __db_lock *) R_ADDR( &lt->reginfo, lockoffset ) ;
	lobj = (struct __db_lockobj*) 
			( (u_int8_t *) ( (u_int8_t *) lp ) +lp->obj ) ;
	lrp = lt->reginfo.primary ;

	LOCKREGION( dbenv, lt);

	for ( ndx = 0 ; ndx < lrp->object_t_size ; ndx++ )
		if ( ( op = (DB_LOCKOBJ *) 
				SH_TAILQ_FIRST( &lt->obj_tab[ndx], __db_object )
				) && op == lobj ) {
			lock->off = lockoffset ;
			lock->ndx = ndx ;
			lock->gen = lp->gen ;
			lock->mode = lp->mode ;

			break ;
			}

	UNLOCKREGION( dbenv, lt);

	if ( ndx == lrp->object_t_size )
		return NULL ;

	return lock ;
	}
	

MODULE = BerkeleyDB::Locks		PACKAGE = BerkeleyDB::Locks		

AV* _waiters( SV *envAddr )
	CODE:
	u_int32_t i ;

	BerkeleyDB__Env dbenv = NULL ;

	DB_LOCKTAB* lt = NULL ;
	DB_LOCKREGION* lrp ;
	DB_LOCKER* lip ;

	DB_LOCKOBJ* lobj ;

	AV *av ;

	// struct __db_lock* lp, * wlp, * hlp ;
	struct __db_lock* lp, * wlp ;

	RETVAL = newAV() ;

	if ( SvIOK( envAddr ) ) {
		dbenv = (BerkeleyDB__Env) SvIV( envAddr ) ;
		lt = dbenv->Env->lk_handle;
		}
	else {
		croak( "Invalid BerkeleyDB::Env object" ) ;
		}

	/* Identify waiting locks and associated objects.
	 * Two values identify a lock:
		offset
		gen
	 */

	if ( lt != NULL ) {
		lrp = lt->reginfo.primary;
	
		LOCKREGION(dbenv->Env, lt);
	
		for (i = 0; i < lrp->locker_t_size; i++) {
			lip = SH_TAILQ_FIRST(&lt->locker_tab[i], __db_locker) ;

			if ( lip && lip->nlocks )
			for ( lp = SH_LIST_FIRST( &lip->heldby, __db_lock ) ;
		    			lp != NULL ;
		    			lp = SH_LIST_NEXT( lp,
					locker_links, __db_lock ) ) {

				if ( lp->status != DB_LSTAT_HELD )
					continue ;


				lobj = (struct __db_lockobj*) ( (u_int8_t *) 
						( (u_int8_t *) lp ) +lp->obj 
						) ;

				for ( wlp = SH_TAILQ_FIRST( 
						  &lobj->waiters, __db_lock ) ;
						wlp ;
						wlp = SH_TAILQ_NEXT( 
						  wlp, links, __db_lock )
						) {
	/*  Each waiter on a locked object represents a separate 
	 *  lock condition:
	 */
					av = newAV() ;
					// waiter
					av_push( av, newSViv( R_OFFSET( 
							&lt->reginfo, wlp ) 
							) ) ;
					av_push( av, newSViv( wlp->gen ) ) ;

					// holder
					av_push( av, newSViv( R_OFFSET( 
							&lt->reginfo, lp ) 
							) ) ;
					av_push( av, newSViv( lp->gen ) ) ;

					av_push( RETVAL, newRV_inc( (SV *) av )
							) ;
					}
				}
			}

		UNLOCKREGION(dbenv->Env, lt);
		}
	
	OUTPUT:
	RETVAL


HV* _properties( SV *envAddr, SV *lockOff )
	CODE:
	size_t off ;

	BerkeleyDB__Env dbenv = NULL ;
	DB_LOCK lock, * lockp ;
	struct __db_lock* lp ;

	RETVAL = newHV() ;

	if ( SvIOK( envAddr ) ) {
		dbenv = (BerkeleyDB__Env) SvIV( envAddr ) ;
		off = SvIV( lockOff ) ;
		}
	else {
		croak( "Invalid BerkeleyDB::Env object" ) ;
		}
	
	if ( db_lock_u( dbenv->Env, off, &lock ) != NULL
			&& ( lp = db_lock( dbenv->Env, off ) ) != NULL ) {
		hv_store( RETVAL, "holder", strlen("holder"), 
				newSViv( lp->holder ), 0 ) ;
		hv_store( RETVAL, "gen", strlen("gen"), 
				newSViv( lp->gen ), 0 ) ;
		hv_store( RETVAL, "mode", strlen("mode"), 
				newSViv( lp->mode ), 0 ) ;
		hv_store( RETVAL, "obj", strlen("obj"), 
				newSViv( lock.ndx ), 0 ) ;
		hv_store( RETVAL, "status", strlen("status"), 
				newSViv( lp->status ), 0 ) ;
		}

	OUTPUT:
	RETVAL


SV* _release( SV *envAddr, SV *lockOff )
	CODE:
	size_t off ;

	BerkeleyDB__Env dbenv = NULL ;
	DB_LOCK lock ;
	struct __db_lock* lp ;
	
	if ( SvIOK( envAddr ) ) {
		dbenv = (BerkeleyDB__Env) SvIV( envAddr ) ;
		off = SvIV( lockOff ) ;
		}
	else {
		croak( "Invalid BerkeleyDB::Env object" ) ;
		}

	if ( db_lock_u( dbenv->Env, off, &lock ) == NULL )
		RETVAL = newSViv( -1 ) ;
	else
		RETVAL = newSViv( dbenv->Env->lock_put( dbenv->Env, &lock ) ) ;

	OUTPUT:
	RETVAL
