// vim: set noexpandtab:
/* Data-Util/DataUtil.xs */

#define NEED_mro_get_linear_isa
#include "data-util.h"

#define MY_CXT_KEY "Data::Util::_guts" XS_VERSION

#define NotReached assert(((void)"PANIC: NOT REACHED", 0))

#define is_special_nv(nv) (nv == NV_INF || nv == -NV_INF || Perl_isnan(nv))

typedef struct{
	GV* universal_isa;

	GV* croak;
} my_cxt_t;
START_MY_CXT;

/* null magic virtual table to identify magic functions */
extern MGVTBL curried_vtbl;
extern MGVTBL modified_vtbl;

MGVTBL subr_name_vtbl;

typedef enum{
	T_NOT_REF,
	T_SV,
	T_AV,
	T_HV,
	T_CV,
	T_GV,
	T_IO,
	T_FM,
	T_RX,
	T_OBJECT,

	T_VALUE,
	T_STR,
	T_NUM,
	T_INT
} my_type_t;

static const char* const ref_names[] = {
	NULL, /* NOT_REF */
	"a SCALAR reference",
	"an ARRAY reference",
	"a HASH reference",
	"a CODE reference",
	"a GLOB reference",
	NULL, /* IO */
	NULL, /* FM */
	"a regular expression reference", /* RX */
	NULL  /* OBJECT */
};

static void
my_croak(pTHX_ const char* const fmt, ...)
	__attribute__format__(__printf__, pTHX_1, pTHX_2);

static void
my_croak(pTHX_ const char* const fmt, ...){
	dMY_CXT;
	dSP;
	SV* message;
	va_list args;

	ENTER;
	SAVETMPS;

	if(!MY_CXT.croak){
		Perl_load_module(aTHX_ PERL_LOADMOD_NOIMPORT, newSVpvs("Data::Util::Error"), NULL, NULL);
		MY_CXT.croak = CvGV(get_cv("Data::Util::Error::croak", GV_ADD));
		SvREFCNT_inc_simple_void_NN(MY_CXT.croak);
	}

	va_start(args, fmt);
	message = vnewSVpvf(fmt, &args);
	va_end(args);

	PUSHMARK(SP);
	mXPUSHs(message);
	PUTBACK;

	call_sv((SV*)MY_CXT.croak, G_VOID);

	NotReached;
	/*
	FREETMPS;
	LEAVE;
	*/
}

static void
my_fail(pTHX_ const char* const name, SV* value){
	my_croak(aTHX_ "Validation failed: you must supply %s, not %s", name, neat(value));
}

static int
S_nv_is_integer(pTHX_ NV const nv) {
    if(nv == (NV)(IV)nv){
        return TRUE;
    }
    else {
        char buf[64];  /* Must fit sprintf/Gconvert of longest NV */
        char* p;
        (void)Gconvert(nv, NV_DIG, 0, buf);
        p = &buf[0];

        /* -?[0-9]+ */
        if(*p == '-') p++;

        while(*p){
            if(!isDIGIT(*p)){
                return FALSE;
            }
            p++;
        }
        return TRUE;
    }
}

static int
my_check_type_primitive(pTHX_ SV* const sv, const my_type_t t){
	if(!SvOK(sv) || SvROK(sv) || isGV(sv)){
		return FALSE;
	}

	switch(t){
	case T_INT:
		/* check POK, NOK and IOK respectively */
		if(SvPOKp(sv)){
			int const num_type = grok_number(SvPVX(sv), SvCUR(sv), NULL);

			if(num_type && !strEQ(SvPVX(sv), "0 but true")){
				return !(num_type & IS_NUMBER_NOT_INT);
			}
		}
		else if(SvNOKp(sv)){
			NV const nv = SvNVX(sv);
			return S_nv_is_integer(aTHX_ nv);
		}
		else if(SvIOKp(sv)){
			return TRUE;
		}
		break;

	case T_NUM:
		if(SvPOKp(sv)){
			int const num_type = grok_number(SvPVX(sv), SvCUR(sv), NULL);

			if(num_type && !strEQ(SvPVX(sv), "0 but true")){
				return !(num_type & (IS_NUMBER_INFINITY | IS_NUMBER_NAN));
			}
		}
		else if(SvNOKp(sv)){
			NV const nv = SvNVX(sv);
			return !is_special_nv(nv);
		}
		else if(SvIOKp(sv)){
			return TRUE;
		}
		break;

	case T_STR:
		if(SvPOKp(sv)){
			return SvCUR(sv) > 0;
		}
		/* fall throught */

	default:/* T_VALUE */
		return TRUE;
	}

	return FALSE;
}

static bool
my_has_amagic_converter(pTHX_ SV* const sv, const my_type_t t){
	const AMT* amt;
	const HV *stash;
	int o = 0;

	if (
		   (!SvAMAGIC(sv))
		|| (!(stash = SvSTASH(SvRV(sv))))
		|| (!Gv_AMG((HV*)stash))
	) {
		return FALSE;
	}
	amt = (AMT*)mg_find((SV*)stash, PERL_MAGIC_overload_table)->mg_ptr;
	assert(amt);
	assert(AMT_AMAGIC(amt));


	switch(t){
	case T_SV:
		o = to_sv_amg;
		break;
	case T_AV:
		o = to_av_amg;
		break;
	case T_HV:
		o = to_hv_amg;
		break;
	case T_CV:
		o = to_cv_amg;
		break;
	case T_GV:
		o = to_gv_amg;
		break;
	default:
		NotReached;
	}

	return amt->table[o] ? TRUE : FALSE;
}

#define check_type(sv, t) my_check_type(aTHX_ sv, t)
static int
my_check_type(pTHX_ SV* const sv, const my_type_t t){
	if(!SvROK(sv)){
		return FALSE;
	}

	if(SvOBJECT(SvRV(sv))){
		if(t == T_RX){ /* regex? */
			return SvRXOK(sv);
		}
		else{
			SvGETMAGIC(sv);
			return my_has_amagic_converter(aTHX_ sv, t);
		}
	}


	switch(SvTYPE(SvRV(sv))){
	case SVt_PVAV: return T_AV == t;
	case SVt_PVHV: return T_HV == t;
	case SVt_PVCV: return T_CV == t;
	case SVt_PVGV: return T_GV == t;
	case SVt_PVIO: return T_IO == t;
	case SVt_PVFM: return T_FM == t;
	default:       NOOP;
	}

	return T_SV == t;
}

#define deref_av(sv) my_deref_av(aTHX_ sv)
#define deref_hv(sv) my_deref_hv(aTHX_ sv)
#define deref_cv(sv) my_deref_cv(aTHX_ sv)

static AV*
my_deref_av(pTHX_ SV* sv){
	SvGETMAGIC(sv);
	if(my_has_amagic_converter(aTHX_ sv, T_AV)){
		SV* const* sp = &sv; /* used in tryAMAGICunDEREF macro */
		tryAMAGICunDEREF(to_av);
	}

	if(!(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV)){
		my_fail(aTHX_ ref_names[T_AV], sv);
	}
	return (AV*)SvRV(sv);
}
static HV*
my_deref_hv(pTHX_ SV* sv){
	SvGETMAGIC(sv);
	if(my_has_amagic_converter(aTHX_ sv, T_HV)){
		SV* const* sp = &sv; /* used in tryAMAGICunDEREF macro */
		tryAMAGICunDEREF(to_hv);
	}

	if(!(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)){
		my_fail(aTHX_ ref_names[T_HV], sv);
	}
	return (HV*)SvRV(sv);
}
static CV*
my_deref_cv(pTHX_ SV* sv){
	SvGETMAGIC(sv);
	if(my_has_amagic_converter(aTHX_ sv, T_CV)){
		SV* const* sp = &sv; /* used in tryAMAGICunDEREF macro */
		tryAMAGICunDEREF(to_cv);
	}

	if(!(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)){
		my_fail(aTHX_ ref_names[T_CV], sv);
	}
	return (CV*)SvRV(sv);
}

#define validate(sv, t) my_validate(aTHX_ sv, t)
static SV*
my_validate(pTHX_ SV* const sv, my_type_t const ref_type){
	SvGETMAGIC(sv);
	if(!check_type(sv, ref_type)){
		my_fail(aTHX_ ref_names[ref_type], sv);
	}
	return sv;
}

static SV*
my_string(pTHX_ SV* const sv, const char* const name){
	SvGETMAGIC(sv);
	if(!is_string(sv)) my_fail(aTHX_ name, sv);
	return sv;
}

static const char*
my_canon_pkg(pTHX_ const char* name){
	/* "::Foo" -> "Foo" */
	if(name[0] == ':' && name[1] == ':'){
		name += 2;
	}

	/* "main::main::main::Foo" -> "Foo" */
	while(strnEQ(name, "main::", sizeof("main::")-1)){

		name += sizeof("main::")-1;
	}

	return name;
}


static int
my_isa_lookup(pTHX_ HV* const stash, const char* klass_name){
	const char* const stash_name = my_canon_pkg(aTHX_ HvNAME_get(stash));

	klass_name = my_canon_pkg(aTHX_ klass_name);

	if(strEQ(stash_name, klass_name)){
		return TRUE;
	}
	else if(strEQ(klass_name, "UNIVERSAL")){
		return TRUE;
	}
	else{
		AV*  const linearized_isa = mro_get_linear_isa(stash);
		SV**       svp            = AvARRAY(linearized_isa) + 1;   /* skip this class */
		SV** const end            = svp + AvFILLp(linearized_isa); /* start + 1 + last index */

		while(svp != end){
			if(strEQ(klass_name, my_canon_pkg(aTHX_ SvPVX(*svp)))){
				return TRUE;
			}
			svp++;
		}
	}
	return FALSE;
}

