/* hashmap_si.h — string -> int64_t hashmap (24 bytes/node) */
#ifndef HASHMAP_SI_H
#define HASHMAP_SI_H

#define HM_PREFIX       hashmap_si
#define HM_NODE_TYPE    HashNodeSI
#define HM_MAP_TYPE     HashMapSI
/* HM_KEY_IS_INT not defined — string keys */
/* HM_VALUE_IS_STR not defined — int64_t values */
#define HM_HAS_COUNTERS

#include "hashmap_generic.h"

#endif /* HASHMAP_SI_H */
