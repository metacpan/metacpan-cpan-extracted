/* neat.c */

#include "data-util.h"

#define PV_LIMIT 20

static int
is_identifier_cstr(const char* pv, const STRLEN len){
	if(isIDFIRST(*pv)){
		const char* const end = pv + len - 1 /* '\0' */;

		while(pv != end){
			++pv;
			if(!isALNUM(*pv)){
				return FALSE;
			}
		}
		return TRUE;
	}
	return FALSE;
}

static void
du_neat_cat(pTHX_ SV* const dsv, SV* x, const int level){

	if(level > 2){
		sv_catpvs(dsv, "...");
		return;
	}

	if(SvRXOK(x)){ /* regex */
		Perl_sv_catpvf(aTHX_ dsv, "qr{%"SVf"}", x);
		return;
	}
	else if(SvROK(x)){
		x = SvRV(x);

		if(SvOBJECT(x)){
			Perl_sv_catpvf(aTHX_ dsv, "%s=%s(0x%p)",
				sv_reftype(x, TRUE), sv_reftype(x, FALSE), x);
			return;
		}
		else if(SvTYPE(x) == SVt_PVAV){
			I32 const len = av_len((AV*)x);

			sv_catpvs(dsv, "[");
			if(len >= 0){
				SV** const svp = av_fetch((AV*)x, 0, FALSE);

				if(*svp){
					du_neat_cat(aTHX_ dsv, *svp, level+1);
				}
				else{
					sv_catpvs(dsv, "undef");
				}
				if(len > 0){
					sv_catpvs(dsv, ", ...");
				}
			}
			sv_catpvs(dsv, "]");
		}
		else if(SvTYPE(x) == SVt_PVHV){
			I32 klen;
			char* key;
			SV* val;

			hv_iterinit((HV*)x);
			val = hv_iternextsv((HV*)x, &key, &klen);

			sv_catpvs(dsv, "{");
			if(val){
				if(!is_identifier_cstr(key, klen)){
					SV* const sv = sv_newmortal();
					key = pv_display(sv, key, klen, klen, PV_LIMIT);
				}
				Perl_sv_catpvf(aTHX_ dsv, "%s => ", key);
				du_neat_cat(aTHX_ dsv, val, level+1);

				if(hv_iternext((HV*)x)){
					sv_catpvs(dsv, ", ...");
				}
			}

			sv_catpvs(dsv, "}");
		}
		else if(SvTYPE(x) == SVt_PVCV){
			GV* const gv = CvGV((CV*)x);
			Perl_sv_catpvf(aTHX_ dsv, "\\&%s::%s(0x%p)", HvNAME(GvSTASH(gv)), GvNAME(gv), x);
		}
		else{
			sv_catpvs(dsv, "\\");
			du_neat_cat(aTHX_ dsv, x, level+1);
		}
	}
	else if(isGV(x)){
		sv_catsv(dsv, x);
	}
	else if(SvOK(x)){
		if(SvPOKp(x)){
			STRLEN cur;
			char* const pv = SvPV(x, cur); /* pv_sisplay requires char*, not const char* */
			SV* const sv = sv_newmortal();
			pv_display(sv, pv, cur, cur, PV_LIMIT);
			sv_catsv(dsv, sv);
		}
		else{
			NV const nv = SvNV(x);

			if(nv == NV_INF){
				sv_catpvs(dsv, "+Inf");
			}
			else if(nv == -NV_INF){
				sv_catpvs(dsv, "-Inf");
			}
			else if(Perl_isnan(nv)){
				sv_catpvs(dsv, "NaN");
			}
			else{
				Perl_sv_catpvf(aTHX_ dsv, "%"NVgf, nv);
			}
		}
	}
	else{
		sv_catpvs(dsv, "undef");
	}
}

const char*
du_neat(pTHX_ SV* x){
	SV* const dsv = newSV(100);
	sv_2mortal(dsv);
	sv_setpvs(dsv, "");

	ENTER;
	SAVETMPS;

	SvGETMAGIC(x);
	du_neat_cat(aTHX_ dsv, x, 0);

	FREETMPS;
	LEAVE;

	return SvPVX(dsv);
}
