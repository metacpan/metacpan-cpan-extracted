/* hashmap_sa.h — string -> SV* hashmap (~24 bytes/node) */
#ifndef HASHMAP_SA_H
#define HASHMAP_SA_H

#define HM_PREFIX       hashmap_sa
#define HM_NODE_TYPE    HashNodeSA
#define HM_MAP_TYPE     HashMapSA
/* HM_KEY_IS_INT not defined — string keys */
#define HM_VALUE_IS_SV
/* HM_HAS_COUNTERS not defined — SV* values */

#include "hashmap_generic.h"

#endif /* HASHMAP_SA_H */
