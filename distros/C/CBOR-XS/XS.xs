#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <float.h>
#include <inttypes.h>

#define ECB_NO_THREADS 1
#include "ecb.h"

// compatibility with perl <5.18
#ifndef HvNAMELEN_get
# define HvNAMELEN_get(hv) strlen (HvNAME (hv))
#endif
#ifndef HvNAMELEN
# define HvNAMELEN(hv) HvNAMELEN_get (hv)
#endif
#ifndef HvNAMEUTF8
# define HvNAMEUTF8(hv) 0
#endif
#ifndef SvREFCNT_inc_NN
# define SvREFCNT_inc_NN(sv) SvREFCNT_inc (sv)
#endif
#ifndef SvREFCNT_dec_NN
# define SvREFCNT_dec_NN(sv) SvREFCNT_dec (sv)
#endif

// known major and minor types
enum cbor_type
{
  MAJOR_SHIFT   = 5,
  MINOR_MASK    = 0x1f,

  MAJOR_POS_INT = 0 << MAJOR_SHIFT,
  MAJOR_NEG_INT = 1 << MAJOR_SHIFT,
  MAJOR_BYTES   = 2 << MAJOR_SHIFT,
  MAJOR_TEXT    = 3 << MAJOR_SHIFT,
  MAJOR_ARRAY   = 4 << MAJOR_SHIFT,
  MAJOR_MAP     = 5 << MAJOR_SHIFT,
  MAJOR_TAG     = 6 << MAJOR_SHIFT,
  MAJOR_MISC    = 7 << MAJOR_SHIFT,

  // INT/STRING/ARRAY/MAP subtypes
  LENGTH_EXT1    = 24,
  LENGTH_EXT2    = 25,
  LENGTH_EXT4    = 26,
  LENGTH_EXT8    = 27,

  // SIMPLE types (effectively MISC subtypes)
  SIMPLE_FALSE   = 20,
  SIMPLE_TRUE    = 21,
  SIMPLE_NULL    = 22,
  SIMPLE_UNDEF   = 23,

  // MISC subtype (unused)
  MISC_EXT1      = 24,
  MISC_FLOAT16   = 25,
  MISC_FLOAT32   = 26,
  MISC_FLOAT64   = 27,

  // BYTES/TEXT/ARRAY/MAP
  MINOR_INDEF    = 31,
};

// known tags
enum cbor_tag
{
  // extensions
  CBOR_TAG_STRINGREF           =    25, // http://cbor.schmorp.de/stringref
  CBOR_TAG_PERL_OBJECT         =    26, // http://cbor.schmorp.de/perl-object
  CBOR_TAG_GENERIC_OBJECT      =    27, // http://cbor.schmorp.de/generic-object
  CBOR_TAG_VALUE_SHAREABLE     =    28, // http://cbor.schmorp.de/value-sharing
  CBOR_TAG_VALUE_SHAREDREF     =    29, // http://cbor.schmorp.de/value-sharing
  CBOR_TAG_STRINGREF_NAMESPACE =   256, // http://cbor.schmorp.de/stringref
  CBOR_TAG_INDIRECTION	       = 22098, // http://cbor.schmorp.de/indirection

  // rfc7049
  CBOR_TAG_DATETIME    =     0, // rfc4287, utf-8
  CBOR_TAG_TIMESTAMP   =     1, // unix timestamp, any
  CBOR_TAG_POS_BIGNUM  =     2, // byte string
  CBOR_TAG_NEG_BIGNUM  =     3, // byte string
  CBOR_TAG_DECIMAL     =     4, // decimal fraction, array
  CBOR_TAG_BIGFLOAT    =     5, // array

  CBOR_TAG_CONV_B64U   =    21, // base64url, any
  CBOR_TAG_CONV_B64    =    22, // base64, any
  CBOR_TAG_CONV_HEX    =    23, // base16, any
  CBOR_TAG_CBOR        =    24, // embedded cbor, byte string

  CBOR_TAG_URI         =    32, // URI rfc3986, utf-8
  CBOR_TAG_B64U        =    33, // base64url rfc4648, utf-8
  CBOR_TAG_B64         =    34, // base6 rfc46484, utf-8
  CBOR_TAG_REGEX       =    35, // regex pcre/ecma262, utf-8
  CBOR_TAG_MIME        =    36, // mime message rfc2045, utf-8

  CBOR_TAG_MAGIC       = 55799, // self-describe cbor
};

#define F_SHRINK          0x00000001UL
#define F_ALLOW_UNKNOWN   0x00000002UL
#define F_ALLOW_SHARING   0x00000004UL
#define F_ALLOW_CYCLES    0x00000008UL
#define F_FORBID_OBJECTS  0x00000010UL
#define F_PACK_STRINGS    0x00000020UL
#define F_TEXT_KEYS       0x00000040UL
#define F_TEXT_STRINGS    0x00000080UL
#define F_VALIDATE_UTF8   0x00000100UL

#define INIT_SIZE   32 // initial scalar size to be allocated

#define SB do {
#define SE } while (0)

#define IN_RANGE_INC(type,val,beg,end) \
  ((unsigned type)((unsigned type)(val) - (unsigned type)(beg)) \
  <= (unsigned type)((unsigned type)(end) - (unsigned type)(beg)))

#define ERR_NESTING_EXCEEDED "cbor text or perl structure exceeds maximum nesting level (max_depth set too low?)"

#ifdef USE_ITHREADS
# define CBOR_SLOW 1
# define CBOR_STASH (cbor_stash ? cbor_stash : gv_stashpv ("CBOR::XS", 1))
#else
# define CBOR_SLOW 0
# define CBOR_STASH cbor_stash
#endif

static HV *cbor_stash, *types_boolean_stash, *types_error_stash, *cbor_tagged_stash; // CBOR::XS::
static SV *types_true, *types_false, *types_error, *sv_cbor, *default_filter;

typedef struct {
  U32 flags;
  U32 max_depth;
  STRLEN max_size;
  SV *filter;

  // for the incremental parser
  STRLEN incr_pos; // the current offset into the text
  STRLEN incr_need; // minimum bytes needed to decode
  AV *incr_count; // for every nesting level, the number of outstanding values, or -1 for indef.
} CBOR;

ecb_inline void
cbor_init (CBOR *cbor)
{
  Zero (cbor, 1, CBOR);
  cbor->max_depth = 512;
}

ecb_inline void
cbor_free (CBOR *cbor)
{
  SvREFCNT_dec (cbor->filter);
  SvREFCNT_dec (cbor->incr_count);
}

