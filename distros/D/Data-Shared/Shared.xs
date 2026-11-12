#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Each XSUB either completes the call exactly as its _pp_NAME in
   lib/Data/Shared.pm would, or hands that sub its untouched arguments
   before pushing anything. */

/* Data::Shared::Adapter::Keyed::FAST_* */
#define FAST_KEY_INT 1
#define FAST_ABSENT  2
#define FAST_INCR    4

#define V_GET    0
#define V_SET    1
#define V_DELETE 2
#define V_EXISTS 3
#define V_INCR   4
#define V_CALL   5
#define MUTATING(v) ((v) == V_SET || (v) == V_DELETE || (v) == V_INCR)

#define T_STRING   0
#define T_ARRAY    1
#define T_COMPILED 2

#define MAX_CALL_COMPONENTS 16

/* What a call borrows from a mount record or binding is held until the
   caller's statement ends: the callee may unmount the very mount it runs on. */
#define HOLD(sv) sv_2mortal(SvREFCNT_inc_simple_NN((SV *)(sv)))

static const char *const VERB_NAME[] = { "get", "set", "delete", "exists", "incr" };
static const I32 VERB_LEN[] = { 3, 3, 6, 6, 4 };

static const char *const SLOW[3][6] = {
    { "Data::Shared::_pp_shared_get", "Data::Shared::_pp_shared_set",
      "Data::Shared::_pp_shared_delete", "Data::Shared::_pp_shared_exists",
      "Data::Shared::_pp_shared_incr", "Data::Shared::_pp_shared_call" },
    { "Data::Shared::_pp_shareda_get", "Data::Shared::_pp_shareda_set",
      "Data::Shared::_pp_shareda_delete", "Data::Shared::_pp_shareda_exists",
      "Data::Shared::_pp_shareda_incr", "Data::Shared::_pp_shareda_call" },
    { "Data::Shared::_pp_sharedc_get", "Data::Shared::_pp_sharedc_set",
      "Data::Shared::_pp_sharedc_delete", "Data::Shared::_pp_sharedc_exists",
      "Data::Shared::_pp_sharedc_incr", "Data::Shared::_pp_sharedc_call" },
};

/* Calls the Perl implementation with this XSUB's own arguments, in the
   caller's context; its results land where this XSUB's arguments were. */
static I32 slow_path(pTHX_ int tier, int verb, I32 ax, I32 items, I32 gimme)
{
    SV **sp = PL_stack_base + ax - 1;
    CV *slow = get_cv(SLOW[tier][verb], 0);
    if (!slow)
        croak("Data::Shared: %s is missing", SLOW[tier][verb]);
    PUSHMARK(sp);
    sp += items;
    PUTBACK;
    return call_sv((SV *)slow, gimme);
}

static HV *hv_of(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV ? (HV *)SvRV(sv) : NULL;
}

/* Not SvRMAGICAL alone: a weak reference to a container gives it backref
   magic, and the compiled bindings hold exactly such references. */
#define TIED(sv) (SvRMAGICAL(sv) && mg_find((SV *)(sv), PERL_MAGIC_tied))

static AV *av_of(pTHX_ SV *sv)
{
    AV *av;
    if (!sv || SvGMAGICAL(sv) || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
        return NULL;
    av = (AV *)SvRV(sv);
    return TIED(av) ? NULL : av;
}

static CV *cv_of(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV ? (CV *)SvRV(sv) : NULL;
}

static HV *object_hv(pTHX_ SV *sv, const char *class, STRLEN len)
{
    SV *obj;
    HEK *name;
    if (SvGMAGICAL(sv) || !SvROK(sv))
        return NULL;
    obj = SvRV(sv);
    if (SvTYPE(obj) != SVt_PVHV || !SvOBJECT(obj) || TIED(obj))
        return NULL;
    name = SvSTASH(obj) ? HvNAME_HEK(SvSTASH(obj)) : NULL;
    if (!name || (STRLEN)HEK_LEN(name) != len || memNE(HEK_KEY(name), class, len))
        return NULL;
    return (HV *)obj;
}

#define root_hv(sv)     object_hv(aTHX_ (sv), "Data::Shared", 12)
#define compiled_hv(sv) object_hv(aTHX_ (sv), "Data::Shared::Compiled", 22)

static SV *fetch(pTHX_ HV *hv, const char *key, I32 klen)
{
    SV **svp = hv_fetch(hv, key, klen, 0);
    return svp ? *svp : NULL;
}

static int truthy(pTHX_ SV *sv)
{
    return sv && SvTRUE(sv);
}

static int plain_string(SV *sv)
{
    return sv && SvPOK(sv) && !SvGMAGICAL(sv);
}

/* _parse_string_path: the maximal runs of non-'/' bytes. -1 past max. */
static int split_path(const char *p, STRLEN len, const char **at, STRLEN *size, int max)
{
    const char *end = p + len;
    int n = 0;
    while (p < end) {
        const char *s;
        while (p < end && *p == '/')
            p++;
        if (p >= end)
            break;
        s = p;
        while (p < end && *p != '/')
            p++;
        if (n == max)
            return -1;
        at[n] = s;
        size[n] = (STRLEN)(p - s);
        n++;
    }
    return n;
}

/* Registry's \A-?[0-9]+\z on the value Perl would match: 1 or 0, or -1 when
   only Perl can tell (a float, a reference, magic). */
static int index_shape(pTHX_ SV *sv)
{
    if (SvGMAGICAL(sv) || SvROK(sv))
        return -1;
    if (SvPOK(sv)) {
        STRLEN len, i = 0;
        const char *p = SvPVX_const(sv);
        len = SvCUR(sv);
        if (len && p[0] == '-')
            i = 1;
        if (i >= len)
            return 0;
        for (; i < len; i++)
            if (p[i] < '0' || p[i] > '9')
                return 0;
        return 1;
    }
    if (SvIOK(sv) && !SvNOK(sv))
        return 1;
    return -1;
}

static int args_plain(pTHX_ I32 ax, I32 from, I32 items)
{
    I32 i;
    for (i = from; i < items; i++)
        if (SvGMAGICAL(ST(i)))
            return 0;
    return 1;
}

static HV *flat_mount(pTHX_ HV *root, const char *name, STRLEN len, int utf8, int mutating)
{
    HV *mounts, *m;
    if (mutating && truthy(aTHX_ fetch(aTHX_ root, "readonly", 8)))
        return NULL;
    if (truthy(aTHX_ fetch(aTHX_ root, "_nest_depth", 11)))
        return NULL;
    if (!(mounts = hv_of(fetch(aTHX_ root, "mounts", 6))))
        return NULL;
    m = hv_of(fetch(aTHX_ mounts, name, utf8 ? -(I32)len : (I32)len));
    if (!m || truthy(aTHX_ fetch(aTHX_ m, "composite", 9)))
        return NULL;
    return m;
}

/* Moves count results from the top of the stack to ST(0), copying any the
   callee still owns, as returning through a Perl sub would. */
static I32 settle(pTHX_ I32 ax, I32 count)
{
    /* An index, not a pointer: a copy's get-magic may grow the stack. */
    I32 from = (I32)(PL_stack_sp - PL_stack_base) - count + 1, i;
    for (i = 0; i < count; i++) {
        SV *r = PL_stack_base[from + i];
        if (!SvTEMP(r) && !SvIMMORTAL(r))
            r = sv_mortalcopy(r);
        ST(i) = r;
    }
    return count;
}

static I32 settle_bool(pTHX_ I32 ax, I32 count)
{
    SV *r = count ? *PL_stack_sp : &PL_sv_undef;
    ST(0) = sv_2mortal(newSViv(SvTRUE(r) ? 1 : 0));
    return 1;
}

/* Keyed::make_verb's closure for one key, from a fast_verb descriptor
   [handle, code, by, flags]: the result count at ST(0), or -1 before
   anything was pushed when the Perl path has to decide. */
static I32 run_desc(pTHX_ AV *desc, SV *key, int verb, I32 ax, I32 from, I32 items, I32 gimme)
{
    SV **d, *handle;
    CV *code, *by;
    IV flags;
    I32 nargs = items - from, i, count;
    if (AvFILLp(desc) < 3 || !args_plain(aTHX_ ax, from, items))
        return -1;
    d = AvARRAY(desc);
    handle = d[0];
    code = cv_of(d[1]);
    by = cv_of(d[2]);
    flags = d[3] ? SvIV(d[3]) : 0;
    if (!handle || !code)
        return -1;
    if ((flags & FAST_KEY_INT) && (verb != V_EXISTS || (flags & FAST_ABSENT))) {
        int shape = index_shape(aTHX_ key);
        if (shape < 0)
            return -1;
        if (!shape) {
            if (verb != V_EXISTS)
                return -1;
            ST(0) = sv_2mortal(newSViv(0));
            return 1;
        }
    }
    if ((flags & FAST_INCR) && nargs > 0) {
        if (!SvOK(ST(from)))
            return -1;
        if (by) {
            code = by;
            nargs = 1;
        }
    }
    HOLD(code);
    {
        dSP;
        PUSHMARK(SP);
        EXTEND(SP, 2 + nargs);
        PUSHs(HOLD(handle));
        PUSHs(HOLD(key));
        for (i = 0; i < nargs; i++)
            PUSHs(sv_mortalcopy(ST(from + i)));
        PUTBACK;
    }
    if (verb == V_EXISTS)
        return settle_bool(aTHX_ ax, call_sv((SV *)code, G_SCALAR));
    count = call_sv((SV *)code, gimme);
    return settle(aTHX_ ax, count);
}

static I32 call_with(pTHX_ CV *code, I32 ax, I32 from, I32 items, I32 gimme, int boolean)
{
    I32 i;
    dSP;
    HOLD(code);
    PUSHMARK(SP);
    EXTEND(SP, items - from);
    for (i = from; i < items; i++)
        PUSHs(ST(i));
    PUTBACK;
    if (boolean)
        return settle_bool(aTHX_ ax, call_sv((SV *)code, G_SCALAR));
    return settle(aTHX_ ax, call_sv((SV *)code, gimme));
}

static AV *fast_desc(pTHX_ HV *m, int verb)
{
    HV *fast = hv_of(fetch(aTHX_ m, "fast", 4));
    return fast ? av_of(aTHX_ fetch(aTHX_ fast, VERB_NAME[verb], VERB_LEN[verb])) : NULL;
}

/* A compiled binding [gen, bound, root, desc, key] still live for root. */
static AV *live_binding(pTHX_ SV *rootref, SV *cpref, const char *key, I32 klen)
{
    HV *cp, *bc, *root;
    AV *entry;
    SV **e, *gen;
    if (!SvROK(rootref) || !(cp = compiled_hv(cpref)))
        return NULL;
    if (!(bc = hv_of(fetch(aTHX_ cp, "_bc", 3))))
        return NULL;
    if (!(entry = av_of(aTHX_ fetch(aTHX_ bc, key, klen))) || AvFILLp(entry) < 2)
        return NULL;
    e = AvARRAY(entry);
    if (!e[2] || !SvROK(e[2]) || SvRV(e[2]) != SvRV(rootref))
        return NULL;
    if (!(root = hv_of(rootref)) || TIED(root))
        return NULL;
    gen = fetch(aTHX_ root, "gen", 3);
    if (!gen || !e[0] || SvGMAGICAL(gen) || SvIV(gen) != SvIV(e[0]))
        return NULL;
    return entry;
}

XS(xs_string_verb)
{
    dXSARGS;
    dXSI32;
    int verb = ix;
    I32 gimme = GIMME_V;
    HV *root, *m;
    AV *desc;
    SV *path, *key;
    const char *at[2];
    STRLEN size[2];
    I32 n;
    if (items < 2 || !(root = root_hv(ST(0))))
        goto slow;
    path = ST(1);
    if (!plain_string(path))
        goto slow;
    if (split_path(SvPVX_const(path), SvCUR(path), at, size, 2) != 2)
        goto slow;
    m = flat_mount(aTHX_ root, at[0], size[0], SvUTF8(path), MUTATING(verb));
    if (!m || !(desc = fast_desc(aTHX_ m, verb)))
        goto slow;
    key = newSVpvn_flags(at[1], size[1], SVs_TEMP | (SvUTF8(path) ? SVf_UTF8 : 0));
    n = run_desc(aTHX_ desc, key, verb, ax, 2, items, G_SCALAR);
    if (n >= 0)
        XSRETURN(n);
  slow:
    XSRETURN(slow_path(aTHX_ T_STRING, verb, ax, items, gimme));
}

XS(xs_array_verb)
{
    dXSARGS;
    dXSI32;
    int verb = ix;
    I32 gimme = GIMME_V;
    HV *root, *m;
    AV *path, *desc;
    SV *c0, *c1;
    I32 n;
    if (items < 2 || !(root = root_hv(ST(0))))
        goto slow;
    if (!(path = av_of(aTHX_ ST(1))) || SvOBJECT(path) || AvFILLp(path) != 1)
        goto slow;
    c0 = AvARRAY(path)[0];
    c1 = AvARRAY(path)[1];
    if (!plain_string(c0) || !c1 || SvGMAGICAL(c1) || SvROK(c1) || !SvOK(c1))
        goto slow;
    m = flat_mount(aTHX_ root, SvPVX_const(c0), SvCUR(c0), SvUTF8(c0), MUTATING(verb));
    if (!m || !(desc = fast_desc(aTHX_ m, verb)))
        goto slow;
    n = run_desc(aTHX_ desc, sv_mortalcopy(c1), verb, ax, 2, items, G_SCALAR);
    if (n >= 0)
        XSRETURN(n);
  slow:
    XSRETURN(slow_path(aTHX_ T_ARRAY, verb, ax, items, gimme));
}

XS(xs_compiled_verb)
{
    dXSARGS;
    dXSI32;
    int verb = ix;
    I32 gimme = GIMME_V;
    AV *entry, *desc;
    SV **e;
    CV *bound;
    I32 n;
    /* A subclass root goes to Perl, whose binding check compares with ==. */
    if (items < 2 || !root_hv(ST(0)))
        goto slow;
    if (!(entry = live_binding(aTHX_ ST(0), ST(1), VERB_NAME[verb], VERB_LEN[verb])))
        goto slow;
    if (MUTATING(verb) && truthy(aTHX_ fetch(aTHX_ (HV *)SvRV(ST(0)), "readonly", 8)))
        goto slow;
    e = AvARRAY(entry);
    if (AvFILLp(entry) >= 4 && (desc = av_of(aTHX_ e[3])) && e[4]) {
        n = run_desc(aTHX_ desc, e[4], verb, ax, 2, items, gimme);
        if (n >= 0)
            XSRETURN(n);
        goto slow;
    }
    if (!(bound = cv_of(e[1])))
        goto slow;
    XSRETURN(call_with(aTHX_ bound, ax, 2, items, gimme, verb == V_EXISTS));
  slow:
    XSRETURN(slow_path(aTHX_ T_COMPILED, verb, ax, items, gimme));
}

/* A method name the Perl path would pass straight through to can(). */
static int plain_method(pTHX_ SV *m)
{
    const char *p;
    STRLEN len;
    if (!plain_string(m) || !SvCUR(m))
        return 0;
    p = SvPVX_const(m);
    len = SvCUR(m);
    if (memchr(p, ':', len))
        return 0;
    return !(len == 6 && memEQ(p, "unlink", 6)) && !(len == 7 && memEQ(p, "destroy", 7))
        && !(len == 6 && memEQ(p, "freeze", 6));
}

/* _dispatch_record_call: handle->method(@rest, @args) through the can() cache. */
static I32 call_mount(pTHX_ HV *m, SV *method, SV **rest, I32 nrest, I32 ax, I32 items, I32 gimme)
{
    HV *can;
    CV *code;
    SV *handle;
    I32 i;
    if (!(can = hv_of(fetch(aTHX_ m, "can", 3))))
        return -1;
    code = cv_of(fetch(aTHX_ can, SvPVX_const(method),
        SvUTF8(method) ? -(I32)SvCUR(method) : (I32)SvCUR(method)));
    handle = fetch(aTHX_ m, "handle", 6);
    if (!code || !handle || !args_plain(aTHX_ ax, 3, items))
        return -1;
    HOLD(code);
    {
        dSP;
        PUSHMARK(SP);
        EXTEND(SP, 1 + nrest + items - 3);
        /* A copy, as Perl's lexical $handle is: the invocant must not alias
           the mount record's slot. */
        PUSHs(sv_mortalcopy(handle));
        for (i = 0; i < nrest; i++)
            PUSHs(rest[i]);
        for (i = 3; i < items; i++)
            PUSHs(sv_mortalcopy(ST(i)));
        PUTBACK;
    }
    return settle(aTHX_ ax, call_sv((SV *)code, gimme));
}

XS(xs_string_call)
{
    dXSARGS;
    I32 gimme = GIMME_V;
    HV *root, *m;
    SV *path, *rest[MAX_CALL_COMPONENTS];
    const char *at[MAX_CALL_COMPONENTS + 1];
    STRLEN size[MAX_CALL_COMPONENTS + 1];
    int n, i, utf8;
    I32 r;
    if (items < 3 || !(root = root_hv(ST(0))) || !plain_method(aTHX_ ST(2)))
        goto slow;
    path = ST(1);
    if (!plain_string(path))
        goto slow;
    n = split_path(SvPVX_const(path), SvCUR(path), at, size, MAX_CALL_COMPONENTS + 1);
    if (n < 1)
        goto slow;
    utf8 = SvUTF8(path) ? 1 : 0;
    if (!(m = flat_mount(aTHX_ root, at[0], size[0], utf8, 0)))
        goto slow;
    for (i = 1; i < n; i++)
        rest[i - 1] = newSVpvn_flags(at[i], size[i], SVs_TEMP | (utf8 ? SVf_UTF8 : 0));
    r = call_mount(aTHX_ m, ST(2), rest, n - 1, ax, items, gimme);
    if (r >= 0)
        XSRETURN(r);
  slow:
    XSRETURN(slow_path(aTHX_ T_STRING, V_CALL, ax, items, gimme));
}

XS(xs_array_call)
{
    dXSARGS;
    I32 gimme = GIMME_V;
    HV *root, *m;
    AV *path;
    SV *c0, *rest[MAX_CALL_COMPONENTS];
    I32 n, i, r;
    if (items < 3 || !(root = root_hv(ST(0))) || !plain_method(aTHX_ ST(2)))
        goto slow;
    if (!(path = av_of(aTHX_ ST(1))) || SvOBJECT(path))
        goto slow;
    n = AvFILLp(path) + 1;
    if (n < 1 || n > MAX_CALL_COMPONENTS + 1)
        goto slow;
    c0 = AvARRAY(path)[0];
    if (!plain_string(c0))
        goto slow;
    for (i = 1; i < n; i++) {
        SV *c = AvARRAY(path)[i];
        if (!c || SvGMAGICAL(c) || SvROK(c) || !SvOK(c))
            goto slow;
    }
    if (!(m = flat_mount(aTHX_ root, SvPVX_const(c0), SvCUR(c0), SvUTF8(c0), 0)))
        goto slow;
    for (i = 1; i < n; i++)
        rest[i - 1] = sv_mortalcopy(AvARRAY(path)[i]);
    r = call_mount(aTHX_ m, ST(2), rest, n - 1, ax, items, gimme);
    if (r >= 0)
        XSRETURN(r);
  slow:
    XSRETURN(slow_path(aTHX_ T_ARRAY, V_CALL, ax, items, gimme));
}

XS(xs_compiled_call)
{
    dXSARGS;
    I32 gimme = GIMME_V;
    AV *entry;
    CV *bound;
    SV *m;
    char key[256];
    STRLEN len;
    /* Perl copies the arguments before it picks the binding; a tied one may
       retire that binding when fetched. */
    if (items < 3 || !root_hv(ST(0)) || !plain_method(aTHX_ (m = ST(2)))
        || !args_plain(aTHX_ ax, 3, items))
        goto slow;
    len = SvCUR(m);
    if (len > sizeof key - 5)
        goto slow;
    memcpy(key, "call:", 5);
    memcpy(key + 5, SvPVX_const(m), len);
    if (!(entry = live_binding(aTHX_ ST(0), ST(1), key,
            SvUTF8(m) ? -(I32)(len + 5) : (I32)(len + 5))))
        goto slow;
    if (!(bound = cv_of(AvARRAY(entry)[1])))
        goto slow;
    XSRETURN(call_with(aTHX_ bound, ax, 3, items, gimme, 0));
  slow:
    XSRETURN(slow_path(aTHX_ T_COMPILED, V_CALL, ax, items, gimme));
}

MODULE = Data::Shared    PACKAGE = Data::Shared

PROTOTYPES: DISABLE

BOOT:
{
    static const char *const names[3][5] = {
        { "Data::Shared::shared_get", "Data::Shared::shared_set", "Data::Shared::shared_delete",
          "Data::Shared::shared_exists", "Data::Shared::shared_incr" },
        { "Data::Shared::shareda_get", "Data::Shared::shareda_set", "Data::Shared::shareda_delete",
          "Data::Shared::shareda_exists", "Data::Shared::shareda_incr" },
        { "Data::Shared::sharedc_get", "Data::Shared::sharedc_set", "Data::Shared::sharedc_delete",
          "Data::Shared::sharedc_exists", "Data::Shared::sharedc_incr" },
    };
    XSUBADDR_t verb_xs[3] = { xs_string_verb, xs_array_verb, xs_compiled_verb };
    int t, v;
    for (t = 0; t < 3; t++)
        for (v = 0; v < 5; v++)
            CvXSUBANY(newXS(names[t][v], verb_xs[t], __FILE__)).any_i32 = v;
    newXS("Data::Shared::shared_call", xs_string_call, __FILE__);
    newXS("Data::Shared::shareda_call", xs_array_call, __FILE__);
    newXS("Data::Shared::sharedc_call", xs_compiled_call, __FILE__);
}
