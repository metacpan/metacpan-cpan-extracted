#ifndef CJWS_B64_H
#define CJWS_B64_H

/* base64url (RFC 4648 section 5), unpadded encode, padding-tolerant
 * decode. Self-contained - no OpenSSL involvement, so the transforms are
 * identical on every build. */

static const char cjws_b64u_chars[] =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

static STRLEN cjws_b64url_encoded_len(STRLEN n) {
  return ((n + 2) / 3) * 4;   /* upper bound; unpadded actual may be less */
}

/* Encode src[0..n) into dst (caller sizes via cjws_b64url_encoded_len).
 * Returns bytes written. */
static STRLEN cjws_b64url_encode(char *dst, const unsigned char *src, STRLEN n) {
  STRLEN i = 0, o = 0;
  while (i + 3 <= n) {
    unsigned v = (unsigned)src[i] << 16 | (unsigned)src[i+1] << 8 | src[i+2];
    dst[o++] = cjws_b64u_chars[(v >> 18) & 63];
    dst[o++] = cjws_b64u_chars[(v >> 12) & 63];
    dst[o++] = cjws_b64u_chars[(v >> 6) & 63];
    dst[o++] = cjws_b64u_chars[v & 63];
    i += 3;
  }
  if (n - i == 1) {
    unsigned v = (unsigned)src[i] << 16;
    dst[o++] = cjws_b64u_chars[(v >> 18) & 63];
    dst[o++] = cjws_b64u_chars[(v >> 12) & 63];
  }
  else if (n - i == 2) {
    unsigned v = (unsigned)src[i] << 16 | (unsigned)src[i+1] << 8;
    dst[o++] = cjws_b64u_chars[(v >> 18) & 63];
    dst[o++] = cjws_b64u_chars[(v >> 12) & 63];
    dst[o++] = cjws_b64u_chars[(v >> 6) & 63];
  }
  return o;
}

/* Decode: -_ plus +/ accepted (JWKS in the wild mix alphabets), '='
 * padding tolerated at the end, anything else is an error. Returns bytes
 * written into dst (size at least (n/4+1)*3), or (STRLEN)-1 on bad input. */
static STRLEN cjws_b64url_decode(unsigned char *dst, const char *src, STRLEN n) {
  unsigned v = 0;
  int bits = 0;
  STRLEN o = 0, i;
  while (n && src[n-1] == '=') n--;
  for (i = 0; i < n; i++) {
    unsigned char c = (unsigned char)src[i];
    int d;
    if (c >= 'A' && c <= 'Z') d = c - 'A';
    else if (c >= 'a' && c <= 'z') d = c - 'a' + 26;
    else if (c >= '0' && c <= '9') d = c - '0' + 52;
    else if (c == '-' || c == '+') d = 62;
    else if (c == '_' || c == '/') d = 63;
    else return (STRLEN)-1;
    v = (v << 6) | (unsigned)d;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      dst[o++] = (unsigned char)((v >> bits) & 0xff);
    }
  }
  /* A trailing chunk of 1 base64 char (6 bits) cannot encode a byte. */
  if (bits >= 6) return (STRLEN)-1;
  return o;
}

#endif
