#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>

// C99 required!
// this is not just for comments, but also for
// integer constant semantics,
// sscanf format modifiers and more.

enum {
  // ASN_TAG
  ASN_BOOLEAN           = 0x01,
  ASN_INTEGER           = 0x02,
  ASN_BIT_STRING        = 0x03,
  ASN_OCTET_STRING      = 0x04,
  ASN_NULL              = 0x05,
  ASN_OBJECT_IDENTIFIER = 0x06,
  ASN_OID               = 0x06,
  ASN_OBJECT_DESCRIPTOR = 0x07,
  ASN_EXTERNAL          = 0x08,
  ASN_REAL              = 0x09,
  ASN_ENUMERATED        = 0x0a,
  ASN_EMBEDDED_PDV      = 0x0b,
  ASN_UTF8_STRING       = 0x0c,
  ASN_RELATIVE_OID      = 0x0d,
  ASN_SEQUENCE          = 0x10,
  ASN_SET               = 0x11,
  ASN_NUMERIC_STRING    = 0x12,
  ASN_PRINTABLE_STRING  = 0x13,
  ASN_TELETEX_STRING    = 0x14,
  ASN_T61_STRING        = 0x14,
  ASN_VIDEOTEX_STRING   = 0x15,
  ASN_IA5_STRING        = 0x16,
  ASN_ASCII_STRING      = 0x16,
  ASN_UTC_TIME          = 0x17,
  ASN_GENERALIZED_TIME  = 0x18,
  ASN_GRAPHIC_STRING    = 0x19,
  ASN_VISIBLE_STRING    = 0x1a,
  ASN_ISO646_STRING     = 0x1a,
  ASN_GENERAL_STRING    = 0x1b,
  ASN_UNIVERSAL_STRING  = 0x1c,
  ASN_CHARACTER_STRING  = 0x1d,
  ASN_BMP_STRING        = 0x1e,

  ASN_TAG_BER           = 0x1f,
  ASN_TAG_MASK          = 0x1f,

  // primitive/constructed
  ASN_CONSTRUCTED       = 0x20,

  // ASN_CLASS
  ASN_UNIVERSAL         = 0x00,
  ASN_APPLICATION       = 0x01,
  ASN_CONTEXT           = 0x02,
  ASN_PRIVATE           = 0x03,

  ASN_CLASS_MASK        = 0xc0,
  ASN_CLASS_SHIFT       = 6,

  // ASN_APPLICATION SNMP
  SNMP_IPADDRESS         = 0x00,
  SNMP_COUNTER32         = 0x01,
  SNMP_GAUGE32           = 0x02,
  SNMP_UNSIGNED32        = 0x02,
  SNMP_TIMETICKS         = 0x03,
  SNMP_OPAQUE            = 0x04,
  SNMP_COUNTER64         = 0x06,
};

// tlow-level types this module can ecode the above (and more) into
enum {
  BER_TYPE_BYTES,
  BER_TYPE_UTF8,
  BER_TYPE_UCS2,
  BER_TYPE_UCS4,
  BER_TYPE_INT,
  BER_TYPE_OID,
  BER_TYPE_RELOID,
  BER_TYPE_NULL,
  BER_TYPE_BOOL,
  BER_TYPE_REAL,
  BER_TYPE_IPADDRESS,
  BER_TYPE_CROAK,
};

// tuple array indices
enum {
  BER_CLASS     = 0,
  BER_TAG       = 1,
  BER_FLAGS     = 2,
  BER_DATA      = 3,
  BER_ARRAYSIZE
};

#define MAX_OID_STRLEN 4096

typedef void profile_type;

static profile_type *cur_profile, *default_profile;
static SV *buf_sv; // encoding buffer
static U8 *buf, *cur, *end; // buffer start, current, end

#if PERL_VERSION < 18
# define utf8_to_uvchr_buf(s,e,l) utf8_to_uvchr (s, l)
#endif

#ifndef SvREFCNT_inc_NN
#define SvREFCNT_inc_NN(x) SvREFCNT_inc (x)
#endif
#ifndef SvREFCNT_dec_NN
#define SvREFCNT_dec_NN(x) SvREFCNT_dec (x)
#endif

#if __GNUC__ >= 3
# define expect(expr,value)         __builtin_expect ((expr), (value))
# define INLINE                     static inline
#else
# define expect(expr,value)         (expr)
# define INLINE                     static
#endif

#define expect_false(expr) expect ((expr) != 0, 0)
#define expect_true(expr)  expect ((expr) != 0, 1)

/////////////////////////////////////////////////////////////////////////////

static SV *sviv_cache[32];

// for "small" integers, return a readonly sv, otherwise create a new one
static SV *newSVcacheint (int val)
{
  if (expect_false (val < 0 || val >= sizeof (sviv_cache)))
    return newSViv (val);

  if (expect_false (!sviv_cache [val]))
    {
      sviv_cache [val] = newSVuv (val);
      SvREADONLY_on (sviv_cache [val]);
    }

  return SvREFCNT_inc_NN (sviv_cache [val]);
}

/////////////////////////////////////////////////////////////////////////////

static HV *profile_stash;

static profile_type *
SvPROFILE (SV *profile)
{
  if (!SvOK (profile))
    return default_profile;

  if (!SvROK (profile))
    croak ("Convert::BER::XS::Profile expected");

  profile = SvRV (profile);

  if (SvSTASH (profile) != profile_stash)
    croak ("Convert::BER::XS::Profile expected");

  return (void *)profile;
}

static int
profile_lookup (profile_type *profile, int klass, int tag)
{
  SV *sv = (SV *)profile;
  U32 idx = (tag << 2) + klass;

  if (expect_false (idx >= SvCUR (sv)))
    return BER_TYPE_BYTES;

  return SvPVX (sv)[idx];
}

static void
profile_set (profile_type *profile, int klass, int tag, int type)
{
  SV *sv = (SV *)profile;
  U32 idx = (tag << 2) + klass;
  STRLEN oldlen = SvCUR (sv);
  STRLEN newlen = idx + 2;

  if (idx >= oldlen)
    {
      sv_grow (sv, newlen);
      memset (SvPVX (sv) + oldlen, BER_TYPE_BYTES, newlen - oldlen);
      SvCUR_set (sv, newlen);
    }

  SvPVX (sv)[idx] = type;
}

static SV *
profile_new (void)
{
  SV *sv = newSVpvn ("", 0);

  static const struct {
    int klass;
    int tag;
    int type;
  } *celem, default_map[] = {
      { ASN_UNIVERSAL, ASN_BOOLEAN          , BER_TYPE_BOOL },
      { ASN_UNIVERSAL, ASN_INTEGER          , BER_TYPE_INT  },
      { ASN_UNIVERSAL, ASN_NULL             , BER_TYPE_NULL },
      { ASN_UNIVERSAL, ASN_OBJECT_IDENTIFIER, BER_TYPE_OID  },
      { ASN_UNIVERSAL, ASN_RELATIVE_OID     , BER_TYPE_RELOID },
      { ASN_UNIVERSAL, ASN_REAL             , BER_TYPE_REAL },
      { ASN_UNIVERSAL, ASN_ENUMERATED       , BER_TYPE_INT },
      { ASN_UNIVERSAL, ASN_UTF8_STRING      , BER_TYPE_UTF8 },
      { ASN_UNIVERSAL, ASN_BMP_STRING       , BER_TYPE_UCS2 },
      { ASN_UNIVERSAL, ASN_UNIVERSAL_STRING , BER_TYPE_UCS4 },
  };

  for (celem = default_map + sizeof (default_map) / sizeof (default_map [0]); celem-- > default_map; )
    profile_set ((profile_type *)sv, celem->klass, celem->tag, celem->type);

  return sv_bless (newRV_noinc (sv), profile_stash);
}

/////////////////////////////////////////////////////////////////////////////
// decoder

static void
error (const char *errmsg)
{
  croak ("%s at offset 0x%04x", errmsg, cur - buf);
}

static void
want (UV count)
{
  if (expect_false ((uintptr_t)(end - cur) < count))
    error ("unexpected end of message buffer");
}

// get_* functions fetch something from the buffer
// decode_* functions use get_* fun ctions to decode ber values

// get single octet
static U8
get_u8 (void)
{
  if (cur == end)
    error ("unexpected end of message buffer");

  return *cur++;
}

// get n octets
static U8 *
get_n (UV count)
{
  want (count);
  U8 *res = cur;
  cur += count;
  return res;
}

// get ber-encoded integer (i.e. pack "w")
static UV
get_w (void)
{
  UV res = 0;
  U8 c = get_u8 ();

  if (expect_false (c == 0x80))
    error ("invalid BER padding (X.690 8.1.2.4.2, 8.19.2)");

  for (;;)
    {
      if (expect_false (res >> UVSIZE * 8 - 7))
        error ("BER variable length integer overflow");

      res = (res << 7) | (c & 0x7f);

      if (expect_true (!(c & 0x80)))
        return res;

      c = get_u8 ();
    }
}

static UV
get_length (void)
{
  UV res = get_u8 ();

  if (expect_false (res & 0x80))
    {
      U8 cnt = res & 0x7f;

      // this genewrates quite ugly code, but the overhead
      // of copying the bytes for these lengths is probably so high
      // that a slightly inefficient get_length won't matter.

      if (expect_false (cnt == 0))
        error ("invalid use of indefinite BER length form in primitive encoding (X.690 8.1.3.2)");

      if (expect_false (cnt > UVSIZE))
        error ("BER value length too long (must fit into UV) or BER reserved value in length (X.690 8.1.3.5)");

      want (cnt);

      res = 0;
      do
        res = (res << 8) | *cur++;
      while (--cnt);
    }

  return res;
}

static SV *
decode_int (UV len)
{
  if (!len)
    error ("invalid BER_TYPE_INT length zero (X.690 8.3.1)");

  U8 *data = get_n (len);

  if (expect_false (len > 1))
    {
      U16 mask = (data [0] << 8) | data [1] & 0xff80;

      if (expect_false (mask == 0xff80 || mask == 0x0000))
        error ("invalid padding in BER_TYPE_INT (X.690 8.3.2)");
    }

  int negative = data [0] & 0x80;

  UV val = negative ? -1 : 0; // copy signbit to all bits

  if (len > UVSIZE + (!negative && !*data))
    error ("BER_TYPE_INT overflow");

  do
    val = (val << 8) | *data++;
  while (--len);

  // the cast to IV relies on implementation-defined behaviour (two's complement cast)
  // but that's ok, as perl relies on it as well.
  return negative ? newSViv ((IV)val) : newSVuv (val);
}

