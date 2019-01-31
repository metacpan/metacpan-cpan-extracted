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
    *end--;// = 0;
    --len;
  }

  return newSVpvn_flags( str, len, SvUTF8(sv) );
}


SV *_replace_str( SV *sv, SV *map ) {
  char buffer[_REPLACE_BUFFER_SIZE] = { 0 };
  char *src = SvPVX(sv);
  int len = SvCUR(sv);
  int           i = 0;
  char     *ptr = src;
  char           *str = buffer;             /* the new string we are going to use */
  char     *tmp; /* used to grow */
  int      str_size = _REPLACE_BUFFER_SIZE; /* we start with the buffer */
  int   ix_newstr = 0;
  AV           *mapav;
  SV           *reply;

  if ( !map || SvTYPE(map) != SVt_RV || SvTYPE(SvRV(map)) != SVt_PVAV
    || AvFILL( SvRV(map) ) <= 0
    ) {
      return newSVpv( src, len ); /* no alteration */
  }

  mapav = (AV *)SvRV(map);
  SV **ary = AvARRAY(mapav);


  for ( i = 0; i < len; ++i, ++ptr, ++ix_newstr ) {
    char c = *ptr;
    int  ix = (int) ( c );
    if ( ix < 0 ) ix = 256 + ix;
    // need to croak in DEBUG mode if char is invalid

    str[ix_newstr] = c; /* default always performed... */
    if ( ix >= AvFILL(mapav)
      || !AvARRAY(mapav)[ix]
      ) {
      continue;
    } else {
      SV *entry = AvARRAY(mapav)[ix];
      if ( SvPOK( entry ) ) {
        int slen = SvCUR( entry ); /* length of the string used for replacement */
        if ( slen <= 0  ) {
          continue;
        } else {
          char *replace = SvPVX( entry );
          int j;

          /* Check if we need to expand. */
          if (str_size <= (ix_newstr + slen + 1) ) { /* +1 for \0 */
            //printf( "#### need to grow %d -> %d\n", str_size, ix_newstr + slen );
            str_size *= 2;

            if ( str == buffer ) {
              /* our first malloc */
              Newx(str, str_size, char*);
              memcpy( str, buffer, _REPLACE_BUFFER_SIZE ); /* strncpy stops after the first \0 */
            } else {
              /* grow the string */
              tmp = Perl_realloc( str, str_size );
              if ( !tmp ) Perl_croak(aTHX_ "failed to realloc string" );
              str = tmp;
            }
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

  /* free our tmp buffer if needed */
  if ( str != buffer ) free(str);

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
