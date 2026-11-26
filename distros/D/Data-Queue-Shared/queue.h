/*
 * queue.h -- Shared-memory MPMC queue for Linux
 *
 * Two variants:
 *   Int  -- lock-free Vyukov bounded MPMC queue (int64 values)
 *   Str  -- futex-mutex protected queue with circular arena (byte strings)
 *
 * Both use file-backed mmap(MAP_SHARED) for cross-process sharing,
 * futex for blocking wait, and PID-based stale lock recovery.
 */

#ifndef QUEUE_H
#define QUEUE_H

#include <stddef.h>
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
#define QUEUE_VERSION     2
#define QUEUE_MODE_INT    0
#define QUEUE_MODE_STR    1
#define QUEUE_MODE_INT32  2
#define QUEUE_MODE_INT16  3
#define QUEUE_ERR_BUFLEN  (PATH_MAX + 256)
#define QUEUE_SPIN_LIMIT  32
/* Period of the safety retries in the wait loops, and the longest wait before a lock holder is checked. */
#define QUEUE_RECHECK_SEC 2
#define QUEUE_RECHECK_NS  (QUEUE_RECHECK_SEC * 1000000000L)
/* A lock waiter first checks the holder is alive after this, doubling up to QUEUE_RECHECK_NS. */
#define QUEUE_LOCK_CHECK_NS 1000000L
/* Arena bytes populated per step, under the mutex: small, as every producer waits for it. */
#define QUEUE_POPULATE_CHUNK (16u << 10)

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
    uint64_t pidns;          /* 48: creator's PID namespace inode, 0 if unknown */
    uint32_t pidns_mixed;    /* 56: set once a process of another PID namespace attaches */
    uint8_t  _pad0[4];       /* 60-63 */

    /* ---- Cache line 1 (64-127): head / consumer hot ---- */
    uint64_t head;           /* 64: consumer position */
    uint32_t pop_waiters;    /* 72: count of blocked consumers */
    uint32_t pop_futex;      /* 76: futex word for consumer wakeup */
    uint8_t  _pad1[48];      /* 80-127 */

    /* ---- Cache line 2 (128-191): tail / producer hot ---- */
    uint64_t tail;           /* 128: producer position */
    uint32_t push_waiters;   /* 136: count of blocked producers */
    uint32_t push_futex;     /* 140: futex word for producer wakeup */
    uint64_t stat_lock_waits;      /* 144: Str lock acquisitions that slept */
    uint64_t stat_lock_wait_ns;    /* 152 */
    uint64_t stat_lock_wait_max_ns;/* 160 */
    uint64_t stat_lock_timeouts;   /* 168 */
    uint64_t stat_last_recovery;   /* 176: CLOCK_REALTIME seconds */
    uint8_t  _pad2[8];             /* 184-191 */

    /* ---- Cache line 3 (192-255): mutex + arena state + stats ---- */
    uint32_t mutex;          /* 192: futex-based mutex (0 or PID|0x80000000) */
    uint32_t mutex_waiters;  /* 196 */
    union {
        struct {
            uint32_t arena_wpos; /* 200 */
            uint32_t arena_used; /* 204 */
        };
        uint64_t arena_state;
    };
    uint64_t stat_push_ok;   /* 208 */
    uint64_t stat_pop_ok;    /* 216 */
    uint64_t stat_push_full; /* 224 */
    uint64_t stat_pop_empty; /* 232 */
    uint64_t stat_recoveries;/* 240 */
    uint32_t str_arena_wait; /* 248: a producer has run out of arena bytes */
    uint32_t arena_populated;/* 252: arena bytes below this are allocated */
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
    int          notify_fd_owned; /* 1 if we created notify_fd and must close it */
    double       lock_timeout; /* Str: seconds to wait for the mutex, < 0 for no limit */
    int          fail_errno;
    int          same_pidns;   /* this process sees the creator's PIDs */
} QueueHandle;

/* An operation that did nothing for a reason in h->fail_errno. */
#define QUEUE_FAILED (-3)

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

/* Keep the arena front consistent if a process dies between metadata writes. */
static inline void queue_set_arena(QueueHeader *hdr, uint32_t wpos, uint32_t used) {
    union { uint32_t parts[2]; uint64_t word; } state;
    state.parts[0] = wpos;
    state.parts[1] = used;
    __atomic_store_n(&hdr->arena_state, state.word, __ATOMIC_RELEASE);
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
    if (!(timeout < 1e9)) timeout = 1e9; /* clamp Inf/NaN/huge: avoid UB (time_t) cast -> instant spurious timeout */
    deadline->tv_sec += (time_t)timeout;
    deadline->tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1e9);
    if (deadline->tv_nsec >= 1000000000L) {
        deadline->tv_sec++;
        deadline->tv_nsec -= 1000000000L;
    }
}

/* ================================================================
 * Futex helpers
 * ================================================================ */

#define QUEUE_MUTEX_WRITER_BIT 0x80000000U
#define QUEUE_MUTEX_PID_MASK   0x7FFFFFFFU
#define QUEUE_MUTEX_VAL(pid)   (QUEUE_MUTEX_WRITER_BIT | ((uint32_t)(pid) & QUEUE_MUTEX_PID_MASK))

/* A zombie (dead but not yet reaped) still answers kill(pid,0) as alive, so a
 * process that crashed while holding the lock and lingers unreaped would never
 * be recovered.  Treat /proc/<pid>/stat state 'Z' as dead.  Linux-only (as is
 * this module); if /proc is unreadable we fall back to "alive" (safe: we never
 * force-recover a possibly-live holder). */
static inline int queue_pid_is_zombie(uint32_t pid) {
    char path[32], buf[256];
    snprintf(path, sizeof(path), "/proc/%u/stat", (unsigned)pid);
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return 0;
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (n <= 0) return 0;
    buf[n] = '\0';
    /* "pid (comm) state ..."; comm may contain ')', so scan to the last one. */
    char *rp = strrchr(buf, ')');
    if (!rp || rp + 2 >= buf + n) return 0;   /* need ") X" within the bytes read */
    return rp[1] == ' ' && rp[2] == 'Z';
}
static inline int queue_pid_alive(uint32_t pid) {
    if (pid == 0) return 0; /* no owner recorded, treat as dead */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0; /* definitely dead */
    if (queue_pid_is_zombie(pid)) return 0; /* zombie -> treat as dead */
    /* Re-check kill(): if process was reaped during proc scan, ESRCH avoids 2s stall */
    if (kill((pid_t)pid, 0) == -1 && errno == ESRCH) return 0;
    return 1;
}

static const struct timespec queue_recheck = { QUEUE_RECHECK_SEC, 0 };

#ifndef MADV_WIPEONFORK
#define MADV_WIPEONFORK 18
#endif

/* getpid() costs a syscall per lock. The cache sits in a page MADV_WIPEONFORK zeroes in a forked
 * child, so a child never takes the lock under its parent's PID. */
static uint32_t queue_self_pid(void) {
    static uint32_t *cache;
    static int uncached;
    uint32_t *c = __atomic_load_n(&cache, __ATOMIC_ACQUIRE);
    if (c && *c) return *c;
    uint32_t pid = (uint32_t)getpid();
    if (!c && !uncached) {
        size_t page = (size_t)sysconf(_SC_PAGESIZE);
        void *p = mmap(NULL, page, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (p == MAP_FAILED) { uncached = 1; return pid; }
        if (madvise(p, page, MADV_WIPEONFORK) < 0) { munmap(p, page); uncached = 1; return pid; }
        uint32_t *expected = NULL;
        if (__atomic_compare_exchange_n(&cache, &expected, (uint32_t *)p, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE))
            c = (uint32_t *)p;
        else { munmap(p, page); c = expected; }
    }
    if (c) *c = pid;
    return pid;
}

static uint64_t queue_pidns(void) {
    struct stat st;
    return stat("/proc/self/ns/pid", &st) == 0 ? (uint64_t)st.st_ino : 0;
}

static inline int queue_recover_stale_mutex(QueueHeader *hdr, uint32_t observed) {
    if (!__atomic_compare_exchange_n(&hdr->mutex, &observed, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return 0;
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    __atomic_store_n(&hdr->stat_last_recovery, (uint64_t)time(NULL), __ATOMIC_RELAXED);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
    return 1;
}

static inline int queue_recover_dead_holder(QueueHeader *hdr, uint32_t val) {
    return val >= QUEUE_MUTEX_WRITER_BIT
        && !queue_pid_alive(val & QUEUE_MUTEX_PID_MASK)
        && queue_recover_stale_mutex(hdr, val);
}

/* Under the mutex, after a wait that started at *since. */
static void queue_lock_wait_stat(QueueHeader *hdr, const struct timespec *since) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    uint64_t ns = (uint64_t)(now.tv_sec - since->tv_sec) * 1000000000u + now.tv_nsec - since->tv_nsec;
    __atomic_store_n(&hdr->stat_lock_waits, hdr->stat_lock_waits + 1, __ATOMIC_RELAXED);
    __atomic_store_n(&hdr->stat_lock_wait_ns, hdr->stat_lock_wait_ns + ns, __ATOMIC_RELAXED);
    if (ns > hdr->stat_lock_wait_max_ns)
        __atomic_store_n(&hdr->stat_lock_wait_max_ns, ns, __ATOMIC_RELAXED);
}

/* Takes the Str mutex, or returns 0 once h->lock_timeout runs out. PIDs of another namespace look
 * dead, so a queue shared across PID namespaces checks a holder only after QUEUE_RECHECK_NS. */
static int queue_str_lock(QueueHandle *h) {
    QueueHeader *hdr = h->hdr;
    uint32_t mypid = QUEUE_MUTEX_VAL(queue_self_pid());
    uint32_t watched = 0;
    long check_ns = 0;
    struct timespec deadline, slept_at;
    int has_deadline = 0, slept = 0;
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
            if (slept) queue_lock_wait_stat(hdr, &slept_at);
            return 1;
        }
        if (__builtin_expect(spin < QUEUE_SPIN_LIMIT, 1)) {
            queue_spin_pause();
            continue;
        }
        spin = 0;
        int fast = h->same_pidns && !__atomic_load_n(&hdr->pidns_mixed, __ATOMIC_SEQ_CST);
        __atomic_add_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
        if (cur == 0) {
            __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
            continue;
        }
        if (cur != watched) { watched = cur; check_ns = fast ? QUEUE_LOCK_CHECK_NS : QUEUE_RECHECK_NS; }
        struct timespec ts = { check_ns / 1000000000L, check_ns % 1000000000L };
        int full_wait = 1;
        if (h->lock_timeout >= 0) {
            struct timespec rem;
            if (!has_deadline) { queue_make_deadline(h->lock_timeout, &deadline); has_deadline = 1; }
            if (!queue_remaining_time(&deadline, &rem)) {
                __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
                if (fast && queue_recover_dead_holder(hdr, cur)) continue;
                __atomic_add_fetch(&hdr->stat_lock_timeouts, 1, __ATOMIC_RELAXED);
                h->fail_errno = EAGAIN;
                return 0;
            }
            if (rem.tv_sec < ts.tv_sec || (rem.tv_sec == ts.tv_sec && rem.tv_nsec < ts.tv_nsec))
                ts = rem, full_wait = 0;
        }
        if (!slept) { clock_gettime(CLOCK_MONOTONIC, &slept_at); slept = 1; }
        long rc = syscall(SYS_futex, &hdr->mutex, FUTEX_WAIT, cur, &ts, NULL, 0);
        int timed_out = rc == -1 && errno == ETIMEDOUT;
        __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        if (!timed_out || __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED) != cur)
            watched = 0;   /* the lock moved on: check the next hold afresh */
        else if (full_wait && !queue_recover_dead_holder(hdr, cur))
            check_ns = check_ns < QUEUE_RECHECK_NS / 2 ? check_ns * 2 : QUEUE_RECHECK_NS;
    }
}

static inline void queue_mutex_unlock(QueueHeader *hdr) {
    __atomic_store_n(&hdr->mutex, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

/* Wake up to `n` blocked consumers (after batch push). Each woken
 * consumer pops at most one item, so batch publishers must wake `n`
 * (not 1) to drain a multi-item commit without leaving consumers
 * sleeping on still-available items. */
static inline void queue_wake_consumers_n(QueueHeader *hdr, uint32_t n) {
    if (n == 0) return;
    if (__atomic_load_n(&hdr->pop_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->pop_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->pop_futex, FUTEX_WAKE,
                n > (uint32_t)INT_MAX ? INT_MAX : (int)n, NULL, NULL, 0);
    }
}

/* Wake blocked consumers (after single push) */
static inline void queue_wake_consumers(QueueHeader *hdr) {
    queue_wake_consumers_n(hdr, 1);
}

/* Wake up to `n` blocked producers (after batch pop). See
 * queue_wake_consumers_n for the batching rationale. */
static inline void queue_wake_producers_n(QueueHeader *hdr, uint32_t n) {
    if (n == 0) return;
    if (__atomic_load_n(&hdr->push_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->push_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->push_futex, FUTEX_WAKE,
                n > (uint32_t)INT_MAX ? INT_MAX : (int)n, NULL, NULL, 0);
    }
}

/* Wake blocked producers (after single pop) */
static inline void queue_wake_producers(QueueHeader *hdr) {
    queue_wake_producers_n(hdr, 1);
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define QUEUE_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, QUEUE_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

#define QUEUE_FORMAT_ERR "queue file format v%u, this module uses v%u; recreate the queue"

typedef struct { uint32_t cap; uint64_t arena_off, arena_cap, total_size; } QueueGeometry;

static uint64_t queue_slot_size(uint32_t mode) {
    return mode == QUEUE_MODE_INT   ? sizeof(QueueIntSlot)
         : mode == QUEUE_MODE_INT32 ? sizeof(QueueInt32Slot)
         : mode == QUEUE_MODE_INT16 ? sizeof(QueueInt16Slot)
         :                            sizeof(QueueStrSlot);
}

static int queue_geometry(uint32_t capacity, uint32_t mode, uint64_t arena_cap_hint,
                          QueueGeometry *g, char *errbuf) {
    g->cap = queue_next_pow2(capacity);
    if (g->cap == 0) { QUEUE_ERR("invalid capacity"); return 0; }
    if (mode > QUEUE_MODE_INT16) { QUEUE_ERR("unknown mode %u", mode); return 0; }
    uint64_t slots_end = sizeof(QueueHeader) + (uint64_t)g->cap * queue_slot_size(mode);
    g->arena_off = g->arena_cap = 0;
    g->total_size = slots_end;
    if (mode == QUEUE_MODE_STR) {
        g->arena_off = (slots_end + 7) & ~(uint64_t)7;
        g->arena_cap = arena_cap_hint < 4096 ? 4096 : arena_cap_hint > UINT32_MAX ? UINT32_MAX : arena_cap_hint;
        g->total_size = g->arena_off + g->arena_cap;
    }
    return 1;
}

static void queue_init_new_header(void *base, const QueueGeometry *g, uint32_t mode, uint64_t reserved) {
    QueueHeader *hdr = (QueueHeader *)base;
    memset(hdr, 0, sizeof(QueueHeader));
    hdr->version    = QUEUE_VERSION;
    hdr->mode       = mode;
    hdr->capacity   = g->cap;
    hdr->total_size = g->total_size;
    hdr->slots_off  = sizeof(QueueHeader);
    hdr->arena_off  = g->arena_off;
    hdr->arena_cap  = g->arena_cap;
    hdr->pidns      = queue_pidns();
    hdr->arena_populated = reserved >= g->total_size ? (uint32_t)g->arena_cap : 0;
    #define INIT_SEQ(STYPE) do { \
        STYPE *s = (STYPE *)((char *)base + sizeof(QueueHeader)); \
        for (uint32_t _i = 0; _i < g->cap; _i++) s[_i].sequence = _i; \
    } while(0)
    if      (mode == QUEUE_MODE_INT)   INIT_SEQ(QueueIntSlot);
    else if (mode == QUEUE_MODE_INT32) INIT_SEQ(QueueInt32Slot);
    else if (mode == QUEUE_MODE_INT16) INIT_SEQ(QueueInt16Slot);
    #undef INIT_SEQ
    /* Publish magic LAST, as a release store: it is the commit point, so a
       creator killed before it leaves magic==0 and never a file mistaken for
       a valid one.  A kill during the field stores leaves one to remove by
       hand. */
    __atomic_store_n(&hdr->magic, QUEUE_MAGIC, __ATOMIC_RELEASE);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static int queue_header_valid(const QueueHeader *hdr, uint32_t mode, uint64_t size) {
    uint64_t slot_size = queue_slot_size(mode);
    if (!(hdr->magic == QUEUE_MAGIC && hdr->version == QUEUE_VERSION && hdr->mode == mode
          && hdr->capacity >= 2 && (hdr->capacity & (hdr->capacity - 1)) == 0
          && hdr->total_size == size && hdr->slots_off == sizeof(QueueHeader)
          && hdr->capacity <= (hdr->total_size - hdr->slots_off) / slot_size))
        return 0;
    if (mode != QUEUE_MODE_STR) return 1;
    uint64_t slots_end = hdr->slots_off + (uint64_t)hdr->capacity * slot_size;
    return hdr->arena_cap >= 4096 && (hdr->arena_off & 7) == 0 && hdr->arena_off >= slots_end
        && hdr->arena_off <= hdr->total_size && hdr->arena_cap <= hdr->total_size - hdr->arena_off;
}

static QueueHandle *queue_handle_new(void *base, size_t map_size, const char *path, int backing_fd) {
    QueueHeader *hdr = (QueueHeader *)base;
    QueueHandle *h = (QueueHandle *)calloc(1, sizeof(QueueHandle));
    if (!h) return NULL;
    h->hdr          = hdr;
    h->slots        = (char *)base + hdr->slots_off;
    h->arena        = hdr->mode == QUEUE_MODE_STR ? (char *)base + hdr->arena_off : NULL;
    h->mmap_size    = map_size;
    h->capacity     = hdr->capacity;
    h->cap_mask     = hdr->capacity - 1;
    h->arena_cap    = hdr->arena_cap;
    h->path         = path ? strdup(path) : NULL;
    h->notify_fd    = -1;
    h->backing_fd   = backing_fd;
    h->lock_timeout = -1;
    uint64_t ns = queue_pidns();
    h->same_pidns = ns && ns == hdr->pidns;
    if (!h->same_pidns) __atomic_store_n(&hdr->pidns_mixed, 1, __ATOMIC_SEQ_CST);
    return h;
}

/* Securely obtain a fd: create exclusively (O_CREAT|O_EXCL|O_NOFOLLOW at
 * file_mode, default 0600 = owner-only), or attach an existing file
 * (O_RDWR|O_NOFOLLOW, no O_CREAT). Blocks a symlink swap or a pre-seeded/
 * hard-linked backing file; cross-user sharing is opt-in via a wider file_mode. */
static int queue_secure_open(const char *path, mode_t file_mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, file_mode);
        if (fd >= 0) { (void)fchmod(fd, file_mode); return fd; }   /* exact mode: umask narrowed the O_EXCL create */
        if (errno != EEXIST) { QUEUE_ERR("create(%s): %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;
        QUEUE_ERR("open(%s): %s", path, strerror(errno));
        return -1;
    }
    QUEUE_ERR("open(%s): create/attach kept racing", path);
    return -1;
}

/* True iff the whole file is zero -- what an abandoned mid-init
   creator leaves.  Lets recovery re-init only a provably-empty file, never
   one that merely starts with a zero word.  Cold path, so a byte scan is
   fine.  Read, not mapped: a read fault on a tmpfs hole allocates the page. */
static int queue_file_is_zero(int fd, uint64_t size) {
    char buf[16384];
    for (uint64_t off = 0; off < size; ) {
        ssize_t n = pread(fd, buf, size - off < sizeof buf ? (size_t)(size - off) : sizeof buf, (off_t)off);
        if (n <= 0) return 0;
        for (ssize_t i = 0; i < n; i++) if (buf[i]) return 0;
        off += (uint64_t)n;
    }
    return 1;
}

/* A sparse segment would SIGBUS at the first write the filesystem cannot back. */
static uint64_t queue_reserve_len(uint32_t mode, uint64_t total_size, uint64_t arena_off) {
    const char *sp = getenv("DATA_QUEUE_SHARED_SPARSE");
    if (sp && *sp) return strcmp(sp, "0") ? 0 : total_size;
    return mode == QUEUE_MODE_STR ? arena_off : total_size;
}

static int queue_reserve(int fd, uint64_t size) {
    if (!size) return 0;
    /* Before Linux 6.11 tmpfs gives up at any pending signal and undoes the allocation, so a
     * periodic one could keep it from ever completing; SIGSTOP cannot be blocked. */
    sigset_t all, old;
    sigfillset(&all);
    sigprocmask(SIG_BLOCK, &all, &old);
    int e;
    do e = posix_fallocate(fd, 0, (off_t)size); while (e == EINTR);
    sigprocmask(SIG_SETMASK, &old, NULL);
    if (e == 0 || e == EOPNOTSUPP || e == EINVAL) return 0;
    errno = e;
    return -1;
}

static QueueHandle *queue_create(const char *path, uint32_t capacity,
                                  uint32_t mode, uint64_t arena_cap_hint,
                                  mode_t file_mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    QueueGeometry g;
    if (!queue_geometry(capacity, mode, arena_cap_hint, &g, errbuf)) return NULL;
    uint64_t total_size = g.total_size;

    int anonymous = (path == NULL);
    size_t map_size;
    void *base;

    if (anonymous) {
        /* Anonymous shared mmap -- fork-inherited, no filesystem */
        map_size = (size_t)total_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) {
            QUEUE_ERR("mmap(anonymous): %s", strerror(errno));
            return NULL;
        }
        queue_init_new_header(base, &g, mode, 0);
    } else {
        /* File-backed shared mmap */
        uint64_t reserved = queue_reserve_len(mode, total_size, g.arena_off);
        int fd = queue_secure_open(path, file_mode, errbuf);
        if (fd < 0) return NULL;

        if (flock(fd, LOCK_EX) < 0) {
            QUEUE_ERR("flock(%s): %s", path, strerror(errno));
            close(fd); return NULL;
        }

        struct stat st;
        if (fstat(fd, &st) < 0) {
            QUEUE_ERR("fstat(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (!S_ISREG(st.st_mode)) {
            QUEUE_ERR("%s: invalid (not a regular file)", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        int is_new = (st.st_size == 0);

        if (!is_new && (uint64_t)st.st_size < sizeof(QueueHeader)) {
            QUEUE_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (is_new && (st.st_uid != geteuid() || fchmod(fd, file_mode) < 0)) {
            QUEUE_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new) {
            if (ftruncate(fd, (off_t)total_size) < 0) {
                QUEUE_ERR("ftruncate(%s): %s", path, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (queue_reserve(fd, reserved) < 0) {
                QUEUE_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)reserved, strerror(errno));
                if (ftruncate(fd, 0) < 0) { /* best effort */ }
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        map_size = is_new ? (size_t)total_size : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            QUEUE_ERR("mmap(%s): %s", path, strerror(errno));
            if (is_new && ftruncate(fd, 0) < 0) { /* best effort */ }
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        QueueHeader *hdr = (QueueHeader *)base;

        if (!is_new) {
            if (!queue_header_valid(hdr, mode, (uint64_t)st.st_size)) {
                /* Recover an abandoned mid-init file: a creator killed
                 * between the ftruncate and the header init leaves a
                 * full-size, all-zero (magic==0) file that would brick every
                 * future open of this path.  Re-initialize ONLY when it is
                 * exactly our size, still uninitialized, and owned by us;
                 * anything else still errors. */
                if (hdr->magic == 0 && (uint64_t)st.st_size == total_size
                    && st.st_uid == geteuid() && queue_file_is_zero(fd, map_size)) {
                    if (fchmod(fd, file_mode) < 0) {
                        QUEUE_ERR("%s: fchmod: %s", path, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    if (queue_reserve(fd, reserved) < 0) {
                        QUEUE_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)reserved, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    queue_init_new_header(base, &g, mode, reserved);
                    flock(fd, LOCK_UN); close(fd);
                    goto setup_handle;
                }
                if (hdr->magic == 0 && (uint64_t)st.st_size == total_size
                    && st.st_uid == geteuid())
                    QUEUE_ERR("%s: incomplete queue file left by an interrupted create; remove it and retry", path);
                else if (hdr->magic == QUEUE_MAGIC && hdr->version != QUEUE_VERSION)
                    QUEUE_ERR("%s: " QUEUE_FORMAT_ERR, path, hdr->version, QUEUE_VERSION);
                else
                    QUEUE_ERR("%s: invalid or incompatible queue file", path);
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN);
            close(fd);
            goto setup_handle;
        }

        queue_init_new_header(base, &g, mode, reserved);
        flock(fd, LOCK_UN);
        close(fd);
    }

setup_handle:;
    QueueHandle *h = queue_handle_new(base, map_size, path, -1);
    if (!h) munmap(base, map_size);
    return h;
}

/* Create queue backed by memfd -- shareable via fd passing (SCM_RIGHTS) */
static QueueHandle *queue_create_memfd(const char *name, uint32_t capacity,
                                        uint32_t mode, uint64_t arena_cap_hint,
                                        char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    QueueGeometry g;
    if (!queue_geometry(capacity, mode, arena_cap_hint, &g, errbuf)) return NULL;
    uint64_t total_size = g.total_size;

    int fd = memfd_create(name ? name : "queue", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { QUEUE_ERR("memfd_create: %s", strerror(errno)); return NULL; }

    if (ftruncate(fd, (off_t)total_size) < 0) {
        QUEUE_ERR("ftruncate(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }
    uint64_t reserved = queue_reserve_len(mode, total_size, g.arena_off);
    if (queue_reserve(fd, reserved) < 0) {
        QUEUE_ERR("memfd: cannot reserve %llu bytes: %s", (unsigned long long)reserved, strerror(errno));
        close(fd); return NULL;
    }

    /* Seal size against ftruncate-based SIGBUS attacks via SCM_RIGHTS peers. */
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        QUEUE_ERR("mmap(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    queue_init_new_header(base, &g, mode, reserved);
    QueueHandle *h = queue_handle_new(base, (size_t)total_size, NULL, fd);
    if (!h) { munmap(base, (size_t)total_size); close(fd); }
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

    if (!S_ISREG(st.st_mode)) {
        QUEUE_ERR("fd %d: invalid (not a regular file)", fd);
        return NULL;
    }

    if ((uint64_t)st.st_size < sizeof(QueueHeader)) {
        QUEUE_ERR("fd %d: too small (%lld)", fd, (long long)st.st_size);
        return NULL;
    }

    /* before mmap: a creator may truncate the file until it has set magic */
    uint32_t magic;
    if (pread(fd, &magic, sizeof magic, offsetof(QueueHeader, magic)) != (ssize_t)sizeof magic || magic != QUEUE_MAGIC) {
        QUEUE_ERR("fd %d: invalid or incompatible queue", fd);
        return NULL;
    }

    size_t map_size = (size_t)st.st_size;
    void *base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        QUEUE_ERR("mmap(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    QueueHeader *hdr = (QueueHeader *)base;
    if (!queue_header_valid(hdr, mode, (uint64_t)st.st_size)) {
        if (hdr->version != QUEUE_VERSION)
            QUEUE_ERR("fd %d: " QUEUE_FORMAT_ERR, fd, hdr->version, QUEUE_VERSION);
        else
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

    QueueHandle *h = queue_handle_new(base, map_size, NULL, myfd);
    if (!h) { munmap(base, map_size); close(myfd); }
    return h;
}

static void queue_destroy(QueueHandle *h) {
    if (!h) return;
    /* Only close notify_fd if we own it; caller-supplied fds (via
     * queue_eventfd_set) remain the caller's responsibility. */
    if (h->notify_fd >= 0 && h->notify_fd_owned) close(h->notify_fd);
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
    int spins = 0;                                                            \
    for (;;) {                                                                \
        SLOT *slot = &slots[pos & mask];                                      \
        STYPE seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);       \
        DTYPE diff = (DTYPE)(seq - (STYPE)pos);                               \
        if (diff == 0) {                                                      \
            if (__atomic_compare_exchange_n(&hdr->tail, &pos, pos + 1,        \
                    1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {                 \
                slot->value = value;                                          \
                __atomic_store_n(&slot->sequence, (STYPE)(pos + 1),           \
                                 __ATOMIC_RELEASE);                           \
                /* Order publication before the waiter-count read. */       \
                __atomic_add_fetch(&hdr->stat_push_ok, 1, __ATOMIC_SEQ_CST); \
                queue_wake_consumers(hdr);                                    \
                return 1;                                                     \
            }                                                                 \
            spins = 0;                                                        \
        } else if (diff < 0) {                                                \
            __atomic_add_fetch(&hdr->stat_push_full, 1, __ATOMIC_RELAXED);   \
            return 0;                                                         \
        } else {                                                              \
            uint64_t next_pos = __atomic_load_n(&hdr->tail, __ATOMIC_RELAXED);\
            if (next_pos == pos) {                                            \
                queue_spin_pause();                                           \
                if (++spins > QUEUE_SPIN_LIMIT) return 0;                     \
                continue;                                                     \
            }                                                                 \
            pos = next_pos;                                                   \
            spins = 0;                                                        \
        }                                                                     \
    }                                                                         \
}                                                                             \
                                                                               \
static inline int queue_##PFX##_try_pop(QueueHandle *h, VTYPE *value) {       \
    QueueHeader *hdr = h->hdr;                                                \
    SLOT *slots = (SLOT *)h->slots;                                           \
    uint32_t mask = h->cap_mask;                                              \
    uint64_t pos = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);             \
    int spins = 0;                                                            \
    for (;;) {                                                                \
        SLOT *slot = &slots[pos & mask];                                      \
        STYPE seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);       \
        DTYPE diff = (DTYPE)(seq - (STYPE)(pos + 1));                         \
        if (diff == 0) {                                                      \
            if (__atomic_compare_exchange_n(&hdr->head, &pos, pos + 1,        \
                    1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {                 \
                *value = slot->value;                                         \
                __atomic_store_n(&slot->sequence,                             \
                    (STYPE)(pos + h->capacity), __ATOMIC_RELEASE);            \
                __atomic_add_fetch(&hdr->stat_pop_ok, 1, __ATOMIC_SEQ_CST);  \
                queue_wake_producers(hdr);                                    \
                return 1;                                                     \
            }                                                                 \
            spins = 0;                                                        \
        } else if (diff < 0) {                                                \
            __atomic_add_fetch(&hdr->stat_pop_empty, 1, __ATOMIC_RELAXED);   \
            return 0;                                                         \
        } else {                                                              \
            uint64_t next_pos = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);\
            if (next_pos == pos) {                                            \
                queue_spin_pause();                                           \
                if (++spins > QUEUE_SPIN_LIMIT) return 0;                     \
                continue;                                                     \
            }                                                                 \
            pos = next_pos;                                                   \
            spins = 0;                                                        \
        }                                                                     \
    }                                                                         \
}                                                                             \
                                                                               \
/* Pass a wake onward when reservations completed out of order. */           \
static inline void queue_##PFX##_handoff(QueueHandle *h, bool producer) {     \
    QueueHeader *hdr = h->hdr;                                                \
    uint32_t *waiters = producer ? &hdr->push_waiters : &hdr->pop_waiters;     \
    if (!__atomic_load_n(waiters, __ATOMIC_RELAXED)) return;                 \
    uint64_t pos = __atomic_load_n(producer ? &hdr->tail : &hdr->head,        \
                                   __ATOMIC_RELAXED);                        \
    SLOT *slot = &((SLOT *)h->slots)[pos & h->cap_mask];                       \
    STYPE seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);           \
    if ((DTYPE)(seq - (STYPE)(pos + (producer ? 0 : 1))) < 0) return;         \
    if (producer) queue_wake_producers(hdr);                                  \
    else queue_wake_consumers(hdr);                                           \
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
        /* Announce waiter BEFORE sampling fseq and re-checking the         \
         * condition. The reverse order races with a waker that pops       \
         * between our check and our announce: the waker reads             \
         * push_waiters==0, skips the push_futex bump, and our subsequent  \
         * FUTEX_WAIT then sleeps on an unchanged seq with no future       \
         * waker to wake it. */                                             \
        __atomic_add_fetch(&hdr->push_waiters, 1, __ATOMIC_SEQ_CST);          \
        uint32_t fseq = __atomic_load_n(&hdr->push_futex, __ATOMIC_ACQUIRE); \
        if (queue_##PFX##_try_push(h, value)) {                               \
            __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);      \
            queue_##PFX##_handoff(h, true);                                   \
            return 1;                                                         \
        }                                                                     \
        const struct timespec *pts = &queue_recheck;                          \
        if (has_deadline) {                                                    \
            if (!queue_remaining_time(&deadline, &remaining)) {               \
                __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE); \
                return 0;                                                     \
            }                                                                 \
            if (remaining.tv_sec < QUEUE_RECHECK_SEC) pts = &remaining;       \
        }                                                                     \
        long rc = syscall(SYS_futex, &hdr->push_futex, FUTEX_WAIT,           \
                          fseq, pts, NULL, 0);                                \
        __atomic_sub_fetch(&hdr->push_waiters, 1, __ATOMIC_RELEASE);          \
        if (queue_##PFX##_try_push(h, value)) {                               \
            queue_##PFX##_handoff(h, true);                                   \
            return 1;                                                         \
        }                                                                     \
        if (has_deadline && rc == -1 && errno == ETIMEDOUT && !queue_remaining_time(&deadline, &remaining)) return 0;                         \
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
        /* Announce BEFORE sampling fseq / checking condition; see        \
         * queue_##PFX##_push_wait for the missed-wakeup race this        \
         * ordering closes. */                                             \
        __atomic_add_fetch(&hdr->pop_waiters, 1, __ATOMIC_SEQ_CST);           \
        uint32_t fseq = __atomic_load_n(&hdr->pop_futex, __ATOMIC_ACQUIRE);  \
        if (queue_##PFX##_try_pop(h, value)) {                                \
            __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);       \
            queue_##PFX##_handoff(h, false);                                  \
            return 1;                                                         \
        }                                                                     \
        const struct timespec *pts = &queue_recheck;                          \
        if (has_deadline) {                                                    \
            if (!queue_remaining_time(&deadline, &remaining)) {               \
                __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);  \
                return 0;                                                     \
            }                                                                 \
            if (remaining.tv_sec < QUEUE_RECHECK_SEC) pts = &remaining;       \
        }                                                                     \
        long rc = syscall(SYS_futex, &hdr->pop_futex, FUTEX_WAIT,            \
                          fseq, pts, NULL, 0);                                \
        __atomic_sub_fetch(&hdr->pop_waiters, 1, __ATOMIC_RELEASE);           \
        if (queue_##PFX##_try_pop(h, value)) {                                \
            queue_##PFX##_handoff(h, false);                                  \
            return 1;                                                         \
        }                                                                     \
        if (has_deadline && rc == -1 && errno == ETIMEDOUT && !queue_remaining_time(&deadline, &remaining)) return 0;                         \
    }                                                                         \
}                                                                             \
                                                                               \
static inline int queue_##PFX##_peek(QueueHandle *h, VTYPE *value) {          \
    SLOT *slots = (SLOT *)h->slots;                                           \
    uint64_t pos = __atomic_load_n(&h->hdr->head, __ATOMIC_ACQUIRE);          \
    SLOT *slot = &slots[pos & h->cap_mask];                                   \
    STYPE seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);           \
    if ((DTYPE)(seq - (STYPE)(pos + 1)) == 0) {                               \
        *value = slot->value;                                                 \
        return 1;                                                             \
    }                                                                         \
    return 0;                                                                 \
}                                                                             \
                                                                               \
static inline uint64_t queue_##PFX##_size(QueueHandle *h) {                   \
    uint64_t tail = __atomic_load_n(&h->hdr->tail, __ATOMIC_RELAXED);         \
    uint64_t head = __atomic_load_n(&h->hdr->head, __ATOMIC_RELAXED);         \
    uint64_t diff = tail - head;                                              \
    if ((int64_t)diff < 0) return 0;                                          \
    return diff > h->capacity ? h->capacity : diff;                           \
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

/* Under the mutex: a woken large value may not fit while a smaller one does.
 * Wake its peers once per removal, without changing the space futex sequence. */
static inline void queue_str_arena_blocked(QueueHandle *h) {
    QueueHeader *hdr = h->hdr;
    if (hdr->str_arena_wait) return;
    hdr->str_arena_wait = 1;
    if (h->arena_cap - hdr->arena_used >= 8
        && __atomic_load_n(&hdr->push_waiters, __ATOMIC_RELAXED))
        syscall(SYS_futex, &hdr->push_futex, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

static inline uint32_t queue_str_producer_wake_count(QueueHeader *hdr, uint32_t n) {
    if (!hdr->str_arena_wait) return n;
    hdr->str_arena_wait = 0;
    return INT_MAX;
}

#ifndef MADV_POPULATE_WRITE
#define MADV_POPULATE_WRITE 23
#endif

/* Allocates the pages under [p, p+len) as a write would, but fails instead of raising SIGBUS;
 * does nothing on kernels without MADV_POPULATE_WRITE (before 5.14). */
static int queue_populate(char *p, uint64_t len) {
    static uintptr_t page;
    static int unsupported;
    if (unsupported) return 0;
    if (!page) page = (uintptr_t)sysconf(_SC_PAGESIZE);
    uintptr_t a = (uintptr_t)p & ~(page - 1);
    uintptr_t e = ((uintptr_t)p + len + page - 1) & ~(page - 1);
    int r, tries = 0;
    do r = madvise((void *)a, e - a, MADV_POPULATE_WRITE);
    while (r < 0 && (errno == EINTR || errno == EAGAIN) && ++tries < 8);
    if (r < 0 && errno == EINVAL) unsupported = 1, r = 0;
    return r;
}

/* Under the mutex, before writing arena bytes [pos, end); only push_front's wrap to the top writes above the mark. */
static int queue_arena_populate(QueueHandle *h, uint32_t pos, uint32_t end) {
    QueueHeader *hdr = h->hdr;
    uint32_t mark = hdr->arena_populated;
    if (end <= mark) return 1;
    uint64_t from = pos > mark ? pos : mark, to = end;
    if (from == mark) {
        uint64_t step = (uint64_t)mark + QUEUE_POPULATE_CHUNK;
        if (step > h->arena_cap) step = h->arena_cap;
        if (step > to) to = step;
    }
    if (queue_populate(h->arena + from, to - from) < 0) {
        h->fail_errno = errno == EFAULT ? ENOSPC : errno;
        return 0;
    }
    if (from == mark) __atomic_store_n(&hdr->arena_populated, (uint32_t)to, __ATOMIC_RELAXED);
    return 1;
}

/* Push one item while mutex is already held. Returns 1=ok, 0=full, -2=too long, QUEUE_FAILED. */
static inline int queue_str_push_locked(QueueHandle *h, const char *str,
                                         uint32_t len, bool utf8) {
    QueueHeader *hdr = h->hdr;

    if (len > QUEUE_STR_LEN_MASK) return -2;

    if (hdr->tail - hdr->head >= h->capacity) {
        __atomic_add_fetch(&hdr->stat_push_full, 1, __ATOMIC_RELAXED);
        return 0;
    }

    uint32_t alloc = (len + 7) & ~7u;
    if (alloc == 0) alloc = 8;
    if (alloc > h->arena_cap) return -2;
    uint32_t saved_wpos = hdr->arena_wpos;
    uint32_t pos = saved_wpos;
    uint64_t skip = alloc;

    if (pos >= h->arena_cap || (uint64_t)pos + alloc > h->arena_cap) {
        skip += (pos < h->arena_cap) ? (h->arena_cap - pos) : 0;
        pos = 0;
    }

    if ((uint64_t)hdr->arena_used + skip > h->arena_cap) {
        if (hdr->tail == hdr->head) {
            saved_wpos = 0;
            pos = 0;
            skip = alloc;
        } else {
            queue_str_arena_blocked(h);
            __atomic_add_fetch(&hdr->stat_push_full, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }

    if (!queue_arena_populate(h, pos, pos + alloc)) return QUEUE_FAILED;
    memcpy(h->arena + pos, str, len);

    uint32_t idx = (uint32_t)(hdr->tail & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];
    slot->arena_off = pos;
    slot->packed_len = len | (utf8 ? QUEUE_STR_UTF8_FLAG : 0);
    slot->arena_skip = (uint32_t)skip;
    slot->prev_wpos = saved_wpos;

    queue_set_arena(hdr, pos + alloc,
        hdr->tail == hdr->head ? (uint32_t)skip : hdr->arena_used + (uint32_t)skip);
    /* Publish after the payload and arena state, including on weakly ordered CPUs. */
    __atomic_store_n(&hdr->tail, hdr->tail + 1, __ATOMIC_RELEASE);
    __atomic_add_fetch(&hdr->stat_push_ok, 1, __ATOMIC_RELAXED);
    return 1;
}

static inline int queue_str_try_push(QueueHandle *h, const char *str,
                                      uint32_t len, bool utf8) {
    if (!queue_str_lock(h)) return QUEUE_FAILED;
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
        __atomic_add_fetch(&hdr->stat_pop_empty, 1, __ATOMIC_RELAXED);
        return 0;
    }

    uint32_t idx = (uint32_t)(hdr->head & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];

    uint32_t off = slot->arena_off;
    uint32_t len = slot->packed_len & QUEUE_STR_LEN_MASK;
    /* arena_off/len come from the mmap'd slot; a local peer can corrupt the
     * backing file. Bound the record against the arena so a poisoned slot
     * yields an empty payload instead of an out-of-bounds read (CWE-125). */
    if ((uint64_t)off + len > h->arena_cap) len = 0;
    *out_utf8 = (slot->packed_len & QUEUE_STR_UTF8_FLAG) != 0;

    if (!queue_ensure_copy_buf(h, len + 1))
        return -1;
    if (len > 0)
        memcpy(h->copy_buf, h->arena + off, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;

    int last = hdr->tail == hdr->head + 1;
    uint32_t skip = slot->arena_skip;
    /* Consume before crediting the bytes back: a crash between the two then
     * leaves a self-healing over-count, not a message the next push overwrites. */
    __atomic_store_n(&hdr->head, hdr->head + 1, __ATOMIC_RELAXED);

    if (last) {
        queue_set_arena(hdr, 0, 0);
    } else if (hdr->arena_used <= skip) {
        __atomic_store_n(&hdr->arena_used, 0, __ATOMIC_RELEASE);
    } else {
        __atomic_store_n(&hdr->arena_used, hdr->arena_used - skip, __ATOMIC_RELEASE);
    }

    __atomic_add_fetch(&hdr->stat_pop_ok, 1, __ATOMIC_RELAXED);
    return 1;
}

/* Under the mutex; 0 when empty. */
static inline uint32_t queue_str_front_len(QueueHandle *h) {
    QueueHeader *hdr = h->hdr;
    if (hdr->tail == hdr->head) return 0;
    return ((QueueStrSlot *)h->slots)[hdr->head & h->cap_mask].packed_len & QUEUE_STR_LEN_MASK;
}

static inline int queue_str_try_pop(QueueHandle *h, const char **out_str,
                                     uint32_t *out_len, bool *out_utf8) {
    if (!queue_str_lock(h)) return QUEUE_FAILED;
    int r = queue_str_pop_locked(h, out_str, out_len, out_utf8);
    uint32_t wake = r == 1 ? queue_str_producer_wake_count(h->hdr, 1) : 0;
    queue_mutex_unlock(h->hdr);
    if (wake) queue_wake_producers_n(h->hdr, wake);
    return r;
}

static inline uint64_t queue_str_size(QueueHandle *h) {
    QueueHeader *hdr = h->hdr;
    uint64_t tail = __atomic_load_n(&hdr->tail, __ATOMIC_RELAXED);
    uint64_t head = __atomic_load_n(&hdr->head, __ATOMIC_RELAXED);
    uint64_t diff = tail - head;
    if ((int64_t)diff < 0) return 0;
    return diff > h->capacity ? h->capacity : diff;
}

static int queue_str_clear(QueueHandle *h) {
    QueueHeader *hdr = h->hdr;
    if (!queue_str_lock(h)) return QUEUE_FAILED;
    /* One store empties it: zeroing head and tail apart would leave tail-head garbage. */
    __atomic_store_n(&hdr->head, hdr->tail, __ATOMIC_RELAXED);
    queue_set_arena(hdr, 0, 0);
    queue_mutex_unlock(hdr);
    /* clear is a bulk transition -- wake every blocked producer and
     * consumer so they re-evaluate state, not just one of each. */
    if (__atomic_load_n(&hdr->push_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->push_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->push_futex, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
    if (__atomic_load_n(&hdr->pop_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->pop_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->pop_futex, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
    return 1;
}

/* Peek: read front element without consuming (exact, under mutex). */
static inline int queue_str_peek(QueueHandle *h, const char **out_str,
                                  uint32_t *out_len, bool *out_utf8) {
    QueueHeader *hdr = h->hdr;
    if (!queue_str_lock(h)) return QUEUE_FAILED;
    if (hdr->tail == hdr->head) {
        queue_mutex_unlock(hdr);
        return 0;
    }
    uint32_t idx = (uint32_t)(hdr->head & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];
    uint32_t off = slot->arena_off;
    uint32_t len = slot->packed_len & QUEUE_STR_LEN_MASK;
    if ((uint64_t)off + len > h->arena_cap) len = 0;
    *out_utf8 = (slot->packed_len & QUEUE_STR_UTF8_FLAG) != 0;
    if (!queue_ensure_copy_buf(h, len + 1)) {
        queue_mutex_unlock(hdr);
        return -1;
    }
    if (len > 0)
        memcpy(h->copy_buf, h->arena + off, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;
    queue_mutex_unlock(hdr);
    return 1;
}

/* Push to front of queue (requeue). Str only -- Int is strictly FIFO. */
static inline int queue_str_push_front(QueueHandle *h, const char *str,
                                        uint32_t len, bool utf8) {
    QueueHeader *hdr = h->hdr;
    if (!queue_str_lock(h)) return QUEUE_FAILED;

    if (len > QUEUE_STR_LEN_MASK) {
        queue_mutex_unlock(hdr);
        return -2;
    }

    uint64_t size = hdr->tail - hdr->head;
    if (size >= h->capacity) {
        __atomic_add_fetch(&hdr->stat_push_full, 1, __ATOMIC_RELAXED);
        queue_mutex_unlock(hdr);
        return 0;
    }

    uint32_t alloc = (len + 7) & ~7u;
    if (alloc == 0) alloc = 8;
    if (alloc > h->arena_cap) {
        queue_mutex_unlock(hdr);
        return -2;
    }

    /* Allocate at the READ end of the circular arena, growing BACKWARD, so
     * the new element sits just before the current front in ring order. The
     * arena is thus always laid out in queue order (front..back is a single
     * contiguous ring region), which the free accounting relies on. The
     * invariant arena_wpos == (read_frontier + arena_used) mod arena_cap is
     * preserved by every op, so pop_back can just retreat arena_wpos by the
     * slot's skip. */
    uint32_t cap = (uint32_t)h->arena_cap;
    if (cap == 0) { queue_mutex_unlock(hdr); return 0; }
    uint32_t pos, skip;
    int empty = hdr->tail == hdr->head;

    if (empty) {
        /* Empty: the element is both front and back. Place it at the arena
         * start, resetting the ring (also defragments a drained arena). */
        pos  = 0;
        skip = alloc;
    } else {
        uint32_t rpos = (uint32_t)(((uint64_t)hdr->arena_wpos
                          + cap - (hdr->arena_used % cap)) % cap);
        if (alloc <= rpos) {
            pos  = rpos - alloc;   /* fits contiguously below the front */
            skip = alloc;
        } else {
            pos  = cap - alloc;    /* wrap: place at the top of the arena, */
            skip = alloc + rpos;   /* wasting the [0, rpos) bytes below it  */
        }
        if ((uint64_t)hdr->arena_used + skip > cap) {
            queue_str_arena_blocked(h);
            __atomic_add_fetch(&hdr->stat_push_full, 1, __ATOMIC_RELAXED);
            queue_mutex_unlock(hdr);
            return 0;
        }
    }
    if (!queue_arena_populate(h, pos, pos + alloc)) {
        queue_mutex_unlock(hdr);
        return QUEUE_FAILED;
    }
    if (empty) {
        queue_set_arena(hdr, alloc, alloc);
    } else {
        hdr->arena_used += skip;   /* arena_wpos unchanged: rpos moved down */
    }

    memcpy(h->arena + pos, str, len);

    uint32_t idx = (uint32_t)((hdr->head - 1) & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];
    slot->arena_off  = pos;
    slot->packed_len = len | (utf8 ? QUEUE_STR_UTF8_FLAG : 0);
    slot->arena_skip = skip;
    slot->prev_wpos  = hdr->arena_wpos;   /* retained for layout stability */
    __atomic_store_n(&hdr->head, hdr->head - 1, __ATOMIC_RELEASE);

    __atomic_add_fetch(&hdr->stat_push_ok, 1, __ATOMIC_RELAXED);
    queue_mutex_unlock(hdr);
    queue_wake_consumers(hdr);
    return 1;
}

/* Pop from back (tail). Str only -- undoes the most recent push. */
static inline int queue_str_pop_back(QueueHandle *h, const char **out_str,
                                      uint32_t *out_len, bool *out_utf8) {
    QueueHeader *hdr = h->hdr;
    if (!queue_str_lock(h)) return QUEUE_FAILED;

    if (hdr->tail == hdr->head) {
        __atomic_add_fetch(&hdr->stat_pop_empty, 1, __ATOMIC_RELAXED);
        queue_mutex_unlock(hdr);
        return 0;
    }

    /* Unpublish before the release store that credits the arena bytes back. */
    __atomic_store_n(&hdr->tail, hdr->tail - 1, __ATOMIC_RELAXED);
    uint32_t idx = (uint32_t)(hdr->tail & h->cap_mask);
    QueueStrSlot *slot = &((QueueStrSlot *)h->slots)[idx];

    uint32_t off = slot->arena_off;
    uint32_t len = slot->packed_len & QUEUE_STR_LEN_MASK;
    if ((uint64_t)off + len > h->arena_cap) len = 0;
    *out_utf8 = (slot->packed_len & QUEUE_STR_UTF8_FLAG) != 0;

    if (!queue_ensure_copy_buf(h, len + 1)) {
        __atomic_store_n(&hdr->tail, hdr->tail + 1, __ATOMIC_RELAXED); /* rollback */
        queue_mutex_unlock(hdr);
        return -1;
    }
    if (len > 0)
        memcpy(h->copy_buf, h->arena + off, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;

    /* Retreat the write frontier past this (back) element. The arena is kept
     * in queue order with arena_wpos == (read_frontier + arena_used) mod cap,
     * and pop_back does not move the front, so the new write frontier is just
     * the old one minus this slot's skip (its span plus any wrap waste). This
     * holds whether the element was appended (push) or prepended
     * (push_front). */
    if (hdr->tail == hdr->head) {
        queue_set_arena(hdr, 0, 0);
    } else if (hdr->arena_used <= slot->arena_skip || h->arena_cap == 0) {
        __atomic_store_n(&hdr->arena_used, 0, __ATOMIC_RELEASE);
    } else {
        queue_set_arena(hdr, (uint32_t)(((uint64_t)hdr->arena_wpos
                          + h->arena_cap - (slot->arena_skip % h->arena_cap)) % h->arena_cap),
                          hdr->arena_used - slot->arena_skip);
    }

    __atomic_add_fetch(&hdr->stat_pop_ok, 1, __ATOMIC_RELAXED);
    uint32_t wake = queue_str_producer_wake_count(hdr, 1);
    queue_mutex_unlock(hdr);
    if (wake) queue_wake_producers_n(hdr, wake);
    return 1;
}

/* In for a push, out for a pop. */
typedef struct { const char *str; uint32_t len; bool utf8; } QueueStrVal;
typedef int (*queue_str_op)(QueueHandle *, QueueStrVal *);

static int queue_str_op_push(QueueHandle *h, QueueStrVal *v) { return queue_str_try_push(h, v->str, v->len, v->utf8); }
static int queue_str_op_push_front(QueueHandle *h, QueueStrVal *v) { return queue_str_push_front(h, v->str, v->len, v->utf8); }
static int queue_str_op_pop(QueueHandle *h, QueueStrVal *v) { return queue_str_try_pop(h, &v->str, &v->len, &v->utf8); }
static int queue_str_op_pop_back(QueueHandle *h, QueueStrVal *v) { return queue_str_pop_back(h, &v->str, &v->len, &v->utf8); }

/* Retries op until it is done or fails, or timeout (seconds, < 0 for none) runs out. */
static int queue_str_wait(QueueHandle *h, queue_str_op op, QueueStrVal *v, int producer, double timeout) {
    int r = op(h, v);
    if (r != 0 || timeout == 0) return r;
    QueueHeader *hdr = h->hdr;
    uint32_t *waiters = producer ? &hdr->push_waiters : &hdr->pop_waiters;
    uint32_t *futex = producer ? &hdr->push_futex : &hdr->pop_futex;
    struct timespec deadline, remaining;
    int has_deadline = timeout > 0;
    if (has_deadline) queue_make_deadline(timeout, &deadline);
    for (;;) {
        /* Announce before sampling seq, so a peer that changes the queue in between wakes us. */
        __atomic_add_fetch(waiters, 1, __ATOMIC_RELEASE);
        uint32_t seq = __atomic_load_n(futex, __ATOMIC_ACQUIRE);
        r = op(h, v);
        if (r != 0) {
            __atomic_sub_fetch(waiters, 1, __ATOMIC_RELEASE);
            break;
        }
        /* Periodic retries also recover a peer killed before its wakeup. */
        const struct timespec *pts = &queue_recheck;
        if (has_deadline) {
            if (!queue_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            if (remaining.tv_sec < QUEUE_RECHECK_SEC) pts = &remaining;
        }
        long rc = syscall(SYS_futex, futex, FUTEX_WAIT, seq, pts, NULL, 0);
        __atomic_sub_fetch(waiters, 1, __ATOMIC_RELEASE);
        r = op(h, v);
        if (r != 0) break;
        if (has_deadline && rc == -1 && errno == ETIMEDOUT
            && !queue_remaining_time(&deadline, &remaining)) return 0;
    }
    if (r == QUEUE_FAILED) {   /* pass on a wake we may have taken */
        if (producer) queue_wake_producers(hdr);
        else queue_wake_consumers(hdr);
    }
    return r;
}

static int queue_str_push_wait(QueueHandle *h, const char *str, uint32_t len, bool utf8, double timeout) {
    QueueStrVal v = { str, len, utf8 };
    return queue_str_wait(h, queue_str_op_push, &v, 1, timeout);
}

static int queue_str_push_front_wait(QueueHandle *h, const char *str, uint32_t len, bool utf8, double timeout) {
    QueueStrVal v = { str, len, utf8 };
    return queue_str_wait(h, queue_str_op_push_front, &v, 1, timeout);
}

static int queue_str_pop_wait_with(QueueHandle *h, queue_str_op op, const char **out_str,
                                   uint32_t *out_len, bool *out_utf8, double timeout) {
    QueueStrVal v;
    int r = queue_str_wait(h, op, &v, 0, timeout);
    if (r == 1) { *out_str = v.str; *out_len = v.len; *out_utf8 = v.utf8; }
    return r;
}

static int queue_str_pop_wait(QueueHandle *h, const char **out_str, uint32_t *out_len, bool *out_utf8, double timeout) {
    return queue_str_pop_wait_with(h, queue_str_op_pop, out_str, out_len, out_utf8, timeout);
}

static int queue_str_pop_back_wait(QueueHandle *h, const char **out_str, uint32_t *out_len, bool *out_utf8, double timeout) {
    return queue_str_pop_wait_with(h, queue_str_op_pop_back, out_str, out_len, out_utf8, timeout);
}

/* msync -- flush mapped pages to disk */
static inline int queue_sync(QueueHandle *h) {
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * eventfd -- event-loop integration
 * ================================================================ */

static inline int queue_eventfd_create(QueueHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    h->notify_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (h->notify_fd >= 0) h->notify_fd_owned = 1;
    return h->notify_fd;
}

/* Replace the current notify fd. Closes the old fd ONLY if we created
 * it ourselves via queue_eventfd_create -- caller-supplied fds remain
 * the caller's property. */
static inline void queue_eventfd_set(QueueHandle *h, int fd) {
    if (h->notify_fd == fd) return;
    if (h->notify_fd >= 0 && h->notify_fd != fd && h->notify_fd_owned)
        close(h->notify_fd);
    h->notify_fd = fd;
    h->notify_fd_owned = 0;
}

/* Signal that data is available. Called after successful push. */
static inline void queue_notify(QueueHandle *h) {
    if (h->notify_fd >= 0) {
        uint64_t one = 1;
        ssize_t __attribute__((unused)) rc = write(h->notify_fd, &one, sizeof(one));
    }
}

/* Consume notification counter. Call from event-loop callback before pop.
 * Returns the accumulated counter, or -1 on error / no eventfd. */
static inline int64_t queue_eventfd_consume(QueueHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t val = 0;
    if (read(h->notify_fd, &val, sizeof(val)) != sizeof(val)) return -1;
    return (int64_t)val;
}

#endif /* QUEUE_H */