static SV *
decode_data (UV len)
{
  return newSVpvn ((char *)get_n (len), len);
}

// helper for decode_object_identifier
static char *
write_uv (char *buf, UV u)
{
  // the one-digit case is absolutely predominant, so this pays off (hopefully)
  if (expect_true (u < 10))
    *buf++ = u + '0';
  else
    {
      // this *could* be done much faster using branchless fixed-point arithmetics
      char *beg = buf;

      do
        {
          *buf++ = u % 10 + '0';
          u /= 10;
        }
      while (u);

      // reverse digits
      char *ptr = buf;
      while (--ptr > beg)
        {
          char c = *ptr;
          *ptr = *beg;
          *beg = c;
          ++beg;
        }
    }

  return buf;
}

static SV *
decode_oid (UV len, int relative)
{
  if (len <= 0)
    {
      error ("BER_TYPE_OID length must not be zero");
      return &PL_sv_undef;
    }

  U8 *end = cur + len;
  UV w = get_w ();

  static char oid[MAX_OID_STRLEN]; // static, because too large for stack
  char *app = oid;

  if (relative)
    app = write_uv (app, w);
  else
    {
      UV w1, w2;

      if (w < 2 * 40)
        (w1 = w / 40), (w2 = w % 40);
      else
        (w1 =      2), (w2 = w - 2 * 40);

      app = write_uv (app, w1);
      *app++ = '.';
      app = write_uv (app, w2);
    }

  while (cur < end)
    {
      // we assume an oid component is never > 64 digits
      if (oid + sizeof (oid) - app < 64)
        croak ("BER_TYPE_OID to long to decode");

      w = get_w ();
      *app++ = '.';
      app = write_uv (app, w);
    }

  return newSVpvn (oid, app - oid);
}

// oh my, this is a total mess
static SV *
decode_real (UV len)
{
  SV *res;
  U8 *beg = cur;

  if (len == 0)
    res = newSVnv (0.);
  else
    {
      U8 info = get_u8 ();

      if (info & 0x80)
        {
          // binary
          static const U8 base[]  = { 2, 8, 16, 0 };
          NV  S = info & 0x40 ? -1 : 1; // sign
          NV  B = base [(info >> 4) & 3]; // base
          NV  F = 1 << ((info >> 2) & 3); // scale factor ("shift")
          int L = info & 3; // exponent length

          if (!B)
            croak ("BER_TYPE_REAL binary encoding uses invalid base (0x%02x)", info);

          SAVETMPS;

          SV *E = sv_2mortal (decode_int (L == 3 ? get_u8 () : L + 1));
          SV *M = sv_2mortal (decode_int (len - (cur - beg)));

          res = newSVnv (S * SvNV (M) * F * Perl_pow (B, SvNV (E)));

          FREETMPS;
        }
      else if (info & 0x40)
        {
          // SpecialRealValue
          U8 special = get_u8 ();
          NV val;

          switch (special)
            {
              case 0x40: val =  NV_INF; break;
              case 0x41: val = -NV_INF; break;
              case 0x42: val =  NV_NAN; break;
              case 0x43: val = -(NV)0.; break;

              default:
                croak ("BER_TYPE_REAL SpecialRealValues invalid encoding 0x%02x (X.690 8.5.9)", special);
            }

          res = newSVnv (val);
        }
      else
        {
          // decimal
          dSP;
          SAVETMPS;
          PUSHMARK (SP);
          EXTEND (SP, 2);
          PUSHs (sv_2mortal (newSVcacheint (info & 0x3f)));
          PUSHs (sv_2mortal (newSVpvn (get_n (len - 1), len - 1)));
          PUTBACK;
          call_pv ("Convert::BER::XS::_decode_real_decimal", G_SCALAR);
          SPAGAIN;
          res = SvREFCNT_inc_NN (POPs);
          PUTBACK;
          FREETMPS;
        }
    }

  if (cur - beg != len)
    {
      SvREFCNT_dec_NN (res);
      croak ("BER_TYPE_REAL invalid content length (X.690 8,5)");
    }

  return res;
}

// TODO: this is unacceptably slow
static SV *
decode_ucs (UV len, int chrsize)
{
  if (len & (chrsize - 1))
    croak ("BER_TYPE_UCS has an invalid number of octets (%d)", len);

  SV *res = NEWSV (0, 0);

  while (len)
    {
      U8 b1 = get_u8 ();
      U8 b2 = get_u8 ();
      U32 chr = (b1 << 8) | b2;

      if (chrsize == 4)
        {
          U8 b3 = get_u8 ();
          U8 b4 = get_u8 ();
          chr = (chr << 16) | (b3 << 8) | b4;
        }

      U8 uchr [UTF8_MAXBYTES];
      int uclen = uvuni_to_utf8 (uchr, chr) - uchr;

      sv_catpvn (res, (const char *)uchr, uclen);
      len -= chrsize;
    }

  SvUTF8_on (res);

  return res;
}

static SV *
decode_ber (void)
{
  int identifier = get_u8 ();

  SV *res;

  int constructed =  identifier & ASN_CONSTRUCTED;
  int klass       = (identifier & ASN_CLASS_MASK) >> ASN_CLASS_SHIFT;
  int tag         =  identifier & ASN_TAG_MASK;

  if (tag == ASN_TAG_BER)
    tag = get_w ();

  if (constructed)
    {
      want (1);
      AV *av = (AV *)sv_2mortal ((SV *)newAV ());

      if (expect_false (*cur == 0x80))
        {
          // indefinite length
          ++cur;

          for (;;)
            {
              want (2);
              if (!cur [0] && !cur [1])
                {
                  cur += 2;
                  break;
                }

            av_push (av, decode_ber ());
          }
        }
      else
        {
          UV len = get_length ();
          UV seqend = (cur - buf) + len;

          while (cur < buf + seqend)
            av_push (av, decode_ber ());

          if (expect_false (cur > buf + seqend))
            croak ("CONSTRUCTED type %02x length overflow (0x%x 0x%x)\n", identifier, (int)(cur - buf), (int)seqend);
        }

      res = newRV_inc ((SV *)av);
    }
  else
    {
      UV len = get_length ();

      switch (profile_lookup (cur_profile, klass, tag))
        {
          case BER_TYPE_NULL:
            if (expect_false (len))
              croak ("BER_TYPE_NULL value with non-zero length %d encountered (X.690 8.8.2)", len);

            res = &PL_sv_undef;
            break;

          case BER_TYPE_BOOL:
            if (expect_false (len != 1))
              croak ("BER_TYPE_BOOLEAN value with invalid length %d encountered (X.690 8.2.1)", len);

            res = newSVcacheint (!!get_u8 ());
            break;

          case BER_TYPE_OID:
            res = decode_oid (len, 0);
            break;

          case BER_TYPE_RELOID:
            res = decode_oid (len, 1);
            break;

          case BER_TYPE_INT:
            res = decode_int (len);
            break;

          case BER_TYPE_UTF8:
            res = decode_data (len);
            SvUTF8_on (res);
            break;

          case BER_TYPE_BYTES:
            res = decode_data (len);
            break;

          case BER_TYPE_IPADDRESS:
            {
              if (len != 4)
                croak ("BER_TYPE_IPADDRESS type with invalid length %d encountered (RFC 2578 7.1.5)", len);

              U8 *data = get_n (4);
              res = newSVpvf ("%d.%d.%d.%d", data [0], data [1], data [2], data [3]);
            }
            break;

          case BER_TYPE_UCS2:
            res = decode_ucs (len, 2);
            break;

          case BER_TYPE_UCS4:
            res = decode_ucs (len, 4);
            break;

          case BER_TYPE_REAL:
            res = decode_real (len);
            break;

          case BER_TYPE_CROAK:
            croak ("class/tag %d/%d mapped to BER_TYPE_CROAK", klass, tag);

          default:
            croak ("unconfigured/unsupported class/tag %d/%d", klass, tag);
        }
    }

  AV *av = newAV ();
  av_fill (av, BER_ARRAYSIZE - 1);
  AvARRAY (av)[BER_CLASS] = newSVcacheint (klass);
  AvARRAY (av)[BER_TAG  ] = newSVcacheint (tag);
  AvARRAY (av)[BER_FLAGS] = newSVcacheint (constructed ? 1 : 0);
  AvARRAY (av)[BER_DATA ] = res;

  return newRV_noinc ((SV *)av);
}

/////////////////////////////////////////////////////////////////////////////
// encoder

/* adds two STRLENs together, slow, and with paranoia */
static STRLEN
strlen_sum (STRLEN l1, STRLEN l2)
{
  size_t sum = l1 + l2;

  if (sum < (size_t)l2 || sum != (size_t)(STRLEN)sum)
    croak ("Convert::BER::XS: string size overflow");

  return sum;
}

static void
set_buf (SV *sv)
{
  STRLEN len;
  buf_sv = sv;
  buf = (U8  *)SvPVbyte (buf_sv, len);
  cur = buf;
  end = buf + len;
}

/* similar to SvGROW, but somewhat safer and guarantees exponential realloc strategy */
static char *
my_sv_grow (SV *sv, size_t len1, size_t len2)
{
  len1 = strlen_sum (len1, len2);
  len1 = strlen_sum (len1, len1 >> 1);

  if (len1 > 4096 - 24)
    len1 = (len1 | 4095) - 24;

  return SvGROW (sv, len1);
}

static void
need (STRLEN len)
{
  if (expect_false ((uintptr_t)(end - cur) < len))
    {
      STRLEN pos = cur - buf;
      buf = (U8 *)my_sv_grow (buf_sv, pos, len);
      cur = buf + pos;
      end = buf + SvLEN (buf_sv) - 1;
    }
}

static void
put_u8 (int val)
{
  need (1);
  *cur++ = val;
}

static void
put_w_nocheck (UV val)
{
#if UVSIZE > 4
  *cur = (val >> 7 * 9) | 0x80; cur += val >= ((UV)1 << (7 * 9));
  *cur = (val >> 7 * 8) | 0x80; cur += val >= ((UV)1 << (7 * 8));
  *cur = (val >> 7 * 7) | 0x80; cur += val >= ((UV)1 << (7 * 7));
  *cur = (val >> 7 * 6) | 0x80; cur += val >= ((UV)1 << (7 * 6));
  *cur = (val >> 7 * 5) | 0x80; cur += val >= ((UV)1 << (7 * 5));
#endif
  *cur = (val >> 7 * 4) | 0x80; cur += val >= ((UV)1 << (7 * 4));
  *cur = (val >> 7 * 3) | 0x80; cur += val >= ((UV)1 << (7 * 3));
  *cur = (val >> 7 * 2) | 0x80; cur += val >= ((UV)1 << (7 * 2));
  *cur = (val >> 7 * 1) | 0x80; cur += val >= ((UV)1 << (7 * 1));
  *cur =  val           & 0x7f; cur += 1;
}

static void
put_w (UV val)
{
  need (5); // we only handle up to 5 bytes

  put_w_nocheck (val);
}

static U8 *
put_length_at (UV val, U8 *cur)
{
  if (val <= 0x7fU)
    *cur++ = val;
  else
    {
      U8 *lenb = cur++;

#if UVSIZE > 4
      *cur = val >> 56; cur += val >= ((UV)1 << (8 * 7));
      *cur = val >> 48; cur += val >= ((UV)1 << (8 * 6));
      *cur = val >> 40; cur += val >= ((UV)1 << (8 * 5));
      *cur = val >> 32; cur += val >= ((UV)1 << (8 * 4));
#endif
      *cur = val >> 24; cur += val >= ((UV)1 << (8 * 3));
      *cur = val >> 16; cur += val >= ((UV)1 << (8 * 2));
      *cur = val >>  8; cur += val >= ((UV)1 << (8 * 1));
      *cur = val      ; cur += 1;

      *lenb = 0x80 + cur - lenb - 1;
    }

  return cur;
}

static void
put_length (UV val)
{
  need (9 + val);
  cur = put_length_at (val, cur);
}

// return how many bytes the encoded length requires
static int length_length (UV val)
{
  // use hashing with a DeBruin sequence, anyone?
  return expect_true (val <= 0x7fU)
    ? 1
    : 2
      + (val > 0x000000000000ffU)
      + (val > 0x0000000000ffffU)
      + (val > 0x00000000ffffffU)
#if UVSIZE > 4
      + (val > 0x000000ffffffffU)
      + (val > 0x0000ffffffffffU)
      + (val > 0x00ffffffffffffU)
      + (val > 0xffffffffffffffU)
#endif
    ;
}

static void
encode_data (const char *ptr, STRLEN len)
{
  put_length (len);
  memcpy (cur, ptr, len);
  cur += len;
}

static void
encode_uv (UV uv)
{
}

static void
encode_int (SV *sv)
{
  need (8 + 1 + 1); // 64 bit + length + extra 0

  if (expect_false (!SvIOK (sv)))
    sv_2iv_flags (sv, 0);

  U8 *lenb = cur++;

  if (SvIOK_notUV (sv))
    {
      IV iv = SvIVX (sv);

      if (expect_false (iv < 0))
        {
          // get two's complement bit pattern - works even on hypothetical non-2c machines
          UV uv = iv;

#if UVSIZE > 4
          *cur = uv >> 56; cur += !!(~uv & 0xff80000000000000U);
          *cur = uv >> 48; cur += !!(~uv & 0xffff800000000000U);
          *cur = uv >> 40; cur += !!(~uv & 0xffffff8000000000U);
          *cur = uv >> 32; cur += !!(~uv & 0xffffffff80000000U);
#endif
          *cur = uv >> 24; cur += !!(~uv & 0xffffffffff800000U);
          *cur = uv >> 16; cur += !!(~uv & 0xffffffffffff8000U);
          *cur = uv >>  8; cur += !!(~uv & 0xffffffffffffff80U);
          *cur = uv      ; cur += 1;

          *lenb = cur - lenb - 1;

          return;
        }
    }

  UV uv = SvUV (sv);

  // prepend an extra 0 if the high bit is 1
  *cur = 0; cur += !!(uv & ((UV)1 << (UVSIZE * 8 - 1)));

#if UVSIZE > 4
  *cur = uv >> 56; cur += !!(uv & 0xff80000000000000U);
  *cur = uv >> 48; cur += !!(uv & 0xffff800000000000U);
  *cur = uv >> 40; cur += !!(uv & 0xffffff8000000000U);
  *cur = uv >> 32; cur += !!(uv & 0xffffffff80000000U);
#endif
  *cur = uv >> 24; cur += !!(uv & 0xffffffffff800000U);
  *cur = uv >> 16; cur += !!(uv & 0xffffffffffff8000U);
  *cur = uv >>  8; cur += !!(uv & 0xffffffffffffff80U);
  *cur = uv      ; cur += 1;

  *lenb = cur - lenb - 1;
}

// we don't know the length yet, so we optimistically
// assume the length will need one octet later. If that
// turns out to be wrong, we memmove as needed.
// mark the beginning
static STRLEN
len_fixup_mark (void)
{
  return cur++ - buf;
}

// patch up the length
static void
len_fixup (STRLEN mark)
{
  STRLEN reallen = (cur - buf) - mark - 1;
  int lenlen = length_length (reallen);

  if (expect_false (lenlen > 1))
    {
      // bad luck, we have to shift the bytes to make room for the length
      need (5);
      memmove (buf + mark + lenlen, buf + mark + 1, reallen);
      cur += lenlen - 1;
    }
  
  put_length_at (reallen, buf + mark);
}

static char *
read_uv (char *str, UV *uv)
{
  UV r = 0;

  while (*str >= '0')
    r = r * 10 + *str++ - '0';

  *uv = r;

  str += !!*str; // advance over any non-zero byte

  return str;
}

static void
encode_oid (SV *oid, int relative)
{
  STRLEN len;
  char *ptr = SvPV (oid, len); // utf8 vs. bytes does not matter

  // we need at most as many octets as the string form
  need (len + 1);
  STRLEN mark = len_fixup_mark ();

  UV w1, w2;

  if (!relative)
    {
      ptr = read_uv (ptr, &w1);
      ptr = read_uv (ptr, &w2);

      put_w_nocheck (w1 * 40 + w2);
    }

  while (*ptr)
    {
      ptr = read_uv (ptr, &w1);
      put_w_nocheck (w1);
    }

  len_fixup (mark);
}

static void
encode_real (SV *data)
{
  NV nv = SvNV (data);

  if (expect_false (nv == (NV)0.))
    {
      if (signbit (nv))
        {
          // negative zero
          need (3);
          *cur++ = 2;
          *cur++ = 0x40;
          *cur++ = 0x43;
        }
      else
        {
          // positive zero
          need (1);
          *cur++ = 0;
        }
    }
  else if (expect_false (Perl_isinf (nv)))
    {
      need (3);
      *cur++ = 2;
      *cur++ = 0x40;
      *cur++ = nv < (NV)0. ? 0x41 : 0x40;
    }
  else if (expect_false (Perl_isnan (nv)))
    {
      need (3);
      *cur++ = 2;
      *cur++ = 0x40;
      *cur++ = 0x42;
    }
  else
    {
      // use decimal encoding
      dSP;
      SAVETMPS;
      PUSHMARK (SP);
      EXTEND (SP, 2);
      PUSHs (data);
      PUSHs (sv_2mortal (newSVcacheint (NV_DIG)));
      PUTBACK;
      call_pv ("Convert::BER::XS::_encode_real_decimal", G_SCALAR);
      SPAGAIN;

      SV *sv = POPs;
      STRLEN l;
      char *f = SvPV (sv, l);

      put_length (l);
      memcpy (cur, f, l);
      cur += l;

      PUTBACK;
      FREETMPS;
    }
}

static void
encode_ucs (SV *data, int chrsize)
{
  STRLEN uchars = sv_len_utf8 (data);
  STRLEN len;;
  char *ptr = SvPVutf8 (data, len);

  put_length (uchars * chrsize);

  while (uchars--)
    {
      STRLEN uclen;
      UV uchr = utf8_to_uvchr_buf ((U8 *)ptr, (U8 *)ptr + len, &uclen);

      ptr += uclen;
      len -= uclen;

      if (chrsize == 4)
        {
          *cur++ = uchr >> 24;
          *cur++ = uchr >> 16;
        }

      *cur++ = uchr >> 8;
      *cur++ = uchr;
    }
}

// check whether an SV is a BER tuple and returns its AV *
static AV *
ber_tuple (SV *tuple)
{
  SV *rv;

  if (expect_false (!SvROK (tuple) || SvTYPE ((rv = SvRV (tuple))) != SVt_PVAV))
    croak ("BER tuple must be array-reference");

  if (expect_false (SvRMAGICAL (rv)))
    croak ("BER tuple must not be tied");

  if (expect_false (AvFILL ((AV *)rv) != BER_ARRAYSIZE - 1))
    croak ("BER tuple must contain exactly %d elements, not %d", BER_ARRAYSIZE, AvFILL ((AV *)rv) + 1);

  return (AV *)rv;
}

static void
encode_ber (SV *tuple)
{
  AV *av = ber_tuple (tuple);

  int klass       = SvIV (AvARRAY (av)[BER_CLASS]);
  int tag         = SvIV (AvARRAY (av)[BER_TAG]);
  int constructed = SvIV (AvARRAY (av)[BER_FLAGS]) & 1 ? ASN_CONSTRUCTED : 0;
  SV *data        =       AvARRAY (av)[BER_DATA];

  int identifier = (klass << ASN_CLASS_SHIFT) | constructed;

  if (expect_false (tag >= ASN_TAG_BER))
    {
      put_u8 (identifier | ASN_TAG_BER);
      put_w (tag);
    }
  else
    put_u8 (identifier | tag);

  if (constructed)
    {
      // we optimistically assume that only one length byte is needed
      // and adjust later
      need (1);
      STRLEN mark = len_fixup_mark ();

      if (expect_false (!SvROK (data) || SvTYPE (SvRV (data)) != SVt_PVAV))
        croak ("BER CONSTRUCTED data must be array-reference");

      AV *av = (AV *)SvRV (data);
      int fill = AvFILL (av);

      if (expect_false (SvRMAGICAL (av)))
        croak ("BER CONSTRUCTED data must not be tied");

      int i;
      for (i = 0; i <= fill; ++i)
        encode_ber (AvARRAY (av)[i]);

      len_fixup (mark);
    }
  else
    switch (profile_lookup (cur_profile, klass, tag))
      {
        case BER_TYPE_NULL:
          put_length (0);
          break;

        case BER_TYPE_BOOL:
          put_length (1);
          *cur++ = SvTRUE (data) ? 0xff : 0x00; // 0xff = DER/CER
          break;

        case BER_TYPE_OID:
          encode_oid (data, 0);
          break;

        case BER_TYPE_RELOID:
          encode_oid (data, 1);
          break;

        case BER_TYPE_INT:
          encode_int (data);
          break;

        case BER_TYPE_BYTES:
          {
            STRLEN len;
            const char *ptr = SvPVbyte (data, len);
            encode_data (ptr, len);
          }
          break;

        case BER_TYPE_UTF8:
          {
            STRLEN len;
            const char *ptr = SvPVutf8 (data, len);
            encode_data (ptr, len);
          }
          break;

        case BER_TYPE_IPADDRESS:
          {
            U8 ip[4];
            sscanf (SvPV_nolen (data), "%hhu.%hhu.%hhu.%hhu", ip + 0, ip + 1, ip + 2, ip + 3);
            encode_data ((const char *)ip, sizeof (ip));
          }
          break;

        case BER_TYPE_UCS2:
          encode_ucs (data, 2);
          break;

        case BER_TYPE_UCS4:
          encode_ucs (data, 4);
          break;

        case BER_TYPE_REAL:
          encode_real (data);
          break;

        case BER_TYPE_CROAK:
          croak ("class/tag %d/%d mapped to BER_TYPE_CROAK", klass, tag);

        default:
          croak ("unconfigured/unsupported class/tag %d/%d", klass, tag);
      }

}

