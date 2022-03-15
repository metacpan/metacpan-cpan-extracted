#include "easyxs/easyxs.h"

#include <unbound.h>    /* unbound API */
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#define UNUSED(x) (void)(x)

#define DEBUG 0

#ifdef MULTIPLICITY
#define NEED_THX 1
#else
#define NEED_THX 0
#endif

#define _PERL_HAS_PL_PHASE (PERL_VERSION_GE(5, 14, 0))

#if _PERL_HAS_PL_PHASE
// TODO: Once the phase name macro is in ppport.h, use that instead.
#define _DEBUG(str, ...) if (DEBUG) fprintf(stderr, str " (phase=%s)\n", ##__VA_ARGS__, PL_phase_names[PL_phase]);
#else
#define _DEBUG(str, ...) if (DEBUG) fprintf(stderr, str " (destruct? %d)\n", ##__VA_ARGS__, PL_dirty);
#endif

#include "errcodes_define.inc"

typedef struct {
    pid_t pid;
    struct ub_ctx* ub_ctx;
    HV* queries_hv;
    unsigned refcount;
    int debugfd;    /* -1 means no stored debug out */
} DNS__Unbound__Context;

typedef struct {
#if NEED_THX
    tTHX my_aTHX;
#endif

    pid_t pid;

    DNS__Unbound__Context* ctx;

    int id;

    SV* callback;
} dub_query_ctx_t;

// ----------------------------------------------------------------------

// A “blessed struct” is an SVPV that stores a C struct, wrapped in a
// reference SV with a bless(). This allows Perl itself to do the
// allocating and freeing of the struct, which simplfies memory management.

#define my_new_blessedstruct(type, classname) _my_new_blessedstruct_f(aTHX_ sizeof(type), classname)

#define my_get_blessedstruct_ptr(svrv) ( (void *) SvPVX( SvRV(svrv) ) )

static SV* _my_new_blessedstruct_f (pTHX_ unsigned size, const char* classname) {

    SV* referent = newSV(size);
    SvPOK_on(referent);

    SV* reference = newRV_noinc(referent);
    sv_bless(reference, gv_stashpv(classname, FALSE));

    return reference;
}

// ----------------------------------------------------------------------

#define _new_dub_context_struct(ubctx) (    \
    (DNS__Unbound__Context) {               \
        .pid = getpid(),                    \
        .ub_ctx = ubctx,                    \
        .queries_hv = newHV(),              \
        .refcount = 1,                      \
        .debugfd = -1,                      \
    }                                       \
)

#define _increment_dub_ctx_refcount(ctx) STMT_START { \
    ctx->refcount++;    \
    _DEBUG("%s: DNS__Unbound__Context %p inc refcount (now %d)", __func__, ctx, ctx->refcount); \
} STMT_END

static bool _decrement_dub_ctx_refcount (pTHX_ DNS__Unbound__Context* dub_ctx) {
    if (!--dub_ctx->refcount) {
        _DEBUG("Freeing DNS__Unbound__Context %p", dub_ctx);

        if ((getpid() == dub_ctx->pid) && PL_dirty) {
            warn("Freeing DNS::Unbound context at global destruction; memory leak likely!");
        }

        // We do NOT need to _close_saved_debugfd() here because
        // Unbound will do that for us.

        ub_ctx_delete(dub_ctx->ub_ctx);
        dub_ctx->ub_ctx = NULL;

        SvREFCNT_dec((SV*) dub_ctx->queries_hv);

        return true;
    }

    _DEBUG("DNS__Unbound__Context %p dec refcount (now %d)", dub_ctx, dub_ctx->refcount);
    return false;
}

// ----------------------------------------------------------------------

#define _create_query_id_str(async_id, strname) \
    char strname[256]; \
    snprintf(strname, sizeof(strname), "%d", async_id);

static void _store_query (pTHX_ DNS__Unbound__Context* ctx, SV* blessedstruct, int async_id, SV* callback) {

    dub_query_ctx_t* query_ctx = my_get_blessedstruct_ptr(blessedstruct);

    *query_ctx = (dub_query_ctx_t) {
#if NEED_THX
        .my_aTHX = aTHX,
#endif
        .pid = getpid(),
        .ctx = ctx,
        .id  = async_id,
        .callback = SvREFCNT_inc(callback),
    };

    _increment_dub_ctx_refcount(ctx);

    _create_query_id_str(async_id, id_str);

    hv_store(ctx->queries_hv, id_str, strlen(id_str), blessedstruct, 0);
}

