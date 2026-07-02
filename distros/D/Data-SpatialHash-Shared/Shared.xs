#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "sphash.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::SpatialHash::Shared")) \
        croak("Expected a Data::SpatialHash::Shared object"); \
    SpatialHandle *h = INT2PTR(SpatialHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::SpatialHash::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

#define REQUIRE_LIVE(h, idx) do { \
    if (!sph_is_live((h), (idx))) { sph_rwlock_wrunlock(h); \
        croak("invalid or freed handle %u", (unsigned)(idx)); } \
} while (0)

/* read-lock counterpart of REQUIRE_LIVE (releases the read lock before croaking) */
#define REQUIRE_LIVE_RD(h, idx) do { \
    if (!sph_is_live((h), (idx))) { sph_rwlock_rdunlock(h); \
        croak("invalid or freed handle %u", (unsigned)(idx)); } \
} while (0)

/* Shared croak message for the SPH_Q_TOOBIG cap (EMIT_QUERY, EMIT_PAIRS, each_in_radius, query_radius_many);
   takes (unsigned)SPH_MAX_QUERY_CELLS as its %u argument. */
#define SPH_TOOBIG_MSG "query region spans more than %u cells; increase cell_size or shrink the query"

/* Run a collector-filling query under the read lock, then push its values as
   mortal IVs. `CALL` must be an expression filling sph_collect_t `col`. */
#define EMIT_QUERY(CALL) do { \
    sph_collect_t col = { NULL, 0, 0 }; \
    sph_rwlock_rdlock(h); \
    int rc = (CALL); \
    sph_rwlock_rdunlock(h); \
    if (rc == SPH_Q_OOM)    { free(col.vals); croak("query: out of memory"); } \
    if (rc == SPH_Q_TOOBIG) { free(col.vals); croak(SPH_TOOBIG_MSG, (unsigned)SPH_MAX_QUERY_CELLS); } \
    EXTEND(SP, (SSize_t)col.n); \
    for (size_t i = 0; i < col.n; i++) PUSHs(sv_2mortal(newSViv((IV)col.vals[i]))); \
    free(col.vals); \
} while (0)

/* Collect pairs (flattened va,vb,...) under the read lock, then -- after the
   lock is released -- invoke `cb` once per pair. G_EVAL so a die in the callback
   still frees the buffer; re-throw after cleanup (matches each_in_radius). */
#define EMIT_PAIRS(CALL) do { \
    sph_collect_t col = { NULL, 0, 0 }; \
    sph_rwlock_rdlock(h); \
    int rc = (CALL); \
    sph_rwlock_rdunlock(h); \
    if (rc == SPH_Q_OOM)    { free(col.vals); croak("each pair: out of memory"); } \
    if (rc == SPH_Q_TOOBIG) { free(col.vals); croak(SPH_TOOBIG_MSG, (unsigned)SPH_MAX_QUERY_CELLS); } \
    for (size_t i = 0; i + 1 < col.n; i += 2) { \
        dSP; ENTER; SAVETMPS; PUSHMARK(SP); \
        XPUSHs(sv_2mortal(newSViv((IV)col.vals[i]))); \
        XPUSHs(sv_2mortal(newSViv((IV)col.vals[i+1]))); \
        PUTBACK; \
        call_sv(cb, G_VOID|G_DISCARD|G_EVAL); \
        FREETMPS; LEAVE; \
        if (SvTRUE(ERRSV)) { free(col.vals); croak_sv(ERRSV); } \
    } \
    free(col.vals); \
} while (0)

/* parse optional trailing "wrap => [Wx, Wy(, Wz)]" and "sphere => R" args;
   returns world pointer (or NULL) and sets *sphere if a sphere radius is given */
static const double *sph_parse_opts(pTHX_ SV **sp, int first, int items, double world[3], double *sphere, const char *who) {
    const double *wp = NULL;
    if ((items - first) % 2 != 0) croak("%s: odd number of option arguments", who);
    for (int ai = first; ai + 1 < items; ai += 2) {
        const char *key = SvPV_nolen(sp[ai]);
        if (strcmp(key, "wrap") == 0) {
            SV *wv = sp[ai + 1];
            if (!SvROK(wv) || SvTYPE(SvRV(wv)) != SVt_PVAV)
                croak("%s: wrap must be an arrayref [Wx, Wy] or [Wx, Wy, Wz]", who);
            AV *av = (AV *)SvRV(wv);
            SSize_t n = av_len(av) + 1;
            if (n < 2 || n > 3) croak("%s: wrap needs 2 or 3 extents", who);
            world[0] = world[1] = world[2] = 0.0;
            for (SSize_t i = 0; i < n; i++) { SV **e = av_fetch(av, i, 0); world[(int)i] = e ? SvNV(*e) : 0.0; }
            wp = world;
        } else if (strcmp(key, "sphere") == 0) {
            *sphere = (double)SvNV(sp[ai + 1]);
            if (!(*sphere > 0.0) || !isfinite(*sphere)) croak("%s: sphere radius must be finite and > 0", who);
        } else {
            croak("%s: unknown option '%s'", who, key);
        }
    }
    return wp;
}

MODULE = Data::SpatialHash::Shared  PACKAGE = Data::SpatialHash::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, max_entries, num_buckets, cell_size, ...)
    const char *class
    SV *path
    UV max_entries
    UV num_buckets
    NV cell_size
  PREINIT:
    char errbuf[SPH_ERR_BUFLEN];
    double world[3] = {0,0,0};
    double sphere_radius = 0;
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    if (max_entries > UINT32_MAX || num_buckets > UINT32_MAX)
        croak("Data::SpatialHash::Shared->new: max_entries/num_buckets exceed 2^32");
    const double *worldp = sph_parse_opts(aTHX_ &ST(0), 5, items, world, &sphere_radius,
                                          "Data::SpatialHash::Shared->new");
    SpatialHandle *h = sph_create(p, (uint32_t)max_entries, (uint32_t)num_buckets,
                                  (double)cell_size, worldp, sphere_radius, errbuf);
    if (!h) croak("Data::SpatialHash::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, max_entries, num_buckets, cell_size, ...)
    const char *class
    const char *name
    UV max_entries
    UV num_buckets
    NV cell_size
  PREINIT:
    char errbuf[SPH_ERR_BUFLEN];
    double world[3] = {0,0,0};
    double sphere_radius = 0;
  CODE:
    if (max_entries > UINT32_MAX || num_buckets > UINT32_MAX)
        croak("Data::SpatialHash::Shared->new_memfd: max_entries/num_buckets exceed 2^32");
    const double *worldp = sph_parse_opts(aTHX_ &ST(0), 5, items, world, &sphere_radius,
                                          "Data::SpatialHash::Shared->new_memfd");
    SpatialHandle *h = sph_create_memfd(name, (uint32_t)max_entries, (uint32_t)num_buckets,
                                        (double)cell_size, worldp, sphere_radius, errbuf);
    if (!h) croak("Data::SpatialHash::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[SPH_ERR_BUFLEN];
  CODE:
    SpatialHandle *h = sph_open_fd(fd, errbuf);
    if (!h) croak("Data::SpatialHash::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    SpatialHandle *h = INT2PTR(SpatialHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    sph_destroy(h);

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (sph_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p = NULL;
    if (sv_isobject(self_or_class)) {
        SpatialHandle *h = INT2PTR(SpatialHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        p = h->path;
    } else {
        if (items < 2) croak("Usage: ...->unlink($path)");
        p = SvPV_nolen(ST(1));
    }
    if (!p) croak("cannot unlink anonymous or memfd object");
    if (unlink(p) != 0) croak("unlink(%s): %s", p, strerror(errno));

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = sph_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = sph_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    int64_t n = sph_eventfd_consume(h);
    RETVAL = (n >= 0) ? newSViv((IV)n) : &PL_sv_undef;
  OUTPUT:
    RETVAL

UV
max_entries(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->max_entries;
  OUTPUT:
    RETVAL

UV
num_buckets(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->num_buckets;
  OUTPUT:
    RETVAL

NV
cell_size(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->cell_size;
  OUTPUT:
    RETVAL

void
world(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    if (h->wrap) {
        int dims = (h->hdr->world[2] > 0.0) ? 3 : 2;
        EXTEND(SP, dims);
        for (int i = 0; i < dims; i++) PUSHs(sv_2mortal(newSVnv(h->hdr->world[i])));
    }

NV
sphere(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->sphere_radius;
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = __atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE);
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

SV *
insert(self, x, y, ...)
    SV *self
    NV x
    NV y
  PREINIT:
    EXTRACT(self);
    double z, radius;
    int64_t val;
    uint32_t idx;
  CODE:
    /* (x,y,value)=4 2D ; (x,y,z,value)=5 3D ; (x,y,z,value,radius)=6 3D+radius */
    z = 0; radius = 0;
    if (items == 4) { val = (int64_t)SvIV(ST(3)); }
    else if (items == 5) { z = (double)SvNV(ST(3)); val = (int64_t)SvIV(ST(4)); }
    else if (items == 6) { z = (double)SvNV(ST(3)); val = (int64_t)SvIV(ST(4)); radius = (double)SvNV(ST(5)); }
    else croak("insert: expected (x,y,value), (x,y,z,value), or (x,y,z,value,radius)");
    if (radius < 0 || !isfinite(radius)) croak("insert: radius must be a finite number >= 0");
    sph_rwlock_wrlock(h);
    idx = sph_insert_locked(h, x, y, z, val, radius);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);
    RETVAL = (idx == SPH_NONE) ? &PL_sv_undef : newSVuv(idx);
  OUTPUT:
    RETVAL

bool
move(self, handle, x, y, ...)
    SV *self
    UV handle
    NV x
    NV y
  PREINIT:
    EXTRACT(self);
    double z;
  CODE:
    z = 0;
    if (items == 5) z = (double)SvNV(ST(4));
    else if (items != 4) croak("move: expected (handle,x,y) or (handle,x,y,z)");
    sph_rwlock_wrlock(h);
    RETVAL = sph_move_locked(h, (uint32_t)handle, x, y, z);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

bool
remove(self, handle)
    SV *self
    UV handle
  PREINIT:
    EXTRACT(self);
  CODE:
    sph_rwlock_wrlock(h);
    RETVAL = sph_remove_locked(h, (uint32_t)handle);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

bool
has(self, handle)
    SV *self
    UV handle
  PREINIT:
    EXTRACT(self);
  CODE:
    sph_rwlock_rdlock(h);
    RETVAL = sph_is_live(h, (uint32_t)handle);
    sph_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

IV
value(self, handle)
    SV *self
    UV handle
  PREINIT:
    EXTRACT(self);
  CODE:
    sph_rwlock_rdlock(h);
    REQUIRE_LIVE_RD(h, (uint32_t)handle);
    RETVAL = (IV)h->entries[(uint32_t)handle].value;
    sph_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

void
set_value(self, handle, v)
    SV *self
    UV handle
    IV v
  PREINIT:
    EXTRACT(self);
  CODE:
    sph_rwlock_wrlock(h);
    REQUIRE_LIVE(h, (uint32_t)handle);
    h->entries[(uint32_t)handle].value = (int64_t)v;
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);

void
set_radius(self, handle, radius)
    SV *self
    UV handle
    NV radius
  PREINIT:
    EXTRACT(self);
  CODE:
    if (radius < 0 || !isfinite(radius)) croak("set_radius: radius must be a finite number >= 0");
    sph_rwlock_wrlock(h);
    REQUIRE_LIVE(h, (uint32_t)handle);
    h->entries[(uint32_t)handle].radius = (double)radius;
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);

NV
get_radius(self, handle)
    SV *self
    UV handle
  PREINIT:
    EXTRACT(self);
  CODE:
    sph_rwlock_rdlock(h);
    REQUIRE_LIVE_RD(h, (uint32_t)handle);
    RETVAL = h->entries[(uint32_t)handle].radius;
    sph_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

IV
move_many(self, rows)
    SV *self
    SV *rows
  PREINIT:
    EXTRACT(self);
    IV moved;
  CODE:
    if (!SvROK(rows) || SvTYPE(SvRV(rows)) != SVt_PVAV)
        croak("move_many: expected an arrayref of [handle,x,y] or [handle,x,y,z]");
    {
    AV *av = (AV *)SvRV(rows);
    SSize_t nr = av_len(av) + 1;
    moved = 0;
    sph_rwlock_wrlock(h);
    for (SSize_t i = 0; i < nr; i++) {
        SV **rv = av_fetch(av, i, 0);
        if (!rv || !SvROK(*rv) || SvTYPE(SvRV(*rv)) != SVt_PVAV) continue;
        AV *row = (AV *)SvRV(*rv);
        SSize_t rl = av_len(row) + 1;
        if (rl != 3 && rl != 4) continue;
        SV **hp = av_fetch(row, 0, 0), **xp = av_fetch(row, 1, 0), **yp = av_fetch(row, 2, 0);
        SV **zp = (rl == 4) ? av_fetch(row, 3, 0) : NULL;
        if (!hp || !xp || !yp) continue;
        if (sph_move_locked(h, (uint32_t)SvUV(*hp), SvNV(*xp), SvNV(*yp), zp ? SvNV(*zp) : 0.0)) moved++;
    }
    if (nr > 0) __atomic_fetch_add(&h->hdr->stat_ops, (uint64_t)nr, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);
    }
    RETVAL = moved;
  OUTPUT:
    RETVAL

void
insert_many(self, rows)
    SV *self
    SV *rows
  PREINIT:
    EXTRACT(self);
  PPCODE:
    if (!SvROK(rows) || SvTYPE(SvRV(rows)) != SVt_PVAV)
        croak("insert_many: expected an arrayref of [x,y,value] or [x,y,value,radius]");
    {
    AV *av = (AV *)SvRV(rows);
    SSize_t nr = av_len(av) + 1;
    EXTEND(SP, nr);
    sph_rwlock_wrlock(h);
    for (SSize_t i = 0; i < nr; i++) {
        uint32_t idx = SPH_NONE;
        SV **rv = av_fetch(av, i, 0);
        if (rv && SvROK(*rv) && SvTYPE(SvRV(*rv)) == SVt_PVAV) {
            AV *row = (AV *)SvRV(*rv);
            SSize_t rl = av_len(row) + 1;
            if (rl == 3 || rl == 4) {
                SV **xp = av_fetch(row, 0, 0), **yp = av_fetch(row, 1, 0), **vp = av_fetch(row, 2, 0);
                SV **rp = (rl == 4) ? av_fetch(row, 3, 0) : NULL;
                if (xp && yp && vp) {
                    double rad = rp ? SvNV(*rp) : 0.0;
                    /* skip a row with a bad radius (-> undef handle), like other
                       malformed rows; can't croak here -- we hold the write lock */
                    if (rad >= 0 && isfinite(rad))
                        idx = sph_insert_locked(h, SvNV(*xp), SvNV(*yp), 0.0,
                                                (int64_t)SvIV(*vp), rad);
                }
            }
        }
        PUSHs(idx == SPH_NONE ? &PL_sv_undef : sv_2mortal(newSVuv(idx)));
    }
    if (nr > 0) __atomic_fetch_add(&h->hdr->stat_ops, (uint64_t)nr, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);
    }

void
position(self, handle)
    SV *self
    UV handle
  PREINIT:
    EXTRACT(self);
    double px, py, pz;
  PPCODE:
    sph_rwlock_rdlock(h);
    REQUIRE_LIVE_RD(h, (uint32_t)handle);
    px = h->entries[(uint32_t)handle].pos[0];
    py = h->entries[(uint32_t)handle].pos[1];
    pz = h->entries[(uint32_t)handle].pos[2];
    sph_rwlock_rdunlock(h);
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSVnv(px)));
    PUSHs(sv_2mortal(newSVnv(py)));
    PUSHs(sv_2mortal(newSVnv(pz)));

void
query_cell(self, x, y, ...)
    SV *self
    NV x
    NV y
  PREINIT:
    EXTRACT(self);
  PPCODE:
    if (items != 3 && items != 4) croak("query_cell: (x,y) or (x,y,z)");
    int dims = (items == 4) ? 3 : 2;
    double p[3] = { x, y, dims==3 ? (double)SvNV(ST(3)) : 0 };
    EMIT_QUERY(sph_query_cell(h, p, dims, &col));

void
query_aabb(self, ...)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    double lo[3], hi[3]; int dims;
    if (items == 5) { dims = 2;
        lo[0]=SvNV(ST(1)); lo[1]=SvNV(ST(2)); hi[0]=SvNV(ST(3)); hi[1]=SvNV(ST(4)); lo[2]=hi[2]=0;
    } else if (items == 7) { dims = 3;
        lo[0]=SvNV(ST(1)); lo[1]=SvNV(ST(2)); lo[2]=SvNV(ST(3));
        hi[0]=SvNV(ST(4)); hi[1]=SvNV(ST(5)); hi[2]=SvNV(ST(6));
    } else croak("query_aabb: (x0,y0,x1,y1) or (x0,y0,z0,x1,y1,z1)");
    EMIT_QUERY(sph_query_aabb(h, lo, hi, dims, &col));

void
query_radius(self, ...)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    double c[3] = {0,0,0}, r; int dims;
    if (items == 4) { dims = 2; c[0]=SvNV(ST(1)); c[1]=SvNV(ST(2)); r=SvNV(ST(3)); }
    else if (items == 5) { dims = 3; c[0]=SvNV(ST(1)); c[1]=SvNV(ST(2)); c[2]=SvNV(ST(3)); r=SvNV(ST(4)); }
    else croak("query_radius: (x,y,r) or (x,y,z,r)");
    if (r < 0 || !isfinite(r)) croak("query_radius: r must be a finite number >= 0");
    EMIT_QUERY(sph_query_radius(h, c, r, dims, &col));

# Batched broad-phase: N radius queries under ONE read lock. Returns an arrayref of
# id-list arrayrefs, one per query in input order (each == [query_radius(@$q)]). A
# malformed row (not a 3/4-elem arrayref, or a negative/non-finite r) yields an empty
# list for that slot -- can't croak under the lock, mirrors insert_many. OOM/TOOBIG
# from any query croak after freeing the partial result tree.
SV *
query_radius_many(self, queries)
    SV *self
    SV *queries
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!SvROK(queries) || SvTYPE(SvRV(queries)) != SVt_PVAV)
        croak("query_radius_many: expected an arrayref of [x,y,r] or [x,y,z,r]");
    {
    AV *qav = (AV *)SvRV(queries);
    SSize_t nq = av_len(qav) + 1;
    AV *out = newAV();
    if (nq > 0) av_extend(out, nq - 1);
    int err = 0;                                  /* 0 ok, 1 OOM, 2 TOOBIG */
    sph_rwlock_rdlock(h);                          /* one lock for the whole batch */
    for (SSize_t i = 0; i < nq && !err; i++) {
        AV *res = newAV();
        SV **qp = av_fetch(qav, i, 0);
        if (qp && SvROK(*qp) && SvTYPE(SvRV(*qp)) == SVt_PVAV) {
            AV *q = (AV *)SvRV(*qp);
            SSize_t ql = av_len(q) + 1;
            double c[3] = {0,0,0}, r = 0; int dims = 0;
            if (ql == 3) {
                SV **x=av_fetch(q,0,0), **y=av_fetch(q,1,0), **rr=av_fetch(q,2,0);
                if (x && y && rr) { dims=2; c[0]=SvNV(*x); c[1]=SvNV(*y); r=SvNV(*rr); }
            } else if (ql == 4) {
                SV **x=av_fetch(q,0,0), **y=av_fetch(q,1,0), **z=av_fetch(q,2,0), **rr=av_fetch(q,3,0);
                if (x && y && z && rr) { dims=3; c[0]=SvNV(*x); c[1]=SvNV(*y); c[2]=SvNV(*z); r=SvNV(*rr); }
            }
            if (dims && r >= 0 && isfinite(r)) {
                sph_collect_t col = { NULL, 0, 0 };
                int rc = sph_query_radius(h, c, r, dims, &col);
                if (rc == SPH_Q_OOM)         { free(col.vals); err = 1; }
                else if (rc == SPH_Q_TOOBIG) { free(col.vals); err = 2; }
                else {
                    if (col.n) av_extend(res, (SSize_t)col.n - 1);
                    for (size_t k = 0; k < col.n; k++) av_push(res, newSViv((IV)col.vals[k]));
                    free(col.vals);
                }
            }
            /* else: malformed query -> empty res (cannot croak under the lock) */
        }
        av_push(out, newRV_noinc((SV *)res));      /* out owns res, even on the error path */
    }
    sph_rwlock_rdunlock(h);
    if (err) {
        SvREFCNT_dec((SV *)out);                   /* frees out + every res pushed so far */
        if (err == 1) croak("query_radius_many: out of memory");
        croak(SPH_TOOBIG_MSG, (unsigned)SPH_MAX_QUERY_CELLS);
    }
    RETVAL = newRV_noinc((SV *)out);
    }
  OUTPUT:
    RETVAL

SV *
insert_geo(self, lat, lon, alt, value)
    SV *self
    NV lat
    NV lon
    NV alt
    IV value
  PREINIT:
    EXTRACT(self);
    double xyz[3];
    uint32_t idx;
  CODE:
    if (!(h->hdr->sphere_radius > 0.0)) croak("insert_geo: map was not created with sphere => R");
    sph_geo_to_xyz(h->hdr->sphere_radius, lat, lon, alt, xyz);
    sph_rwlock_wrlock(h);
    idx = sph_insert_locked(h, xyz[0], xyz[1], xyz[2], (int64_t)value, 0.0);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);
    RETVAL = (idx == SPH_NONE) ? &PL_sv_undef : newSVuv(idx);
  OUTPUT:
    RETVAL

bool
move_geo(self, handle, lat, lon, alt)
    SV *self
    UV handle
    NV lat
    NV lon
    NV alt
  PREINIT:
    EXTRACT(self);
    double xyz[3];
  CODE:
    if (!(h->hdr->sphere_radius > 0.0)) croak("move_geo: map was not created with sphere => R");
    sph_geo_to_xyz(h->hdr->sphere_radius, lat, lon, alt, xyz);
    sph_rwlock_wrlock(h);
    RETVAL = sph_move_locked(h, (uint32_t)handle, xyz[0], xyz[1], xyz[2]);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

void
position_geo(self, handle)
    SV *self
    UV handle
  PREINIT:
    EXTRACT(self);
    double p[3], lat, lon, alt;
  PPCODE:
    if (!(h->hdr->sphere_radius > 0.0)) croak("position_geo: map was not created with sphere => R");
    sph_rwlock_rdlock(h);
    REQUIRE_LIVE_RD(h, (uint32_t)handle);
    p[0] = h->entries[(uint32_t)handle].pos[0];
    p[1] = h->entries[(uint32_t)handle].pos[1];
    p[2] = h->entries[(uint32_t)handle].pos[2];
    sph_rwlock_rdunlock(h);
    sph_geo_of_xyz(h->hdr->sphere_radius, p, &lat, &lon, &alt);
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSVnv(lat)));
    PUSHs(sv_2mortal(newSVnv(lon)));
    PUSHs(sv_2mortal(newSVnv(alt)));

