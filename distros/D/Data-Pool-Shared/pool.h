/*
 * pool.h -- Fixed-size shared-memory object pool for Linux
 *
 * Bitmap-based slot allocation with CAS (lock-free).
 * Futex-based blocking when pool is exhausted.
 * PID-based stale slot recovery.
 *
 * Variants:
 *   Raw — opaque byte slots of arbitrary elem_size
 *   I64 — int64_t slots with atomic CAS/add
 *   F64 — double slots
 *   I32 — int32_t slots with atomic CAS/add
 *   Str — fixed-length string slots (4-byte length prefix + data)
 */

#ifndef POOL_H
#define POOL_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <limits.h>
#include <signal.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <sys/eventfd.h>

/* ================================================================
 * Constants
 * ================================================================ */

#define POOL_MAGIC        0x504F4C31U  /* "POL1" */
#define POOL_VERSION      1
#define POOL_ERR_BUFLEN   256

#define POOL_VAR_RAW  0
#define POOL_VAR_I64  1
#define POOL_VAR_F64  2
#define POOL_VAR_I32  3
#define POOL_VAR_STR  4

#define POOL_ALIGN8(x) (((x) + 7) & ~(uint64_t)7)

/* ================================================================
 * Header (128 bytes = 2 cache lines)
 * ================================================================ */

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;          /* 0 */
    uint32_t version;        /* 4 */
    uint32_t elem_size;      /* 8 */
    uint32_t variant_id;     /* 12 */
    uint64_t capacity;       /* 16: number of slots */
    uint64_t total_size;     /* 24: total mmap size */
    uint64_t data_off;       /* 32: offset to slot data */
    uint64_t bitmap_off;     /* 40: offset to allocation bitmap */
    uint64_t owners_off;     /* 48: offset to per-slot owner PIDs */
    uint8_t  _pad0[8];       /* 56-63 */

    /* ---- Cache line 1 (64-127): mutable state ---- */
    uint32_t used;           /* 64: allocated count (futex word) */
    uint32_t waiters;        /* 68: blocked on alloc */
    uint8_t  _pad1[8];       /* 72-79 */
    uint64_t stat_allocs;    /* 80 */
    uint64_t stat_frees;     /* 88 */
    uint64_t stat_waits;     /* 96 */
    uint64_t stat_timeouts;  /* 104 */
    uint64_t stat_recoveries;/* 112 */
    uint8_t  _pad2[8];       /* 120-127 */
} PoolHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(PoolHeader) == 128, "PoolHeader must be 128 bytes");
#endif

/* ================================================================
 * Process-local handle
 * ================================================================ */

typedef struct {
    PoolHeader *hdr;
    uint64_t   *bitmap;
    uint32_t   *owners;
    uint8_t    *data;
    size_t      mmap_size;
    uint32_t    bitmap_words;
    char       *path;
    int         notify_fd;
    int         backing_fd;
    uint32_t    scan_hint;
} PoolHandle;

/* ================================================================
 * Utility
 * ================================================================ */

static inline int pool_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

static inline void pool_make_deadline(double timeout, struct timespec *deadline) {
    clock_gettime(CLOCK_MONOTONIC, deadline);
    deadline->tv_sec += (time_t)timeout;
    deadline->tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1e9);
    if (deadline->tv_nsec >= 1000000000L) {
        deadline->tv_sec++;
        deadline->tv_nsec -= 1000000000L;
    }
}

static inline int pool_remaining_time(const struct timespec *deadline,
                                       struct timespec *remaining) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    remaining->tv_sec = deadline->tv_sec - now.tv_sec;
    remaining->tv_nsec = deadline->tv_nsec - now.tv_nsec;
    if (remaining->tv_nsec < 0) {
        remaining->tv_sec--;
        remaining->tv_nsec += 1000000000L;
    }
    return remaining->tv_sec >= 0;
}

/* ================================================================
 * Slot access
 * ================================================================ */

static inline uint8_t *pool_slot_ptr(PoolHandle *h, uint64_t slot) {
    return h->data + slot * h->hdr->elem_size;
}

static inline int pool_is_allocated(PoolHandle *h, uint64_t slot) {
    uint32_t widx = (uint32_t)(slot / 64);
    int bit = (int)(slot % 64);
    uint64_t word = __atomic_load_n(&h->bitmap[widx], __ATOMIC_RELAXED);
    return (word >> bit) & 1;
}

/* ================================================================
 * Allocation (lock-free bitmap scan + CAS)
 * ================================================================ */

static inline int64_t pool_try_alloc(PoolHandle *h) {
    uint32_t nwords = h->bitmap_words;
    uint64_t cap = h->hdr->capacity;
    uint32_t start = h->scan_hint;
    uint32_t mypid = (uint32_t)getpid();

    for (uint32_t i = 0; i < nwords; i++) {
        uint32_t widx = (start + i) % nwords;
        uint64_t word = __atomic_load_n(&h->bitmap[widx], __ATOMIC_RELAXED);

        while (word != ~(uint64_t)0) {
            int bit = __builtin_ctzll(~word);
            uint64_t slot = (uint64_t)widx * 64 + bit;
            if (slot >= cap) break;

            uint64_t new_word = word | ((uint64_t)1 << bit);
            if (__atomic_compare_exchange_n(&h->bitmap[widx], &word, new_word,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
                __atomic_store_n(&h->owners[slot], mypid, __ATOMIC_RELAXED);
                memset(pool_slot_ptr(h, slot), 0, h->hdr->elem_size);
                __atomic_add_fetch(&h->hdr->used, 1, __ATOMIC_RELEASE);
                __atomic_add_fetch(&h->hdr->stat_allocs, 1, __ATOMIC_RELAXED);
                /* Advance hint past full word to reduce next scan */
                h->scan_hint = (new_word == ~(uint64_t)0 && nwords > 1)
                    ? (widx + 1) % nwords : widx;
                return (int64_t)slot;
            }
            /* CAS failed — word now holds current value, retry */
        }
    }
    return -1;
}

/* Blocking alloc. timeout<0 = infinite, 0 = non-blocking, >0 = seconds. */
static inline int64_t pool_alloc(PoolHandle *h, double timeout) {
    int64_t slot = pool_try_alloc(h);
    if (slot >= 0) return slot;
    if (timeout == 0) return -1;

    PoolHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) pool_make_deadline(timeout, &deadline);

    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        uint32_t cur_used = __atomic_load_n(&hdr->used, __ATOMIC_RELAXED);
        if (cur_used < (uint32_t)hdr->capacity) {
            slot = pool_try_alloc(h);
            if (slot >= 0) return slot;
        }

        __atomic_add_fetch(&hdr->waiters, 1, __ATOMIC_RELEASE);

        cur_used = __atomic_load_n(&hdr->used, __ATOMIC_ACQUIRE);
        if (cur_used >= (uint32_t)hdr->capacity) {
            struct timespec *pts = NULL;
            if (has_deadline) {
                if (!pool_remaining_time(&deadline, &remaining)) {
                    __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return -1;
                }
                pts = &remaining;
            }
            syscall(SYS_futex, &hdr->used, FUTEX_WAIT, cur_used, pts, NULL, 0);
        }

        __atomic_sub_fetch(&hdr->waiters, 1, __ATOMIC_RELAXED);

        slot = pool_try_alloc(h);
        if (slot >= 0) return slot;

        if (has_deadline) {
            if (!pool_remaining_time(&deadline, &remaining)) {
                __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                return -1;
            }
        }
    }
}

/* ================================================================
 * Free
 * ================================================================ */

static inline int pool_free_slot(PoolHandle *h, uint64_t slot) {
    PoolHeader *hdr = h->hdr;
    if (slot >= hdr->capacity) return 0;

    uint32_t widx = (uint32_t)(slot / 64);
    int bit = (int)(slot % 64);
    uint64_t mask = (uint64_t)1 << bit;

    for (;;) {
        uint64_t word = __atomic_load_n(&h->bitmap[widx], __ATOMIC_RELAXED);
        if (!(word & mask)) return 0;

        uint64_t new_word = word & ~mask;
        if (__atomic_compare_exchange_n(&h->bitmap[widx], &word, new_word,
                1, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
            __atomic_store_n(&h->owners[slot], 0, __ATOMIC_RELAXED);
            __atomic_sub_fetch(&hdr->used, 1, __ATOMIC_RELEASE);
            __atomic_add_fetch(&hdr->stat_frees, 1, __ATOMIC_RELAXED);
            if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->used, FUTEX_WAKE, 1, NULL, NULL, 0);
            return 1;
        }
    }
}

/* ================================================================
 * Batch free — single used decrement + single futex wake
 * ================================================================ */

