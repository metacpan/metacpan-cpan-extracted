#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "ndarray.h"

#ifdef HAVE_PDL
#include <pdlcore.h>
static Core *PDL;   /* PDL core C functions; bootstrapped lazily on first as_pdl_alias */

/* deletedata magic for our external (mmap-aliased) data: never free it -- the
   NDArray handle owns the mapping (kept alive via the piddle's header). */
static void nda_pdl_nofree(pdl *p, Size_t param) { (void)param; p->data = 0; }

/* Load PDL::Core and grab its Core struct on first use, so plain use of the module
   without as_pdl_alias does not pull in PDL. */
static void nda_boot_pdl(pTHX) {
    SV *coresv;
    if (PDL) return;
    perl_require_pv("PDL/Core.pm");
    if (SvTRUE(ERRSV)) croak("%s", SvPV_nolen(ERRSV));
    coresv = get_sv("PDL::SHARE", 0);
    if (!coresv) croak("Data::NDArray::Shared: PDL::Core not loadable (needed for as_pdl_alias)");
    PDL = INT2PTR(Core *, SvIV(coresv));
    if (!PDL) croak("Data::NDArray::Shared: got a NULL PDL Core pointer");
    if (PDL->Version != PDL_CORE_VERSION)
        croak("Data::NDArray::Shared: please rebuild against the installed PDL (Core version mismatch)");
}
#endif

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::NDArray::Shared")) \
        croak("Expected a Data::NDArray::Shared object"); \
    NdaHandle *h = INT2PTR(NdaHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::NDArray::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

/* ----------------------------------------------------------------
 * Typed element get: read element e of dtype dt, return the dtype-correct SV
 * (float -> newSVnv, signed -> newSViv, unsigned -> newSVuv).
 * ---------------------------------------------------------------- */
static SV *nda_get_sv(pTHX_ NdaHandle *h, uint64_t e) {
    char *base = nda_data(h);
    switch (h->hdr->dtype) {
        case NDA_F64: { double   v; memcpy(&v, base + e*8, 8); return newSVnv(v); }
        case NDA_F32: { float    v; memcpy(&v, base + e*4, 4); return newSVnv((double)v); }
        case NDA_I64: { int64_t  v; memcpy(&v, base + e*8, 8); return newSViv((IV)v); }
        case NDA_I32: { int32_t  v; memcpy(&v, base + e*4, 4); return newSViv((IV)v); }
        case NDA_I16: { int16_t  v; memcpy(&v, base + e*2, 2); return newSViv((IV)v); }
        case NDA_I8:  { int8_t   v = (int8_t)base[e];          return newSViv((IV)v); }
        case NDA_U64: { uint64_t v; memcpy(&v, base + e*8, 8); return newSVuv((UV)v); }
        case NDA_U32: { uint32_t v; memcpy(&v, base + e*4, 4); return newSVuv((UV)v); }
        case NDA_U16: { uint16_t v; memcpy(&v, base + e*2, 2); return newSVuv((UV)v); }
        case NDA_U8:  { uint8_t  v = (uint8_t)base[e];         return newSVuv((UV)v); }
    }
    return newSViv(0);
}

/* ----------------------------------------------------------------
 * Typed element set: write element e from an SV, casting/truncating to the
 * element width (float -> SvNV, signed -> (intN)SvIV, unsigned -> (uintN)SvUV).
 * Out-of-range integer values wrap to the element width per C cast rules.
 * ---------------------------------------------------------------- */
static void nda_set_sv(pTHX_ NdaHandle *h, uint64_t e, SV *val) {
    char *base = nda_data(h);
    switch (h->hdr->dtype) {
        case NDA_F64: { double   v = (double)SvNV(val); memcpy(base + e*8, &v, 8); break; }
        case NDA_F32: { float    v = (float)SvNV(val);  memcpy(base + e*4, &v, 4); break; }
        case NDA_I64: { int64_t  v = (int64_t)SvIV(val); memcpy(base + e*8, &v, 8); break; }
        case NDA_I32: { int32_t  v = (int32_t)SvIV(val); memcpy(base + e*4, &v, 4); break; }
        case NDA_I16: { int16_t  v = (int16_t)SvIV(val); memcpy(base + e*2, &v, 2); break; }
        case NDA_I8:  { int8_t   v = (int8_t)SvIV(val);  base[e] = (char)v;         break; }
        case NDA_U64: { uint64_t v = (uint64_t)SvUV(val); memcpy(base + e*8, &v, 8); break; }
        case NDA_U32: { uint32_t v = (uint32_t)SvUV(val); memcpy(base + e*4, &v, 4); break; }
        case NDA_U16: { uint16_t v = (uint16_t)SvUV(val); memcpy(base + e*2, &v, 2); break; }
        case NDA_U8:  { uint8_t  v = (uint8_t)SvUV(val);  base[e] = (char)v;        break; }
    }
}

/* ----------------------------------------------------------------
 * Fill every element with the typed value of val.
 * ---------------------------------------------------------------- */
static void nda_fill_locked(pTHX_ NdaHandle *h, SV *val) {
    uint64_t size = h->hdr->size, e;
    char *base = nda_data(h);
    /* Decode once, then splat the raw bytes for speed + consistency. */
    switch (h->hdr->dtype) {
        case NDA_F64: { double   v = (double)SvNV(val); for (e=0;e<size;e++) memcpy(base+e*8,&v,8); break; }
        case NDA_F32: { float    v = (float)SvNV(val);  for (e=0;e<size;e++) memcpy(base+e*4,&v,4); break; }
        case NDA_I64: { int64_t  v = (int64_t)SvIV(val); for (e=0;e<size;e++) memcpy(base+e*8,&v,8); break; }
        case NDA_I32: { int32_t  v = (int32_t)SvIV(val); for (e=0;e<size;e++) memcpy(base+e*4,&v,4); break; }
        case NDA_I16: { int16_t  v = (int16_t)SvIV(val); for (e=0;e<size;e++) memcpy(base+e*2,&v,2); break; }
        case NDA_I8:  { int8_t   v = (int8_t)SvIV(val);  memset(base, (int)(unsigned char)v, (size_t)size); break; }
        case NDA_U64: { uint64_t v = (uint64_t)SvUV(val); for (e=0;e<size;e++) memcpy(base+e*8,&v,8); break; }
        case NDA_U32: { uint32_t v = (uint32_t)SvUV(val); for (e=0;e<size;e++) memcpy(base+e*4,&v,4); break; }
        case NDA_U16: { uint16_t v = (uint16_t)SvUV(val); for (e=0;e<size;e++) memcpy(base+e*2,&v,2); break; }
        case NDA_U8:  { uint8_t  v = (uint8_t)SvUV(val);  memset(base, (int)v, (size_t)size); break; }
    }
}

/* ----------------------------------------------------------------
 * In-place scalar op over every element: e = e OP s, in the dtype's arithmetic
 * (float dtypes use double; int dtypes use integer arithmetic in the element
 * width, wrapping per C rules).  `op` is '+' or '*'.
 * ---------------------------------------------------------------- */
/* Integer arithmetic is done in UT -- an unsigned type of at least `unsigned int`
 * rank -- so overflow is a defined wrap (no signed-overflow UB, and no u16/u8
 * promotion to signed int) and the narrowing cast back to CT gives the documented
 * two's-complement wrap.  UT must be uint32_t for the <=32-bit dtypes, uint64_t
 * for the 64-bit ones. */
#define NDA_SCALAR_INT(CT, UT) do { \
    CT *p = (CT *)base; \
    if (op == '+') { CT s = (CT)siv; for (e=0;e<size;e++) p[e] = (CT)((UT)p[e] + (UT)s); } \
    else           { CT s = (CT)siv; for (e=0;e<size;e++) p[e] = (CT)((UT)p[e] * (UT)s); } \
} while (0)
#define NDA_SCALAR_UINT(CT, UT) do { \
    CT *p = (CT *)base; \
    if (op == '+') { CT s = (CT)suv; for (e=0;e<size;e++) p[e] = (CT)((UT)p[e] + (UT)s); } \
    else           { CT s = (CT)suv; for (e=0;e<size;e++) p[e] = (CT)((UT)p[e] * (UT)s); } \
} while (0)

