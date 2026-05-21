#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

/* Use stronger inline hint */
#ifndef PERL_STATIC_INLINE
#define PERL_STATIC_INLINE static inline
#endif

/* Magic signature for fast type checking (avoids sv_derived_from) */
#define COMPILED_PATH_MAGIC 0x44505853  /* "DPXS" */

/* Branch prediction hints */
#ifndef LIKELY
#  if defined(__GNUC__) || defined(__clang__)
#    define LIKELY(x)   __builtin_expect(!!(x), 1)
#    define UNLIKELY(x) __builtin_expect(!!(x), 0)
#  else
#    define LIKELY(x)   (x)
#    define UNLIKELY(x) (x)
#  endif
#endif

/* Max safe index digits to avoid IV overflow
 * 64-bit IV: max ~9e18 (19 digits), safe limit 18
 * 32-bit IV: max ~2e9 (10 digits), safe limit 9
 */
#if IVSIZE >= 8
#  define MAX_INDEX_DIGITS 18
#else
#  define MAX_INDEX_DIGITS 9
#endif

/* Path component - pre-parsed */
typedef struct {
    const char *str;
    STRLEN len;
    IV idx;             /* Pre-parsed array index (valid only if is_numeric) */
    int is_numeric;     /* 1 if component is a valid array index, 0 for hash key */
    int next_is_array;  /* 1 if next component is numeric (create array), 0 for hash */
} PathComponent;

/* Compiled path object - flexible array member for cache locality */
typedef struct {
    U32 magic;       /* COMPILED_PATH_MAGIC for fast type check */
    I32 utf8_flag;   /* +1 for byte path, -1 for UTF-8 path (signed klen factor) */
    SSize_t count;
    SV *path_sv;     /* Owned copy of path string buffer */
    PathComponent components[1];  /* Flexible array member (C89 style) */
} CompiledPath;

/* Fast compiled path validation - check ref, payload type, and magic.
 * sv_setref_pv produces an RV whose target is an IV-bearing SV; if not IOK,
 * input is not a compiled path. Checking SvIOK avoids "isn't numeric" warnings
 * from SvIV on bless'd hashes/arrays/garbage. */
#define VALIDATE_COMPILED_PATH(sv, cp) do { \
    SV *_inner; \
    if (UNLIKELY(!SvROK(sv) || !SvIOK(_inner = SvRV(sv)))) croak("Not a compiled path"); \
    cp = INT2PTR(CompiledPath*, SvIVX(_inner)); \
    if (UNLIKELY(!cp || cp->magic != COMPILED_PATH_MAGIC)) croak("Not a compiled path"); \
} while(0)

/* Check if string is a valid array index, parse it
 * Returns 0 for: empty, leading zeros, non-digits, overflow
 * Accepts negative indices (e.g., "-1" for last element)
 * Note: "-0" parses as 0 (single zero after minus is allowed)
 * Max safe index: we limit to MAX_INDEX_DIGITS digits to avoid IV overflow
 */
PERL_STATIC_INLINE int is_array_index(const char *s, STRLEN len, IV *idx) {
    IV val = 0;
    const char *end = s + len;
    int negative = 0;

    /* Length cap includes the optional leading minus sign. */
    if (UNLIKELY(len == 0 || len > (MAX_INDEX_DIGITS + 1))) return 0;

    if (*s == '-') {
        negative = 1;
        s++;
        len--;
        if (UNLIKELY(len == 0)) return 0;
    }

    if (UNLIKELY(len > MAX_INDEX_DIGITS)) return 0;
    if (len > 1 && *s == '0') return 0;  /* leading zeros => hash key */

    while (s < end) {
        if (UNLIKELY(*s < '0' || *s > '9')) return 0;
        val = val * 10 + (*s - '0');
        s++;
    }

    *idx = negative ? -val : val;
    return 1;
}

/* SvPV + SvUTF8 → signed klen (negative encodes UTF-8 to hv_*). */
PERL_STATIC_INLINE I32 sv_to_klen(pTHX_ SV *sv, const char **kstr_out) {
    STRLEN klen;
    *kstr_out = SvPV(sv, klen);
    return SvUTF8(sv) ? -(I32)klen : (I32)klen;
}

/* True iff p..end (after slash-skipping) has no further non-empty components. */
PERL_STATIC_INLINE int kw_at_last_component(const char *p, const char *end) {
    while (p < end && *p == '/') p++;
    return p >= end;
}

/* Fast SV to index - check IOK first, accept negative for Perl-style access */
PERL_STATIC_INLINE int sv_to_index(pTHX_ SV *sv, IV *idx) {
    if (SvIOK(sv)) {
        *idx = SvIVX(sv);
        return 1;
    }
    STRLEN len;
    const char *s = SvPV(sv, len);
    return is_array_index(s, len, idx);
}

/* Navigate using raw char* path components.
 * utf8_flag is +1 for byte keys, -1 for UTF-8 keys (signed klen convention). */
PERL_STATIC_INLINE SV* navigate_to_parent(pTHX_ SV *data, const char *path, STRLEN path_len,
                              const char **final_key_ptr, STRLEN *final_key_len,
                              int create, I32 utf8_flag) {
    const char *p = path;
    const char *end = path + path_len;
    SV *current = data;

    if (UNLIKELY(path_len == 0)) {
        *final_key_ptr = NULL;
        *final_key_len = 0;
        return data;
    }

    /* Skip leading slash if present (optional for consistency with keyword API) */
    if (*p == '/') p++;

    while (p < end) {
        const char *tok_start = p;
        while (p < end && *p != '/') p++;
        STRLEN tok_len = p - tok_start;

        /* Skip empty components (e.g., double slashes, trailing slashes) */
        if (UNLIKELY(tok_len == 0)) {
            p++;  /* Always advance to avoid infinite loop */
            continue;
        }

        /* Skip trailing slashes to check if this is the last real component */
        const char *check = p;
        while (check < end && *check == '/') check++;

        /* Last non-empty token - return parent */
        if (check >= end) {
            *final_key_ptr = tok_start;
            *final_key_len = tok_len;
            return current;
        }

        /* Navigate deeper */
        if (UNLIKELY(!SvROK(current))) {
            *final_key_ptr = NULL;
            return NULL;
        }

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            HV *hv = (HV*)inner;
            SV **val = hv_fetch(hv, tok_start, (I32)tok_len * utf8_flag, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                if (create) {
                    /* Tied/magical containers can't autovivify — hv_store
                     * returns NULL without invoking STORE. Croak with a
                     * useful message rather than the generic one above. */
                    if (UNLIKELY(SvRMAGICAL((SV*)hv))) {
                        croak("Cannot path_set on tied/magical hash");
                    }
                    /* check already points at next real component start */
                    const char *next_end = check;
                    while (next_end < end && *next_end != '/') next_end++;
                    IV dummy;
                    SV *new_ref = is_array_index(check, next_end - check, &dummy)
                        ? newRV_noinc((SV*)newAV())
                        : newRV_noinc((SV*)newHV());
                    if (UNLIKELY(!hv_store(hv, tok_start, (I32)tok_len * utf8_flag, new_ref, 0))) {
                        SvREFCNT_dec(new_ref);
                        *final_key_ptr = NULL;
                        return NULL;
                    }
                    current = new_ref;
                } else {
                    *final_key_ptr = NULL;
                    return NULL;
                }
            } else {
                current = *val;
            }
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!is_array_index(tok_start, tok_len, &idx))) {
                *final_key_ptr = NULL;
                return NULL;
            }
            SV **val = av_fetch((AV*)inner, idx, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                if (create) {
                    if (UNLIKELY(SvRMAGICAL((SV*)inner))) {
                        croak("Cannot path_set on tied/magical array");
                    }
                    const char *next_end = check;
                    while (next_end < end && *next_end != '/') next_end++;
                    IV dummy;
                    SV *new_ref = is_array_index(check, next_end - check, &dummy)
                        ? newRV_noinc((SV*)newAV())
                        : newRV_noinc((SV*)newHV());
                    if (UNLIKELY(!av_store((AV*)inner, idx, new_ref))) {
                        SvREFCNT_dec(new_ref);
                        *final_key_ptr = NULL;
                        return NULL;
                    }
                    current = new_ref;
                } else {
                    *final_key_ptr = NULL;
                    return NULL;
                }
            } else {
                current = *val;
            }
        } else {
            *final_key_ptr = NULL;
            return NULL;
        }

        p++;
    }

    *final_key_ptr = NULL;
    return current;
}

/* Compile a path string into reusable components */
static CompiledPath* compile_path(pTHX_ SV *path_sv) {
    STRLEN path_len;
    const char *path = SvPV(path_sv, path_len);
    CompiledPath *cp;
    SSize_t count = 0;
    const char *p;
    const char *path_end = path + path_len;

    /* Skip leading slash */
    const char *start = path;
    if (path_len > 0 && *start == '/') start++;

    /* Count non-empty components (skip double slashes) */
    p = start;
    while (p < path_end) {
        const char *tok_start = p;
        while (p < path_end && *p != '/') p++;
        if (p > tok_start) count++;
        if (p < path_end) p++;
    }

    /* Empty path, root path ("/"), or all-slashes ("///") */
    if (count == 0) {
        Newxz(cp, 1, CompiledPath);
        cp->magic = COMPILED_PATH_MAGIC;
        cp->utf8_flag = SvUTF8(path_sv) ? -1 : 1;
        cp->count = 0;
        cp->path_sv = newSVpvn_flags(path, path_len, SvUTF8(path_sv) ? SVf_UTF8 : 0);
        return cp;
    }

    /* Single alloc: base struct already has 1 inline component slot. */
    Size_t alloc_size = sizeof(CompiledPath) + (count - 1) * sizeof(PathComponent);
    Newxc(cp, alloc_size, char, CompiledPath);

    cp->magic = COMPILED_PATH_MAGIC;
    cp->utf8_flag = SvUTF8(path_sv) ? -1 : 1;
    cp->count = count;
    /* Create independent copy of path string so PathComponent pointers
     * remain valid even if the original SV's buffer is modified/freed */
    cp->path_sv = newSVpvn_flags(path, path_len, SvUTF8(path_sv) ? SVf_UTF8 : 0);

    /* Re-derive pointers into our own copy's buffer */
    const char *copy_buf = SvPVX(cp->path_sv);
    const char *copy_start = copy_buf + (start - path);
    const char *copy_end = copy_buf + path_len;

    /* Parse components directly into inline array, skipping empty ones */
    p = copy_start;
    SSize_t i = 0;
    while (p < copy_end && i < count) {
        const char *tok_start = p;
        while (p < copy_end && *p != '/') p++;
        STRLEN tok_len = p - tok_start;
        if (tok_len > 0) {
            cp->components[i].str = tok_start;
            cp->components[i].len = tok_len;
            cp->components[i].is_numeric = is_array_index(tok_start, tok_len, &cp->components[i].idx);
            cp->components[i].next_is_array = 0;  /* Will set below */
            i++;
        }
        if (p < copy_end) p++;  /* Skip slash */
    }

    /* Pre-compute next_is_array flag for faster creation */
    for (SSize_t j = 0; j < count - 1; j++) {
        cp->components[j].next_is_array = cp->components[j + 1].is_numeric;
    }
    cp->components[count - 1].next_is_array = 0;  /* Last element */

    return cp;
}

static void free_compiled_path(pTHX_ CompiledPath *cp) {
    if (cp) {
        SvREFCNT_dec(cp->path_sv);
        Safefree(cp);
    }
}

/* ========== KEYWORD SUPPORT ========== */

/* Custom ops for dynamic path access - runs directly in runloop */
static XOP xop_pathget;
static XOP xop_pathset;
static XOP xop_pathdelete;
static XOP xop_pathexists;

static OP* pp_pathget_dynamic(pTHX)
{
    dSP;
    SV *path_sv = POPs;
    SV *data_sv = POPs;

    STRLEN path_len;
    const char *path = SvPV(path_sv, path_len);
    const char *p = path;
    const char *end = path + path_len;
    const I32 utf8_flag = SvUTF8(path_sv) ? -1 : 1;

    SV *current = data_sv;

    /* Skip leading slashes */
    while (p < end && *p == '/') p++;

    while (p < end && SvOK(current)) {
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (UNLIKELY(comp_len == 0)) {
            if (p < end) p++;
            continue;
        }

        if (UNLIKELY(!SvROK(current))) {
            current = &PL_sv_undef;
            break;
        }

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        /* Dispatch by parent container type, like path_get/patha_get/pathc_get.
         * Hash keys that look numeric are still hash keys. */
        if (LIKELY(t == SVt_PVHV)) {
            SV **svp = hv_fetch((HV*)inner, start, (I32)comp_len * utf8_flag, 0);
            current = svp ? *svp : &PL_sv_undef;
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!is_array_index(start, comp_len, &idx))) {
                current = &PL_sv_undef;
                break;
            }
            SV **elem = av_fetch((AV*)inner, idx, 0);
            current = elem ? *elem : &PL_sv_undef;
        } else {
            current = &PL_sv_undef;
            break;
        }

        if (p < end && *p == '/') p++;
    }

    PUSHs(current);
    RETURN;
}

/* Check if the next non-empty component (after p) parses as an array index. */
PERL_STATIC_INLINE int kw_next_component_is_numeric(const char *p, const char *end)
{
    while (p < end && *p == '/') p++;
    if (p >= end) return 0;
    const char *q = p;
    while (q < end && *q != '/') q++;
    IV dummy;
    return is_array_index(p, q - p, &dummy);
}

/* Custom op for dynamic path set with autovivification.
 * Dispatches by parent container type (consistent with path_set/patha_set/pathc_set):
 * hash parent -> use component as hash key (even if numeric-looking);
 * array parent -> require numeric component. */
static OP* pp_pathset_dynamic(pTHX)
{
    dSP; dMARK; dORIGMARK;
    SV *data_sv = *++MARK;
    SV *path_sv = *++MARK;
    SV *value_sv = *++MARK;
    SP = ORIGMARK;  /* Reset stack to before our args */

    STRLEN path_len;
    const char *path = SvPV(path_sv, path_len);
    const char *p = path;
    const char *end = path + path_len;
    const I32 utf8_flag = SvUTF8(path_sv) ? -1 : 1;

    /* Skip leading slashes */
    while (p < end && *p == '/') p++;

    if (UNLIKELY(p >= end)) {
        /* Empty path (or all slashes) - can't set root */
        croak("Cannot set root");
    }

    SV *current = data_sv;

    while (p < end) {
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (UNLIKELY(comp_len == 0)) {
            if (p < end) p++;
            continue;
        }

        int is_last = kw_at_last_component(p, end);

        if (UNLIKELY(!SvROK(current))) {
            croak("Cannot navigate to path");
        }

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            HV *hv = (HV*)inner;
            I32 klen = (I32)comp_len * utf8_flag;

            if (is_last) {
                SV *copy = SvROK(value_sv) ? SvREFCNT_inc(value_sv) : newSVsv(value_sv);
                if (UNLIKELY(!hv_store(hv, start, klen, copy, 0))) {
                    SvREFCNT_dec(copy);
                    croak(SvRMAGICAL((SV*)hv)
                          ? "Cannot pathset on tied/magical hash"
                          : "Failed to store value");
                }
            } else {
                SV **elem = hv_fetch(hv, start, klen, 1);  /* lvalue/create */
                if (UNLIKELY(!elem)) {
                    croak(SvRMAGICAL((SV*)hv)
                          ? "Cannot pathset on tied/magical hash"
                          : "Cannot navigate to path");
                }
                if (!SvROK(*elem)) {
                    /* sv_setsv on a magical slot won't propagate STORE;
                     * fail loudly instead of silently dropping the write. */
                    if (UNLIKELY(SvRMAGICAL((SV*)hv))) {
                        croak("Cannot pathset on tied/magical hash");
                    }
                    SV *new_ref = kw_next_component_is_numeric(p, end)
                        ? newRV_noinc((SV*)newAV())
                        : newRV_noinc((SV*)newHV());
                    sv_setsv(*elem, new_ref);
                    SvREFCNT_dec(new_ref);
                }
                current = *elem;
            }
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!is_array_index(start, comp_len, &idx))) {
                croak("Cannot navigate to path");
            }
            AV *av = (AV*)inner;

            if (is_last) {
                SV *copy = SvROK(value_sv) ? SvREFCNT_inc(value_sv) : newSVsv(value_sv);
                if (UNLIKELY(!av_store(av, idx, copy))) {
                    SvREFCNT_dec(copy);
                    croak(SvRMAGICAL((SV*)av)
                          ? "Cannot pathset on tied/magical array"
                          : "Failed to store value");
                }
            } else {
                SV **elem = av_fetch(av, idx, 1);  /* lvalue/create */
                if (UNLIKELY(!elem)) {
                    croak(SvRMAGICAL((SV*)av)
                          ? "Cannot pathset on tied/magical array"
                          : "Cannot navigate to path");
                }
                if (!SvROK(*elem)) {
                    if (UNLIKELY(SvRMAGICAL((SV*)av))) {
                        croak("Cannot pathset on tied/magical array");
                    }
                    SV *new_ref = kw_next_component_is_numeric(p, end)
                        ? newRV_noinc((SV*)newAV())
                        : newRV_noinc((SV*)newHV());
                    sv_setsv(*elem, new_ref);
                    SvREFCNT_dec(new_ref);
                }
                current = *elem;
            }
        } else {
            croak("Cannot navigate to path");
        }

        if (p < end && *p == '/') p++;
    }

    if (GIMME_V != G_VOID)
        PUSHs(value_sv);
    RETURN;
}

/* Custom op for dynamic path delete.
 * Dispatches the final delete by parent container type. */
static OP* pp_pathdelete_dynamic(pTHX)
{
    dSP;
    SV *path_sv = POPs;
    SV *data_sv = POPs;

    STRLEN path_len;
    const char *path = SvPV(path_sv, path_len);
    const char *p = path;
    const char *end = path + path_len;
    const I32 utf8_flag = SvUTF8(path_sv) ? -1 : 1;

    /* Skip leading slashes */
    while (p < end && *p == '/') p++;

    if (p >= end) {
        /* Empty path (or all slashes) - can't delete root */
        croak("Cannot delete root");
    }

    SV *current = data_sv;
    SV *parent = NULL;
    const char *last_key_start = NULL;
    STRLEN last_key_len = 0;

    while (p < end) {
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (UNLIKELY(comp_len == 0)) {
            if (p < end) p++;
            continue;
        }

        int is_last = kw_at_last_component(p, end);

        if (is_last) {
            parent = current;
            last_key_start = start;
            last_key_len = comp_len;
            break;
        }

        if (UNLIKELY(!SvROK(current))) {
            PUSHs(&PL_sv_undef);
            RETURN;
        }

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            SV **svp = hv_fetch((HV*)inner, start, (I32)comp_len * utf8_flag, 0);
            current = svp ? *svp : &PL_sv_undef;
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!is_array_index(start, comp_len, &idx))) {
                PUSHs(&PL_sv_undef);
                RETURN;
            }
            SV **elem = av_fetch((AV*)inner, idx, 0);
            current = elem ? *elem : &PL_sv_undef;
        } else {
            PUSHs(&PL_sv_undef);
            RETURN;
        }

        if (p < end && *p == '/') p++;
    }

    /* Perform the delete by parent container type */
    SV *deleted = NULL;
    if (parent && SvROK(parent)) {
        SV *inner = SvRV(parent);
        svtype t = SvTYPE(inner);
        if (LIKELY(t == SVt_PVHV)) {
            deleted = hv_delete((HV*)inner, last_key_start,
                                (I32)last_key_len * utf8_flag, 0);
        } else if (t == SVt_PVAV) {
            IV idx;
            if (is_array_index(last_key_start, last_key_len, &idx))
                deleted = av_delete((AV*)inner, idx, 0);
        }
    }

    /* hv_delete/av_delete with flags=0 already mortalize the returned SV. */
    PUSHs(deleted ? deleted : &PL_sv_undef);
    RETURN;
}

/* Custom op for dynamic path exists check.
 * Dispatches by parent container type. */
static OP* pp_pathexists_dynamic(pTHX)
{
    dSP;
    SV *path_sv = POPs;
    SV *data_sv = POPs;

    STRLEN path_len;
    const char *path = SvPV(path_sv, path_len);
    const char *p = path;
    const char *end = path + path_len;
    const I32 utf8_flag = SvUTF8(path_sv) ? -1 : 1;

    /* Skip leading slashes */
    while (p < end && *p == '/') p++;

    if (p >= end) {
        /* Empty path - root always exists (consistent with path_exists) */
        PUSHs(&PL_sv_yes);
        RETURN;
    }

    SV *current = data_sv;

    while (p < end) {
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (UNLIKELY(comp_len == 0)) {
            if (p < end) p++;
            continue;
        }

        int is_last = kw_at_last_component(p, end);

        if (UNLIKELY(!SvROK(current))) {
            PUSHs(&PL_sv_no);
            RETURN;
        }

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            HV *hv = (HV*)inner;
            I32 klen = (I32)comp_len * utf8_flag;
            if (is_last) {
                PUSHs(hv_exists(hv, start, klen) ? &PL_sv_yes : &PL_sv_no);
                RETURN;
            }
            SV **svp = hv_fetch(hv, start, klen, 0);
            if (!svp || !SvOK(*svp)) {
                PUSHs(&PL_sv_no);
                RETURN;
            }
            current = *svp;
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!is_array_index(start, comp_len, &idx))) {
                PUSHs(&PL_sv_no);
                RETURN;
            }
            AV *av = (AV*)inner;
            if (is_last) {
                PUSHs(av_exists(av, idx) ? &PL_sv_yes : &PL_sv_no);
                RETURN;
            }
            SV **elem = av_fetch(av, idx, 0);
            if (!elem || !SvOK(*elem)) {
                PUSHs(&PL_sv_no);
                RETURN;
            }
            current = *elem;
        } else {
            PUSHs(&PL_sv_no);
            RETURN;
        }

        if (p < end && *p == '/') p++;
    }

    /* All components consumed (or path was all slashes) - root/value exists */
    PUSHs(&PL_sv_yes);
    RETURN;
}

/* Wrap a (data, path) pair as a custom binop dispatched to ppaddr. */
PERL_STATIC_INLINE OP* kw_make_binop(pTHX_ OP *data_op, OP *path_op,
                                     OP *(*ppaddr)(pTHX))
{
    OP *binop = newBINOP(OP_NULL, 0, data_op, path_op);
    binop->op_type = OP_CUSTOM;
    binop->op_ppaddr = ppaddr;
    return binop;
}

/* Build a chain of HELEM accesses for constant-path assignment (lvalue).
 * Only entered when build_kw_pathset has verified all components are
 * non-numeric strings, so no AELEM branch is needed. */
static OP* kw_build_deref_chain_lvalue(pTHX_ OP *data_op, const char *path, STRLEN path_len)
{
    OP *current = data_op;
    const char *p = path;
    const char *end = path + path_len;

    if (p < end && *p == '/') p++;

    while (p < end) {
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (comp_len == 0) {
            if (p < end) p++;
            continue;
        }

        current = newBINOP(OP_HELEM, OPf_MOD,
            newUNOP(OP_RV2HV, OPf_REF | OPf_MOD, current),
            newSVOP(OP_CONST, 0, newSVpvn(start, comp_len)));

        if (p < end && *p == '/') p++;
    }

    return current;
}

/* Build a LISTOP-style custom op carrying (pushmark, data, path, value). */
static OP* kw_build_dynamic_pathset(pTHX_ OP *data_op, OP *path_op, OP *value_op)
{
    OP *list = op_append_elem(OP_LIST, newOP(OP_PUSHMARK, 0), data_op);
    list = op_append_elem(OP_LIST, list, path_op);
    list = op_append_elem(OP_LIST, list, value_op);

    OP *custom = op_convert_list(OP_NULL, 0, list);
    custom->op_type = OP_CUSTOM;
    custom->op_ppaddr = pp_pathset_dynamic;
    return custom;
}

/* The build callback for 'pathget' keyword */
static int build_kw_pathget(pTHX_ OP **out, XSParseKeywordPiece *args[],
                         size_t nargs, void *hookdata)
{
    PERL_UNUSED_ARG(nargs);
    PERL_UNUSED_ARG(hookdata);

    OP *data_op = args[0]->op;
    OP *path_op = args[1]->op;

    /* Always use custom op to avoid autovivification of intermediate levels */
    *out = kw_make_binop(aTHX_ data_op, path_op, pp_pathget_dynamic);
    return KEYWORD_PLUGIN_EXPR;
}

/* Keyword hooks structure for pathget */
static const struct XSParseKeywordHooks hooks_pathget = {
    .permit_hintkey = "Data::Path::XS/pathget",
    .pieces = (const struct XSParseKeywordPieceType []) {
        XPK_TERMEXPR,       /* data structure */
        XPK_COMMA,          /* , */
        XPK_TERMEXPR,       /* path */
        {0}
    },
    .build = &build_kw_pathget,
};

/* The build callback for 'pathset' keyword */
static int build_kw_pathset(pTHX_ OP **out, XSParseKeywordPiece *args[],
                         size_t nargs, void *hookdata)
{
    PERL_UNUSED_ARG(nargs);
    PERL_UNUSED_ARG(hookdata);

    OP *data_op = args[0]->op;
    OP *path_op = args[1]->op;
    OP *value_op = args[2]->op;

    /* Check if path is a compile-time constant string */
    if (path_op->op_type == OP_CONST &&
        (path_op->op_private & OPpCONST_BARE) == 0)
    {
        SV *path_sv = cSVOPx(path_op)->op_sv;
        if (SvPOK(path_sv) && !SvUTF8(path_sv)) {
            STRLEN path_len;
            const char *path = SvPV(path_sv, path_len);
            const char *path_end = path + path_len;

            /* Validate: non-empty path with at least one component */
            const char *p = path;
            while (p < path_end && *p == '/') p++;
            if (p >= path_end) {
                croak("Cannot set root");
            }

            /* Scan for numeric components. The const-path optimization compiles
             * to native HELEM/AELEM ops, which forces a fixed hash-vs-array
             * choice per component. Numeric-looking components would force AELEM,
             * but the actual parent at runtime might be a hash with stringy
             * numeric keys (path_set treats those as hash keys). Fall through
             * to the dynamic op for consistent semantics in that case. */
            int has_numeric = 0;
            const char *q = p;
            while (q < path_end) {
                const char *tok = q;
                while (q < path_end && *q != '/') q++;
                STRLEN tok_len = q - tok;
                IV dummy;
                if (tok_len > 0 && is_array_index(tok, tok_len, &dummy)) {
                    has_numeric = 1;
                    break;
                }
                if (q < path_end) q++;
            }

            if (!has_numeric) {
                /* All components are string keys: build $data->{a}{b}{c} = $value */
                OP *lvalue = kw_build_deref_chain_lvalue(aTHX_ data_op, path, path_len);

                /* Mark as lvalue for proper autovivification */
                lvalue = op_lvalue(lvalue, OP_SASSIGN);

                *out = newBINOP(OP_SASSIGN, 0, value_op, lvalue);

                /* Free the constant path op */
                op_free(path_op);

                return KEYWORD_PLUGIN_EXPR;
            }
            /* fallthrough to dynamic op for paths with numeric components */
        }
    }

    /* Dynamic path - use custom op */
    *out = kw_build_dynamic_pathset(aTHX_ data_op, path_op, value_op);
    return KEYWORD_PLUGIN_EXPR;
}

/* Keyword hooks structure for pathset */
static const struct XSParseKeywordHooks hooks_pathset = {
    .permit_hintkey = "Data::Path::XS/pathset",
    .pieces = (const struct XSParseKeywordPieceType []) {
        XPK_TERMEXPR,       /* data structure */
        XPK_COMMA,          /* , */
        XPK_TERMEXPR,       /* path */
        XPK_COMMA,          /* , */
        XPK_TERMEXPR,       /* value */
        {0}
    },
    .build = &build_kw_pathset,
};

/* The build callback for 'pathdelete' keyword */
static int build_kw_pathdelete(pTHX_ OP **out, XSParseKeywordPiece *args[],
                            size_t nargs, void *hookdata)
{
    PERL_UNUSED_ARG(nargs);
    PERL_UNUSED_ARG(hookdata);

    OP *data_op = args[0]->op;
    OP *path_op = args[1]->op;

    /* Always use custom op to avoid autovivification of intermediate levels */
    *out = kw_make_binop(aTHX_ data_op, path_op, pp_pathdelete_dynamic);
    return KEYWORD_PLUGIN_EXPR;
}

/* Keyword hooks structure for pathdelete */
static const struct XSParseKeywordHooks hooks_pathdelete = {
    .permit_hintkey = "Data::Path::XS/pathdelete",
    .pieces = (const struct XSParseKeywordPieceType []) {
        XPK_TERMEXPR,       /* data structure */
        XPK_COMMA,          /* , */
        XPK_TERMEXPR,       /* path */
        {0}
    },
    .build = &build_kw_pathdelete,
};

