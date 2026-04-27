/*
 * buf_generic.h — Macro-template for shared-memory typed buffers.
 *
 * Before including, define:
 *   BUF_PREFIX         — function prefix (e.g., buf_i64)
 *   BUF_ELEM_TYPE      — C element type (e.g., int64_t)
 *   BUF_VARIANT_ID     — unique integer for header validation
 *   BUF_ELEM_SIZE      — sizeof(BUF_ELEM_TYPE) or fixed string length
 *
 * Optional:
 *   BUF_HAS_COUNTERS   — generate incr/decr/cas (integer types only)
 *   BUF_IS_FLOAT       — element is float/double (affects SV conversion)
 *   BUF_IS_FIXEDSTR    — element is fixed-length char array
 */

/* ================================================================
 * Part 1: Shared definitions (included once)
 * ================================================================ */

#ifndef BUF_DEFS_H
#define BUF_DEFS_H

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <limits.h>
#include <signal.h>
#include <errno.h>
#include <linux/futex.h>
#include <sys/eventfd.h>

/* ---- Constants ---- */

#define BUF_MAGIC       0x42554631U  /* "BUF1" */
#define BUF_VERSION     1
#define BUF_ERR_BUFLEN  256

/* ---- Shared memory header (128 bytes, 2 cache lines, in mmap) ---- */

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#define BUF_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)
#else
#define BUF_STATIC_ASSERT(cond, msg)
#endif

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;           /* 0 */
    uint32_t version;         /* 4 */
    uint32_t variant_id;      /* 8 */
    uint32_t elem_size;       /* 12 */
    uint64_t capacity;        /* 16: number of elements */
    uint64_t total_size;      /* 24: total mmap size */
    uint64_t data_off;        /* 32: offset to data array */
    uint8_t  _reserved0[24];  /* 40-63 */

    /* ---- Cache line 1 (64-127): seqlock + rwlock + mutable state ---- */
    uint32_t seq;             /* 64: seqlock counter, odd = writer active */
    uint32_t rwlock;          /* 68: 0=unlocked, readers=1..0x7FFFFFFF, writer=0x80000000|pid */
    uint32_t rwlock_waiters;  /* 72: wake-target counter (readers+writers) */
    uint32_t stat_recoveries; /* 76 */
    uint32_t rwlock_writers_waiting; /* 80: reader yield signal (writers only) */
    uint32_t _pad2;           /* 84 */
    uint64_t _reserved1[5];   /* 88-127 */
} BufHeader;

BUF_STATIC_ASSERT(sizeof(BufHeader) == 128, "BufHeader must be exactly 128 bytes (2 cache lines)");

/* ---- Process-local handle ---- */

typedef struct {
    BufHeader *hdr;
    void      *data;         /* pointer to element array in mmap */
    size_t     mmap_size;
    char      *path;         /* backing file path (strdup'd, NULL for anon) */
    int        fd;           /* kept open for memfd, -1 otherwise */
    int        efd;          /* eventfd for notifications, -1 if none */
    uint8_t    wr_locked;    /* process-local: 1 if lock_wr is held */
    uint8_t    efd_owned;    /* 1 if we created the eventfd (close on destroy) */
} BufHandle;

/* ---- Futex-based read-write lock ---- */

#define BUF_RWLOCK_SPIN_LIMIT 32
#define BUF_LOCK_TIMEOUT_SEC  2

static inline void buf_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

#define BUF_RWLOCK_WRITER_BIT 0x80000000U
#define BUF_RWLOCK_PID_MASK   0x7FFFFFFFU
#define BUF_RWLOCK_WR(pid)    (BUF_RWLOCK_WRITER_BIT | ((uint32_t)(pid) & BUF_RWLOCK_PID_MASK))

static inline int buf_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

static inline void buf_recover_stale_lock(BufHeader *hdr, uint32_t observed_rwlock) {
    uint32_t mypid = BUF_RWLOCK_WR((uint32_t)getpid());
    if (!__atomic_compare_exchange_n(&hdr->rwlock, &observed_rwlock,
            mypid, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
        return;
    uint32_t seq = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
    if (seq & 1)
        __atomic_store_n(&hdr->seq, seq + 1, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static const struct timespec buf_lock_timeout = { BUF_LOCK_TIMEOUT_SEC, 0 };

static inline void buf_rwlock_rdlock(BufHeader *hdr) {
    uint32_t *lock = &hdr->rwlock;
    uint32_t *waiters = &hdr->rwlock_waiters;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    for (int spin = 0; ; spin++) {
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur > 0 && cur < BUF_RWLOCK_WRITER_BIT) {
            if (__atomic_compare_exchange_n(lock, &cur, cur + 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        } else if (cur == 0 && !__atomic_load_n(writers_waiting, __ATOMIC_RELAXED)) {
            if (__atomic_compare_exchange_n(lock, &cur, 1,
                    1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
                return;
        }
        if (__builtin_expect(spin < BUF_RWLOCK_SPIN_LIMIT, 1)) {
            buf_spin_pause();
            continue;
        }
        __atomic_add_fetch(waiters, 1, __ATOMIC_RELAXED);
        cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur >= BUF_RWLOCK_WRITER_BIT || cur == 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &buf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(waiters, 1, __ATOMIC_RELAXED);
                if (cur >= BUF_RWLOCK_WRITER_BIT) {
                    uint32_t val = __atomic_load_n(lock, __ATOMIC_RELAXED);
                    if (val >= BUF_RWLOCK_WRITER_BIT) {
                        uint32_t pid = val & BUF_RWLOCK_PID_MASK;
                        if (!buf_pid_alive(pid))
                            buf_recover_stale_lock(hdr, val);
                    }
                } else {
                    /* Yielding to writer timed out — drop one writers_waiting
                     * to recover from a potentially-crashed parked writer. */
                    uint32_t wc = __atomic_load_n(writers_waiting, __ATOMIC_RELAXED);
                    while (wc > 0 && !__atomic_compare_exchange_n(
                            writers_waiting, &wc, wc - 1,
                            1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {}
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void buf_rwlock_rdunlock(BufHeader *hdr) {
    uint32_t prev = __atomic_sub_fetch(&hdr->rwlock, 1, __ATOMIC_RELEASE);
    if (prev == 0 && __atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void buf_rwlock_wrlock(BufHeader *hdr) {
    uint32_t *lock = &hdr->rwlock;
    uint32_t *waiters = &hdr->rwlock_waiters;
    uint32_t *writers_waiting = &hdr->rwlock_writers_waiting;
    uint32_t mypid = BUF_RWLOCK_WR((uint32_t)getpid());
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(lock, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < BUF_RWLOCK_SPIN_LIMIT, 1)) {
            buf_spin_pause();
            continue;
        }
        __atomic_add_fetch(waiters, 1, __ATOMIC_RELAXED);
        __atomic_add_fetch(writers_waiting, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(lock, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, lock, FUTEX_WAIT, cur,
                              &buf_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(waiters, 1, __ATOMIC_RELAXED);
                __atomic_sub_fetch(writers_waiting, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(lock, __ATOMIC_RELAXED);
                if (val >= BUF_RWLOCK_WRITER_BIT) {
                    uint32_t pid = val & BUF_RWLOCK_PID_MASK;
                    if (!buf_pid_alive(pid))
                        buf_recover_stale_lock(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(waiters, 1, __ATOMIC_RELAXED);
        __atomic_sub_fetch(writers_waiting, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void buf_rwlock_wrunlock(BufHeader *hdr) {
    __atomic_store_n(&hdr->rwlock, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->rwlock_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->rwlock, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* ---- Seqlock ---- */

static inline uint32_t buf_seqlock_read_begin(BufHeader *hdr) {
    int spin = 0;
    for (;;) {
        uint32_t s = __atomic_load_n(&hdr->seq, __ATOMIC_ACQUIRE);
        if (__builtin_expect((s & 1) == 0, 1)) return s;
        if (__builtin_expect(spin < 100000, 1)) {
            buf_spin_pause();
            spin++;
            continue;
        }
        uint32_t val = __atomic_load_n(&hdr->rwlock, __ATOMIC_RELAXED);
        if (val >= BUF_RWLOCK_WRITER_BIT) {
            uint32_t pid = val & BUF_RWLOCK_PID_MASK;
            if (!buf_pid_alive(pid)) {
                buf_recover_stale_lock(hdr, val);
                spin = 0;
                continue;
            }
        }
        struct timespec ts = {0, 1000000};
        nanosleep(&ts, NULL);
        spin = 0;
    }
}

static inline int buf_seqlock_read_retry(uint32_t *seq, uint32_t start) {
    return __atomic_load_n(seq, __ATOMIC_ACQUIRE) != start;
}

static inline void buf_seqlock_write_begin(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);
}

static inline void buf_seqlock_write_end(uint32_t *seq) {
    __atomic_add_fetch(seq, 1, __ATOMIC_RELEASE);
}

/* ---- mmap create/open ---- */

static BufHandle *buf_create_map(const char *path, uint64_t capacity,
                                  uint32_t elem_size, uint32_t variant_id,
                                  char *errbuf) {
    errbuf[0] = '\0';
    int created = 0;
    int fd = open(path, O_RDWR | O_CREAT | O_EXCL, 0666);
    if (fd >= 0) {
        created = 1;
    } else if (errno == EEXIST) {
        fd = open(path, O_RDWR);
    }
    if (fd < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "open(%s): %s", path, strerror(errno));
        return NULL;
    }

    /* Lock file for init race prevention */
    if (flock(fd, LOCK_EX) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "flock(%s): %s", path, strerror(errno));
        close(fd);
        return NULL;
    }

    uint64_t data_off = sizeof(BufHeader); /* 128, already cache-line aligned */
    if (elem_size > 0 && capacity > (UINT64_MAX - data_off) / elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "buffer size overflow");
        flock(fd, LOCK_UN);
        close(fd);
        return NULL;
    }
    uint64_t total_size = data_off + capacity * elem_size;

    struct stat st;
    if (fstat(fd, &st) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fstat(%s): %s", path, strerror(errno));
        flock(fd, LOCK_UN);
        close(fd);
        return NULL;
    }

    if (!created && st.st_size > 0 && (uint64_t)st.st_size < sizeof(BufHeader)) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "%s: file too small (%lld)", path, (long long)st.st_size);
        flock(fd, LOCK_UN); close(fd); return NULL;
    }
    if (created || st.st_size == 0) {
        if (ftruncate(fd, (off_t)total_size) < 0) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "ftruncate(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN);
            close(fd);
            return NULL;
        }
    }

    /* Re-stat after possible truncate */
    if (fstat(fd, &st) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fstat(%s): %s", path, strerror(errno));
        flock(fd, LOCK_UN);
        close(fd);
        return NULL;
    }

    void *base = mmap(NULL, (size_t)st.st_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "mmap(%s): %s", path, strerror(errno));
        flock(fd, LOCK_UN);
        close(fd);
        return NULL;
    }

    BufHeader *hdr = (BufHeader *)base;

    if (created || hdr->magic == 0) {
        /* Initialize header */
        memset(hdr, 0, sizeof(BufHeader));
        hdr->magic = BUF_MAGIC;
        hdr->version = BUF_VERSION;
        hdr->variant_id = variant_id;
        hdr->elem_size = elem_size;
        hdr->capacity = capacity;
        hdr->total_size = (uint64_t)st.st_size;
        hdr->data_off = data_off;
        /* Zero the data area */
        memset((char *)base + data_off, 0, (size_t)(capacity * elem_size));
        __atomic_thread_fence(__ATOMIC_RELEASE);
    } else {
        /* Validate existing header */
        if (hdr->magic != BUF_MAGIC) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: bad magic (0x%08x)", path, hdr->magic);
            goto fail;
        }
        if (hdr->version != BUF_VERSION) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: version mismatch (%u != %u)",
                     path, hdr->version, BUF_VERSION);
            goto fail;
        }
        if (hdr->variant_id != variant_id) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: variant mismatch (%u != %u)",
                     path, hdr->variant_id, variant_id);
            goto fail;
        }
        if (hdr->elem_size != elem_size) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: elem_size mismatch (%u != %u)",
                     path, hdr->elem_size, elem_size);
            goto fail;
        }
        if (hdr->elem_size == 0 ||
            hdr->data_off < sizeof(BufHeader) ||
            hdr->data_off >= (uint64_t)st.st_size ||
            hdr->capacity > ((uint64_t)st.st_size - hdr->data_off) / hdr->elem_size) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "%s: corrupt header (data doesn't fit in file)", path);
            goto fail;
        }
    }

    flock(fd, LOCK_UN);
    close(fd);

    BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
    if (!h) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
        munmap(base, (size_t)st.st_size);
        return NULL;
    }
    h->hdr = hdr;
    h->data = (char *)base + hdr->data_off;
    h->mmap_size = (size_t)st.st_size;
    h->path = strdup(path);
    h->fd = -1;
    h->efd = -1;
    return h;

fail:
    munmap(base, (size_t)st.st_size);
    flock(fd, LOCK_UN);
    close(fd);
    return NULL;
}

/* ---- Anonymous mmap (no file, fork-only sharing) ---- */

static BufHandle *buf_create_anon(uint64_t capacity, uint32_t elem_size,
                                   uint32_t variant_id, char *errbuf) {
    errbuf[0] = '\0';
    uint64_t data_off = sizeof(BufHeader);
    if (elem_size > 0 && capacity > (UINT64_MAX - data_off) / elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "buffer size overflow");
        return NULL;
    }
    uint64_t total_size = data_off + capacity * elem_size;

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (base == MAP_FAILED) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "mmap(anon): %s", strerror(errno));
        return NULL;
    }

    BufHeader *hdr = (BufHeader *)base;
    memset(hdr, 0, sizeof(BufHeader));
    hdr->magic = BUF_MAGIC;
    hdr->version = BUF_VERSION;
    hdr->variant_id = variant_id;
    hdr->elem_size = elem_size;
    hdr->capacity = capacity;
    hdr->total_size = total_size;
    hdr->data_off = data_off;

    BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
    if (!h) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
        munmap(base, (size_t)total_size);
        return NULL;
    }
    h->hdr = hdr;
    h->data = (char *)base + data_off;
    h->mmap_size = (size_t)total_size;
    h->path = NULL;
    h->fd = -1;
    h->efd = -1;
    return h;
}

/* ---- memfd (named anonymous, shareable via fd passing) ---- */

static BufHandle *buf_create_memfd(const char *name, uint64_t capacity,
                                    uint32_t elem_size, uint32_t variant_id,
                                    char *errbuf) {
    errbuf[0] = '\0';
    uint64_t data_off = sizeof(BufHeader);
    if (elem_size > 0 && capacity > (UINT64_MAX - data_off) / elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "buffer size overflow");
        return NULL;
    }
    uint64_t total_size = data_off + capacity * elem_size;

    int fd = (int)syscall(SYS_memfd_create, name, MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "memfd_create: %s", strerror(errno));
        return NULL;
    }
    if (ftruncate(fd, (off_t)total_size) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "ftruncate(memfd): %s", strerror(errno));
        close(fd);
        return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "mmap(memfd): %s", strerror(errno));
        close(fd);
        return NULL;
    }

    BufHeader *hdr = (BufHeader *)base;
    memset(hdr, 0, sizeof(BufHeader));
    hdr->magic = BUF_MAGIC;
    hdr->version = BUF_VERSION;
    hdr->variant_id = variant_id;
    hdr->elem_size = elem_size;
    hdr->capacity = capacity;
    hdr->total_size = total_size;
    hdr->data_off = data_off;

    BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
    if (!h) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
        munmap(base, (size_t)total_size);
        close(fd);
        return NULL;
    }
    h->hdr = hdr;
    h->data = (char *)base + data_off;
    h->mmap_size = (size_t)total_size;
    h->path = NULL;
    h->fd = fd;
    h->efd = -1;
    return h;
}

/* ---- Open from fd (received via SCM_RIGHTS or dup) ---- */

static BufHandle *buf_open_fd(int fd, uint32_t elem_size, uint32_t variant_id,
                               char *errbuf) {
    errbuf[0] = '\0';
    struct stat st;
    if (fstat(fd, &st) < 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fstat(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }
    if ((uint64_t)st.st_size < sizeof(BufHeader)) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: file too small for header", fd);
        return NULL;
    }

    void *base = mmap(NULL, (size_t)st.st_size, PROT_READ | PROT_WRITE,
                       MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "mmap(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    BufHeader *hdr = (BufHeader *)base;
    if (hdr->magic != BUF_MAGIC) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: bad magic (0x%08x)", fd, hdr->magic);
        goto fail;
    }
    if (hdr->version != BUF_VERSION) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: version mismatch (%u != %u)",
                 fd, hdr->version, BUF_VERSION);
        goto fail;
    }
    if (hdr->variant_id != variant_id) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: variant mismatch (%u != %u)",
                 fd, hdr->variant_id, variant_id);
        goto fail;
    }
    if (hdr->elem_size != elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: elem_size mismatch (%u != %u)",
                 fd, hdr->elem_size, elem_size);
        goto fail;
    }
    if (hdr->elem_size == 0 ||
        hdr->data_off != sizeof(BufHeader) ||
        hdr->total_size != (uint64_t)st.st_size ||
        hdr->capacity > ((uint64_t)st.st_size - hdr->data_off) / hdr->elem_size) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "fd=%d: corrupt header", fd);
        goto fail;
    }

    {
        int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
        if (myfd < 0) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "fcntl(F_DUPFD_CLOEXEC, fd=%d): %s",
                     fd, strerror(errno));
            munmap(base, (size_t)st.st_size);
            return NULL;
        }
        BufHandle *h = (BufHandle *)calloc(1, sizeof(BufHandle));
        if (!h) {
            snprintf(errbuf, BUF_ERR_BUFLEN, "calloc: out of memory");
            close(myfd);
            munmap(base, (size_t)st.st_size);
            return NULL;
        }
        h->hdr = hdr;
        h->data = (char *)base + hdr->data_off;
        h->mmap_size = (size_t)st.st_size;
        h->path = NULL;
        h->fd = myfd;
        h->efd = -1;
        return h;
    }

fail:
    munmap(base, (size_t)st.st_size);
    return NULL;
}

/* ---- msync ---- */

static inline int buf_msync(BufHandle *h) {
    if (!h || !h->hdr) return 0;
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

/* ---- Eventfd integration (opt-in notifications) ---- */

static int buf_create_eventfd(BufHandle *h) {
    if (h->efd >= 0) return h->efd;
    int efd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (efd < 0) return -1;
    h->efd = efd;
    h->efd_owned = 1;
    return efd;
}

static void buf_attach_eventfd(BufHandle *h, int efd) {
    if (h->efd >= 0 && h->efd_owned) close(h->efd);
    h->efd = efd;
    h->efd_owned = 0;
}

static int buf_notify(BufHandle *h) {
    if (h->efd < 0) return 0;
    uint64_t val = 1;
    return write(h->efd, &val, sizeof(val)) == sizeof(val);
}

static int64_t buf_wait_notify(BufHandle *h) {
    if (h->efd < 0) return -1;
    uint64_t val = 0;
    if (read(h->efd, &val, sizeof(val)) != sizeof(val)) return -1;
    return (int64_t)val;
}

static void buf_close_map(BufHandle *h) {
    if (!h) return;
    if (h->efd >= 0 && h->efd_owned) close(h->efd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    if (h->fd >= 0) close(h->fd);
    if (h->path) free(h->path);
    free(h);
}

#endif /* BUF_DEFS_H */


/* ================================================================
 * Part 2: Per-variant functions (instantiated per include)
 * ================================================================ */

#ifndef BUF_PREFIX
#error "BUF_PREFIX must be defined before including buf_generic.h"
#endif

#define BUF_PASTE2(a, b) a##_##b
#define BUF_PASTE(a, b)  BUF_PASTE2(a, b)
#define BUF_FN(name)     BUF_PASTE(BUF_PREFIX, name)

/* ---- Create ---- */

#ifdef BUF_IS_FIXEDSTR
static BufHandle *BUF_FN(create)(const char *path, uint64_t capacity,
                                  uint32_t str_len, char *errbuf) {
    if (str_len == 0) {
        snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0");
        return NULL;
    }
    return buf_create_map(path, capacity, str_len, BUF_VARIANT_ID, errbuf);
}
#else
static BufHandle *BUF_FN(create)(const char *path, uint64_t capacity, char *errbuf) {
    return buf_create_map(path, capacity, BUF_ELEM_SIZE, BUF_VARIANT_ID, errbuf);
}
#endif

/* ---- Create anonymous ---- */

#ifdef BUF_IS_FIXEDSTR
static BufHandle *BUF_FN(create_anon)(uint64_t capacity, uint32_t str_len, char *errbuf) {
    if (str_len == 0) { snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0"); return NULL; }
    return buf_create_anon(capacity, str_len, BUF_VARIANT_ID, errbuf);
}
static BufHandle *BUF_FN(create_memfd)(const char *name, uint64_t capacity, uint32_t str_len, char *errbuf) {
    if (str_len == 0) { snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0"); return NULL; }
    return buf_create_memfd(name, capacity, str_len, BUF_VARIANT_ID, errbuf);
}
static BufHandle *BUF_FN(open_fd)(int fd, uint32_t str_len, char *errbuf) {
    if (str_len == 0) { snprintf(errbuf, BUF_ERR_BUFLEN, "str_len must be > 0"); return NULL; }
    return buf_open_fd(fd, str_len, BUF_VARIANT_ID, errbuf);
}
#else
static BufHandle *BUF_FN(create_anon)(uint64_t capacity, char *errbuf) {
    return buf_create_anon(capacity, BUF_ELEM_SIZE, BUF_VARIANT_ID, errbuf);
}
static BufHandle *BUF_FN(create_memfd)(const char *name, uint64_t capacity, char *errbuf) {
    return buf_create_memfd(name, capacity, BUF_ELEM_SIZE, BUF_VARIANT_ID, errbuf);
}
static BufHandle *BUF_FN(open_fd)(int fd, char *errbuf) {
    return buf_open_fd(fd, BUF_ELEM_SIZE, BUF_VARIANT_ID, errbuf);
}
#endif

/* ---- Raw byte access (for packed binary interop) ---- */

static int BUF_FN(get_raw)(BufHandle *h, uint64_t byte_off, uint64_t nbytes, void *out) {
    uint64_t data_size = h->hdr->capacity * (uint64_t)h->hdr->elem_size;
    if (nbytes > data_size || byte_off > data_size - nbytes) return 0;
    char *data = (char *)h->data;
    if (h->wr_locked) {
        memcpy(out, data + byte_off, (size_t)nbytes);
    } else {
        uint32_t seq_start;
        do {
            seq_start = buf_seqlock_read_begin(h->hdr);
            memcpy(out, data + byte_off, (size_t)nbytes);
        } while (buf_seqlock_read_retry(&h->hdr->seq, seq_start));
    }
    return 1;
}

static int BUF_FN(set_raw)(BufHandle *h, uint64_t byte_off, uint64_t nbytes, const void *in) {
    uint64_t data_size = h->hdr->capacity * (uint64_t)h->hdr->elem_size;
    if (nbytes > data_size || byte_off > data_size - nbytes) return 0;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(h->hdr); buf_seqlock_write_begin(&h->hdr->seq); }
    memcpy(data + byte_off, in, (size_t)nbytes);
    if (!nested) { buf_seqlock_write_end(&h->hdr->seq); buf_rwlock_wrunlock(h->hdr); }
    return 1;
}

/* ---- Clear (zero entire buffer) ---- */

static void BUF_FN(clear)(BufHandle *h) {
    BufHeader *hdr = h->hdr;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(hdr); buf_seqlock_write_begin(&hdr->seq); }
    memset(h->data, 0, (size_t)(hdr->capacity * hdr->elem_size));
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(hdr); }
}

/* ---- Single-element atomic get (lock-free for numeric types) ---- */

#ifdef BUF_IS_FIXEDSTR

static int BUF_FN(get)(BufHandle *h, uint64_t idx, char *out, uint32_t *out_len) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    if (idx >= hdr->capacity) return 0;
    char *data = (char *)h->data;
    if (h->wr_locked) {
        memcpy(out, data + idx * esz, esz);
    } else {
        uint32_t seq_start;
        do {
            seq_start = buf_seqlock_read_begin(hdr);
            memcpy(out, data + idx * esz, esz);
        } while (buf_seqlock_read_retry(&hdr->seq, seq_start));
    }
    uint32_t len = esz;
    while (len > 0 && out[len - 1] == '\0') len--;
    *out_len = len;
    return 1;
}

static int BUF_FN(set)(BufHandle *h, uint64_t idx, const char *val, uint32_t len) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    if (idx >= hdr->capacity) return 0;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(hdr); buf_seqlock_write_begin(&hdr->seq); }
    memset(data + idx * esz, 0, esz);
    uint32_t copy_len = len < esz ? len : esz;
    memcpy(data + idx * esz, val, copy_len);
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(hdr); }
    return 1;
}

#elif defined(BUF_IS_FLOAT)

/* Float/double: GCC __atomic builtins don't support FP types.
 * Use same-sized integer atomic load/store + memcpy for lock-free access. */

#if BUF_ELEM_SIZE == 4
typedef uint32_t BUF_PASTE(BUF_PREFIX, _uint_t);
#elif BUF_ELEM_SIZE == 8
typedef uint64_t BUF_PASTE(BUF_PREFIX, _uint_t);
#else
#error "BUF_IS_FLOAT requires BUF_ELEM_SIZE of 4 or 8"
#endif

static int BUF_FN(get)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE *out) {
    BufHeader *hdr = h->hdr;
    if (idx >= hdr->capacity) return 0;
    typedef BUF_PASTE(BUF_PREFIX, _uint_t) uint_t;
    uint_t *idata = (uint_t *)h->data;
    uint_t tmp = __atomic_load_n(&idata[idx], __ATOMIC_RELAXED);
    memcpy(out, &tmp, sizeof(BUF_ELEM_TYPE));
    return 1;
}

static int BUF_FN(set)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE val) {
    BufHeader *hdr = h->hdr;
    if (idx >= hdr->capacity) return 0;
    typedef BUF_PASTE(BUF_PREFIX, _uint_t) uint_t;
    uint_t *idata = (uint_t *)h->data;
    uint_t tmp;
    memcpy(&tmp, &val, sizeof(BUF_ELEM_TYPE));
    __atomic_store_n(&idata[idx], tmp, __ATOMIC_RELAXED);
    return 1;
}

#else /* integer types */

static int BUF_FN(get)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE *out) {
    BufHeader *hdr = h->hdr;
    if (idx >= hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    *out = __atomic_load_n(&data[idx], __ATOMIC_RELAXED);
    return 1;
}

static int BUF_FN(set)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE val) {
    BufHeader *hdr = h->hdr;
    if (idx >= hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    __atomic_store_n(&data[idx], val, __ATOMIC_RELAXED);
    return 1;
}

#endif /* BUF_IS_FIXEDSTR */

/* ---- Bulk operations (seqlock-guarded) ---- */

#ifdef BUF_IS_FIXEDSTR

static int BUF_FN(get_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              void *out) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    if (count > hdr->capacity || from > hdr->capacity - count) return 0;
    char *data = (char *)h->data;
    if (h->wr_locked) {
        memcpy(out, data + from * esz, count * esz);
    } else {
        uint32_t seq_start;
        do {
            seq_start = buf_seqlock_read_begin(hdr);
            memcpy(out, data + from * esz, count * esz);
        } while (buf_seqlock_read_retry(&hdr->seq, seq_start));
    }
    return 1;
}

static int BUF_FN(set_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              const void *in) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    if (count > hdr->capacity || from > hdr->capacity - count) return 0;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(hdr); buf_seqlock_write_begin(&hdr->seq); }
    memcpy(data + from * esz, in, count * esz);
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(hdr); }
    return 1;
}

#else /* numeric */

static int BUF_FN(get_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              BUF_ELEM_TYPE *out) {
    BufHeader *hdr = h->hdr;
    if (count > hdr->capacity || from > hdr->capacity - count) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    if (h->wr_locked) {
        memcpy(out, &data[from], count * sizeof(BUF_ELEM_TYPE));
    } else {
        uint32_t seq_start;
        do {
            seq_start = buf_seqlock_read_begin(hdr);
            memcpy(out, &data[from], count * sizeof(BUF_ELEM_TYPE));
        } while (buf_seqlock_read_retry(&hdr->seq, seq_start));
    }
    return 1;
}

static int BUF_FN(set_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              const BUF_ELEM_TYPE *in) {
    BufHeader *hdr = h->hdr;
    if (count > hdr->capacity || from > hdr->capacity - count) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(hdr); buf_seqlock_write_begin(&hdr->seq); }
    memcpy(&data[from], in, count * sizeof(BUF_ELEM_TYPE));
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(hdr); }
    return 1;
}

#endif /* BUF_IS_FIXEDSTR */

/* ---- Fill ---- */

#ifdef BUF_IS_FIXEDSTR

static void BUF_FN(fill)(BufHandle *h, const char *val, uint32_t len) {
    BufHeader *hdr = h->hdr;
    uint32_t esz = hdr->elem_size;
    char *data = (char *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(hdr); buf_seqlock_write_begin(&hdr->seq); }
    uint32_t copy_len = len < esz ? len : esz;
    memset(data, 0, (size_t)hdr->capacity * esz);
    for (uint64_t i = 0; i < hdr->capacity; i++)
        memcpy(data + i * esz, val, copy_len);
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(hdr); }
}

#else

static void BUF_FN(fill)(BufHandle *h, BUF_ELEM_TYPE val) {
    BufHeader *hdr = h->hdr;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    int nested = h->wr_locked;
    if (!nested) { buf_rwlock_wrlock(hdr); buf_seqlock_write_begin(&hdr->seq); }
    for (uint64_t i = 0; i < hdr->capacity; i++)
        data[i] = val;
    if (!nested) { buf_seqlock_write_end(&hdr->seq); buf_rwlock_wrunlock(hdr); }
}

#endif

/* ---- Atomic operations (integer types only) ---- */

#ifdef BUF_HAS_COUNTERS

static BUF_ELEM_TYPE BUF_FN(incr)(BufHandle *h, uint64_t idx) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_add_fetch(&data[idx], 1, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(decr)(BufHandle *h, uint64_t idx) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_sub_fetch(&data[idx], 1, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(add)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE delta) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_add_fetch(&data[idx], delta, __ATOMIC_RELAXED);
}

static int BUF_FN(cas)(BufHandle *h, uint64_t idx,
                        BUF_ELEM_TYPE expected, BUF_ELEM_TYPE desired) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_compare_exchange_n(&data[idx], &expected, desired,
                                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(cmpxchg)(BufHandle *h, uint64_t idx,
                                       BUF_ELEM_TYPE expected, BUF_ELEM_TYPE desired) {
    if (idx >= h->hdr->capacity) return expected;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    __atomic_compare_exchange_n(&data[idx], &expected, desired,
                                0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
    return expected; /* on failure, expected is updated to the current value */
}

static BUF_ELEM_TYPE BUF_FN(atomic_and)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_and_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(atomic_or)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_or_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static BUF_ELEM_TYPE BUF_FN(atomic_xor)(BufHandle *h, uint64_t idx, BUF_ELEM_TYPE mask) {
    if (idx >= h->hdr->capacity) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    return __atomic_xor_fetch(&data[idx], mask, __ATOMIC_RELAXED);
}

static int BUF_FN(add_slice)(BufHandle *h, uint64_t from, uint64_t count,
                              const BUF_ELEM_TYPE *deltas) {
    if (count > h->hdr->capacity || from > h->hdr->capacity - count) return 0;
    BUF_ELEM_TYPE *data = (BUF_ELEM_TYPE *)h->data;
    for (uint64_t i = 0; i < count; i++)
        __atomic_add_fetch(&data[from + i], deltas[i], __ATOMIC_RELAXED);
    return 1;
}

#endif /* BUF_HAS_COUNTERS */

/* ---- Diagnostics ---- */

static inline uint64_t BUF_FN(capacity)(BufHandle *h) {
    return h->hdr->capacity;
}

static inline uint64_t BUF_FN(mmap_size)(BufHandle *h) {
    return (uint64_t)h->mmap_size;
}

static inline uint32_t BUF_FN(elem_size)(BufHandle *h) {
    return h->hdr->elem_size;
}

/* ---- Raw pointer access (for passing to external C/XS code) ---- */

static inline void *BUF_FN(ptr)(BufHandle *h) {
    return h->data;
}

static inline void *BUF_FN(ptr_at)(BufHandle *h, uint64_t idx) {
    if (idx >= h->hdr->capacity) return NULL;
    return (char *)h->data + idx * h->hdr->elem_size;
}

/* ---- Explicit locking for batch operations ---- */

static inline void BUF_FN(lock_wr)(BufHandle *h) {
    buf_rwlock_wrlock(h->hdr);
    buf_seqlock_write_begin(&h->hdr->seq);
    h->wr_locked = 1;
}

static inline void BUF_FN(unlock_wr)(BufHandle *h) {
    h->wr_locked = 0;
    buf_seqlock_write_end(&h->hdr->seq);
    buf_rwlock_wrunlock(h->hdr);
}

static inline void BUF_FN(lock_rd)(BufHandle *h) {
    buf_rwlock_rdlock(h->hdr);
}

static inline void BUF_FN(unlock_rd)(BufHandle *h) {
    buf_rwlock_rdunlock(h->hdr);
}

/* ---- Cleanup ---- */

#undef BUF_PASTE2
#undef BUF_PASTE
#undef BUF_FN
#undef BUF_PREFIX
#undef BUF_ELEM_TYPE
#undef BUF_ELEM_SIZE
#undef BUF_VARIANT_ID
#ifdef BUF_HAS_COUNTERS
#undef BUF_HAS_COUNTERS
#endif
#ifdef BUF_IS_FLOAT
#undef BUF_IS_FLOAT
#endif
#ifdef BUF_IS_FIXEDSTR
#undef BUF_IS_FIXEDSTR
#endif
