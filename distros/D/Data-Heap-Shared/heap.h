/*
 * heap.h -- Shared-memory binary min-heap (priority queue) for Linux
 *
 * Mutex-protected push/pop with sift-up/sift-down.
 * Futex blocking when empty (pop_wait).
 * Elements are (int64_t priority, int64_t value) pairs.
 * Lowest priority pops first (min-heap).
 */

#ifndef HEAP_H
#define HEAP_H

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

#define HEAP_MAGIC       0x48455031U  /* "HEP1" */
#define HEAP_VERSION     1
#define HEAP_ERR_BUFLEN  256
#define HEAP_SPIN_LIMIT  32

#define HEAP_MUTEX_BIT   0x80000000U
#define HEAP_MUTEX_PID   0x7FFFFFFFU

typedef struct {
    int64_t priority;
    int64_t value;
} HeapEntry;

/* ================================================================
 * Header (128 bytes)
 * ================================================================ */

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint64_t capacity;
    uint64_t total_size;
    uint64_t data_off;
    uint8_t  _pad0[32];

    uint32_t size;             /* 64: current element count (futex word for pop) */
    uint32_t mutex;            /* 68: 0=free, HEAP_MUTEX_BIT|pid=locked */
    uint32_t mutex_waiters;    /* 72 */
    uint32_t waiters_pop;      /* 76 */
    uint64_t stat_pushes;      /* 80 */
    uint64_t stat_pops;        /* 88 */
    uint64_t stat_waits;       /* 96 */
    uint64_t stat_timeouts;    /* 104 */
    uint64_t stat_recoveries;  /* 112 */
    uint8_t  _pad1[8];         /* 120-127 */
} HeapHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(HeapHeader) == 128, "HeapHeader must be 128 bytes");
#endif

typedef struct {
    HeapHeader *hdr;
    HeapEntry  *data;
    size_t      mmap_size;
    char       *path;
    int         notify_fd;
    int         backing_fd;
} HeapHandle;

/* ================================================================
 * Mutex (PID-based, stale-recoverable)
 * ================================================================ */

static const struct timespec heap_lock_timeout = { 2, 0 };

static inline int heap_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

static inline void heap_mutex_lock(HeapHeader *hdr) {
    uint32_t mypid = HEAP_MUTEX_BIT | ((uint32_t)getpid() & HEAP_MUTEX_PID);
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (spin < HEAP_SPIN_LIMIT) {
#if defined(__x86_64__) || defined(__i386__)
            __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
            __asm__ volatile("yield" ::: "memory");
#endif
            continue;
        }
        __atomic_add_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->mutex, FUTEX_WAIT, cur,
                              &heap_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT && cur >= HEAP_MUTEX_BIT) {
                uint32_t pid = cur & HEAP_MUTEX_PID;
                if (!heap_pid_alive(pid)) {
                    if (__atomic_compare_exchange_n(&hdr->mutex, &cur, 0,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                        __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
                        /* Wake one waiter so recovery latency is not bounded by the 2s timeout. */
                        if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
                            syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
                    }
                }
            }
        }
        __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void heap_mutex_unlock(HeapHeader *hdr) {
    __atomic_store_n(&hdr->mutex, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

/* ================================================================
 * Heap operations (must hold mutex)
 * ================================================================ */

static inline void heap_swap(HeapEntry *a, HeapEntry *b) {
    HeapEntry t = *a; *a = *b; *b = t;
}

static inline void heap_sift_up(HeapEntry *data, uint32_t idx) {
    while (idx > 0) {
        uint32_t parent = (idx - 1) / 2;
        if (data[parent].priority <= data[idx].priority) break;
        heap_swap(&data[parent], &data[idx]);
        idx = parent;
    }
}

static inline void heap_sift_down(HeapEntry *data, uint32_t size, uint32_t idx) {
    while (1) {
        uint32_t smallest = idx;
        uint32_t left = 2 * idx + 1;
        uint32_t right = 2 * idx + 2;
        if (left < size && data[left].priority < data[smallest].priority)
            smallest = left;
        if (right < size && data[right].priority < data[smallest].priority)
            smallest = right;
        if (smallest == idx) break;
        heap_swap(&data[idx], &data[smallest]);
        idx = smallest;
    }
}

/* ================================================================
 * Public API
 * ================================================================ */

static inline void heap_make_deadline(double t, struct timespec *dl) {
    clock_gettime(CLOCK_MONOTONIC, dl);
    dl->tv_sec += (time_t)t;
    dl->tv_nsec += (long)((t - (double)(time_t)t) * 1e9);
    if (dl->tv_nsec >= 1000000000L) { dl->tv_sec++; dl->tv_nsec -= 1000000000L; }
}

static inline int heap_remaining(const struct timespec *dl, struct timespec *rem) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    rem->tv_sec = dl->tv_sec - now.tv_sec;
    rem->tv_nsec = dl->tv_nsec - now.tv_nsec;
    if (rem->tv_nsec < 0) { rem->tv_sec--; rem->tv_nsec += 1000000000L; }
    return rem->tv_sec >= 0;
}

static inline int heap_push(HeapHandle *h, int64_t priority, int64_t value) {
    HeapHeader *hdr = h->hdr;
    heap_mutex_lock(hdr);
    if (hdr->size >= (uint32_t)hdr->capacity) {
        heap_mutex_unlock(hdr);
        return 0;
    }
    uint32_t idx = hdr->size++;
    h->data[idx].priority = priority;
    h->data[idx].value = value;
    heap_sift_up(h->data, idx);
    __atomic_add_fetch(&hdr->stat_pushes, 1, __ATOMIC_RELAXED);
    heap_mutex_unlock(hdr);
    /* wake pop-waiters */
    if (__atomic_load_n(&hdr->waiters_pop, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->size, FUTEX_WAKE, 1, NULL, NULL, 0);
    return 1;
}

static inline int heap_pop(HeapHandle *h, int64_t *out_priority, int64_t *out_value) {
    HeapHeader *hdr = h->hdr;
    heap_mutex_lock(hdr);
    if (hdr->size == 0) {
        heap_mutex_unlock(hdr);
        return 0;
    }
    *out_priority = h->data[0].priority;
    *out_value = h->data[0].value;
    hdr->size--;
    if (hdr->size > 0) {
        h->data[0] = h->data[hdr->size];
        heap_sift_down(h->data, hdr->size, 0);
    }
    __atomic_add_fetch(&hdr->stat_pops, 1, __ATOMIC_RELAXED);
    heap_mutex_unlock(hdr);
    return 1;
}

static inline int heap_pop_wait(HeapHandle *h, int64_t *out_p, int64_t *out_v, double timeout) {
    if (heap_pop(h, out_p, out_v)) return 1;
    if (timeout == 0) return 0;

    HeapHeader *hdr = h->hdr;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) heap_make_deadline(timeout, &dl);
    __atomic_add_fetch(&hdr->stat_waits, 1, __ATOMIC_RELAXED);

    for (;;) {
        __atomic_add_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELEASE);
        uint32_t cur = __atomic_load_n(&hdr->size, __ATOMIC_ACQUIRE);
        if (cur == 0) {
            struct timespec *pts = NULL;
            if (has_dl) {
                if (!heap_remaining(&dl, &rem)) {
                    __atomic_sub_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
                    return 0;
                }
                pts = &rem;
            }
            syscall(SYS_futex, &hdr->size, FUTEX_WAIT, 0, pts, NULL, 0);
        }
        __atomic_sub_fetch(&hdr->waiters_pop, 1, __ATOMIC_RELAXED);
        if (heap_pop(h, out_p, out_v)) return 1;
        if (has_dl && !heap_remaining(&dl, &rem)) {
            __atomic_add_fetch(&hdr->stat_timeouts, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
}

static inline int heap_peek(HeapHandle *h, int64_t *out_p, int64_t *out_v) {
    HeapHeader *hdr = h->hdr;
    heap_mutex_lock(hdr);
    if (hdr->size == 0) { heap_mutex_unlock(hdr); return 0; }
    *out_p = h->data[0].priority;
    *out_v = h->data[0].value;
    heap_mutex_unlock(hdr);
    return 1;
}

static inline uint32_t heap_size(HeapHandle *h) {
    return __atomic_load_n(&h->hdr->size, __ATOMIC_RELAXED);
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define HEAP_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, HEAP_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static inline void heap_init_header(void *base, uint64_t total, uint64_t capacity) {
    HeapHeader *hdr = (HeapHeader *)base;
    memset(base, 0, (size_t)total);
    hdr->magic     = HEAP_MAGIC;
    hdr->version   = HEAP_VERSION;
    hdr->capacity  = capacity;
    hdr->total_size = total;
    hdr->data_off  = sizeof(HeapHeader);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* Validate a mapped header (shared by heap_create reopen and heap_open_fd). */
static inline int heap_validate_header(const HeapHeader *hdr, uint64_t file_size) {
    if (hdr->magic != HEAP_MAGIC) return 0;
    if (hdr->version != HEAP_VERSION) return 0;
    if (hdr->capacity == 0) return 0;
    if (hdr->capacity > (UINT64_MAX - sizeof(HeapHeader)) / sizeof(HeapEntry)) return 0;
    if (hdr->total_size != file_size) return 0;
    if (hdr->data_off != sizeof(HeapHeader)) return 0;
    uint64_t exp_total = sizeof(HeapHeader) + hdr->capacity * sizeof(HeapEntry);
    if (hdr->total_size != exp_total) return 0;
    /* Runtime-state sanity: size must not exceed capacity (corrupted file). */
    if (hdr->size > hdr->capacity) return 0;
    return 1;
}

static inline HeapHandle *heap_setup(void *base, size_t ms, const char *path, int bfd) {
    HeapHeader *hdr = (HeapHeader *)base;
    HeapHandle *h = (HeapHandle *)calloc(1, sizeof(HeapHandle));
    if (!h) { munmap(base, ms); return NULL; }
    h->hdr = hdr;
    h->data = (HeapEntry *)((uint8_t *)base + hdr->data_off);
    h->mmap_size = ms;
    h->path = path ? strdup(path) : NULL;
    h->notify_fd = -1;
    h->backing_fd = bfd;
    return h;
}

static HeapHandle *heap_create(const char *path, uint64_t capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { HEAP_ERR("capacity must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(HeapHeader)) / sizeof(HeapEntry)) {
        HEAP_ERR("capacity overflow"); return NULL;
    }

    uint64_t total = sizeof(HeapHeader) + capacity * sizeof(HeapEntry);
    int anonymous = (path == NULL);
    int fd = -1;
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { HEAP_ERR("mmap: %s", strerror(errno)); return NULL; }
    } else {
        fd = open(path, O_RDWR|O_CREAT, 0666);
        if (fd < 0) { HEAP_ERR("open: %s", strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { HEAP_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { HEAP_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(HeapHeader)) {
            HEAP_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total) < 0) {
            HEAP_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { HEAP_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!heap_validate_header((HeapHeader *)base, (uint64_t)st.st_size)) {
                HEAP_ERR("invalid heap file"); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return heap_setup(base, map_size, path, -1);
        }
    }
    heap_init_header(base, total, capacity);
    if (fd >= 0) { flock(fd, LOCK_UN); close(fd); }
    return heap_setup(base, map_size, path, -1);
}

static HeapHandle *heap_create_memfd(const char *name, uint64_t capacity, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (capacity == 0) { HEAP_ERR("capacity must be > 0"); return NULL; }
    if (capacity > (UINT64_MAX - sizeof(HeapHeader)) / sizeof(HeapEntry)) {
        HEAP_ERR("capacity overflow"); return NULL;
    }
    uint64_t total = sizeof(HeapHeader) + capacity * sizeof(HeapEntry);
    int fd = memfd_create(name ? name : "heap", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { HEAP_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total) < 0) { HEAP_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL; }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HEAP_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }
    heap_init_header(base, total, capacity);
    return heap_setup(base, (size_t)total, NULL, fd);
}

static HeapHandle *heap_open_fd(int fd, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) { HEAP_ERR("fstat: %s", strerror(errno)); return NULL; }
    if ((uint64_t)st.st_size < sizeof(HeapHeader)) { HEAP_ERR("too small"); return NULL; }
    size_t ms = (size_t)st.st_size;
    void *base = mmap(NULL, ms, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { HEAP_ERR("mmap: %s", strerror(errno)); return NULL; }
    if (!heap_validate_header((HeapHeader *)base, (uint64_t)st.st_size)) {
        HEAP_ERR("invalid heap"); munmap(base, ms); return NULL;
    }
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) { HEAP_ERR("fcntl: %s", strerror(errno)); munmap(base, ms); return NULL; }
    return heap_setup(base, ms, NULL, myfd);
}

static void heap_destroy(HeapHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* Concurrency-safe: holds mutex (heap is already mutex-based) */
static void heap_clear(HeapHandle *h) {
    heap_mutex_lock(h->hdr);
    h->hdr->size = 0;
    heap_mutex_unlock(h->hdr);
    if (__atomic_load_n(&h->hdr->waiters_pop, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &h->hdr->size, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static int heap_create_eventfd(HeapHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    int efd = eventfd(0, EFD_NONBLOCK|EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->notify_fd = efd; return efd;
}
static int heap_notify(HeapHandle *h) {
    if (h->notify_fd < 0) return 0;
    uint64_t v = 1; return write(h->notify_fd, &v, sizeof(v)) == sizeof(v);
}
static int64_t heap_eventfd_consume(HeapHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t v = 0;
    if (read(h->notify_fd, &v, sizeof(v)) != sizeof(v)) return -1;
    return (int64_t)v;
}
static int heap_msync(HeapHandle *h) { return msync(h->hdr, h->mmap_size, MS_SYNC); }

#endif /* HEAP_H */
