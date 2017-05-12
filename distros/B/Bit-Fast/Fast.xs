#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = Bit::Fast		PACKAGE = Bit::Fast		

int
popcount (v)
        unsigned int v
    CODE:
#ifdef __GNUC__
        RETVAL = __builtin_popcount(v);
#else
        v = (v & 0x55555555U) + ((v & 0xAAAAAAAAU) >> 1);
        v = (v & 0x33333333U) + ((v & 0xCCCCCCCCU) >> 2);
        v = (v & 0x0F0F0F0FU) + ((v & 0xF0F0F0F0U) >> 4);
        v = (v & 0x00FF00FFU) + ((v & 0xFF00FF00U) >> 8);
        v = (v & 0x0000FFFFU) + ((v & 0xFFFF0000U) >> 16);
        RETVAL = v;
#endif
    OUTPUT:
        RETVAL

#if LONGSIZE == 8

int
popcountl (v)
        unsigned long v
    CODE:
#ifdef __GNUC__
        RETVAL = __builtin_popcountl(v);
#else
        v = (v & 0x5555555555555555UL) + ((v & 0xAAAAAAAAAAAAAAAAUL) >> 1);
        v = (v & 0x3333333333333333UL) + ((v & 0xCCCCCCCCCCCCCCCCUL) >> 2);
        v = (v & 0x0F0F0F0F0F0F0F0FUL) + ((v & 0xF0F0F0F0F0F0F0F0UL) >> 4);
        v = (v & 0x00FF00FF00FF00FFUL) + ((v & 0xFF00FF00FF00FF00UL) >> 8);
        v = (v & 0x0000FFFF0000FFFFUL) + ((v & 0xFFFF0000FFFF0000UL) >> 16);
        v = (v & 0x00000000FFFFFFFFUL) + ((v & 0xFFFFFFFF00000000UL) >> 32);
        RETVAL = v;
#endif
    OUTPUT:
        RETVAL

#endif
