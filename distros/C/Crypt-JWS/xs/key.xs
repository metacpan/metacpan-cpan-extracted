MODULE = Crypt::JWS  PACKAGE = Crypt::JWS::Key

SV *
from_pem(class, pem)
        SV *class
        SV *pem
    CODE:
        STRLEN len;
        const char *p = SvPVbyte(pem, len);
        cjws_key *k = cjws_key_from_pem(p, len);
        PERL_UNUSED_VAR(class);
        if (!k)
            croak("Crypt::JWS::Key: cannot parse PEM (RSA and EC keys only)");
        RETVAL = cjws_bless_key(aTHX_ k);
    OUTPUT:
        RETVAL

SV *
from_secret(class, secret)
        SV *class
        SV *secret
    CODE:
        STRLEN len;
        const char *p = SvPVbyte(secret, len);
        cjws_key *k = cjws_key_from_oct((const unsigned char *)p, len);
        PERL_UNUSED_VAR(class);
        if (!k)
            croak("Crypt::JWS::Key: cannot build oct key");
        RETVAL = cjws_bless_key(aTHX_ k);
    OUTPUT:
        RETVAL

SV *
from_jwk(class, jwk)
        SV *class
        SV *jwk
    CODE:
        HV *hv;
        SV **ktysv;
        STRLEN ktylen = 0;
        const char *kty = NULL;
        cjws_key *k = NULL;
        PERL_UNUSED_VAR(class);
        if (!SvROK(jwk) || SvTYPE(SvRV(jwk)) != SVt_PVHV)
            croak("Crypt::JWS::Key->from_jwk expects a hashref");
        hv = (HV *)SvRV(jwk);
        ktysv = hv_fetchs(hv, "kty", 0);
        if (ktysv && *ktysv && SvOK(*ktysv))
            kty = SvPV_const(*ktysv, ktylen);
        if (kty && ktylen == 3 && memEQ(kty, "RSA", 3)) {
            SV *n = cjws_jwk_b64_field(aTHX_ hv, "n", 1);
            SV *e = cjws_jwk_b64_field(aTHX_ hv, "e", 1);
            SV *d = cjws_jwk_b64_field(aTHX_ hv, "d", 0);
            k = cjws_key_from_rsa_params(
                (const unsigned char *)SvPVX(n), SvCUR(n),
                (const unsigned char *)SvPVX(e), SvCUR(e),
                d ? (const unsigned char *)SvPVX(d) : NULL,
                d ? SvCUR(d) : 0);
            if (!k)
                croak("Crypt::JWS::Key: invalid RSA parameters");
        }
        else if (kty && ktylen == 2 && memEQ(kty, "EC", 2)) {
            int bits = cjws_jwk_curve_bits(aTHX_ hv);
            SV *x = cjws_jwk_b64_field(aTHX_ hv, "x", 1);
            SV *y = cjws_jwk_b64_field(aTHX_ hv, "y", 1);
            SV *d = cjws_jwk_b64_field(aTHX_ hv, "d", 0);
            k = cjws_key_from_ec_params(bits,
                (const unsigned char *)SvPVX(x), SvCUR(x),
                (const unsigned char *)SvPVX(y), SvCUR(y),
                d ? (const unsigned char *)SvPVX(d) : NULL,
                d ? SvCUR(d) : 0);
            if (!k)
                croak("Crypt::JWS::Key: invalid EC parameters (point not "
                      "on P-%d?)", bits);
        }
        else if (kty && ktylen == 3 && memEQ(kty, "oct", 3)) {
            SV *sec = cjws_jwk_b64_field(aTHX_ hv, "k", 1);
            k = cjws_key_from_oct((const unsigned char *)SvPVX(sec),
                                  SvCUR(sec));
            if (!k)
                croak("Crypt::JWS::Key: cannot build oct key");
        }
        else {
            croak("Crypt::JWS::Key: unsupported kty '%.*s'",
                  kty ? (int)ktylen : 0, kty ? kty : "");
        }
        RETVAL = cjws_bless_key(aTHX_ k);
    OUTPUT:
        RETVAL

SV *
generate(class, alg, ...)
        SV *class
        SV *alg
    CODE:
        STRLEN alglen;
        const char *a = SvPV_const(alg, alglen);
        char fam = 0;
        int bits = 0;
        cjws_key *k = NULL;
        IV rsa_bits = 2048;
        int i;
        PERL_UNUSED_VAR(class);
        if ((items - 2) % 2)
            croak("Crypt::JWS::Key->generate: uneven option list");
        for (i = 2; i < items; i += 2) {
            STRLEN klen;
            const char *opt = SvPV_const(ST(i), klen);
            if (klen == 4 && memEQ(opt, "bits", 4))
                rsa_bits = SvIV(ST(i + 1));
            else
                croak("Crypt::JWS::Key->generate: unknown option '%.*s'",
                      (int)klen, opt);
        }
        if (!cjws_alg_parse(a, alglen, &fam, &bits))
            croak("Crypt::JWS::Key: cannot generate for alg '%.*s'",
                  (int)alglen, a);
        if (fam == CJWS_FAM_ES) {
            k = cjws_key_generate_ec(cjws_es_curve_bits(bits));
            if (!k)
                croak("Crypt::JWS::Key: EC generation failed");
        }
        else if (fam == CJWS_FAM_RS) {
            if (rsa_bits < 2048 || rsa_bits > 8192)
                croak("Crypt::JWS::Key: RSA bits must be 2048 .. 8192");
            k = cjws_key_generate_rsa((int)rsa_bits);
            if (!k)
                croak("Crypt::JWS::Key: RSA generation failed");
        }
        else {
            unsigned char secret[64];
            cjws_random_bytes(aTHX_ secret, (STRLEN)(bits / 8));
            k = cjws_key_from_oct(secret, (STRLEN)(bits / 8));
            OPENSSL_cleanse(secret, sizeof secret);
            if (!k)
                croak("Crypt::JWS::Key: oct generation failed");
        }
        RETVAL = cjws_bless_key(aTHX_ k);
    OUTPUT:
        RETVAL

SV *
to_pem(self, ...)
        SV *self
    CODE:
        cjws_key *k = cjws_key_of(aTHX_ self);
        int want_private = 0;
        STRLEN outlen = 0;
        unsigned char *pem;
        if (items > 1 && SvTRUE(ST(1)))
            want_private = 1;
        pem = cjws_key_to_pem(k, want_private, &outlen);
        if (!pem)
            croak(want_private && !k->is_private
                ? "Crypt::JWS::Key: this key has no private part"
                : "Crypt::JWS::Key: PEM export failed (oct keys have no "
                  "PEM form)");
        RETVAL = newSVpvn((const char *)pem, outlen);
        OPENSSL_cleanse(pem, outlen);
        OPENSSL_free(pem);
    OUTPUT:
        RETVAL

SV *
to_jwk(self, ...)
        SV *self
    CODE:
        cjws_key *k = cjws_key_of(aTHX_ self);
        HV *jwk;
        int i;
        SV *kid = NULL, *use_sv = NULL, *algv = NULL;
        if ((items - 1) % 2)
            croak("Crypt::JWS::Key->to_jwk: uneven option list");
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *opt = SvPV_const(ST(i), klen);
            if (klen == 7 && memEQ(opt, "private", 7)) {
                if (SvTRUE(ST(i + 1)))
                    croak("Crypt::JWS::Key: private JWK export is not "
                          "supported - use to_pem(1) for the private half");
            }
            else if (klen == 3 && memEQ(opt, "kid", 3)) kid = ST(i + 1);
            else if (klen == 3 && memEQ(opt, "use", 3)) use_sv = ST(i + 1);
            else if (klen == 3 && memEQ(opt, "alg", 3)) algv = ST(i + 1);
            else
                croak("Crypt::JWS::Key->to_jwk: unknown option '%.*s'",
                      (int)klen, opt);
        }
        if (k->kty == CJWS_KTY_OCT)
            croak("Crypt::JWS::Key: oct keys are secrets - no public JWK");
        jwk = newHV();
        if (k->kty == CJWS_KTY_RSA) {
            BIGNUM *n = NULL, *e = NULL;
            int nlen, elen;
            unsigned char *buf;
            if (!cjws_pkey_get_rsa(k->pkey, &n, &e)) {
                SvREFCNT_dec((SV *)jwk);
                croak("Crypt::JWS::Key: RSA parameter extraction failed");
            }
            nlen = BN_num_bytes(n);
            elen = BN_num_bytes(e);
            buf = (unsigned char *)OPENSSL_malloc((size_t)(nlen > elen ? nlen : elen));
            (void)hv_stores(jwk, "kty", newSVpvs("RSA"));
            if (buf) {
                BN_bn2bin(n, buf);
                (void)hv_stores(jwk, "n", cjws_b64url_sv(aTHX_ buf, (STRLEN)nlen));
                BN_bn2bin(e, buf);
                (void)hv_stores(jwk, "e", cjws_b64url_sv(aTHX_ buf, (STRLEN)elen));
            }
            OPENSSL_free(buf);
            BN_free(n); BN_free(e);
            if (!buf) {
                SvREFCNT_dec((SV *)jwk);
                croak("Crypt::JWS::Key: out of memory");
            }
        }
        else {
            BIGNUM *x = NULL, *y = NULL;
            int bits = 0, clen;
            unsigned char *buf;
            if (!cjws_pkey_get_ec(k->pkey, &bits, &x, &y)) {
                SvREFCNT_dec((SV *)jwk);
                croak("Crypt::JWS::Key: EC parameter extraction failed");
            }
            clen = cjws_curve_coord_len(bits);
            buf = (unsigned char *)OPENSSL_malloc((size_t)clen);
            (void)hv_stores(jwk, "kty", newSVpvs("EC"));
            (void)hv_stores(jwk, "crv", newSVpvf("P-%d", bits));
            if (buf) {
                BN_bn2binpad(x, buf, clen);
                (void)hv_stores(jwk, "x", cjws_b64url_sv(aTHX_ buf, (STRLEN)clen));
                BN_bn2binpad(y, buf, clen);
                (void)hv_stores(jwk, "y", cjws_b64url_sv(aTHX_ buf, (STRLEN)clen));
            }
            OPENSSL_free(buf);
            BN_free(x); BN_free(y);
            if (!buf) {
                SvREFCNT_dec((SV *)jwk);
                croak("Crypt::JWS::Key: out of memory");
            }
        }
        if (kid && SvOK(kid))    (void)hv_stores(jwk, "kid", newSVsv(kid));
        if (use_sv && SvOK(use_sv)) (void)hv_stores(jwk, "use", newSVsv(use_sv));
        if (algv && SvOK(algv))  (void)hv_stores(jwk, "alg", newSVsv(algv));
        RETVAL = newRV_noinc((SV *)jwk);
    OUTPUT:
        RETVAL

SV *
thumbprint(self)
        SV *self
    CODE:
        cjws_key *k = cjws_key_of(aTHX_ self);
        unsigned char out[32];
        if (!cjws_key_thumbprint(k, out))
            croak("Crypt::JWS::Key: thumbprint failed");
        RETVAL = cjws_b64url_sv(aTHX_ out, 32);
    OUTPUT:
        RETVAL

SV *
thumbprint_raw(self)
        SV *self
    CODE:
        cjws_key *k = cjws_key_of(aTHX_ self);
        unsigned char out[32];
        if (!cjws_key_thumbprint(k, out))
            croak("Crypt::JWS::Key: thumbprint failed");
        RETVAL = newSVpvn((const char *)out, 32);
    OUTPUT:
        RETVAL

int
is_private(self)
        SV *self
    CODE:
        RETVAL = cjws_key_of(aTHX_ self)->is_private;
    OUTPUT:
        RETVAL

SV *
kty(self)
        SV *self
    CODE:
        cjws_key *k = cjws_key_of(aTHX_ self);
        RETVAL = newSVpv(k->kty == CJWS_KTY_RSA ? "RSA"
                       : k->kty == CJWS_KTY_EC  ? "EC" : "oct", 0);
    OUTPUT:
        RETVAL

int
curve_bits(self)
        SV *self
    CODE:
        RETVAL = cjws_key_of(aTHX_ self)->curve_bits;
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        cjws_key_free(cjws_key_of(aTHX_ self));
