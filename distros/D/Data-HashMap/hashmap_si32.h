/* hashmap_si32.h — string -> int32_t hashmap */
#ifndef HASHMAP_SI32_H
#define HASHMAP_SI32_H

#define HM_INT_TYPE     int32_t
#define HM_INT_MIN      INT32_MIN
#define HM_INT_MAX      INT32_MAX
#define HM_PREFIX       hashmap_si32
#define HM_NODE_TYPE    HashNodeSI32
#define HM_MAP_TYPE     HashMapSI32
/* string keys (HM_KEY_IS_INT not defined) */
#define HM_HAS_COUNTERS

#include "hashmap_generic.h"

#endif /* HASHMAP_SI32_H */
