#ifndef PERL_COUCHBASE_H_
#define PERL_COUCHBASE_H_
#define NO_XSLOCKS

#include <sys/types.h> /*for size_t*/
#include <libcouchbase/couchbase.h>
#include <libcouchbase/api3.h>
#include <libcouchbase/n1ql.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define PLCB_BKT_CLASSNAME "Couchbase::Bucket"
#define PLCB_RET_CLASSNAME "Couchbase::Document"
#define PLCB_OPCTX_CLASSNAME "Couchbase::OpContext"
#define PLCB_PUB_CONSTANTS_PKG "Couchbase::Constants"
#define PLCB_PRIV_CONSTANTS_PKG "Couchbase::_GlueConstants"
#define PLCB_OBS_PLHELPER "Couchbase::Bucket::__obshelper"
#define PLCB_STATS_PLHELPER "Couchbase::Bucket::__statshelper"
#define PLCB_EVENT_CLASS "Couchbase::IO::Event"
#define PLCB_IOPROCS_CLASS "Couchbase::IO"
#define PLCB_IOPROCS_CONSTANTS_CLASS "Couchbase::IO::Constants"
#define PLCB_VIEWHANDLE_CLASS "Couchbase::View::Handle"
#define PLCB_N1QLHANDLE_CLASS "Couchbase::N1QL::Handle"

#if IVSIZE >= 8
#define PLCB_PERL64
#endif
#include "plcb-util.h"

typedef struct PLCB_st PLCB_t;

enum {
    PLCB_CONVERTERS_CUSTOM = 1,
    PLCB_CONVERTERS_JSON,
    PLCB_CONVERTERS_STORABLE
};

enum {
    PLCB_SETTING_INT,
    PLCB_SETTING_UINT,
    PLCB_SETTING_U32,
    PLCB_SETTING_SIZE,
    PLCB_SETTING_STRING,
    PLCB_SETTING_TIMEOUT
};

enum {
    PLCB_CMD_GET,
    PLCB_CMD_GAT,
    PLCB_CMD_TOUCH,
    PLCB_CMD_LOCK,
    PLCB_CMD_SET,
    PLCB_CMD_ADD,
    PLCB_CMD_REPLACE,
    PLCB_CMD_COUNTER,
    PLCB_CMD_APPEND,
    PLCB_CMD_PREPEND,
    PLCB_CMD_REMOVE,
    PLCB_CMD_UNLOCK,
    PLCB_CMD_STATS,
    PLCB_CMD_KEYSTATS,
    PLCB_CMD_OBSERVE,
    PLCB_CMD_ENDURE,
    PLCB_CMD_HTTP
};

enum {
    PLCB_RETIDX_KEY = 0,
    PLCB_RETIDX_VALUE,
    PLCB_RETIDX_ERRNUM,
    PLCB_RETIDX_CAS,
    PLCB_RETIDX_OPTIONS,
    PLCB_RETIDX_EXP,
    PLCB_RETIDX_FMTSPEC,
    PLCB_RETIDX_CALLBACK,
    PLCB_RETIDX_MAX
};

#define PLCB_HTIDX_STATUS PLCB_RETIDX_CAS
#define PLCB_HTIDX_HEADERS PLCB_RETIDX_EXP

enum {
    PLCB_VHIDX_PATH     = PLCB_RETIDX_KEY,
    PLCB_VHIDX_RC       = PLCB_RETIDX_ERRNUM,
    PLCB_VHIDX_ROWBUF   = PLCB_RETIDX_VALUE,
    PLCB_VHIDX_PARENT   = PLCB_RETIDX_CAS,
    PLCB_VHIDX_PLPRIV   = PLCB_RETIDX_FMTSPEC,
    PLCB_VHIDX_PRIVCB   = PLCB_RETIDX_MAX,
    PLCB_VHIDX_META,
    PLCB_VHIDX_RAWROWS,
    PLCB_VHIDX_ISDONE,
    PLCB_VHIDX_HTCODE,
    PLCB_VHIDX_SELFREF,
    PLCB_VHIDX_VHANDLE,
    PLCB_VHIDX_MAX
};

enum {
    PLCB_OPCTXIDX_FLAGS = 0,
    PLCB_OPCTXIDX_CBO,
    PLCB_OPCTXIDX_REMAINING,
    PLCB_OPCTXIDX_QUEUE,
    PLCB_OPCTXIDX_EXTRA
};

enum {
    PLCB_LF_JSON = 0x00,
    PLCB_LF_STORABLE = 0x01 << 3,
    PLCB_LF_RAW = 0x03 << 3,
    PLCB_LF_UTF8 = 0x04 << 3,
    PLCB_LF_MASK = 0xFF,

    PLCB_CF_NONE,
    PLCB_CF_PRIVATE = 0x01 << 24,
    PLCB_CF_STORABLE = PLCB_CF_PRIVATE,

    PLCB_CF_JSON = 0x02 << 24,
    PLCB_CF_RAW = 0x03 << 24,
    PLCB_CF_UTF8 = 0x04 << 24,
    PLCB_CF_MASK = 0xFF << 24
};

enum {
    PLCB_EVIDX_FD,
    PLCB_EVIDX_DUPFH,
    PLCB_EVIDX_WATCHFLAGS,
    PLCB_EVIDX_OPAQUE,
    PLCB_EVIDX_PLDATA,
    PLCB_EVIDX_TYPE,
    PLCB_EVIDX_MAX
};

/*various types of actions which may be taken by the callback*/
enum {
    PLCB_EVACTION_WATCH,
    PLCB_EVACTION_UNWATCH,
    PLCB_EVACTION_INIT,
    PLCB_EVACTION_CLEANUP
};

enum {
    PLCB_EVTYPE_IO,
    PLCB_EVTYPE_TIMER
};

struct PLCB_st {
    lcb_t instance; /*our library handle*/
    HV *ret_stash; /*stash with which we bless our return objects*/
    HV *view_stash;
    HV *n1ql_stash;
    HV *design_stash;
    HV *handle_av_stash;
    HV *opctx_sync_stash;
    HV *opctx_cb_stash;

    int connected;
    int wait_for_kv; /* Awaiting KV completion */
    int wait_for_views; /* Awaiting views completion */
    
    SV *cv_serialize;
    SV *cv_deserialize;
    SV *cv_jsonenc;
    SV *cv_jsondec;
    SV *cv_customenc;
    SV *cv_customdec;

    SV *curctx;
    SV *cachectx;
    SV *selfobj;
    SV *ioprocs;
    SV *udata;
    SV *conncb;

    /*how many operations are pending on this object*/
    int npending;
    int async;
};

#define plcb_kv_wait(obj) do { \
    (obj)->wait_for_kv = 1; \
    lcb_wait3((obj)->instance, LCB_WAIT_NOCHECK); \
} while (0);

#define plcb_views_wait(obj) do { \
    (obj)->wait_for_views = 1; \
    lcb_wait3((obj)->instance, LCB_WAIT_NOCHECK); \
} while (0);

#define plcb_kv_waitdone(obj) do { \
    (obj)->wait_for_kv = 0; \
    plcb_evloop_wait_unref(obj); \
} while (0);

#define plcb_views_waitdone(obj) do { \
    (obj)->wait_for_views = 0; \
    plcb_evloop_wait_unref(obj); \
} while (0);

typedef struct {
    unsigned nremaining;
    unsigned flags;
    int waiting;
    HV *docs;
    SV *parent; /* PLCB_T */
    lcb_MULTICMD_CTX *multi;
    union {
        SV *callback; /* For async only */
        AV *ctxqueue; /* For queued operations */
    } u;
} plcb_OPCTX;

typedef struct {
    int cmdbase; /* Effective command passed, without flags or modifiers */
    PLCB_t *parent;
    AV *docav; /* The document */
    SV *opctx; /* The context */
    SV *cmdopts; /* Command options */
    SV *docrv; /* Reference for the document */
    void *cookie;
    plcb_OPCTX *ctxptr;
} plcb_SINGLEOP;

/* Temporary structure used for encoding/storing values */
typedef struct {
    SV *value;
    uint32_t flags;
    uint32_t spec;
    short need_free;
    const char *encoded;
    size_t len;
} plcb_DOCVAL;

#define PLCB_OPCTXf_IMPLICIT 0x01
#define PLCB_OPCTXf_CALLEACH 0x02
#define PLCB_OPCTXf_CALLDONE 0x04
#define PLCB_OPCTXf_WAITONE 0x08

/*need to include this after defining PLCB_t*/
#include "plcb-return.h"
#include "plcb-args.h"

void plcb_callbacks_setup(PLCB_t *object);

/*options for common constructor settings*/
void plcb_ctor_cbc_opts(AV *options, struct lcb_create_st *cropts);
void plcb_ctor_conversion_opts(PLCB_t *object, AV *options);
void plcb_ctor_init_common(PLCB_t *object, lcb_t instance, AV *options);

/*cleanup functions*/
void plcb_cleanup(PLCB_t *object);

/*conversion functions*/
void
plcb_convert_storage(PLCB_t* object, AV *doc, plcb_DOCVAL *vspec);

