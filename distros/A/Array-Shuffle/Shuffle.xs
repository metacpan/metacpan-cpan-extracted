#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

void shuffle_array(SV **p, IV i) {
    if (i > 0) {
        do {
            NV d = Drand01();
            IV j = (i + 1) * d;
            SV *tmp = p[i];
            p[i] = p[j];
            p[j] = tmp;
        } while (--i);
    }
}

void
shuffle_huge_array(SV **first, SV **last) {
    IV i;
    /* 100_000 is roughly the number of pointers that fit inside a 1MB
     * processor cache */
    while ((i = last - first) > 100000) {
        SV **f = first, **l = last;
        while (f <= l) {
            if (Drand01() < 0.5) {
                f++;
            }
            else {
                SV *tmp = *f;
                *f = *l;
                *l = tmp;
                l--;
            }
        }
        shuffle_huge_array(first, l);
        first = f;
    }
    shuffle_array(first, i);
}

MODULE = Array::Shuffle         PACKAGE = Array::Shuffle

PROTOTYPES: DISABLE

BOOT:
#if (PERL_VERSION >= 14)
    sv_setpv((SV*)GvCV(gv_fetchpvs("Array::Shuffle::shuffle_array", 0, SVt_PVCV)), "+");
    sv_setpv((SV*)GvCV(gv_fetchpvs("Array::Shuffle::shuffle_huge_array", 0, SVt_PVCV)), "+");
#else
    sv_setpv((SV*)GvCV(gv_fetchpvs("Array::Shuffle::shuffle_array", 0, SVt_PVCV)), "\\@");
    sv_setpv((SV*)GvCV(gv_fetchpvs("Array::Shuffle::shuffle_huge_array", 0, SVt_PVCV)), "\\@");
#endif

void
shuffle_array(av)
    AV *av
CODE:
    if (SvREADONLY(av))
        Perl_croak(aTHX_ "can't shuffle a read only array");
    if (SvMAGICAL((SV *)av)) {
        IV i;
        for (i = av_len(av); i > 0; i--) {
            NV d = Drand01();
            IV j = (i + 1) * d;
            if (i != j) {
                SV **svpi = av_fetch(av, i, 0);
                SV *svi = (svpi ? newSVsv(*svpi) : &PL_sv_undef);
                SV **svpj = av_fetch(av, j, 0);
                SV *svj = (svpj ? newSVsv(*svpj) : &PL_sv_undef);
                SV **svj_stored = av_store(av, i, svj);
                mg_set(svj);
                if (svj_stored == NULL) SvREFCNT_dec(svj);
                SV **svi_stored = av_store(av, j, svi);
                mg_set(svi);
                if (svi_stored == NULL) SvREFCNT_dec(svi);
            }
        }
    }
    else
        shuffle_array(AvARRAY(av), av_len(av));

void
shuffle_huge_array(av)
    AV *av
PREINIT:
    SV **p;
CODE:
    if (SvREADONLY(av))
        Perl_croak(aTHX_ "can't shuffle a read only array");
    if (SvMAGICAL((SV *)av))
        Perl_croak(aTHX_ "shuffle_huge_array can not handle arrays with magic attached");
    p = AvARRAY(av);
    shuffle_huge_array(p, p + av_len(av));
