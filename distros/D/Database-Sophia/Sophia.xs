//
//
//  Created by Alexander Borisov on 22.07.14.
//  Copyright (c) 2014 Alexander Borisov. All rights reserved.
//

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdarg.h>
#include <sophia.h>

typedef struct
{
	void *ptr;
	void *cmp;
	void *arg;
}
sophia_t;

typedef sophia_t * Database__Sophia;

static inline int sp_cmp(char *a_key, size_t asz, char *b_key, size_t bsz, void *arg)
{
	dSP;
	
	ENTER;
	SAVETMPS;
	
	sophia_t *ent = (sophia_t *)arg;
	
	PUSHMARK(sp);
		XPUSHs( sv_2mortal( newSVpv(a_key, asz) ) );
		XPUSHs( sv_2mortal( newSVpv(b_key, bsz) ) );
		if(ent->arg)
		{
			XPUSHs(ent->arg);
		}
	PUTBACK;
	
	long res = 0;
	int count = call_sv((SV *)ent->cmp, G_SCALAR);
	
	SPAGAIN;
    if (count > 0)
		res = POPi;
    PUTBACK;
	
	FREETMPS;
	LEAVE;

	return (int)res;
}

MODULE = Database::Sophia  PACKAGE = Database::Sophia

PROTOTYPES: DISABLE

Database::Sophia
sp_env(name = 0)
	char *name;
	
	CODE:
		sophia_t *env = malloc(sizeof(sophia_t));
		
		env->ptr = sp_env();
		env->cmp = NULL;
		env->arg = NULL;
		
		RETVAL = env;
	OUTPUT:
		RETVAL

Database::Sophia
sp_open(env)
	Database::Sophia env;
	
	CODE:
		sophia_t *db = malloc(sizeof(sophia_t));
		
		db->ptr = sp_open(env->ptr);
		db->cmp = NULL;
		db->arg = NULL;
		
		RETVAL = db;
	OUTPUT:
		RETVAL

SV*
sp_ctl(env, opt, ...)
	Database::Sophia env;
	int opt;
	
	CODE:
		void **	cmdargs;
		void *	currarg;
	    I32	stindex;
	    I32	argindex;
		I32 va_start = 2;
		I32 argc = 0, argc_o = 0;
		STRLEN len = 0;
		SV * sv;
		
		if(opt == SPGCF)
		{
			double factor = SvNV( ST(2) );
			
			RETVAL = newSViv( sp_ctl(env->ptr, opt, factor) );
		}
		else if(opt == SPGROW)
		{
			uint32_t new_size = SvIV( ST(2) );
			double resize = SvNV( ST(3) );
			
			RETVAL = newSViv( sp_ctl(env->ptr, opt, new_size, resize) );
		}
		else if(opt == SPCMP)
		{
			SV *sub = newSVsv((SV *)ST(2));
			
			if(env->cmp)
			{
				sv_2mortal((SV *)env->cmp);
			}
			
			env->arg = (void *)ST(3);
			env->cmp = (void *)sub;
			
			RETVAL = newSViv( sp_ctl(env->ptr, opt, sp_cmp, (void *)env));
		}
		else
		{
			argc = argc_o = items - va_start;
			
			if ( items > va_start )
			{
				New( 0, cmdargs, argc, void * );
				
				for ( stindex = va_start, argindex = 0; argc; argc--, stindex++, argindex++ )
				{
					if ( SvPOK( ST(stindex) ) )
					{
						cmdargs[argindex] = (void *)SvPV( ST(stindex), len );
					}
					else if ( SvIOK( ST(stindex) ) )
					{
						cmdargs[argindex] = (void *)SvIV( ST( stindex ) );
					}
				}
			}
			
			switch (argc_o)
			{
				case 1:
					RETVAL = newSViv( sp_ctl(env->ptr, opt, cmdargs[0]));
					break;
				case 2:
					RETVAL = newSViv( sp_ctl(env->ptr, opt, cmdargs[0], cmdargs[1]));
					break;
				case 3:
					RETVAL = newSViv( sp_ctl(env->ptr, opt, cmdargs[0], cmdargs[1], cmdargs[2]));
					break;
				case 4:
					RETVAL = newSViv( sp_ctl(env->ptr, opt, cmdargs[0], cmdargs[1],
											cmdargs[2], cmdargs[3]));
					break;
				case 5:
					RETVAL = newSViv( sp_ctl(env->ptr, opt, cmdargs[0], cmdargs[1],
											cmdargs[2], cmdargs[3], cmdargs[4]));
					break;
				// :-)
					break;
				default:
					break;
			}
			
			if ( cmdargs )Safefree( cmdargs );
		}
		
	OUTPUT:
		RETVAL

