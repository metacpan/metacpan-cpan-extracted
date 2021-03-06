
/*
 * *********** WARNING **************
 * This file generated by Apache::DAV::WrapXS/0.01
 * Any changes made here will be lost
 * ***********************************
 * 1. /opt/perl5.6.1/lib/site_perl/5.6.1/ExtUtils/XSBuilder/WrapXS.pm:38
 * 2. /opt/perl5.6.1/lib/site_perl/5.6.1/ExtUtils/XSBuilder/WrapXS.pm:1898
 * 3. xsbuilder/xs_generate.pl:6
 */


#include "mod_dav.h"

#include "EXTERN.h"

#include "perl.h"

#include "XSUB.h"

#include "moddav_xs_sv_convert.h"

#include "moddav_xs_typedefs.h"

static SV * davxs_Apache__DAV__WalkerCtx_obj[4] ;



void Apache__DAV__WalkerCtx_new_init (pTHX_ Apache__DAV__WalkerCtx  obj, SV * item, int overwrite) {

    SV * * tmpsv ;

    if (SvTYPE(item) == SVt_PVMG) 
        memcpy (obj, (void *)SvIVX(item), sizeof (*obj)) ;
    else if (SvTYPE(item) == SVt_PVHV) {
        if ((tmpsv = hv_fetch((HV *)item, "walk_type", sizeof("walk_type") - 1, 0)) || overwrite) {
            obj -> walk_type = (int)davxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "postfix", sizeof("postfix") - 1, 0)) || overwrite) {
            obj -> postfix = (int)davxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "pool", sizeof("pool") - 1, 0)) || overwrite) {
            obj -> pool = (struct pool *)davxs_sv2_Apache__Pool((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "r", sizeof("r") - 1, 0)) || overwrite) {
            obj -> r = (request_rec *)davxs_sv2_Apache((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "resource", sizeof("resource") - 1, 0)) || overwrite) {
            obj -> resource = (const dav_resource *)davxs_sv2_Apache__DAV__Resource((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "res2", sizeof("res2") - 1, 0)) || overwrite) {
            obj -> res2 = (const dav_resource *)davxs_sv2_Apache__DAV__Resource((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "root", sizeof("root") - 1, 0)) || overwrite) {
            obj -> root = (const dav_resource *)davxs_sv2_Apache__DAV__Resource((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "lockdb", sizeof("lockdb") - 1, 0)) || overwrite) {
            obj -> lockdb = (dav_lockdb *)davxs_sv2_Apache__DAV__LockDB((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "response", sizeof("response") - 1, 0)) || overwrite) {
            obj -> response = (dav_response *)davxs_sv2_Apache__DAV__Response((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "doc", sizeof("doc") - 1, 0)) || overwrite) {
            obj -> doc = (dav_xml_doc *)davxs_sv2_Apache__DAV__XMLDoc((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "propfind_type", sizeof("propfind_type") - 1, 0)) || overwrite) {
            obj -> propfind_type = (int)davxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "propstat_404", sizeof("propstat_404") - 1, 0)) || overwrite) {
            obj -> propstat_404 = (dav_text *)davxs_sv2_Apache__DAV__Text((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "is_move", sizeof("is_move") - 1, 0)) || overwrite) {
            obj -> is_move = (int)davxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "if_header", sizeof("if_header") - 1, 0)) || overwrite) {
            obj -> if_header = (const dav_if_header *)davxs_sv2_Apache__DAV__IfHeader((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "locktoken", sizeof("locktoken") - 1, 0)) || overwrite) {
            obj -> locktoken = (const dav_locktoken *)davxs_sv2_Apache__DAV__LockToken((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "lock", sizeof("lock") - 1, 0)) || overwrite) {
            obj -> lock = (const dav_lock *)davxs_sv2_Apache__DAV__Lock((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "skip_root", sizeof("skip_root") - 1, 0)) || overwrite) {
            obj -> skip_root = (int)davxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
        if ((tmpsv = hv_fetch((HV *)item, "flags", sizeof("flags") - 1, 0)) || overwrite) {
            obj -> flags = (int)davxs_sv2_IV((tmpsv && *tmpsv?*tmpsv:&PL_sv_undef)) ;
        }
   ; }

    else
        croak ("initializer for Apache::DAV::WalkerCtx::new is not a hash or object reference") ;

} ;



/* --- Apache::DAV::WalkerCtx -> func --- */



static Apache__DAV__Error davxs_cb_Apache__DAV__WalkerCtx__func (SV * __cbdest,struct dav_walker_ctx * ctx,int calltype)
    {
    Apache__DAV__Error __retval ;
    SV * __retsv ;

    int __cnt ;
    
    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;
    PUSHs(__cbdest) ;
    PUSHs(davxs_Apache__DAV__WalkerCtx_2obj(ctx)) ;
    PUSHs(davxs_IV_2obj(calltype)) ;

    PUTBACK ;
    __cnt = perl_call_method("func", G_SCALAR) ;


    if (__cnt != 1)
        croak ("davxs_cb_Apache__DAV__WalkerCtx__func expected 1 return values") ;

    SPAGAIN ;
    __retsv = POPs;
    __retval = (Apache__DAV__Error)davxs_sv2_Apache__DAV__Error(__retsv);

    PUTBACK ;
    FREETMPS ;
    LEAVE ;
    
   
    return __retval ;

    }
   


static Apache__DAV__Error davxs_cb_Apache__DAV__WalkerCtx__func_obj0 (struct dav_walker_ctx * ctx,int calltype)
    {
    return davxs_cb_Apache__DAV__WalkerCtx__func (davxs_Apache__DAV__WalkerCtx_obj[0],ctx,calltype) ;
    }



static Apache__DAV__Error davxs_cb_Apache__DAV__WalkerCtx__func_obj1 (struct dav_walker_ctx * ctx,int calltype)
    {
    return davxs_cb_Apache__DAV__WalkerCtx__func (davxs_Apache__DAV__WalkerCtx_obj[1],ctx,calltype) ;
    }



static Apache__DAV__Error davxs_cb_Apache__DAV__WalkerCtx__func_obj2 (struct dav_walker_ctx * ctx,int calltype)
    {
    return davxs_cb_Apache__DAV__WalkerCtx__func (davxs_Apache__DAV__WalkerCtx_obj[2],ctx,calltype) ;
    }



static Apache__DAV__Error davxs_cb_Apache__DAV__WalkerCtx__func_obj3 (struct dav_walker_ctx * ctx,int calltype)
    {
    return davxs_cb_Apache__DAV__WalkerCtx__func (davxs_Apache__DAV__WalkerCtx_obj[3],ctx,calltype) ;
    }

typedef Apache__DAV__Error (*tdavxs_cb_Apache__DAV__WalkerCtx__func_func)(struct dav_walker_ctx * ctx,int calltype)  ;
static tdavxs_cb_Apache__DAV__WalkerCtx__func_func davxs_davxs_cb_Apache__DAV__WalkerCtx__func_func [4] = {
    davxs_cb_Apache__DAV__WalkerCtx__func_obj0,
    davxs_cb_Apache__DAV__WalkerCtx__func_obj1,
    davxs_cb_Apache__DAV__WalkerCtx__func_obj2,
    davxs_cb_Apache__DAV__WalkerCtx__func_obj3
    } ;


MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

