#define NEED_utf8_to_uvchr_buf
#include "dds_engine.h"

/* Recognize decimal spellings accepted for unquoted output, excluding
 * leading-zero integers and trailing-zero fractions.
 */
static bool dds_decimal(const char *p, STRLEN len)
{
    STRLEN i = 0;

    if (!len)
        return FALSE;
    if (p[i] == '-' && ++i == len)
        return FALSE;

    if (p[i] == '0')
        i++;
    else if (p[i] >= '1' && p[i] <= '9')
        while (i < len && p[i] >= '0' && p[i] <= '9')
            i++;
    else
        return FALSE;
    if (i == len)
        return TRUE;

    if (p[i++] != '.' || i == len)
        return FALSE;
    while (i < len && p[i] >= '0' && p[i] <= '9')
        i++;

    return i == len && p[len - 1] != '0';
}

/* Build a mortal double-quoted Perl expression, escaping interpolation and
 * controls while preserving the input's UTF-8 flag.
 */
SV *dds_qquote(pTHX_ SV *value)
{
    STRLEN len, offset = 0, chars = 0;
    const U8 *p = (const U8 *)SvPV(value, len);
    SV *out = newSVpvs("\"");
    bool force_unicode = SvUTF8(value);

    /* A Latin-1-only UTF-8 value needs a Unicode escape to keep its flag
     * when the generated literal is evaluated. Empty strings need a seed. */
    if (force_unicode) {
        STRLEN i;

        for (i = 0; i < len;) {
            STRLEN width;
            UV ch = utf8_to_uvchr_buf(p + i, p + len, &width);

            if (ch > 255) {
                force_unicode = FALSE;
                break;
            }
            i += width;
        }
        if (!len) {
            SvREFCNT_dec(out);
            return DDS_TEMP(newSVpvs("substr(\"\\N{U+100}\",0,0)"));
        }
    }

    while (offset < len) {
        STRLEN width = 1;
        UV ch = p[offset];

        if (SvUTF8(value))
            ch = utf8_to_uvchr_buf(p + offset, p + len, &width);
        if (chars == 72) {
            sv_catpvs(out, "\".\n\t\"");
            chars = 0;
        }

        if (force_unicode && !offset) {
            sv_catpvf(out, "\\N{U+%" UVXf "}", ch);
        } else if (ch == '\\' || ch == '"' || ch == '@' || ch == '$') {
            sv_catpvs(out, "\\");
            sv_catpvn(out, (const char *)p + offset, width);
        } else if (ch == '\a')
            sv_catpvs(out, "\\a");
        else if (ch == '\b')
            sv_catpvs(out, "\\b");
        else if (ch == '\t')
            sv_catpvs(out, "\\t");
        else if (ch == '\n')
            sv_catpvs(out, "\\n");
        else if (ch == '\f')
            sv_catpvs(out, "\\f");
        else if (ch == '\r')
            sv_catpvs(out, "\\r");
        else if (ch == 27)
            sv_catpvs(out, "\\e");
        else if (ch < 32 || ch == 127 || (ch >= 128 && ch <= 255)) {
            bool next_digit = offset + width < len && isDIGIT_A(p[offset + width]);

            if (ch < 32 && !next_digit)
                sv_catpvf(out, "\\%o", (unsigned)ch);
            else
                sv_catpvf(out, "\\%03o", (unsigned)ch);
        } else if (ch > 126)
            sv_catpvf(out, "\\x{%" UVxf "}", ch);
        else
            sv_catpvn(out, (const char *)p + offset, width);

        offset += width;
        chars++;
    }

    sv_catpvs(out, "\"");
    return DDS_TEMP(out);
}

/* Choose a numeric, bareword, single-quoted or double-quoted representation
 * suitable for a hash key or scalar value.
 */
SV *dds_quote(pTHX_ SV *value, bool key)
{
    STRLEN len, i;
    const char *p = SvOK(value) ? SvPV(value, len) : "";
    SV *out;

    if (!SvOK(value))
        len = 0;
    if (key && !len)
        return DDS_TEMP(newSVpvs("\"\""));
    if (!key && SvUTF8(value))
        return dds_qquote(aTHX_ value);
    if (dds_decimal(p, len))
        return DDS_TEMP(newSVpvn(p, len));

    /* Hash keys may use barewords; values need a quoted string literal. */
    if (key) {
        i = p[0] == '-' ? 1 : 0;
        if (i < len && (isALPHA_A(p[i]) || p[i] == '_')) {
            for (i++; i < len && (isALNUMC_A(p[i]) || p[i] == '_'); i++)
                ;
            if (i == len)
                return DDS_TEMP(newSVpvn(p, len));
        }
        return dds_qquote(aTHX_ value);
    }

    for (i = 0; i < len; i++)
        if ((U8)p[i] < 32 || (U8)p[i] > 126)
            return dds_qquote(aTHX_ value);

    out = newSVpvs("'");
    for (i = 0; i < len; i++) {
        if (p[i] == '\\' || p[i] == '\'')
            sv_catpvs(out, "\\");
        sv_catpvn(out, p + i, 1);
    }

    sv_catpvs(out, "'");
    return DDS_TEMP(out);
}

/* Return a mortal byte slice while retaining the input string's UTF-8 flag. */
static SV *dds_string_slice(pTHX_ SV *name, STRLEN start, STRLEN length)
{
    STRLEN len;
    const char *p = SvPV(name, len);
    SV *slice = DDS_TEMP(newSVpvn(p + start, length));

    if (SvUTF8(name))
        SvUTF8_on(slice);
    return slice;
}

/* Find the byte offset after a run of identifier characters, decoding UTF-8
 * when the name carries that flag.
 */
static STRLEN dds_word_end(pTHX_ SV *name, STRLEN start)
{
    STRLEN len, at = start;
    const U8 *p = (const U8 *)SvPV(name, len);

    while (at < len) {
        STRLEN width = 1;
        UV ch = p[at];

        if (SvUTF8(name))
            ch = utf8_to_uvchr_buf(p + at, p + len, &width);
        if (!isWORDCHAR_uni(ch))
            break;
        at += width;
    }

    return at;
}

/* Recover a mortal inner expression from a simple or braced scalar
 * dereference, returning NULL when it cannot be safely unwrapped.
 */
SV *dds_underef(pTHX_ SV *name)
{
    STRLEN len;
    const char *p = SvPV(name, len);

    if (len > 1 && strchr("@%$", p[0])) {
        if (p[1] == '$')
            return dds_string_slice(aTHX_ name, 1, len - 1);
        if (p[1] == '{' && p[len - 1] == '}') {
            STRLEN i;
            IV depth = 0;
            char quote = 0;

            for (i = 1; i < len; i++) {
                char c = p[i];

                if (quote) {
                    if (c == '\\')
                        i++;
                    else if (c == quote)
                        quote = 0;
                } else if (c == '\'' || c == '"')
                    quote = c;
                else if (c == '{')
                    depth++;
                else if (c == '}' && --depth == 0) {
                    if (i == len - 1)
                        return dds_string_slice(aTHX_ name, 2, len - 3);
                    break;
                }
            }
        }
    }
    return NULL;
}

/* Construct a mortal expression for an array/hash child or a dereferenced
 * slot, adjusting sigils and braces for valid Perl syntax.
 */
SV *dds_child_name(pTHX_ SV *parent, char kind, SV *key, IV child_index)
{
    SV *out = DDS_TEMP(newSVsv(parent));
    STRLEN len;
    char *p = SvPV_force(out, len);

    if (kind == '[' || kind == '{') {
        SV *underef;
        bool plain = len > 1 && strchr("@%$", p[0]);

        if (len > 1 && strchr("@%", p[0]) && p[1] == '$') {
            sv_chop(out, p + 1);
            p = SvPV_force(out, len);
        }

        underef = dds_underef(aTHX_ out);
        if (plain)
            plain = dds_word_end(aTHX_ out, 1) == len;
        if (plain || underef || (p[0] == '*' && p[len - 1] == '}')) {
            bool dereferenced = p[0] == '@' || p[0] == '%';

            if (dereferenced)
                p[0] = '$';
            if (!dereferenced || underef)
                sv_catpvs(out, "->");
            p = SvPV_force(out, len);
            if (len > 3 && p[0] == '$' && p[1] == '$' && p[len - 1] == '>') {
                SV *tmp = DDS_TEMP(newSVpvs("${"));

                DDS_CAT(tmp, dds_string_slice(aTHX_ out, 1, len - 3));
                sv_catpvs(tmp, "}->");
                sv_setsv(out, tmp);
            }
        }

        if (kind == '[')
            sv_catpvf(out, "[%" IVdf "]", child_index);
        else {
            sv_catpvs(out, "{");
            DDS_CAT(out, dds_quote(aTHX_ key, TRUE));
            sv_catpvs(out, "}");
        }
    } else {
        SV *tmp = DDS_TEMP(newSVpvn(&kind, 1));

        if (strchr(p, '[') || strchr(p, '{') || p[0] == '*') {
            sv_catpvs(tmp, "{");
            DDS_CAT(tmp, out);
            sv_catpvs(tmp, "}");
        } else if (p[0] == kind && kind != '$')
            return out;
        else
            DDS_CAT(tmp, out);
        sv_setsv(out, tmp);
    }
    return out;
}

/* Derive a scalar-slot name from an aggregate expression, preserving UTF-8. */
SV *dds_clean_name(pTHX_ SV *name)
{
    STRLEN len, i;
    const char *p = SvPV(name, len);
    SV *out;

    if (!len || !strchr("@%&", p[0]))
        return DDS_TEMP(newSVsv(name));
    i = dds_word_end(aTHX_ name, 1);
    if (i == 1)
        return DDS_TEMP(newSVsv(name));

    out = DDS_TEMP(newSVpvs("$"));
    DDS_CAT(out, dds_string_slice(aTHX_ name, 1, i - 1));
    sv_catpvs(out, "_");
    DDS_CAT(out, dds_string_slice(aTHX_ name, i, len - i));
    return out;
}

/* Choose a root expression from an explicit name or a unique type-derived
 * name, honoring verbose and abbreviation settings.
 */
