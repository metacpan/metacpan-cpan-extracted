MODULE = Crypt::JWS  PACKAGE = Crypt::JWS

SV *
sign(key, payload, ...)
        SV *key
        SV *payload
    CODE:
        cjws_key *k = cjws_key_of(aTHX_ key);
        STRLEN plen, alglen = 0;
        const char *pp = SvPVbyte(payload, plen);
        const char *alg = NULL;
        SV *kid = NULL, *typ = NULL, *extra = NULL;
        HV *header;
        char fam;
        int bits;
        int i;
        if ((items - 2) % 2)
            croak("Crypt::JWS::sign: uneven option list");
        for (i = 2; i < items; i += 2) {
            STRLEN klen;
            const char *opt = SvPV_const(ST(i), klen);
            if (klen == 3 && memEQ(opt, "alg", 3))
                alg = SvPV_const(ST(i + 1), alglen);
            else if (klen == 3 && memEQ(opt, "kid", 3))
                kid = ST(i + 1);
            else if (klen == 3 && memEQ(opt, "typ", 3))
                typ = ST(i + 1);
            else if (klen == 13 && memEQ(opt, "extra_headers", 13))
                extra = ST(i + 1);
            else
                croak("Crypt::JWS::sign: unknown option '%.*s'",
                      (int)klen, opt);
        }
        if (!alg)
            croak("Crypt::JWS::sign: an alg is required");
        if (!cjws_alg_parse(alg, alglen, &fam, &bits))
            croak("Crypt::JWS::sign: unsupported alg '%.*s'",
                  (int)alglen, alg);
        header = newHV();
        sv_2mortal((SV *)header);
        if (extra && SvOK(extra)) {
            HV *ehv;
            HE *he;
            if (!SvROK(extra) || SvTYPE(SvRV(extra)) != SVt_PVHV)
                croak("Crypt::JWS::sign: extra_headers must be a hashref");
            ehv = (HV *)SvRV(extra);
            hv_iterinit(ehv);
            while ((he = hv_iternext(ehv))) {
                SV *v = HeVAL(he);
                STRLEN klen2;
                const char *k2 = HePV(he, klen2);
                (void)hv_store(header, k2, (I32)klen2, newSVsv(v), 0);
            }
        }
        /* alg/kid/typ stored last - extras can never clobber them */
        (void)hv_stores(header, "alg", newSVpvn(alg, alglen));
        if (kid && SvOK(kid))
            (void)hv_stores(header, "kid", newSVsv(kid));
        if (typ && SvOK(typ))
            (void)hv_stores(header, "typ", newSVsv(typ));
        RETVAL = cjws_compact_sign(aTHX_ k, alg, alglen, header,
                                   (const unsigned char *)pp, plen);
    OUTPUT:
        RETVAL

SV *
verify(token, key, ...)
        SV *token
        SV *key
    CODE:
        AV *algs = NULL;
        int i;
        if ((items - 2) % 2)
            croak("Crypt::JWS::verify: uneven option list");
        for (i = 2; i < items; i += 2) {
            STRLEN klen;
            const char *opt = SvPV_const(ST(i), klen);
            if (klen == 4 && memEQ(opt, "algs", 4)) {
                SV *v = ST(i + 1);
                if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV)
                    algs = (AV *)SvRV(v);
            }
            else
                croak("Crypt::JWS::verify: unknown option '%.*s'",
                      (int)klen, opt);
        }
        if (!algs)
            croak("Crypt::JWS::verify: an algs allowlist is required");
        RETVAL = cjws_compact_verify(aTHX_ token, key, algs);
        if (!RETVAL)
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
peek(token)
        SV *token
    CODE:
        STRLEN tlen;
        const char *t;
        const char *dot;
        SV *header;
        if (!SvOK(token))
            XSRETURN_UNDEF;
        t = SvPV_const(token, tlen);
        dot = (const char *)memchr(t, '.', tlen);
        header = cjws_decode_header(aTHX_ t,
            dot ? (STRLEN)(dot - t) : tlen);
        if (!header)
            XSRETURN_UNDEF;
        RETVAL = header;
    OUTPUT:
        RETVAL

SV *
_sign_raw(key, alg, input)
        SV *key
        SV *alg
        SV *input
    CODE:
        cjws_key *k = cjws_key_of(aTHX_ key);
        STRLEN alglen, inlen;
        const char *algp = SvPVbyte(alg, alglen);
        const char *inp = SvPVbyte(input, inlen);
        RETVAL = cjws_abi_sign(aTHX_ (void *)k, algp, alglen,
                               (const unsigned char *)inp, inlen);
        if (!RETVAL)
            croak("Crypt::JWS: sign failed (wrong key type for %.*s, "
                  "public key, or OpenSSL error)", (int)alglen, algp);
    OUTPUT:
        RETVAL

int
_verify_raw(key, alg, input, sig)
        SV *key
        SV *alg
        SV *input
        SV *sig
    CODE:
        cjws_key *k = cjws_key_of(aTHX_ key);
        STRLEN alglen, inlen, siglen;
        const char *algp = SvPVbyte(alg, alglen);
        const char *inp = SvPVbyte(input, inlen);
        const char *sigp = SvPVbyte(sig, siglen);
        RETVAL = cjws_verify_raw(aTHX_ k, algp, alglen,
                                 (const unsigned char *)inp, inlen,
                                 (const unsigned char *)sigp, siglen);
    OUTPUT:
        RETVAL
