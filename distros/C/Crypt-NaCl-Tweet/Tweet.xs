#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "patchlevel.h"
#include "ppport.h"

#include "tweetnacl.h"

#define xNEWX(x, n, t) Newx(x, n + 1, t); \
  if (x == NULL) \
    croak("Out of memory"); \
  x[n] = '\0';

static const unsigned char salsa_sigma[16] = "expand 32-byte k";

/* should be impossible to call this. provided for the symbol only */
void randombytes(unsigned char *out, unsigned long long len) {
  croak("Unreachable");
}

int sign_keypair(unsigned char *pk, unsigned char *sk)
{
  unsigned char d[64];
  long long p[4][16];
  int i;

  crypto_hash(d, sk, 32);
  d[0] &= 248;
  d[31] &= 127;
  d[31] |= 64;

  scalarbase(p,d);
  pack(pk,p);

  for (i = 0; i < 32; ++i)
    sk[32 + i] = pk[i];
  return 0;
}

MODULE = Crypt::NaCl::Tweet PACKAGE = Crypt::NaCl::Tweet

PROTOTYPES: ENABLE

SV * box(SV *msg, SV *nonce, SV *pk, SV *sk)

  PREINIT:
  STRLEN full_len, msg_len, nonce_len, pk_len, sk_len;
  unsigned char *ctext_buf, *full_buf, *msg_buf, *nonce_buf, *pk_buf, *sk_buf;

  CODE:
  pk_buf = SvPVbyte(pk, pk_len);
  if (pk_len != crypto_box_PUBLICKEYBYTES)
    croak("Invalid public key length");

  sk_buf = SvPVbyte(sk, sk_len);
  if (sk_len != crypto_box_SECRETKEYBYTES)
    croak("Invalid secret key length");

  nonce_buf = SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_box_NONCEBYTES)
    croak("Invalid nonce length");

  msg_buf = SvPVbyte(msg, msg_len);

  /* what a gross API */
  full_len = msg_len + crypto_box_ZEROBYTES;
  xNEWX(full_buf, full_len, unsigned char);
  memzero(full_buf, crypto_box_ZEROBYTES);
  Copy(msg_buf, full_buf + crypto_box_ZEROBYTES, msg_len, unsigned char);

  xNEWX(ctext_buf, full_len, unsigned char);

  crypto_box(ctext_buf, full_buf, full_len, nonce_buf, pk_buf, sk_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ctext_buf, full_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * box_afternm(SV *msg, SV *nonce, SV *key)

  PREINIT:
  STRLEN full_len, key_len, msg_len, nonce_len;
  unsigned char *ctext_buf, *full_buf, *key_buf, *msg_buf, *nonce_buf;

  CODE:
  key_buf = SvPVbyte(key, key_len);
  if (key_len != crypto_box_BEFORENMBYTES)
    croak("Invalid key length");

  nonce_buf = SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_box_NONCEBYTES)
    croak("Invalid nonce length");

  msg_buf = SvPVbyte(msg, msg_len);

  /* what a gross API */
  full_len = msg_len + crypto_box_ZEROBYTES;
  xNEWX(full_buf, full_len, unsigned char);
  memzero(full_buf, crypto_box_ZEROBYTES);
  Copy(msg_buf, full_buf + crypto_box_ZEROBYTES, msg_len, unsigned char);

  xNEWX(ctext_buf, full_len, unsigned char);

  crypto_box_afternm(ctext_buf, full_buf, full_len, nonce_buf, key_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ctext_buf, full_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * box_beforenm(SV *pk, SV *sk)

  PREINIT:
  STRLEN pk_len, sk_len;
  unsigned char *key_buf, *pk_buf, *sk_buf;

  CODE:
  pk_buf = SvPVbyte(pk, pk_len);
  if (pk_len != crypto_box_PUBLICKEYBYTES)
    croak("Invalid public key length");

  sk_buf = SvPVbyte(sk, sk_len);
  if (sk_len != crypto_box_SECRETKEYBYTES)
    croak("Invalid secret key length");

  xNEWX(key_buf, crypto_box_BEFORENMBYTES, unsigned char);

  crypto_box_beforenm(key_buf, pk_buf, sk_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)key_buf, crypto_box_BEFORENMBYTES, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

=for doc

most of sign_keypair is cribbed from tweetnacl.c to avoid its call to
randombytes

=cut

SV * box_open(SV *ctext, SV *nonce, SV * pk, SV *sk)

  PREINIT:
  STRLEN ctext_len, nonce_len, pk_len, sk_len;
  unsigned char *ctext_buf, *full_buf, *nonce_buf, *pk_buf, *sk_buf;

  CODE:
  pk_buf = SvPVbyte(pk, pk_len);
  if (pk_len != crypto_box_PUBLICKEYBYTES)
    croak("Invalid public key length");

  sk_buf = SvPVbyte(sk, sk_len);
  if (sk_len != crypto_box_SECRETKEYBYTES)
    croak("Invalid secret key length");

  nonce_buf = SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_secretbox_NONCEBYTES)
    croak("Invalid nonce length");

  ctext_buf = SvPVbyte(ctext, ctext_len);

  full_buf = malloc(ctext_len);
  if (full_buf == NULL)
    croak("Out of memory");

  if (crypto_box_open(full_buf, ctext_buf, ctext_len, nonce_buf, pk_buf, sk_buf) != 0) {
    free(full_buf);
    XSRETURN_UNDEF;
  }

  RETVAL = newSVpvn(full_buf + crypto_box_ZEROBYTES, ctext_len - crypto_box_ZEROBYTES);

  OUTPUT:
  RETVAL

SV * box_open_afternm(SV *ctext, SV *nonce, SV *key)

  PREINIT:
  STRLEN ctext_len, key_len, nonce_len;
  unsigned char *ctext_buf, *full_buf, *key_buf, *nonce_buf;

  CODE:
  key_buf = SvPVbyte(key, key_len);
  if (key_len != crypto_box_BEFORENMBYTES)
    croak("Invalid key length");

  nonce_buf = SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_box_NONCEBYTES)
    croak("Invalid nonce length");

  ctext_buf = SvPVbyte(ctext, ctext_len);

  full_buf = malloc(ctext_len);
  if (full_buf == NULL)
    croak("Out of memory");

  if (crypto_box_open_afternm(full_buf, ctext_buf, ctext_len, nonce_buf, key_buf) != 0) {
    free(full_buf);
    XSRETURN_UNDEF;
  }

  RETVAL = newSVpvn(full_buf + crypto_box_ZEROBYTES, ctext_len - crypto_box_ZEROBYTES);

  OUTPUT:
  RETVAL

=for doc

low-level and undocumented. included in case useful.

=cut

SV * core_salsa20(SV *in, SV *key)

  ALIAS:
  core_hsalsa20 = 1

  PREINIT:
  STRLEN key_len, key_len_req, in_len, in_len_req, out_len;
  unsigned char *out_buf, *key_buf, *in_buf;
  int (*func) (unsigned char *, const unsigned char *, const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      key_len_req = crypto_core_hsalsa20_tweet_KEYBYTES;
      in_len_req = crypto_core_hsalsa20_tweet_INPUTBYTES;
      out_len = crypto_core_hsalsa20_tweet_OUTPUTBYTES;
      func = crypto_core_hsalsa20;
      break;
    default:
      key_len_req = crypto_core_salsa20_tweet_KEYBYTES;
      in_len_req = crypto_core_salsa20_tweet_INPUTBYTES;
      out_len = crypto_core_salsa20_tweet_OUTPUTBYTES;
      func = crypto_core_salsa20;
      break;
  }

  key_buf = SvPVbyte(key, key_len);
  if (key_len != key_len_req)
    croak("Invalid key length");

  in_buf = SvPVbyte(in, in_len);
  if (in_len != in_len_req)
    croak("Invalid input length");

  xNEWX(out_buf, out_len, unsigned char);

  func(out_buf, in_buf, key_buf, salsa_sigma);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

=for doc

low-level and undocumented. included in case useful.

=cut

SV * hashblocks(SV *msg)

  PREINIT:
  STRLEN msg_len, rem;
  unsigned char *msg_buf, *out_buf;

  CODE:
  msg_buf = SvPVbyte(msg, msg_len);
  if (msg_len & 127)
    croak("Message length must be a multiple of 128");

  xNEWX(out_buf, crypto_hashblocks_STATEBYTES, unsigned char);

  crypto_hashblocks(out_buf, msg_buf, msg_len);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_hashblocks_STATEBYTES, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * scalarmult(SV *n, SV *p)

  PREINIT:
  STRLEN n_len, p_len;
  unsigned char *n_buf, *p_buf, *q_buf;

  CODE:
  n_buf = SvPVbyte(n, n_len);
  if (n_len != crypto_scalarmult_SCALARBYTES)
    croak("Invalid scalar length");

  p_buf = SvPVbyte(p, p_len);
  if (p_len != crypto_scalarmult_BYTES)
    croak("Invalid group element length");

  xNEWX(q_buf, crypto_scalarmult_BYTES, unsigned char);

  crypto_scalarmult(q_buf, n_buf, p_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)q_buf, crypto_scalarmult_BYTES, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * scalarmult_base(SV *n)

  PREINIT:
  STRLEN n_len;
  unsigned char *n_buf, *q_buf;

  CODE:
  n_buf = SvPVbyte(n, n_len);
  if (n_len != crypto_scalarmult_SCALARBYTES)
    croak("Invalid scalar length");

  xNEWX(q_buf, crypto_scalarmult_BYTES, unsigned char);

  crypto_scalarmult_base(q_buf, n_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)q_buf, crypto_scalarmult_BYTES, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL


SV * hash(SV *msg)

  PREINIT:
  STRLEN hash_len, msg_len;
  unsigned char *mac_buf, *msg_buf;
  int (*func) (unsigned char *, const unsigned char *, unsigned long long);

  CODE:
  xNEWX(mac_buf, crypto_hash_BYTES, unsigned char);

  msg_buf = SvPVbyte(msg, msg_len);

  crypto_hash(mac_buf, msg_buf, msg_len);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)mac_buf, crypto_hash_BYTES, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * onetimeauth(SV *msg, SV *key)

  PREINIT:
  STRLEN key_len, msg_len;
  unsigned char *auth_buf, *key_buf, *msg_buf;

  CODE:
  key_buf = SvPVbyte(key, key_len);
  if (key_len != crypto_onetimeauth_KEYBYTES)
    croak("Invalid key length");

  msg_buf = SvPVbyte(msg, msg_len);

  xNEWX(auth_buf, crypto_onetimeauth_BYTES, unsigned char);

  crypto_onetimeauth(auth_buf, msg_buf, msg_len, key_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)auth_buf, crypto_onetimeauth_BYTES, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

void onetimeauth_verify(SV *auth, SV *msg, SV *key)

  PREINIT:
  STRLEN auth_len, key_len, msg_len;
  unsigned char *auth_buf, *key_buf, *msg_buf;

  PPCODE:
  auth_buf = SvPVbyte(auth, auth_len);
  if (auth_len != crypto_onetimeauth_BYTES)
    croak("Invalid authenticator length");

  key_buf = SvPVbyte(key, key_len);
  if (key_len != crypto_onetimeauth_KEYBYTES)
    croak("Invalid key length");

  msg_buf = SvPVbyte(msg, msg_len);

  if (crypto_onetimeauth_verify(auth_buf, msg_buf, msg_len, key_buf) == 0)
    XSRETURN_YES;
  XSRETURN_NO;

SV * secretbox(SV *msg, SV *nonce, SV *key)

  PREINIT:
  STRLEN full_len, key_len, msg_len, nonce_len;
  unsigned char *ctext_buf, *full_buf, *key_buf, *msg_buf, *nonce_buf;

  CODE:
  key_buf = SvPVbyte(key, key_len);
  if (key_len != crypto_secretbox_KEYBYTES)
    croak("Invalid key length");

  nonce_buf = SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_secretbox_NONCEBYTES)
    croak("Invalid nonce length");

  msg_buf = SvPVbyte(msg, msg_len);

  /* what a gross API */
  full_len = msg_len + crypto_secretbox_ZEROBYTES;
  xNEWX(full_buf, full_len, unsigned char);
  memzero(full_buf, crypto_secretbox_ZEROBYTES);
  Copy(msg_buf, full_buf + crypto_secretbox_ZEROBYTES, msg_len, unsigned char);

  xNEWX(ctext_buf, full_len, unsigned char);

  crypto_secretbox(ctext_buf, full_buf, full_len, nonce_buf, key_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ctext_buf, full_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * secretbox_open(SV *ctext, SV *nonce, SV *key)

  PREINIT:
  STRLEN key_len, ctext_len, nonce_len;
  unsigned char *ctext_buf, *key_buf, *nonce_buf, *full_buf;

  CODE:
  key_buf = SvPVbyte(key, key_len);
  if (key_len != crypto_secretbox_KEYBYTES)
    croak("Invalid key length");

  nonce_buf = SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_secretbox_NONCEBYTES)
    croak("Invalid nonce length");

  ctext_buf = SvPVbyte(ctext, ctext_len);

  full_buf = malloc(ctext_len);
  if (full_buf == NULL)
    croak("Out of memory");

  if (crypto_secretbox_open(full_buf, ctext_buf, ctext_len, nonce_buf, key_buf) != 0) {
    free(full_buf);
    XSRETURN_UNDEF;
  }

  RETVAL = newSVpvn(full_buf + crypto_secretbox_ZEROBYTES, ctext_len - crypto_secretbox_ZEROBYTES);

  free(full_buf);

  OUTPUT:
  RETVAL

SV * sign(SV *msg, SV *sk)

  PREINIT:
  STRLEN msg_len, sk_len;
  unsigned char *msg_buf, *sm_buf, *sk_buf;
  long long unsigned sm_len;

  CODE:
  sk_buf = SvPVbyte(sk, sk_len);
  if (sk_len != crypto_sign_SECRETKEYBYTES)
    croak("Invalid secret key length");

  msg_buf = SvPVbyte(msg, msg_len);

  xNEWX(sm_buf, msg_len + crypto_sign_BYTES + 1, unsigned char);

  crypto_sign(sm_buf, &sm_len, msg_buf, msg_len, sk_buf);
  sm_buf[sm_len] = '\0';

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)sm_buf, (STRLEN)sm_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

void sign_keypair()

  PREINIT:
  SV *pk, *sk;
  STRLEN pk_len, sk_len;
  unsigned char d[64], *pk_buf, *sk_buf;
  long long p[4];
  int i, n;

  PPCODE:
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(crypto_sign_SECRETKEYBYTES)));
  PUTBACK;
  n = call_pv("Crypt::NaCl::Tweet::random_bytes", G_SCALAR);
  SPAGAIN;
  if (n != 1)
    croak("Failed to get random bytes (%d)", n);
  sk = POPs;
  sk_buf = SvPVbyte(sk, sk_len);

  if (sk_len != crypto_sign_SECRETKEYBYTES)
    croak("random_bytes returned wrong number of bytes");

  xNEWX(pk_buf, crypto_box_PUBLICKEYBYTES, unsigned char);

  sign_keypair(pk_buf, sk_buf);

  pk = newSV(0);
  sv_usepvn_flags(pk, (char *)pk_buf, crypto_box_PUBLICKEYBYTES, SV_HAS_TRAILING_NUL);

  SvREFCNT_inc(sk);
  PUTBACK;
  FREETMPS;
  LEAVE;
  mXPUSHs(pk);
  mXPUSHs(sk);
  XSRETURN(2);

SV * sign_open(SV *sm, SV *pk)

  PREINIT:
  STRLEN pk_len, sm_len;
  unsigned char *msg_buf, *pk_buf, *sm_buf;
  long long unsigned msg_len;

  CODE:
  pk_buf = SvPVbyte(pk, pk_len);
  if (pk_len != crypto_sign_PUBLICKEYBYTES)
    croak("Invalid public key length");

  sm_buf = SvPVbyte(sm, sm_len);

  xNEWX(msg_buf, sm_len + 1, unsigned char);

  if (crypto_sign_open(msg_buf, &msg_len, sm_buf, sm_len, pk_buf) != 0) {
    Safefree(msg_buf);
    XSRETURN_UNDEF;
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)msg_buf, (STRLEN)msg_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * stream(UV stream_len, SV *nonce, SV *key)

  PREINIT:
  STRLEN key_len, nonce_len;
  unsigned char *key_buf, *nonce_buf, *stream_buf;

  CODE:
  key_buf = SvPVbyte(key, key_len);
  if (key_len != crypto_stream_KEYBYTES)
    croak("Invalid key length");

  nonce_buf = SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_stream_NONCEBYTES)
    croak("Invalid nonce length");

  xNEWX(stream_buf, stream_len, unsigned char);

  crypto_stream(stream_buf, stream_len, nonce_buf, key_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)stream_buf, stream_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * stream_xor(SV *msg, SV *nonce, SV *key)

  PREINIT:
  STRLEN key_len, msg_len, nonce_len;
  unsigned char *ctext_buf, *key_buf, *msg_buf, *nonce_buf;

  CODE:
  key_buf = SvPVbyte(key, key_len);
  if (key_len != crypto_stream_KEYBYTES)
    croak("Invalid key length");

  nonce_buf = SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_stream_NONCEBYTES)
    croak("Invalid nonce length");

  msg_buf = SvPVbyte(msg, msg_len);

  xNEWX(ctext_buf, msg_len, unsigned char);

  crypto_stream_xor(ctext_buf, msg_buf, msg_len, nonce_buf, key_buf);

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ctext_buf, msg_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

void verify(SV *x, SV *y)

  ALIAS:
  verify_16 = 1
  verify_32 = 2

  PREINIT:
  STRLEN x_len, y_len, req_len;
  unsigned char *x_buf, *y_buf;
  int (*func) (const unsigned char *, const unsigned char *);

  PPCODE:
  switch(ix) {
    case 2:
      req_len = 32;
      func = crypto_verify_32_tweet;
      break;
    default:
      req_len = 16;
      func = crypto_verify_16_tweet;
      break;
  }

  x_buf = SvPVbyte(x, x_len);
  y_buf = SvPVbyte(y, y_len);
  if (x_len != req_len || y_len != req_len)
    croak("Invalid argument size(s); must be %d bytes", req_len);

  if (func(x_buf, y_buf) == 0)
    XSRETURN_YES;
  XSRETURN_NO;