static dub_query_ctx_t* _fetch_query (pTHX_ DNS__Unbound__Context* ctx, int async_id) {
    _DEBUG("%s %p %d", __func__, ctx, async_id);
    _create_query_id_str(async_id, id_str);

    SV** entry = hv_fetch(ctx->queries_hv, id_str, strlen(id_str), 0);

    // Sanity-check:
    assert(entry && *entry);

    _DEBUG("end %s %p %d", __func__, ctx, async_id);

    return my_get_blessedstruct_ptr(*entry);
}

static void _unstore_query (pTHX_ DNS__Unbound__Context* ctx, int async_id, SV* cb_arg) {
    _DEBUG("%s %p %d", __func__, ctx, async_id);
    dub_query_ctx_t* query_ctx = _fetch_query(aTHX_ ctx, async_id);

    SV* callback = query_ctx->callback;

    _create_query_id_str(async_id, id_str);

    // This will mortalize the query_ctx_svrv stored in the hash:
    SV* query_ctx_svrv = hv_delete(ctx->queries_hv, id_str, strlen(id_str), 0);
    PERL_UNUSED_VAR(query_ctx_svrv);
    assert(query_ctx_svrv);

    if (_decrement_dub_ctx_refcount(aTHX_ ctx)) {
        warn("Prematurely reaped DNS::Unbound::Context?!?!?");
    }

    if (cb_arg) {
        SV *args[] = { cb_arg, NULL };
        exs_call_sv_void(callback, args);
    }

    SvREFCNT_dec(callback);

    _DEBUG("end %s %p", __func__, ctx);
}

// ----------------------------------------------------------------------

static SV* _ub_result_to_svhv_and_free (pTHX_ struct ub_result* result) {

    AV *data = newAV();
    unsigned datasize = 0;

    if (result->data != NULL) {
        while (result->data[datasize] != NULL) {
            datasize++;
        }

        if (datasize) {
            av_extend(data, datasize - 1);

            for (unsigned i=0; i<datasize; i++) {
                av_store(data, i, newSVpvn(result->data[i], result->len[i]));
            }
        }
    }

    HV * rh = newHV();

    hv_stores(rh, "qname", newSVpv(result->qname, 0));

    hv_stores(rh, "qtype", newSViv(result->qtype));

    hv_stores(rh, "qclass", newSViv(result->qclass));

    hv_stores(rh, "data", newRV_noinc((SV *)data));

    hv_stores(rh, "canonname", newSVpv(result->canonname, 0));

    hv_stores(rh, "rcode", newSViv(result->rcode));

    /* Ideally these could use boolSV(), but the efficiency gains
       probably don’t justify the API change. libunbound(3) documents
       these as ints, not bools, so we should preserve that. */
    hv_stores(rh, "havedata",   newSViv(result->havedata));
    hv_stores(rh, "nxdomain",   newSViv(result->nxdomain));
    hv_stores(rh, "secure",     newSViv(result->secure));
    hv_stores(rh, "bogus",      newSViv(result->bogus));

    hv_stores(rh, "why_bogus",
#if HAS_WHY_BOGUS
        newSVpv(result->why_bogus, 0)
#else
        &PL_sv_undef
#endif
    );

    hv_stores(rh, "ttl",
#if HAS_TTL
        newSViv(result->ttl)
#else
        &PL_sv_undef
#endif
    );

    hv_stores(rh, "answer_packet", newSVpvn(result->answer_packet, result->answer_len));

    ub_resolve_free(result);

    return newRV_noinc( (SV *)rh );
}

static void _async_resolve_callback(void* mydata, int err, struct ub_result* result) {
    SV* query_ctx_svrv = (SV*) mydata;

    dub_query_ctx_t *query_ctx = my_get_blessedstruct_ptr(query_ctx_svrv);

#if NEED_THX
    pTHX = query_ctx->my_aTHX;
#endif

    _DEBUG("RESOLVE CALLBACK (ID=%d)\n", query_ctx->id);

    SV* result_sv;
    _DEBUG("err: %d\n", err);

    if (err) {
        result_sv = newSViv(err);
    }
    else {
        result_sv = _ub_result_to_svhv_and_free(aTHX_ result);
    }

    _unstore_query(aTHX_ query_ctx->ctx, query_ctx->id, result_sv );

    return;
}

static void _close_saved_debugfd (DNS__Unbound__Context* ctx) {
        if (-1 != ctx->debugfd) close(ctx->debugfd);
}

// ----------------------------------------------------------------------

MODULE = DNS::Unbound           PACKAGE = DNS::Unbound

PROTOTYPES: DISABLE

INCLUDE: errcodes_boot.inc

const char*
_get_fd_mode_for_fdopen(int fd)
    CODE:
        int flags = fcntl( fd, F_GETFL );

        if ( flags == -1 ) {
            SETERRNO( errno, 0 );
            RETVAL = "";
        }
        else {
            RETVAL = (flags & O_APPEND) ? "a" : "w";
        }
    OUTPUT:
        RETVAL

