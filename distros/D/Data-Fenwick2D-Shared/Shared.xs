#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "fenwick2d.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Fenwick2D::Shared")) \
        croak("Expected a Data::Fenwick2D::Shared object"); \
    F2dHandle *h = INT2PTR(F2dHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Fenwick2D::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

/* 1-based (row, col) bounds check (croaks with a clear message) */
#define CHECK_XY(x, y) \
    do { if ((x) < 1 || (x) > h->rows || (y) < 1 || (y) > h->cols) \
        croak("Data::Fenwick2D::Shared: cell (%" UVuf ",%" UVuf ") out of range 1..%" UVuf " x 1..%" UVuf, \
              (UV)(x), (UV)(y), (UV)h->rows, (UV)h->cols); } while (0)

MODULE = Data::Fenwick2D::Shared  PACKAGE = Data::Fenwick2D::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, rows = 0, cols = 0, ...)
    const char *class
    SV *path
    UV rows
    UV cols
  PREINIT:
    char errbuf[F2D_ERR_BUFLEN];
  CODE:
    if (rows < 1 || cols < 1)
        croak("Data::Fenwick2D::Shared->new: rows and cols must be >= 1");
    /* Optional 5th arg: file mode for a newly-created file-backed segment (default 0600). */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    /* Capture the path PV last, after all get-magic on the optional args:
       SvGETMAGIC(ST(4)) above could realloc/free the PV before f2d_create() uses it. */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    F2dHandle *hh = f2d_create(p, (uint64_t)rows, (uint64_t)cols, mode, errbuf);
    if (!hh) croak("Data::Fenwick2D::Shared->new: %s", errbuf);
    /* Re-read the class PV at the point of use: xsubpp captured it in INPUT,
     * before the argument magic above ran, and that magic can realloc/free
     * the PV, leaving MAKE_OBJ to bless into a stale (or reused) buffer.
     * SvPV_nolen, not SvPV_nomg: an overloaded class must re-stringify. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, rows = 0, cols = 0)
    const char *class
    SV *name
    UV rows
    UV cols
  PREINIT:
    char errbuf[F2D_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;
    if (rows < 1 || cols < 1)
        croak("Data::Fenwick2D::Shared->new_memfd: rows and cols must be >= 1");
    F2dHandle *hh = f2d_create_memfd(nm, (uint64_t)rows, (uint64_t)cols, errbuf);
    if (!hh) croak("Data::Fenwick2D::Shared->new_memfd: %s", errbuf);
    /* Re-read the class PV at the point of use (see new() above): the rows/
     * cols INPUT conversions and the name magic both ran after xsubpp
     * captured class. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[F2D_ERR_BUFLEN];
  CODE:
    F2dHandle *hh = f2d_open_fd(fd, errbuf);
    if (!hh) croak("Data::Fenwick2D::Shared->new_from_fd: %s", errbuf);
    /* Re-read the class PV at the point of use (see new() above): fd's INPUT
     * conversion ran get-magic after xsubpp captured class. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Fenwick2D::Shared")) {
        F2dHandle *h = INT2PTR(F2dHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); f2d_destroy(h); }
    }

# ---- mutation ----

void
update(self, x, y, delta)
    SV *self
    UV x
    UV y
    IV delta
  PREINIT:
    EXTRACT(self);
  CODE:
    CHECK_XY(x, y);
    f2d_rwlock_wrlock(h);
    f2d_update_locked(h, (uint64_t)x, (uint64_t)y, (int64_t)delta);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    f2d_rwlock_wrunlock(h);

IV
set(self, x, y, value)
    SV *self
    UV x
    UV y
    IV value
  PREINIT:
    EXTRACT(self);
    int64_t cur;
  CODE:
    CHECK_XY(x, y);
    f2d_rwlock_wrlock(h);
    cur = f2d_point_locked(h, (uint64_t)x, (uint64_t)y);           /* current value at (x,y) */
    f2d_update_locked(h, (uint64_t)x, (uint64_t)y, (int64_t)value - cur);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    f2d_rwlock_wrunlock(h);
    RETVAL = (IV)cur;                                              /* previous value */
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    f2d_rwlock_wrlock(h);
    f2d_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    f2d_rwlock_wrunlock(h);

# ---- query ----

IV
prefix(self, x, y)
    SV *self
    UV x
    UV y
  PREINIT:
    EXTRACT(self);
    int64_t s;
  CODE:
    if (x > h->rows || y > h->cols)
        croak("Data::Fenwick2D::Shared->prefix: (%" UVuf ",%" UVuf ") out of range 0..%" UVuf " x 0..%" UVuf,
              (UV)x, (UV)y, (UV)h->rows, (UV)h->cols);
    f2d_rwlock_rdlock(h);
    s = f2d_prefix_locked(h, (uint64_t)x, (uint64_t)y);
    f2d_rwlock_rdunlock(h);
    RETVAL = (IV)s;
  OUTPUT:
    RETVAL

IV
rect(self, x1, y1, x2, y2)
    SV *self
    UV x1
    UV y1
    UV x2
    UV y2
  PREINIT:
    EXTRACT(self);
    int64_t s;
  CODE:
    if (x1 < 1 || y1 < 1 || x2 > h->rows || y2 > h->cols || x1 > x2 || y1 > y2)
        croak("Data::Fenwick2D::Shared->rect: bad rectangle [%" UVuf ",%" UVuf "]..[%" UVuf ",%" UVuf "] (valid 1..%" UVuf " x 1..%" UVuf ")",
              (UV)x1, (UV)y1, (UV)x2, (UV)y2, (UV)h->rows, (UV)h->cols);
    f2d_rwlock_rdlock(h);
    s = f2d_rect_locked(h, (uint64_t)x1, (uint64_t)y1, (uint64_t)x2, (uint64_t)y2);
    f2d_rwlock_rdunlock(h);
    RETVAL = (IV)s;
  OUTPUT:
    RETVAL

IV
point(self, x, y)
    SV *self
    UV x
    UV y
  PREINIT:
    EXTRACT(self);
    int64_t s;
  CODE:
    CHECK_XY(x, y);
    f2d_rwlock_rdlock(h);
    s = f2d_point_locked(h, (uint64_t)x, (uint64_t)y);
    f2d_rwlock_rdunlock(h);
    RETVAL = (IV)s;
  OUTPUT:
    RETVAL

IV
total(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    int64_t s;
  CODE:
    f2d_rwlock_rdlock(h);
    s = f2d_prefix_locked(h, h->rows, h->cols);
    f2d_rwlock_rdunlock(h);
    RETVAL = (IV)s;
  OUTPUT:
    RETVAL

# ---- introspection ----

UV
rows(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->rows;
  OUTPUT:
    RETVAL

UV
cols(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->cols;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t rr, cc, ops, mmap_size;
        int64_t  tot;
        rr = h->rows; cc = h->cols;
        f2d_rwlock_rdlock(h);
        tot       = f2d_prefix_locked(h, rr, cc);
        ops       = h->hdr->stat_ops;
        f2d_rwlock_rdunlock(h);
        mmap_size = (uint64_t)h->mmap_size;

        HV *hv = newHV();
        hv_stores(hv, "rows",      newSVuv((UV)rr));
        hv_stores(hv, "cols",      newSVuv((UV)cc));
        hv_stores(hv, "total",     newSViv((IV)tot));
        hv_stores(hv, "ops",       newSVuv((UV)ops));
        hv_stores(hv, "mmap_size", newSVuv((UV)mmap_size));
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
    if (f2d_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Fenwick2D::Shared")) {
        F2dHandle *h = INT2PTR(F2dHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
