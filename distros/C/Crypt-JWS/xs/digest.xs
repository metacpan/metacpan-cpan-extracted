MODULE = Crypt::JWS  PACKAGE = Crypt::JWS

SV *
sha256(bytes)
        SV *bytes
    ALIAS:
        sha384 = 384
        sha512 = 512
    CODE:
        STRLEN len;
        const char *p = SvPVbyte(bytes, len);
        int bits = ix ? (int)ix : 256;
        unsigned char out[EVP_MAX_MD_SIZE];
        unsigned n = cjws_digest(bits, (const unsigned char *)p, len, out);
        if (!n)
            croak("Crypt::JWS: digest failed");
        RETVAL = newSVpvn((const char *)out, n);
    OUTPUT:
        RETVAL

SV *
hmac_sha256(key, bytes)
        SV *key
        SV *bytes
    ALIAS:
        hmac_sha384 = 384
        hmac_sha512 = 512
    CODE:
        STRLEN klen, len;
        const char *kp = SvPVbyte(key, klen);
        const char *p = SvPVbyte(bytes, len);
        int bits = ix ? (int)ix : 256;
        unsigned char out[EVP_MAX_MD_SIZE];
        STRLEN n = cjws_hmac(bits, (const unsigned char *)kp, klen,
                             (const unsigned char *)p, len, out);
        if (!n)
            croak("Crypt::JWS: hmac failed");
        RETVAL = newSVpvn((const char *)out, n);
    OUTPUT:
        RETVAL
