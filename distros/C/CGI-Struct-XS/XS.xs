#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <string.h>

#define CONF_GET(conf, key, default)                    \
    ({                                                  \
        SV** val = hv_fetch(conf, key, strlen(key), 0); \
        val ? SvUV(*val) : (default);                   \
    })

#ifndef newSVpvn_utf8
#define newSVpvn_utf8(ptr, len, utf8)      \
    ({                                     \
        SV* copy = newSVpvn((ptr), (len)); \
        if (utf8) { SvUTF8_on(copy); }     \
        copy;                              \
    })
#endif

#define BUF_LEN 1024
#define STATE_MASK  0x00FF
#define ACTION_MASK 0xFF00
#define DBG(fmt, ...) if (opts->debug > 0) { fprintf(stderr, fmt, ##__VA_ARGS__); }
#define DUMP(s) do_sv_dump(0, Perl_debug_log, (s), 0, 1, 0, 0);

typedef struct opts {
    U32 nodot;
    U32 nullsplit;
    U32 dclone;
    U32 debug;
} Opts;

typedef enum input {
    I_DT = 0x00, // .
    I_LS = 0x01, // [
    I_RS = 0x02, // ]
    I_LC = 0x03, // {
    I_RC = 0x04, // }
    I_DI = 0x05, // 0-9 digit
    I_CH = 0x06, // any other char
    I_EN = 0x07  // fake end-of-line char
} Input;

typedef enum action {
    A_EC = 0x0200, // eat char
    A_ED = 0x0800, // eat digit
    A_CH = 0x1000, // create hash (vivify)
    A_CA = 0x2000, // create array (vivify)
    A_CV = 0x4000, // put scalar
    A_AA = 0x8000  // put scalar-or-array (auto-arrays)
} Action;

static Input classes[] = {
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_DT, I_CH,
    I_DI, I_DI, I_DI, I_DI, I_DI, I_DI, I_DI, I_DI,
    I_DI, I_DI, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_LS, I_CH, I_RS, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_LC, I_CH, I_RC, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH,
    I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH, I_CH
};

typedef enum state {
    S_FN = 0x00, // first char in normal key
    S_RN = 0x01, // reading normal key
    S_FK = 0x02, // first char of key inside {}
    S_RK = 0x03, // reading key inside {}
    S_FI = 0x04, // first digit of index inside [], checking auto-array
    S_RI = 0x05, // reading index inside []
    S_RC = 0x06, // reading controll . [ or {
    S_EN = 0x07, // end state
    S_E1 = 0x08, // error: delimeter not balanced
    S_E2 = 0x09, // error: index should be a number
    S_E3 = 0x0a, // error: zero-length key name 
    S_E4 = 0x0b, // error: unexpected controll char
    S_E5 = 0x0c, // error: type mismatch - array found
    S_E6 = 0x0d, // error: type mismatch - hash found
} State;

static U32 machine[][8] = {
/*          I_DT,         I_LS,         I_RS,       I_LC,         I_RC,         I_DI,       I_CH,       I_EN       
/*S_FN*/ {  S_E3,         S_E3,         S_E3,       S_E3,         S_E3,         S_RN|A_EC,  S_RN|A_EC,  S_E3      }, 
/*S_RN*/ {  S_FN|A_CH,    S_FI|A_CA,    S_RN|A_EC,  S_FK|A_CH,    S_RN|A_EC,    S_RN|A_EC,  S_RN|A_EC,  S_EN|A_CV },
/*S_FK*/ {  S_E1,         S_E1,         S_E1,       S_E1,         S_E3,         S_RK|A_EC,  S_RK|A_EC,  S_E1      },
/*S_RK*/ {  S_E1,         S_E1,         S_E1,       S_E1,         S_RC,         S_RK|A_EC,  S_RK|A_EC,  S_E1      },
/*S_FI*/ {  S_E2,         S_E1,         S_EN|A_AA,  S_E1,         S_E1,         S_RI|A_ED,  S_E2,       S_E1      },
/*S_RI*/ {  S_E2,         S_E1,         S_RC,       S_E1,         S_E1,         S_RI|A_ED,  S_E2,       S_E1      },
/*S_RC*/ {  S_FN|A_CH,    S_FI|A_CA,    S_E4,       S_FK|A_CH,    S_E4,         S_E4,       S_E4,       S_EN|A_CV }
};

static SV*
_dclone(SV* sv)
{
    I32 count;
    SV* res;
    dSP;
    if (!SvROK(sv)) {
        return sv_mortalcopy(sv);
    }
    PUSHMARK(SP);
    XPUSHs(sv);
    PUTBACK;
    count = call_pv("Storable::dclone", G_SCALAR);
    if (count != 1) {
        croak("Storable::dclone call failed\n");
    }
    SPAGAIN;
    res = POPs;
    PUTBACK;
    return res;
}

static SV*
_split(SV* val, Opts* opts)
{
    char* beg = SvPVX(val);
    char* end = SvEND(val);
    char* zer = (char*) memchr(beg, '\0', SvCUR(val));
    if (zer && zer < end) {
        AV* arr = newAV();
        do {
            av_push(arr, newSVpvn_utf8(beg, zer - beg, SvUTF8(val)));
            beg = zer + 1;
            zer = memchr(beg, '\0', end - beg);
        } while (zer && zer < end);
        if (beg <= end) {
            av_push(arr, newSVpvn_utf8(beg, end - beg, SvUTF8(val)));
        }
        val = newRV_noinc((SV*)arr);
        sv_2mortal(val);
    }
    return val;
}

static void
_copy_array(AV* tgt, AV* src)
{
    U32 i = 0;
    U32 l = av_len(src); // last index
    av_fill(tgt, l);
    for (i = 0; i <= l; i++) {
        // TODO: optimize copying
        SV** el = av_fetch(src, i, 0);
        if (el) { 
            SvREFCNT_inc(*el);
            av_store(tgt, i, *el);
        }
    }
}

static void
_store(void* ptr, const char* part_key, U32 part_klen, U32 part_idx, SV* val, Opts* opts)
{
    if (SvTYPE((SV*)ptr) == SVt_PVHV) {
        DBG("hv_store ptr %p part_key '%s' part_klen %u val %p (type %u)\n", ptr, part_key, part_klen, val, SvTYPE(val));
        hv_store((HV*)ptr, part_key, part_klen, val, 0);
    }
    else {
        DBG("av_store ptr %p part_idx %u val %p (type %u)\n", ptr, part_idx, val, SvTYPE(val));
        av_store((AV*)ptr, part_idx, val);
    }
}

static SV*
_next(void* ptr, const char* part_key, U32 part_klen, U32 part_idx, svtype type, Opts* opts)
{
    SV** ref_ptr;
    SV* next;
    if (SvTYPE((SV*)ptr) == SVt_PVHV) {
        ref_ptr = hv_fetch((HV*)ptr, part_key, part_klen, 0);
    }
    else {
        ref_ptr = av_fetch((AV*)ptr, part_idx, 0);
    }
    if (!ref_ptr) {
        next = type == SVt_PVHV ? (SV*)newHV() : (SV*)newAV();
        _store(ptr, part_key, part_klen, part_idx, newRV_noinc((SV*)next), opts);
    }
    else {
        if (SvROK(*ref_ptr) && SvTYPE(SvRV(*ref_ptr)) == type) {
            next = SvRV(*ref_ptr);
        }
        else {
            return NULL;
        }
    }
    return next;
}

