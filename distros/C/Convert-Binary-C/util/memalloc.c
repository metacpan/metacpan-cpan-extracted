/*******************************************************************************
*
* MODULE: memalloc
*
********************************************************************************
*
* DESCRIPTION: Memory allocation and tracing routines
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

#include "ccattr.h"

#if defined(DEBUG_MEMALLOC)

#include "memalloc.h"

#ifdef DEBUG_MEMALLOC

# ifdef AUTOPURGE_MEMALLOC
#  include <string.h>
# endif

# ifdef UTIL_FORMAT_CHECK

#  define DEBUG( flag, out ) debug_check out

static void debug_check( const char *str, ... )
            __attribute__(( __format__( __printf__, 1, 2 ), __noreturn__ ));

# else

#  define DEBUG( flag, out )                                         \
          do {                                                       \
            if( gs_dbfunc && ((DB_MEMALLOC_ ## flag) & gs_dbflags) ) \
              gs_dbfunc out ;                                        \
          } while(0)

# endif

static void (*gs_dbfunc)(const char *, ...) = NULL;
static unsigned long gs_dbflags             = 0;

#else /* !DEBUG_MEMALLOC */

# define DEBUG( flag, out )

#endif

#ifndef MEMALLOC_MAX_DIAG_DIST
# define MEMALLOC_MAX_DIAG_DIST     256
#endif

#ifndef MEMALLOC_BUCKET_SIZE_INCR
# define MEMALLOC_BUCKET_SIZE_INCR    4
#endif

#ifndef MEMALLOC_HASH_OFFSET
# define MEMALLOC_HASH_OFFSET         4
#endif

#ifndef MEMALLOC_HASH_BITS
# define MEMALLOC_HASH_BITS           8
#endif

#ifndef HEX_BYTES_PER_LINE
# define HEX_BYTES_PER_LINE          16
#endif

#if defined(DEBUG_MEMALLOC) && defined(TRACE_MEMALLOC)

#ifndef MEM_TRACE_REALLOC
# define MEM_TRACE_REALLOC   realloc
#endif

#ifndef MEM_TRACE_FREE
# define MEM_TRACE_FREE      free
#endif

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <assert.h>
#include <limits.h>

#ifndef ULONG_MAX
# define ULONG_MAX ((1<<(8*sizeof(unsigned long)))-1)
#endif

#define HASH_BUCKET( ptr )  ((((unsigned long)(ptr)) >> MEMALLOC_HASH_OFFSET)  \
                             & ((1 << MEMALLOC_HASH_BITS) - 1))

#define TRACE_MSG( msg )    (void) (gs_dbfunc ? gs_dbfunc : trace_msg) msg

#define free_slot( p )                                                         \
        do {                                                                   \
          gs_memstat.free++;                                                   \
          gs_memstat.total_blocks--;                                           \
          gs_memstat.total_bytes -= p->size;                                   \
          if( MEMALLOC_FLAG(env.check_freed) )                                 \
            (p)->freed = 1;                                                    \
          else {                                                               \
            (p)->ptr   = NULL;                                                 \
            (p)->size  = 0;                                                    \
          }                                                                    \
        } while(0)

typedef struct {
  const void    *ptr;
  const char    *file;
  int            line;
  unsigned       freed:1;
  size_t         size;
  unsigned long  serial;
} MemTrace;

typedef struct {
  int        size;
  MemTrace  *block;
} MemTraceBucket;

static struct {
  unsigned long alloc;
  unsigned long free;
  unsigned long total_blocks;
  unsigned long total_bytes;
  unsigned long max_total_blocks;
  unsigned long max_total_bytes;
  size_t        min_alloc;
  size_t        max_alloc;
  double        avg_alloc;
} gs_memstat;

static struct {
  int initialized;
  struct {
    int soft_assert;
    int check_freed;
    int show_dumps;
  } env;
} gs_flags;

static int gs_stat_level = -1;
static unsigned long  gs_serial = 0;
static MemTraceBucket gs_trace[1<<MEMALLOC_HASH_BITS];

static void trace_msg( const char *fmt, ... )
{
  va_list l;
  va_start(l, fmt);
  vfprintf(stderr, fmt, l);
  va_end(l);
}

#define MEMALLOC_FLAG( x ) \
        (gs_flags.initialized ? gs_flags.x : (update_flags(), gs_flags.x))

static void update_flags( void )
{
  char *str;
  gs_flags.env.soft_assert = (str=getenv("MEMALLOC_SOFT_ASSERT")) && atoi(str);
  gs_flags.env.check_freed = (str=getenv("MEMALLOC_CHECK_FREED")) && atoi(str);
  gs_flags.env.show_dumps  = (str=getenv("MEMALLOC_SHOW_DUMPS"))  && atoi(str);
}

static void trace_leaks( void )
{
  int b, i, level = gs_stat_level;
  long min_buck, max_buck, empty_buckets = 0;
  unsigned long bytes_used = 0;
  MemTraceBucket *buck;

  assert( gs_memstat.alloc - gs_memstat.free == gs_memstat.total_blocks );

  if( level < 0 && (gs_memstat.total_blocks != 0 || gs_memstat.total_bytes != 0) )
    level = 1;

  if( level >= 1 ) {
    if( gs_serial == ULONG_MAX )
      TRACE_MSG(("*** serial number overflow, results may be inaccurate ***\n"));

    TRACE_MSG(("--------------------------------\n"));

    if( level >= 2 )
      TRACE_MSG((" serials used   : %lu\n", gs_serial));

    TRACE_MSG((" total allocs   : %lu\n", gs_memstat.alloc));
    TRACE_MSG((" total frees    : %lu\n", gs_memstat.free));
    TRACE_MSG((" max mem blocks : %lu\n", gs_memstat.max_total_blocks));
    TRACE_MSG((" max mem usage  : %lu byte%s\n", gs_memstat.max_total_bytes,
                 gs_memstat.max_total_bytes == 1 ? "" : "s"));

    if( gs_memstat.max_total_blocks > 0 ) {
      TRACE_MSG((" smallest block : %d byte%s\n", gs_memstat.min_alloc,
                   gs_memstat.min_alloc == 1 ? "" : "s"));
      TRACE_MSG((" largest block  : %d byte%s\n", gs_memstat.max_alloc,
                   gs_memstat.max_alloc == 1 ? "" : "s"));
      TRACE_MSG((" average block  : %.1f bytes\n",
                   gs_memstat.avg_alloc/(double)gs_memstat.alloc));
    }

    if( gs_memstat.total_blocks > 0 ) {
      TRACE_MSG((" memory leakage : %d byte%s in %d block%s\n",
                   gs_memstat.total_bytes, gs_memstat.total_bytes == 1 ? "" : "s",
                   gs_memstat.total_blocks, gs_memstat.total_blocks == 1 ? "" : "s"
               ));
    }

    TRACE_MSG(("--------------------------------\n"));
  }

  min_buck = max_buck = gs_trace[0].size;

  for( b = 0, buck = &gs_trace[0]; (unsigned)b < sizeof(gs_trace)/sizeof(gs_trace[0]); ++b, ++buck ) {
    if( level >= 3 ) {
      TRACE_MSG(("bucket %d used %d bytes in %d blocks\n",
                 b, buck->size*sizeof(MemTrace), buck->size));
    }

    if( buck->size < min_buck )
      min_buck = buck->size;
    if( buck->size > max_buck )
      max_buck = buck->size;

    if( buck->block != NULL ) {
      assert( buck->size > 0 );
      bytes_used += buck->size*sizeof(MemTrace);

      for( i = 0; i < buck->size; ++i ) {
        MemTrace *p = &buck->block[i];
        if( p->ptr != NULL && !p->freed ) {
          TRACE_MSG(("(%d) leaked %d bytes at %p allocated in %s:%d\n",
                     p->serial, p->size, p->ptr, p->file, p->line));

          gs_memstat.total_blocks--;
          gs_memstat.total_bytes -= p->size;

#ifdef MEMALLOC_FREE_BLOCKS_AT_EXIT
          UTIL_FREE( (void *) p->ptr );
#endif
        }
      }

#ifdef MEMALLOC_FREE_BLOCKS_AT_EXIT
      MEM_TRACE_FREE( buck->block );
#endif
    }
    else {
      assert( buck->size == 0 );
      empty_buckets++;
    }
  }

  if( level >= 2 ) {
    TRACE_MSG(("memalloc tracing used %d bytes in %d buckets (%d empty)\n",
               bytes_used, b, empty_buckets));
    TRACE_MSG(("min/max bucket size was %d/%d blocks\n", min_buck, max_buck));
  }

  assert( gs_memstat.total_blocks == 0 );
  assert( gs_memstat.total_bytes == 0 );
}

static inline MemTrace *get_empty_slot( const void *ptr )
{
  MemTraceBucket *buck;
  MemTrace *p;
  int i, pos = -1;

  assert( ptr != NULL );

  buck = &gs_trace[ HASH_BUCKET(ptr) ];

  for( i = 0; i < buck->size; ++i ) {
    p = &buck->block[i];
    if( p->ptr == ptr ) {
      if( p->freed ) {
        p->ptr   = NULL;
        p->size  = 0;
        p->freed = 0;
        return p;
      }
      return NULL;
    }
    if( pos < 0 && p->ptr == NULL )
      pos = i;
  }

  if( pos < 0 )
    pos = buck->size;

  if( pos >= buck->size ) {
    buck->size  = pos + MEMALLOC_BUCKET_SIZE_INCR;
    buck->block = MEM_TRACE_REALLOC( buck->block, buck->size * sizeof(MemTrace) );
    if( buck->block == NULL ) {
      fprintf(stderr, "panic: out of memory in get_empty_slot()\n");
      abort();
    }
    for( p = &buck->block[i = pos]; i < buck->size; ++i, ++p ) {
      p->ptr   = NULL;
      p->size  = 0;
      p->freed = 0;
    }
  }

  return &buck->block[pos];
}

static inline MemTrace *find_slot( const void *ptr )
{
  MemTraceBucket *buck;
  MemTrace *p;
  int pos;

  buck = &gs_trace[ HASH_BUCKET(ptr) ];

  for( pos = 0; pos < buck->size; ++pos ) {
    p = &buck->block[pos];
    if( p->ptr == ptr )
      return p;
  }

  return NULL;
}

static void hex_dump( const void *ptr, size_t len )
{
  const unsigned char *px = ptr;
  unsigned long pos = 0;

  for( pos = 0; pos < len; pos += HEX_BYTES_PER_LINE ) {
    int i;
    TRACE_MSG(("%08lX ", pos));
    for( i = 0; pos+i < len && i < HEX_BYTES_PER_LINE; i++ )
      TRACE_MSG(("%s%02X", i%4 ? " " : "  ", px[pos+i]));
    for( ; i < HEX_BYTES_PER_LINE; i++ )
      TRACE_MSG(("%s  ", i%4 ? " " : "  "));
    TRACE_MSG((" "));
    for( i = 0; pos+i < len && i < HEX_BYTES_PER_LINE; i++ )
      TRACE_MSG(("%s%c", i%4 ? "" : " ", px[pos+i] < 32 || px[pos+i] > 127 ? '.' : px[pos+i]));
    TRACE_MSG(("\n"));
  }
}

static void diag_ptr( const void *ptr )
{
  const char *px = ptr;
  int b, i, delta = -1;
  MemTraceBucket *buck;
  MemTrace *best = NULL;
  enum Match { None, BeforeF, AfterF, BeforeA, AfterA, InsideF, InsideA, Freed }
             match = None;

  assert( ptr != NULL );

  for( b = 0, buck = &gs_trace[0]; (unsigned)b < sizeof(gs_trace)/sizeof(gs_trace[0]); ++b, ++buck )
    for( i = 0; i < buck->size; ++i ) {
      MemTrace *p = &buck->block[i];

      if( p->ptr != NULL ) {
        const char *ps = p->ptr;
        const char *pe = ps + p->size;
        enum Match m = None;
        int d = 0;

        if( ps == px && p->freed ) {
          m = Freed;
        }
        else if( ps <= px && px < pe ) {
          m = p->freed ? InsideF : InsideA;
        }
        else if( px >= pe ) {
          m = p->freed ? AfterF : AfterA;
          d = (px - pe) + 1;
        }
        else {
          assert( px < ps );
          m = p->freed ? BeforeF : BeforeA;
          d = ps - px;
        }

        assert( m != None );

        if( (m >  match && d < MEMALLOC_MAX_DIAG_DIST) ||
            (m == match && d < delta) ) {
          match = m;
          delta = d;
          best  = p;
        }
      }
    }

  if( match != None ) {
    const char *type, *s1, *s2;

    assert( delta >= 0 && delta < MEMALLOC_MAX_DIAG_DIST );
    assert( best != NULL );

    type = best->freed ? "a freed" : "an allocated";
    s1 = delta == 1 ? "" : "s";
    s2 = best->size == 1 ? "" : "s";

    switch( match ) {
      case BeforeF:
      case BeforeA:
        TRACE_MSG(("  %p is %d byte%s before %s block of %d byte%s at %p (%s:%d)\n",
                   ptr, delta, s1, type, best->size, s2, best->ptr, best->file, best->line));
        break;

      case AfterF:
      case AfterA:
        TRACE_MSG(("  %p is %d byte%s behind %s block of %d byte%s at %p (%s:%d)\n",
                   ptr, delta, s1, type, best->size, s2, best->ptr, best->file, best->line));
        break;

      case InsideF:
      case InsideA:
        assert( delta == 0 );
        TRACE_MSG(("  %p is inside %s block of %d byte%s at %p (%s:%d)\n",
                   ptr, type, best->size, s2, best->ptr, best->file, best->line));
        break;

      case Freed:
        assert( delta == 0 );
        TRACE_MSG(("  %p points to a block of %d byte%s already freed (%s:%d)\n",
                   ptr, best->size, s2, best->file, best->line));
        break;

      default:
        fprintf(stderr, "panic: unknown match type (%d)\n", (int) match);
        abort();
        break;
    }

    if( !best->freed && MEMALLOC_FLAG(env.show_dumps) )
      hex_dump( best->ptr, best->size );
  }
}

static void diag_range( const void *ptr, size_t size )
{
  const char *pS, *pE;
  int b, i, delta = -1, overlap = -1;
  MemTraceBucket *buck;
  MemTrace *best = NULL;
  enum Match { None, BeforeF, AfterF, BeforeA, AfterA, OverlapF, OverlapA, InsideF, Freed }
             match = None;

  assert( ptr != NULL );
  assert( size > 0 );

  pS = ptr;
  pE = pS + size;

  for( b = 0, buck = &gs_trace[0]; (unsigned)b < sizeof(gs_trace)/sizeof(gs_trace[0]); ++b, ++buck )
    for( i = 0; i < buck->size; ++i ) {
      MemTrace *p = &buck->block[i];

      if( p->ptr != NULL ) {
        const char *ps = p->ptr;
        const char *pe = ps + p->size;
        enum Match m = None;
        int d = 0, o = 0;

        /*               pS                   pE
         *                |===================|
         *                :                   :
         *          ps |--:-------------------:-----| pe           -> inside
         *  ps |---------|:pe                 :                    -> after
         *          ps |--:------| pe         :                    -> overlap
         *                : ps |---------| pe :                    -> overlap
         *                :           ps |----:----| pe            -> overlap
         *                :                   : ps |---------| pe  -> before
         *                :                   |
         *                |===================|
         */
        if( ps == pS && pe == pE && p->freed ) {
          m = Freed;
        }
        else if( ps <= pS && pe >= pE && p->freed ) {
          m = InsideF;
        }
        else if( pS <= ps && ps <= pE ) {
          m = p->freed ? OverlapF : OverlapA;
          o = pE - ps;
        }
        else if( pS <= pe && pe <= pE ) {
          m = p->freed ? OverlapF : OverlapA;
          o = pe - pS;
        }
        else if( pS > pe ) {
          m = p->freed ? AfterF : AfterA;
          d = pS - pe;
        }
        else {
          assert( pE < ps );
          m = p->freed ? BeforeF : BeforeA;
          d = ps - pE;
        }

        assert( m != None );

        if( (m >  match && d < MEMALLOC_MAX_DIAG_DIST) ||
            (m == match && (d < delta || o > overlap)) ) {
          match   = m;
          delta   = d;
          overlap = o;
          best    = p;
        }
      }
    }

  if( match != None ) {
    const char *type, *s1, *s2, *s3;

    assert( delta >= 0 && delta < MEMALLOC_MAX_DIAG_DIST );
    assert( best != NULL );

    type = best->freed ? "a freed" : "an allocated";
    s1 = delta == 1 ? "" : "s";
    s2 = best->size == 1 ? "" : "s";
    s3 = overlap == 1 ? "" : "s";

    switch( match ) {
      case BeforeF:
      case BeforeA:
        assert( overlap == 0 );
        TRACE_MSG(("  %p(%d) is %d byte%s before %s block of %d byte%s at %p (%s:%d)\n",
                   ptr, size, delta, s1, type, best->size, s2, best->ptr, best->file, best->line));
        break;

      case AfterF:
      case AfterA:
        assert( overlap == 0 );
        TRACE_MSG(("  %p(%d) is %d byte%s behind %s block of %d byte%s at %p (%s:%d)\n",
                   ptr, size, delta, s1, type, best->size, s2, best->ptr, best->file, best->line));
        break;

      case OverlapF:
      case OverlapA:
        assert( delta == 0 );
        assert( overlap > 0 );
        TRACE_MSG(("  %p(%d) overlaps %d byte%s with %s block of %d byte%s at %p (%s:%d)\n",
                   ptr, size, overlap, s3, type, best->size, s2, best->ptr, best->file, best->line));
        break;

      case InsideF:
        assert( delta == 0 );
        TRACE_MSG(("  %p(%d) is inside %s block of %d byte%s at %p (%s:%d)\n",
                   ptr, size, type, best->size, s2, best->ptr, best->file, best->line));
        break;

      case Freed:
        assert( delta == 0 );
        TRACE_MSG(("  %p(%d) matches a block already freed (%s:%d)\n",
                   ptr, size, best->file, best->line));
        break;

      default:
        fprintf(stderr, "panic: unknown match type (%d)\n", (int) match);
        abort();
        break;
    }

    if( !best->freed && MEMALLOC_FLAG(env.show_dumps) )
      hex_dump( best->ptr, best->size );
  }
}

static inline void init_trace(size_t first_alloc_size)
{
  const char *str;

  assert(gs_serial == 0);

  if( (str = getenv("MEMALLOC_STAT_LEVEL")) != NULL )
    gs_stat_level = atoi(str);

  gs_memstat.min_alloc = gs_memstat.max_alloc = first_alloc_size;
  atexit( trace_leaks );
}

static inline int trace_add( const void *ptr, size_t size, const char *file, int line )
{
  MemTrace *p;

  assert( file != NULL );

  if( ptr == NULL ) {
    if( size == 0 )
      return 1;

    TRACE_MSG(("request for %d bytes failed in %s:%d\n", size, file, line));
    return 0;
  }

  if( (p = get_empty_slot(ptr)) == NULL ) {
    TRACE_MSG(("pointer %p has already been allocated in %s:%d\n", ptr, file, line));
    return 0;
  }

  if( gs_serial == 0 )
    init_trace(size);

  gs_memstat.alloc++;
  gs_memstat.total_blocks++;
  gs_memstat.total_bytes += size;

  if( gs_memstat.total_blocks > gs_memstat.max_total_blocks )
    gs_memstat.max_total_blocks = gs_memstat.total_blocks;

  if( gs_memstat.total_bytes > gs_memstat.max_total_bytes )
    gs_memstat.max_total_bytes = gs_memstat.total_bytes;

  if( size < gs_memstat.min_alloc )
    gs_memstat.min_alloc = size;

  if( size > gs_memstat.max_alloc )
    gs_memstat.max_alloc = size;

  gs_memstat.avg_alloc += (double) size;

  p->ptr    = ptr;
  p->file   = file;
  p->line   = line;
  p->size   = size;
  p->serial = gs_serial;

  if( gs_serial < ULONG_MAX )
    gs_serial++;

  return 1;
}

static inline int trace_del( const void *ptr, const char *file, int line )
{
  MemTrace *p;

  assert( file != NULL );

  if( ptr == NULL ) {
    TRACE_MSG(("trying to free NULL pointer in %s:%d\n", ptr, file, line));
    return 0;
  }

  if( (p = find_slot(ptr)) == NULL ) {
    TRACE_MSG(("pointer %p has not yet been allocated in %s:%d\n", ptr, file, line));
    diag_ptr(ptr);
    return 0;
  }

  if( p->freed ) {
    TRACE_MSG(("pointer %p has already been freed in %s:%d\n", ptr, file, line));
    return 0;
  }

  free_slot( p );

  return 1;
}

static inline int trace_upd( const void *old, const void *ptr, size_t size, const char *file, int line )
{
  MemTrace *p;

  assert( file != NULL );

  if( old != ptr && old != NULL ) {
    if( (p = find_slot(old)) == NULL ) {
      TRACE_MSG(("pointer %p has not yet been allocated in %s:%d\n", old, file, line));
      diag_ptr(old);
    }
    else if( p->freed )
      TRACE_MSG(("pointer %p has already been freed in %s:%d\n", ptr, file, line));
    else
      free_slot( p );
  }

  if( ptr == NULL ) {
    if( size == 0 )
      return 1;

    TRACE_MSG(("request for %d bytes failed in %s:%d\n", size, file, line));
    return 0;
  }

  p = NULL;

  if( old == ptr ) {
    if( (p = find_slot(ptr)) == NULL ) {
      TRACE_MSG(("pointer %p has not yet been allocated in %s:%d\n", ptr, file, line));
      diag_ptr(ptr);
    }
    else if( p->freed ) {
      TRACE_MSG(("pointer %p has already been freed in %s:%d\n", ptr, file, line));
      p->size  = 0;
      p->freed = 0;
    }
    else {
      gs_memstat.alloc++;
      gs_memstat.free++;
    }
  }

  if( p == NULL ) {
    if( (p = get_empty_slot(ptr)) == NULL ) {
      TRACE_MSG(("pointer %p has already been allocated in %s:%d\n", ptr, file, line));
      return 0;
    }
    gs_memstat.alloc++;
    gs_memstat.total_blocks++;
    if( gs_memstat.total_blocks > gs_memstat.max_total_blocks )
      gs_memstat.max_total_blocks = gs_memstat.total_blocks;
  }

  if( gs_serial == 0 )
    init_trace(size);

  gs_memstat.total_bytes += size - p->size;

  if( gs_memstat.total_bytes > gs_memstat.max_total_bytes )
    gs_memstat.max_total_bytes = gs_memstat.total_bytes;

  if( size < gs_memstat.min_alloc )
    gs_memstat.min_alloc = size;

  if( size > gs_memstat.max_alloc )
    gs_memstat.max_alloc = size;

  gs_memstat.avg_alloc += (double) size;

  p->ptr    = ptr;
  p->file   = file;
  p->line   = line;
  p->size   = size;
  p->serial = gs_serial;

  if( gs_serial < ULONG_MAX )
    gs_serial++;

  return 1;
}

static inline int trace_check_ptr( const void *ptr, const char *file, int line )
{
  MemTrace *p;

  if( ptr != NULL && (p =find_slot(ptr)) != NULL && !p->freed )
    return 1;

  TRACE_MSG(("Assertion failed: %p is not a valid pointer in %s:%d\n", ptr, file, line));

  if( ptr != NULL )
    diag_ptr(ptr);

  if( MEMALLOC_FLAG(env.soft_assert) == 0 )
    abort();

  return 0;
}

