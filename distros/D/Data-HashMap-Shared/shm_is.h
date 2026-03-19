/* shm_is.h -- int64 -> string shared hashmap */
#define SHM_PREFIX       shm_is
#define SHM_NODE_TYPE    ShmNodeIS
#define SHM_VARIANT_ID   6
#define SHM_KEY_IS_INT
#define SHM_KEY_INT_TYPE int64_t
#define SHM_VAL_IS_STR
#include "shm_generic.h"
