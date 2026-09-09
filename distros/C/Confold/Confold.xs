#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "confold_compat.h"

#define CONFOLD_HINT_KEY  "Confold/on"
#define CONFOLD_HINT_LEN  (sizeof(CONFOLD_HINT_KEY) - 1)

#define CONFOLD_SENTINEL_CH  'C'

static Perl_infix_plugin_t   cf_next_infix_plugin;
static Perl_keyword_plugin_t cf_next_keyword_plugin;

static int cf_armed  = 0;
static IV  cf_offset = -1;

static XOP cf_confold_xop;

static OP *
cf_pp_confold(pTHX)
{
    dSP;
    SV *sv = TOPs;
    SV *copy;

    SvGETMAGIC(sv);
    copy = sv_2mortal(newSVsv_nomg(sv));
    SvREADONLY_on(copy);

    SETs(copy);
    RETURN;
}

static bool
cf_hint_active(pTHX)
{
    HV *hints = GvHV(PL_hintgv);
    SV **hent;

    if (!hints)
        return FALSE;

    hent = hv_fetch(hints, CONFOLD_HINT_KEY, (I32)CONFOLD_HINT_LEN, 0);
    return cBOOL(hent && *hent && SvTRUE(*hent));
}

typedef struct {
    CV        *cv;
    PADOFFSET  off;
    SV        *sv;
} cf_slot;

static cf_slot *cf_slots     = NULL;
static IV       cf_slot_used = 0;
static IV       cf_slot_size = 0;

#define CF_PENDING_MAX 32
static OP *cf_pending[CF_PENDING_MAX];
static int cf_pending_used = 0;

static void
cf_mark_const(OP *o)
{
    if (cf_pending_used >= CF_PENDING_MAX)
        cf_pending_used = 0;
    cf_pending[cf_pending_used++] = o;
}

static bool
cf_is_marked(const OP *o)
{
    int i;
    for (i = 0; i < cf_pending_used; i++)
        if (cf_pending[i] == o)
            return TRUE;
    return FALSE;
}

static void
cf_slot_record(pTHX_ CV *cv, PADOFFSET off, SV *sv)
{
    IV i;

    for (i = 0; i < cf_slot_used; i++) {
        if (cf_slots[i].cv == cv && cf_slots[i].off == off) {
            SvREFCNT_dec(cf_slots[i].sv);
            cf_slots[i].sv = newSVsv(sv);
            SvREADONLY_on(cf_slots[i].sv);
            return;
        }
    }

    if (cf_slot_used >= cf_slot_size) {
        cf_slot_size = cf_slot_size ? cf_slot_size * 2 : 16;
        Renew(cf_slots, cf_slot_size, cf_slot);
    }

    cf_slots[cf_slot_used].cv  = cv;
    cf_slots[cf_slot_used].off = off;
    cf_slots[cf_slot_used].sv  = newSVsv(sv);
    SvREADONLY_on(cf_slots[cf_slot_used].sv);
    cf_slot_used++;
}

static SV *
cf_slot_lookup_one(pTHX_ CV *cv, PADOFFSET off)
{
    IV i;
    for (i = 0; i < cf_slot_used; i++)
        if (cf_slots[i].cv == cv && cf_slots[i].off == off)
            return cf_slots[i].sv;
    return NULL;
}

static SV *
cf_slot_lookup(pTHX_ CV *cv, PADOFFSET off)
{
    int guard = 0;

    while (cv && off && guard++ < 32) {
        PADNAMELIST *pnl;
        PADNAME     *pn;
        SV          *found = cf_slot_lookup_one(aTHX_ cv, off);

        if (found)
            return found;

        if (!CvPADLIST(cv))
            return NULL;

        pnl = PadlistNAMES(CvPADLIST(cv));
        if (!pnl || (SSize_t)off > PadnamelistMAX(pnl))
            return NULL;

        pn = PadnamelistARRAY(pnl)[off];
        if (!pn || !PadnameOUTER(pn))
            return NULL;

        off = PARENT_PAD_INDEX(pn);
        cv  = CvOUTSIDE(cv);
    }

    return NULL;
}

static SV *
cf_const_sv(pTHX_ const OP *o)
{
    if (!o)
        return NULL;

    if (o->op_type == OP_CONST)
        return cSVOPx_sv((OP *)o);

    if (o->op_type == OP_PADSV)
        return cf_slot_lookup(aTHX_ PL_compcv, o->op_targ);

    return NULL;
}

static OP *
cf_wrap(pTHX_ OP *operand)
{
    OP *o;

    if (!operand)
        return NULL;

    if (operand->op_type == OP_CONST) {
        cf_mark_const(operand);
        return operand;
    }

    if (operand->op_type == OP_PADSV) {
        SV *known = cf_slot_lookup(aTHX_ PL_compcv, operand->op_targ);
        if (known) {
            OP *k = newSVOP(OP_CONST, 0, newSVsv(known));
            SvREADONLY_on(cSVOPx_sv(k));
            op_free(operand);
            cf_mark_const(k);
            return k;
        }
    }

    o = newUNOP(OP_NULL, 0, operand);
    CF_MAKE_CUSTOM(o, cf_pp_confold);
    return o;
}

static bool
cf_looser_than_refgen(const OP *o)
{
    switch (o->op_type) {
        case OP_ADD:        case OP_I_ADD:
        case OP_SUBTRACT:   case OP_I_SUBTRACT:
        case OP_MULTIPLY:   case OP_I_MULTIPLY:
        case OP_DIVIDE:     case OP_I_DIVIDE:
        case OP_MODULO:     case OP_I_MODULO:
        case OP_CONCAT:
        case OP_REPEAT:
        case OP_LEFT_SHIFT:
        case OP_RIGHT_SHIFT:
            return TRUE;
        default:
            return FALSE;
    }
}

static void
cf_drop_op_next(pTHX_ OP *o)
{
    OP *kid;

    if (!o)
        return;

    o->op_next = NULL;

    if (o->op_flags & OPf_KIDS) {
        for (kid = cUNOPx(o)->op_first; kid; kid = OpSIBLING(kid))
            cf_drop_op_next(aTHX_ kid);
    }
}

static OP *
cf_rebalance(pTHX_ OP *o)
{
    OP *parent = NULL;
    OP *cur    = o;
    OP *kid;

    while (!(cur->op_flags & OPf_PARENS)
        && cf_looser_than_refgen(cur)
        && (cur->op_flags & OPf_KIDS)
        && cBINOPx(cur)->op_first
        && OpHAS_SIBLING(cBINOPx(cur)->op_first))
    {
        parent = cur;
        cur    = cBINOPx(cur)->op_first;
    }

    if (!parent)
        return cf_wrap(aTHX_ o);

    kid = op_sibling_splice(parent, NULL, 1, NULL);
    op_sibling_splice(parent, NULL, 0,
                      op_contextualize(cf_wrap(aTHX_ kid), G_SCALAR));

    cf_drop_op_next(aTHX_ o);

    return o;
}

static char *
cf_find_glyph(pTHX)
{
    char *p   = CF_bufptr;
    char *end = CF_bufend;

    if (!p || !end)
        return NULL;

    while (p < end) {
        if (isSPACE(*p))
            p++;
        else if (*p == '#') {
            while (p < end && *p != '\n')
                p++;
        }
        else break;
    }

    if (p + 1 < end && p[0] == '<' && p[1] == ':')
        return p;

    return NULL;
}

static Perl_check_t cf_next_ck_padsv_store;
static Perl_check_t cf_next_ck_sassign;

static void
cf_slot_forget(pTHX_ CV *cv, PADOFFSET off)
{
    IV i;

    for (i = 0; i < cf_slot_used; i++) {
        if (cf_slots[i].cv == cv && cf_slots[i].off == off) {
            SvREFCNT_dec(cf_slots[i].sv);
            cf_slots[i] = cf_slots[--cf_slot_used];
            return;
        }
    }
}

static void
cf_note_declaration(pTHX_ OP *store, OP *value, PADOFFSET off)
{
    PERL_UNUSED_ARG(store);

    if (!off)
        return;

    if (value && cf_is_marked(value)) {
        cf_slot_record(aTHX_ PL_compcv, off, cSVOPx_sv(value));
        cf_pending_used = 0;
        return;
    }

    cf_slot_forget(aTHX_ PL_compcv, off);
}

static Perl_check_t cf_next_ck_entersub;

static OP *
cf_ck_entersub(pTHX_ OP *o)
{
    OP *kid;

    if (PL_compcv && (o->op_flags & OPf_KIDS)) {
        OP *parent = o;
        OP *prev   = NULL;

        kid = cUNOPx(o)->op_first;
        if (kid && (kid->op_type == OP_LIST || kid->op_type == OP_NULL)
                && (kid->op_flags & OPf_KIDS)) {
            parent = kid;
            kid    = cUNOPx(kid)->op_first;
        }

        while (kid) {
            OP *next  = OpSIBLING(kid);
            SV *known = NULL;

            if (kid->op_type == OP_PADSV
             && kid->op_targ
             && !(kid->op_private & OPpLVAL_INTRO))
                known = cf_slot_lookup(aTHX_ PL_compcv, kid->op_targ);

            if (known) {
                OP *k = newSVOP(OP_CONST, 0, newSVsv(known));

                SvREADONLY_on(cSVOPx_sv(k));
                op_free(op_sibling_splice(parent, prev, 1, k));
                op_contextualize(k, G_SCALAR);
                cf_drop_op_next(aTHX_ o);
                prev = k;
            }
            else {
                prev = kid;
            }

            kid = next;
        }
    }

    return cf_next_ck_entersub(aTHX_ o);
}

static OP *
cf_ck_padsv_store(pTHX_ OP *o)
{
    o = cf_next_ck_padsv_store(aTHX_ o);

    if (o->op_type == OP_PADSV_STORE && (o->op_flags & OPf_KIDS))
        cf_note_declaration(aTHX_ o, cUNOPx(o)->op_first, o->op_targ);

    return o;
}

static OP *
cf_ck_sassign(pTHX_ OP *o)
{
    o = cf_next_ck_sassign(aTHX_ o);

    if (o->op_type == OP_SASSIGN && (o->op_flags & OPf_KIDS)) {
        OP *value  = cBINOPx(o)->op_first;
        OP *target = value ? OpSIBLING(value) : NULL;

        if (target && target->op_type == OP_PADSV) {
            if (target->op_private & OPpLVAL_INTRO)
                cf_note_declaration(aTHX_ o, value, target->op_targ);
            else
                cf_slot_forget(aTHX_ PL_compcv, target->op_targ);
        }
    }

    return o;
}

static STRLEN
cf_infix_plugin(pTHX_ char *opname, STRLEN oplen, struct Perl_custom_infix **def)
{
    if (oplen >= 2 && opname[0] == '<' && opname[1] == ':'
     && PL_parser && CF_expect != XOPERATOR
     && cf_hint_active(aTHX))
    {
        char *glyph = cf_find_glyph(aTHX);

        if (glyph) {
            cf_offset = glyph - SvPVX(CF_linestr);
            cf_armed  = 1;
            glyph[0]  = CONFOLD_SENTINEL_CH;
            glyph[1]  = ' ';
            return 0;
        }
    }

    return cf_next_infix_plugin(aTHX_ opname, oplen, def);
}

static int
cf_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr)
{
    if (cf_armed
     && keyword_len == 1
     && keyword_ptr[0] == CONFOLD_SENTINEL_CH
     && PL_parser
     && (CF_bufptr - SvPVX(CF_linestr)) == cf_offset + 1)
    {
        IV    off = cf_offset;
        OP   *operand;
        char *base;

        cf_armed  = 0;
        cf_offset = -1;

        operand = parse_arithexpr(0);

        base = SvPVX(CF_linestr);
        if (off >= 0 && off + 1 < (IV)SvCUR(CF_linestr)
         && base[off] == CONFOLD_SENTINEL_CH && base[off + 1] == ' ')
        {
            base[off]     = '<';
            base[off + 1] = ':';
        }

        if (!operand)
            croak("confold: missing operand for <:");

        *op_ptr = cf_rebalance(aTHX_ operand);
        return KEYWORD_PLUGIN_EXPR;
    }

    return cf_next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
}

MODULE = Confold    PACKAGE = Confold

PROTOTYPES: DISABLE

void
_hint_on()
CODE:
{
    HV *hints = GvHV(PL_hintgv);
    if (hints) {
        (void)hv_store(hints, CONFOLD_HINT_KEY, (I32)CONFOLD_HINT_LEN,
                       newSViv(1), 0);
        PL_hints |= HINT_LOCALIZE_HH;
    }
}

void
_hint_off()
CODE:
{
    HV *hints = GvHV(PL_hintgv);
    if (hints) {
        (void)hv_delete(hints, CONFOLD_HINT_KEY, (I32)CONFOLD_HINT_LEN,
                        G_DISCARD);
        PL_hints |= HINT_LOCALIZE_HH;
    }
}

BOOT:
{
    XopENTRY_set(&cf_confold_xop, xop_name, "confold");
    XopENTRY_set(&cf_confold_xop, xop_desc, "constant fold");
    XopENTRY_set(&cf_confold_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ cf_pp_confold, &cf_confold_xop);

    wrap_infix_plugin(cf_infix_plugin, &cf_next_infix_plugin);

    cf_next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin = cf_keyword_plugin;

    wrap_op_checker(OP_ENTERSUB,    cf_ck_entersub,    &cf_next_ck_entersub);
    wrap_op_checker(OP_PADSV_STORE, cf_ck_padsv_store, &cf_next_ck_padsv_store);
    wrap_op_checker(OP_SASSIGN,     cf_ck_sassign,     &cf_next_ck_sassign);
}
