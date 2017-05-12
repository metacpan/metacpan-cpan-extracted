#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = B::CompilerPhase::Hook  PACKAGE = B::CompilerPhase::Hook

PROTOTYPES: ENABLE

# UNITCHECK

void
prepend_UNITCHECK(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_unitcheckav ) {
            PL_unitcheckav = newAV();
        }
        SvREFCNT_inc(handler);
        av_unshift(PL_unitcheckav, 1);
        av_store(PL_unitcheckav, 0, handler);

void
append_UNITCHECK(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_unitcheckav ) {
            PL_unitcheckav = newAV();
        }
        SvREFCNT_inc(handler);
        av_push(PL_unitcheckav, handler);

# CHECK

void
prepend_CHECK(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_checkav ) {
            PL_checkav = newAV();
        }
        SvREFCNT_inc(handler);
        av_unshift(PL_checkav, 1);
        av_store(PL_checkav, 0, handler);

void
append_CHECK(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_checkav ) {
            PL_checkav = newAV();
        }
        SvREFCNT_inc(handler);
        av_push(PL_checkav, handler);

# INIT

void
prepend_INIT(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_initav ) {
            PL_initav = newAV();
        }
        SvREFCNT_inc(handler);
        av_unshift(PL_initav, 1);
        av_store(PL_initav, 0, handler);

void
append_INIT(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_initav ) {
            PL_initav = newAV();
        }
        SvREFCNT_inc(handler);
        av_push(PL_initav, handler);


# BEGIN

void
prepend_BEGIN(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_beginav ) {
            PL_beginav = newAV();
        }
        SvREFCNT_inc(handler);
        av_unshift(PL_beginav, 1);
        av_store(PL_beginav, 0, handler);

void
append_BEGIN(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_beginav ) {
            PL_beginav = newAV();
        }
        SvREFCNT_inc(handler);
        av_push(PL_beginav, handler);

# END

void
prepend_END(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_endav ) {
            PL_endav = newAV();
        }
        SvREFCNT_inc(handler);
        av_unshift(PL_endav, 1);
        av_store(PL_endav, 0, handler);

void
append_END(handler)
        SV* handler
    PROTOTYPE: &
    CODE:
        if ( !PL_endav ) {
            PL_endav = newAV();
        }
        SvREFCNT_inc(handler);
        av_push(PL_endav, handler);

MODULE = B::CompilerPhase::Hook  PACKAGE = B::CompilerPhase::Hook::Debug

AV*
get_END_array()
    CODE:
        RETVAL = PL_endav;
    OUTPUT:
        RETVAL

AV*
get_BEGIN_array()
    CODE:
        RETVAL = PL_beginav;
    OUTPUT:
        RETVAL

AV*
get_CHECK_array()
    CODE:
        RETVAL = PL_checkav;
    OUTPUT:
        RETVAL

AV*
get_INIT_array()
    CODE:
        RETVAL = PL_initav;
    OUTPUT:
        RETVAL

AV*
get_UNITCHECK_array()
    CODE:
        RETVAL = PL_unitcheckav;
    OUTPUT:
        RETVAL


