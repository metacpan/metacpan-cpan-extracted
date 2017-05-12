/*
 *
 * Copyright (C) 2006 by Richard Holden
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */
#include "memory.h"
#include "../pack.h"

/* pack struct perfstat_memory_total_t into a hash
 * and put a reference to this hash onto Perl stack
 */
void XS_pack_perfstat_memory_total_tPtr(SV *st, perfstat_memory_total_t *p)
{
	HV *hv = newHV();
	SV *sv;

	PACK_UV(virt_total);
	PACK_UV(real_total);
	PACK_UV(real_free);
	PACK_UV(real_pinned);
	PACK_UV(real_inuse);
	PACK_UV(pgbad);
	PACK_UV(pgexct);
	PACK_UV(pgins);
	PACK_UV(pgouts);
	PACK_UV(pgspins);
	PACK_UV(pgspouts);
	PACK_UV(scans);
	PACK_UV(cycles);
	PACK_UV(pgsteals);
	PACK_UV(numperm);
	PACK_UV(pgsp_total);
	PACK_UV(pgsp_free);
	PACK_UV(pgsp_rsvd);

	/* put ref to hv onto stack */
	sv = newSVrv(st, NULL);
	SvREFCNT_dec(sv);
	SvRV(st) = (SV*)hv;
}
