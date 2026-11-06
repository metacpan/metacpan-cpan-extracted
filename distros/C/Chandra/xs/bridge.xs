MODULE = Chandra    PACKAGE = Chandra::Bridge

PROTOTYPES: DISABLE

SV *
js_code(...)
CODE:
{
    RETVAL = newSVpvn(CHANDRA_BRIDGE_JS, CHANDRA_BRIDGE_JS_LEN);
    /* append any registered extensions */
    if (_ext_count > 0) {
        SV *ext_js = chandra_ext_generate_js(aTHX);
        sv_catsv(RETVAL, ext_js);
        SvREFCNT_dec(ext_js);
    }
}
OUTPUT:
    RETVAL

SV *
js_code_escaped(...)
CODE:
{
    STRLEN src_len = CHANDRA_BRIDGE_JS_LEN;
    const char *src = CHANDRA_BRIDGE_JS;
    SV *out = newSV(src_len * 2);
    char *dst = SvPVX(out);
    STRLEN dlen = 0;
    STRLEN i;

    # uncoverable branch true class:ignore_covered_err
    # uncoverable branch false class:ignore_covered_err
    for (i = 0; i < src_len; i++) {
        # uncoverable branch true count:1
        # uncoverable branch true count:4
        switch (src[i]) {
            # uncoverable statement
            case '\\': dst[dlen++] = '\\'; dst[dlen++] = '\\'; break;
            case '\'': dst[dlen++] = '\\'; dst[dlen++] = '\''; break;
            case '\n': dst[dlen++] = '\\'; dst[dlen++] = 'n';  break;
            # uncoverable statement
            case '\r': dst[dlen++] = '\\'; dst[dlen++] = 'r';  break;
            default:   dst[dlen++] = src[i]; break;
        }
    }
    dst[dlen] = '\0';
    SvCUR_set(out, dlen);
    SvPOK_on(out);
    /* append escaped extensions */
    if (_ext_count > 0) {
        SV *ext_js = chandra_ext_generate_js(aTHX);
        SV *ext_esc = chandra_ext_escape_sv(aTHX_ ext_js);
        sv_catsv(out, ext_esc);
        SvREFCNT_dec(ext_js);
        SvREFCNT_dec(ext_esc);
    }
    RETVAL = out;
}
OUTPUT:
    RETVAL
