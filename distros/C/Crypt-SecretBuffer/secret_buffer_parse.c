
/* These local parse functions are independenct of the SecretBuffer instance,
 * needing only the 'data' pointer to whch the parse_state refers.
 * The pos/lim of the parse state must already be checked against the length
 * of the data before calling these.
 */
static int sizeof_codepoint_encoding(int codepoint, int encoding);
static int sb_parse_prev_codepoint(secret_buffer_parse *parse);
static int sb_parse_next_codepoint(secret_buffer_parse *parse);
static bool sb_parse_encode_codepoint(secret_buffer_parse *parse, int codepoint);
static bool sb_parse_match_charset_bytes(secret_buffer_parse *parse, const secret_buffer_charset *cset, int flags);
static bool sb_parse_match_charset_codepoints(secret_buffer_parse *parse, const secret_buffer_charset *cset, int flags);
static bool sb_parse_match_str_U8(secret_buffer_parse *parse, const U8 *pattern, size_t pattern_len, int flags);
static bool sb_parse_match_str_I32(secret_buffer_parse *parse, const I32 *pattern, size_t pattern_len, int flags);

static bool parse_encoding(pTHX_ SV *sv, int *out) {
   int enc;
   if (looks_like_number(sv)) {
      IV i= SvIV(sv);
      if (i < 0 || i > SECRET_BUFFER_ENCODING_MAX)
         return false;
      enc= (int) i;
   } else {
      STRLEN len;
      const char *str= SvPV(sv, len);
      switch (len) {
      case  3: if (0 == strcmp(str, "HEX"))        { enc= SECRET_BUFFER_ENCODING_HEX;       break; }
      case  4: if (0 == strcmp(str, "UTF8"))       { enc= SECRET_BUFFER_ENCODING_UTF8;      break; }
      case  5: if (0 == strcmp(str, "ASCII"))      { enc= SECRET_BUFFER_ENCODING_ASCII;     break; }
               if (0 == strcmp(str, "UTF-8"))      { enc= SECRET_BUFFER_ENCODING_UTF8;      break; }
      case  6: if (0 == strcmp(str, "BASE64"))     { enc= SECRET_BUFFER_ENCODING_BASE64;    break; }
      case  7: if (0 == strcmp(str, "UTF16LE"))    { enc= SECRET_BUFFER_ENCODING_UTF16LE;   break; }
               if (0 == strcmp(str, "UTF16BE"))    { enc= SECRET_BUFFER_ENCODING_UTF16BE;   break; }
      case  8: if (0 == strcmp(str, "UTF-16LE"))   { enc= SECRET_BUFFER_ENCODING_UTF16LE;   break; }
               if (0 == strcmp(str, "UTF-16BE"))   { enc= SECRET_BUFFER_ENCODING_UTF16BE;   break; }
      case  9: if (0 == strcmp(str, "ISO8859_1"))  { enc= SECRET_BUFFER_ENCODING_ISO8859_1; break; }
      case 10: if (0 == strcmp(str, "ISO-8859-1")) { enc= SECRET_BUFFER_ENCODING_ISO8859_1; break; }
      default:
         return false;
      }
   }
   if (out) *out= enc;
   return true;
}

/* Public API --------------------------------------------------------------*/

/* initialize a parse struct, but only if it is valid span of the buffer */
bool secret_buffer_parse_init(secret_buffer_parse *parse,
   secret_buffer *buf, size_t pos, size_t lim, int encoding
) {
   Zero(parse, 1, secret_buffer_parse);
   // Sanity check this parse state vs. the buffer
   if (lim > buf->len || pos > lim) {
      parse->error= pos > lim? "span starts beyond buffer" : "span ends beyond buffer";
      return false;
   }
   parse->pos= ((U8*) buf->data) + pos;
   parse->lim= ((U8*) buf->data) + lim;
   parse->encoding= encoding;
   parse->sbuf= buf;
   return true;
}

/* Initialize a parse struct, either from a Span, or a SecretBuffer, or a plain Scalar.
 */
bool secret_buffer_parse_init_from_sv(secret_buffer_parse *parse, SV *sv) {
   dTHX;
   secret_buffer *sb;
   secret_buffer_span *span;
   /* Is the sv a Span object? */
   if ((span= secret_buffer_span_from_magic(sv, 0)) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
      SV **sb_sv= hv_fetchs((HV*)SvRV(sv), "buf", 1);
      sb= secret_buffer_from_magic(*sb_sv, SECRET_BUFFER_MAGIC_OR_DIE);
      return secret_buffer_parse_init(parse, sb, span->pos, span->lim, span->encoding);
   }
   /* Is the sv a SecretBuffer? */
   else if ((sb= secret_buffer_from_magic(sv, 0))) {
      return secret_buffer_parse_init(parse, sb, 0, sb->len, SECRET_BUFFER_ENCODING_ISO8859_1);
   }
   /* It needs to at least be defined */
   else if (SvOK(sv)) {
      STRLEN len;
      char *buf= SvPV(sv, len);
      Zero(parse, 1, secret_buffer_parse);
      parse->pos= (U8*) buf;
      parse->lim= (U8*) buf + len;
      parse->encoding= SvUTF8(sv)? SECRET_BUFFER_ENCODING_UTF8 : SECRET_BUFFER_ENCODING_ISO8859_1;
      return true;
   }
   else {
      Zero(parse, 1, secret_buffer_parse);
      parse->error= "Not a Span, SecretBuffer, or defined scalar";
      return false;
   }
}

/* Scan for a pattern which may be a regex or literal string.
 * Regexes are currently limited to a single charclass.
 */
