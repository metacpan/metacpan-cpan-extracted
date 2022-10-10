#ifndef __INHERITED_XS_COMPAT_H_
#define __INHERITED_XS_COMPAT_H_

#if (PERL_VERSION >= 12)
#define CAIX_OPTIMIZE_OPMETHOD
#define CAIX_OPTIMIZE_OPMETHOD_RESULT (&PL_sv_yes)
#else
#define CAIX_OPTIMIZE_OPMETHOD_RESULT (&PL_sv_no)
#endif

#ifndef SvREFCNT_dec_NN
#define SvREFCNT_dec_NN SvREFCNT_dec
#endif

#ifdef dNOOP
#undef dNOOP
#define dNOOP
#endif

#if defined(GvGPFLAGS_on) || defined(GvGPFLAGS_off)
#error("GvGPFLAGS_on or GvGPFLAGS_off defined by perl core");
#endif

#ifndef GvGPFLAGS
#define GvGPFLAGS(gv) (GvLINE(gv) & ((U32)1<<31))
#define GvGPFLAGS_on(gv) (GvLINE(gv) |= ((U32)1<<31))
#define GvGPFLAGS_off(gv) (GvLINE(gv) &= ~((U32)1<<31))
#else
#define GvGPFLAGS_on(gv) (GvGPFLAGS(gv) = 1)
#define GvGPFLAGS_off(gv) (GvGPFLAGS(gv) = 0)
#endif

#ifndef OpSIBLING
#define OpSIBLING(o) ((o)->op_sibling)
#endif

#ifndef OpHAS_SIBLING
#define OpHAS_SIBLING(o) ((o)->op_sibling)
#endif

#ifndef HvENAME
#define HvENAME HvNAME
#define HvENAME_HEK HvNAME_HEK
#endif

#define hv_fetchhek(hv, hek) \
    ((SV **)hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), HV_FETCH_JUST_SV, NULL, HEK_HASH(hek)))

#ifndef gv_init_sv
#define gv_init_sv(gv, stash, sv, flags) gv_init(gv, stash, SvPVX(sv), SvLEN(sv), flags | SvUTF8(sv))
#endif

#ifndef gv_fetchmethod_sv_flags
#define gv_fetchmethod_sv_flags(stash, name, flags) gv_fetchmethod_flags(stash, SvPV_nolen_const(name), flags)
#endif

#if (PERL_VERSION < 16) || defined(WIN32) || (PERL_VERSION > 36)
#define CAIX_BINARY_UNSAFE
#define CAIX_BINARY_UNSAFE_RESULT (&PL_sv_yes)
#define Perl_newXS_len_flags(name, len, subaddr, filename, proto, const_svp, flags) Perl_newXS_flags(name, subaddr, filename, proto, flags)
#else
#define CAIX_BINARY_UNSAFE_RESULT (&PL_sv_no)
#endif

#endif /* __INHERITED_XS_COMPAT_H_ */
