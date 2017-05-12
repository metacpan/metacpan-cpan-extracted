/*
----------------------------------------------------------------------------

    mro_compat.h - Provides mro functions for XS

    Automatically created by Devel::MRO/0.01, running under perl 5.10.0

    Copyright (c) 2008, Goro Fuji <gfuji(at)cpan.org>.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

----------------------------------------------------------------------------

Usage:
	#include "mro_compat.h"

Functions:
	AV*  mro_get_linear_isa(HV* stash)
	UV   mro_get_pkg_gen(HV* stash)
	void mro_method_changed_in(HV* stash)


    See "perldoc mro" for details.


 */


#ifndef mro_get_linear_isa
#define mro_get_linear_isa(stash) my_mro_get_linear_isa(aTHX_ stash)

#define mro_method_changed_in(stash) ((void)stash, (void)PL_sub_generation++)
#define mro_get_pkg_gen(stash) ((void)stash, PL_sub_generation)

#if defined(NEED_mro_get_linear_isa) && !defined(NEED_mro_get_linear_isa_GLOBAL)
static AV* my_mro_get_linear_isa(pTHX_ HV* const stash);
static
#else
extern AV* my_mro_get_linear_isa(pTHX_ HV* const stash);
#endif /* !NEED_mro_get_linear_isa */

#if defined(NEED_mro_get_linear_isa) || defined(NEED_mro_get_linear_isa_GLOBAL)
#define ISA_CACHE "::LINEALIZED_ISA_CACHE::"

AV*
my_mro_get_linear_isa(pTHX_ HV* const stash){
	GV* const cachegv = *(GV**)hv_fetchs(stash, ISA_CACHE, TRUE);
	AV* isa;
	SV* gen;
	CV* get_linear_isa;

	if(!isGV(cachegv))
		gv_init(cachegv, stash, ISA_CACHE, sizeof(ISA_CACHE)-1, TRUE);

	isa = GvAVn(cachegv);
#ifdef GvSVn
	gen = GvSVn(cachegv);
#else
	gen = GvSV(cachegv);
#endif

	if(SvIOK(gen) && SvIVX(gen) == (IV)mro_get_pkg_gen(stash)){
		return isa; /* returns the cache if available */
	}
	else{
		SvREADONLY_off(isa);
		av_clear(isa);
	}

	get_linear_isa = get_cv("mro::get_linear_isa", FALSE);
	if(!get_linear_isa){
		ENTER;
		SAVETMPS;

		Perl_load_module(aTHX_ PERL_LOADMOD_NOIMPORT, newSVpvs("MRO::Compat"), NULL, NULL);
		get_linear_isa = get_cv("mro::get_linear_isa", TRUE);

		FREETMPS;
		LEAVE;
	}

	{
		SV* avref;
		dSP;

		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		mXPUSHp(HvNAME(stash), strlen(HvNAME(stash)));
		PUTBACK;

		call_sv((SV*)get_linear_isa, G_SCALAR);

		SPAGAIN;
		avref = POPs;
		PUTBACK;

		if(SvROK(avref) && SvTYPE(SvRV(avref)) == SVt_PVAV){
			AV* const av  = (AV*)SvRV(avref);
			I32 const len = AvFILLp(av) + 1;
			I32 i;

			for(i = 0; i < len; i++){
				HV* const stash = gv_stashsv(AvARRAY(av)[i], FALSE);
				if(stash)
					av_push(isa, newSVpv(HvNAME(stash), 0));
			}
			SvREADONLY_on(isa);
		}
		else{
			Perl_croak(aTHX_ "mro::get_linear_isa() didn't return an ARRAY reference");
		}

		FREETMPS;
		LEAVE;
	}

	sv_setiv(gen, (IV)mro_get_pkg_gen(stash));
	return GvAV(cachegv);
}
#undef ISA_CACHE

#endif /* !(defined(NEED_mro_get_linear_isa) || defined(NEED_mro_get_linear_isa_GLOBAL)) */

#else /* !mro_get_linear_isa */

/* NOTE:
	Because ActivePerl 5.10.0 does not provide Perl_mro_meta_init(), 
	which is used in HvMROMETA() macro, this mro_get_pkg_gen() refers
	to xhv_mro_meta directly.
*/
#ifndef mro_get_pkg_gen
#define mro_get_pkg_gen(stash) (HvAUX(stash)->xhv_mro_meta ? HvAUX(stash)->xhv_mro_meta->pkg_gen : (U32)0)
#endif

#endif /* mro_get_linear_isa */