static inline uint32_t pool_free_n(PoolHandle *h, uint64_t *slots, uint32_t count) {
    uint32_t freed = 0;
    PoolHeader *hdr = h->hdr;

    for (uint32_t i = 0; i < count; i++) {
        uint64_t slot = slots[i];
        if (slot >= hdr->capacity) continue;

        uint32_t widx = (uint32_t)(slot / 64);
        int bit = (int)(slot % 64);
        uint64_t mask = (uint64_t)1 << bit;

        for (;;) {
            uint64_t word = __atomic_load_n(&h->bitmap[widx], __ATOMIC_RELAXED);
            if (!(word & mask)) break;
            uint64_t new_word = word & ~mask;
            if (__atomic_compare_exchange_n(&h->bitmap[widx], &word, new_word,
                    1, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                __atomic_store_n(&h->owners[slot], 0, __ATOMIC_RELAXED);
                freed++;
                break;
            }
        }
    }

    if (freed > 0) {
        __atomic_sub_fetch(&hdr->used, freed, __ATOMIC_RELEASE);
        __atomic_add_fetch(&hdr->stat_frees, freed, __ATOMIC_RELAXED);
        if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0) {
            int wake = freed < (uint32_t)INT_MAX ? (int)freed : INT_MAX;
            syscall(SYS_futex, &hdr->used, FUTEX_WAKE, wake, NULL, NULL, 0);
        }
    }
    return freed;
}

/* ================================================================
 * Batch alloc — all-or-nothing, shared deadline
 * ================================================================ */

static inline int pool_alloc_n(PoolHandle *h, uint64_t *out, uint32_t count,
                                double timeout) {
    if (count == 0) return 1;

    if (timeout == 0) {
        for (uint32_t i = 0; i < count; i++) {
            int64_t slot = pool_try_alloc(h);
            if (slot < 0) {
                if (i > 0) pool_free_n(h, out, i);
                return 0;
            }
            out[i] = (uint64_t)slot;
        }
        return 1;
    }

    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) pool_make_deadline(timeout, &deadline);

    for (uint32_t i = 0; i < count; i++) {
        double t = timeout;
        if (has_deadline) {
            if (!pool_remaining_time(&deadline, &remaining)) {
                __atomic_add_fetch(&h->hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                if (i > 0) pool_free_n(h, out, i);
                return 0;
            }
            t = (double)remaining.tv_sec + (double)remaining.tv_nsec / 1e9;
        }
        int64_t slot = pool_alloc(h, t);
        if (slot < 0) {
            if (i > 0) pool_free_n(h, out, i);
            return 0;
        }
        out[i] = (uint64_t)slot;
    }
    return 1;
}

/* ================================================================
 * Stale recovery — CAS owner to narrow race window
 * ================================================================ */

static inline uint32_t pool_recover_stale(PoolHandle *h) {
    uint32_t recovered = 0;
    uint64_t cap = h->hdr->capacity;

    for (uint64_t slot = 0; slot < cap; slot++) {
        if (!pool_is_allocated(h, slot)) continue;
        uint32_t owner = __atomic_load_n(&h->owners[slot], __ATOMIC_ACQUIRE);
        if (owner == 0 || pool_pid_alive(owner)) continue;

        /* CAS owner from dead PID to 0 — if it fails, slot was
         * re-allocated or already recovered by another process */
        if (!__atomic_compare_exchange_n(&h->owners[slot], &owner, 0,
                0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
            continue;

        /* We now own the right to free this slot's bitmap bit */
        uint32_t widx = (uint32_t)(slot / 64);
        int bit = (int)(slot % 64);
        uint64_t mask = (uint64_t)1 << bit;

        for (;;) {
            uint64_t word = __atomic_load_n(&h->bitmap[widx], __ATOMIC_RELAXED);
            if (!(word & mask)) break;
            uint64_t new_word = word & ~mask;
            if (__atomic_compare_exchange_n(&h->bitmap[widx], &word, new_word,
                    1, __ATOMIC_RELEASE, __ATOMIC_RELAXED)) {
                __atomic_sub_fetch(&h->hdr->used, 1, __ATOMIC_RELEASE);
                __atomic_add_fetch(&h->hdr->stat_frees, 1, __ATOMIC_RELAXED);
                if (__atomic_load_n(&h->hdr->waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &h->hdr->used, FUTEX_WAKE, 1, NULL, NULL, 0);
                recovered++;
                break;
            }
        }
    }

    if (recovered > 0)
        __atomic_add_fetch(&h->hdr->stat_recoveries, recovered, __ATOMIC_RELAXED);

    return recovered;
}

/* ================================================================
 * Layout calculation
 * ================================================================ */

static inline void pool_calc_layout(uint64_t capacity, uint32_t elem_size,
                                     uint64_t *bitmap_off, uint64_t *owners_off,
                                     uint64_t *data_off, uint64_t *total_size) {
    uint64_t bwords = (capacity + 63) / 64;
    uint64_t bitmap_sz = bwords * 8;
    uint64_t owners_sz = POOL_ALIGN8(capacity * 4);
    uint64_t data_sz   = (uint64_t)capacity * elem_size;

    *bitmap_off   = sizeof(PoolHeader);
    *owners_off   = *bitmap_off + bitmap_sz;
    *data_off     = *owners_off + owners_sz;
    *total_size   = *data_off + data_sz;
}

/* ================================================================
 * Header initialization (shared by pool_create and pool_create_memfd)
 * ================================================================ */

static inline void pool_init_header(void *base, uint64_t total,
                                     uint32_t elem_size, uint32_t variant_id,
                                     uint64_t capacity, uint64_t bm_off,
                                     uint64_t own_off, uint64_t dat_off) {
    PoolHeader *hdr = (PoolHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic      = POOL_MAGIC;
    hdr->version    = POOL_VERSION;
    hdr->elem_size  = elem_size;
    hdr->variant_id = variant_id;
    hdr->capacity   = capacity;
    hdr->total_size = total;
    hdr->data_off   = dat_off;
    hdr->bitmap_off = bm_off;
    hdr->owners_off = own_off;
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define POOL_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, POOL_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

/* Max capacity to prevent bitmap_words (uint32_t) truncation */
#define POOL_MAX_CAPACITY ((uint64_t)UINT32_MAX * 64)

/* Validate header: magic, version, variant, sizes, AND layout offsets. */
static inline int pool_validate_header(const PoolHeader *hdr, uint64_t file_size,
                                        uint32_t expected_variant) {
    if (hdr->magic != POOL_MAGIC) return 0;
    if (hdr->version != POOL_VERSION) return 0;
    if (hdr->variant_id != expected_variant) return 0;
    if (hdr->capacity == 0 || hdr->capacity > POOL_MAX_CAPACITY) return 0;
    if (hdr->elem_size == 0) return 0;
    if (hdr->capacity > (UINT64_MAX - sizeof(PoolHeader)) / hdr->elem_size) return 0;
    if (hdr->total_size != file_size) return 0;

    uint64_t bm_off, own_off, dat_off, total;
    pool_calc_layout(hdr->capacity, hdr->elem_size, &bm_off, &own_off, &dat_off, &total);

    if (hdr->bitmap_off != bm_off) return 0;
    if (hdr->owners_off != own_off) return 0;
    if (hdr->data_off   != dat_off) return 0;
    if (hdr->total_size != total)   return 0;
    return 1;
}

static inline PoolHandle *pool_setup_handle(void *base, size_t map_size,
                                             const char *path, int backing_fd) {
    PoolHeader *hdr = (PoolHeader *)base;
    PoolHandle *h = (PoolHandle *)calloc(1, sizeof(PoolHandle));
    if (!h) { munmap(base, map_size); return NULL; }

    h->hdr         = hdr;
    h->bitmap      = (uint64_t *)((uint8_t *)base + hdr->bitmap_off);
    h->owners      = (uint32_t *)((uint8_t *)base + hdr->owners_off);
    h->data        = (uint8_t *)base + hdr->data_off;
    h->mmap_size   = map_size;
    h->bitmap_words = (uint32_t)((hdr->capacity + 63) / 64);
    h->path        = path ? strdup(path) : NULL;
    h->notify_fd   = -1;
    h->backing_fd  = backing_fd;
    h->scan_hint   = (uint32_t)getpid() % h->bitmap_words;

    return h;
}

static PoolHandle *pool_create(const char *path, uint64_t capacity,
                                uint32_t elem_size, uint32_t variant_id,
                                char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    if (capacity == 0) { POOL_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { POOL_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > POOL_MAX_CAPACITY) { POOL_ERR("capacity too large"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(PoolHeader)) / elem_size) {
        POOL_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t bm_off, own_off, dat_off, total;
    pool_calc_layout(capacity, elem_size, &bm_off, &own_off, &dat_off, &total);

    int fd = -1;
    int anonymous = (path == NULL);
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) {
            POOL_ERR("mmap(anonymous): %s", strerror(errno));
            return NULL;
        }
    } else {
        fd = open(path, O_RDWR | O_CREAT, 0666);
        if (fd < 0) { POOL_ERR("open(%s): %s", path, strerror(errno)); return NULL; }

        if (flock(fd, LOCK_EX) < 0) {
            POOL_ERR("flock(%s): %s", path, strerror(errno));
            close(fd); return NULL;
        }

        struct stat st;
        if (fstat(fd, &st) < 0) {
            POOL_ERR("fstat(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        int is_new = (st.st_size == 0);

        if (!is_new && (uint64_t)st.st_size < sizeof(PoolHeader)) {
            POOL_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (is_new) {
            if (ftruncate(fd, (off_t)total) < 0) {
                POOL_ERR("ftruncate(%s): %s", path, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            POOL_ERR("mmap(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (!is_new) {
            if (!pool_validate_header((PoolHeader *)base, (uint64_t)st.st_size, variant_id)) {
                POOL_ERR("%s: invalid or incompatible pool file", path);
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN);
            close(fd);
            return pool_setup_handle(base, map_size, path, -1);
        }
    }

    /* Initialize header — flock still held for file-backed new files */
    pool_init_header(base, total, elem_size, variant_id, capacity,
                     bm_off, own_off, dat_off);

    if (fd >= 0) {
        flock(fd, LOCK_UN);
        close(fd);
    }

    return pool_setup_handle(base, map_size, path, -1);
}

static PoolHandle *pool_create_memfd(const char *name, uint64_t capacity,
                                      uint32_t elem_size, uint32_t variant_id,
                                      char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    if (capacity == 0) { POOL_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { POOL_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > POOL_MAX_CAPACITY) { POOL_ERR("capacity too large"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(PoolHeader)) / elem_size) {
        POOL_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t bm_off, own_off, dat_off, total;
    pool_calc_layout(capacity, elem_size, &bm_off, &own_off, &dat_off, &total);

    int fd = memfd_create(name ? name : "pool", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { POOL_ERR("memfd_create: %s", strerror(errno)); return NULL; }

    if (ftruncate(fd, (off_t)total) < 0) {
        POOL_ERR("ftruncate(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    /* Seal against shrink/grow to block ftruncate-based SIGBUS attacks via
     * SCM_RIGHTS-shared fds. Peers can still write; only size is immutable. */
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);

    void *base = mmap(NULL, (size_t)total, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        POOL_ERR("mmap(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    pool_init_header(base, total, elem_size, variant_id, capacity,
                     bm_off, own_off, dat_off);

    return pool_setup_handle(base, (size_t)total, NULL, fd);
}

static PoolHandle *pool_open_fd(int fd, uint32_t variant_id, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    struct stat st;
    if (fstat(fd, &st) < 0) {
        POOL_ERR("fstat(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    if ((uint64_t)st.st_size < sizeof(PoolHeader)) {
        POOL_ERR("fd %d: too small (%lld)", fd, (long long)st.st_size);
        return NULL;
    }

    size_t map_size = (size_t)st.st_size;
    void *base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        POOL_ERR("mmap(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    if (!pool_validate_header((PoolHeader *)base, (uint64_t)st.st_size, variant_id)) {
        POOL_ERR("fd %d: invalid or incompatible pool", fd);
        munmap(base, map_size);
        return NULL;
    }

    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) {
        POOL_ERR("fcntl(F_DUPFD_CLOEXEC): %s", strerror(errno));
        munmap(base, map_size);
        return NULL;
    }

    return pool_setup_handle(base, map_size, NULL, myfd);
}

static void pool_destroy(PoolHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* ================================================================
 * Eventfd integration
 * ================================================================ */

static int pool_create_eventfd(PoolHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd;
    return efd;
}

static int pool_notify(PoolHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t val = 1;
    return write(h->notify_fd, &val, sizeof(val)) == sizeof(val);
}

static int64_t pool_eventfd_consume(PoolHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t val = 0;
    if (read(h->notify_fd, &val, sizeof(val)) != sizeof(val)) return -1;
    return (int64_t)val;
}

static int pool_msync(PoolHandle *h) {
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * Typed accessors — integers (atomic)
 * ================================================================ */

static inline int64_t pool_get_i64(PoolHandle *h, uint64_t slot) {
    return __atomic_load_n((int64_t *)pool_slot_ptr(h, slot), __ATOMIC_RELAXED);
}

static inline void pool_set_i64(PoolHandle *h, uint64_t slot, int64_t val) {
    __atomic_store_n((int64_t *)pool_slot_ptr(h, slot), val, __ATOMIC_RELAXED);
}

static inline int pool_cas_i64(PoolHandle *h, uint64_t slot,
                                int64_t expected, int64_t desired) {
    return __atomic_compare_exchange_n((int64_t *)pool_slot_ptr(h, slot),
            &expected, desired, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
}

static inline int64_t pool_cmpxchg_i64(PoolHandle *h, uint64_t slot,
                                        int64_t expected, int64_t desired) {
    __atomic_compare_exchange_n((int64_t *)pool_slot_ptr(h, slot),
            &expected, desired, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
    return expected;
}

static inline int64_t pool_xchg_i64(PoolHandle *h, uint64_t slot, int64_t val) {
    return __atomic_exchange_n((int64_t *)pool_slot_ptr(h, slot), val, __ATOMIC_ACQ_REL);
}

static inline int64_t pool_add_i64(PoolHandle *h, uint64_t slot, int64_t delta) {
    return __atomic_add_fetch((int64_t *)pool_slot_ptr(h, slot), delta, __ATOMIC_ACQ_REL);
}

static inline int32_t pool_get_i32(PoolHandle *h, uint64_t slot) {
    return __atomic_load_n((int32_t *)pool_slot_ptr(h, slot), __ATOMIC_RELAXED);
}

static inline void pool_set_i32(PoolHandle *h, uint64_t slot, int32_t val) {
    __atomic_store_n((int32_t *)pool_slot_ptr(h, slot), val, __ATOMIC_RELAXED);
}

static inline int pool_cas_i32(PoolHandle *h, uint64_t slot,
                                int32_t expected, int32_t desired) {
    return __atomic_compare_exchange_n((int32_t *)pool_slot_ptr(h, slot),
            &expected, desired, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
}

static inline int32_t pool_cmpxchg_i32(PoolHandle *h, uint64_t slot,
                                        int32_t expected, int32_t desired) {
    __atomic_compare_exchange_n((int32_t *)pool_slot_ptr(h, slot),
            &expected, desired, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
    return expected;
}

static inline int32_t pool_xchg_i32(PoolHandle *h, uint64_t slot, int32_t val) {
    return __atomic_exchange_n((int32_t *)pool_slot_ptr(h, slot), val, __ATOMIC_ACQ_REL);
}

static inline int32_t pool_add_i32(PoolHandle *h, uint64_t slot, int32_t delta) {
    return __atomic_add_fetch((int32_t *)pool_slot_ptr(h, slot), delta, __ATOMIC_ACQ_REL);
}

/* ================================================================
 * Typed accessors — float (non-atomic)
 * ================================================================ */

static inline double pool_get_f64(PoolHandle *h, uint64_t slot) {
    double v;
    memcpy(&v, pool_slot_ptr(h, slot), sizeof(double));
    return v;
}

static inline void pool_set_f64(PoolHandle *h, uint64_t slot, double val) {
    memcpy(pool_slot_ptr(h, slot), &val, sizeof(double));
}

/* ================================================================
 * Typed accessors — string (4-byte length prefix + data)
 * ================================================================ */

static inline uint32_t pool_get_str_len(PoolHandle *h, uint64_t slot) {
    uint32_t len;
    memcpy(&len, pool_slot_ptr(h, slot), sizeof(uint32_t));
    uint32_t max_len = h->hdr->elem_size - sizeof(uint32_t);
    if (len > max_len) len = max_len;
    return len;
}

static inline const char *pool_get_str_ptr(PoolHandle *h, uint64_t slot) {
    return (const char *)(pool_slot_ptr(h, slot) + sizeof(uint32_t));
}

static inline void pool_set_str(PoolHandle *h, uint64_t slot,
                                 const char *str, uint32_t len) {
    uint32_t max_len = h->hdr->elem_size - sizeof(uint32_t);
    if (len > max_len) len = max_len;
    memcpy(pool_slot_ptr(h, slot), &len, sizeof(uint32_t));
    memcpy(pool_slot_ptr(h, slot) + sizeof(uint32_t), str, len);
}

/* ================================================================
 * Reset — free all slots (NOT concurrency-safe, caller must
 * ensure no other process is accessing the pool)
 * ================================================================ */

static inline void pool_reset(PoolHandle *h) {
    PoolHeader *hdr = h->hdr;
    memset(h->bitmap, 0, (size_t)h->bitmap_words * 8);
    memset(h->owners, 0, (size_t)hdr->capacity * 4);
    __atomic_store_n(&hdr->used, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->used, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

#endif /* POOL_H */
