#define NEED_utf8_to_uvchr_buf
#include "dds_engine.h"

/* The public facade remains a blessed hash for API compatibility. All
 * configuration and ordinary entry points are native XSUBs. */
/* Create a blessed facade hash with default style values and empty per-class
 * policies.
 */
SV *dds_new_object(pTHX_ SV *class_name)
{
    HV *object = newHV(), *style = newHV();
    AV *opts = newAV();
    SV *self = DDS_TEMP(newRV_noinc((SV *)object));

    hv_stores(object, "style", newRV_noinc((SV *)style));

    /* Keep the facade's defaults in the same form as option setters. */
#define STR(key, value) hv_stores(style, key, newSVpv(value, 0))
#define NUM(key, value) hv_stores(style, key, newSViv(value))
    STR("hashsep", "=>");
    STR("arysep", ",");
    STR("pairsep", ",");
    STR("optspace", " ");
    STR("bless", "bless()");
    STR("freezer", "DDS_freeze");
    STR("eclipsename", "%s_eclipse_%d");
    STR("codestub", "sub { Carp::confess \"Dumped code stub!\" }");
    STR("formatstub", "do{ local *F; eval \"format F =\\nFormat Stub\\n.\\n\"; *F{FORMAT} }");

    NUM("compress", 0);
    NUM("indent", 2);
    NUM("indentcols", 2);
    NUM("indentkeys", 1);
    NUM("declare", 0);
    NUM("verbose", 1);
    NUM("dumpglob", 1);
    NUM("deparseglob", 1);
    NUM("deparse", 1);
    NUM("rle", 1);
    NUM("ro", 1);
    NUM("dualvars", 1);
    NUM("purity", 1);
    NUM("terse", 0);
    NUM("special", 0);
#undef STR
#undef NUM

    hv_stores(style, "compressor",
              newRV_inc((SV *)get_cv("Data::Dump::Streamer::_compressor", GV_ADD)));
    hv_stores(style, "sortkeys", newRV_noinc((SV *)newHV()));
    hv_stores(style, "freeze_class", newRV_noinc((SV *)newHV()));
    hv_stores(style, "ignore", newRV_noinc((SV *)newHV()));
    av_push(opts, newSVpvs("-sCi2v'Useless const omitted'"));
    hv_stores(style, "deparseopts", newRV_noinc((SV *)opts));

    hv_stores(object, "cataloged", newSViv(0));
    sv_bless(self, gv_stashsv(class_name, GV_ADD));

    return self;
}

/* Return an object invocant or call the class's constructor, respecting
 * inherited and overridden constructors.
 */
SV *dds_safe_self(pTHX_ SV *self)
{
    if (SvROK(self))
        return self;

    /* Respect an inherited or overridden constructor on class calls. */
    return dds_invoke(aTHX_ NULL, DDS_TEMP(newSVpvs("new")), TRUE, G_SCALAR, 1, &self);
}

/* Return an idle dumper unchanged, or clone its facade and retained roots so
 * reentrant callbacks have independent traversal state.
 */
SV *dds_working_self(pTHX_ SV *self)
{
    dds_ctx *ctx = dds_context(aTHX_ self), *working;
    HV *copy;
    SV *result;
    HE *he;
    UV i;

    if (!ctx->busy)
        return self;

    /* A callback may reuse this dumper. Give it independent traversal
     * state while preserving the facade and captured root values. */
    copy = newHV();
    result = DDS_TEMP(sv_bless(newRV_noinc((SV *)copy), SvSTASH((SV *)ctx->object)));
    hv_iterinit(ctx->object);
    while ((he = hv_iternext(ctx->object)))
        hv_store_ent(copy, hv_iterkeysv(he), newSVsv(HeVAL(he)), 0);

    working = dds_context(aTHX_ result);
    if (ctx->root_count) {
        Newxz(working->roots, ctx->root_count, dds_root);
        working->root_count = working->root_capacity = ctx->root_count;
        for (i = 0; i < ctx->root_count; i++) {
            working->roots[i].sv = SvREFCNT_inc(ctx->roots[i].sv);
            working->roots[i].count = ctx->roots[i].count;
            working->roots[i].readonly = ctx->roots[i].readonly;
            working->roots[i].lexical = ctx->roots[i].lexical;
        }
    }

    hv_delete(copy, "lexicals", 8, G_DISCARD);
    return result;
}

/* Invalidate public catalogue status and clear freezer-policy caches before
 * analyzing new input.
 */
static void dds_reset_facade(pTHX_ dds_ctx *ctx)
{
    hv_delete(ctx->object, "cache_freeze_class", 18, G_DISCARD);
    hv_delete(ctx->object, "cache_skip_freeze", 17, G_DISCARD);
    hv_stores(ctx->object, "cataloged", newSViv(0));
}

/*
 * Guarded operations
 *
 * Capture and analysis share an operation guard with output. Entry points
 * adapt that result to Perl calling context.
 */

/* Run capture, analysis or emission inside an exception-safe operation,
 * returning the dumper, text or chunk array appropriate to the call.
 */
static SV *dds_run(pTHX_ SV *self, I32 argc, SV **args, I32 gimme, bool analyze_only)
{
    dds_ctx *ctx = dds_context(aTHX_ self);

    void *operation;
    SV *result = DDS_TEMP(newSV(0));

    ENTER;
    operation = dds_operation_begin(aTHX_ ctx, self);
    if (analyze_only || argc || !ctx->cataloged)
        dds_reset_facade(aTHX_ ctx);
    if (argc)
        dds_capture(aTHX_ ctx, argc, args);

    if (analyze_only) {
        dds_analyze(aTHX_ ctx);
        sv_setsv(result, self);
    } else {
        static const char *globals[] = {"\\", "\"", ","};
        UV i;

        /* Output must not inherit the caller's record or field separators. */
        for (i = 0; i < 3; i++) {
            GV *gv = gv_fetchpv(globals[i], GV_ADD, SVt_PV);
            SV *local = save_scalar(gv);

            sv_setpvs(local, "");
            SvSETMAGIC(local);
        }

        dds_output(aTHX_ ctx, gimme);

        if (ctx->printer || gimme == G_VOID)
            sv_setsv(result, self);
        else if (gimme == G_ARRAY)
            sv_setsv(result, DDS_TEMP(newRV_inc((SV *)ctx->chunks)));
        else
            sv_setsv(result, ctx->out);
    }

    dds_operation_commit(operation);
    LEAVE;

    return result;
}

/* Replace captured roots under the operation guard, invalidating cached
 * analysis without producing output.
 */
static void dds_capture_api(pTHX_ SV *self, I32 count, SV **args)
{
    dds_ctx *ctx = dds_context(aTHX_ self);

    void *operation;

    ENTER;
    operation = dds_operation_begin(aTHX_ ctx, self);
    dds_reset_facade(aTHX_ ctx);
    dds_capture(aTHX_ ctx, count, args);
    dds_operation_commit(operation);
    LEAVE;
}

/* Normalize and validate supplied root names, then store an owned name list on
 * the facade.
 */
static void dds_set_names(pTHX_ HV *object, I32 count, SV **args)
{
    AV *names = (AV *)DDS_TEMP((SV *)newAV());
    AV *source;
    SSize_t i, last;

    if (count == 1 && SvROK(args[0]) && SvTYPE(SvRV(args[0])) == SVt_PVAV) {
        source = (AV *)DDS_TEMP(SvREFCNT_inc(SvRV(args[0])));
    } else {
        /* A magical name can grow the Perl stack or replace another
         * argument. Retain the input SVs before fetching any values. */
        source = (AV *)DDS_TEMP((SV *)newAV());
        for (i = 0; i < count; i++)
            av_push(source, SvREFCNT_inc(args[i]));
    }

    last = av_len(source);
    for (i = 0; i <= last; i++) {
        SV **entry = av_fetch(source, i, 0);
        SV *value, *name;
        STRLEN len, j = 0;
        const U8 *p;

        if (!entry)
            continue;

        value = DDS_TEMP(SvREFCNT_inc(*entry));
        name = DDS_TEMP(newSVsv(value));
        if (!SvOK(name))
            continue;

        /* Normalize the sigil before checking the identifier itself. */
        p = (const U8 *)SvPV_force(name, len);
        if (len && strchr("@%&-", p[0]))
            SvPVX(name)[0] = '*';
        else if (len && p[0] == '$') {
            sv_chop(name, (char *)p + 1);
            p = (U8 *)SvPV(name, len);
        }

        if (len && p[0] == '*')
            j++;
        if (len && j == len)
            croak("Bad name '%s'", DDS_PV(name));
        while (j < len) {
            STRLEN width = 1;
            UV ch = p[j];

            if (SvUTF8(name))
                ch = utf8_to_uvchr_buf(p + j, p + len, &width);
            if (!isWORDCHAR_uni(ch))
                croak("Bad name '%s'", DDS_PV(name));
            j += width;
        }

        av_push(names, newSVsv(name));
    }

    hv_stores(object, "unames", newRV_inc((SV *)names));
}

/* Build a mortal policy key: an address key for a reference, or a Unicode-
 * preserving class/default key for a string.
 */
static SV *dds_policy_key(pTHX_ SV *value)
{
    SV *key;

    if (SvROK(value))
        return DDS_TEMP(newSVpvf("#%" UVuf, PTR2UV(SvRV(value))));

    key = DDS_TEMP(newSVpvs("."));
    if (SvOK(value))
        sv_catsv(key, value);
    return key;
}

/* Read or update key-order policies, resolving built-in modes and class
 * methods into values the native sorter can use.
 */
static SV *dds_key_order(pTHX_ SV *self, I32 count, SV **args)
{
    HV *style = dds_hash(aTHX_ dds_context(aTHX_ self)->object, "style", TRUE);
    HV *sorters = dds_hash(aTHX_ style, "sortkeys", TRUE);
    HV *strings = dds_hash(aTHX_ style, "sortkeys_string", TRUE);
    I32 i;

    if (count > 2 && count % 2)
        croak("KeyOrder() must have an even number of arguments");

    for (i = 0; i < count; i += 2) {
        SV *key = dds_policy_key(aTHX_ args[i]);
        SV *value;

        if (i + 1 == count) {
            HE *entry = hv_fetch_ent(strings, key, 0, 0);

            if (entry && SvTRUE(HeVAL(entry)))
                return HeVAL(entry);
            entry = hv_fetch_ent(sorters, key, 0, 0);
            return entry ? HeVAL(entry) : &PL_sv_undef;
        }

        value = args[i + 1];
        hv_delete_ent(strings, key, G_DISCARD, 0);
        if (!SvOK(value)) {
            hv_delete_ent(sorters, key, G_DISCARD, 0);
            continue;
        }

        if (!SvROK(value)) {
            const char *builtin = dds_builtin_order(aTHX_ value);

            if (builtin) {
                hv_store_ent(strings, key, newSVsv(value), 0);
                value = DDS_TEMP(newSVpv(builtin, 0));
            } else {
                HV *stash;
                GV *method;

                if (SvROK(args[i]) || !SvTRUE(args[i]))
                    croak("Unblessed or per object Sortkeys() must be coderefs:'%s'",
                          DDS_PV(value));
                stash = gv_stashsv(args[i], 0);
                method = stash ? gv_fetchmethod_autoload(stash, DDS_PV(value), 0) : NULL;
                if (!method || !GvCV(method))
                    croak("Unknown sortkeys '%s'", DDS_PV(value));
                hv_store_ent(strings, key, newSVsv(value), 0);
                value = DDS_TEMP(newRV_inc((SV *)GvCV(method)));
            }
        } else if (SvTYPE(SvRV(value)) != SVt_PVAV && SvTYPE(SvRV(value)) != SVt_PVCV)
            croak("Can't use value as KeyOrder() value");
        hv_store_ent(sorters, key, newSVsv(value), 0);
    }
    return self;
}

/* Implement the public constructor, returning a newly initialized dumper for
 * the requested class.
 */
static XS(dds_xs_new)
{
    dXSARGS;
    if (!items)
        croak("Usage: Data::Dump::Streamer->new()");
    ST(0) = dds_new_object(aTHX_ ST(0));
    XSRETURN(1);
}

/* Normalize the invocant and, for the working-self variant, isolate a
 * reentrant operation before returning it to Perl.
 */
static XS(dds_xs_safe_self)
{
    dXSARGS;
    SV *self;

    if (!items)
        croak("Missing dumper invocant");
    self = dds_safe_self(aTHX_ ST(0));
    if (CvXSUBANY(cv).any_i32)
        self = dds_working_self(aTHX_ self);
    ST(0) = DDS_TEMP(newSVsv(self));
    XSRETURN(1);
}

/* Implement Data and Out, forwarding arguments and Perl context and unpacking
 * list-context output chunks.
 */
