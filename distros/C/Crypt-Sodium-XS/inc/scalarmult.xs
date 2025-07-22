MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::scalarmult

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::scalarmult", 0);

  PPCODE:
  newCONSTSUB(stash, "scalarmult_BYTES",
              newSVuv(crypto_scalarmult_BYTES));
  newCONSTSUB(stash, "scalarmult_SCALARBYTES",
              newSVuv(crypto_scalarmult_SCALARBYTES));
  newCONSTSUB(stash, "scalarmult_x25519_BYTES",
              newSVuv(crypto_scalarmult_BYTES));
  newCONSTSUB(stash, "scalarmult_x25519_SCALARBYTES",
              newSVuv(crypto_scalarmult_SCALARBYTES));
  newCONSTSUB(stash, "scalarmult_ed25519_BYTES",
              newSVuv(crypto_scalarmult_ed25519_BYTES));
  newCONSTSUB(stash, "scalarmult_ed25519_SCALARBYTES",
              newSVuv(crypto_scalarmult_ed25519_SCALARBYTES));
#ifdef SODIUM_HAS_RISTRETTO255
  newCONSTSUB(stash, "scalarmult_ristretto255_BYTES",
              newSVuv(crypto_scalarmult_ristretto255_BYTES));
  newCONSTSUB(stash, "scalarmult_ristretto255_SCALARBYTES",
              newSVuv(crypto_scalarmult_ristretto255_SCALARBYTES));
  newCONSTSUB(stash, "scalarmult_ristretto255_available", &PL_sv_yes);
#else
  newCONSTSUB(stash, "scalarmult_ristretto255_available", &PL_sv_no);
#endif

SV * scalarmult_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  scalarmult_ed25519_keygen = 1
  scalarmult_ristretto255_keygen = 2
  scalarmult_x25519_keygen = 99

  PREINIT:
  protmem *new_pm;
  unsigned int new_flags = g_protmem_flags_key_default;

  CODE:
  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);

  switch(ix) {
    case 1:
      new_pm = protmem_init(aTHX_ crypto_core_ed25519_SCALARBYTES, new_flags);
      if (new_pm == NULL)
        croak("scalarmult_ed25519_keygen: Failed to allocate protmem");
      crypto_core_ed25519_scalar_random(new_pm->pm_ptr);
      if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
        croak("scalarmult_ed25519_keygen: Failed to release protmem RW");
      }

      RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);
      break;
    case 2:
#ifdef SODIUM_HAS_RISTRETTO255
      new_pm = protmem_init(aTHX_ crypto_core_ed25519_SCALARBYTES, new_flags);
      if (new_pm == NULL)
        croak("scalarmult_ed25519_keygen: Failed to allocate protmem");
      crypto_core_ristretto255_scalar_random(new_pm->pm_ptr);
      if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
        croak("scalarmult_ed25519_keygen: Failed to release protmem RW");
      }

      RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);
#else
      croak("ristretto255 not supported by this version of libsodium");
#endif
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_scalarmult_SCALARBYTES, flags);
  }

  OUTPUT:
  RETVAL

