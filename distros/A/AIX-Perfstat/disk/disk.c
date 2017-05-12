/*
 *
 * Copyright (C) 2006 by Richard Holden
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

#include "disk.h"
#include "../pack.h"


my_disk_t* disk_impl(int desired_number, char* name, int update_name)
{
	perfstat_id_t disk_name;

	if (desired_number < 1)
	{
		die("disk: desired_number must be at least 1.");
	}
	if (strlen(name) > (IDENTIFIER_LENGTH - 1))
	{
		die("disk: name must be less than IDENTIFER_LENGTH chars including the trailing \'\\0\'.\n");
	}

	strncpy(disk_name.name, name, IDENTIFIER_LENGTH);

	my_disk_t*	disk = (my_disk_t*)safemalloc(sizeof(my_disk_t));
	if (disk == NULL)
	{
		die("disk: malloc failed for disk");
	}

	disk->size = 0;
	disk->data = (perfstat_disk_t*)safemalloc(desired_number * sizeof(perfstat_disk_t));
	if (disk->data == NULL)
	{
		safefree(disk);
		die("disk: malloc failed for disk->data");
	}

	if ((disk->size = perfstat_disk(&disk_name, disk->data, sizeof(perfstat_disk_t), desired_number)) == -1 || (disk->size == 0))
	{
		safefree(disk->data);
		safefree(disk);
		disk = NULL;
	}

	if (update_name)
	{
		int name_len = strlen(name);
		int disk_name_len = strlen(disk_name.name);

		if (disk_name_len > name_len)
		{
			safefree(name);
			name = (char*)safemalloc((disk_name_len+1)*sizeof(char));
			if (name == NULL)
			{
				die("disk: couldn't malloc for new name string.");
			}
		}
		strncpy(name, disk_name.name, disk_name_len+1);
	}
	return disk;
}

int disk_count_impl()
{
	return perfstat_disk(NULL, NULL, sizeof(perfstat_disk_t), 0);
}

perfstat_disk_total_t* disk_total_impl()
{
	perfstat_disk_total_t* disk_total = (perfstat_disk_total_t*)safemalloc(sizeof(perfstat_disk_total_t));
	if (disk_total == NULL)
	{
		die("disk_total: unable to malloc");
	}

	if (perfstat_disk_total(NULL, disk_total, sizeof(perfstat_disk_total_t), 1) == -1)
	{
		safefree(disk_total);
		die("disk_total: failed");
	}
	return disk_total;
}

/* pack a number of (struct perfstat_disk_t) into an array of hashes
 * and put a reference to this array onto Perl stack
 */
void XS_pack_my_disk_tPtr(SV *st, my_disk_t *q)
{
	AV *av = newAV();
	SV *sv;
	perfstat_disk_t *p;
	int i;
	for (i = 0, p = q->data; i < (q->size); i++, p++)
	{
		HV *hv = newHV();

		PACK_PV(name,0);
		PACK_PV(description,0);
		PACK_PV(vgname,0);
		PACK_UV(size);
		PACK_UV(free);
		PACK_UV(bsize);
		PACK_UV(xrate);
		PACK_UV(xfers);
		PACK_UV(wblks);
		PACK_UV(rblks);
		PACK_UV(qdepth);
		PACK_UV(time);

		av_push(av, newRV_noinc((SV*)hv));
	}

	/* put ref to hv onto stack */
	sv = newSVrv(st, NULL);
	SvREFCNT_dec(sv);
	SvRV(st) = (SV*)av;
}

/* pack struct perfstat_disk_total_t into a hash
 * and put a reference to this hash onto Perl stack
 */
void XS_pack_perfstat_disk_total_tPtr(SV *st, perfstat_disk_total_t *p)
{
	HV *hv = newHV();
	SV *sv;

	PACK_IV(number);
	PACK_UV(size);
	PACK_UV(free);
	PACK_UV(xrate);
	PACK_UV(xfers);
	PACK_UV(wblks);
	PACK_UV(rblks);
	PACK_UV(time);

	/* put ref to hv onto stack */
	sv = newSVrv(st, NULL);
	SvREFCNT_dec(sv);
	SvRV(st) = (SV*)hv;
}


