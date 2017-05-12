/*******************************************************************************
*
* HEADER: config.h
*
********************************************************************************
*
* DESCRIPTION: Configuration for ucpp
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#ifndef _UCPP_CONFIG_H
#define _UCPP_CONFIG_H

#include "ctlib/arch.h"

/*-------------------------*/
/* configure ucpp features */
/*-------------------------*/

#define UCPP_REENTRANT
#define UCPP_CLONE
#define NO_UCPP_COPY_LINE

/*------------------------*/
/* configure ucpp pragmas */
/*------------------------*/

#define PRAGMA_TOKENIZE
#define PRAGMA_TOKEN_END ((unsigned char)'\n')

/*-------------*/
/* no defaults */
/*-------------*/

#define STD_INCLUDE_PATH 0
#define STD_ASSERT       0
#define STD_MACROS       0

/*-------------------------*/
/* 64-bit integer handling */
/*-------------------------*/

#if ARCH_NATIVE_64_BIT_INTEGER

#define NATIVE_UINTMAX u_64
#define NATIVE_INTMAX  i_64

#define NATIVE_SIGNED           i_64
#define NATIVE_UNSIGNED         u_64
#define NATIVE_UNSIGNED_BITS    64
#define NATIVE_UNSIGNED_ONE     1ULL
#define NATIVE_SIGNED_MIN       (-9223372036854775807LL - 1)
#define NATIVE_SIGNED_MAX       9223372036854775807LL

#else

#define SIMUL_UINTMAX

#undef NATIVE_SIGNED
#define SIMUL_ARITH_SUBTYPE     u_32
#define SIMUL_SUBTYPE_BITS      32
#define SIMUL_NUMBITS           64

#endif

/*----------------------------------*/
/* configure preprocessor and lexer */
/*----------------------------------*/

#define DEFAULT_CPP_FLAGS	(DISCARD_COMMENTS | WARN_STANDARD \
				| WARN_PRAGMA | FAIL_SHARP | MACRO_VAARG \
				| CPLUSPLUS_COMMENTS | LINE_NUM | TEXT_OUTPUT \
				| KEEP_OUTPUT | HANDLE_TRIGRAPHS \
				| HANDLE_ASSERTIONS)

#define DEFAULT_LEXER_FLAGS	(DISCARD_COMMENTS | FAIL_SHARP | LEXER \
				| HANDLE_TRIGRAPHS | HANDLE_ASSERTIONS)

/*-------------------*/
/* memory management */
/*-------------------*/

#include <stdlib.h>

/*
 * Under some circumstances, setjmp() on Win64 does deadlock when the
 * memory containing the jmpbuf was allocated through the Perl API.
 *
 * Apparently, using standard malloc/free fixes the deadlock, yet I
 * don't have any explanation for what's really going on.
 *
 * I'll appreciate any enlightenment. :-)
 */

#ifndef _WIN64 

extern void *CBC_malloc(size_t size);
extern void *CBC_realloc(void *ptr, size_t size);
extern void  CBC_free(void *ptr);

#define UCPP_MALLOC   CBC_malloc
#define UCPP_REALLOC  CBC_realloc
#define UCPP_FREE     CBC_free

#endif

/*-------------*/
/* other stuff */
/*-------------*/

#define ARITHMETIC_CHECKS

#define LOW_MEM

#define NO_UCPP_ERROR_FUNCTIONS

#define MAX_CHAR_VAL 256

#define UCPP_PUBLIC_PREFIX	ucpp_public_
#define UCPP_PRIVATE_PREFIX	ucpp_private_

#endif /* _UCPP_CONFIG_H */
