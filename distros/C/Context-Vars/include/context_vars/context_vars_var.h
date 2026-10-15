#ifndef CONTEXT_VARS_VAR_H
#define CONTEXT_VARS_VAR_H

/* The imported scalar.
 *
 * There is one scalar in the interpreter for each name, and every package
 * that imports the name has it in its own glob. The scalar holds no value of
 * its own. It carries magic, recognised by the address of the vtable below,
 * with the name hanging off it: a read fetches the name from the current
 * context into the scalar, and an assignment stores what was assigned under
 * the name in the current context. The scalar's own buffer is where one
 * read lands and is never the truth.
 *
 * A reference left in that buffer is let go at the end of the statement
 * that read or assigned it. The buffer outlives that statement, and a
 * reference kept there would hold an object alive after every context
 * holding it had let it go, for as long as nothing read or assigned the
 * variable again. A copy taken from the variable is an ordinary reference.
 *
 * It is NOT done by weakening the buffer's reference, which was the first
 * way: when the object goes, perl clears every weak reference to it and
 * calls set magic on each, which here would unset the variable in whatever
 * context is current - the caller's, at the end of a sub that had replaced
 * the reference.
 *
 * ---- local ---------------------------------------------------------------
 *
 * `local $name` works, and needs two things from here that are easy to get
 * wrong. perl makes a NEW scalar for the glob, copies this magic to it, and
 * calls set on it with PL_localizing at 1: that is the moment to remember
 * what the context holds under the name. On the way out perl puts the OLD
 * scalar back and calls set on it with PL_localizing at 2, and the old
 * scalar holds whatever was last READ into it, which may be the value of a
 * different context altogether. So that call ignores the scalar and puts
 * back what was remembered. */

static int context_vars_var_get(pTHX_ SV *sv, MAGIC *mg);
static int context_vars_var_set(pTHX_ SV *sv, MAGIC *mg);

static MGVTBL context_vars_var_vtbl = {
    context_vars_var_get, context_vars_var_set, 0, 0, 0
};

/* The magic that makes `sv` one of ours, or NULL. By hand: mg_findext is
 * 5.14. */
static MAGIC *context_vars_var_mg(SV *sv) {
    MAGIC *mg;
    if (!sv || SvTYPE(sv) < SVt_PVMG) return NULL;
    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext
            && mg->mg_virtual == &context_vars_var_vtbl)
            return mg;
    return NULL;
}

/* A mortal that, when the statement's temporaries are freed, takes the
 * reference out of the variable's buffer without calling its magic. Taking it
 * out early is harmless: the buffer is never the truth, and the next read
 * fetches again. */
static int context_vars_unhold_free(pTHX_ SV *sv, MAGIC *mg) {
    SV *var = (SV *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (var) {
        mg->mg_ptr = NULL;
        if (SvROK(var)) {
            SV *target = SvRV(var);
            SvRV_set(var, NULL);
            SvROK_off(var);
            SvREFCNT_dec(target);
        }
        SvREFCNT_dec(var);
    }
    return 0;
}

static MGVTBL context_vars_unhold_vtbl = { 0, 0, 0, 0, context_vars_unhold_free };

static void context_vars_var_unhold(pTHX_ SV *sv) {
    SV *later;
    if (!SvROK(sv)) return;
    later = sv_newmortal();
    SvREFCNT_inc_simple_void_NN(sv);
    sv_magicext(later, NULL, PERL_MAGIC_ext, &context_vars_unhold_vtbl, (const char *)sv, 0);
}

static int context_vars_var_get(pTHX_ SV *sv, MAGIC *mg) {
    SV *held = context_vars_fetch(aTHX_ mg->mg_ptr, (STRLEN)mg->mg_len);
    if (held && (context_vars_is_map(aTHX_ held) || context_vars_is_vec(aTHX_ held))) {
        AV *path = newAV();
        av_push(path, newSVpvn(mg->mg_ptr, mg->mg_len));
        sv_setsv(sv, context_vars_out(aTHX_ held, path));
    }
    else if (held) sv_setsv(sv, held);
    else      sv_setsv(sv, &PL_sv_undef);
    context_vars_var_unhold(aTHX_ sv);
    return 0;
}

/* Assigning undef unsets the name. A name that is not set reads undef, so
 * the two are the same to a reader and the context stays as small as what
 * is actually in it. A plain hash or array, or a proxy, is stored as context
 * data, at every depth. */
static void context_vars_var_put(pTHX_ const char *name, STRLEN len, SV *value) {
    if (value && SvOK(value)) {
        SV *conv = context_vars_in(aTHX_ value);
        context_vars_writable(aTHX);
        context_vars_store(aTHX_ name, len, conv ? conv : value);
        if (conv) SvREFCNT_dec(conv);
    }
    else if (context_vars_fetch(aTHX_ name, len)) {
        context_vars_writable(aTHX);
        context_vars_remove(aTHX_ name, len);
    }
}

static int context_vars_var_set(pTHX_ SV *sv, MAGIC *mg) {
    dMY_CXT;
    const char *name = mg->mg_ptr;
    STRLEN      len  = (STRLEN)mg->mg_len;

    if (PL_localizing == 1) {
        SV *held = context_vars_fetch(aTHX_ name, len);
        av_push(MY_CXT.locals, held ? newSVsv(held) : newSV(0));
        context_vars_var_put(aTHX_ name, len, sv);
        context_vars_var_unhold(aTHX_ sv);
        return 0;
    }
    if (PL_localizing == 2) {
        SV *was = av_pop(MY_CXT.locals);
        context_vars_var_put(aTHX_ name, len, was);
        SvREFCNT_dec(was);
        return 0;
    }
    context_vars_var_put(aTHX_ name, len, sv);
    if (context_vars_is_fresh(aTHX_ sv)) {
        /* perl 5.14 and older vivify $v->{k} by putting a fresh plain hash
         * straight into $v and then writing into it: tie that hash in place,
         * as a store through a proxy does (context_vars_tie_fresh). */
        AV *path = (AV *)sv_2mortal((SV *)newAV());
        av_push(path, newSVpvn(name, len));
        context_vars_tie_fresh(aTHX_ sv, path);
    }
    context_vars_var_unhold(aTHX_ sv);
    return 0;
}

/* ---- import --------------------------------------------------------------- */

/* A name is `$`, `@` or `%` and then an identifier, in ASCII. Returns the
 * length of the identifier, or 0 when `arg` is anything else. */
static STRLEN context_vars_name_ok(const char *arg, STRLEN len) {
    STRLEN i;
    if (len < 2 || (arg[0] != '$' && arg[0] != '@' && arg[0] != '%')) return 0;
    if (!(isALPHA(arg[1]) || arg[1] == '_')) return 0;
    for (i = 2; i < len; i++)
        if (!(isALNUM(arg[i]))) return 0;
    return len - 1;
}

/* Names perl keeps in main:: whatever package they are written in. A glob
 * of that name in the caller's package would be made and never looked at. */
static int context_vars_name_forced(const char *n, STRLEN len) {
    static const char *const forced[] = {
        "_", "ENV", "INC", "ARGV", "ARGVOUT", "STDIN", "STDOUT", "STDERR", "SIG", NULL
    };
    int i;
    for (i = 0; forced[i]; i++)
        if (strlen(forced[i]) == len && memEQ(forced[i], n, len)) return 1;
    return 0;
}

/* The one scalar for a name in this interpreter, made the first time the
 * name is imported. They are kept in a package hash and not in C, so that a
 * new thread gets its own, already pointing at its own scalars. */
static SV *context_vars_var_for(pTHX_ const char *name, STRLEN len) {
    HV  *reg = get_hv("Context::Vars::_VARS", GV_ADD);
    SV **svp = hv_fetch(reg, name, (I32)len, 0);
    SV  *sv;

    if (svp && SvROK(*svp) && context_vars_var_mg(SvRV(*svp)))
        return SvRV(*svp);

    sv = newSV(0);
    SvUPGRADE(sv, SVt_PVMG);
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &context_vars_var_vtbl, name, (I32)len);
    (void)hv_store(reg, name, (I32)len, newRV_noinc(sv), 0);
    return sv;
}

