/* $Id: Slice.xs,v 1.6 2007/04/16 07:30:37 dk Exp $ */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* hacked copy of Array::Each::Override.xs by Aaron Crane */

static char private_data = '\0';

static MAGIC *
get_existing_magic( pTHX_ SV *sv)
{
	MAGIC *mg;

	for (mg = mg_find(sv, PERL_MAGIC_ext);  mg;  mg = mg->mg_moremagic)
		if (mg->mg_ptr == &private_data)
			return mg;

	return 0;
}

static MAGIC *
get_magic( pTHX_ SV *sv)
{
	MAGIC *mg;

	mg = get_existing_magic( aTHX_ sv);
	if (mg)
		return mg;

	/* didn't find any iterator magic, so create some */
	return sv_magicext(sv, sv_2mortal( newSViv( 0)), PERL_MAGIC_ext, 0, &private_data, 0);
}

static int
advance_iterator( pTHX_ SV *sv, int howmany)
{
	MAGIC *mg;
	int i;

	mg = get_magic( aTHX_ sv);
	i = SvIVX( mg-> mg_obj);
	sv_setiv( mg-> mg_obj, i + howmany);

	return i;
}

static int
set_iterator( pTHX_ SV *sv, int val)
{
	MAGIC *mg;
	int i;

	mg = get_magic( aTHX_ sv);
	i = SvIVX( mg-> mg_obj);
	sv_setiv( mg-> mg_obj, val);

	return i;
}

static void
clear_iterator( pTHX_ SV *sv)
{
	MAGIC *mg;

	if ((mg = get_existing_magic( aTHX_ sv)))
		sv_setiv(mg-> mg_obj, 0);
}

MODULE = Array::Slice      PACKAGE = Array::Slice

PROTOTYPES: ENABLE

void
array_slice(sv,howmany)
	SV *sv
	int howmany
PREINIT:
	int i, j, len;
	AV *av;
PPCODE:
	if (howmany == 0)
		XSRETURN_EMPTY;
	if (howmany < 0)
		croak("Second argument must be a positive integer");
	if (!SvROK(sv))
		croak("Argument to Array::Slice::slice must be a reference");
	sv = SvRV(sv);
	if (SvTYPE(sv) != SVt_PVAV)
		croak("Argument to Array::Slice::slice must be an array reference");
	av = (AV *) sv;
	i = advance_iterator( aTHX_ sv, howmany);
	len = av_len( av);
	if (i > len) {
		clear_iterator( aTHX_ sv);
		XSRETURN_EMPTY;
	}
	if (GIMME_V != G_VOID) {
		EXTEND(SP, howmany);
		for ( j = 0; j < howmany; j++) {
			PUSHs(( i + j <= len) ?
				*av_fetch( av, i + j, 0) : 
				&PL_sv_undef
			);
		}
		XSRETURN( howmany);
	}
	XSRETURN_EMPTY;

void
reset(sv,...)
	SV *sv
PROTOTYPE: \@;$
PPCODE:
	if (!SvROK(sv))
		croak("Argument to Array::Slice::reset must be a reference");
	sv = SvRV(sv);
	if (SvTYPE(sv) != SVt_PVAV)
		croak("Argument to Array::Slice::reset must be an array reference");
	if ( items == 1 || SvTYPE( ST(1)) == SVt_NULL) {
		clear_iterator( aTHX_ sv);
	} else {
		int i   = SvIV( ST( 1));
		AV *av  = (AV *) sv;
		int len = av_len( av);
		if ( i < 0) {
			i = len + i + 1;
			if ( i < 0) {
				warn("Array::Slice::reset past beginning of array");
				i = 0;
			}
		} else if ( i > len) {
			warn("Array::Slice::reset past end of array");
			i = len;
		}
		set_iterator( aTHX_ sv, i);
	}
	XSRETURN_EMPTY;
