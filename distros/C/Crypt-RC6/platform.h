#ifndef PLATFORM_H
#define PLATFORM_H

/*
    If we can't use the compiler's intrinsic rotation functions,
    we'll use these macros.
*/

#define	ROL(x, n) (((x) << ((n) & 0x1F)) | ((x) >> (32 - ((n) & 0x1F))))
#define	ROR(x, n) (((x) >> ((n) & 0x1F)) | ((x) << (32 - ((n) & 0x1F))))

/*
    If we're using the Borland compiler, set the ROL and ROR macros
    to call Borland's intrinsic rotation functions.
*/

#if (0) && defined(__BORLANDC__) && (__BORLANDC__ >= 0x462)
#include <stdlib.h>
#pragma inline __lrotl__
#pragma inline __lrotr__
#undef ROL
#undef ROR
#define	ROL(x, n) __lrotl__(x, n)
#define	ROR(x, n) __lrotr__(x, n)
#endif

/*
    If we're using the Microsoft compiler, set the ROL and ROR macros
    to call Microsoft's intrinsic rotation functions.
*/

#ifdef _MSC_VER
#include <stdlib.h>
#undef ROL
#undef ROR
#pragma intrinsic(_lrotl, _lrotr)
#define	ROL(x, n) _lrotl(x, n)			
#define	ROR(x, n) _lrotr(x, n)
#endif

#endif

