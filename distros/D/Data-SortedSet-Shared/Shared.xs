#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "sortedset.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::SortedSet::Shared")) \
        croak("Expected a Data::SortedSet::Shared object"); \
    SsHandle *h = INT2PTR(SsHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::SortedSet::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

/* collect ranks [S0, S0+LEN) (REV = reverse order) and push onto the stack:
   members, or (member,score) pairs if WS. The read lock must be HELD on entry;
   it is released (after the snapshot) before anything is pushed. */
#define EMIT_COLLECTED(S0, LEN, REV, WS) STMT_START { \
    ss_rcollect_t col = { NULL, NULL, 0, 0 }; \
    int ok_ = ss_collect_range(h, (S0), (LEN), (REV), &col); \
    ss_rwlock_rdunlock(h); \
    if (!ok_) { free(col.members); free(col.scores); croak("range: out of memory"); } \
    EXTEND(SP, (SSize_t)((WS) ? col.n * 2 : col.n)); \
    for (size_t i_ = 0; i_ < col.n; i_++) { \
        PUSHs(sv_2mortal(newSViv((IV)col.members[i_]))); \
        if (WS) PUSHs(sv_2mortal(newSVnv(col.scores[i_]))); \
    } \
    free(col.members); free(col.scores); \
} STMT_END

/* parse trailing "withscores => bool", "limit => n", "offset => n" options */
static void ss_parse_range_opts(pTHX_ SV **sp, int first, int items, int *ws, IV *limit, IV *offset) {
    if ((items - first) % 2 != 0) croak("range options must be key => value pairs");
    for (int ai = first; ai + 1 < items; ai += 2) {
        const char *k = SvPV_nolen(sp[ai]);
        if      (!strcmp(k, "withscores")) *ws = SvTRUE(sp[ai+1]);
        else if (limit  && !strcmp(k, "limit"))  *limit  = SvIV(sp[ai+1]);
        else if (offset && !strcmp(k, "offset")) *offset = SvIV(sp[ai+1]);
        else croak("unknown option '%s'", k);
    }
}

/* normalize Perl-style [start, stop] rank indices into a forward [*a, *b] window
   (negatives count from the end); returns true if the window is non-empty */
static int ss_rank_window(uint32_t cnt, IV start, IV stop, IV *a, IV *b) {
    *a = start; *b = stop;
    if (*a < 0) *a += (IV)cnt;
    if (*b < 0) *b += (IV)cnt;
    if (*a < 0) *a = 0;
    if (*b >= (IV)cnt) *b = (IV)cnt - 1;
    return cnt > 0 && *a <= *b;
}

MODULE = Data::SortedSet::Shared  PACKAGE = Data::SortedSet::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, max_entries, ...)
    const char *class
    SV *path
    UV max_entries
  PREINIT:
    char errbuf[SS_ERR_BUFLEN];
  CODE:
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    if (max_entries > UINT32_MAX) croak("Data::SortedSet::Shared->new: max_entries exceeds 2^32");
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    SsHandle *h = ss_create(p, (uint32_t)max_entries, mode, errbuf);
    if (!h) croak("Data::SortedSet::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, max_entries)
    const char *class
    const char *name
    UV max_entries
  PREINIT:
    char errbuf[SS_ERR_BUFLEN];
  CODE:
    if (max_entries > UINT32_MAX) croak("Data::SortedSet::Shared->new_memfd: max_entries exceeds 2^32");
    SsHandle *h = ss_create_memfd(name, (uint32_t)max_entries, errbuf);
    if (!h) croak("Data::SortedSet::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[SS_ERR_BUFLEN];
  CODE:
    SsHandle *h = ss_open_fd(fd, errbuf);
    if (!h) croak("Data::SortedSet::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::SortedSet::Shared")) {
        SsHandle *h = INT2PTR(SsHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); ss_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    ss_rwlock_rdlock(h);
    RETVAL = h->hdr->count;
    ss_rwlock_rdunlock(h);
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

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    ss_rwlock_wrlock(h);
    ss_clear_locked(h);
    ss_rwlock_wrunlock(h);

SV *
add(self, member, score)
    SV *self
    IV member
    NV score
  PREINIT:
    EXTRACT(self);
    int rc;
  CODE:
    if (score != score) croak("add: score must not be NaN");
    ss_rwlock_wrlock(h);
    rc = ss_add_locked(h, (int64_t)member, (double)score);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    ss_rwlock_wrunlock(h);
    RETVAL = (rc < 0) ? &PL_sv_undef : newSViv(rc);
  OUTPUT:
    RETVAL

SV *
score(self, member)
    SV *self
    IV member
  PREINIT:
    EXTRACT(self);
    double sc;
  CODE:
    ss_rwlock_rdlock(h);
    int found = ss_idx_get(h, (int64_t)member, &sc);
    ss_rwlock_rdunlock(h);
    RETVAL = found ? newSVnv(sc) : &PL_sv_undef;
  OUTPUT:
    RETVAL

bool
exists(self, member)
    SV *self
    IV member
  PREINIT:
    EXTRACT(self);
    double sc;
  CODE:
    ss_rwlock_rdlock(h);
    RETVAL = ss_idx_get(h, (int64_t)member, &sc);
    ss_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

bool
remove(self, member)
    SV *self
    IV member
  PREINIT:
    EXTRACT(self);
  CODE:
    ss_rwlock_wrlock(h);
    RETVAL = ss_remove_locked(h, (int64_t)member);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    ss_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

NV
incr(self, member, delta)
    SV *self
    IV member
    NV delta
  PREINIT:
    EXTRACT(self);
    double out;
    int rc;
  CODE:
    if (delta != delta) croak("incr: delta must not be NaN");
    ss_rwlock_wrlock(h);
    rc = ss_incr_locked(h, (int64_t)member, (double)delta, &out);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    ss_rwlock_wrunlock(h);
    if (rc == -1) croak("incr: max_entries exhausted");
    if (rc == -2) croak("incr: result is NaN");
    RETVAL = out;
  OUTPUT:
    RETVAL

void
pop_min(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    {
        int64_t m; double s; int ok;
        ss_rwlock_wrlock(h);
        ok = ss_pop_locked(h, 0, &m, &s);
        if (ok) __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        ss_rwlock_wrunlock(h);
        if (ok) { EXTEND(SP, 2); PUSHs(sv_2mortal(newSViv((IV)m))); PUSHs(sv_2mortal(newSVnv(s))); }
    }

void
pop_max(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    {
        int64_t m; double s; int ok;
        ss_rwlock_wrlock(h);
        ok = ss_pop_locked(h, 1, &m, &s);
        if (ok) __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        ss_rwlock_wrunlock(h);
        if (ok) { EXTEND(SP, 2); PUSHs(sv_2mortal(newSViv((IV)m))); PUSHs(sv_2mortal(newSVnv(s))); }
    }

bool
_validate(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    ss_rwlock_rdlock(h);
    RETVAL = ss_validate_tree(h);
    ss_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

SV *
rank(self, member)
    SV *self
    IV member
  PREINIT:
    EXTRACT(self);
    double sc;
  CODE:
    ss_rwlock_rdlock(h);
    RETVAL = ss_idx_get(h, (int64_t)member, &sc)
        ? newSVuv(ss_rank_of(h, sc, (int64_t)member)) : &PL_sv_undef;
    ss_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

SV *
rev_rank(self, member)
    SV *self
    IV member
  PREINIT:
    EXTRACT(self);
    double sc;
  CODE:
    ss_rwlock_rdlock(h);
    RETVAL = ss_idx_get(h, (int64_t)member, &sc)
        ? newSVuv(h->hdr->count - 1 - ss_rank_of(h, sc, (int64_t)member)) : &PL_sv_undef;
    ss_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

SV *
at_rank(self, rank)
    SV *self
    IV rank
  PREINIT:
    EXTRACT(self);
  CODE:
    ss_rwlock_rdlock(h);
    {
        uint32_t cnt = h->hdr->count;
        IV r = rank; if (r < 0) r += (IV)cnt;
        if (r >= 0 && (uint64_t)r < cnt) {          /* compare in 64-bit; large r must not truncate to an in-range index */
            int pos; uint32_t leaf = ss_at_rank(h, (uint32_t)r, &pos);
            RETVAL = (leaf != SS_NONE) ? newSViv((IV)h->nodes[leaf].members[pos]) : &PL_sv_undef;
        } else RETVAL = &PL_sv_undef;
    }
    ss_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

UV
count_in_score(self, min, max)
    SV *self
    NV min
    NV max
  PREINIT:
    EXTRACT(self);
  CODE:
    ss_rwlock_rdlock(h);
    RETVAL = ss_count_in_score(h, (double)min, (double)max, NULL);
    ss_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

void
range_by_rank(self, start, stop, ...)
    SV *self
    IV start
    IV stop
  PREINIT:
    EXTRACT(self);
  PPCODE:
    int ws = 0;
    ss_parse_range_opts(aTHX_ &ST(0), 3, items, &ws, NULL, NULL);
    ss_rwlock_rdlock(h);
    {
        uint32_t s0 = 0, len = 0;
        IV a, b;
        if (ss_rank_window(h->hdr->count, start, stop, &a, &b)) { s0 = (uint32_t)a; len = (uint32_t)(b - a + 1); }
        EMIT_COLLECTED(s0, len, 0, ws);
    }

void
rev_range_by_rank(self, start, stop, ...)
    SV *self
    IV start
    IV stop
  PREINIT:
    EXTRACT(self);
  PPCODE:
    int ws = 0;
    ss_parse_range_opts(aTHX_ &ST(0), 3, items, &ws, NULL, NULL);
    ss_rwlock_rdlock(h);
    {
        uint32_t cnt = h->hdr->count, s0 = 0, len = 0;
        IV a, b;
        if (ss_rank_window(cnt, start, stop, &a, &b)) { s0 = (uint32_t)((IV)cnt - 1 - b); len = (uint32_t)(b - a + 1); }
        EMIT_COLLECTED(s0, len, 1, ws);
    }

void
range_by_score(self, min, max, ...)
    SV *self
    NV min
    NV max
  PREINIT:
    EXTRACT(self);
  PPCODE:
    int ws = 0; IV limit = -1, offset = 0;
    ss_parse_range_opts(aTHX_ &ST(0), 3, items, &ws, &limit, &offset);
    ss_rwlock_rdlock(h);
    {
        uint32_t lo;
        uint32_t win = ss_count_in_score(h, (double)min, (double)max, &lo);
        uint32_t off = (offset > 0) ? (offset >= (IV)win ? win : (uint32_t)offset) : 0;
        uint32_t s0 = lo, len = 0;
        if (off < win) { s0 = lo + off; len = win - off; if (limit >= 0 && limit < (IV)len) len = (uint32_t)limit; }
        EMIT_COLLECTED(s0, len, 0, ws);
    }

void
rev_range_by_score(self, max, min, ...)
    SV *self
    NV max
    NV min
  PREINIT:
    EXTRACT(self);
  PPCODE:
    int ws = 0; IV limit = -1, offset = 0;
    ss_parse_range_opts(aTHX_ &ST(0), 3, items, &ws, &limit, &offset);
    ss_rwlock_rdlock(h);
    {
        uint32_t lo;
        uint32_t win = ss_count_in_score(h, (double)min, (double)max, &lo);
        uint32_t off = (offset > 0) ? (offset >= (IV)win ? win : (uint32_t)offset) : 0;
        uint32_t s0 = lo, len = 0;
        if (off < win) { len = win - off; if (limit >= 0 && limit < (IV)len) len = (uint32_t)limit;
                         s0 = lo + (win - off - len); }
        EMIT_COLLECTED(s0, len, 1, ws);
    }

void
peek_min(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    ss_rwlock_rdlock(h);
    if (h->hdr->root != SS_NONE && ss_node_ok(h, h->hdr->leftmost)) {
        SsNode *nd = &h->nodes[h->hdr->leftmost];
        IV m = (IV)nd->members[0]; NV s = nd->scores[0];
        ss_rwlock_rdunlock(h);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(m)));
        PUSHs(sv_2mortal(newSVnv(s)));
    } else ss_rwlock_rdunlock(h);

void
peek_max(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    ss_rwlock_rdlock(h);
    if (h->hdr->root != SS_NONE && ss_node_ok(h, h->hdr->rightmost)) {
        SsNode *nd = &h->nodes[h->hdr->rightmost];
        IV m = (IV)nd->members[nd->num - 1]; NV s = nd->scores[nd->num - 1];
        ss_rwlock_rdunlock(h);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(m)));
        PUSHs(sv_2mortal(newSVnv(s)));
    } else ss_rwlock_rdunlock(h);

void
each(self, cb)
    SV *self
    SV *cb
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) croak("each: callback must be a code ref");
    {
        ss_rcollect_t col = { NULL, NULL, 0, 0 };
        ss_rwlock_rdlock(h);
        int ok = ss_collect_range(h, 0, h->hdr->count, 0, &col);
        ss_rwlock_rdunlock(h);
        if (!ok) { free(col.members); free(col.scores); croak("each: out of memory"); }
        for (size_t i = 0; i < col.n; i++) {
            dSP; ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSViv((IV)col.members[i])));
            XPUSHs(sv_2mortal(newSVnv(col.scores[i])));
            PUTBACK;
            call_sv(cb, G_VOID|G_DISCARD|G_EVAL);
            FREETMPS; LEAVE;
            if (SvTRUE(ERRSV)) { free(col.members); free(col.scores); croak_sv(ERRSV); }
        }
        free(col.members); free(col.scores);
    }

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
    if (ss_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    {
        const char *p = NULL;
        if (sv_isobject(self) && sv_derived_from(self, "Data::SortedSet::Shared")) {
            SsHandle *h = INT2PTR(SsHandle*, SvIV(SvRV(self)));
            if (h) p = h->path;
        } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
            p = SvPV_nolen(ST(1));
        }
        if (p && unlink(p) != 0 && errno != ENOENT) croak("unlink: %s", strerror(errno));
    }