static int
my_instance_of(pTHX_ SV* const x, SV* const klass){
	if( !is_string(klass) ){
		my_fail(aTHX_ "a class name", klass);
	}

	if( SvROK(x) && SvOBJECT(SvRV(x)) ){
		dMY_CXT;
		HV* const stash = SvSTASH(SvRV(x));
		GV* const isa   = gv_fetchmeth_autoload(stash, "isa", sizeof("isa")-1, 0 /* special zero, not flags nor bool */);

		/* common cases */
		if(isa == NULL || GvCV(isa) == GvCV(MY_CXT.universal_isa)){
			return my_isa_lookup(aTHX_ stash, SvPV_nolen_const(klass));
		}

		/* special cases */
		/* call their own ->isa() method */
		{
			int retval;
			dSP;

			ENTER;
			SAVETMPS;

			PUSHMARK(SP);
			EXTEND(SP, 2);
			PUSHs(x);
			PUSHs(klass);
			PUTBACK;

			call_sv((SV*)isa, G_SCALAR | G_METHOD);

			SPAGAIN;

			retval = SvTRUE(TOPs);
			(void)POPs;

			PUTBACK;

			FREETMPS;
			LEAVE;

			return retval;
		}
	}

	return FALSE;
}

#define type_isa(sv, type) my_type_isa(aTHX_ sv, type)
static bool
my_type_isa(pTHX_ SV* const sv, SV* const type){
	const char* const typestr = SvPV_nolen_const(type);
	switch(typestr[0]){
	case 'S':
		if(strEQ(typestr, "SCALAR")){
			return check_type(sv, T_SV);
		}
		break;
	case 'A':
		if(strEQ(typestr, "ARRAY")){
			return check_type(sv, T_AV);
		}
		break;
	case 'H':
		if(strEQ(typestr, "HASH")){
			return check_type(sv, T_HV);
		}
		break;
	case 'C':
		if(strEQ(typestr, "CODE")){
			return check_type(sv, T_CV);
		}
		break;
	case 'G':
		if(strEQ(typestr, "GLOB")){
			return check_type(sv, T_GV);
		}
		break;
	}
	return my_instance_of(aTHX_ sv, type);
}

static void
my_opt_add(pTHX_
	AV* const result_av, HV* const result_hv, SV* const moniker,
	SV* const name, SV* const value,
	bool const with_validation,
	SV* vsv,
	AV* vav,
	HV* const vhv ){

	if(with_validation && SvOK(value)){
		if(vhv){
			HE* const he = hv_fetch_ent(vhv, name, FALSE, 0U);
			vav = NULL;
			if(he){
				SV* const sv = hv_iterval(vhv, he);
				if(check_type(sv, T_AV)){
					vav = deref_av(sv);
				}
				else if(SvOK(sv)){
					vsv = sv;
				}
				else{
					goto store_pair;
				}
			}
			else{
				goto store_pair;
			}
		}

		if(vav){
			I32 const len = av_len(vav)+1;
			I32 i;
			for(i = 0; i < len; i++){
				if(type_isa(value, *av_fetch(vav, i, TRUE))){
					break;
				}
			}
			if(i == len) goto validation_failed;
		}
		else{
			if(!type_isa(value, vsv)){
				validation_failed:
				my_croak(aTHX_ "%s-ref values are not valid for %"SVf" in %"SVf" opt list",
					sv_reftype(SvRV(value), TRUE), name, moniker);
			}
		}
	}

	store_pair:
	if(result_av){ /* push @result, [$name => $value] */
		SV* pair[2];

		pair[0] = name;
		pair[1] = value;

		av_push(result_av, newRV_noinc((SV*) av_make(2, pair)));
	}
	else{ /* $result{$name} = $value */
		(void)hv_store_ent(result_hv, name, newSVsv(value), 0U);
	}
}