const char *
_ub_strerror( int err )
    CODE:
        RETVAL = ub_strerror(err);
    OUTPUT:
        RETVAL

#if HAS_UB_VERSION
SV*
unbound_version(...)
    CODE:
        UNUSED(items);
        RETVAL = newSVpv( ub_version(), 0 );

    OUTPUT:
        RETVAL

#endif

# ----------------------------------------------------------------------

MODULE = DNS::Unbound           PACKAGE = DNS::Unbound::Context

PROTOTYPES: DISABLE

int
_ub_ctx_set_option( DNS__Unbound__Context* ctx, const char* opt, SV* val_sv)
    CODE:
        char *val = exs_SvPVbyte_nolen(val_sv);
        RETVAL = ub_ctx_set_option(ctx->ub_ctx, opt, val);
    OUTPUT:
        RETVAL

void
_ub_ctx_debuglevel( DNS__Unbound__Context* ctx, int d )
    CODE:
        ub_ctx_debuglevel(ctx->ub_ctx, d);

void
_ub_ctx_debugout( DNS__Unbound__Context* ctx, int fd, SV *mode_sv )
    CODE:
        char *mode = exs_SvPVbyte_nolen(mode_sv);
        FILE *fstream;

        int fd_to_save = -1;

        // Since libunbound does equality checks against stderr,
        // let’s ensure we use that same pointer.
        if (fd == fileno(stderr)) {
            fstream = stderr;
        }
        else if (fd == fileno(stdout)) {
            fstream = stdout;
        }
        else {
            int dupfd = dup(fd);

            if (-1 == dupfd) {
                croak("Failed to dup(%d): %s", fd, strerror(errno));
            }

            // We opened it, so we need to close it:
            fd_to_save = dupfd;

            // Linux doesn’t care, but MacOS will segfault if you
            // setvbuf() on an append stream opened on a non-append fd.
            fstream = fdopen( dupfd, mode );

            if (fstream == NULL) {
                fprintf(stderr, "fdopen failed!!\n");
            }

            setvbuf(fstream, NULL, _IONBF, 0);
        }

        ub_ctx_debugout( ctx->ub_ctx, fstream );

        _close_saved_debugfd(ctx);

        // This will usually be -1:
        ctx->debugfd = fd_to_save;

SV*
_ub_ctx_get_option( DNS__Unbound__Context* ctx, SV* opt)
    CODE:
        char *str;

        char *opt_str = exs_SvPVbyte_nolen(opt);

        int fate = ub_ctx_get_option(ctx->ub_ctx, opt_str, &str);

        if (fate) {

            // On failure, return a plain SV that gives the error.
            RETVAL = newSViv(fate);
        }
        else {
            SV *val = newSVpv(str, 0);

            // On success, return a reference to an SV that gives the value.
            RETVAL = newRV_noinc(val);
        }

        free(str);
    OUTPUT:
        RETVAL

int
_ub_ctx_add_ta( DNS__Unbound__Context* ctx, SV *ta )
    CODE:
        char *ta_str = exs_SvPVbyte_nolen(ta);
        RETVAL = ub_ctx_add_ta( ctx->ub_ctx, ta_str );
    OUTPUT:
        RETVAL

#if HAS_UB_CTX_ADD_TA_AUTR
int
_ub_ctx_add_ta_autr( DNS__Unbound__Context* ctx, SV *fname )
    CODE:
        char *fname_str = exs_SvPVbyte_nolen(fname);
        RETVAL = ub_ctx_add_ta_autr( ctx->ub_ctx, fname_str );
    OUTPUT:
        RETVAL

#endif

int
_ub_ctx_resolvconf( DNS__Unbound__Context* ctx, SV *fname_sv )
    CODE:
        char *fname = SvOK(fname_sv) ? exs_SvPVbyte_nolen(fname_sv) : NULL;

        RETVAL = ub_ctx_resolvconf( ctx->ub_ctx, fname );
    OUTPUT:
        RETVAL

int
_ub_ctx_hosts( DNS__Unbound__Context* ctx, SV *fname_sv )
    CODE:
        char *fname = SvOK(fname_sv) ? exs_SvPVbyte_nolen(fname_sv) : NULL;

        RETVAL = ub_ctx_hosts( ctx->ub_ctx, fname );
    OUTPUT:
        RETVAL

int
_ub_ctx_add_ta_file( DNS__Unbound__Context* ctx, SV *fname )
    CODE:
        char *fname_str = exs_SvPVbyte_nolen(fname);
        RETVAL = ub_ctx_add_ta_file( ctx->ub_ctx, fname_str );
    OUTPUT:
        RETVAL

