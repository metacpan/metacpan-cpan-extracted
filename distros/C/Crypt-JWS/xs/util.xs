MODULE = Crypt::JWS  PACKAGE = Crypt::JWS

SV *
b64url(bytes)
        SV *bytes
    CODE:
        STRLEN len;
        const char *p = SvPVbyte(bytes, len);
        RETVAL = cjws_abi_b64url(aTHX_ (const unsigned char *)p, len);
    OUTPUT:
        RETVAL

SV *
b64url_decode(str)
        SV *str
    CODE:
        STRLEN len;
        const char *p = SvPVbyte(str, len);
        RETVAL = cjws_abi_b64url_decode(aTHX_ p, len);
        if (!RETVAL)
            croak("Crypt::JWS: invalid base64url input");
    OUTPUT:
        RETVAL

int
ct_eq(a, b)
        SV *a
        SV *b
    CODE:
        STRLEN alen, blen;
        const char *ap = SvPVbyte(a, alen);
        const char *bp = SvPVbyte(b, blen);
        RETVAL = cjws_ct_eq((const unsigned char *)ap, alen,
                            (const unsigned char *)bp, blen);
    OUTPUT:
        RETVAL

SV *
random_bytes(n)
        UV n
    CODE:
        if (n < 1 || n > 1024 * 1024)
            croak("Crypt::JWS: random_bytes(1 .. 1048576)");
        RETVAL = cjws_abi_random_bytes(aTHX_ (STRLEN)n);
    OUTPUT:
        RETVAL

IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&CJWS_ABI);
    OUTPUT:
        RETVAL

int
_abi_selftest(...)
    CODE:
        /* Exercise the table the way a C consumer would: resolve, version
         * check, then call through the pointers. */
        const jws_abi *J = &CJWS_ABI;
        void *key;
        SV *sig, *digest, *rand;
        int ok = 0;
        if (J->version != JWS_ABI_VERSION)
            croak("Crypt::JWS: ABI version mismatch");
        key = J->key_from_oct(aTHX_ (const unsigned char *)"selftest", 8);
        if (!key)
            croak("Crypt::JWS: ABI key_from_oct failed");
        sig = J->sign(aTHX_ key, "HS256", 5,
                      (const unsigned char *)"input", 5);
        if (sig) {
            STRLEN slen;
            const char *sp = SvPVbyte(sig, slen);
            ok = J->verify(aTHX_ key, "HS256", 5,
                           (const unsigned char *)"input", 5,
                           (const unsigned char *)sp, slen);
            SvREFCNT_dec(sig);
        }
        digest = J->sha256(aTHX_ (const unsigned char *)"abc", 3);
        ok = ok && digest && SvCUR(digest) == 32;
        if (digest) SvREFCNT_dec(digest);
        /* v2: SHA-1 answers with the FIPS 180 "abc" vector, so the
         * selftest proves the digest and not merely the length */
        digest = J->sha1(aTHX_ (const unsigned char *)"abc", 3);
        ok = ok && digest && SvCUR(digest) == 20
           && memEQ(SvPVX(digest),
                    "\xa9\x99\x3e\x36\x47\x06\x81\x6a\xba\x3e"
                    "\x25\x71\x78\x50\xc2\x6c\x9c\xd0\xd8\x9d", 20);
        if (digest) SvREFCNT_dec(digest);
        digest = J->hmac_sha1(aTHX_ (const unsigned char *)"key", 3,
                              (const unsigned char *)"msg", 3);
        ok = ok && digest && SvCUR(digest) == 20;
        if (digest) SvREFCNT_dec(digest);
        digest = J->hmac_sha512(aTHX_ (const unsigned char *)"key", 3,
                                (const unsigned char *)"msg", 3);
        ok = ok && digest && SvCUR(digest) == 64;
        if (digest) SvREFCNT_dec(digest);
        rand = J->random_bytes(aTHX_ 16);
        ok = ok && rand && SvCUR(rand) == 16;
        if (rand) SvREFCNT_dec(rand);
        ok = ok && J->key_is_private(aTHX_ key);
        J->key_free(aTHX_ key);
        if (items >= 2 && SvOK(ST(0)) && SvOK(ST(1))) {
            STRLEN derlen, pemlen;
            const char *der = SvPVbyte(ST(0), derlen);
            const char *pem = SvPVbyte(ST(1), pemlen);
            void *priv = J->key_from_pem(aTHX_ pem, pemlen);
            void *pub  = J->key_from_x509_der(aTHX_
                             (const unsigned char *)der, derlen);
            int v3 = 0;
            if (priv && pub) {
                SV *s = J->sign(aTHX_ priv, "RS256", 5,
                                (const unsigned char *)"input", 5);
                if (s) {
                    STRLEN slen;
                    const char *sp = SvPVbyte(s, slen);
                    v3 = J->verify(aTHX_ pub, "RS256", 5,
                                   (const unsigned char *)"input", 5,
                                   (const unsigned char *)sp, slen);
                    SvREFCNT_dec(s);
                }
                v3 = v3 && J->key_is_private(aTHX_ priv)
                        && !J->key_is_private(aTHX_ pub);
            }
            if (priv) J->key_free(aTHX_ priv);
            if (pub)  J->key_free(aTHX_ pub);
            /* garbage is NULL, not a crash and not a key */
            v3 = v3 && !J->key_from_x509_der(aTHX_
                           (const unsigned char *)"not a certificate", 17);
            ok = ok && v3;
        }
        RETVAL = ok;
    OUTPUT:
        RETVAL
