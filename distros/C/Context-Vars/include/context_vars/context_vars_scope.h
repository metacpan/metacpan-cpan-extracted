#ifndef CONTEXT_VARS_SCOPE_H
#define CONTEXT_VARS_SCOPE_H

/* Sub scope: an assignment to an imported variable holds until the sub it is
 * written in returns.
 *
 * "Written in" is lexical - the innermost sub whose text holds the
 * assignment - so it is settled when that sub is COMPILED. perl hands every
 * sub to its optimiser once, when the sub is complete; a hook there looks
 * for a write to one of our scalars, and a sub that has one is given a scope
 * that opens each time the sub is entered. The scope is an ordinary entry
 * on the sub's own save stack, so it closes however the sub is left: by
 * falling off the end, by return from any depth of block, by die, by goto
 * &other, by last out of a caller's loop.
 *
 * A sub with no write is left exactly as perl built it.
 *
 * plan_context_vars/02-scope-spike.md has the evidence for each choice below,
 * on eighteen perls from 5.10.1 to 5.44.0. */

#ifndef OpSIBLING
#  define OpSIBLING(o) ((o)->op_sibling)
#endif
#ifndef isGV_with_GP
#  define isGV_with_GP(sv) (SvTYPE(sv) == SVt_PVGV && GvGP((GV *)(sv)))
#endif

/* ---- opening the scope ----------------------------------------------------- */

static OP *context_vars_pp_scope(pTHX) {
    context_vars_scope(aTHX);
    return NORMAL;
}

/* The usual way: the sub's own first statement marker opens the scope and
 * then does what it always did. Nothing is added to the op tree, so the
 * tools that walk it - B::Deparse, B::Concise - see the sub as it was
 * written, and nothing is allocated. */
static OP *context_vars_pp_nextstate(pTHX) {
    context_vars_scope(aTHX);
    return PL_ppaddr[OP_NEXTSTATE](aTHX);
}

static OP *context_vars_pp_dbstate(pTHX) {
    context_vars_scope(aTHX);
    return PL_ppaddr[OP_DBSTATE](aTHX);
}

static OP *context_vars_first_real(OP *o) {
    while (o && o->op_type == OP_NULL) o = o->op_next;
    return o;
}

/* 1 when the sub opens a scope with its first statement, 2 when with an op
 * of its own, 0 when it opens none. */
static int context_vars_scope_kind(CV *cv) {
    OP *t;
    if (!cv || CvISXSUB(cv) || !CvSTART(cv)) return 0;
    if (CvSTART(cv)->op_ppaddr == context_vars_pp_scope) return 2;
    t = context_vars_first_real(CvSTART(cv));
    if (t && (t->op_ppaddr == context_vars_pp_nextstate
              || t->op_ppaddr == context_vars_pp_dbstate))
        return 1;
    return 0;
}

#ifdef XopENTRY_set
static XOP context_vars_xop;
#endif

static void context_vars_register_op(pTHX) {
#ifdef XopENTRY_set
    XopENTRY_set(&context_vars_xop, xop_name, "context_vars_scope");
    XopENTRY_set(&context_vars_xop, xop_desc, "open a Context::Vars scope");
    XopENTRY_set(&context_vars_xop, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ context_vars_pp_scope, &context_vars_xop);
#else
    SV *key = sv_2mortal(newSViv(PTR2IV(context_vars_pp_scope)));
    if (!PL_custom_op_names) PL_custom_op_names = newHV();
    if (!PL_custom_op_descs) PL_custom_op_descs = newHV();
    (void)hv_store_ent(PL_custom_op_names, key, newSVpv("context_vars_scope", 0), 0);
    (void)hv_store_ent(PL_custom_op_descs, key, newSVpv("open a Context::Vars scope", 0), 0);
#endif
}

/* Gives the sub its scope. The first statement marker is used unless it has
 * a label - a goto to the label would open the scope a second time - or the
 * sub does not begin with one. Then a new op goes in front, into the op tree
 * as well as the run order so that it is freed with the sub. */
static void context_vars_plant(pTHX_ CV *cv) {
    OP *t = context_vars_first_real(CvSTART(cv));
    OP *root, *body, *s;

    if (t && (t->op_type == OP_NEXTSTATE || t->op_type == OP_DBSTATE)
        && !CopLABEL((COP *)t)) {
        t->op_ppaddr = (t->op_type == OP_NEXTSTATE)
                     ? context_vars_pp_nextstate : context_vars_pp_dbstate;
        return;
    }

    root = CvROOT(cv);
    body = (root->op_flags & OPf_KIDS) ? cUNOPx(root)->op_first : NULL;
    if (!body || body->op_type != OP_LINESEQ || !(body->op_flags & OPf_KIDS))
        return;     /* nowhere to hang an op: the sub goes unscoped */

    s = newOP(OP_CUSTOM, 0);
    s->op_ppaddr = context_vars_pp_scope;
    s->op_next   = CvSTART(cv);
    CvSTART(cv)  = s;
#if PERL_VERSION >= 22
    op_sibling_splice(body, NULL, 0, s);
#else
    s->op_sibling = cLISTOPx(body)->op_first;
    cLISTOPx(body)->op_first = s;
#endif
}

/* ---- finding a write ------------------------------------------------------- */

/* Is there anywhere in this tree a write to one of our scalars? Run BEFORE
 * perl's own optimiser: until then a package scalar is an rv2sv over a gv
 * and still carries the flags the compiler gave it, and the optimiser fuses
 * the two and drops them. The whole tree is walked, not the run order, which
 * would miss every branch.
 *
 * A write is OPf_MOD together with OPf_REF, or OPpLVAL_INTRO. That is every
 * kind of assignment, ++ and --, chomp, chop, undef, s///, tr/// and local.
 * It is also \$x, so a sub that takes a reference to the variable is given
 * a scope. A variable passed as an argument is OPf_MOD alone, and is not.
 *
 * Part of a sub may have been optimised already: perl 5.14 and older
 * optimise a map or grep block as soon as it is parsed, before the sub
 * around it is finished. There the rv2sv is nulled and the gv beneath it
 * fused into a gvsv - but the nulled op keeps its flags, so it is read the
 * same way. */
/* Ext magic with this vtable, by hand: mg_findext is 5.14. */
static int context_vars_has_ext(SV *sv, const MGVTBL *vt) {
    MAGIC *mg;
    if (!sv || SvTYPE(sv) < SVt_PVMG) return 0;
    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == vt) return 1;
    return 0;
}

/* Is a glob one of ours: a scalar carrying our magic, or an array or hash
 * carrying the container mark? */
static int context_vars_gv_ours(pTHX_ GV *gv) {
    if (!gv || !isGV_with_GP(gv)) return 0;
    if (context_vars_var_mg(GvSV(gv))) return 1;
    if (context_vars_has_ext((SV *)GvHV(gv), &context_vars_container_vtbl)) return 1;
    if (context_vars_has_ext((SV *)GvAV(gv), &context_vars_container_vtbl)) return 1;
    return 0;
}

/* Follows an lvalue down its first children - element, dereference, the
 * nulled forms the optimiser leaves - to the glob at its root, and says
 * whether that is one of ours. */
static int context_vars_rooted(pTHX_ OP *o) {
    int guard = 0;
    while (o && guard++ < 256) {
        switch (o->op_type) {
        case OP_GV: case OP_GVSV:
            return context_vars_gv_ours(aTHX_ cGVOPx_gv(o));
        case OP_PUSHMARK:
            o = OpSIBLING(o);
            continue;
        case OP_HSLICE: case OP_ASLICE:
            /* A slice's container is its last child: the keys come first. */
            if (!(o->op_flags & OPf_KIDS)) return 0;
            o = cLISTOPx(o)->op_last;
            continue;
        case OP_SCOPE: case OP_LEAVE: case OP_LINESEQ:
            /* A dereference written as a block, @{ $h{a} }, is a scope whose
             * value is its last statement; the first is a dead nextstate. */
            if (!(o->op_flags & OPf_KIDS)) return 0;
            o = cLISTOPx(o)->op_last;
            continue;
        case OP_HELEM: case OP_AELEM: case OP_RV2HV: case OP_RV2AV: case OP_RV2SV:
        case OP_NULL: case OP_EXISTS: case OP_DELETE: case OP_LIST:
            if (!(o->op_flags & OPf_KIDS)) return 0;
            o = cUNOPx(o)->op_first;
            continue;
        default:
            return 0;
        }
    }
    return 0;
}

/* A write to an array, a hash, an element of one, or anything below one.
 *
 * perl marks some reads as modifications too, and those are left out: an
 * element in the middle of a chain, $h{a} in $h{a}{b}, is marked so that it
 * can be made if it is missing (OPpDEREF); an element passed to a sub is
 * marked in case the sub assigns through @_ (OPpLVAL_DEFER), which the pass
 * does not see for a scalar either. */
static int context_vars_deep_write(pTHX_ OP *o) {
    switch (o->op_type) {
    case OP_HELEM: case OP_AELEM:
        if (o->op_private & (OPpDEREF | OPpLVAL_DEFER)) return 0;
        if ((o->op_flags & OPf_MOD) || (o->op_private & OPpLVAL_INTRO))
            return context_vars_rooted(aTHX_ o);
        return 0;
    case OP_RV2HV: case OP_RV2AV:
    case OP_HSLICE: case OP_ASLICE:
        if ((o->op_flags & OPf_MOD) || (o->op_private & OPpLVAL_INTRO))
            return context_vars_rooted(aTHX_ o);
        return 0;
    case OP_DELETE: case OP_PUSH: case OP_POP: case OP_SHIFT: case OP_UNSHIFT: case OP_SPLICE:
        return (o->op_flags & OPf_KIDS) && context_vars_rooted(aTHX_ cUNOPx(o)->op_first);
    default:
        return 0;
    }
}

/* Ops whose container operand perl marks as modified for its own purposes,
 * not because it is written: keys, values and each reset an iterator, and
 * foreach, grep and map make aliases. A write through those aliases is one
 * the pass does not see, as for a scalar. */
static int context_vars_reads_container(OP *o) {
    switch (o->op_type) {
    case OP_KEYS: case OP_VALUES: case OP_EACH:
    case OP_ENTERITER: case OP_GREPSTART: case OP_MAPSTART:
        return 1;
    default:
        return 0;
    }
}

static int context_vars_writes(pTHX_ OP *o);

/* The kids of such an op, with any array or hash among them - directly, or
 * inside the list perl wraps them in - not counted as written, and everything
 * below them looked at as usual. */
static int context_vars_writes_under_reader(pTHX_ OP *o) {
    OP *k, *g;
    if (!(o->op_flags & OPf_KIDS)) return 0;
    for (k = cUNOPx(o)->op_first; k; k = OpSIBLING(k)) {
        if (k->op_type == OP_RV2AV || k->op_type == OP_RV2HV) {
            if (k->op_flags & OPf_KIDS)
                for (g = cUNOPx(k)->op_first; g; g = OpSIBLING(g))
                    if (context_vars_writes(aTHX_ g)) return 1;
        }
        else if ((k->op_type == OP_LIST || k->op_type == OP_NULL) && (k->op_flags & OPf_KIDS)) {
            if (context_vars_writes_under_reader(aTHX_ k)) return 1;
        }
        else if (context_vars_writes(aTHX_ k)) return 1;
    }
    return 0;
}

static int context_vars_writes(pTHX_ OP *o) {
    OP *k;
    if (!o) return 0;
    if (context_vars_reads_container(o)) return context_vars_writes_under_reader(aTHX_ o);
    if (context_vars_deep_write(aTHX_ o)) return 1;
    if ((o->op_type == OP_RV2SV
         || (o->op_type == OP_NULL && o->op_targ == OP_RV2SV))
        && (o->op_flags & OPf_KIDS)) {
        k = cUNOPx(o)->op_first;
        if (k && (k->op_type == OP_GV || k->op_type == OP_GVSV)) {
            GV *gv = cGVOPx_gv(k);
            if (gv && isGV_with_GP(gv) && context_vars_var_mg(GvSV(gv))
                && (o->op_flags & OPf_MOD)
                && ((o->op_flags & OPf_REF) || (o->op_private & OPpLVAL_INTRO)))
                return 1;
        }
    }
    if (o->op_flags & OPf_KIDS)
        for (k = cUNOPx(o)->op_first; k; k = OpSIBLING(k))
            if (context_vars_writes(aTHX_ k)) return 1;
    return 0;
}

/* BEGIN and its kind are never given a scope: an assignment there is meant
 * for the program. */
static int context_vars_special_block(pTHX_ CV *cv) {
    const char *n = NULL;
#ifdef CvNAMED
    if (CvNAMED(cv)) n = HEK_KEY(CvNAME_HEK(cv));
    else
#endif
    if (CvGV(cv)) n = GvNAME(CvGV(cv));
    if (!n) return 0;
    return strEQ(n, "BEGIN") || strEQ(n, "END") || strEQ(n, "INIT")
        || strEQ(n, "CHECK") || strEQ(n, "UNITCHECK");
}

/* ---- the optimiser hook ------------------------------------------------------ */

static peep_t context_vars_prev_peep = NULL;

/* perl calls the optimiser for a finished sub with that sub's first op, while
 * the sub is still PL_compcv. Anything else it is called for - file code, a
 * string eval - is passed straight on. */
static void context_vars_peep(pTHX_ OP *o) {
    CV *cv = PL_compcv;
    int plant = 0;

    if (o && cv && SvTYPE((SV *)cv) == SVt_PVCV && !CvISXSUB(cv)
        && CvROOT(cv) && CvSTART(cv) == o
        && !context_vars_special_block(aTHX_ cv))
        plant = context_vars_writes(aTHX_ CvROOT(cv));

    context_vars_prev_peep(aTHX_ o);

    if (plant && CvSTART(cv) && !context_vars_scope_kind(cv))
        context_vars_plant(aTHX_ cv);
}

/* Once for the process. The hook is chained, so another module's hook,
 * installed before or after, still runs. */
static void context_vars_scope_boot(pTHX) {
    context_vars_register_op(aTHX);
    if (!context_vars_prev_peep) {
        context_vars_prev_peep = PL_peepp;
        PL_peepp = context_vars_peep;
    }
}

#endif
