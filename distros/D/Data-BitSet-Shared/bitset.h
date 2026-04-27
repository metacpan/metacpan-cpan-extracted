/*
 * bitset.h -- Shared-memory fixed-size bitset for Linux
 *
 * CAS-based atomic per-bit operations on uint64_t words.
 * Lock-free set/clear/test/toggle with popcount.
 */

#ifndef BITSET_H
#define BITSET_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>

#define BS_MAGIC       0x42535431U  /* "BST1" */
#define BS_VERSION     1
#define BS_ERR_BUFLEN  256

/* ================================================================
 * Header (128 bytes)
 * ================================================================ */

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint64_t capacity;         /* 8: number of bits */
    uint64_t total_size;       /* 16 */
    uint64_t data_off;         /* 24 */
    uint32_t num_words;        /* 32: ceil(capacity/64) */
    uint8_t  _pad0[28];        /* 36-63 */

    uint64_t stat_sets;        /* 64 */
    uint64_t stat_clears;      /* 72 */
    uint64_t stat_toggles;     /* 80 */
    uint8_t  _pad1[40];        /* 88-127 */
} BsHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(BsHeader) == 128, "BsHeader must be 128 bytes");
#endif

typedef struct {
    BsHeader *hdr;
    uint64_t *data;
    size_t    mmap_size;
    char     *path;
    int       backing_fd;
} BsHandle;

/* ================================================================
 * Bit operations (lock-free CAS)
 * ================================================================ */

static inline int bs_test(BsHandle *h, uint64_t bit) {
    uint64_t word = __atomic_load_n(&h->data[bit / 64], __ATOMIC_ACQUIRE);
    return (word >> (bit % 64)) & 1;
}

