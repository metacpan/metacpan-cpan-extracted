/* hashmap_ia.h — int64_t -> SV* hashmap (16 bytes/node) */
#ifndef HASHMAP_IA_H
#define HASHMAP_IA_H

#define HM_PREFIX       hashmap_ia
#define HM_NODE_TYPE    HashNodeIA
#define HM_MAP_TYPE     HashMapIA
#define HM_KEY_IS_INT
#define HM_VALUE_IS_SV
/* HM_HAS_COUNTERS not defined — SV* values */

#include "hashmap_generic.h"

#endif /* HASHMAP_IA_H */