static XS(dds_xs_io)
{
    dXSARGS;
    SV *self, *result;
    I32 gimme = GIMME_V;
    bool data = CvXSUBANY(cv).any_i32;

    if (!items)
        croak("Missing dumper invocant");
    self = DDS_TEMP(newSVsv(dds_working_self(aTHX_ dds_safe_self(aTHX_ ST(0)))));
    PUTBACK;
    result = dds_run(aTHX_ self, items - 1, &ST(1), gimme, data);
    SPAGAIN;
    if (!data && gimme == G_ARRAY && SvROK(result) && SvTYPE(SvRV(result)) == SVt_PVAV) {
        AV *chunks = (AV *)SvRV(result);
        SSize_t i, count = av_len(chunks) + 1;

        EXTEND(SP, count);
        for (i = 0; i < count; i++)
            ST(i) = DDS_TEMP(newSVsv(*av_fetch(chunks, i, 0)));
        XSRETURN(count);
    }
    ST(0) = result;
    XSRETURN(1);
}

/* Implement the capture-only entry points, replacing roots and returning the
 * working dumper for chaining.
 */
static XS(dds_xs_capture)
{
    dXSARGS;
    SV *self;

    if (!items)
        croak("Missing dumper invocant");
    self = DDS_TEMP(newSVsv(dds_working_self(aTHX_ dds_safe_self(aTHX_ ST(0)))));
    dds_capture_api(aTHX_ self, items - 1, &ST(1));
    ST(0) = DDS_TEMP(newSVsv(self));
    XSRETURN(1);
}

typedef enum {
    DDS_DUMP,
    DDS_DUMP_TEXT,
    DDS_DUMP_VARS,
    DDS_DUMP_LEX
} dds_dump_kind;

/* Dispatch Dump, Dumper, DumpVars and DumpLex, handling invocants, naming,
 * scalar capture and context-sensitive output.
 */
static XS(dds_xs_dump)
{
    dXSARGS;
    I32 first = 0, gimme = GIMME_V;
    const dds_dump_kind kind = (dds_dump_kind)CvXSUBANY(cv).any_i32;
    const bool want_text = kind == DDS_DUMP_TEXT;
    const bool named_pairs = kind == DDS_DUMP_VARS;
    bool lexical_names, capture_empty, capture;
    SV *self = NULL, *result;
    AV *values = NULL, *names = NULL;

    /* Accept either the exported function form or an existing dumper. */
    if (items && SvROK(ST(0)) && sv_derived_from(ST(0), "Data::Dump::Streamer")) {
        self = DDS_TEMP(newSVsv(dds_working_self(aTHX_ ST(0))));
        first++;
    }
    if (!self)
        self = dds_new_object(aTHX_ DDS_TEMP(newSVpvs("Data::Dump::Streamer")));

    lexical_names = kind == DDS_DUMP_LEX && SvTRUE(get_sv("Data::Dump::Streamer::HasPadWalker", 0));

    /* Scalar-context named entry points capture even an empty argument list.
     * Output calls without arguments reuse existing roots. Without PadWalker,
     * DumpLex follows ordinary Dump capture rules. */
    capture_empty = named_pairs || lexical_names;

    if (lexical_names) {
        SV *lexnames;

        PUTBACK;
        lexnames = dds_invoke(aTHX_ dds_context(aTHX_ self),
                              DDS_TEMP(newSVpvs("Data::Dump::Streamer::_xs_lexical_names")), FALSE,
                              G_SCALAR, items - first, &ST(first));
        SPAGAIN;
        if (SvROK(lexnames) && SvTYPE(SvRV(lexnames)) == SVt_PVAV) {
            AV *source = (AV *)SvRV(lexnames);

            dds_set_names(aTHX_ dds_context(aTHX_ self)->object, av_len(source) + 1,
                          AvARRAY(source));
        }
    }

    if (named_pairs) {
        I32 i;

        values = (AV *)DDS_TEMP((SV *)newAV());
        names = (AV *)DDS_TEMP((SV *)newAV());
        if ((items - first) % 2) {
            warn("Odd number of arguments in DumpVars");
            items--;
        }

        for (i = first; i < items; i += 2) {
            av_push(names, newSVsv(ST(i)));
            av_push(values, SvREFCNT_inc(ST(i + 1)));
        }

        dds_set_names(aTHX_ dds_context(aTHX_ self)->object, av_len(names) + 1, AvARRAY(names));
    }

    /* Scalar Dump captures for chaining; Dumper always produces text. */
    capture = items > first || capture_empty;
    if (!want_text && ((gimme == G_SCALAR && capture) || (!items && !capture_empty))) {
        if (capture)
            dds_capture_api(aTHX_ self, values ? av_len(values) + 1 : items - first,
                            values ? AvARRAY(values) : &ST(first));
        ST(0) = DDS_TEMP(newSVsv(self));
        XSRETURN(1);
    }

    PUTBACK;
    result = dds_run(aTHX_ self, values ? av_len(values) + 1 : items - first,
                     values ? AvARRAY(values) : &ST(first), want_text ? G_SCALAR : gimme, FALSE);
    SPAGAIN;

    if (!want_text && gimme == G_ARRAY && SvROK(result) && SvTYPE(SvRV(result)) == SVt_PVAV) {
        AV *chunks = (AV *)SvRV(result);
        SSize_t i, count = av_len(chunks) + 1;

        EXTEND(SP, count);
        for (i = 0; i < count; i++)
            ST(i) = DDS_TEMP(newSVsv(*av_fetch(chunks, i, 0)));
        XSRETURN(count);
    }

    ST(0) = result;
    XSRETURN(1);
}

#define DDS_OPTION_LIST(X) \
    X(DECLARE, "declare", "Declare") \
    X(INDENT_COLS, "indentcols", "IndentCols") \
    X(INDENT_KEYS, "indentkeys", "IndentKeys") \
    X(VERBOSE, "verbose", "Verbose") \
    X(DUMP_GLOB, "dumpglob", "DumpGlob") \
    X(DEPARSE, "deparse", "Deparse") \
    X(DEPARSE_GLOB, "deparseglob", "DeparseGlob") \
    X(DEPARSE_FORMAT, "deparseformat", "DeparseFormat") \
    X(CODE_STUB, "codestub", "CodeStub") \
    X(FORMAT_STUB, "formatstub", "FormatStub") \
    X(RLE, "rle", "Rle") \
    X(PURITY, "purity", "Purity") \
    X(DUAL_VARS, "dualvars", "DualVars") \
    X(ECLIPSE_NAME, "eclipsename", "EclipseName") \
    X(COMPRESS, "compress", "Compress") \
    X(COMPRESSOR, "compressor", "Compressor") \
    X(OPT_SPACE, "optspace", "OptSpace") \
    X(TERSE, "terse", "Terse") \
    X(INDENT, "indent", "Indent") \
    X(TO, "fh", "To") \
    X(DEPARSE_OPTS, "deparseopts", "DeparseOpts") \
    X(FREEZER, "freezer", "Freezer") \
    X(RESET_FREEZER, "resetfreezer", "ResetFreezer") \
    X(IGNORE, "ignore", "Ignore") \
    X(KEY_ORDER, "keyorder", "KeyOrder") \
    X(SORT_KEYS, "sortkeys", "SortKeys") \
    X(NAMES, "unames", "Names")

typedef enum {
#define OPTION_ENUM(id, key, name) DDS_OPT_##id,
    DDS_OPTION_LIST(OPTION_ENUM)
#undef OPTION_ENUM
    DDS_OPT_COUNT
} dds_option;

static const char *dds_option_keys[] = {
#define OPTION_KEY(id, key, name) key,
    DDS_OPTION_LIST(OPTION_KEY)
#undef OPTION_KEY
};

/*
 * Option dispatch
 *
 * The shared selector table connects accessor names to stored option keys.
 * Complex options retain their specialized validation and context behavior.
 */

/* Implement option getters and setters, including context-sensitive list
 * results and options with specialized validation or storage.
 */