/* Set bit. Returns old value (0 or 1). */
static inline int bs_set(BsHandle *h, uint64_t bit) {
    uint32_t widx = (uint32_t)(bit / 64);
    uint64_t mask = (uint64_t)1 << (bit % 64);
    for (;;) {
        uint64_t word = __atomic_load_n(&h->data[widx], __ATOMIC_RELAXED);
        if (word & mask) return 1;  /* already set */
        if (__atomic_compare_exchange_n(&h->data[widx], &word, word | mask,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            __atomic_add_fetch(&h->hdr->stat_sets, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

/* Clear bit. Returns old value (0 or 1). */
static inline int bs_clear(BsHandle *h, uint64_t bit) {
    uint32_t widx = (uint32_t)(bit / 64);
    uint64_t mask = (uint64_t)1 << (bit % 64);
    for (;;) {
        uint64_t word = __atomic_load_n(&h->data[widx], __ATOMIC_RELAXED);
        if (!(word & mask)) return 0;  /* already clear */
        if (__atomic_compare_exchange_n(&h->data[widx], &word, word & ~mask,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            __atomic_add_fetch(&h->hdr->stat_clears, 1, __ATOMIC_RELAXED);
            return 1;
        }
    }
}

/* Toggle bit. Returns new value (0 or 1). */
static inline int bs_toggle(BsHandle *h, uint64_t bit) {
    uint32_t widx = (uint32_t)(bit / 64);
    uint64_t mask = (uint64_t)1 << (bit % 64);
    uint64_t old = __atomic_fetch_xor(&h->data[widx], mask, __ATOMIC_ACQ_REL);
    __atomic_add_fetch(&h->hdr->stat_toggles, 1, __ATOMIC_RELAXED);
    return (old & mask) ? 0 : 1;
}

/* Population count — total set bits. */
static inline uint64_t bs_count(BsHandle *h) {
    uint64_t total = 0;
    uint32_t nw = h->hdr->num_words;
    for (uint32_t i = 0; i < nw; i++) {
        uint64_t word = __atomic_load_n(&h->data[i], __ATOMIC_RELAXED);
        total += (uint64_t)__builtin_popcountll(word);
    }
    return total;
}

static inline int bs_any(BsHandle *h) {
    uint32_t nw = h->hdr->num_words;
    for (uint32_t i = 0; i < nw; i++)
        if (__atomic_load_n(&h->data[i], __ATOMIC_RELAXED)) return 1;
    return 0;
}

static inline int bs_none(BsHandle *h) { return !bs_any(h); }

/* Fill all bits. NOT safe concurrently with per-bit CAS ops. */
static inline void bs_fill(BsHandle *h) {
    uint32_t nw = h->hdr->num_words;
    uint64_t cap = h->hdr->capacity;
    for (uint32_t i = 0; i < nw; i++) {
        uint64_t valid = (i == nw - 1 && cap % 64)
            ? ((uint64_t)1 << (cap % 64)) - 1 : ~(uint64_t)0;
        __atomic_store_n(&h->data[i], valid, __ATOMIC_RELEASE);
    }
}

/* Zero all bits. NOT safe concurrently with per-bit CAS ops. */
static inline void bs_zero(BsHandle *h) {
    uint32_t nw = h->hdr->num_words;
    for (uint32_t i = 0; i < nw; i++)
        __atomic_store_n(&h->data[i], 0, __ATOMIC_RELEASE);
}

/* Find first set bit. Returns -1 if none. */
static inline int64_t bs_first_set(BsHandle *h) {
    uint32_t nw = h->hdr->num_words;
    uint64_t cap = h->hdr->capacity;
    for (uint32_t i = 0; i < nw; i++) {
        uint64_t word = __atomic_load_n(&h->data[i], __ATOMIC_RELAXED);
        if (word) {
            uint64_t bit = (uint64_t)i * 64 + __builtin_ctzll(word);
            return bit < cap ? (int64_t)bit : -1;
        }
    }
    return -1;
}

/* Find first clear bit. Returns -1 if none. */
static inline int64_t bs_first_clear(BsHandle *h) {
    uint32_t nw = h->hdr->num_words;
    uint64_t cap = h->hdr->capacity;
    for (uint32_t i = 0; i < nw; i++) {
        uint64_t word = __atomic_load_n(&h->data[i], __ATOMIC_RELAXED);
        if (word != ~(uint64_t)0) {
            uint64_t bit = (uint64_t)i * 64 + __builtin_ctzll(~word);
            return bit < cap ? (int64_t)bit : -1;
        }
    }
    return -1;
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define BS_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, BS_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline void bs_init_header(void *base, uint64_t total, uint64_t capacity, uint32_t nw) {
    BsHeader *hdr = (BsHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic     = BS_MAGIC;
    hdr->version   = BS_VERSION;
    hdr->capacity  = capacity;
    hdr->total_size = total;
    hdr->data_off  = sizeof(BsHeader);
    hdr->num_words = nw;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* Validate a mapped header (shared by bs_create reopen and bs_open_fd). */
static inline int bs_validate_header(const BsHeader *hdr, uint64_t file_size) {
    if (hdr->magic != BS_MAGIC) return 0;
    if (hdr->version != BS_VERSION) return 0;
    if (hdr->capacity == 0) return 0;
    if (hdr->capacity > (uint64_t)(UINT32_MAX - 63) * 64) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->data_off != sizeof(BsHeader)) return 0;
    uint32_t exp_nw = (uint32_t)((hdr->capacity + 63) / 64);
    if (hdr->num_words != exp_nw) return 0;
    uint64_t exp_total = sizeof(BsHeader) + (uint64_t)exp_nw * 8;
    if (hdr->total_size != exp_total) return 0;
    return 1;
}

static inline BsHandle *bs_setup(void *base, size_t ms, const char *path, int bfd) {
    BsHeader *hdr = (BsHeader *)base;
    BsHandle *h = (BsHandle *)calloc(1, sizeof(BsHandle));
    if (!h) { munmap(base, ms); return NULL; }
    h->hdr = hdr;
    h->data = (uint64_t *)((uint8_t *)base + hdr->data_off);
    h->mmap_size = ms;
    h->path = path ? strdup(path) : NULL;
    h->backing_fd = bfd;
    return h;
}

static BsHandle *bs_create(const char *path, uint64_t capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { BS_ERR("capacity must be > 0"); return NULL; }
    uint32_t nw = (uint32_t)((capacity + 63) / 64);
    if (capacity > (uint64_t)(UINT32_MAX - 63) * 64) { BS_ERR("capacity too large"); return NULL; }
    uint64_t total = sizeof(BsHeader) + (uint64_t)nw * 8;

    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { BS_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { BS_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { BS_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { BS_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(BsHeader)) {
            BS_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            BS_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { BS_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!bs_validate_header((BsHeader *)base, (uint64_t)st.st_size)) {
                BS_ERR("invalid bitset file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return bs_setup(base, map_size, path, -1);
        }
    }
    bs_init_header(base, total, capacity, nw);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return bs_setup(base, map_size, path, -1);
}

static BsHandle *bs_create_memfd(const char *name, uint64_t capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { BS_ERR("capacity must be > 0"); return NULL; }
    uint32_t nw = (uint32_t)((capacity + 63) / 64);
    if (capacity > (uint64_t)(UINT32_MAX - 63) * 64) { BS_ERR("capacity too large"); return NULL; }
    uint64_t total = sizeof(BsHeader) + (uint64_t)nw * 8;
    int fd = memfd_create(name ? name : "bitset", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { BS_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { BS_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { BS_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    bs_init_header(base, total, capacity, nw);
    return bs_setup(base, (size_t)total, NULL, fd);
}

static BsHandle *bs_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { BS_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(BsHeader)) { BS_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { BS_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!bs_validate_header((BsHeader *)base, (uint64_t)st.st_size)) {
        BS_ERR("invalid bitset"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { BS_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return bs_setup(base, ms, NULL, myfd);
}

static void bs_destroy(BsHandle *h) {
    if (!h) return;
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

static int bs_msync(BsHandle *h) { return msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* BITSET_H */
