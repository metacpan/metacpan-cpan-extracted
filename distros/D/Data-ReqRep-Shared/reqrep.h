/*
 * reqrep.h -- Shared-memory request/response IPC for Linux
 *
 * Request queue (client -> server) with circular arena for variable-length
 * request data, plus per-request response slots for targeted reply delivery.
 *
 * Uses file-backed mmap(MAP_SHARED) for cross-process sharing,
 * futex for blocking wait, and PID-based stale lock recovery.
 */

#ifndef REQREP_H
#define REQREP_H

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

#define REQREP_MAGIC           0x52525331U  /* "RRS1" */
#define REQREP_VERSION         1
#define REQREP_ERR_BUFLEN      256
#define REQREP_SPIN_LIMIT      32
#define REQREP_LOCK_TIMEOUT_SEC 2

#define REQREP_UTF8_FLAG       0x80000000U
#define REQREP_STR_LEN_MASK    0x7FFFFFFFU

#define RESP_FREE              0
#define RESP_ACQUIRED          1
#define RESP_READY             2

#define REQREP_MODE_STR        0
#define REQREP_MODE_INT        1

/* Pack/unpack slot index + generation into a 64-bit request ID.
 * Prevents ABA: cancelled slot re-acquired by another client
 * won't match the generation stored in the original request. */
#define REQREP_MAKE_ID(slot, gen) (((uint64_t)(gen) << 32) | (uint64_t)(slot))
#define REQREP_ID_SLOT(id)  ((uint32_t)((id) & 0xFFFFFFFFULL))
#define REQREP_ID_GEN(id)   ((uint32_t)((id) >> 32))

/* ================================================================
 * Header (256 bytes = 4 cache lines, lives at start of mmap)
 * ================================================================ */

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;           /* 0 */
    uint32_t version;         /* 4 */
    uint32_t mode;            /* 8: REQREP_MODE_STR or REQREP_MODE_INT */
    uint32_t req_cap;         /* 12: request queue capacity (power of 2) */
    uint64_t total_size;      /* 16: mmap size */
    uint32_t req_slots_off;   /* 24: offset to request slot array */
    uint32_t req_arena_off;   /* 28: offset to request arena */
    uint32_t req_arena_cap;   /* 32: arena byte capacity */
    uint32_t resp_slots;      /* 36: number of response slots */
    uint32_t resp_data_max;   /* 40: max response data bytes per slot */
    uint32_t resp_off;        /* 44: offset to response slot area */
    uint32_t resp_stride;     /* 48: bytes per response slot (cache-aligned) */
    uint8_t  _pad0[12];       /* 52-63 */

    /* ---- Cache line 1 (64-127): recv hot (server) ---- */
    uint64_t req_head;        /* 64: consumer position */
    uint32_t recv_waiters;    /* 72: blocked servers */
    uint32_t recv_futex;      /* 76: futex for recv wakeup */
    uint8_t  _pad1[48];       /* 80-127 */

    /* ---- Cache line 2 (128-191): send hot (client) ---- */
    uint64_t req_tail;        /* 128: producer position */
    uint32_t send_waiters;    /* 136: blocked clients */
    uint32_t send_futex;      /* 140: futex for send wakeup */
    uint8_t  _pad2[48];       /* 144-191 */

    /* ---- Cache line 3 (192-255): mutex + arena state + stats ---- */
    uint32_t mutex;           /* 192: futex-based mutex (0 or PID|0x80000000) */
    uint32_t mutex_waiters;   /* 196 */
    uint32_t arena_wpos;      /* 200: arena write position */
    uint32_t arena_used;      /* 204: arena bytes consumed */
    uint32_t resp_hint;       /* 208: hint for slot scan */
    uint32_t stat_recoveries; /* 212 */
    uint32_t slot_futex;      /* 216: futex for slot availability */
    uint32_t slot_waiters;    /* 220: threads waiting for free slot */
    uint64_t stat_requests;   /* 224 */
    uint64_t stat_replies;    /* 232 */
    uint64_t stat_send_full;  /* 240 */
    uint32_t stat_recv_empty; /* 248 */
    uint32_t _pad3;           /* 252-255 */
} ReqRepHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(ReqRepHeader) == 256, "ReqRepHeader must be 256 bytes");
#endif

/* ================================================================
 * Slot types
 * ================================================================ */

typedef struct {
    uint32_t arena_off;
    uint32_t packed_len;   /* bit 31 = UTF-8, bits 0-30 = byte length */
    uint32_t arena_skip;   /* bytes to release from arena on recv */
    uint32_t resp_slot;    /* response slot index */
    uint32_t resp_gen;     /* generation at time of slot acquire (ABA guard) */
    uint32_t _rpad;
} ReqSlot;  /* 24 bytes (Str mode) */

/* Int request slot: Vyukov sequence + value + response routing */
typedef struct {
    uint64_t sequence;
    int64_t  value;
    uint32_t resp_slot;
    uint32_t resp_gen;
} ReqIntSlot;  /* 24 bytes (Int mode, lock-free) */

typedef struct {
    uint32_t state;        /* futex: RESP_FREE=0, RESP_ACQUIRED=1, RESP_READY=2 */
    uint32_t waiters;      /* futex waiters on this slot */
    uint32_t owner_pid;    /* PID of client that acquired (for stale recovery) */
    uint32_t resp_len;     /* response data length */
    uint32_t resp_flags;   /* bit 0 = UTF-8 */
    uint32_t generation;   /* incremented on each acquire (ABA guard) */
    uint32_t _rpad[2];     /* pad to 32 bytes */
} RespSlotHeader;  /* 32 bytes + data */

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(RespSlotHeader) == 32, "RespSlotHeader must be 32 bytes");
#endif

/* ================================================================
 * Process-local handle
 * ================================================================ */

typedef struct {
    ReqRepHeader  *hdr;
    ReqSlot       *req_slots;
    char          *req_arena;
    uint8_t       *resp_area;     /* base of response slots region */
    size_t         mmap_size;
    uint32_t       req_cap;
    uint32_t       req_cap_mask;  /* req_cap - 1 */
    uint32_t       req_arena_cap;
    uint32_t       resp_slots;
    uint32_t       resp_data_max;
    uint32_t       resp_stride;
    char          *copy_buf;
    uint32_t       copy_buf_cap;
    char          *path;
    int            notify_fd;     /* request notification eventfd, -1 if unset */
    int            reply_fd;      /* reply notification eventfd, -1 if unset */
    int            backing_fd;    /* memfd fd, -1 for file-backed/anonymous */
} ReqRepHandle;

/* ================================================================
 * Utility
 * ================================================================ */

static inline uint32_t reqrep_next_pow2(uint32_t v) {
    if (v < 2) return 2;
    if (v > 0x80000000U) return 0;
    v--;
    v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
    return v + 1;
}

static inline void reqrep_spin_pause(void) {
#if defined(__x86_64__) || defined(__i386__)
    __asm__ volatile("pause" ::: "memory");
#elif defined(__aarch64__)
    __asm__ volatile("yield" ::: "memory");
#else
    __asm__ volatile("" ::: "memory");
#endif
}

static inline int reqrep_ensure_copy_buf(ReqRepHandle *h, uint32_t needed) {
    if (needed <= h->copy_buf_cap) return 1;
    uint32_t ns = h->copy_buf_cap ? h->copy_buf_cap : 64;
    while (ns < needed) { uint32_t n2 = ns * 2; if (n2 <= ns) { ns = needed; break; } ns = n2; }
    char *nb = (char *)realloc(h->copy_buf, ns);
    if (!nb) return 0;
    h->copy_buf = nb;
    h->copy_buf_cap = ns;
    return 1;
}

static inline RespSlotHeader *reqrep_resp_slot(ReqRepHandle *h, uint32_t idx) {
    return (RespSlotHeader *)(h->resp_area + (uint64_t)idx * h->resp_stride);
}

/* ================================================================
 * Futex helpers
 * ================================================================ */

#define REQREP_MUTEX_WRITER_BIT 0x80000000U
#define REQREP_MUTEX_PID_MASK   0x7FFFFFFFU
#define REQREP_MUTEX_VAL(pid)   (REQREP_MUTEX_WRITER_BIT | ((uint32_t)(pid) & REQREP_MUTEX_PID_MASK))

static inline int reqrep_pid_alive(uint32_t pid) {
    if (pid == 0) return 1;
    return !(kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

static const struct timespec reqrep_lock_timeout = { REQREP_LOCK_TIMEOUT_SEC, 0 };

static inline void reqrep_recover_stale_mutex(ReqRepHeader *hdr, uint32_t observed) {
    if (!__atomic_compare_exchange_n(&hdr->mutex, &observed, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

static inline void reqrep_mutex_lock(ReqRepHeader *hdr) {
    uint32_t mypid = REQREP_MUTEX_VAL((uint32_t)getpid());
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return;
        if (__builtin_expect(spin < REQREP_SPIN_LIMIT, 1)) {
            reqrep_spin_pause();
            continue;
        }
        __atomic_add_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        uint32_t cur = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
        if (cur != 0) {
            long rc = syscall(SYS_futex, &hdr->mutex, FUTEX_WAIT, cur,
                              &reqrep_lock_timeout, NULL, 0);
            if (rc == -1 && errno == ETIMEDOUT) {
                __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
                uint32_t val = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
                if (val >= REQREP_MUTEX_WRITER_BIT) {
                    uint32_t pid = val & REQREP_MUTEX_PID_MASK;
                    if (!reqrep_pid_alive(pid))
                        reqrep_recover_stale_mutex(hdr, val);
                }
                spin = 0;
                continue;
            }
        }
        __atomic_sub_fetch(&hdr->mutex_waiters, 1, __ATOMIC_RELAXED);
        spin = 0;
    }
}

static inline void reqrep_mutex_unlock(ReqRepHeader *hdr) {
    __atomic_store_n(&hdr->mutex, 0, __ATOMIC_RELEASE);
    if (__atomic_load_n(&hdr->mutex_waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &hdr->mutex, FUTEX_WAKE, 1, NULL, NULL, 0);
}

static inline void reqrep_wake_consumers(ReqRepHeader *hdr) {
    if (__atomic_load_n(&hdr->recv_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->recv_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->recv_futex, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void reqrep_wake_producers(ReqRepHeader *hdr) {
    if (__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->send_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->send_futex, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline void reqrep_wake_slot_waiters(ReqRepHeader *hdr) {
    if (__atomic_load_n(&hdr->slot_waiters, __ATOMIC_RELAXED) > 0) {
        __atomic_add_fetch(&hdr->slot_futex, 1, __ATOMIC_RELEASE);
        syscall(SYS_futex, &hdr->slot_futex, FUTEX_WAKE, 1, NULL, NULL, 0);
    }
}

static inline int reqrep_remaining_time(const struct timespec *deadline,
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

static inline void reqrep_make_deadline(double timeout, struct timespec *deadline) {
    clock_gettime(CLOCK_MONOTONIC, deadline);
    deadline->tv_sec += (time_t)timeout;
    deadline->tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1e9);
    if (deadline->tv_nsec >= 1000000000L) {
        deadline->tv_sec++;
        deadline->tv_nsec -= 1000000000L;
    }
}

/* ================================================================
 * Response slot operations
 * ================================================================ */

static int32_t reqrep_slot_acquire(ReqRepHandle *h) {
    uint32_t n = h->resp_slots;
    uint32_t hint = __atomic_load_n(&h->hdr->resp_hint, __ATOMIC_RELAXED);
    uint32_t mypid = (uint32_t)getpid();

    for (uint32_t i = 0; i < n; i++) {
        uint32_t idx = (hint + i) % n;
        RespSlotHeader *slot = reqrep_resp_slot(h, idx);
        uint32_t expected = RESP_FREE;
        if (__atomic_compare_exchange_n(&slot->state, &expected, RESP_ACQUIRED,
                0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
            __atomic_store_n(&slot->owner_pid, mypid, __ATOMIC_RELAXED);
            __atomic_add_fetch(&slot->generation, 1, __ATOMIC_RELEASE);
            __atomic_store_n(&h->hdr->resp_hint, (idx + 1) % n, __ATOMIC_RELAXED);
            return (int32_t)idx;
        }
    }

    /* Recover stale slots from dead processes (both ACQUIRED and READY) */
    for (uint32_t i = 0; i < n; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
        if (state == RESP_ACQUIRED || state == RESP_READY) {
            uint32_t pid = __atomic_load_n(&slot->owner_pid, __ATOMIC_RELAXED);
            if (pid && !reqrep_pid_alive(pid)) {
                if (__atomic_compare_exchange_n(&slot->state, &state, RESP_FREE,
                        0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                    __atomic_add_fetch(&h->hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
                    uint32_t expected = RESP_FREE;
                    if (__atomic_compare_exchange_n(&slot->state, &expected, RESP_ACQUIRED,
                            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                        __atomic_store_n(&slot->owner_pid, mypid, __ATOMIC_RELAXED);
                        __atomic_add_fetch(&slot->generation, 1, __ATOMIC_RELEASE);
                        return (int32_t)i;
                    }
                    reqrep_wake_slot_waiters(h->hdr);
                }
            }
        }
    }

    return -1;
}

static inline void reqrep_slot_release(ReqRepHandle *h, uint32_t idx) {
    RespSlotHeader *slot = reqrep_resp_slot(h, idx);
    __atomic_store_n(&slot->owner_pid, 0, __ATOMIC_RELAXED);
    __atomic_store_n(&slot->state, RESP_FREE, __ATOMIC_RELEASE);
    reqrep_wake_slot_waiters(h->hdr);
}

/* ================================================================
 * Create / Open / Close
 * ================================================================ */

#define REQREP_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, REQREP_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static ReqRepHandle *reqrep_setup_handle(void *base, size_t map_size,
                                          const char *path, int backing_fd) {
    ReqRepHeader *hdr = (ReqRepHeader *)base;
    ReqRepHandle *h = (ReqRepHandle *)calloc(1, sizeof(ReqRepHandle));
    if (!h) return NULL;

    h->hdr           = hdr;
    h->req_slots     = (ReqSlot *)((char *)base + hdr->req_slots_off);
    h->req_arena     = (char *)base + hdr->req_arena_off;
    h->resp_area     = (uint8_t *)base + hdr->resp_off;
    h->mmap_size     = map_size;
    h->req_cap       = hdr->req_cap;
    h->req_cap_mask  = hdr->req_cap - 1;
    h->req_arena_cap = hdr->req_arena_cap;
    h->resp_slots    = hdr->resp_slots;
    h->resp_data_max = hdr->resp_data_max;
    h->resp_stride   = hdr->resp_stride;
    h->path          = path ? strdup(path) : NULL;
    h->notify_fd     = -1;
    h->reply_fd      = -1;
    h->backing_fd    = backing_fd;

    return h;
}

static int reqrep_validate_header(ReqRepHeader *hdr, size_t file_size, uint32_t expected_mode) {
    if (hdr->magic != REQREP_MAGIC) return 0;
    if (hdr->version != REQREP_VERSION) return 0;
    if (hdr->mode != expected_mode) return 0;
    if (hdr->req_cap == 0 || (hdr->req_cap & (hdr->req_cap - 1)) != 0) return 0;
    if (hdr->total_size != (uint64_t)file_size) return 0;
    if (hdr->req_slots_off != sizeof(ReqRepHeader)) return 0;
    if (hdr->resp_slots == 0) return 0;
    if (hdr->resp_stride < sizeof(RespSlotHeader)) return 0;
    /* Compute end of req slots area; req_arena and resp must come after it. */
    uint64_t req_slot_size = (expected_mode == REQREP_MODE_STR)
                           ? sizeof(ReqSlot) : sizeof(ReqIntSlot);
    uint64_t req_slots_end = (uint64_t)hdr->req_slots_off
                           + (uint64_t)hdr->req_cap * req_slot_size;
    if (req_slots_end > hdr->total_size) return 0;
    if (expected_mode == REQREP_MODE_STR) {
        if (hdr->req_arena_off < req_slots_end) return 0;
        if ((uint64_t)hdr->req_arena_off + hdr->req_arena_cap > hdr->total_size) return 0;
        /* resp must not overlap arena */
        if (hdr->resp_off < (uint64_t)hdr->req_arena_off + hdr->req_arena_cap) return 0;
    }
    if (hdr->resp_off < req_slots_end) return 0;
    if ((uint64_t)hdr->resp_off + (uint64_t)hdr->resp_slots * hdr->resp_stride > hdr->total_size) return 0;
    return 1;
}

static void reqrep_init_header(void *base, uint32_t req_cap, uint32_t resp_slots_n,
                                uint32_t resp_data_max, uint64_t total_size,
                                uint32_t req_slots_off, uint32_t req_arena_off,
                                uint32_t req_arena_cap, uint32_t resp_off,
                                uint32_t resp_stride) {
    ReqRepHeader *hdr = (ReqRepHeader *)base;
    memset(hdr, 0, sizeof(ReqRepHeader));
    hdr->magic         = REQREP_MAGIC;
    hdr->version       = REQREP_VERSION;
    hdr->mode          = REQREP_MODE_STR;
    hdr->req_cap       = req_cap;
    hdr->total_size    = total_size;
    hdr->req_slots_off = req_slots_off;
    hdr->req_arena_off = req_arena_off;
    hdr->req_arena_cap = req_arena_cap;
    hdr->resp_slots    = resp_slots_n;
    hdr->resp_data_max = resp_data_max;
    hdr->resp_off      = resp_off;
    hdr->resp_stride   = resp_stride;

    for (uint32_t i = 0; i < resp_slots_n; i++) {
        RespSlotHeader *rs = (RespSlotHeader *)((uint8_t *)base + resp_off + (uint64_t)i * resp_stride);
        memset(rs, 0, sizeof(RespSlotHeader));
    }

    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* Returns 0 on success, -1 on overflow (offsets would exceed UINT32_MAX). */
static int reqrep_compute_layout(uint32_t req_cap, uint32_t resp_slots_n,
                                  uint32_t resp_data_max, uint64_t arena_hint,
                                  uint32_t *out_req_slots_off, uint32_t *out_req_arena_off,
                                  uint32_t *out_req_arena_cap, uint32_t *out_resp_off,
                                  uint32_t *out_resp_stride, uint64_t *out_total_size) {
    uint32_t req_slots_off = sizeof(ReqRepHeader);
    uint64_t slots_end = (uint64_t)req_slots_off + (uint64_t)req_cap * sizeof(ReqSlot);
    uint64_t req_arena_off_64 = (slots_end + 7) & ~(uint64_t)7;
    if (req_arena_off_64 > UINT32_MAX) return -1;
    uint32_t req_arena_off = (uint32_t)req_arena_off_64;

    if (arena_hint > UINT32_MAX) return -1;
    uint32_t req_arena_cap = (uint32_t)arena_hint;
    if (req_arena_cap < 4096) req_arena_cap = 4096;

    uint32_t resp_stride = (sizeof(RespSlotHeader) + resp_data_max + 63) & ~63u;
    uint64_t resp_off_64 = ((uint64_t)req_arena_off + req_arena_cap + 63) & ~(uint64_t)63;
    if (resp_off_64 > UINT32_MAX) return -1;
    uint64_t total_size = resp_off_64 + (uint64_t)resp_slots_n * resp_stride;

    *out_req_slots_off = req_slots_off;
    *out_req_arena_off = req_arena_off;
    *out_req_arena_cap = req_arena_cap;
    *out_resp_off      = (uint32_t)resp_off_64;
    *out_resp_stride   = resp_stride;
    *out_total_size    = total_size;
    return 0;
}

static ReqRepHandle *reqrep_create(const char *path, uint32_t req_cap,
                                    uint32_t resp_slots_n, uint32_t resp_data_max,
                                    uint64_t arena_hint, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    req_cap = reqrep_next_pow2(req_cap);
    if (req_cap == 0) { REQREP_ERR("invalid req_cap"); return NULL; }
    if (resp_slots_n == 0) { REQREP_ERR("resp_slots must be > 0"); return NULL; }

    if (arena_hint == 0) arena_hint = (uint64_t)req_cap * 256;

    uint32_t req_slots_off, req_arena_off, req_arena_cap, resp_off, resp_stride;
    uint64_t total_size;
    if (reqrep_compute_layout(req_cap, resp_slots_n, resp_data_max, arena_hint,
                               &req_slots_off, &req_arena_off, &req_arena_cap,
                               &resp_off, &resp_stride, &total_size) < 0) {
        REQREP_ERR("layout overflow: req_cap/arena_hint too large for uint32 offsets");
        return NULL;
    }

    int anonymous = (path == NULL);
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) {
            REQREP_ERR("mmap(anonymous): %s", strerror(errno));
            return NULL;
        }
        reqrep_init_header(base, req_cap, resp_slots_n, resp_data_max, total_size,
                            req_slots_off, req_arena_off, req_arena_cap,
                            resp_off, resp_stride);
    } else {
        int fd = open(path, O_RDWR | O_CREAT, 0666);
        if (fd < 0) { REQREP_ERR("open(%s): %s", path, strerror(errno)); return NULL; }

        if (flock(fd, LOCK_EX) < 0) {
            REQREP_ERR("flock(%s): %s", path, strerror(errno));
            close(fd); return NULL;
        }

        struct stat st;
        if (fstat(fd, &st) < 0) {
            REQREP_ERR("fstat(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        int is_new = (st.st_size == 0);

        if (!is_new && (uint64_t)st.st_size < sizeof(ReqRepHeader)) {
            REQREP_ERR("%s: file too small (%lld)", path, (long long)st.st_size);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (is_new) {
            if (ftruncate(fd, (off_t)total_size) < 0) {
                REQREP_ERR("ftruncate(%s): %s", path, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        map_size = is_new ? (size_t)total_size : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            REQREP_ERR("mmap(%s): %s", path, strerror(errno));
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (!is_new) {
            if (!reqrep_validate_header((ReqRepHeader *)base, (size_t)st.st_size, REQREP_MODE_STR)) {
                REQREP_ERR("%s: invalid or incompatible reqrep file", path);
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN);
            close(fd);
            ReqRepHandle *h = reqrep_setup_handle(base, map_size, path, -1);
            if (!h) { munmap(base, map_size); return NULL; }
            return h;
        }

        reqrep_init_header(base, req_cap, resp_slots_n, resp_data_max, total_size,
                            req_slots_off, req_arena_off, req_arena_cap,
                            resp_off, resp_stride);
        flock(fd, LOCK_UN);
        close(fd);
    }

    ReqRepHandle *h = reqrep_setup_handle(base, map_size, path, -1);
    if (!h) { munmap(base, map_size); return NULL; }
    return h;
}

static ReqRepHandle *reqrep_open(const char *path, uint32_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    if (!path) { REQREP_ERR("path required"); return NULL; }

    int fd = open(path, O_RDWR);
    if (fd < 0) { REQREP_ERR("open(%s): %s", path, strerror(errno)); return NULL; }

    if (flock(fd, LOCK_EX) < 0) {
        REQREP_ERR("flock(%s): %s", path, strerror(errno));
        close(fd); return NULL;
    }

    struct stat st;
    if (fstat(fd, &st) < 0) {
        REQREP_ERR("fstat(%s): %s", path, strerror(errno));
        flock(fd, LOCK_UN); close(fd); return NULL;
    }

    if ((uint64_t)st.st_size < sizeof(ReqRepHeader)) {
        REQREP_ERR("%s: file too small or not initialized", path);
        flock(fd, LOCK_UN); close(fd); return NULL;
    }

    size_t map_size = (size_t)st.st_size;
    void *base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        REQREP_ERR("mmap(%s): %s", path, strerror(errno));
        flock(fd, LOCK_UN); close(fd); return NULL;
    }

    if (!reqrep_validate_header((ReqRepHeader *)base, map_size, mode)) {
        REQREP_ERR("%s: invalid or incompatible reqrep file", path);
        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
    }

    flock(fd, LOCK_UN);
    close(fd);

    ReqRepHandle *h = reqrep_setup_handle(base, map_size, path, -1);
    if (!h) { munmap(base, map_size); return NULL; }
    return h;
}

static ReqRepHandle *reqrep_create_memfd(const char *name, uint32_t req_cap,
                                          uint32_t resp_slots_n, uint32_t resp_data_max,
                                          uint64_t arena_hint, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    req_cap = reqrep_next_pow2(req_cap);
    if (req_cap == 0) { REQREP_ERR("invalid req_cap"); return NULL; }
    if (resp_slots_n == 0) { REQREP_ERR("resp_slots must be > 0"); return NULL; }

    if (arena_hint == 0) arena_hint = (uint64_t)req_cap * 256;

    uint32_t req_slots_off, req_arena_off, req_arena_cap, resp_off, resp_stride;
    uint64_t total_size;
    if (reqrep_compute_layout(req_cap, resp_slots_n, resp_data_max, arena_hint,
                               &req_slots_off, &req_arena_off, &req_arena_cap,
                               &resp_off, &resp_stride, &total_size) < 0) {
        REQREP_ERR("layout overflow: req_cap/arena_hint too large for uint32 offsets");
        return NULL;
    }

    int fd = memfd_create(name ? name : "reqrep", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { REQREP_ERR("memfd_create: %s", strerror(errno)); return NULL; }

    if (ftruncate(fd, (off_t)total_size) < 0) {
        REQREP_ERR("ftruncate(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);

    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        REQREP_ERR("mmap(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }

    reqrep_init_header(base, req_cap, resp_slots_n, resp_data_max, total_size,
                        req_slots_off, req_arena_off, req_arena_cap,
                        resp_off, resp_stride);

    ReqRepHandle *h = reqrep_setup_handle(base, (size_t)total_size, NULL, fd);
    if (!h) { munmap(base, (size_t)total_size); close(fd); return NULL; }
    return h;
}

static ReqRepHandle *reqrep_open_fd(int fd, uint32_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';

    struct stat st;
    if (fstat(fd, &st) < 0) {
        REQREP_ERR("fstat(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    if ((uint64_t)st.st_size < sizeof(ReqRepHeader)) {
        REQREP_ERR("fd %d: too small (%lld)", fd, (long long)st.st_size);
        return NULL;
    }

    size_t map_size = (size_t)st.st_size;
    void *base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) {
        REQREP_ERR("mmap(fd=%d): %s", fd, strerror(errno));
        return NULL;
    }

    if (!reqrep_validate_header((ReqRepHeader *)base, map_size, mode)) {
        REQREP_ERR("fd %d: invalid or incompatible reqrep", fd);
        munmap(base, map_size);
        return NULL;
    }

    int myfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (myfd < 0) {
        REQREP_ERR("fcntl(F_DUPFD_CLOEXEC): %s", strerror(errno));
        munmap(base, map_size);
        return NULL;
    }

    ReqRepHandle *h = reqrep_setup_handle(base, map_size, NULL, myfd);
    if (!h) { munmap(base, map_size); close(myfd); return NULL; }
    return h;
}

static void reqrep_destroy(ReqRepHandle *h) {
    if (!h) return;
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->reply_fd >= 0) close(h->reply_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->copy_buf);
    free(h->path);
    free(h);
}

/* ================================================================
 * Request queue operations (client -> server)
 * ================================================================ */

/* Push request while mutex is held. Returns 1=ok, 0=full, -2=too long. */
static inline int reqrep_send_locked(ReqRepHandle *h, const char *str,
                                      uint32_t len, bool utf8,
                                      uint32_t resp_slot_idx, uint32_t resp_gen) {
    ReqRepHeader *hdr = h->hdr;

    if (len > REQREP_STR_LEN_MASK) return -2;

    if (hdr->req_tail - hdr->req_head >= h->req_cap) {
        __atomic_add_fetch(&hdr->stat_send_full, 1, __ATOMIC_RELAXED);
        return 0;
    }

    uint32_t alloc = (len + 7) & ~7u;
    if (alloc == 0) alloc = 8;
    /* Single message must fit arena; else overflow into response slots. */
    if (alloc > h->req_arena_cap) return -2;
    uint32_t pos = hdr->arena_wpos;
    uint64_t skip = alloc;

    if ((uint64_t)pos + alloc > h->req_arena_cap) {
        skip += h->req_arena_cap - pos;
        pos = 0;
    }

    if ((uint64_t)hdr->arena_used + skip > h->req_arena_cap) {
        if (hdr->req_tail == hdr->req_head) {
            hdr->arena_wpos = 0;
            hdr->arena_used = 0;
            pos = 0;
            skip = alloc;
        } else {
            __atomic_add_fetch(&hdr->stat_send_full, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }

    memcpy(h->req_arena + pos, str, len);

    uint32_t idx = (uint32_t)(hdr->req_tail & h->req_cap_mask);
    ReqSlot *slot = &h->req_slots[idx];
    slot->arena_off = pos;
    slot->packed_len = len | (utf8 ? REQREP_UTF8_FLAG : 0);
    slot->arena_skip = (uint32_t)skip;
    slot->resp_slot = resp_slot_idx;
    slot->resp_gen = resp_gen;

    hdr->arena_wpos = pos + alloc;
    hdr->arena_used += (uint32_t)skip;
    hdr->req_tail++;
    __atomic_add_fetch(&hdr->stat_requests, 1, __ATOMIC_RELAXED);
    return 1;
}

/* Non-blocking send: acquire slot + push request.
 * Returns 1=ok, 0=full, -2=too long, -3=no slots.
 * On success, *out_id is the packed slot+generation ID. */
static int reqrep_try_send(ReqRepHandle *h, const char *str, uint32_t len,
                            bool utf8, uint64_t *out_id) {
    int32_t slot = reqrep_slot_acquire(h);
    if (slot < 0) return -3;

    RespSlotHeader *rslot = reqrep_resp_slot(h, (uint32_t)slot);
    uint32_t gen = __atomic_load_n(&rslot->generation, __ATOMIC_ACQUIRE);

    reqrep_mutex_lock(h->hdr);
    int r = reqrep_send_locked(h, str, len, utf8, (uint32_t)slot, gen);
    reqrep_mutex_unlock(h->hdr);

    if (r == 1) {
        reqrep_wake_consumers(h->hdr);
        *out_id = REQREP_MAKE_ID((uint32_t)slot, gen);
        return 1;
    }

    reqrep_slot_release(h, (uint32_t)slot);
    return r;
}

/* Blocking send with timeout. Returns 1=ok, 0=timeout, -2=too long, -3=no slots (timeout). */
static int reqrep_send_wait(ReqRepHandle *h, const char *str, uint32_t len,
                             bool utf8, uint64_t *out_id, double timeout) {
    int r = reqrep_try_send(h, str, len, utf8, out_id);
    if (r == 1 || r == -2) return r;
    if (timeout == 0) return r;

    ReqRepHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t *futex_word  = (r == -3) ? &hdr->slot_futex : &hdr->send_futex;
        uint32_t *waiter_cnt  = (r == -3) ? &hdr->slot_waiters : &hdr->send_waiters;

        uint32_t fseq = __atomic_load_n(futex_word, __ATOMIC_ACQUIRE);
        r = reqrep_try_send(h, str, len, utf8, out_id);
        if (r == 1 || r == -2) return r;

        __atomic_add_fetch(waiter_cnt, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(waiter_cnt, 1, __ATOMIC_RELEASE);
                return r;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, futex_word, FUTEX_WAIT, fseq, pts, NULL, 0);
        __atomic_sub_fetch(waiter_cnt, 1, __ATOMIC_RELEASE);

        r = reqrep_try_send(h, str, len, utf8, out_id);
        if (r == 1 || r == -2) return r;
        if (rc == -1 && errno == ETIMEDOUT) return r;
    }
}

/* Pop request while mutex is held. Returns 1=ok, 0=empty, -1=OOM. */
static inline int reqrep_recv_locked(ReqRepHandle *h, const char **out_str,
                                      uint32_t *out_len, bool *out_utf8,
                                      uint64_t *out_id) {
    ReqRepHeader *hdr = h->hdr;

    if (hdr->req_tail == hdr->req_head) {
        __atomic_add_fetch(&hdr->stat_recv_empty, 1, __ATOMIC_RELAXED);
        return 0;
    }

    uint32_t idx = (uint32_t)(hdr->req_head & h->req_cap_mask);
    ReqSlot *slot = &h->req_slots[idx];

    uint32_t len = slot->packed_len & REQREP_STR_LEN_MASK;
    *out_utf8 = (slot->packed_len & REQREP_UTF8_FLAG) != 0;
    *out_id = REQREP_MAKE_ID(slot->resp_slot, slot->resp_gen);

    if (!reqrep_ensure_copy_buf(h, len + 1))
        return -1;
    if (len > 0)
        memcpy(h->copy_buf, h->req_arena + slot->arena_off, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;

    if (hdr->arena_used >= slot->arena_skip)
        hdr->arena_used -= slot->arena_skip;
    else
        hdr->arena_used = 0;
    if (hdr->arena_used == 0)
        hdr->arena_wpos = 0;

    hdr->req_head++;
    return 1;
}

/* Pop request (server recv). Returns 1=ok, 0=empty, -1=OOM. */
static inline int reqrep_try_recv(ReqRepHandle *h, const char **out_str,
                                   uint32_t *out_len, bool *out_utf8,
                                   uint64_t *out_id) {
    reqrep_mutex_lock(h->hdr);
    int r = reqrep_recv_locked(h, out_str, out_len, out_utf8, out_id);
    reqrep_mutex_unlock(h->hdr);
    if (r == 1) reqrep_wake_producers(h->hdr);
    return r;
}

/* Blocking recv with timeout. Returns 1=ok, 0=timeout, -1=OOM. */
static int reqrep_recv_wait(ReqRepHandle *h, const char **out_str,
                             uint32_t *out_len, bool *out_utf8,
                             uint64_t *out_id, double timeout) {
    int r = reqrep_try_recv(h, out_str, out_len, out_utf8, out_id);
    if (r != 0) return r;
    if (timeout == 0) return 0;

    ReqRepHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t fseq = __atomic_load_n(&hdr->recv_futex, __ATOMIC_ACQUIRE);
        r = reqrep_try_recv(h, out_str, out_len, out_utf8, out_id);
        if (r != 0) return r;

        __atomic_add_fetch(&hdr->recv_waiters, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->recv_waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, &hdr->recv_futex, FUTEX_WAIT, fseq, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->recv_waiters, 1, __ATOMIC_RELEASE);

        r = reqrep_try_recv(h, out_str, out_len, out_utf8, out_id);
        if (r != 0) return r;
        if (rc == -1 && errno == ETIMEDOUT) return 0;
    }
}

/* ================================================================
 * Response operations (server -> client)
 * ================================================================ */

/* Write response to a response slot.
 * Returns 1=ok, -1=bad slot, -2=stale (cancelled/recycled), -3=too long. */
static int reqrep_reply(ReqRepHandle *h, uint64_t id,
                         const char *str, uint32_t len, bool utf8) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t expected_gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return -1;
    if (len > h->resp_data_max) return -3;

    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
    if (state != RESP_ACQUIRED) return -2;
    if (__atomic_load_n(&slot->generation, __ATOMIC_ACQUIRE) != expected_gen) return -2;

    uint8_t *data = (uint8_t *)slot + sizeof(RespSlotHeader);
    if (len > 0) memcpy(data, str, len);
    slot->resp_len = len;
    slot->resp_flags = utf8 ? 1 : 0;

    /* CAS ACQUIRED→READY to prevent race with concurrent cancel */
    uint32_t expected_state = RESP_ACQUIRED;
    if (!__atomic_compare_exchange_n(&slot->state, &expected_state, RESP_READY,
            0, __ATOMIC_RELEASE, __ATOMIC_RELAXED))
        return -2;

    if (__atomic_load_n(&slot->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &slot->state, FUTEX_WAKE, 1, NULL, NULL, 0);

    __atomic_add_fetch(&h->hdr->stat_replies, 1, __ATOMIC_RELAXED);
    return 1;
}

/* Non-blocking get response. Returns 1=ok, 0=not ready, -1=bad slot, -2=OOM, -4=stale. */
static int reqrep_try_get(ReqRepHandle *h, uint64_t id,
                           const char **out_str, uint32_t *out_len, bool *out_utf8) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t expected_gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return -1;

    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
    if (__atomic_load_n(&slot->generation, __ATOMIC_ACQUIRE) != expected_gen) return -4;
    if (state != RESP_READY) return 0;

    uint32_t len = slot->resp_len;
    *out_utf8 = (slot->resp_flags & 1) != 0;

    if (!reqrep_ensure_copy_buf(h, len + 1)) return -2;

    uint8_t *data = (uint8_t *)slot + sizeof(RespSlotHeader);
    if (len > 0) memcpy(h->copy_buf, data, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;

    reqrep_slot_release(h, slot_idx);
    return 1;
}

/* Blocking get response. Returns 1=ok, 0=timeout, -1=bad slot, -2=OOM, -4=stale. */
static int reqrep_get_wait(ReqRepHandle *h, uint64_t id,
                            const char **out_str, uint32_t *out_len, bool *out_utf8,
                            double timeout) {
    int r = reqrep_try_get(h, id, out_str, out_len, out_utf8);
    if (r != 0) return r;
    if (timeout == 0) return 0;

    uint32_t slot_idx = REQREP_ID_SLOT(id);
    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);

    for (;;) {
        uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
        if (state == RESP_READY)
            return reqrep_try_get(h, id, out_str, out_len, out_utf8);

        __atomic_add_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);

        /* Re-check: cancel may have fired between try_get and waiter registration */
        if (__atomic_load_n(&slot->generation, __ATOMIC_ACQUIRE) != REQREP_ID_GEN(id)) {
            __atomic_sub_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);
            return -4;
        }

        state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
        if (state == RESP_READY) {
            __atomic_sub_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);
            return reqrep_try_get(h, id, out_str, out_len, out_utf8);
        }

        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }

        syscall(SYS_futex, &slot->state, FUTEX_WAIT, state, pts, NULL, 0);
        __atomic_sub_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);

        r = reqrep_try_get(h, id, out_str, out_len, out_utf8);
        if (r != 0) return r;
    }
}

/* Cancel a pending request — CAS ACQUIRED→FREE only if generation matches.
 * If the reply already arrived (READY), cancel is a no-op — call get() to drain. */
static void reqrep_cancel(ReqRepHandle *h, uint64_t id) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t expected_gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return;
    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    if (__atomic_load_n(&slot->generation, __ATOMIC_ACQUIRE) != expected_gen) return;
    uint32_t expected_state = RESP_ACQUIRED;
    if (__atomic_compare_exchange_n(&slot->state, &expected_state, RESP_FREE,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
        __atomic_store_n(&slot->owner_pid, 0, __ATOMIC_RELAXED);
        __atomic_add_fetch(&slot->generation, 1, __ATOMIC_RELEASE);
        /* Wake get_wait blocked on this slot's state futex */
        if (__atomic_load_n(&slot->waiters, __ATOMIC_RELAXED) > 0)
            syscall(SYS_futex, &slot->state, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
        reqrep_wake_slot_waiters(h->hdr);
    }
}

/* Combined send + wait-for-reply with single deadline.
 * Returns 1=ok, 0=timeout, -2=too long, -3=no slots, -4=stale. */
static int reqrep_request(ReqRepHandle *h, const char *req_str, uint32_t req_len,
                           bool req_utf8, const char **out_str, uint32_t *out_len,
                           bool *out_utf8, double timeout) {
    uint64_t id;
    struct timespec deadline;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);

    int r = reqrep_send_wait(h, req_str, req_len, req_utf8, &id, timeout);
    if (r != 1) return r;

    double get_timeout = timeout;
    if (has_deadline) {
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        get_timeout = (double)(deadline.tv_sec - now.tv_sec) +
                      (double)(deadline.tv_nsec - now.tv_nsec) / 1e9;
        if (get_timeout <= 0) {
            reqrep_cancel(h, id);
            return 0;
        }
    }

    r = reqrep_get_wait(h, id, out_str, out_len, out_utf8, get_timeout);
    if (r != 1) {
        reqrep_cancel(h, id);
        /* If reply arrived between timeout and cancel, drain to free the slot */
        const char *discard; uint32_t dlen; bool dutf8;
        reqrep_try_get(h, id, &discard, &dlen, &dutf8);
    }
    return r;
}

/* Count response slots owned by this process */
static uint32_t reqrep_pending(ReqRepHandle *h) {
    uint32_t mypid = (uint32_t)getpid();
    uint32_t count = 0;
    for (uint32_t i = 0; i < h->resp_slots; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_RELAXED);
        if ((state == RESP_ACQUIRED || state == RESP_READY) &&
            __atomic_load_n(&slot->owner_pid, __ATOMIC_RELAXED) == mypid)
            count++;
    }
    return count;
}

/* ================================================================
 * Queue state
 * ================================================================ */

static inline uint64_t reqrep_size(ReqRepHandle *h) {
    ReqRepHeader *hdr = h->hdr;
    uint64_t tail = __atomic_load_n(&hdr->req_tail, __ATOMIC_RELAXED);
    uint64_t head = __atomic_load_n(&hdr->req_head, __ATOMIC_RELAXED);
    return tail - head;
}

static void reqrep_clear(ReqRepHandle *h) {
    ReqRepHeader *hdr = h->hdr;
    reqrep_mutex_lock(hdr);
    hdr->req_head = 0;
    hdr->req_tail = 0;
    hdr->arena_wpos = 0;
    hdr->arena_used = 0;
    reqrep_mutex_unlock(hdr);

    /* Release all in-flight response slots so get_wait callers unblock.
     * Retry CAS if reply races us (ACQUIRED→READY between load and CAS). */
    for (uint32_t i = 0; i < h->resp_slots; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
        while (state == RESP_ACQUIRED || state == RESP_READY) {
            if (__atomic_compare_exchange_n(&slot->state, &state, RESP_FREE,
                    0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                __atomic_store_n(&slot->owner_pid, 0, __ATOMIC_RELAXED);
                __atomic_add_fetch(&slot->generation, 1, __ATOMIC_RELEASE);
                if (__atomic_load_n(&slot->waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &slot->state, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
                break;
            }
            /* CAS failed — state updated with actual value; retry if still valid */
        }
    }

    reqrep_wake_slot_waiters(hdr);
    reqrep_wake_producers(hdr);
    reqrep_wake_consumers(hdr);
}

static inline int reqrep_sync(ReqRepHandle *h) {
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

/* ================================================================
 * eventfd — event-loop integration
 *
 * Two separate eventfds:
 *   notify_fd — request notification (client -> server: "new request")
 *   reply_fd  — reply notification (server -> client: "response ready")
 * ================================================================ */

static inline int reqrep_eventfd_create(ReqRepHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    h->notify_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    return h->notify_fd;
}

static inline void reqrep_eventfd_set(ReqRepHandle *h, int fd) {
    if (h->notify_fd >= 0 && h->notify_fd != fd)
        close(h->notify_fd);
    h->notify_fd = fd;
}

static inline void reqrep_notify(ReqRepHandle *h) {
    if (h->notify_fd >= 0) {
        uint64_t one = 1;
        ssize_t __attribute__((unused)) rc = write(h->notify_fd, &one, sizeof(one));
    }
}

static inline int64_t reqrep_eventfd_consume(ReqRepHandle *h) {
    if (h->notify_fd < 0) return -1;
    uint64_t val = 0;
    if (read(h->notify_fd, &val, sizeof(val)) != sizeof(val)) return -1;
    return (int64_t)val;
}

static inline int reqrep_reply_eventfd_create(ReqRepHandle *h) {
    if (h->reply_fd >= 0) return h->reply_fd;
    h->reply_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    return h->reply_fd;
}

static inline void reqrep_reply_eventfd_set(ReqRepHandle *h, int fd) {
    if (h->reply_fd >= 0 && h->reply_fd != fd)
        close(h->reply_fd);
    h->reply_fd = fd;
}

static inline void reqrep_reply_notify(ReqRepHandle *h) {
    if (h->reply_fd >= 0) {
        uint64_t one = 1;
        ssize_t __attribute__((unused)) rc = write(h->reply_fd, &one, sizeof(one));
    }
}

static inline int64_t reqrep_reply_eventfd_consume(ReqRepHandle *h) {
    if (h->reply_fd < 0) return -1;
    uint64_t val = 0;
    if (read(h->reply_fd, &val, sizeof(val)) != sizeof(val)) return -1;
    return (int64_t)val;
}

/* ================================================================
 * Int mode: lock-free Vyukov MPMC request queue, inline int64 response
 * ================================================================ */

/* Returns 0 on success, -1 on overflow. */
static int reqrep_int_compute_layout(uint32_t req_cap, uint32_t resp_slots_n,
                                      uint32_t *out_req_slots_off, uint32_t *out_resp_off,
                                      uint32_t *out_resp_stride, uint64_t *out_total_size) {
    uint32_t req_slots_off = sizeof(ReqRepHeader);
    uint64_t slots_end = (uint64_t)req_slots_off + (uint64_t)req_cap * sizeof(ReqIntSlot);
    uint32_t resp_stride = (sizeof(RespSlotHeader) + sizeof(int64_t) + 63) & ~63u;
    uint64_t resp_off = (slots_end + 63) & ~(uint64_t)63;
    if (resp_off > UINT32_MAX) return -1;
    *out_req_slots_off = req_slots_off;
    *out_resp_off      = (uint32_t)resp_off;
    *out_resp_stride   = resp_stride;
    *out_total_size    = resp_off + (uint64_t)resp_slots_n * resp_stride;
    return 0;
}

static void reqrep_int_init_header(void *base, uint32_t req_cap, uint32_t resp_slots_n,
                                    uint64_t total_size, uint32_t req_slots_off,
                                    uint32_t resp_off, uint32_t resp_stride) {
    ReqRepHeader *hdr = (ReqRepHeader *)base;
    memset(hdr, 0, sizeof(ReqRepHeader));
    hdr->magic         = REQREP_MAGIC;
    hdr->version       = REQREP_VERSION;
    hdr->mode          = REQREP_MODE_INT;
    hdr->req_cap       = req_cap;
    hdr->total_size    = total_size;
    hdr->req_slots_off = req_slots_off;
    hdr->resp_slots    = resp_slots_n;
    hdr->resp_data_max = sizeof(int64_t);
    hdr->resp_off      = resp_off;
    hdr->resp_stride   = resp_stride;

    /* Vyukov: init sequence numbers */
    ReqIntSlot *slots = (ReqIntSlot *)((char *)base + req_slots_off);
    for (uint32_t i = 0; i < req_cap; i++)
        slots[i].sequence = i;

    /* Init response slots */
    for (uint32_t i = 0; i < resp_slots_n; i++) {
        RespSlotHeader *rs = (RespSlotHeader *)((uint8_t *)base + resp_off + (uint64_t)i * resp_stride);
        memset(rs, 0, sizeof(RespSlotHeader));
    }

    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static ReqRepHandle *reqrep_create_int(const char *path, uint32_t req_cap,
                                        uint32_t resp_slots_n, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    req_cap = reqrep_next_pow2(req_cap);
    if (req_cap == 0) { REQREP_ERR("invalid req_cap"); return NULL; }
    if (resp_slots_n == 0) { REQREP_ERR("resp_slots must be > 0"); return NULL; }

    uint32_t req_slots_off, resp_off, resp_stride;
    uint64_t total_size;
    if (reqrep_int_compute_layout(req_cap, resp_slots_n, &req_slots_off,
                                   &resp_off, &resp_stride, &total_size) < 0) {
        REQREP_ERR("layout overflow: req_cap too large for uint32 offsets");
        return NULL;
    }

    int anonymous = (path == NULL);
    size_t map_size;
    void *base;

    if (anonymous) {
        map_size = (size_t)total_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        if (base == MAP_FAILED) { REQREP_ERR("mmap(anonymous): %s", strerror(errno)); return NULL; }
    } else {
        int fd = open(path, O_RDWR | O_CREAT, 0666);
        if (fd < 0) { REQREP_ERR("open(%s): %s", path, strerror(errno)); return NULL; }
        if (flock(fd, LOCK_EX) < 0) { REQREP_ERR("flock: %s", strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { REQREP_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(ReqRepHeader)) {
            REQREP_ERR("%s: file too small", path); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && ftruncate(fd, (off_t)total_size) < 0) {
            REQREP_ERR("ftruncate: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total_size : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) { REQREP_ERR("mmap: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        if (!is_new) {
            if (!reqrep_validate_header((ReqRepHeader *)base, map_size, REQREP_MODE_INT)) {
                REQREP_ERR("%s: invalid or incompatible", path); munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            return reqrep_setup_handle(base, map_size, path, -1);
        }
        reqrep_int_init_header(base, req_cap, resp_slots_n, total_size,
                                req_slots_off, resp_off, resp_stride);
        flock(fd, LOCK_UN); close(fd);
        return reqrep_setup_handle(base, map_size, path, -1);
    }

    reqrep_int_init_header(base, req_cap, resp_slots_n, total_size,
                            req_slots_off, resp_off, resp_stride);
    return reqrep_setup_handle(base, map_size, path, -1);
}

static ReqRepHandle *reqrep_create_int_memfd(const char *name, uint32_t req_cap,
                                              uint32_t resp_slots_n, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    req_cap = reqrep_next_pow2(req_cap);
    if (req_cap == 0) { REQREP_ERR("invalid req_cap"); return NULL; }
    if (resp_slots_n == 0) { REQREP_ERR("resp_slots must be > 0"); return NULL; }

    uint32_t req_slots_off, resp_off, resp_stride;
    uint64_t total_size;
    if (reqrep_int_compute_layout(req_cap, resp_slots_n, &req_slots_off,
                                   &resp_off, &resp_stride, &total_size) < 0) {
        REQREP_ERR("layout overflow: req_cap too large for uint32 offsets");
        return NULL;
    }

    int fd = memfd_create(name ? name : "reqrep_int", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { REQREP_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (ftruncate(fd, (off_t)total_size) < 0) {
        REQREP_ERR("ftruncate: %s", strerror(errno)); close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { REQREP_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }

    reqrep_int_init_header(base, req_cap, resp_slots_n, total_size,
                            req_slots_off, resp_off, resp_stride);
    return reqrep_setup_handle(base, (size_t)total_size, NULL, fd);
}

/* --- Int request queue: lock-free Vyukov MPMC --- */

static inline int reqrep_int_try_send(ReqRepHandle *h, int64_t value, uint64_t *out_id) {
    int32_t rslot = reqrep_slot_acquire(h);
    if (rslot < 0) return -3;

    RespSlotHeader *rs = reqrep_resp_slot(h, (uint32_t)rslot);
    uint32_t gen = __atomic_load_n(&rs->generation, __ATOMIC_ACQUIRE);

    ReqRepHeader *hdr = h->hdr;
    ReqIntSlot *slots = (ReqIntSlot *)((char *)h->hdr + hdr->req_slots_off);
    uint32_t mask = h->req_cap_mask;
    uint64_t pos = __atomic_load_n(&hdr->req_tail, __ATOMIC_RELAXED);

    for (;;) {
        ReqIntSlot *slot = &slots[pos & mask];
        uint64_t seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);
        int64_t diff = (int64_t)seq - (int64_t)pos;
        if (diff == 0) {
            if (__atomic_compare_exchange_n(&hdr->req_tail, &pos, pos + 1,
                    1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {
                slot->value = value;
                slot->resp_slot = (uint32_t)rslot;
                slot->resp_gen = gen;
                __atomic_store_n(&slot->sequence, pos + 1, __ATOMIC_RELEASE);
                __atomic_add_fetch(&hdr->stat_requests, 1, __ATOMIC_RELAXED);
                reqrep_wake_consumers(hdr);
                *out_id = REQREP_MAKE_ID((uint32_t)rslot, gen);
                return 1;
            }
        } else if (diff < 0) {
            __atomic_add_fetch(&hdr->stat_send_full, 1, __ATOMIC_RELAXED);
            reqrep_slot_release(h, (uint32_t)rslot);
            return 0;
        } else {
            pos = __atomic_load_n(&hdr->req_tail, __ATOMIC_RELAXED);
        }
    }
}

static int reqrep_int_send_wait(ReqRepHandle *h, int64_t value,
                                 uint64_t *out_id, double timeout) {
    int r = reqrep_int_try_send(h, value, out_id);
    if (r == 1) return 1;
    if (timeout == 0) return r;
    ReqRepHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);
    for (;;) {
        /* Wait on slot_futex if no slots (-3), send_futex if queue full (0) */
        uint32_t *futex_word = (r == -3) ? &hdr->slot_futex : &hdr->send_futex;
        uint32_t *waiter_cnt = (r == -3) ? &hdr->slot_waiters : &hdr->send_waiters;

        uint32_t fseq = __atomic_load_n(futex_word, __ATOMIC_ACQUIRE);
        r = reqrep_int_try_send(h, value, out_id);
        if (r == 1) return 1;

        __atomic_add_fetch(waiter_cnt, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(waiter_cnt, 1, __ATOMIC_RELEASE);
                return r;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, futex_word, FUTEX_WAIT, fseq, pts, NULL, 0);
        __atomic_sub_fetch(waiter_cnt, 1, __ATOMIC_RELEASE);
        r = reqrep_int_try_send(h, value, out_id);
        if (r == 1) return 1;
        if (rc == -1 && errno == ETIMEDOUT) return r;
    }
}

static inline int reqrep_int_try_recv(ReqRepHandle *h, int64_t *out_value, uint64_t *out_id) {
    ReqRepHeader *hdr = h->hdr;
    ReqIntSlot *slots = (ReqIntSlot *)((char *)hdr + hdr->req_slots_off);
    uint32_t mask = h->req_cap_mask;
    uint64_t pos = __atomic_load_n(&hdr->req_head, __ATOMIC_RELAXED);
    for (;;) {
        ReqIntSlot *slot = &slots[pos & mask];
        uint64_t seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);
        int64_t diff = (int64_t)seq - (int64_t)(pos + 1);
        if (diff == 0) {
            if (__atomic_compare_exchange_n(&hdr->req_head, &pos, pos + 1,
                    1, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {
                *out_value = slot->value;
                *out_id = REQREP_MAKE_ID(slot->resp_slot, slot->resp_gen);
                __atomic_store_n(&slot->sequence, pos + h->req_cap, __ATOMIC_RELEASE);
                reqrep_wake_producers(hdr);
                return 1;
            }
        } else if (diff < 0) {
            __atomic_add_fetch(&hdr->stat_recv_empty, 1, __ATOMIC_RELAXED);
            return 0;
        } else {
            pos = __atomic_load_n(&hdr->req_head, __ATOMIC_RELAXED);
        }
    }
}

static int reqrep_int_recv_wait(ReqRepHandle *h, int64_t *out_value,
                                 uint64_t *out_id, double timeout) {
    if (reqrep_int_try_recv(h, out_value, out_id)) return 1;
    if (timeout == 0) return 0;
    ReqRepHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);
    for (;;) {
        uint32_t fseq = __atomic_load_n(&hdr->recv_futex, __ATOMIC_ACQUIRE);
        if (reqrep_int_try_recv(h, out_value, out_id)) return 1;
        __atomic_add_fetch(&hdr->recv_waiters, 1, __ATOMIC_RELEASE);
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&hdr->recv_waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }
        long rc = syscall(SYS_futex, &hdr->recv_futex, FUTEX_WAIT, fseq, pts, NULL, 0);
        __atomic_sub_fetch(&hdr->recv_waiters, 1, __ATOMIC_RELEASE);
        if (reqrep_int_try_recv(h, out_value, out_id)) return 1;
        if (rc == -1 && errno == ETIMEDOUT) return 0;
    }
}

/* --- Int response: inline int64 in resp data area --- */

static int reqrep_int_reply(ReqRepHandle *h, uint64_t id, int64_t value) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t expected_gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return -1;

    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
    if (state != RESP_ACQUIRED) return -2;
    if (__atomic_load_n(&slot->generation, __ATOMIC_ACQUIRE) != expected_gen) return -2;

    *(int64_t *)((uint8_t *)slot + sizeof(RespSlotHeader)) = value;

    uint32_t expected_state = RESP_ACQUIRED;
    if (!__atomic_compare_exchange_n(&slot->state, &expected_state, RESP_READY,
            0, __ATOMIC_RELEASE, __ATOMIC_RELAXED))
        return -2;

    if (__atomic_load_n(&slot->waiters, __ATOMIC_RELAXED) > 0)
        syscall(SYS_futex, &slot->state, FUTEX_WAKE, 1, NULL, NULL, 0);
    __atomic_add_fetch(&h->hdr->stat_replies, 1, __ATOMIC_RELAXED);
    return 1;
}

static int reqrep_int_try_get(ReqRepHandle *h, uint64_t id, int64_t *out_value) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t expected_gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return -1;

    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
    if (__atomic_load_n(&slot->generation, __ATOMIC_ACQUIRE) != expected_gen) return -4;
    if (state != RESP_READY) return 0;

    *out_value = *(int64_t *)((uint8_t *)slot + sizeof(RespSlotHeader));
    reqrep_slot_release(h, slot_idx);
    return 1;
}

static int reqrep_int_get_wait(ReqRepHandle *h, uint64_t id, int64_t *out_value,
                                double timeout) {
    int r = reqrep_int_try_get(h, id, out_value);
    if (r != 0) return r;
    if (timeout == 0) return 0;
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);
    for (;;) {
        uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
        if (state == RESP_READY)
            return reqrep_int_try_get(h, id, out_value);
        __atomic_add_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);
        if (__atomic_load_n(&slot->generation, __ATOMIC_ACQUIRE) != REQREP_ID_GEN(id)) {
            __atomic_sub_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);
            return -4;
        }
        state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
        if (state == RESP_READY) {
            __atomic_sub_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);
            return reqrep_int_try_get(h, id, out_value);
        }
        struct timespec *pts = NULL;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                __atomic_sub_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);
                return 0;
            }
            pts = &remaining;
        }
        syscall(SYS_futex, &slot->state, FUTEX_WAIT, state, pts, NULL, 0);
        __atomic_sub_fetch(&slot->waiters, 1, __ATOMIC_RELEASE);
        r = reqrep_int_try_get(h, id, out_value);
        if (r != 0) return r;
    }
}

static int reqrep_int_request(ReqRepHandle *h, int64_t req_value, int64_t *out_value,
                               double timeout) {
    uint64_t id;
    struct timespec deadline;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);
    int r = reqrep_int_send_wait(h, req_value, &id, timeout);
    if (r != 1) return r;
    double get_timeout = timeout;
    if (has_deadline) {
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        get_timeout = (double)(deadline.tv_sec - now.tv_sec) +
                      (double)(deadline.tv_nsec - now.tv_nsec) / 1e9;
        if (get_timeout <= 0) { reqrep_cancel(h, id); return 0; }
    }
    r = reqrep_int_get_wait(h, id, out_value, get_timeout);
    if (r != 1) {
        reqrep_cancel(h, id);
        int64_t discard;
        reqrep_int_try_get(h, id, &discard);
    }
    return r;
}

static inline uint64_t reqrep_int_size(ReqRepHandle *h) {
    uint64_t tail = __atomic_load_n(&h->hdr->req_tail, __ATOMIC_RELAXED);
    uint64_t head = __atomic_load_n(&h->hdr->req_head, __ATOMIC_RELAXED);
    return tail - head;
}

static void reqrep_int_clear(ReqRepHandle *h) {
    ReqRepHeader *hdr = h->hdr;

    /* Reset Vyukov queue: head/tail to 0, reinit sequence numbers.
     * Use atomic stores — concurrent readers use atomic loads on these. */
    __atomic_store_n(&hdr->req_head, 0, __ATOMIC_RELAXED);
    __atomic_store_n(&hdr->req_tail, 0, __ATOMIC_RELAXED);
    ReqIntSlot *slots = (ReqIntSlot *)((char *)hdr + hdr->req_slots_off);
    for (uint32_t i = 0; i < h->req_cap; i++)
        __atomic_store_n(&slots[i].sequence, (uint64_t)i, __ATOMIC_RELAXED);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);

    /* Release all in-flight response slots (same as Str clear) */
    for (uint32_t i = 0; i < h->resp_slots; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        uint32_t state = __atomic_load_n(&slot->state, __ATOMIC_ACQUIRE);
        while (state == RESP_ACQUIRED || state == RESP_READY) {
            if (__atomic_compare_exchange_n(&slot->state, &state, RESP_FREE,
                    0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                __atomic_store_n(&slot->owner_pid, 0, __ATOMIC_RELAXED);
                __atomic_add_fetch(&slot->generation, 1, __ATOMIC_RELEASE);
                if (__atomic_load_n(&slot->waiters, __ATOMIC_RELAXED) > 0)
                    syscall(SYS_futex, &slot->state, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
                break;
            }
        }
    }

    reqrep_wake_slot_waiters(hdr);
    reqrep_wake_producers(hdr);
    reqrep_wake_consumers(hdr);
}

#endif /* REQREP_H */
