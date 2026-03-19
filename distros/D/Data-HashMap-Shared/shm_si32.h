/* shm_si32.h -- string -> int32 shared hashmap */
#define SHM_PREFIX       shm_si32
#define SHM_NODE_TYPE    ShmNodeSI32
#define SHM_VARIANT_ID   8
#define SHM_VAL_INT_TYPE int32_t
#define SHM_HAS_COUNTERS
#include "shm_generic.h"
