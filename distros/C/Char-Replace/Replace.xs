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

SV *_replace_str( char *src, int len, SV *map );

SV *_replace_str( char *src, int len, SV *map ) {
  char buffer[_REPLACE_BUFFER_SIZE] = { 0 };

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
    if ( ix >= AvFILL(mapav) || !AvARRAY(mapav)[ix] ) {
      continue;
    } else {
      SV *entry = AvARRAY(mapav)[ix];
      if ( SvPOK( entry ) ) {
        int slen = SvCUR( entry ); /* length of the string used for replacement */
        if ( slen <= 0  ) {
          continue;
        } else {
          char *replace = SvPVX( entry );
          int j = 0;

          /* Check if we need to expand. */
          if (str_size <= (ix_newstr + slen + 1) ) { /* +1 for \0 */
            //printf( "neew to grow %d -> %d\n", str_size, ix_newstr + slen );
            str_size *= 2;

            if ( str == buffer ) {
              /* our first malloc */
              Newx(str, str_size, char*);
              strncpy( str, buffer, ix_newstr );
            } else {
              /* grow the string */
              tmp = Perl_realloc( str, str_size );
              if ( !tmp ) Perl_croak(aTHX_ "failed to realloc string" );
              str = tmp;
            }
          }

          /* replace all characters except the last one, which avoids us to do a --ix_newstr after */
          for ( ; j < slen - 1; ++j ) {
            str[ix_newstr++] = replace[j];
          }
          /* handle the last character */
          str[ix_newstr] = replace[j];
        }
      } /* end - SvPOK */
    } /* end - AvFILL || AvARRAY */    
  }

  str[ix_newstr] = '\0'; /* add the final trailing \0 character */
  reply = newSVpv( str, ix_newstr );

  /* free our tmp buffer if needed */
  if ( str != buffer ) free(str);

  return reply;
}

MODULE = Char__Replace       PACKAGE = Char::Replace


SV*
replace(str, map)
  SV *str;
  SV *map;
CODE:
  if ( str && SvPOK(str) ) {
     RETVAL = _replace_str( SvPVX(str), SvCUR(str), map );
  } else {
     RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL
