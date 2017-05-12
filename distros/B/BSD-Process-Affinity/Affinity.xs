/*
Copyright (c) 2009, 2011 by Sergey Aleynikov.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <sys/param.h>
#include <sys/cpuset.h>

#define PANIC(msg) croak("%s: %s", msg, strerror(errno))

#define objnew(cl)								\
		SV* obj_ref;							\
		SV* obj;								\
		struct cpusetinfo* info;				\
												\
		obj_ref= newSViv(0);					\
		obj = newSVrv(obj_ref, cl);				\
												\
		Newz(0, info, 1, struct cpusetinfo);	\
		sv_setiv(obj, (IV)info);				\
		SvREADONLY_on(obj);						\

struct cpusetinfo {
	/* set is designated to */
	cpulevel_t	level;
	cpuwhich_t	which;
	id_t		id;
	/* set id */
	cpusetid_t	setid;
	/* data for it */
	cpuset_t	mask;
};

void
populate_set(struct cpusetinfo *info){
	int result;

	if (info->setid != 0){
		result = cpuset_getaffinity(CPU_LEVEL_WHICH, CPU_WHICH_CPUSET, info->setid, sizeof(info->mask), &(info->mask));
	}else{
		result = cpuset_getaffinity(CPU_LEVEL_WHICH, info->which, info->id, sizeof(info->mask), &(info->mask));
	}

	if (result != 0){
		Safefree(info);
		PANIC("Can't retrieve affinity info");
	}
}

MODULE = BSD::Process::Affinity		PACKAGE = BSD::Process::Affinity
PROTOTYPES: DISABLE

void
DESTROY(obj)
		SV* obj
	CODE:
		struct cpusetinfo* info = (struct cpusetinfo*)SvIV(SvRV(obj));
		Safefree(info);

SV *
clone(...)
	CODE:
		objnew("BSD::Process::Affinity::Cpuset");

		if (cpuset(&(info->setid)) != 0){
			Safefree(info);
			PANIC("Can't clone cpuset");
		}
		/* we're the only members of new set */
		info->level = CPU_LEVEL_CPUSET;
		info->which = CPU_WHICH_PID;
		info->id = -1;

		populate_set(info);

		RETVAL = obj_ref;
	OUTPUT:
		RETVAL

SV *
rootof_set(...)
	ALIAS:
		rootof_pid = 1
		current_set = 2
		current_pid = 3
	CODE:
		objnew("BSD::Process::Affinity::Cpuset");

		if (items > 0){
			info->id = SvIV(ST(0));
		}

		if (info->id == 0){
			info->id = -1;
		}

		switch(ix){
			case 0:
				info->level = CPU_LEVEL_ROOT;
				info->which = CPU_WHICH_CPUSET;
				break;
			case 1:
				info->level = CPU_LEVEL_ROOT;
				info->which = CPU_WHICH_PID;
				break;
			case 2:
				info->level = CPU_LEVEL_CPUSET;
				info->which = CPU_WHICH_CPUSET;
				break;
			case 3:
				info->level = CPU_LEVEL_CPUSET;
				info->which = CPU_WHICH_PID;
				break;
		}

		if (cpuset_getid(info->level, info->which, info->id, &(info->setid)) != 0){
			Safefree(info);
			PANIC("Can't get cpuset");
		}

		populate_set(info);

		RETVAL = obj_ref;
	OUTPUT:
		RETVAL

SV *
get_thread_mask(...)
	ALIAS:
		get_process_mask = 1
	CODE:
		objnew("BSD::Process::Affinity::Cpuset");

		info->level = CPU_LEVEL_WHICH;
		info->which = (ix == 0) ? CPU_WHICH_TID : CPU_WHICH_PID;

		if (items > 0){
			info->id = SvIV(ST(0));
		}

		if (info->id == 0){
			info->id = -1;
		}

		populate_set(info);

		RETVAL = obj_ref;
	OUTPUT:
		RETVAL

MODULE = BSD::Process::Affinity     PACKAGE = BSD::Process::Affinity::Cpuset

void
assign(obj, ...)
		SV* obj
	CODE:
		struct cpusetinfo* info = (struct cpusetinfo*)SvIV(SvRV(obj));

		if (info->setid == 0){
			croak("This object does not correspond to real cpuset, it's only an anonymous mask.");
		}

		id_t target = 0;
		if (items > 1){
			target = (id_t)SvIV(ST(1));
		}
		if (target == 0){
			target = -1;
		}

		if (cpuset_setid(CPU_WHICH_PID, target, info->setid) != 0){
			PANIC("Can't set thread's cpuset");
		}

void
update(obj)
		SV* obj
	CODE:
		struct cpusetinfo* info = (struct cpusetinfo*)SvIV(SvRV(obj));
		int result;

		if (info->setid != 0){
			result = cpuset_setaffinity(CPU_LEVEL_WHICH, CPU_WHICH_CPUSET, info->setid, sizeof(info->mask), &(info->mask));
		}else{
			result = cpuset_setaffinity(CPU_LEVEL_WHICH, info->which, info->id, sizeof(info->mask), &(info->mask));
		}

		if (result != 0){
			PANIC("Can't set affinity mask");
		}

int
get_cpusetid(obj)
		SV* obj
	CODE:
		struct cpusetinfo* info = (struct cpusetinfo*)SvIV(SvRV(obj));
		RETVAL = info->setid;
	OUTPUT:
		RETVAL

SV*
get(obj)
		SV* obj
	CODE:
		dSP;
		struct cpusetinfo* info = (struct cpusetinfo*)SvIV(SvRV(obj));
		UV result = 0;

		int i;
		for(i = 0; i < CPU_SETSIZE; i++){
			if (CPU_ISSET(i, &(info->mask))){
                if (i > sizeof(UV) * 8){
                    croak("Can't convert mask to number - too many bits set, got %d already set, but unsigned can hold only %d", i, sizeof(UV) * 8);
                }

				result |= ((UV)1 << i);
			}
		}

		RETVAL = newSVuv(result);
	OUTPUT:
		RETVAL

void
set(obj, num)
		SV* obj
		SV* num
    ALIAS:
        from_num = 1
	PPCODE:
		struct cpusetinfo* info = (struct cpusetinfo*)SvIV(SvRV(obj));

		CPU_ZERO(&(info->mask));

		UV input = SvUV(num);
		if (input > 0){
			int i;
			for(i = 0; i < sizeof(UV) * 8; i++){
                if (input & ((UV)1 << i)){
					if (i > CPU_SETSIZE){
						croak("Can't convert number to mask - too many bits set, expecting at most %d set, but already got %d", CPU_SETSIZE, i);
					}

					CPU_SET(i, &(info->mask));
				}
			}
		}

		XSRETURN(1);