/////////////////////////////////////////////////////////////////////////////

MODULE = Convert::BER::XS		PACKAGE = Convert::BER::XS

PROTOTYPES: ENABLE

BOOT:
{
  HV *stash = gv_stashpv ("Convert::BER::XS", 1);

  profile_stash = gv_stashpv ("Convert::BER::XS::Profile", 1);

  static const struct {
    const char *name;
    IV iv;
  } *civ, const_iv[] = {
#define const_iv(name) { # name, name },
    const_iv (ASN_BOOLEAN)
    const_iv (ASN_INTEGER)
    const_iv (ASN_BIT_STRING)
    const_iv (ASN_OCTET_STRING)
    const_iv (ASN_NULL)
    const_iv (ASN_OBJECT_IDENTIFIER)
    const_iv (ASN_OBJECT_DESCRIPTOR)
    const_iv (ASN_OID)
    const_iv (ASN_EXTERNAL)
    const_iv (ASN_REAL)
    const_iv (ASN_SEQUENCE)
    const_iv (ASN_ENUMERATED)
    const_iv (ASN_EMBEDDED_PDV)
    const_iv (ASN_UTF8_STRING)
    const_iv (ASN_RELATIVE_OID)
    const_iv (ASN_SET)
    const_iv (ASN_NUMERIC_STRING)
    const_iv (ASN_PRINTABLE_STRING)
    const_iv (ASN_TELETEX_STRING)
    const_iv (ASN_T61_STRING)
    const_iv (ASN_VIDEOTEX_STRING)
    const_iv (ASN_IA5_STRING)
    const_iv (ASN_ASCII_STRING)
    const_iv (ASN_UTC_TIME)
    const_iv (ASN_GENERALIZED_TIME)
    const_iv (ASN_GRAPHIC_STRING)
    const_iv (ASN_VISIBLE_STRING)
    const_iv (ASN_ISO646_STRING)
    const_iv (ASN_GENERAL_STRING)
    const_iv (ASN_UNIVERSAL_STRING)
    const_iv (ASN_CHARACTER_STRING)
    const_iv (ASN_BMP_STRING)

    const_iv (ASN_UNIVERSAL)
    const_iv (ASN_APPLICATION)
    const_iv (ASN_CONTEXT)
    const_iv (ASN_PRIVATE)

    const_iv (BER_CLASS)
    const_iv (BER_TAG)
    const_iv (BER_FLAGS)
    const_iv (BER_DATA)

    const_iv (BER_TYPE_BYTES)
    const_iv (BER_TYPE_UTF8)
    const_iv (BER_TYPE_UCS2)
    const_iv (BER_TYPE_UCS4)
    const_iv (BER_TYPE_INT)
    const_iv (BER_TYPE_OID)
    const_iv (BER_TYPE_RELOID)
    const_iv (BER_TYPE_NULL)
    const_iv (BER_TYPE_BOOL)
    const_iv (BER_TYPE_REAL)
    const_iv (BER_TYPE_IPADDRESS)
    const_iv (BER_TYPE_CROAK)

    const_iv (SNMP_IPADDRESS)
    const_iv (SNMP_COUNTER32)
    const_iv (SNMP_GAUGE32)
    const_iv (SNMP_UNSIGNED32)
    const_iv (SNMP_TIMETICKS)
    const_iv (SNMP_OPAQUE)
    const_iv (SNMP_COUNTER64)
  };

  for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
    newCONSTSUB (stash, (char *)civ[-1].name, newSViv (civ[-1].iv));
}

void
ber_decode (SV *ber, SV *profile = &PL_sv_undef)
	ALIAS:
        ber_decode_prefix = 1
	PPCODE:
{
        cur_profile = SvPROFILE (profile);
	STRLEN len;
        buf = (U8 *)SvPVbyte (ber, len);
        cur = buf;
        end = buf + len;

        PUTBACK;
        SV *tuple = decode_ber ();
        SPAGAIN;

        EXTEND (SP, 2);
        PUSHs (sv_2mortal (tuple));

        if (ix)
          PUSHs (sv_2mortal (newSViv (cur - buf)));
        else if (cur != end)
          error ("trailing garbage after BER value");
}

