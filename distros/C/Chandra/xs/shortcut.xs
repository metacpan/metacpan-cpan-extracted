MODULE = Chandra    PACKAGE = Chandra::Shortcut

PROTOTYPES: DISABLE

 # ---- ShortcutBindCtx: context for the __chandra_shortcut callback ----

SV *
new(class, ...)
    const char *class
CODE:
{
    HV *self_hv = newHV();
    I32 i;

    /* Parse %args from stack */
    for (i = 1; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "app")) {
            (void)hv_stores(self_hv, "app", newSVsv(val));
        }
    }

    (void)hv_stores(self_hv, "bindings", newRV_noinc((SV *)newHV()));
    (void)hv_stores(self_hv, "_disabled_all", newSViv(0));
    (void)hv_stores(self_hv, "_injected", newSViv(0));
    (void)hv_stores(self_hv, "_dispatch_bound", newSViv(0));

    RETVAL = sv_bless(newRV_noinc((SV *)self_hv), gv_stashpv(class, GV_ADD));
}
OUTPUT:
    RETVAL

 # ---- _normalize_combo: parse and normalize a combo string ----
 # Returns canonical form: modifiers in order ctrl+shift+alt+meta, then key
 # Handles: case-insensitive, mod -> platform modifier, key aliases

SV *
_normalize_combo(...)
CODE:
{
    SV *combo_sv = (items > 1) ? ST(1) : ST(0);
    const char *combo;
    STRLEN combo_len;
    char lower[512];
    STRLEN li;

    int has_ctrl = 0, has_shift = 0, has_alt = 0, has_meta = 0;
    char key_buf[128];
    STRLEN key_len = 0;

    /* Parts of a chord (space-separated combos) */
    char result[1024];
    STRLEN result_len = 0;
    int chord_count = 0;

    if (!SvOK(combo_sv)) {
        croak("_normalize_combo() requires a combo string");
    }

    combo = SvPV(combo_sv, combo_len);

    /* Lowercase the entire string into buffer */
    if (combo_len >= sizeof(lower)) combo_len = sizeof(lower) - 1;
    for (li = 0; li < combo_len; li++) {
        lower[li] = (combo[li] >= 'A' && combo[li] <= 'Z')
            ? combo[li] + 32 : combo[li];
    }
    lower[combo_len] = '\0';

    /* Process each chord part (split by space) */
    {
        const char *p = lower;
        const char *end = lower + combo_len;

        while (p <= end) {
            const char *chord_start = p;
            const char *chord_end;

            /* Find end of this chord part */
            chord_end = p;
            while (chord_end < end && *chord_end != ' ') chord_end++;

            /* Parse this part: split by '+' */
            has_ctrl = 0; has_shift = 0; has_alt = 0; has_meta = 0;
            key_len = 0;

            {
                const char *pp = chord_start;
                while (pp < chord_end) {
                    const char *tok_start = pp;
                    const char *tok_end = pp;
                    STRLEN tok_len;

                    while (tok_end < chord_end && *tok_end != '+') tok_end++;
                    tok_len = tok_end - tok_start;

                    if (tok_len == 4 && memEQ(tok_start, "ctrl", 4)) {
                        has_ctrl = 1;
                    } else if (tok_len == 7 && memEQ(tok_start, "control", 7)) {
                        has_ctrl = 1;
                    } else if (tok_len == 5 && memEQ(tok_start, "shift", 5)) {
                        has_shift = 1;
                    } else if (tok_len == 3 && memEQ(tok_start, "alt", 3)) {
                        has_alt = 1;
                    } else if (tok_len == 6 && memEQ(tok_start, "option", 6)) {
                        has_alt = 1;
                    } else if (tok_len == 4 && memEQ(tok_start, "meta", 4)) {
                        has_meta = 1;
                    } else if (tok_len == 3 && memEQ(tok_start, "cmd", 3)) {
                        has_meta = 1;
                    } else if (tok_len == 7 && memEQ(tok_start, "command", 7)) {
                        has_meta = 1;
                    } else if (tok_len == 5 && memEQ(tok_start, "super", 5)) {
                        has_meta = 1;
                    } else if (tok_len == 3 && memEQ(tok_start, "mod", 3)) {
                        /* Platform-aware: Cmd on macOS, Ctrl elsewhere */
#if defined(__APPLE__)
                        has_meta = 1;
#else
                        has_ctrl = 1;
#endif
                    } else {
                        /* It's the key part */
                        if (tok_len < sizeof(key_buf)) {
                            Copy(tok_start, key_buf, tok_len, char);
                            key_len = tok_len;
                            key_buf[key_len] = '\0';
                        }
                    }

                    pp = (tok_end < chord_end) ? tok_end + 1 : chord_end;
                }
            }

            /* Normalize key aliases */
            if (key_len > 0) {
                if (key_len == 5 && memEQ(key_buf, "space", 5)) {
                    Copy(" ", key_buf, 1, char); key_len = 1; key_buf[1] = '\0';
                } else if (key_len == 5 && memEQ(key_buf, "enter", 5)) {
                    Copy("enter", key_buf, 5, char); key_len = 5;
                } else if (key_len == 6 && memEQ(key_buf, "return", 6)) {
                    Copy("enter", key_buf, 5, char); key_len = 5; key_buf[5] = '\0';
                } else if (key_len == 6 && memEQ(key_buf, "escape", 6)) {
                    Copy("escape", key_buf, 6, char); key_len = 6;
                } else if (key_len == 3 && memEQ(key_buf, "esc", 3)) {
                    Copy("escape", key_buf, 6, char); key_len = 6; key_buf[6] = '\0';
                } else if (key_len == 3 && memEQ(key_buf, "tab", 3)) {
                    Copy("tab", key_buf, 3, char); key_len = 3;
                } else if (key_len == 9 && memEQ(key_buf, "backspace", 9)) {
                    Copy("backspace", key_buf, 9, char); key_len = 9;
                } else if (key_len == 6 && memEQ(key_buf, "delete", 6)) {
                    Copy("delete", key_buf, 6, char); key_len = 6;
                } else if (key_len == 3 && memEQ(key_buf, "del", 3)) {
                    Copy("delete", key_buf, 6, char); key_len = 6; key_buf[6] = '\0';
                } else if (key_len == 2 && memEQ(key_buf, "up", 2)) {
                    Copy("arrowup", key_buf, 7, char); key_len = 7; key_buf[7] = '\0';
                } else if (key_len == 7 && memEQ(key_buf, "arrowup", 7)) {
                    /* already canonical */
                } else if (key_len == 4 && memEQ(key_buf, "down", 4)) {
                    Copy("arrowdown", key_buf, 9, char); key_len = 9; key_buf[9] = '\0';
                } else if (key_len == 9 && memEQ(key_buf, "arrowdown", 9)) {
                    /* already canonical */
                } else if (key_len == 4 && memEQ(key_buf, "left", 4)) {
                    Copy("arrowleft", key_buf, 9, char); key_len = 9; key_buf[9] = '\0';
                } else if (key_len == 9 && memEQ(key_buf, "arrowleft", 9)) {
                    /* already canonical */
                } else if (key_len == 5 && memEQ(key_buf, "right", 5)) {
                    Copy("arrowright", key_buf, 10, char); key_len = 10; key_buf[10] = '\0';
                } else if (key_len == 10 && memEQ(key_buf, "arrowright", 10)) {
                    /* already canonical */
                } else if (key_len == 4 && memEQ(key_buf, "plus", 4)) {
                    Copy("+", key_buf, 1, char); key_len = 1; key_buf[1] = '\0';
                } else if (key_len == 5 && memEQ(key_buf, "minus", 5)) {
                    Copy("-", key_buf, 1, char); key_len = 1; key_buf[1] = '\0';
                } else if (key_len == 5 && memEQ(key_buf, "equal", 5)) {
                    Copy("=", key_buf, 1, char); key_len = 1; key_buf[1] = '\0';
                }
            }

            /* Build canonical combo: ctrl+shift+alt+meta+key */
            if (chord_count > 0) {
                result[result_len++] = ' ';
            }

            if (has_ctrl) {
                if (result_len + 5 < sizeof(result)) {
                    Copy("ctrl+", result + result_len, 5, char);
                    result_len += 5;
                }
            }
            if (has_shift) {
                if (result_len + 6 < sizeof(result)) {
                    Copy("shift+", result + result_len, 6, char);
                    result_len += 6;
                }
            }
            if (has_alt) {
                if (result_len + 4 < sizeof(result)) {
                    Copy("alt+", result + result_len, 4, char);
                    result_len += 4;
                }
            }
            if (has_meta) {
                if (result_len + 5 < sizeof(result)) {
                    Copy("meta+", result + result_len, 5, char);
                    result_len += 5;
                }
            }
            if (key_len > 0 && result_len + key_len < sizeof(result)) {
                Copy(key_buf, result + result_len, key_len, char);
                result_len += key_len;
            }

            chord_count++;
            p = (chord_end < end) ? chord_end + 1 : end + 1;
        }
    }

    result[result_len] = '\0';
    RETVAL = newSVpvn(result, result_len);
}
OUTPUT:
    RETVAL

 # ---- bind($combo, $handler, %opts) ----

SV *
bind(self, combo_sv, handler, ...)
    SV *self
    SV *combo_sv
    SV *handler
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **bindings_svp;
    HV *bindings_hv;
    SV *norm_combo;
    const char *norm_str;
    STRLEN norm_len;
    HV *entry_hv;
    int prevent_default = 0;
    I32 i;

    /* Validate handler */
    if (!SvOK(handler) || !SvROK(handler) || SvTYPE(SvRV(handler)) != SVt_PVCV) {
        croak("bind() requires a handler coderef");
    }

    /* Validate combo */
    if (!SvOK(combo_sv)) {
        croak("bind() requires a combo string");
    }

    /* Parse optional %opts */
    for (i = 3; i + 1 < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "prevent_default")) {
            prevent_default = SvIV(ST(i + 1));
        }
    }

    /* Normalize combo */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(combo_sv);
        PUTBACK;
        count = call_method("_normalize_combo", G_SCALAR);
        SPAGAIN;
        norm_combo = (count > 0) ? newSVsv(POPs) : newSVsv(combo_sv);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    norm_str = SvPV(norm_combo, norm_len);

    /* Create entry: { handler, enabled, prevent_default } */
    entry_hv = newHV();
    (void)hv_stores(entry_hv, "handler", newSVsv(handler));
    (void)hv_stores(entry_hv, "enabled", newSViv(1));
    (void)hv_stores(entry_hv, "prevent_default", newSViv(prevent_default));
    (void)hv_stores(entry_hv, "combo", newSVsv(norm_combo));

    /* Store in bindings hash */
    bindings_svp = hv_fetchs(hv, "bindings", 0);
    if (bindings_svp && SvROK(*bindings_svp)) {
        bindings_hv = (HV *)SvRV(*bindings_svp);
    } else {
        bindings_hv = newHV();
        (void)hv_stores(hv, "bindings", newRV_noinc((SV *)bindings_hv));
    }
    (void)hv_store(bindings_hv, norm_str, norm_len,
        newRV_noinc((SV *)entry_hv), 0);

    /* Bind __chandra_shortcut dispatch if not already done */
    {
        SV **db_svp = hv_fetchs(hv, "_dispatch_bound", 0);
        if (!db_svp || !SvIV(*db_svp)) {
            SV **app_svp = hv_fetchs(hv, "app", 0);
            if (app_svp && SvOK(*app_svp)) {
                /* Create dispatch callback that references self */
                CV *wrapper_cv;
                SV *self_ref;

                self_ref = newSVsv(self);
                sv_rvweaken(self_ref); /* weak ref to avoid circular */

                wrapper_cv = newXS(NULL, xs_shortcut_dispatch_callback, __FILE__);
                CvXSUBANY(wrapper_cv).any_ptr = (void *)self_ref;

                {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*app_svp);
                    XPUSHs(sv_2mortal(newSVpvs("__chandra_shortcut")));
                    XPUSHs(sv_2mortal(newRV_noinc((SV *)wrapper_cv)));
                    PUTBACK;
                    call_method("bind", G_DISCARD);
                    FREETMPS; LEAVE;
                }

                (void)hv_stores(hv, "_dispatch_bound", newSViv(1));
            }
        }
    }

    SvREFCNT_dec(norm_combo);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- unbind($combo) ----

SV *
unbind(self, combo_sv)
    SV *self
    SV *combo_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **bindings_svp;
    SV *norm_combo;
    const char *norm_str;
    STRLEN norm_len;

    /* Normalize combo */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(combo_sv);
        PUTBACK;
        count = call_method("_normalize_combo", G_SCALAR);
        SPAGAIN;
        norm_combo = (count > 0) ? newSVsv(POPs) : newSVsv(combo_sv);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    norm_str = SvPV(norm_combo, norm_len);

    bindings_svp = hv_fetchs(hv, "bindings", 0);
    if (bindings_svp && SvROK(*bindings_svp)) {
        HV *bindings_hv = (HV *)SvRV(*bindings_svp);
        (void)hv_delete(bindings_hv, norm_str, norm_len, G_DISCARD);
    }

    SvREFCNT_dec(norm_combo);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- list() — return array of hashrefs ----

void
list(self)
    SV *self
PPCODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **bindings_svp;

    bindings_svp = hv_fetchs(hv, "bindings", 0);
    if (bindings_svp && SvROK(*bindings_svp)) {
        HV *bindings_hv = (HV *)SvRV(*bindings_svp);
        HE *entry;

        hv_iterinit(bindings_hv);
        while ((entry = hv_iternext(bindings_hv)) != NULL) {
            SV *val = HeVAL(entry);
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                HV *ehv = (HV *)SvRV(val);
                HV *result = newHV();
                SV **tmp;

                (void)hv_stores(result, "combo",
                    newSVhek(HeKEY_hek(entry)));

                tmp = hv_fetchs(ehv, "handler", 0);
                if (tmp) (void)hv_stores(result, "handler", newSVsv(*tmp));

                tmp = hv_fetchs(ehv, "enabled", 0);
                (void)hv_stores(result, "enabled",
                    newSViv(tmp ? SvIV(*tmp) : 1));

                tmp = hv_fetchs(ehv, "prevent_default", 0);
                (void)hv_stores(result, "prevent_default",
                    newSViv(tmp ? SvIV(*tmp) : 0));

                XPUSHs(sv_2mortal(newRV_noinc((SV *)result)));
            }
        }
    }
}

 # ---- is_bound($combo) ----

SV *
is_bound(self, combo_sv)
    SV *self
    SV *combo_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **bindings_svp;
    SV *norm_combo;
    const char *norm_str;
    STRLEN norm_len;

    /* Normalize combo */
    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(combo_sv);
        PUTBACK;
        count = call_method("_normalize_combo", G_SCALAR);
        SPAGAIN;
        norm_combo = (count > 0) ? newSVsv(POPs) : newSVsv(combo_sv);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    norm_str = SvPV(norm_combo, norm_len);

    bindings_svp = hv_fetchs(hv, "bindings", 0);
    if (bindings_svp && SvROK(*bindings_svp)) {
        HV *bindings_hv = (HV *)SvRV(*bindings_svp);
        RETVAL = hv_exists(bindings_hv, norm_str, norm_len)
            ? &PL_sv_yes : &PL_sv_no;
    } else {
        RETVAL = &PL_sv_no;
    }

    SvREFCNT_dec(norm_combo);
}
OUTPUT:
    RETVAL

 # ---- disable($combo) ----

SV *
disable(self, combo_sv)
    SV *self
    SV *combo_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **bindings_svp;
    SV *norm_combo;
    const char *norm_str;
    STRLEN norm_len;

    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(combo_sv);
        PUTBACK;
        count = call_method("_normalize_combo", G_SCALAR);
        SPAGAIN;
        norm_combo = (count > 0) ? newSVsv(POPs) : newSVsv(combo_sv);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    norm_str = SvPV(norm_combo, norm_len);

    bindings_svp = hv_fetchs(hv, "bindings", 0);
    if (bindings_svp && SvROK(*bindings_svp)) {
        HV *bindings_hv = (HV *)SvRV(*bindings_svp);
        SV **entry_svp = hv_fetch(bindings_hv, norm_str, norm_len, 0);
        if (entry_svp && SvROK(*entry_svp) && SvTYPE(SvRV(*entry_svp)) == SVt_PVHV) {
            HV *ehv = (HV *)SvRV(*entry_svp);
            (void)hv_stores(ehv, "enabled", newSViv(0));
        }
    }

    SvREFCNT_dec(norm_combo);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- enable($combo) ----

