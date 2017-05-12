#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "xtea.h"

MODULE = Crypt::XTEA    PACKAGE = Crypt::XTEA

PROTOTYPES: ENABLE

SV *
encrypt_block_in_c(self, blocks)
    SV * self
    AV * blocks
    INIT:
        HV * obj;
        unsigned int i;
        uint32_t v[2], k[4], num_rounds;
        AV * results;
        results = MUTABLE_AV(sv_2mortal(MUTABLE_SV(newAV())));
    CODE:
        obj = MUTABLE_HV(SvRV(self));

        for (i = 0; i < 2; i++) {
            v[i] = (uint32_t) SvUV(*av_fetch(blocks, i, 0));
        }

        for (i = 0; i < 4; i++) {
            k[i] = (uint32_t) SvUV(*av_fetch(MUTABLE_AV(SvRV(*hv_fetch(obj, "key", 3, 0))), i, 0));
        }

        num_rounds = (uint32_t) SvUV(*hv_fetch(obj, "rounds", 6, 0));

        xtea_encrypt( num_rounds, v, k );

        for (i = 0; i < 2; i++) {
            av_store(results, i, newSVuv(v[i]));
        }

        RETVAL = newRV(MUTABLE_SV(results));
    OUTPUT:
        RETVAL

SV *
decrypt_block_in_c(self, blocks)
    SV * self
    AV * blocks
    INIT:
        HV * obj;
        unsigned int i;
        uint32_t v[2], k[4], num_rounds;
        AV * results;
        results = MUTABLE_AV(sv_2mortal(MUTABLE_SV(newAV())));
    CODE:
        obj = MUTABLE_HV(SvRV(self));

        for (i = 0; i < 2; i++) {
            v[i] = (uint32_t) SvUV(*av_fetch(blocks, i, 0));
        }

        for (i = 0; i < 4; i++) {
            k[i] = (uint32_t) SvUV(*av_fetch(MUTABLE_AV(SvRV(*hv_fetch(obj, "key", 3, 0))), i, 0));
        }

        num_rounds = (uint32_t) SvUV(*hv_fetch(obj, "rounds", 6, 0));

        xtea_decrypt( num_rounds, v, k );

        for (i = 0; i < 2; i++) {
            av_store(results, i, newSVuv(v[i]));
        }

        RETVAL = newRV(MUTABLE_SV(results));
    OUTPUT:
        RETVAL