void plcb_convert_storage_free(PLCB_t *object, plcb_DOCVAL *vspec);

/* Do not fall back to "Custom" encoders */
#define PLCB_CONVERT_NOCUSTOM 1
SV*
plcb_convert_retrieval_ex(PLCB_t *object,
    AV *doc, const char *data, size_t data_len, uint32_t flags, int options);

#define plcb_convert_retrieval(obj, doc, data, len, flags) \
    plcb_convert_retrieval_ex(obj, doc, data, len, flags, 0)
#define plcb_convert_getresp(obj, doc, resp) \
    plcb_convert_retrieval(\
        obj, doc, (resp)->value, (resp)->nvalue, (resp)->itmflags)

/**
 * This function decrements the wait count by one, and possibly calls stop_event_loop
 * if the reference count has hit 0.
 */
void plcb_evloop_wait_unref(PLCB_t *obj);

/**
 * Returns a new blessed operation context, also makes it the current
 * context
 */
SV *plcb_opctx_new(PLCB_t *, int);
void plcb_opctx_clear(PLCB_t *parent);
void plcb_opctx_initop(plcb_SINGLEOP *so, PLCB_t *parent, SV *doc, SV *ctx, SV *options);
SV * plcb_opctx_return(plcb_SINGLEOP *so, lcb_error_t err);
void plcb_opctx_submit(PLCB_t *parent, plcb_OPCTX *ctx);

#define plcb_opctx_is_cmd_multi(cmd) \
    ((cmd) == PLCB_CMD_OBSERVE || (cmd) == PLCB_CMD_STATS)

/** Operation functions */
SV *PLCB_op_get(PLCB_t*,plcb_SINGLEOP*);
SV *PLCB_op_set(PLCB_t*,plcb_SINGLEOP*);
SV* PLCB_op_counter(PLCB_t *object, plcb_SINGLEOP *opinfo);
SV *PLCB_op_remove(PLCB_t*,plcb_SINGLEOP*);
SV *PLCB_op_observe(PLCB_t *object, plcb_SINGLEOP *args);
SV *PLCB_op_endure(PLCB_t *object, plcb_SINGLEOP *args);
SV *PLCB_op_unlock(PLCB_t *object, plcb_SINGLEOP *args);
SV *PLCB_op_stats(PLCB_t *object, plcb_SINGLEOP *args);
SV *PLCB_op_observe(PLCB_t *object, plcb_SINGLEOP *args);
SV *PLCB_op_endure(PLCB_t *object, plcb_SINGLEOP *opinfo);
SV* PLCB_op_http(PLCB_t *object, plcb_SINGLEOP *opinfo);

SV *
PLCB_args_return(plcb_SINGLEOP *so, lcb_error_t err);

void plcb_define_constants(void);

typedef struct plcb_EVENT_st plcb_EVENT;
struct plcb_EVENT_st {
    /* Corresponding Perl event object */
    AV *pl_event;
    SV *rv_event;

    int evtype;
    lcb_ioE_callback lcb_handler;
    void *lcb_arg;
    short flags;

    /*FD from libcouchbase*/
    lcb_socket_t fd;
    lcb_io_opt_t ioptr;
};

/*our base object*/
typedef struct {
    lcb_io_opt_t iops_ptr;
    SV *userdata;
    SV *action_sv;
    SV *flags_sv;
    SV *usec_sv;
    SV *sched_r_sv;
    SV *sched_w_sv;
    SV *stop_r_sv;
    SV *stop_w_sv;

    SV *selfrv;
    SV *cv_evmod; /* Modify an event */
    SV *cv_timermod; /* Modify a timer */
    SV *cv_evinit;
    SV *cv_evclean;
    SV *cv_tminit;
    SV *cv_tmclean;
    int refcount;
} plcb_IOPROCS;

#define PLCB_READ_EVENT LCB_READ_EVENT
#define PLCB_WRITE_EVENT LCB_WRITE_EVENT

SV * PLCB_ioprocs_new(SV *options);
void PLCB_ioprocs_dtor(lcb_io_opt_t cbcio);

SV *
PLCB__viewhandle_new(PLCB_t *parent,
    const char *ddoc, const char *view, const char *options, int flags);

void
PLCB__viewhandle_fetch(SV *pp);

void
PLCB__viewhandle_stop(SV *pp);

SV *
PLCB__n1qlhandle_new(PLCB_t *parent, lcb_N1QLPARAMS *params, const char *host);

/* Declare these ahead of time */
XS(boot_Couchbase__BucketConfig);
XS(boot_Couchbase__IO);
XS(boot_Couchbase__N1QL__Params);

#endif /* PERL_COUCHBASE_H_ */
