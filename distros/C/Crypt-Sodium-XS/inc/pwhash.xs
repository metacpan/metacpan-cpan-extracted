MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::pwhash

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::pwhash", 0);

  PPCODE:
  newCONSTSUB(stash, "pwhash_BYTES_MAX", newSVuv(crypto_pwhash_BYTES_MAX));
  newCONSTSUB(stash, "pwhash_argon2i_BYTES_MAX",
              newSVuv(crypto_pwhash_argon2i_BYTES_MAX));
  newCONSTSUB(stash, "pwhash_argon2id_BYTES_MAX",
              newSVuv(crypto_pwhash_argon2id_BYTES_MAX));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_BYTES_MAX",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_BYTES_MAX));
  newCONSTSUB(stash, "pwhash_BYTES_MIN", newSVuv(crypto_pwhash_BYTES_MIN));
  newCONSTSUB(stash, "pwhash_argon2i_BYTES_MIN",
              newSVuv(crypto_pwhash_argon2i_BYTES_MIN));
  newCONSTSUB(stash, "pwhash_argon2id_BYTES_MIN",
              newSVuv(crypto_pwhash_argon2id_BYTES_MIN));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_BYTES_MIN",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_BYTES_MIN));
  newCONSTSUB(stash, "pwhash_MEMLIMIT_INTERACTIVE",
              newSVuv(crypto_pwhash_MEMLIMIT_INTERACTIVE));
  newCONSTSUB(stash, "pwhash_argon2i_MEMLIMIT_INTERACTIVE",
              newSVuv(crypto_pwhash_argon2i_MEMLIMIT_INTERACTIVE));
  newCONSTSUB(stash, "pwhash_argon2id_MEMLIMIT_INTERACTIVE",
              newSVuv(crypto_pwhash_argon2id_MEMLIMIT_INTERACTIVE));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE));
  newCONSTSUB(stash, "pwhash_MEMLIMIT_MAX",
              newSVuv(crypto_pwhash_MEMLIMIT_MAX));
  newCONSTSUB(stash, "pwhash_argon2i_MEMLIMIT_MAX",
              newSVuv(crypto_pwhash_argon2i_MEMLIMIT_MAX));
  newCONSTSUB(stash, "pwhash_argon2id_MEMLIMIT_MAX",
              newSVuv(crypto_pwhash_argon2id_MEMLIMIT_MAX));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_MEMLIMIT_MAX",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MAX));
  newCONSTSUB(stash, "pwhash_MEMLIMIT_MIN",
              newSVuv(crypto_pwhash_MEMLIMIT_MIN));
  newCONSTSUB(stash, "pwhash_argon2i_MEMLIMIT_MIN",
              newSVuv(crypto_pwhash_argon2i_MEMLIMIT_MIN));
  newCONSTSUB(stash, "pwhash_argon2id_MEMLIMIT_MIN",
              newSVuv(crypto_pwhash_argon2id_MEMLIMIT_MIN));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_MEMLIMIT_MIN",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MIN));
  newCONSTSUB(stash, "pwhash_MEMLIMIT_MODERATE",
              newSVuv(crypto_pwhash_MEMLIMIT_MODERATE));
  newCONSTSUB(stash, "pwhash_argon2i_MEMLIMIT_MODERATE",
              newSVuv(crypto_pwhash_argon2i_MEMLIMIT_MODERATE));
  newCONSTSUB(stash, "pwhash_argon2id_MEMLIMIT_MODERATE",
              newSVuv(crypto_pwhash_argon2id_MEMLIMIT_MODERATE));
  newCONSTSUB(stash, "pwhash_MEMLIMIT_SENSITIVE",
              newSVuv(crypto_pwhash_MEMLIMIT_SENSITIVE));
  newCONSTSUB(stash, "pwhash_argon2i_MEMLIMIT_SENSITIVE",
              newSVuv(crypto_pwhash_argon2i_MEMLIMIT_SENSITIVE));
  newCONSTSUB(stash, "pwhash_argon2id_MEMLIMIT_SENSITIVE",
              newSVuv(crypto_pwhash_argon2id_MEMLIMIT_SENSITIVE));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE));
  newCONSTSUB(stash, "pwhash_OPSLIMIT_INTERACTIVE",
              newSVuv(crypto_pwhash_OPSLIMIT_INTERACTIVE));
  newCONSTSUB(stash, "pwhash_argon2i_OPSLIMIT_INTERACTIVE",
              newSVuv(crypto_pwhash_argon2i_OPSLIMIT_INTERACTIVE));
  newCONSTSUB(stash, "pwhash_argon2id_OPSLIMIT_INTERACTIVE",
              newSVuv(crypto_pwhash_argon2id_OPSLIMIT_INTERACTIVE));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE));
  newCONSTSUB(stash, "pwhash_OPSLIMIT_MAX",
              newSVuv(crypto_pwhash_OPSLIMIT_MAX));
  newCONSTSUB(stash, "pwhash_argon2i_OPSLIMIT_MAX",
              newSVuv(crypto_pwhash_argon2i_OPSLIMIT_MAX));
  newCONSTSUB(stash, "pwhash_argon2id_OPSLIMIT_MAX",
              newSVuv(crypto_pwhash_argon2id_OPSLIMIT_MAX));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_OPSLIMIT_MAX",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MAX));
  newCONSTSUB(stash, "pwhash_OPSLIMIT_MIN",
              newSVuv(crypto_pwhash_OPSLIMIT_MIN));
  newCONSTSUB(stash, "pwhash_argon2i_OPSLIMIT_MIN",
              newSVuv(crypto_pwhash_argon2i_OPSLIMIT_MIN));
  newCONSTSUB(stash, "pwhash_argon2id_OPSLIMIT_MIN",
              newSVuv(crypto_pwhash_argon2id_OPSLIMIT_MIN));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_OPSLIMIT_MIN",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MIN));
  newCONSTSUB(stash, "pwhash_OPSLIMIT_MODERATE",
              newSVuv(crypto_pwhash_OPSLIMIT_MODERATE));
  newCONSTSUB(stash, "pwhash_argon2i_OPSLIMIT_MODERATE",
              newSVuv(crypto_pwhash_argon2i_OPSLIMIT_MODERATE));
  newCONSTSUB(stash, "pwhash_argon2id_OPSLIMIT_MODERATE",
              newSVuv(crypto_pwhash_argon2id_OPSLIMIT_MODERATE));
  newCONSTSUB(stash, "pwhash_OPSLIMIT_SENSITIVE",
              newSVuv(crypto_pwhash_OPSLIMIT_SENSITIVE));
  newCONSTSUB(stash, "pwhash_argon2i_OPSLIMIT_SENSITIVE",
              newSVuv(crypto_pwhash_argon2i_OPSLIMIT_SENSITIVE));
  newCONSTSUB(stash, "pwhash_argon2id_OPSLIMIT_SENSITIVE",
              newSVuv(crypto_pwhash_argon2id_OPSLIMIT_SENSITIVE));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE));
  newCONSTSUB(stash, "pwhash_PASSWD_MAX", newSVuv(crypto_pwhash_PASSWD_MAX));
  newCONSTSUB(stash, "pwhash_argon2i_PASSWD_MAX",
              newSVuv(crypto_pwhash_argon2i_PASSWD_MAX));
  newCONSTSUB(stash, "pwhash_argon2id_PASSWD_MAX",
              newSVuv(crypto_pwhash_argon2id_PASSWD_MAX));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_PASSWD_MAX",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_PASSWD_MAX));
  newCONSTSUB(stash, "pwhash_PASSWD_MIN", newSVuv(crypto_pwhash_PASSWD_MIN));
  newCONSTSUB(stash, "pwhash_argon2i_PASSWD_MIN",
              newSVuv(crypto_pwhash_argon2i_PASSWD_MIN));
  newCONSTSUB(stash, "pwhash_argon2id_PASSWD_MIN",
              newSVuv(crypto_pwhash_argon2id_PASSWD_MIN));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_PASSWD_MIN",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_PASSWD_MIN));
  newCONSTSUB(stash, "pwhash_SALTBYTES", newSVuv(crypto_pwhash_SALTBYTES));
  newCONSTSUB(stash, "pwhash_argon2i_SALTBYTES",
              newSVuv(crypto_pwhash_argon2i_SALTBYTES));
  newCONSTSUB(stash, "pwhash_argon2id_SALTBYTES",
              newSVuv(crypto_pwhash_argon2id_SALTBYTES));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_SALTBYTES",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_SALTBYTES));
  newCONSTSUB(stash, "pwhash_STRBYTES", newSVuv(crypto_pwhash_STRBYTES));
  newCONSTSUB(stash, "pwhash_argon2i_STRBYTES",
              newSVuv(crypto_pwhash_argon2i_STRBYTES));
  newCONSTSUB(stash, "pwhash_argon2id_STRBYTES",
              newSVuv(crypto_pwhash_argon2id_STRBYTES));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_STRBYTES",
              newSVuv(crypto_pwhash_scryptsalsa208sha256_STRBYTES));
  newCONSTSUB(stash, "pwhash_STRPREFIX", newSVpvs(crypto_pwhash_STRPREFIX));
  newCONSTSUB(stash, "pwhash_argon2i_STRPREFIX",
              newSVpvs(crypto_pwhash_argon2i_STRPREFIX));
  newCONSTSUB(stash, "pwhash_argon2id_STRPREFIX",
              newSVpvs(crypto_pwhash_argon2id_STRPREFIX));
  newCONSTSUB(stash, "pwhash_scryptsalsa208sha256_STRPREFIX",
              newSVpvs(crypto_pwhash_scryptsalsa208sha256_STRPREFIX));
  newCONSTSUB(stash, "pwhash_PRIMITIVE", newSVpvs(crypto_pwhash_PRIMITIVE));

