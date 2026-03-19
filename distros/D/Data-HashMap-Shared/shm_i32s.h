/* shm_i32s.h -- int32 -> string shared hashmap */
#define SHM_PREFIX       shm_i32s
#define SHM_NODE_TYPE    ShmNodeI32S
#define SHM_VARIANT_ID   5
#define SHM_KEY_IS_INT
#define SHM_KEY_INT_TYPE int32_t
#define SHM_VAL_IS_STR
#include "shm_generic.h"
