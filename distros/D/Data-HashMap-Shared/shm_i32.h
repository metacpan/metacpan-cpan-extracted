/* shm_i32.h -- int32 -> int32 shared hashmap */
#define SHM_PREFIX       shm_i32
#define SHM_NODE_TYPE    ShmNodeI32
#define SHM_VARIANT_ID   2
#define SHM_KEY_IS_INT
#define SHM_KEY_INT_TYPE int32_t
#define SHM_VAL_INT_TYPE int32_t
#define SHM_HAS_COUNTERS
#include "shm_generic.h"