/////////////////////////////////////////////////////////////////////////////
// utility functions

ecb_inline SV *
get_bool (const char *name)
{
  SV *sv = get_sv (name, 1);

  SvREADONLY_on (sv);
  SvREADONLY_on (SvRV (sv));

  return sv;
}

ecb_inline void
shrink (SV *sv)
{
  sv_utf8_downgrade (sv, 1);

  if (SvLEN (sv) > SvCUR (sv) + 1)
    {
#ifdef SvPV_shrink_to_cur
      SvPV_shrink_to_cur (sv);
#elif defined (SvPV_renew)
      SvPV_renew (sv, SvCUR (sv) + 1);
#endif
    }
}

// minimum length of a string to be registered for stringref
ecb_inline int
minimum_string_length (UV idx)
{
  return idx <=          23 ?  3
       : idx <=       0xffU ?  4
       : idx <=     0xffffU ?  5
       : idx <= 0xffffffffU ?  7
       :                      11;
}

/////////////////////////////////////////////////////////////////////////////
// encoder

// structure used for encoding CBOR
typedef struct
{
  char *cur;  // SvPVX (sv) + current output position
  char *end;  // SvEND (sv)
  SV *sv;     // result scalar
  CBOR cbor;
  U32 depth;  // recursion level
  HV *stringref[2]; // string => index, or 0 ([0] = bytes, [1] = utf-8)
  UV stringref_idx;
  HV *shareable; // ptr => index, or 0
  UV shareable_idx;
} enc_t;

ecb_inline void
need (enc_t *enc, STRLEN len)
{
  if (ecb_expect_false ((uintptr_t)(enc->end - enc->cur) < len))
    {
      STRLEN cur = enc->cur - (char *)SvPVX (enc->sv);
      SvGROW (enc->sv, cur + (len < (cur >> 2) ? cur >> 2 : len) + 1);
      enc->cur = SvPVX (enc->sv) + cur;
      enc->end = SvPVX (enc->sv) + SvLEN (enc->sv) - 1;
    }
}

ecb_inline void
encode_ch (enc_t *enc, char ch)
{
  need (enc, 1);
  *enc->cur++ = ch;
}

static void
encode_uint (enc_t *enc, int major, UV len)
{
   need (enc, 9);

   if (ecb_expect_true (len < LENGTH_EXT1))
      *enc->cur++ = major | len;
   else if (ecb_expect_true (len <= 0xffU))
     {
       *enc->cur++ = major | LENGTH_EXT1;
       *enc->cur++ = len;
     }
   else if (len <= 0xffffU)
     {
       *enc->cur++ = major | LENGTH_EXT2;
       *enc->cur++ = len >> 8;
       *enc->cur++ = len;
     }
   else if (len <= 0xffffffffU)
     {
       *enc->cur++ = major | LENGTH_EXT4;
       *enc->cur++ = len >> 24;
       *enc->cur++ = len >> 16;
       *enc->cur++ = len >>  8;
       *enc->cur++ = len;
     }
   else
     {
       *enc->cur++ = major | LENGTH_EXT8;
       *enc->cur++ = len >> 56;
       *enc->cur++ = len >> 48;
       *enc->cur++ = len >> 40;
       *enc->cur++ = len >> 32;
       *enc->cur++ = len >> 24;
       *enc->cur++ = len >> 16;
       *enc->cur++ = len >>  8;
       *enc->cur++ = len;
     }
}

ecb_inline void
encode_tag (enc_t *enc, UV tag)
{
  encode_uint (enc, MAJOR_TAG, tag);
}

// exceptional (hopefully) slow path for byte strings that need to be utf8-encoded
ecb_noinline static void
encode_str_utf8 (enc_t *enc, int utf8, char *str, STRLEN len)
{
  STRLEN ulen = len;
  U8 *p, *pend = (U8 *)str + len;

  for (p = (U8 *)str; p < pend; ++p)
    ulen += *p >> 7; // count set high bits

  encode_uint (enc, MAJOR_TEXT, ulen);

  need (enc, ulen);
  for (p = (U8 *)str; p < pend; ++p)
    if (*p < 0x80)
      *enc->cur++ = *p;
    else
      {
        *enc->cur++ = 0xc0 + (*p >> 6);
        *enc->cur++ = 0x80 + (*p & 63);
      }
}

ecb_inline void
encode_str (enc_t *enc, int upgrade_utf8, int utf8, char *str, STRLEN len)
{
  if (ecb_expect_false (upgrade_utf8))
    if (!utf8)
      {
        encode_str_utf8 (enc, utf8, str, len);
        return;
      }

  encode_uint (enc, utf8 ? MAJOR_TEXT : MAJOR_BYTES, len);
  need (enc, len);
  memcpy (enc->cur, str, len);
  enc->cur += len;
}

ecb_inline void
encode_strref (enc_t *enc, int upgrade_utf8, int utf8, char *str, STRLEN len)
{
  if (ecb_expect_false (enc->cbor.flags & F_PACK_STRINGS))
    {
      SV **svp = hv_fetch (enc->stringref[!!utf8], str, len, 1);

      if (SvOK (*svp))
        {
          // already registered, use stringref
          encode_tag (enc, CBOR_TAG_STRINGREF);
          encode_uint (enc, MAJOR_POS_INT, SvUV (*svp));
          return;
        }
      else if (len >= minimum_string_length (enc->stringref_idx))
        {
          // register only
          sv_setuv (*svp, enc->stringref_idx);
          ++enc->stringref_idx;
        }
    }

  encode_str (enc, upgrade_utf8, utf8, str, len);
}

static void encode_sv (enc_t *enc, SV *sv);

static void
encode_av (enc_t *enc, AV *av)
{
  int i, len = av_len (av);

  if (enc->depth >= enc->cbor.max_depth)
    croak (ERR_NESTING_EXCEEDED);

  ++enc->depth;

  encode_uint (enc, MAJOR_ARRAY, len + 1);

  if (ecb_expect_false (SvMAGICAL (av)))
    for (i = 0; i <= len; ++i)
      {
        SV **svp = av_fetch (av, i, 0);
        encode_sv (enc, svp ? *svp : &PL_sv_undef);
      }
  else
    for (i = 0; i <= len; ++i)
      {
        SV *sv = AvARRAY (av)[i];
        encode_sv (enc, sv ? sv : &PL_sv_undef);
      }

  --enc->depth;
}

