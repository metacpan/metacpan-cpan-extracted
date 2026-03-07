/* hashmap_ii.h — int64_t -> int64_t hashmap (16 bytes/node) */
#ifndef HASHMAP_II_H
#define HASHMAP_II_H

#define HM_PREFIX       hashmap_ii
#define HM_NODE_TYPE    HashNodeII
#define HM_MAP_TYPE     HashMapII
#define HM_KEY_IS_INT
/* HM_VALUE_IS_STR not defined — int64_t values */
#define HM_HAS_COUNTERS

#include "hashmap_generic.h"

#endif /* HASHMAP_II_H */
