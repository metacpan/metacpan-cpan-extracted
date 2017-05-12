#ifndef _ALPMXS_CB
#define _ALPMXS_CB

#define DEFSETCB(TYPE, HND, ARG)\
	if(!SvOK(ARG) && TYPE##cb_ref){\
		SvREFCNT_dec(TYPE##cb_ref);\
		alpm_option_set_##TYPE##cb(HND, NULL);\
		TYPE##cb_ref = NULL;\
	}else{\
		if(!SvROK(ARG) || SvTYPE(SvRV(ARG)) != SVt_PVCV){\
			croak("value for " #TYPE "cb option must be a code reference");\
		}else if(TYPE##cb_ref){\
			sv_setsv(TYPE##cb_ref, ARG);\
		}else{\
			TYPE##cb_ref = newSVsv(ARG);\
			alpm_option_set_##TYPE##cb(HND, c2p_##TYPE##cb);\
		}\
	}

extern SV * logcb_ref, * dlcb_ref, * totaldlcb_ref, * fetchcb_ref;

void c2p_logcb(alpm_loglevel_t, const char *, va_list);
void c2p_dlcb(const char *, off_t, off_t);
int c2p_fetchcb(const char *, const char *, int);
void c2p_totaldlcb(off_t);

#endif