static void
encode_hv (enc_t *enc, HV *hv)
{
  HE *he;

  if (enc->depth >= enc->cbor.max_depth)
    croak (ERR_NESTING_EXCEEDED);

  ++enc->depth;

  int pairs = hv_iterinit (hv);
  int mg = SvMAGICAL (hv);

  if (ecb_expect_false (mg))
    encode_ch (enc, MAJOR_MAP | MINOR_INDEF);
  else
    encode_uint (enc, MAJOR_MAP, pairs);

  while ((he = hv_iternext (hv)))
    {
      if (HeKLEN (he) == HEf_SVKEY)
        encode_sv (enc, HeSVKEY (he));
      else
        encode_strref (enc, enc->cbor.flags & (F_TEXT_KEYS | F_TEXT_STRINGS), HeKUTF8 (he), HeKEY (he), HeKLEN (he));

      encode_sv (enc, ecb_expect_false (mg) ? hv_iterval (hv, he) : HeVAL (he));
    }

  if (ecb_expect_false (mg))
    encode_ch (enc, MAJOR_MISC | MINOR_INDEF);

  --enc->depth;
}

// encode objects, arrays and special \0=false and \1=true values.
static void
encode_rv (enc_t *enc, SV *sv)
{
  SvGETMAGIC (sv);

  svtype svt = SvTYPE (sv);

  if (ecb_expect_false (SvOBJECT (sv)))
    {
      HV *boolean_stash = !CBOR_SLOW || types_boolean_stash
                          ? types_boolean_stash
                          : gv_stashpv ("Types::Serialiser::Boolean", 1);
      HV *error_stash   = !CBOR_SLOW || types_error_stash
                          ? types_error_stash
                          : gv_stashpv ("Types::Serialiser::Error", 1);
      HV *tagged_stash  = !CBOR_SLOW || cbor_tagged_stash
                          ? cbor_tagged_stash
                          : gv_stashpv ("CBOR::XS::Tagged" , 1);

      HV *stash = SvSTASH (sv);

      if (stash == boolean_stash)
        {
          encode_ch (enc, SvIV (sv) ? MAJOR_MISC | SIMPLE_TRUE : MAJOR_MISC | SIMPLE_FALSE);
          return;
        }
      else if (stash == error_stash)
        {
          encode_ch (enc, MAJOR_MISC | SIMPLE_UNDEF);
          return;
        }
      else if (stash == tagged_stash)
        {
          if (svt != SVt_PVAV)
            croak ("encountered CBOR::XS::Tagged object that isn't an array");

          encode_uint (enc, MAJOR_TAG, SvUV (*av_fetch ((AV *)sv, 0, 1)));
          encode_sv (enc, *av_fetch ((AV *)sv, 1, 1));

          return;
        }
    }

  if (ecb_expect_false (SvREFCNT (sv) > 1)
      && ecb_expect_false (enc->cbor.flags & F_ALLOW_SHARING))
    {
      if (ecb_expect_false (!enc->shareable))
        enc->shareable = (HV *)sv_2mortal ((SV *)newHV ());

      SV **svp = hv_fetch (enc->shareable, (char *)&sv, sizeof (sv), 1);

      if (SvOK (*svp))
        {
          encode_tag (enc, CBOR_TAG_VALUE_SHAREDREF);
          encode_uint (enc, MAJOR_POS_INT, SvUV (*svp));
          return;
        }
      else
        {
          sv_setuv (*svp, enc->shareable_idx);
          ++enc->shareable_idx;
          encode_tag (enc, CBOR_TAG_VALUE_SHAREABLE);
        }
    }

  if (ecb_expect_false (SvOBJECT (sv)))
    {
      HV *stash = SvSTASH (sv);
      GV *method;

      if (enc->cbor.flags & F_FORBID_OBJECTS)
        croak ("encountered object '%s', but forbid_objects is enabled",
               SvPV_nolen (sv_2mortal (newRV_inc (sv))));
      else if ((method = gv_fetchmethod_autoload (stash, "TO_CBOR", 0)))
        {
          dSP;

          ENTER; SAVETMPS;
          PUSHMARK (SP);
          // we re-bless the reference to get overload and other niceties right
          XPUSHs (sv_bless (sv_2mortal (newRV_inc (sv)), stash));

          PUTBACK;
          // G_SCALAR ensures that return value is 1
          call_sv ((SV *)GvCV (method), G_SCALAR);
          SPAGAIN;

          // catch this surprisingly common error
          if (SvROK (TOPs) && SvRV (TOPs) == sv)
            croak ("%s::TO_CBOR method returned same object as was passed instead of a new one", HvNAME (stash));

          encode_sv (enc, POPs);

          PUTBACK;

          FREETMPS; LEAVE;
        }
      else if ((method = gv_fetchmethod_autoload (stash, "FREEZE", 0)) != 0)
        {
          dSP;

          ENTER; SAVETMPS;
          SAVESTACK_POS ();
          PUSHMARK (SP);
          EXTEND (SP, 2);
          // we re-bless the reference to get overload and other niceties right
          PUSHs (sv_bless (sv_2mortal (newRV_inc (sv)), stash));
          PUSHs (sv_cbor);

          PUTBACK;
          int count = call_sv ((SV *)GvCV (method), G_ARRAY);
          SPAGAIN;

          // catch this surprisingly common error
          if (count == 1 && SvROK (TOPs) && SvRV (TOPs) == sv)
            croak ("%s::FREEZE(CBOR) method returned same object as was passed instead of a new one", HvNAME (stash));

          encode_tag (enc, CBOR_TAG_PERL_OBJECT);
          encode_uint (enc, MAJOR_ARRAY, count + 1);
          encode_strref (enc, 0, HvNAMEUTF8 (stash), HvNAME (stash), HvNAMELEN (stash));

          while (count)
            encode_sv (enc, SP[1 - count--]);

          PUTBACK;

          FREETMPS; LEAVE;
        }
      else
        croak ("encountered object '%s', but no TO_CBOR or FREEZE methods available on it",
               SvPV_nolen (sv_2mortal (newRV_inc (sv))));
    }
  else if (svt == SVt_PVHV)
    encode_hv (enc, (HV *)sv);
  else if (svt == SVt_PVAV)
    encode_av (enc, (AV *)sv);
  else
    {
      encode_tag (enc, CBOR_TAG_INDIRECTION);
      encode_sv (enc, sv);
    }
}

static void
encode_nv (enc_t *enc, SV *sv)
{
  double nv = SvNVX (sv);

  need (enc, 9);

  if (ecb_expect_false (nv == (NV)(U32)nv))
    encode_uint (enc, MAJOR_POS_INT, (U32)nv);
  //TODO: maybe I32?
  else if (ecb_expect_false (nv == (float)nv))
    {
      *enc->cur++ = MAJOR_MISC | MISC_FLOAT32;

      uint32_t fp = ecb_float_to_binary32 (nv);

      if (!ecb_big_endian ())
        fp = ecb_bswap32 (fp);

      memcpy (enc->cur, &fp, 4);
      enc->cur += 4;
    }
  else
    {
      *enc->cur++ = MAJOR_MISC | MISC_FLOAT64;

      uint64_t fp = ecb_double_to_binary64 (nv);

      if (!ecb_big_endian ())
        fp = ecb_bswap64 (fp);

      memcpy (enc->cur, &fp, 8);
      enc->cur += 8;
    }
}

static void
encode_sv (enc_t *enc, SV *sv)
{
  SvGETMAGIC (sv);

  if (SvPOKp (sv))
    {
      STRLEN len;
      char *str = SvPV (sv, len);
      encode_strref (enc, enc->cbor.flags & F_TEXT_STRINGS, SvUTF8 (sv), str, len);
    }
  else if (SvNOKp (sv))
    encode_nv (enc, sv);
  else if (SvIOKp (sv))
    {
      if (SvIsUV (sv))
        encode_uint (enc, MAJOR_POS_INT, SvUVX (sv));
      else if (SvIVX (sv) >= 0)
        encode_uint (enc, MAJOR_POS_INT, SvIVX (sv));
      else
        encode_uint (enc, MAJOR_NEG_INT, -(SvIVX (sv) + 1));
    }
  else if (SvROK (sv))
    encode_rv (enc, SvRV (sv));
  else if (!SvOK (sv))
    encode_ch (enc, MAJOR_MISC | SIMPLE_NULL);
  else if (enc->cbor.flags & F_ALLOW_UNKNOWN)
    encode_ch (enc, MAJOR_MISC | SIMPLE_UNDEF);
  else
    croak ("encountered perl type (%s,0x%x) that CBOR cannot handle, check your input data",
           SvPV_nolen (sv), (unsigned int)SvFLAGS (sv));
}

static SV *
encode_cbor (SV *scalar, CBOR *cbor)
{
  enc_t enc = { 0 };

  enc.cbor = *cbor;
  enc.sv   = sv_2mortal (NEWSV (0, INIT_SIZE));
  enc.cur  = SvPVX (enc.sv);
  enc.end  = SvEND (enc.sv);

  SvPOK_only (enc.sv);

  if (cbor->flags & F_PACK_STRINGS)
    {
      encode_tag (&enc, CBOR_TAG_STRINGREF_NAMESPACE);
      enc.stringref[0]= (HV *)sv_2mortal ((SV *)newHV ());
      enc.stringref[1]= (HV *)sv_2mortal ((SV *)newHV ());
    }

  encode_sv (&enc, scalar);

  SvCUR_set (enc.sv, enc.cur - SvPVX (enc.sv));
  *SvEND (enc.sv) = 0; // many xs functions expect a trailing 0 for text strings

  if (enc.cbor.flags & F_SHRINK)
    shrink (enc.sv);

  return enc.sv;
}

/////////////////////////////////////////////////////////////////////////////
// decoder

// structure used for decoding CBOR
typedef struct
{
  U8 *cur; // current parser pointer
  U8 *end; // end of input string
  const char *err; // parse error, if != 0
  CBOR cbor;
  U32 depth; // recursion depth
  U32 maxdepth; // recursion depth limit
  AV *shareable;
  AV *stringref;
  SV *decode_tagged;
  SV *err_sv; // optional sv for error, needs to be freed
} dec_t;

// set dec->err to ERRSV
ecb_cold static void
err_errsv (dec_t *dec)
{
  if (!dec->err)
    {
      dec->err_sv = newSVsv (ERRSV);

      // chop off the trailing \n
      SvCUR_set (dec->err_sv, SvCUR (dec->err_sv) - 1);
      *SvEND (dec->err_sv) = 0;

      dec->err = SvPVutf8_nolen (dec->err_sv);
    }
}

// the following functions are used to reduce code size and help the compiler to optimise
ecb_cold static void
err_set (dec_t *dec, const char *reason)
{
  if (!dec->err)
    dec->err = reason;
}

ecb_cold static void
err_unexpected_end (dec_t *dec)
{
  err_set (dec, "unexpected end of CBOR data");
}

#define ERR_DO(do) SB do; goto fail; SE
#define ERR(reason) ERR_DO (err_set (dec, reason))
#define ERR_ERRSV ERR_DO (err_errsv (dec))

#define WANT(len) if (ecb_expect_false ((uintptr_t)(dec->end - dec->cur) < (STRLEN)len)) ERR_DO (err_unexpected_end (dec))

#define DEC_INC_DEPTH if (ecb_expect_false (++dec->depth > dec->cbor.max_depth)) ERR (ERR_NESTING_EXCEEDED)
#define DEC_DEC_DEPTH --dec->depth

static UV
decode_uint (dec_t *dec)
{
  U8 m = *dec->cur & MINOR_MASK;
  ++dec->cur;

  if (ecb_expect_true (m < LENGTH_EXT1))
    return m;
  else if (ecb_expect_true (m == LENGTH_EXT1))
    {
      WANT (1);
      dec->cur += 1;
      return dec->cur[-1];
    }
  else if (ecb_expect_true (m == LENGTH_EXT2))
    {
      WANT (2);
      dec->cur += 2;
      return (((UV)dec->cur[-2]) <<  8)
           |  ((UV)dec->cur[-1]);
    }
  else if (ecb_expect_true (m == LENGTH_EXT4))
    {
      WANT (4);
      dec->cur += 4;
      return (((UV)dec->cur[-4]) << 24)
           | (((UV)dec->cur[-3]) << 16)
           | (((UV)dec->cur[-2]) <<  8)
           |  ((UV)dec->cur[-1]);
    }
  else if (ecb_expect_true (m == LENGTH_EXT8))
    {
      WANT (8);
      dec->cur += 8;

      return
#if UVSIZE < 8
             0
#else
             (((UV)dec->cur[-8]) << 56)
           | (((UV)dec->cur[-7]) << 48)
           | (((UV)dec->cur[-6]) << 40)
           | (((UV)dec->cur[-5]) << 32)
#endif
           | (((UV)dec->cur[-4]) << 24)
           | (((UV)dec->cur[-3]) << 16)
           | (((UV)dec->cur[-2]) <<  8)
           |  ((UV)dec->cur[-1]);
    }
  else
    ERR ("corrupted CBOR data (unsupported integer minor encoding)");

fail:
  return 0;
}

static SV *decode_sv (dec_t *dec);

static SV *
decode_av (dec_t *dec)
{
  AV *av = newAV ();

  DEC_INC_DEPTH;

  if (*dec->cur == (MAJOR_ARRAY | MINOR_INDEF))
    {
      ++dec->cur;

      for (;;)
        {
          WANT (1);

          if (*dec->cur == (MAJOR_MISC | MINOR_INDEF))
            {
              ++dec->cur;
              break;
            }

          av_push (av, decode_sv (dec));
        }
    }
  else
    {
      UV i, len = decode_uint (dec);

      WANT (len); // complexity check for av_fill - need at least one byte per value, do not allow supersize arrays
      av_fill (av, len - 1);

      for (i = 0; i < len; ++i)
        AvARRAY (av)[i] = decode_sv (dec);
    }

  DEC_DEC_DEPTH;
  return newRV_noinc ((SV *)av);

fail:
  SvREFCNT_dec_NN (av);
  DEC_DEC_DEPTH;
  return &PL_sv_undef;
}

static void
decode_he (dec_t *dec, HV *hv)
{
  // for speed reasons, we specialcase single-string
  // byte or utf-8 strings as keys, but only when !stringref

  if (ecb_expect_true (!dec->stringref))
    if (ecb_expect_true ((U8)(*dec->cur - MAJOR_BYTES) <= LENGTH_EXT8))
      {
        STRLEN len = decode_uint (dec);
        char *key = (char *)dec->cur;

        WANT (len);
        dec->cur += len;

        hv_store (hv, key, len, decode_sv (dec), 0);

        return;
      }
    else if (ecb_expect_true ((U8)(*dec->cur - MAJOR_TEXT) <= LENGTH_EXT8))
      {
        STRLEN len = decode_uint (dec);
        char *key = (char *)dec->cur;

        WANT (len);
        dec->cur += len;

        if (ecb_expect_false (dec->cbor.flags & F_VALIDATE_UTF8))
          if (!is_utf8_string (key, len))
            ERR ("corrupted CBOR data (invalid UTF-8 in map key)");

        hv_store (hv, key, -len, decode_sv (dec), 0);

        return;
      }

  SV *k = decode_sv (dec);
  SV *v = decode_sv (dec);

  // we leak memory if uncaught exceptions are thrown by random magical
  // methods, and this is hopefully the only place where it can happen,
  // so if there is a chance of an exception, take the very slow path.
  // since catching exceptions is "undocumented/internal/forbidden" by
  // the new p5p powers, we need to call out to a perl function :/
  if (ecb_expect_false (SvAMAGIC (k)))
    {
      dSP;

      ENTER; SAVETMPS;
      PUSHMARK (SP);
      EXTEND (SP, 3);
      PUSHs (sv_2mortal (newRV_inc ((SV *)hv)));
      PUSHs (sv_2mortal (k));
      PUSHs (sv_2mortal (v));

      PUTBACK;
      call_pv ("CBOR::XS::_hv_store", G_VOID | G_DISCARD | G_EVAL);
      SPAGAIN;

      FREETMPS; LEAVE;

      if (SvTRUE (ERRSV))
        ERR_ERRSV;

      return;
    }

  hv_store_ent (hv, k, v, 0);
  SvREFCNT_dec_NN (k);

fail:
  ;
}

static SV *
decode_hv (dec_t *dec)
{
  HV *hv = newHV ();

  DEC_INC_DEPTH;

  if (*dec->cur == (MAJOR_MAP | MINOR_INDEF))
    {
      ++dec->cur;

      for (;;)
        {
          WANT (1);

          if (*dec->cur == (MAJOR_MISC | MINOR_INDEF))
            {
              ++dec->cur;
              break;
            }

          decode_he (dec, hv);
        }
    }
  else
    {
      UV pairs = decode_uint (dec);

      WANT (pairs); // complexity check - need at least one byte per value, do not allow supersize hashes

      while (pairs--)
        decode_he (dec, hv);
    }

  DEC_DEC_DEPTH;
  return newRV_noinc ((SV *)hv);

fail:
  SvREFCNT_dec_NN (hv);
  DEC_DEC_DEPTH;
  return &PL_sv_undef;
}

static SV *
decode_str (dec_t *dec, int utf8)
{
  SV *sv = 0;

  if (ecb_expect_false ((*dec->cur & MINOR_MASK) == MINOR_INDEF))
    {
      // indefinite length strings
      ++dec->cur;

      U8 major = *dec->cur & MAJOR_MISC;

      sv = newSVpvn ("", 0);

      for (;;)
        {
          WANT (1);

          if ((*dec->cur - major) > LENGTH_EXT8)
            if (*dec->cur == (MAJOR_MISC | MINOR_INDEF))
              {
                ++dec->cur;
                break;
              }
            else
              ERR ("corrupted CBOR data (invalid chunks in indefinite length string)");

          STRLEN len = decode_uint (dec);

          WANT (len);
          sv_catpvn (sv, dec->cur, len);
          dec->cur += len;
        }
    }
  else
    {
      STRLEN len = decode_uint (dec);

      WANT (len);
      sv = newSVpvn (dec->cur, len);
      dec->cur += len;

      if (ecb_expect_false (dec->stringref)
          && SvCUR (sv) >= minimum_string_length (AvFILLp (dec->stringref) + 1))
        av_push (dec->stringref, SvREFCNT_inc_NN (sv));
    }

  if (utf8)
    {
      if (ecb_expect_false (dec->cbor.flags & F_VALIDATE_UTF8))
        if (!is_utf8_string (SvPVX (sv), SvCUR (sv)))
          ERR ("corrupted CBOR data (invalid UTF-8 in text string)");

      SvUTF8_on (sv);
    }

  return sv;

fail:
  SvREFCNT_dec (sv);
  return &PL_sv_undef;
}

static SV *
decode_tagged (dec_t *dec)
{
  SV *sv = 0;
  UV tag = decode_uint (dec);

  WANT (1);

  switch (tag)
    {
      case CBOR_TAG_MAGIC:
        sv = decode_sv (dec);
        break;

      case CBOR_TAG_INDIRECTION:
        sv = newRV_noinc (decode_sv (dec));
        break;

      case CBOR_TAG_STRINGREF_NAMESPACE:
        {
          // do not use SAVETMPS/FREETMPS, as these will
          // erase mortalised caches, e.g. "shareable"
          ENTER;

          SAVESPTR (dec->stringref);
          dec->stringref = (AV *)sv_2mortal ((SV *)newAV ());

          sv = decode_sv (dec);

          LEAVE;
        }
        break;

      case CBOR_TAG_STRINGREF:
        {
          if ((*dec->cur >> MAJOR_SHIFT) != (MAJOR_POS_INT >> MAJOR_SHIFT))
            ERR ("corrupted CBOR data (stringref index not an unsigned integer)");

          UV idx = decode_uint (dec);

          if (!dec->stringref || (int)idx > AvFILLp (dec->stringref))
            ERR ("corrupted CBOR data (stringref index out of bounds or outside namespace)");

          sv = newSVsv (AvARRAY (dec->stringref)[idx]);
        }
        break;

      case CBOR_TAG_VALUE_SHAREABLE:
        {
          if (ecb_expect_false (!dec->shareable))
            dec->shareable = (AV *)sv_2mortal ((SV *)newAV ());

          if (dec->cbor.flags & F_ALLOW_CYCLES)
            {
              sv = newSV (0);
              av_push (dec->shareable, SvREFCNT_inc_NN (sv));

              SV *osv = decode_sv (dec);
              sv_setsv (sv, osv);
              SvREFCNT_dec_NN (osv);
            }
          else
            {
              av_push (dec->shareable, &PL_sv_undef);
              int idx = AvFILLp (dec->shareable);
              sv = decode_sv (dec);
              av_store (dec->shareable, idx, SvREFCNT_inc_NN (sv));
            }
        }
        break;

      case CBOR_TAG_VALUE_SHAREDREF:
        {
          if ((*dec->cur >> MAJOR_SHIFT) != (MAJOR_POS_INT >> MAJOR_SHIFT))
            ERR ("corrupted CBOR data (sharedref index not an unsigned integer)");

          UV idx = decode_uint (dec);

          if (!dec->shareable || (int)idx > AvFILLp (dec->shareable))
            ERR ("corrupted CBOR data (sharedref index out of bounds)");

          sv = SvREFCNT_inc_NN (AvARRAY (dec->shareable)[idx]);

          if (sv == &PL_sv_undef)
            ERR ("cyclic CBOR data structure found, but allow_cycles is not enabled");
        }
        break;

      case CBOR_TAG_PERL_OBJECT:
        {
          if (dec->cbor.flags & F_FORBID_OBJECTS)
            goto filter;

          sv = decode_sv (dec);

          if (!SvROK (sv) || SvTYPE (SvRV (sv)) != SVt_PVAV)
            ERR ("corrupted CBOR data (non-array perl object)");

          AV *av = (AV *)SvRV (sv);
          int len = av_len (av) + 1;
          HV *stash = gv_stashsv (*av_fetch (av, 0, 1), 0);

          if (!stash)
            ERR ("cannot decode perl-object (package does not exist)");

          GV *method = gv_fetchmethod_autoload (stash, "THAW", 0);
          
          if (!method)
            ERR ("cannot decode perl-object (package does not have a THAW method)");
          
          dSP;

          ENTER; SAVETMPS;
          PUSHMARK (SP);
          EXTEND (SP, len + 1);
          // we re-bless the reference to get overload and other niceties right
          PUSHs (*av_fetch (av, 0, 1));
          PUSHs (sv_cbor);

          int i;

          for (i = 1; i < len; ++i)
            PUSHs (*av_fetch (av, i, 1));

          PUTBACK;
          call_sv ((SV *)GvCV (method), G_SCALAR | G_EVAL);
          SPAGAIN;

          if (SvTRUE (ERRSV))
            {
              FREETMPS; LEAVE;
              ERR_ERRSV;
            }

          SvREFCNT_dec_NN (sv);
          sv = SvREFCNT_inc (POPs);

          PUTBACK;

          FREETMPS; LEAVE;
        }
        break;

      default:
      filter:
        {
          SV *tag_sv = newSVuv (tag);

          sv = decode_sv (dec);

          dSP;
          ENTER; SAVETMPS;
          SAVESTACK_POS ();
          PUSHMARK (SP);
          EXTEND (SP, 2);
          PUSHs (tag_sv);
          PUSHs (sv);

          PUTBACK;
          int count = call_sv (dec->cbor.filter ? dec->cbor.filter : default_filter, G_ARRAY | G_EVAL);
          SPAGAIN;

          if (SvTRUE (ERRSV))
            {
              SvREFCNT_dec_NN (tag_sv);
              FREETMPS; LEAVE;
              ERR_ERRSV;
            }

          if (count)
            {
              SvREFCNT_dec_NN (tag_sv);
              SvREFCNT_dec_NN (sv);
              sv = SvREFCNT_inc_NN (POPs);
            }
          else
            {
              AV *av = newAV ();
              av_push (av, tag_sv);
              av_push (av, sv);

              HV *tagged_stash  = !CBOR_SLOW || cbor_tagged_stash
                                  ? cbor_tagged_stash
                                  : gv_stashpv ("CBOR::XS::Tagged" , 1);
              sv = sv_bless (newRV_noinc ((SV *)av), tagged_stash);
            }

          PUTBACK;

          FREETMPS; LEAVE;
        }
        break;
    }

  return sv;

fail:
  SvREFCNT_dec (sv);
  return &PL_sv_undef;
}

static SV *
decode_sv (dec_t *dec)
{
  WANT (1);

  switch (*dec->cur >> MAJOR_SHIFT)
    {
      case MAJOR_POS_INT >> MAJOR_SHIFT: return newSVuv (decode_uint (dec));
      case MAJOR_NEG_INT >> MAJOR_SHIFT: return newSViv (-1 - (IV)decode_uint (dec));
      case MAJOR_BYTES   >> MAJOR_SHIFT: return decode_str (dec, 0);
      case MAJOR_TEXT    >> MAJOR_SHIFT: return decode_str (dec, 1);
      case MAJOR_ARRAY   >> MAJOR_SHIFT: return decode_av (dec);
      case MAJOR_MAP     >> MAJOR_SHIFT: return decode_hv (dec);
      case MAJOR_TAG     >> MAJOR_SHIFT: return decode_tagged (dec);

      case MAJOR_MISC    >> MAJOR_SHIFT:
        switch (*dec->cur++ & MINOR_MASK)
          {
            case SIMPLE_FALSE:
#if CBOR_SLOW
              types_false = get_bool ("Types::Serialiser::false");
#endif
              return newSVsv (types_false);
            case SIMPLE_TRUE:
#if CBOR_SLOW
              types_true = get_bool ("Types::Serialiser::true");
#endif
              return newSVsv (types_true);
            case SIMPLE_NULL:
              return newSVsv (&PL_sv_undef);
            case SIMPLE_UNDEF:
#if CBOR_SLOW
              types_error = get_bool ("Types::Serialiser::error");
#endif
              return newSVsv (types_error);

            case MISC_FLOAT16:
              {
                WANT (2);

                uint16_t fp = (dec->cur[0] << 8) | dec->cur[1];
                dec->cur += 2;

                return newSVnv (ecb_binary16_to_float (fp));
              }

            case MISC_FLOAT32:
              {
                uint32_t fp;
                WANT (4);
                memcpy (&fp, dec->cur, 4);
                dec->cur += 4;

                if (!ecb_big_endian ())
                  fp = ecb_bswap32 (fp);

                return newSVnv (ecb_binary32_to_float (fp));
              }

            case MISC_FLOAT64:
              {
                uint64_t fp;
                WANT (8);
                memcpy (&fp, dec->cur, 8);
                dec->cur += 8;

                if (!ecb_big_endian ())
                  fp = ecb_bswap64 (fp);

                return newSVnv (ecb_binary64_to_double (fp));
              }

            // 0..19 unassigned simple
            // 24 reserved + unassigned simple (reserved values are not encodable)
            // 28-30 unassigned misc
            // 31 break code
            default:
              ERR ("corrupted CBOR data (reserved/unassigned/unexpected major 7 value)");
          }

        break;
  }

fail:
  return &PL_sv_undef;
}

static SV *
decode_cbor (SV *string, CBOR *cbor, char **offset_return)
{
  dec_t dec = { 0 };
  SV *sv;
  STRLEN len;
  char *data = SvPVbyte (string, len);

  if (len > cbor->max_size && cbor->max_size)
    croak ("attempted decode of CBOR text of %lu bytes size, but max_size is set to %lu",
           (unsigned long)len, (unsigned long)cbor->max_size);

  dec.cbor  = *cbor;
  dec.cur   = (U8 *)data;
  dec.end   = (U8 *)data + len;

  sv = decode_sv (&dec);

  if (offset_return)
    *offset_return = dec.cur;

  if (!(offset_return || !sv))
    if (dec.cur != dec.end && !dec.err)
      dec.err = "garbage after CBOR object";

  if (dec.err)
    {
      if (dec.shareable)
        {
          // need to break cyclic links, which would all be in shareable
          int i;
          SV **svp;

          for (i = av_len (dec.shareable) + 1; i--; )
            if ((svp = av_fetch (dec.shareable, i, 0)))
              sv_setsv (*svp, &PL_sv_undef);
        }

      SvREFCNT_dec_NN (sv);

      if (dec.err_sv)
        sv_2mortal (dec.err_sv);

      croak ("%s, at offset %d (octet 0x%02x)", dec.err, dec.cur - (U8 *)data, (int)(uint8_t)*dec.cur);
    }

  sv = sv_2mortal (sv);

  return sv;
}

/////////////////////////////////////////////////////////////////////////////
// incremental parser

#define INCR_DONE(cbor) (AvFILLp (cbor->incr_count) < 0)

// returns 0 for notyet, 1 for success or error
static int
incr_parse (CBOR *self, SV *cborstr)
{
  STRLEN cur;
  SvPV (cborstr, cur);

  while (ecb_expect_true (self->incr_need <= cur))
    {
      // table of integer count bytes
      static I8 incr_len[MINOR_MASK + 1] = {
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        1, 2, 4, 8,-1,-1,-1,-2
      };

      const U8 *p = SvPVX (cborstr) + self->incr_pos;
      U8 m = *p & MINOR_MASK;
      IV count = SvIVX (AvARRAY (self->incr_count)[AvFILLp (self->incr_count)]);
      I8 ilen = incr_len[m];

      self->incr_need = self->incr_pos + 1;

      if (ecb_expect_false (ilen < 0))
        {
          if (m != MINOR_INDEF)
            return 1; // error

          if (*p == (MAJOR_MISC | MINOR_INDEF))
            {
              if (count >= 0)
                return 1; // error

              count = 1;
            }
          else
            {
              av_push (self->incr_count, newSViv (-1)); //TODO: nest
              count = -1;
            }
        }
      else
        {
          self->incr_need += ilen;
          if (ecb_expect_false (self->incr_need > cur))
            return 0;

          int major = *p >> MAJOR_SHIFT;

          switch (major)
            {
              case MAJOR_TAG     >> MAJOR_SHIFT:
                ++count; // tags merely prefix another value
                break;

              case MAJOR_BYTES   >> MAJOR_SHIFT:
              case MAJOR_TEXT    >> MAJOR_SHIFT:
              case MAJOR_ARRAY   >> MAJOR_SHIFT:
              case MAJOR_MAP     >> MAJOR_SHIFT:
                {
                  UV len;

                  if (ecb_expect_false (ilen))
                    {
                      len = 0;

                      do {
                        len = (len << 8) | *++p;
                      } while (--ilen);
                    }
                  else
                    len = m;

                  switch (major)
                    {
                      case MAJOR_BYTES   >> MAJOR_SHIFT:
                      case MAJOR_TEXT    >> MAJOR_SHIFT:
                        self->incr_need += len;
                        if (ecb_expect_false (self->incr_need > cur))
                          return 0;

                        break;

                      case MAJOR_MAP     >> MAJOR_SHIFT:
                        len <<= 1;
                      case MAJOR_ARRAY   >> MAJOR_SHIFT:
                        if (len)
                          {
                            av_push (self->incr_count, newSViv (len + 1)); //TODO: nest
                            count = len + 1;
                          }
                        break;
                    }
                }
            }
        }

      self->incr_pos = self->incr_need;

      if (count > 0)
        {
          while (!--count)
            {
              if (!AvFILLp (self->incr_count))
                return 1; // done

              SvREFCNT_dec_NN (av_pop (self->incr_count));
              count = SvIVX (AvARRAY (self->incr_count)[AvFILLp (self->incr_count)]);
            }

          SvIVX (AvARRAY (self->incr_count)[AvFILLp (self->incr_count)]) = count;
        }
    }

  return 0;
}

                  
/////////////////////////////////////////////////////////////////////////////
// XS interface functions

MODULE = CBOR::XS		PACKAGE = CBOR::XS

BOOT:
{
	cbor_stash         = gv_stashpv ("CBOR::XS"         , 1);
	cbor_tagged_stash  = gv_stashpv ("CBOR::XS::Tagged" , 1);

	types_boolean_stash = gv_stashpv ("Types::Serialiser::Boolean", 1);
	types_error_stash   = gv_stashpv ("Types::Serialiser::Error"  , 1);

        types_true  = get_bool ("Types::Serialiser::true" );
        types_false = get_bool ("Types::Serialiser::false");
        types_error = get_bool ("Types::Serialiser::error");

        default_filter = newSVpv ("CBOR::XS::default_filter", 0);

        sv_cbor = newSVpv ("CBOR", 0);
        SvREADONLY_on (sv_cbor);

        assert (("STRLEN must be an unsigned type", 0 <= (STRLEN)-1));
}

PROTOTYPES: DISABLE

void CLONE (...)
	CODE:
        cbor_stash          = 0;
        cbor_tagged_stash   = 0;
        types_error_stash   = 0;
        types_boolean_stash = 0;

void new (char *klass)
	PPCODE:
{
	SV *pv = NEWSV (0, sizeof (CBOR));
        SvPOK_only (pv);
        cbor_init ((CBOR *)SvPVX (pv));
        XPUSHs (sv_2mortal (sv_bless (
           newRV_noinc (pv),
           strEQ (klass, "CBOR::XS") ? CBOR_STASH : gv_stashpv (klass, 1)
        )));
}

void shrink (CBOR *self, int enable = 1)
	ALIAS:
        shrink          = F_SHRINK
        allow_unknown   = F_ALLOW_UNKNOWN
        allow_sharing   = F_ALLOW_SHARING
        allow_cycles    = F_ALLOW_CYCLES
        forbid_objects  = F_FORBID_OBJECTS
        pack_strings    = F_PACK_STRINGS
        text_keys       = F_TEXT_KEYS
        text_strings    = F_TEXT_STRINGS
        validate_utf8   = F_VALIDATE_UTF8
	PPCODE:
{
        if (enable)
          self->flags |=  ix;
        else
          self->flags &= ~ix;

        XPUSHs (ST (0));
}

void get_shrink (CBOR *self)
	ALIAS:
        get_shrink          = F_SHRINK
        get_allow_unknown   = F_ALLOW_UNKNOWN
        get_allow_sharing   = F_ALLOW_SHARING
        get_allow_cycles    = F_ALLOW_CYCLES
        get_forbid_objects  = F_FORBID_OBJECTS
        get_pack_strings    = F_PACK_STRINGS
        get_text_keys       = F_TEXT_KEYS
        get_text_strings    = F_TEXT_STRINGS
        get_validate_utf8   = F_VALIDATE_UTF8
	PPCODE:
        XPUSHs (boolSV (self->flags & ix));

void max_depth (CBOR *self, U32 max_depth = 0x80000000UL)
	PPCODE:
        self->max_depth = max_depth;
        XPUSHs (ST (0));

U32 get_max_depth (CBOR *self)
	CODE:
        RETVAL = self->max_depth;
	OUTPUT:
        RETVAL

void max_size (CBOR *self, U32 max_size = 0)
	PPCODE:
        self->max_size = max_size;
        XPUSHs (ST (0));

int get_max_size (CBOR *self)
	CODE:
        RETVAL = self->max_size;
	OUTPUT:
        RETVAL

void filter (CBOR *self, SV *filter = 0)
	PPCODE:
        SvREFCNT_dec (self->filter);
        self->filter = filter ? newSVsv (filter) : filter;
        XPUSHs (ST (0));

SV *get_filter (CBOR *self)
	CODE:
        RETVAL = self->filter ? self->filter : NEWSV (0, 0);
	OUTPUT:
        RETVAL

void encode (CBOR *self, SV *scalar)
	PPCODE:
        PUTBACK; scalar = encode_cbor (scalar, self); SPAGAIN;
        XPUSHs (scalar);

void decode (CBOR *self, SV *cborstr)
	PPCODE:
        PUTBACK; cborstr = decode_cbor (cborstr, self, 0); SPAGAIN;
        XPUSHs (cborstr);

void decode_prefix (CBOR *self, SV *cborstr)
	PPCODE:
{
	SV *sv;
        char *offset;
        PUTBACK; sv = decode_cbor (cborstr, self, &offset); SPAGAIN;
        EXTEND (SP, 2);
        PUSHs (sv);
        PUSHs (sv_2mortal (newSVuv (offset - SvPVX (cborstr))));
}

void incr_parse (CBOR *self, SV *cborstr)
	ALIAS:
        incr_parse_multiple = 1
	PPCODE:
{
        if (SvUTF8 (cborstr))
          sv_utf8_downgrade (cborstr, 0);

        if (!self->incr_count)
          {
            self->incr_count = newAV ();
            self->incr_pos   = 0;
            self->incr_need  = 1;

            av_push (self->incr_count, newSViv (1));
          }

        do
          {
            if (!incr_parse (self, cborstr))
              {
                if (self->incr_need > self->max_size && self->max_size)
                  croak ("attempted decode of CBOR text of %lu bytes size, but max_size is set to %lu",
                         (unsigned long)self->incr_need, (unsigned long)self->max_size);

                break;
              }

            SV *sv;
            char *offset;

            PUTBACK; sv = decode_cbor (cborstr, self, &offset); SPAGAIN;
            XPUSHs (sv);

            sv_chop (cborstr, offset);

            av_clear (self->incr_count);
            av_push (self->incr_count, newSViv (1));

            self->incr_pos = 0;
            self->incr_need = self->incr_pos + 1;
          }
        while (ix);
}

void incr_reset (CBOR *self)
	CODE:
{
	SvREFCNT_dec (self->incr_count);
        self->incr_count = 0;
}

void DESTROY (CBOR *self)
	PPCODE:
	cbor_free (self);

PROTOTYPES: ENABLE

void encode_cbor (SV *scalar)
	ALIAS:
        encode_cbor         = 0
        encode_cbor_sharing = F_ALLOW_SHARING
	PPCODE:
{
        CBOR cbor;
        cbor_init (&cbor);
        cbor.flags |= ix;
        PUTBACK; scalar = encode_cbor (scalar, &cbor); SPAGAIN;
        XPUSHs (scalar);
}

void decode_cbor (SV *cborstr)
	PPCODE:
{
        CBOR cbor;
        cbor_init (&cbor);
        PUTBACK; cborstr = decode_cbor (cborstr, &cbor, 0); SPAGAIN;
        XPUSHs (cborstr);
}

