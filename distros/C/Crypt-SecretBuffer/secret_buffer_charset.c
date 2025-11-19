/* While the compiled Perl regular expression itself will have a character-class (set)
 * implementation that could be used directly, its API is private and changes across
 * perl versions.  I gave up on interfacing directly with that, and took this approach of
 * building my own bitmaps.
 *
 * The bitmaps only cache the result of testing the perl character class against bytes 0-0xFF
 * in a non-unicode context.  In a unicode context, it uses the cache for codepoints 0-0x7F
 * and falls back to invoking the regex engine on each character with a higher codepoint value.
 * This is inefficient, but I expect 7-bit ascii or non-unicode context is what gets used the
 * most anyway.
 *
 * This file gets sourced directly into SecretBuffer.xs, so its static functions are availabe
 * in other source files as well.
 */

struct secret_buffer_charset {
   uint64_t bitmap[4];   // covers 0..255 codepoints
   REGEXP *rx;           // refers to Regexp object this was derived from
   #define SECRET_BUFFER_CHARSET_NOUNI 0
   #define SECRET_BUFFER_CHARSET_ALLUNI 1
   #define SECRET_BUFFER_CHARSET_TESTUNI 2
   int unicode_above_7F; // controls action when matching against unicode
   bool match_multi;     // stores whether regex ended with '+'
};

/* MAGIC vtable for cached charset */
static int secret_buffer_charset_magic_free(pTHX_ SV *sv, MAGIC *mg) {
   if (mg->mg_ptr) {
      secret_buffer_charset *cset = (secret_buffer_charset*)mg->mg_ptr;
      Safefree(cset);
      mg->mg_ptr = NULL;
   }
   return 0;
}

#ifdef USE_ITHREADS
static int secret_buffer_charset_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
   secret_buffer_charset *old_cset = (secret_buffer_charset*)mg->mg_ptr;
   secret_buffer_charset *new_cset;

   Newx(new_cset, 1, secret_buffer_charset);
   Copy(old_cset, new_cset, 1, secret_buffer_charset);

   new_cset->rx = NULL; // filled again later during charset_from_regexp_ref

   mg->mg_ptr = (char*)new_cset;
   return 0;
}
#else
#define secret_buffer_charset_magic_dup 0
#endif

static MGVTBL secret_buffer_charset_magic_vtbl = {
   NULL,                     /* get */
   NULL,                     /* set */
   NULL,                     /* len */
   NULL,                     /* clear */
   secret_buffer_charset_magic_free,    /* free */
   NULL,                     /* copy */
   secret_buffer_charset_magic_dup,     /* dup */
   NULL                     /* local */
};

/* Set a bit in the bitmap */
static inline void sbc_bitmap_set(uint64_t *bitmap, U8 c) {
   bitmap[c >> 6] |= (1ULL << (c & 63));
}
/* Test for byte in bitmap */
static inline bool sbc_bitmap_test(const uint64_t *bitmap, U8 c) {
   return (bitmap[c >> 6] >> (c & 63)) & 1;
}

/* Helper to test if a unicode codepoint matches the charset */
static bool sbc_test_codepoint(pTHX_ const secret_buffer_charset *cset, uint32_t cp) {
   /* Codepoints 0..7F are cached.  Could cache up to 0xFF but locale might mess things up */
   if (cp <= 0x80)
      return sbc_bitmap_test(cset->bitmap, (U8) cp);
   /* High codepoint handling */
   if (cset->unicode_above_7F == SECRET_BUFFER_CHARSET_TESTUNI) {
      /* Must test with regex engine */
      if (!cset->rx) return false;
      SV *test_sv= sv_2mortal(newSV(8));
      U8 *utf8_buf= SvPVX(test_sv);
      U8 *end = uvchr_to_utf8(utf8_buf, cp);
      *end= '\0';
      SvPOK_on(test_sv);
      SvCUR_set(test_sv, (end - utf8_buf));
      SvUTF8_on(test_sv);
      I32 result = pregexec(cset->rx, utf8_buf, end, utf8_buf, 0, test_sv, 1);
      return result > 0;
   }
   else
      return cset->unicode_above_7F == SECRET_BUFFER_CHARSET_ALLUNI;
}

/* implement extern functions for public API */
bool secret_buffer_charset_test_byte(const secret_buffer_charset *cset, U8 b) {
   return sbc_bitmap_test(cset->bitmap, b);
}
bool secret_buffer_charset_test_codepoint(const secret_buffer_charset *cset, uint32_t cp) {
   dTHX;
   return sbc_test_codepoint(aTHX_ cset, cp);
}

/* Parse a simple character class into bitmap.  Returns true if it is confident
 * it fully handled the spec.  Returns false if anything might be a problem,
 * in which case caller should use build_bitmap_via_regex.
 */
#define HEXCHAR_TO_INT(c) (((c) >= '0' && (c) <= '9')? ((c) - '0') \
                         : ((c) >= 'A' && (c) <= 'F')? ((c) - 'A' + 10) \
                         : ((c) >= 'a' && (c) <= 'f')? ((c) - 'a' + 10) \
                         : -1)
static bool parse_simple_charclass(pTHX_ secret_buffer_charset *cset, SV *qr_ref) {
   uint64_t *bitmap= cset->bitmap;
   I32 range_start= -1;
   bool negated = false;
/* before 5.10 the flags are hidden somewhere and ->extflgs doesn't exist */
#ifdef RX_EXTFLAGS
   U32 rx_flags = RX_EXTFLAGS(cset->rx);
   bool flag_i= !!(rx_flags & RXf_PMf_FOLD);
/* the /xx flag was added in 5.26 */
#ifdef RXf_PMf_EXTENDED_MORE
   bool flag_xx= !!(rx_flags & RXf_PMf_EXTENDED_MORE);
#endif
   const char *pos = RX_PRECOMP(cset->rx);
   const char *lim = pos + RX_PRELEN(cset->rx);
#else
   /* collect the flags by parsing the stringified representation. */
   bool flag_i= false;
   STRLEN len;
   const char *pos= SvPV(qr_ref, len);
   const char *lim= pos + len;
   if (len < 3 || pos[0] != '(' || pos[1] != '?' || lim[-1] != ')')
      return false;
   bool ignore= false;
   for (pos += 2, lim--; *pos != ':'; ++pos) {
      if (pos >= lim) // we can read *lim because we bcked it up one char
         return false;
      if (*pos == 'i' && !ignore)
         flag_i= true;
      else if (*pos == '-')
         ignore= true;
   }
   pos++; /* cross ':' char */
#endif

   //warn("Attempting to parse '%.*s' %d  %c %c\n", (int)(lim-pos), pos, (int)RX_PRELEN(rx), *pos, lim[-1]);
   if (pos < lim && lim[-1] == '+') {
      cset->match_multi= true;
      lim--;
   }
   if (pos >= lim || *pos != '[' || lim[-1] != ']')
      return false;
   pos++; /* Skip [ */

   /* Check for negation */
   if (pos < lim && *pos == '^') {
      negated = true;
      pos++;
   }
   /* first character may be ] without ending charset */
   if (pos < lim && *pos == ']') {
      sbc_bitmap_set(bitmap, ']');
      pos++;
   }
   /* Parse characters and ranges */
   while (pos < lim && *pos != ']') {
      I32 c= (I32)(unsigned char) *pos++;
      int high, low;
      // in case of a literal char over 0x7F, things get confusing because I
      // can't tell whether the pattern itself is latin-1 or unicode.
      if (c >= 0x80)
         return false;
      // but if ascii notation describes a codepoint over 0x80, that's OK.
      else if (c == '\\') {
         if (pos >= lim) return false;
         switch (*pos++) {
         /* is it escaping something we can use literally below? */
         case '\\': case ']': case ' ':
            c= (unsigned char) pos[-1];
            break;
         /* is it a special constant? */
         case 'a': c= '\a'; break;
         case 'b': c= '\b'; break;
         case 'e': c= '\e'; break;
         case 'f': c= '\f'; break;
         case 'n': c= '\n'; break;
         case 'r': c= '\r'; break;
         case 't': c= '\t'; break;
         case 'o': // octal
            if (pos + 1 >= lim || !(*pos >= '0' && *pos <= '7'))
               return false;
            ++pos;
         case '0': case '1': case '2': case '3':
         case '4': case '5': case '6': case '7':
            c= pos[-1] - '0';
            if (pos < lim && *pos >= '0' && *pos <= '7')
               c= (c << 3) | (*pos++ - '0');
            if (pos < lim && *pos >= '0' && *pos <= '7')
               c= (c << 3) | (*pos++ - '0');
            if (c > 0xFF)
               cset->unicode_above_7F= SECRET_BUFFER_CHARSET_TESTUNI;
            break;
         case 'x':
            if (pos+1 >= lim) return false;
            high= HEXCHAR_TO_INT(pos[0]);
            low=  HEXCHAR_TO_INT(pos[1]);
            if (high < 0 || low < 0) return false;
            c= (high << 4) | low;
            pos += 2;
            break;
         default:
            /* too complicated, give up and fall back to exhaustive test*/
            return false;
         }
      }
      // abort on [:class:] notation
      else if (c == '[' && pos < lim && *pos == ':')
         return false;
// the /xx flag was added in 5.26
#ifdef RXf_PMf_EXTENDED_MORE
      else if ((c == ' ' || c == '\t') && flag_xx)
         continue;
#endif
      if (range_start >= 0) {
         if (c < range_start) /* Invalid range */
            return false;
         if (c > 0xFF)
            c= 0xFF;
         while (range_start <= c)
            sbc_bitmap_set(bitmap, (unsigned char) range_start++);
         range_start= -1;
      }
      else if (pos + 1 < lim && *pos == '-' && pos[1] != ']') {
         range_start= c;
         ++pos; // skip '-' char
      }
      else if (c < 0xFF) {
         sbc_bitmap_set(bitmap, (U8) c);
      }
   }
   if (pos+1 != lim) // regex did not end at ']', give up
      return false;
   //warn("bitmaps: %08llX %08llX %08llX %08llX\n", bitmap[0], bitmap[1], bitmap[2], bitmap[3]);
   if (flag_i) {
      // Latin1 case folding will be a mess best handled by the regex engine
      if (bitmap[2] | bitmap[3])
         return false;
      // Bits in range 0x41-0x5A need ORed into 0x61-0x7A and vice-versa
      bitmap[1] |= ((bitmap[1]>>32) & 0x7FFFFFE);
      bitmap[1] |= (bitmap[1] & 0x7FFFFFE) << 32;
   }
   // If any char 0x80-0xFF is set, a unicode context should use the regex engine.
   // Otherwise, the charset doesn't contain any upper chars at all.
   if (bitmap[2] || bitmap[3])
      cset->unicode_above_7F= SECRET_BUFFER_CHARSET_TESTUNI;
   // Apply negation
   if (negated) {
      for (int i = 0; i < 4; i++)
         bitmap[i] = ~bitmap[i];
      if (cset->unicode_above_7F == SECRET_BUFFER_CHARSET_NOUNI)
         cset->unicode_above_7F= SECRET_BUFFER_CHARSET_ALLUNI;
   }
   return true;
}