void
query_geo_radius(self, lat, lon, alt, dist)
    SV *self
    NV lat
    NV lon
    NV alt
    NV dist
  PREINIT:
    EXTRACT(self);
    double c[3];
  PPCODE:
    if (!(h->hdr->sphere_radius > 0.0)) croak("query_geo_radius: map was not created with sphere => R");
    if (dist < 0 || !isfinite(dist)) croak("query_geo_radius: dist must be a finite number >= 0");
    sph_geo_to_xyz(h->hdr->sphere_radius, lat, lon, alt, c);
    EMIT_QUERY(sph_query_radius(h, c, (double)dist, 3, &col));

UV
cube_cell(self, x, y, z, level)
    SV *self
    NV x
    NV y
    NV z
    IV level
  PREINIT:
    EXTRACT(self);
    double dir[3];
  CODE:
    (void)h;
    if (level < 0 || level > SPH_CUBE_MAX_LEVEL) croak("cube_cell: level must be in 0..%d", SPH_CUBE_MAX_LEVEL);
    dir[0] = x; dir[1] = y; dir[2] = z;
    RETVAL = (UV)sph_cube_cell(dir, (int)level);
  OUTPUT:
    RETVAL

UV
cube_cell_geo(self, lat, lon, level)
    SV *self
    NV lat
    NV lon
    IV level
  PREINIT:
    EXTRACT(self);
    double dir[3];
  CODE:
    (void)h;
    if (level < 0 || level > SPH_CUBE_MAX_LEVEL) croak("cube_cell_geo: level must be in 0..%d", SPH_CUBE_MAX_LEVEL);
    sph_geo_to_xyz(1.0, lat, lon, 0.0, dir);   /* unit direction */
    RETVAL = (UV)sph_cube_cell(dir, (int)level);
  OUTPUT:
    RETVAL

