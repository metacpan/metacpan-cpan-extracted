#ifndef CJWS_COMPACT_H
#define CJWS_COMPACT_H

/* The JWS compact serialization pipeline, entirely in C. Header JSON is
 * encoded and decoded through File::Raw::JSON's C ABI (frj_abi.h),
 * resolved lazily via the house consumer pattern - File::Raw::JSON is a
 * hard PREREQ, so a resolution failure is a boot-environment error. */

#include "frj_abi.h"
#include "cjws_key.h"
#include "cjws_jws.h"
#include "cjws_b64.h"

static const frj_abi *CJWS_FRJ = NULL;
static int CJWS_FRJ_TRIED = 0;

static const frj_abi *cjws_frj(pTHX) {
  if (!CJWS_FRJ && !CJWS_FRJ_TRIED) {
    dSP; int count; IV p = 0;
    CJWS_FRJ_TRIED = 1;
    eval_pv("require File::Raw::JSON;", FALSE);
    SPAGAIN;   /* the require may have reallocated the stack */
    if (!SvTRUE(ERRSV)) {
      ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
      count = call_pv("File::Raw::JSON::_abi_ptr", G_SCALAR | G_EVAL);
      SPAGAIN;
      if (!SvTRUE(ERRSV) && count > 0) p = POPi;
      else if (count > 0)              (void)POPs;
      PUTBACK; FREETMPS; LEAVE;
      if (p) {
        const frj_abi *a = INT2PTR(const frj_abi *, p);
        if (a && a->abi_version == FRJ_ABI_VERSION) CJWS_FRJ = a;
      }
    }
  }
  if (!CJWS_FRJ)
    croak("Crypt::JWS: File::Raw::JSON with a compatible C ABI is "
          "required (FRJ_ABI_VERSION %d)", FRJ_ABI_VERSION);
  return CJWS_FRJ;
}

/* b64url an SV's bytes into a fresh owned SV. */
static SV *cjws_b64url_sv(pTHX_ const unsigned char *p, STRLEN n) {
  SV *out = newSV(cjws_b64url_encoded_len(n) + 1);
  STRLEN o;
  SvPOK_on(out);
  o = cjws_b64url_encode(SvPVX(out), p, n);
  SvCUR_set(out, o);
  *SvEND(out) = '\0';
  return out;
}

/* Decode a b64url span into a fresh owned SV, or NULL on bad input. */
static SV *cjws_b64url_decode_sv(pTHX_ const char *p, STRLEN n) {
  SV *out = newSV((n / 4 + 1) * 3 + 1);
  STRLEN o;
  SvPOK_on(out);
  o = cjws_b64url_decode((unsigned char *)SvPVX(out), p, n);
  if (o == (STRLEN)-1) {
    SvREFCNT_dec(out);
    return NULL;
  }
  SvCUR_set(out, o);
  *SvEND(out) = '\0';
  return out;
}

/* Validate an allowlist AV: every entry must be a supported alg name.
 * Croaks on policy errors - an invalid allowlist is caller misuse, not
 * an invalid token. */
static void cjws_check_allowlist(pTHX_ AV *algs) {
  SSize_t i, n = av_count(algs);
  if (!n)
    croak("Crypt::JWS::verify: an algs allowlist is required");
  for (i = 0; i < n; i++) {
    SV **e = av_fetch(algs, i, 0);
    char fam;
    int bits;
    STRLEN len;
    const char *s = (e && *e && SvOK(*e)) ? SvPV_const(*e, len) : NULL;
    if (!s || !cjws_alg_parse(s, len, &fam, &bits))
      croak("Crypt::JWS::verify: unsupported alg '%s' in allowlist",
            s ? s : "(undef)");
  }
}

static int cjws_alg_in_list(pTHX_ AV *algs, const char *alg, STRLEN alglen) {
  SSize_t i, n = av_count(algs);
  for (i = 0; i < n; i++) {
    SV **e = av_fetch(algs, i, 0);
    STRLEN len;
    const char *s;
    if (!e || !*e || !SvOK(*e)) continue;
    s = SvPV_const(*e, len);
    if (len == alglen && memEQ(s, alg, len)) return 1;
  }
  return 0;
}

/* Build the compact serialization. header_hv carries everything except
 * alg (stored by the caller into the HV before the call, so extras can
 * never clobber it). Returns an owned SV. */
static SV *cjws_compact_sign(pTHX_ cjws_key *key, const char *alg,
                             STRLEN alglen, HV *header_hv,
                             const unsigned char *payload, STRLEN plen) {
  const frj_abi *J = cjws_frj(aTHX);
  SV *href = sv_2mortal(newRV_inc((SV *)header_hv));
  SV *hjson = J->encode(aTHX_ href, NULL);
  SV *out;
  STRLEN hjlen, siglen = 0, inlen;
  const char *hj;
  unsigned char *sig;

  if (!hjson)
    croak("Crypt::JWS: header JSON encoding failed");
  sv_2mortal(hjson);
  hj = SvPV_const(hjson, hjlen);

  out = newSV(cjws_b64url_encoded_len(hjlen)
            + cjws_b64url_encoded_len(plen) + 2 + 96);
  SvPOK_on(out);
  SvCUR_set(out, 0);
  SvCUR_set(out, cjws_b64url_encode(SvPVX(out),
                                    (const unsigned char *)hj, hjlen));
  sv_catpvs(out, ".");
  {
    STRLEN cur = SvCUR(out);
    SvGROW(out, cur + cjws_b64url_encoded_len(plen) + 1);
    SvCUR_set(out, cur + cjws_b64url_encode(SvPVX(out) + cur, payload, plen));
  }

  inlen = SvCUR(out);
  sig = cjws_sign_raw(aTHX_ key, alg, alglen,
                      (const unsigned char *)SvPVX(out), inlen, &siglen);
  if (!sig) {
    SvREFCNT_dec(out);
    croak("Crypt::JWS: sign failed (wrong key type for %.*s, public "
          "key, or OpenSSL error)", (int)alglen, alg);
  }
  sv_catpvs(out, ".");
  {
    STRLEN cur = SvCUR(out);
    SvGROW(out, cur + cjws_b64url_encoded_len(siglen) + 1);
    SvCUR_set(out, cur + cjws_b64url_encode(SvPVX(out) + cur, sig, siglen));
  }
  *SvEND(out) = '\0';
  OPENSSL_cleanse(sig, siglen);
  OPENSSL_free(sig);
  return out;
}

/* Split "a.b.c" into three spans. Returns 1 on exactly two dots. */
static int cjws_split3(const char *t, STRLEN tlen,
                       const char **h, STRLEN *hl,
                       const char **p, STRLEN *pl,
                       const char **s, STRLEN *sl) {
  const char *d1 = (const char *)memchr(t, '.', tlen);
  const char *d2;
  if (!d1) return 0;
  d2 = (const char *)memchr(d1 + 1, '.', (size_t)(t + tlen - d1 - 1));
  if (!d2) return 0;
  if (memchr(d2 + 1, '.', (size_t)(t + tlen - d2 - 1))) return 0;
  *h = t;       *hl = (STRLEN)(d1 - t);
  *p = d1 + 1;  *pl = (STRLEN)(d2 - d1 - 1);
  *s = d2 + 1;  *sl = (STRLEN)(t + tlen - d2 - 1);
  return 1;
}

/* Decode a header span into a hashref SV (owned), or NULL. Malformed
 * JSON must be an invalid-token condition, not an exception, and the
 * frj C entry croaks on bad input - so this one decode goes through the
 * Perl function under G_EVAL. Header decoding happens once per verify;
 * the signature crypto stays pure C. */
static SV *cjws_decode_header(pTHX_ const char *h64, STRLEN hlen) {
  SV *hjson = cjws_b64url_decode_sv(aTHX_ h64, hlen);
  SV *header = NULL;
  if (!hjson) return NULL;
  (void)cjws_frj(aTHX);   /* loads File::Raw::JSON, croaks if absent */
  {
    dSP;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(hjson);   /* hand ownership to the call frame */
    PUTBACK;
    count = call_pv("File::Raw::JSON::file_json_decode",
                    G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) {
      SV *out = POPs;
      if (SvROK(out) && SvTYPE(SvRV(out)) == SVt_PVHV)
        header = SvREFCNT_inc_simple_NN(out);
    }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
  }
  return header;
}

/* The full verify pipeline. key_sv is a Crypt::JWS::Key or a coderef
 * (called with the decoded header hashref; returns a key or undef).
 * Returns owned payload SV, or NULL for every invalid-token condition. */
static SV *cjws_compact_verify(pTHX_ SV *token_sv, SV *key_sv, AV *algs) {
  STRLEN tlen, hlen, plen, slen, alglen;
  const char *t, *h64, *p64, *s64, *alg;
  SV *header = NULL, *payload = NULL, *sig = NULL;
  SV **algsv;
  cjws_key *key = NULL;

  cjws_check_allowlist(aTHX_ algs);

  if (!SvOK(token_sv)) return NULL;
  t = SvPV_const(token_sv, tlen);
  if (!cjws_split3(t, tlen, &h64, &hlen, &p64, &plen, &s64, &slen))
    return NULL;
  if (!hlen || !slen) return NULL;

  header = cjws_decode_header(aTHX_ h64, hlen);
  if (!header) return NULL;

  algsv = hv_fetchs((HV *)SvRV(header), "alg", 0);
  if (!algsv || !*algsv || !SvOK(*algsv) || SvROK(*algsv))
    goto fail;
  alg = SvPV_const(*algsv, alglen);
  if (!cjws_alg_in_list(aTHX_ algs, alg, alglen))
    goto fail;

  if (SvROK(key_sv) && SvTYPE(SvRV(key_sv)) == SVt_PVCV) {
    /* kid routing: the resolver sees the (unverified) header */
    dSP;
    int count;
    SV *resolved = NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(header);
    PUTBACK;
    count = call_sv(key_sv, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) {
      resolved = POPs;
      if (SvOK(resolved)) SvREFCNT_inc_simple_void_NN(resolved);
      else resolved = NULL;
    }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (SvTRUE(ERRSV) || !resolved) {
      SvREFCNT_dec(resolved);
      goto fail;
    }
    /* Mortalize AFTER the FREETMPS above: the resolver may have handed
     * back a key nothing else holds, and the struct must outlive the
     * verify below. The enclosing XSUB's frame frees it. */
    sv_2mortal(resolved);
    if (!(SvROK(resolved) && sv_isobject(resolved)
          && sv_derived_from(resolved, "Crypt::JWS::Key")))
      goto fail;
    key = INT2PTR(cjws_key *, SvIV(SvRV(resolved)));
  }
  else if (SvROK(key_sv) && sv_isobject(key_sv)
           && sv_derived_from(key_sv, "Crypt::JWS::Key")) {
    key = INT2PTR(cjws_key *, SvIV(SvRV(key_sv)));
  }
  else {
    croak("Crypt::JWS::verify: key must be a Crypt::JWS::Key or a coderef");
  }

  sig = cjws_b64url_decode_sv(aTHX_ s64, slen);
  if (!sig) goto fail;

  if (!cjws_verify_raw(aTHX_ key, alg, alglen,
                       (const unsigned char *)h64,
                       (STRLEN)(s64 - 1 - h64),   /* "h64.p64" span */
                       (const unsigned char *)SvPVX(sig), SvCUR(sig)))
    goto fail;

  payload = cjws_b64url_decode_sv(aTHX_ p64, plen);

fail:
  SvREFCNT_dec(header);
  SvREFCNT_dec(sig);
  return payload;
}

#endif
