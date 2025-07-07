MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::Base64

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::Base64", 0);

  PPCODE:
  newCONSTSUB(stash, "BASE64_VARIANT_ORIGINAL",
              newSVuv(sodium_base64_VARIANT_ORIGINAL));
  newCONSTSUB(stash, "BASE64_VARIANT_ORIGINAL_NO_PADDING",
              newSVuv(sodium_base64_VARIANT_ORIGINAL_NO_PADDING));
  newCONSTSUB(stash, "BASE64_VARIANT_URLSAFE",
              newSVuv(sodium_base64_VARIANT_URLSAFE));
  newCONSTSUB(stash, "BASE64_VARIANT_URLSAFE_NO_PADDING",
              newSVuv(sodium_base64_VARIANT_URLSAFE_NO_PADDING));
  XSRETURN_YES;

SV * sodium_bin2base64(SV * bytes, int variant = sodium_base64_VARIANT_URLSAFE_NO_PADDING)

  PREINIT:
  char *bytes_buf;
  char *out_buf;
  STRLEN bytes_len;
  STRLEN out_len;

  CODE:
  switch (variant) {
    case sodium_base64_VARIANT_ORIGINAL: /* fallthrough */
    case sodium_base64_VARIANT_ORIGINAL_NO_PADDING: /* fallthrough */
    case sodium_base64_VARIANT_URLSAFE: /* fallthrough */
    case sodium_base64_VARIANT_URLSAFE_NO_PADDING:
      break;
    default:
      croak("Invalid base64 variant");
  }

  bytes_buf = SvPVbyte(bytes, bytes_len);
  out_len = sodium_base64_encoded_len(bytes_len, variant);
  Newx(out_buf, out_len, char);
  if (out_buf == NULL)
    croak("Failed to allocate memory");
  out_buf[out_len - 1] = '\0';
  sodium_bin2base64(out_buf, out_len, (unsigned char *)bytes_buf,
                    bytes_len, variant);
  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, out_buf, out_len - 1, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * sodium_base642bin(SV * bytes, int variant = sodium_base64_VARIANT_URLSAFE_NO_PADDING)

  PREINIT:
  char *bytes_buf;
  char *out_buf;
  STRLEN bytes_len;
  STRLEN out_len;

  CODE:
  switch (variant) {
    case sodium_base64_VARIANT_ORIGINAL: /* fallthrough */
    case sodium_base64_VARIANT_ORIGINAL_NO_PADDING: /* fallthrough */
    case sodium_base64_VARIANT_URLSAFE: /* fallthrough */
    case sodium_base64_VARIANT_URLSAFE_NO_PADDING:
      break;
    default:
      croak("Invalid base64 variant");
  }

  bytes_buf = SvPVbyte(bytes, bytes_len);
  /* should check for overflow... */
  out_len = ((bytes_len + 3) & ~3) / 4 * 3;
  Newx(out_buf, out_len + 1, char);
  if (out_buf == NULL)
    croak("Failed to allocate memory");
  out_buf[out_len] = '\0';
  sodium_base642bin((unsigned char *)out_buf, out_len + 1, bytes_buf, bytes_len,
                    NULL, &out_len, NULL, variant);
  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL
