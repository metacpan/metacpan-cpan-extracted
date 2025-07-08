MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::scalarmult

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::scalarmult", 0);

  PPCODE:
  newCONSTSUB(stash, "scalarmult_BYTES", newSVuv(crypto_scalarmult_BYTES));
  newCONSTSUB(stash, "scalarmult_SCALARBYTES",
              newSVuv(crypto_scalarmult_SCALARBYTES));

SV * scalarmult_keygen(SV * flags = &PL_sv_undef)

  CODE:
  RETVAL = sv_keygen(aTHX_ crypto_scalarmult_SCALARBYTES, flags);

  OUTPUT:
  RETVAL

SV * scalarmult_base(SV * sk)

  PREINIT:
  protmem *sk_pm = NULL;
  unsigned char *sk_buf;
  unsigned char *out_buf;
  STRLEN sk_len;

  CODE:
  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != crypto_scalarmult_BYTES)
    croak("scalarmult_base: Invalid key length %lu", sk_len);

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("scalarmult_base: Failed to grant sk protmem RO");

  Newx(out_buf, crypto_scalarmult_SCALARBYTES + 1, unsigned char);
  if (out_buf == NULL) {
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("scalarmult_base: Failed to allocate memory");
  }
  out_buf[crypto_scalarmult_SCALARBYTES] = '\0';

  crypto_scalarmult_base(out_buf, sk_buf);

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("scalarmult_base: Failed to release sk protmem RO");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_scalarmult_SCALARBYTES,
                  SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * scalarmult(SV * sk, SV * pk, SV * flags = &PL_sv_undef)

  PREINIT:
  protmem *sk_pm = NULL;
  protmem *ss_pm;
  unsigned char *sk_buf;
  unsigned char *pk_buf;
  STRLEN sk_len;
  STRLEN pk_len;
  unsigned int sk_flags = g_protmem_flags_key_default;
  int ret;

  CODE:
  if (SvOK(flags))
    sk_flags = SvUV(flags);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != crypto_scalarmult_SCALARBYTES)
    croak("scalarmult: Invalid secret key lenth %lu", sk_len);

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != crypto_scalarmult_SCALARBYTES)
    croak("scalarmult: Invalid public key lenth %lu", pk_len);

  ss_pm = protmem_init(aTHX_ crypto_scalarmult_BYTES, sk_flags);
  if (ss_pm == NULL)
    croak("scalarmult: Failed to allocate protmem");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ ss_pm);
    croak("scalarmult: Failed to grant sk protmem RO");
  }

  ret = crypto_scalarmult(ss_pm->pm_ptr, sk_buf, pk_buf);

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ ss_pm);
    croak("scalarmult: Failed to release sk protmem RO");
  }

  if (protmem_release(aTHX_ ss_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ ss_pm);
    croak("scalarmult: Failed to protect memvault");
  }

  if (ret != 0) {
    protmem_free(aTHX_ ss_pm);
    croak("scalarmult: Failed to calculate shared secret");
  }

  RETVAL = protmem_to_sv(aTHX_ ss_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL
