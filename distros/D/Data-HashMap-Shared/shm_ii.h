/* shm_ii.h -- int64 -> int64 shared hashmap */
#define SHM_PREFIX       shm_ii
#define SHM_NODE_TYPE    ShmNodeII
#define SHM_VARIANT_ID   3
#define SHM_KEY_IS_INT
#define SHM_KEY_INT_TYPE int64_t
#define SHM_VAL_INT_TYPE int64_t
#define SHM_HAS_COUNTERS
#include "shm_generic.h"
