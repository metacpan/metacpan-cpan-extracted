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
static int context_vars_writes(pTHX_ OP *o) {
    OP *k;
    if (!o) return 0;
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
