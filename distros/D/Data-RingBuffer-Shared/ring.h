/*
 * ring.h -- Shared-memory fixed-size ring buffer for Linux
 *
 * Lock-free circular buffer: writes overwrite oldest when full.
 * Readers access by relative position (0=latest) or absolute sequence.
 * No consumer tracking — data persists until overwritten.
 *
 * v2 layout adds per-slot publication sequence (seqlock-per-slot), so
 * readers never observe a partially-written or cross-epoch torn slot:
 * read_seq / read_latest return 0 if the slot is mid-write or has been
 * overwritten to a different epoch. Safe under MPMC writers.
 *
 * Unlike Queue (consumed on read) or PubSub (subscription tracking),
 * RingBuffer is a simple overwriting circular window.
 */

#ifndef RING_H
#define RING_H

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
#include <sys/syscall.h>
#include <linux/futex.h>
#include <sys/eventfd.h>

#define RING_MAGIC       0x524E4732U  /* "RNG2" — v2 layout: per-slot publication seq */
#define RING_VERSION     2
#define RING_ERR_BUFLEN  256

#define RING_VAR_INT  0
#define RING_VAR_F64  1

/* ================================================================
 * Header (128 bytes)
 * ================================================================ */

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t elem_size;
    uint32_t variant_id;
    uint64_t capacity;
    uint64_t total_size;
    uint64_t data_off;         /* 32: offset to data array */
    uint64_t seq_off;          /* 40: offset to per-slot publication seq array */
    uint8_t  _pad0[16];        /* 48-63 */

    uint64_t head;             /* 64: monotonic write cursor (next write position) */
    uint64_t count;            /* 72: total writes (for overwrite detection) */
    uint32_t waiters;          /* 80: blocked on new data */
    uint32_t wake_seq;         /* 84: FUTEX_WAIT target (avoids 64-bit count wraparound) */
    uint64_t stat_writes;      /* 88 */
    uint64_t stat_overwrites;  /* 96 */
    uint8_t  _pad2[24];        /* 104-127 */
} RingHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(RingHeader) == 128, "RingHeader must be 128 bytes");
#endif

typedef struct {
    RingHeader *hdr;
    uint8_t    *data;
    uint64_t   *seq;           /* per-slot publication sequence (cap entries) */
    size_t      mmap_size;
    uint32_t    elem_size;
    char       *path;
    int         notify_fd;
    int         backing_fd;
} RingHandle;

/* ================================================================
 * Slot access
 * ================================================================ */

static inline uint8_t *ring_slot(RingHandle *h, uint64_t seq) {
    return h->data + (seq % h->hdr->capacity) * h->elem_size;
}

/* ================================================================
 * Write — overwrites oldest when full, always succeeds
 *
 * Per-slot seq encoding (uint64_t, initial 0):
 *   bit 0 = 1 (odd): writer in progress for pos = (seq >> 1) - 1
 *   bit 0 = 0 (even): data for pos = (seq >> 1) - 1 is published and stable
 * Writers serialize on the slot via CAS (two writers at pos N and pos N+cap
 * racing on the same slot index). Readers use a seqlock-style double-load
 * to detect mid-write tearing.
 * ================================================================ */

static inline uint64_t ring_write(RingHandle *h, const void *val, uint32_t vlen) {
    RingHeader *hdr = h->hdr;
    /* Claim a unique position via fetch_add — ring overwrites, no capacity check. */
    uint64_t pos = __atomic_fetch_add(&hdr->head, 1, __ATOMIC_ACQ_REL);
    uint32_t slot_idx = (uint32_t)(pos % hdr->capacity);
    uint64_t my_writing = ((pos + 1) << 1) | 1;   /* odd: writing for pos */
    uint64_t my_done    = (pos + 1) << 1;         /* even: pos is committed */

    /* CAS per-slot seq from a committed (even) mark to our writing-mark.
     * If another writer is in progress (odd), spin until they commit —
     * otherwise we'd race data writes to the same slot. If a newer writer
     * has already committed (seq >> 1 > pos+1), skip: their data wins. */
    uint64_t cur = __atomic_load_n(&h->seq[slot_idx], __ATOMIC_ACQUIRE);
    int wrote = 0;
    for (;;) {
        if (cur & 1) {
            /* Another writer owns the slot; wait for them to publish. */
            cur = __atomic_load_n(&h->seq[slot_idx], __ATOMIC_ACQUIRE);
            continue;
        }
        uint64_t cur_committed = cur >> 1;
        if (cur_committed > pos + 1) break;   /* newer writer already here */
        if (__atomic_compare_exchange_n(&h->seq[slot_idx], &cur, my_writing,
                0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            wrote = 1; break;
        }
    }
    if (wrote) {
        uint32_t sz = h->elem_size;
        uint32_t cp = vlen < sz ? vlen : sz;
        memcpy(ring_slot(h, pos), val, cp);
        if (cp < sz) memset(ring_slot(h, pos) + cp, 0, sz - cp);
        __atomic_store_n(&h->seq[slot_idx], my_done, __ATOMIC_RELEASE);
    }

    uint64_t cnt = __atomic_add_fetch(&hdr->count, 1, __ATOMIC_RELEASE);
    if (cnt > hdr->capacity)
        __atomic_add_fetch(&hdr->stat_overwrites, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&hdr->stat_writes, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&hdr->wake_seq, 1, __ATOMIC_RELEASE);

    /* Wake readers */
    if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);

    return pos;
}

/* ================================================================
 * Read — by relative position (0=latest) or absolute sequence
 * ================================================================ */

/* Read by absolute sequence number. Returns 1 if data for that seq was
 * observed intact, 0 if not-yet-written / overwritten / mid-write. */
static inline int ring_read_seq(RingHandle *h, uint64_t seq, void *out) {
    uint64_t head = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
    if (seq >= head) return 0;  /* not yet written */
    uint64_t oldest = (head > h->hdr->capacity) ? head - h->hdr->capacity : 0;
    if (seq < oldest) return 0;  /* already overwritten */

    uint32_t slot_idx = (uint32_t)(seq % h->hdr->capacity);
    uint64_t expected = (seq + 1) << 1;  /* even mark: pos=seq committed */

    for (int retry = 0; retry < 8; retry++) {
        uint64_t s1 = __atomic_load_n(&h->seq[slot_idx], __ATOMIC_ACQUIRE);
        if (s1 & 1) continue;           /* writer in progress: spin and retry */
        if (s1 != expected) return 0;   /* stale epoch (overwritten) */
        memcpy(out, ring_slot(h, seq), h->elem_size);
        uint64_t s2 = __atomic_load_n(&h->seq[slot_idx], __ATOMIC_ACQUIRE);
        if (s1 == s2) return 1;          /* stable: no concurrent writer touched us */
    }
    return 0;  /* too much contention to get a clean read */
}

/* Read the nth most recent value (0=latest, 1=previous, ...).
 * Returns 1 on success, 0 if n >= available entries or slot is unstable. */
static inline int ring_read_latest(RingHandle *h, uint32_t n, void *out) {
    uint64_t head = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
    if (head == 0) return 0;
    uint64_t avail = head < h->hdr->capacity ? head : h->hdr->capacity;
    if (n >= avail) return 0;
    return ring_read_seq(h, head - 1 - n, out);
}

/* ================================================================
 * Status
 * ================================================================ */

static inline uint64_t ring_head(RingHandle *h) {
    return __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
}

static inline uint64_t ring_size(RingHandle *h) {
    uint64_t head = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);
    return head < h->hdr->capacity ? head : h->hdr->capacity;
}

/* ================================================================
 * Wait — block until new data arrives
 * ================================================================ */

static inline void ring_make_deadline(double t, struct timespec *dl) {
    clock_gettime(CLOCK_MONOTONIC, dl);
    dl->tv_sec += (time_t)t;
    dl->tv_nsec += (long)((t - (double)(time_t)t) * 1e9);
    if (dl->tv_nsec >= 1000000000L) { dl->tv_sec++; dl->tv_nsec -= 1000000000L; }
}

static inline int ring_remaining(const struct timespec *dl, struct timespec *rem) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    rem->tv_sec = dl->tv_sec - now.tv_sec;
    rem->tv_nsec = dl->tv_nsec - now.tv_nsec;
    if (rem->tv_nsec < 0) { rem->tv_sec--; rem->tv_nsec += 1000000000L; }
    return rem->tv_sec >= 0;
}

static inline int ring_wait(RingHandle *h, uint64_t expected_count, double timeout) {
    if (__atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE) != expected_count) return 1;
    if (timeout == 0) return 0;

    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) ring_make_deadline(timeout, &dl);

    for (;;) {
        __atomic_add_fetch(&h->hdr->waiters, 1, __ATOMIC_RELEASE);
        uint32_t seq = __atomic_load_n(&h->hdr->wake_seq, __ATOMIC_ACQUIRE);
        uint64_t cur = __atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE);
        if (cur == expected_count) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!ring_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &h->hdr->wake_seq, FUTEX_WAIT, seq, pts, NULL, 0);
        }
        __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
        if (__atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE) != expected_count) return 1;
        if (has_dl && !ring_remaining(&dl, &rem)) return 0;
    }
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define RING_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, RING_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

/* Layout offsets:
 *   seq_off  = sizeof(RingHeader)                        (128)
 *   data_off = sizeof(RingHeader) + capacity * sizeof(uint64_t)
 *   total    = data_off + capacity * elem_size
 */
static inline uint64_t ring_seq_off(void) { return sizeof(RingHeader); }
static inline uint64_t ring_data_off(uint64_t capacity) {
    return sizeof(RingHeader) + capacity * sizeof(uint64_t);
}

static inline void ring_init_header(void *base, uint64_t total,
                                     uint32_t elem_size, uint32_t variant_id,
                                     uint64_t capacity) {
    RingHeader *hdr = (RingHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic      = RING_MAGIC;
    hdr->version    = RING_VERSION;
    hdr->elem_size  = elem_size;
    hdr->variant_id = variant_id;
    hdr->capacity   = capacity;
    hdr->total_size = total;
    hdr->seq_off    = ring_seq_off();
    hdr->data_off   = ring_data_off(capacity);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* Validate a mapped header (shared by ring_create reopen and ring_open_fd). */
static inline int ring_validate_header(const RingHeader *hdr, uint64_t file_size,
                                        uint32_t expected_variant) {
    if (hdr->magic != RING_MAGIC) return 0;
    if (hdr->version != RING_VERSION) return 0;
    if (hdr->variant_id != expected_variant) return 0;
    if (hdr->elem_size == 0 || hdr->capacity == 0) return 0;
    /* capacity * 8 + capacity * elem_size + header must fit in uint64_t */
    if (hdr->capacity > (UINT64_MAX - sizeof(RingHeader)) / (sizeof(uint64_t) + hdr->elem_size)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->seq_off  != ring_seq_off()) return 0;
    if (hdr->data_off != ring_data_off(hdr->capacity)) return 0;
    if (hdr->total_size != hdr->data_off + hdr->capacity * hdr->elem_size) return 0;
    return 1;
}

static inline RingHandle *ring_setup(void *base, size_t ms, const char *path, int bfd) {
    RingHeader *hdr = (RingHeader *)base;
    RingHandle *h = (RingHandle *)calloc(1, sizeof(RingHandle));
    if (!h) { munmap(base, ms); return NULL; }
    h->hdr = hdr;
    h->seq = (uint64_t *)((uint8_t *)base + hdr->seq_off);
    h->data = (uint8_t *)base + hdr->data_off;
    h->mmap_size = ms;
    h->elem_size = hdr->elem_size;
    h->path = path ? strdup(path) : NULL;
    h->notify_fd = -1;
    h->backing_fd = bfd;
    return h;
}

static RingHandle *ring_create(const char *path, uint64_t capacity,
                                uint32_t elem_size, uint32_t variant_id,
                                char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { RING_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { RING_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(RingHeader)) / (sizeof(uint64_t) + elem_size)) {
        RING_ERR("capacity * elem_size overflow"); return NULL;
    }

    uint64_t total = ring_data_off(capacity) + capacity * elem_size;
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { RING_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { RING_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { RING_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { RING_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(RingHeader)) {
            RING_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            RING_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { RING_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!ring_validate_header((RingHeader *)base, (uint64_t)st.st_size, variant_id)) {
                RING_ERR("invalid ring file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return ring_setup(base, map_size, path, -1);
        }
    }
    ring_init_header(base, total, elem_size, variant_id, capacity);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return ring_setup(base, map_size, path, -1);
}

static RingHandle *ring_create_memfd(const char *name, uint64_t capacity,
                                      uint32_t elem_size, uint32_t variant_id,
                                      char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { RING_ERR("capacity must be > 0"); return NULL; }
    if (elem_size == 0) { RING_ERR("elem_size must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(RingHeader)) / (sizeof(uint64_t) + elem_size)) {
        RING_ERR("capacity * elem_size overflow"); return NULL;
    }
    uint64_t total = ring_data_off(capacity) + capacity * elem_size;
    int fd = memfd_create(name ? name : "ring", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { RING_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { RING_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RING_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    ring_init_header(base, total, elem_size, variant_id, capacity);
    return ring_setup(base, (size_t)total, NULL, fd);
}

static RingHandle *ring_open_fd(int fd, uint32_t variant_id, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { RING_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(RingHeader)) { RING_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { RING_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!ring_validate_header((RingHeader *)base, (uint64_t)st.st_size, variant_id)) {
        RING_ERR("invalid ring"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { RING_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return ring_setup(base, ms, NULL, myfd);
}

static void ring_destroy(RingHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* NOT concurrency-safe — caller must ensure no concurrent writers/readers. */
static void ring_clear(RingHandle *h) {
    uint64_t cap = h->hdr->capacity;
    /* Reset per-slot seq: otherwise new writes at pos=0 look stale against
     * old high seq marks. */
    for (uint64_t i = 0; i < cap; i++)
        __atomic_store_n(&h->seq[i], 0, __ATOMIC_RELAXED);
    __atomic_store_n(&h->hdr->head, 0, __ATOMIC_RELEASE);
    __atomic_store_n(&h->hdr->count, 0, __ATOMIC_RELEASE);
    __atomic_add_fetch(&h->hdr->wake_seq, 1, __ATOMIC_RELEASE);
    /* Wake any ring_wait callers parked with timeout=-1 so they re-check. */
    if (__atomic_load_n(&h->hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static int ring_create_eventfd(RingHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd; return efd;
}
static int ring_notify(RingHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1; return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}
static int64_t ring_eventfd_consume(RingHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}
static int ring_msync(RingHandle *h) { return msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* RING_H */