SV *dds_name(pTHX_ dds_ctx *ctx, SV *sv, UV root_index)
{
    AV *names = dds_array(aTHX_ ctx->object, "unames", FALSE);
    SV **entry = names ? av_fetch(names, root_index, 0) : NULL;
    SV *out;
    const char *type;

    if (entry && SvTRUE(*entry)) {
        STRLEN len;
        const char *p = SvPV(*entry, len);

        if (p[0] == '*' || p[0] == '-') {
            char sigil = '$';

            if (SvROK(sv)) {
                if (SvTYPE(SvRV(sv)) == SVt_PVAV)
                    sigil = '@';
                else if (SvTYPE(SvRV(sv)) == SVt_PVHV)
                    sigil = '%';
                else if (SvTYPE(SvRV(sv)) == SVt_PVCV)
                    sigil = '&';
            }
            out = DDS_TEMP(newSVsv(*entry));
            (void)SvPV_force(out, len);
            SvPVX(out)[0] = sigil;
        } else {
            out = DDS_TEMP(newSVpvs("$"));
            DDS_CAT(out, *entry);
        }
        return out;
    }

    if (SvROK(sv))
        type = sv_reftype(SvRV(sv), TRUE);
    else
        type = SvREADONLY(sv) && sv != &PL_sv_undef ? "RO" : "VAR";

    out = DDS_TEMP(newSVpvs("$"));
    if (!ctx->style.verbose) {
        SV *abr = DDS_TEMP(newSVpvs(""));
        const char *p = type, *part;
        STRLEN n;

        while ((part = strstr(p, "::"))) {
            if (part > p)
                sv_catpvn(abr, p, 1);
            p = part + 2;
        }

        sv_catpv(abr, p);
        hv_store(ctx->abbreviations, type, (I32)strlen(type), newSVpv(type, 0), 0);
        for (n = 1; n <= SvCUR(abr); n++) {
            SV **old = hv_fetch(ctx->abbreviations, SvPVX(abr), n, 0);

            if (!old || strEQ(DDS_PV(*old), type))
                break;
        }

        if (n <= SvCUR(abr)) {
            hv_store(ctx->abbreviations, SvPVX(abr), n, newSVpv(type, 0), 0);
            sv_catpvn(out, SvPVX(abr), n);
        }
    }

    if (SvCUR(out) == 1) {
        const char *p;

        for (p = type; *p; p++) {
            if (p[0] == ':' && p[1] == ':') {
                sv_catpvs(out, "_");
                p++;
            } else if (isALNUMC_A(*p) || *p == '_')
                sv_catpvn(out, p, 1);
            else if (SvCUR(out) > 1)
                break;
        }
    }

    {
        SV **counter = hv_fetch(ctx->types, type, (I32)strlen(type), 1);
        UV next = SvOK(*counter) ? SvUV(*counter) + 1 : 1;

        sv_setuv(*counter, next);
        sv_catpvf(out, "%" UVuf, next);
    }

    return out;
}

/* Build a mortal Perl glob expression, shortening main-package names and
 * quoting names that require protection.
 */
SV *dds_glob_name(pTHX_ GV *gv)
{
    SV *name = DDS_TEMP(newSV(0)), *out;
    STRLEN len, i;
    const char *p;
    bool quote = FALSE;

    gv_fullname3(name, gv, NULL);
    p = SvPV(name, len);
    if (len >= 6 && memEQ(p, "main::", 6)) {
        p += 4;
        len -= 4;
    }

    for (i = 0; i < len; i++)
        if (!isALNUMC_A(p[i]) && p[i] != '_' && p[i] != ':')
            quote = TRUE;

    out = DDS_TEMP(newSVpvs("*"));
    if (quote) {
        SV *value = dds_string_slice(aTHX_ name, (STRLEN)(p - SvPVX(name)), len);

        sv_catpvs(out, "{");
        DDS_CAT(out, dds_quote(aTHX_ value, FALSE));
        sv_catpvs(out, "}");
    } else
        sv_catpvn(out, p, len);
    return out;
}

typedef struct {
    SV *key, *clean;
    NV number;
    bool numeric;
} dds_key;

/*
 * Key ordering
 *
 * Native comparators operate on prepared key records. Policy selection and
 * callbacks choose the order before values are traversed.
 */

/* Compare smart-order keys by numeric-prefix status and value, then folded
 * word text and the original key as a tie-breaker.
 */
static int dds_key_compare(const void *a, const void *b)
{
    const dds_key *left = (const dds_key *)a, *right = (const dds_key *)b;

    dTHX;
    int cmp;

    if (left->numeric != right->numeric)
        return left->numeric ? -1 : 1;
    if (left->numeric && left->number != right->number)
        return left->number < right->number ? -1 : 1;
    cmp = sv_cmp(left->clean, right->clean);
    return cmp ? cmp : sv_cmp(left->key, right->key);
}

/* Compare original key strings for lexical and alphabetical ordering. */
static int dds_key_lexical(const void *a, const void *b)
{
    dTHX;

    return sv_cmp(((const dds_key *)a)->key, ((const dds_key *)b)->key);
}

/* Compare the numeric values prepared for numeric key ordering. */
static int dds_key_numeric(const void *a, const void *b)
{
    const dds_key *left = (const dds_key *)a, *right = (const dds_key *)b;

    return left->number < right->number ? -1 : left->number > right->number ? 1 : 0;
}

/* Resolve a nonempty prefix of a supported built-in key-order mode, returning
 * NULL for an unknown or undefined mode.
 */
const char *dds_builtin_order(pTHX_ SV *mode)
{
    static const char *names[] = {"numeric", "lexical",     "alphabetical",
                                  "smart",   "intelligent", "each"};
    STRLEN len;
    const char *p;
    UV i;

    if (!SvOK(mode))
        return NULL;

    p = SvPV(mode, len);
    for (i = 0; i < sizeof(names) / sizeof(*names); i++)
        if (len && len <= strlen(names[i]) && memEQ(p, names[i], len))
            return names[i];

    return NULL;
}

/* Return a mortal ordered key list using object/class policies or native
 * sorting; expose a callback thaw action through the optional out parameter.
 */
AV *dds_keys(pTHX_ dds_ctx *ctx, HV *hv, I32 pass, SV **thaw)
{
    HV *style = dds_hash(aTHX_ ctx->object, "style", FALSE);
    HV *sorters = dds_hash(aTHX_ style, "sortkeys", FALSE);
    SV *address = DDS_TEMP(newSVpvf("#%" UVuf, PTR2UV(hv)));
    SV *class_name = dds_class(aTHX_(SV *) hv);
    SV *class_key = DDS_TEMP(newSVpvs("."));
    SV *sorter;
    AV *result;
    HE *he;
    HE *cursor = NULL;
    UV bucket = 0;
    dds_key *keys;
    SV *workspace;
    UV count = 0, capacity = HvTOTALKEYS(hv) + 1, i;
    const char *order = "smart";
    bool tied = SvTIED_mg((SV *)hv, PERL_MAGIC_tied) != NULL;

    if (tied)
        dds_callback_guard(aTHX_ ctx);

    /* Resolve the object policy first, then the class and default policies. */
    if (SvOK(class_name))
        DDS_CAT(class_key, class_name);
    sorter = dds_hget_sv(aTHX_ sorters, address);
    if (!SvTRUE(sorter)) {
        GV *method = NULL;

        sorter = dds_hget_sv(aTHX_ sorters, class_key);
        if (!SvTRUE(sorter) && SvOK(class_name))
            method = gv_fetchmethod_autoload(SvSTASH((SV *)hv), "DDS_sortkeys", 0);
        if (method && GvCV(method))
            sorter = DDS_TEMP(newRV_inc((SV *)GvCV(method)));
        if (!SvTRUE(sorter))
            sorter = dds_hget(aTHX_ sorters, ".");
    }

    if (SvTRUE(sorter) && !SvROK(sorter))
        order = dds_builtin_order(aTHX_ sorter);

    if (SvROK(sorter)) {
        AV *source = NULL;

        if (SvTYPE(SvRV(sorter)) == SVt_PVAV)
            source = (AV *)SvRV(sorter);
        else {
            SV *args[4], *values;
            SV **entry, **thaw_entry;

            args[0] = DDS_TEMP(newRV_inc((SV *)hv));
            args[1] = DDS_TEMP(newSViv(pass));
            args[2] = DDS_TEMP(newSVuv(PTR2UV(hv)));
            args[3] = class_name;
            values = dds_invoke(aTHX_ ctx, sorter, FALSE, G_ARRAY, 4, args);
            entry = av_fetch((AV *)SvRV(values), 0, 0);
            thaw_entry = av_fetch((AV *)SvRV(values), 1, 0);
            if (thaw && thaw_entry && SvTRUE(*thaw_entry))
                *thaw = *thaw_entry;

            if (entry && SvTRUE(*entry)) {
                if (!SvROK(*entry) || SvTYPE(SvRV(*entry)) != SVt_PVAV)
                    croak("Sortkeys callback must return an array reference or undef");
                source = (AV *)SvRV(*entry);
            }
        }

        if (source) {
            SSize_t k;

            result = (AV *)DDS_TEMP((SV *)newAV());
            for (k = 0; k <= av_len(source); k++) {
                SV **key = av_fetch(source, k, 0);

                av_push(result, key ? newSVsv(*key) : newSV(0));
            }
            return result;
        }

        order = "each";
    }

    if (!order)
        croak("Unknown native key order");

    /* Tied hashes can report no physical keys and still iterate values.
     * An SV-owned buffer can grow and remains protected on croak. */
    workspace = DDS_TEMP(newSV(capacity * sizeof(dds_key)));
    keys = (dds_key *)SvPVX(workspace);
    if (tied)
        hv_iterinit(hv);

    while (1) {
        /* No callbacks occur during an ordinary key walk. Walking buckets
         * avoids disturbing a caller's each(), including its lazy deletion. */
        if (tied) {
            if (!(he = hv_iternext(hv)))
                break;
        } else {
            while (!cursor && bucket < DDS_HASH_LIMIT(hv)) {
                cursor = DDS_HASH_FIRST(hv, bucket);
                bucket++;
            }
            if (!cursor)
                break;
            he = cursor;
            cursor = DDS_HASH_NEXT(hv, cursor);
            if (HeVAL(he) == &PL_sv_placeholder)
                continue;
        }

        SV *key = DDS_TEMP(newSVsv(hv_iterkeysv(he)));
        STRLEN len, j = 0, start = 0;
        const char *p = SvPV(key, len);
        dds_key *record;

        if (count == capacity) {
            capacity *= 2;
            SvGROW(workspace, capacity * sizeof(dds_key));
            keys = (dds_key *)SvPVX(workspace);
        }

        record = &keys[count++];
        Zero(record, 1, dds_key);
        record->key = key;
        record->clean = DDS_TEMP(newSVpvs(""));

        /* Smart order compares a numeric prefix, then a folded word key. */
        if (len && p[j] == '-')
            j++;
        if (j < len && p[j] >= '0' && p[j] <= '9') {
            STRLEN first = j;

            if (p[j] == '0')
                j++;
            else
                while (j < len && isDIGIT_A(p[j]) && j - first < 9)
                    j++;
            if (j == len || !isDIGIT_A(p[j])) {
                if (j < len && p[j] == '.' && j + 1 < len && isDIGIT_A(p[j + 1])) {
                    STRLEN fraction = ++j;

                    while (j < len && isDIGIT_A(p[j]) && j - fraction < 15)
                        j++;
                }
                if (j == len || !isDIGIT_A(p[j])) {
                    SV *number = DDS_TEMP(newSVpvn(p, j));

                    record->numeric = TRUE;
                    record->number = SvNV(number);
                    start = j;
                }
            }
        }

        for (j = start; j < len;) {
            STRLEN width = 1;
            UV ch = (U8)p[j];

            if (SvUTF8(key))
                ch = utf8_to_uvchr_buf((U8 *)p + j, (U8 *)p + len, &width);
            j += width;
            if (isWORDCHAR_uni(ch)) {
                U8 lower[UTF8_MAXBYTES + 1];
                STRLEN lower_len;

                toLOWER_uni(ch, lower, &lower_len);
                sv_catpvn(record->clean, (char *)lower, lower_len);
                SvUTF8_on(record->clean);
            }
        }

        if (strnEQ(order, "num", 3))
            record->number = SvNV(key);
    }

    if (strnEQ(order, "lex", 3) || strnEQ(order, "alph", 4))
        qsort(keys, count, sizeof(dds_key), dds_key_lexical);
    else if (strnEQ(order, "num", 3))
        qsort(keys, count, sizeof(dds_key), dds_key_numeric);
    else if (!strnEQ(order, "each", 4))
        qsort(keys, count, sizeof(dds_key), dds_key_compare);

    result = (AV *)DDS_TEMP((SV *)newAV());
    for (i = 0; i < count; i++)
        av_push(result, newSVsv(keys[i].key));

    return result;
}