int
walk_type(obj, val=0)
    Apache::DAV::WalkerCtx obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->walk_type;

    if (items > 1) {
        obj->walk_type = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

int
postfix(obj, val=0)
    Apache::DAV::WalkerCtx obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->postfix;

    if (items > 1) {
        obj->postfix = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::Error
func(__self, ctx, calltype)
    Apache::DAV::WalkerCtx __self
    Apache::DAV::WalkerCtx ctx
    int calltype
CODE:
    RETVAL = (*__self->func)(ctx, calltype);
OUTPUT:
    RETVAL


MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::Pool
pool(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::Pool val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__Pool)  obj->pool;

    if (items > 1) {
        obj->pool = (Apache__Pool) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache
r(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache)  obj->r;

    if (items > 1) {
        obj->r = (Apache) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::Resource
resource(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::Resource val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__Resource)  obj->resource;

    if (items > 1) {
        obj->resource = (Apache__DAV__Resource) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::Resource
res2(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::Resource val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__Resource)  obj->res2;

    if (items > 1) {
        obj->res2 = (Apache__DAV__Resource) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::Resource
root(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::Resource val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__Resource)  obj->root;

    if (items > 1) {
        obj->root = (Apache__DAV__Resource) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::LockDB
lockdb(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::LockDB val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__LockDB)  obj->lockdb;

    if (items > 1) {
        obj->lockdb = (Apache__DAV__LockDB) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::Response
response(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::Response val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__Response)  obj->response;

    if (items > 1) {
        obj->response = (Apache__DAV__Response) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::XMLDoc
doc(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::XMLDoc val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__XMLDoc)  obj->doc;

    if (items > 1) {
        obj->doc = (Apache__DAV__XMLDoc) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

int
propfind_type(obj, val=0)
    Apache::DAV::WalkerCtx obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->propfind_type;

    if (items > 1) {
        obj->propfind_type = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::Text
propstat_404(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::Text val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__Text)  obj->propstat_404;

    if (items > 1) {
        obj->propstat_404 = (Apache__DAV__Text) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

int
is_move(obj, val=0)
    Apache::DAV::WalkerCtx obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->is_move;

    if (items > 1) {
        obj->is_move = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::IfHeader
if_header(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::IfHeader val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__IfHeader)  obj->if_header;

    if (items > 1) {
        obj->if_header = (Apache__DAV__IfHeader) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::LockToken
locktoken(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::LockToken val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__LockToken)  obj->locktoken;

    if (items > 1) {
        obj->locktoken = (Apache__DAV__LockToken) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

Apache::DAV::Lock
lock(obj, val=NULL)
    Apache::DAV::WalkerCtx obj
    Apache::DAV::Lock val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (Apache__DAV__Lock)  obj->lock;

    if (items > 1) {
        obj->lock = (Apache__DAV__Lock) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

int
skip_root(obj, val=0)
    Apache::DAV::WalkerCtx obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->skip_root;

    if (items > 1) {
        obj->skip_root = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 

int
flags(obj, val=0)
    Apache::DAV::WalkerCtx obj
    int val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = (int)  obj->flags;

    if (items > 1) {
        obj->flags = (int) val;
    }
  OUTPUT:
    RETVAL

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 



SV *
new (class,initializer=NULL)
    char * class
    SV * initializer 
PREINIT:
    SV * svobj ;
    Apache__DAV__WalkerCtx  cobj ;
    SV * tmpsv ;
CODE:
    davxs_Apache__DAV__WalkerCtx_create_obj(cobj,svobj,RETVAL,malloc(sizeof(*cobj))) ;

    if (initializer) {
        if (!SvROK(initializer) || !(tmpsv = SvRV(initializer))) 
            croak ("initializer for Apache::DAV::WalkerCtx::new is not a reference") ;

        if (SvTYPE(tmpsv) == SVt_PVHV || SvTYPE(tmpsv) == SVt_PVMG)  
            Apache__DAV__WalkerCtx_new_init (aTHX_ cobj, tmpsv, 0) ;
        else if (SvTYPE(tmpsv) == SVt_PVAV) {
            int i ;
            SvGROW(svobj, sizeof (*cobj) * av_len((AV *)tmpsv)) ;     
            for (i = 0; i <= av_len((AV *)tmpsv); i++) {
                SV * * itemrv = av_fetch((AV *)tmpsv, i, 0) ;
                SV * item ;
                if (!itemrv || !*itemrv || !SvROK(*itemrv) || !(item = SvRV(*itemrv))) 
                    croak ("array element of initializer for Apache::DAV::WalkerCtx::new is not a reference") ;
                Apache__DAV__WalkerCtx_new_init (aTHX_ &cobj[i], item, 1) ;
            }
        }
        else {
             croak ("initializer for Apache::DAV::WalkerCtx::new is not a hash/array/object reference") ;
        }
    }
OUTPUT:
    RETVAL 

MODULE = Apache::DAV::WalkerCtx    PACKAGE = Apache::DAV::WalkerCtx 



void
init_callbacks (obj)
    SV *  obj
PREINIT:
    int  n = -1 ;
    int  i ;
    Apache__DAV__WalkerCtx cobj = (Apache__DAV__WalkerCtx)davxs_sv2_Apache__DAV__WalkerCtx(obj) ;
    SV * ref ;
    SV * perl_obj ;
CODE:

    perl_obj = SvRV(obj) ;
    ref = newRV_noinc(perl_obj) ;

    for (i=0;i < 4;i++)
        {
        if (davxs_Apache__DAV__WalkerCtx_obj[i] == ref)
            {
            n = i ;
            break ;
            }
        }

    if (n < 0)
        for (i=0;i < 4;i++)
            {
            if (davxs_Apache__DAV__WalkerCtx_obj[i] == NULL)
                {
                n = i ;
                break ;
                }
            }
        
    if (n < 0)
        croak ("Limit for concurrent object callbacks reached for Apache::DAV::WalkerCtx. Limit is 4") ;

    davxs_Apache__DAV__WalkerCtx_obj[n] = ref ;
    cobj -> func = davxs_davxs_cb_Apache__DAV__WalkerCtx__func_func[n] ;
    

PROTOTYPES: disabled

BOOT:
    items = items; /* -Wall */