/* The build callback for 'pathexists' keyword */
static int build_kw_pathexists(pTHX_ OP **out, XSParseKeywordPiece *args[],
                            size_t nargs, void *hookdata)
{
    PERL_UNUSED_ARG(nargs);
    PERL_UNUSED_ARG(hookdata);

    OP *data_op = args[0]->op;
    OP *path_op = args[1]->op;

    /* Always use custom op to avoid autovivification of intermediate levels */
    *out = kw_make_binop(aTHX_ data_op, path_op, pp_pathexists_dynamic);
    return KEYWORD_PLUGIN_EXPR;
}

/* Keyword hooks structure for pathexists */
static const struct XSParseKeywordHooks hooks_pathexists = {
    .permit_hintkey = "Data::Path::XS/pathexists",
    .pieces = (const struct XSParseKeywordPieceType []) {
        XPK_TERMEXPR,       /* data structure */
        XPK_COMMA,          /* , */
        XPK_TERMEXPR,       /* path */
        {0}
    },
    .build = &build_kw_pathexists,
};

/* ========== END KEYWORD SUPPORT ========== */

MODULE = Data::Path::XS    PACKAGE = Data::Path::XS

PROTOTYPES: DISABLE

SV*
path_get(data, path)
    SV *data
    SV *path
  CODE:
    STRLEN path_len;
    const char *path_str = SvPV(path, path_len);
    const char *final_key;
    STRLEN final_key_len;
    const I32 utf8_flag = SvUTF8(path) ? -1 : 1;

    if (path_len == 0) {
        RETVAL = SvREFCNT_inc(data);
    } else {
        SV *parent = navigate_to_parent(aTHX_ data, path_str, path_len, &final_key, &final_key_len, 0, utf8_flag);

        /* final_key == NULL means path refers to root (e.g., "/" or "///") */
        if (!final_key) {
            RETVAL = parent ? SvREFCNT_inc(parent) : &PL_sv_undef;
        } else if (!parent || !SvROK(parent)) {
            RETVAL = &PL_sv_undef;
        } else {
            SV *inner = SvRV(parent);
            svtype t = SvTYPE(inner);

            if (t == SVt_PVHV) {
                SV **val = hv_fetch((HV*)inner, final_key, (I32)final_key_len * utf8_flag, 0);
                RETVAL = (val && *val) ? SvREFCNT_inc(*val) : &PL_sv_undef;
            } else if (t == SVt_PVAV) {
                IV idx;
                if (is_array_index(final_key, final_key_len, &idx)) {
                    SV **val = av_fetch((AV*)inner, idx, 0);
                    RETVAL = (val && *val) ? SvREFCNT_inc(*val) : &PL_sv_undef;
                } else {
                    RETVAL = &PL_sv_undef;
                }
            } else {
                RETVAL = &PL_sv_undef;
            }
        }
    }
  OUTPUT:
    RETVAL

SV*
path_set(data, path, value)
    SV *data
    SV *path
    SV *value
  CODE:
    STRLEN path_len;
    const char *path_str = SvPV(path, path_len);
    const char *final_key;
    STRLEN final_key_len;
    const I32 utf8_flag = SvUTF8(path) ? -1 : 1;

    if (path_len == 0) {
        croak("Cannot set root");
    }

    SV *parent = navigate_to_parent(aTHX_ data, path_str, path_len, &final_key, &final_key_len, 1, utf8_flag);

    /* final_key == NULL with parent means path refers to root - can't set
     * final_key == NULL without parent means navigation failed */
    if (!final_key) {
        croak(parent ? "Cannot set root" : "Cannot navigate to path");
    }
    if (!parent || !SvROK(parent)) {
        croak("Cannot navigate to path");
    }

    SV *inner = SvRV(parent);
    svtype t = SvTYPE(inner);
    SV *copy = SvROK(value) ? SvREFCNT_inc(value) : newSVsv(value);  /* Refs shared, scalars copied */

    if (t == SVt_PVHV) {
        if (UNLIKELY(!hv_store((HV*)inner, final_key, (I32)final_key_len * utf8_flag, copy, 0))) {
            SvREFCNT_dec(copy);
            croak(SvRMAGICAL(inner)
                  ? "Cannot path_set on tied/magical hash"
                  : "Failed to store value");
        }
    } else if (t == SVt_PVAV) {
        IV idx;
        if (!is_array_index(final_key, final_key_len, &idx)) {
            SvREFCNT_dec(copy);
            croak("Invalid array index");
        }
        if (UNLIKELY(!av_store((AV*)inner, idx, copy))) {
            SvREFCNT_dec(copy);
            croak(SvRMAGICAL(inner)
                  ? "Cannot path_set on tied/magical array"
                  : "Failed to store value");
        }
    } else {
        SvREFCNT_dec(copy);
        croak("Parent is not a hash or array");
    }

    if (GIMME_V == G_VOID) {
        XSRETURN_EMPTY;
    }
    RETVAL = SvREFCNT_inc(value);
  OUTPUT:
    RETVAL

SV*
path_delete(data, path)
    SV *data
    SV *path
  CODE:
    STRLEN path_len;
    const char *path_str = SvPV(path, path_len);
    const char *final_key;
    STRLEN final_key_len;
    const I32 utf8_flag = SvUTF8(path) ? -1 : 1;

    if (path_len == 0) {
        croak("Cannot delete root");
    }

    SV *parent = navigate_to_parent(aTHX_ data, path_str, path_len, &final_key, &final_key_len, 0, utf8_flag);

    /* final_key == NULL with parent means path refers to root - can't delete
     * final_key == NULL without parent means navigation failed - return undef */
    if (!final_key) {
        if (parent) {
            croak("Cannot delete root");
        }
        RETVAL = &PL_sv_undef;
    } else if (!parent || !SvROK(parent)) {
        RETVAL = &PL_sv_undef;
    } else {
        SV *inner = SvRV(parent);
        svtype t = SvTYPE(inner);

        if (t == SVt_PVHV) {
            RETVAL = hv_delete((HV*)inner, final_key, (I32)final_key_len * utf8_flag, 0);
            if (RETVAL) SvREFCNT_inc(RETVAL);
            else RETVAL = &PL_sv_undef;
        } else if (t == SVt_PVAV) {
            IV idx;
            if (is_array_index(final_key, final_key_len, &idx)) {
                SV *old = av_delete((AV*)inner, idx, 0);
                RETVAL = old ? SvREFCNT_inc(old) : &PL_sv_undef;
            } else {
                RETVAL = &PL_sv_undef;
            }
        } else {
            RETVAL = &PL_sv_undef;
        }
    }
  OUTPUT:
    RETVAL

