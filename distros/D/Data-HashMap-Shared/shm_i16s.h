/* shm_i16s.h -- int16 -> string shared hashmap */
#define SHM_PREFIX       shm_i16s
#define SHM_NODE_TYPE    ShmNodeI16S
#define SHM_VARIANT_ID   4
#define SHM_KEY_IS_INT
#define SHM_KEY_INT_TYPE int16_t
#define SHM_VAL_IS_STR
#include "shm_generic.h"
