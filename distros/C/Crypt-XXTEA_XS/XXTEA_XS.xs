#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "xxtea.h"

MODULE = Crypt::XXTEA_XS    PACKAGE = Crypt::XXTEA_XS

PROTOTYPES: ENABLE

SV *
encrypt_block_in_c(self, blocks)
    SV * self
    AV * blocks
    INIT:
        HV * obj;
        unsigned int i, n;
        uint32_t * v, k[4];
        AV * results;
        results = MUTABLE_AV(sv_2mortal(MUTABLE_SV(newAV())));
    CODE:
        obj = MUTABLE_HV(SvRV(self));

        n = av_len(blocks) + 1;

        Newx(v, n, uint32_t);

        for (i = 0; i < n; i++) {
            *(v + i) = (uint32_t) SvUV(*av_fetch(blocks, i, 0));
        }

        for (i = 0; i < 4; i++) {
            k[i] = (uint32_t) SvUV(*av_fetch(MUTABLE_AV(SvRV(*hv_fetch(obj, "key", 3, 0))), i, 0));
        }

        xxtea_encrypt( v, n, k );

        for (i = 0; i < n; i++) {
            av_store(results, i, newSVuv(*(v + i)));
        }

        Safefree(v);

        RETVAL = newRV(MUTABLE_SV(results));
    OUTPUT:
        RETVAL

SV *
decrypt_block_in_c(self, blocks)
    SV * self
    AV * blocks
    INIT:
        HV * obj;
        unsigned int i, n;
        uint32_t * v, k[4];
        AV * results;
        results = MUTABLE_AV(sv_2mortal(MUTABLE_SV(newAV())));
    CODE:
        obj = MUTABLE_HV(SvRV(self));

        n = av_len(blocks) + 1;

        Newx(v, n, uint32_t);

        for (i = 0; i < n; i++) {
            *(v + i) = (uint32_t) SvUV(*av_fetch(blocks, i, 0));
        }

        for (i = 0; i < 4; i++) {
            k[i] = (uint32_t) SvUV(*av_fetch(MUTABLE_AV(SvRV(*hv_fetch(obj, "key", 3, 0))), i, 0));
        }

        xxtea_decrypt( v, n, k );

        for (i = 0; i < n; i++) {
            av_store(results, i, newSVuv(*(v + i)));
        }

        Safefree(v);

        RETVAL = newRV(MUTABLE_SV(results));
    OUTPUT:
        RETVAL