SV*
sp_set(db, key, value)
	Database::Sophia db;
	SV *key;
	SV* value;
	
	CODE:
		STRLEN len_k = 0, len_v = 0;
		
		char *key_c = SvPV( key, len_k );
		char *value_c = SvPV( value, len_v );
		
		RETVAL = newSViv( sp_set(db->ptr, (void *)key_c, len_k, (void *)value_c, len_v ) );
	OUTPUT:
		RETVAL

SV*
sp_begin(db)
	Database::Sophia db;
	
	CODE:
		RETVAL = newSViv( sp_begin(db->ptr) );
	OUTPUT:
		RETVAL

SV*
sp_commit(db)
	Database::Sophia db;
	
	CODE:
		RETVAL = newSViv( sp_commit(db->ptr) );
	OUTPUT:
		RETVAL

SV*
sp_rollback(db)
	Database::Sophia db;
	
	CODE:
		RETVAL = newSViv( sp_rollback(db->ptr) );
	OUTPUT:
		RETVAL

SV*
sp_delete(db, key)
	Database::Sophia db;
	SV *key;
	
	CODE:
		STRLEN len_k = 0;
		char *key_c = SvPV( key, len_k );
		
		RETVAL = newSViv( sp_delete(db->ptr, key_c, len_k) );
	OUTPUT:
		RETVAL

SV*
sp_get(db, key, error)
	Database::Sophia db;
	SV *key;
	SV *error;
	
	CODE:
		STRLEN len_k = 0;
		char *key_c = SvPV( key, len_k );
		void *value;
		size_t size;
		
		sv_setiv(error, sp_get(db->ptr, key_c, len_k, &value, &size) );
		
		RETVAL = newSVpv(value, size);
	OUTPUT:
		RETVAL

Database::Sophia
sp_cursor(db, order, key)
	Database::Sophia db;
	int order;
	SV *key;
	
	CODE:
		STRLEN len_k = 0;
		char *key_c = SvPV( key, len_k );
		
		sophia_t *cur = malloc(sizeof(sophia_t));
		
		cur->ptr = sp_cursor(db->ptr, order, key_c, len_k);
		cur->cmp = NULL;
		cur->arg = NULL;
		
		RETVAL = cur;
	OUTPUT:
		RETVAL

SV*
sp_fetch(cur)
	Database::Sophia cur;
	
	CODE:
		RETVAL = newSViv(sp_fetch(cur->ptr));
	OUTPUT:
		RETVAL

SV*
sp_key(cur)
	Database::Sophia cur;
	
	CODE:
		RETVAL = newSVpv(sp_key(cur->ptr), sp_keysize(cur->ptr));
	OUTPUT:
		RETVAL

SV*
sp_keysize(cur)
	Database::Sophia cur;
	
	CODE:
		RETVAL = newSViv(sp_keysize(cur->ptr));
	OUTPUT:
		RETVAL

SV*
sp_value(cur)
	Database::Sophia cur;
	
	CODE:
		RETVAL = newSVpv(sp_value(cur->ptr), sp_valuesize(cur->ptr));
	OUTPUT:
		RETVAL

SV*
sp_valuesize(cur)
	Database::Sophia cur;
	
	CODE:
		RETVAL = newSViv(sp_valuesize(cur->ptr));
	OUTPUT:
		RETVAL

SV*
sp_error(ptr)
	Database::Sophia ptr;
	
	CODE:
		RETVAL = newSVpv(sp_error(ptr->ptr), 0);
	OUTPUT:
		RETVAL