bool secret_buffer_match(secret_buffer_parse *parse, SV *pattern, int flags) {
   dTHX;
   REGEXP *rx= (REGEXP*)SvRX(pattern);
   secret_buffer_parse pat_parse;

   /* Is the pattern a regexp-ref? */
   if (rx) {
      secret_buffer_charset *cset= secret_buffer_charset_from_regexpref(pattern);
      return secret_buffer_match_charset(parse, cset, flags);
   }

   /* load up a parse struct with the pos, lim, and encoding */
   if (!secret_buffer_parse_init_from_sv(&pat_parse, pattern))
      croak("%s", pat_parse.error);

   /* Remove edge case of zero-length pattern (always matches) */
   if (pat_parse.pos >= pat_parse.lim) {
      if ((flags & SECRET_BUFFER_MATCH_REVERSE))
         parse->pos= parse->lim;
      else
         parse->lim= parse->pos;
      return !(flags & SECRET_BUFFER_MATCH_NEGATE);
   }
   /* Remove edge case of zero-length subject (never matches) */
   if (parse->pos >= parse->lim) {
      return (flags & SECRET_BUFFER_MATCH_NEGATE);
   }

   /* Since unicode iteration of the pattern is a hassle and might happen lots of times,
    * convert it to either plain bytes or array of U32 codepoints.
    */
   if (pat_parse.encoding != SECRET_BUFFER_ENCODING_ISO8859_1) {
      int dst_enc= 
         /* these can be transcoded to bytes */
         (pat_parse.encoding == SECRET_BUFFER_ENCODING_ASCII
          || pat_parse.encoding == SECRET_BUFFER_ENCODING_HEX
          || pat_parse.encoding == SECRET_BUFFER_ENCODING_BASE64)
         ? SECRET_BUFFER_ENCODING_ISO8859_1
         : SECRET_BUFFER_ENCODING_I32;
      SSize_t dst_len= secret_buffer_sizeof_transcode(&pat_parse, dst_enc);
      if (dst_len < 0)
         croak("transcode of pattern failed: %s", pat_parse.error);
      /* No need to transcode SECRET_BUFFER_ENCODING_ASCII, but the above size check
       * verified it is clean 7-bit, which is the whole point of that encoding.
       */
      if (pat_parse.encoding == SECRET_BUFFER_ENCODING_ASCII
         /* Likewise, if SECRET_BUFFER_ENCODING_UTF8's I32 len is exactly 4x the number of
          * original bytes, that means every byte became a character, which means every
          * character could fit in a byte. */
         || (pat_parse.encoding == SECRET_BUFFER_ENCODING_UTF8
            && dst_len == (pat_parse.lim - pat_parse.pos) * 4)
      ) {
         pat_parse.encoding= SECRET_BUFFER_ENCODING_ISO8859_1;
      } else {
         /* create a temporary secret buffer to hold the transcode */
         secret_buffer *tmp= secret_buffer_new(0, NULL);
         secret_buffer_parse pat_orig= pat_parse;
         secret_buffer_set_len(tmp, dst_len);
         if (!secret_buffer_parse_init(&pat_parse, tmp, 0, dst_len, dst_enc))
            croak("transcode of pattern failed: %s", pat_parse.error);
         /* Transcode the pattern */
         if (!secret_buffer_transcode(&pat_orig, &pat_parse))
            croak("transcode of pattern failed: %s", pat_orig.error? pat_orig.error : pat_parse.error);
      }
   }
   /* In some cases it would also be nice to transcode the subject first, but the
    * final state of the parse struct carries information back to the caller and
    * needs to refer to original positions of characters. */

   /* Now dipatch to sb_parse_match_str_X */
   if (pat_parse.encoding == SECRET_BUFFER_ENCODING_ISO8859_1) {
      size_t pat_len= pat_parse.lim - pat_parse.pos;
      return sb_parse_match_str_U8(parse, pat_parse.pos, pat_len, flags);
   } else { /* must be _I32 encoding, from above */
      size_t pat_len= (pat_parse.lim - pat_parse.pos) >> 2;
      return sb_parse_match_str_I32(parse, (I32*) pat_parse.pos, pat_len, flags);
   }
}

/* Scan for a pattern which is a set of characters */
bool secret_buffer_match_charset(secret_buffer_parse *parse, secret_buffer_charset *cset, int flags) {
   if (parse->pos >= parse->lim) // empty range
      return false;

   // byte matching gets to use a more efficient algorithm
   return parse->encoding == SECRET_BUFFER_ENCODING_ISO8859_1
      ? sb_parse_match_charset_bytes(parse, cset, flags)
      : sb_parse_match_charset_codepoints(parse, cset, flags);
}

/* Scan for a pattern which is a literal string of bytes.
 */
bool secret_buffer_match_bytestr(secret_buffer_parse *parse, char *data, size_t datalen, int flags) {
   return sb_parse_match_str_U8(parse, (U8*) data, datalen, flags);
}

/* Count number of bytes required to transcode the source.
 * If the source contains an invalid character for its encoding, or that codepoint
 * can't be encoded as the dst_encoding, this returns -1 and sets src->error
 * and also sets src->pos pointing at the character that could not be converted.
 */
SSize_t secret_buffer_sizeof_transcode(secret_buffer_parse *src, int dst_encoding) {
   // If the source and destination encodings are both bytes, return the length
   if (dst_encoding == src->encoding && src->encoding == 0)
      return src->lim - src->pos;
   // Else need to iterate characters (to validate) and re-encode them
   else {
      size_t dst_size_needed= 0;
      secret_buffer_parse tmp;
      Zero(&tmp, 1, secret_buffer_parse);
      tmp.pos= src->pos;
      tmp.lim= src->lim;
      tmp.encoding= src->encoding;
      while (tmp.pos < tmp.lim) {
         int cp= sb_parse_next_codepoint(&tmp);
         if (cp < 0) return -1;
         int ch_size= sizeof_codepoint_encoding(cp, dst_encoding);
         if (ch_size < 0) return -1;
         dst_size_needed += ch_size;
      }
      // If dest is base64, need special calculation
      if (dst_encoding == SECRET_BUFFER_ENCODING_BASE64) {
         dst_size_needed= ((dst_size_needed + 2) / 3) * 4;
      }
      return dst_size_needed;
   }
}

static const char base64_alphabet[64]=
   "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
   "abcdefghijklmnopqrstuvwxyz"
   "0123456789+/";

/*
perl -E 'my @tbl= (-1)x256;
$tbl[ord]= -ord(A)+ord for A..Z;
$tbl[ord]= 26-ord(a)+ord for a..z;
$tbl[ord]= 52-ord(0)+ord for 0..9;
$tbl[ord "+"]= 62;
$tbl[ord "/"]= 63;
$tbl[ord "="]= 64;
say join ",\n", map join(",", @tbl[$_*16 .. $_*16+15]), 0..0xF'
*/
static const int8_t base64_decode_table[256]= {
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
   52,53,54,55,56,57,58,59,60,61,-1,-1,-1,64,-1,-1,
   -1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
   15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
   -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
   41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
   -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
};

