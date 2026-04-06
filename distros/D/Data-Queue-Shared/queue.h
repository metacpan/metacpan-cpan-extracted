/*
 * queue.h -- Shared-memory MPMC queue for Linux
 *
 * Two variants:
 *   Int  — lock-free Vyukov bounded MPMC queue (int64 values)
 *   Str  — futex-mutex protected queue with circular arena (byte strings)
 *
 * Both use file-backed mmap(MAP_SHARED) for cross-process sharing,
 * futex for blocking wait, and PID-based stale lock recovery.
 */

#ifndef QUEUE_H
#define QUEUE_H

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

#define QUEUE_MAGIC       0x51554531U  /* "QUE1" */
#define QUEUE_VERSION     1
#define QUEUE_MODE_INT    0
#define QUEUE_MODE_STR    1
#define QUEUE_MODE_INT32  2
#define QUEUE_MODE_INT16  3
#define QUEUE_ERR_BUFLEN  256
#define QUEUE_SPIN_LIMIT  32
#define QUEUE_LOCK_TIMEOUT_SEC 2

/* ================================================================
 * Header (256 bytes = 4 cache lines, lives at start of mmap)
 * ================================================================ */

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;          /* 0 */
    uint32_t version;        /* 4 */
    uint32_t mode;           /* 8: QUEUE_MODE_INT or QUEUE_MODE_STR */
    uint32_t capacity;       /* 12: max elements (power of 2) */
    uint64_t total_size;     /* 16: mmap size */
    uint64_t slots_off;      /* 24: offset to slot array */
    uint64_t arena_off;      /* 32: str mode: offset to arena; int: 0 */
    uint64_t arena_cap;      /* 40: str mode: arena byte capacity; int: 0 */
    uint8_t  _pad0[16];      /* 48-63 */

    /* ---- Cache line 1 (64-127): head / consumer hot ---- */
    uint64_t head;           /* 64: consumer position */
    uint32_t pop_waiters;    /* 72: count of blocked consumers */
    uint32_t pop_futex;      /* 76: futex word for consumer wakeup */
    uint8_t  _pad1[48];      /* 80-127 */

    /* ---- Cache line 2 (128-191): tail / producer hot ---- */
    uint64_t tail;           /* 128: producer position */
    uint32_t push_waiters;   /* 136: count of blocked producers */
    uint32_t push_futex;     /* 140: futex word for producer wakeup */
    uint8_t  _pad2[48];      /* 144-191 */

    /* ---- Cache line 3 (192-255): mutex + arena state + stats ---- */
    uint32_t mutex;          /* 192: futex-based mutex (0 or PID|0x80000000) */
    uint32_t mutex_waiters;  /* 196 */
    uint32_t arena_wpos;     /* 200: str mode: next write position in arena */
    uint32_t arena_used;     /* 204: str mode: total arena bytes consumed */
    uint64_t stat_push_ok;   /* 208 */
    uint64_t stat_pop_ok;    /* 216 */
    uint64_t stat_push_full; /* 224 */
    uint64_t stat_pop_empty; /* 232 */
    uint32_t stat_recoveries;/* 240 */
    uint8_t  _pad3[12];      /* 244-255 */
} QueueHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(QueueHeader) == 256, "QueueHeader must be 256 bytes");
#endif

/* ================================================================
 * Slot types
 * ================================================================ */

/* Int slot: Vyukov MPMC sequence + value */
typedef struct {
    uint64_t sequence;
    int64_t  value;
} QueueIntSlot;  /* 16 bytes */

/* Compact int slots: 32-bit sequence + value = 8 bytes (2x cache density) */
typedef struct {
    uint32_t sequence;
    int32_t  value;
} QueueInt32Slot;  /* 8 bytes */

typedef struct {
    uint32_t sequence;
    int16_t  value;
    int16_t  _pad;
} QueueInt16Slot;  /* 8 bytes */

/* Str slot: arena pointer + length + skip (for FIFO arena free) */
typedef struct {
    uint32_t arena_off;
    uint32_t packed_len;   /* bit 31 = UTF-8, bits 0-30 = byte length */
    uint32_t arena_skip;   /* bytes to release from arena on pop (includes wrap waste) */
    uint32_t prev_wpos;   /* arena_wpos before this push (for pop_back rollback) */
} QueueStrSlot;  /* 16 bytes */

#define QUEUE_STR_UTF8_FLAG  0x80000000U
#define QUEUE_STR_LEN_MASK   0x7FFFFFFFU

/* ================================================================
 * Process-local handle
 * ================================================================ */

typedef struct {
    QueueHeader *hdr;
    void        *slots;      /* QueueIntSlot* or QueueStrSlot* */
    char        *arena;      /* NULL for int mode */
    size_t       mmap_size;
    uint32_t     capacity;
    uint32_t     cap_mask;   /* capacity - 1 */
    uint64_t     arena_cap;
    char        *copy_buf;   /* for str pop: buffer to copy string before unlock */
    uint32_t     copy_buf_cap;
    char        *path;
    int          notify_fd;  /* eventfd for event-loop integration, -1 if disabled */
    int          backing_fd; /* memfd fd, -1 for file-backed/anonymous */
} QueueHandle;

/* ================================================================
 * Utility
 * ================================================================ */

static inline uint32_t queue_next_pow2(uint32_t v) {
    if (v < 2) return 2;
    if (v > 0x80000000U) return 0;
    v--;
    v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
    return v + 1;
}

static inline void queue_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

static inline int queue_ensure_copy_buf(QueueHandle *h, uint32_t needed) {
    if (needed <= h->copy_buf_cap) return 1;
    uint32_t ns = h->copy_buf_cap ? h->copy_buf_cap : 64;
    while (ns < needed) { uint32_t n2 = ns * 2; if (n2 <= ns) { ns = needed; break; } ns = n2; }
    char *nb = (char *)realloc(h->copy_buf, ns);
    if (!nb) return 0;
    h->copy_buf = nb;
    h->copy_buf_cap = ns;
    return 1;
}

/* ================================================================
 * Futex helpers
 * ================================================================ */

#define QUEUE_MUTEX_WRITER_BIT 0x80000000U
#define QUEUE_MUTEX_PID_MASK   0x7FFFFFFFU
#define QUEUE_MUTEX_VAL(pid)   (QUEUE_MUTEX_WRITER_BIT | ((uint32_t)(pid) & QUEUE_MUTEX_PID_MASK))

static inline int queue_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

static const struct timespec queue_lock_timeout = { QUEUE_LOCK_TIMEOUT_SEC, 0 };

static inline void queue_recover_stale_mutex(QueueHeader *hdr, uint32_t observed) {
    if (!__atomic_compare_exchange_n(&hdr->mutex, &observed, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline void queue_mutex_lock(QueueHeader *hdr) {
    uint32_t mypid = QUEUE_MUTEX_VAL((uint32_t)getpid());
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < QUEUE_SPIN_LIMIT, 1)) {
            queue_spin_pause();
            continue;
        }
        __atomic_add_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->mutex, FUTEX_WAIT, cur,
                              &queue_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
                if (val >= QUEUE_MUTEX_WRITER_BIT) {
                    uint32_t pid = val & QUEUE_MUTEX_PID_MASK;
                    if (!queue_pid_alive(pid))
                        queue_recover_stale_mutex(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void queue_mutex_unlock(QueueHeader *hdr) {
    __atomic_store_n(&hdr->mutex, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

/* Wake blocked consumers (after push) */
static inline void queue_wake_consumers(QueueHeader *hdr) {
    if (__atomic_load_n(&hdr->pop_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->pop_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->pop_futex, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

/* Wake blocked producers (after pop) */
static inline void queue_wake_producers(QueueHeader *hdr) {
    if (__atomic_load_n(&hdr->push_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->push_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->push_futex, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

/* Compute remaining timespec from absolute deadline. Returns 0 if deadline passed. */
static inline int queue_remaining_time(const struct timespec *deadline,
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

/* Convert timeout in seconds (double) to absolute deadline */
static inline void queue_make_deadline(double timeout, struct timespec *deadline) {
    clock_gettime(CLOCK_MONOTONIC, deadline);
    deadline->tv_sec += (time_t)timeout;
    deadline->tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1e9);
    if (deadline->tv_nsec >= 1000000000L) {
        deadline->tv_sec++;
        deadline->tv_nsec -= 1000000000L;
    }
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define QUEUE_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, QUEUE_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static QueueHandle *queue_create(const char *path, uint32_t capacity,
                                  uint32_t mode, uint64_t arena_cap_hint,
                                  char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    uint32_t cap = queue_next_pow2(capacity);
    if (cap == 0) { QUEUE_ERR("invalid capacity"); return NULL; }
    if (mode > QUEUE_MODE_INT16) { QUEUE_ERR("unknown mode %u", mode); return NULL; }

    uint64_t slots_off = sizeof(QueueHeader);
    uint64_t slot_size = (mode == QUEUE_MODE_INT)   ? sizeof(QueueIntSlot)
                       : (mode == QUEUE_MODE_INT32) ? sizeof(QueueInt32Slot)
                       : (mode == QUEUE_MODE_INT16) ? sizeof(QueueInt16Slot)
                       :                              sizeof(QueueStrSlot);
    uint64_t arena_off = 0, arena_cap = 0;
    uint64_t total_size;

    if (mode == QUEUE_MODE_STR) {
        uint64_t slots_end = slots_off + (uint64_t)cap * slot_size;
        arena_off = (slots_end + 7) & ~(uint64_t)7;
        arena_cap = arena_cap_hint;
        if (arena_cap < 4096) arena_cap = 4096;
        if (arena_cap > UINT32_MAX) arena_cap = UINT32_MAX;
        total_size = arena_off + arena_cap;
    } else {
        total_size = slots_off + (uint64_t)cap * slot_size;
    }

    int anonymous = (path == NULL);
    size_t map_size;
    void *base;

    if (anonymous) {
        /* Anonymous shared mmap — fork-inherited, no filesystem */
        map_size = (size_t)total_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) {
            QUEUE_ERR("mmap(anonymous): %s", strerror(errno));
            return NULL;
        }
    } else {
        /* File-backed shared mmap */
        int fd = open(path, O_RDWR | O_CREAT, 0666);
        if (fd < 0) { QUEUE_ERR("open(%s): %s", path, strerror(errno)); return NULL; }

        if (flock(fd, LOCK_EX) < 0) {
            QUEUE_ERR("flock(%s): %s", path, strerror(errno));
            close(fd); return NULL;
        }

        struct stat st;
        if (fstat(fd, &st) < 0) {
            QUEUE_ERR("fstat(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        int is_new = (st.st_size == 0);

        if (!is_new && (uint64_t)st.st_size < sizeof(QueueHeader)) {
            QUEUE_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (is_new) {
            if (ftruncate(fd, (off_t)total_size) < 0) {
                QUEUE_ERR("ftruncate(%s): %s", path, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        map_size = is_new ? (size_t)total_size : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            QUEUE_ERR("mmap(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        QueueHeader *hdr = (QueueHeader *)base;

        if (!is_new) {
            /* Validate existing file */
            int valid = (hdr->magic == QUEUE_MAGIC &&
                         hdr->version == QUEUE_VERSION &&
                         hdr->mode == mode &&
                         hdr->capacity > 0 &&
                         (hdr->capacity & (hdr->capacity - 1)) == 0 &&
                         hdr->total_size == (uint64_t)st.st_size &&
                         hdr->slots_off == sizeof(QueueHeader));
            if (mode == QUEUE_MODE_STR && valid)
                valid = (hdr->arena_off > 0 &&
                         hdr->arena_off + hdr->arena_cap <= hdr->total_size);
            if (!valid) {
                QUEUE_ERR("%s: invalid or incompatible queue file", path);
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            cap = hdr->capacity;
            arena_cap = hdr->arena_cap;
            flock(fd, LOCK_UN);
            close(fd);
            goto setup_handle;
        }

        flock(fd, LOCK_UN);
        close(fd);
    }

    /* Initialize new queue (anonymous or new file) */
    {
        QueueHeader *hdr = (QueueHeader *)base;
        memset(hdr, 0, sizeof(QueueHeader));
        hdr->magic     = QUEUE_MAGIC;
        hdr->version   = QUEUE_VERSION;
        hdr->mode      = mode;
        hdr->capacity  = cap;
        hdr->total_size = total_size;
        hdr->slots_off = slots_off;
        hdr->arena_off = arena_off;
        hdr->arena_cap = arena_cap;

        /* Initialize Vyukov sequence numbers for integer modes */
        #define INIT_SEQ(STYPE, BASE, OFF, CAP) do { \
            STYPE *s = (STYPE *)((char *)(BASE) + (OFF)); \
            for (uint32_t _i = 0; _i < (CAP); _i++) s[_i].sequence = _i; \
        } while(0)
        if      (mode == QUEUE_MODE_INT)   INIT_SEQ(QueueIntSlot,   base, slots_off, cap);
        else if (mode == QUEUE_MODE_INT32) INIT_SEQ(QueueInt32Slot, base, slots_off, cap);
        else if (mode == QUEUE_MODE_INT16) INIT_SEQ(QueueInt16Slot, base, slots_off, cap);
        #undef INIT_SEQ

        __atomic_thread_fence(__ATOMIC_SEQ_CST);
    }

setup_handle:;
    {
    QueueHeader *hdr = (QueueHeader *)base;
    QueueHandle *h = (QueueHandle *)calloc(1, sizeof(QueueHandle));
    if (!h) { munmap(base, map_size); return NULL; }

    h->hdr       = hdr;
    h->slots     = (char *)base + hdr->slots_off;
    h->arena     = (mode == QUEUE_MODE_STR) ? (char *)base + hdr->arena_off : NULL;
    h->mmap_size = map_size;
    h->capacity  = cap;
    h->cap_mask  = cap - 1;
    h->arena_cap = arena_cap;
    h->path      = path ? strdup(path) : NULL;
    h->notify_fd = -1;
    h->backing_fd = -1;

    return h;
    }
}

/* Create queue backed by memfd — shareable via fd passing (SCM_RIGHTS) */
static QueueHandle *queue_create_memfd(const char *name, uint32_t capacity,
                                        uint32_t mode, uint64_t arena_cap_hint,
                                        char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    uint32_t cap = queue_next_pow2(capacity);
    if (cap == 0) { QUEUE_ERR("invalid capacity"); return NULL; }
    if (mode > QUEUE_MODE_INT16) { QUEUE_ERR("unknown mode %u", mode); return NULL; }

    uint64_t slots_off = sizeof(QueueHeader);
    uint64_t slot_size = (mode == QUEUE_MODE_INT)   ? sizeof(QueueIntSlot)
                       : (mode == QUEUE_MODE_INT32) ? sizeof(QueueInt32Slot)
                       : (mode == QUEUE_MODE_INT16) ? sizeof(QueueInt16Slot)
                       :                              sizeof(QueueStrSlot);
    uint64_t arena_off = 0, arena_cap = 0, total_size;

    if (mode == QUEUE_MODE_STR) {
        uint64_t slots_end = slots_off + (uint64_t)cap * slot_size;
        arena_off = (slots_end + 7) & ~(uint64_t)7;
        arena_cap = arena_cap_hint;
        if (arena_cap < 4096) arena_cap = 4096;
        if (arena_cap > UINT32_MAX) arena_cap = UINT32_MAX;
        total_size = arena_off + arena_cap;
    } else {
        total_size = slots_off + (uint64_t)cap * slot_size;
    }

    int fd = memfd_create(name ? name : "queue", MFD_CLOEXEC);
    if (fd < 0) { QUEUE_ERR("memfd_create: %s", strerror(errno)); return NULL; }

    if (ftruncate(fd, (off_t)total_size) < 0) {
        QUEUE_ERR("ftruncate(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        QUEUE_ERR("mmap(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    QueueHeader *hdr = (QueueHeader *)base;
    memset(hdr, 0, sizeof(QueueHeader));
    hdr->magic     = QUEUE_MAGIC;
    hdr->version   = QUEUE_VERSION;
    hdr->mode      = mode;
    hdr->capacity  = cap;
    hdr->total_size = total_size;
    hdr->slots_off = slots_off;
    hdr->arena_off = arena_off;
    hdr->arena_cap = arena_cap;

    #define INIT_SEQ(STYPE, BASE, OFF, CAP) do { \
        STYPE *s = (STYPE *)((char *)(BASE) + (OFF)); \
        for (uint32_t _i = 0; _i < (CAP); _i++) s[_i].sequence = _i; \
    } while(0)
    if      (mode == QUEUE_MODE_INT)   INIT_SEQ(QueueIntSlot,   base, slots_off, cap);
    else if (mode == QUEUE_MODE_INT32) INIT_SEQ(QueueInt32Slot, base, slots_off, cap);
    else if (mode == QUEUE_MODE_INT16) INIT_SEQ(QueueInt16Slot, base, slots_off, cap);
    #undef INIT_SEQ

    __atomic_thread_fence(__ATOMIC_SEQ_CST);

    QueueHandle *h = (QueueHandle *)calloc(1, sizeof(QueueHandle));
    if (!h) { munmap(base, (size_t)total_size); close(fd); return NULL; }

    h->hdr        = hdr;
    h->slots      = (char *)base + slots_off;
    h->arena      = (mode == QUEUE_MODE_STR) ? (char *)base + arena_off : NULL;
    h->mmap_size  = (size_t)total_size;
    h->capacity   = cap;
    h->cap_mask   = cap - 1;
    h->arena_cap  = arena_cap;
    h->path       = NULL;
    h->notify_fd  = -1;
    h->backing_fd = fd;

    return h;
}

/* Open queue from an existing fd (memfd received via SCM_RIGHTS or dup) */
static QueueHandle *queue_open_fd(int fd, uint32_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    struct stat st;
    if (fstat(fd, &st) < 0) {
        QUEUE_ERR("fstat(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    if ((uint64_t)st.st_size < sizeof(QueueHeader)) {
        QUEUE_ERR("fd %d: too small (%lld)", fd, (long long)st.st_size);
        return NULL;
    }

    size_t map_size = (size_t)st.st_size;
    void *base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        QUEUE_ERR("mmap(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    QueueHeader *hdr = (QueueHeader *)base;
    int valid = (hdr->magic == QUEUE_MAGIC &&
                 hdr->version == QUEUE_VERSION &&
                 hdr->mode == mode &&
                 hdr->capacity > 0 &&
                 (hdr->capacity & (hdr->capacity - 1)) == 0 &&
                 hdr->total_size == (uint64_t)st.st_size &&
                 hdr->slots_off == sizeof(QueueHeader));
    if (mode == QUEUE_MODE_STR && valid)
        valid = (hdr->arena_off > 0 &&
                 hdr->arena_off + hdr->arena_cap <= hdr->total_size);
    if (!valid) {
        QUEUE_ERR("fd %d: invalid or incompatible queue", fd);
        munmap(base, map_size);
        return NULL;
    }

    /* Dup the fd so caller retains ownership of the original */
    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) {
        QUEUE_ERR("fcntl(F_DUPFD_CLOEXEC): %s", strerror(errno));
        munmap(base, map_size);
        return NULL;
    }

    QueueHandle *h = (QueueHandle *)calloc(1, sizeof(QueueHandle));
    if (!h) { munmap(base, map_size); close(myfd); return NULL; }

    h->hdr        = hdr;
    h->slots      = (char *)base + hdr->slots_off;
    h->arena      = (mode == QUEUE_MODE_STR) ? (char *)base + hdr->arena_off : NULL;
    h->mmap_size  = map_size;
    h->capacity   = hdr->capacity;
    h->cap_mask   = hdr->capacity - 1;
    h->arena_cap  = hdr->arena_cap;
    h->path       = NULL;
    h->notify_fd  = -1;
    h->backing_fd = myfd;

    return h;
}

static void queue_destroy(QueueHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->copy_buf);
    free(h->path);
    free(h);
}

/* ================================================================
 * Int queue macro template: Vyukov bounded MPMC (lock-free)
 *
 * DEFINE_INT_QUEUE(prefix, SlotType, ValType, SeqType, DiffType)
 *   generates: queue_<prefix>_try_push, try_pop, push_wait, pop_wait,
 *              peek, size, clear
 * ================================================================ */

#define DEFINE_INT_QUEUE(PFX, SLOT, VTYPE, STYPE, DTYPE)                      \
                                                                               \
static inline int queue_##PFX##_try_push(QueueHandle *h, VTYPE value) {       \
    QueueHeader *hdr = h->hdr;                                                \
    SLOT *slots = (SLOT *)h->slots;                                           \
    uint32_t mask = h->cap_mask;                                              \
    uint64_t pos = __atomic_load_n(&hdr->tail, __ATOMIC_RELAXED);             \
    for (;;) {                                                                \
        SLOT *slot = &slots[pos & mask];                                      \
        STYPE seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);       \
        DTYPE diff = (DTYPE)seq - (DTYPE)(STYPE)pos;                          \
        if (diff == 0) {                                                      \
            if (__atomic_compare_exchange_n(&hdr->tail, &pos, pos + 1,        \
                    1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {                 \
                slot->value = value;                                          \
                __atomic_store_n(&slot->sequence, (STYPE)(pos + 1),           \
                                 __ATOMIC_RELEASE);                           \
                __atomic_add_fetch(&hdr->stat_push_ok, 1, __ATOMIC_RELAXED); \
                queue_wake_consumers(hdr);                                    \
                return 1;                                                     \
            }                                                                 \
        } else if (diff < 0) {                                                \
            __atomic_add_fetch(&hdr->stat_push_full, 1, __ATOMIC_RELAXED);   \
            return 0;                                                         \
        } else {                                                              \
            pos = __atomic_load_n(&hdr->tail, __ATOMIC_RELAXED);              \
        }                                                                     \
    }                                                                         \
}                                                                             \
                                                                               \
static inline int queue_##PFX##_try_pop(QueueHandle *h, VTYPE *value) {       \
    QueueHeader *hdr = h->hdr;                                                \
    SLOT *slots = (SLOT *)h->slots;                                           \
    uint32_t mask = h->cap_mask;                                              \
    uint64_t pos = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);             \
    for (;;) {                                                                \
        SLOT *slot = &slots[pos & mask];                                      \
        STYPE seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);       \
        DTYPE diff = (DTYPE)seq - (DTYPE)(STYPE)(pos + 1);                    \
        if (diff == 0) {                                                      \
            if (__atomic_compare_exchange_n(&hdr->head, &pos, pos + 1,        \
                    1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {                 \
                *value = slot->value;                                         \
                __atomic_store_n(&slot->sequence,                             \
                    (STYPE)(pos + h->capacity), __ATOMIC_RELEASE);            \
                __atomic_add_fetch(&hdr->stat_pop_ok, 1, __ATOMIC_RELAXED);  \
                queue_wake_producers(hdr);                                    \
                return 1;                                                     \
            }                                                                 \
        } else if (diff < 0) {                                                \
            __atomic_add_fetch(&hdr->stat_pop_empty, 1, __ATOMIC_RELAXED);   \
            return 0;                                                         \
        } else {                                                              \
            pos = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);              \
        }                                                                     \
    }                                                                         \
}                                                                             \
                                                                               \
static int queue_##PFX##_push_wait(QueueHandle *h, VTYPE value,               \
                                    double timeout) {                          \
    if (queue_##PFX##_try_push(h, value)) return 1;                           \
    if (timeout == 0) return 0;                                               \
    QueueHeader *hdr = h->hdr;                                                \
    struct timespec deadline, remaining;                                       \
    int has_deadline = (timeout > 0);                                         \
    if (has_deadline) queue_make_deadline(timeout, &deadline);                 \
    for (;;) {                                                                \
        uint32_t fseq = __atomic_load_n(&hdr->push_futex, __ATOMIC_ACQUIRE); \
        if (queue_##PFX##_try_push(h, value)) return 1;                       \
        __atomic_add_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);          \
        struct timespec *pts = NULL;                                          \
        if (has_deadline) {                                                    \
            if (!queue_remaining_time(&deadline, &remaining)) {               \
                __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE); \
                return 0;                                                     \
            }                                                                 \
            pts = &remaining;                                                 \
        }                                                                     \
        long rc = syscall(SYS_futex, &hdr->push_futex, FUTEX_WAIT,           \
                          fseq, pts, NULL, 0);                                \
        __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);          \
        if (queue_##PFX##_try_push(h, value)) return 1;                       \
        if (rc == -1 && errno == ETIMEDOUT) return 0;                         \
    }                                                                         \
}                                                                             \
                                                                               \
static int queue_##PFX##_pop_wait(QueueHandle *h, VTYPE *value,               \
                                   double timeout) {                           \
    if (queue_##PFX##_try_pop(h, value)) return 1;                            \
    if (timeout == 0) return 0;                                               \
    QueueHeader *hdr = h->hdr;                                                \
    struct timespec deadline, remaining;                                       \
    int has_deadline = (timeout > 0);                                         \
    if (has_deadline) queue_make_deadline(timeout, &deadline);                 \
    for (;;) {                                                                \
        uint32_t fseq = __atomic_load_n(&hdr->pop_futex, __ATOMIC_ACQUIRE);  \
        if (queue_##PFX##_try_pop(h, value)) return 1;                        \
        __atomic_add_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);           \
        struct timespec *pts = NULL;                                          \
        if (has_deadline) {                                                    \
            if (!queue_remaining_time(&deadline, &remaining)) {               \
                __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);  \
                return 0;                                                     \
            }                                                                 \
            pts = &remaining;                                                 \
        }                                                                     \
        long rc = syscall(SYS_futex, &hdr->pop_futex, FUTEX_WAIT,            \
                          fseq, pts, NULL, 0);                                \
        __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);           \
        if (queue_##PFX##_try_pop(h, value)) return 1;                        \
        if (rc == -1 && errno == ETIMEDOUT) return 0;                         \
    }                                                                         \
}                                                                             \
                                                                               \
static inline int queue_##PFX##_peek(QueueHandle *h, VTYPE *value) {          \
    SLOT *slots = (SLOT *)h->slots;                                           \
    uint64_t pos = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);          \
    SLOT *slot = &slots[pos & h->cap_mask];                                   \
    STYPE seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);           \
    if ((DTYPE)seq - (DTYPE)(STYPE)(pos + 1) == 0) {                          \
        *value = slot->value;                                                 \
        return 1;                                                             \
    }                                                                         \
    return 0;                                                                 \
}                                                                             \
                                                                               \
static inline uint64_t queue_##PFX##_size(QueueHandle *h) {                   \
    uint64_t tail = __atomic_load_n(&h->hdr->tail, __ATOMIC_RELAXED);         \
    uint64_t head = __atomic_load_n(&h->hdr->head, __ATOMIC_RELAXED);         \
    return tail - head;                                                       \
}                                                                             \
                                                                               \
static void queue_##PFX##_clear(QueueHandle *h) {                             \
    VTYPE tmp;                                                                \
    while (queue_##PFX##_try_pop(h, &tmp)) {}                                 \
}

/* Instantiate for Int (64-bit seq + 64-bit value = 16 bytes/slot) */
DEFINE_INT_QUEUE(int, QueueIntSlot, int64_t, uint64_t, int64_t)

/* Instantiate for Int32 (32-bit seq + 32-bit value = 8 bytes/slot) */
DEFINE_INT_QUEUE(int32, QueueInt32Slot, int32_t, uint32_t, int32_t)

/* Instantiate for Int16 (32-bit seq + 16-bit value = 8 bytes/slot) */
DEFINE_INT_QUEUE(int16, QueueInt16Slot, int16_t, uint32_t, int32_t)

/* ================================================================
 * Str queue: mutex-protected with circular arena
 * ================================================================ */

/* Push one item while mutex is already held. Returns 1=ok, 0=full, -2=too long. */
static inline int queue_str_push_locked(QueueHandle *h, const char *str,
                                         uint32_t len, bool utf8) {
    QueueHeader *hdr = h->hdr;

    if (len > QUEUE_STR_LEN_MASK) return -2;

    if (hdr->tail - hdr->head >= h->capacity) {
        hdr->stat_push_full++;
        return 0;
    }

    uint32_t alloc = (len + 7) & ~7u;
    if (alloc == 0) alloc = 8;
    uint32_t saved_wpos = hdr->arena_wpos;
    uint32_t pos = saved_wpos;
    uint64_t skip = alloc;

    if ((uint64_t)pos + alloc > h->arena_cap) {
        skip += h->arena_cap - pos;
        pos = 0;
    }

    if ((uint64_t)hdr->arena_used + skip > h->arena_cap) {
        if (hdr->tail == hdr->head) {
            hdr->arena_wpos = 0;
            hdr->arena_used = 0;
            saved_wpos = 0;
            pos = 0;
            skip = alloc;
        } else {
            hdr->stat_push_full++;
            return 0;
        }
    }

    memcpy(h->arena + pos, str, len);

    uint32_t idx = (uint32_t)(hdr->tail & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];
    slot->arena_off = pos;
    slot->packed_len = len | (utf8 ? QUEUE_STR_UTF8_FLAG : 0);
    slot->arena_skip = (uint32_t)skip;
    slot->prev_wpos = saved_wpos;

    hdr->arena_wpos = pos + alloc;
    hdr->arena_used += (uint32_t)skip;
    hdr->tail++;
    hdr->stat_push_ok++;
    return 1;
}

static inline int queue_str_try_push(QueueHandle *h, const char *str,
                                      uint32_t len, bool utf8) {
    queue_mutex_lock(h->hdr);
    int r = queue_str_push_locked(h, str, len, utf8);
    queue_mutex_unlock(h->hdr);
    if (r == 1) queue_wake_consumers(h->hdr);
    return r;
}

/* Pop one item while mutex is held. Returns 1=ok, 0=empty, -1=OOM. */
static inline int queue_str_pop_locked(QueueHandle *h, const char **out_str,
                                        uint32_t *out_len, bool *out_utf8) {
    QueueHeader *hdr = h->hdr;

    if (hdr->tail == hdr->head) {
        hdr->stat_pop_empty++;
        return 0;
    }

    uint32_t idx = (uint32_t)(hdr->head & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];

    uint32_t len = slot->packed_len & QUEUE_STR_LEN_MASK;
    *out_utf8 = (slot->packed_len & QUEUE_STR_UTF8_FLAG) != 0;

    if (!queue_ensure_copy_buf(h, len + 1))
        return -1;
    if (len > 0)
        memcpy(h->copy_buf, h->arena + slot->arena_off, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;

    hdr->arena_used -= slot->arena_skip;
    if (hdr->arena_used == 0)
        hdr->arena_wpos = 0;

    hdr->head++;
    hdr->stat_pop_ok++;
    return 1;
}

static inline int queue_str_try_pop(QueueHandle *h, const char **out_str,
                                     uint32_t *out_len, bool *out_utf8) {
    queue_mutex_lock(h->hdr);
    int r = queue_str_pop_locked(h, out_str, out_len, out_utf8);
    queue_mutex_unlock(h->hdr);
    if (r == 1) queue_wake_producers(h->hdr);
    return r;
}

static int queue_str_push_wait(QueueHandle *h, const char *str,
                                uint32_t len, bool utf8, double timeout) {
    int r = queue_str_try_push(h, str, len, utf8);
    if (r != 0) return r;  /* 1 = success, -2 = too long */
    if (timeout == 0) return 0;

    QueueHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) queue_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t seq = __atomic_load_n(&hdr->push_futex, __ATOMIC_ACQUIRE);
        r = queue_str_try_push(h, str, len, utf8);
        if (r != 0) return r;

        __atomic_add_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!queue_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, &hdr->push_futex, FUTEX_WAIT, seq, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);

        r = queue_str_try_push(h, str, len, utf8);
        if (r != 0) return r;
        if (rc == -1 && errno == ETIMEDOUT) return 0;
    }
}

static int queue_str_pop_wait(QueueHandle *h, const char **out_str,
                               uint32_t *out_len, bool *out_utf8, double timeout) {
    int r = queue_str_try_pop(h, out_str, out_len, out_utf8);
    if (r != 0) return r;
    if (timeout == 0) return 0;

    QueueHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) queue_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t seq = __atomic_load_n(&hdr->pop_futex, __ATOMIC_ACQUIRE);
        r = queue_str_try_pop(h, out_str, out_len, out_utf8);
        if (r != 0) return r;

        __atomic_add_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!queue_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, &hdr->pop_futex, FUTEX_WAIT, seq, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);

        r = queue_str_try_pop(h, out_str, out_len, out_utf8);
        if (r != 0) return r;
        if (rc == -1 && errno == ETIMEDOUT) return 0;
    }
}

static inline uint64_t queue_str_size(QueueHandle *h) {
    QueueHeader *hdr = h->hdr;
    uint64_t tail = __atomic_load_n(&hdr->tail, __ATOMIC_RELAXED);
    uint64_t head = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);
    return tail - head;  /* unsigned wrap is correct for push_front (head > tail) */
}

static void queue_str_clear(QueueHandle *h) {
    QueueHeader *hdr = h->hdr;
    queue_mutex_lock(hdr);
    hdr->head = 0;
    hdr->tail = 0;
    hdr->arena_wpos = 0;
    hdr->arena_used = 0;
    queue_mutex_unlock(hdr);
    queue_wake_producers(hdr);
    queue_wake_consumers(hdr);
}

/* Peek: read front element without consuming (exact, under mutex). */
static inline int queue_str_peek(QueueHandle *h, const char **out_str,
                                  uint32_t *out_len, bool *out_utf8) {
    QueueHeader *hdr = h->hdr;
    queue_mutex_lock(hdr);
    if (hdr->tail == hdr->head) {
        queue_mutex_unlock(hdr);
        return 0;
    }
    uint32_t idx = (uint32_t)(hdr->head & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];
    uint32_t len = slot->packed_len & QUEUE_STR_LEN_MASK;
    *out_utf8 = (slot->packed_len & QUEUE_STR_UTF8_FLAG) != 0;
    if (!queue_ensure_copy_buf(h, len + 1)) {
        queue_mutex_unlock(hdr);
        return -1;
    }
    if (len > 0)
        memcpy(h->copy_buf, h->arena + slot->arena_off, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;
    queue_mutex_unlock(hdr);
    return 1;
}

/* Push to front of queue (requeue). Str only — Int is strictly FIFO. */
static inline int queue_str_push_front(QueueHandle *h, const char *str,
                                        uint32_t len, bool utf8) {
    QueueHeader *hdr = h->hdr;
    queue_mutex_lock(hdr);

    if (len > QUEUE_STR_LEN_MASK) {
        queue_mutex_unlock(hdr);
        return -2;
    }

    uint64_t size = hdr->tail - hdr->head;
    if (size >= h->capacity) {
        hdr->stat_push_full++;
        queue_mutex_unlock(hdr);
        return 0;
    }

    uint32_t alloc = (len + 7) & ~7u;
    if (alloc == 0) alloc = 8;
    uint32_t saved_wpos = hdr->arena_wpos;
    uint32_t pos = saved_wpos;
    uint64_t skip = alloc;

    if ((uint64_t)pos + alloc > h->arena_cap) {
        skip += h->arena_cap - pos;
        pos = 0;
    }

    if ((uint64_t)hdr->arena_used + skip > h->arena_cap) {
        if (hdr->tail == hdr->head) {
            hdr->arena_wpos = 0;
            hdr->arena_used = 0;
            saved_wpos = 0;
            pos = 0;
            skip = alloc;
        } else {
            hdr->stat_push_full++;
            queue_mutex_unlock(hdr);
            return 0;
        }
    }

    memcpy(h->arena + pos, str, len);

    hdr->head--;
    uint32_t idx = (uint32_t)(hdr->head & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];
    slot->arena_off = pos;
    slot->packed_len = len | (utf8 ? QUEUE_STR_UTF8_FLAG : 0);
    slot->arena_skip = (uint32_t)skip;
    slot->prev_wpos = saved_wpos;

    hdr->arena_wpos = pos + alloc;
    hdr->arena_used += (uint32_t)skip;
    hdr->stat_push_ok++;

    queue_mutex_unlock(hdr);
    queue_wake_consumers(hdr);
    return 1;
}

static int queue_str_push_front_wait(QueueHandle *h, const char *str,
                                      uint32_t len, bool utf8, double timeout) {
    int r = queue_str_push_front(h, str, len, utf8);
    if (r != 0) return r;
    if (timeout == 0) return 0;

    QueueHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) queue_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t seq = __atomic_load_n(&hdr->push_futex, __ATOMIC_ACQUIRE);
        r = queue_str_push_front(h, str, len, utf8);
        if (r != 0) return r;

        __atomic_add_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!queue_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, &hdr->push_futex, FUTEX_WAIT, seq, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);

        r = queue_str_push_front(h, str, len, utf8);
        if (r != 0) return r;
        if (rc == -1 && errno == ETIMEDOUT) return 0;
    }
}

/* Pop from back (tail). Str only — undoes the most recent push. */
static inline int queue_str_pop_back(QueueHandle *h, const char **out_str,
                                      uint32_t *out_len, bool *out_utf8) {
    QueueHeader *hdr = h->hdr;
    queue_mutex_lock(hdr);

    if (hdr->tail == hdr->head) {
        hdr->stat_pop_empty++;
        queue_mutex_unlock(hdr);
        return 0;
    }

    hdr->tail--;
    uint32_t idx = (uint32_t)(hdr->tail & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];

    uint32_t len = slot->packed_len & QUEUE_STR_LEN_MASK;
    *out_utf8 = (slot->packed_len & QUEUE_STR_UTF8_FLAG) != 0;

    if (!queue_ensure_copy_buf(h, len + 1)) {
        hdr->tail++;  /* rollback */
        queue_mutex_unlock(hdr);
        return -1;
    }
    if (len > 0)
        memcpy(h->copy_buf, h->arena + slot->arena_off, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;

    hdr->arena_used -= slot->arena_skip;
    /* Restore arena_wpos to before this slot's push if it's the frontier.
     * prev_wpos correctly handles wrap waste — it's the pre-push state
     * including the original position before any wrap adjustment. */
    {
        uint32_t slot_alloc = (len + 7) & ~7u;
        if (slot_alloc == 0) slot_alloc = 8;
        if (slot->arena_off + slot_alloc == hdr->arena_wpos)
            hdr->arena_wpos = slot->prev_wpos;
    }
    if (hdr->arena_used == 0)
        hdr->arena_wpos = 0;

    hdr->stat_pop_ok++;
    queue_mutex_unlock(hdr);
    queue_wake_producers(hdr);
    return 1;
}

static int queue_str_pop_back_wait(QueueHandle *h, const char **out_str,
                                    uint32_t *out_len, bool *out_utf8, double timeout) {
    int r = queue_str_pop_back(h, out_str, out_len, out_utf8);
    if (r != 0) return r;
    if (timeout == 0) return 0;

    QueueHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) queue_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t seq = __atomic_load_n(&hdr->pop_futex, __ATOMIC_ACQUIRE);
        r = queue_str_pop_back(h, out_str, out_len, out_utf8);
        if (r != 0) return r;

        __atomic_add_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!queue_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, &hdr->pop_futex, FUTEX_WAIT, seq, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);

        r = queue_str_pop_back(h, out_str, out_len, out_utf8);
        if (r != 0) return r;
        if (rc == -1 && errno == ETIMEDOUT) return 0;
    }
}

/* msync — flush mmap to disk for crash durability */
static inline int queue_sync(QueueHandle *h) {
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * eventfd — event-loop integration
 * ================================================================ */

static inline int queue_eventfd_create(QueueHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    h->notify_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    return h->notify_fd;
}

static inline void queue_eventfd_set(QueueHandle *h, int fd) {
    if (h->notify_fd >= 0 && h->notify_fd != fd)
        close(h->notify_fd);
    h->notify_fd = fd;
}

/* Signal that data is available. Called after successful push. */
static inline void queue_notify(QueueHandle *h) {
    if (h->notify_fd >= 0) {
        uint64_t one = 1;
        ssize_t __attribute__((unused)) rc = write(h->notify_fd, &one, sizeof(one));
    }
}

/* Consume notification counter. Call from event-loop callback before pop. */
static inline void queue_eventfd_consume(QueueHandle *h) {
    if (h->notify_fd >= 0) {
        uint64_t val;
        ssize_t __attribute__((unused)) rc = read(h->notify_fd, &val, sizeof(val));
    }
}

#endif /* QUEUE_H */
