/* clone implementation, big, slow, useless, but not pointless */

static AV *
clone_av (pTHX_ AV *av)
{
  int i;
  AV *nav = newAV ();

  av_fill (nav, AvFILLp (av));

  for (i = 0; i <= AvFILLp (av); ++i)
    AvARRAY (nav)[i] = SvREFCNT_inc (AvARRAY (av)[i]);

  return nav;
}

static struct coro *
coro_clone (pTHX_ struct coro *coro)
{
  perl_slots *slot, *nslot;
  struct coro *ncoro;

  if (coro->flags & (CF_RUNNING | CF_NEW))
    croak ("Coro::State::clone cannot clone new or running states, caught");

  if (coro->cctx)
    croak ("Coro::State::clone cannot clone a state running on a custom C context, caught");

  /* TODO: maybe check slf_frame for prpeare_rransfer/check_nop? */

  slot = coro->slot;

  if (slot->curstackinfo->si_type != PERLSI_MAIN)
    croak ("Coro::State::clone cannot clone a state running on a non-main stack, caught");

  Newz (0, ncoro, 1, struct coro);
  Newz (0, nslot, 1, perl_slots);

  /* copy first, then fixup */
  *ncoro = *coro;
  *nslot = *slot;
  ncoro->slot = nslot;

  nslot->curstackinfo = new_stackinfo (slot->stack_max - slot->stack_sp + 1, slot->curstackinfo->si_cxmax);
  nslot->curstackinfo->si_type = PERLSI_MAIN;
  nslot->curstackinfo->si_cxix = slot->curstackinfo->si_cxix;
  nslot->curstack = nslot->curstackinfo->si_stack;
  ncoro->mainstack = nslot->curstack;

  nslot->stack_base = AvARRAY (nslot->curstack);
  nslot->stack_sp   = nslot->stack_base + (slot->stack_sp - slot->stack_base);
  nslot->stack_max  = nslot->stack_base + AvMAX (nslot->curstack);

  Copy (slot->stack_base, nslot->stack_base, slot->stack_sp - slot->stack_base + 1, SV *);
  Copy (slot->curstackinfo->si_cxstack, nslot->curstackinfo->si_cxstack, nslot->curstackinfo->si_cxix + 1, PERL_CONTEXT);

  New (50, nslot->tmps_stack, nslot->tmps_max, SV *);
  Copy (slot->tmps_stack, nslot->tmps_stack, slot->tmps_ix + 1, SV *);

  New (54, nslot->markstack, slot->markstack_max - slot->markstack + 1, I32);
  nslot->markstack_ptr = nslot->markstack + (slot->markstack_ptr - slot->markstack);
  nslot->markstack_max = nslot->markstack + (slot->markstack_max - slot->markstack);
  Copy (slot->markstack, nslot->markstack, slot->markstack_ptr - slot->markstack + 1, I32);

#ifdef SET_MARK_OFFSET
    //SET_MARK_OFFSET; /*TODO*/
#endif

  New (54, nslot->scopestack, slot->scopestack_max, I32);
  Copy (slot->scopestack, nslot->scopestack, slot->scopestack_ix + 1, I32);

  New (54, nslot->savestack, nslot->savestack_max, ANY);
  Copy (slot->savestack, nslot->savestack, slot->savestack_ix + 1, ANY);

#if !PERL_VERSION_ATLEAST (5,10,0)
  New (54, nslot->retstack, nslot->retstack_max, OP *);
  Copy (slot->retstack, nslot->retstack, slot->retstack_max, OP *);
#endif

  /* first fix up the padlists, by walking up our own saved state */
  {
    SV **sp = nslot->stack_sp;
    AV *av;
    CV *cv;
    int i;

    /* now do the ugly restore mess */
    while (expect_true (cv = (CV *)POPs))
      {
        /* cv will be refcnt_inc'ed twice by the following two loops */
        POPs;

        /* need to clone the padlist */
        /* this simplistic hack is most likely wrong */
        av = clone_av (aTHX_ (AV *)TOPs);
        AvREAL_off (av);

        for (i = 1; i <= AvFILLp (av); ++i)
          {
            SvREFCNT_dec (AvARRAY (av)[i]);
            AvARRAY (av)[i] = (SV *)clone_av (aTHX_ (AV *)AvARRAY (av)[i]);
            AvREIFY_only (AvARRAY (av)[i]);
          }

        TOPs = (SV *)av;

        POPs;
      }
  }

  /* easy things first, mortals */
  {
    int i;

    for (i = 0; i <= nslot->tmps_ix; ++i)
      SvREFCNT_inc (nslot->tmps_stack [i]);
  }

  /* now fix up the context stack, modelled after cx_dup */
  {
    I32 cxix = nslot->curstackinfo->si_cxix;
    PERL_CONTEXT *ccstk = nslot->curstackinfo->si_cxstack;

    while (expect_true (cxix >= 0))
      {
        PERL_CONTEXT *cx = &ccstk[cxix--];

        switch (CxTYPE (cx))
          {
            case CXt_SUBST:
              croak ("Coro::State::clone cannot clone a state inside a substitution context, caught");

            case CXt_SUB:
              if (cx->blk_sub.olddepth == 0)
                SvREFCNT_inc ((SV *)cx->blk_sub.cv);

              if (cx->blk_sub.hasargs)
                {
                  SvREFCNT_inc ((SV *)cx->blk_sub.argarray);
                  SvREFCNT_inc ((SV *)cx->blk_sub.savearray);
                }
              break;

            case CXt_EVAL:
              SvREFCNT_inc ((SV *)cx->blk_eval.old_namesv);
              SvREFCNT_inc ((SV *)cx->blk_eval.cur_text);
              break;

            case CXt_LOOP:
              /*TODO: cx->blk_loop.iterdata*/
              SvREFCNT_inc ((SV *)cx->blk_loop.itersave);
              SvREFCNT_inc ((SV *)cx->blk_loop.iterlval);
              SvREFCNT_inc ((SV *)cx->blk_loop.iterary);
              break;

            case CXt_FORMAT:
              croak ("Coro::State::clone cannot clone a state inside a format, caught");
              break;

            /* BLOCK, NULL etc. */
          }
      }
  }

  /* now fix up the save stack */
  /* modelled after ss_dup */

#define POPINT(ss,ix)   ((ss)[--(ix)].any_i32)
#define TOPINT(ss,ix)   ((ss)[ix].any_i32)
#define POPLONG(ss,ix)  ((ss)[--(ix)].any_long)
#define TOPLONG(ss,ix)  ((ss)[ix].any_long)
#define POPIV(ss,ix)    ((ss)[--(ix)].any_iv)
#define TOPIV(ss,ix)    ((ss)[ix].any_iv)
#define POPBOOL(ss,ix)  ((ss)[--(ix)].any_bool)
#define TOPBOOL(ss,ix)  ((ss)[ix].any_bool)
#define POPPTR(ss,ix)   ((ss)[--(ix)].any_ptr)
#define TOPPTR(ss,ix)   ((ss)[ix].any_ptr)
#define POPDPTR(ss,ix)  ((ss)[--(ix)].any_dptr)
#define TOPDPTR(ss,ix)  ((ss)[ix].any_dptr)
#define POPDXPTR(ss,ix) ((ss)[--(ix)].any_dxptr)
#define TOPDXPTR(ss,ix) ((ss)[ix].any_dxptr)

  {
    ANY * const ss	= nslot->savestack;
    const I32 max	= nslot->savestack_max;
    I32 ix		= nslot->savestack_ix;
    void *any_ptr;

    while (ix > 0)
      {
        const I32 type = POPINT (ss, ix);

        switch (type)
          {
            case SAVEt_HELEM:      /* hash element */
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              /* fall through */
            case SAVEt_ITEM:       /* normal string */
            case SAVEt_SV:         /* scalar reference */
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              /* fall through */
            case SAVEt_FREESV:
            case SAVEt_MORTALIZESV:
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              break;

            case SAVEt_SHARED_PVREF:       /* char* in shared space */
              abort ();
#if 0
              c = (char *) POPPTR (ss, ix);
              TOPPTR (ss, ix) = savesharedpv (c);
              ptr = POPPTR (ss, ix);
              TOPPTR (ss, ix) = any_dup (ptr, proto_perl);
#endif
              break;
            case SAVEt_GENERIC_SVREF:      /* generic sv */
            case SAVEt_SVREF:      /* scalar reference */
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              POPPTR (ss, ix);
              break;

            case SAVEt_HV:         /* hash reference */
            case SAVEt_AV:         /* array reference */
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              /* fall through */
            case SAVEt_COMPPAD:
            case SAVEt_NSTAB:
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              break;

            case SAVEt_INT:        /* int reference */
              POPPTR (ss, ix);
              POPINT (ss, ix);
              break;

            case SAVEt_LONG:       /* long reference */
              POPPTR (ss, ix);
              /* fall through */
            case SAVEt_CLEARSV:
              POPLONG (ss, ix);
              break;

            case SAVEt_I32:        /* I32 reference */
            case SAVEt_I16:        /* I16 reference */
            case SAVEt_I8:         /* I8 reference */
            case SAVEt_COP_ARYBASE:        /* call CopARYBASE_set */
              POPPTR (ss, ix);
              POPINT (ss, ix);
              break;

            case SAVEt_IV:         /* IV reference */
              POPPTR (ss, ix);
              POPIV (ss, ix);
              break;

            case SAVEt_HPTR:       /* HV* reference */
            case SAVEt_APTR:       /* AV* reference */
            case SAVEt_SPTR:       /* SV* reference */
              POPPTR (ss, ix);
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              break;

            case SAVEt_VPTR:       /* random* reference */
              POPPTR (ss, ix);
              POPPTR (ss, ix);
              break;
            case SAVEt_GENERIC_PVREF:      /* generic char* */
            case SAVEt_PPTR:       /* char* reference */
              POPPTR (ss, ix);
              any_ptr = POPPTR (ss, ix);
              TOPPTR (ss, ix) = savepv ((char *) any_ptr);
              break;

            case SAVEt_GP:         /* scalar reference */
              ((GP *) POPPTR (ss, ix))->gp_refcnt++;
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              break;

            case SAVEt_FREEOP:
              abort ();
#if 0
              ptr = POPPTR (ss, ix);
              if (ptr && (((OP *) ptr)->op_private & OPpREFCOUNTED))
                {
                  /* these are assumed to be refcounted properly */
                  OP *o;

                  switch (((OP *) ptr)->op_type)
                    {
                      case OP_LEAVESUB:
                      case OP_LEAVESUBLV:
                      case OP_LEAVEEVAL:
                      case OP_LEAVE:
                      case OP_SCOPE:
                      case OP_LEAVEWRITE:
                        TOPPTR (ss, ix) = ptr;
                        o = (OP *) ptr;
                        OP_REFCNT_LOCK;
                        (void) OpREFCNT_inc (o);
                        OP_REFCNT_UNLOCK;
                        break;
                      default:
                        TOPPTR (ss, ix) = NULL;
                        break;
                    }
                }
              else
                TOPPTR (ss, ix) = NULL;
#endif
              break;

            case SAVEt_FREEPV:
              any_ptr = POPPTR (ss, ix);
              TOPPTR (ss, ix) = savepv ((char *) any_ptr);
              break;

            case SAVEt_DELETE:
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              any_ptr = POPPTR (ss, ix);
              TOPPTR (ss, ix) = savepv ((char *) any_ptr);
              /* fall through */
            case SAVEt_STACK_POS:  /* Position on Perl stack */
              POPINT (ss, ix);
              break;

            case SAVEt_DESTRUCTOR:
              POPPTR (ss, ix);
              POPDPTR (ss, ix);
              break;

            case SAVEt_DESTRUCTOR_X:
              POPPTR (ss, ix);
              POPDXPTR (ss, ix);
              break;

            case SAVEt_REGCONTEXT:
            case SAVEt_ALLOC:
              {
                I32 ni = POPINT (ss, ix);
                ix = ni;
              }
              break;

            case SAVEt_AELEM:      /* array element */
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              POPINT (ss, ix);
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              break;
            case SAVEt_OP:
              POPPTR (ss, ix);
              break;
            case SAVEt_HINTS:
              abort ();
#if 0
              {
                int i = POPINT (ss, ix);
                void *ptr = POPPTR (ss, ix);
                if (ptr)
                  ((struct refcounted_he *)ptr)->refcounted_he_refcnt++;

                if (i & HINT_LOCALIZE_HH)
                  SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              }
#endif
              break;

            case SAVEt_PADSV:
              POPLONG (ss, ix);
              POPPTR (ss, ix);
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              break;

            case SAVEt_BOOL:
              POPPTR (ss, ix);
              POPBOOL (ss, ix);
              break;

            case SAVEt_SET_SVFLAGS:
              POPINT (ss, ix);
              POPINT (ss, ix);
              SvREFCNT_inc ((SV *) POPPTR (ss, ix));
              break;

            case SAVEt_RE_STATE:
              abort ();
#if 0
              {
                const struct re_save_state *const old_state = (struct re_save_state *) (ss + ix - SAVESTACK_ALLOC_FOR_RE_SAVE_STATE);
                struct re_save_state *const new_state = (struct re_save_state *) (ss + ix - SAVESTACK_ALLOC_FOR_RE_SAVE_STATE);

                Copy (old_state, new_state, 1, struct re_save_state);

                ix -= SAVESTACK_ALLOC_FOR_RE_SAVE_STATE;

                new_state->re_state_bostr = pv_dup (old_state->re_state_bostr);
                new_state->re_state_reginput = pv_dup (old_state->re_state_reginput);
                new_state->re_state_regeol = pv_dup (old_state->re_state_regeol);
                new_state->re_state_regoffs = (regexp_paren_pair *) any_dup (old_state->re_state_regoffs, proto_perl);
                new_state->re_state_reglastparen = (U32 *) any_dup (old_state->re_state_reglastparen, proto_perl);
                new_state->re_state_reglastcloseparen = (U32 *) any_dup (old_state->re_state_reglastcloseparen, proto_perl);
                /* XXX This just has to be broken. The old save_re_context
                   code did SAVEGENERICPV(PL_reg_start_tmp);
                   PL_reg_start_tmp is char **.
                   Look above to what the dup code does for
                   SAVEt_GENERIC_PVREF
                   It can never have worked.
                   So this is merely a faithful copy of the exiting bug:  */
                new_state->re_state_reg_start_tmp = (char **) pv_dup ((char *) old_state->re_state_reg_start_tmp);
                /* I assume that it only ever "worked" because no-one called
                   (pseudo)fork while the regexp engine had re-entered itself.
                 */
#ifdef PERL_OLD_COPY_ON_WRITE
                new_state->re_state_nrs = sv_dup (old_state->re_state_nrs, param);
#endif
                new_state->re_state_reg_magic = (MAGIC *) any_dup (old_state->re_state_reg_magic, proto_perl);
                new_state->re_state_reg_oldcurpm = (PMOP *) any_dup (old_state->re_state_reg_oldcurpm, proto_perl);
                new_state->re_state_reg_curpm = (PMOP *) any_dup (old_state->re_state_reg_curpm, proto_perl);
                new_state->re_state_reg_oldsaved = pv_dup (old_state->re_state_reg_oldsaved);
                new_state->re_state_reg_poscache = pv_dup (old_state->re_state_reg_poscache);
                new_state->re_state_reg_starttry = pv_dup (old_state->re_state_reg_starttry);
                break;
              }
#endif

            case SAVEt_COMPILE_WARNINGS:
              abort ();
#if 0
              ptr = POPPTR (ss, ix);
              TOPPTR (ss, ix) = DUP_WARNINGS ((STRLEN *) ptr);
              break;
#endif

            case SAVEt_PARSER:
              abort ();
#if 0
              ptr = POPPTR (ss, ix);
              TOPPTR (ss, ix) = parser_dup ((const yy_parser *) ptr, param);
              break;
#endif
            default:
              croak ("panic: ss_dup inconsistency (%" IVdf ")", (IV) type);
          }
      }
  }

  SvREFCNT_inc (nslot->defsv);
  SvREFCNT_inc (nslot->defav);
  SvREFCNT_inc (nslot->errsv);
  SvREFCNT_inc (nslot->irsgv);

  SvREFCNT_inc (nslot->defoutgv);
  SvREFCNT_inc (nslot->rs);
  SvREFCNT_inc (nslot->compcv);
  SvREFCNT_inc (nslot->diehook);
  SvREFCNT_inc (nslot->warnhook);

  SvREFCNT_inc (ncoro->startcv);
  SvREFCNT_inc (ncoro->args);
  SvREFCNT_inc (ncoro->except);

  return ncoro;
}
