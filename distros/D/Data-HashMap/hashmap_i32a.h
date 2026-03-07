/* hashmap_i32a.h — int32_t -> SV* hashmap */
#ifndef HASHMAP_I32A_H
#define HASHMAP_I32A_H

#define HM_INT_TYPE     int32_t
#define HM_INT_MIN      INT32_MIN
#define HM_INT_MAX      INT32_MAX
#define HM_PREFIX       hashmap_i32a
#define HM_NODE_TYPE    HashNodeI32A
#define HM_MAP_TYPE     HashMapI32A
#define HM_KEY_IS_INT
#define HM_VALUE_IS_SV

#include "hashmap_generic.h"

#endif /* HASHMAP_I32A_H */
