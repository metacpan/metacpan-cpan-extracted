#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define MP_SOURCE 1
#include "msgpuck.h"



void _mpack_item(SV *res, SV *o)
{
	size_t len, res_len, new_len;
	char *s, *res_s;
	res_s = SvPVbyte(res, res_len);
	unsigned i;

	if (!SvOK(o)) {
		new_len = res_len + mp_sizeof_nil();
		res_s = SvGROW(res, new_len);
		SvCUR_set(res, new_len);
		mp_encode_nil(res_s + res_len);
		return;
	}

	if (SvROK(o)) {
		o = SvRV(o);
		if (SvOBJECT(o)) {
			SvGETMAGIC(o);
			HV *stash = SvSTASH(o);
			GV *mtd = gv_fetchmethod_autoload(stash, "msgpack", 0);
			if (!mtd)
				croak("Object has no method 'msgpack'");
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			XPUSHs (sv_bless (sv_2mortal (newRV_inc(o)), stash));
			PUTBACK;
			call_sv((SV *)GvCV(mtd), G_SCALAR);
			SPAGAIN;

			SV *pkt = POPs;

			if (!SvOK(pkt))
				croak("O->msgpack returned undef");

			s = SvPV(pkt, len);

			new_len = res_len + len;
			res_s = SvGROW(res, new_len);
			SvCUR_set(res, new_len);
			memcpy(res_s + res_len, s, len);

			PUTBACK;
			FREETMPS;
			LEAVE;

			return;
		}

		switch(SvTYPE(o)) {
			case SVt_PVAV: {
				AV *a = (AV *)o;
				len = av_len(a) + 1;
				new_len = res_len + mp_sizeof_array(len);
				res_s = SvGROW(res, new_len);
				SvCUR_set(res, new_len);
				mp_encode_array(res_s + res_len, len);

				for (i = 0; i < len; i++) {
					SV **item = av_fetch(a, i, 0);
					if (!item)
						_mpack_item(res, 0);
					else
						_mpack_item(res, *item);
				}

				break;
			}
			case SVt_PVHV: {
				HV *h = (HV *)o;
				len = hv_iterinit(h);
				new_len = res_len + mp_sizeof_map(len);
				res_s = SvGROW(res, new_len);
				SvCUR_set(res, new_len);
				mp_encode_map(res_s + res_len, len);

				for (;;) {
					HE * iter = hv_iternext(h);
					if (!iter)
						break;

					SV *k = hv_iterkeysv(iter);
					SV *v = HeVAL(iter);
					_mpack_item(res, k);
					_mpack_item(res, v);

				}

				break;
			}

			default:
				croak("Can't serialize reference");
		}
		return;
	}

	switch(SvTYPE(o)) {
		case SVt_PV:
		case SVt_PVIV:
		case SVt_PVNV:
		case SVt_PVMG:
		case SVt_REGEXP:
			if (!looks_like_number(o)) {
				s = SvPV(o, len);
				new_len = res_len + mp_sizeof_str(len);
				res_s = SvGROW(res, new_len);
				SvCUR_set(res, new_len);
				mp_encode_str(res_s + res_len, s, len);
				break;
			}

		case SVt_NV: {
			NV v = SvNV(o);
			IV iv = (IV)v;

			if (v != iv) {
				new_len = res_len + mp_sizeof_double(v);
				res_s = SvGROW(res, new_len);
				SvCUR_set(res, new_len);
				mp_encode_double(res_s + res_len, v);
				break;
			}
		}
		case SVt_IV: {
			IV v = SvIV(o);
			if (v >= 0) {
				new_len = res_len + mp_sizeof_uint(v);
				res_s = SvGROW(res, new_len);
				SvCUR_set(res, new_len);
				mp_encode_uint(res_s + res_len, v);
			} else {
				new_len = res_len + mp_sizeof_int(v);
				res_s = SvGROW(res, new_len);
				SvCUR_set(res, new_len);
				mp_encode_int(res_s + res_len, v);
			}
			break;
		}
		default:
			croak("Internal msgpack error %d", SvTYPE(o));
	}
}


const char *
_munpack_item(const char *p, size_t len, SV **res, HV *ext, int utf)
{
	if (!len || !p)
		croak("Internal error: out of pointer");

	const char *pe = p + len;

	switch(mp_typeof(*p)) {
		case MP_UINT:
			*res = newSViv( mp_decode_uint(&p) );
			break;
		case MP_INT:
			*res = newSViv( mp_decode_int(&p) );
			break;
		case MP_FLOAT:
			*res = newSVnv( mp_decode_float(&p) );
			break;
		case MP_DOUBLE:
			*res = newSVnv( mp_decode_double(&p) );
			break;
		case MP_STR: {
			const char *s;
			uint32_t len;
			s = mp_decode_str(&p, &len);
			*res = newSVpvn_flags(s, len, utf ? SVf_UTF8 : 0);
			break;
		}
		case MP_NIL: {
			mp_decode_nil(&p);
			*res = newSV(0);
			break;
		}
		case MP_BOOL:
			if (mp_decode_bool(&p)) {
				*res = newSViv(1);
			} else {
				*res = newSViv(0);
			}
			break;
		case MP_MAP: {
			uint32_t l, i;
			l = mp_decode_map(&p);
			HV * h = newHV();
			sv_2mortal((SV *)h);
			for (i = 0; i < l; i++) {
				SV *k = 0;
				SV *v = 0;
				if (p >= pe)
					croak("Unexpected EOF msgunpack str");
				p = _munpack_item(p, pe - p, &k, ext, utf);
				sv_2mortal(k);
				if (p >= pe)
					croak("Unexpected EOF msgunpack str");
				p = _munpack_item(p, pe - p, &v, ext, utf);
				hv_store_ent(h, k, v, 0);
			}
			*res = newRV((SV *)h);
			break;
		}
		case MP_ARRAY: {
			uint32_t l, i;
			l = mp_decode_array(&p);
			AV *a = newAV();
			sv_2mortal((SV *)a);
			for (i = 0; i < l; i++) {
				SV *item = 0;
				if (p >= pe)
					croak("Unexpected EOF msgunpack str");
				p = _munpack_item(p, pe - p, &item, ext, utf);
				av_push(a, item);

			}
			*res = newRV((SV *)a);
			break;
		}
		case MP_EXT: {
			croak("Isn't defined yet");
		}
		default:
			croak("Unexpected symbol 0x%02x", 0xFF & (int)(*p));

	}
	return p;
}


