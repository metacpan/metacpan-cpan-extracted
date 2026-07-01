#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "intern.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Intern::Shared")) \
        croak("Expected a Data::Intern::Shared object"); \
    SiHandle *h = INT2PTR(SiHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Intern::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Intern::Shared  PACKAGE = Data::Intern::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, max_strings, arena_bytes = 0)
    const char *class
    SV *path
    UV max_strings
    UV arena_bytes
  PREINIT:
    char errbuf[SI_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    if (max_strings > SI_MAX_STRINGS) croak("Data::Intern::Shared->new: max_strings exceeds 2^30");
    if (arena_bytes > UINT32_MAX) croak("Data::Intern::Shared->new: arena_bytes exceeds 2^32");
    SiHandle *h = si_create(p, (uint32_t)max_strings, (uint32_t)arena_bytes, errbuf);
    if (!h) croak("Data::Intern::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, max_strings, arena_bytes = 0)
    const char *class
    SV *name
    UV max_strings
    UV arena_bytes
  PREINIT:
    char errbuf[SI_ERR_BUFLEN];
  CODE:
    const char *nm = SvOK(name) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (max_strings > SI_MAX_STRINGS) croak("Data::Intern::Shared->new_memfd: max_strings exceeds 2^30");
    if (arena_bytes > UINT32_MAX) croak("Data::Intern::Shared->new_memfd: arena_bytes exceeds 2^32");
    SiHandle *h = si_create_memfd(nm, (uint32_t)max_strings, (uint32_t)arena_bytes, errbuf);
    if (!h) croak("Data::Intern::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[SI_ERR_BUFLEN];
  CODE:
    SiHandle *h = si_open_fd(fd, errbuf);
    if (!h) croak("Data::Intern::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Intern::Shared")) {
        SiHandle *h = INT2PTR(SiHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); si_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    si_rwlock_rdlock(h);
    RETVAL = h->hdr->count;
    si_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

UV
max_strings(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->max_strings;
  OUTPUT:
    RETVAL

UV
arena_bytes(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->arena_bytes;
  OUTPUT:
    RETVAL

UV
arena_used(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    si_rwlock_rdlock(h);
    RETVAL = h->hdr->arena_used;
    si_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    si_rwlock_wrlock(h);
    si_clear_locked(h);
    si_rwlock_wrunlock(h);

SV *
intern(self, str)
    SV *self
    SV *str
  PREINIT:
    EXTRACT(self);
    STRLEN n;
    const char *s;
    int64_t id;
  CODE:
    s = SvPVbyte(str, n);
    si_rwlock_wrlock(h);
    id = si_intern_locked(h, s, n);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    si_rwlock_wrunlock(h);
    RETVAL = (id < 0) ? &PL_sv_undef : newSVuv((UV)id);
  OUTPUT:
    RETVAL

SV *
id_of(self, str)
    SV *self
    SV *str
  PREINIT:
    EXTRACT(self);
    STRLEN n;
    const char *s;
    uint32_t id;
  CODE:
    s = SvPVbyte(str, n);
    si_rwlock_rdlock(h);
    int found = si_id_of_locked(h, s, n, &id);
    si_rwlock_rdunlock(h);
    RETVAL = found ? newSVuv(id) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
string(self, id)
    SV *self
    UV id
  PREINIT:
    EXTRACT(self);
  CODE:
    si_rwlock_rdlock(h);
    {
        SV *out = &PL_sv_undef;
        if (id < h->hdr->count) {
            uint32_t l;
            const char *str = si_arena_str(h, h->reverse[id], &l);
            out = newSVpvn(str, l);
        }
        si_rwlock_rdunlock(h);
        RETVAL = out;
    }
  OUTPUT:
    RETVAL

bool
exists(self, str)
    SV *self
    SV *str
  PREINIT:
    EXTRACT(self);
    STRLEN n;
    const char *s;
    uint32_t id;
  CODE:
    s = SvPVbyte(str, n);
    si_rwlock_rdlock(h);
    RETVAL = si_id_of_locked(h, s, n, &id);
    si_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        HV *hv = newHV();
        si_rwlock_rdlock(h);
        SiHeader *hd = h->hdr;
        hv_stores(hv, "count",       newSVuv(hd->count));
        hv_stores(hv, "max_strings", newSVuv(hd->max_strings));
        hv_stores(hv, "hash_slots",  newSVuv(hd->hash_slots));
        hv_stores(hv, "hash_load",   newSVnv((double)hd->count / (double)hd->hash_slots));
        hv_stores(hv, "arena_used",  newSVuv(hd->arena_used));
        hv_stores(hv, "arena_bytes", newSVuv(hd->arena_bytes));
        hv_stores(hv, "arena_load",  newSVnv((double)hd->arena_used / (double)hd->arena_bytes));
        hv_stores(hv, "ops",         newSVuv(hd->stat_ops));
        hv_stores(hv, "mmap_size",   newSVuv((UV)h->mmap_size));
        si_rwlock_rdunlock(h);
        RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

int
memfd(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (si_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Intern::Shared")) {
        SiHandle *h = INT2PTR(SiHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && SvOK(ST(1))) {
        unlink(SvPV_nolen(ST(1)));
    }
