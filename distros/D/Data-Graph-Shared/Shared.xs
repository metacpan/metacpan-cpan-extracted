#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "graph.h"

#define EXTRACT_GRAPH(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Graph::Shared")) \
        croak("Expected a Data::Graph::Shared object"); \
    GraphHandle *h = INT2PTR(GraphHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Graph::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

#define REQUIRE_NODE(h, node) do { \
    if ((uint32_t)(node) >= (h)->hdr->max_nodes || !graph_bit_set((h)->node_bitmap, (uint32_t)(node))) { \
        graph_mutex_unlock((h)->hdr); \
        croak("node %u does not exist", (unsigned)(node)); \
    } \
} while (0)

MODULE = Data::Graph::Shared  PACKAGE = Data::Graph::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, max_nodes, max_edges)
    const char *class
    SV *path
    UV max_nodes
    UV max_edges
  PREINIT:
    char errbuf[GRAPH_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    GraphHandle *h = graph_create(p, (uint32_t)max_nodes, (uint32_t)max_edges, errbuf);
    if (!h) croak("Data::Graph::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, max_nodes, max_edges)
    const char *class
    const char *name
    UV max_nodes
    UV max_edges
  PREINIT:
    char errbuf[GRAPH_ERR_BUFLEN];
  CODE:
    GraphHandle *h = graph_create_memfd(name, (uint32_t)max_nodes, (uint32_t)max_edges, errbuf);
    if (!h) croak("Data::Graph::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[GRAPH_ERR_BUFLEN];
  CODE:
    GraphHandle *h = graph_open_fd(fd, errbuf);
    if (!h) croak("Data::Graph::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    GraphHandle *h = INT2PTR(GraphHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    graph_destroy(h);

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    if (graph_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p = NULL;
    if (sv_isobject(self_or_class)) {
        GraphHandle *h = INT2PTR(GraphHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = graph_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = graph_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    int64_t n = graph_eventfd_consume(h);
    RETVAL = (n >= 0) ? newSViv((IV)n) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
add_node(self, data)
    SV *self
    IV data
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    int32_t idx = graph_add_node(h, (int64_t)data);
    RETVAL = (idx >= 0) ? newSViv((IV)idx) : &PL_sv_undef;
  OUTPUT:
    RETVAL

bool
add_edge(self, src, dst, ...)
    SV *self
    UV src
    UV dst
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    int64_t weight = (items > 3) ? (int64_t)SvIV(ST(3)) : 1;
    RETVAL = graph_add_edge(h, (uint32_t)src, (uint32_t)dst, weight);
  OUTPUT:
    RETVAL

bool
remove_node(self, node)
    SV *self
    UV node
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = graph_remove_node(h, (uint32_t)node);
  OUTPUT:
    RETVAL

bool
remove_node_full(self, node)
    SV *self
    UV node
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = graph_remove_node_full(h, (uint32_t)node);
  OUTPUT:
    RETVAL

bool
has_node(self, node)
    SV *self
    UV node
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = graph_has_node(h, (uint32_t)node);
  OUTPUT:
    RETVAL

IV
node_data(self, node)
    SV *self
    UV node
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    graph_mutex_lock(h->hdr);
    REQUIRE_NODE(h, node);
    RETVAL = (IV)h->node_data[(uint32_t)node];
    graph_mutex_unlock(h->hdr);
  OUTPUT:
    RETVAL

void
set_node_data(self, node, data)
    SV *self
    UV node
    IV data
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    graph_mutex_lock(h->hdr);
    REQUIRE_NODE(h, node);
    h->node_data[(uint32_t)node] = (int64_t)data;
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    graph_mutex_unlock(h->hdr);

void
neighbors(self, node)
    SV *self
    UV node
  PREINIT:
    EXTRACT_GRAPH(self);
  PPCODE:
    /* Collect edges under lock, then build Perl SVs outside it:
     * newAV/newSVuv/newSViv can longjmp on OOM, which would leak the
     * process-shared mutex to peers (no automatic cleanup for futex). */
    graph_mutex_lock(h->hdr);
    REQUIRE_NODE(h, node);
    uint32_t deg = graph_degree(h, (uint32_t)node);
    uint32_t eidx = h->node_heads[(uint32_t)node];
    uint32_t *dsts = deg ? (uint32_t *)malloc(deg * sizeof(uint32_t)) : NULL;
    int64_t  *wts  = deg ? (int64_t *)malloc(deg * sizeof(int64_t))  : NULL;
    if (deg && (!dsts || !wts)) {
        free(dsts); free(wts);
        graph_mutex_unlock(h->hdr);
        croak("neighbors: out of memory");
    }
    uint32_t i = 0;
    while (eidx != GRAPH_NONE && i < deg) {
        dsts[i] = h->edges[eidx].dst;
        wts[i]  = h->edges[eidx].weight;
        eidx = h->edges[eidx].next;
        i++;
    }
    graph_mutex_unlock(h->hdr);
    EXTEND(SP, (SSize_t)i);
    for (uint32_t j = 0; j < i; j++) {
        AV *pair = newAV();
        av_push(pair, newSVuv(dsts[j]));
        av_push(pair, newSViv((IV)wts[j]));
        PUSHs(sv_2mortal(newRV_noinc((SV *)pair)));
    }
    free(dsts); free(wts);

UV
degree(self, node)
    SV *self
    UV node
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    graph_mutex_lock(h->hdr);
    REQUIRE_NODE(h, node);
    RETVAL = graph_degree(h, (uint32_t)node);
    graph_mutex_unlock(h->hdr);
  OUTPUT:
    RETVAL

UV
node_count(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = __atomic_load_n(&h->hdr->node_count, __ATOMIC_ACQUIRE);
  OUTPUT:
    RETVAL

UV
edge_count(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = __atomic_load_n(&h->hdr->edge_count, __ATOMIC_ACQUIRE);
  OUTPUT:
    RETVAL

UV
max_nodes(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = h->hdr->max_nodes;
  OUTPUT:
    RETVAL

UV
max_edges(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = h->hdr->max_edges;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    HV *hv = newHV();
    hv_store(hv, "node_count", 10, newSVuv(__atomic_load_n(&h->hdr->node_count, __ATOMIC_ACQUIRE)), 0);
    hv_store(hv, "edge_count", 10, newSVuv(__atomic_load_n(&h->hdr->edge_count, __ATOMIC_ACQUIRE)), 0);
    hv_store(hv, "max_nodes", 9, newSVuv(h->hdr->max_nodes), 0);
    hv_store(hv, "max_edges", 9, newSVuv(h->hdr->max_edges), 0);
    hv_store(hv, "ops", 3, newSVuv((UV)__atomic_load_n(&h->hdr->stat_ops, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL
