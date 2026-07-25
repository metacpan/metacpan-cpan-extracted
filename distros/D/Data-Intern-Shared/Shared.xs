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
    if (!h) croak("Attempted to use a destroyed Data::Intern::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code (tied/overloaded
 * argument magic, tied-array fetches).  That code may call $obj->DESTROY
 * explicitly, which frees the handle and zeroes the IV; EXTRACT's mortal
 * pins the referent only against refcount-driven destruction, not an
 * explicit DESTROY, so the local `h` would dangle.  Used only where magic
 * can actually intervene between EXTRACT and the first use of h. */
#define REEXTRACT(sv) \
    h = INT2PTR(SiHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Data::Intern::Shared object destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Intern::Shared  PACKAGE = Data::Intern::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, max_strings, arena_bytes = 0, ...)
    const char *class
    SV *path
    UV max_strings
    UV arena_bytes
  PREINIT:
    char errbuf[SI_ERR_BUFLEN];
  CODE:
    /* Resolve the optional trailing mode arg BEFORE capturing the path PV:
       its get-magic can run Perl code that reallocs/frees path's PV, so the
       PV must be captured last, immediately before si_create() uses it. */
    /* Opt-in file mode for cross-user sharing; default 0600 (owner-only). */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    if (max_strings > SI_MAX_STRINGS) croak("Data::Intern::Shared->new: max_strings exceeds 2^30");
    if (arena_bytes > UINT32_MAX) croak("Data::Intern::Shared->new: arena_bytes exceeds 2^32");
    SiHandle *h = si_create(p, (uint32_t)max_strings, (uint32_t)arena_bytes, mode, errbuf);
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
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
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
    REEXTRACT(self);
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
    REEXTRACT(self);
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
        char *tmp = NULL; uint32_t tl = 0; int found = 0;
        /* id, reverse[id] and the arena length prefix are all file-stored and
         * attacker-controlled; bound each before dereferencing so a corrupted
         * segment yields undef instead of an out-of-bounds read/trap. Valid
         * data always satisfies off+4+len <= arena_used, so behavior is
         * unchanged in normal use. */
        /* count/arena_used are mutable peer-writable header words; clamp each to
         * the cached physical array size before using it as the id / offset
         * bound, so a corrupted over-large counter cannot admit an OOB index. */
        uint32_t count = h->hdr->count;
        if (count > h->max_strings) count = h->max_strings;
        if (id < count) {
            uint32_t off = h->reverse[id];
            uint32_t used = h->hdr->arena_used;
            if (used > h->arena_bytes) used = h->arena_bytes;
            if (off <= used && used - off >= sizeof(uint32_t)) {
                uint32_t l;
                const char *str = si_arena_str(h, off, &l);
                if (l <= used - off - (uint32_t)sizeof(uint32_t)) {
                    found = 1; tl = l;
                    /* Copy out with a non-croaking malloc so the SV can be
                     * built AFTER unlocking: newSVpvn can croak on OOM, and a
                     * croak while holding the rdlock would leak it and wedge
                     * every writer. */
                    if (l) { tmp = (char *)malloc(l); if (tmp) memcpy(tmp, str, l); }
                }
            }
        }
        si_rwlock_rdunlock(h);
        if (!found)          RETVAL = &PL_sv_undef;
        else if (tl == 0)    RETVAL = newSVpvn("", 0);
        else if (tmp)      { RETVAL = newSVpvn(tmp, tl); free(tmp); }
        else croak("Data::Intern::Shared->string: out of memory");
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
    REEXTRACT(self);
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
        uint32_t count, max_strings, hash_slots, arena_used, arena_bytes;
        uint64_t ops;
        /* Snapshot the header fields under the lock; do all (croak-capable) Perl
           allocation after releasing it -- an OOM in newHV/newSVuv must never
           strand the read lock. */
        si_rwlock_rdlock(h);
        SiHeader *hd = h->hdr;
        count       = hd->count;
        max_strings = hd->max_strings;
        hash_slots  = hd->hash_slots;
        arena_used  = hd->arena_used;
        arena_bytes = hd->arena_bytes;
        ops         = hd->stat_ops;
        si_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "count",       newSVuv(count));
        hv_stores(hv, "max_strings", newSVuv(max_strings));
        hv_stores(hv, "hash_slots",  newSVuv(hash_slots));
        hv_stores(hv, "hash_load",   newSVnv((double)count / (double)hash_slots));
        hv_stores(hv, "arena_used",  newSVuv(arena_used));
        hv_stores(hv, "arena_bytes", newSVuv(arena_bytes));
        hv_stores(hv, "arena_load",  newSVnv((double)arena_used / (double)arena_bytes));
        hv_stores(hv, "ops",         newSVuv(ops));
        hv_stores(hv, "mmap_size",   newSVuv((UV)h->mmap_size));
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
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