SV*
sp_stat(ptr)
	Database::Sophia ptr;
	
	CODE:
        SV **ha;
        HV *hash = newHV();
		
		spstat mstat;
		sp_stat(ptr->ptr, &mstat);
		
        ha = hv_store(hash, "epoch", 5, newSViv(mstat.epoch), 0);
        ha = hv_store(hash, "psn", 3, newSViv(mstat.psn), 0);
        ha = hv_store(hash, "repn", 4, newSViv(mstat.repn), 0);
        ha = hv_store(hash, "repndb", 6, newSViv(mstat.repndb), 0);
        ha = hv_store(hash, "repnxfer", 8, newSViv(mstat.repnxfer), 0);
        ha = hv_store(hash, "catn" , 4, newSViv(mstat.catn) , 0);
        ha = hv_store(hash, "indexn" , 6, newSViv(mstat.indexn) , 0);
		ha = hv_store(hash, "indexpages" , 10, newSViv(mstat.indexpages) , 0);
		
		RETVAL = newRV_noinc((SV*)hash);
	
	OUTPUT:
		RETVAL

SV*
sp_destroy(ptr)
	Database::Sophia ptr;
	
	CODE:
		RETVAL = newSViv( sp_destroy(ptr->ptr) );
		
		ptr->ptr = NULL;
		ptr->cmp = NULL;
		ptr->arg = NULL;
		
	OUTPUT:
		RETVAL

void
DESTROY(ptr)
	Database::Sophia ptr;
	
	CODE:
		if(ptr)
			free(ptr);
# spopt

SV*
SPDIR()
	CODE:
		RETVAL = newSViv( SPDIR );
	OUTPUT:
		RETVAL

SV*
SPALLOC()
	CODE:
		RETVAL = newSViv( SPALLOC );
	OUTPUT:
		RETVAL

SV*
SPCMP()
	CODE:
		RETVAL = newSViv( SPCMP );
	OUTPUT:
		RETVAL

SV*
SPPAGE()
	CODE:
		RETVAL = newSViv( SPPAGE );
	OUTPUT:
		RETVAL

SV*
SPGC()
	CODE:
		RETVAL = newSViv( SPGC );
	OUTPUT:
		RETVAL

SV*
SPGCF()
	CODE:
		RETVAL = newSViv( SPGCF );
	OUTPUT:
		RETVAL

SV*
SPGROW()
	CODE:
		RETVAL = newSViv( SPGROW );
	OUTPUT:
		RETVAL

SV*
SPMERGE()
	CODE:
		RETVAL = newSViv( SPMERGE );
	OUTPUT:
		RETVAL

SV*
SPMERGEWM()
	CODE:
		RETVAL = newSViv( SPMERGEWM );
	OUTPUT:
		RETVAL

SV*
SPMERGEFORCE()
	CODE:
		RETVAL = newSViv( SPMERGEFORCE );
	OUTPUT:
		RETVAL

SV*
SPVERSION()
	CODE:
		RETVAL = newSViv( SPVERSION );
	OUTPUT:
		RETVAL

# spflags
SV*
SPO_RDONLY()
	CODE:
		RETVAL = newSViv( SPO_RDONLY );
	OUTPUT:
		RETVAL

SV*
SPO_RDWR()
	CODE:
		RETVAL = newSViv( SPO_RDWR );
	OUTPUT:
		RETVAL

SV*
SPO_CREAT()
	CODE:
		RETVAL = newSViv( SPO_CREAT );
	OUTPUT:
		RETVAL

SV*
SPO_SYNC()
	CODE:
		RETVAL = newSViv( SPO_SYNC );
	OUTPUT:
		RETVAL

#
SV*
SPGT()
	CODE:
		RETVAL = newSViv( SPGT );
	OUTPUT:
		RETVAL

SV*
SPGTE()
	CODE:
		RETVAL = newSViv( SPGTE );
	OUTPUT:
		RETVAL

SV*
SPLT()
	CODE:
		RETVAL = newSViv( SPLT );
	OUTPUT:
		RETVAL

SV*
SPLTE()
	CODE:
		RETVAL = newSViv( SPLTE );
	OUTPUT:
		RETVAL