/* Transcode characters from one parse state into another.
 * This works sort of like
 *   $data= decode($src_enc, substr($src, $src_pos, $src_len));
 *   substr($dst, $dst_pos, $dst_lim, encode($dst_enc, $data));
 * processing only a range of the source, and replacing only a range of the dest,
 * adjusting the size of dst as needed.  Both src->pos and dst->pos
 * are updated.
 */
bool secret_buffer_transcode(secret_buffer_parse *src, secret_buffer_parse *dst) {
   src->error= NULL;
   dst->error= NULL;
   // If the source and destination encodings are both bytes, use memcpy
   if (dst->encoding == src->encoding && src->encoding == 0) {
      size_t cnt= dst->lim - dst->pos;
      if (src->lim - src->pos != cnt) {
         dst->error= "miscalculated buffer length";
         return false;
      }
      memcpy((U8*)dst->pos, src->pos, cnt);
      dst->pos += cnt;
      src->pos += cnt;
   }
   // Else need to iterate characters and re-encode them
   // base64 encoding doesn't work with sb_parse_encode_codepoint, so it gets
   // special treatment.
   else if (dst->encoding == SECRET_BUFFER_ENCODING_BASE64) {
      // Read 3, write 4
      int accum= 0;
      int shift= 16, cp;
      while (src->pos < src->lim) {
         cp= sb_parse_next_codepoint(src);
         if (cp > 0xFF) {
            dst->error= "byte out of range";
            return false;
         }
         if (!shift) {
            U8 *writable= (U8*) dst->pos;
            if (dst->pos + 4 > dst->lim) {
               dst->error= "miscalculated buffer length";
               return false;
            }
            dst->pos += 4;
            accum |= cp;
            writable[0] = base64_alphabet[0x3F & (accum >> 18)];
            writable[1] = base64_alphabet[0x3F & (accum >> 12)];
            writable[2] = base64_alphabet[0x3F & (accum >> 6)];
            writable[3] = base64_alphabet[0x3F & accum];
            accum= 0;
            shift= 16;
         }
         else {
            accum |= (cp << shift);
            shift -= 8;
         }
      }
      if (dst->pos + (shift < 16? 4 : 0) != dst->lim) {
         dst->error= "miscalculated buffer length";
         return false;
      }
      // write leftover accumulated bits
      if (shift < 16) {
         U8 *writable= (U8*) dst->pos;
         if (dst->pos + 4 > dst->lim) {
            dst->error= "miscalculated buffer length";
            return false;
         }
         dst->pos += 4;
         writable[0] = base64_alphabet[0x3F & (accum >> 18)];
         writable[1] = base64_alphabet[0x3F & (accum >> 12)];
         writable[2] = shift? '=' : base64_alphabet[0x3F & (accum >> 6)];
         writable[3] = '=';
      }
   }
   else {
      while (src->pos < src->lim) {
         int cp= sb_parse_next_codepoint(src);
         if (cp < 0)
            return false; // error is already set
         int len= sb_parse_encode_codepoint(dst, cp);
         if (len < 0)
            return false; // error is already set
      }
      if (dst->pos != dst->lim) {
         dst->error= "miscalculated buffer length";
         return false;
      }
   }
   return true;
}

bool
secret_buffer_copy_to(secret_buffer_parse *src, SV *dst_sv, int encoding, bool append) {
   dTHX;
   secret_buffer_parse dst;
   secret_buffer *dst_sbuf= NULL;
   SSize_t need_bytes;
   bool dst_wide= false;

   Zero(&dst, 1, secret_buffer_parse);
   // Encoding may be -1 to indicate the user didn't specify, in which case we use the
   // same encoding as the source, unless the destination is a perl scalar (handled below)
   dst.encoding= encoding >= 0? encoding : src->encoding;
   if (sv_isobject(dst_sv)) {
      // if object, must be a SecretBuffer
      dst_sbuf= secret_buffer_from_magic(dst_sv, SECRET_BUFFER_MAGIC_OR_DIE);
   }
   else {
      // Going to overwrite the scalar, or if its a scalar-ref, overwrite that.
      if (SvROK(dst_sv) && !sv_isobject(dst_sv) && SvTYPE(SvRV(dst_sv)) <= SVt_PVMG)
         dst_sv= SvRV(dst_sv);
      // Refuse to overwrite any other kind of ref
      if (SvTYPE(dst_sv) > SVt_PVMG || SvROK(dst_sv)) {
         src->error= "Can only copy_to scalars or scalar-refs";
         return false;
      }
      // If the source encoding is a type of unicode, and the destination encoding is not
      // specified, then write wide characters (utf-8) to the perl scalar and flag it as utf8
      if (encoding < 0 && SECRET_BUFFER_ENCODING_IS_UNICODE(src->encoding)) {
         dst.encoding= SECRET_BUFFER_ENCODING_UTF8;
         dst_wide= true;
      }
   }
   // Determine how many bytes we need
   need_bytes= secret_buffer_sizeof_transcode(src, dst.encoding);
   if (need_bytes < 0)
      return false;
   // Prepare the buffers for that many bytes
   if (dst_sbuf) {
      // For destination SecretBuffer, set length to 0 unless appending, then
      // ensure enough allocated space for need_bytes, then transcode and update
      // the length in the block below.
      if (!append)
         secret_buffer_set_len(dst_sbuf, 0); /* clears secrets */
      secret_buffer_alloc_at_least(dst_sbuf, dst_sbuf->len + need_bytes);
      dst.pos= (U8*) dst_sbuf->data + dst_sbuf->len;
      dst.lim= dst.pos + need_bytes;
   }
   else {
      // For destination SV, set length to 0 unless appending, then force it to
      // be bytes or utf-8, then grow it to ensure room for additional `need_bytes`.
      U8* ptr;
      STRLEN len;
      // If overwriting, set the length to 0 before forcing to bytes or utf8
      if (!append)
         sv_setpvn(dst_sv, "", 0);
      // force it to the type required
      if (dst_wide) SvPVutf8(dst_sv, len);
      else SvPVbyte(dst_sv, len);
      // grow it to the required length, for writing
      sv_grow(dst_sv, (append? len : 0) + need_bytes + 1);
      ptr= (U8*) SvPVX_mutable(dst_sv) + len;
      // don't forget the NUL terminator
      ptr[need_bytes]= '\0';
      dst.pos= ptr;
      dst.lim= dst.pos + need_bytes;
   }
   if (!secret_buffer_transcode(src, &dst)) {
      if (!src->error) src->error= dst.error;
      return false;
   }
   /* update the lengths */
   if (dst_sbuf) {
      dst_sbuf->len += need_bytes;
   }
   else {
      SvCUR_set(dst_sv, SvCUR(dst_sv) + need_bytes);
      SvSETMAGIC(dst_sv);
   }
   return true;
}

/* Append DER length octets (ASN.1 Length field, definite form only).
 *
 * DER rules:
 *  - If len <= 127: single byte [0x00..0x7F]
 *  - Else: first byte is 0x80 | N, where N is # of following length bytes (big-endian),
 *          and the length must be encoded in the minimal number of bytes (no leading 0x00).
 *
 * This function encodes ONLY the length field (not tag/value).
 */
void
secret_buffer_append_uv_asn1_der_length(secret_buffer *buf, UV val) {
   dTHX;
   int enc_len = 1;
   U8 *pos;
   if (val > 127) {
      /* Determine minimal number of bytes needed to represent len in base-256. */
      UV tmp = val;
      while (tmp) {
         enc_len++;
         tmp >>= 8;
      }
   }
   /* In BER/DER, the long-form initial octet has 7 bits of length-of-length.
    * 0x80 is indefinite length (forbidden in DER), 0xFF would mean 127 length bytes.
    * With 64-bit UV enc_len will never exceed 9.
    */
   ASSUME(enc_len < 127);
   secret_buffer_set_len(buf, buf->len + enc_len);
   pos= (U8*) buf->data + buf->len - 1;
   if (val <= 127) {
      *pos = (U8) val;
   } else {
      UV tmp = val;
      /* Write the length big-endian into enc[1..n]. */
      while (tmp) {
         *pos-- = (U8)(tmp & 0xFF);
         tmp >>= 8;
      }
      *pos= (U8) (0x80 | (U8)(enc_len-1));
   }
}

/* Parse ASN.1 DER Length (definite form only) */
bool
secret_buffer_parse_uv_asn1_der_length(secret_buffer_parse *parse, UV *out) {
   /* Work on a local cursor so we can roll back on failure */
   const U8 *pos = parse->pos;
   const U8 *lim = parse->lim;
   UV result;

   if (pos >= lim) {
      parse->error = "unexpected end of buffer";
      return false;
   }

   result = *pos++;

   /* If 0..127, the byte is the length value itself, otherwise it is the number of octets
    * to read following that byte. */
   if ((result & 0x80)) {
      int n = result & 0x7F;
      /* 0x80 means indefinite length (BER/CER), forbidden in DER */
      if (n == 0) {
         parse->error = "ASN.1 DER indefinite length not allowed";
         return false;
      }
      /* Number of octets should be smallest possible encoding, so if it is larger than size_t
       * don't even bother trying to decode it.
       */
      if (n > sizeof(UV)) {
         parse->error = "ASN.1 DER length too large for perl UV";
         return false;
      }
      /* ensure we have that many bytes */
      if ((size_t)(lim - pos) < (size_t)n) {
         parse->error = "unexpected end of buffer";
         return false;
      }
      /* DER minimal encoding rules:
       * - no leading 0x00 in the length octets
       * - long form must not be used for lengths <= 127
       */
      lim= pos + n;
      result= *pos++;
      if (!result) {
         parse->error = "ASN.1 DER length has leading zero (non-minimal)";
         return false;
      }
      /* Parse remaining bytes of big-endian unsigned integer */
      while (pos < lim)
         result= (result << 8) | *pos++;
      /* DER should not use 1-byte encoding if it would have fit in the initial byte */
      if (result < 0x80) {
         parse->error = "ASN.1 DER length should use short form (non-minimal)";
         return false;
      }
   }
   if (out) *out = result;
   parse->pos = pos;
   parse->error = NULL;
   return true;
}

/* Append canonical unsigned Base128, Little-Endian
 *
 * Rules:
 *  - 7 data bits per byte, little-endian (least significant group first)
 *  - High bit 0x80 set on all bytes except the final byte
 *  - Canonical/minimal: stop as soon as remaining value is 0
 */
void
secret_buffer_append_uv_base128le(secret_buffer *buf, UV val) {
   dTHX;
   U8 *pos;
   int enc_len= 1;
   UV tmp= val >> 7;
   while (tmp) {
      enc_len++;
      tmp >>= 7;
   }
   secret_buffer_set_len(buf, buf->len + enc_len);
   pos= (U8*) buf->data + buf->len - enc_len;
   /* Encode */
   tmp= val;
   do {
      U8 byte = (U8)(tmp & 0x7F);
      tmp >>= 7;
      if (tmp)
         byte |= 0x80;
      *pos++ = byte;
   } while (tmp);
   ASSUME(pos == (U8*)(buf->data + buf->len));
}

/* Parse Unsigned LittleEndian Base128 (also requiring canonical / minimal encoding) */
bool
secret_buffer_parse_uv_base128le(secret_buffer_parse *parse, UV *out) {
   const U8 *pos = parse->pos;
   const U8 *lim = parse->lim;
   UV result= 0, payload;
   int shift= 7;

   if (pos >= lim) {
      parse->error = "unexpected end of buffer";
      return false;
   }
   result= payload= *pos & 0x7F;
   /* Scan forward looking for the first byte without the continuation flag */
   while (*pos++ & 0x80) {
      if (pos >= lim) {
         parse->error = "unexpected end of buffer";
         return false;
      }
      payload= *pos & 0x7F;
      if (shift > sizeof(UV)*8 - 7) {
         /* Do any of the bits overflow? Is the continuation flag set? */
         if (shift >= sizeof(UV)*8 || (payload >> (sizeof(UV)*8 - shift))) {
            parse->error = "Base128-LE value overflows perl UV";
            return false;
         }
      }
      result |= payload << shift;
      shift += 7;
   }
   /* check if the high bits were all zero, meaning an unnecessary byte was encoded */
   if (!payload && result != 0) {
      parse->error = "Over-long encoding of Base128-LE";
      return false;
   }
   if (out) *out = result;
   parse->pos = pos;
   parse->error = NULL;
   return true;
}

/* Append canonical unsigned Base128, Big-Endian
 *
 * Rules:
 *  - 7 data bits per byte, big-endian (most significant group first)
 *  - High bit 0x80 set on all bytes except the final byte
 *  - Canonical/minimal: stop as soon as remaining value is 0
 */
void
secret_buffer_append_uv_base128be(secret_buffer *buf, UV val) {
   dTHX;
   U8 *pos;
   int enc_len= 1, shift;
   UV tmp= val >> 7;
   while (tmp) {
      enc_len++;
      tmp >>= 7;
   }
   secret_buffer_set_len(buf, buf->len + enc_len);
   pos= (U8*) buf->data + buf->len - enc_len;
   /* Encode */
   for (shift= (enc_len-1) * 7; shift >= 0; shift -= 7) {
      U8 byte = (U8)((val >> shift) & 0x7F);
      if (shift)
         byte |= 0x80;
      *pos++ = byte;
   }
   ASSUME(pos == (U8*)(buf->data + buf->len));
}

/* Parse Unsigned BigEndian Base128 (also requiring canonical / minimal encoding) */
bool
secret_buffer_parse_uv_base128be(secret_buffer_parse *parse, UV *out) {
   const U8 *pos = parse->pos;
   const U8 *lim = parse->lim;
   UV result= 0;

   if (pos >= lim) {
      parse->error = "unexpected end of buffer";
      return false;
   }
   /* high-bit payload == 0 with continue bit set is an error. */
   if (*pos == 0x80) {
      parse->error = "Over-long encoding of Base128-BE";
      return false;
   }
   result= *pos & 0x7F;
   while (*pos++ & 0x80) {
      /* Will existing bits overflow UV when shifted? */
      if (result >> (sizeof(UV)*8 - 7)) {
         parse->error = "Base128-BE value overflows perl UV";
         return false;
      }
      if (pos >= lim) {
         parse->error = "unexpected end of buffer";
         return false;
      }
      result= (result << 7) | (*pos & 0x7F);
   }
   if (out) *out = result;
   parse->pos = pos;
   parse->error = NULL;
   return true;
}

/* Private API -------------------------------------------------------------*/

/* Scan raw bytes using only the bitmap */
static bool sb_parse_match_charset_bytes(
   secret_buffer_parse *parse,
   const secret_buffer_charset *cset,
   int flags
) {
   bool negate=   0 != (flags & SECRET_BUFFER_MATCH_NEGATE);
   bool reverse=  0 != (flags & SECRET_BUFFER_MATCH_REVERSE);
   bool multi=    0 != (flags & SECRET_BUFFER_MATCH_MULTI) || cset->match_multi;
   bool anchored= 0 != (flags & SECRET_BUFFER_MATCH_ANCHORED);
   bool consttime=0 != (flags & SECRET_BUFFER_MATCH_CONST_TIME);
   int step= reverse? -1 : 1;
   const U8 *pos= reverse? parse->lim-1 : parse->pos,
            *lim= reverse? parse->pos-1 : parse->lim,
            *span_start= NULL;
   //warn("scan_charset_bytes pos=%p lim=%p len=%d", parse->pos, parse->lim, (int)(parse->lim - parse->pos));

   while (pos != lim) {
      if (sbc_bitmap_test(cset->bitmap, *pos) != negate) {
         // Found.  Now are we looking for a span?
         if (span_start)
            break;
         span_start= pos;
         if (!multi) {
            pos += step;
            break;
         }
         negate= !negate;
      } else if (anchored && !span_start)
         break;
      pos += step;
   }
   /* If constant time operation is requested, we need to perform one sbc_bitmap_test
    * for every character in the span, and make sure the compiler doesn't eliminate it.
    */
   if (consttime) {
      volatile bool sink= false;
      while (pos != lim) {
         sink ^= sbc_bitmap_test(cset->bitmap, *pos);
         pos += step;
      }
      (void) sink;
   }
   // reached end of defined range, and implicitly ends span
   if (reverse) {
      parse->pos= pos + 1;
      parse->lim= span_start? span_start + 1 : parse->pos;
   } else {
      parse->lim= pos;
      parse->pos= span_start? span_start : parse->lim;
   }
   return span_start != NULL;
}

static bool sb_parse_match_charset_codepoints(
   secret_buffer_parse *parse,
   const secret_buffer_charset *cset,
   int flags
) {
   dTHX;
   bool negate=   0 != (flags & SECRET_BUFFER_MATCH_NEGATE);
   bool reverse=  0 != (flags & SECRET_BUFFER_MATCH_REVERSE);
   bool multi=    0 != (flags & SECRET_BUFFER_MATCH_MULTI) || cset->match_multi;
   bool anchored= 0 != (flags & SECRET_BUFFER_MATCH_ANCHORED);
   bool consttime=0 != (flags & SECRET_BUFFER_MATCH_CONST_TIME);
   bool span_started= false;
   bool encoding_error= false;
   const U8 *span_mark= NULL, *prev_mark= reverse? parse->lim : parse->pos;

   while (parse->pos < parse->lim) {
      int codepoint= reverse? sb_parse_prev_codepoint(parse)
                            : sb_parse_next_codepoint(parse);
      // warn("parse.pos=%p  parse.lim=%p  parse.enc=%d  cp=%d  parse.err=%s", parse->pos, parse->lim, parse->encoding, codepoint, parse->error);
      if (codepoint < 0) {// encoding error
         encoding_error= true;
         break;
      }
      if (sbc_test_codepoint(aTHX_ cset, codepoint) != negate) {
         // Found.  Mark boundaries of char.
         // Now are we looking for a span?
         if (span_started)
            break;
         span_started= true;
         span_mark= prev_mark;
         negate= !negate;
         if (!multi) {
            prev_mark= reverse? parse->lim : parse->pos;
            break;
         }
      } else if (anchored && !span_started)
         break;
      prev_mark= reverse? parse->lim : parse->pos;
   }
   /* If constant time operation is requested, we need to perform one sbc_bitmap_test
    * for every character in the span, and make sure the compiler doesn't eliminate it.
    */
   if (consttime) {
      volatile bool sink= false;
      while (parse->pos < parse->lim) {
         int codepoint= reverse? sb_parse_prev_codepoint(parse)
                               : sb_parse_next_codepoint(parse);
         // warn("parse.pos=%p  parse.lim=%p  parse.enc=%d  cp=%d  parse.err=%s", parse->pos, parse->lim, parse->encoding, codepoint, parse->error);
         if (codepoint < 0) { // encoding error
            encoding_error= true;
            sink ^= sbc_test_codepoint(aTHX_ cset, 0);
         }
         else
            sink ^= sbc_test_codepoint(aTHX_ cset, codepoint);
      }
      (void) sink;
   }
   if (encoding_error)
      return false;
   // reached end of defined range
   if (span_started) { // and implicitly ends span
      if (reverse) {
         parse->pos= prev_mark;
         parse->lim= span_mark;
      }
      else {
         parse->pos= span_mark;
         parse->lim= prev_mark;
      }
      return true;
   }
   return false;
}

int sb_parse_codepointcmp(secret_buffer_parse *lhs, secret_buffer_parse *rhs) {
   I32 lhs_cp, rhs_cp;
   volatile int ret= 0;
   /* constant-time iteration per the shorter of the two strings */
   while (lhs->pos < lhs->lim && rhs->pos < rhs->lim) {
      lhs_cp= sb_parse_next_codepoint(lhs);
      if (lhs_cp < 0)
         croak("Encoding error in left-hand buffer");
      rhs_cp= sb_parse_next_codepoint(rhs);
      if (rhs_cp < 0)
         croak("Encoding error in right-hand buffer");
      if (lhs_cp != rhs_cp && !ret)
         ret= lhs_cp < rhs_cp? -1 : 1;
   }
   return ret? ret
        : (lhs->pos < lhs->lim)?  1 /* right string shorter than left */
        : (rhs->pos < rhs->lim)? -1 /* left string shorter than right */
        : 0;
}

/* UTF-8 decoding helper */
static int sb_parse_next_codepoint(secret_buffer_parse *parse) {
   const U8 *pos= parse->pos, *lim= parse->lim;
   int cp, encoding= parse->encoding;
   #define SB_RETURN_ERROR(msg) { parse->error= msg; return -1; }

   if (encoding == SECRET_BUFFER_ENCODING_ASCII
    || encoding == SECRET_BUFFER_ENCODING_ISO8859_1
    || encoding == SECRET_BUFFER_ENCODING_UTF8
   ) {
      if (lim - pos < 1)
         SB_RETURN_ERROR("end of span")
      cp= *pos++;
      if (cp >= 0x80 && encoding == SECRET_BUFFER_ENCODING_ASCII)
         SB_RETURN_ERROR("not 7-bit ASCII")
      else if (cp >= 0x80 && encoding == SECRET_BUFFER_ENCODING_UTF8) {
         int min_cp= 0;
         switch ((cp >> 3) & 0xF) {
         case 14:                          // 0b1[1110]yyy
            {  if (lim - pos < 3) goto incomplete;
               min_cp= 0x10000;
               cp &= 0x07;
            }
            if ((*pos & 0xC0) != 0x80) goto invalid;
            cp= (cp << 6) | (*pos++ & 0x3F);
            if (0)
         case 12: case 13:                 // 0b1[110x]yyy
            {  if (lim - pos < 2) goto incomplete;
               min_cp= 0x800;
               cp &= 0x0F;
            }
            if ((*pos & 0xC0) != 0x80) goto invalid;
            cp= (cp << 6) | (*pos++ & 0x3F);
            if (0)
         case 8: case 9: case 10: case 11: // 0b1[10xx]yyy
            {  if (lim - pos < 1) goto incomplete;
               min_cp= 0x80;
               cp &= 0x1F;
            }
            if ((*pos & 0xC0) != 0x80) goto invalid;
            cp= (cp << 6) | (*pos++ & 0x3F);
            break;
         default:
            invalid:    SB_RETURN_ERROR("invalid UTF8 character")
            incomplete: SB_RETURN_ERROR("incomplete UTF8 character")
         }
         if (cp < min_cp)
            SB_RETURN_ERROR("overlong encoding of UTF8 character")
         else if (cp > 0x10FFFF)
            SB_RETURN_ERROR("UTF8 character exceeds max")
      }
      // else all ISO-8859-1 bytes are valid codepoints
   }
   else if (encoding == SECRET_BUFFER_ENCODING_UTF16LE
         || encoding == SECRET_BUFFER_ENCODING_UTF16BE
   ) {
      int low= encoding == SECRET_BUFFER_ENCODING_UTF16LE? 0 : 1;
      if (lim - pos < 2)
         SB_RETURN_ERROR("end of span")
      cp= pos[low] | ((int)pos[low^1] << 8);
      pos += 2;
      if (cp >= 0xD800 && cp <= 0xDFFF) {
         if (lim - pos < 2)
            SB_RETURN_ERROR("incomplete UTF16 character")
         int w2= pos[low] | ((int)pos[low^1] << 8);
         pos += 2;
         if (w2 < 0xDC00 || w2 > 0xDFFF)
            SB_RETURN_ERROR("invalid UTF16 low surrogate")
         cp = 0x10000 + (((cp & 0x3FF) << 10) | (w2 & 0x3FF));
      }
   }
   else if (encoding == SECRET_BUFFER_ENCODING_HEX) {
      // Skip over whitespace
      while (pos < lim && isspace(*pos))
         pos++;
      if (lim - pos < 2)
         SB_RETURN_ERROR("end of span")
      int high= *pos++ - '0';
      int low= *pos++ - '0';
      if (low >= ('a'-'0')) low -= ('a'-'0'-10);
      else if (low >= ('A'-'0')) low -= ('A'-'0'-10);
      if (high >= ('a'-'0')) high -= ('a'-'0'-10);
      else if (high >= ('A'-'0')) high -= ('A'-'0'-10);
      if ((low >> 4) | (high >> 4))
         SB_RETURN_ERROR("not a pair of hex digits")
      cp= (high << 4) | low;
      // skip over whitespace if it takes us to the end of buffer so that caller
      // knows it's EOF before trying another decode.
      while (pos < lim && isspace(*pos))
         pos++;
   }
   else if (encoding == SECRET_BUFFER_ENCODING_BASE64) {
      // Skip over whitespace and control chars
      while (pos < lim && *pos <= ' ')
         pos++;
      // There need to be at least 2 base64 characters left
      if (pos < lim) {
         if (base64_decode_table[*pos] < 0)
            SB_RETURN_ERROR("invalid base64 character");
         // ->pos_bit > 0 means pointer is pointing at a sub-bit of the base64
         // character at *pos (and possible values are 0, 2, or 4)
         cp= (((int)base64_decode_table[*pos++]) << (2 + parse->pos_bit)) & 0xFF;
         while (pos < lim && *pos <= ' ')
            pos++;
      }
      if (pos >= lim) {
         parse->pos_bit= 0;
         SB_RETURN_ERROR("end of span")
      }
      if (base64_decode_table[*pos] < 0)
         SB_RETURN_ERROR("invalid base64 character");
      cp |= base64_decode_table[*pos] >> (4-parse->pos_bit);
      parse->pos_bit += 2;
      // If pos_bit == 6 we've completed a set of 4 b64 chars and fully consumed them.
      if (parse->pos_bit >= 6) {
         pos++;
         parse->pos_bit= 0;
         // consume trailing whitespace
         while (pos < lim && *pos <= ' ')
            pos++;
      }
      else {
         // if next char is '=', terminate the decoding
         const U8 *next= pos+1;
         while (next < lim && *next <= ' ')
            next++;
         if (next < lim && *next == '=') {
            pos= lim; // indicate parsing complete
            parse->pos_bit= 0;
         }
      }
   }
   else if (encoding == SECRET_BUFFER_ENCODING_I32) {
      if (lim - pos < 4)
         SB_RETURN_ERROR("end of span");
      cp= *(I32*)pos;
      pos+= 4;
   }
   else SB_RETURN_ERROR("unsupported encoding")
   parse->pos= pos;
   return cp;
   #undef SB_RETURN_ERROR
}

static int sb_parse_prev_codepoint(secret_buffer_parse *parse) {
   const U8 *pos= parse->pos, *lim= parse->lim;
   int encoding= parse->encoding;
   int cp;
   #define SB_RETURN_ERROR(msg) { parse->error= msg; return -1; }

   if (encoding == SECRET_BUFFER_ENCODING_ASCII
    || encoding == SECRET_BUFFER_ENCODING_ISO8859_1
    || encoding == SECRET_BUFFER_ENCODING_UTF8
   ) {
      if (lim <= pos)
         SB_RETURN_ERROR("end of span")
      cp= *--lim;
      // handle the simple case first
      if (cp >= 0x80 && encoding != SECRET_BUFFER_ENCODING_ISO8859_1) {
         // Strict ASCII can't encode above 0x7F
         if (encoding == SECRET_BUFFER_ENCODING_ASCII)
            SB_RETURN_ERROR("not 7-bit ASCII")
         // else need to backtrack and then call next_codepoint
         const U8 *start= lim;
         while (start >= pos && (*start & 0xC0) == 0x80)
            --start;
         parse->pos= start;
         cp= sb_parse_next_codepoint(parse);
         if (parse->pos != parse->lim) {// consumed all characters we gave it?
            parse->pos= pos; // restore original pos
            if (cp >= 0) // had a valid char, but extra 0x80 bytes
               parse->error= "invalid UTF8 character";
            // else use the error message from next_codepoint
            return -1;
         }
         parse->pos= pos; // restore original pos
         lim= start; // new lim is where we started the parse from
      }
   }
   else if (encoding == SECRET_BUFFER_ENCODING_UTF16LE
         || encoding == SECRET_BUFFER_ENCODING_UTF16BE
   ) {
      if (lim - pos < 2)
         SB_RETURN_ERROR("end of span");
      // handle the simple case first
      lim -= 2;
      int low= (encoding == SECRET_BUFFER_ENCODING_UTF16LE)? 0 : 1;
      cp= lim[low] | ((int)lim[low^1] << 8);
      if (cp >= 0xD800 && cp <= 0xDFFF) {
         if (lim - pos < 4)
            SB_RETURN_ERROR("end of span");
         lim -= 2;
         int w1= lim[low] | ((int)lim[low^1] << 8);
         if (w1 < 0xD800 || w1 > 0xDFFF || cp < 0xDC00)
            SB_RETURN_ERROR("invalid UTF16 surrogate");
         cp = 0x10000 + (((w1 & 0x3FF) << 10) | (cp & 0x3FF));
      }
   }
   else if (encoding == SECRET_BUFFER_ENCODING_HEX) {
      // Skip over whitespace
      while (pos < lim && isspace(lim[-1]))
         lim--;
      if (lim - pos < 2)
         SB_RETURN_ERROR((pos == lim? "end of span" : "incomplete hex pair at end of span"))
      int low= *--lim - '0';
      int high= *--lim - '0';
      if (low >= ('a'-'0')) low -= ('a'-'0'-10);
      else if (low >= ('A'-'0')) low -= ('A'-'0'-10);
      if (high >= ('a'-'0')) high -= ('a'-'0'-10);
      else if (high >= ('A'-'0')) high -= ('A'-'0'-10);
      if ((low >> 4) | (high >> 4))
         SB_RETURN_ERROR("not a pair of hex digits")
      cp= (high << 4) | low;
   }
   else if (encoding == SECRET_BUFFER_ENCODING_BASE64) {
      bool again;
      do {
         again= false;
         // Skip over non-base64 chars
         while (pos < lim && base64_decode_table[lim[-1]] < 0)
            lim--;
         if (pos < lim) {
            //warn("lim-pos=%d, lim[-1]=%c, lim_bit=%d", (int)(lim-pos), lim[-1], parse->lim_bit);
            if (base64_decode_table[lim[-1]] < 0)
               SB_RETURN_ERROR("invalid base64 character");
            // ->lim_bit > 0 means the character lim[-1] is partially consumed.
            // (sequence is 0, 2, 4, 0)
            cp= ((int)base64_decode_table[lim[-1]]) >> parse->lim_bit;
            // parsing an equal sign means 'cp' is bogus and need to go again
            if (lim[-1] == '=')
               again= true;
            --lim;
            // find next base64 char
            while (pos < lim && base64_decode_table[lim[-1]] < 0)
               lim--;
         }
         if (pos >= lim) {
            parse->lim_bit= 0;
            SB_RETURN_ERROR("end of span")
         }
         if (base64_decode_table[lim[-1]] < 0)
            SB_RETURN_ERROR("invalid base64 character");
         //warn(" lim-pos=%d, lim[-1]=%c, lim_bit=%d", (int)(lim-pos), lim[-1], parse->lim_bit);
         cp |= (((int)base64_decode_table[lim[-1]]) << (6 - parse->lim_bit)) & 0xFF;
         parse->lim_bit += 2;
         if (parse->lim_bit >= 6) {
            parse->lim_bit= 0;
            // If completed a set of 4 b64 chars, lim[-1] is consumed, and need to
            // walk backward to find next base64 char
            --lim;
            while (pos < lim && base64_decode_table[lim[-1]] < 0)
               lim--;
         }
         //warn(" cp=%d, lim-pos=%d, lim_bit=%d", cp, (int)(lim-pos), parse->lim_bit);
      } while (again);
   }
   else if (encoding == SECRET_BUFFER_ENCODING_I32) {
      if (lim - pos < 4)
         SB_RETURN_ERROR("end of span");
      lim -= 4;
      cp= *(I32*)lim;
   }
   else SB_RETURN_ERROR("unsupported encoding")
   parse->lim= lim;
   return cp;
   #undef SB_RETURN_ERROR
}

static int sizeof_codepoint_encoding(int codepoint, int encoding) {
   if (encoding == SECRET_BUFFER_ENCODING_ASCII)
      return codepoint < 0x80? 1 : -1;
   if (encoding == SECRET_BUFFER_ENCODING_ISO8859_1)
      return codepoint < 0x100? 1 : -1;
   else if (encoding == SECRET_BUFFER_ENCODING_UTF8)
      return codepoint < 0x80? 1 : codepoint < 0x800? 2 : codepoint < 0x10000? 3 : 4;
   else if (encoding == SECRET_BUFFER_ENCODING_UTF16LE
         || encoding == SECRET_BUFFER_ENCODING_UTF16BE)
      return codepoint >= 0xD800 && codepoint < 0xE000? -1
           : codepoint < 0x10000? 2 : 4;
   else if (encoding == SECRET_BUFFER_ENCODING_HEX)
      return codepoint < 0x100? 2 : -1;
   /* Base64 would need to track an accumulator, so just return 1 and fix it in the caller */
   else if (encoding == SECRET_BUFFER_ENCODING_BASE64)
      return codepoint < 0x100? 1 : -1;
   else if (encoding == SECRET_BUFFER_ENCODING_I32)
      return 4;
   else
      return -1;
}

static bool sb_parse_encode_codepoint(secret_buffer_parse *dst, int codepoint) {
   #define SB_RETURN_ERROR(msg) { dst->error= msg; return false; }
   int encoding= dst->encoding, n;
   U8 *dst_pos= (U8*) dst->pos;
   // codepoints above 0x10FFFF are illegal
   if (codepoint >= 0x110000)
      SB_RETURN_ERROR("invalid codepoint");
   // not quite as efficient as checking during the code below, but saves a bunch of redundancy
   n= sizeof_codepoint_encoding(codepoint, encoding);
   if (n < 0)
      SB_RETURN_ERROR("character too wide for encoding")
   if (dst->lim - dst_pos < n)
      SB_RETURN_ERROR("buffer too small")
   dst->pos += n;

   if (encoding == SECRET_BUFFER_ENCODING_ASCII
    || encoding == SECRET_BUFFER_ENCODING_ISO8859_1
    || encoding == SECRET_BUFFER_ENCODING_UTF8
   ) {
      switch ((n-1)&0x3) { // help the compiler understand there are only 4 possible values
      case 0: *dst_pos++ = (U8) codepoint;
              break;
      case 1: *dst_pos++ = (U8)(0xC0 | (codepoint >> 6));
              *dst_pos++ = (U8)(0x80 | (codepoint & 0x3F));
              break;
      case 2: *dst_pos++ = (U8)(0xE0 | (codepoint >> 12));
              *dst_pos++ = (U8)(0x80 | ((codepoint >> 6) & 0x3F));
              *dst_pos++ = (U8)(0x80 | (codepoint & 0x3F));
              break;
      case 3: *dst_pos++ = (U8)(0xF0 | (codepoint >> 18));
              *dst_pos++ = (U8)(0x80 | ((codepoint >> 12) & 0x3F));
              *dst_pos++ = (U8)(0x80 | ((codepoint >> 6) & 0x3F));
              *dst_pos++ = (U8)(0x80 | (codepoint & 0x3F));
              break;
      }
   }
   else if (encoding == SECRET_BUFFER_ENCODING_UTF16LE
         || encoding == SECRET_BUFFER_ENCODING_UTF16BE
   ) {
      int low= (encoding == SECRET_BUFFER_ENCODING_UTF16LE)? 0 : 1;
      if (n == 2) {
         dst_pos[low] = (U8)(codepoint & 0xFF);
         dst_pos[low^1] = (U8)(codepoint >> 8);
      }
      else {
         int adjusted = codepoint - 0x10000;
         int w0 = 0xD800 | (adjusted >> 10);
         int w1 = 0xDC00 | (adjusted & 0x3FF);
         dst_pos[low]   = (U8)(w0 & 0xFF);
         dst_pos[1^low] = (U8)(w0 >> 8);
         dst_pos[2^low] = (U8)(w1 & 0xFF);
         dst_pos[3^low] = (U8)(w1 >> 8);
      }
   }
   else if (encoding == SECRET_BUFFER_ENCODING_HEX) {
      dst_pos[0] = "0123456789ABCDEF"[(codepoint >> 4) & 0xF];
      dst_pos[1] = "0123456789ABCDEF"[codepoint & 0xF];
   }
   else if (encoding == SECRET_BUFFER_ENCODING_I32) {
      *(I32*)dst_pos = codepoint;
   }
   /* BASE64 is not handled here because the '=' padding can only be generated in
    * a context that knows when we are ending on a non-multiple-of-4. */
   else SB_RETURN_ERROR("unsupported encoding");
   return true;
   #undef SB_RETURN_ERROR
}

#define SB_PARSE_MATCH_STR_FN sb_parse_match_str_U8
#define SB_PATTERN_EL_TYPE const U8
#include "secret_buffer_parse_match_str.c"
#undef SB_PARSE_MATCH_STR_FN
#undef SB_PATTERN_EL_TYPE

#define SB_PARSE_MATCH_STR_FN sb_parse_match_str_I32
#define SB_PATTERN_EL_TYPE const I32
#include "secret_buffer_parse_match_str.c"
#undef SB_PARSE_MATCH_STR_FN
#undef SB_PATTERN_EL_TYPE
