// Attempt to destroy all objects not yet freed.

void
Perl_sv_clean_objs(pTHX)
{
    GV *olddef, *olderr;
    PL_in_clean_objs = TRUE;
    visit(do_clean_objs, SVf_ROK, SVf_ROK);
    // Some barnacles may yet remain, clinging to typeglobs.
    // Run the non-IO destructors first: they may want to output
    // error messages, close files etc.
    visit(do_clean_named_objs, SVt_PVGV|SVpgv_GP, SVTYPEMASK|SVp_POK|SVpgv_GP);
    visit(do_clean_named_io_objs, SVt_PVGV|SVpgv_GP, SVTYPEMASK|SVp_POK|SVpgv_GP);
    // And if there are some very tenacious barnacles clinging to arrays,
    // closures, or what have you....
    visit(do_curse, SVs_OBJECT, SVs_OBJECT);
    olddef = PL_defoutgv;
    PL_defoutgv = NULL; // disable skip of PL_defoutgv
    if (olddef && isGV_with_GP(olddef))
	do_clean_named_io_objs(aTHX_ MUTABLE_SV(olddef));
    olderr = PL_stderrgv;
    PL_stderrgv = NULL; // disable skip of PL_stderrgv
    if (olderr && isGV_with_GP(olderr))
	do_clean_named_io_objs(aTHX_ MUTABLE_SV(olderr));
    SvREFCNT_dec(olddef);
    PL_in_clean_objs = FALSE;
}
