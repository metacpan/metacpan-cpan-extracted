/* hashmap_is.h — int64_t -> string hashmap (24 bytes/node) */
#ifndef HASHMAP_IS_H
#define HASHMAP_IS_H

#define HM_PREFIX       hashmap_is
#define HM_NODE_TYPE    HashNodeIS
#define HM_MAP_TYPE     HashMapIS
#define HM_KEY_IS_INT
#define HM_VALUE_IS_STR
/* HM_HAS_COUNTERS not defined — string values */

#include "hashmap_generic.h"

#endif /* HASHMAP_IS_H */
