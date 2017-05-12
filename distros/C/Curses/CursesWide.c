/* This is an inclusion for Curses.c */


/* Combined Normal/Wide-Character helper functions */

/* April 2014, Edgar Fuﬂ, Mathematisches Institut der Universit‰t Bonn,
  <ef@math.uni-bonn.de> 
*/

#include <wchar.h>

#if HAVE_PERL_UVCHR_TO_UTF8
  #define UVCHR_TO_UTF8 uvchr_to_utf8
#elif HAVE_PERL_UV_TO_UTF8
  #define UVCHR_TO_UTF8 uv_to_utf8
#else
  #error CursesWide.c cannot be compiled on this system; no uv[chr]_to_utf8
#endif



static UV
utf8_to_uvchr_buf_x(U8 *     s,
                    U8 *     end,
                    STRLEN * lenP) {

#if HAVE_PERL_UTF8_TO_UVCHR_BUF
    return utf8_to_uvchr_buf(s, end, lenP);
#elif HAVE_PERL_UTF8_TO_UVCHR
    return utf8_to_uvchr(s, lenP);
#elif HAVE_PERL_UTF8_TO_UV
    return utf8_to_uv(s, end - s, lenP, 0);
#else
    #error CursesWide.c cannot compile because \
           there is no utf8_to_uvchr_buf, etc.
#endif
}
    


static void
c_wchar2sv(SV *    const sv,
           wchar_t const wc) {
/*----------------------------------------------------------------------------
  Set SV to a one-character (not -byte!) Perl string holding a given wide
  character
-----------------------------------------------------------------------------*/
    if (wc <= 0xff) {
        char s[] = { wc, 0 };
        sv_setpv(sv, s);
        SvPOK_on(sv);
        SvUTF8_off(sv);
    } else {
        char s[UTF8_MAXBYTES + 1] = { 0 };
        char *s_end = (char *)UVCHR_TO_UTF8((U8 *)s, wc);
        *s_end = 0;
        sv_setpv(sv, s);
        SvPOK_on(sv);
        SvUTF8_on(sv);
    }
}

static void
c_bstr2sv(SV *            const sv,
          unsigned char * const bs) {
/*----------------------------------------------------------------------------
  Set SV to a Perl string holding a given byte string
-----------------------------------------------------------------------------*/
    SvPOK_on(sv);
    sv_setpv(sv, (char *)bs);
    SvUTF8_off(sv);
}

static void
c_wstr2sv(SV *      const sv,
          wchar_t * const ws) {
/*----------------------------------------------------------------------------
  Set SV to a Perl string holding a given wide string
-----------------------------------------------------------------------------*/
    wint_t *ws_p;
    int need_utf8 = 0;
    size_t ws_len = wcslen(ws);
    
    for (ws_p = ws; *ws_p; ws_p++) {
        if (*ws_p > 0xff) {
            need_utf8 = 1;
            break;
        }
    }
    SvPOK_on(sv);
    if (need_utf8) {
        U8 *u8, *u8_p;
        u8 = (U8 *)sv_grow(sv, (ws_len + 1) * UTF8_MAXBYTES);
        for (ws_p = ws, u8_p = u8; *ws_p; ws_p++)
            u8_p = UVCHR_TO_UTF8(u8_p, *ws_p);
        *u8_p = 0;
        SvCUR_set(sv, u8_p - u8);
        SvUTF8_on(sv);
    } else {
        U8 *u8, *u8_p;
        u8 = (U8 *)sv_grow(sv, ws_len + 1);
        for (ws_p = ws, u8_p = u8; *ws_p; ws_p++, u8_p++)
            *u8_p = *ws_p;
        *u8_p = 0;
        SvCUR_set(sv, ws_len);
        SvUTF8_off(sv);
    }
}

static wint_t
c_sv2wchar(SV * const sv) {
/*----------------------------------------------------------------------------
   Extract a wide character from a SV holding a one-character Perl string

   Fails (returning WEOF) if SV doesn't hold a string or the string is not one
   character long.
-----------------------------------------------------------------------------*/
    U8 *s;
    STRLEN s_len;
    if (!SvPOK(sv))
        return WEOF;
    s = (U8 *)SvPV(sv, s_len);
    if (s_len == 0)
        return WEOF;
    if (SvUTF8(sv)) {
        STRLEN len;
        UV uv = utf8_to_uvchr_buf_x(s, s + s_len, &len);
        if (len != s_len)
            return WEOF;
        return (wint_t) uv;
    } else {
        if (s_len != 1)
            return WEOF;
        return *s;
    }
}

static unsigned char *
c_sv2bstr(SV *     const sv,
          size_t * const b_len,
          int *    const need_free) {
/*----------------------------------------------------------------------------
  Extract a char (byte) string from a SV holding a Perl string

  Fails (returning NULL) if SV doesn't hold a string or the string has
  characters not fitting into a byte or doesn't UTF-8 decode

  Set b_len to length of result.

   Caller must free() result if we set need_free.
-----------------------------------------------------------------------------*/
    U8 *s, *s_p, *s_end;
    STRLEN s_len;
    unsigned char *bs, *bs_p;

    if (!SvPOK(sv)) {
        *need_free = 0;
        return NULL;
    }
    s = (U8 *)SvPV(sv, s_len);
    s_p = s;
    s_end = s + s_len;
    if (SvUTF8(sv)) {
        bs = malloc(s_len + 1);
            /* number of bytes is an upper bound on the number of characters */
        if (bs == NULL) croak("c_sv2bstr: malloc");
        bs_p = bs;
        while (s_p < s_end) {
            if (UTF8_IS_INVARIANT(*s_p)) {
                *bs_p++ = *s_p++;
            } else {
                STRLEN len;
                UV uv = utf8_to_uvchr_buf_x(s_p, s_end, &len);
                if (uv > 0xff) {
                    *need_free = 0;
                    *b_len = 0;
                    return NULL;
                }
                *bs_p++ = uv;
                s_p += len;
            }
        }
        if (s_p != s_end) {
            *need_free = 0;
            *b_len = 0;
            return NULL;
        }
        *bs_p = 0;
        *b_len = s_len;
        *need_free = 1;
        return bs;
    } else {
        *need_free = 0;
        *b_len = s_len;
        return (unsigned char *)s;
    }

}

static wint_t *
c_sv2wstr(SV *     const sv,
          size_t * const w_len) {
/*----------------------------------------------------------------------------
   Extract a wide char string from a SV holding a Perl string.

   Fails (returning NULL) if SV doesn't hold a string or doesn't UTF-8
   decode.

   set w_len s to length of result.

   Caller must free() result
-----------------------------------------------------------------------------*/
    U8 *s, *s_p, *s_end;
    STRLEN s_len;
    wint_t *ws, *ws_p;

    if (!SvPOK(sv)) return NULL;
    s = (U8 *)SvPV(sv, s_len);
    s_p = s;
    s_end = s + s_len;
    ws = malloc((s_len + 1) * sizeof(*ws));
        /* number of bytes is an upper bound on the number of characters */
    if (ws == NULL) croak("c_sv2wstr: malloc");
    ws_p = ws;
    if (SvUTF8(sv)) {
        while (s_p < s_end) {
            if (UTF8_IS_INVARIANT(*s_p)) {
                *ws_p++ = *s_p++;
            } else {
                STRLEN len;
                *ws_p++ = utf8_to_uvchr_buf_x(s_p, s_end, &len);
                s_p += len;
            }
        }
        if (s_p != s_end) {
            free(ws);
            *w_len = 0;
            return NULL;
        }
    } else {
        s_p = s;
        while (s_p < s_end) {
            *ws_p++ = *s_p++;
        }
    }
    *ws_p = 0;
    *w_len = s_len;
    return ws;
}

