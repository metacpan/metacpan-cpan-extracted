/* vi: set ft=c : */

static bool op_is_const(OP *o)
{
  switch(o->op_type) {
    case OP_CONST:
      return true;

    case OP_LIST:
    {
      OP *oelem = cLISTOPo->op_first;
      if(oelem->op_type == OP_PUSHMARK)
        oelem = OpSIBLING(oelem);
      for(; oelem; oelem = OpSIBLING(oelem))
        if(oelem->op_type != OP_CONST)
          return false;
      return true;
    }

    default:
      return false;
  }
}

static OP *ckcall_constfold(pTHX_ OP *o, GV *namegv, SV *ckobj)
{
  assert(o->op_type == OP_ENTERSUB);

  OP *kid = cUNOPo->op_first;
  /* The first kid is usually an ex-list whose ->op_first begins the actual args list */
  if(kid->op_type == OP_NULL && kid->op_targ == OP_LIST)
    kid = cUNOPx(kid)->op_first;

  /* First actual arg is likely a OP_PUSHMARK */
  if(kid->op_type == OP_PUSHMARK)
    kid = OpSIBLING(kid);
  OP *firstarg = kid;

  for(; kid && OpSIBLING(kid); kid = OpSIBLING(kid)) {
    if(op_is_const(kid))
      continue;

    return o;
  }

  CV *cv = GvCV(namegv);
  assert(SvTYPE(cv) == SVt_PVCV);

  /* We've not rejected it now, so lets invoke it and inline the result */

  /* TODO: I tried invoking the actual optree by linking it, setting it as
   * PL_op and invoking CALLRUNOPS(), but it seems the pad isn't set up
   * correctly yet to permit this for OP_PADCV ops.
   * Instead, we'll simulated it by PUSHs()ing ourselves
   */

  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);

  for(OP *oarg = firstarg; oarg && OpSIBLING(oarg); oarg = OpSIBLING(oarg)) {
    switch(oarg->op_type) {
      case OP_CONST:
        PUSHs(cSVOPx(oarg)->op_sv);
        break;

      case OP_LIST:
      {
        OP *oelem = cUNOPx(oarg)->op_first;
        if(oelem->op_type == OP_PUSHMARK)
          oelem = OpSIBLING(oelem);
        for(; oelem; oelem = OpSIBLING(oelem)) {
          assert(oelem->op_type == OP_CONST);
          PUSHs(cSVOPx(oelem)->op_sv);
        }
        break;
      }
    }
  }

  PUTBACK;

  /* TODO: Currently always presume scalar context */
  I32 count = call_sv((SV *)cv, G_SCALAR|G_EVAL);
  bool got_err = SvTRUE(GvSV(PL_errgv));

  SPAGAIN;

  SV *retval = SvREFCNT_inc(POPs);

  PUTBACK;

  FREETMPS;
  LEAVE;

  if(got_err)
    /* Error was raised; abort */
    return o;

  op_free(o);

  o = newSVOP(OP_CONST, 0, retval);
  return o;
}
