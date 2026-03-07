/* hashmap_i32s.h — int32_t -> string hashmap */
#ifndef HASHMAP_I32S_H
#define HASHMAP_I32S_H

#define HM_INT_TYPE     int32_t
#define HM_INT_MIN      INT32_MIN
#define HM_INT_MAX      INT32_MAX
#define HM_PREFIX       hashmap_i32s
#define HM_NODE_TYPE    HashNodeI32S
#define HM_MAP_TYPE     HashMapI32S
#define HM_KEY_IS_INT
#define HM_VALUE_IS_STR

#include "hashmap_generic.h"

#endif /* HASHMAP_I32S_H */
