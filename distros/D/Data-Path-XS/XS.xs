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
    SSize_t count;
    SV *path_sv;     /* Owned copy of path string buffer */
    PathComponent components[1];  /* Flexible array member (C89 style) */
} CompiledPath;

/* Fast compiled path validation - check ref, NULL, and magic */
#define VALIDATE_COMPILED_PATH(sv, cp) do { \
    if (UNLIKELY(!SvROK(sv))) croak("Not a compiled path"); \
    cp = INT2PTR(CompiledPath*, SvIV(SvRV(sv))); \
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

    if (UNLIKELY(len == 0 || len > (MAX_INDEX_DIGITS + 1))) return 0;  /* Empty or too long */

    /* Handle negative sign */
    if (*s == '-') {
        negative = 1;
        s++;
        len--;
        if (UNLIKELY(len == 0)) return 0;  /* Just "-" */
    }

    if (UNLIKELY(len > MAX_INDEX_DIGITS)) return 0;  /* Too many digits */
    if (len > 1 && *s == '0') return 0;  /* No leading zeros */

    while (s < end) {
        if (UNLIKELY(*s < '0' || *s > '9')) return 0;
        val = val * 10 + (*s - '0');
        s++;
    }

    *idx = negative ? -val : val;
    return 1;
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

/* Navigate using raw char* path components */
PERL_STATIC_INLINE SV* navigate_to_parent(pTHX_ SV *data, const char *path, STRLEN path_len,
                              const char **final_key_ptr, STRLEN *final_key_len, int create) {
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
            SV **val = hv_fetch(hv, tok_start, tok_len, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                if (create) {
                    /* check already points at next real component start */
                    const char *next_end = check;
                    while (next_end < end && *next_end != '/') next_end++;
                    IV dummy;
                    SV *new_ref = is_array_index(check, next_end - check, &dummy)
                        ? newRV_noinc((SV*)newAV())
                        : newRV_noinc((SV*)newHV());
                    if (UNLIKELY(!hv_store(hv, tok_start, tok_len, new_ref, 0))) {
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
                    /* check already points at next real component start */
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
        cp->count = 0;
        cp->path_sv = newSVpvn(path, path_len);
        return cp;
    }

    /* Allocate struct with inline component array in single allocation
     * Size = base struct + (count-1) extra PathComponents
     * (struct already includes space for 1 component)
     */
    Size_t alloc_size = sizeof(CompiledPath);
    if (count > 1) {
        alloc_size += (count - 1) * sizeof(PathComponent);
    }
    Newxc(cp, alloc_size, char, CompiledPath);

    cp->magic = COMPILED_PATH_MAGIC;
    cp->count = count;
    /* Create independent copy of path string so PathComponent pointers
     * remain valid even if the original SV's buffer is modified/freed */
    cp->path_sv = newSVpvn(path, path_len);

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

    SV *current = data_sv;

    /* Skip leading slashes */
    while (p < end && *p == '/') p++;

    while (p < end && SvOK(current)) {
        /* Find component end */
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
        IV idx;

        if (is_array_index(start, comp_len, &idx)) {
            if (UNLIKELY(SvTYPE(inner) != SVt_PVAV)) {
                current = &PL_sv_undef;
                break;
            }
            SV **elem = av_fetch((AV*)inner, idx, 0);
            current = elem ? *elem : &PL_sv_undef;
        } else {
            if (UNLIKELY(SvTYPE(inner) != SVt_PVHV)) {
                current = &PL_sv_undef;
                break;
            }
            SV **svp = hv_fetch((HV*)inner, start, comp_len, 0);
            current = svp ? *svp : &PL_sv_undef;
        }

        if (p < end && *p == '/') p++;
    }

    PUSHs(current);
    RETURN;
}

/* Helper to check if next path component is numeric (including negative) */
PERL_STATIC_INLINE int kw_next_component_is_numeric(const char *p, const char *end)
{
    if (p >= end || *p != '/') return 0;
    /* Skip consecutive slashes to find next real component */
    while (p < end && *p == '/') p++;
    if (p >= end) return 0;

    /* Handle optional negative sign */
    if (*p == '-') {
        p++;
        if (p >= end || *p == '/') return 0;  /* Just "-" */
    }

    const char *digits_start = p;
    while (p < end && *p != '/') {
        if (*p < '0' || *p > '9') return 0;
        p++;
    }
    /* Use same rules as is_array_index: no leading zeros, max digits */
    STRLEN len = p - digits_start;
    if (UNLIKELY(len == 0 || len > MAX_INDEX_DIGITS)) return 0;
    if (len > 1 && *digits_start == '0') return 0;
    return 1;
}

/* Custom op for dynamic path set with autovivification */
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

    /* Skip leading slashes */
    while (p < end && *p == '/') p++;

    if (UNLIKELY(p >= end)) {
        /* Empty path (or all slashes) - can't set root */
        croak("Cannot set root");
    }

    SV *current = data_sv;

    while (p < end) {
        /* Find component end */
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (UNLIKELY(comp_len == 0)) {
            if (p < end) p++;
            continue;
        }

        /* Skip all trailing slashes/empty components for "is last" check */
        const char *next_p = p;
        while (next_p < end && *next_p == '/') next_p++;
        int is_last = (next_p >= end);

        if (UNLIKELY(!SvROK(current))) {
            croak("Cannot navigate to path");
        }

        SV *inner = SvRV(current);
        IV idx;

        if (is_array_index(start, comp_len, &idx)) {
            /* Array access */
            if (UNLIKELY(SvTYPE(inner) != SVt_PVAV)) {
                croak("Cannot navigate to path");
            }
            AV *av = (AV*)inner;

            if (is_last) {
                /* Final component - store value */
                SV *copy = SvROK(value_sv) ? SvREFCNT_inc(value_sv) : newSVsv(value_sv);
                if (UNLIKELY(!av_store(av, idx, copy))) {
                    SvREFCNT_dec(copy);
                    croak("Failed to store value");
                }
            } else {
                /* Intermediate - autovivify if needed */
                SV **elem = av_fetch(av, idx, 1);  /* 1 = lvalue/create */
                if (UNLIKELY(!elem)) {
                    croak("Cannot navigate to path");
                }
                if (!SvOK(*elem) || !SvROK(*elem)) {
                    /* Autovivify based on next component */
                    SV *new_ref;
                    if (kw_next_component_is_numeric(p, end)) {
                        new_ref = newRV_noinc((SV*)newAV());
                    } else {
                        new_ref = newRV_noinc((SV*)newHV());
                    }
                    sv_setsv(*elem, new_ref);
                    SvREFCNT_dec(new_ref);
                }
                current = *elem;
            }
        } else {
            /* Hash access */
            if (UNLIKELY(SvTYPE(inner) != SVt_PVHV)) {
                croak("Cannot navigate to path");
            }
            HV *hv = (HV*)inner;

            if (is_last) {
                /* Final component - store value */
                SV *copy = SvROK(value_sv) ? SvREFCNT_inc(value_sv) : newSVsv(value_sv);
                if (UNLIKELY(!hv_store(hv, start, comp_len, copy, 0))) {
                    SvREFCNT_dec(copy);
                    croak("Failed to store value");
                }
            } else {
                /* Intermediate - autovivify if needed */
                SV **elem = hv_fetch(hv, start, comp_len, 1);  /* 1 = lvalue/create */
                if (UNLIKELY(!elem)) {
                    croak("Cannot navigate to path");
                }
                if (!SvOK(*elem) || !SvROK(*elem)) {
                    /* Autovivify based on next component */
                    SV *new_ref;
                    if (kw_next_component_is_numeric(p, end)) {
                        new_ref = newRV_noinc((SV*)newAV());
                    } else {
                        new_ref = newRV_noinc((SV*)newHV());
                    }
                    sv_setsv(*elem, new_ref);
                    SvREFCNT_dec(new_ref);
                }
                current = *elem;
            }
        }

        if (p < end && *p == '/') p++;
    }

    if (GIMME_V != G_VOID)
        PUSHs(value_sv);
    RETURN;
}

/* Custom op for dynamic path delete */
static OP* pp_pathdelete_dynamic(pTHX)
{
    dSP;
    SV *path_sv = POPs;
    SV *data_sv = POPs;

    STRLEN path_len;
    const char *path = SvPV(path_sv, path_len);
    const char *p = path;
    const char *end = path + path_len;

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
    int last_is_numeric = 0;
    IV last_idx = 0;

    while (p < end) {
        /* Find component end */
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (UNLIKELY(comp_len == 0)) {
            if (p < end) p++;
            continue;
        }

        /* Check if numeric using shared helper */
        IV idx;
        int is_numeric = is_array_index(start, comp_len, &idx);

        /* Skip all trailing slashes/empty components for "is last" check */
        const char *next_p = p;
        while (next_p < end && *next_p == '/') next_p++;
        int is_last = (next_p >= end);

        if (is_last) {
            /* Remember this for deletion */
            parent = current;
            last_key_start = start;
            last_key_len = comp_len;
            last_is_numeric = is_numeric;
            last_idx = idx;
            break;
        }

        if (UNLIKELY(!SvROK(current))) {
            PUSHs(&PL_sv_undef);
            RETURN;
        }

        SV *inner = SvRV(current);

        if (is_numeric) {
            if (UNLIKELY(SvTYPE(inner) != SVt_PVAV)) {
                PUSHs(&PL_sv_undef);
                RETURN;
            }
            SV **elem = av_fetch((AV*)inner, idx, 0);
            current = elem ? *elem : &PL_sv_undef;
        } else {
            if (UNLIKELY(SvTYPE(inner) != SVt_PVHV)) {
                PUSHs(&PL_sv_undef);
                RETURN;
            }
            SV **svp = hv_fetch((HV*)inner, start, comp_len, 0);
            current = svp ? *svp : &PL_sv_undef;
        }

        if (p < end && *p == '/') p++;
    }

    /* Perform the delete */
    SV *deleted = NULL;
    if (parent && SvROK(parent)) {
        SV *inner = SvRV(parent);
        if (last_is_numeric) {
            if (SvTYPE(inner) == SVt_PVAV)
                deleted = av_delete((AV*)inner, last_idx, 0);
        } else {
            if (SvTYPE(inner) == SVt_PVHV)
                deleted = hv_delete((HV*)inner, last_key_start, last_key_len, 0);
        }
    }

    if (deleted) {
        SvREFCNT_inc_simple_void_NN(deleted);
        PUSHs(sv_2mortal(deleted));
    } else {
        PUSHs(&PL_sv_undef);
    }
    RETURN;
}

/* Custom op for dynamic path exists check */
static OP* pp_pathexists_dynamic(pTHX)
{
    dSP;
    SV *path_sv = POPs;
    SV *data_sv = POPs;

    STRLEN path_len;
    const char *path = SvPV(path_sv, path_len);
    const char *p = path;
    const char *end = path + path_len;

    /* Skip leading slashes */
    while (p < end && *p == '/') p++;

    if (p >= end) {
        /* Empty path - root always exists (consistent with path_exists) */
        PUSHs(&PL_sv_yes);
        RETURN;
    }

    SV *current = data_sv;

    while (p < end) {
        /* Find component end */
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (UNLIKELY(comp_len == 0)) {
            if (p < end) p++;
            continue;
        }

        /* Check if numeric using shared helper */
        IV idx;
        int is_numeric = is_array_index(start, comp_len, &idx);

        /* Skip all trailing slashes/empty components for "is last" check */
        const char *next_p = p;
        while (next_p < end && *next_p == '/') next_p++;
        int is_last = (next_p >= end);

        if (UNLIKELY(!SvROK(current))) {
            PUSHs(&PL_sv_no);
            RETURN;
        }

        SV *inner = SvRV(current);

        if (is_numeric) {
            if (UNLIKELY(SvTYPE(inner) != SVt_PVAV)) {
                PUSHs(&PL_sv_no);
                RETURN;
            }
            AV *av = (AV*)inner;

            if (is_last) {
                /* Final component - check if exists */
                bool exists = av_exists(av, idx);
                PUSHs(exists ? &PL_sv_yes : &PL_sv_no);
                RETURN;
            } else {
                SV **elem = av_fetch(av, idx, 0);
                if (!elem || !SvOK(*elem)) {
                    PUSHs(&PL_sv_no);
                    RETURN;
                }
                current = *elem;
            }
        } else {
            if (UNLIKELY(SvTYPE(inner) != SVt_PVHV)) {
                PUSHs(&PL_sv_no);
                RETURN;
            }
            HV *hv = (HV*)inner;

            if (is_last) {
                /* Final component - check if exists */
                bool exists = hv_exists(hv, start, comp_len);
                PUSHs(exists ? &PL_sv_yes : &PL_sv_no);
                RETURN;
            } else {
                SV **svp = hv_fetch(hv, start, comp_len, 0);
                if (!svp || !SvOK(*svp)) {
                    PUSHs(&PL_sv_no);
                    RETURN;
                }
                current = *svp;
            }
        }

        if (p < end && *p == '/') p++;
    }

    /* All components consumed (or path was all slashes) - root/value exists */
    PUSHs(&PL_sv_yes);
    RETURN;
}

/* Build a custom op for dynamic path access */
static OP* kw_build_dynamic_pathget(pTHX_ OP *data_op, OP *path_op)
{
    /* Create BINOP with data and path as children */
    OP *binop = newBINOP(OP_NULL, 0, data_op, path_op);
    binop->op_type = OP_CUSTOM;
    binop->op_ppaddr = pp_pathget_dynamic;

    return binop;
}

/* Build a chain of hash/array element accesses for assignment (lvalue) */
static OP* kw_build_deref_chain_lvalue(pTHX_ OP *data_op, const char *path, STRLEN path_len)
{
    OP *current = data_op;
    const char *p = path;
    const char *end = path + path_len;

    /* Skip leading slash */
    if (p < end && *p == '/') p++;

    while (p < end) {
        /* Find component end */
        const char *start = p;
        while (p < end && *p != '/') p++;
        STRLEN comp_len = p - start;

        if (comp_len == 0) {
            if (p < end) p++;
            continue;
        }

        /* Check if this component is numeric */
        IV idx;
        int is_numeric = is_array_index(start, comp_len, &idx);

        if (is_numeric) {
            /* Array element: $current->[$idx] */
            current = newBINOP(OP_AELEM, OPf_MOD,
                newUNOP(OP_RV2AV, OPf_REF | OPf_MOD, current),
                newSVOP(OP_CONST, 0, newSViv(idx)));
        } else {
            /* Hash element: $current->{key} */
            current = newBINOP(OP_HELEM, OPf_MOD,
                newUNOP(OP_RV2HV, OPf_REF | OPf_MOD, current),
                newSVOP(OP_CONST, 0, newSVpvn(start, comp_len)));
        }

        if (p < end && *p == '/') p++;
    }

    return current;
}

/* Build a custom op for dynamic path set */
static OP* kw_build_dynamic_pathset(pTHX_ OP *data_op, OP *path_op, OP *value_op)
{
    /* Build list: pushmark, data, path, value */
    OP *pushmark = newOP(OP_PUSHMARK, 0);
    OP *list = op_append_elem(OP_LIST, pushmark, data_op);
    list = op_append_elem(OP_LIST, list, path_op);
    list = op_append_elem(OP_LIST, list, value_op);

    /* Convert to custom op */
    OP *custom = op_convert_list(OP_NULL, 0, list);
    custom->op_type = OP_CUSTOM;
    custom->op_ppaddr = pp_pathset_dynamic;

    return custom;
}

/* Build a custom op for dynamic path delete */
static OP* kw_build_dynamic_pathdelete(pTHX_ OP *data_op, OP *path_op)
{
    /* Create BINOP with data and path as children */
    OP *binop = newBINOP(OP_NULL, 0, data_op, path_op);
    binop->op_type = OP_CUSTOM;
    binop->op_ppaddr = pp_pathdelete_dynamic;

    return binop;
}

/* Build a custom op for dynamic path exists */
static OP* kw_build_dynamic_pathexists(pTHX_ OP *data_op, OP *path_op)
{
    /* Create BINOP with data and path as children */
    OP *binop = newBINOP(OP_NULL, 0, data_op, path_op);
    binop->op_type = OP_CUSTOM;
    binop->op_ppaddr = pp_pathexists_dynamic;

    return binop;
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
    *out = kw_build_dynamic_pathget(aTHX_ data_op, path_op);
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
        if (SvPOK(path_sv)) {
            STRLEN path_len;
            const char *path = SvPV(path_sv, path_len);

            /* Validate: non-empty path with at least one component */
            const char *p = path;
            while (p < path + path_len && *p == '/') p++;
            if (p >= path + path_len) {
                croak("Cannot set root");
            }

            /* Build: $data->{a}{b}{c} = $value */
            OP *lvalue = kw_build_deref_chain_lvalue(aTHX_ data_op, path, path_len);

            /* Mark as lvalue for proper autovivification */
            lvalue = op_lvalue(lvalue, OP_SASSIGN);

            *out = newBINOP(OP_SASSIGN, 0, value_op, lvalue);

            /* Free the constant path op */
            op_free(path_op);

            return KEYWORD_PLUGIN_EXPR;
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
    *out = kw_build_dynamic_pathdelete(aTHX_ data_op, path_op);
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
    *out = kw_build_dynamic_pathexists(aTHX_ data_op, path_op);
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

    if (path_len == 0) {
        RETVAL = SvREFCNT_inc(data);
    } else {
        SV *parent = navigate_to_parent(aTHX_ data, path_str, path_len, &final_key, &final_key_len, 0);

        /* final_key == NULL means path refers to root (e.g., "/" or "///") */
        if (!final_key) {
            RETVAL = parent ? SvREFCNT_inc(parent) : &PL_sv_undef;
        } else if (!parent || !SvROK(parent)) {
            RETVAL = &PL_sv_undef;
        } else {
            SV *inner = SvRV(parent);
            svtype t = SvTYPE(inner);

            if (t == SVt_PVHV) {
                SV **val = hv_fetch((HV*)inner, final_key, final_key_len, 0);
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

    if (path_len == 0) {
        croak("Cannot set root");
    }

    SV *parent = navigate_to_parent(aTHX_ data, path_str, path_len, &final_key, &final_key_len, 1);

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
        if (UNLIKELY(!hv_store((HV*)inner, final_key, final_key_len, copy, 0))) {
            SvREFCNT_dec(copy);
            croak("Failed to store value");
        }
    } else if (t == SVt_PVAV) {
        IV idx;
        if (!is_array_index(final_key, final_key_len, &idx)) {
            SvREFCNT_dec(copy);
            croak("Invalid array index");
        }
        if (UNLIKELY(!av_store((AV*)inner, idx, copy))) {
            SvREFCNT_dec(copy);
            croak("Failed to store value");
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

    if (path_len == 0) {
        croak("Cannot delete root");
    }

    SV *parent = navigate_to_parent(aTHX_ data, path_str, path_len, &final_key, &final_key_len, 0);

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
            RETVAL = hv_delete((HV*)inner, final_key, final_key_len, 0);
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

    if (path_len == 0) {
        RETVAL = 1;
    } else {
        SV *parent = navigate_to_parent(aTHX_ data, path_str, path_len, &final_key, &final_key_len, 0);

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
                RETVAL = hv_exists((HV*)inner, final_key, final_key_len);
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
            STRLEN klen;
            const char *kstr = SvPV(*key_ptr, klen);
            SV **val = hv_fetch((HV*)inner, kstr, klen, 0);
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
            STRLEN klen;
            const char *kstr = SvPV(*key_ptr, klen);
            SV **val = hv_fetch((HV*)inner, kstr, klen, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                SV **next_key = av_fetch(path_av, i + 1, 0);
                IV dummy;
                SV *new_ref = (next_key && *next_key && sv_to_index(aTHX_ *next_key, &dummy))
                    ? newRV_noinc((SV*)newAV())
                    : newRV_noinc((SV*)newHV());
                if (UNLIKELY(!hv_store((HV*)inner, kstr, klen, new_ref, 0))) {
                    SvREFCNT_dec(new_ref);
                    croak("Failed to store intermediate value");
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
                    croak("Failed to store intermediate value");
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
        STRLEN klen;
        const char *kstr = SvPV(*final_key_ptr, klen);
        if (UNLIKELY(!hv_store((HV*)inner, kstr, klen, copy, 0))) {
            SvREFCNT_dec(copy);
            croak("Failed to store value");
        }
    } else if (t == SVt_PVAV) {
        IV idx;
        if (UNLIKELY(!sv_to_index(aTHX_ *final_key_ptr, &idx))) {
            SvREFCNT_dec(copy);
            croak("Invalid array index");
        }
        if (UNLIKELY(!av_store((AV*)inner, idx, copy))) {
            SvREFCNT_dec(copy);
            croak("Failed to store value");
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
            STRLEN klen;
            const char *kstr = SvPV(*key_ptr, klen);
            SV **val = hv_fetch((HV*)inner, kstr, klen, 0);
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
        STRLEN klen;
        const char *kstr = SvPV(*final_key_ptr, klen);
        RETVAL = hv_exists((HV*)inner, kstr, klen);
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
            STRLEN klen;
            const char *kstr = SvPV(*key_ptr, klen);
            SV **val = hv_fetch((HV*)inner, kstr, klen, 0);
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
        STRLEN klen;
        const char *kstr = SvPV(*final_key_ptr, klen);
        RETVAL = hv_delete((HV*)inner, kstr, klen, 0);
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

        while (c < end) {
            if (UNLIKELY(!SvROK(current))) {
                RETVAL = &PL_sv_undef;
                goto done;
            }

            SV *inner = SvRV(current);
            svtype t = SvTYPE(inner);

            if (LIKELY(t == SVt_PVHV)) {
                SV **val = hv_fetch((HV*)inner, c->str, c->len, 0);
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

    /* Navigate to parent, creating intermediate structures as needed */
    while (c < last) {
        if (UNLIKELY(!SvROK(current))) croak("Cannot navigate to path");

        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            SV **val = hv_fetch((HV*)inner, c->str, c->len, 0);
            if (UNLIKELY(!val || !*val || !SvROK(*val))) {
                /* Create intermediate structure using pre-computed type */
                SV *new_ref = c->next_is_array
                    ? newRV_noinc((SV*)newAV())
                    : newRV_noinc((SV*)newHV());
                if (UNLIKELY(!hv_store((HV*)inner, c->str, c->len, new_ref, 0))) {
                    SvREFCNT_dec(new_ref);
                    croak("Failed to store intermediate value");
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
                    croak("Failed to store intermediate value");
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
        if (UNLIKELY(!hv_store((HV*)inner, last->str, last->len, copy, 0))) {
            SvREFCNT_dec(copy);
            croak("Failed to store value");
        }
    } else if (t == SVt_PVAV) {
        if (UNLIKELY(!last->is_numeric)) { SvREFCNT_dec(copy); croak("Invalid array index"); }
        if (UNLIKELY(!av_store((AV*)inner, last->idx, copy))) {
            SvREFCNT_dec(copy);
            croak("Failed to store value");
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

        while (c < last) {
            if (UNLIKELY(!SvROK(current))) {
                RETVAL = 0;
                goto done;
            }
            SV *inner = SvRV(current);
            svtype t = SvTYPE(inner);

            if (LIKELY(t == SVt_PVHV)) {
                SV **val = hv_fetch((HV*)inner, c->str, c->len, 0);
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
                RETVAL = hv_exists((HV*)inner, last->str, last->len);
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

    while (c < last) {
        if (UNLIKELY(!SvROK(current))) {
            RETVAL = &PL_sv_undef;
            goto done;
        }
        SV *inner = SvRV(current);
        svtype t = SvTYPE(inner);

        if (LIKELY(t == SVt_PVHV)) {
            SV **val = hv_fetch((HV*)inner, c->str, c->len, 0);
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
            RETVAL = hv_delete((HV*)inner, last->str, last->len, 0);
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
        CompiledPath *cp = INT2PTR(CompiledPath*, SvIV(SvRV(self)));
        /* Validate magic before freeing to prevent crashes from invalid objects */
        if (cp && cp->magic == COMPILED_PATH_MAGIC) {
            free_compiled_path(aTHX_ cp);
        }
    }

MODULE = Data::Path::XS    PACKAGE = Data::Path::XS

BOOT:
    {
        /* Register custom ops for dynamic paths */
        XopENTRY_set(&xop_pathget, xop_name, "pathget_dynamic");
        XopENTRY_set(&xop_pathget, xop_desc, "dynamic path get");
        Perl_custom_op_register(aTHX_ pp_pathget_dynamic, &xop_pathget);

        XopENTRY_set(&xop_pathset, xop_name, "pathset_dynamic");
        XopENTRY_set(&xop_pathset, xop_desc, "dynamic path set");
        Perl_custom_op_register(aTHX_ pp_pathset_dynamic, &xop_pathset);

        XopENTRY_set(&xop_pathdelete, xop_name, "pathdelete_dynamic");
        XopENTRY_set(&xop_pathdelete, xop_desc, "dynamic path delete");
        Perl_custom_op_register(aTHX_ pp_pathdelete_dynamic, &xop_pathdelete);

        XopENTRY_set(&xop_pathexists, xop_name, "pathexists_dynamic");
        XopENTRY_set(&xop_pathexists, xop_desc, "dynamic path exists");
        Perl_custom_op_register(aTHX_ pp_pathexists_dynamic, &xop_pathexists);

        boot_xs_parse_keyword(0.40);
        register_xs_parse_keyword("pathget", &hooks_pathget, NULL);
        register_xs_parse_keyword("pathset", &hooks_pathset, NULL);
        register_xs_parse_keyword("pathdelete", &hooks_pathdelete, NULL);
        register_xs_parse_keyword("pathexists", &hooks_pathexists, NULL);
    }
