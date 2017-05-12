#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif
#include <devstat.h>

struct bsd_devstat {
	kvm_t *kd;
	struct statinfo	stats;
	struct devinfo  dinfo;
};
typedef struct bsd_devstat	bsd_devstat;


#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define XS_STRUCT2OBJ(sv, class, obj) \
    if (obj == NULL) { \
        sv_setsv(sv, &PL_sv_undef); \
    } else { \
        sv_setref_pv(sv, class, (void *) obj); \
    }

bsd_devstat*
bsd_devstat_new(void)
{
	kvm_t *kd = NULL;	/* may support non-NULL value later. */
	if (devstat_checkversion(kd) == -1) return NULL;
	bsd_devstat* p = calloc(1, sizeof(bsd_devstat));
	p->kd = kd;
	p->stats.dinfo = &p->dinfo;
	if (devstat_getdevs(p->kd, &p->stats) == -1) return NULL;
	return p;
}

void
bsd_devstat_free(bsd_devstat *self)
{
	if (self) {
		free(self);
	}
}

#include "compstat.h"

#define HVpv(rh, key, pv)	hv_store(rh, key, strlen(key), newSVpv(pv, 0), 0)
#define HViv(rh, key, iv)	hv_store(rh, key, strlen(key), newSViv(iv), 0)

MODULE = BSD::devstat  PACKAGE = BSD::devstat

bsd_devstat*
BSD::devstat::new()
CODE:
    bsd_devstat* self = bsd_devstat_new();
    RETVAL = self;
OUTPUT:
    RETVAL

int
numdevs(bsd_devstat* self)
CODE:
    RETVAL = (self->stats.dinfo)->numdevs;
OUTPUT:
    RETVAL

HV*
devices(bsd_devstat* self, int index)
CODE:
    if (index < 0 || index >= self->stats.dinfo->numdevs) {
        croak("Invalid index range");
    }
    HV *rh = (HV*)sv_2mortal((SV*)newHV());
    struct devstat dev = self->stats.dinfo->devices[index];
    HVpv(rh, "device_name",		dev.device_name);
    HViv(rh, "unit_number",		dev.unit_number);
    HViv(rh, "bytes_read",		dev.bytes[DEVSTAT_READ]);
    HViv(rh, "bytes_write",		dev.bytes[DEVSTAT_WRITE]);
    HViv(rh, "bytes_free",		dev.bytes[DEVSTAT_FREE]);
    HViv(rh, "operations_read",		dev.operations[DEVSTAT_READ]);
    HViv(rh, "operations_write",	dev.operations[DEVSTAT_WRITE]);
    HViv(rh, "operations_free",		dev.operations[DEVSTAT_FREE]);
    HViv(rh, "operations_other",	dev.operations[DEVSTAT_NO_DATA]);
    HViv(rh, "duration_read_sec",	dev.duration[DEVSTAT_READ].sec);
    HViv(rh, "duration_read_frac",	dev.duration[DEVSTAT_READ].frac);
    HViv(rh, "duration_write_sec",	dev.duration[DEVSTAT_WRITE].sec);
    HViv(rh, "duration_write_frac",	dev.duration[DEVSTAT_WRITE].frac);
    HViv(rh, "duration_free_sec",	dev.duration[DEVSTAT_FREE].sec);
    HViv(rh, "duration_free_frac",	dev.duration[DEVSTAT_FREE].frac);
    HViv(rh, "busy_time_sec",		dev.busy_time.sec);
    HViv(rh, "busy_time_frac",		dev.busy_time.frac);
    HViv(rh, "creation_time_sec",	dev.creation_time.sec);
    HViv(rh, "creation_time_frac",	dev.creation_time.frac);
    HViv(rh, "block_size",		dev.block_size);
    HViv(rh, "tag_simple",		dev.tag_types[DEVSTAT_TAG_SIMPLE]);
    HViv(rh, "tag_ordered",		dev.tag_types[DEVSTAT_TAG_ORDERED]);
    HViv(rh, "tag_head",		dev.tag_types[DEVSTAT_TAG_HEAD]);
    HViv(rh, "flags",			dev.flags);
    HViv(rh, "device_type",		dev.device_type);
    HViv(rh, "priority",		dev.priority);
    RETVAL = rh;
OUTPUT:
    RETVAL

HV*
compute_statistics(bsd_devstat* self, int index, float sec)
CODE:
    struct statinfo s1;
    struct statinfo s2;
    struct devinfo d1;
    struct devinfo d2;
    struct timespec t;
    memset(&s1, 0, sizeof(struct statinfo));
    memset(&s2, 0, sizeof(struct statinfo));
    memset(&d1, 0, sizeof(struct devinfo));
    memset(&d2, 0, sizeof(struct devinfo));
    s1.dinfo = &d1;
    s2.dinfo = &d2;
    if (index < 0 || index >= self->stats.dinfo->numdevs) {
        croak("Invalid index range");
    }
    if (sec < 0) {
        croak("Cannot accept negative second");
    }
    if (devstat_getdevs(self->kd, &s1) == -1) {
        croak("First devstat_getdevs() returns -1: %s", devstat_errbuf);
    }
    t.tv_sec = (int)(sec);
    t.tv_nsec = (long)(1000000000L * sec) % 1000000000L;
    nanosleep(&t, NULL);
    if (devstat_getdevs(self->kd, &s2) == -1) {
        croak("Second devstat_getdevs() returns -1: %s", devstat_errbuf);
    }
    HV *rh = (HV*)sv_2mortal((SV*)newHV());
    compstat(&d2.devices[index], &d1.devices[index], s2.snap_time - s1.snap_time, rh);
    RETVAL = rh;
OUTPUT:
    RETVAL

void
DESTROY(bsd_devstat* self)
CODE:
    bsd_devstat_free(self);
