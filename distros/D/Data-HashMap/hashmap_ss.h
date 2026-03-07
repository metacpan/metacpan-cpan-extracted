/* hashmap_ss.h — string -> string hashmap (32 bytes/node) */
#ifndef HASHMAP_SS_H
#define HASHMAP_SS_H

#define HM_PREFIX       hashmap_ss
#define HM_NODE_TYPE    HashNodeSS
#define HM_MAP_TYPE     HashMapSS
/* HM_KEY_IS_INT not defined — string keys */
#define HM_VALUE_IS_STR
/* HM_HAS_COUNTERS not defined — string values */

#include "hashmap_generic.h"

#endif /* HASHMAP_SS_H */