SV *
enable(self, combo_sv)
    SV *self
    SV *combo_sv
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **bindings_svp;
    SV *norm_combo;
    const char *norm_str;
    STRLEN norm_len;

    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        XPUSHs(combo_sv);
        PUTBACK;
        count = call_method("_normalize_combo", G_SCALAR);
        SPAGAIN;
        norm_combo = (count > 0) ? newSVsv(POPs) : newSVsv(combo_sv);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    norm_str = SvPV(norm_combo, norm_len);

    bindings_svp = hv_fetchs(hv, "bindings", 0);
    if (bindings_svp && SvROK(*bindings_svp)) {
        HV *bindings_hv = (HV *)SvRV(*bindings_svp);
        SV **entry_svp = hv_fetch(bindings_hv, norm_str, norm_len, 0);
        if (entry_svp && SvROK(*entry_svp) && SvTYPE(SvRV(*entry_svp)) == SVt_PVHV) {
            HV *ehv = (HV *)SvRV(*entry_svp);
            (void)hv_stores(ehv, "enabled", newSViv(1));
        }
    }

    SvREFCNT_dec(norm_combo);
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- disable_all() ----

SV *
disable_all(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_disabled_all", newSViv(1));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- enable_all() ----

SV *
enable_all(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    (void)hv_stores(hv, "_disabled_all", newSViv(0));
    RETVAL = SvREFCNT_inc(self);
}
OUTPUT:
    RETVAL

 # ---- js_code() — returns JavaScript for shortcut handling ----

SV *
js_code(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **bindings_svp;

    bindings_svp = hv_fetchs(hv, "bindings", 0);
    if (!bindings_svp || !SvROK(*bindings_svp)
        || HvUSEDKEYS((HV *)SvRV(*bindings_svp)) == 0) {
        RETVAL = newSVpvs("");
    } else {
        HV *bindings_hv = (HV *)SvRV(*bindings_svp);
        HE *entry;
        SV *js;
        int first = 1;

        js = newSVpvs(
            "(function(){\n"
            "if(window.__chandraShortcut)return;\n"
            "var bindings={\n"
        );

        /* Emit binding entries: combo => { pd: 0|1 } */
        hv_iterinit(bindings_hv);
        while ((entry = hv_iternext(bindings_hv)) != NULL) {
            I32 klen;
            const char *key = hv_iterkey(entry, &klen);
            SV *val = HeVAL(entry);
            int pd = 0;

            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                HV *ehv = (HV *)SvRV(val);
                SV **pd_svp = hv_fetchs(ehv, "prevent_default", 0);
                if (pd_svp) pd = SvIV(*pd_svp);
            }

            if (!first) sv_catpvs(js, ",\n");
            sv_catpvs(js, "'");
            sv_catpvn(js, key, klen);
            sv_catpvs(js, "':{pd:");
            sv_catpvf(js, "%d", pd);
            sv_catpvs(js, "}");
            first = 0;
        }

        sv_catpvs(js,
            "\n};\n"

            "var chordPrefix=null,chordTimer=null;\n"

            "function normKey(e){\n"
            "var p=[];\n"
            "if(e.ctrlKey)p.push('ctrl');\n"
            "if(e.shiftKey)p.push('shift');\n"
            "if(e.altKey)p.push('alt');\n"
            "if(e.metaKey)p.push('meta');\n"
            "var k=e.key.toLowerCase();\n"
            "if(k==='control'||k==='shift'||k==='alt'||k==='meta')return '';\n"
            "if(k===' ')k=' ';\n"
            "p.push(k);\n"
            "return p.join('+');\n"
            "}\n"

            "document.addEventListener('keydown',function(e){\n"
            "var combo=normKey(e);\n"
            "if(!combo)return;\n"

            /* Chord handling */
            "if(chordPrefix){\n"
            "var full=chordPrefix+' '+combo;\n"
            "clearTimeout(chordTimer);\n"
            "chordPrefix=null;\n"
            "if(bindings[full]){\n"
            "if(bindings[full].pd)e.preventDefault();\n"
            "window.chandra.invoke('__chandra_shortcut',[full]);\n"
            "return;\n"
            "}\n"
            "}\n"

            /* Check chord prefix */
            "var isPrefix=false;\n"
            "for(var k in bindings){\n"
            "if(k.indexOf(combo+' ')===0){isPrefix=true;break;}\n"
            "}\n"
            "if(isPrefix){\n"
            "e.preventDefault();\n"
            "chordPrefix=combo;\n"
            "chordTimer=setTimeout(function(){chordPrefix=null;},1500);\n"
            "return;\n"
            "}\n"

            /* Regular combo */
            "if(bindings[combo]){\n"
            "if(bindings[combo].pd)e.preventDefault();\n"
            "window.chandra.invoke('__chandra_shortcut',[combo]);\n"
            "}\n"
            "},true);\n"

            "window.__chandraShortcut={\n"
            "register:function(c,o){bindings[c]=o||{};},\n"
            "unregister:function(c){delete bindings[c];}\n"
            "};\n"
            "})();\n"
        );

        RETVAL = js;
    }
}
OUTPUT:
    RETVAL

 # ---- inject() — inject JS via app->eval ----