void pwhash_scryptsalsa208sha256_MEMLIMIT_MODERATE()
  PPCODE:
  croak("This primitive does not support MEMLIMIT_MODERATE");

void pwhash_scryptsalsa208sha256_OPSLIMIT_MODERATE()
  PPCODE:
  croak("This primitive does not support OPSLIMIT_MODERATE");

SV * pwhash( \
  SV * passphrase, \
  SV * salt, \
  STRLEN out_len = 0, \
  STRLEN opslimit = 0, \
  STRLEN memlimit = 0 \
)

  ALIAS:
  pwhash_argon2i = 1
  pwhash_argon2id = 2
  pwhash_scryptsalsa208sha256 = 3

  PREINIT:
  protmem *pw_pm = NULL;
  unsigned char *salt_buf;
  unsigned char *pw_buf;
  unsigned char *out_buf;
  STRLEN salt_len;
  STRLEN pw_len;
  STRLEN salt_req_len;
  int alg;
  size_t out_min;
  size_t out_max;
  size_t opslimit_def;
  size_t opslimit_min;
  size_t opslimit_max;
  size_t memlimit_def;
  size_t memlimit_min;
  size_t memlimit_max;
  int ret;

  CODE:
  switch(ix) {
    case 1:
      alg = crypto_pwhash_ALG_ARGON2I13;
      out_min = crypto_pwhash_argon2i_BYTES_MIN;
      out_max = crypto_pwhash_argon2i_BYTES_MAX;
      salt_req_len = crypto_pwhash_argon2i_SALTBYTES;
      opslimit_def = crypto_pwhash_argon2i_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_argon2i_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_argon2i_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_argon2i_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_argon2i_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_argon2i_MEMLIMIT_MAX;
      break;
    case 2:
      alg = crypto_pwhash_ALG_ARGON2ID13;
      out_min = crypto_pwhash_argon2id_BYTES_MIN;
      out_max = crypto_pwhash_argon2id_BYTES_MAX;
      salt_req_len = crypto_pwhash_argon2id_SALTBYTES;
      opslimit_def = crypto_pwhash_argon2id_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_argon2id_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_argon2id_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_argon2id_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_argon2id_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_argon2id_MEMLIMIT_MAX;
      break;
    case 3:
      out_min = crypto_pwhash_scryptsalsa208sha256_BYTES_MIN;
      out_max = crypto_pwhash_scryptsalsa208sha256_BYTES_MAX;
      salt_req_len = crypto_pwhash_scryptsalsa208sha256_SALTBYTES;
      opslimit_def = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MAX;
      break;
    default:
      alg = crypto_pwhash_ALG_DEFAULT;
      out_min = crypto_pwhash_BYTES_MIN;
      out_max = crypto_pwhash_BYTES_MAX;
      salt_req_len = crypto_pwhash_SALTBYTES;
      opslimit_def = crypto_pwhash_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_MEMLIMIT_MAX;
  }

  if (out_len == 0)
    /* default out length identical to what the current string default uses */
    out_len = 32;
  else {
    if (out_len < out_min || out_len > out_max)
      croak("pwhash: Invalid output length %lu", out_len);
  }
  if (opslimit == 0)
    opslimit = opslimit_def;
  else {
    if (opslimit < opslimit_min || opslimit > opslimit_max)
      croak("pwhash: Invalid opslimit %lu", opslimit);
  }
  if (memlimit == 0)
    memlimit = memlimit_def;
  else {
    if (memlimit < memlimit_min || memlimit > memlimit_max)
      croak("pwhash: Invalid memlimit %lu", memlimit);
  }

  salt_buf = (unsigned char *)SvPVbyte(salt, salt_len);
  if (salt_len != salt_req_len)
    croak("pwhash: Invalid salt length %lu", salt_len);

  if (sv_derived_from(passphrase, MEMVAULT_CLASS)) {
    pw_pm = protmem_get(aTHX_ passphrase, MEMVAULT_CLASS);
    pw_buf = pw_pm->pm_ptr;
    pw_len = pw_pm->size;
  }
  else
    pw_buf = (unsigned char *)SvPVbyte(passphrase, pw_len);

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("pwhash: Failed to allocate protmem");
  out_buf[out_len] = '\0';

  if (pw_pm && protmem_grant(aTHX_ pw_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("pwhash: Failed to grant passphrase protmem RO");
  }

  if (ix == 3)
    ret = crypto_pwhash_scryptsalsa208sha256(out_buf, out_len, (char *)pw_buf,
                                             pw_len, salt_buf, opslimit, memlimit);
  else
    ret = crypto_pwhash(out_buf, out_len, (char *)pw_buf, pw_len,
                        salt_buf, opslimit, memlimit, alg);

  if (pw_pm && protmem_release(aTHX_ pw_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("pwhash: Failed to release passphrase protmem RO");
  }

  if (ret != 0) {
    Safefree(out_buf);
    croak("pwhash: pwhash failed (out of memory?)");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * pwhash_salt()

  ALIAS:
  pwhash_argon2i_salt = 1
  pwhash_argon2id_salt = 2
  pwhash_scryptsalsa208sha256_salt = 3

  PREINIT:
  unsigned char *out_buf;
  unsigned int out_len;

  CODE:
  switch(ix) {
    case 1:
      out_len = crypto_pwhash_argon2i_SALTBYTES;
      break;
    case 2:
      out_len = crypto_pwhash_argon2id_SALTBYTES;
      break;
    case 3:
      out_len = crypto_pwhash_scryptsalsa208sha256_SALTBYTES;
      break;
    default:
      out_len = crypto_pwhash_SALTBYTES;
  }

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("Failed to allocate memory");
  out_buf[out_len] = '\0';

  randombytes_buf(out_buf, out_len);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * pwhash_str(SV * passphrase, STRLEN opslimit = 0, STRLEN memlimit = 0)

  ALIAS:
  pwhash_argon2i_str = 1
  pwhash_argon2id_str = 2
  pwhash_scryptsalsa208sha256_str = 3

  PREINIT:
  protmem *pw_pm = NULL;
  unsigned char *pw_buf;
  unsigned char *out_buf;
  STRLEN pw_len;
  int alg;
  size_t out_len;
  size_t opslimit_def;
  size_t opslimit_min;
  size_t opslimit_max;
  size_t memlimit_def;
  size_t memlimit_min;
  size_t memlimit_max;
  int ret;

  CODE:
  switch(ix) {
    case 1:
      alg = crypto_pwhash_ALG_ARGON2I13;
      out_len = crypto_pwhash_argon2i_STRBYTES;
      opslimit_def = crypto_pwhash_argon2i_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_argon2i_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_argon2i_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_argon2i_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_argon2i_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_argon2i_MEMLIMIT_MAX;
      break;
    case 2:
      alg = crypto_pwhash_ALG_ARGON2ID13;
      out_len = crypto_pwhash_argon2id_STRBYTES;
      opslimit_def = crypto_pwhash_argon2id_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_argon2id_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_argon2id_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_argon2id_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_argon2id_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_argon2id_MEMLIMIT_MAX;
      break;
    case 3:
      out_len = crypto_pwhash_scryptsalsa208sha256_STRBYTES;
      opslimit_def = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MAX;
      break;
    default:
      alg = crypto_pwhash_ALG_DEFAULT;
      out_len = crypto_pwhash_STRBYTES;
      opslimit_def = crypto_pwhash_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_MEMLIMIT_MAX;
  }

  if (opslimit == 0)
    opslimit = opslimit_def;
  else {
    if (opslimit < opslimit_min || opslimit > opslimit_max)
      croak("pwhash_str: Invalid opslimit %lu", opslimit);
  }
  if (memlimit == 0)
    memlimit = memlimit_def;
  else {
    if (memlimit < memlimit_min || memlimit > memlimit_max)
      croak("pwhash_str: Invalid memlimit %lu", memlimit);
  }

  if (sv_derived_from(passphrase, MEMVAULT_CLASS)) {
    pw_pm = protmem_get(aTHX_ passphrase, MEMVAULT_CLASS);
    pw_buf = pw_pm->pm_ptr;
    pw_len = pw_pm->size;
  }
  else
    pw_buf = (unsigned char *)SvPVbyte(passphrase, pw_len);

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("pwhash_str: Failed to allocate protmem");
  out_buf[out_len] = '\0';

  if (pw_pm && protmem_grant(aTHX_ pw_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("pwhash_str: Failed to grant passphrase protmem RO");
  }

  if (ix == 3)
    ret = crypto_pwhash_scryptsalsa208sha256_str((char *)out_buf, (char *)pw_buf,
                                                 pw_len, opslimit, memlimit);
  else
    ret = crypto_pwhash_str_alg((char *)out_buf, (char *)pw_buf, pw_len,
                                opslimit, memlimit, alg);

  /* unlike the rest of the api, no argument for actual output length. >:| */
  out_len = strlen((char *)out_buf);

  if (pw_pm && protmem_release(aTHX_ pw_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("pwhash_str: Failed to release passphrase protmem RO");
  }

  if (ret != 0) {
    Safefree(out_buf);
    croak("pwhash_str: pwhash_str failed (out of memory?)");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

void pwhash_str_needs_rehash(SV * str, STRLEN opslimit = 0, STRLEN memlimit = 0)

  ALIAS:
  pwhash_argon2i_str_needs_rehash = 1
  pwhash_argon2id_str_needs_rehash = 2
  pwhash_scryptsalsa208sha256_str_needs_rehash = 3

  PREINIT:
  protmem *str_pm = NULL;
  char *str_buf;
  size_t opslimit_def;
  size_t opslimit_min;
  size_t opslimit_max;
  size_t memlimit_def;
  size_t memlimit_min;
  size_t memlimit_max;
  STRLEN str_len;
  int ret;
  int (*func)(const char *, unsigned long long, size_t);

  PPCODE:
  switch(ix) {
    case 1:
      opslimit_def = crypto_pwhash_argon2i_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_argon2i_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_argon2i_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_argon2i_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_argon2i_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_argon2i_MEMLIMIT_MAX;
      func = crypto_pwhash_argon2i_str_needs_rehash;
      break;
    case 2:
      opslimit_def = crypto_pwhash_argon2id_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_argon2id_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_argon2id_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_argon2id_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_argon2id_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_argon2id_MEMLIMIT_MAX;
      func = crypto_pwhash_argon2id_str_needs_rehash;
      break;
    case 3:
      opslimit_def = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MAX;
      func = crypto_pwhash_scryptsalsa208sha256_str_needs_rehash;
      break;
    default:
      opslimit_def = crypto_pwhash_OPSLIMIT_INTERACTIVE;
      opslimit_min = crypto_pwhash_OPSLIMIT_MIN;
      opslimit_max = crypto_pwhash_OPSLIMIT_MAX;
      memlimit_def = crypto_pwhash_MEMLIMIT_INTERACTIVE;
      memlimit_min = crypto_pwhash_MEMLIMIT_MIN;
      memlimit_max = crypto_pwhash_MEMLIMIT_MAX;
      func = crypto_pwhash_str_needs_rehash;
  }

  if (opslimit == 0)
    opslimit = opslimit_def;
  else {
    if (opslimit < opslimit_min || opslimit > opslimit_max)
      croak("pwhash_str_needs_rehash: Invalid opslimit %lu", opslimit);
  }
  if (memlimit == 0)
    memlimit = memlimit_def;
  else {
    if (memlimit < memlimit_min || memlimit > memlimit_max)
      croak("pwhash_str_needs_rehash: Invalid memlimit %lu", memlimit);
  }

  if (sv_derived_from(str, MEMVAULT_CLASS)) {
    str_pm = protmem_get(aTHX_ str, MEMVAULT_CLASS);
    str_buf = str_pm->pm_ptr;
    str_len = str_pm->size;
  }
  else
    str_buf = SvPVbyte(str, str_len);
  if (str_buf[str_len] != '\0')
    croak("pwhash_str_needs_rehash: Invalid hash string");

  if (str_pm && protmem_grant(aTHX_ str_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("pwhash_str_needs_rehash: Failed to grant str protmem RO");

  ret = func(str_buf, opslimit, memlimit);

  if (str_pm)
    if (protmem_release(aTHX_ str_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
      croak("pwhash_str_needs_rehash: Failed to release str protmem RO");

  if (ret == 0)
    XSRETURN_NO;

  XSRETURN_YES;

void pwhash_verify(SV * str, SV * passphrase)

  ALIAS:
  pwhash_argon2i_verify = 1
  pwhash_argon2id_verify = 2
  pwhash_scryptsalsa208sha256_verify = 3

  PREINIT:
  protmem *pw_pm = NULL;
  unsigned char *pw_buf;
  unsigned char *str_buf;
  unsigned char *tmp_buf = NULL;
  STRLEN pw_len;
  STRLEN str_len;
  int ret = 0;
  int (*func)(const char *, const char * const, unsigned long long);

  CODE:
  switch(ix) {
    case 1:
      func = crypto_pwhash_argon2i_str_verify;
      break;
    case 2:
      func = crypto_pwhash_argon2id_str_verify;
      break;
    case 3:
      func = crypto_pwhash_scryptsalsa208sha256_str_verify;
      break;
    default:
      func = crypto_pwhash_str_verify;
  }

  if (sv_derived_from(passphrase, MEMVAULT_CLASS)) {
    pw_pm = protmem_get(aTHX_ passphrase, MEMVAULT_CLASS);
    pw_buf = pw_pm->pm_ptr;
    pw_len = pw_pm->size;
  }
  else
    pw_buf = (unsigned char *)SvPVbyte(passphrase, pw_len);

  str_buf = (unsigned char *)SvPVbyte(str, str_len);
  if (str_buf[str_len] != '\0')
    croak("pwhash_verify: Invalid hash string");

  if (pw_pm && protmem_grant(aTHX_ pw_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (tmp_buf) {
      free(tmp_buf);
      tmp_buf = NULL;
    }
    croak("pwhash_verify: Failed to grant passphrase protmem RO");
  }

  ret = func((char *)str_buf, (char *)pw_buf, pw_len);

  if (pw_pm && protmem_release(aTHX_ pw_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (tmp_buf) {
      free(tmp_buf);
      tmp_buf = NULL;
    }
    croak("pwhash_verify: Failed to release passphrase protmem RO");
  }

  if (ret == 0)
    XSRETURN_YES;

  XSRETURN_NO;

  CLEANUP:
  if (tmp_buf)
    free(tmp_buf);
