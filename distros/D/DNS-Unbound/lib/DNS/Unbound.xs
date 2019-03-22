#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unbound.h>    /* unbound API */

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
            RETVAL = newSVnv(fate);
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

SV *
_resolve( struct ub_ctx *ctx, SV *name, int type, int class = 1 )
    CODE:
        struct ub_result* result;
        int retval;

        retval = ub_resolve(ctx, SvPV_nolen(name), type, class, &result);

        if (retval != 0) {
            RETVAL = newSVnv(retval);
        }
        else {
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

            val = newSVnv(result->qtype);
            hv_stores(rh, "qtype", val);

            val = newSVnv(result->qclass);
            hv_stores(rh, "qclass", val);

            hv_stores(rh, "data", newRV_inc((SV *)data));

            val = newSVpv(result->canonname, 0);
            hv_stores(rh, "canonname", val);

            val = newSVnv(result->rcode);
            hv_stores(rh, "rcode", val);

            val = newSVnv(result->havedata);
            hv_stores(rh, "havedata", val);

            val = newSVnv(result->nxdomain);
            hv_stores(rh, "nxdomain", val);

            val = newSVnv(result->secure);
            hv_stores(rh, "secure", val);

            val = newSVnv(result->bogus);
            hv_stores(rh, "bogus", val);

            val = newSVpv(result->why_bogus, 0);
            hv_stores(rh, "why_bogus", val);

            val = newSVnv(result->ttl);
            hv_stores(rh, "ttl", val);

            RETVAL = newRV_inc((SV *)rh);
        }

        ub_resolve_free(result);

    OUTPUT:
        RETVAL

BOOT:
    HV *stash = gv_stashpvn("DNS::Unbound", 12, FALSE);
    newCONSTSUB(stash, "unbound_version", newSVpv( ub_version(), 0 ));

void
_destroy_context( struct ub_ctx *ctx )
    CODE:
        ub_ctx_delete(ctx);
