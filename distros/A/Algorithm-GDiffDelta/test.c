#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* TODO - try with long long */
typedef unsigned long Off_t;

typedef unsigned int U32;

#include "util.c"

int
main (void)
{
    assert(QEF_MIN(17, 23) == 17);
    assert(QEF_MIN(23, 17) == 17);

    assert(hashbits(0) == 1);
    assert(hashbits(1) == 1);
    assert(hashbits(2) == 2);
    return 0;
}

/* vi:set ts=4 sw=4 expandtab: */
