/*******************************************************************************
*
* HEADER: memalloc
*
********************************************************************************
*
* DESCRIPTION: Memory allocation and tracing routines
*
********************************************************************************
*
* Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/**
 *  \file memalloc.h
 *  \brief Memory allocation and tracing routines
 *
 *  The functions in this file provide an interface to
 *  the standard malloc / free functions, but in addition
 *  you can selectively enable tracing of your memory
 *  allocation. This may be useful to detect memory leaks
 *  or usage of already freed memory blocks.
 *
 *  A Perl script is supplied to analyze the output of
 *  the memory tracing routines.
 *
 *  To enable the tracing capability, the library must be
 *  compiled with the #DEBUG_MEMALLOC preprocessor flag. Then,
 *  you can selectively enable the tracing for each file or
 *  project by using the SetDebugMemAlloc() routine.
 *
 *  The following code shows an example:
 *
 *  \include Alloc.c
 *
 *  Then, a file like this will be written to stdout:
 *
 *  \verbinclude mem_debug.dat
 *
 *  This output is easy to understand. It tells you that
 *
 *  -# in file \c Alloc.c, line 9, there were 16 bytes allocated at address 0x400031C0,
 *  -# in file \c Alloc.c, line 10, address 0x400031C0 was verified,
 *  -# in file \c Alloc.c, line 11, the memory block at address 0x400031C0 was freed,
 *  -# in file \c Alloc.c, line 12, address 0x400031C0 was verified again.
 *
 *  These files usually become very large if you work a lot with
 *  dynamic memory allocation. So it would be rather hard to step
 *  through that file on your own. For that reason, there's a Perl
 *  script called \c check_alloc.pl that will take \c mem_debug.dat
 *  as input and print all errors discovered and summary statistics:
 *
 *  \verbinclude mem_debug.out
 *
 *  As you can see, the last call to AssertValidPtr() caused an error
 *  because the block that was checked has already been freed. The
 *  other output is only useful if you have lots of dynamic memory
 *  allocation, for example:
 *
 *  \verbinclude memdb_large.out
 *
 *  This will tell you that a total of 32404 memory blocks have been
 *  successfully allocated and freed, a maximum of 13305 memory blocks
 *  were in use simultanously, the peak memory usage was 183675 bytes,
 *  the smallest and largest block that were allocated were 2 and 29
 *  bytes in size, respectively, and there were no memory leaks detected.
 *
 */
#ifndef _UTIL_MEMALLOC_H
#define _UTIL_MEMALLOC_H

#include <stdio.h>

#ifdef UTIL_HAVE_CONFIG_H
# include "config.h"
#endif

#if !(defined(UTIL_MALLOC) && defined(UTIL_CALLOC) && defined(UTIL_REALLOC) && defined(UTIL_FREE))
# include <stdlib.h>
# define UTIL_MALLOC(size)          malloc(size)
# define UTIL_CALLOC(count, size)   calloc(count, size)
# define UTIL_REALLOC(ptr, size)    realloc(ptr, size)
# define UTIL_FREE(ptr)             free(ptr)
#endif

#define DB_MEMALLOC_TRACE    0x00000001
#define DB_MEMALLOC_ASSERT   0x00000002

#ifdef DEBUG_MEMALLOC
void *_memAlloc( size_t size, const char *file, int line );
void *_memCAlloc( size_t nobj, size_t size, const char *file, int line );
void *_memReAlloc( void *p, size_t size, const char *file, int line );
void  _memFree( void *p, const char *file, int line );
void  _assertValidPtr( const void *p, const char *file, int line );
void  _assertValidBlock( const void *p, size_t size, const char *file, int line );
int    SetDebugMemAlloc( void (*dbfunc)(const char *, ...), unsigned long dbflags );
#else
void *_memAlloc( size_t size );
void *_memCAlloc( size_t nobj, size_t size );
void *_memReAlloc( void *p, size_t size );
void  _memFree( void *p );
#endif

/***************************************************************/
/*                       DOCUMENTATION                         */
/***************************************************************/

#ifdef DOXYGEN

/**
 *  Make memory allocation routines abort when out of memory
 *
 *  Set this preprocessor flag if you want the Alloc(), CAlloc()
 *  and ReAlloc() functions as well as the fast macros AllocF(),
 *  CAllocF() and ReAllocF() to abort if the system runs out of
 *  memory.
 */

#define ABORT_IF_NO_MEM

/**
 *  Compile with debugging support
 */

#define DEBUG_MEMALLOC

