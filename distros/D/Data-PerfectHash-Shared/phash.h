#ifndef PHASH_H
#define PHASH_H
#include <stdint.h>
#include <string.h>
#include <stddef.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <stdio.h>

/* Older/rarer libc may lack O_NOFOLLOW; degrade to 0 (no-op) rather than fail to compile. */
#ifndef O_NOFOLLOW
#define O_NOFOLLOW 0
#endif

#define XXH_INLINE_ALL
#include "xxhash.h"

#define PH_MAGIC       0x31534850u   /* 'P''H''S''1' little-endian */
#define PH_VERSION     2u             /* v2: bucket_count=ceil(n/lambda), byte-packed disp[] (disp_width bytes/entry) */
#define PH_ENDIAN_MARK 0x0102030405060708ull
#define PH_TYPE_INT    1u
#define PH_TYPE_STR    2u
/* Heap-handle type tags (PhSet/PhBuilder only, NOT on-disk format). Catches a
 * handle reblessed into the wrong package -- sv_derived_from() can't detect
 * that, since blessing is just a stash pointer and the C struct underneath is
 * reinterpreted regardless. type_tag is the first member of both structs, so
 * even a cross-blessed pointer reads a valid tag (never OOB); mismatch = wrong struct. */
#define PH_SET_TAG     0x50534554u   /* PSET */
#define PH_BUILDER_TAG 0x50424c44u   /* PBLD */
typedef struct { uint64_t off, len; } PhStrSlot;
typedef struct {
    /* disp_width (v2; reuses v1's _pad slot, struct size/layout unchanged): byte
     * width of each byte-packed disp[] entry (1..4); disp[b] is disp_width
     * little-endian bytes at disp_off + b*disp_width. */
    uint32_t magic, version, key_type, disp_width;
    uint64_t endian, n, bucket_count, seed0;
    uint64_t disp_off, disp_len, slots_off, slots_len, arena_off, arena_len, file_size;
} PhHeader;
_Static_assert(sizeof(PhHeader) % 8 == 0, "PhHeader must be 8-aligned");

/* Build side (chd.h) and lookup side (ph_has_*) MUST compute the slot with
 * byte-identical arithmetic: same hash fn, same ph_mix, same modulo order, same seed. */
static inline uint64_t ph_h_int(int64_t k, uint64_t seed){ return XXH3_64bits_withSeed(&k,sizeof k,seed); }
static inline uint64_t ph_h_str(const void*k,size_t n,uint64_t seed){ return XXH3_64bits_withSeed(k,n,seed); }
static inline uint64_t ph_mix(uint64_t s,uint64_t d){ return s ^ (d*0x9E3779B97F4A7C15ull + 0x1ull); }
/* Reads a width-byte (1..4) little-endian uint -- the byte-packed disp[]
 * entry. Fixed <=4-iteration loop, byte-addressed so no alignment requirement (unlike the v1 uint32 disp[]). */
static inline uint32_t ph_load_uint_le(const uint8_t *p, uint32_t width) {
    uint32_t v = 0, i;
    for (i = 0; i < width; i++) v |= (uint32_t)p[i] << (8u*i);
    return v;
}

/* --- read-only mmapped handle to a built image --- */
typedef struct {
    uint32_t type_tag;   /* PH_SET_TAG; must stay the first member -- see above */
    int fd; void *map; size_t map_size;
    const PhHeader *hdr; const uint8_t *disp; const void *slots; const uint8_t *arena;
    char *path;
} PhSet;

/* disp[b] = disp_width little-endian bytes at s->disp + b*disp_width; in bounds
 * because b < bucket_count and ph_open checked bucket_count*disp_width <= disp_len. */
static inline uint32_t ph_disp(const PhSet *s, uint64_t b) {
    uint32_t w = s->hdr->disp_width;   /* single load, avoid re-reading the mapped header */
    return ph_load_uint_le(s->disp + b * w, w);
}
static inline int ph_has_int(const PhSet *s, int64_t key) {
    const PhHeader *h = s->hdr; if (!h->n) return 0;
    uint64_t b = ph_h_int(key, h->seed0) % h->bucket_count;
    uint64_t slot = ph_h_int(key, ph_mix(h->seed0, ph_disp(s, b))) % h->n;
    return ((const int64_t*)s->slots)[slot] == key;
}
static inline int ph_has_str(const PhSet *s, const void *key, size_t klen) {
    const PhHeader *h = s->hdr; if (!h->n) return 0;
    uint64_t b = ph_h_str(key, klen, h->seed0) % h->bucket_count;
    uint64_t slot = ph_h_str(key, klen, ph_mix(h->seed0, ph_disp(s, b))) % h->n;
    const PhStrSlot *ss = &((const PhStrSlot*)s->slots)[slot];
    /* ss (off,len) comes straight from the mmapped file -- untrusted, a
     * crafted/corrupt image can put anything there; ph_open only validates the
     * arena region as a whole, not this slot. A violation means "not present",
     * never OOB. Overflow-safe: never forms off+len (checks off<=limit first so limit-off can't underflow). */
    if (ss->off > h->arena_len || ss->len > h->arena_len - ss->off) return 0;
    return ss->len == klen && memcmp(s->arena + ss->off, key, klen) == 0;
}

/* [off, off+len) fits inside [0, limit); overflow-safe -- never computes
 * off+len, so a huge off/len can't wrap around and slip past the check. */
static inline int ph_region_ok(uint64_t off, uint64_t len, uint64_t limit) {
    return off <= limit && len <= limit - off;
}
/* count*size <= have, overflow-safe via pre-divide (count > MAX/size) instead of checking after multiplying. */
static inline int ph_mul_le(uint64_t count, uint64_t size, uint64_t have) {
    if (size != 0 && count > UINT64_MAX / size) return 0;
    return count * size <= have;
}

static PhSet *ph_open(const char *path, char *err, size_t el) {
    /* O_NOFOLLOW: refuse a symlink at the final component -- a .phs path can
     * come from anywhere, and following a planted symlink is a classic TOCTOU/redirection trap. */
    int fd = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (fd < 0) { snprintf(err,el,"open: %s", strerror(errno)); return NULL; }
    struct stat st;
    if (fstat(fd,&st) < 0) { snprintf(err,el,"fstat: %s", strerror(errno)); close(fd); return NULL; }
    if ((uint64_t)st.st_size < sizeof(PhHeader)) { snprintf(err,el,"truncated file"); close(fd); return NULL; }
    void *m = mmap(NULL, st.st_size, PROT_READ, MAP_SHARED, fd, 0);
    if (m == MAP_FAILED) { snprintf(err,el,"mmap: %s", strerror(errno)); close(fd); return NULL; }
    const PhHeader *h = (const PhHeader*)m;
    const char *bad = NULL;
    /* Untrusted input (dump/load can load a .phs from anywhere, crafted or
     * corrupt): every check below uses exact equality or the overflow-safe
     * helpers above, never a bare "off+len > limit" that a huge off/len can wrap past. */
    if (h->magic != PH_MAGIC) bad = "bad magic (not a PerfectHash image)";
    else if (h->version != PH_VERSION) bad = "unsupported format version";
    else if (h->endian != PH_ENDIAN_MARK) bad = "built for a different architecture";
    else if (h->file_size != (uint64_t)st.st_size) bad = "size mismatch";
    else if (h->key_type != PH_TYPE_INT && h->key_type != PH_TYPE_STR) bad = "corrupt PerfectHash image";
    else if (h->n > 0 && h->bucket_count == 0) bad = "corrupt PerfectHash image";       /* else hash%bucket_count divides by zero */
    else if (h->disp_width < 1u || h->disp_width > 4u) bad = "corrupt PerfectHash image"; /* byte-packed disp: 1..4 bytes/entry, validate before it feeds ph_mul_le */
    else if (!ph_region_ok(h->disp_off, h->disp_len, h->file_size)
          || !ph_mul_le(h->bucket_count, h->disp_width, h->disp_len)) bad = "corrupt PerfectHash image";
    else if (!ph_region_ok(h->slots_off, h->slots_len, h->file_size)
          || !ph_mul_le(h->n, h->key_type==PH_TYPE_INT ? sizeof(int64_t) : sizeof(PhStrSlot), h->slots_len))
        bad = "corrupt PerfectHash image";
    else if (h->key_type == PH_TYPE_STR && !ph_region_ok(h->arena_off, h->arena_len, h->file_size))
        bad = "corrupt PerfectHash image";
    /* disp[] is byte-packed, so no alignment requirement (the old v1 disp_off&3
     * check is gone). slots[] (int64_t/PhStrSlot) still needs 8-alignment -- a
     * crafted image with an in-bounds but misaligned slots_off would otherwise reach
     * an unaligned load in ph_has_int/ph_has_str/each_key (UB; SIGBUS on strict-alignment CPUs). */
    else if (h->slots_off & 7u) bad = "misaligned region";
    if (bad) { snprintf(err,el,"%s",bad); munmap(m,st.st_size); close(fd); return NULL; }
    PhSet *s = (PhSet*)malloc(sizeof *s);
    if (!s) { snprintf(err,el,"out of memory"); munmap(m,st.st_size); close(fd); return NULL; }
    s->type_tag = PH_SET_TAG;
    s->path = strdup(path);
    if (!s->path) { snprintf(err,el,"strdup: %s", strerror(errno)); free(s); munmap(m,st.st_size); close(fd); return NULL; }
    s->fd=fd; s->map=m; s->map_size=st.st_size; s->hdr=h;
    s->disp=(const uint8_t*)m + h->disp_off;
    s->slots=(const uint8_t*)m + h->slots_off;
    s->arena = h->key_type==PH_TYPE_STR ? (const uint8_t*)m + h->arena_off : NULL;
    return s;
}
static void ph_close(PhSet *s){ if(!s) return; free(s->path); munmap(s->map,s->map_size); close(s->fd); free(s); }

#endif