/* Build bitmap by testing each byte through regex engine */
static void build_charset_via_regex_engine(pTHX_ secret_buffer_charset *cset) {
   SV *test_sv= sv_2mortal(newSV(2));
   SvPOK_on(test_sv);
   SvCUR_set(test_sv, 1);
   char *buf= SvPVX(test_sv);
   //warn("Run regex test on chars 0x00-0xFF\n");
   for (int c= 0; c < 256; c++) {
      buf[0]= (char) c;
      /* find the next match */
      I32 result = pregexec(cset->rx, buf, buf+1, buf, 0, test_sv, 1);
      if (result > 0)
         sbc_bitmap_set(cset->bitmap, (unsigned char) c);
   }
}

static bool regex_is_single_charclass(REGEXP *rx) {
   /* Get the pattern string */
   STRLEN pat_len = RX_PRELEN(rx);
   const char *pattern = RX_PRECOMP(rx);
   struct regexp *re=
#ifndef SVt_REGEXP
      (struct regexp*) rx;          // before 5.12 REGEXP was struct regexp
#else
      (struct regexp*) SvANY(rx);   // after 5.12 REGEXP is a type of SV
#endif
   /* Try to validate that this regex is a single char class, with optional '+' */
   //warn("pattern = '%.*s' re->nparens = %d re->minlen = %d", pat_len, pattern, re->nparens, re->minlen);
   return pat_len >= 3 && pattern[0] == '[' && (
            pattern[pat_len-1] == ']'
         || (pattern[pat_len-1] == '+' && pattern[pat_len-2] == ']')
         );
//       && re->nparens == 0 && re->minlen == 1; <-- this doesn't seem to be reliable
}

/* Main function: Get or create cached charset from regexp */
secret_buffer_charset *secret_buffer_charset_from_regexpref(SV *qr_ref) {
   MAGIC *mg;
   REGEXP *rx;
   secret_buffer_charset *cset;
   dTHX;

   /* Validate input */
   if (!qr_ref || !(rx= (REGEXP*)SvRX(qr_ref)))
      croak("Expected Regexp ref");

   /* Check for existing cached charset */
   if (SvMAGICAL(qr_ref)) {
      mg = mg_findext(qr_ref, PERL_MAGIC_ext, &secret_buffer_charset_magic_vtbl);
      if (mg && mg->mg_ptr) {
         cset= (secret_buffer_charset*)mg->mg_ptr;
         cset->rx= rx; // in case threading cloned us
         return cset;
      }
   }

   if (!regex_is_single_charclass(rx))
      croak("Regex must contain a single character class and nothing else");

   /* Need to create new charset */
   Newxz(cset, 1, secret_buffer_charset);
   cset->rx = rx;

   if (!parse_simple_charclass(aTHX_ cset, qr_ref)) {
      // reset bitmap
      for (int i= 0; i < sizeof(cset->bitmap)/sizeof(cset->bitmap[0]); i++)
         cset->bitmap[i]= 0;
      // Need to use regex engine and cache results of first 256 codepoints.
      build_charset_via_regex_engine(aTHX_ cset);
      // If pattern has PMf_UNICODE or similar, it might match unicode
      //if (rx_flags & (RXf_PMf_LOCALE | RXf_PMf_UNICODE)) {
      // ...actually, if 'parse simple' couldn't handle it, need engine regardless
      cset->unicode_above_7F= SECRET_BUFFER_CHARSET_TESTUNI;
   }

   /* Attach magic to cache the charset */
   sv_magicext(qr_ref, NULL, PERL_MAGIC_ext,
               &secret_buffer_charset_magic_vtbl, (char*)cset, 0);

   return cset;
}