static XS(dds_xs_option)
{
    dXSARGS;
    I32 ix = CvXSUBANY(cv).any_i32;
    SV *self, *result, *setvalue = NULL;
    HV *object, *style;
    const char *key = dds_option_keys[ix];

    if (!items)
        croak("Missing dumper invocant");
    self = DDS_TEMP(newSVsv(dds_safe_self(aTHX_ ST(0))));
    if (items > 1 && ix < DDS_OPT_DEPARSE_OPTS)
        setvalue = DDS_TEMP(newSVsv(ST(1)));
    object = dds_context(aTHX_ self)->object;
    style = dds_hash(aTHX_ object, "style", TRUE);
    result = self;
    if (ix == DDS_OPT_NAMES) { /* Names */
        AV *names;

        if (items > 1)
            dds_set_names(aTHX_ object, items - 1, &ST(1));
        else if (GIMME_V == G_VOID)
            hv_stores(object, "unames", newRV_noinc((SV *)newAV()));
        else if (GIMME_V == G_ARRAY) {
            SSize_t i, count;

            names = dds_array(aTHX_ object, "unames", FALSE);
            count = names ? av_len(names) + 1 : 0;
            SPAGAIN;
            EXTEND(SP, count);
            for (i = 0; i < count; i++)
                ST(i) = DDS_TEMP(newSVsv(*av_fetch(names, i, 0)));
            XSRETURN(count);
        } else
            result = dds_hget(aTHX_ object, "unames");
    } else if (ix == DDS_OPT_KEY_ORDER || ix == DDS_OPT_SORT_KEYS) {
        if (ix == DDS_OPT_SORT_KEYS) {
            AV *args = (AV *)DDS_TEMP((SV *)newAV());
            I32 i;

            av_push(args, newSVpvs(""));
            for (i = 1; i < items; i++)
                av_push(args, newSVsv(ST(i)));
            result = dds_key_order(aTHX_ self, av_len(args) + 1, AvARRAY(args));
        } else
            result = dds_key_order(aTHX_ self, items - 1, &ST(1));
    } else if (ix == DDS_OPT_IGNORE) { /* Ignore */
        HV *ignore = dds_hash(aTHX_ style, "ignore", TRUE);
        I32 i;

        if (items == 1) {
            HE *he;
            I32 count = 0;

            hv_iterinit(ignore);
            SPAGAIN;
            EXTEND(SP, (SSize_t)HvTOTALKEYS(ignore));
            while ((he = hv_iternext(ignore))) {
                SV *name = DDS_TEMP(newSVsv(hv_iterkeysv(he)));
                STRLEN len;
                char *p = SvPV(name, len);

                if (len)
                    sv_chop(name, p + 1);
                ST(count++) = name;
            }
            if (GIMME_V == G_ARRAY)
                XSRETURN(count);
            ST(0) = DDS_TEMP(newSViv(count));
            XSRETURN(1);
        }
        if (items > 2 && !(items % 2))
            croak("Must have an even number of arguments in Ignore()");
        for (i = 1; i < items; i += 2) {
            SV *policy = dds_policy_key(aTHX_ ST(i));

            if (i + 1 == items) {
                HE *entry = hv_fetch_ent(ignore, policy, 0, 0);

                result = entry ? HeVAL(entry) : &PL_sv_undef;
                break;
            }
            if (SvTRUE(ST(i + 1)))
                hv_store_ent(ignore, policy, newSViv(1), 0);
            else
                hv_delete_ent(ignore, policy, G_DISCARD, 0);
        }
    } else if (ix == DDS_OPT_RESET_FREEZER) {
        hv_stores(style, "freezer", newSVpvs("DDS_freeze"));
        hv_stores(style, "freeze_class", newRV_noinc((SV *)newHV()));
    } else if (ix == DDS_OPT_FREEZER && items == 3) {
        hv_store_ent(dds_hash(aTHX_ style, "freeze_class", TRUE), ST(1), newSVsv(ST(2)), 0);
    } else if (ix == DDS_OPT_FREEZER && items == 1 && GIMME_V == G_ARRAY) {
        HV *classes = dds_hash(aTHX_ style, "freeze_class", TRUE);
        HE *he;
        I32 count = 1;

        SPAGAIN;
        EXTEND(SP, 2 * (SSize_t)HvTOTALKEYS(classes) + 1);
        ST(0) = DDS_TEMP(newSVsv(dds_hget(aTHX_ style, "freezer")));
        hv_iterinit(classes);
        while ((he = hv_iternext(classes))) {
            ST(count++) = DDS_TEMP(newSVsv(hv_iterkeysv(he)));
            ST(count++) = DDS_TEMP(newSVsv(HeVAL(he)));
        }
        XSRETURN(count);
    } else if (ix == DDS_OPT_DEPARSE_OPTS) {
        if (items > 1) {
            SV *opts;

            if (SvROK(ST(1)))
                opts = newSVsv(ST(1));
            else {
                AV *array = newAV();
                I32 i;

                for (i = 1; i < items; i++)
                    av_push(array, newSVsv(ST(i)));
                opts = newRV_noinc((SV *)array);
            }
            hv_stores(style, "deparseopts", opts);
        } else if (GIMME_V == G_ARRAY) {
            AV *opts = dds_array(aTHX_ style, "deparseopts", FALSE);
            SSize_t i, count = opts ? av_len(opts) + 1 : 0;

            SPAGAIN;
            EXTEND(SP, count);
            for (i = 0; i < count; i++)
                ST(i) = DDS_TEMP(newSVsv(*av_fetch(opts, i, 0)));
            XSRETURN(count);
        } else
            result = dds_hget(aTHX_ style, key);
    } else if (items > 1) {
        HV *target = ix == DDS_OPT_TO ? object : style;

        if (ix == DDS_OPT_INDENT) {
            SV *space = dds_hget(aTHX_ style, "optspace");

            if (SvIV(setvalue) == 0 && sv_len_utf8(space)) {
                hv_stores(style, "last_optspace", newSVsv(space));
                hv_stores(style, "optspace", newSVpvs(""));
            } else if (!SvTRUE(dds_hget(aTHX_ style, "indent")) && !sv_len_utf8(space))
                hv_stores(style, "optspace", newSVsv(dds_hget(aTHX_ style, "last_optspace")));
        }
        hv_store(target, key, strlen(key), newSVsv(setvalue ? setvalue : ST(1)), 0);
    } else
        result = dds_hget(aTHX_ ix == DDS_OPT_TO ? object : style, key);
    ST(0) = DDS_TEMP(newSVsv(result));
    XSRETURN(1);
}

/* Provide the non-pure output placeholder by returning its first argument, or
 * undef when none was supplied.
 */
static XS(dds_xs_alias_to)
{
    dXSARGS;
    ST(0) = items ? ST(0) : &PL_sv_undef;
    XSRETURN(1);
}

/* Exclude dumper objects from ithread cloning because their native traversal
 * state belongs to one interpreter.
 */
static XS(dds_xs_clone_skip)
{
    dXSARGS;
    PERL_UNUSED_VAR(items);
    XSRETURN_YES;
}

/* Register public entry points, option accessors and spelling aliases with
 * their native dispatch selectors.
 */
void dds_api_boot(pTHX)
{
    static const struct {
        const char *name;
        dds_option selector;
    } options[] = {
#define OPTION_ENTRY(id, key, name) {name, DDS_OPT_##id},
        DDS_OPTION_LIST(OPTION_ENTRY)
#undef OPTION_ENTRY
            {"RLE", DDS_OPT_RLE},
        {"Dualvars", DDS_OPT_DUAL_VARS},
        {"Keyorder", DDS_OPT_KEY_ORDER},
        {"HashKeys", DDS_OPT_KEY_ORDER},
        {"Hashkeys", DDS_OPT_KEY_ORDER},
        {"Sortkeys", DDS_OPT_SORT_KEYS},
    };
    UV i;
    CV *cv;
#define INSTALL(name, function, selector) \
    STMT_START \
    { \
        cv = newXS("Data::Dump::Streamer::" name, function, __FILE__); \
        CvXSUBANY(cv).any_i32 = selector; \
    } \
    STMT_END
    INSTALL("new", dds_xs_new, 0);
    INSTALL("_safe_self", dds_xs_safe_self, 0);
    INSTALL("_xs_working_self", dds_xs_safe_self, 1);
    INSTALL("Data", dds_xs_io, 1);
    INSTALL("Out", dds_xs_io, 0);
    INSTALL("_xs_data", dds_xs_io, 1);
    INSTALL("_xs_out", dds_xs_io, 0);
    INSTALL("_xs_capture", dds_xs_capture, 0);
    INSTALL("_make_args", dds_xs_capture, 0);
    INSTALL("Dump", dds_xs_dump, DDS_DUMP);
    INSTALL("Precise", dds_xs_dump, DDS_DUMP);
    INSTALL("Dumper", dds_xs_dump, DDS_DUMP_TEXT);
    INSTALL("DumpVars", dds_xs_dump, DDS_DUMP_VARS);
    INSTALL("DumpLex", dds_xs_dump, DDS_DUMP_LEX);
    INSTALL("alias_to", dds_xs_alias_to, 0);
    INSTALL("CLONE_SKIP", dds_xs_clone_skip, 0);
    for (i = 0; i < sizeof(options) / sizeof(*options); i++) {
        SV *name = DDS_TEMP(newSVpvf("Data::Dump::Streamer::%s", options[i].name));

        cv = newXS(DDS_PV(name), dds_xs_option, __FILE__);
        CvXSUBANY(cv).any_i32 = options[i].selector;
    }
#undef INSTALL
}