static SV*
my_mkopt(pTHX_ SV* const opt_list, SV* const moniker, const bool require_unique, SV* must_be, const my_type_t result_type){
	SV* ret;
	AV* result_av = NULL;
	HV* result_hv = NULL;

	HV* vhv  = NULL; /* validator HV */
	AV* vav  = NULL; /* validator AV */
	bool const with_validation = SvOK(must_be) ? TRUE : FALSE;


	if(with_validation){
		if(check_type(must_be, T_HV)){
			vhv = deref_hv(must_be);
		}
		else if(check_type(must_be, T_AV)){
			vav = deref_av(must_be);
		}
		else if(!is_string(must_be)){
			my_fail(aTHX_ "type constraints", must_be);
		}
	}

	if(result_type == T_AV){
		result_av = newAV();
		ret = (SV*)result_av;
	}
	else{
		result_hv = newHV();
		ret = (SV*)result_hv;
	}
	sv_2mortal(ret);

	if(check_type(opt_list, T_AV)){
		HV* seen = NULL;
		AV* const opt_av = deref_av(opt_list);
		I32 const len    = av_len(opt_av) + 1;
		I32 i;

		if(require_unique){
			seen = newHV();
			sv_2mortal((SV*)seen);
		}

		for(i = 0; i < len; i++){
			SV* const name = my_string(aTHX_ *av_fetch(opt_av, i, TRUE), "an option name");
			SV* value;

			if(require_unique){
				HE* const he    = hv_fetch_ent(seen, name, TRUE, 0U);
				SV* const count = hv_iterval(seen, he);
				if(SvTRUE(count)){
					my_croak(aTHX_ "Multiple definitions provided for %"SVf" in %"SVf" opt list", name, moniker);
				}
				sv_inc(count); /* count++ */
			}

			if( (i+1) == len ){ /* last */
				value = &PL_sv_undef;
			}
			else{
				value = *av_fetch(opt_av, i+1, TRUE);
				if(SvROK(value) || !SvOK(value)){
					i++;
				}
				else{
					value = &PL_sv_undef;
				}
			}

			my_opt_add(aTHX_ result_av, result_hv, moniker, name, value,
				with_validation, must_be, vav, vhv);
		}
	}
	else if(check_type(opt_list, T_HV)){
		HV* const opt_hv = deref_hv(opt_list);
		I32 keylen;
		char* key;
		SV* value;
		SV* const name = sv_newmortal();

		hv_iterinit(opt_hv);

		while((value = hv_iternextsv(opt_hv, &key, &keylen))){
			sv_setpvn(name, key, keylen); /* copied in my_opt_add */

			if(!SvROK(value) && SvOK(value)){
				value = &PL_sv_undef;
			}
			my_opt_add(aTHX_ result_av, result_hv, moniker, name, value,
				with_validation, must_be, vav, vhv);
		}
	}
	else if(SvOK(opt_list)){
		my_fail(aTHX_ "an ARRAY or HASH reference", opt_list);
	}

	return newRV_inc(ret);
}

/*
	$code = curry($_, (my $tmp = $code_ref), *_) for @around;
*/
static SV*
my_build_around_code(pTHX_ SV* code_ref, AV* const around){
	I32 i;
	for(i = av_len(around); i >= 0; i--){
		CV* current;
		MAGIC* mg;
		SV* const sv = validate(*av_fetch(around, i, TRUE), T_CV);
		AV* const params       = newAV();
		AV* const placeholders = newAV();

		av_store(params, 0, newSVsv(sv));       /* base proc */
		av_store(params, 1, newSVsv(code_ref)); /* first argument (next proc) */
		av_store(params, 2, &PL_sv_undef);      /* placeholder hole */

		av_store(placeholders, 2, (SV*)PL_defgv); // *_
		SvREFCNT_inc_simple_void_NN(PL_defgv);

		current = newXS(NULL /* anonymous */, XS_Data__Util_curried, __FILE__);
		mg = sv_magicext((SV*)current, (SV*)params, PERL_MAGIC_ext, &curried_vtbl, (const char*)placeholders, HEf_SVKEY);

		SvREFCNT_dec(params);       /* because: refcnt++ in sv_magicext() */
		SvREFCNT_dec(placeholders); /* because: refcnt++ in sv_magicext() */

		CvXSUBANY(current).any_ptr = (void*)mg;

		code_ref = newRV_noinc((SV*)current);
		sv_2mortal(code_ref);
	}
	return newSVsv(code_ref);
}

static void
my_gv_setsv(pTHX_ GV* const gv, SV* const sv){
	ENTER;
	SAVETMPS;

	sv_setsv_mg((SV*)gv, sv_2mortal(newRV_inc((sv))));

	FREETMPS;
	LEAVE;
}

static void
my_install_sub(pTHX_ HV* const stash, const char* const name, STRLEN const namelen, SV* code_ref){
	CV* const code         = deref_cv(code_ref);
	GV* const gv           = (GV*)*hv_fetch(stash, name, namelen, TRUE);

	if(!isGV(gv)) gv_init(gv, stash, name, namelen, GV_ADDMULTI);

	my_gv_setsv(aTHX_ gv, (SV*)code); /* *foo = \&bar */

	if(CvANON(code)
		&& CvGV(code)                            /* under construction? */
		&& isGV(CvGV(code))                      /* released? */){

		/* rename cv with gv */
		CvGV_set(code, gv);
		CvANON_off(code);
	}
}

static void
my_uninstall_sub(pTHX_ HV* const stash, const char* const name, STRLEN const namelen, SV* const specified_code_ref){
	GV** const gvp = (GV**)hv_fetch(stash, name, namelen, FALSE);

	if(gvp){
		GV* const gv = *gvp;
		CV* const specified_code = SvOK(specified_code_ref) ? deref_cv(specified_code_ref) : NULL;
		GV* newgv;
		CV* code;

		if(!isGV(gv)){ /* a subroutine stub or special constant*/
			       /* or perhaps a sub ref */
			if(SvROK((SV*)gv)) {
			    if(SvTYPE(SvRV(gv)) == SVt_PVCV) {
				if( specified_code &&
				    specified_code != (CV*)SvRV(gv) )
					return;
			    }
			    else if(ckWARN(WARN_MISC))
				Perl_warner(aTHX_ packWARN(WARN_MISC), "Constant subroutine %s uninstalled", name);
			}
			(void)hv_delete(stash, name, namelen, G_DISCARD);
			return;
		}

		if(!(code = GvCVu(gv))){
			return;
		}

		/* when an uninstalled subroutine is supplied ... */
		if( specified_code && specified_code != code ){
			return; /* skip */
		}

		if(CvCONST(code) && ckWARN(WARN_MISC)){
			Perl_warner(aTHX_ packWARN(WARN_MISC), "Constant subroutine %s uninstalled", name);
		}

		(void)hv_delete(stash, name, namelen, G_DISCARD);

		if(SvREFCNT(gv) == 0 || !(
			   GvSV(gv)
			|| GvAV(gv)
			|| GvHV(gv)
			|| GvIO(gv)
			|| GvFORM(gv))){

			return; /* no need to retrieve gv */
		}

		newgv = (GV*)*hv_fetch(stash, name, namelen, TRUE);
		gv_init(newgv, stash, name, namelen, GV_ADDMULTI); /* vivify */

		/* restore all slots other than GvCV */

		if(GvSV(gv))   my_gv_setsv(aTHX_ newgv,      GvSV(gv));
		if(GvAV(gv))   my_gv_setsv(aTHX_ newgv, (SV*)GvAV(gv));
		if(GvHV(gv))   my_gv_setsv(aTHX_ newgv, (SV*)GvHV(gv));
		if(GvIO(gv))   my_gv_setsv(aTHX_ newgv, (SV*)GvIOp(gv));
		if(GvFORM(gv)) my_gv_setsv(aTHX_ newgv, (SV*)GvFORM(gv));
	}
}

static void
initialize_my_cxt(pTHX_ my_cxt_t* const cxt){
	cxt->universal_isa = CvGV(get_cv("UNIVERSAL::isa", GV_ADD));
	SvREFCNT_inc_simple_void_NN(cxt->universal_isa);

	cxt->croak = NULL;
}

#define UNDEF &PL_sv_undef


MODULE = Data::Util		PACKAGE = Data::Util

PROTOTYPES: DISABLE

BOOT:
{
	MY_CXT_INIT;
	initialize_my_cxt(aTHX_ &MY_CXT);
}

void
CLONE(...)
CODE:
	MY_CXT_CLONE;
	initialize_my_cxt(aTHX_ &MY_CXT);
	PERL_UNUSED_VAR(items);

#define T_RX_deprecated T_RX

void
is_scalar_ref(x)
	SV* x
ALIAS:
	is_scalar_ref = T_SV
	is_array_ref  = T_AV
	is_hash_ref   = T_HV
	is_code_ref   = T_CV
	is_glob_ref   = T_GV
	is_regex_ref  = T_RX_deprecated
	is_rx         = T_RX
CODE:
	SvGETMAGIC(x);
	ST(0) = boolSV(check_type(x, (my_type_t)ix));
	XSRETURN(1);

void
scalar_ref(x)
	SV* x
ALIAS:
	scalar_ref = T_SV
	array_ref  = T_AV
	hash_ref   = T_HV
	code_ref   = T_CV
	glob_ref   = T_GV
	regex_ref  = T_RX_deprecated
	rx         = T_RX
CODE:
	SvGETMAGIC(x);
	if(check_type(x, (my_type_t)ix)){
		XSRETURN(1); /* return the first value */
	}
	my_fail(aTHX_ ref_names[ix], x);

void
is_instance(x, klass)
	SV* x
	SV* klass
CODE:
	SvGETMAGIC(x);
	SvGETMAGIC(klass);
	ST(0) = boolSV(my_instance_of(aTHX_ x, klass));
	XSRETURN(1);

void
instance(x, klass)
	SV* x
	SV* klass
CODE:
	SvGETMAGIC(x);
	SvGETMAGIC(klass);
	if( my_instance_of(aTHX_ x, klass) ){
		XSRETURN(1); /* return $_[0] */
	}
	my_croak(aTHX_ "Validation failed: you must supply an instance of %"SVf", not %s",
		klass, neat(x));

void
invocant(x)
	SV* x
ALIAS:
	is_invocant = 0
	invocant    = 1
PREINIT:
	bool result;
CODE:
	SvGETMAGIC(x);
	if(SvROK(x)){
		result = SvOBJECT(SvRV(x)) ? TRUE : FALSE;
	}
	else if(is_string(x)){
		result = gv_stashsv(x, FALSE) ? TRUE : FALSE;
	}
	else{
		result = FALSE;
	}
	if(ix == 0){ /* is_invocant() */
		ST(0) = boolSV(result);
		XSRETURN(1);
	}
	else{ /* invocant() */
		if(result){ /* XXX: do{ package ::Foo; ::Foo->something; } causes an fatal error */
			if(!SvROK(x)){
				dXSTARG;
				sv_setsv(TARG, x); /* copy the pv and flags */
				sv_setpv(TARG, my_canon_pkg(aTHX_ SvPV_nolen_const(x)));
				ST(0) = TARG;
			}
			XSRETURN(1);
		}
		my_fail(aTHX_ "an invocant", x);
	}

void
is_value(x)
	SV* x
ALIAS:
	is_value   = T_VALUE
	is_string  = T_STR
	is_number  = T_NUM
	is_integer = T_INT
CODE:
	SvGETMAGIC(x);
	ST(0) = boolSV(my_check_type_primitive(aTHX_ x, (my_type_t)ix));
	XSRETURN(1);

HV*
get_stash(invocant)
	SV* invocant
CODE:
	SvGETMAGIC(invocant);
	if(SvROK(invocant) && SvOBJECT(SvRV(invocant))){
		RETVAL = SvSTASH(SvRV(invocant));
	}
	else if(is_string(invocant)){
		RETVAL = gv_stashsv(invocant, FALSE);
	}
	else{
		RETVAL = NULL;
	}
	if(!RETVAL){
		XSRETURN_UNDEF;
	}
OUTPUT:
	RETVAL


SV*
anon_scalar(referent = undef)
CODE:
	RETVAL = newRV_noinc(items == 0 ? newSV(0) : newSVsv(ST(0)));
OUTPUT:
	RETVAL

const char*
neat(expr)
	SV* expr

void
install_subroutine(into, ...)
	SV* into
PREINIT:
	HV* stash;
	int i;
CODE:
	stash = gv_stashsv(my_string(aTHX_ into, "a package name"), TRUE);

	if(items == 2){
		HV* const hv = deref_hv(ST(1));
		I32   namelen;
		char* name;
		SV* code_ref;

		hv_iterinit(hv);
		while((code_ref = hv_iternextsv(hv, &name, &namelen))){
			my_install_sub(aTHX_ stash, name, namelen, code_ref);
		}
	}
	else{
		if( ((items-1) % 2) != 0 ){
			my_croak(aTHX_ "Odd number of arguments for %s", GvNAME(CvGV(cv)));
		}

		for(i = 1; i < items; i += 2){
			SV* const as           = my_string(aTHX_ ST(i), "a subroutine name");
			STRLEN namelen;
			const char* const name = SvPV_const(as, namelen);
			SV* const code_ref     = ST(i+1);

			my_install_sub(aTHX_ stash, name, namelen, code_ref);
		}
	}

void
uninstall_subroutine(package, ...)
	SV* package
PREINIT:
	HV* stash;
	int i;
CODE:
	stash = gv_stashsv(my_string(aTHX_ package, "a package name"), FALSE);
	if(!stash) XSRETURN_EMPTY;

	if(items == 2 && SvROK(ST(1))){
		HV* const hv = deref_hv(ST(1));
		I32   namelen;
		char* name;
		SV* specified_code_ref;

		hv_iterinit(hv);
		while((specified_code_ref = hv_iternextsv(hv, &name, &namelen))){
			my_uninstall_sub(aTHX_ stash, name, namelen, specified_code_ref);
		}
	}
	else{
		for(i = 1; i < items; i++){
			SV* const namesv = my_string(aTHX_ ST(i), "a subroutine name");
			STRLEN namelen;
			const char* const name = SvPV_const(namesv, namelen);
			SV* specified_code_ref;

			if( (i+1) < items && SvROK(ST(i+1)) ){
				i++;
				specified_code_ref = ST(i);
			}
			else{
				specified_code_ref = &PL_sv_undef;
			}

			my_uninstall_sub(aTHX_ stash, name, namelen, specified_code_ref);
		}
	}
	mro_method_changed_in(stash);

void
get_code_info(code)
	CV* code
PREINIT:
	GV* gv;
	HV* stash;
PPCODE:
	if( (gv = CvGV(code)) && isGV_with_GP(gv)
		&& (stash = (GvSTASH(gv))) && HvNAME_get(stash) ){

		if(GIMME_V == G_ARRAY){
			EXTEND(SP, 2);
			mPUSHs(newSVpvn_share(HvNAME_get(stash), HvNAMELEN_get(stash), 0U));
			mPUSHs(newSVpvn_share(GvNAME(gv), GvNAMELEN(gv), 0U));
		}
		else{
			SV* const sv = newSVpvf("%s::%s", HvNAME_get(stash), GvNAME(gv));
			mXPUSHs(sv);
		}
	}


SV*
get_code_ref(package, name, ...)
	SV* package
	SV* name
INIT:
	I32 flags = 0;
	RETVAL = &PL_sv_undef;
CODE:
	(void)my_string(aTHX_ package, "a package name");
	(void)my_string(aTHX_ name,    "a subroutine name");

	if(items > 2){ /* with flags */
		I32 i;
		for(i = 2; i < items; i++){
			SV* const sv = my_string(aTHX_ ST(i), "a flag");
			if(strEQ(SvPV_nolen_const(sv), "-create")){
				flags |= GV_ADD;
			}
			else{
				my_fail(aTHX_ "a flag", sv);
			}
		}
	}

	{
		HV* const stash = gv_stashsv(package, flags);

		if(stash){
			STRLEN len;
			const char* const pv = SvPV_const(name, len);
			GV** const gvp = (GV**)hv_fetch(stash, pv, len, flags);
			GV*  const gv  = gvp ? *gvp : NULL;

			if(gv){
				if(!isGV(gv)) gv_init(gv, stash, pv, len, GV_ADDMULTI);

				if(GvCVu(gv)){
					RETVAL = newRV_inc((SV*)GvCV(gv));
				}
				else if(flags & GV_ADD){
					SV* const sv = Perl_newSVpvf(aTHX_ "%"SVf"::%"SVf, package, name);

					/* from Perl_get_cvn_flags() in perl.c */
					CV* const cv = newSUB(
						start_subparse(FALSE, 0),
						newSVOP(OP_CONST, 0, sv),
						NULL, NULL);
					RETVAL = newRV_inc((SV*)cv);
				}
			}
		}
	}
OUTPUT:
	RETVAL

SV*
curry(code, ...)
	SV* code
PREINIT:
	CV* curried;
	AV* params;
	AV* placeholders;
	U16 is_method;
	I32 i;
	MAGIC* mg;
CODE:
	SvGETMAGIC(code);
	is_method = check_type(code, T_CV) ? 0 : G_METHOD;

	params       = newAV();
	placeholders = newAV();

	av_extend(params,       items-1);
	av_extend(placeholders, items-1);

	for(i = 0; i < items; i++){
		SV* const sv = ST(i);
		SvGETMAGIC(sv);

		if(SvROK(sv) && SvIOKp(SvRV(sv)) && !SvOBJECT(SvRV(sv))){ // \0, \1, ...
			av_store(params, i, &PL_sv_undef);
			av_store(placeholders, i, newSVsv(SvRV(sv)));
		}
		else if(sv == (SV*)PL_defgv){ // *_ (always *main::_)
			av_store(params, i, &PL_sv_undef);
			av_store(placeholders, i, sv); /* not copy */
			SvREFCNT_inc_simple_void_NN(sv);
		}
		else{
			av_store(params, i, sv); /* not copy */
			av_store(placeholders, i, &PL_sv_undef);
			SvREFCNT_inc_simple_void_NN(sv);
		}
	}
	curried = newXS(NULL /* anonymous */, XS_Data__Util_curried, __FILE__);

	mg = sv_magicext((SV*)curried, (SV*)params, PERL_MAGIC_ext, &curried_vtbl, (const char*)placeholders, HEf_SVKEY);
	SvREFCNT_dec((SV*)params);       /* refcnt++ in sv_magicext() */
	SvREFCNT_dec((SV*)placeholders); /* refcnt++ in sv_magicext() */
	mg->mg_private = is_method;
	CvXSUBANY(curried).any_ptr = mg;

	RETVAL = newRV_noinc((SV*)curried);
OUTPUT:
	RETVAL

SV*
modify_subroutine(code, ...)
	SV* code
PREINIT:
	CV* modified;
	AV* before;
	AV* around;
	AV* after;
	AV* modifiers; /* (before, around, after, original, current) */
	I32 i;
	MAGIC* mg;
