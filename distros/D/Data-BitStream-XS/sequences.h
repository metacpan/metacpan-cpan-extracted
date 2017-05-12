#ifndef DBXS_SEQUENCES_H
#define DBXS_SEQUENCES_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "wtype.h"

extern void  prime_init(WTYPE x);
extern int   is_prime(WTYPE x);
extern WTYPE prime_count(WTYPE x);
extern WTYPE nth_prime(WTYPE n);

extern int   find_best_pair(WTYPE* basis, int basislen, WTYPE val, int adder, int* a, int* b);
extern int   find_best_prime_pair(WTYPE val, int adder, int* a, int* b);

#endif
