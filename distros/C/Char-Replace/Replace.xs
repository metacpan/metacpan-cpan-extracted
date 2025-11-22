/*
*
* Copyright (c) 2018, cPanel, LLC.
* All rights reserved.
* http://cpanel.net
*
* This is free software; you can redistribute it and/or modify it under the
* same terms as Perl itself.
*
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <embed.h>

#define _REPLACE_BUFFER_SIZE 64

#define IS_SPACE(c) c == ' ' || c == '\n' || c == '\r' || c == '\t' || c == '\f'

SV *_replace_str( SV *sv, SV *map );
SV *_trim_sv( SV *sv );

SV *_trim_sv( SV *sv ) {
  dTHX;
  int len  = SvCUR(sv);
  char *str = SvPVX(sv);;
  char *end = str + len - 1;

  // Skip whitespace at front...
  while ( IS_SPACE( (unsigned char) *str) ) {
    ++str;
    --len;
  }

  // Trim at end...
  while (end > str && isspace( (unsigned char) *end) ) {
    end--;
    --len;
  }

  return newSVpvn_flags( str, len, SvUTF8(sv) );
}


SV *_replace_str( SV *sv, SV *map ) {
  dTHX;
  STRLEN len;
  char *src;
  STRLEN        i = 0;
  char     *ptr;
  char           *str;                      /* the new string we are going to use */
  STRLEN      str_size;                     /* start with input length + some padding */
  STRLEN   ix_newstr = 0;
  AV           *mapav;
  SV           *reply;

  if ( !map || SvTYPE(map) != SVt_RV || SvTYPE(SvRV(map)) != SVt_PVAV
    || AvFILL( SvRV(map) ) <= 0
    ) {
      src = SvPV(sv, len);
      return newSVpvn_flags( src, len, SvUTF8(sv) ); /* no alteration */
  }

  src = SvPV(sv, len);
  ptr = src;
  str_size = len + 64;

  mapav = (AV *)SvRV(map);
  SV **ary = AvARRAY(mapav);

  /* Always allocate memory using Perl's memory management */
  Newx(str, str_size, char);


  for ( i = 0; i < len; ++i, ++ptr, ++ix_newstr ) {
    char c = *ptr;
    int  ix = (int) ( c );
    if ( ix < 0 ) ix = 256 + ix;
    // need to croak in DEBUG mode if char is invalid

    str[ix_newstr] = c; /* default always performed... */
    if ( ix >= AvFILL(mapav)
      || !ary[ix]
      ) {
      continue;
    } else {
      SV *entry = ary[ix];
      if ( SvPOK( entry ) ) {
        STRLEN slen;
        char *replace = SvPV( entry, slen ); /* length of the string used for replacement */
        if ( slen <= 0  ) {
          continue;
        } else {
          int j;

          /* Check if we need to expand. */
          if (str_size <= (ix_newstr + slen + 1) ) { /* +1 for \0 */
            /* Calculate the required size, ensuring it's enough */
            while (str_size <= (ix_newstr + slen + 1)) {
              str_size *= 2;
            }
            /* grow the string */
            Renew( str, str_size, char );
          }

          /* replace all characters except the last one, which avoids us to do a --ix_newstr after */
          for ( j = 0 ; j < slen - 1; ++j ) {
            str[ix_newstr++] = replace[j];
          }

          /* handle the last character */
          str[ix_newstr] = replace[j];
        }
      } /* end - SvPOK */
    } /* end - AvFILL || AvARRAY */
  }

  str[ix_newstr] = '\0'; /* add the final trailing \0 character */

  reply = newSVpvn_flags( str, ix_newstr, SvUTF8(sv) );

  /* free our tmp buffer */
  Safefree(str);

  return reply;
}

MODULE = Char__Replace       PACKAGE = Char::Replace

SV*
replace(sv, map)
  SV *sv;
  SV *map;
CODE:
  if ( sv && SvPOK(sv) ) {
     RETVAL = _replace_str( sv, map );
  } else {
     RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL

SV*
trim(sv)
  SV *sv;
CODE:
  if ( sv && SvPOK(sv) ) {
     RETVAL = _trim_sv( sv );
  } else {
     RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL
