/*******************************************************************************
*
* HEADER: ccattr
*
********************************************************************************
*
* DESCRIPTION: Define special features of C compilers.
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of either the Artistic License or the
* GNU General Public License as published by the Free Software
* Foundation; either version 2 of the License, or (at your option)
* any later version.
*
* THIS PROGRAM IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
* IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
* WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
*
*******************************************************************************/

#ifndef _UTIL_CCATTR_H
#define _UTIL_CCATTR_H

/*--------*/
/* inline */
/*--------*/

#if defined(__STDC__) && __STDC__ && defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
/* C99 compiler, inline is a valid keyword */
#elif defined(__GNUC__)
/* GNU compiler, inline is __inline__ */
# ifdef  inline
#  undef inline
# endif
# if __GNUC__ >= 3
#  define inline __inline__ __attribute__((always_inline))
# else
#  define inline __inline__
# endif
#else
/* Other compiler, forget about inline */
# ifdef  inline
#  undef inline
# endif
# define inline
#endif

/*---------------*/
/* __attribute__ */
/*---------------*/

#if defined(__GNUC__) && ( __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 95) )
  /* we can use attributes */
#else
# ifdef  __attribute__
#  undef __attribute__
# endif
# define __attribute__( x )
#endif

#endif
