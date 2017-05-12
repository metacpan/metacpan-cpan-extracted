/*
 *
 * Copyright (C) 2006 by Richard Holden
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

#include "netinterface.h"
#include "../pack.h"


my_netinterface_t* netinterface_impl(int desired_number, char* name, int update_name)
{
	perfstat_id_t netinterface_name;

	if (desired_number < 1)
	{
		die("netinterface: desired_number must be at least 1.");
	}
	if (strlen(name) > (IDENTIFIER_LENGTH - 1))
	{
		die("netinterface: name must be less than IDENTIFER_LENGTH chars including the trailing \'\\0\'.\n");
	}

	strncpy(netinterface_name.name, name, IDENTIFIER_LENGTH);

	my_netinterface_t*	netinterface = (my_netinterface_t*)safemalloc(sizeof(my_netinterface_t));
	if (netinterface == NULL)
	{
		die("netinterface: malloc failed for netinterface");
	}

	netinterface->size = 0;
	netinterface->data = (perfstat_netinterface_t*)safemalloc(desired_number * sizeof(perfstat_netinterface_t));
	if (netinterface->data == NULL)
	{
		safefree(netinterface);
		die("netinterface: malloc failed for netinterface->data");
	}

	if ((netinterface->size = perfstat_netinterface(&netinterface_name, netinterface->data, sizeof(perfstat_netinterface_t), desired_number)) == -1 || (netinterface->size == 0))
	{
		safefree(netinterface->data);
		safefree(netinterface);
		netinterface = NULL;
	}

	if (update_name)
	{
		int name_len = strlen(name);
		int netinterface_name_len = strlen(netinterface_name.name);

		if (netinterface_name_len > name_len)
		{
			safefree(name);
			name = (char*)safemalloc((netinterface_name_len+1)*sizeof(char));
			if (name == NULL)
			{
				die("netinterface: couldn't malloc for new name string.");
			}
		}
		strncpy(name, netinterface_name.name, netinterface_name_len+1);
	}
	return netinterface;
}

int netinterface_count_impl()
{
	return perfstat_netinterface(NULL, NULL, sizeof(perfstat_netinterface_t), 0);
}

perfstat_netinterface_total_t* netinterface_total_impl()
{
	perfstat_netinterface_total_t* netinterface_total = (perfstat_netinterface_total_t*)safemalloc(sizeof(perfstat_netinterface_total_t));
	if (netinterface_total == NULL)
	{
		die("netinterface_total: unable to malloc");
	}

	if (perfstat_netinterface_total(NULL, netinterface_total, sizeof(perfstat_netinterface_total_t), 1) == -1)
	{
		safefree(netinterface_total);
		die("netinterface_total: failed");
	}
	return netinterface_total;
}


/* pack a number of (struct perfstat_netinterface_t) into an array of hashes
 * and put a reference to this array onto Perl stack
 */
void XS_pack_my_netinterface_tPtr(SV *st, my_netinterface_t *q)
{
	AV *av = newAV();
	SV *sv;
	perfstat_netinterface_t *p;
	int i;

	for (i = 0, p = q->data; i < (q->size); i++, p++)
	{
		HV *hv = newHV();

		PACK_PV(name,0);
		PACK_PV(description,0);
		PACK_UV(type);
		PACK_UV(mtu);
		PACK_UV(ipackets);
		PACK_UV(ibytes);
		PACK_UV(ierrors);
		PACK_UV(opackets);
		PACK_UV(obytes);
		PACK_UV(oerrors);
		PACK_UV(collisions);

		av_push(av, newRV_noinc((SV*)hv));
	}

	/* put ref to hv onto stack */
	sv = newSVrv(st, NULL);
	SvREFCNT_dec(sv);
	SvRV(st) = (SV*)av;
}

/* pack struct perfstat_netinterface_total_t into a hash
 * and put a reference to this hash onto Perl stack
 */
void XS_pack_perfstat_netinterface_total_tPtr(SV *st, perfstat_netinterface_total_t *p)
{
	HV *hv = newHV();
	SV *sv;

	PACK_IV(number);
	PACK_UV(ipackets);
	PACK_UV(ibytes);
	PACK_UV(ierrors);
	PACK_UV(opackets);
	PACK_UV(obytes);
	PACK_UV(oerrors);
	PACK_UV(collisions);

	/* put ref to hv onto stack */
	sv = newSVrv(st, NULL);
	SvREFCNT_dec(sv);
	SvRV(st) = (SV*)hv;
}
