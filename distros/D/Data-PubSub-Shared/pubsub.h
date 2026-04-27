/*
 * pubsub.h -- Shared-memory broadcast pub/sub for Linux
 *
 * Two variants:
 *   Int -- lock-free MPMC publish, lock-free subscribe (int64 values)
 *   Str -- mutex-protected publish, lock-free subscribe (variable-length
 *          byte strings up to msg_size, stored in a circular arena)
 *
 * Ring buffer broadcast: publishers write, each subscriber independently
 * reads with its own cursor. Messages are never consumed -- the ring
 * overwrites old data when it wraps. Subscribers auto-recover from
 * overflow by resetting to the oldest available position.
 *
 * File-backed mmap(MAP_SHARED) for cross-process sharing,
 * futex for blocking poll, PID-based stale lock recovery (Str mode).
 */

#ifndef PUBSUB_H
#define PUBSUB_H

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

#define PUBSUB_MAGIC             0x50534231U  /* "PSB1" */
#define PUBSUB_VERSION           1
#define PUBSUB_MODE_INT          0
#define PUBSUB_MODE_STR          1
#define PUBSUB_MODE_INT32        2
#define PUBSUB_MODE_INT16        3
#define PUBSUB_ERR_BUFLEN        256
#define PUBSUB_SPIN_LIMIT        32
#define PUBSUB_LOCK_TIMEOUT_SEC  2
#define PUBSUB_DEFAULT_MSG_SIZE  256
#define PUBSUB_STR_UTF8_FLAG     0x80000000U
#define PUBSUB_STR_LEN_MASK      0x7FFFFFFFU
#define PUBSUB_POLL_RETRIES      8

/* ================================================================
 * Header (256 bytes = 4 cache lines)
 * ================================================================ */

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;          /* 0 */
    uint32_t version;        /* 4 */
    uint32_t mode;           /* 8 */
    uint32_t capacity;       /* 12 */
    uint64_t total_size;     /* 16 */
    uint64_t slots_off;      /* 24 */
    uint64_t data_off;       /* 32: str: offset to arena; int: 0 */
    uint32_t msg_size;       /* 40: str: max bytes per message; int: 0 */
    uint32_t _reserved0;     /* 44 */
    uint64_t arena_cap;      /* 48: str: arena byte capacity; int: 0 */
    uint8_t  _pad0[8];       /* 56-63 */

    /* ---- Cache line 1 (64-127): writer hot ---- */
    uint64_t write_pos;      /* 64 */
    uint32_t mutex;          /* 72: str: futex mutex */
    uint32_t mutex_waiters;  /* 76 */
    uint32_t arena_wpos;     /* 80: str: next write position in arena */
    uint8_t  _pad1[44];      /* 84-127 */

    /* ---- Cache line 2 (128-191): subscriber notification ---- */
    uint32_t sub_futex;      /* 128 */
    uint32_t sub_waiters;    /* 132 */
    uint8_t  _pad2[56];      /* 136-191 */

    /* ---- Cache line 3 (192-255): stats ---- */
    uint64_t stat_publish_ok;  /* 192 */
    uint64_t stat_recoveries;  /* 200 */
    uint8_t  _pad3[48];        /* 208-255 */
} PubSubHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(PubSubHeader) == 256, "PubSubHeader must be 256 bytes");
#endif

/* ================================================================
 * Slot types
 * ================================================================ */

typedef struct {
    uint64_t sequence;
    int64_t  value;
} PubSubIntSlot;  /* 16 bytes */

/* Compact int slots: 32-bit sequence + value = 8 bytes (2x cache density) */
typedef struct {
    uint32_t sequence;
    int32_t  value;
} PubSubInt32Slot;  /* 8 bytes */

typedef struct {
    uint32_t sequence;
    int16_t  value;
    int16_t  _pad;
} PubSubInt16Slot;  /* 8 bytes */

typedef struct {
    uint64_t sequence;
    uint32_t packed_len;  /* bit 31 = UTF-8, bits 0-30 = byte length */
    uint32_t arena_off;   /* offset into data arena */
} PubSubStrSlot;  /* 16 bytes */

/* ================================================================
 * Process-local handles
 * ================================================================ */

