
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
static bool sb_parse_match_str_U8(secret_buffer_parse *parse, const U8 *pattern, int pattern_len, int flags);
static bool sb_parse_match_str_I32(secret_buffer_parse *parse, const I32 *pattern, int pattern_len, int flags);

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
   secret_buffer *src_buf;
   secret_buffer_span *span;
   /* Is the pattern a regexp-ref? */
   if (rx) {
      secret_buffer_charset *cset= secret_buffer_charset_from_regexpref(pattern);
      return secret_buffer_match_charset(parse, cset, flags);
   }
   /* Is the pattern a SecretBuffer? */
   else if (SvROK(pattern) && (src_buf= secret_buffer_from_magic(pattern, 0))) {
      return sb_parse_match_str_U8(parse, (U8*) src_buf->data, src_buf->len, flags);
   }
   /* Is the pattern a SecretBuffer::Span? */
   else if (SvROK(pattern) && (span= secret_buffer_span_from_magic(pattern, 0))) {
      secret_buffer_parse pattern_parse;
      SV **buf_field= hv_fetchs(((HV*)SvRV(pattern)), "buf", 0);
      IV len= span->lim - span->pos;
      if (!buf_field || !*buf_field || !(src_buf= secret_buffer_from_magic(*buf_field, 0)))
         croak("Span lacks reference to source buffer");
      if (!secret_buffer_parse_init(&pattern_parse, src_buf, span->pos, span->lim, span->encoding))
         croak("%s", pattern_parse.error);
      /* optimize if it is a span of plain bytes */
      if (span->encoding == SECRET_BUFFER_ENCODING_ISO8859_1) {
         return sb_parse_match_str_U8(parse, pattern_parse.pos, len, flags);
      }
      /* else need to unpack the codepoints of the span */
      else {
         /* create a temporary secret buffer of integers */
         secret_buffer *tmp= secret_buffer_new(len * sizeof(I32), NULL);
         IV i= 0;
         while (pattern_parse.pos < pattern_parse.lim) {
            int cp= sb_parse_next_codepoint(&pattern_parse);
            if (cp < 0)
               croak("encoding error in pattern: %s", pattern_parse.error);
            ASSUME(i < len);
            ((I32*)tmp->data)[i++]= cp;
         }
         secret_buffer_set_len(tmp, i * sizeof(I32));
         return sb_parse_match_str_I32(parse, (I32*) tmp->data, i, flags);
      }
   }
   /* Else treat it as a normal SV, either UTF-8 or bytes (ISO8859-1) */
   else {
      STRLEN len;
      U8 *str= (U8*) SvPV(pattern, len);
      if (SvUTF8(pattern)) {
         /* unpack the UTF8 codepoints into I32 array.  Just in case they are a
          * secret, use a SecretBuffer instead of a plain malloc.
          */
         secret_buffer_parse tmp;
         secret_buffer *sb= secret_buffer_new(len * sizeof(I32), NULL); /* mortal, cleans itself up */
         size_t i= 0;
         Zero(&tmp, 1, secret_buffer_parse);
         tmp.pos= str;
         tmp.lim= str + len;
         tmp.encoding= SECRET_BUFFER_ENCODING_UTF8;
         while (tmp.pos < tmp.lim) {
            int cp= sb_parse_next_codepoint(&tmp);
            if (cp < 0)
               croak("%s", tmp.error);
            ASSUME(i < len);
            ((I32*)sb->data)[i++]= cp;
         }
         secret_buffer_set_len(sb, i * sizeof(I32));
         return sb_parse_match_str_I32(parse, (I32*) sb->data, i, flags);
      }
      return sb_parse_match_str_U8(parse, str, len, flags);
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

static const int8_t base64_decode_table[256]= {
   [0 ... 255] = -1,
   /* A–Z = 0–25 */
   ['A'] = 0,  ['B'] = 1,  ['C'] = 2,  ['D'] = 3,
   ['E'] = 4,  ['F'] = 5,  ['G'] = 6,  ['H'] = 7,
   ['I'] = 8,  ['J'] = 9,  ['K'] = 10, ['L'] = 11,
   ['M'] = 12, ['N'] = 13, ['O'] = 14, ['P'] = 15,
   ['Q'] = 16, ['R'] = 17, ['S'] = 18, ['T'] = 19,
   ['U'] = 20, ['V'] = 21, ['W'] = 22, ['X'] = 23,
   ['Y'] = 24, ['Z'] = 25,
   /* a–z = 26–51 */
   ['a'] = 26, ['b'] = 27, ['c'] = 28, ['d'] = 29,
   ['e'] = 30, ['f'] = 31, ['g'] = 32, ['h'] = 33,
   ['i'] = 34, ['j'] = 35, ['k'] = 36, ['l'] = 37,
   ['m'] = 38, ['n'] = 39, ['o'] = 40, ['p'] = 41,
   ['q'] = 42, ['r'] = 43, ['s'] = 44, ['t'] = 45,
   ['u'] = 46, ['v'] = 47, ['w'] = 48, ['x'] = 49,
   ['y'] = 50, ['z'] = 51,
   /* 0–9 = 52–61 */
   ['0'] = 52, ['1'] = 53, ['2'] = 54, ['3'] = 55,
   ['4'] = 56, ['5'] = 57, ['6'] = 58, ['7'] = 59,
   ['8'] = 60, ['9'] = 61,

   /* + and / */
   ['+'] = 62, ['/'] = 63,
   /* = flushes out the remaining bits */
   ['='] = 64
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
      memcpy(dst->pos, src->pos, cnt);
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
            if (dst->pos + 4 > dst->lim) {
               dst->error= "miscalculated buffer length";
               return false;
            }
            accum |= cp;
            *dst->pos++ = base64_alphabet[0x3F & (accum >> 18)];
            *dst->pos++ = base64_alphabet[0x3F & (accum >> 12)];
            *dst->pos++ = base64_alphabet[0x3F & (accum >> 6)];
            *dst->pos++ = base64_alphabet[0x3F & accum];
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
         *dst->pos++ = base64_alphabet[0x3F & (accum >> 18)];
         *dst->pos++ = base64_alphabet[0x3F & (accum >> 12)];
         *dst->pos++ = shift? '=' : base64_alphabet[0x3F & (accum >> 6)];
         *dst->pos++ = '=';
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
   int step= reverse? -1 : 1;
   U8 *pos= reverse? parse->lim-1 : parse->pos,
      *lim= reverse? parse->pos-1 : parse->lim,
      *span_start= NULL;
   //warn("scan_charset_bytes pos=%p lim=%p len=%d", parse->pos, parse->lim, (int)(parse->lim - parse->pos));

   while (pos != lim) {
      if (sbc_bitmap_test(cset->bitmap, *pos) != negate) {
         // Found.  Now are we looking for a span?
         if (span_start)
            break;
         if (!multi) {
            parse->pos= pos;
            parse->lim= pos+1;
            return true;
         }
         span_start= pos;
         negate= !negate;
      } else if (anchored && !span_start)
         break;
      pos += step;
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
   bool span_started= false;
   U8 *span_mark= NULL, *prev_mark= reverse? parse->lim : parse->pos;

   while (parse->pos < parse->lim) {
      int codepoint= reverse? sb_parse_prev_codepoint(parse)
                            : sb_parse_next_codepoint(parse);
      // warn("parse.pos=%p  parse.lim=%p  parse.enc=%d  cp=%d  parse.err=%s", parse->pos, parse->lim, parse->encoding, codepoint, parse->error);
      if (codepoint < 0) // encoding error
         return false;
      if (sbc_test_codepoint(aTHX_ cset, codepoint) != negate) {
         // Found.  Mark boundaries of char.
         // Now are we looking for a span?
         if (span_started)
            break;
         if (!multi) {
            if (reverse) {
               parse->pos= parse->lim;
               parse->lim= prev_mark;
            } else {
               parse->lim= parse->pos;
               parse->pos= prev_mark;
            }
            return true;
         }
         span_started= true;
         span_mark= prev_mark;
         negate= !negate;
      } else if (anchored && !span_started)
         break;
      prev_mark= reverse? parse->lim : parse->pos;
   }
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
   while (lhs->pos < lhs->lim && rhs->pos < rhs->lim) {
      lhs_cp= sb_parse_next_codepoint(lhs);
      if (lhs_cp < 0)
         croak("Encoding error in left-hand buffer");
      rhs_cp= sb_parse_next_codepoint(rhs);
      if (rhs_cp < 0)
         croak("Encoding error in right-hand buffer");
      if (lhs_cp != rhs_cp)
         return lhs_cp < rhs_cp? -1 : 1;
   }
   return (lhs->pos < lhs->lim)?  1 /* right string shorter than left */
        : (rhs->pos < rhs->lim)? -1 /* left string shorter than right */
        : 0;
}

/* UTF-8 decoding helper */
static int sb_parse_next_codepoint(secret_buffer_parse *parse) {
   U8 *pos= parse->pos, *lim= parse->lim;
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
         U8 *next= pos+1;
         while (next < lim && *next <= ' ')
            next++;
         if (next < lim && *next == '=') {
            pos= lim; // indicate parsing complete
            parse->pos_bit= 0;
         }
      }
   }
   else SB_RETURN_ERROR("unsupported encoding")
   parse->pos= pos;
   return cp;
   #undef SB_RETURN_ERROR
}

static int sb_parse_prev_codepoint(secret_buffer_parse *parse) {
   U8 *pos= parse->pos, *lim= parse->lim;
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
         U8 *start= lim;
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
   else
      return -1;
}

static bool sb_parse_encode_codepoint(secret_buffer_parse *dst, int codepoint) {
   #define SB_RETURN_ERROR(msg) { dst->error= msg; return false; }
   int encoding= dst->encoding;
   // codepoints above 0x10FFFF are illegal
   if (codepoint >= 0x110000)
      SB_RETURN_ERROR("invalid codepoint");
   // not quite as efficient as checking during the code below, but saves a bunch of redundancy
   int n= sizeof_codepoint_encoding(codepoint, encoding);
   if (n < 0)
      SB_RETURN_ERROR("character too wide for encoding")
   if (dst->lim - dst->pos < n)
      SB_RETURN_ERROR("buffer too small")

   if (encoding == SECRET_BUFFER_ENCODING_ASCII
    || encoding == SECRET_BUFFER_ENCODING_ISO8859_1
    || encoding == SECRET_BUFFER_ENCODING_UTF8
   ) {
      switch ((n-1)&0x3) { // help the compiler understand there are only 4 possible values
      case 0: *dst->pos++ = (U8) codepoint;
              break;
      case 1: *dst->pos++ = (U8)(0xC0 | (codepoint >> 6));
              *dst->pos++ = (U8)(0x80 | (codepoint & 0x3F));
              break;
      case 2: *dst->pos++ = (U8)(0xE0 | (codepoint >> 12));
              *dst->pos++ = (U8)(0x80 | ((codepoint >> 6) & 0x3F));
              *dst->pos++ = (U8)(0x80 | (codepoint & 0x3F));
              break;
      case 3: *dst->pos++ = (U8)(0xF0 | (codepoint >> 18));
              *dst->pos++ = (U8)(0x80 | ((codepoint >> 12) & 0x3F));
              *dst->pos++ = (U8)(0x80 | ((codepoint >> 6) & 0x3F));
              *dst->pos++ = (U8)(0x80 | (codepoint & 0x3F));
              break;
      }
   }
   else if (encoding == SECRET_BUFFER_ENCODING_UTF16LE
         || encoding == SECRET_BUFFER_ENCODING_UTF16BE
   ) {
      int low= (encoding == SECRET_BUFFER_ENCODING_UTF16LE)? 0 : 1;
      if (n == 2) {
         dst->pos[low] = (U8)(codepoint & 0xFF);
         dst->pos[low^1] = (U8)(codepoint >> 8);
         dst->pos+= 2;
      }
      else {
         int adjusted = codepoint - 0x10000;
         int w0 = 0xD800 | (adjusted >> 10);
         int w1 = 0xDC00 | (adjusted & 0x3FF);
         dst->pos[low] = (U8)(w0 & 0xFF);
         dst->pos[1^low] = (U8)(w0 >> 8);
         dst->pos[2^low] = (U8)(w1 & 0xFF);
         dst->pos[3^low] = (U8)(w1 >> 8);
         dst->pos+= 4;
      }
   }
   else if (encoding == SECRET_BUFFER_ENCODING_HEX) {
      *dst->pos++ = "0123456789ABCDEF"[(codepoint >> 4) & 0xF];
      *dst->pos++ = "0123456789ABCDEF"[codepoint & 0xF];
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
