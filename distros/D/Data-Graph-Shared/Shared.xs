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

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    GraphHandle *h = INT2PTR(GraphHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    graph_destroy(h);

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
    if ((uint32_t)node >= h->hdr->max_nodes || !graph_bit_set(h->node_bitmap, (uint32_t)node)) {
        graph_mutex_unlock(h->hdr);
        croak("node %u does not exist", (unsigned)node);
    }
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
    if ((uint32_t)node >= h->hdr->max_nodes || !graph_bit_set(h->node_bitmap, (uint32_t)node)) {
        graph_mutex_unlock(h->hdr);
        croak("node %u does not exist", (unsigned)node);
    }
    h->node_data[(uint32_t)node] = (int64_t)data;
    graph_mutex_unlock(h->hdr);

void
neighbors(self, node)
    SV *self
    UV node
  PREINIT:
    EXTRACT_GRAPH(self);
  PPCODE:
    graph_mutex_lock(h->hdr);
    if ((uint32_t)node >= h->hdr->max_nodes || !graph_bit_set(h->node_bitmap, (uint32_t)node)) {
        graph_mutex_unlock(h->hdr);
        croak("node %u does not exist", (unsigned)node);
    }
    uint32_t eidx = h->node_heads[(uint32_t)node];
    AV *results = newAV();
    while (eidx != GRAPH_NONE) {
        AV *pair = newAV();
        av_push(pair, newSVuv(h->edges[eidx].dst));
        av_push(pair, newSViv((IV)h->edges[eidx].weight));
        av_push(results, newRV_noinc((SV *)pair));
        eidx = h->edges[eidx].next;
    }
    graph_mutex_unlock(h->hdr);
    SSize_t count = av_top_index(results) + 1;
    if (count > 0) {
        EXTEND(SP, count);
        for (SSize_t i = 0; i < count; i++)
            PUSHs(sv_2mortal(SvREFCNT_inc(*av_fetch(results, i, 0))));
    }
    SvREFCNT_dec((SV *)results);

UV
degree(self, node)
    SV *self
    UV node
  PREINIT:
    EXTRACT_GRAPH(self);
  CODE:
    graph_mutex_lock(h->hdr);
    if ((uint32_t)node >= h->hdr->max_nodes || !graph_bit_set(h->node_bitmap, (uint32_t)node)) {
        graph_mutex_unlock(h->hdr);
        croak("node %u does not exist", (unsigned)node);
    }
    RETVAL = graph_neighbors(h, (uint32_t)node, NULL, NULL, 0);
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
    hv_store(hv, "ops", 3, newSVuv((UV)h->hdr->stat_ops), 0);
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