IV
cube_level(self, cell)
    SV *self
    UV cell
  PREINIT:
    EXTRACT(self);
  CODE:
    (void)h;
    if (!sph_cube_valid((uint64_t)cell)) croak("cube_level: not a valid cube cell id");
    RETVAL = (IV)sph_cube_level((uint64_t)cell);
  OUTPUT:
    RETVAL

void
cube_center(self, cell)
    SV *self
    UV cell
  PREINIT:
    EXTRACT(self);
    double d[3];
  PPCODE:
    (void)h;
    if (!sph_cube_valid((uint64_t)cell)) croak("cube_center: not a valid cube cell id");
    sph_cube_center((uint64_t)cell, d);
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSVnv(d[0])));
    PUSHs(sv_2mortal(newSVnv(d[1])));
    PUSHs(sv_2mortal(newSVnv(d[2])));

void
cube_center_geo(self, cell)
    SV *self
    UV cell
  PREINIT:
    EXTRACT(self);
    double d[3], lat, lon, alt;
  PPCODE:
    (void)h;
    if (!sph_cube_valid((uint64_t)cell)) croak("cube_center_geo: not a valid cube cell id");
    sph_cube_center((uint64_t)cell, d);
    sph_geo_of_xyz(1.0, d, &lat, &lon, &alt);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVnv(lat)));
    PUSHs(sv_2mortal(newSVnv(lon)));

