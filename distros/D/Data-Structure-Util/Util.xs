#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define dsDEBUG 0
#if dsDEBUG
#  define dsWARN(msg)  warn(msg)
#else
#  define dsWARN(msg)
#endif
#define PTRLEN 40

int has_seen( SV * sv, HV * seen );
/*
   Generate a string containing the address,
   the flags and the Sv type
*/

SV *
_get_infos( SV * sv ) {
    return newSVpvf( "%p-%x-%x", sv, SvFLAGS( sv ) & ~SVf_OOK,
                     SvTYPE( sv ) );
}

/*

Upgrade strings to utf8

*/
bool
_utf8_set( SV * sv, HV * seen, int onoff ) {
    I32 len, i;
    HV *myHash;
    HE *HEntry;
    SV **AValue;

    /* if this is a plain reference then simply
       move down to what the reference points at */

  redo_utf8:
    if ( SvROK( sv ) ) {
        if ( has_seen( sv, seen ) )
            return TRUE;
        sv = SvRV( sv );
        goto redo_utf8;
    }

    switch ( SvTYPE( sv ) ) {

        /* recursivly look inside a hash and arrays */

    case SVt_PVAV:{
            dsWARN( "Found array\n" );
            len = av_len( ( AV * ) sv );
            for ( i = 0; i <= len; i++ ) {
                AValue = av_fetch( ( AV * ) sv, i, 0 );
                if ( AValue )
                    _utf8_set( *AValue, seen, onoff );
            }
            break;
        }
    case SVt_PVHV:{
            dsWARN( "Found hash\n" );
            myHash = ( HV * ) sv;
            hv_iterinit( myHash );
            while (( HEntry = hv_iternext( myHash ) )) {
                _utf8_set( HeVAL( HEntry ), seen, onoff );
            }
            break;
        }

        /* non recursive case, check if it's got a string
           value or not. */

    default:{
            if ( SvPOK( sv ) ) {
                /* it's a string! do the transformation if we need to */

                dsWARN( "string (PV)\n" );
                dsWARN( SvUTF8( sv ) ? "UTF8 is on\n" : "UTF8 is off\n" );
                if ( onoff && !SvUTF8( sv ) ) {
                    sv_utf8_upgrade( sv );
                }
                else if ( !onoff && SvUTF8( sv ) ) {
                    sv_utf8_downgrade( sv, 0 );
                }
            }
            else {
                /* unknown type.  Could be a SvIV or SvNV, but they don't
                   have magic so that's okay.  Could also be one of the
                   types we don't deal with (a coderef, a typeglob) */

                dsWARN( "unknown type\n" );
            }
        }
    }
    return TRUE;
}

/*

Change utf8 flag

*/
bool
_utf8_flag_set( SV * sv, HV * seen, int onoff ) {
    I32 i, len;
    HV *myHash;
    HE *HEntry;
    SV **AValue;

    /* if this is a plain reference then simply
       move down to what the reference points at */

  redo_flag_utf8:
    if ( SvROK( sv ) ) {
        if ( has_seen( sv, seen ) )
            return TRUE;
        sv = SvRV( sv );
        goto redo_flag_utf8;
    }

    switch ( SvTYPE( sv ) ) {

        /* recursivly look inside a hash and arrays */

    case SVt_PVAV:{
            dsWARN( "Found array\n" );
            len = av_len( ( AV * ) sv );
            for ( i = 0; i <= len; i++ ) {
                AValue = av_fetch( ( AV * ) sv, i, 0 );
                if ( AValue )
                    _utf8_flag_set( *AValue, seen, onoff );
            }
            break;
        }
    case SVt_PVHV:{
            dsWARN( "Found hash\n" );
            myHash = ( HV * ) sv;
            hv_iterinit( myHash );
            while (( HEntry = hv_iternext( myHash ) )) {
                _utf8_flag_set( HeVAL( HEntry ), seen, onoff );
            }
            break;
        }

        /* non recursive case, check if it's got a string
           value or not. */

    default:{

            /* it's a string! do the transformation if we need to */

            if ( SvPOK( sv ) ) {
                dsWARN( "string (PV)\n" );
                dsWARN( SvUTF8( sv ) ? "UTF8 is on\n" : "UTF8 is off\n" );
                if ( onoff && !SvUTF8( sv ) ) {
                    SvUTF8_on( sv );
                }
                else if ( !onoff && SvUTF8( sv ) ) {
                    SvUTF8_off( sv );
                }
            }
            else {

                /* unknown type.  Could be a SvIV or SvNV, but they don't
                   have magic so that's okay.  Could also be one of the
                   types we don't deal with (a codref, a typeglob) */

                dsWARN( "unknown type\n" );
            }
        }
    }
    return TRUE;
}