/**
 *  Compile with tracing / leak detection support
 *
 *  This may slow down memory allocation if lots of blocks
 *  are simultaneously allocted. It will also increase the
 *  memory requirements of your application.
 *
 *  On the plus side, you get run-time memory allocation tracing,
 *  assertion checking, leak detection and memory statistics.
 *  You can control the amount of statistics by setting the
 *  MEMALLOC_STAT_LEVEL environment variable to a value between
 *  0 and 3, with increasing amount of output.
 *
 *  If an assertion fails, the program will usually abort.
 *  You can choose not to abort the program by setting
 *  MEMALLOC_SOFT_ASSERT to a non-zero value in your
 *  environment.
 *
 *  If you want the memory allocator to keep information about
 *  freed blocks, set MEMALLOC_CHECK_FREED to a non-zero value.
 *  This can give more detailed trace output at the cost of
 *  slower execution.
 *
 *  If you like to see hex dumps of non-freed memory blocks,
 *  you can set MEMALLOC_SHOW_DUMPS to a non-zero value.
 *
 *  Only works if DEBUG_MEMALLOC is also defined.
 */

#define TRACE_MEMALLOC

/**
 *  Build with memory allocator that automatically purges
 *  allocated / freed memory blocks.
 *
 *  Only works if DEBUG_MEMALLOC is also defined.
 */

#define AUTOPURGE_MEMALLOC

/**
 *  Build without support for the Alloc(), CAlloc() and
 *  ReAlloc() functions. Memory management is completely
 *  carried out through the use of the fast allocation
 *  macros AllocF(), CAllocF() and ReAllocF().
 */

#define NO_SLOW_MEMALLOC_CALLS

/**
 *  Allocate a memory block
 *
 *  Allocates a memory block of \a size bytes. If the files
 *  were compiled with the #ABORT_IF_NO_MEM preprocessor flag,
 *  the function aborts if no memory can be allocated.
 *
 *  \param size           Size of the memory block in bytes.
 *
 *  \return A pointer to the allocated memory block, or NULL
 *          if memory couldn't be allocated.
 */

void *Alloc( size_t size );

/**
 *  Allocate a memory block and initialize to zero
 *
 *  Allocates a memory block to hold \a nobj times
 *  \a size bytes. If the files were compiled with the
 *  #ABORT_IF_NO_MEM preprocessor flag, the function
 *  aborts if no memory can be allocated.
 *
 *  \param nobj           Number of objects.
 *
 *  \param size           Size of one object in bytes.
 *
 *  \return A pointer to the allocated memory block, or NULL
 *          if memory couldn't be allocated.
 */

void *CAlloc( size_t nobj, size_t size );

/**
 *  Reallocate a memory block
 *
 *  Reallocates a memory block of \a size bytes. If the files
 *  were compiled with the #ABORT_IF_NO_MEM preprocessor flag,
 *  the function aborts if no memory can be allocated.
 *
 *  \param ptr            Pointer to an allocated memory block.
 *
 *  \param size           Size of new memory block in bytes.
 *
 *  \return A pointer to the reallocated memory block, or NULL
 *          if memory couldn't be reallocated.
 */

void *ReAlloc( void *ptr, size_t size );

/**
 *  Fast Alloc Macro
 *
 *  Allocates a memory block of \a size bytes. If the files
 *  were compiled with the #ABORT_IF_NO_MEM preprocessor flag,
 *  the function aborts if no memory can be allocated.
 *
 *  \param cast           Pointer cast.
 *
 *  \param ptr            Pointer to memory block.
 *
 *  \param size           Size of the memory block in bytes.
 */

#define AllocF( cast, ptr, size )

/**
 *  Fast CAlloc Macro
 *
 *  Allocates a memory block to hold \a nobj times
 *  \a size bytes. If the files were compiled with the
 *  #ABORT_IF_NO_MEM preprocessor flag, the function
 *  aborts if no memory can be allocated.
 *
 *  \param cast           Pointer cast.
 *
 *  \param ptr            Pointer to memory block.
 *
 *  \param nobj           Number of objects.
 *
 *  \param size           Size of one object in bytes.
 */

#define CAllocF( cast, ptr, nobj, size )

/**
 *  Fast ReAlloc Macro
 *
 *  Reallocates a memory block of \a size bytes. If the files
 *  were compiled with the #ABORT_IF_NO_MEM preprocessor flag,
 *  the function aborts if no memory can be allocated.
 *
 *  \param cast           Pointer cast.
 *
 *  \param ptr            Pointer to memory block.
 *
 *  \param size           Size of new memory block in bytes.
 */

#define ReAllocF( cast, ptr, size )

/**
 *  Free a memory block
 *
 *  Frees a memory block that has been previously allocated
 *  using the Alloc() function.
 *
 *  \param ptr            Pointer to a previously allocated
 *                        memory block.
 */

