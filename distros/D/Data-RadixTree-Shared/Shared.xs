#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "radix.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::RadixTree::Shared")) \
        croak("Expected a Data::RadixTree::Shared object"); \
    RdxHandle *h = INT2PTR(RdxHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::RadixTree::Shared object"); \
    RdxHandle *h0 = h; PERL_UNUSED_VAR(h0); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code (tied/overloaded
 * argument magic, tied-array fetches).  That code may call $obj->DESTROY
 * explicitly, which frees the handle and zeroes the IV; EXTRACT's mortal
 * pins the referent only against refcount-driven destruction, not an
 * explicit DESTROY, so the local `h` would dangle.  Used only where magic
 * can actually intervene between EXTRACT and the first use of h. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::RadixTree::Shared object was replaced during the call"); \
    h = INT2PTR(RdxHandle*, SvIV(SvRV(sv))); \
    if (h != h0) croak("Data::RadixTree::Shared object replaced or destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::RadixTree::Shared  PACKAGE = Data::RadixTree::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, node_capacity = 4096, arena_capacity = 65536, ...)
    const char *class
    SV *path
    UV node_capacity
    UV arena_capacity
  PREINIT:
    char errbuf[RDX_ERR_BUFLEN];
  CODE:
    /* Optional 5th arg: file mode for a newly-created file-backed segment
     * (default 0600, owner-only). Pass e.g. 0660 to opt into cross-user
     * sharing. Ignored for anonymous/existing segments. */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    /* Capture the path PV only AFTER get-magic on the later optional args
     * above has run: SvGETMAGIC(ST(4)) may realloc/free the PV that
     * SvPV_nolen(path) returns, so the capture must stay last. */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    RdxHandle *h = rdx_create(p, (uint64_t)node_capacity, (uint64_t)arena_capacity, mode, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::RadixTree::Shared->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, node_capacity = 4096, arena_capacity = 65536)
    const char *class
    SV *name
    UV node_capacity
    UV arena_capacity
  PREINIT:
    char errbuf[RDX_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    RdxHandle *h = rdx_create_memfd(nm, (uint64_t)node_capacity, (uint64_t)arena_capacity, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::RadixTree::Shared->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[RDX_ERR_BUFLEN];
  CODE:
    RdxHandle *h = rdx_open_fd(fd, errbuf);
    if (!h) croak("Data::RadixTree::Shared->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_readonly(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[RDX_ERR_BUFLEN];
  CODE:
    /* Open a FROZEN (sealed) file read-only: O_RDONLY + PROT_READ, no lock
       ever.  A sealed file is immutable and no read path writes the mapping,
       so queries take no reader-slot / rwlock traffic and any number of
       processes can share one PROT_READ mapping (same architecture; the
       magic rejects a wrong-endian file). */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    if (!p) croak("Data::RadixTree::Shared->new_readonly: path is required");
    RdxHandle *h = rdx_open_readonly(p, errbuf);
    if (!h) croak("Data::RadixTree::Shared->new_readonly: %s", errbuf);
    class = SvPV_nolen(ST(0));   /* re-read: SvGETMAGIC(path) above can run Perl that reallocs/frees ST(0)'s PV */
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::RadixTree::Shared")) {
        RdxHandle *h = INT2PTR(RdxHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); rdx_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

IV
insert(self, key, value = 1)
    SV *self
    SV *key
    UV value
  PREINIT:
    EXTRACT(self);
    STRLEN klen;
    const char *kp;
    int isnew;
  CODE:
    if (h->readonly) croak("Data::RadixTree::Shared->insert: tree is frozen (read-only)");
    /* Resolve key bytes BEFORE locking: SvPVbyte croaks on wide chars, and a
       croak must never happen while holding the lock. */
    kp = SvPVbyte(key, klen);
    REEXTRACT(self);
    rdx_rwlock_wrlock(h);
    if (h->hdr->sealed) { rdx_rwlock_wrunlock(h); croak("Data::RadixTree::Shared->insert: tree is frozen (read-only)"); }
    if (!rdx_insert_has_room(h, (uint32_t)klen)) {
        rdx_rwlock_wrunlock(h);   /* release BEFORE croak */
        croak("Data::RadixTree::Shared->insert: capacity exhausted "
              "(node pool or label arena full; grow node/arena capacity)");
    }
    isnew = rdx_insert_locked(h, (const uint8_t *)kp, (uint32_t)klen, (uint64_t)value);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    rdx_rwlock_wrunlock(h);
    RETVAL = (IV)isnew;
  OUTPUT:
    RETVAL

SV *
lookup(self, key)
    SV *self
    SV *key
  PREINIT:
    EXTRACT(self);
    STRLEN klen;
    const char *kp;
    uint64_t val;
    int found;
  CODE:
    kp = SvPVbyte(key, klen);   /* before the lock */
    REEXTRACT(self);
    if (h->readonly) {          /* frozen: immutable tree, no lock needed */
        found = rdx_lookup_locked(h, (const uint8_t *)kp, (uint32_t)klen, &val);
    } else {
        rdx_rwlock_rdlock(h);
        found = rdx_lookup_locked(h, (const uint8_t *)kp, (uint32_t)klen, &val);
        rdx_rwlock_rdunlock(h);
    }
    RETVAL = found ? newSVuv((UV)val) : &PL_sv_undef;
  OUTPUT:
    RETVAL

bool
exists(self, key)
    SV *self
    SV *key
  PREINIT:
    EXTRACT(self);
    STRLEN klen;
    const char *kp;
  CODE:
    kp = SvPVbyte(key, klen);   /* before the lock */
    REEXTRACT(self);
    if (h->readonly) {          /* frozen: immutable tree, no lock needed */
        RETVAL = rdx_lookup_locked(h, (const uint8_t *)kp, (uint32_t)klen, NULL) ? 1 : 0;
    } else {
        rdx_rwlock_rdlock(h);
        RETVAL = rdx_lookup_locked(h, (const uint8_t *)kp, (uint32_t)klen, NULL) ? 1 : 0;
        rdx_rwlock_rdunlock(h);
    }
  OUTPUT:
    RETVAL

SV *
longest_prefix(self, key)
    SV *self
    SV *key
  PREINIT:
    EXTRACT(self);
    STRLEN klen;
    const char *kp;
    uint64_t val;
    int found;
  CODE:
    kp = SvPVbyte(key, klen);   /* before the lock */
    REEXTRACT(self);
    if (h->readonly) {          /* frozen: immutable tree, no lock needed */
        found = rdx_longest_prefix_locked(h, (const uint8_t *)kp, (uint32_t)klen, &val);
    } else {
        rdx_rwlock_rdlock(h);
        found = rdx_longest_prefix_locked(h, (const uint8_t *)kp, (uint32_t)klen, &val);
        rdx_rwlock_rdunlock(h);
    }
    RETVAL = found ? newSVuv((UV)val) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
delete(self, key)
    SV *self
    SV *key
  PREINIT:
    EXTRACT(self);
    STRLEN klen;
    const char *kp;
    int removed;
  CODE:
    if (h->readonly) croak("Data::RadixTree::Shared->delete: tree is frozen (read-only)");
    kp = SvPVbyte(key, klen);   /* before the lock */
    REEXTRACT(self);
    rdx_rwlock_wrlock(h);
    if (h->hdr->sealed) { rdx_rwlock_wrunlock(h); croak("Data::RadixTree::Shared->delete: tree is frozen (read-only)"); }
    removed = rdx_delete_locked(h, (const uint8_t *)kp, (uint32_t)klen);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    rdx_rwlock_wrunlock(h);
    RETVAL = (IV)removed;
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) croak("Data::RadixTree::Shared->clear: tree is frozen (read-only)");
    rdx_rwlock_wrlock(h);
    if (h->hdr->sealed) { rdx_rwlock_wrunlock(h); croak("Data::RadixTree::Shared->clear: tree is frozen (read-only)"); }
    rdx_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    rdx_rwlock_wrunlock(h);

void
freeze(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) croak("Data::RadixTree::Shared->freeze: cannot freeze a read-only handle");
    if (rdx_freeze(h) != 0) croak("Data::RadixTree::Shared->freeze: msync: %s", strerror(errno));
    h->readonly = 1;   /* this handle now rejects mutation too (the file is sealed) */

UV
frozen(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->sealed ? 1 : 0;
  OUTPUT:
    RETVAL

UV
readonly(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->readonly ? 1 : 0;
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) {          /* frozen: immutable tree, no lock needed */
        RETVAL = (UV)h->hdr->keys;
    } else {
        rdx_rwlock_rdlock(h);
        RETVAL = (UV)h->hdr->keys;
        rdx_rwlock_rdunlock(h);
    }
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t keys, ops;
        uint32_t node_used, node_cap, arena_used, arena_cap;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSV* can never strand the lock. */
        if (!h->readonly) rdx_rwlock_rdlock(h);   /* frozen: immutable, no lock */
        keys       = h->hdr->keys;
        node_used  = h->hdr->node_used;
        node_cap   = h->hdr->node_cap;
        arena_used = h->hdr->arena_used;
        arena_cap  = h->hdr->arena_cap;
        ops        = h->hdr->stat_ops;
        if (!h->readonly) rdx_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "keys",           newSVuv((UV)keys));
        hv_stores(hv, "nodes_used",     newSVuv((UV)node_used));
        hv_stores(hv, "nodes_capacity", newSVuv((UV)node_cap));
        hv_stores(hv, "arena_used",     newSVuv((UV)arena_used));
        hv_stores(hv, "arena_capacity", newSVuv((UV)arena_cap));
        hv_stores(hv, "ops",            newSVuv((UV)ops));
        hv_stores(hv, "mmap_size",      newSVuv((UV)h->mmap_size));
        hv_stores(hv, "frozen",         newSVuv(h->hdr->sealed ? 1 : 0));
        hv_stores(hv, "readonly",       newSVuv(h->readonly ? 1 : 0));
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
    if (!h->readonly && rdx_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::RadixTree::Shared")) {
        RdxHandle *h = INT2PTR(RdxHandle*, SvIV(SvRV(self)));
        if (h && h->path && unlink(h->path) != 0 && errno != ENOENT)
            croak("Data::RadixTree::Shared->unlink(%s): %s", h->path, strerror(errno));
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        {
            const char *up = SvPV_nolen(ST(1));
            if (unlink(up) != 0 && errno != ENOENT)
                croak("Data::RadixTree::Shared->unlink(%s): %s", up, strerror(errno));
        }
    }
