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
    if (!h) croak("Attempted to use a destroyed Data::BitSet::Shared object")

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
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[BS_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    BsHandle *h = bs_create(p, capacity, errbuf);
    if (!h) croak("Data::BitSet::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[BS_ERR_BUFLEN];
  CODE:
    BsHandle *h = bs_create_memfd(name, capacity, errbuf);
    if (!h) croak("Data::BitSet::Shared->new_memfd: %s", errbuf);
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
    if (!h) croak("Data::BitSet::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
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
    CHECK_BIT(h, bit);
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
    CHECK_BIT(h, bit);
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
    CHECK_BIT(h, bit);
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
    bs_fill(h);

void
zero(self)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    bs_zero(h);

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
    if (bs_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        BsHandle *h = INT2PTR(BsHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        p = h->path;
    } else {
        if (items < 2) croak("Usage: ...->unlink($path)");
        p = SvPV_nolen(ST(1));
    }
    if (!p) croak("cannot unlink anonymous or memfd object");
    if (unlink(p) != 0) croak("unlink(%s): %s", p, strerror(errno));

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
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
to_string(self, ...)
    SV *self
  PREINIT:
    EXTRACT_BS(self);
  CODE:
    uint64_t cap = h->hdr->capacity;
    uint32_t nw = h->hdr->num_words;
    char *buf;
    Newx(buf, cap + 1, char);
    uint64_t idx = 0;
    for (uint32_t w = 0; w < nw && idx < cap; w++) {
        uint64_t word = __atomic_load_n(&h->data[w], __ATOMIC_RELAXED);
        for (int b = 0; b < 64 && idx < cap; b++, idx++)
            buf[idx] = (word >> b) & 1 ? '1' : '0';
    }
    buf[cap] = '\0';
    RETVAL = newSVpvn(buf, cap);
    Safefree(buf);
  OUTPUT:
    RETVAL
