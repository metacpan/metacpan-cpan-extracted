/* hashmap_i16.h — int16_t -> int16_t hashmap (4 bytes/node) */
#ifndef HASHMAP_I16_H
#define HASHMAP_I16_H

#define HM_INT_TYPE     int16_t
#define HM_INT_MIN      INT16_MIN
#define HM_INT_MAX      INT16_MAX
#define HM_PREFIX       hashmap_i16
#define HM_NODE_TYPE    HashNodeI16
#define HM_MAP_TYPE     HashMapI16
#define HM_KEY_IS_INT
#define HM_HAS_COUNTERS

#include "hashmap_generic.h"

#endif /* HASHMAP_I16_H */
