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

#define NEED_newSVpvn_flags
#include "ppport.h"

/* prototypes */
SV* _parse_string_field(pTHX_ SV *sv, int need_field, const char sep);

SV* _parse_string_field(pTHX_ SV *sv, int need_field, const char sep) {
  STRLEN len = SvCUR(sv);
  char *ptr = (char *) SvPVX_const(sv); /* todo: preserve the const state of the pointer */
  AV   *av;
  char *start_key, *end_key;
  char *start_val, *end_val;
  char *max;
  int is_utf8 = SvUTF8(sv);
  const char eol      = '\n';
  const char comment  = '#';
  const char line_feed = '\r';
  int found_eol = 1;
  int found_comment = 0;
  int found_sep  = 0;
  int found_field = 0;

  av = newAV();

  start_key = ptr;
  end_key   = 0;
  start_val = 0;
  end_val   = 0;

  for ( max = ptr + len ; ptr < max; ++ptr ) {
    if ( ! *ptr ) continue; /* skip \0 so we can parse binaries strings */
    if ( *ptr == line_feed ) continue; /* ignore \r */

    /* printf( "# %c\n", *ptr ); */

    /* skip all characters in a comment block */
    if ( found_comment ) {
      if ( *ptr == eol ) found_comment = 0;
      continue;
    }

    if ( (need_field == 0 && found_sep) || (need_field && found_sep == need_field) ) {
      if ( *ptr == ' ' || *ptr == '\t' ) continue;
      if (need_field == 0) found_sep = 0;
      else ++found_sep; /* moving it away */
      end_val = start_val = ptr;
      found_field = 0;
    }

    /* get to the first valuable char of the line */
    if ( found_eol ) { /* starting a line */
      /* spaces at the beginning of a line */
      if ( *ptr == ' ' || *ptr == '\t' || *ptr == line_feed )
        continue;
      if ( *ptr == comment ) {
          found_comment = 1;
          continue;
      }
      /* we have a real character to start the line */
      found_eol = 0;
      start_key = ptr;
      end_key   = 0;
      end_val   = 0;
      found_sep = 0;
      start_val = 0;
      found_field = 0;
    }

    if ( *ptr == sep ) {
        /* printf ("# separator key/value\n" ); */
        if (need_field) ++found_sep;
        if ( !end_key  ) {
          end_key = ptr;
          if ( !need_field) found_sep = 1;
        }

        if ( need_field && found_sep == need_field + 2 ) {
          end_val = ptr;
          found_field = 1;
        }

    }  else if ( *ptr == eol ) { /* only handle the line once we reach a \n */

#define __PARSE_STRING_LINE_FIELD /* reuse code for the last line */ \
        if ( ( need_field == 0 || found_field == 0) && end_val == start_val) end_val = ptr; \
        if (end_val && *end_val == line_feed) end_val = ptr - 1; \
        found_eol = 1; \
\
        /* check if we got a key (end_key is NULL when no separator was found) */ \
        if ( end_key && end_key > start_key ) { \
          /* we got a key */ \
          av_push(av, newSVpvn_flags( start_key, (STRLEN) (end_key - start_key), is_utf8 )); \
\
          /* remove the line_feed chars if any */ \
          while ( start_val && end_val > start_val && \
            ( ( *(end_val - 1) == line_feed ) || ( *(end_val - 1) == ' ' ) || ( *(end_val - 1) == '\t' ) ) \
            ) { \
            --end_val; \
          }  \
          /* only add the value if we have a key */ \
          if ( start_val && end_val > start_val ) { \
            av_push(av, newSVpvn_flags( start_val, (STRLEN) (end_val - start_val), is_utf8 )); \
          } else { \
            av_push(av, &PL_sv_undef); \
          } \
        } \
/* end of __PARSE_STRING_LINE_FIELD */

        __PARSE_STRING_LINE_FIELD

        start_key = 0;
    }

  } /* end main for loop for *ptr */

  /* handle the last entry */
  if ( start_key ) {
      __PARSE_STRING_LINE_FIELD
  }

  return (SV*) (newRV_noinc((SV*) av));
}

MODULE = Colon__Config       PACKAGE = Colon::Config

SV*
read(sv, ...)
  SV *sv;
CODE:
  if ( sv && SvPOK(sv) ) {
    int field = 0;
    char sep = ':';
    if ( items > 3 )
      croak( "Too many arguments when calling 'Colon::Config::read'." );
    if ( items >= 2 ) {
      SV *sv_field = ST(1);
       if ( !SvOK(sv_field) || !looks_like_number(sv_field) )
          croak( "Colon::Config::read - Second argument must be one integer." );
        field = SvIV(sv_field);
        if ( field < 0 )
          croak( "Colon::Config::read - field must be >= 0" );
    }
    if ( items == 3 ) {
      SV *sv_sep = ST(2);
      STRLEN sep_len;
      char *sep_str;
      if ( !SvOK(sv_sep) || !SvPOK(sv_sep) )
        croak( "Colon::Config::read - Third argument must be a string." );
      sep_str = SvPV(sv_sep, sep_len);
      if ( sep_len != 1 )
        croak( "Colon::Config::read - separator must be a single character." );
      if ( sep_str[0] == '\n' || sep_str[0] == '\r' || sep_str[0] == '\0' )
        croak( "Colon::Config::read - separator cannot be a newline, carriage return, or null character." );
      sep = sep_str[0];
    }
    RETVAL = _parse_string_field( aTHX_ sv, field, sep );
  } else {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL

