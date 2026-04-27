/*
 * log.h -- Append-only shared-memory log (WAL) for Linux
 *
 * Multiple writers append variable-length entries via CAS on tail offset.
 * Readers replay from any offset. Entries persist until explicit reset.
 *
 * Entry format: [uint32_t length][data bytes][padding to 4-byte alignment].
 * length is written AFTER data, acting as a commit flag (0 = uncommitted).
 * Padding ensures the next uint32_t length is naturally aligned — required
 * for atomic load/store on strict-alignment ISAs (ARM64 LDAR/STLR trap on
 * unaligned addresses with SIGBUS).
 */

#ifndef LOG_H
#define LOG_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <limits.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <sys/eventfd.h>

#define LOG_MAGIC       0x4C4F4731U  /* "LOG1" */
#define LOG_VERSION     1
#define LOG_ERR_BUFLEN  256
#define LOG_ENTRY_HDR   sizeof(uint32_t)

/* ================================================================
 * Header (128 bytes)
 * ================================================================ */

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint64_t data_size;        /* 8: usable data region size */
    uint64_t total_size;       /* 16 */
    uint64_t data_off;         /* 24 */
    uint8_t  _pad0[32];        /* 32-63 */

    uint64_t tail;             /* 64: byte offset past last entry (CAS target) */
    uint64_t count;            /* 72: number of committed entries */
    uint32_t waiters;          /* 80: blocked tailers */
    uint32_t wake_seq;         /* 84: FUTEX_WAIT target (avoids 64-bit count wraparound) */
    uint64_t stat_appends;     /* 88 */
    uint64_t stat_waits;       /* 96 */
    uint64_t stat_timeouts;    /* 104 */
    uint64_t truncation;       /* 112: entries before this offset are invalid */
    uint8_t  _pad2[8];         /* 120-127 */
} LogHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(LogHeader) == 128, "LogHeader must be 128 bytes");
#endif

typedef struct {
    LogHeader *hdr;
    uint8_t   *data;
    size_t     mmap_size;
    char      *path;
    int        notify_fd;
    int        backing_fd;
} LogHandle;

/* ================================================================
 * Utility
 * ================================================================ */

static inline void log_make_deadline(double t, struct timespec *dl) {
    clock_gettime(CLOCK_MONOTONIC, dl);
    dl->tv_sec += (time_t)t;
    dl->tv_nsec += (long)((t - (double)(time_t)t) * 1e9);
    if (dl->tv_nsec >= 1000000000L) { dl->tv_sec++; dl->tv_nsec -= 1000000000L; }
}

static inline int log_remaining(const struct timespec *dl, struct timespec *rem) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    rem->tv_sec = dl->tv_sec - now.tv_sec;
    rem->tv_nsec = dl->tv_nsec - now.tv_nsec;
    if (rem->tv_nsec < 0) { rem->tv_sec--; rem->tv_nsec += 1000000000L; }
    return rem->tv_sec >= 0;
}

/* ================================================================
 * Append — CAS reserve space, then write data, then commit (len)
 * ================================================================ */

static inline int64_t log_append(LogHandle *h, const void *data, uint32_t len) {
    if (len == 0) return -1;  /* 0 is the uncommitted marker */

    LogHeader *hdr = h->hdr;
    if (len > UINT32_MAX - LOG_ENTRY_HDR - 3U) return -1;
    /* Pad total entry size up to 4-byte boundary so the next entry's
     * length field is naturally aligned for atomic ops on ARM64. */
    uint32_t entry_size = (LOG_ENTRY_HDR + len + 3U) & ~3U;

    for (;;) {
        uint64_t t = __atomic_load_n(&hdr->tail, __ATOMIC_RELAXED);
        if (t + entry_size > hdr->data_size) return -1;

        if (__atomic_compare_exchange_n(&hdr->tail, &t, t + entry_size,
                1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            uint8_t *slot = h->data + t;
            /* write data first */
            memcpy(slot + LOG_ENTRY_HDR, data, len);
            /* commit: atomic release store of len — readers acquire-load it. */
            __atomic_store_n((uint32_t *)slot, len, __ATOMIC_RELEASE);

            __atomic_add_fetch(&hdr->count, 1, __ATOMIC_RELEASE);
            __atomic_add_fetch(&hdr->stat_appends, 1, __ATOMIC_RELAXED);
            __atomic_add_fetch(&hdr->wake_seq, 1, __ATOMIC_RELEASE);

            if (__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED) > 0)
                syscall(SYS_futex, &hdr->wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);

            return (int64_t)t;
        }
    }
}

/* ================================================================
 * Read — read entry at offset
 * ================================================================ */

static inline int log_read(LogHandle *h, uint64_t offset,
                            const uint8_t **out_data, uint32_t *out_len,
                            uint64_t *next_off) {
    uint64_t trunc = __atomic_load_n(&h->hdr->truncation, __ATOMIC_ACQUIRE);
    if (offset < trunc) return 0;  /* truncated */
    uint64_t t = __atomic_load_n(&h->hdr->tail, __ATOMIC_ACQUIRE);
    if (offset >= t) return 0;
    if (offset + LOG_ENTRY_HDR > h->hdr->data_size) return 0;

    uint8_t *slot = h->data + offset;
    /* Atomic acquire-load pairs with writer's __atomic_store_n RELEASE. */
    uint32_t len = __atomic_load_n((const uint32_t *)slot, __ATOMIC_ACQUIRE);
    if (len == 0) return 0;  /* uncommitted */

    if (offset + LOG_ENTRY_HDR + len > t) return 0;

    *out_data = slot + LOG_ENTRY_HDR;
    *out_len = len;
    /* Advance past entry + alignment padding (matches log_append). */
    *next_off = offset + (((uint64_t)LOG_ENTRY_HDR + len + 3U) & ~(uint64_t)3U);
    return 1;
}

/* ================================================================
 * Tail / Wait
 * ================================================================ */

static inline uint64_t log_tail_offset(LogHandle *h) {
    return __atomic_load_n(&h->hdr->tail, __ATOMIC_ACQUIRE);
}

static inline uint64_t log_entry_count(LogHandle *h) {
    return __atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE);
}

static inline uint64_t log_data_size(LogHandle *h) {
    return h->hdr->data_size;
}

static inline uint64_t log_available(LogHandle *h) {
    return h->hdr->data_size - __atomic_load_n(&h->hdr->tail, __ATOMIC_RELAXED);
}

