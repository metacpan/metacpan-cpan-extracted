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
_abi_selftest()
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
        rand = J->random_bytes(aTHX_ 16);
        ok = ok && rand && SvCUR(rand) == 16;
        if (rand) SvREFCNT_dec(rand);
        ok = ok && J->key_is_private(aTHX_ key);
        J->key_free(aTHX_ key);
        RETVAL = ok;
    OUTPUT:
        RETVAL