static inline int trace_check_range( const void *ptr, size_t size, const char *file, int line )
{
  int b, i;
  MemTraceBucket *buck;

  if( ptr != NULL && size > 0 ) {
    for( b = 0, buck = &gs_trace[0]; (unsigned)b < sizeof(gs_trace)/sizeof(gs_trace[0]); ++b, ++buck )
      for( i = 0; i < buck->size; ++i ) {
        MemTrace *pmt = &buck->block[i];

        if( pmt->ptr != NULL && !pmt->freed ) {
          const char *bs = pmt->ptr;
          const char *be = bs + pmt->size;
          const char *cs = ptr;
          const char *ce = cs + size;

          int s_in_b = bs <= cs && cs <= be;
          int e_in_b = bs <= ce && ce <= be;

          if( s_in_b && e_in_b )
            return 1;
        }
      }
  }

  TRACE_MSG(("Assertion failed: %p(%d) is not a valid block in %s:%d\n", ptr, size, file, line));

  if( ptr != NULL && size > 0 )
    diag_range(ptr, size);

  if( MEMALLOC_FLAG(env.soft_assert) == 0 )
    abort();

  return 0;
}

#else

#define trace_add( ptr, size, file, line )         1
#define trace_upd( old, ptr, size, file, line )    1
#define trace_del( ptr, file, line )               1
#define trace_check_ptr( ptr, file, line )         1
#define trace_check_range( ptr, size, file, line ) 1

#endif /* defined(DEBUG_MEMALLOC) && defined(TRACE_MEMALLOC) */


#ifdef DEBUG_MEMALLOC
void *_memAlloc( size_t size, const char *file, int line )
#else
void *_memAlloc( size_t size )
#endif
{
  void *p;

#if defined(DEBUG_MEMALLOC) && defined(AUTOPURGE_MEMALLOC)
  p = UTIL_MALLOC( size + sizeof( size_t ) );
#else
  p = UTIL_MALLOC( size );
#endif

  abortMEMALLOC( "_memAlloc", size, p );

#if defined(DEBUG_MEMALLOC) && defined(AUTOPURGE_MEMALLOC)
  if( p != NULL ) {
    *((size_t *)p) = size;
    p = (void *)(((size_t *)p)+1);
  }
#endif

  (void) trace_add( p, size, file, line );
  DEBUG( TRACE, ("%s(%d):A=%d@%08lX\n", file, line, size, (unsigned long)p) );

  return p;
}

#ifdef DEBUG_MEMALLOC
void *_memCAlloc( size_t nobj, size_t size, const char *file, int line )
#else
void *_memCAlloc( size_t nobj, size_t size )
#endif
{
  void *p;

#if defined(DEBUG_MEMALLOC) && defined(AUTOPURGE_MEMALLOC)
  p = UTIL_MALLOC( nobj*size + sizeof( size_t ) );
#else
  p = UTIL_CALLOC( nobj, size );
#endif

  abortMEMALLOC( "_memCAlloc", nobj*size, p );

#if defined(DEBUG_MEMALLOC) && defined(AUTOPURGE_MEMALLOC)
  if( p != NULL ) {
    *((size_t *)p) = size;
    p = (void *)(((size_t *)p)+1);
    memset( p, 0, nobj*size );
  }
#endif

  (void) trace_add( p, nobj*size, file, line );
  DEBUG( TRACE, ("%s(%d):A=%d@%08lX\n", file, line, nobj*size, (unsigned long)p) );

  return p;
}

#ifdef DEBUG_MEMALLOC
void *_memReAlloc( void *p, size_t size, const char *file, int line )
#else
void *_memReAlloc( void *p, size_t size )
#endif
{
#if defined(DEBUG_MEMALLOC) && defined(TRACE_MEMALLOC)
  void *oldp = p;
#endif

#ifdef DEBUG_MEMALLOC
  if( p != NULL )
    DEBUG( TRACE, ("%s(%d):F=%08lX\n", file, line, (unsigned long)p) );
#endif

#if defined(DEBUG_MEMALLOC) && defined(AUTOPURGE_MEMALLOC)
  if( p != NULL ) {
    size_t old_size;

    p = (void *)(((size_t *)p)-1);
    old_size = *((size_t *)p);

    if( old_size > size )
      memset( ((char *)p) + sizeof(size_t) + size, 0xA5, old_size - size );
  }

  if( size != 0 )
    p = UTIL_REALLOC( p, size + sizeof( size_t ) );
#else
  p = UTIL_REALLOC( p, size );
#endif

  abortMEMALLOC( "_memReAlloc", size, p );

#if defined(DEBUG_MEMALLOC) && defined(AUTOPURGE_MEMALLOC)
  if( p != NULL ) {
    *((size_t *)p) = size;
    p = (void *)(((size_t *)p)+1);
  }
#endif

#ifdef DEBUG_MEMALLOC
  if( size != 0 )
    DEBUG( TRACE, ("%s(%d):A=%d@%08lX\n", file, line, size, (unsigned long)p) );

  (void) trace_upd( oldp, p, size, file, line );
#endif

  return p;
}

#ifdef DEBUG_MEMALLOC

void _memFree( void *p, const char *file, int line )
{
  DEBUG( TRACE, ("%s(%d):F=%08lX\n", file, line, (unsigned long)p) );

  if( trace_del( p, file, line ) && p ) {
#ifdef AUTOPURGE_MEMALLOC
    size_t size;
    p = (void *)(((size_t *)p)-1);
    size = *((size_t *)p);
    memset( p, 0xA5, size + sizeof( size_t ) );
#endif
    UTIL_FREE( p );
  }
}

void _assertValidPtr( const void *p, const char *file, int line )
{
  DEBUG( ASSERT, ("%s(%d):V=%08lX\n", file, line, (unsigned long)p) );
  (void) trace_check_ptr( p, file, line );
}

void _assertValidBlock( const void *p, size_t size, const char *file, int line )
{
  DEBUG( ASSERT, ("%s(%d):B=%d@%08lX\n", file, line, size, (unsigned long)p) );
  (void) trace_check_range( p, size, file, line );
}

#ifdef UTIL_FORMAT_CHECK
static void debug_check( const char *str __attribute__(( __unused__ )), ... )
{
  fprintf( stderr, "compiled with UTIL_FORMAT_CHECK, please don't run\n" );
  abort();
}
#endif

int SetDebugMemAlloc( void (*dbfunc)(const char *, ...), unsigned long dbflags )
{
  gs_dbfunc  = dbfunc;
  gs_dbflags = dbflags;
  return 1;
}

#endif /* DEBUG_MEMALLOC */

#else

/* avoid empty source file warning */
extern int _memalloc___notused __attribute__((unused));

#endif /* defined(DEBUG_MEMALLOC) */

/* ============================================================= */
/* ==================== TEST CODE FOLLOWING ==================== */
/* ============================================================= */

#ifdef MEMALLOC_TEST

#include <stdio.h>
#include <stdarg.h>
#include "memalloc.h"

static FILE *ftest;
static FILE *fdebug;

static struct {
  int debug;
  int assert;
  int check_freed;
  int stat_level;
} flags;

static void t_trace( const char *fmt, ... )
{
  va_list l;
  va_start(l, fmt);
#if defined(DEBUG_MEMALLOC) && defined(TRACE_MEMALLOC)
  vfprintf(ftest, fmt, l);
#endif
  va_end(l);
}

#if defined(DEBUG_MEMALLOC)
static void t_debug( const char *fmt, ... )
{
  va_list l;
  va_start(l, fmt);
  if( flags.debug )
    vfprintf(ftest, fmt, l);
  va_end(l);
}
#endif

static void t_assert( const char *fmt, ... )
{
  va_list l;
  va_start(l, fmt);
#if defined(DEBUG_MEMALLOC)
  if( flags.assert )
    vfprintf(ftest, fmt, l);
#endif
  va_end(l);
}

#define trc_not_alloc     t_trace("pointer %p has not yet been allocated in %s:%d\n", p, __FILE__, __LINE__)
#define trc_assP_fail     t_trace("Assertion failed: %p is not a valid pointer in %s:%d\n", p, __FILE__, __LINE__)
#define trc_assB_fail(s)  t_trace("Assertion failed: %p(%d) is not a valid block in %s:%d\n", p, s, __FILE__, __LINE__)
#define trc               t_trace
#define trc_f             if( flags.check_freed ) t_trace
#define assP              t_assert("%s(%d):V=%08lX\n", __FILE__, __LINE__, (unsigned long)p)
#define assB(s)           t_assert("%s(%d):B=%d@%08lX\n", __FILE__, __LINE__, s, (unsigned long)p)
#if defined(DEBUG_MEMALLOC)
#  define dbg(what)       t_debug("%s(%d):" #what "=%08lX\n", __FILE__, __LINE__, (unsigned long)p)
#  define dbgA(p,s)       t_debug("%s(%d):A=%d@%08lX\n", __FILE__, __LINE__, s, (unsigned long)p)
#else
#  define dbg(what)       (void)1
#  define dbgA(p,s)       (void)1
#endif