void Free( void *ptr );

/**
 *  Trace pointer access.
 *
 *  This may prove useful for checking if \a ptr points to
 *  an existing, previously allocated, not yet freed memory
 *  block.
 *
 *  \param ptr            Pointer to be traced.
 */

void AssertValidPtr( void *ptr );

/**
 *  Trace memory block access.
 *
 *  Allows checking if a certain memory block lies within
 *  a previously allocated memory block.
 *
 *  \param ptr            Pointer to memory block.
 *
 *  \param size           Size of memory block.
 */

void AssertValidBlock( void *ptr, size_t size );

/**
 *  Configure debugging support.
 *
 *  \param dbfunc         Pointer to a printf() like function
 *                        for writing the debug output.
 *
 *  \param dbflags        Binary ORed debugging flags. Currently,
 *                        you can request memory allocation tracing
 *                        with \c DB_MEMALLOC_TRACE and pointer
 *                        assertions with \c DB_MEMALLOC_ASSERT.
 */

int SetDebugMemAlloc( void (*dbfunc)(char *, ...), unsigned long dbflags );

#else /* !DOXYGEN */

/***************************************************************/
/*                    END OF DOCUMENTATION                     */
/***************************************************************/

#ifdef ABORT_IF_NO_MEM
# define abortMEMALLOC( call, size, expr )                                     \
        do {                                                                   \
          size_t tmp_size__ = (size);                                          \
          if( (expr) == NULL && tmp_size__ > 0 ) {                             \
            fprintf(stderr, "%s(%u): out of memory!\n",                        \
                    call, (unsigned) tmp_size__);                              \
            abort();                                                           \
          }                                                                    \
        } while(0)
#else
# define abortMEMALLOC( call, size, expr )  do { (void) (expr); } while(0)
#endif

#ifdef DEBUG_MEMALLOC

# ifndef NO_SLOW_MEMALLOC_CALLS
#  define ReAlloc( ptr, size )           _memReAlloc( ptr, size, __FILE__, __LINE__ )
#  define CAlloc( nobj, size )           _memCAlloc( nobj, size, __FILE__, __LINE__ )
#  define Alloc( size )                  _memAlloc( size, __FILE__, __LINE__ )
# endif

# define Free( ptr )                     _memFree( ptr, __FILE__, __LINE__ )
# define AssertValidPtr( ptr )           _assertValidPtr( ptr, __FILE__, __LINE__ )
# define AssertValidBlock( ptr, size )   _assertValidBlock( ptr, size, __FILE__, __LINE__ )

# define ReAllocF( cast, ptr, size ) \
          do { ptr = (cast) _memReAlloc( ptr, size, __FILE__, __LINE__ ); } while(0)
# define CAllocF( cast, ptr, nobj, size ) \
          do { ptr = (cast) _memCAlloc( nobj, size, __FILE__, __LINE__ ); } while(0)
# define AllocF( cast, ptr, size ) \
          do { ptr = (cast) _memAlloc( size, __FILE__, __LINE__ ); } while(0)

#else /* !DEBUG_MEMALLOC */

# ifndef NO_SLOW_MEMALLOC_CALLS
#  ifdef ABORT_IF_NO_MEM
#   define ReAlloc( ptr, size )          _memReAlloc( ptr, size )
#   define CAlloc( nobj, size )          _memCAlloc( nobj, size )
#   define Alloc( size )                 _memAlloc( size )
#  else
#   define ReAlloc( ptr, size )          UTIL_REALLOC( ptr, size )
#   define CAlloc( nobj, size )          UTIL_CALLOC( nobj, size )
#   define Alloc( size )                 UTIL_MALLOC( size )
#  endif
# endif

# define Free( ptr )                     do { if( ptr ) UTIL_FREE( ptr ); } while(0)
# define AssertValidPtr( ptr )           (void) 0
# define AssertValidBlock( ptr, size )   (void) 0
# define SetDebugMemAlloc( func, flags ) 0

# define ReAllocF( cast, ptr, size ) \
           abortMEMALLOC( "ReAllocF", size, ptr = (cast) UTIL_REALLOC( ptr, size ) )
# define CAllocF( cast, ptr, nobj, size ) \
           abortMEMALLOC( "CAllocF", nobj*size, ptr = (cast) UTIL_CALLOC( nobj, size ) )
# define AllocF( cast, ptr, size ) \
           abortMEMALLOC( "AllocF", size, ptr = (cast) UTIL_MALLOC( size ) )

#endif /* DEBUG_MEMALLOC */

#endif /* DOXYGEN */

#endif
