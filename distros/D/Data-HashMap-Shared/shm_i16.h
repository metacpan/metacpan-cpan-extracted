/* shm_i16.h -- int16 -> int16 shared hashmap */
#define SHM_PREFIX       shm_i16
#define SHM_NODE_TYPE    ShmNodeI16
#define SHM_VARIANT_ID   1
#define SHM_KEY_IS_INT
#define SHM_KEY_INT_TYPE int16_t
#define SHM_VAL_INT_TYPE int16_t
#define SHM_HAS_COUNTERS
#include "shm_generic.h"
