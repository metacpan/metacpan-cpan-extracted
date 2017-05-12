#include <dce/binding.h>
#include <dce/pgo.h>
#include <dce/uuid.h>
#include <dce/rgynbase.h>
#include <dce/acct.h>
#include <dce/policy.h>
#include <dce/rpc.h>
#include <dce/dce_error.h>

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* $Id: DCE_Perl.h,v 1.16 1997/06/23 03:45:20 dougm Exp $ */

#ifndef SET_STATUS
#define SET_STATUS(stp, val)      ((*stp) = val)
#endif

/* 
 * Not sure this is a good idea, so for now users
 * must ask for this magic ala 'tie $status => DCE::Status'
 */
#define STATUS_MAGIC \
   if(status != sec_rgy_status_ok) { \
      int error_stat; \
      unsigned char error_string[dce_c_error_string_len]; \
      SV *sv = perl_get_sv("DCE::status",TRUE); \
      sv_setnv(sv, (double)status); \
      dce_error_inq_text(status, error_string, &error_stat); \
      sv_setpv(sv, error_string); \
      SvNOK_on(sv); \
   } 

#define DCESTATUS \
   XPUSHs_iv(status)  

#define CHK_STS(n) \
{ \
   int i; \
   if(status > 0) { \
	for(i=0; i<n; i++) \
	  XPUSHs(&PL_sv_undef); \
        DCESTATUS; \
	PUTBACK; \
	return; \
   } \
}

#define WANTARRAY GIMME == G_ARRAY

#define hv_true_fetch(hv,k,kl,lv) \
hv_exists(hv, k, kl) ? hv_fetch(hv, k, kl, lv) : 0

#define DCE_TIEHASH(p, package, hv) \
{ \
      SV *sv = sv_newmortal(); \
      resetHV(hv); \
      sv_setref_pv(sv, package, (void*)p); \
      sv_magic((SV*)hv, sv, 'P', Nullch, 0); \
}

#define resetHV(hv) hv = (HV*)sv_2mortal((SV*)newHV()) 
#define iniHV 	hv = (HV*)sv_2mortal((SV*)newHV())
#define resetAV(av) av = (AV*)sv_2mortal((SV*)newAV())
#define iniAV 	av = (AV*)sv_2mortal((SV*)newAV())
#define iniSV 	sv = (SV*)sv_2mortal((SV*)newSV(0))

#define PUSHs_pv(pv) PUSHs(sv_2mortal((SV*)newSVpv(pv,0)));
#define PUSHs_iv(iv) PUSHs(sv_2mortal((SV*)newSViv(iv)));
#define XPUSHs_pv(pv) XPUSHs(sv_2mortal((SV*)newSVpv(pv,0)));
#define XPUSHs_iv(iv) XPUSHs(sv_2mortal((SV*)newSViv(iv)));

typedef sec_rgy_handle_t   DCE__Registry;
typedef sec_login_handle_t DCE__Login;
typedef sec_rgy_cursor_t   * DCE__cursor;
typedef sec_rgy_cursor_t   * DCE__RegistryCursor;
typedef uuid_t             * DCE__UUID;

#define __bless_uuid(anyid, sv) \
{ \
       unsigned_char_t *uuid_str; \
       error_status_t  uuid_str_status; \
       uuid_to_string(&anyid, &uuid_str, &uuid_str_status); \
       sv_setpv(sv, (unsigned_char_t *)uuid_str); \
}

#define broken__bless_uuid(id, uuid_sv) \
    sv_setref_pv(uuid_sv, "DCE::UUID", (void*)id)  

#define BLESS_UUID(anyid) \
{ \
       uuid_sv = newSV(0); \
       __bless_uuid(anyid, uuid_sv); \
}

#define BLESS_UUID_mortal(id) \
    uuid_sv = sv_newmortal(); \
    __bless_uuid(id, uuid_sv)


#define UUID2SV(uuid) \
{ \
    error_status_t status; \
    unsigned_char_t *uuid_str; \
    uuid_sv = newSV(0); \
    uuid_to_string(&uuid, &uuid_str, &status); \
    sv_setpv(uuid_sv, (unsigned_char_t *)uuid_str); \
    printf("UUID2SV %s\n", uuid_str); \
}

#define UUIDmagic_sv(_uuid, sv) \
{\
      STRLEN l; \
      error_status_t  str_status; \
      uuid_from_string((unsigned_char_t *)SvPV(sv,l), &_uuid, &str_status); \
}


/* can be a DCE::UUID object or string */

#define broken_UUIDmagic_sv(uuid, sv) \
{ \
    if(sv_isa(sv, "DCE::UUID")) { \
      IV tmp = SvIV((SV*)SvRV(sv)); \
      uuid = (DCE__UUID)tmp; \
    } \
    else { \
       error_status_t  str_status; \
       uuid = (uuid_t *)safemalloc(sizeof(uuid_t)); \
       uuid_from_string((unsigned_char_t *)SvPV(sv,PL_na), uuid, &str_status); \
    } \
}

/* DCE_TIEHASH(&sec_id, "DCE::sec_id", id); */

#define STORE_SEC_ID(sec_id,hv,key,len) \
{ \
    HV *id = (HV*)sv_2mortal((SV*)newHV()); \
    SV *uuid_sv; \
    BLESS_UUID(sec_id.uuid); \
    hv_store(id, "uuid", 4, uuid_sv, 0); \
    hv_store(hv, key, len, newRV((SV*)id), 0); \
}

#define AV_PUSH_SEC_ID(sec_id,av) \
{ \
    HV *id = (HV*)sv_2mortal((SV*)newHV()); \
    SV *uuid_sv; \
    BLESS_UUID(sec_id.uuid); \
    hv_store(id, "uuid", 4, uuid_sv, 0); \
    av_push(av, newRV((SV*)id)); \
}

#define FETCH_SEC_ID(sec_id,hv,key,len) \
{ \
    SV **svp; \
    HV *set_id = (HV*)SvRV(*hv_fetch(hv, key, len, 0)); \
    svp = hv_fetch(set_id, "uuid", 4, 0); \
    if(SvTRUE(*svp)) \
      UUIDmagic_sv(sec_id.uuid, *svp); \
    svp = hv_fetch(set_id, "name", 4, 0); \
    if(SvTRUE(*svp)) \
    sec_id.name = SvPV(*svp,PL_na); \
}

#define FETCH_FOREIGN_ID(f_id,hv) \
{ \
    HV *f_hv = (HV*)SvRV(*hv_fetch(hv, "foreign_id", 10, 0)); \
    FETCH_SEC_ID(f_id.id, f_hv, "id", 2); \
    FETCH_SEC_ID(f_id.realm, f_hv, "realm", 5); \
}

#define STORE_FOREIGN_ID(f_id,hv) \
{ \
    HV *foreign_id = (HV*)sv_2mortal((SV*)newHV()); \
    STORE_SEC_ID(f_id.id, foreign_id, "id", 2); \
    STORE_SEC_ID(f_id.realm, foreign_id, "realm", 5); \
    hv_store(hv, "foreign_id", 10, newRV((SV*)foreign_id), 0); \
}









