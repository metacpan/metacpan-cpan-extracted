#ifdef WITH_UNICODE

#include "ODBC.h"
#include <stdio.h>
#include "ConvertUTF.h"

typedef enum { do_new=1, do_cat, do_set } new_cat_set_t;

/* static prototypes */
static long utf16_len(UTF16 *wp);
static void utf16_copy(UTF16 *d, UTF16 *s);

static SV * _dosvwv(SV * sv, UTF16 * wp, STRLEN len, new_cat_set_t mode);



/*
 * If len>=0, wp is an array of <len> wide characters without a
 * termination character.
 * If len==-1, wp is a null-terminated wide string
 */
static SV * _dosvwv(SV * sv, UTF16 * wp, STRLEN len, new_cat_set_t mode)
{
    char * p=NULL;
    STRLEN svlen;

#ifdef WIN32
    int bytes;
    bytes=WideCharToMultiByte(CP_UTF8,0,wp,len,NULL,0,NULL,NULL);
    Newz(0,p,1+bytes,char);	/* allocate bytes+1 chars - ptr to p */
    if (bytes!=0) {
        if(!WideCharToMultiByte(CP_UTF8,0,wp,len,p,bytes,NULL,NULL)) {
            int err=GetLastError();
            switch (err) {
              case ERROR_INSUFFICIENT_BUFFER:
                croak("_dosvwv: WideCharToMultiByte() failed: insufficient buffer");
              case ERROR_INVALID_FLAGS:
                croak("_dosvwv: WideCharToMultiByte() failed: invalid flags");
              case ERROR_INVALID_PARAMETER:
                croak("_dosvwv: WideCharToMultiByte() failed: invalid parameter");
              default:
                croak("_dosvwv: WideCharToMultiByte() failed: error code %i",err);
            }
        }
    }
    svlen=(len==-1 ? strlen(p) : bytes);
#else
    unsigned int bytes;
    if (len == -1) {
        len = utf16_len(wp);
    }
    if (len > 0) {
      ConversionResult ret;
      UTF16 *source_start = wp;
      UTF16 *source_end = source_start + len;
      UTF8 *target_start;
      UTF8 *target_end;

      /* Test conversion and find size UTF* of buffer we need */
      ret = ConvertUTF16toUTF8((const UTF16 **)&source_start, source_end,
			       NULL, NULL, strictConversion, &bytes);
      /*printf("Bytes Required = %d\n", bytes);*/
      if (ret != conversionOK) {
	if (ret == sourceExhausted) {
	  croak("_dosvwc: Partial character in input");
	} else if (ret == targetExhausted) {
	  croak("_dosvwc: target buffer exhausted");
	} else if (ret == sourceIllegal) {
	  croak("_dosvwc: malformed/illegal source sequence");
	} else {
	  croak("_dosvwc: unknown ConvertUTF16toUTF8 error");
        }
      }
      Newz(0, p, bytes + 1, char);
      /* convert UTF16 to UTF8 */
      target_start = p;
      target_end = p + bytes;
      source_start = (UTF16 *)wp;
      source_end = source_start + len;
      ret = ConvertUTF16toUTF8((const UTF16 **)&source_start, source_end,
			       &target_start, target_end,
			       strictConversion, &bytes);
      /*fprintf(stderr, "%s\n", p);*/

      if (ret != conversionOK) {
	croak("_dosvwc: second call to ConvertUTF16toUTF8 failed (%d)", ret);
      }
      svlen = bytes;
    } else {
        svlen = 0;
    }
#endif

    switch (mode) {
      case do_new:
        sv=newSVpvn(p,svlen);
        break;
      case do_cat:
        sv_catpvn_mg(sv,p,svlen);
        break;
      case do_set:
        sv_setpvn_mg(sv,p,svlen);
        break;
      default:
        croak("_dosvwv called with bad mode value");
    }

#ifdef sv_utf8_decode
    if (!sv_utf8_decode(sv)) {
        croak("Attempt to utf8 decode a non utf8 sequence");
    }
#else
    if (*p) {
        SvUTF8_on(sv);
        /*printf("Switching UTF8 on\n");*/

    } else if (mode!=do_cat) {
        SvUTF8_off(sv); /* Don't switch off UTF8 just because we *APPENDED* an empty string! sv may still be UTF8. */
        /*printf("Switching UTF8 off\n");*/
    }
#endif
    Safefree(p);
    return sv;
}

/*
 * Set the string value of an SV* to a representation of a UTF16 * value,
 * similar to sv_setpvn() and sv_setpv()
 * SV contains UTF-8 representation of wp, has UTF8-Flag on except for
 * empty strings
 *
 * wp is an array of <len> wide characters without a termination character
 */
void sv_setwvn(SV * sv, UTF16 * wp, STRLEN len)
{
    if (wp==NULL) {
        sv_setpvn(sv,NULL,len);
    } else if (len==0) {
        sv_setpvn(sv,"",0);
    } else {
        _dosvwv(sv,wp,len,do_set);
    }
}

SV *sv_newwvn(UTF16 * wp, STRLEN len)
{
    SV *sv;

    /*printf("wp=%p, strlen=%d\n", wp, len);*/

    if (wp==NULL) {
        sv = &PL_sv_undef;
    } else if (len==0) {
        sv = newSVpvn("",0);
    } else {
        sv = _dosvwv(NULL,wp,len,do_new);
    }
    return sv;

}

/*
 * Get a UTF16 * representation of a char *
 * The representation is a converted copy, so the result needs to be freed
 * usng WVfree().
 * char * s == NULL is handled properly
 *
 * Does not handle byte arrays, only null-terminated strings.
 */
UTF16 * WValloc(char * s)
{
    UTF16 * buf=NULL;
    if (NULL!=s) {
#ifdef WIN32
        int widechars=MultiByteToWideChar(CP_UTF8,0,s,-1,NULL,0);
        Newz(0,buf,widechars+1,UTF16);
        if (widechars!=0) {
            MultiByteToWideChar(CP_UTF8,0,s,-1,buf,widechars);
        }
#else  /* !WIN32 */
        unsigned int widechrs, bytes;
        size_t slen;
        ConversionResult ret;
        UTF8 *source_start, *source_end;
        UTF16 *target_start, *target_end;

        slen = strlen(s);
        /*printf("utf8 string \\%.20s\\ is %d bytes long\n", s, slen);*/

        source_start = s;
        /* source_end needs to include NUL and be 1 past as ConvertUTF8toUTF17
           loops while < source_end */
        source_end = s + slen + 1;

        ret = ConvertUTF8toUTF16(
            (const UTF8 **)&source_start, source_end,
            NULL, NULL, strictConversion, &bytes);
        if (ret != conversionOK) {
            if (ret == sourceExhausted) {
                croak("WValloc: Partial character in input");
            } else if (ret == targetExhausted) {
                croak("WValloc: target buffer exhausted");
            } else if (ret == sourceIllegal) {
                croak("WValloc: malformed/illegal source sequence");
            } else {
                croak("WValloc: unknown ConvertUTF16toUTF8 error");
            }
        }
        /*printf("utf8 -> utf16 requires %d bytes\n", bytes);*/

        widechrs = bytes / sizeof(UTF16);
        /*printf("Allocating %d wide chrs\n", widechrs);*/

        Newz(0,buf,widechrs + 1,UTF16);
        if (widechrs != 0) {
            source_start = s;
            /* 1 after NUL because ConvertUTF8toUTF16 does while < end */
            source_end = s + slen + 1;
            target_start = buf;
            /* in ConvertUTF8toUTF16 once target_end hit buf is exhausted */
            target_end = buf + widechrs;
            /*printf("ss=%p se=%p ts=%p te=%p\n",
              source_start, source_end, target_start, target_end);*/

            ret = ConvertUTF8toUTF16(
                (const UTF8 **)&source_start, source_end,
                &target_start, target_end, strictConversion, &bytes);
            if (ret != conversionOK) {
                croak("WValloc: second call to ConvertUTF8toUTF16 failed (%d)", ret);
            }
            /*printf("Second returned %d bytes\n", bytes);*/
        }
#endif  /* WIN32 */
    }
    return buf;
}


/*
 * Free a UTF16 * representation of a char *
 * Used to free the return values of WValloc()
 */
void WVfree(UTF16 * wp)
{
    if (wp != NULL) Safefree(wp);
}


/*
 * Get a char * representation of a UTF16 *
 * The representation is a converted copy, so the result needs to be freed
 * using PVfree().
 * wp == NULL is handled properly
 *
 * Does not handle byte arrays, only null-terminated strings.
 */

char * PVallocW(UTF16 * wp)
{
    char * p=NULL;

    if (wp!=NULL) {

#ifdef WIN32
        int bytes=WideCharToMultiByte(
            CP_UTF8,                            /* convert to UTF8 */
            0,                                  /* no flags */
            wp,                             /* wide chrs to convert */
            -1,                            /* wp is null terminated */
            NULL,                           /* no conversion output */
            0,                     /* return how many bytes we need */
            NULL,           /* default chr - must be NULL for UTF-8 */
            NULL); /* was default chr used - must be NULL for UTF-8 */
        if (bytes == 0) {
        		DWORD err;
        		err = GetLastError();
        		croak("WideCharToMultiByte() failed with %ld", err);
        }
        Newz(0,p,bytes,char);                   /* allocate "bytes" chars */
        if (!WideCharToMultiByte(CP_UTF8,0,wp,-1,p,bytes,NULL,NULL)) {
        	  DWORD err;
        	  err = GetLastError();
            croak("WideCharToMultiByte() failed with %ld, bytes=%d, chrs=%d", err, bytes, wcslen(wp));
        }
#else
        ConversionResult ret;
        UTF16 *source_start;
        UTF16 *source_end;
        unsigned int bytes;
        UTF8 *target_start;
        UTF8 *target_end;
        long len;

        if (wp != NULL) {
            len = utf16_len(wp);
        }
        source_start = (UTF16 *)wp;
        source_end = source_start + len;
        ret = ConvertUTF16toUTF8((const UTF16 **)&source_start, source_end,
                                 NULL, NULL, strictConversion, &bytes);
        if (ret != conversionOK) {
            if (ret == sourceExhausted) {
                croak("PVallocW: Partial character in input");
            } else if (ret == targetExhausted) {
                croak("PVallocW: target buffer exhausted");
            } else if (ret == sourceIllegal) {
                croak("PVallocW: malformed/illegal source sequence");
            } else {
                croak("PVallocW: unknown ConvertUTF16toUTF8 error");
            }
        }
        Newz(0,p,bytes,char);
        target_start = p;
        target_end = p + bytes;
        source_start = (UTF16 *)wp;
        source_end = source_start + len;
        ret = ConvertUTF16toUTF8((const UTF16 **)&source_start, source_end,
                                 &target_start, target_end,
                                 strictConversion, &bytes);
        if (ret != conversionOK) {
            croak("PVallocW: second call to ConvertUTF16toUTF8 failed (%d)", ret);
        }
#endif
    }
    return p;
}


/*
 * Free a UTF16 * representation of a char *
 * Used to free the return value of PVallocW()
 * char * s == NULL is handled properly
 */
void PVfreeW(char * s)
{
    if (s!=NULL) Safefree(s);
}


/*
 * Mutate an SV's PV INPLACE to contain UTF-16. Does not handle byte arrays,
 * only null-terminated strings.
 * Turns the UTF8 flag OFF unconditionally, because SV becomes a byte array
 * (for Perl).
 */
void SV_toWCHAR(SV * sv)
{
    STRLEN len;
    UTF16 * wp;
    char * p;
    if (!SvOK(sv)) {
        /* warn("SV_toWCHAR called for undef"); */
        return;
    }
    /* _force makes sure SV is only a string */
    p=SvPVutf8_force(sv,len);
    /*printf("p=%p, strlen(p) = %d\n", p, strlen(p));*/

    wp=WValloc(p); /* allocate wp containing utf16 copy of utf8 p */
    len=utf16_len(wp);
    p=SvGROW(sv,sizeof(UTF16)*(1+len));
    utf16_copy((UTF16 *)p,wp);
    SvCUR_set(sv,sizeof(UTF16)*len);
    WVfree(wp);
    SvPOK_only(sv); /* sv is nothing but a non-UTF8 string -- for Perl ;-) */
}

/* change a UTF8 encoded SV to a wide chr string in place - see SV_toWCHAR */
void utf8sv_to_wcharsv(SV *sv)
{
#ifdef sv_utf8_decode
    sv_utf8_decode(sv);
#else
    SvUTF8_on(sv);
#endif
    SV_toWCHAR(sv);
}

static long utf16_len(UTF16 *wp)
{
    long len = 0;

    if (!wp) return 0;

    while (*wp != 0) {
        wp++;
        len++;
    }
    return len;
}

static void utf16_copy(UTF16 *d, UTF16 *s)
{
    while(*s) {
        /*printf("Copying %p %d\n", s, *s);*/
        *d++ = *s++;
    }
    *d = 0;
}
#endif /* WITH_UNICODE */
