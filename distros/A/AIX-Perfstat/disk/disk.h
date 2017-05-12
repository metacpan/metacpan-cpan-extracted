/*
 *
 * Copyright (C) 2006 by Richard Holden
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

#ifndef DISK_H_INCLUDE_GUARD
#define DISK_H_INCLUDE_GUARD

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libperfstat.h>

#ifdef __cplusplus
extern "C" {
#endif

	typedef struct my_disk_t
	{
		int size;
		perfstat_disk_t *data;
	} my_disk_t;

	extern my_disk_t* disk_impl(int desired_number, char * name, int update_name);
	extern int disk_count_impl();
	extern perfstat_disk_total_t* disk_total_impl();

	// Functions called by XSUB to pack the C datastructures into perl structures. */
	extern void XS_pack_my_disk_tPtr(SV *, my_disk_t *);
	extern void XS_pack_perfstat_disk_total_tPtr(SV *, perfstat_disk_total_t *);


#ifdef __cplusplus
}
#endif

#endif /* undef DISK_H_INCLUDE_GUARD */