int
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = ss_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

int
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
    RETVAL = ss_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        int64_t v = ss_eventfd_consume(h);
        RETVAL = (v < 0) ? &PL_sv_undef : newSVuv((UV)v);
    }
  OUTPUT:
    RETVAL

IV
add_many(self, rows)
    SV *self
    SV *rows
  PREINIT:
    EXTRACT(self);
    int added = 0;
  CODE:
    if (!SvROK(rows) || SvTYPE(SvRV(rows)) != SVt_PVAV)
        croak("add_many: expected an arrayref of [member, score] rows");
    {
        AV *av = (AV *)SvRV(rows);
        SSize_t nr = av_len(av) + 1;
        ss_rwlock_wrlock(h);
        for (SSize_t i = 0; i < nr; i++) {
            SV **rv = av_fetch(av, i, 0);
            if (!rv || !SvROK(*rv) || SvTYPE(SvRV(*rv)) != SVt_PVAV) continue;   /* skip malformed */
            AV *row = (AV *)SvRV(*rv);
            if (av_len(row) + 1 < 2) continue;
            SV **ms = av_fetch(row, 0, 0), **sv = av_fetch(row, 1, 0);
            if (!ms || !sv) continue;
            double score = SvNV(*sv);
            if (score != score) continue;                                       /* skip NaN */
            int rc = ss_add_locked(h, (int64_t)SvIV(*ms), score);
            if (rc == 1) added++;
            else if (rc == -1) break;                                           /* pool full */
        }
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        ss_rwlock_wrunlock(h);
    }
    RETVAL = added;
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
        ss_rwlock_rdlock(h);
        SsHeader *hd = h->hdr;
        uint32_t nfree = 0, f = hd->node_free_head;
        /* node_free_head / parent free-links are file-stored: bound the index and
           cap iterations so a crafted out-of-range or cyclic free-list can't OOB
           or spin (never taken for a valid free-list of length <= node_capacity) */
        while (f != SS_NONE && ss_node_ok(h, f) && nfree <= hd->node_capacity) { nfree++; f = h->nodes[f].parent; }
        uint32_t iload = hd->count;   /* backward-shift delete leaves no tombstones: occupied slots == count */
        hv_stores(hv, "count",         newSVuv(hd->count));
        hv_stores(hv, "max_entries",   newSVuv(hd->max_entries));
        hv_stores(hv, "height",        newSVuv(hd->height));
        hv_stores(hv, "node_capacity", newSVuv(hd->node_capacity));
        hv_stores(hv, "nodes_used",    newSVuv(hd->node_capacity - nfree));
        hv_stores(hv, "index_slots",   newSVuv(hd->index_slots));
        hv_stores(hv, "index_load",    newSVnv((double)iload / (double)hd->index_slots));
        hv_stores(hv, "ops",           newSVuv(hd->stat_ops));
        hv_stores(hv, "mmap_size",     newSVuv((UV)h->mmap_size));
        ss_rwlock_rdunlock(h);
        RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL
