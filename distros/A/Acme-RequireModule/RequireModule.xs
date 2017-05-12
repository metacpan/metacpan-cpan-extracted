#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>


#define HINT_KEY "Acme::RequireModule"

U32 my_depth = 0;

SV* my_hint_key;
U32 my_hint_key_hash;

Perl_check_t my_old_ck_require;

static OP*
my_pp_require(pTHX){
	dVAR; dSP;

	if(PL_op->op_flags & OPf_SPECIAL && PL_op->op_type == OP_REQUIRE){
		SV* const sv = sv_newmortal();
		char* pv;
		const char* end;

		sv_copypv(sv, POPs);
		pv  = SvPV_nolen(sv);
		end = SvEND(sv); /* ptr to the last character */

		while(pv != end){
			if(*pv == ':' && *(pv+1) == ':'){
				*pv = '/';
				 Move(pv+2, pv+1, end - pv - 1, char);
				 end--;
			 }
			 pv++;
		}
		SvEND_set(sv, end);
		sv_catpvs(sv, ".pm");

		PUSHs(sv);
	}
	return PL_ppaddr[OP_REQUIRE](aTHX);
}

static OP*
my_ck_require(pTHX_ OP* o){
	HE* he = hv_fetch_ent(GvHV(PL_hintgv), my_hint_key, FALSE, my_hint_key_hash);

	if( he && SvTRUE(HeVAL(he)) ){
		SVOP * const kid = (SVOP*)cUNOPo->op_first;

		/* require $foo or "Foo", not require BareWord */
		if( !(kid->op_private & OPpCONST_BARE) ){
			o->op_flags |= OPf_SPECIAL;
			o->op_ppaddr = my_pp_require;
		}
	}
	return my_old_ck_require(aTHX_ o);
}


MODULE = Acme::RequireModule	PACKAGE = Acme::RequireModule

PROTOTYPES: DISABLE

BOOT:
	my_hint_key = newSVpvs(HINT_KEY);
	PERL_HASH(my_hint_key_hash, HINT_KEY, sizeof(HINT_KEY)-1);

SV*
_enter(...)
CODE:
	PERL_UNUSED_ARG(items);
	if(my_depth == 0){
		my_old_ck_require = PL_check[OP_REQUIRE];
		PL_check[OP_REQUIRE] = my_ck_require;
	}
	my_depth++;
	RETVAL = newSV(0);
	sv_setref_uv(RETVAL, HINT_KEY, my_depth);
OUTPUT:
	RETVAL

void
DESTROY(...)
CODE:
	PERL_UNUSED_ARG(items);
	if(my_depth == 0){
		Perl_croak(aTHX_ "panic: %s scope underflow", HINT_KEY);
	}
	if(my_depth == 1){
		PL_check[OP_REQUIRE]       = my_old_ck_require;
	}
	my_depth--;

