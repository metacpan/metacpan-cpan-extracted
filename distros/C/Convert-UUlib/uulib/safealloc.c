/* enable the POSIX prototypes of mmap/munmap on Solaris */
#ifdef __sun
# if __STDC_VERSION__ >= 199901L
#  define _XOPEN_SOURCE 600
# else
#  define _XOPEN_SOURCE 500
# endif
#endif

#ifndef _WIN32
  #include <unistd.h>
#endif

#if !defined USE_MMAP \
    && _POSIX_MAPPED_FILES > 0 \
    && (_POSIX_VERSION >= 200809L || _POSIX_MEMORY_PROTECTION > 0)
  #include <sys/mman.h>
  #if !defined MAP_ANONYMOUS && defined MAP_ANON
    #define MAP_ANONYMOUS MAP_ANON
  #endif
  #ifdef MAP_ANONYMOUS
    #include <limits.h>
    #if PAGESIZE <= 0
      static long pagesize;
      #define PAGESIZE pagesize ? pagesize : (pagesize = sysconf (_SC_PAGESIZE))
    #endif
    #define USE_MMAP 1
  #endif
#endif

/* we assume natural alignment, uulib only uses ints and chars */
#define ALIGN 1
#define GUARDS 4

static void *
safe_alloc (size_t size)
{
#if USE_MMAP

  size_t rounded = (size + ALIGN - 1) & ~(ALIGN - 1);
  size_t page = PAGESIZE;
  size_t page_rounded = (rounded + page - 1) & ~(page - 1);
  void *base = mmap (0, page_rounded + page * GUARDS * 2, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);

  if (base == (void *)-1)
    return 0;

  mprotect (base, page * GUARDS, PROT_NONE); /* beginning */
  mprotect (page_rounded + page * GUARDS + (char *)base, page * GUARDS, PROT_NONE); /* end */

  return page * GUARDS + (page_rounded - rounded) + (char *)base;

#else
  return malloc (size);
#endif
}

static void
safe_free (void *mem, size_t size)
{
#if USE_MMAP

  size_t rounded = (size + ALIGN - 1) & ~(ALIGN - 1);
  size_t page = PAGESIZE;
  size_t page_rounded = (rounded + page - 1) & ~(page - 1);

  if (!mem)
    return;

  mem = (char *)mem - page * GUARDS - (page_rounded - rounded);

  munmap (mem, page_rounded + page * GUARDS * 2);

#else
  free (size);
#endif
}