static inline int log_wait(LogHandle *h, uint64_t expected_count, double timeout) {
    if (log_entry_count(h) != expected_count) return 1;
    if (timeout == 0) return 0;

    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) log_make_deadline(timeout, &dl);
    __atomic_add_fetch(&h->hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        __atomic_add_fetch(&h->hdr->waiters, 1, __ATOMIC_RELEASE);
        uint32_t seq = __atomic_load_n(&h->hdr->wake_seq, __ATOMIC_ACQUIRE);
        uint64_t cur = __atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE);
        if (cur == expected_count) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!log_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&h->hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &h->hdr->wake_seq, FUTEX_WAIT, seq, pts, NULL, 0);
        }
        __atomic_sub_fetch(&h->hdr->waiters, 1, __ATOMIC_RELAXED);
        if (log_entry_count(h) != expected_count) return 1;
        if (has_dl && !log_remaining(&dl, &rem)) {
            __atomic_add_fetch(&h->hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define LOG_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, LOG_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline void log_init_header(void *base, uint64_t total, uint64_t data_size) {
    LogHeader *hdr = (LogHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic     = LOG_MAGIC;
    hdr->version   = LOG_VERSION;
    hdr->data_size = data_size;
    hdr->total_size = total;
    hdr->data_off  = sizeof(LogHeader);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* Validate a mapped header (shared by log_create reopen and log_open_fd). */
static inline int log_validate_header(const LogHeader *hdr, uint64_t file_size) {
    if (hdr->magic != LOG_MAGIC) return 0;
    if (hdr->version != LOG_VERSION) return 0;
    if (hdr->data_size == 0) return 0;
    if (hdr->data_size > UINT64_MAX - sizeof(LogHeader)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->data_off != sizeof(LogHeader)) return 0;
    if (hdr->total_size != sizeof(LogHeader) + hdr->data_size) return 0;
    /* Runtime-state sanity: tail and truncation must not exceed data_size. */
    if (hdr->tail > hdr->data_size) return 0;
    if (hdr->truncation > hdr->data_size) return 0;
    return 1;
}

static inline LogHandle *log_setup(void *base, size_t ms, const char *path, int bfd) {
    LogHeader *hdr = (LogHeader *)base;
    LogHandle *h = (LogHandle *)calloc(1, sizeof(LogHandle));
    if (!h) { munmap(base, ms); return NULL; }
    h->hdr = hdr;
    h->data = (uint8_t *)base + hdr->data_off;
    h->mmap_size = ms;
    h->path = path ? strdup(path) : NULL;
    h->notify_fd = -1;
    h->backing_fd = bfd;
    /* Log is append-only: hint sequential access so the kernel prefetcher
     * reads ahead on large scans (read_entry, each_entry). Best-effort. */
    (void)madvise(base, ms, MADV_SEQUENTIAL);
    return h;
}

static LogHandle *log_create(const char *path, uint64_t data_size, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (data_size == 0) { LOG_ERR("data_size must be > 0"); return NULL; }
    if (data_size > UINT64_MAX - sizeof(LogHeader)) { LOG_ERR("data_size too large"); return NULL; }

    uint64_t total = sizeof(LogHeader) + data_size;
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { LOG_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { LOG_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { LOG_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) {
            LOG_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(LogHeader)) {
            LOG_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            LOG_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { LOG_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!log_validate_header((LogHeader *)base, (uint64_t)st.st_size)) {
                LOG_ERR("invalid log file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return log_setup(base, map_size, path, -1);
        }
    }
    log_init_header(base, total, data_size);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return log_setup(base, map_size, path, -1);
}

static LogHandle *log_create_memfd(const char *name, uint64_t data_size, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (data_size == 0) { LOG_ERR("data_size must be > 0"); return NULL; }
    if (data_size > UINT64_MAX - sizeof(LogHeader)) { LOG_ERR("data_size too large"); return NULL; }
    uint64_t total = sizeof(LogHeader) + data_size;
    int fd = memfd_create(name ? name : "log", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { LOG_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { LOG_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { LOG_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    log_init_header(base, total, data_size);
    return log_setup(base, (size_t)total, NULL, fd);
}

static LogHandle *log_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { LOG_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(LogHeader)) { LOG_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { LOG_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!log_validate_header((LogHeader *)base, (uint64_t)st.st_size)) {
        LOG_ERR("invalid log"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { LOG_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return log_setup(base, ms, NULL, myfd);
}

static void log_destroy(LogHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* NOT concurrency-safe — caller must ensure no concurrent access */
static void log_reset(LogHandle *h) {
    __atomic_store_n(&h->hdr->truncation, 0, __ATOMIC_RELEASE);
    __atomic_store_n(&h->hdr->tail, 0, __ATOMIC_RELEASE);
    __atomic_store_n(&h->hdr->count, 0, __ATOMIC_RELEASE);
    __atomic_add_fetch(&h->hdr->wake_seq, 1, __ATOMIC_RELEASE);
    if (__atomic_load_n(&h->hdr->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->wake_seq, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* Concurrency-safe truncate: mark entries before offset as invalid.
 * Does NOT reclaim space — the log is append-only. Readers skip
 * entries below the truncation offset. */
static inline void log_truncate(LogHandle *h, uint64_t offset) {
    for (;;) {
        uint64_t cur = __atomic_load_n(&h->hdr->truncation, __ATOMIC_RELAXED);
        if (offset <= cur) return;  /* can only advance, not retreat */
        if (__atomic_compare_exchange_n(&h->hdr->truncation, &cur, offset,
                1, __ATOMIC_RELEASE, __ATOMIC_RELAXED))
            return;
    }
}

static inline uint64_t log_truncation(LogHandle *h) {
    return __atomic_load_n(&h->hdr->truncation, __ATOMIC_ACQUIRE);
}

static int log_create_eventfd(LogHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd; return efd;
}
static int log_notify(LogHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1; return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}
static int64_t log_eventfd_consume(LogHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}
static int log_msync(LogHandle *h) { return msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* LOG_H */
