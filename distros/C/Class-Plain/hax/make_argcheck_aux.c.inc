/* vi: set ft=c : */

#ifndef make_argcheck_aux

#define make_argcheck_aux(params, opt_params, slurpy)  S_make_argcheck_aux(aTHX_ params, opt_params, slurpy)
static inline UNOP_AUX_item *S_make_argcheck_aux(pTHX_ UV params, UV opt_params, char slurpy)
{
#  if HAVE_PERL_VERSION(5, 31, 5)
  struct op_argcheck_aux *aux = (struct op_argcheck_aux*)
    PerlMemShared_malloc(sizeof(struct op_argcheck_aux));
  aux->params     = params;
  aux->opt_params = opt_params;
  aux->slurpy     = slurpy;
  return (UNOP_AUX_item *)aux;
#  else
  UNOP_AUX_item *aux = (UNOP_AUX_item *)PerlMemShared_malloc(sizeof(UNOP_AUX_item) * 3);
  aux[0].iv = params;
  aux[1].iv = opt_params;
  aux[2].iv = slurpy;
  return aux;
#  endif
}

#endif