void
ber_is (SV *tuple, SV *klass = &PL_sv_undef, SV *tag = &PL_sv_undef, SV *flags = &PL_sv_undef, SV *data = &PL_sv_undef)
	PPCODE:
{
	if (!SvOK (tuple))
          XSRETURN_NO;

        if (!SvROK (tuple) || SvTYPE (SvRV (tuple)) != SVt_PVAV)
          croak ("ber_is: tuple must be BER tuple (array-ref)");

        AV *av = (AV *)SvRV (tuple);

        XPUSHs (
             (!SvOK (klass) || SvIV  (AvARRAY (av)[BER_CLASS]) == SvIV (klass))
          && (!SvOK (tag)   || SvIV  (AvARRAY (av)[BER_TAG  ]) == SvIV (tag))
          && (!SvOK (flags) || !SvIV (AvARRAY (av)[BER_FLAGS]) == !SvIV (flags))
          && (!SvOK (data)  || sv_eq (AvARRAY (av)[BER_DATA ], data))
          ? &PL_sv_yes : &PL_sv_undef);
}

void
ber_is_seq (SV *tuple)
	PPCODE:
{
	if (!SvOK (tuple))
          XSRETURN_UNDEF;

        AV *av = ber_tuple (tuple);

        XPUSHs (
             SvIV (AvARRAY (av)[BER_CLASS]) == ASN_UNIVERSAL
          && SvIV (AvARRAY (av)[BER_TAG  ]) == ASN_SEQUENCE
          && SvIV (AvARRAY (av)[BER_FLAGS])
          ? AvARRAY (av)[BER_DATA] : &PL_sv_undef);
}

void
ber_is_int (SV *tuple, SV *value = &PL_sv_undef)
	PPCODE:
{
	if (!SvOK (tuple))
          XSRETURN_NO;

        AV *av = ber_tuple (tuple);

        UV data = SvUV (AvARRAY (av)[BER_DATA]);

        XPUSHs (
               SvIV (AvARRAY (av)[BER_CLASS]) == ASN_UNIVERSAL
          &&   SvIV (AvARRAY (av)[BER_TAG  ]) == ASN_INTEGER
          &&  !SvIV (AvARRAY (av)[BER_FLAGS])
          &&  (!SvOK (value) || data == SvUV (value))
          ? sv_2mortal (data ? newSVsv (AvARRAY (av)[BER_DATA]) : newSVpv ("0 but true", 0))
          : &PL_sv_undef);
}

void
ber_is_oid (SV *tuple, SV *oid = &PL_sv_undef)
	PPCODE:
{
	if (!SvOK (tuple))
          XSRETURN_NO;

        AV *av = ber_tuple (tuple);

        XPUSHs (
              SvIV (AvARRAY (av)[BER_CLASS]) == ASN_UNIVERSAL
          &&  SvIV (AvARRAY (av)[BER_TAG  ]) == ASN_OBJECT_IDENTIFIER
          && !SvIV (AvARRAY (av)[BER_FLAGS])
          && (!SvOK (oid) || sv_eq (AvARRAY (av)[BER_DATA], oid))
          ? newSVsv (AvARRAY (av)[BER_DATA]) : &PL_sv_undef);
}

#############################################################################

void
ber_encode (SV *tuple, SV *profile = &PL_sv_undef)
	PPCODE:
{
        cur_profile = SvPROFILE (profile);
	buf_sv = sv_2mortal (NEWSV (0, 256));
        SvPOK_only (buf_sv);
        set_buf (buf_sv);

        PUTBACK;
        encode_ber (tuple);
        SPAGAIN;

        SvCUR_set (buf_sv, cur - buf);
        XPUSHs (buf_sv);
}

SV *
ber_int (SV *sv)
	CODE:
{
	AV *av = newAV ();
        av_fill (av, BER_ARRAYSIZE - 1);
        AvARRAY (av)[BER_CLASS] = newSVcacheint (ASN_UNIVERSAL);
        AvARRAY (av)[BER_TAG  ] = newSVcacheint (ASN_INTEGER);
        AvARRAY (av)[BER_FLAGS] = newSVcacheint (0);
        AvARRAY (av)[BER_DATA ] = newSVsv (sv);
        RETVAL = newRV_noinc ((SV *)av);
}
	OUTPUT: RETVAL

# TODO: not arrayref, but elements?
SV *
ber_seq (SV *arrayref)
	CODE:
{
	AV *av = newAV ();
        av_fill (av, BER_ARRAYSIZE - 1);
        AvARRAY (av)[BER_CLASS] = newSVcacheint (ASN_UNIVERSAL);
        AvARRAY (av)[BER_TAG  ] = newSVcacheint (ASN_SEQUENCE);
        AvARRAY (av)[BER_FLAGS] = newSVcacheint (1);
        AvARRAY (av)[BER_DATA ] = newSVsv (arrayref);
        RETVAL = newRV_noinc ((SV *)av);
}
	OUTPUT: RETVAL

MODULE = Convert::BER::XS		PACKAGE = Convert::BER::XS::Profile

SV *
new (SV *klass)
	CODE:
        RETVAL = profile_new ();
        OUTPUT: RETVAL

void
set (SV *profile, int klass, int tag, int type)
	CODE:
        profile_set (SvPROFILE (profile), klass, tag, type);

IV
get (SV *profile, int klass, int tag)
	CODE:
        RETVAL = profile_lookup (SvPROFILE (profile), klass, tag);
        OUTPUT: RETVAL

void
_set_default (SV *profile)
	CODE:
        default_profile = SvPROFILE (profile);


