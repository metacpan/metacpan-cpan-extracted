#ifndef cxsa_locking_h_
#define cxsa_locking_h_

#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

/* If we're not using threads, provide no-op macros */
#ifndef USE_ITHREADS
#  define CXSA_RELEASE_GLOBAL_LOCK(theLock)
#  define CXSA_ACQUIRE_GLOBAL_LOCK(theLock)
#endif

#ifdef USE_ITHREADS
typedef struct {
  perl_mutex mutex;
  perl_cond cond;
  unsigned int locks;
} cxsa_global_lock;

extern cxsa_global_lock CXSAccessor_lock;

void _init_cxsa_lock(cxsa_global_lock* theLock);

#define CXSA_ACQUIRE_GLOBAL_LOCK(theLock)     \
STMT_START {                                  \
  MUTEX_LOCK(&theLock.mutex);                 \
  while (theLock.locks != 0) {                \
    COND_WAIT(&theLock.cond, &theLock.mutex); \
  }                                           \
  theLock.locks = 1;                          \
  MUTEX_UNLOCK(&theLock.mutex);               \
} STMT_END

#define CXSA_RELEASE_GLOBAL_LOCK(theLock)     \
STMT_START {                                  \
  MUTEX_LOCK(&theLock.mutex);                 \
  theLock.locks = 0;                          \
  COND_SIGNAL(&theLock.cond);                 \
  MUTEX_UNLOCK(&theLock.mutex);               \
} STMT_END

#endif /* USE_ITHREADS */

#endif
