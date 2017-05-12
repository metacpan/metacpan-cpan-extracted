#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <memcache.h>

typedef struct memcache Memcache;
typedef struct memcache_req MemcacheReq;
typedef struct memcache_res MemcacheRes;

static void my_callback_func(MCM_CALLBACK_SIG);
static void
my_callback_func(MCM_CALLBACK_FUNC)
{
	struct my_struct *ptr = (struct my_struct *)MCM_CALLBACK_PTR;
	struct memcache_ctxt *ctxt = MCM_CALLBACK_CTXT;
	struct memcache_res *res = MCM_CALLBACK_RES;

	SV * resultsarrayref;
	AV * resultsarray;
	SV * resultshash1ref;
	HV * resultshash1;
	SV * resultshash2ref;
	HV * resultshash2;

	if (!(res->_flags & MCM_RES_FOUND))
		return;
	resultsarrayref = (SV*)ptr;
	if (!SvROK(resultsarrayref))
		return;
	resultsarray = (AV *)SvRV(resultsarrayref);
	if (SvTYPE(resultsarray) != SVt_PVAV)
		return;
	if (av_len(resultsarray) != 1)
		return;
	resultshash1ref = *av_fetch(resultsarray, 0, 0);
	resultshash2ref = *av_fetch(resultsarray, 1, 0);

	resultshash1 = (HV *)SvRV(resultshash1ref);
	if (SvTYPE(resultshash1) != SVt_PVHV)
		return;
	hv_store(resultshash1, res->key, res->len, newSVpvn(res->val,res->bytes), 0);

	resultshash2 = (HV *)SvRV(resultshash2ref);
	if (SvTYPE(resultshash2) != SVt_PVHV)
		return;
	hv_store(resultshash2, res->key, res->len, newSViv(res->flags), 0);
}

MODULE = Cache::Memcached::XS		PACKAGE = Cache::Memcached::XS		

Memcache *
mc_new()
	CODE:
		RETVAL = (Memcache *)mc_new();
	OUTPUT:
		RETVAL

void
mc_server_add4(mc,host)
		Memcache *mc;
		char *host;

MemcacheReq *
mc_req_new()
	CODE:
		RETVAL = (MemcacheReq *)mc_req_new();
	OUTPUT:
		RETVAL

MemcacheRes *
mc_req_add(req,key)
		MemcacheReq *req;
		char *key;
	CODE:
		RETVAL = (MemcacheRes *)mc_req_add(req,key,strlen(key));
	OUTPUT:
		RETVAL

void
mc_res_register_callback(req,res,results)
		MemcacheReq *req;
		MemcacheRes *res;
		SV * results;
	CODE:
		mc_res_register_fetch_cb(req,res,my_callback_func,results);

void
mc_get(mc,req)
		Memcache *mc;
		MemcacheReq *req;

int
mc_set(mc,key,val_sv,exp,flags)
		Memcache *mc;
		char *key;
		SV *val_sv;
		int exp;
		int flags;
	INIT:
		char *val;
		int len;
	CODE:
		val = SvPV(val_sv,len);
		RETVAL = mc_set(mc,key,strlen(key),val,len,exp,flags);
	OUTPUT:
		RETVAL

int
mc_add(mc,key,val_sv,exp,flags)
		Memcache *mc;
		char *key;
		SV *val_sv;
		int exp;
		int flags;
	INIT:
		char *val;
		int len;
	CODE:
		val = SvPV(val_sv,len);
		RETVAL = mc_add(mc,key,strlen(key),val,len,exp,flags);
	OUTPUT:
		RETVAL

int
mc_replace(mc,key,val_sv,exp,flags)
		Memcache *mc;
		char *key;
		SV *val_sv;
		int exp;
		int flags;
	INIT:
		char *val;
		int len;
	CODE:
		val = SvPV(val_sv,len);
		RETVAL = mc_replace(mc,key,strlen(key),val,len,exp,flags);
	OUTPUT:
		RETVAL

int
mc_incr(mc,key,val)
		Memcache *mc;
		char *key;
		int val;
	CODE:
		RETVAL = mc_incr(mc,key,strlen(key),val);
	OUTPUT:
		RETVAL

int
mc_decr(mc,key,val)
		Memcache *mc;
		char *key;
		int val;
	CODE:
		RETVAL = mc_decr(mc,key,strlen(key),val);
	OUTPUT:
		RETVAL

int
mc_delete(mc,key,hold)
		Memcache *mc;
		char *key;
		int hold;
	CODE:
		RETVAL = mc_delete(mc,key,strlen(key),hold);
	OUTPUT:
		RETVAL

MODULE = Cache::Memcached::XS		PACKAGE = MemcachePtr		PREFIX = xsmc_

void
xsmc_DESTROY(mc)
		Memcache *mc
	CODE:
		mc_free(mc);

MODULE = Cache::Memcached::XS		PACKAGE = MemcacheReqPtr	PREFIX = xsmcreq_

void
xsmcreq_DESTROY(req)
		MemcacheReq *req
	CODE:
		mc_req_free(req);

