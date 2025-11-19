
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
static bool sb_parse_match_bytestr(secret_buffer_parse *parse, const U8 *bytestr, size_t bytestr_len, int flags);

static bool parse_encoding(SV *sv, int *out) {
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
      case  3: if (0 == strcmp(str, "HEX"))       enc= SECRET_BUFFER_ENCODING_HEX;     break;
      case  4: if (0 == strcmp(str, "UTF8"))      enc= SECRET_BUFFER_ENCODING_UTF8;    break;
      case  5: if (0 == strcmp(str, "ASCII"))     enc= SECRET_BUFFER_ENCODING_ASCII;   else
               if (0 == strcmp(str, "UTF-8"))     enc= SECRET_BUFFER_ENCODING_UTF8;    break;
      case  7: if (0 == strcmp(str, "UTF16LE"))   enc= SECRET_BUFFER_ENCODING_UTF16LE; else
               if (0 == strcmp(str, "UTF16BE"))   enc= SECRET_BUFFER_ENCODING_UTF16BE; break;
      case  8: if (0 == strcmp(str, "UTF-16LE"))  enc= SECRET_BUFFER_ENCODING_UTF16LE; else
               if (0 == strcmp(str, "UTF-16BE"))  enc= SECRET_BUFFER_ENCODING_UTF16BE; break;
      case  9: if (0 == strcmp(str, "ISO8859_1")) enc= SECRET_BUFFER_ENCODING_ISO8859_1; break;
      case 10: if (0 == strcmp(str, "ISO-8859-1"))enc= SECRET_BUFFER_ENCODING_ISO8859_1; break;
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

/* Scan for a pattern which may be a regex or literal string.
 * Regexes are currently limited to a single charclass.
 */
bool secret_buffer_match(secret_buffer_parse *parse, SV *pattern, int flags) {
   REGEXP *rx= (REGEXP*)SvRX(pattern);
   if (rx) {
      secret_buffer_charset *cset= secret_buffer_charset_from_regexpref(pattern);
      return secret_buffer_match_charset(parse, cset, flags);
   } else {
      STRLEN len;
      U8 *str= (U8*) SvPVbyte(pattern, len);
      return secret_buffer_match_bytestr(parse, str, len, flags);
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
 * The caller is responsible for encoding them in the same format as requested
 * by parse_state->encoding.
 */
bool secret_buffer_match_bytestr(secret_buffer_parse *parse, char *data, size_t datalen, int flags) {
   return sb_parse_match_bytestr(parse, data, datalen, flags);
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
      U8 *orig_pos= src->pos;
      while (src->pos < src->lim) {
         int cp= sb_parse_next_codepoint(src);
         if (cp < 0) return -1;
         int ch_size= sizeof_codepoint_encoding(cp, dst_encoding);
         if (ch_size < 0) return -1;
         dst_size_needed += ch_size;
      }
      src->pos= orig_pos;
      return dst_size_needed;
   }
}

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
   }
   else SB_RETURN_ERROR("unknown encoding")
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
   else SB_RETURN_ERROR("unknown encoding")
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
   return true;
   #undef SB_RETURN_ERROR
}

bool sb_parse_match_bytestr(secret_buffer_parse *parse, const U8 *pattern, size_t pattern_len, int flags) {
   bool reverse=  0 != (flags & SECRET_BUFFER_MATCH_REVERSE);
   bool multi=    0 != (flags & SECRET_BUFFER_MATCH_MULTI);
   bool anchored= 0 != (flags & SECRET_BUFFER_MATCH_ANCHORED);
   bool negate=   0 != (flags & SECRET_BUFFER_MATCH_NEGATE);

   if (reverse) {
      U8 *orig_lim= parse->lim;
      // back up by whole characters until there are at least pattern_len bytes from the current
      // character until the original limit
      while (parse->lim > orig_lim - pattern_len) {
         if (parse->lim <= parse->pos)
            return false;
         if (sb_parse_prev_codepoint(parse) < 0)
            return false; // encoding error
      }
      // from here forward, ->lim is acting like a 'pos' and is safe for a memcmp of pattern_len bytes
      while (1) {
         if ((0 == memcmp(parse->lim, pattern, pattern_len)) != negate) {
            // Found.
            U8 *match_pos= parse->lim;
            U8 *match_lim= parse->lim + pattern_len;
            // Are we looking for a span of matches?
            if (multi) {
               while (1) {
                  // In the negate condition, need to step by whole characters.
                  // Else need to step by whole matches of the pattern.
                  if (!negate) 
                     parse->lim -= pattern_len;
                  else if (sb_parse_prev_codepoint(parse) < 0)
                     break; // encoding error
                  if (parse->lim < parse->pos) break;
                  if ((0 == memcmp(parse->lim, pattern, pattern_len)) == negate) {
                     // in the negate case, need to move match_pos to the end of the match.
                     if (negate && pattern_len > 1)
                        match_pos= parse->lim + pattern_len;
                     break;
                  }
                  // still matching (or not matching)
                  match_pos= parse->lim;
               }
            }
            parse->pos= match_pos;
            parse->lim= match_lim;
            return true;
         }
         else if (anchored)
            break;
         // step backward one character.  prev_codepoint will fail if there isn't a char available
         if (parse->lim <= parse->pos)
            break;
         if (sb_parse_prev_codepoint(parse) < 0)
            break; // encoding error
      }
   } else { // forward
      U8 *pmax= parse->lim - pattern_len;
      while (parse->pos <= pmax) {
         if ((0 == memcmp(parse->pos, pattern, pattern_len)) != negate) {
            // Found
            U8 *match_pos= parse->pos;
            U8 *match_lim= parse->pos + pattern_len;
            // Are we looking for a span of matches?
            if (multi) {
               while (1) {
                  // In the negate condition, need to step by whole characters.
                  // Else need to step by whole matches of the pattern.
                  if (!negate)
                     parse->pos += pattern_len;
                  else if (sb_parse_next_codepoint(parse) < 0)
                     break; // encoding error
                  if (parse->pos > pmax
                     || (0 == memcmp(parse->pos, pattern, pattern_len)) == negate)
                     break;
                  match_lim= parse->pos + pattern_len;
               }
            }
            parse->pos= match_pos;
            parse->lim= match_lim;
            return true;
         }
         else if (anchored)
            break;
         // step forward one character
         if (sb_parse_next_codepoint(parse) < 0)
            break; // encoding error
      }
   }
   return false;
}
