#ifndef DBXS_WTYPE_H
#define DBXS_WTYPE_H

/*
 * The data type to use.
 *
 * This should be the largest native integer type available, but also needs
 * to be portable and compile on ancient and wacky compilers.
 *
 * I used to just use 'unsigned long' and let things fall where they will.
 *
 * What I've decided to do in this version is to leverage as much of Perl's
 * code as possible.  This is in perl.h and config.h (included by perl.h).
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef U32_CONST
/* From perl.h, wrapped in PERL_CORE */
# if INTSIZE >= 4
#  define U32_CONST(x) ((U32TYPE)x##U)
# else
#  define U32_CONST(x) ((U32TYPE)x##UL)
# endif
#endif

#ifndef U64_CONST
# ifdef HAS_QUAD
#  if INTSIZE >= 8
#   define U64_CONST(x) ((U64TYPE)x##U)
#  elif LONGSIZE >= 8
#   define U64_CONST(x) ((U64TYPE)x##UL)
#  elif QUADKIND == QUAD_IS_LONG_LONG
#   define U64_CONST(x) ((U64TYPE)x##ULL)
#  else /* best guess we can make */
#   define U64_CONST(x) ((U64TYPE)x##UL)
#  endif
# endif
#endif


#ifdef HAS_QUAD
  typedef U64TYPE WTYPE;
  #define W_CONST(c)  U64_CONST(c)
  #define WTYPE_IS_64BIT   1
  #define BITS_PER_WORD    64
#elif LONGSIZE >= 8
  /* Should we be doing this? */
  typedef unsigned long WTYPE
  #define W_CONST(c)  ((U64TYPE)x##UL)
  #define WTYPE_IS_64BIT   1
  #define BITS_PER_WORD    64
#else
  typedef U32TYPE WTYPE;
  #define W_CONST(c)  U32_CONST(c)
  #define WTYPE_IS_64BIT   0
  #define BITS_PER_WORD    32
#endif

#define W_ZERO      W_CONST(0)
#define W_ONE       W_CONST(1)
#define W_FFFF      W_CONST(~0)

#define MAXBIT        (BITS_PER_WORD-1)
#define NWORDS(bits)  ( ((bits)+BITS_PER_WORD-1) / BITS_PER_WORD )
#define NBYTES(bits)  ( ((bits)+8-1) / 8 )

#endif