static void nda_scalar_op_locked(pTHX_ NdaHandle *h, SV *sv, int op) {
    uint64_t size = h->hdr->size, e;
    char *base = nda_data(h);
    if (nda_is_float(h->hdr->dtype)) {
        double s = (double)SvNV(sv);
        if (h->hdr->dtype == NDA_F64) {
            double *p = (double *)base;
            if (op == '+') for (e=0;e<size;e++) p[e] += s; else for (e=0;e<size;e++) p[e] *= s;
        } else { /* F32 */
            float *p = (float *)base; float fs = (float)s;
            if (op == '+') for (e=0;e<size;e++) p[e] += fs; else for (e=0;e<size;e++) p[e] *= fs;
        }
    } else if (nda_is_signed(h->hdr->dtype)) {
        int64_t siv = (int64_t)SvIV(sv);
        switch (h->hdr->dtype) {
            case NDA_I64: NDA_SCALAR_INT(int64_t, uint64_t); break;
            case NDA_I32: NDA_SCALAR_INT(int32_t, uint32_t); break;
            case NDA_I16: NDA_SCALAR_INT(int16_t, uint32_t); break;
            case NDA_I8:  NDA_SCALAR_INT(int8_t,  uint32_t); break;
        }
    } else {
        uint64_t suv = (uint64_t)SvUV(sv);
        switch (h->hdr->dtype) {
            case NDA_U64: NDA_SCALAR_UINT(uint64_t, uint64_t); break;
            case NDA_U32: NDA_SCALAR_UINT(uint32_t, uint32_t); break;
            case NDA_U16: NDA_SCALAR_UINT(uint16_t, uint32_t); break;
            case NDA_U8:  NDA_SCALAR_UINT(uint8_t,  uint32_t); break;
        }
    }
}

/* ----------------------------------------------------------------
 * In-place element-wise array op: a[i] = a[i] OP b[i] (same dtype + size).
 * `op` is '+', '-' or '*'.  Both buffers are interpreted in the shared dtype.
 * ---------------------------------------------------------------- */
/* float dtypes: native arithmetic (overflow -> +-inf, well-defined) */
#define NDA_EW_FLT(CT) do { \
    CT *pa = (CT *)da; const CT *pb = (const CT *)db; \
    if      (op == '+') for (e=0;e<size;e++) pa[e] = (CT)(pa[e] + pb[e]); \
    else if (op == '-') for (e=0;e<size;e++) pa[e] = (CT)(pa[e] - pb[e]); \
    else                for (e=0;e<size;e++) pa[e] = (CT)(pa[e] * pb[e]); \
} while (0)
/* integer dtypes: compute in UT (unsigned, >= int rank) for defined wrap -- see
 * the NDA_SCALAR_INT note above. */
#define NDA_EW_INT(CT, UT) do { \
    CT *pa = (CT *)da; const CT *pb = (const CT *)db; \
    if      (op == '+') for (e=0;e<size;e++) pa[e] = (CT)((UT)pa[e] + (UT)pb[e]); \
    else if (op == '-') for (e=0;e<size;e++) pa[e] = (CT)((UT)pa[e] - (UT)pb[e]); \
    else                for (e=0;e<size;e++) pa[e] = (CT)((UT)pa[e] * (UT)pb[e]); \
} while (0)

static void nda_elementwise_op_locked(NdaHandle *a, NdaHandle *b, int op) {
    uint64_t size = a->hdr->size, e;
    char *da = nda_data(a);
    const char *db = nda_data(b);
    switch (a->hdr->dtype) {
        case NDA_F64: NDA_EW_FLT(double);   break;
        case NDA_F32: NDA_EW_FLT(float);    break;
        case NDA_I64: NDA_EW_INT(int64_t,  uint64_t); break;
        case NDA_I32: NDA_EW_INT(int32_t,  uint32_t); break;
        case NDA_I16: NDA_EW_INT(int16_t,  uint32_t); break;
        case NDA_I8:  NDA_EW_INT(int8_t,   uint32_t); break;
        case NDA_U64: NDA_EW_INT(uint64_t, uint64_t); break;
        case NDA_U32: NDA_EW_INT(uint32_t, uint32_t); break;
        case NDA_U16: NDA_EW_INT(uint16_t, uint32_t); break;
        case NDA_U8:  NDA_EW_INT(uint8_t,  uint32_t); break;
    }
}

/* Acquire receiver `a`'s WRITE lock and other `b`'s READ lock in a
 * globally-consistent order keyed on each array's shared identity (array_id),
 * NOT the process-local handle pointer, so two unrelated processes mapping the
 * same pair agree on order and cannot deadlock.  a and b must be DISTINCT
 * underlying arrays (the caller has already handled the same-array case). */
static void nda_lock_pair(NdaHandle *a, NdaHandle *b) {
    if (a->hdr->array_id < b->hdr->array_id) {
        nda_rwlock_wrlock(a);
        nda_rwlock_rdlock(b);
    } else {
        nda_rwlock_rdlock(b);
        nda_rwlock_wrlock(a);
    }
}
static void nda_unlock_pair(NdaHandle *a, NdaHandle *b) {
    if (a->hdr->array_id < b->hdr->array_id) {
        nda_rwlock_rdunlock(b);
        nda_rwlock_wrunlock(a);
    } else {
        nda_rwlock_wrunlock(a);
        nda_rwlock_rdunlock(b);
    }
}

/* Shared body of add/subtract/multiply: validate `other`, take the locks in a
 * deadlock-free id order (or a single wrlock for self/same-id), apply the
 * element-wise op, bump stat_ops, and unlock.  `op` is '+', '-' or '*'; `who`
 * is the fully-qualified method name used in croak messages. */