typedef struct {
    PubSubHeader *hdr;
    void         *slots;
    char         *data;       /* NULL for int mode */
    size_t        mmap_size;
    uint32_t      capacity;
    uint32_t      cap_mask;
    uint32_t      msg_size;
    uint64_t      arena_cap;
    char         *path;
    int           notify_fd;
    int           backing_fd;
} PubSubHandle;

typedef struct {
    PubSubHeader *hdr;
    void         *slots;
    char         *data;
    uint64_t      cursor;
    uint32_t      capacity;
    uint32_t      cap_mask;
    uint32_t      msg_size;
    char         *copy_buf;
    uint32_t      copy_buf_cap;
    uint64_t      overflow_count;
    int           notify_fd;
    void         *userdata;
} PubSubSub;

/* ================================================================
 * Utility
 * ================================================================ */

static inline uint32_t pubsub_next_pow2(uint32_t v) {
    if (v < 2) return 2;
    if (v > 0x80000000U) return 0;
    v--;
    v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
    return v + 1;
}

static inline void pubsub_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

static inline int pubsub_ensure_copy_buf(PubSubSub *sub, uint32_t needed) {
    if (needed <= sub->copy_buf_cap) return 1;
    uint32_t ns = sub->copy_buf_cap ? sub->copy_buf_cap : 64;
    while (ns < needed) {
        uint32_t n2 = ns * 2;
        if (n2 <= ns) { ns = needed; break; }
        ns = n2;
    }
    char *nb = (char *)realloc(sub->copy_buf, ns);
    if (!nb) return 0;
    sub->copy_buf = nb;
    sub->copy_buf_cap = ns;
    return 1;
}

/* ================================================================
 * Futex helpers
 * ================================================================ */

#define PUBSUB_MUTEX_WRITER_BIT 0x80000000U
#define PUBSUB_MUTEX_PID_MASK   0x7FFFFFFFU
#define PUBSUB_MUTEX_VAL(pid)   (PUBSUB_MUTEX_WRITER_BIT | ((uint32_t)(pid) & PUBSUB_MUTEX_PID_MASK))

static inline int pubsub_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

static const struct timespec pubsub_lock_timeout = { PUBSUB_LOCK_TIMEOUT_SEC, 0 };

static inline void pubsub_recover_stale_mutex(PubSubHeader *hdr, uint32_t observed) {
    if (!__atomic_compare_exchange_n(&hdr->mutex, &observed, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

static inline void pubsub_mutex_lock(PubSubHeader *hdr) {
    uint32_t mypid = PUBSUB_MUTEX_VAL((uint32_t)getpid());
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < PUBSUB_SPIN_LIMIT, 1)) {
            pubsub_spin_pause();
            continue;
        }
        __atomic_add_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->mutex, FUTEX_WAIT, cur,
                              &pubsub_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
                if (val >= PUBSUB_MUTEX_WRITER_BIT) {
                    uint32_t pid = val & PUBSUB_MUTEX_PID_MASK;
                    if (!pubsub_pid_alive(pid))
                        pubsub_recover_stale_mutex(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void pubsub_mutex_unlock(PubSubHeader *hdr) {
    __atomic_store_n(&hdr->mutex, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

static inline void pubsub_wake_subscribers(PubSubHeader *hdr) {
    if (__atomic_load_n(&hdr->sub_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->sub_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->sub_futex, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
    }
}

static inline int pubsub_remaining_time(const struct timespec *deadline,
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

static inline void pubsub_make_deadline(double timeout, struct timespec *deadline) {
    clock_gettime(CLOCK_MONOTONIC, deadline);
    deadline->tv_sec += (time_t)timeout;
    deadline->tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1e9);
    if (deadline->tv_nsec >= 1000000000L) {
        deadline->tv_sec++;
        deadline->tv_nsec -= 1000000000L;
    }
}

/* ================================================================
 * Header validation
 * ================================================================ */

static inline int pubsub_validate_header(PubSubHeader *hdr, uint32_t mode,
                                          uint64_t file_size) {
    if (hdr->magic != PUBSUB_MAGIC ||
        hdr->version != PUBSUB_VERSION ||
        hdr->mode != mode ||
        hdr->capacity == 0 ||
        (hdr->capacity & (hdr->capacity - 1)) != 0 ||
        hdr->total_size != file_size ||
        hdr->slots_off != sizeof(PubSubHeader))
        return 0;
    /* Slot array must fit within file. */
    uint64_t slot_size = (mode == PUBSUB_MODE_INT)   ? sizeof(PubSubIntSlot)
                       : (mode == PUBSUB_MODE_INT32) ? sizeof(PubSubInt32Slot)
                       : (mode == PUBSUB_MODE_INT16) ? sizeof(PubSubInt16Slot)
                       :                               sizeof(PubSubStrSlot);
    if (hdr->capacity > (hdr->total_size - hdr->slots_off) / slot_size)
        return 0;
    if (mode == PUBSUB_MODE_STR) {
        if (hdr->data_off == 0 || hdr->msg_size == 0 || hdr->arena_cap == 0)
            return 0;
        uint64_t slots_end = hdr->slots_off + (uint64_t)hdr->capacity * slot_size;
        if (hdr->data_off < slots_end ||
            hdr->data_off + hdr->arena_cap > hdr->total_size)
            return 0;
    }
    return 1;
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define PUBSUB_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, PUBSUB_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static PubSubHandle *pubsub_init_handle(void *base, size_t map_size,
                                         uint32_t mode, const char *path) {
    PubSubHeader *hdr = (PubSubHeader *)base;
    PubSubHandle *h = (PubSubHandle *)calloc(1, sizeof(PubSubHandle));
    if (!h) return NULL;

    h->hdr        = hdr;
    h->slots      = (char *)base + hdr->slots_off;
    h->data       = (mode == PUBSUB_MODE_STR) ? (char *)base + hdr->data_off : NULL;
    h->mmap_size  = map_size;
    h->capacity   = hdr->capacity;
    h->cap_mask   = hdr->capacity - 1;
    h->msg_size   = hdr->msg_size;
    h->arena_cap  = hdr->arena_cap;
    h->path       = path ? strdup(path) : NULL;
    h->notify_fd  = -1;
    h->backing_fd = -1;

    return h;
}

static void pubsub_init_header(void *base, uint32_t mode, uint32_t cap,
                                uint64_t total_size, uint64_t slots_off,
                                uint64_t data_off, uint32_t msg_size,
                                uint64_t arena_cap) {
    PubSubHeader *hdr = (PubSubHeader *)base;
    memset(hdr, 0, sizeof(PubSubHeader));
    hdr->magic     = PUBSUB_MAGIC;
    hdr->version   = PUBSUB_VERSION;
    hdr->mode      = mode;
    hdr->capacity  = cap;
    hdr->total_size = total_size;
    hdr->slots_off = slots_off;
    hdr->data_off  = data_off;
    hdr->msg_size  = msg_size;
    hdr->arena_cap = arena_cap;
}

static void pubsub_calc_layout(uint32_t cap, uint32_t mode, uint32_t msg_size,
                                uint64_t *out_slots_off, uint64_t *out_data_off,
                                uint64_t *out_arena_cap, uint64_t *out_total_size) {
    uint64_t slots_off = sizeof(PubSubHeader);
    uint64_t slot_size = (mode == PUBSUB_MODE_INT)   ? sizeof(PubSubIntSlot)
                       : (mode == PUBSUB_MODE_INT32) ? sizeof(PubSubInt32Slot)
                       : (mode == PUBSUB_MODE_INT16) ? sizeof(PubSubInt16Slot)
                       :                               sizeof(PubSubStrSlot);
    uint64_t data_off = 0, arena_cap = 0, total_size;

    if (mode == PUBSUB_MODE_STR) {
        uint64_t slots_end = slots_off + (uint64_t)cap * slot_size;
        data_off = (slots_end + 63) & ~(uint64_t)63;
        arena_cap = (uint64_t)cap * ((uint64_t)msg_size + 8);
        if (arena_cap > UINT32_MAX) arena_cap = UINT32_MAX;
        total_size = data_off + arena_cap;
    } else {
        total_size = slots_off + (uint64_t)cap * slot_size;
    }

    *out_slots_off  = slots_off;
    *out_data_off   = data_off;
    *out_arena_cap  = arena_cap;
    *out_total_size = total_size;
}

static PubSubHandle *pubsub_create(const char *path, uint32_t capacity,
                                    uint32_t mode, uint32_t msg_size,
                                    char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    uint32_t cap = pubsub_next_pow2(capacity);
    if (cap == 0) { PUBSUB_ERR("invalid capacity"); return NULL; }
    if (mode > PUBSUB_MODE_INT16) { PUBSUB_ERR("unknown mode %u", mode); return NULL; }

    if (mode == PUBSUB_MODE_STR && msg_size == 0)
        msg_size = PUBSUB_DEFAULT_MSG_SIZE;

    uint64_t slots_off, data_off, arena_cap, total_size;
    pubsub_calc_layout(cap, mode, msg_size, &slots_off, &data_off, &arena_cap, &total_size);

    int anonymous = (path == NULL);
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) {
            PUBSUB_ERR("mmap(anonymous): %s", strerror(errno));
            return NULL;
        }
        pubsub_init_header(base, mode, cap, total_size, slots_off, data_off,
                            msg_size, arena_cap);
    } else {
        int fd = open(path, O_RDWR | O_CREAT, 0666);
        if (fd < 0) { PUBSUB_ERR("open(%s): %s", path, strerror(errno)); return NULL; }

        if (flock(fd, LOCK_EX) < 0) {
            PUBSUB_ERR("flock(%s): %s", path, strerror(errno));
            close(fd); return NULL;
        }

        struct stat st;
        if (fstat(fd, &st) < 0) {
            PUBSUB_ERR("fstat(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        int is_new = (st.st_size == 0);

        if (!is_new && (uint64_t)st.st_size < sizeof(PubSubHeader)) {
            PUBSUB_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (is_new) {
            if (ftruncate(fd, (off_t)total_size) < 0) {
                PUBSUB_ERR("ftruncate(%s): %s", path, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        map_size = is_new ? (size_t)total_size : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            PUBSUB_ERR("mmap(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (!is_new) {
            if (!pubsub_validate_header((PubSubHeader *)base, mode, (uint64_t)st.st_size)) {
                PUBSUB_ERR("%s: invalid or incompatible pubsub file", path);
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN);
            close(fd);
            return pubsub_init_handle(base, map_size, mode, path);
        }

        pubsub_init_header(base, mode, cap, total_size, slots_off, data_off,
                            msg_size, arena_cap);
        flock(fd, LOCK_UN);
        close(fd);
    }

    PubSubHandle *h = pubsub_init_handle(base, (size_t)total_size, mode, path);
    if (!h) { munmap(base, (size_t)total_size); return NULL; }
    return h;
}

static PubSubHandle *pubsub_create_memfd(const char *name, uint32_t capacity,
                                          uint32_t mode, uint32_t msg_size,
                                          char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    uint32_t cap = pubsub_next_pow2(capacity);
    if (cap == 0) { PUBSUB_ERR("invalid capacity"); return NULL; }
    if (mode > PUBSUB_MODE_INT16) { PUBSUB_ERR("unknown mode %u", mode); return NULL; }

    if (mode == PUBSUB_MODE_STR && msg_size == 0)
        msg_size = PUBSUB_DEFAULT_MSG_SIZE;

    uint64_t slots_off, data_off, arena_cap, total_size;
    pubsub_calc_layout(cap, mode, msg_size, &slots_off, &data_off, &arena_cap, &total_size);

    int fd = memfd_create(name ? name : "pubsub", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { PUBSUB_ERR("memfd_create: %s", strerror(errno)); return NULL; }

    if (ftruncate(fd, (off_t)total_size) < 0) {
        PUBSUB_ERR("ftruncate(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        PUBSUB_ERR("mmap(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    pubsub_init_header(base, mode, cap, total_size, slots_off, data_off,
                        msg_size, arena_cap);

    PubSubHandle *h = pubsub_init_handle(base, (size_t)total_size, mode, NULL);
    if (!h) { munmap(base, (size_t)total_size); close(fd); return NULL; }
    h->backing_fd = fd;
    return h;
}

static PubSubHandle *pubsub_open_fd(int fd, uint32_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    struct stat st;
    if (fstat(fd, &st) < 0) {
        PUBSUB_ERR("fstat(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    if ((uint64_t)st.st_size < sizeof(PubSubHeader)) {
        PUBSUB_ERR("fd %d: too small (%lld)", fd, (long long)st.st_size);
        return NULL;
    }

    size_t map_size = (size_t)st.st_size;
    void *base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        PUBSUB_ERR("mmap(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    if (!pubsub_validate_header((PubSubHeader *)base, mode, (uint64_t)st.st_size)) {
        PUBSUB_ERR("fd %d: invalid or incompatible pubsub", fd);
        munmap(base, map_size);
        return NULL;
    }

    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) {
        PUBSUB_ERR("fcntl(F_DUPFD_CLOEXEC): %s", strerror(errno));
        munmap(base, map_size);
        return NULL;
    }

    PubSubHandle *h = pubsub_init_handle(base, map_size, mode, NULL);
    if (!h) { munmap(base, map_size); close(myfd); return NULL; }
    h->backing_fd = myfd;
    return h;
}

static void pubsub_destroy(PubSubHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->path);
    free(h);
}

/* ================================================================
 * Subscribe
 * ================================================================ */

static PubSubSub *pubsub_subscribe(PubSubHandle *h, int from_oldest) {
    PubSubSub *sub = (PubSubSub *)calloc(1, sizeof(PubSubSub));
    if (!sub) return NULL;

    sub->hdr      = h->hdr;
    sub->slots    = h->slots;
    sub->data     = h->data;
    sub->capacity = h->capacity;
    sub->cap_mask = h->cap_mask;
    sub->msg_size = h->msg_size;

    sub->notify_fd = h->notify_fd;

    uint64_t wp = __atomic_load_n(&h->hdr->write_pos, __ATOMIC_ACQUIRE);
    if (from_oldest && wp > h->capacity)
        sub->cursor = wp - h->capacity;
    else if (from_oldest)
        sub->cursor = 0;
    else
        sub->cursor = wp;

    return sub;
}

static void pubsub_sub_destroy(PubSubSub *sub) {
    if (!sub) return;
    free(sub->copy_buf);
    free(sub);
}

/* ================================================================
 * Common: lag (shared between Int and Str)
 * ================================================================ */

static inline uint64_t pubsub_lag(PubSubSub *sub) {
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
    return (wp > sub->cursor) ? (wp - sub->cursor) : 0;
}

/* ================================================================
 * Int publish/poll macro template
 *
 * DEFINE_INT_PUBSUB(prefix, SlotType, ValType, SeqType, DiffType)
 *   generates: pubsub_<prefix>_publish, _publish_multi, _poll, _poll_wait
 * ================================================================ */

#define DEFINE_INT_PUBSUB(PFX, SLOT, VTYPE, STYPE, DTYPE)                      \
                                                                                \
static inline int pubsub_##PFX##_publish(PubSubHandle *h, VTYPE value) {       \
    PubSubHeader *hdr = h->hdr;                                                \
    SLOT *slots = (SLOT *)h->slots;                                            \
    uint64_t pos = __atomic_fetch_add(&hdr->write_pos, 1, __ATOMIC_RELAXED);   \
    uint32_t idx = pos & h->cap_mask;                                          \
    slots[idx].value = value;                                                  \
    __atomic_store_n(&slots[idx].sequence, (STYPE)(pos + 1), __ATOMIC_RELEASE);\
    __atomic_add_fetch(&hdr->stat_publish_ok, 1, __ATOMIC_RELAXED);            \
    pubsub_wake_subscribers(hdr);                                              \
    return 1;                                                                  \
}                                                                              \
                                                                                \
static inline uint32_t pubsub_##PFX##_publish_multi(PubSubHandle *h,           \
        const VTYPE *values, uint32_t count) {                                 \
    PubSubHeader *hdr = h->hdr;                                                \
    SLOT *slots = (SLOT *)h->slots;                                            \
    uint32_t mask = h->cap_mask;                                               \
    uint64_t pos = __atomic_fetch_add(&hdr->write_pos, count, __ATOMIC_RELAXED);\
    for (uint32_t i = 0; i < count; i++) {                                     \
        uint32_t idx = (pos + i) & mask;                                       \
        slots[idx].value = values[i];                                          \
        __atomic_store_n(&slots[idx].sequence,                                 \
            (STYPE)(pos + i + 1), __ATOMIC_RELEASE);                           \
    }                                                                          \
    __atomic_add_fetch(&hdr->stat_publish_ok, count, __ATOMIC_RELAXED);        \
    pubsub_wake_subscribers(hdr);                                              \
    return count;                                                              \
}                                                                              \
                                                                                \
static inline int pubsub_##PFX##_poll(PubSubSub *sub, VTYPE *value) {          \
    PubSubHeader *hdr = sub->hdr;                                              \
    SLOT *slots = (SLOT *)sub->slots;                                          \
    for (int attempt = 0; attempt < PUBSUB_POLL_RETRIES; attempt++) {          \
        uint64_t cursor = sub->cursor;                                         \
        uint64_t wp = __atomic_load_n(&hdr->write_pos, __ATOMIC_ACQUIRE);      \
        if (cursor >= wp) return 0;                                            \
        if (wp - cursor > sub->capacity) {                                     \
            sub->overflow_count += wp - cursor - sub->capacity;                \
            sub->cursor = wp - sub->capacity;                                  \
            continue;                                                          \
        }                                                                      \
        uint32_t idx = cursor & sub->cap_mask;                                 \
        SLOT *slot = &slots[idx];                                              \
        STYPE seq1 = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);       \
        DTYPE diff = (DTYPE)seq1 - (DTYPE)(STYPE)(cursor + 1);                 \
        if (diff != 0) {                                                       \
            if (diff > 0) {                                                    \
                uint64_t nc = wp > sub->capacity ? wp - sub->capacity : 0;     \
                if (nc > cursor) sub->overflow_count += nc - cursor;           \
                sub->cursor = nc;                                              \
                continue;                                                      \
            }                                                                  \
            return 0;                                                          \
        }                                                                      \
        VTYPE v = slot->value;                                                 \
        STYPE seq2 = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);       \
        if (seq2 != seq1) continue;                                            \
        *value = v;                                                            \
        sub->cursor = cursor + 1;                                              \
        return 1;                                                              \
    }                                                                          \
    return 0;                                                                  \
}                                                                              \
                                                                                \
static int pubsub_##PFX##_poll_wait(PubSubSub *sub, VTYPE *value,              \
                                     double timeout) {                         \
    int r = pubsub_##PFX##_poll(sub, value);                                   \
    if (r != 0) return r;                                                      \
    if (timeout == 0.0) return 0;                                              \
    PubSubHeader *hdr = sub->hdr;                                              \
    struct timespec deadline, remaining;                                        \
    int has_deadline = (timeout > 0);                                          \
    if (has_deadline) pubsub_make_deadline(timeout, &deadline);                 \
    for (;;) {                                                                 \
        uint32_t fseq = __atomic_load_n(&hdr->sub_futex, __ATOMIC_ACQUIRE);    \
        r = pubsub_##PFX##_poll(sub, value);                                   \
        if (r != 0) return r;                                                  \
        __atomic_add_fetch(&hdr->sub_waiters, 1, __ATOMIC_RELEASE);            \
        struct timespec *pts = NULL;                                           \
        if (has_deadline) {                                                     \
            if (!pubsub_remaining_time(&deadline, &remaining)) {               \
                __atomic_sub_fetch(&hdr->sub_waiters, 1, __ATOMIC_RELEASE);    \
                return 0;                                                      \
            }                                                                  \
            pts = &remaining;                                                  \
        }                                                                      \
        long rc = syscall(SYS_futex, &hdr->sub_futex, FUTEX_WAIT,             \
                          fseq, pts, NULL, 0);                                 \
        __atomic_sub_fetch(&hdr->sub_waiters, 1, __ATOMIC_RELEASE);            \
        r = pubsub_##PFX##_poll(sub, value);                                   \
        if (r != 0) return r;                                                  \
        if (rc == -1 && errno == ETIMEDOUT) return 0;                          \
    }                                                                          \
}

/* Instantiate for Int (64-bit seq + 64-bit value = 16 bytes/slot) */
DEFINE_INT_PUBSUB(int, PubSubIntSlot, int64_t, uint64_t, int64_t)

/* Instantiate for Int32 (32-bit seq + 32-bit value = 8 bytes/slot) */
DEFINE_INT_PUBSUB(int32, PubSubInt32Slot, int32_t, uint32_t, int32_t)

/* Instantiate for Int16 (32-bit seq + 16-bit value = 8 bytes/slot) */
DEFINE_INT_PUBSUB(int16, PubSubInt16Slot, int16_t, uint32_t, int32_t)

/* ================================================================
 * Str: mutex-protected publish, lock-free subscribe
 *
 * Variable-length messages stored in a circular arena. Each slot
 * records the arena offset; the seqlock (sequence double-check)
 * guarantees readers see consistent data.
 * ================================================================ */

/* Publish one Str message while mutex is already held (no lock/wake). */
static inline int pubsub_str_publish_locked(PubSubHandle *h, const char *str,
                                             uint32_t len, bool utf8) {
    if (len > PUBSUB_STR_LEN_MASK) return -1;
    if (len > h->msg_size) return -1;

    PubSubHeader *hdr = h->hdr;
    PubSubStrSlot *slots = (PubSubStrSlot *)h->slots;

    uint64_t pos = __atomic_load_n(&hdr->write_pos, __ATOMIC_RELAXED);
    uint32_t idx = pos & h->cap_mask;
    PubSubStrSlot *slot = &slots[idx];

    __atomic_store_n(&slot->sequence, 0, __ATOMIC_RELAXED);
    __atomic_thread_fence(__ATOMIC_RELEASE);

    uint32_t alloc = (len + 7) & ~7u;
    if (alloc == 0) alloc = 8;
    if (alloc > h->arena_cap) return -1;
    uint32_t apos = __atomic_load_n(&hdr->arena_wpos, __ATOMIC_RELAXED);
    if ((uint64_t)apos + alloc > h->arena_cap)
        apos = 0;

    memcpy(h->data + apos, str, len);

    slot->arena_off = apos;
    slot->packed_len = len | (utf8 ? PUBSUB_STR_UTF8_FLAG : 0);

    __atomic_store_n(&hdr->arena_wpos, apos + alloc, __ATOMIC_RELAXED);

    __atomic_store_n(&slot->sequence, pos + 1, __ATOMIC_RELEASE);
    __atomic_store_n(&hdr->write_pos, pos + 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&hdr->stat_publish_ok, 1, __ATOMIC_RELAXED);

    return 1;
}

static inline int pubsub_str_publish(PubSubHandle *h, const char *str,
                                      uint32_t len, bool utf8) {
    if (len > h->msg_size) return -1;
    pubsub_mutex_lock(h->hdr);
    int r = pubsub_str_publish_locked(h, str, len, utf8);
    pubsub_mutex_unlock(h->hdr);
    if (r == 1) pubsub_wake_subscribers(h->hdr);
    return r;
}

/* Returns: 1 = success, 0 = empty/not-ready */
static inline int pubsub_str_poll(PubSubSub *sub, const char **out_str,
                                   uint32_t *out_len, bool *out_utf8) {
    PubSubHeader *hdr = sub->hdr;
    PubSubStrSlot *slots = (PubSubStrSlot *)sub->slots;

    for (int attempt = 0; attempt < PUBSUB_POLL_RETRIES; attempt++) {
        uint64_t cursor = sub->cursor;
        uint64_t wp = __atomic_load_n(&hdr->write_pos, __ATOMIC_ACQUIRE);

        if (cursor >= wp) return 0;

        if (wp - cursor > sub->capacity) {
            sub->overflow_count += wp - cursor - sub->capacity;
            sub->cursor = wp - sub->capacity;
            continue;
        }

        uint32_t idx = cursor & sub->cap_mask;
        PubSubStrSlot *slot = &slots[idx];

        uint64_t seq1 = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);
        if (seq1 != cursor + 1) {
            if (seq1 > cursor + 1) {
                uint64_t new_cursor = wp > sub->capacity ? wp - sub->capacity : 0;
                if (new_cursor > cursor)
                    sub->overflow_count += new_cursor - cursor;
                sub->cursor = new_cursor;
                continue;
            }
            return 0;
        }

        uint32_t plen = slot->packed_len;
        uint32_t aoff = slot->arena_off;
        uint32_t len = plen & PUBSUB_STR_LEN_MASK;
        bool utf8 = (plen & PUBSUB_STR_UTF8_FLAG) != 0;

        /* Safety: if metadata looks corrupted, retry */
        if (len > sub->msg_size) continue;
        if ((uint64_t)aoff + len > sub->hdr->arena_cap) continue;

        if (!pubsub_ensure_copy_buf(sub, len + 1)) return 0;

        if (len > 0)
            memcpy(sub->copy_buf, sub->data + aoff, len);
        sub->copy_buf[len] = '\0';

        uint64_t seq2 = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);
        if (seq2 != seq1) continue;

        *out_str = sub->copy_buf;
        *out_len = len;
        *out_utf8 = utf8;
        sub->cursor = cursor + 1;
        return 1;
    }
    return 0;
}

static int pubsub_str_poll_wait(PubSubSub *sub, const char **out_str,
                                 uint32_t *out_len, bool *out_utf8,
                                 double timeout) {
    int r = pubsub_str_poll(sub, out_str, out_len, out_utf8);
    if (r != 0) return r;
    if (timeout == 0.0) return 0;

    PubSubHeader *hdr = sub->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) pubsub_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t fseq = __atomic_load_n(&hdr->sub_futex, __ATOMIC_ACQUIRE);
        r = pubsub_str_poll(sub, out_str, out_len, out_utf8);
        if (r != 0) return r;

        __atomic_add_fetch(&hdr->sub_waiters, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!pubsub_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->sub_waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, &hdr->sub_futex, FUTEX_WAIT,
                          fseq, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->sub_waiters, 1, __ATOMIC_RELEASE);

        r = pubsub_str_poll(sub, out_str, out_len, out_utf8);
        if (r != 0) return r;
        if (rc == -1 && errno == ETIMEDOUT) return 0;
    }
}

/* ================================================================
 * Common operations
 * ================================================================ */

static void pubsub_clear(PubSubHandle *h) {
    PubSubHeader *hdr = h->hdr;
    if (hdr->mode == PUBSUB_MODE_STR)
        pubsub_mutex_lock(hdr);

    __atomic_store_n(&hdr->write_pos, 0, __ATOMIC_RELAXED);
    __atomic_store_n(&hdr->stat_publish_ok, 0, __ATOMIC_RELAXED);
    if (hdr->mode == PUBSUB_MODE_STR)
        __atomic_store_n(&hdr->arena_wpos, 0, __ATOMIC_RELAXED);

    /* Zero all slot sequences */
    uint32_t cap = h->capacity;
    if (hdr->mode == PUBSUB_MODE_INT) {
        PubSubIntSlot *s = (PubSubIntSlot *)h->slots;
        for (uint32_t i = 0; i < cap; i++)
            __atomic_store_n(&s[i].sequence, 0, __ATOMIC_RELAXED);
    } else if (hdr->mode == PUBSUB_MODE_INT32) {
        PubSubInt32Slot *s = (PubSubInt32Slot *)h->slots;
        for (uint32_t i = 0; i < cap; i++)
            __atomic_store_n(&s[i].sequence, 0, __ATOMIC_RELAXED);
    } else if (hdr->mode == PUBSUB_MODE_INT16) {
        PubSubInt16Slot *s = (PubSubInt16Slot *)h->slots;
        for (uint32_t i = 0; i < cap; i++)
            __atomic_store_n(&s[i].sequence, 0, __ATOMIC_RELAXED);
    } else {
        PubSubStrSlot *s = (PubSubStrSlot *)h->slots;
        for (uint32_t i = 0; i < cap; i++)
            __atomic_store_n(&s[i].sequence, 0, __ATOMIC_RELAXED);
    }

    if (hdr->mode == PUBSUB_MODE_STR)
        pubsub_mutex_unlock(hdr);
    pubsub_wake_subscribers(hdr);
}

static inline int pubsub_sync(PubSubHandle *h) {
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

static inline int pubsub_eventfd_create(PubSubHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    h->notify_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    return h->notify_fd;
}

static inline void pubsub_eventfd_set(PubSubHandle *h, int fd) {
    if (h->notify_fd >= 0 && h->notify_fd != fd)
        close(h->notify_fd);
    h->notify_fd = fd;
}

static inline void pubsub_notify(PubSubHandle *h) {
    if (h->notify_fd >= 0) {
        uint64_t one = 1;
        ssize_t __attribute__((unused)) rc = write(h->notify_fd, &one, sizeof(one));
    }
}

static inline int64_t pubsub_eventfd_consume(PubSubHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t val = 0;
    if (read(h->notify_fd, &val, sizeof(val)) != sizeof(val)) return -1;
    return (int64_t)val;
}

static inline void pubsub_sub_eventfd_consume(PubSubSub *sub) {
    if (sub->notify_fd >= 0) {
        uint64_t val;
        ssize_t __attribute__((unused)) rc = read(sub->notify_fd, &val, sizeof(val));
    }
}

#endif /* PUBSUB_H */
