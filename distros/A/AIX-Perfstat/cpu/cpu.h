/*
 *
 * Copyright (C) 2006 by Richard Holden
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

#ifndef CPU_H_INCLUDE_GUARD
#define CPU_H_INCLUDE_GUARD

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libperfstat.h>

#ifdef __cplusplus
extern "C" {
#endif

	typedef struct my_cpu_t
	{
		int size;
		perfstat_cpu_t *data;
	} my_cpu_t;

	extern my_cpu_t* cpu_impl(int desired_number, char* name, int update_name);
	extern int cpu_count_impl();
	extern perfstat_cpu_total_t* cpu_total_impl();

	extern void XS_pack_my_cpu_tPtr(SV *, my_cpu_t *);
	extern void XS_pack_perfstat_cpu_total_tPtr(SV *, perfstat_cpu_total_t *);

#ifdef __cplusplus
}
#endif

#endif /* undef CPU_H_INCLUDE_GUARD */