SV *
inject(self)
    SV *self
CODE:
{
    HV *hv = (HV *)SvRV(self);
    SV **injected_svp;
    SV **bindings_svp;

    injected_svp = hv_fetchs(hv, "_injected", 0);
    if (injected_svp && SvTRUE(*injected_svp)) {
        RETVAL = SvREFCNT_inc(self);
    } else {
        bindings_svp = hv_fetchs(hv, "bindings", 0);
        if (!bindings_svp || !SvROK(*bindings_svp)
            || HvUSEDKEYS((HV *)SvRV(*bindings_svp)) == 0) {
            RETVAL = SvREFCNT_inc(self);
        } else {
            SV *js;

            (void)hv_stores(hv, "_injected", newSViv(1));

            /* Get JS code */
            {
                dSP;
                int count;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(self);
                PUTBACK;
                count = call_method("js_code", G_SCALAR);
                SPAGAIN;
                js = (count > 0) ? newSVsv(POPs) : newSVpvs("");
                PUTBACK;
                FREETMPS; LEAVE;
            }

            /* Call $self->{app}->eval($js) */
            {
                SV **app_svp = hv_fetchs(hv, "app", 0);
                if (app_svp && SvOK(*app_svp)) {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(*app_svp);
                    XPUSHs(sv_2mortal(js));
                    PUTBACK;
                    call_method("eval", G_DISCARD);
                    FREETMPS; LEAVE;
                } else {
                    SvREFCNT_dec(js);
                }
            }

            RETVAL = SvREFCNT_inc(self);
        }
    }
}
OUTPUT:
    RETVAL