SV *
cube_parent(self, cell)
    SV *self
    UV cell
  PREINIT:
    EXTRACT(self);
    uint64_t p;
  CODE:
    (void)h;
    if (!sph_cube_valid((uint64_t)cell)) croak("cube_parent: not a valid cube cell id");
    RETVAL = sph_cube_parent((uint64_t)cell, &p) ? newSVuv((UV)p) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
cube_children(self, cell)
    SV *self
    UV cell
  PREINIT:
    EXTRACT(self);
    uint64_t kids[4];
  PPCODE:
    (void)h;
    if (!sph_cube_valid((uint64_t)cell)) croak("cube_children: not a valid cube cell id");
    if (sph_cube_children((uint64_t)cell, kids)) {
        EXTEND(SP, 4);
        for (int k = 0; k < 4; k++) PUSHs(sv_2mortal(newSVuv((UV)kids[k])));
    }

void
cube_neighbors(self, cell)
    SV *self
    UV cell
  PREINIT:
    EXTRACT(self);
    uint64_t nb[4];
  PPCODE:
    (void)h;
    if (!sph_cube_valid((uint64_t)cell)) croak("cube_neighbors: not a valid cube cell id");
    sph_cube_neighbors((uint64_t)cell, nb);
    EXTEND(SP, 4);
    for (int k = 0; k < 4; k++) PUSHs(sv_2mortal(newSVuv((UV)nb[k])));

