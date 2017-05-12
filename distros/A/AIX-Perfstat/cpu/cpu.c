/*
 *
 * Copyright (C) 2006 by Richard Holden
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

#include "cpu.h"
#include "../pack.h"

my_cpu_t* cpu_impl(int desired_number, char* name, int update_name)
{
	perfstat_id_t cpu_name;

	if (desired_number < 1)
	{
		die("cpu: desired_number must be at least 1.");
	}
	if (strlen(name) > (IDENTIFIER_LENGTH - 1))
	{
		die("cpu: name must be less than IDENTIFER_LENGTH chars including the trailing \'\\0\'.\n");
	}

	strncpy(cpu_name.name, name, IDENTIFIER_LENGTH);

	my_cpu_t*	cpu = (my_cpu_t*)safemalloc(sizeof(my_cpu_t));
	if (cpu == NULL)
	{
		die("cpu: malloc failed for cpu");
	}

	cpu->size = 0;
	cpu->data = (perfstat_cpu_t*)safemalloc(desired_number * sizeof(perfstat_cpu_t));
	if (cpu->data == NULL)
	{
		safefree(cpu);
		die("cpu: malloc failed for cpu->data");
	}

	if ((cpu->size = perfstat_cpu(&cpu_name, cpu->data, sizeof(perfstat_cpu_t), desired_number)) == -1 || (cpu->size == 0))
	{
		safefree(cpu->data);
		safefree(cpu);
		cpu = NULL;
	}

	if (update_name)
	{
		int name_len = strlen(name);
		int cpu_name_len = strlen(cpu_name.name);

		if (cpu_name_len > name_len)
		{
			safefree(name);
			name = (char*)safemalloc((cpu_name_len+1)*sizeof(char));
			if (name == NULL)
			{
				die("cpu: couldn't malloc for new name string.");
			}
		}
		strncpy(name, cpu_name.name, cpu_name_len+1);
	}
	return cpu;
}

int cpu_count_impl()
{
	return perfstat_cpu(NULL, NULL, sizeof(perfstat_cpu_t), 0);
}

perfstat_cpu_total_t* cpu_total_impl()
{
	perfstat_cpu_total_t* cpu_total = (perfstat_cpu_total_t*)safemalloc(sizeof(perfstat_cpu_total_t));
	if (cpu_total == NULL)
	{
		die("cpu_total: unable to malloc");
	}

	if (perfstat_cpu_total(NULL, cpu_total, sizeof(perfstat_cpu_total_t), 1) == -1)
	{
		safefree(cpu_total);
		die("cpu_total: failed");
	}
	return cpu_total;
}

/* pack a number of (struct perfstat_cpu_t) into an array of hashes
 * and put a reference to this array onto Perl stack
 */
void XS_pack_my_cpu_tPtr(SV *st, my_cpu_t *q)
{
	AV *av = newAV();
	SV *sv;
	perfstat_cpu_t *p;
	int i;

	for (i = 0, p = q->data; i < (q->size); i++, p++)
	{
		HV *hv = newHV();

		PACK_PV(name,0);
		PACK_UV(user);
		PACK_UV(sys);
		PACK_UV(idle);
		PACK_UV(wait);
		PACK_UV(pswitch);
		PACK_UV(syscall);
		PACK_UV(sysread);
		PACK_UV(syswrite);
		PACK_UV(sysfork);
		PACK_UV(sysexec);
		PACK_UV(readch);
		PACK_UV(writech);
		PACK_UV(bread);
		PACK_UV(bwrite);
		PACK_UV(lread);
		PACK_UV(lwrite);
		PACK_UV(phread);
		PACK_UV(phwrite);

		av_push(av, newRV_noinc((SV*)hv));
	}

	/* put ref to hv onto stack */
	sv = newSVrv(st, NULL);
	SvREFCNT_dec(sv);
	SvRV(st) = (SV*)av;
}

/* pack struct perfstat_cpu_total_t into a hash
 * and put a reference to this hash onto Perl stack
 */
void XS_pack_perfstat_cpu_total_tPtr(SV *st, perfstat_cpu_total_t *p)
{
	HV *hv = newHV();
	SV *sv;

	PACK_IV(ncpus);
	PACK_IV(ncpus_cfg);
	PACK_PV(description,0);
	PACK_UV(processorHZ);
	PACK_UV(user);
	PACK_UV(sys);
	PACK_UV(idle);
	PACK_UV(wait);
	PACK_UV(pswitch);
	PACK_UV(syscall);
	PACK_UV(sysread);
	PACK_UV(syswrite);
	PACK_UV(sysfork);
	PACK_UV(sysexec);
	PACK_UV(readch);
	PACK_UV(writech);
	PACK_UV(devintrs);
	PACK_UV(softintrs);
	PACK_IV(lbolt);

	/* loadavg[3] */
	{
		AV *av = newAV();
		int i;

		for (i = 0; i < 3; i++)
		{
			av_push(av, newSVuv(p->loadavg[i]));
		}
		PACK_AV(loadavg);
	}

	PACK_UV(runque);
	PACK_UV(swpque);
	PACK_UV(bread);
	PACK_UV(bwrite);
	PACK_UV(lread);
	PACK_UV(lwrite);
	PACK_UV(phread);
	PACK_UV(phwrite);

	/* put ref to hv onto stack */
	sv = newSVrv(st, NULL);
	SvREFCNT_dec(sv);
	SvRV(st) = (SV*)hv;
}