/* Collect restricted-hash placeholder keys without disturbing the caller's
 * iterator, returning a sorted mortal array.
 */
AV *dds_hidden_keys(pTHX_ HV *hv)
{
    AV *keys = (AV *)DDS_TEMP((SV *)newAV());
    HE *he;
    UV bucket;

    if (HvARRAY(hv))
        for (bucket = 0; bucket < DDS_HASH_LIMIT(hv); bucket++)
            for (he = DDS_HASH_FIRST(hv, bucket); he; he = DDS_HASH_NEXT(hv, he))
                if (HeVAL(he) == &PL_sv_placeholder)
                    av_push(keys, newSVsv(hv_iterkeysv(he)));

    if (av_len(keys) > 0)
        sortsv(AvARRAY(keys), av_len(keys) + 1, Perl_sv_cmp);
    return keys;
}

/*
 * Regexp literals
 *
 * Inspection and quoting are separate: recover the original pattern and flags,
 * then protect them from Perl interpolation and delimiter parsing.
 */

/* Recognize a regexp referent using the representation supported by the
 * current interpreter.
 */
bool dds_is_regexp(pTHX_ SV *target)
{
#if PERL_VERSION >= 11
    return SvTYPE(target) == SVt_REGEXP;
#else
    MAGIC *magic;

    return SvTYPE(target) == SVt_PVMG && SvMAGICAL(target) &&
           (magic = mg_find(target, PERL_MAGIC_qr)) && magic->mg_obj;
#endif
}

/* Build a mortal qr expression that preserves pattern text and modifiers
 * through delimiter escaping and sigil interpolation.
 */
SV *dds_regex(pTHX_ dds_ctx *ctx, SV *rv)
{
    SV *values, *pattern, *mods, *out;
    AV *parts;
    STRLEN len, i, width;
    const U8 *p;
    static const char *delimiters[] = {"/", "!", "%", "&", "<>", "{}", "\"", "#"};
    UV best = UV_MAX, chosen = 0, d;

    values = dds_call(aTHX_ ctx, "Data::Dump::Streamer::regex", NULL, G_ARRAY, 1, &rv);
    parts = (AV *)SvRV(values);
    if (av_len(parts) != 1)
        croak("Cannot inspect regexp");
    pattern = *av_fetch(parts, 0, 0);
    mods = *av_fetch(parts, 1, 0);
    p = (const U8 *)SvPV(pattern, len);

    /* In /x patterns a literal whitespace character and an escaped one
     * have different meanings. Keep Unicode Pattern_White_Space literal
     * too. Its five non-ASCII members are fixed by Unicode; the parser's
     * internal classifier is not exposed to extensions on newer Perls. */
    if (strchr(DDS_PV(mods), 'x')) {
        bool preserve_layout = FALSE;

        for (i = 0; i < len; i += width) {
            UV ch = p[i];

            width = 1;
            if (SvUTF8(pattern))
                ch = utf8_to_uvchr_buf(p + i, p + len, &width);

            if (ch < 32 || ch == 127 || ch == 0x85 || ch == 0x200e || ch == 0x200f ||
                ch == 0x2028 || ch == 0x2029) {
                preserve_layout = TRUE;
                break;
            }
        }

        if (preserve_layout) {
            out = DDS_TEMP(newSVpvs("do { my $p = "));
            DDS_CAT(out, dds_qquote(aTHX_ pattern));
            sv_catpvs(out, "; qr/$p/");
            DDS_CAT(out, mods);
            sv_catpvs(out, " }");
            return out;
        }
    }

    /* Prefer a delimiter that introduces the fewest new escapes. */
    for (d = 0; d < sizeof(delimiters) / sizeof(*delimiters); d++) {
        UV bad = 0;

        for (i = 0; i < len; i++)
            if (strchr(delimiters[d], p[i]))
                bad++;
        if (bad < best) {
            best = bad;
            chosen = d;
        }
        if (!bad)
            break;
    }

    /* Sigil interpolation below uses slash delimiters so q(...) remains
     * independent of the surrounding regexp's quoting rules. */
    for (i = 0; i < len; i++) {
        if (p[i] == '\\' && i + 1 < len) {
            i++;
            continue;
        }
        if (p[i] == '$' || p[i] == '@') {
            chosen = 0;
            break;
        }
    }

    out = DDS_TEMP(newSVpvs("qr"));
    sv_catpvn(out, delimiters[chosen], 1);

    for (i = 0; i < len; i += width) {
        UV ch = p[i];

        width = 1;
        if (SvUTF8(pattern))
            ch = utf8_to_uvchr_buf(p + i, p + len, &width);
        if (ch == '\\' && i + 1 < len) {
            STRLEN next_width = 1;

            if (SvUTF8(pattern))
                (void)utf8_to_uvchr_buf(p + i + 1, p + len, &next_width);

            /* Raw UTF-8 bytes need an SV carrying their encoding so the
             * output and its enclosing source string are upgraded too. */
            if (next_width > 1)
                DDS_CAT(out, dds_string_slice(aTHX_ pattern, i, 1 + next_width));
            else
                sv_catpvn(out, (const char *)p + i, 1 + next_width);
            width = 1 + next_width;
        } else if (ch == '@' || (ch == '$' && i + 1 < len && !strchr("()| \t\r\n", p[i + 1]))) {
            STRLEN end = i + width;

            while (end < len && (p[end] == '{' || p[end] == '['))
                end++;

            /* Capture the entire opening-bracket run, as in Yves Orton's
             * Data::Dumper sigil-interpolation patch. Interpolation then
             * gives the regexp parser exactly the original pattern text. */
            sv_catpvs(out, "${\\q(");
            sv_catpvn(out, (const char *)p + i, end - i);
            sv_catpvs(out, ")}");
            width = end - i;
        } else if (ch < 32 || ch > 126)
            sv_catpvf(out, "\\x{%" UVxf "}", ch);
        else {
            if (strchr(delimiters[chosen], (char)ch))
                sv_catpvs(out, "\\");
            sv_catpvn(out, (const char *)p + i, width);
        }
    }

    sv_catpvn(out, delimiters[chosen] + strlen(delimiters[chosen]) - 1, 1);
    DDS_CAT(out, mods);

    return out;
}

/* Send text to the configured print callback or append it to buffered output,
 * maintaining list-context output chunks when requested.
 */
void dds_write(pTHX_ dds_ctx *ctx, SV *text)
{
    if (ctx->printer) {
        SV *args[1];

        args[0] = text;
        (void)dds_call(aTHX_ ctx, "print", ctx->printer, G_VOID | G_DISCARD, 1, args);
    } else {
        DDS_CAT(ctx->out, text);
        if (ctx->chunks) {
            SV **last =
                av_len(ctx->chunks) >= 0 ? av_fetch(ctx->chunks, av_len(ctx->chunks), 0) : NULL;

            if (!last || strchr(DDS_PV(*last), '\n') || SvCUR(*last) > 4000)
                av_push(ctx->chunks, newSVsv(text));
            else
                DDS_CAT(*last, text);
        }
    }
}

/* Write a NUL-terminated C string through the common output path. */
void dds_put(pTHX_ dds_ctx *ctx, const char *text)
{
    dds_write(aTHX_ ctx, DDS_TEMP(newSVpv(text, 0)));
}

/* Write a nonnegative run of spaces for output indentation and alignment. */
void dds_spaces(pTHX_ dds_ctx *ctx, IV count)
{
    SV *space;

    if (count < 0)
        count = 0;

    space = DDS_TEMP(newSVpvs(""));
    SvGROW(space, (STRLEN)count + 1);
    SvPOK_on(space);
    SvCUR_set(space, count);
    memset(SvPVX(space), ' ', count);
    SvPVX(space)[count] = 0;
    dds_write(aTHX_ ctx, space);
}