static void 
_handle_pair(const unsigned char* key, U32 klen, SV* val, AV* err, Opts* opts, HV* ov)
{
    U32 pos = 0;
    U32 mv = 0;
    U32 ac = 0;
    Input inp = I_CH;
    State st = S_FN;

    U32 part_idx = 0;
    const unsigned char* part_key = key;
    U32 part_klen = 0;

    void* ptr = ov;

    DBG("key '%s' klen %u\n", key, klen);

    for (pos = 0; pos <= klen && st < S_EN; pos++) {
        DBG("chr %c %u\n", key[pos], key[pos]);
        DBG("class %u\n", classes[key[pos]]);
        
        inp = pos == klen ? I_EN : classes[key[pos]];
        if (inp == I_DT && opts->nodot) {
            inp = I_CH;
        }
        mv = machine[st][inp];
        DBG("st %u pos %u chr '%c(%u)' inp %u -> st %u\n", st, pos, key[pos], (int)key[pos], inp, mv & STATE_MASK);
        st = mv & STATE_MASK;
        ac = mv & ACTION_MASK;

        switch (ac) {
            case A_EC:
                part_klen++;
                break;
            case A_ED:
                part_idx = part_idx * 10 + key[pos] - '0';
                break;
            case A_CH:
                ptr = _next(ptr, part_key, part_klen, part_idx, SVt_PVHV, opts);
                if (!ptr) {
                    st = S_E5;
                }
                part_key = key + pos + 1; 
                part_klen = 0;
                part_idx = 0;
                break;
            case A_CA:
                ptr = _next(ptr, part_key, part_klen, part_idx, SVt_PVAV, opts);
                if (!ptr) {
                    st = S_E6;
                }
                part_key = key + pos + 1; 
                part_klen = 0;
                part_idx = 0;
                break;
            case A_CV:
                if (opts->nullsplit && SvPOK(val)) {
                    val = _split(val, opts);
                }
                SvREFCNT_inc(val);
                _store(ptr, part_key, part_klen, part_idx, val, opts);
                break;
            case A_AA:
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    _copy_array((AV*) ptr, (AV*) SvRV(val));
                }
                else {
                    SvREFCNT_inc(val);
                    _store(ptr, part_key, part_klen, part_idx, val, opts);
                }
                break;
        }
    }
    DBG("final state %u\n\n", st);

    // normal return
    if (st == S_EN) {
        return;
    }

    // error handling if needed
    if (err) {
        char msg[BUF_LEN];
        char* key_prefix = NULL;
        # define ERR(fmt, ...) snprintf(msg, sizeof(msg), fmt, ##__VA_ARGS__);
        switch (st) {
            case S_EN:
                break;
            case S_E1:
                ERR("Not balanced delimiter for %s", key);
                break;
            case S_E2:
                ERR("Array index should be a number for %s", key);
                break;
            case S_E3:
                if (pos == 1) {
                    ERR("Unexpected initial char '%c' for %s", key[0], key);
                }
                else {
                    ERR("Zero-length key name for %s", key);
                }
                break;
            case S_E4:
                ERR("Delimeter expected at %s for %s", key + pos, key);
                break;
            case S_E5:
            case S_E6:
                key_prefix = (char*) malloc(pos);
                strncpy(key_prefix, key, pos - 1);
                key_prefix[pos-1] = '\0';
                ERR("Type mismatch: %s already used as %s for %s", key_prefix, (st == S_E5 ? "ArrayRef" : "HashRef"), key);
                free(key_prefix);
                break;
            default:
                ERR("Internal: unexpected final state %u for %s", st, key); 
                break;
        }
        # undef ERR
        av_push(err, newSVpv((msg), 0));
    }

    return;
}


MODULE = CGI::Struct::XS PACKAGE = CGI::Struct::XS

PROTOTYPES: DISABLE

HV*
build_cgi_struct(HV* iv, ...)
PREINIT:
    AV* err = NULL;
    HV* conf = NULL;
    Opts opts = { .nodot = 0, .nullsplit = 1, .dclone = 1, .debug = 0 };
    HE* pair = NULL;
    char* key = NULL;
    U32 klen = 0;
    SV* val = NULL;
CODE:
    /* prepare args */
    if (items > 1) {
        SV* const xsub_tmp_sv = ST(1);
        SvGETMAGIC(xsub_tmp_sv);
        if (SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVAV) {
            err = (AV*) SvRV(xsub_tmp_sv);
        }
    }
    if (items > 2) {
        SV* const xsub_tmp_sv = ST(2);
        SvGETMAGIC(xsub_tmp_sv);
        if (SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVHV) {
            conf = (HV*) SvRV(xsub_tmp_sv);
            opts.nodot = CONF_GET(conf, "nodot", opts.nodot);
            opts.nullsplit = CONF_GET(conf, "nullsplit", opts.nullsplit);
            opts.dclone = CONF_GET(conf, "dclone", opts.dclone);
            opts.debug = CONF_GET(conf, "debug", opts.debug);
        }
    }

    /* prepare output */
    RETVAL = newHV();
    sv_2mortal((SV*)RETVAL);
    
    /* main loop */
    hv_iterinit(iv);
    while (pair = hv_iternext(iv)) {
        key = hv_iterkey(pair, &klen);
        val = hv_iterval(iv, pair);
        if (opts.dclone) {
            val = _dclone(val);        
        }
        _handle_pair(key, klen, val, err, &opts, RETVAL);
    }
OUTPUT:
    RETVAL
