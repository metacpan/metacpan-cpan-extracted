#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "callparser.h"
#include "XSUB.h"
#include "ppport.h"

#define DEMAND_IMMEDIATE 0x00000001
#define DEMAND_NOCONSUME 0x00000002
#define demand_unichar(c, f) THX_demand_unichar(aTHX_ c, f)
static void
THX_demand_unichar (pTHX_ I32 c, U32 flags)
{
  if (!(flags & DEMAND_IMMEDIATE))
    lex_read_space(0);

  if (lex_peek_unichar(0) != c)
    croak("syntax error");

  if (!(flags & DEMAND_NOCONSUME))
    lex_read_unichar(0);
}

#define parse_idword(word) THX_parse_idword(aTHX_ word)
static bool
THX_parse_idword(pTHX_ char const *word)
{
  char *start, *s, c;

  s = start = PL_parser->bufptr;
  c = *s;

  if (!isIDFIRST(c))
    return 0;

  do {
    c = *++s;
  } while (isALNUM(c));

  if (strnNE(word, start, s-start))
    return 0;

  lex_read_to(s);
    return 1;
}

#define parse_blk() THX_parse_blk(aTHX)
static OP *
THX_parse_blk(pTHX)
{
  int blk_floor;
  OP *blkop;

  demand_unichar('{', DEMAND_NOCONSUME);
  blk_floor = Perl_block_start(aTHX_ 1);
  blkop = parse_block(0);
  return op_scope(Perl_block_end(aTHX_ blk_floor, blkop));
}

static OP *
myck_entersub_cond (pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
  OP *pushop, *condop, *rv2cvop;
  OP *parent = entersubop;

  PERL_UNUSED_ARG(namegv);
  PERL_UNUSED_ARG(ckobj);

  pushop = cUNOPx(entersubop)->op_first;
  if (!OpHAS_SIBLING(pushop)) {
    parent = pushop;
    pushop = cUNOPx(pushop)->op_first;
  }

#ifdef op_sibling_splice
  condop = op_sibling_splice(parent, pushop, 1, NULL);
#else
  condop = pushop->op_sibling;
  rv2cvop = condop->op_sibling;
  condop->op_sibling = NULL;
  pushop->op_sibling = rv2cvop;
#endif

  op_free(entersubop);
  return condop;
}

static OP *
myparse_args_cond (pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
  AV *exprs, *blks;
  OP *condop;

  PERL_UNUSED_ARG(namegv);
  PERL_UNUSED_ARG(psobj);
  PERL_UNUSED_ARG(flagsp);

  exprs = newAV();
  blks = newAV();
  AvREAL_off(exprs);
  AvREAL_off(blks);

  while (1) {
    lex_read_space(0);

    switch (lex_peek_unichar(0)) {
    case '(':
      demand_unichar('(', 0);
      av_push(exprs, (SV *)parse_fullexpr(0));
      demand_unichar(')', 0);

      av_push(blks, (SV *)parse_blk());
      continue;
    case 'o':
      if (parse_idword("otherwise")) {
        av_push(exprs, (SV *)newSVOP(OP_CONST, 0, &PL_sv_yes));
        av_push(blks, (SV *)parse_blk());
      }
      continue;
    default:
      break;
    }

    break;
  }

  condop = newOP(OP_STUB, 0);
  while (av_len(exprs) >= 0)
    condop = newCONDOP(0,
                       (OP *)av_pop(exprs),
                       (OP *)av_pop(blks),
                       condop);

  SvREFCNT_inc(exprs);
  SvREFCNT_inc(blks);

  return condop;
}

MODULE = Cond::Expr  PACKAGE = Cond::Expr

void
cond (...)
  CODE:
    PERL_UNUSED_ARG(items);
    croak("cond called as a function");

BOOT:
{
  CV *cond_cv;

  cond_cv = get_cv("Cond::Expr::cond", 0);

  cv_set_call_parser(cond_cv, myparse_args_cond, &PL_sv_undef);
  cv_set_call_checker(cond_cv, myck_entersub_cond, &PL_sv_undef);
}
