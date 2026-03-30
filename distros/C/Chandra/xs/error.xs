MODULE = Chandra    PACKAGE = Chandra::Error

PROTOTYPES: DISABLE

void
on_error(class, handler)
    SV *class
    SV *handler
CODE:
    PERL_UNUSED_VAR(class);
    chandra_error_add_handler(aTHX_ handler);

void
clear_handlers(class)
    SV *class
CODE:
    PERL_UNUSED_VAR(class);
    chandra_error_clear_handlers(aTHX);

SV *
handlers(class)
    SV *class
CODE:
    PERL_UNUSED_VAR(class);
    RETVAL = newRV_noinc((SV *)chandra_error_get_handlers(aTHX));
OUTPUT:
    RETVAL

SV *
capture(class, error, ...)
    SV *class
    SV *error
PREINIT:
    const char *context = "unknown";
    int skip = 2;
    int i;
CODE:
    PERL_UNUSED_VAR(class);
    /* Parse key => value pairs from remaining args */
    for (i = 2; i < items - 1; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "context")) {
            context = SvPV_nolen(ST(i + 1));
        } else if (strEQ(key, "skip")) {
            skip = (int)SvIV(ST(i + 1));
        }
    }
    RETVAL = newRV_noinc((SV *)chandra_error_capture(aTHX_ error, context, skip));
OUTPUT:
    RETVAL

SV *
stack_trace(class, ...)
    SV *class
PREINIT:
    int skip = 1;
CODE:
    PERL_UNUSED_VAR(class);
    if (items > 1) {
        skip = (int)SvIV(ST(1));
    }
    RETVAL = newRV_noinc((SV *)chandra_error_stack_trace(aTHX_ skip));
OUTPUT:
    RETVAL

SV *
format_text(class, err)
    SV *class
    SV *err
CODE:
    PERL_UNUSED_VAR(class);
    if (!SvROK(err) || SvTYPE(SvRV(err)) != SVt_PVHV) {
        croak("format_text requires a hashref");
    }
    RETVAL = chandra_error_format_text(aTHX_ (HV *)SvRV(err));
OUTPUT:
    RETVAL

SV *
format_js_console(class, err)
    SV *class
    SV *err
CODE:
    PERL_UNUSED_VAR(class);
    if (!SvROK(err) || SvTYPE(SvRV(err)) != SVt_PVHV) {
        croak("format_js_console requires a hashref");
    }
    RETVAL = chandra_error_format_js(aTHX_ (HV *)SvRV(err));
OUTPUT:
    RETVAL