int
_ub_ctx_trustedkeys( DNS__Unbound__Context* ctx, SV *fname )
    CODE:
        char *fname_str = exs_SvPVbyte_nolen(fname);
        RETVAL = ub_ctx_trustedkeys( ctx->ub_ctx, fname_str );
    OUTPUT:
        RETVAL

int
_ub_ctx_async( DNS__Unbound__Context* ctx, int dothread )
    CODE:
        RETVAL = ub_ctx_async( ctx->ub_ctx, dothread );
    OUTPUT:
        RETVAL

int
_ub_poll( DNS__Unbound__Context* ctx )
    CODE:
        RETVAL = ub_poll(ctx->ub_ctx);
    OUTPUT:
        RETVAL

int
_ub_wait( DNS__Unbound__Context* ctx )
    CODE:
        RETVAL = ub_wait(ctx->ub_ctx);
    OUTPUT:
        RETVAL

int
_ub_process( DNS__Unbound__Context* ctx )
    CODE:

        // Never ub_ctx_delete(ub_ctx) while using ub_ctx:
        _increment_dub_ctx_refcount(ctx);

        RETVAL = ub_process(ctx->ub_ctx);

        _decrement_dub_ctx_refcount(aTHX_ ctx);

    OUTPUT:
        RETVAL

unsigned
_count_pending_queries ( DNS__Unbound__Context* ctx )
    CODE:
        RETVAL = hv_iterinit(ctx->queries_hv);

    OUTPUT:
        RETVAL

#if HAS_UB_CANCEL
int
_ub_cancel( DNS__Unbound__Context* ctx, int async_id )
    CODE:
        int result = ub_cancel(ctx->ub_ctx, async_id);

        if (!result) {
            _unstore_query(aTHX_ ctx, async_id, NULL);
        }

        RETVAL = result;
    OUTPUT:
        RETVAL

#endif

int
_ub_fd( DNS__Unbound__Context* ctx )
    CODE:
        RETVAL = ub_fd(ctx->ub_ctx);
    OUTPUT:
        RETVAL

SV*
_resolve_async( DNS__Unbound__Context* ctx, SV *name_sv, int type, int class, SV *callback )
    CODE:
        char *name = exs_SvPVbyte_nolen(name_sv);

        int async_id = 0;

        SV* query_ctx_svrv = my_new_blessedstruct(dub_query_ctx_t, "DNS::Unbound::QueryContext");

        int reserr = ub_resolve_async(
            ctx->ub_ctx,
            name, type, class,
            (void *) query_ctx_svrv, _async_resolve_callback, &async_id
        );

        if (reserr) {
            SvREFCNT_dec(query_ctx_svrv);
        }
        else {
            _store_query(aTHX_ ctx, query_ctx_svrv, async_id, callback);
            _DEBUG("New query ID: %d", async_id);
        }

        AV *ret = newAV();
        av_extend(ret, 1);  // 2 elems - 1
        av_store( ret, 0, newSViv(reserr) );
        av_store( ret, 1, newSViv(async_id) );

        RETVAL = newRV_noinc((SV *)ret);
    OUTPUT:
        RETVAL

SV*
_resolve( DNS__Unbound__Context* ctx, SV *name, int type, int class = 1 )
    CODE:
        struct ub_result* result;
        int retval;

        retval = ub_resolve(ctx->ub_ctx, exs_SvPVbyte_nolen(name), type, class, &result);

        if (retval != 0) {
            RETVAL = newSViv(retval);
        }
        else {
            RETVAL = _ub_result_to_svhv_and_free(aTHX_ result);
        }

    OUTPUT:
        RETVAL

SV*
create()
    CODE:
        struct ub_ctx* my_ctx = ub_ctx_create();

        if (!my_ctx) {
            croak("Failed to create Unbound context!");
        }

        SV* dub_ctx_sv = my_new_blessedstruct(DNS__Unbound__Context, "DNS::Unbound::Context");

        DNS__Unbound__Context* dub_ctx = my_get_blessedstruct_ptr(dub_ctx_sv);

        *dub_ctx = _new_dub_context_struct(my_ctx);

        RETVAL = dub_ctx_sv;
    OUTPUT:
        RETVAL

void
DESTROY (DNS__Unbound__Context* dub_ctx)
    CODE:
        _DEBUG("%s", __func__);

        _decrement_dub_ctx_refcount(aTHX_ dub_ctx);

# ----------------------------------------------------------------------

MODULE = DNS::Unbound   PACKAGE = DNS::Unbound::QueryContext

void
DESTROY (SV* self_sv)
    CODE:
        _DEBUG("%s", __func__);

        dub_query_ctx_t* query_ctx = my_get_blessedstruct_ptr(self_sv);

        if ((getpid() == query_ctx->pid) && PL_dirty) {
            warn("Freeing %" SVf " at global destruction; memory leak likely!", self_sv);
        }
