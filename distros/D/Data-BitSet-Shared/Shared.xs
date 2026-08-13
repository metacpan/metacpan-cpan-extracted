#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "bitset.h"

#define EXTRACT_BS(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::BitSet::Shared")) \
        croak("Expected a Data::BitSet::Shared object"); \
    BsHandle *h = INT2PTR(BsHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::BitSet::Shared object"); \
    BsHandle *h0 = h; PERL_UNUSED_VAR(h0); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code. EXTRACT_BS's
 * sv_2mortal(SvREFCNT_inc(...)) pin only blocks REFCOUNT-driven destruction;
 * an explicit $obj->DESTROY frees the handle regardless and zeroes the IV.
 * The same Perl can also REPLACE the invocant ($obj = 42 mutates ST(0),
 * because Perl passes aliases), hence the SvROK re-check.
 *
 * No instance method needs it today: every index/value argument is a plain
 * typemap UV, which xsubpp converts in INPUT, BEFORE PREINIT's EXTRACT_BS
 * runs. It is defined for the method that eventually converts an SV after
 * extracting the handle. */
#define REEXTRACT_BS(sv) \
    if (!SvROK(sv)) \
        croak("Data::BitSet::Shared object was replaced during the call"); \
    h = INT2PTR(BsHandle*, SvIV(SvRV(sv))); \
    if (h != h0) croak("Data::BitSet::Shared object replaced or destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

#define CHECK_BIT(h, bit) \
    if ((UV)(bit) >= (h)->hdr->capacity) \
        croak("bit %" UVuf " out of range (capacity %" UVuf ")", (UV)(bit), (UV)(h)->hdr->capacity)

MODULE = Data::BitSet::Shared  PACKAGE = Data::BitSet::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, capacity, ...)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[BS_ERR_BUFLEN];
  CODE:
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    BsHandle *h = bs_create(p, capacity, mode, errbuf);
    if (!h) croak("Data::BitSet::Shared->new: %s", errbuf[0] ? errbuf : "out of memory");
    /* Re-read the class PV at the point of use: xsubpp captured it in INPUT,
     * before the argument magic above ran, and that magic can realloc/free
     * the PV, leaving MAKE_OBJ to bless into a stale (or reused) buffer.
     * SvPV_nolen, not SvPV_nomg: an overloaded class must re-stringify. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    SV *name
    UV capacity
  PREINIT:
    char errbuf[BS_ERR_BUFLEN];
  CODE:
    /* Take the name as SV and capture its PV here, AFTER xsubpp's INPUT
     * conversion of capacity has run: a T_PV name is captured during INPUT,
     * i.e. before SvUV(ST(2)) get-magic, which could realloc/free that PV. */
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;
    BsHandle *h = bs_create_memfd(nm, capacity, errbuf);
    if (!h) croak("Data::BitSet::Shared->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    /* Re-read the class PV at the point of use (see new() above): capacity's
     * INPUT conversion and the name magic both ran after xsubpp captured
     * class. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[BS_ERR_BUFLEN];
  CODE:
    BsHandle *h = bs_open_fd(fd, errbuf);
    if (!h) croak("Data::BitSet::Shared->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    /* Re-read the class PV at the point of use (see new() above): fd's INPUT
     * conversion ran get-magic after xsubpp captured class. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_readonly(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[BS_ERR_BUFLEN];
  CODE:
    /* Open a FROZEN (sealed) file read-only: O_RDONLY + PROT_READ, no lock
       ever.  A sealed file is immutable and no read path writes the mapping,
       so queries take no reader-slot / rwlock traffic and any number of
       processes can share one PROT_READ mapping (same architecture; the
       magic rejects a wrong-endian file). */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    if (!p) croak("Data::BitSet::Shared->new_readonly: path is required");
    BsHandle *h = bs_open_readonly(p, errbuf);
    if (!h) croak("Data::BitSet::Shared->new_readonly: %s", errbuf);
    /* Re-read the class PV at the point of use (see new() above): path's
     * get-magic above could have run Perl code that reallocs/frees it.
     * BitSet has no REREAD_CLASS macro -- inlined here as elsewhere in this file. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!sv_isobject(self) || !sv_derived_from(self, "Data::BitSet::Shared")) return;
    BsHandle *h = INT2PTR(BsHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    bs_destroy(h);

IV
test(self, bit)
    SV *self
    UV bit
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    CHECK_BIT(h, bit);
    RETVAL = bs_test(h, bit);
  OUTPUT:
    RETVAL

IV
set(self, bit)
    SV *self
    UV bit
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    if (h->readonly) croak("Data::BitSet::Shared->set: bitset is frozen (read-only)");
    CHECK_BIT(h, bit);
    /* Re-check the live shared header immediately before the CAS: BitSet has no
     * rwlock to serialize against a PEER process calling ->freeze between our
     * readonly check and this write, so this atomic load is the closest
     * available analog to the rest of the family's post-wrlock sealed re-check. */
    if (__atomic_load_n(&h->hdr->sealed, __ATOMIC_ACQUIRE))
        croak("Data::BitSet::Shared->set: bitset is frozen (read-only)");
    RETVAL = bs_set(h, bit);
  OUTPUT:
    RETVAL

IV
clear(self, bit)
    SV *self
    UV bit
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    if (h->readonly) croak("Data::BitSet::Shared->clear: bitset is frozen (read-only)");
    CHECK_BIT(h, bit);
    if (__atomic_load_n(&h->hdr->sealed, __ATOMIC_ACQUIRE))
        croak("Data::BitSet::Shared->clear: bitset is frozen (read-only)");
    RETVAL = bs_clear(h, bit);
  OUTPUT:
    RETVAL

IV
toggle(self, bit)
    SV *self
    UV bit
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    if (h->readonly) croak("Data::BitSet::Shared->toggle: bitset is frozen (read-only)");
    CHECK_BIT(h, bit);
    if (__atomic_load_n(&h->hdr->sealed, __ATOMIC_ACQUIRE))
        croak("Data::BitSet::Shared->toggle: bitset is frozen (read-only)");
    RETVAL = bs_toggle(h, bit);
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    RETVAL = (UV)bs_count(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    RETVAL = (UV)h->hdr->capacity;
  OUTPUT:
    RETVAL

IV
any(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    RETVAL = bs_any(h);
  OUTPUT:
    RETVAL

IV
none(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    RETVAL = bs_none(h);
  OUTPUT:
    RETVAL

void
fill(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    if (h->readonly) croak("Data::BitSet::Shared->fill: bitset is frozen (read-only)");
    if (__atomic_load_n(&h->hdr->sealed, __ATOMIC_ACQUIRE))
        croak("Data::BitSet::Shared->fill: bitset is frozen (read-only)");
    bs_fill(h);

void
zero(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    if (h->readonly) croak("Data::BitSet::Shared->zero: bitset is frozen (read-only)");
    if (__atomic_load_n(&h->hdr->sealed, __ATOMIC_ACQUIRE))
        croak("Data::BitSet::Shared->zero: bitset is frozen (read-only)");
    bs_zero(h);

void
freeze(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    if (h->readonly) croak("Data::BitSet::Shared->freeze: cannot freeze a read-only handle");
    if (bs_freeze(h) != 0) croak("Data::BitSet::Shared->freeze: msync: %s", strerror(errno));
    h->readonly = 1;   /* this handle now rejects mutation too (the file is sealed) */

UV
frozen(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    RETVAL = __atomic_load_n(&h->hdr->sealed, __ATOMIC_ACQUIRE) ? 1 : 0;
  OUTPUT:
    RETVAL

UV
readonly(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    RETVAL = h->readonly ? 1 : 0;
  OUTPUT:
    RETVAL

SV *
first_set(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    int64_t r = bs_first_set(h);
    RETVAL = (r >= 0) ? newSViv((IV)r) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
first_clear(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    int64_t r = bs_first_clear(h);
    RETVAL = (r >= 0) ? newSViv((IV)r) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    if (!h->readonly && bs_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class) && sv_derived_from(self_or_class, "Data::BitSet::Shared")) {
        BsHandle *h = INT2PTR(BsHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        p = h->path;
    } else {
        if (items < 2) croak("Usage: ...->unlink($path)");
        p = SvPV_nolen(ST(1));
    }
    if (!p) croak("cannot unlink anonymous or memfd object");
    if (unlink(p) != 0 && errno != ENOENT) croak("unlink(%s): %s", p, strerror(errno));

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    HV *hv = newHV();
    hv_store(hv, "capacity", 8, newSVuv((UV)h->hdr->capacity), 0);
    hv_store(hv, "count", 5, newSVuv((UV)bs_count(h)), 0);
    hv_store(hv, "sets", 4, newSVuv((UV)__atomic_load_n(&h->hdr->stat_sets, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "clears", 6, newSVuv((UV)__atomic_load_n(&h->hdr->stat_clears, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "toggles", 7, newSVuv((UV)__atomic_load_n(&h->hdr->stat_toggles, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "frozen", 6, newSVuv(__atomic_load_n(&h->hdr->sealed, __ATOMIC_ACQUIRE) ? 1 : 0), 0);
    hv_store(hv, "readonly", 8, newSVuv(h->readonly ? 1 : 0), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
to_string(self, ...)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    uint32_t mw = bs_max_words(h);
    uint64_t cap = h->hdr->capacity;
    uint32_t nw = h->hdr->num_words;
    if (nw > mw) nw = mw;                                /* bound word loop against mapping */
    if (cap > (uint64_t)nw * 64) cap = (uint64_t)nw * 64; /* bound alloc/length against mapping */
    char *buf;
    Newx(buf, cap + 1, char);
    SAVEFREEPV(buf);  /* freed on scope exit, incl. a croak from newSVpvn (OOM) */
    uint64_t idx = 0;
    for (uint32_t w = 0; w < nw && idx < cap; w++) {
        uint64_t word = __atomic_load_n(&h->data[w], __ATOMIC_RELAXED);
        for (int b = 0; b < 64 && idx < cap; b++, idx++)
            buf[idx] = (word >> b) & 1 ? '1' : '0';
    }
    buf[cap] = '\0';
    RETVAL = newSVpvn(buf, cap);
  OUTPUT:
    RETVAL
