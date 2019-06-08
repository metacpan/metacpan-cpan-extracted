#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unbound.h>    /* unbound API */

SV * _ub_result_to_svhv_and_free (struct ub_result* result) {
    SV *val;

    AV *data = newAV();
    unsigned int i = 0;

    if (result->data != NULL) {
        while (result->data[i] != NULL) {
            val = newSVpvn(result->data[i], result->len[i]);
            av_push(data, val);
            i++;
        }
    }

    HV * rh = newHV();

    val = newSVpv(result->qname, 0);
    hv_stores(rh, "qname", val);

    val = newSViv(result->qtype);
    hv_stores(rh, "qtype", val);

    val = newSViv(result->qclass);
    hv_stores(rh, "qclass", val);

    hv_stores(rh, "data", newRV_inc((SV *)data));

    val = newSVpv(result->canonname, 0);
    hv_stores(rh, "canonname", val);

    val = newSViv(result->rcode);
    hv_stores(rh, "rcode", val);

    val = newSViv(result->havedata);
    hv_stores(rh, "havedata", val);

    val = newSViv(result->nxdomain);
    hv_stores(rh, "nxdomain", val);

    val = newSViv(result->secure);
    hv_stores(rh, "secure", val);

    val = newSViv(result->bogus);
    hv_stores(rh, "bogus", val);

    val = newSVpv(result->why_bogus, 0);
    hv_stores(rh, "why_bogus", val);

    val = newSViv(result->ttl);
    hv_stores(rh, "ttl", val);

    ub_resolve_free(result);

    return (SV *)rh;
}

void _async_resolve_callback(void* mydata, int err, struct ub_result* result) {
    SV *result_sv = (SV *) mydata;

    if (err) {
        SvUPGRADE( result_sv, SVt_IV );
        SvIV_set( result_sv, err );
        SvIOK_on( result_sv );
    }
    else {
        SV * svres = _ub_result_to_svhv_and_free(result);

        SvUPGRADE( result_sv, SVt_RV );
        SvRV_set( result_sv, svres );
        SvROK_on( result_sv );
    }

    return;
}

MODULE = DNS::Unbound           PACKAGE = DNS::Unbound

PROTOTYPES: DISABLE

struct ub_ctx*
_create_context()
    CODE:
        struct ub_ctx* my_ctx = ub_ctx_create();

        if (!my_ctx) {
            croak("Failed to create Unbound context!");
        }

        RETVAL = my_ctx;
    OUTPUT:
        RETVAL

int
_ub_ctx_set_option( struct ub_ctx *ctx, const char* opt, const char* val)
    CODE:
        RETVAL = ub_ctx_set_option(ctx, opt, val);
    OUTPUT:
        RETVAL

SV *
_ub_ctx_get_option( struct ub_ctx *ctx, const char* opt)
    CODE:
        char *str;

        int fate = ub_ctx_get_option(ctx, opt, &str);

        if (fate) {

            // On failure, return a plain SV that gives the error.
            RETVAL = newSViv(fate);
        }
        else {
            SV *val = newSVpv(str, 0);

            // On success, return a reference to an SV that gives the value.
            RETVAL = newRV_inc(val);
        }

        free(str);
    OUTPUT:
        RETVAL

const char *
_ub_strerror( int err )
    CODE:
        RETVAL = ub_strerror(err);
    OUTPUT:
        RETVAL

int
_ub_ctx_async( struct ub_ctx *ctx, int dothread )
    CODE:
        RETVAL = ub_ctx_async( ctx, dothread );
    OUTPUT:
        RETVAL

int
_ub_poll( struct ub_ctx *ctx )
    CODE:
        RETVAL = ub_poll(ctx);
    OUTPUT:
        RETVAL

int
_ub_wait( struct ub_ctx *ctx )
    CODE:
        RETVAL = ub_wait(ctx);
    OUTPUT:
        RETVAL

int
_ub_process( struct ub_ctx *ctx )
    CODE:
        RETVAL = ub_process(ctx);
    OUTPUT:
        RETVAL

int
_ub_cancel( struct ub_ctx *ctx, int async_id )
    CODE:
        RETVAL = ub_cancel(ctx, async_id);
    OUTPUT:
        RETVAL

int
_ub_fd( struct ub_ctx *ctx )
    CODE:
        RETVAL = ub_fd(ctx);
    OUTPUT:
        RETVAL

SV *
_resolve_async( struct ub_ctx *ctx, const char *name, int type, int class, SV *result )
    CODE:
        int async_id = 0;

        // A few different approaches were tried here, including passing
        // coderefs to ub_resolve_async, but the one thing that seems to
        // work is passing a pointer to the result SV, which the async
        // callback then receives; that callback then populates the SV
        // with either the result hashref (success) or the failure number.
        // This does mean that it has to be Perl that checks for whether
        // the result SV is populated--which seems to work just fine.

        int reserr = ub_resolve_async(
            ctx,
            name, type, class,
            (void *) result, _async_resolve_callback, &async_id
        );

        AV *ret = newAV();
        av_push( ret, newSViv(reserr) );
        av_push( ret, newSViv(async_id) );

        RETVAL = newRV_inc((SV *)ret);
    OUTPUT:
        RETVAL

SV *
_resolve( struct ub_ctx *ctx, SV *name, int type, int class = 1 )
    CODE:
        struct ub_result* result;
        int retval;

        retval = ub_resolve(ctx, SvPV_nolen(name), type, class, &result);

        if (retval != 0) {
            RETVAL = newSViv(retval);
        }
        else {
            RETVAL = _ub_result_to_svhv_and_free(result);
        }

    OUTPUT:
        RETVAL

BOOT:
    HV *stash = gv_stashpvn("DNS::Unbound", 12, FALSE);
    newCONSTSUB(stash, "unbound_version", newSVpv( ub_version(), 0 ));

void
_destroy_context( struct ub_ctx *ctx )
    CODE:
        ub_ctx_delete(ctx);
