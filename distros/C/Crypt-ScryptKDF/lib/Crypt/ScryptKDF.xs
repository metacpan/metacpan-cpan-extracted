#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "crypto_scrypt.h"

MODULE = Crypt::ScryptKDF       PACKAGE = Crypt::ScryptKDF

SV *
_scrypt(SV *passwd, SV *salt, UV N, U32 r, U32 p, STRLEN res_len)
    PREINIT:
        STRLEN p_len, s_len;
        uint8_t *result, *p_data, *s_data;
    CODE:
    {
        p_data = (uint8_t *) SvPVbyte(passwd, p_len);
        s_data = (uint8_t *) SvPVbyte(salt, s_len);
        /* warn("DEBUG: p_len=%d s_len=%d r=%d, N=%d, p=%d, res_len=%d\n", p_len, s_len, r, N, p, res_len); */
        Newz(0, result, res_len, uint8_t);
        /* crypto_scrypt(const uint8_t * passwd, size_t passwdlen,
         *               const uint8_t * salt, size_t saltlen,
         *               uint64_t N, uint32_t r, uint32_t p, uint8_t * buf, size_t buflen)
         */
        if (crypto_scrypt(p_data, p_len, s_data, s_len, N, r, p, result, res_len) == 0)
          RETVAL = newSVpvn((char*)result, res_len);
        else
          RETVAL = newSVpvn(NULL, 0); /* undef */
        Zero(result, res_len, uint8_t);
        Safefree(result);
    }
    OUTPUT:
        RETVAL