void query_knn(self, ...)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    double c[3] = {0,0,0}; uint32_t k; int dims;
    if (items == 4) { dims = 2; c[0]=SvNV(ST(1)); c[1]=SvNV(ST(2)); k=(uint32_t)SvUV(ST(3)); }
    else if (items == 5) { dims = 3; c[0]=SvNV(ST(1)); c[1]=SvNV(ST(2)); c[2]=SvNV(ST(3)); k=(uint32_t)SvUV(ST(4)); }
    else croak("query_knn: (x,y,k) or (x,y,z,k)");
    if (k == 0) croak("query_knn: k must be >= 1");
    EMIT_QUERY(sph_query_knn(h, c, k, dims, &col));

void each_in_radius(self, ...)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    /* items: self,x,y,r,cb (5)=2D ; self,x,y,z,r,cb (6)=3D. cb is last. */
    double c[3] = {0,0,0}, r; int dims; SV *cb;
    if (items == 5) { dims=2; c[0]=SvNV(ST(1)); c[1]=SvNV(ST(2)); r=SvNV(ST(3)); cb=ST(4); }
    else if (items == 6) { dims=3; c[0]=SvNV(ST(1)); c[1]=SvNV(ST(2)); c[2]=SvNV(ST(3)); r=SvNV(ST(4)); cb=ST(5); }
    else croak("each_in_radius: (x,y,r,cb) or (x,y,z,r,cb)");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) croak("each_in_radius: last arg must be a coderef");
    if (r < 0 || !isfinite(r)) croak("each_in_radius: r must be a finite number >= 0");
    /* snapshot under lock */
    sph_collect_t col = { NULL, 0, 0 };
    sph_rwlock_rdlock(h);
    int rc = sph_query_radius(h, c, r, dims, &col);
    sph_rwlock_rdunlock(h);
    if (rc == SPH_Q_OOM)    { free(col.vals); croak("each_in_radius: out of memory"); }
    if (rc == SPH_Q_TOOBIG) { free(col.vals); croak(SPH_TOOBIG_MSG, (unsigned)SPH_MAX_QUERY_CELLS); }
    /* invoke callback per value AFTER releasing the lock; G_EVAL so a die in
     * the callback does not skip free(col.vals) -- re-throw after cleanup. */
    for (size_t i = 0; i < col.n; i++) {
        dSP; ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv((IV)col.vals[i])));
        PUTBACK;
        call_sv(cb, G_VOID|G_DISCARD|G_EVAL);
        FREETMPS; LEAVE;
        if (SvTRUE(ERRSV)) { free(col.vals); croak_sv(ERRSV); }
    }
    free(col.vals);

