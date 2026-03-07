/* hashmap_i16a.h — int16_t -> SV* hashmap */
#ifndef HASHMAP_I16A_H
#define HASHMAP_I16A_H

#define HM_INT_TYPE     int16_t
#define HM_INT_MIN      INT16_MIN
#define HM_INT_MAX      INT16_MAX
#define HM_PREFIX       hashmap_i16a
#define HM_NODE_TYPE    HashNodeI16A
#define HM_MAP_TYPE     HashMapI16A
#define HM_KEY_IS_INT
#define HM_VALUE_IS_SV

#include "hashmap_generic.h"

#endif /* HASHMAP_I16A_H */