/* The one array or hash for a name in this interpreter: a container tied to a
 * proxy for its context name, "@name" or "%name", and marked so that `local`
 * on it keeps the context's value. Kept in the same package hash as the
 * scalars. */
static SV *context_vars_container_for(pTHX_ const char *cname, STRLEN clen, int is_hash) {
    HV  *reg = get_hv("Context::Vars::_VARS", GV_ADD);
    SV **svp = hv_fetch(reg, cname, (I32)clen, 0);
    SV  *c;
    AV  *path;

    if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == (is_hash ? SVt_PVHV : SVt_PVAV))
        return SvRV(*svp);

    c = is_hash ? (SV *)newHV() : (SV *)newAV();
    path = newAV();
    av_push(path, newSVpvn(cname, clen));
    context_vars_tie(aTHX_ c, path);
    context_vars_mark_container(aTHX_ c, cname, clen);
    (void)hv_store(reg, cname, (I32)clen, newRV_noinc(c), 0);
    return c;
}

/* Puts the scalar, array or hash for `arg` into `stash` under its name,
 * marked as imported so that `use strict` accepts the name there as it
 * accepts one from `use vars`. Croaks, naming the argument, when it is not a
 * name. */
static void context_vars_import_one(pTHX_ HV *stash, SV *argsv) {
    STRLEN      alen, len;
    const char *arg = SvPV(argsv, alen);
    const char *name;
    SV  *sv;
    SV **gvp;
    GV  *gv;

    len = context_vars_name_ok(arg, alen);
    if (!len)
        croak("Context::Vars: cannot import '%" SVf "': a variable is a "
              "scalar, array or hash with a plain name, such as $request_id", SVfARG(argsv));
    name = arg + 1;
    if (context_vars_name_forced(name, len))
        croak("Context::Vars: cannot import '%" SVf "': perl keeps that name "
              "in package main", SVfARG(argsv));

    gvp = hv_fetch(stash, name, (I32)len, 1);
    if (!gvp) croak("Context::Vars: cannot make a symbol for '%" SVf "'", SVfARG(argsv));
    gv = (GV *)*gvp;
    if (SvTYPE(gv) != SVt_PVGV)
        gv_init(gv, stash, name, len, GV_ADDMULTI);

    if (arg[0] == '$') {
        sv = context_vars_var_for(aTHX_ name, len);
        if (GvSV(gv) != sv) {
            SV *old = GvSV(gv);
            GvSV(gv) = SvREFCNT_inc_simple_NN(sv);
            SvREFCNT_dec(old);
        }
        GvIMPORTED_SV_on(gv);
    }
    else if (arg[0] == '%') {
        sv = context_vars_container_for(aTHX_ arg, alen, 1);
        if ((SV *)GvHV(gv) != sv) {
            HV *old = GvHV(gv);
            GvHV(gv) = (HV *)SvREFCNT_inc_simple_NN(sv);
            SvREFCNT_dec((SV *)old);
        }
        GvIMPORTED_HV_on(gv);
    }
    else {
        sv = context_vars_container_for(aTHX_ arg, alen, 0);
        if ((SV *)GvAV(gv) != sv) {
            AV *old = GvAV(gv);
            GvAV(gv) = (AV *)SvREFCNT_inc_simple_NN(sv);
            SvREFCNT_dec((SV *)old);
        }
        GvIMPORTED_AV_on(gv);
    }
    GvMULTI_on(gv);
}

#endif
