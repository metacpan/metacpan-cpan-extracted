#include "cxsa_locking.h"
#include "cxsa_memory.h"

#ifdef USE_ITHREADS
cxsa_global_lock CXSAccessor_lock;

void _init_cxsa_lock(cxsa_global_lock* theLock) {
  cxa_memzero((void*)theLock, sizeof(cxsa_global_lock));
  MUTEX_INIT(&theLock->mutex);
  COND_INIT(&theLock->cond);
  theLock->locks = 0;
}
#endif
