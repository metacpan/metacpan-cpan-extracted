/* hashmap_i16s.h — int16_t -> string hashmap */
#ifndef HASHMAP_I16S_H
#define HASHMAP_I16S_H

#define HM_INT_TYPE     int16_t
#define HM_INT_MIN      INT16_MIN
#define HM_INT_MAX      INT16_MAX
#define HM_PREFIX       hashmap_i16s
#define HM_NODE_TYPE    HashNodeI16S
#define HM_MAP_TYPE     HashMapI16S
#define HM_KEY_IS_INT
#define HM_VALUE_IS_STR

#include "hashmap_generic.h"

#endif /* HASHMAP_I16S_H */
