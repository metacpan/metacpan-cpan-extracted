/*---------------------------------------------------------------------------
 * DateTime::Format::Lite - DateTime-Format-Lite.xs
 * Version v0.1.0
 * Copyright(c) 2026 DEGUEST Pte. Ltd.
 * Author: Jacques Deguest <jack@deguest.jp>
 * Created  2026/04/14
 * Modified 2026/04/16
 *
 * XS implementations of hot-path functions for DateTime::Format::Lite.
 *
 *   _match_and_extract( self, regex, fields_aref, string )
 *     Executes the pre-compiled pattern regex against the input string and
 *     returns a hashref { field => captured_value, ... } on success, or
 *     undef on no match. Called on every parse_datetime(), so keeping it
 *     in XS avoids the per-field Perl allocation loop.
 *
 *   format_datetime( self, dt )
 *     Calls DateTime::Lite->strftime( $pattern ) directly on the dt object
 *     without the clone() + set_locale() round-trip that Strptime 1.80
 *     performs. strftime() is already XS-accelerated in DateTime::Lite.
 *
 * This program is free software; you can redistribute  it  and/or  modify  it
 * under the same terms as Perl itself.
 *---------------------------------------------------------------------------*/
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"
#include "ppport.h"

/* RX_OFFS was removed in Perl 5.37.10 (first shipped in 5.38.0).
 * RX_OFFSp(rx) returns a pointer to the offsets array from that version on.
 * On older perls RX_OFFS(rx) returns the array directly.
 * We normalise to a single macro RX_OFFS_PTR(rx) that always yields a pointer. */
#if PERL_VERSION_GE(5,37,10)
#  define RX_OFFS_PTR(rx)  RX_OFFSp(rx)
#else
#  define RX_OFFS_PTR(rx)  RX_OFFS(rx)
#endif


#include <stdlib.h>
#include <string.h>

MODULE = DateTime::Format::Lite    PACKAGE = DateTime::Format::Lite

PROTOTYPES: ENABLE

# ---------------------------------------------------------------------------
# _match_and_extract( self, regex, fields_aref, string )
#
# Executes the pre-compiled regex against the input string.
# Returns a hashref mapping each field name in fields_aref to its captured
# substring, or undef if the string does not match.
# ---------------------------------------------------------------------------
SV *
_match_and_extract(self, regex, fields_aref, string)
    SV *self;
    SV *regex;
    AV *fields_aref;
    SV *string;

    PREINIT:
        REGEXP *rx;
        char   *str;
        STRLEN  str_len;
        I32     num_fields;
        I32     i;
        HV     *result;
        SV    **field_svp;

    CODE:
        (void)self;

        /* Extract the compiled regexp from the regex SV */
        rx = SvRX( regex );
        if( !rx )
        {
            warn( "_match_and_extract: argument is not a compiled regexp\n" );
            RETVAL = &PL_sv_undef;
            goto mae_done;
        }

        str        = SvPVutf8( string, str_len );
        num_fields = (I32)( av_len( fields_aref ) + 1 );

        /* Run the regex against the string */
        if( !pregexec( rx, str, str + str_len, str, 0, string, REXEC_COPY_STR ) )
        {
            RETVAL = &PL_sv_undef;
            goto mae_done;
        }

        /* Build result hashref from capture groups keyed by field names */
        result = (HV *)sv_2mortal( (SV *)newHV() );
        for( i = 0; i < num_fields; i++ )
        {
            I32 cap_idx = i + 1;   /* $1 = index 1, $2 = index 2, ... */

            field_svp = av_fetch( fields_aref, (SSize_t)i, 0 );
            if( !field_svp || !SvOK( *field_svp ) )
                continue;

            if( cap_idx > (I32)RX_NPARENS( rx ) )
                continue;

            {
                I32 start = RX_OFFS_PTR( rx )[ cap_idx ].start;
                I32 end   = RX_OFFS_PTR( rx )[ cap_idx ].end;

                if( start < 0 || end < start )
                    continue;

                {
                    SV *val = newSVpvn( str + start, (STRLEN)( end - start ) );
                    if( SvUTF8( string ) )
                        SvUTF8_on( val );
                    /* hv_store_ent increments refcount of the key SV */
                    hv_store_ent( result, *field_svp, val, 0 );
                }
            }
        }

        RETVAL = newRV( (SV *)result );

    mae_done: ;

    OUTPUT:
        RETVAL

# ---------------------------------------------------------------------------
# format_datetime( self, dt )
#
# Formats a DateTime::Lite object using $self->{pattern}, delegating to
# DateTime::Lite->strftime() without cloning the object first.
# Returns the formatted string, or undef if $self->{pattern} is missing.
# ---------------------------------------------------------------------------
SV *
format_datetime(self, dt)
    SV *self;
    SV *dt;

    PREINIT:
        HV    *self_hv;
        SV   **pattern_svp;
        SV    *result;
        I32    count;

    CODE:
        if( !SvROK( self ) || SvTYPE( SvRV( self ) ) != SVt_PVHV )
        {
            warn( "format_datetime: self is not a blessed hashref\n" );
            RETVAL = &PL_sv_undef;
            goto fmt_done;
        }

        self_hv     = (HV *)SvRV( self );
        pattern_svp = hv_fetchs( self_hv, "pattern", 0 );

        if( !pattern_svp || !SvOK( *pattern_svp ) )
        {
            RETVAL = &PL_sv_undef;
            goto fmt_done;
        }

        /* Call $dt->strftime( $self->{pattern} ) */
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK( SP );
            XPUSHs( dt );
            XPUSHs( *pattern_svp );
            PUTBACK;

            count  = call_method( "strftime", G_SCALAR );
            SPAGAIN;

            result = ( count > 0 ) ? SvREFCNT_inc( POPs ) : &PL_sv_undef;
            PUTBACK;
            FREETMPS;
            LEAVE;
        }

        RETVAL = result;

    fmt_done: ;

    OUTPUT:
        RETVAL
