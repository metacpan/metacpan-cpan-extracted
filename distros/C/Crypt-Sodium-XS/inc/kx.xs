=for documentation

Note that for kx, aliases are provided for the current default primitive
(x25519blake2b) even though libsodium does not provide algorithm-specific
functions.

=cut

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::kx

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::kx", 0);

  PPCODE:
  newCONSTSUB(stash, "kx_PUBLICKEYBYTES", newSVuv(crypto_kx_PUBLICKEYBYTES));
  newCONSTSUB(stash, "kx_x25519blake2b_PUBLICKEYBYTES",
              newSVuv(crypto_kx_PUBLICKEYBYTES));
  newCONSTSUB(stash, "kx_SECRETKEYBYTES", newSVuv(crypto_kx_SECRETKEYBYTES));
  newCONSTSUB(stash, "kx_x25519blake2b_SECRETKEYBYTES",
              newSVuv(crypto_kx_SECRETKEYBYTES));
  newCONSTSUB(stash, "kx_SEEDBYTES", newSVuv(crypto_kx_SEEDBYTES));
  newCONSTSUB(stash, "kx_x25519blake2b_SEEDBYTES",
              newSVuv(crypto_kx_SEEDBYTES));
  newCONSTSUB(stash, "kx_SESSIONKEYBYTES", newSVuv(crypto_kx_SESSIONKEYBYTES));
  newCONSTSUB(stash, "kx_x25519blake2b_SESSIONKEYBYTES",
              newSVuv(crypto_kx_SESSIONKEYBYTES));
  newCONSTSUB(stash, "kx_PRIMITIVE", newSVpvs(crypto_kx_PRIMITIVE));

void kx_keypair(SV * seed = &PL_sv_undef, SV * flags = &PL_sv_undef)

  ALIAS:
  kx_x25519blake2b_keypair = 1

  PREINIT:
  protmem *sk_pm;
  SV *pk_sv;
  unsigned char *pk_buf;
  unsigned int sk_flags = g_protmem_flags_key_default;

  PPCODE:
  PERL_UNUSED_VAR(ix);

  if (SvOK(flags))
    sk_flags = SvUV(flags);

  Newx(pk_buf, crypto_kx_PUBLICKEYBYTES + 1, unsigned char);
  if (pk_buf == NULL)
    croak("kx_keypair: Failed to allocate memory");
  pk_buf[crypto_kx_PUBLICKEYBYTES] = '\0';

  if (!SvOK(seed)) {
    sk_pm = protmem_init(aTHX_ crypto_kx_SECRETKEYBYTES, sk_flags);

    if (sk_pm == NULL) {
      Safefree(pk_buf);
      croak("kx_keypair: Failed to allocate protmem");
    }
    crypto_kx_keypair(pk_buf, sk_pm->pm_ptr);

    if (protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("kx_keypair: Failed to release sk protmem RW");
    }
  }
  else {
    /* from seed */
    protmem *seed_pm = NULL;
    unsigned char *seed_buf;
    STRLEN seed_len;

    if (sv_derived_from(ST(0), MEMVAULT_CLASS)) {
      seed_pm = protmem_get(aTHX_ ST(0), MEMVAULT_CLASS);
      seed_buf = seed_pm->pm_ptr;
      seed_len = seed_pm->size;
    }
    else
      seed_buf = (unsigned char *)SvPVbyte(ST(0), seed_len);

    if (seed_len != crypto_kx_SEEDBYTES) {
      Safefree(pk_buf);
      croak("kx_keypair: Invalid seed length: %lu", seed_len);
    }

    sk_pm = protmem_init(aTHX_ crypto_kx_SECRETKEYBYTES, sk_flags);
    if (sk_pm == NULL) {
      Safefree(pk_buf);
      croak("kx_keypair: Failed to allocate protmem");
    }
    /* use flags from seed_pm (if there was one)? */

    if (seed_pm && protmem_grant(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("kx_keypair: Failed to grant seed protmem RO");
    }

    crypto_kx_seed_keypair(pk_buf, sk_pm->pm_ptr, seed_buf);

    if (seed_pm && protmem_release(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("kx_keypair: Failed to release seed protmem RO");
    }

    if (protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("kx_keypair: Failed to release sk protmem RW");
    }
  }

  pk_sv = newSV(0);
  sv_usepvn_flags(pk_sv, (char *)pk_buf, crypto_kx_PUBLICKEYBYTES, SV_HAS_TRAILING_NUL);
  mXPUSHs(pk_sv);
  mXPUSHs(protmem_to_sv(aTHX_ sk_pm, MEMVAULT_CLASS));
  XSRETURN(2);

void kx_client_session_keys(SV * cpk, SV * csk, SV * spk, SV * flags = &PL_sv_undef)

  ALIAS:
  kx_x25519blake2b_client_session_keys = 1

  PREINIT:
  protmem *rx;
  protmem *tx;
  protmem *csk_pm = NULL;
  unsigned char * cpk_buf;
  unsigned char * csk_buf;
  unsigned char * spk_buf;
  STRLEN cpk_len;
  STRLEN csk_len;
  STRLEN spk_len;
  unsigned int key_flags = g_protmem_flags_key_default;
  int ret;

  PPCODE:
  PERL_UNUSED_VAR(ix);

  if (SvOK(flags))
    key_flags = SvUV(flags);

  cpk_buf = (unsigned char *)SvPVbyte(cpk, cpk_len);
  if (cpk_len != crypto_kx_PUBLICKEYBYTES)
    croak("kx_client_session_keys: Invalid public key length %lu", cpk_len);

  if (sv_derived_from(csk, MEMVAULT_CLASS)) {
    csk_pm = protmem_get(aTHX_ csk, MEMVAULT_CLASS);
    csk_buf = csk_pm->pm_ptr;
    csk_len = csk_pm->size;
  }
  else
    csk_buf = (unsigned char *)SvPVbyte(csk, csk_len);
  if (csk_len != crypto_kx_SECRETKEYBYTES)
    croak("kx_client_session_keys: Invalid secret key length %lu", csk_len);

  spk_buf = (unsigned char *)SvPVbyte(spk, spk_len);
  if (spk_len != crypto_kx_PUBLICKEYBYTES)
    croak("kx_client_session_keys: Invalid public key length %lu", spk_len);

  rx = protmem_init(aTHX_ crypto_kx_SESSIONKEYBYTES, key_flags);
  if (rx == NULL)
    croak("kx_client_session_keys: Failed to allocate rx protmem");
  if (csk_pm)
    rx->flags = csk_pm->flags;

  tx = protmem_init(aTHX_ crypto_kx_SESSIONKEYBYTES, key_flags);
  if (tx == NULL) {
    protmem_free(aTHX_ rx);
    croak("kx_client_session_keys: Failed to allocate tx protmem");
  }
  if (csk_pm)
    tx->flags = csk_pm->flags;

  if (csk_pm)
    if (protmem_grant(aTHX_ csk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ rx);
      protmem_free(aTHX_ tx);
      croak("kx_client_session_keys: Failed to grant csk protmem RO");
    }

  ret = crypto_kx_client_session_keys(rx->pm_ptr, tx->pm_ptr,
                                      cpk_buf, csk_buf, spk_buf);

  if (csk_pm && protmem_release(aTHX_ csk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ rx);
    protmem_free(aTHX_ tx);
    croak("kx_client_session_keys: Failed to release csk protmem RO");
  }

  if (protmem_release(aTHX_ rx, PROTMEM_FLAG_MPROTECT_RW) != 0
      || protmem_release(aTHX_ tx, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ rx);
    protmem_free(aTHX_ tx);
    croak("kx_client_session_keys: Failed to release rx/tx protmem RW");
  }

  if (ret != 0) {
    protmem_free(aTHX_ rx);
    protmem_free(aTHX_ tx);
    croak("kx_client_session_keys: Failed to generate session keys (invalid server pubkey?)");
  }

  mXPUSHs(protmem_to_sv(aTHX_ rx, MEMVAULT_CLASS));
  mXPUSHs(protmem_to_sv(aTHX_ tx, MEMVAULT_CLASS));
  XSRETURN(2);

void kx_server_session_keys(SV * spk, SV * ssk, SV * cpk, SV * flags = &PL_sv_undef)

  ALIAS:
  kx_x25519blake2b_server_session_keys = 1

  PREINIT:
  protmem *rx;
  protmem *tx;
  protmem *ssk_pm = NULL;
  unsigned char * spk_buf;
  unsigned char * ssk_buf;
  unsigned char * cpk_buf;
  STRLEN spk_len;
  STRLEN ssk_len;
  STRLEN cpk_len;
  unsigned int key_flags = g_protmem_flags_key_default;
  int ret;

  PPCODE:
  PERL_UNUSED_VAR(ix);

  if (SvOK(flags))
    key_flags = SvUV(flags);

  spk_buf = (unsigned char *)SvPVbyte(spk, spk_len);
  if (spk_len != crypto_kx_PUBLICKEYBYTES)
    croak("kx_server_session_keys: Invalid public key length %lu", spk_len);

  if (sv_derived_from(ssk, MEMVAULT_CLASS)) {
    ssk_pm = protmem_get(aTHX_ ssk, MEMVAULT_CLASS);
    ssk_buf = ssk_pm->pm_ptr;
    ssk_len = ssk_pm->size;
  }
  else
    ssk_buf = (unsigned char *)SvPVbyte(ssk, ssk_len);
  if (ssk_len != crypto_kx_SECRETKEYBYTES)
    croak("kx_server_session_keys: Invalid secret key length %lu", ssk_len);

  cpk_buf = (unsigned char *)SvPVbyte(cpk, cpk_len);
  if (cpk_len != crypto_kx_PUBLICKEYBYTES)
    croak("kx_server_session_keys: Invalid public key length %lu", cpk_len);

  rx = protmem_init(aTHX_ crypto_kx_SESSIONKEYBYTES, key_flags);
  if (rx == NULL)
    croak("kx_server_session_keys: Failed to allocate rx protmem");
  if (ssk_pm)
    rx->flags = ssk_pm->flags;

  tx = protmem_init(aTHX_ crypto_kx_SESSIONKEYBYTES, key_flags);
  if (tx == NULL) {
    protmem_free(aTHX_ rx);
    croak("kx_server_session_keys: Failed to allocate tx protmem");
  }
  if (ssk_pm)
    tx->flags = ssk_pm->flags;

  if (ssk_pm && protmem_grant(aTHX_ ssk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ rx);
    protmem_free(aTHX_ tx);
    croak("kx_server_session_keys: Failed to grant ssk protmem RO");
  }

  ret = crypto_kx_server_session_keys(rx->pm_ptr, tx->pm_ptr,
                                      spk_buf, ssk_buf, cpk_buf);

  if (ssk_pm && protmem_release(aTHX_ ssk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ rx);
    protmem_free(aTHX_ tx);
    croak("kx_server_session_keys: Failed to release ssk protmem RO");
  }

  if (protmem_release(aTHX_ rx, PROTMEM_FLAG_MPROTECT_RW) != 0
      || protmem_release(aTHX_ tx, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ rx);
    protmem_free(aTHX_ tx);
    croak("kx_server_session_keys: Failed to release rx/tx protmem RW");
  }

  if (ret != 0) {
    protmem_free(aTHX_ rx);
    protmem_free(aTHX_ tx);
    croak("kx_server_session_keys: Failed to generate session keys (invalid client pubkey?)");
  }

  mXPUSHs(protmem_to_sv(aTHX_ rx, MEMVAULT_CLASS));
  mXPUSHs(protmem_to_sv(aTHX_ tx, MEMVAULT_CLASS));
  XSRETURN(2);
