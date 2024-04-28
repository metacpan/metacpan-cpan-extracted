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
    size_t const wsLen = wcslen(ws);

    bool needUtf8;
    unsigned int i;

    for (i = 0, needUtf8 = false; ws[i]; ++i) {
        if (ws[i] > 0xff)
            needUtf8 = true;
    }

    SvPOK_on(sv);

    if (needUtf8) {
        U8 * u8;
        U8 * u8Cursor;
        unsigned int i;

        u8 = (U8 *)sv_grow(sv, (wsLen + 1) * UTF8_MAXBYTES);
        for (i = 0, u8Cursor = &u8[0]; ws[i]; ++i)
            u8Cursor = UVCHR_TO_UTF8(u8Cursor, ws[i]);
        *u8Cursor = 0;
        SvCUR_set(sv, u8Cursor - &u8[0]);
        SvUTF8_on(sv);
    } else {
        U8 * u8;
        unsigned int i;

        u8 = (U8 *)sv_grow(sv, wsLen + 1);
        for (i = 0; ws[i]; ++i)
            u8[i] = ws[i];
        u8[i] = 0;
        SvCUR_set(sv, wsLen);
        SvUTF8_off(sv);
    }
}

static void
c_sv2GetWchar(SV *      const sv,
              wchar_t * const wcP,
              bool *    const succeededP) {
/*----------------------------------------------------------------------------
   Extract a wide character from a SV holding a one-character Perl string

   Fails (returning *succeededP false) iff SV doesn't hold a string or the
   string is not one character long.
-----------------------------------------------------------------------------*/
    if (!SvPOK(sv))
        *succeededP = false;
    else {
        U8 * s;
        STRLEN sLen;

        s = (U8 *)SvPV(sv, sLen);

        if (sLen == 0)
            *succeededP = false;
        else {
            if (SvUTF8(sv)) {
                STRLEN len;
                UV uv;

                uv = utf8_to_uvchr_buf_x(s, s + sLen, &len);

                if (len != sLen)
                    *succeededP = false;
                else {
                    *succeededP = true;
                    *wcP = (wchar_t)uv;
                }
            } else {
                if (sLen != 1)
                    *succeededP = false;
                else {
                    *succeededP = true;
                    *wcP = s[0];
                }
            }
        }
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

static wchar_t *
c_sv2wstr(SV *     const sv,
          size_t * const wLenP) {
/*----------------------------------------------------------------------------
   Extract a wide char string from a SV holding a Perl string.

   Fails (returning NULL) if SV doesn't hold a string or doesn't UTF-8
   decode.

   set *wLenP to length of result.

   Caller must free result
-----------------------------------------------------------------------------*/
    wchar_t * ws;

    if (!SvPOK(sv))
        ws = NULL;
    else {
        STRLEN sLen;
        U8 * s;

        s = (U8 *)SvPV(sv, sLen);
        ws = malloc((sLen + 1) * sizeof(ws[0]));
        /* number of bytes is an upper bound on the number of characters */
        if (!ws)
            croak("c_sv2wstr: malloc");
        if (SvUTF8(sv)) {
            U8 * sP;
            U8 * sEnd;
            unsigned int i;

            sP = &s[0];
            sEnd = &s[sLen];
            i = 0;

            while (sP < sEnd) {
                if (UTF8_IS_INVARIANT(*sP)) {
                    ws[i++] = *sP++;
                } else {
                    STRLEN len;
                    ws[i++] = utf8_to_uvchr_buf_x(sP, sEnd, &len);
                    sP += len;
                }
            }
            if (sP != sEnd) {
                free(ws);
                *wLenP = 0;
                ws = NULL;
            } else {
                ws[i] = 0;
                *wLenP = sLen;
            }
        } else {
            unsigned int i;

            for (i = 0; i < sLen; ++i)
                ws[i] = s[i];

            ws[i] = 0;
            *wLenP = sLen;
        }
    }
    return ws;
}


