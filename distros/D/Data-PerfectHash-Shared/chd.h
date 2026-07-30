#ifndef CHD_H
#define CHD_H
#include "phash.h"
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

/* Average keys per bucket: bucket_count r = ceil(n / PH_LAMBDA). lambda=6 is
 * chosen empirically as the largest value that still reliably converges on the
 * first placement attempt (swept up to n=500k), giving the smallest index at
 * ~4.0 bits/key; lower lambda trades index size for a faster build. */
#define PH_LAMBDA 6u

/* TLS qualifier for the qsort() context pointers below: ph_build() may run
 * concurrently in multiple ithreads, and a plain file-static context would let
 * one thread's qsort() read another's pointer (OOB / silent corruption). */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
# define PH_TLS _Thread_local
#elif defined(__GNUC__)
# define PH_TLS __thread
#else
# define PH_TLS
#endif

typedef struct {
    uint32_t type_tag;   /* PH_BUILDER_TAG; must stay the first member -- see phash.h */
    uint32_t key_type;
    int64_t *ints; size_t nint, capint;                 /* int keys */
    uint8_t *arena; size_t arena_len, arena_cap;        /* str bytes */
    PhStrSlot *sslots; size_t nstr, capstr;             /* (off,len) into arena */
} PhBuilder;

/* ph_builder_new/add_int/add_str run only from Shared.xs (chd.h compiled into
 * the XS unit after perl.h), so croak() is the right way to fail here: unlike
 * ph_build below there's no caller-supplied err buffer at this layer, and croak unwinds cleanly without leaving a half-built PhBuilder. */
static PhBuilder *ph_builder_new(uint32_t type) {
    PhBuilder *b = (PhBuilder *)calloc(1, sizeof *b);
    if (!b) croak("out of memory");
    b->type_tag = PH_BUILDER_TAG; b->key_type = type; return b;
}
static void ph_builder_add_int(PhBuilder *b, int64_t k) {
    if (b->nint == b->capint) {
        size_t newcap = b->capint ? b->capint*2 : 16;
        int64_t *p = (int64_t*)realloc(b->ints, newcap*sizeof(int64_t));
        if (!p) croak("out of memory");
        b->ints = p; b->capint = newcap;
    }
    b->ints[b->nint++] = k;
}
static void ph_builder_add_str(PhBuilder *b, const void *k, size_t len) {
    if (b->arena_len + len > b->arena_cap) {
        size_t newcap = b->arena_cap;
        while (newcap < b->arena_len + len) newcap = newcap ? newcap*2 : 4096;
        uint8_t *p = (uint8_t*)realloc(b->arena, newcap);
        if (!p) croak("out of memory");
        b->arena = p; b->arena_cap = newcap;
    }
    if (b->nstr == b->capstr) {
        size_t newcap = b->capstr ? b->capstr*2 : 16;
        PhStrSlot *p = (PhStrSlot*)realloc(b->sslots, newcap*sizeof(PhStrSlot));
        if (!p) croak("out of memory");
        b->sslots = p; b->capstr = newcap;
    }
    PhStrSlot s = { b->arena_len, len };
    memcpy(b->arena + b->arena_len, k, len); b->arena_len += len;
    b->sslots[b->nstr++] = s;
}
static size_t ph_builder_count(const PhBuilder *b) { return b->key_type==PH_TYPE_INT ? b->nint : b->nstr; }
static void ph_builder_free(PhBuilder *b) { if(!b) return; free(b->ints); free(b->arena); free(b->sslots); free(b); }

/* --- CHD build: comparator helpers -------------------------------------
 * The two qsort() comparators below need extra context (the builder, for byte
 * comparison; the bucket-size array, for the descending sort) that plain
 * qsort() has no way to pass through. qsort_r() would do it, but its argument
 * order differs between glibc and BSD/macOS -- so instead, a pair of PH_TLS
 * "current call" pointers, set immediately before each qsort() and read only from inside it. */
static PH_TLS const PhBuilder *ph_cmp_ctx_builder;
static PH_TLS const uint64_t  *ph_cmp_ctx_bsize;

static int cmp_i64(const void*a,const void*b){int64_t x=*(const int64_t*)a,y=*(const int64_t*)b;return (x>y)-(x<y);}

/* Hash of the survivor key at builder-index idx (int: value; str: arena bytes). */
static inline uint64_t ph_hash_of(const PhBuilder *b, size_t idx, uint64_t seed) {
    if (b->key_type == PH_TYPE_INT) return ph_h_int(b->ints[idx], seed);
    { const PhStrSlot *ss = &b->sslots[idx]; return ph_h_str(b->arena + ss->off, ss->len, seed); }
}

/* Lexicographic order over string keys, referenced by index into b->sslots. */
static int ph_cmp_stridx(const void *pa, const void *pb) {
    size_t ia = *(const size_t*)pa, ib = *(const size_t*)pb;
    const PhBuilder *b = ph_cmp_ctx_builder;
    const PhStrSlot *sa = &b->sslots[ia], *sb = &b->sslots[ib];
    size_t n = sa->len < sb->len ? sa->len : sb->len;
    int c = n ? memcmp(b->arena + sa->off, b->arena + sb->off, n) : 0;
    if (c) return c;
    if (sa->len != sb->len) return (sa->len > sb->len) - (sa->len < sb->len);
    return 0;
}
static int ph_stridx_ne(const PhBuilder *b, size_t ia, size_t ib) {
    const PhStrSlot *sa = &b->sslots[ia], *sb = &b->sslots[ib];
    return sa->len != sb->len || memcmp(b->arena + sa->off, b->arena + sb->off, sa->len) != 0;
}
/* Descending sort of bucket ids by size -- standard CHD heuristic: hardest (largest) buckets get first pick of displacement values. */
static int ph_cmp_bkt_desc(const void *pa, const void *pb) {
    uint64_t ba = *(const uint64_t*)pa, bb = *(const uint64_t*)pb;
    uint64_t sa = ph_cmp_ctx_bsize[ba], sb = ph_cmp_ctx_bsize[bb];
    return (sa < sb) - (sa > sb);
}
/* Sum of survivor key lengths -- the str arena size needed in the image. */
static uint64_t ph_arena_len_final(const PhBuilder *b, const size_t *idx, size_t N) {
    uint64_t total = 0; size_t i;
    for (i = 0; i < N; i++) total += b->sslots[idx[i]].len;
    return total;
}

/* Build over the collected keys; write image to path. err on failure. */
static int ph_build(PhBuilder *b, const char *path, mode_t mode, char *err, size_t el) {
    /* --- gather N distinct keys as (hashable) entries --- */
    size_t N;
    /* Index array 0..N-1 into the builder's key store, after dedup. Every
     * pointer below is hoisted here (NULL until allocated) so PHB_OOM() can
     * free(NULL)-safely unwind from any allocation site, including img itself
     * -- which is fully assembled in memory before the output file is ever opened, so OOM never leaves a partial file behind. */
    size_t *idx = NULL;                         /* surviving key indices */
    uint32_t *disp = NULL;
    char *occ = NULL;
    uint64_t *bkt_of = NULL, *order = NULL, *bsize = NULL, *tmp_slots = NULL, *boff = NULL, *mem = NULL;
    uint8_t *img = NULL;
#define PHB_FREEALL() do { \
        free(idx);free(disp);free(occ);free(bkt_of);free(order);free(bsize); \
        free(tmp_slots);free(boff);free(mem);free(img); \
    } while (0)
#define PHB_OOM() do { PHB_FREEALL(); snprintf(err,el,"out of memory"); return -1; } while (0)
    if (b->key_type == PH_TYPE_INT) {
        /* b->ints is NULL when empty; qsort() declares its base nonnull, so
         * qsort(NULL,0,...) is UB even though it would sort nothing -- guard it. */
        if (b->nint) qsort(b->ints, b->nint, sizeof(int64_t), cmp_i64);
        N = 0; for (size_t i=0;i<b->nint;i++){ if(i==0||b->ints[i]!=b->ints[i-1]) b->ints[N++]=b->ints[i]; }
        idx = (size_t*)malloc((N?N:1)*sizeof(size_t)); if (!idx) PHB_OOM();
        for(size_t i=0;i<N;i++) idx[i]=i;
    } else {
        /* dedup str keys: sort an index array over the arena bytes, then unique it */
        N = b->nstr;
        idx = (size_t*)malloc((N?N:1)*sizeof(size_t)); if (!idx) PHB_OOM();
        for(size_t i=0;i<N;i++) idx[i]=i;
        ph_cmp_ctx_builder = b;
        qsort(idx, N, sizeof(size_t), ph_cmp_stridx);
        size_t w=0; for(size_t i=0;i<N;i++){ if(i==0 || ph_stridx_ne(b, idx[i], idx[i-1])) idx[w++]=idx[i]; }
        N = w;
    }
    /* n==N: exactly minimal, no slack. sort-desc (below) places multi-key
     * buckets first while slots are still free; the working disp[] stays a
     * full uint32 here (only the emitted image, further down, is byte-packed to
     * the minimal width), so even the last free slot is found within the 2^32
     * search range. r==1 for N==0 keeps the '% r' bucketing well-defined (no key ever reaches it). */
    uint64_t n = N, r = N ? (N/PH_LAMBDA + (N%PH_LAMBDA ? 1 : 0)) : 1;
    disp = (uint32_t*)calloc(r, sizeof(uint32_t)); if (!disp) PHB_OOM();
    occ = (char*)calloc(n?n:1,1); if (!occ) PHB_OOM();
    /* bucket assignment buffers */
    bkt_of = (uint64_t*)malloc((N?N:1)*sizeof(uint64_t)); if (!bkt_of) PHB_OOM();
    order  = (uint64_t*)malloc(r*sizeof(uint64_t)); if (!order) PHB_OOM();    /* bucket ids sorted by size desc */
    bsize  = (uint64_t*)malloc(r*sizeof(uint64_t)); if (!bsize) PHB_OOM();
    uint64_t seed0 = 0x243F6A8885A308D3ull;
    uint64_t tmp_slots_cap = n;
    tmp_slots = (uint64_t*)malloc((tmp_slots_cap?tmp_slots_cap:1)*sizeof(uint64_t)); if (!tmp_slots) PHB_OOM();
    /* keys grouped per bucket: build a CSR (offsets + members) each attempt */
    boff = (uint64_t*)malloc((r+1)*sizeof(uint64_t)); if (!boff) PHB_OOM();
    mem  = (uint64_t*)malloc((N?N:1)*sizeof(uint64_t)); if (!mem) PHB_OOM();

    /* Cap the per-bucket displacement scan far above any real max_d (real sets
     * need ~4*n; dcap is 256*n, floored at 65536), so genuine convergence is
     * untouched but a pathological/adversarial bucket bails out quickly and
     * reseeds instead of scanning the full 2^32 range for hours. */
    uint64_t dcap = (n > 0xFFFFFFFFull/256 ? 0xFFFFFFFFull : 256*n);
    if (dcap < 65536) dcap = 65536;

    int placed = 0;
    for (int attempt = 0; attempt < 200 && !placed; attempt++, seed0 = seed0*6364136223846793005ull + 1) {
        memset(occ,0,n); memset(disp,0,r*sizeof(uint32_t)); memset(bsize,0,r*sizeof(uint64_t));
        for (size_t i=0;i<N;i++){ uint64_t hb = ph_hash_of(b, idx[i], seed0); uint64_t bk = hb % r; bkt_of[i]=bk; bsize[bk]++; }
        boff[0]=0; for (uint64_t k2=0;k2<r;k2++) boff[k2+1]=boff[k2]+bsize[k2];
        { uint64_t *cur=(uint64_t*)malloc(r*sizeof(uint64_t)); if (!cur) PHB_OOM();
          memcpy(cur,boff,r*sizeof(uint64_t));
          for(size_t i=0;i<N;i++){ mem[cur[bkt_of[i]]++]=idx[i]; } free(cur); }
        for (uint64_t k2=0;k2<r;k2++) order[k2]=k2;
        ph_cmp_ctx_bsize = bsize;
        qsort(order,r,sizeof(uint64_t),ph_cmp_bkt_desc);
        int ok = 1;
        for (uint64_t oi=0; oi<r && ok; oi++) {
            uint64_t bk=order[oi]; uint64_t cnt=bsize[bk]; if(!cnt) continue;
            int found=0;
            /* Search up to dcap (<= UINT32_MAX); d is uint64_t purely so
             * "d <= dcap; d++" terminates cleanly instead of wrapping a uint32_t back to 0 when dcap == UINT32_MAX. */
            for (uint64_t d=0; d<=dcap; d++) {
                int good=1; uint64_t m=ph_mix(seed0,d);
                for (uint64_t j=0;j<cnt;j++){ uint64_t s=ph_hash_of(b, mem[boff[bk]+j], m)%n; tmp_slots[j]=s;
                    if (occ[s]) { good=0; break; }
                    for (uint64_t p=0;p<j;p++) if (tmp_slots[p]==s){ good=0; break; }
                    if(!good) break; }
                if (good){ for(uint64_t j=0;j<cnt;j++) occ[tmp_slots[j]]=1; disp[bk]=(uint32_t)d; found=1; break; }
            }
            if(!found) ok=0;
        }
        /* WARNING: must break here, not just set placed=1 and fall through.
         * The for-loop's increment (seed0 = seed0*...+1) still runs once more
         * even on the successful iteration -- only the *next* condition check
         * is skipped. Falling through would silently advance seed0 past the
         * value actually used to compute disp[]/bkt_of[] above, so the header
         * would record a seed inconsistent with the written displacement array -- has() would then fail for essentially every key. */
        if (ok) { placed = 1; break; }
    }
    if (!placed) { snprintf(err,el,"CHD build failed to converge (pathological key set)");
        PHB_FREEALL(); return -1; }

    /* --- pick the minimal byte width holding every displacement (r*disp_width
     * bytes instead of r*4). In practice max_d ~ n, so disp_width is 1..3 for
     * any realistic set (4 is the safety ceiling); always >=1, even for the empty set (r==1,d==0). */
    uint32_t max_d = 0;
    for (uint64_t k2=0;k2<r;k2++) if (disp[k2] > max_d) max_d = disp[k2];
    uint32_t disp_width = max_d <= 0xFFu ? 1u : max_d <= 0xFFFFu ? 2u : max_d <= 0xFFFFFFu ? 3u : 4u;

    /* --- compute the FINAL slot for each key, lay out the image, write it --- */
    uint64_t disp_off = sizeof(PhHeader);
    uint64_t disp_bytes = r * (uint64_t)disp_width;
    uint64_t slots_off = (disp_off + disp_bytes + 7) & ~(uint64_t)7;   /* 8-byte align slots[] (int64_t/PhStrSlot); disp[] is byte-packed, needs none */
    uint64_t slot_sz = (b->key_type==PH_TYPE_INT) ? sizeof(int64_t) : sizeof(PhStrSlot);
    uint64_t arena_off = slots_off + n*slot_sz;
    uint64_t arena_len = (b->key_type==PH_TYPE_STR) ? ph_arena_len_final(b, idx, N) : 0;  /* sum of surviving key lens */
    uint64_t file_size = arena_off + arena_len;
    img = (uint8_t*)calloc(file_size?file_size:1,1); if (!img) PHB_OOM();
    PhHeader *H = (PhHeader*)img;
    H->magic=PH_MAGIC; H->version=PH_VERSION; H->key_type=b->key_type; H->disp_width=disp_width;
    H->endian=PH_ENDIAN_MARK; H->n=n; H->bucket_count=r; H->seed0=seed0;
    H->disp_off=disp_off; H->disp_len=disp_bytes; H->slots_off=slots_off; H->slots_len=n*slot_sz;
    H->arena_off=arena_off; H->arena_len=arena_len; H->file_size=file_size;
    /* Emit disp[] byte-packed: disp_width little-endian bytes per entry, exactly
     * what ph_load_uint_le reads back. img is calloc'd, so all padding stays zero (deterministic image, no heap disclosure). */
    for (uint64_t bkt=0; bkt<r; bkt++) {
        uint32_t d = disp[bkt];
        for (uint32_t wi=0; wi<disp_width; wi++) img[disp_off + bkt*disp_width + wi] = (uint8_t)(d >> (8u*wi));
    }
    /* place each key at slot = hash(key, mix(seed0, disp[bucket])) % n */
    uint64_t awrite = 0;
    for (size_t i=0;i<N;i++){
        uint64_t bk = ph_hash_of(b, idx[i], seed0) % r;
        uint64_t slot = ph_hash_of(b, idx[i], ph_mix(seed0, disp[bk])) % n;
        if (b->key_type==PH_TYPE_INT) ((int64_t*)(img+slots_off))[slot] = b->ints[idx[i]];
        else { PhStrSlot *ss=&((PhStrSlot*)(img+slots_off))[slot]; size_t len=b->sslots[idx[i]].len;
               memcpy(img+arena_off+awrite, b->arena+b->sslots[idx[i]].off, len);
               ss->off=awrite; ss->len=len; awrite+=len; }
    }
    /* Atomic write: build a temp file in the SAME directory, then rename(2) it
     * over `path`. Readers mmap `path`, and O_TRUNC on a mapped file would
     * SIGBUS them; rename instead leaves the old inode alive until they unmap.
     * mkstemp creates it O_CREAT|O_EXCL 0600 (no symlink to follow, so unlike
     * ph_open's read side this needs no O_NOFOLLOW); fchmod applies the requested mode after. */
    size_t plen = strlen(path);
    char *tmp = (char*)malloc(plen + 12);
    if (!tmp) { snprintf(err,el,"out of memory"); PHB_FREEALL(); return -1; }
    memcpy(tmp, path, plen); memcpy(tmp+plen, ".tmpXXXXXX", 11);   /* 10 chars + NUL */
    int fd = mkstemp(tmp);                                          /* creates 0600, O_EXCL; fills XXXXXX */
    if (fd < 0) { snprintf(err,el,"mkstemp %s: %s", tmp, strerror(errno)); free(tmp); PHB_FREEALL(); return -1; }
    int rc = 0;
    if (fchmod(fd, mode) != 0) { snprintf(err,el,"fchmod: %s", strerror(errno)); rc=-1; }
    else { size_t off=0; while(off<file_size){ ssize_t w=write(fd,img+off,file_size-off); if(w<=0){snprintf(err,el,"write: %s",strerror(errno)); rc=-1; break;} off+=w; } }
    close(fd);
    if (rc==0 && rename(tmp, path) != 0) { snprintf(err,el,"rename %s: %s", path, strerror(errno)); rc=-1; }
    if (rc!=0) unlink(tmp);            /* leave no partial temp on failure */
    free(tmp);
    PHB_FREEALL();
    return rc;
}
#undef PHB_OOM
#undef PHB_FREEALL

#endif