/*

Returns true if sv contains a utf8 string

*/
bool
_has_utf8( SV * sv, HV * seen ) {
    I32 i, len;
    SV **AValue;
    HV *myHash;
    HE *HEntry;

  redo_has_utf8:
    if ( SvROK( sv ) ) {
        if ( has_seen( sv, seen ) )
            return FALSE;
        sv = SvRV( sv );
        goto redo_has_utf8;
    }

    switch ( SvTYPE( sv ) ) {

    case SVt_PV:
    case SVt_PVNV:{
            dsWARN( "string (PV)\n" );
            dsWARN( SvUTF8( sv ) ? "UTF8 is on\n" : "UTF8 is off\n" );
            if ( SvUTF8( sv ) ) {
                dsWARN( "Has UTF8\n" );
                return TRUE;
            }
            break;
        }
    case SVt_PVAV:{
            dsWARN( "Found array\n" );
            len = av_len( ( AV * ) sv );
            for ( i = 0; i <= len; i++ ) {
                AValue = av_fetch( ( AV * ) sv, i, 0 );
                if ( AValue && _has_utf8( *AValue, seen ) )
                    return TRUE;
            }
            break;
        }
    case SVt_PVHV:{
            dsWARN( "Found hash\n" );
            myHash = ( HV * ) sv;
            hv_iterinit( myHash );
            while (( HEntry = hv_iternext( myHash ) )) {
                if ( _has_utf8( HeVAL( HEntry ), seen ) )
                    return TRUE;
            }
            break;
        }
    default: ;
    }
    return FALSE;
}

/*

unbless any object within the data structure

*/
SV *
_unbless( SV * sv, HV * seen ) {
    I32 i, len;
    SV **AValue;
    HV *myHash;
    HE *HEntry;

  redo_unbless:
    if ( SvROK( sv ) ) {

        if ( has_seen( sv, seen ) )
            return sv;

        if ( sv_isobject( sv ) ) {
            sv = ( SV * ) SvRV( sv );
            SvOBJECT_off( sv );
        }
        else {
            sv = ( SV * ) SvRV( sv );
        }
        goto redo_unbless;
    }

    switch ( SvTYPE( sv ) ) {

    case SVt_PVAV:{
            dsWARN( "an array\n" );
            len = av_len( ( AV * ) sv );
            for ( i = 0; i <= len; i++ ) {
                AValue = av_fetch( ( AV * ) sv, i, 0 );
                if ( AValue )
                    _unbless( *AValue, seen );
            }
            break;
        }
    case SVt_PVHV:{
            dsWARN( "a hash (PVHV)\n" );
            myHash = ( HV * ) sv;
            hv_iterinit( myHash );
            while (( HEntry = hv_iternext( myHash ) )) {
                _unbless( HeVAL( HEntry ), seen );
            }
            break;
        }
    default: ;
    }
    return sv;
}

/*

Returns objects within a data structure, deep first

*/
AV *
_get_blessed( SV * sv, HV * seen, AV * objects ) {
    I32 i;
    SV **AValue;
    HV *myHash;
    HE *HEntry;

    if ( SvROK( sv ) ) {

        if ( has_seen( sv, seen ) )
            return objects;
        _get_blessed( SvRV( sv ), seen, objects );
        if ( sv_isobject( sv ) ) {
            (void) SvREFCNT_inc( sv );
            av_push( objects, sv );
        }

    }
    else {

        switch ( SvTYPE( sv ) ) {
        case SVt_PVAV:{
                for ( i = 0; i <= av_len( ( AV * ) sv ); i++ ) {
                    AValue = av_fetch( ( AV * ) sv, i, 0 );
                    if ( AValue )
                        _get_blessed( *AValue, seen, objects );
                }
                break;
            }
        case SVt_PVHV:{
                myHash = ( HV * ) sv;
                hv_iterinit( myHash );
                while (( HEntry = hv_iternext( myHash ) )) {
                    _get_blessed( HeVAL( HEntry ), seen, objects );
                }
                break;
            }
        default: ;
        }
    }

    return objects;
}

/*

Returns references within a data structure, deep first

*/
AV *
_get_refs( SV * sv, HV * seen, AV * objects ) {
    I32 i;
    SV **AValue;
    HV *myHash;
    HE *HEntry;
    if ( SvROK( sv ) ) {

        if ( has_seen( sv, seen ) )
            return objects;
        _get_refs( SvRV( sv ), seen, objects );
        (void) SvREFCNT_inc( sv );
        av_push( objects, sv );

    }
    else {

        switch ( SvTYPE( sv ) ) {
        case SVt_PVAV:{
                for ( i = 0; i <= av_len( ( AV * ) sv ); i++ ) {
                    AValue = av_fetch( ( AV * ) sv, i, 0 );
                    if ( AValue )
                        _get_refs( *AValue, seen, objects );
                }
                break;
            }
        case SVt_PVHV:{
                myHash = ( HV * ) sv;
                hv_iterinit( myHash );
                while (( HEntry = hv_iternext( myHash ) )) {
                    _get_refs( HeVAL( HEntry ), seen, objects );
                }
                break;
            }
        default: ;
        }
    }
    return objects;
}

/*

Returns a signature of the structure

*/
AV *
_signature( SV * sv, HV * seen, AV * infos ) {
    I32 i;
    U32 len;
    SV **AValue;
    HV *myHash;
    HE *HEntry;
    char *HKey;

  testvar1:

    if ( SvROK( sv ) ) {
        if ( has_seen( sv, seen ) )
            return infos;

        av_push( infos, _get_infos( sv ) );
        sv = SvRV( sv );
        goto testvar1;

    }
    else {

        av_push( infos, _get_infos( sv ) );
        switch ( SvTYPE( sv ) ) {
        case SVt_PVAV:
            for ( i = 0; i <= av_len( ( AV * ) sv ); i++ ) {
                AValue = av_fetch( ( AV * ) sv, i, 0 );
                if ( AValue )
                    _signature( *AValue, seen, infos );
            }
            break;

        case SVt_PVHV:
            myHash = ( HV * ) sv;
            hv_iterinit( myHash );
            while (( HEntry = hv_iternext( myHash ) )) {
                STRLEN len;
                HKey = HePV( HEntry, len );
                _signature( HeVAL( HEntry ), seen, infos );
            }
            break;
        default: ;
        }
    }
    return infos;
}

/*

Detects if there is a circular reference

*/
SV *
_has_circular_ref( SV * sv, HV * parents, HV * seen ) {

    SV *ret;
    SV *found;
    U32 len;
    I32 i;
    SV **AValue;
    HV *myHash;
    HE *HEntry;
    SV **HValue;
#if dsDEBUG
    char errmsg[100];
#endif

    if ( SvROK( sv ) ) {        /* Reference */

        char addr[PTRLEN];
        sprintf( addr, "%p", SvRV( sv ) );
        len = strlen( addr );

        if ( hv_exists( parents, addr, len ) ) {
#ifdef SvWEAKREF
            if ( SvWEAKREF( sv ) ) {
                dsWARN( "found a weak reference" );
                return &PL_sv_undef;
            }
            else {
#endif
                dsWARN( "found a circular reference!!!" );
                (void) SvREFCNT_inc( sv );
                return sv;
#ifdef SvWEAKREF
            }
#endif
        }
        if ( hv_exists( seen, addr, len ) ) {
            dsWARN( "circular reference on weak ref" );
            return &PL_sv_undef;
        }

        (void) hv_store( parents, addr, len, NULL, 0 );
        (void) hv_store( seen, addr, len, NULL, 0 );
#ifdef SvWEAKREF
        if ( SvWEAKREF( sv ) ) {
            dsWARN( "found a weak reference 2" );
            ret = _has_circular_ref( SvRV( sv ), newHV(  ), seen );
        }
        else {
#endif
            ret = _has_circular_ref( SvRV( sv ), parents, seen );
#ifdef SvWEAKREF
        }
#endif
        (void) hv_delete( seen, addr, ( U32 ) len, 0 );
        (void) hv_delete( parents, addr, ( U32 ) len, 0 );
        return ret;
    }

    /* Not a reference */
    switch ( SvTYPE( sv ) ) {

    case SVt_PVAV:{            /* Array */
            dsWARN( "Array" );
            for ( i = 0; i <= av_len( ( AV * ) sv ); i++ ) {
#if dsDEBUG
                sprintf( errmsg, "next elem %i\n", i );
                warn( errmsg );
#endif
                AValue = av_fetch( ( AV * ) sv, i, 0 );
                if ( AValue ) {
                    found = _has_circular_ref( *AValue, parents, seen );
                    if ( SvOK( found ) )
                        return found;
                }
            }
            break;
        }
    case SVt_PVHV:{            /* Hash */
            dsWARN( "Hash" );
            myHash = ( HV * ) sv;
            hv_iterinit( myHash );
            while (( HEntry = hv_iternext( myHash ) )) {
#if dsDEBUG
                STRLEN len2;
                char *HKey = HePV( HEntry, len2 );
                sprintf( errmsg, "NEXT KEY is %s\n", HKey );
                warn( errmsg );
#endif
                found =
                    _has_circular_ref( HeVAL( HEntry ), parents, seen );
                if ( SvOK( found ) )
                    return found;
            }
            break;
        }
    default: ;
    }
    return &PL_sv_undef;
}

/*

Weaken any circular reference found

*/
SV *
_circular_off( SV * sv, HV * parents, HV * seen, SV * counter ) {

    U32 len;
    I32 i;
    SV **AValue;
    HV *myHash;
    HE *HEntry;
    char addr[PTRLEN];
#if dsDEBUG
    char errmsg[100];
#endif

    if ( SvROK( sv ) ) {        /* Reference */

        sprintf( addr, "%p", SvRV( sv ) );
        len = strlen( addr );

        if ( hv_exists( parents, addr, len ) ) {
            if ( SvWEAKREF( sv ) ) {
                dsWARN( "found a weak reference" );
            }
            else {
                dsWARN( "found a circular reference!!!" );
                sv_rvweaken( sv );
                sv_inc( counter );
            }
        }
        else {

            if ( hv_exists( seen, addr, len ) ) {
                dsWARN( "circular reference on weak ref" );
                return &PL_sv_undef;
            }

            (void) hv_store( parents, addr, len, NULL, 0 );
            (void) hv_store( seen, addr, len, NULL, 0 );
#ifdef SvWEAKREF
            if ( SvWEAKREF( sv ) ) {
                dsWARN( "found a weak reference 2" );
                _circular_off( SvRV( sv ), newHV(  ), seen, counter );
            }
            else {
#endif
                _circular_off( SvRV( sv ), parents, seen, counter );
#ifdef SvWEAKREF
            }
#endif
            (void) hv_delete( seen, addr, ( U32 ) len, 0 );
            (void) hv_delete( parents, addr, ( U32 ) len, 0 );
        }

    }
    else {

        /* Not a reference */
        switch ( SvTYPE( sv ) ) {

        case SVt_PVAV:{        /* Array */
                dsWARN( "Array" );
                for ( i = 0; i <= av_len( ( AV * ) sv ); i++ ) {
#if dsDEBUG
                    sprintf( errmsg, "next elem %i\n", i );
                    warn( errmsg );
#endif
                    AValue = av_fetch( ( AV * ) sv, i, 0 );
                    if ( AValue ) {
                        _circular_off( *AValue, parents, seen, counter );
                        if ( SvTYPE( sv ) != SVt_PVAV ) {
                            /* In some circumstances, weakening a reference screw things up */
                            croak
                                ( "Array that we were weakening suddenly turned into a scalar of type type %d",
                                  SvTYPE( sv ) );
                        }
                    }
                }
                break;
            }
        case SVt_PVHV:{        /* Hash */
                dsWARN( "Hash" );
                myHash = ( HV * ) sv;
                hv_iterinit( myHash );
                while (( HEntry = hv_iternext( myHash ) )) {
#if dsDEBUG
                    STRLEN len2;
                    char *HKey = HePV( HEntry, len2 );
                    sprintf( errmsg, "NEXT KEY is %s\n", HKey );
                    warn( errmsg );
#endif
                    _circular_off( HeVAL( HEntry ), parents, seen,
                                   counter );
                    if ( SvTYPE( sv ) != SVt_PVHV ) {
                        /* In some circumstances, weakening a reference screw things up */
                        croak
                            ( "Hash that we were weakening suddenly turned into a scalar of type type %d",
                              SvTYPE( sv ) );
                    }
                }
                break;
            }
        default: ;
        }
    }
    return counter;
}

#if dsDEBUG
/*

Dump any data structure

*/

SV *
_dump_any( SV * re, HV * seen, int depth ) {

  testvar:

    if ( SvROK( re ) ) {
        if ( has_seen( re, seen ) )
            return re;
        printf( "a reference " );

        if ( sv_isobject( re ) )
            printf( " blessed " );

        printf( "to " );
        re = SvRV( re );
        goto testvar;

    }
    else {

        switch ( SvTYPE( re ) ) {
        case SVt_NULL:
            printf( "an undef value\n" );
            break;
        case SVt_IV:
            printf( "an integer (IV): %d\n", SvIV( re ) );
            break;
        case SVt_NV:
            printf( "a double (NV): %f\n", SvNV( re ) );
            break;
        case SVt_RV:
            printf( "a RV\n" );
            break;
        case SVt_PV:
            printf( "a string (PV): %s\n", SvPV_nolen( re ) );
            printf( "UTF8 %s\n", SvUTF8( re ) ? "on" : "off" );
            break;
        case SVt_PVIV:
            printf( "an integer (PVIV): %d\n", SvIV( re ) );
            break;
        case SVt_PVNV:
            printf( "a string (PVNV): %s\n", SvPV_nolen( re ) );
            printf( "UTF8 %s\n", SvUTF8( re ) ? "on" : "off" );
            break;
        case SVt_PVMG:
            printf( "a PVMG\n" );
            break;
        case SVt_PVLV:
            printf( "a PVLV\n" );
            break;
        case SVt_PVAV:
            {
                I32 i;

                printf( "an array of %u elems (PVAV)\n",
                        av_len( ( AV * ) re ) + 1 );
                for ( i = 0; i <= av_len( ( AV * ) re ); i++ ) {
                    SV **AValue = av_fetch( ( AV * ) re, i, 0 );
                    if ( AValue ) {
                        printf( "NEXT ELEM is " );
                        _dump_any( *AValue, seen, depth );
                    }
                    else {
                        printf( "NEXT ELEM was undef" );
                    }
                }
                break;
            }

        case SVt_PVHV:
            {
                HV *myHash = ( HV * ) re;
                HE *HEntry;
                int count = 0;

                printf( "a hash (PVHV)\n" );
                hv_iterinit( myHash );
                while ( HEntry = hv_iternext( myHash ) ) {
                    STRLEN len;
                    char *HKey = HePV( HEntry, len );
                    int i;

                    count++;
                    for ( i = 0; i < depth; i++ )
                        printf( "\t" );
                    printf( "NEXT KEY is %s, value is ", HKey );
                    _dump_any( HeVAL( HEntry ), seen, depth + 1 );
                }
                if ( !count )
                    printf( "Empty\n" );
                break;
            }

        case SVt_PVCV:
            printf( "a code (PVCV)\n" );
            return;
        case SVt_PVGV:
            printf( "a glob (PVGV)\n" );
            break;
        case SVt_PVBM:
            printf( "a PVBM\n" );
            break;
        case SVt_PVFM:
            printf( "a PVFM\n" );
            break;
        case SVt_PVIO:
            printf( "a PVIO\n" );
            break;
        default:
            if ( SvOK( re ) ) {
                printf( "Don't know what it is\n" );
                return;
            }
            else {
                croak( "Not a Sv" );
                return;
            }
        }
    }
    return re;
}
#endif

/*
 has_seen
 Returns true if ref already seen
*/
int
has_seen( SV * sv, HV * seen ) {
    char addr[PTRLEN];
    sprintf( addr, "%p", SvRV( sv ) );
    if ( hv_exists( seen, addr, ( U32 ) strlen( addr ) ) ) {
        dsWARN( "already seen" );
        return TRUE;
    }
    else {
        (void) hv_store( seen, addr, ( U32 ) strlen( addr ), NULL, 0 );
        return FALSE;
    }
}

/* *INDENT-OFF* */

MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

bool
utf8_off_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    _utf8_set(sv, (HV*) sv_2mortal((SV*) newHV()), 0);


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

bool
utf8_on_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _utf8_set(sv, (HV*) sv_2mortal((SV*) newHV()), 1);
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

bool
_utf8_off_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    _utf8_flag_set(sv, (HV*) sv_2mortal((SV*) newHV()), 0);


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

bool
_utf8_on_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _utf8_flag_set(sv, (HV*) sv_2mortal((SV*) newHV()), 1);
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

bool
has_utf8_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _has_utf8(sv, (HV*) sv_2mortal((SV*) newHV()));
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

SV*
unbless_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    _unbless(sv, (HV*) sv_2mortal((SV*) newHV()));


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

SV*
has_circular_ref_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _has_circular_ref(sv, (HV*) sv_2mortal((SV*) newHV()), (HV*) sv_2mortal((SV*) newHV()));
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

SV*
circular_off_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
#ifdef SvWEAKREF
#else
    croak("This version of perl doesn't support weak references");
#endif
    RETVAL = _circular_off(sv, (HV*) sv_2mortal((SV*) newHV()), (HV*) sv_2mortal((SV*) newHV()), newSViv(0));
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

AV*
get_blessed_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _get_blessed(sv, (HV*) sv_2mortal((SV*) newHV()), (AV*) sv_2mortal((SV*) newAV()));
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

AV*
get_refs_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _get_refs(sv, (HV*) sv_2mortal((SV*) newHV()), (AV*) sv_2mortal((SV*) newAV()));
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

AV*
signature_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _signature(sv, (HV*) sv_2mortal((SV*) newHV()), (AV*) sv_2mortal((SV*) newAV()));
OUTPUT:
    RETVAL
