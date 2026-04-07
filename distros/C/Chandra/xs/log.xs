MODULE = Chandra    PACKAGE = Chandra::Log

PROTOTYPES: DISABLE

 # ---- new(class, level => ..., output => ..., formatter => ..., rotate => ...) ----

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    chandra_log_ctx *ctx = chandra_log_new_ctx(aTHX);
    int i;
    int has_output = 0;

    for (i = 1; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);

        if (strEQ(key, "level")) {
            ctx->level = chandra_log_parse_level(SvPV_nolen(val));
        } else if (strEQ(key, "output")) {
            chandra_log_parse_output(aTHX_ ctx, val);
            has_output = 1;
        } else if (strEQ(key, "formatter")) {
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
                ctx->fmt_type   = CHANDRA_LOG_FMT_CUSTOM;
                ctx->fmt_custom = SvREFCNT_inc(val);
            } else {
                const char *s = SvPV_nolen(val);
                if (strEQ(s, "json"))
                    ctx->fmt_type = CHANDRA_LOG_FMT_JSON;
                else if (strEQ(s, "minimal"))
                    ctx->fmt_type = CHANDRA_LOG_FMT_MINIMAL;
                else
                    ctx->fmt_type = CHANDRA_LOG_FMT_TEXT;
            }
        } else if (strEQ(key, "rotate")) {
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                HV *rhv = (HV *)SvRV(val);
                SV **ms = hv_fetchs(rhv, "max_size", 0);
                SV **kp = hv_fetchs(rhv, "keep", 0);
                if (ms) ctx->rotate_max_size = chandra_log_parse_size(aTHX_ *ms);
                if (kp && SvOK(*kp)) ctx->rotate_keep = SvIV(*kp);
            }
        }
    }

    if (!has_output)
        chandra_log_add_output_stderr(ctx);

    (void)hv_stores(self_hv, "_ctx", newSViv(PTR2IV(ctx)));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
                      gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
{
    SV **svp;
    HV *hv;
    if (!SvROK(self)) XSRETURN_EMPTY;
    hv = (HV *)SvRV(self);
    svp = hv_fetchs(hv, "_ctx", 0);
    if (svp && SvIOK(*svp)) {
        chandra_log_ctx *ctx = INT2PTR(chandra_log_ctx *, SvIV(*svp));
        chandra_log_free_ctx(aTHX_ ctx);
    }
}

 # ---- level([new_level]) ----

SV *
level(self, ...)
    SV *self
CODE:
{
    chandra_log_ctx *ctx = chandra_log_get_ctx(aTHX_ self);
    if (items > 1 && SvOK(ST(1))) {
        ctx->level = chandra_log_parse_level(SvPV_nolen(ST(1)));
    }
    RETVAL = newSVpv(chandra_log_level_names[ctx->level], 0);
}
OUTPUT:
    RETVAL

 # ---- set_level(level) ----

void
set_level(self, level_name)
    SV *self
    const char *level_name
CODE:
{
    chandra_log_ctx *ctx = chandra_log_get_ctx(aTHX_ self);
    ctx->level = chandra_log_parse_level(level_name);
}

 # ---- formatter(fmt) ----

void
formatter(self, fmt)
    SV *self
    SV *fmt
CODE:
{
    chandra_log_ctx *ctx = chandra_log_get_ctx(aTHX_ self);

    if (ctx->fmt_custom) {
        SvREFCNT_dec(ctx->fmt_custom);
        ctx->fmt_custom = NULL;
    }

    if (SvROK(fmt) && SvTYPE(SvRV(fmt)) == SVt_PVCV) {
        ctx->fmt_type   = CHANDRA_LOG_FMT_CUSTOM;
        ctx->fmt_custom = SvREFCNT_inc(fmt);
    } else {
        const char *s = SvPV_nolen(fmt);
        if (strEQ(s, "json"))
            ctx->fmt_type = CHANDRA_LOG_FMT_JSON;
        else if (strEQ(s, "minimal"))
            ctx->fmt_type = CHANDRA_LOG_FMT_MINIMAL;
        else
            ctx->fmt_type = CHANDRA_LOG_FMT_TEXT;
    }
}

 # ---- with(%context) → child logger ----

SV *
with(self, ...)
    SV *self
CODE:
{
    chandra_log_ctx *orig = chandra_log_get_ctx(aTHX_ self);
    chandra_log_ctx *child = chandra_log_new_ctx(aTHX);
    HV *self_hv = newHV();
    int i;

    /* Copy settings */
    child->level        = orig->level;
    child->fmt_type     = orig->fmt_type;
    child->fmt_custom   = orig->fmt_custom
                              ? SvREFCNT_inc(orig->fmt_custom)
                              : NULL;
    child->rotate_max_size = orig->rotate_max_size;
    child->rotate_keep     = orig->rotate_keep;

    /* Copy outputs */
    child->output_count = orig->output_count;
    for (i = 0; i < orig->output_count; i++) {
        child->outputs[i] = orig->outputs[i];
        if (child->outputs[i].path)
            SvREFCNT_inc(child->outputs[i].path);
        if (child->outputs[i].callback)
            SvREFCNT_inc(child->outputs[i].callback);
    }

    /* Merge context: copy parent context then overlay new key-value pairs */
    SvREFCNT_dec((SV *)child->context);
    child->context = newHVhv(orig->context);
    for (i = 1; i < items - 1; i += 2) {
        STRLEN klen;
        const char *key = SvPV(ST(i), klen);
        (void)hv_store(child->context, key, klen,
                       newSVsv(ST(i + 1)), 0);
    }

    (void)hv_stores(self_hv, "_ctx", newSViv(PTR2IV(child)));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv),
                      gv_stashpv("Chandra::Log", GV_ADD));
}
OUTPUT:
    RETVAL

 # ---- Logging methods ----

void
debug(self, message = &PL_sv_undef, data = NULL)
    SV *self
    SV *message
    SV *data
CODE:
    chandra_log_dispatch(aTHX_ chandra_log_get_ctx(aTHX_ self),
                         CHANDRA_LOG_DEBUG, message, data);

void
info(self, message = &PL_sv_undef, data = NULL)
    SV *self
    SV *message
    SV *data
CODE:
    chandra_log_dispatch(aTHX_ chandra_log_get_ctx(aTHX_ self),
                         CHANDRA_LOG_INFO, message, data);

void
warn(self, message = &PL_sv_undef, data = NULL)
    SV *self
    SV *message
    SV *data
CODE:
    chandra_log_dispatch(aTHX_ chandra_log_get_ctx(aTHX_ self),
                         CHANDRA_LOG_WARN, message, data);

void
error(self, message = &PL_sv_undef, data = NULL)
    SV *self
    SV *message
    SV *data
CODE:
    chandra_log_dispatch(aTHX_ chandra_log_get_ctx(aTHX_ self),
                         CHANDRA_LOG_ERROR, message, data);

void
fatal(self, message = &PL_sv_undef, data = NULL)
    SV *self
    SV *message
    SV *data
CODE:
    chandra_log_dispatch(aTHX_ chandra_log_get_ctx(aTHX_ self),
                         CHANDRA_LOG_FATAL, message, data);
