/*
 *
 * Copyright (C) 2006 by Richard Holden
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

#ifndef NETINTERFACE_H_INCLUDE_GUARD
#define NETINTERFACE_H_INCLUDE_GUARD

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libperfstat.h>

#ifdef __cplusplus
extern "C" {
#endif

	typedef struct my_netinterface_t
	{
		int size;
		perfstat_netinterface_t *data;
	} my_netinterface_t;

	extern my_netinterface_t* netinterface_impl(int desired_number, char* name, int update_name);
	extern int netinterface_count_impl();
	extern perfstat_netinterface_total_t* netinterface_total_impl();
	
	extern void XS_pack_my_netinterface_tPtr(SV *, my_netinterface_t *);
	extern void XS_pack_perfstat_netinterface_total_tPtr(SV *, perfstat_netinterface_total_t *);

#ifdef __cplusplus
}
#endif

#endif /* undef NETINTERFACE_H_INCLUDE_GUARD */