SV * scalarmult_base(SV * sk)

  ALIAS:
  scalarmult_ed25519_base = 1
  scalarmult_ed25519_base_noclamp = 2
  scalarmult_ristretto255_base = 3
  scalarmult_x25519_base = 99

  PREINIT:
  protmem *sk_pm = NULL;
  int ret;
  unsigned char *sk_buf;
  unsigned char *out_buf;
  STRLEN out_len;
  STRLEN sk_len;
  STRLEN sk_req_len;

  CODE:
  switch(ix) {
    case 1:
      /* fallthrough */
    case 2:
      out_len = crypto_scalarmult_ed25519_SCALARBYTES;
      sk_req_len = crypto_scalarmult_ed25519_BYTES;
      break;
    case 3:
#ifdef SODIUM_HAS_RISTRETTO255
      out_len = crypto_scalarmult_ristretto255_SCALARBYTES;
      sk_req_len = crypto_scalarmult_ristretto255_BYTES;
#else
      croak("ristretto255 not supported by this version of libsodium");
#endif
      break;
    default:
      out_len = crypto_scalarmult_SCALARBYTES;
      sk_req_len = crypto_scalarmult_BYTES;
  }

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("scalarmult_base: Invalid key length %lu", sk_len);

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("scalarmult_base: Failed to allocate memory");
  out_buf[out_len] = '\0';

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("scalarmult_base: Failed to grant sk protmem RO");

  switch(ix) {
    case 1:
      ret = crypto_scalarmult_ed25519_base(out_buf, sk_buf);
      break;
    case 2:
      ret = crypto_scalarmult_ed25519_base_noclamp(out_buf, sk_buf);
      break;
    case 3:
      ret = crypto_scalarmult_ristretto255_base(out_buf, sk_buf);
      break;
    default:
      ret = crypto_scalarmult_base(out_buf, sk_buf);
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("scalarmult_base: Failed to release sk protmem RO");
  }

  if (ret != 0) {
    Safefree(out_buf);
    croak("scalarmult_base: Invalid sk: is 0");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * scalarmult(SV * sk, SV * pk, SV * flags = &PL_sv_undef)

  ALIAS:
  scalarmult_ed25519 = 1
  scalarmult_ed25519_noclamp = 2
  scalarmult_ristretto255 = 3
  scalarmult_x25519 = 99

  PREINIT:
  protmem *sk_pm = NULL;
  protmem *ss_pm;
  unsigned char *sk_buf;
  unsigned char *pk_buf;
  STRLEN sk_len;
  STRLEN sk_req_len;
  STRLEN pk_len;
  STRLEN pk_req_len;
  STRLEN ss_len;
  unsigned int sk_flags = g_protmem_flags_key_default;
  int ret;

  CODE:
  switch(ix) {
    case 1:
      /* fallthrough */
    case 2:
      pk_req_len = crypto_scalarmult_ed25519_SCALARBYTES;
      sk_req_len = crypto_scalarmult_ed25519_SCALARBYTES;
      ss_len = crypto_scalarmult_ed25519_BYTES;
      break;
    case 3:
#ifdef SODIUM_HAS_RISTRETTO255
      pk_req_len = crypto_scalarmult_ristretto255_SCALARBYTES;
      sk_req_len = crypto_scalarmult_ristretto255_SCALARBYTES;
      ss_len = crypto_scalarmult_ristretto255_BYTES;
#else
      croak("ristretto255 not supported by this version of libsodium");
#endif
      break;
    default:
      pk_req_len = crypto_scalarmult_SCALARBYTES;
      sk_req_len = crypto_scalarmult_SCALARBYTES;
      ss_len = crypto_scalarmult_BYTES;
  }
  SvGETMAGIC(flags);
  if (SvOK(flags))
    sk_flags = SvUV_nomg(flags);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("scalarmult: Invalid secret key lenth %lu", sk_len);

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("scalarmult: Invalid public key lenth %lu", pk_len);

  ss_pm = protmem_init(aTHX_ ss_len, sk_flags);
  if (ss_pm == NULL)
    croak("scalarmult: Failed to allocate protmem");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ ss_pm);
    croak("scalarmult: Failed to grant sk protmem RO");
  }

  switch(ix) {
    case 1:
      ret = crypto_scalarmult_ed25519(ss_pm->pm_ptr, sk_buf, pk_buf);
      break;
    case 2:
      ret = crypto_scalarmult_ed25519_noclamp(ss_pm->pm_ptr, sk_buf, pk_buf);
      break;
    case 3:
      ret = crypto_scalarmult_ristretto255(ss_pm->pm_ptr, sk_buf, pk_buf);
      break;
    default:
      ret = crypto_scalarmult(ss_pm->pm_ptr, sk_buf, pk_buf);
  }

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
    switch(ix) {
      case 1:
        /* fallthrough */
      case 2:
        croak("scalarmult: sk is 0 or pk is not on the curve, not on the main subgroup, is a point of small order, or is not provided in canonical form");
        break;
      default:
        croak("scalarmult: Unknown failure");
    }
    croak("scalarmult: Failed to scalarmult");
  }

  RETVAL = protmem_to_sv(aTHX_ ss_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL
