/* ====================================================================
 * Copyright (c) 2000 David Lowe.
 *
 * magic_c_int.h
 *
 * A set of functions for creating magical SVs closely tied to C integers
 * ==================================================================== */

#ifndef __MAGIC_C_INT_H
#define __MAGIC_C_INT_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

SV *newSV_magic_c_int(int *addr);
I32 magic_c_int_get(IV num, SV *sv);
I32 magic_c_int_set(IV num, SV *sv);

#endif /* __MAGIC_C_INT_H */
