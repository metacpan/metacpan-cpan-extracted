/* hashmap_i32.h — int32_t -> int32_t hashmap (8 bytes/node) */
#ifndef HASHMAP_I32_H
#define HASHMAP_I32_H

#define HM_INT_TYPE     int32_t
#define HM_INT_MIN      INT32_MIN
#define HM_INT_MAX      INT32_MAX
#define HM_PREFIX       hashmap_i32
#define HM_NODE_TYPE    HashNodeI32
#define HM_MAP_TYPE     HashMapI32
#define HM_KEY_IS_INT
#define HM_HAS_COUNTERS

#include "hashmap_generic.h"

#endif /* HASHMAP_I32_H */