void
each_pair_within(self, max_r, cb)
    SV *self
    NV max_r
    SV *cb
  PREINIT:
    EXTRACT(self);
  PPCODE:
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) croak("each_pair_within: last arg must be a coderef");
    if (max_r < 0 || !isfinite(max_r)) croak("each_pair_within: max_r must be a finite number >= 0");
    EMIT_PAIRS(sph_pairs(h, (double)max_r, sph_pair_to_collect, &col));

void
each_colliding_pair(self, cb)
    SV *self
    SV *cb
  PREINIT:
    EXTRACT(self);
  PPCODE:
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) croak("each_colliding_pair: arg must be a coderef");
    EMIT_PAIRS(sph_pairs(h, -1.0, sph_pair_to_collect, &col));

void clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    sph_rwlock_wrlock(h);
    sph_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    sph_rwlock_wrunlock(h);

SV *stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    sph_rwlock_rdlock(h);
    uint32_t occ, mx, mxcell; sph_chain_stats(h, &occ, &mx, &mxcell);
    uint32_t cnt = h->hdr->count, me = h->hdr->max_entries, nb = h->hdr->num_buckets;
    sph_rwlock_rdunlock(h);
    HV *hv = newHV();
    hv_store(hv, "count", 5, newSVuv(cnt), 0);
    hv_store(hv, "max_entries", 11, newSVuv(me), 0);
    hv_store(hv, "num_buckets", 11, newSVuv(nb), 0);
    hv_store(hv, "cell_size", 9, newSVnv(h->hdr->cell_size), 0);
    hv_store(hv, "free_slots", 10, newSVuv(me - cnt), 0);
    hv_store(hv, "occupied_buckets", 16, newSVuv(occ), 0);
    hv_store(hv, "max_chain", 9, newSVuv(mx), 0);
    hv_store(hv, "max_cell", 8, newSVuv(mxcell), 0);
    hv_store(hv, "load_factor", 11, newSVnv(nb ? (double)cnt / nb : 0), 0);
    hv_store(hv, "ops", 3, newSVuv((UV)__atomic_load_n(&h->hdr->stat_ops, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT: RETVAL
