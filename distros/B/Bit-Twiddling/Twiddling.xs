#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int count_set_bits(long v) {
    int c;
    for (c = 0; v; c++)
      v &= v - 1;
    return c;
}

long nearest_higher_power_of_2(long v) {
    if (v == 0) return 1;
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    return v + 1;
}

MODULE = Bit::Twiddling  PACKAGE = Bit::Twiddling

PROTOTYPES: DISABLE

int
count_set_bits (v)
	long	v

long
nearest_higher_power_of_2 (v)
	long	v