CODE:
	validate(code, T_CV);

	if( ((items - 1) % 2) != 0 ){
		my_croak(aTHX_ "Odd number of arguments for %s", GvNAME(CvGV(cv)));
	}

	before = newAV(); sv_2mortal((SV*)before);
	around = newAV(); sv_2mortal((SV*)around);
	after  = newAV(); sv_2mortal((SV*)after );

	for(i = 1; i < items; i += 2){ /* modifier_type => [subroutine(s)] */
		SV*         const          mtsv = my_string(aTHX_ ST(i), "a modifier type");
		const char* const modifier_type = SvPV_nolen_const(mtsv);
		AV*         const          subs = deref_av(ST(i+1));
		I32         const      subs_len = av_len(subs) + 1;
		AV* av = NULL;
		I32 j;

		if(strEQ(modifier_type, "before")){
			av = before;
		}
		else if(strEQ(modifier_type, "around")){
			av = around;
		}
		else if(strEQ(modifier_type, "after")){
			av = after;
		}
		else{
			my_fail(aTHX_ "a modifier type", mtsv);
		}

		av_extend(av, AvFILLp(av) + subs_len - 1);
		for(j = 0; j < subs_len; j++){
			SV* const code_ref = newSVsv(validate(*av_fetch(subs, j, TRUE), T_CV));

			av_push(av, code_ref);
		}
	}

	modifiers = newAV();
	av_extend(modifiers, 3);

	av_store(modifiers, M_CURRENT,  my_build_around_code(aTHX_ code, around));

	av_store(modifiers, M_BEFORE, SvREFCNT_inc_simple_NN(before));
	av_store(modifiers, M_AROUND, SvREFCNT_inc_simple_NN(around));
	av_store(modifiers, M_AFTER,  SvREFCNT_inc_simple_NN(after));

	modified = newXS(NULL /* anonymous */, XS_Data__Util_modified, __FILE__);

	mg = sv_magicext((SV*)modified, (SV*)modifiers, PERL_MAGIC_ext, &modified_vtbl, NULL, 0);
	SvREFCNT_dec((SV*)modifiers); /* refcnt++ in sv_magicext() */
	CvXSUBANY(modified).any_ptr = (void*)mg;

	RETVAL = newRV_noinc((SV*)modified);
OUTPUT:
	RETVAL


void
subroutine_modifier(code, ...)
	CV* code
PREINIT:
	/* Usage:
		subroutine_modifier(code)                 # check
		subroutine_modifier(code, property)       # get
		subroutine_modifier(code, property, subs) # set
	*/
	MAGIC* mg;
	AV* modifiers; /* (before, around, after, original, current) */
	SV* property;
	const char* property_pv;
PPCODE:
	mg = mg_find_by_vtbl((SV*)code, &modified_vtbl);

	if(items == 1){ /* check only */
		ST(0) = boolSV(mg);
		XSRETURN(1);
	}

	if(!mg){
		my_fail(aTHX_ "a modified subroutine", ST(0) /* ref to code */);
	}

	modifiers = (AV*)mg->mg_obj;
	assert(modifiers);

	property = my_string(aTHX_ ST(1), "a modifier property");
	property_pv = SvPV_nolen_const(property);

	if(strEQ(property_pv, "before") || strEQ(property_pv, "around") || strEQ(property_pv, "after")){
		I32 const idx =
			  strEQ(property_pv, "before") ? M_BEFORE
			: strEQ(property_pv, "around") ? M_AROUND
			:                                M_AFTER;
		AV* const av = (AV*)*av_fetch(modifiers, idx, FALSE);
		if(items != 2){ /* add */
			I32 i;
			for(i = 2; i < items; i++){
				SV* const code_ref = newSVsv(validate(ST(i), T_CV));
				if(idx == M_AFTER){
					av_push(av, code_ref);
				}
				else{
					av_unshift(av, 1);
					av_store(av, 0, code_ref);
				}
			}

			if(idx == M_AROUND){
				AV* const around = (AV*)sv_2mortal((SV*)av_make(items-2, &ST(2)));
				SV* const current = my_build_around_code(aTHX_
						*av_fetch(modifiers, M_CURRENT, FALSE),
						around
					);
				av_store(modifiers, M_CURRENT, current);
			}
		}
		XPUSHary(AvARRAY(av), 0, AvFILLp(av)+1);
	}
	else{
		my_fail(aTHX_ "a modifier property", property);
	}



#define mkopt(opt_list, moniker, require_unique, must_be) \
		my_mkopt(aTHX_ opt_list, moniker, require_unique, must_be, T_AV)
#define mkopt_hash(opt_list, moniker, must_be) \
		my_mkopt(aTHX_ opt_list, moniker, TRUE, must_be, T_HV)


SV*
mkopt(opt_list = UNDEF, moniker = UNDEF, require_unique = FALSE, must_be = UNDEF)
	SV* opt_list
	SV* moniker
	bool require_unique
	SV* must_be

SV*
mkopt_hash(opt_list = UNDEF, moniker = UNDEF, must_be = UNDEF)
	SV* opt_list
	SV* moniker
	SV* must_be
