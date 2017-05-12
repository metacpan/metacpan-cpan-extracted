/*
 *
 * Copyright (C) 2006 by Richard Holden
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */
#ifndef MEMORY_H_INCLUDE_GUARD
#define MEMORY_H_INCLUDE_GUARD

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libperfstat.h>

#ifdef __cplusplus
extern "C" {
#endif

	extern void XS_pack_perfstat_memory_total_tPtr(SV *, perfstat_memory_total_t *);

#ifdef __cplusplus
}
#endif

#endif /* undef MEMORY_H_INCLUDE_GUARD */
