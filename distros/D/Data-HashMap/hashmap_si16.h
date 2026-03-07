/* hashmap_si16.h — string -> int16_t hashmap */
#ifndef HASHMAP_SI16_H
#define HASHMAP_SI16_H

#define HM_INT_TYPE     int16_t
#define HM_INT_MIN      INT16_MIN
#define HM_INT_MAX      INT16_MAX
#define HM_PREFIX       hashmap_si16
#define HM_NODE_TYPE    HashNodeSI16
#define HM_MAP_TYPE     HashMapSI16
/* string keys (HM_KEY_IS_INT not defined) */
#define HM_HAS_COUNTERS

#include "hashmap_generic.h"

#endif /* HASHMAP_SI16_H */