static void runtests( void )
{
  unsigned char *p, *p1;                                   int lp1;
  int i;

#define S_P1 10

  AllocF( char *, p1, S_P1 );             dbgA(p1,S_P1);   lp1 = __LINE__;

  for( i = 0; i < S_P1; i++ )
    p1[i] = (unsigned char) i;

#ifdef TRACE_MEMALLOC
  p = p1 + 1;
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc("  %p is inside an allocated block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);
  p = p1 + (S_P1-1);
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc("  %p is inside an allocated block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);
#if MEMALLOC_MAX_DIAG_DIST > 1
  p = p1 - 1;
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc("  %p is 1 byte before an allocated block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);
  p = p1 + S_P1;
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc("  %p is 1 byte behind an allocated block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);
  p = p1 - (MEMALLOC_MAX_DIAG_DIST-1);
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc("  %p is %d byte%s before an allocated block of %d bytes at %p (%s:%d)\n", p, MEMALLOC_MAX_DIAG_DIST-1,
                                                                                                MEMALLOC_MAX_DIAG_DIST-1 == 1 ? "" : "s", S_P1, p1, __FILE__, lp1);
  p = p1 + (MEMALLOC_MAX_DIAG_DIST+S_P1-2);
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc("  %p is %d byte%s behind an allocated block of %d bytes at %p (%s:%d)\n", p, MEMALLOC_MAX_DIAG_DIST-1,
                                                                                                MEMALLOC_MAX_DIAG_DIST-1 == 1 ? "" : "s", S_P1, p1, __FILE__, lp1);
#endif
  p = p1 - (MEMALLOC_MAX_DIAG_DIST);
  Free( p );                                     dbg(F);   trc_not_alloc;

  p = p1 + (MEMALLOC_MAX_DIAG_DIST+S_P1-1);
  Free( p );                                     dbg(F);   trc_not_alloc;
#endif

  p = p1;
  AssertValidPtr(p);                               assP;
  p = p1+1;
  AssertValidPtr(p);                               assP;   trc_assP_fail;
                                                           trc("  %p is inside an allocated block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);

  p = p1;
  AssertValidBlock(p,5);                        assB(5);
  p = p1-1;
  AssertValidBlock(p,5);                        assB(5);   trc_assB_fail(5);
                                                           trc("  %p(5) overlaps 4 bytes with an allocated block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);

  p = p1;
  Free( p );                                     dbg(F);

  AssertValidPtr(p);                               assP;   trc_assP_fail;
                                                           trc_f("  %p points to a block of %d bytes already freed (%s:%d)\n", p, S_P1, __FILE__, lp1);

#ifdef TRACE_MEMALLOC
  p = p1 + 1;
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc_f("  %p is inside a freed block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);
  p = p1 + (S_P1-1);
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc_f("  %p is inside a freed block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);
#if MEMALLOC_MAX_DIAG_DIST > 1
  p = p1 - 1;
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc_f("  %p is 1 byte before a freed block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);
  p = p1 + S_P1;
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc_f("  %p is 1 byte behind a freed block of %d bytes at %p (%s:%d)\n", p, S_P1, p1, __FILE__, lp1);
  p = p1 - (MEMALLOC_MAX_DIAG_DIST-1);
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc_f("  %p is %d byte%s before a freed block of %d bytes at %p (%s:%d)\n", p, MEMALLOC_MAX_DIAG_DIST-1,
                                                                                             MEMALLOC_MAX_DIAG_DIST-1 == 1 ? "" : "s", S_P1, p1, __FILE__, lp1);
  p = p1 + (MEMALLOC_MAX_DIAG_DIST+S_P1-2);
  Free( p );                                     dbg(F);   trc_not_alloc;
                                                           trc_f("  %p is %d byte%s behind a freed block of %d bytes at %p (%s:%d)\n", p, MEMALLOC_MAX_DIAG_DIST-1,
                                                                                             MEMALLOC_MAX_DIAG_DIST-1 == 1 ? "" : "s", S_P1, p1, __FILE__, lp1);
#endif
  p = p1 - (MEMALLOC_MAX_DIAG_DIST);
  Free( p );                                     dbg(F);   trc_not_alloc;

  p = p1 + (MEMALLOC_MAX_DIAG_DIST+S_P1-1);
  Free( p );                                     dbg(F);   trc_not_alloc;

  p = p1;
  Free( p );                                     dbg(F);   trc("pointer %p has %s in %s:%d\n", p, flags.check_freed ? "already been freed" : "not yet been allocated", __FILE__, __LINE__);
#endif

}

#ifdef DEBUG_MEMALLOC
static void test_dbfunc( const char *fmt, ... )
{
  va_list l;
  va_start(l, fmt);
  vfprintf(fdebug ? fdebug : stderr, fmt, l);
  va_end(l);
}
#endif

int main( void )
{
  const char *str;
  const char *file;

  if( (file = getenv("MEMALLOC_TEST_FILE")) == NULL )
    file = "test.ref";

  flags.debug       = (str=getenv("MEMALLOC_TEST_DEBUG")) && atoi(str);
  flags.assert      = (str=getenv("MEMALLOC_TEST_ASSERT")) && atoi(str);
  flags.check_freed = (str=getenv("MEMALLOC_CHECK_FREED")) && atoi(str);
  flags.stat_level  = (str=getenv("MEMALLOC_STAT_LEVEL")) ? atoi(str) : -1;

  if( (str=getenv("MEMALLOC_TEST_DEBUG_FILE")) != NULL )
    if( (fdebug = fopen(str, "w")) == NULL )
      return -1;

#ifdef DEBUG_MEMALLOC
  SetDebugMemAlloc( test_dbfunc, (flags.debug  ? DB_MEMALLOC_TRACE  : 0)
                               | (flags.assert ? DB_MEMALLOC_ASSERT : 0) );
#endif

  if( (ftest = fopen(file, "w")) == NULL )
    return -1;

  runtests();

  fclose(ftest);

#ifdef DEBUG_MEMALLOC
  SetDebugMemAlloc( NULL, 0 );
#endif

  if( fdebug )
    fclose(fdebug);

  return 0;
}
#endif