int
path_exists(data, path)
    SV *data
    SV *path
  CODE:
    STRLEN path_len;
    const char *path_str = SvPV(path, path_len);
    const char *final_key;
    STRLEN final_key_len;
    const I32 utf8_flag = SvUTF8(path) ? -1 : 1;

    if (path_len == 0) {
        RETVAL = 1;
    } else {
        SV *parent = navigate_to_parent(aTHX_ data, path_str, path_len, &final_key, &final_key_len, 0, utf8_flag);

        /* final_key == NULL with parent means path refers to root (e.g., "/" or "///") - always exists
         * final_key == NULL without parent means navigation failed (e.g., traverse non-ref) */
        if (!final_key) {
            RETVAL = parent ? 1 : 0;
        } else if (!parent || !SvROK(parent)) {
            RETVAL = 0;
        } else {
            SV *inner = SvRV(parent);
            svtype t = SvTYPE(inner);

            if (t == SVt_PVHV) {
                RETVAL = hv_exists((HV*)inner, final_key, (I32)final_key_len * utf8_flag);
            } else if (t == SVt_PVAV) {
                IV idx;
                RETVAL = is_array_index(final_key, final_key_len, &idx)
                    ? av_exists((AV*)inner, idx) : 0;
            } else {
                RETVAL = 0;
            }
        }
    }
  OUTPUT:
    RETVAL

SV*
patha_get(data, path_av)
    SV *data
    AV *path_av
  CODE:
    SSize_t len = av_len(path_av) + 1;
    SV *current = data;

    for (SSize_t i = 0; i < len; i++) {
        SV **key_ptr = av_fetch(path_av, i, 0);
        if (UNLIKELY(!key_ptr || !*key_ptr || !SvROK(current))) {
            RETVAL = &PL_sv_undef;
            goto done;
        }

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            const char *kstr;
            I32 sklen = sv_to_klen(aTHX_ *key_ptr, &kstr);
            SV **val = hv_fetch((HV*)inner, kstr, sklen, 0);
            if (UNLIKELY(!val || !*val)) { RETVAL = &PL_sv_undef; goto done; }
            current = *val;
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!sv_to_index(aTHX_ *key_ptr, &idx))) { RETVAL = &PL_sv_undef; goto done; }
            SV **val = av_fetch((AV*)inner, idx, 0);
            if (UNLIKELY(!val || !*val)) { RETVAL = &PL_sv_undef; goto done; }
            current = *val;
        } else {
            RETVAL = &PL_sv_undef;
            goto done;
        }
    }
    RETVAL = SvREFCNT_inc(current);
  done:
  OUTPUT:
    RETVAL

SV*
patha_set(data, path_av, value)
    SV *data
    AV *path_av
    SV *value
  CODE:
    SSize_t len = av_len(path_av) + 1;
    SV *current = data;

    if (UNLIKELY(len == 0)) croak("Cannot set root");

    for (SSize_t i = 0; i < len - 1; i++) {
        SV **key_ptr = av_fetch(path_av, i, 0);
        if (UNLIKELY(!key_ptr || !*key_ptr)) croak("Invalid path element");
        if (UNLIKELY(!SvROK(current))) croak("Cannot navigate to path");

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            const char *kstr;
            I32 sklen = sv_to_klen(aTHX_ *key_ptr, &kstr);
            SV **val = hv_fetch((HV*)inner, kstr, sklen, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                SV **next_key = av_fetch(path_av, i + 1, 0);
                IV dummy;
                SV *new_ref = (next_key && *next_key && sv_to_index(aTHX_ *next_key, &dummy))
                    ? newRV_noinc((SV*)newAV())
                    : newRV_noinc((SV*)newHV());
                if (UNLIKELY(!hv_store((HV*)inner, kstr, sklen, new_ref, 0))) {
                    SvREFCNT_dec(new_ref);
                    croak(SvRMAGICAL(inner)
                          ? "Cannot patha_set on tied/magical hash"
                          : "Failed to store intermediate value");
                }
                current = new_ref;
            } else {
                current = *val;
            }
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!sv_to_index(aTHX_ *key_ptr, &idx))) croak("Invalid array index");
            SV **val = av_fetch((AV*)inner, idx, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                SV **next_key = av_fetch(path_av, i + 1, 0);
                IV dummy;
                SV *new_ref = (next_key && *next_key && sv_to_index(aTHX_ *next_key, &dummy))
                    ? newRV_noinc((SV*)newAV())
                    : newRV_noinc((SV*)newHV());
                if (UNLIKELY(!av_store((AV*)inner, idx, new_ref))) {
                    SvREFCNT_dec(new_ref);
                    croak(SvRMAGICAL(inner)
                          ? "Cannot patha_set on tied/magical array"
                          : "Failed to store intermediate value");
                }
                current = new_ref;
            } else {
                current = *val;
            }
        } else {
            croak("Cannot navigate to path");
        }
    }

    if (UNLIKELY(!SvROK(current))) croak("Cannot set on non-reference");
    SV *inner = SvRV(current);
    svtype t = SvTYPE(inner);
    SV **final_key_ptr = av_fetch(path_av, len - 1, 0);
    if (UNLIKELY(!final_key_ptr || !*final_key_ptr)) croak("Invalid final key");
    SV *copy = SvROK(value) ? SvREFCNT_inc(value) : newSVsv(value);  /* Refs shared, scalars copied */

    if (LIKELY(t == SVt_PVHV)) {
        const char *kstr;
        I32 sklen = sv_to_klen(aTHX_ *final_key_ptr, &kstr);
        if (UNLIKELY(!hv_store((HV*)inner, kstr, sklen, copy, 0))) {
            SvREFCNT_dec(copy);
            croak(SvRMAGICAL(inner)
                  ? "Cannot patha_set on tied/magical hash"
                  : "Failed to store value");
        }
    } else if (t == SVt_PVAV) {
        IV idx;
        if (UNLIKELY(!sv_to_index(aTHX_ *final_key_ptr, &idx))) {
            SvREFCNT_dec(copy);
            croak("Invalid array index");
        }
        if (UNLIKELY(!av_store((AV*)inner, idx, copy))) {
            SvREFCNT_dec(copy);
            croak(SvRMAGICAL(inner)
                  ? "Cannot patha_set on tied/magical array"
                  : "Failed to store value");
        }
    } else {
        SvREFCNT_dec(copy);
        croak("Parent is not a hash or array");
    }

    if (GIMME_V == G_VOID) {
        XSRETURN_EMPTY;
    }
    RETVAL = SvREFCNT_inc(value);
  OUTPUT:
    RETVAL

int
patha_exists(data, path_av)
    SV *data
    AV *path_av
  CODE:
    SSize_t len = av_len(path_av) + 1;
    SV *current = data;

    if (UNLIKELY(len == 0)) { RETVAL = 1; goto done; }

    for (SSize_t i = 0; i < len - 1; i++) {
        SV **key_ptr = av_fetch(path_av, i, 0);
        if (UNLIKELY(!key_ptr || !*key_ptr || !SvROK(current))) { RETVAL = 0; goto done; }

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            const char *kstr;
            I32 sklen = sv_to_klen(aTHX_ *key_ptr, &kstr);
            SV **val = hv_fetch((HV*)inner, kstr, sklen, 0);
            if (UNLIKELY(!val || !*val)) { RETVAL = 0; goto done; }
            current = *val;
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!sv_to_index(aTHX_ *key_ptr, &idx))) { RETVAL = 0; goto done; }
            SV **val = av_fetch((AV*)inner, idx, 0);
            if (UNLIKELY(!val || !*val)) { RETVAL = 0; goto done; }
            current = *val;
        } else {
            RETVAL = 0; goto done;
        }
    }

    if (UNLIKELY(!SvROK(current))) { RETVAL = 0; goto done; }
    SV *inner = SvRV(current);
    svtype t = SvTYPE(inner);
    SV **final_key_ptr = av_fetch(path_av, len - 1, 0);
    if (UNLIKELY(!final_key_ptr || !*final_key_ptr)) { RETVAL = 0; goto done; }

    if (LIKELY(t == SVt_PVHV)) {
        const char *kstr;
        I32 sklen = sv_to_klen(aTHX_ *final_key_ptr, &kstr);
        RETVAL = hv_exists((HV*)inner, kstr, sklen);
    } else if (t == SVt_PVAV) {
        IV idx;
        RETVAL = sv_to_index(aTHX_ *final_key_ptr, &idx) ? av_exists((AV*)inner, idx) : 0;
    } else {
        RETVAL = 0;
    }
  done:
  OUTPUT:
    RETVAL

SV*
patha_delete(data, path_av)
    SV *data
    AV *path_av
  CODE:
    SSize_t len = av_len(path_av) + 1;
    SV *current = data;

    if (UNLIKELY(len == 0)) croak("Cannot delete root");

    for (SSize_t i = 0; i < len - 1; i++) {
        SV **key_ptr = av_fetch(path_av, i, 0);
        if (UNLIKELY(!key_ptr || !*key_ptr || !SvROK(current))) { RETVAL = &PL_sv_undef; goto done; }

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            const char *kstr;
            I32 sklen = sv_to_klen(aTHX_ *key_ptr, &kstr);
            SV **val = hv_fetch((HV*)inner, kstr, sklen, 0);
            if (UNLIKELY(!val || !*val)) { RETVAL = &PL_sv_undef; goto done; }
            current = *val;
        } else if (t == SVt_PVAV) {
            IV idx;
            if (UNLIKELY(!sv_to_index(aTHX_ *key_ptr, &idx))) { RETVAL = &PL_sv_undef; goto done; }
            SV **val = av_fetch((AV*)inner, idx, 0);
            if (UNLIKELY(!val || !*val)) { RETVAL = &PL_sv_undef; goto done; }
            current = *val;
        } else {
            RETVAL = &PL_sv_undef; goto done;
        }
    }

    if (UNLIKELY(!SvROK(current))) { RETVAL = &PL_sv_undef; goto done; }
    SV *inner = SvRV(current);
    svtype t = SvTYPE(inner);
    SV **final_key_ptr = av_fetch(path_av, len - 1, 0);
    if (UNLIKELY(!final_key_ptr || !*final_key_ptr)) { RETVAL = &PL_sv_undef; goto done; }

    if (LIKELY(t == SVt_PVHV)) {
        const char *kstr;
        I32 sklen = sv_to_klen(aTHX_ *final_key_ptr, &kstr);
        RETVAL = hv_delete((HV*)inner, kstr, sklen, 0);
        if (RETVAL) SvREFCNT_inc(RETVAL);
        else RETVAL = &PL_sv_undef;
    } else if (t == SVt_PVAV) {
        IV idx;
        if (sv_to_index(aTHX_ *final_key_ptr, &idx)) {
            SV *old = av_delete((AV*)inner, idx, 0);
            RETVAL = old ? SvREFCNT_inc(old) : &PL_sv_undef;
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        RETVAL = &PL_sv_undef;
    }
  done:
  OUTPUT:
    RETVAL

# Compiled path API

SV*
path_compile(path)
    SV *path
  CODE:
    CompiledPath *cp = compile_path(aTHX_ path);
    SV *obj = newSV(0);
    sv_setref_pv(obj, "Data::Path::XS::Compiled", (void*)cp);
    RETVAL = obj;
  OUTPUT:
    RETVAL

SV*
pathc_get(data, compiled)
    SV *data
    SV *compiled
  CODE:
    CompiledPath *cp;
    VALIDATE_COMPILED_PATH(compiled, cp);

    if (UNLIKELY(cp->count == 0)) {
        RETVAL = SvREFCNT_inc(data);
    } else {
        /* Fully inlined navigation for maximum speed */
        SV *current = data;
        PathComponent *c = cp->components;
        PathComponent *end = c + cp->count;
        const I32 utf8_flag = cp->utf8_flag;

        while (c < end) {
            if (UNLIKELY(!SvROK(current))) {
                RETVAL = &PL_sv_undef;
                goto done;
            }

            SV *inner = SvRV(current);
            svtype t = SvTYPE(inner);

            if (LIKELY(t == SVt_PVHV)) {
                SV **val = hv_fetch((HV*)inner, c->str, (I32)c->len * utf8_flag, 0);
                if (UNLIKELY(!val || !*val)) {
                    RETVAL = &PL_sv_undef;
                    goto done;
                }
                current = *val;
            } else if (t == SVt_PVAV) {
                if (UNLIKELY(!c->is_numeric)) {
                    RETVAL = &PL_sv_undef;
                    goto done;
                }
                SV **val = av_fetch((AV*)inner, c->idx, 0);
                if (UNLIKELY(!val || !*val)) {
                    RETVAL = &PL_sv_undef;
                    goto done;
                }
                current = *val;
            } else {
                RETVAL = &PL_sv_undef;
                goto done;
            }
            c++;
        }
        RETVAL = SvREFCNT_inc(current);
    }
  done:
  OUTPUT:
    RETVAL

SV*
pathc_set(data, compiled, value)
    SV *data
    SV *compiled
    SV *value
  CODE:
    CompiledPath *cp;
    VALIDATE_COMPILED_PATH(compiled, cp);

    if (UNLIKELY(cp->count == 0)) croak("Cannot set root");

    /* Fully inlined navigation with creation for maximum speed */
    SV *current = data;
    PathComponent *c = cp->components;
    PathComponent *last = c + cp->count - 1;
    const I32 utf8_flag = cp->utf8_flag;

    /* Navigate to parent, creating intermediate structures as needed */
    while (c < last) {
        if (UNLIKELY(!SvROK(current))) croak("Cannot navigate to path");

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            I32 klen = (I32)c->len * utf8_flag;
            SV **val = hv_fetch((HV*)inner, c->str, klen, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                /* Create intermediate structure using pre-computed type */
                SV *new_ref = c->next_is_array
                    ? newRV_noinc((SV*)newAV())
                    : newRV_noinc((SV*)newHV());
                if (UNLIKELY(!hv_store((HV*)inner, c->str, klen, new_ref, 0))) {
                    SvREFCNT_dec(new_ref);
                    croak(SvRMAGICAL(inner)
                          ? "Cannot pathc_set on tied/magical hash"
                          : "Failed to store intermediate value");
                }
                current = new_ref;
            } else {
                current = *val;
            }
        } else if (t == SVt_PVAV) {
            if (UNLIKELY(!c->is_numeric)) croak("Invalid array index");
            SV **val = av_fetch((AV*)inner, c->idx, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                SV *new_ref = c->next_is_array
                    ? newRV_noinc((SV*)newAV())
                    : newRV_noinc((SV*)newHV());
                if (UNLIKELY(!av_store((AV*)inner, c->idx, new_ref))) {
                    SvREFCNT_dec(new_ref);
                    croak(SvRMAGICAL(inner)
                          ? "Cannot pathc_set on tied/magical array"
                          : "Failed to store intermediate value");
                }
                current = new_ref;
            } else {
                current = *val;
            }
        } else {
            croak("Cannot navigate to path");
        }
        c++;
    }

    /* Set the final value */
    if (UNLIKELY(!SvROK(current))) croak("Cannot navigate to path");
    SV *inner = SvRV(current);
    svtype t = SvTYPE(inner);
    SV *copy = SvROK(value) ? SvREFCNT_inc(value) : newSVsv(value);  /* Refs shared, scalars copied */

    if (LIKELY(t == SVt_PVHV)) {
        if (UNLIKELY(!hv_store((HV*)inner, last->str, (I32)last->len * utf8_flag, copy, 0))) {
            SvREFCNT_dec(copy);
            croak(SvRMAGICAL(inner)
                  ? "Cannot pathc_set on tied/magical hash"
                  : "Failed to store value");
        }
    } else if (t == SVt_PVAV) {
        if (UNLIKELY(!last->is_numeric)) { SvREFCNT_dec(copy); croak("Invalid array index"); }
        if (UNLIKELY(!av_store((AV*)inner, last->idx, copy))) {
            SvREFCNT_dec(copy);
            croak(SvRMAGICAL(inner)
                  ? "Cannot pathc_set on tied/magical array"
                  : "Failed to store value");
        }
    } else {
        SvREFCNT_dec(copy);
        croak("Parent is not a hash or array");
    }

    /* Skip return value overhead in void context */
    if (GIMME_V == G_VOID) {
        XSRETURN_EMPTY;
    }
    RETVAL = SvREFCNT_inc(value);
  OUTPUT:
    RETVAL

int
pathc_exists(data, compiled)
    SV *data
    SV *compiled
  CODE:
    CompiledPath *cp;
    VALIDATE_COMPILED_PATH(compiled, cp);

    if (UNLIKELY(cp->count == 0)) {
        RETVAL = 1;
    } else {
        /* Inlined navigation to parent */
        SV *current = data;
        PathComponent *c = cp->components;
        PathComponent *last = c + cp->count - 1;
        const I32 utf8_flag = cp->utf8_flag;

        while (c < last) {
            if (UNLIKELY(!SvROK(current))) {
                RETVAL = 0;
                goto done;
            }
            SV *inner = SvRV(current);
            svtype t = SvTYPE(inner);

            if (LIKELY(t == SVt_PVHV)) {
                SV **val = hv_fetch((HV*)inner, c->str, (I32)c->len * utf8_flag, 0);
                if (UNLIKELY(!val || !*val)) { RETVAL = 0; goto done; }
                current = *val;
            } else if (t == SVt_PVAV) {
                if (UNLIKELY(!c->is_numeric)) { RETVAL = 0; goto done; }
                SV **val = av_fetch((AV*)inner, c->idx, 0);
                if (UNLIKELY(!val || !*val)) { RETVAL = 0; goto done; }
                current = *val;
            } else {
                RETVAL = 0;
                goto done;
            }
            c++;
        }

        /* Check final key existence */
        if (UNLIKELY(!SvROK(current))) {
            RETVAL = 0;
        } else {
            SV *inner = SvRV(current);
            svtype t = SvTYPE(inner);
            if (LIKELY(t == SVt_PVHV)) {
                RETVAL = hv_exists((HV*)inner, last->str, (I32)last->len * utf8_flag);
            } else if (t == SVt_PVAV) {
                RETVAL = last->is_numeric ? av_exists((AV*)inner, last->idx) : 0;
            } else {
                RETVAL = 0;
            }
        }
    }
  done:
  OUTPUT:
    RETVAL

SV*
pathc_delete(data, compiled)
    SV *data
    SV *compiled
  CODE:
    CompiledPath *cp;
    VALIDATE_COMPILED_PATH(compiled, cp);

    if (UNLIKELY(cp->count == 0)) croak("Cannot delete root");

    /* Inlined navigation to parent */
    SV *current = data;
    PathComponent *c = cp->components;
    PathComponent *last = c + cp->count - 1;
    const I32 utf8_flag = cp->utf8_flag;

    while (c < last) {
        if (UNLIKELY(!SvROK(current))) {
            RETVAL = &PL_sv_undef;
            goto done;
        }
        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            SV **val = hv_fetch((HV*)inner, c->str, (I32)c->len * utf8_flag, 0);
            if (UNLIKELY(!val || !*val)) { RETVAL = &PL_sv_undef; goto done; }
            current = *val;
        } else if (t == SVt_PVAV) {
            if (UNLIKELY(!c->is_numeric)) { RETVAL = &PL_sv_undef; goto done; }
            SV **val = av_fetch((AV*)inner, c->idx, 0);
            if (UNLIKELY(!val || !*val)) { RETVAL = &PL_sv_undef; goto done; }
            current = *val;
        } else {
            RETVAL = &PL_sv_undef;
            goto done;
        }
        c++;
    }

    /* Delete final key */
    if (UNLIKELY(!SvROK(current))) {
        RETVAL = &PL_sv_undef;
    } else {
        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            RETVAL = hv_delete((HV*)inner, last->str, (I32)last->len * utf8_flag, 0);
            if (RETVAL) SvREFCNT_inc(RETVAL);
            else RETVAL = &PL_sv_undef;
        } else if (t == SVt_PVAV) {
            if (last->is_numeric) {
                SV *old = av_delete((AV*)inner, last->idx, 0);
                RETVAL = old ? SvREFCNT_inc(old) : &PL_sv_undef;
            } else {
                RETVAL = &PL_sv_undef;
            }
        } else {
            RETVAL = &PL_sv_undef;
        }
    }
  done:
  OUTPUT:
    RETVAL

MODULE = Data::Path::XS    PACKAGE = Data::Path::XS::Compiled

void
DESTROY(self)
    SV *self
  CODE:
    if (SvROK(self)) {
        SV *inner = SvRV(self);
        /* SvIOK guard avoids "Argument isn't numeric" warnings when this
         * package name was abused to bless arbitrary refs. */
        if (SvIOK(inner)) {
            CompiledPath *cp = INT2PTR(CompiledPath*, SvIVX(inner));
            if (cp && cp->magic == COMPILED_PATH_MAGIC) {
                free_compiled_path(aTHX_ cp);
            }
        }
    }

MODULE = Data::Path::XS    PACKAGE = Data::Path::XS

BOOT:
    {
#define REGISTER_XOP(xop, nm, dsc, pp) STMT_START { \
            XopENTRY_set(&(xop), xop_name, (nm));   \
            XopENTRY_set(&(xop), xop_desc, (dsc));  \
            Perl_custom_op_register(aTHX_ (pp), &(xop)); \
        } STMT_END

        REGISTER_XOP(xop_pathget,    "pathget_dynamic",    "dynamic path get",    pp_pathget_dynamic);
        REGISTER_XOP(xop_pathset,    "pathset_dynamic",    "dynamic path set",    pp_pathset_dynamic);
        REGISTER_XOP(xop_pathdelete, "pathdelete_dynamic", "dynamic path delete", pp_pathdelete_dynamic);
        REGISTER_XOP(xop_pathexists, "pathexists_dynamic", "dynamic path exists", pp_pathexists_dynamic);
#undef REGISTER_XOP

        boot_xs_parse_keyword(0.40);
        register_xs_parse_keyword("pathget",    &hooks_pathget,    NULL);
        register_xs_parse_keyword("pathset",    &hooks_pathset,    NULL);
        register_xs_parse_keyword("pathdelete", &hooks_pathdelete, NULL);
        register_xs_parse_keyword("pathexists", &hooks_pathexists, NULL);
    }
