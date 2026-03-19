/* shm_si.h -- string -> int64 shared hashmap */
#define SHM_PREFIX       shm_si
#define SHM_NODE_TYPE    ShmNodeSI
#define SHM_VARIANT_ID   9
#define SHM_VAL_INT_TYPE int64_t
#define SHM_HAS_COUNTERS
#include "shm_generic.h"