static void nda_do_elementwise(pTHX_ NdaHandle *h, SV *other, int op, const char *who) {
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::NDArray::Shared"))
        croak("%s: expected a Data::NDArray::Shared object", who);
    NdaHandle *o = INT2PTR(NdaHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::NDArray::Shared object");
    if (o->hdr->dtype != h->hdr->dtype)
        croak("%s: dtype mismatch", who);
    if (o->hdr->size != h->hdr->size)
        croak("%s: size mismatch (%" UVuf " vs %" UVuf ")",
              who, (UV)h->hdr->size, (UV)o->hdr->size);
    if (o == h || o->hdr->array_id == h->hdr->array_id) {
        nda_rwlock_wrlock(h);
        nda_elementwise_op_locked(h, h, op);   /* self: +=->double, -=->zero, *=->square */
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        nda_rwlock_wrunlock(h);
    } else {
        nda_lock_pair(h, o);
        nda_elementwise_op_locked(h, o, op);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        nda_unlock_pair(h, o);
    }
}

/* Resolve the uniform (path, dtype, @shape) argument convention shared by new
 * and new_memfd, matching the rest of the Data::*::Shared family:
 *   ($path_or_undef, $dtype, @shape)
 * ST(1) is ALWAYS the path/memfd label (an SV that may carry undef for an
 * anonymous mapping), ST(2) is ALWAYS the dtype name string, and ST(3).. are
 * the dimensions.  Sets *out_label, *out_dt, fills dims[] and returns ndim.
 * Croaks (no resource held) on a missing/unknown dtype or bad dims. */
static uint32_t nda_resolve_ctor_args(pTHX_ I32 ax, I32 items, const char *who,
                                      SV **out_label, int *out_dt,
                                      uint64_t dims[NDA_MAX_DIMS]) {
    SV **sp_mark = PL_stack_base + ax;   /* ST(0) == class */
    if (items < 3) croak("%s: dtype required", who);
    SV *label = sp_mark[1];              /* path/name SV (may be undef) */
    SV *dsv   = sp_mark[2];              /* dtype name */
    STRLEN dlen; const char *dname = SvPVbyte(dsv, dlen);
    int dt = nda_dtype_from_name(dname, dlen);
    if (dt < 0) croak("%s: unknown dtype", who);
    /* parse @shape from ST(3).. */
    I32 nd = items - 3;
    if (nd < 1) croak("%s: at least one dimension required", who);
    if (nd > NDA_MAX_DIMS) croak("%s: too many dimensions (max %d)", who, NDA_MAX_DIMS);
    for (I32 i = 0; i < nd; i++) {
        IV iv = SvIV(sp_mark[3 + i]);
        if (iv < 1) croak("%s: dimension %d must be >= 1", who, (int)i);
        dims[i] = (uint64_t)iv;
    }
    *out_label = label;
    *out_dt = dt;
    return (uint32_t)nd;
}

MODULE = Data::NDArray::Shared  PACKAGE = Data::NDArray::Shared

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
  PREINIT:
    char errbuf[NDA_ERR_BUFLEN];
    uint64_t dims[NDA_MAX_DIMS];
  CODE:
    {
        SV *label; int dt;
        uint32_t ndim = nda_resolve_ctor_args(aTHX_ ax, items,
            "Data::NDArray::Shared->new", &label, &dt, dims);   /* croaks before any alloc */
        const char *p = SvOK(label) ? SvPV_nolen(label) : NULL;
        NdaHandle *h = nda_create(p, dt, dims, ndim, errbuf);
        if (!h) croak("Data::NDArray::Shared->new: %s", errbuf);
        MAKE_OBJ(class, h);
    }
  OUTPUT:
    RETVAL

SV *
new_memfd(class, ...)
    const char *class
  PREINIT:
    char errbuf[NDA_ERR_BUFLEN];
    uint64_t dims[NDA_MAX_DIMS];
  CODE:
    {
        SV *label; int dt;
        uint32_t ndim = nda_resolve_ctor_args(aTHX_ ax, items,
            "Data::NDArray::Shared->new_memfd", &label, &dt, dims);
        const char *nm = SvOK(label) ? SvPV_nolen(label) : NULL;
        NdaHandle *h = nda_create_memfd(nm, dt, dims, ndim, errbuf);
        if (!h) croak("Data::NDArray::Shared->new_memfd: %s", errbuf);
        MAKE_OBJ(class, h);
    }
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[NDA_ERR_BUFLEN];
  CODE:
    NdaHandle *h = nda_open_fd(fd, errbuf);
    if (!h) croak("Data::NDArray::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::NDArray::Shared")) {
        NdaHandle *h = INT2PTR(NdaHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); nda_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

SV *
get(self, ...)
    SV *self
  PREINIT:
    EXTRACT(self);
    uint64_t idx[NDA_MAX_DIMS];
  CODE:
    {
        uint32_t ndim = h->hdr->ndim;
        if ((uint32_t)(items - 1) != ndim)
            croak("Data::NDArray::Shared->get: expected %u indices, got %d", ndim, (int)(items - 1));
        for (uint32_t d = 0; d < ndim; d++) {
            UV ix = SvUV(ST(1 + d));
            if (ix >= h->hdr->shape[d])
                croak("Data::NDArray::Shared->get: index %u = %" UVuf " out of range (dim size %" UVuf ")",
                      d, ix, (UV)h->hdr->shape[d]);
            idx[d] = (uint64_t)ix;
        }
        uint64_t e = nda_flat_offset(h, idx, ndim);
        nda_rwlock_rdlock(h);
        RETVAL = nda_get_sv(aTHX_ h, e);
        nda_rwlock_rdunlock(h);
    }
  OUTPUT:
    RETVAL

void
set(self, ...)
    SV *self
  PREINIT:
    EXTRACT(self);
    uint64_t idx[NDA_MAX_DIMS];
  CODE:
    {
        uint32_t ndim = h->hdr->ndim;
        /* items = self + ndim indices + value */
        if ((uint32_t)(items - 2) != ndim)
            croak("Data::NDArray::Shared->set: expected %u indices + value, got %d args", ndim, (int)(items - 1));
        for (uint32_t d = 0; d < ndim; d++) {
            UV ix = SvUV(ST(1 + d));
            if (ix >= h->hdr->shape[d])
                croak("Data::NDArray::Shared->set: index %u = %" UVuf " out of range (dim size %" UVuf ")",
                      d, ix, (UV)h->hdr->shape[d]);
            idx[d] = (uint64_t)ix;
        }
        SV *val = ST(items - 1);
        uint64_t e = nda_flat_offset(h, idx, ndim);
        nda_rwlock_wrlock(h);
        nda_set_sv(aTHX_ h, e, val);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        nda_rwlock_wrunlock(h);
    }

SV *
get_flat(self, e)
    SV *self
    UV e
  PREINIT:
    EXTRACT(self);
  CODE:
    if (e >= h->hdr->size)
        croak("Data::NDArray::Shared->get_flat: index %" UVuf " out of range (size %" UVuf ")",
              e, (UV)h->hdr->size);
    nda_rwlock_rdlock(h);
    RETVAL = nda_get_sv(aTHX_ h, (uint64_t)e);
    nda_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

void
set_flat(self, e, val)
    SV *self
    UV e
    SV *val
  PREINIT:
    EXTRACT(self);
  CODE:
    if (e >= h->hdr->size)
        croak("Data::NDArray::Shared->set_flat: index %" UVuf " out of range (size %" UVuf ")",
              e, (UV)h->hdr->size);
    nda_rwlock_wrlock(h);
    nda_set_sv(aTHX_ h, (uint64_t)e, val);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    nda_rwlock_wrunlock(h);

SV *
fill(self, val)
    SV *self
    SV *val
  PREINIT:
    EXTRACT(self);
  CODE:
    nda_rwlock_wrlock(h);
    nda_fill_locked(aTHX_ h, val);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    nda_rwlock_wrunlock(h);
    SvREFCNT_inc(self);
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
zero(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    nda_rwlock_wrlock(h);
    memset(nda_data(h), 0, (size_t)(h->hdr->size * h->hdr->itemsize));
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    nda_rwlock_wrunlock(h);
    SvREFCNT_inc(self);
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
reshape(self, ...)
    SV *self
  PREINIT:
    EXTRACT(self);
    uint64_t dims[NDA_MAX_DIMS];
    uint64_t strides[NDA_MAX_DIMS];
  CODE:
    {
        I32 nd = items - 1;
        if (nd < 1) croak("Data::NDArray::Shared->reshape: at least one dimension required");
        if (nd > NDA_MAX_DIMS) croak("Data::NDArray::Shared->reshape: too many dimensions (max %d)", NDA_MAX_DIMS);
        uint64_t newsize = 1;
        for (I32 i = 0; i < nd; i++) {
            IV iv = SvIV(ST(1 + i));
            if (iv < 1) croak("Data::NDArray::Shared->reshape: dimension %d must be >= 1", (int)i);
            dims[i] = (uint64_t)iv;
            if (dims[i] > UINT64_MAX / newsize) croak("Data::NDArray::Shared->reshape: shape too large");
            newsize *= dims[i];
        }
        if (newsize != h->hdr->size)
            croak("Data::NDArray::Shared->reshape: total size %" UVuf " does not match current size %" UVuf,
                  (UV)newsize, (UV)h->hdr->size);
        /* row-major strides for the new shape */
        strides[nd - 1] = 1;
        for (int d = nd - 2; d >= 0; d--) strides[d] = strides[d + 1] * dims[d + 1];
        nda_rwlock_wrlock(h);
        h->hdr->ndim = (uint32_t)nd;
        for (I32 i = 0; i < nd; i++) { h->hdr->shape[i] = dims[i]; h->hdr->strides[i] = strides[i]; }
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        nda_rwlock_wrunlock(h);
        SvREFCNT_inc(self);
        RETVAL = self;
    }
  OUTPUT:
    RETVAL

NV
sum(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    nda_rwlock_rdlock(h);
    RETVAL = nda_sum_locked(h);
    nda_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

NV
mean(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        double acc;
        nda_rwlock_rdlock(h);
        acc = nda_sum_locked(h);
        nda_rwlock_rdunlock(h);
        RETVAL = acc / (double)h->hdr->size;   /* size >= 1 always */
    }
  OUTPUT:
    RETVAL

SV *
min(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t best;
        nda_rwlock_rdlock(h);
        best = nda_argextreme_locked(h, 0);   /* compare in native dtype */
        RETVAL = nda_get_sv(aTHX_ h, best);   /* dtype-correct value of the min element */
        nda_rwlock_rdunlock(h);
    }
  OUTPUT:
    RETVAL

SV *
max(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t best;
        nda_rwlock_rdlock(h);
        best = nda_argextreme_locked(h, 1);   /* compare in native dtype */
        RETVAL = nda_get_sv(aTHX_ h, best);
        nda_rwlock_rdunlock(h);
    }
  OUTPUT:
    RETVAL

SV *
add_scalar(self, s)
    SV *self
    SV *s
  PREINIT:
    EXTRACT(self);
  CODE:
    nda_rwlock_wrlock(h);
    nda_scalar_op_locked(aTHX_ h, s, '+');
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    nda_rwlock_wrunlock(h);
    SvREFCNT_inc(self);
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
mul_scalar(self, s)
    SV *self
    SV *s
  PREINIT:
    EXTRACT(self);
  CODE:
    nda_rwlock_wrlock(h);
    nda_scalar_op_locked(aTHX_ h, s, '*');
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    nda_rwlock_wrunlock(h);
    SvREFCNT_inc(self);
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
add(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    nda_do_elementwise(aTHX_ h, other, '+', "Data::NDArray::Shared->add");
    SvREFCNT_inc(self);
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
subtract(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    nda_do_elementwise(aTHX_ h, other, '-', "Data::NDArray::Shared->subtract");
    SvREFCNT_inc(self);
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
multiply(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    nda_do_elementwise(aTHX_ h, other, '*', "Data::NDArray::Shared->multiply");
    SvREFCNT_inc(self);
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
to_list(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t size = h->hdr->size, e;
        AV *av = newAV();
        av_extend(av, (SSize_t)(size - 1));   /* pre-extend BEFORE the lock; no croak under lock */
        nda_rwlock_rdlock(h);
        for (e = 0; e < size; e++)
            av_store(av, (SSize_t)e, nda_get_sv(aTHX_ h, e));
        nda_rwlock_rdunlock(h);
        RETVAL = newRV_noinc((SV *)av);
    }
  OUTPUT:
    RETVAL

void
shape(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    {
        uint32_t ndim = h->hdr->ndim, d;
        EXTEND(SP, (SSize_t)ndim);
        for (d = 0; d < ndim; d++)
            PUSHs(sv_2mortal(newSVuv((UV)h->hdr->shape[d])));
    }

void
strides(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    {
        uint32_t ndim = h->hdr->ndim, d;
        EXTEND(SP, (SSize_t)ndim);
        for (d = 0; d < ndim; d++)
            PUSHs(sv_2mortal(newSVuv((UV)h->hdr->strides[d])));
    }

UV
ndim(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->ndim;   /* immutable shape rank is stable; reshape keeps 1..8 */
  OUTPUT:
    RETVAL

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->size;   /* immutable after creation -- lock-free */
  OUTPUT:
    RETVAL

UV
itemsize(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->itemsize;   /* immutable after creation -- lock-free */
  OUTPUT:
    RETVAL

# Raw contiguous data region as a byte string (read-locked snapshot copy).  The
# bytes are row-major C-order; pair with shape()/dtype() to interpret them.
SV *
buffer(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t bytes = h->hdr->size * h->hdr->itemsize;
        char *base = nda_data(h);
        RETVAL = newSVpvn("", 0);
        (void)SvGROW(RETVAL, (STRLEN)(bytes + 1));   /* size the buffer BEFORE the lock */
        nda_rwlock_rdlock(h);
        Copy(base, SvPVX(RETVAL), bytes, char);
        nda_rwlock_rdunlock(h);
        SvCUR_set(RETVAL, (STRLEN)bytes);
        *SvEND(RETVAL) = '\0';
    }
  OUTPUT:
    RETVAL

# Overwrite the whole data region from a byte string of exactly size*itemsize
# bytes (write-locked).  Used by from_pdl/update_from_pdl.
void
update_from_bytes(self, src)
    SV *self
    SV *src
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        STRLEN slen;
        const char *sbytes = SvPVbyte(src, slen);   /* resolve + any croak BEFORE the lock */
        uint64_t bytes = h->hdr->size * h->hdr->itemsize;
        char *base;
        if ((uint64_t)slen != bytes)
            croak("Data::NDArray::Shared->update_from_bytes: got %" UVuf
                  " bytes, expected %" UVuf, (UV)slen, (UV)bytes);
        base = nda_data(h);
        nda_rwlock_wrlock(h);
        Copy(sbytes, base, bytes, char);
        nda_rwlock_wrunlock(h);
    }

# Zero-copy: build a PDL ndarray whose data IS our shared mmap, via PDL's C API
# (PDL_DONTTOUCHDATA -- PDL never frees or reallocates the mapping, the only way to
# alias external memory PDL won't silently detach from).  The PDL C path is compiled
# only when the module was built against PDL; otherwise this croaks.  Returns SV*
# (not pdl*) so the XSUB needs no PDL typemap and the no-PDL build still compiles.
# `datatype` is the PDL type number; `dims_av` is in PDL order (fastest axis first).
SV *
_alias_pdl_create(self, datatype, dims_av)
    SV *self
    int datatype
    AV *dims_av
  PREINIT:
    EXTRACT(self);
  CODE:
#ifdef HAVE_PDL
    {
        IV nd = av_len(dims_av) + 1, i;
        PDL_Indx dims[NDA_MAX_DIMS];
        pdl_error err;
        pdl *p;
        nda_boot_pdl(aTHX);
        if (nd < 1 || nd > NDA_MAX_DIMS)
            croak("Data::NDArray::Shared: bad dim count %" IVdf, nd);
        for (i = 0; i < nd; i++) {
            SV **e = av_fetch(dims_av, (SSize_t)i, 0);
            dims[i] = (PDL_Indx)(e ? SvIV(*e) : 0);
        }
        p = PDL->pdlnew();
        if (!p) croak("Data::NDArray::Shared: PDL->pdlnew failed");
        p->datatype = (pdl_datatypes)datatype;   /* set type before setdims so nbytes is right */
        err = PDL->setdims(p, dims, (PDL_Indx)nd);
        if (err.error) { PDL->destroy(p); croak("Data::NDArray::Shared: PDL->setdims failed"); }
        p->data = nda_data(h);                    /* alias the shared mmap */
        p->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
        PDL->add_deletedata_magic(p, nda_pdl_nofree, 0);
        RETVAL = newSV(0);
        PDL->SetSV_PDL(RETVAL, p);                /* wrap the pdl as its Perl object */
    }
#else
    PERL_UNUSED_VAR(datatype);
    PERL_UNUSED_VAR(dims_av);
    croak("Data::NDArray::Shared: as_pdl_alias needs the module built with PDL "
          "installed; reinstall with PDL present (to_pdl/update_from_pdl need no rebuild)");
    RETVAL = &PL_sv_undef;   /* not reached (croak does not return) */
#endif
  OUTPUT:
    RETVAL

SV *
dtype(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = newSVpv(nda_name_tab[h->hdr->dtype], 0);   /* immutable */
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint32_t dtype, ndim, itemsize, d;
        uint64_t size, ops, shp[NDA_MAX_DIMS];
        /* Snapshot under the lock; build the HV after releasing it so an OOM
           in newHV/newSV* can never strand the lock. */
        nda_rwlock_rdlock(h);
        dtype    = h->hdr->dtype;
        ndim     = h->hdr->ndim;
        itemsize = h->hdr->itemsize;
        size     = h->hdr->size;
        ops      = h->hdr->stat_ops;
        for (d = 0; d < ndim; d++) shp[d] = h->hdr->shape[d];
        nda_rwlock_rdunlock(h);

        AV *shape_av = newAV();
        av_extend(shape_av, (SSize_t)(ndim - 1));
        for (d = 0; d < ndim; d++) av_store(shape_av, (SSize_t)d, newSVuv((UV)shp[d]));

        HV *hv = newHV();
        hv_stores(hv, "dtype",     newSVpv(nda_name_tab[dtype], 0));
        hv_stores(hv, "ndim",      newSVuv((UV)ndim));
        hv_stores(hv, "size",      newSVuv((UV)size));
        hv_stores(hv, "itemsize",  newSVuv((UV)itemsize));
        hv_stores(hv, "shape",     newRV_noinc((SV *)shape_av));
        hv_stores(hv, "ops",       newSVuv((UV)ops));
        hv_stores(hv, "mmap_size", newSVuv((UV)h->mmap_size));
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
    if (nda_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::NDArray::Shared")) {
        NdaHandle *h = INT2PTR(NdaHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && SvOK(ST(1))) {
        unlink(SvPV_nolen(ST(1)));
    }
