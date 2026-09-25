/* reqrep.h -- Shared-memory request/response IPC for Linux */

#ifndef REQREP_H
#define REQREP_H

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <limits.h>
#include <signal.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/resource.h>
#include <sys/file.h>
#include <sys/syscall.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <stddef.h>
#include <linux/futex.h>
#include <sys/eventfd.h>
#include <pthread.h>

#define REQREP_MAGIC           0x52525331U  /* "RRS1" */
#define REQREP_VERSION         6
#define REQREP_ERR_BUFLEN      (PATH_MAX + 256)
#define REQREP_SPIN_LIMIT      32
#define REQREP_LOCK_TIMEOUT_SEC 2
#define REQREP_TICK_NS         ((uint64_t)REQREP_LOCK_TIMEOUT_SEC * 1000000000ULL)
#define REQREP_EINTR           -7
/* A signal outside a futex wait only sets Perl's flag: waits check it before parking. */
#define REQREP_INTERRUPTED(h)  ((h)->sig_pending && *(h)->sig_pending)
/* Minimum gap between a handle's fruitless recovery scans. */
#define REQREP_RECOVERY_INTERVAL_NS 10000000ULL
/* Processes whose start time a channel remembers at once, a power of 2. */
#define REQREP_PROC_SLOTS      1024
/* A record's start while the holdings of the dead process it named are released. */
#define REQREP_START_RELEASING UINT32_MAX
/* Counters of notifications refused by full client queues, hashed by client pid and tag. */
#define REQREP_LOST_BITS       8
#define REQREP_LOST_SLOTS      (1u << REQREP_LOST_BITS)
/* What follows the response slots: the ReqRepProc table, then the loss counters. */
#define REQREP_TAIL_SIZE       ((uint64_t)REQREP_PROC_SLOTS * sizeof(ReqRepProc) \
                                + (uint64_t)REQREP_LOST_SLOTS * sizeof(uint32_t))
/* CAS retries against concurrent state changes: a safety net, never a wait. */
#define REQREP_CANCEL_RETRIES  4096

#define REQREP_UTF8_FLAG       0x80000000U
/* Ids one ready() call returns at most; the rest wait for the next, which its descriptor asks for. */
#define REQREP_READY_MAX       4096
/* In RespSlotHeader.owner_tag: the owner listens on its ready_fd for this reply. */
#define REQREP_TAG_NOTIFY      0x80000000U
#define REQREP_STR_LEN_MASK    0x7FFFFFFFU

#define RESP_FREE              0
#define RESP_ACQUIRED          1
#define RESP_READY             2
#define RESP_WRITING           3
/* The process that received the request holds it; only that process may reply. */
#define RESP_DISPATCHED        4
/* The owner (or clear()) gave up on a reply still being written; its responder frees the slot. */
#define RESP_ABANDONED         5

/* A response slot's ctl word: [generation:32][pid:24][generation & 31:5][state:3]. Taking a slot
 * bumps the generation. The pid names the owner in ACQUIRED and READY, the receiver in DISPATCHED
 * and the responder in WRITING and ABANDONED. The low half is the futex; its generation bits keep
 * it from repeating across a quick re-acquire. */
#define REQREP_CTL(gen, pid, state) (((uint64_t)(gen) << 32) | ((uint64_t)((pid) & 0xFFFFFFU) << 8) \
                                     | ((uint64_t)((gen) & 31U) << 3) | (uint64_t)(state))
#define REQREP_CTL_GEN(c)      ((uint32_t)((c) >> 32))
#define REQREP_CTL_PID(c)      ((uint32_t)((c) >> 8) & 0xFFFFFFU)
#define REQREP_CTL_STATE(c)    ((uint32_t)(c) & 7U)

#define REQREP_MODE_STR        0
#define REQREP_MODE_INT        1

/* The generation in an id keeps it from matching the slot once re-acquired. */
#define REQREP_MAKE_ID(slot, gen) (((uint64_t)(gen) << 32) | (uint64_t)(slot))
#define REQREP_ID_SLOT(id)  ((uint32_t)((id) & 0xFFFFFFFFULL))
#define REQREP_ID_GEN(id)   ((uint32_t)((id) >> 32))

typedef struct {
    /* ---- Cache line 0 (0-63): immutable after create ---- */
    uint32_t magic;           /* 0 */
    uint32_t version;         /* 4 */
    uint32_t mode;            /* 8 */
    uint32_t req_cap;         /* 12: power of 2 */
    uint64_t total_size;      /* 16 */
    uint32_t req_slots_off;   /* 24 */
    uint32_t req_arena_off;   /* 28 */
    uint32_t req_arena_cap;   /* 32 */
    uint32_t resp_slots;      /* 36 */
    uint32_t resp_data_max;   /* 40 */
    uint32_t resp_off;        /* 44 */
    uint32_t resp_stride;     /* 48 */
    /* Both 0 when the creator could not read /proc: unverifiable, never a match. */
    uint32_t boot_id_hash;    /* 52: FNV-1a of /proc/sys/kernel/random/boot_id */
    uint64_t pidns_ino;       /* 56: inode of the creator's /proc/self/ns/pid */

    /* ---- Cache line 1 (64-127): recv hot (server) ---- */
    uint64_t req_head;        /* 64 */
    uint64_t recv_waiters;    /* 72: see REQREP_WAITERS */
    uint32_t recv_futex;      /* 80 */
    uint8_t  _pad1[44];       /* 84-127 */

    /* ---- Cache line 2 (128-191): send hot (client) ---- */
    uint64_t req_tail;        /* 128 */
    uint64_t send_waiters;    /* 136: see REQREP_WAITERS */
    uint32_t send_futex;      /* 144 */
    uint32_t _pad2a;          /* 148 */
    uint64_t stat_send_full;  /* 152 */
    /* Arena room held for the largest parked sender that did not fit, under the mutex. */
    uint32_t arena_reserved;  /* 160 */
    uint32_t arena_reserver;  /* 164: its pid */
    uint32_t arena_reserver_tag; /* 168: its ReqRepHandle.tag */
    uint32_t proc_off;        /* 172 */
    uint32_t proc_slots;      /* 176 */
    uint32_t lost_slots;      /* 180 */
    uint64_t channel_id;      /* 184: random, names the clients' notification sockets */

    /* ---- Cache line 3 (192-255): mutex + arena state + stats ---- */
    uint32_t mutex;           /* 192: 0 or REQREP_MUTEX_VAL of the holder */
    uint32_t mutex_futex;     /* 196: parked lockers sleep on this, not on the holder's pid */
    uint64_t mutex_waiters;   /* 200: see REQREP_WAITERS */
    uint32_t arena_wpos;      /* 208 */
    uint32_t arena_used;      /* 212 */
    uint32_t resp_hint;       /* 216 */
    uint32_t stat_recoveries; /* 220 */
    uint64_t slot_waiters;    /* 224: see REQREP_WAITERS */
    uint32_t slot_futex;      /* 232 */
    uint32_t stat_recv_empty; /* 236 */
    uint64_t stat_requests;   /* 240 */
    uint64_t stat_replies;    /* 248 */
} ReqRepHeader;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(ReqRepHeader) == 256, "ReqRepHeader must be 256 bytes");
#endif

typedef struct {
    uint32_t arena_off;
    uint32_t packed_len;   /* bit 31 = UTF-8, bits 0-30 = byte length */
    uint32_t arena_skip;   /* bytes to release from arena on recv */
    uint32_t resp_slot;
    uint32_t resp_gen;
    uint32_t _rpad;
} ReqSlot;  /* 24 bytes (Str mode) */

/* Int request slot. A cell at queue position p reads sequence p while free for the sender claiming p,
 * p + 1 once published, and p + capacity once taken, which frees it for the sender at p + capacity.
 * A receiver moves the head past p before marking the cell taken. */
typedef struct {
    uint64_t sequence;
    int64_t  value;
    uint32_t resp_slot;
    uint32_t resp_gen;
} ReqIntSlot;  /* 24 bytes (Int mode, lock-free) */

typedef struct {
    uint64_t ctl;          /* see REQREP_CTL; the low half is the slot's futex */
    uint64_t waiters;      /* [generation:32][count:32] of callers parked for a reply */
    uint64_t claim_pos;    /* the queue position of the owner's request (Int: while claiming it) */
    uint32_t owner;        /* owner pid, while ctl names the receiver or responder */
    uint32_t owner_tag;    /* the owner's ReqRepHandle.tag, with REQREP_TAG_NOTIFY */
    uint32_t resp_len;
    uint32_t resp_flags;   /* bit 0 = UTF-8 */
} RespSlotHeader;  /* 40 bytes + data */

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(RespSlotHeader) == 40, "RespSlotHeader must be 40 bytes");
#endif

/* A process that used the channel: a pid names it only while that pid's start time still matches. */
typedef struct {
    uint32_t pid;
    uint32_t start;        /* low bits of the start time in clock ticks, 0 while unknown */
} ReqRepProc;

/* When a waiting handle last found a receiver or mutex holder alive in /proc. */
#define REQREP_PROBE_MEMO      8
typedef struct {
    uint32_t pid;
    uint64_t when_ns;
} ReqRepProbe;

/* Requests a waiting handle has seen taken off the queue but not yet marked received, and since
 * when. One seen while every entry is current goes untimed, left to the caller's timeout. */
#define REQREP_UNMARKED_MEMO   16
typedef struct {
    uint32_t slot, gen;
    uint64_t since_ns;     /* 0: the entry is free */
} ReqRepUnmarked;

/* A waker's record of wakes that found nobody parked while the count read the same. */
typedef struct { uint64_t seen; uint32_t misses; } ReqRepWakeMemo;

typedef struct {
    ReqRepHeader  *hdr;
    ReqSlot       *req_slots;
    char          *req_arena;
    uint8_t       *resp_area;
    size_t         mmap_size;
    uint32_t       req_cap;
    uint32_t       req_cap_mask;
    uint32_t       req_arena_cap;
    uint32_t       resp_slots;
    uint32_t       resp_data_max;
    uint32_t       resp_stride;
    char          *copy_buf;
    uint32_t       copy_buf_cap;
    char          *path;
    dev_t          file_dev;      /* identity of the file at path when opened, for unlink */
    ino_t          file_ino;
    int            notify_fd;     /* request notification eventfd, -1 if unset */
    int            reply_fd;      /* reply notification eventfd, -1 if unset */
    int            backing_fd;    /* memfd fd, -1 for file-backed/anonymous */
    uint64_t       last_scan_ns;
    ReqRepWakeMemo recv_wake, send_wake, slot_wake, mutex_wake;
    uint32_t       tag;           /* tells this handle's requests from others of the same process */
    uint64_t       inflight;      /* slots this handle took and has not itself given back; never fewer than it holds */
    uint8_t        reserving;     /* this handle may hold the arena reservation */
    uint32_t       reserve_blocker, reserve_blocker_tag; /* whose reservation refused the last send */
    uint64_t       last_reserve_check_ns;
    volatile int  *sig_pending;   /* the owning Perl interpreter's pending-signal flag, or NULL */
    ReqRepProc    *procs;
    uint32_t      *lost;          /* REQREP_LOST_SLOTS counters */
    uint32_t       registered_pid;
    uint32_t       register_failed_pid; /* the process whose registration last failed, and when */
    uint64_t       register_failed_ns;
    int            ready_sock;    /* this client's notification socket, -1 if none */
    uint32_t       ready_pid;     /* the process that bound it */
    uint32_t      *told;          /* per slot, the generation ready last listed */
    uint32_t       lost_seen;     /* this client's loss counter when last looked through */
    uint32_t       lost_scan;     /* slot a search cut short resumes at */
    uint32_t       lost_snapshot; /* the counter when the current search began */
    int            notify_sock;   /* a server's socket for sending notifications, -1 if none */
    uint64_t       last_claim_scan_ns;
    uint64_t       born_ns;           /* when this handle was made: no /proc read in its first tick */
    ReqRepProbe    probe[REQREP_PROBE_MEMO];
    ReqRepUnmarked unmarked[REQREP_UNMARKED_MEMO];
    uint32_t       unmarked_used;     /* entries in use: none, and the wait loop skips the table */
} ReqRepHandle;

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

#define REQREP_MUTEX_WRITER_BIT 0x80000000U
#define REQREP_MUTEX_PID_MASK   0x7FFFFFFFU
#define REQREP_MUTEX_VAL(pid)   (REQREP_MUTEX_WRITER_BIT | ((uint32_t)(pid) & REQREP_MUTEX_PID_MASK))

/* From /proc/<pid>/stat: 0 for a zombie, else 1 with *start set; -1 with errno set if it cannot be
 * read, EIO for a file it cannot parse. */
static inline int reqrep_proc_stat(uint32_t pid, uint32_t *start) {
    char path[16], buf[512];
    snprintf(path, sizeof(path), "%u/stat", (unsigned)pid);
    /* Relative to /proc: qemu-user fakes the start time in a process's own /proc/<pid>/stat. */
    int dir = open("/proc", O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (dir < 0) return -1;
    int fd = openat(dir, path, O_RDONLY | O_CLOEXEC);
    int err = errno;
    close(dir);
    if (fd < 0) { errno = err; return -1; }
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    err = n < 0 ? errno : EIO;
    close(fd);
    if (n <= 0) { errno = err; return -1; }
    buf[n] = '\0';
    /* "pid (comm) state ..."; comm may contain ')', so scan to the last one. */
    char *rp = strrchr(buf, ')');
    if (!rp || rp + 2 >= buf + n || rp[1] != ' ') { errno = EIO; return -1; }
    if (rp[2] == 'Z') return 0;
    char *p = rp + 2;
    for (int field = 3; field < 22; field++) {   /* the start time is field 22 */
        p = strchr(p, ' ');
        if (!p) { errno = EIO; return -1; }
        p++;
    }
    uint32_t t = (uint32_t)strtoull(p, NULL, 10);
    *start = t == 0 ? 1 : t == REQREP_START_RELEASING ? t - 1 : t;
    return 1;
}
static inline uint64_t reqrep_pidns_ino(void) {
    struct stat st;
    if (stat("/proc/self/ns/pid", &st) != 0) return 0;
    return (uint64_t)st.st_ino;
}

static inline uint32_t reqrep_boot_id_hash(void) {
    int fd = open("/proc/sys/kernel/random/boot_id", O_RDONLY | O_CLOEXEC);
    if (fd < 0) return 0;
    char buf[64];
    ssize_t n = read(fd, buf, sizeof(buf));
    close(fd);
    if (n <= 0) return 0;
    uint32_t h = 2166136261u;                     /* FNV-1a */
    for (ssize_t i = 0; i < n; i++) { h ^= (uint8_t)buf[i]; h *= 16777619u; }
    return h ? h : 1;                             /* keep 0 for "unknown" */
}

/* A record is read and changed as one word, so neither half is ever judged by a stale other. */
static inline ReqRepProc reqrep_proc_load(ReqRepProc *e) {
    uint64_t w = __atomic_load_n((uint64_t *)e, __ATOMIC_ACQUIRE);
    ReqRepProc r;
    memcpy(&r, &w, sizeof r);
    return r;
}

static inline int reqrep_proc_cas(ReqRepProc *e, ReqRepProc was, uint32_t pid, uint32_t start) {
    ReqRepProc to = { pid, start };
    uint64_t ow, nw;
    memcpy(&ow, &was, sizeof ow);
    memcpy(&nw, &to, sizeof nw);
    return __atomic_compare_exchange_n((uint64_t *)e, &ow, nw, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE);
}

static inline uint32_t reqrep_proc_start(ReqRepHandle *h, uint32_t pid) {
    uint32_t mask = REQREP_PROC_SLOTS - 1;
    for (uint32_t k = 0; k < REQREP_PROC_SLOTS; k++) {
        ReqRepProc r = reqrep_proc_load(&h->procs[(pid + k) & mask]);
        if (r.pid == pid) return r.start;
        if (!r.pid) return 0;
    }
    return 0;
}

/* Dead and reaped: what kill() alone can tell, without telling zombies or reused pids apart. */
static inline int reqrep_pid_gone(uint32_t pid) {
    return pid == 0 || (kill((pid_t)pid, 0) == -1 && errno == ESRCH);
}

/* Dead, a zombie, or a pid now held by another process than the one that used the channel. */
static inline int reqrep_pid_alive(ReqRepHandle *h, uint32_t pid) {
    if (reqrep_pid_gone(pid)) return 0;
    uint32_t start, known;
    int st = reqrep_proc_stat(pid, &start);
    if (st == 0) return 0;
    known = st > 0 ? reqrep_proc_start(h, pid) : 0;
    return !known || known == REQREP_START_RELEASING || known == start;
}

/* Can a record go? Only when no process has its pid now: a record naming a live pid with another
 * start is what tells the dead process apart from the live one, which may be about to register. */
static inline int reqrep_record_dead(ReqRepProc r) {
    if (reqrep_pid_gone(r.pid)) return 1;
    uint32_t now;
    return reqrep_proc_stat(r.pid, &now) == 0;
}

static const struct timespec reqrep_lock_timeout = { REQREP_LOCK_TIMEOUT_SEC, 0 };

/* SYS_futex takes the kernel's long-based timespec, narrower than time_t on 32-bit time64 ABIs. */
static inline long reqrep_futex_wait(uint32_t *addr, uint32_t val, const struct timespec *ts) {
#if !(defined(__x86_64__) && defined(__ILP32__))
    if (ts && sizeof(ts->tv_sec) > sizeof(long)) {
        struct { long tv_sec, tv_nsec; } k = { (long)ts->tv_sec, ts->tv_nsec };
        return syscall(SYS_futex, addr, FUTEX_WAIT, val, &k, NULL, 0);
    }
#endif
    return syscall(SYS_futex, addr, FUTEX_WAIT, val, ts, NULL, 0);
}

/* fork() resets these in the child. */
static uint32_t reqrep_start_cache;
static uint32_t reqrep_pid_cache;

static void reqrep_pid_forget(void) { __atomic_store_n(&reqrep_pid_cache, 0, __ATOMIC_RELAXED); __atomic_store_n(&reqrep_start_cache, 0, __ATOMIC_RELAXED); }

static void reqrep_pid_watch_forks(void) { pthread_atfork(NULL, NULL, reqrep_pid_forget); }

static inline uint32_t reqrep_self_pid(void) {
    uint32_t pid = __atomic_load_n(&reqrep_pid_cache, __ATOMIC_RELAXED);
    if (!pid) {
        static pthread_once_t once = PTHREAD_ONCE_INIT;
        pthread_once(&once, reqrep_pid_watch_forks);
        pid = (uint32_t)getpid();
        __atomic_store_n(&reqrep_pid_cache, pid, __ATOMIC_RELAXED);
    }
    return pid;
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

static inline uint64_t reqrep_now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (uint64_t)t.tv_sec * 1000000000ULL + (uint64_t)t.tv_nsec;
}

static inline void reqrep_make_deadline(double timeout, struct timespec *deadline) {
    clock_gettime(CLOCK_MONOTONIC, deadline);
    if (!(timeout < 1e9)) timeout = 1e9; /* Inf/NaN/huge: the time_t cast would be UB */
    deadline->tv_sec += (time_t)timeout;
    deadline->tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1e9);
    if (deadline->tv_nsec >= 1000000000L) {
        deadline->tv_sec++;
        deadline->tv_nsec -= 1000000000L;
    }
}

static inline double reqrep_time_left(const struct timespec *deadline) {
    struct timespec left;
    if (!reqrep_remaining_time(deadline, &left)) return 1e-9;
    return (double)left.tv_sec + (double)left.tv_nsec / 1e9;
}

/* A waiter count: [epoch:32][count:32]. A waiter takes back its registration only in the epoch
 * it registered in, so a new epoch forgets the registrations of waiters that died parked. */
#define REQREP_WAITERS(w)      ((uint32_t)(w))
/* Wakes in a row that find nobody parked, with the count unchanged, before a waker starts a new
 * epoch. Live waiters keep changing the count; one left by the dead stays put. */
#define REQREP_STALE_WAKES     8

static inline uint32_t reqrep_waiters_add(uint64_t *word) {
    return (uint32_t)(__atomic_add_fetch(word, 1, __ATOMIC_ACQ_REL) >> 32);
}

static inline void reqrep_waiters_sub(uint64_t *word, uint32_t epoch) {
    uint64_t w = __atomic_load_n(word, __ATOMIC_ACQUIRE);
    while ((uint32_t)(w >> 32) == epoch && REQREP_WAITERS(w)
            && !__atomic_compare_exchange_n(word, &w, w - 1, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {}
}

/* Start a new epoch unless the count moved since `seen`. A live waiter of the old epoch either
 * parked before this wake-all or parks on a futex value already bumped, so none sleeps uncounted. */
static inline void reqrep_waiters_forget(uint32_t *futex_word, uint64_t *waiters, uint64_t seen) {
    if (!__atomic_compare_exchange_n(waiters, &seen, (uint64_t)((uint32_t)(seen >> 32) + 1) << 32,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    __atomic_add_fetch(futex_word, 1, __ATOMIC_RELEASE);
    syscall(SYS_futex, futex_word, FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* Called after the caller changed shared state: the fence publishes that change before the count
 * is read, so a waiter registering concurrently is not missed. */
static inline void reqrep_wake(uint32_t *futex_word, uint64_t *waiters, int n, ReqRepWakeMemo *memo) {
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    uint64_t w = __atomic_load_n(waiters, __ATOMIC_RELAXED);
    if (!REQREP_WAITERS(w)) return;
    __atomic_add_fetch(futex_word, 1, __ATOMIC_RELEASE);
    if (syscall(SYS_futex, futex_word, FUTEX_WAKE, n, NULL, NULL, 0) != 0) { memo->misses = 0; return; }
    if (w != memo->seen) { memo->seen = w; memo->misses = 1; return; }
    if (++memo->misses < REQREP_STALE_WAKES) return;
    memo->misses = 0;
    reqrep_waiters_forget(futex_word, waiters, w);
}

static inline void reqrep_wake_consumers(ReqRepHandle *h) {
    reqrep_wake(&h->hdr->recv_futex, &h->hdr->recv_waiters, 1, &h->recv_wake);
}

static inline void reqrep_wake_producers(ReqRepHandle *h, uint32_t n) {
    /* One woken sender may be refused by a reservation and never pass the wakeup on. */
    if (n && __atomic_load_n(&h->hdr->arena_reserved, __ATOMIC_RELAXED)) n = INT_MAX;
    if (n) reqrep_wake(&h->hdr->send_futex, &h->hdr->send_waiters, n > INT_MAX ? INT_MAX : (int)n, &h->send_wake);
}

static inline void reqrep_wake_slot_waiters(ReqRepHandle *h) {
    reqrep_wake(&h->hdr->slot_futex, &h->hdr->slot_waiters, 1, &h->slot_wake);
}

/* For clear(), which frees many slots at once. */
static inline void reqrep_broadcast(uint32_t *futex_word, uint64_t *waiters) {
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    uint64_t w = __atomic_load_n(waiters, __ATOMIC_RELAXED);
    if (!REQREP_WAITERS(w)) return;
    __atomic_add_fetch(futex_word, 1, __ATOMIC_RELEASE);
    if (syscall(SYS_futex, futex_word, FUTEX_WAKE, INT_MAX, NULL, NULL, 0) == 0)
        reqrep_waiters_forget(futex_word, waiters, w);
}

static inline void reqrep_recover_stale_mutex(ReqRepHandle *h, uint32_t observed) {
    if (!__atomic_compare_exchange_n(&h->hdr->mutex, &observed, 0,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        return;
    __atomic_add_fetch(&h->hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    reqrep_wake(&h->hdr->mutex_futex, &h->hdr->mutex_waiters, 1, &h->mutex_wake);
}

static void reqrep_proc_register(ReqRepHandle *h);
static inline int reqrep_receiver_dead(ReqRepHandle *h, uint32_t pid, uint64_t now);

/* Lock by deadline, or when that is NULL, within timeout of parking: a negative timeout waits as
 * long as the holder lives, and 0 (a non-blocking caller) waits out one lock timeout at most.
 * Returns 1 once locked, 0 when the time is up or a signal ends a non-blocking wait, or
 * REQREP_EINTR on a signal otherwise. */
static int reqrep_mutex_lock_until(ReqRepHandle *h, const struct timespec *deadline, double timeout) {
    reqrep_proc_register(h);
    ReqRepHeader *hdr = h->hdr;
    uint32_t mypid = REQREP_MUTEX_VAL(reqrep_self_pid());
    struct timespec by, remaining;
    for (int spin = 0; ; spin++) {
        uint32_t expected = 0;
        if (__atomic_compare_exchange_n(&hdr->mutex, &expected, mypid,
                1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED))
            return 1;
        if (__builtin_expect(spin < REQREP_SPIN_LIMIT, 1)) {
            reqrep_spin_pause();
            continue;
        }
        if (timeout != 0 && REQREP_INTERRUPTED(h)) return REQREP_EINTR;
        if (!deadline && timeout >= 0) {
            reqrep_make_deadline(timeout > 0 ? timeout : REQREP_LOCK_TIMEOUT_SEC, &by);
            deadline = &by;
        }
        const struct timespec *pts = &reqrep_lock_timeout;
        if (deadline) {
            if (!reqrep_remaining_time(deadline, &remaining)) return 0;
            if (remaining.tv_sec < REQREP_LOCK_TIMEOUT_SEC) pts = &remaining;
        }
        uint32_t fseq = __atomic_load_n(&hdr->mutex_futex, __ATOMIC_ACQUIRE);
        uint32_t epoch = reqrep_waiters_add(&hdr->mutex_waiters);
        /* StoreLoad barrier: an unlocker either sees our registration (and wakes us) or we see
         * the unlock here and retry without sleeping. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        int err = 0;
        if (__atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED) != 0) {
            long rc = reqrep_futex_wait(&hdr->mutex_futex, fseq, pts);
            if (rc == -1) err = errno;
        }
        reqrep_waiters_sub(&hdr->mutex_waiters, epoch);
        if (err == ETIMEDOUT || err == EINTR) {
            uint32_t val = __atomic_load_n(&hdr->mutex, __ATOMIC_RELAXED);
            uint32_t pid = val & REQREP_MUTEX_PID_MASK;
            /* Signals a tick apart would otherwise keep the holder from ever being looked at. */
            if (val >= REQREP_MUTEX_WRITER_BIT
                    && (err == ETIMEDOUT ? !reqrep_pid_alive(h, pid) : reqrep_receiver_dead(h, pid, reqrep_now_ns())))
                reqrep_recover_stale_mutex(h, val);
        }
        /* A non-blocking caller gives up rather than park again: Perl dies once 120 signals pile up. */
        if (err == EINTR) return timeout != 0 ? REQREP_EINTR : 0;
        spin = 0;
    }
}

static inline void reqrep_mutex_unlock(ReqRepHandle *h) {
    __atomic_store_n(&h->hdr->mutex, 0, __ATOMIC_RELEASE);
    reqrep_wake(&h->hdr->mutex_futex, &h->hdr->mutex_waiters, 1, &h->mutex_wake);
}

/* Every transition is one CAS on the whole ctl word: a stale reading or a stale id never moves a slot. */
static inline int reqrep_ctl_cas(RespSlotHeader *slot, uint64_t expected, uint64_t desired) {
    return __atomic_compare_exchange_n(&slot->ctl, &expected, desired,
            0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
}

/* The low half of ctl: it changes with every transition. */
static inline uint32_t *reqrep_slot_futex(RespSlotHeader *slot) {
#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    return (uint32_t *)&slot->ctl + 1;
#else
    return (uint32_t *)&slot->ctl;
#endif
}

/* Only callers parked for this generation's reply count, so ones that died parked cost wakes
 * for the rest of their own generation at most. */
static inline void reqrep_slot_wake(RespSlotHeader *slot, uint32_t gen) {
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    uint64_t w = __atomic_load_n(&slot->waiters, __ATOMIC_RELAXED);
    if ((uint32_t)(w >> 32) == gen && REQREP_WAITERS(w))
        syscall(SYS_futex, reqrep_slot_futex(slot), FUTEX_WAKE, INT_MAX, NULL, NULL, 0);
}

/* Register for gen's reply, restarting the count from an older generation's. 0 once the slot has
 * moved past gen: its waiters may already be counting. */
static inline int reqrep_slot_waiters_add(RespSlotHeader *slot, uint32_t gen) {
    uint64_t w = __atomic_load_n(&slot->waiters, __ATOMIC_ACQUIRE);
    for (;;) {
        int same = (uint32_t)(w >> 32) == gen;
        if (!same && REQREP_CTL_GEN(__atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE)) != gen) return 0;
        if (__atomic_compare_exchange_n(&slot->waiters, &w, same ? w + 1 : ((uint64_t)gen << 32) | 1,
                0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE))
            return 1;
    }
}

static inline void reqrep_slot_waiters_sub(RespSlotHeader *slot, uint32_t gen) {
    reqrep_waiters_sub(&slot->waiters, gen);
}

static inline void reqrep_slot_free(ReqRepHandle *h, RespSlotHeader *slot, uint32_t gen);

/* Generation 0 on slot 0 would make an id of 0, which means no request. */
static inline uint32_t reqrep_next_gen(uint32_t gen) {
    return gen == UINT32_MAX ? 1 : gen + 1;
}

/* Pids one scan remembers the liveness of, as many as the registry holds: each probe reads /proc. */
#define REQREP_SCAN_MEMO_BITS  10
#define REQREP_SCAN_MEMO       (1u << REQREP_SCAN_MEMO_BITS)
#define REQREP_SCAN_PROBES     32

typedef struct {
    uint32_t pid[REQREP_SCAN_MEMO];
    uint8_t  alive[REQREP_SCAN_MEMO];
} ReqRepScanMemo;

static inline int reqrep_scan_alive(ReqRepHandle *h, ReqRepScanMemo *m, uint32_t pid) {
    if (!pid) return 0;
    uint32_t i = (pid * 2654435761u) >> (32 - REQREP_SCAN_MEMO_BITS);
    for (uint32_t k = 0; k < REQREP_SCAN_PROBES; k++, i = (i + 1) & (REQREP_SCAN_MEMO - 1)) {
        if (m->pid[i] == pid) return m->alive[i];
        if (!m->pid[i]) {
            m->pid[i] = pid;
            return m->alive[i] = (uint8_t)reqrep_pid_alive(h, pid);
        }
    }
    return reqrep_pid_alive(h, pid);
}

/* Take a free slot, or one whose named process is dead, in one CAS. */
static int32_t reqrep_slot_acquire(ReqRepHandle *h, uint32_t *out_gen) {
    reqrep_proc_register(h);
    uint32_t n = h->resp_slots;
    uint32_t hint = __atomic_load_n(&h->hdr->resp_hint, __ATOMIC_RELAXED);
    uint32_t mypid = reqrep_self_pid();
    uint32_t tag = h->tag | (h->ready_sock >= 0 && h->ready_pid == mypid ? REQREP_TAG_NOTIFY : 0);

    for (uint32_t i = 0; i < n; i++) {
        uint32_t idx = (hint + i) % n;
        RespSlotHeader *slot = reqrep_resp_slot(h, idx);
        uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
        uint32_t gen = reqrep_next_gen(REQREP_CTL_GEN(c));
        if (REQREP_CTL_STATE(c) != RESP_FREE || !reqrep_ctl_cas(slot, c, REQREP_CTL(gen, mypid, RESP_ACQUIRED)))
            continue;
        __atomic_store_n(&slot->owner, mypid, __ATOMIC_RELAXED);
        __atomic_store_n(&slot->owner_tag, tag, __ATOMIC_RELAXED);
        h->inflight++;
        __atomic_store_n(&h->hdr->resp_hint, (idx + 1) % n, __ATOMIC_RELAXED);
        *out_gen = gen;
        return (int32_t)idx;
    }

    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    uint64_t now_ns = (uint64_t)now.tv_sec * 1000000000ULL + (uint64_t)now.tv_nsec;
    if (h->last_scan_ns && now_ns - h->last_scan_ns < REQREP_RECOVERY_INTERVAL_NS) return -1;

    /* Once a dead holder turns up, keep going and free its other slots, so the sends after us
     * need no scan. */
    ReqRepScanMemo memo = {0};
    uint32_t taken_gen = 0;
    int32_t taken = -1;
    for (uint32_t i = 0; i < n; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
        uint32_t state = REQREP_CTL_STATE(c);
        uint32_t gen = REQREP_CTL_GEN(c);
        uint32_t next = reqrep_next_gen(gen);
        if (state == RESP_FREE) {
            if (taken >= 0 || !reqrep_ctl_cas(slot, c, REQREP_CTL(next, mypid, RESP_ACQUIRED)))
                continue;
            __atomic_store_n(&slot->owner, mypid, __ATOMIC_RELAXED);
            __atomic_store_n(&slot->owner_tag, tag, __ATOMIC_RELAXED);
            h->inflight++;
            *out_gen = next;
            return (int32_t)i;
        }
        if (state > RESP_ABANDONED) continue;
        uint32_t owner = __atomic_load_n(&slot->owner, __ATOMIC_RELAXED);
        if (reqrep_scan_alive(h, &memo, REQREP_CTL_PID(c))
                && (state != RESP_DISPATCHED || reqrep_scan_alive(h, &memo, owner)))
            continue;
        if (taken < 0) {
            if (!reqrep_ctl_cas(slot, c, REQREP_CTL(next, mypid, RESP_ACQUIRED))) continue;
            __atomic_store_n(&slot->owner, mypid, __ATOMIC_RELAXED);
            __atomic_store_n(&slot->owner_tag, tag, __ATOMIC_RELAXED);
            h->inflight++;
            reqrep_slot_wake(slot, gen);
            taken = (int32_t)i;
            taken_gen = next;
        } else {
            if (!reqrep_ctl_cas(slot, c, REQREP_CTL(gen, 0, RESP_FREE))) continue;
            reqrep_slot_free(h, slot, gen);
        }
        __atomic_add_fetch(&h->hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    }
    if (taken >= 0) {
        *out_gen = taken_gen;
        return taken;
    }

    /* Throttle from the end of a fruitless scan: one can outlast the interval by itself. */
    clock_gettime(CLOCK_MONOTONIC, &now);
    h->last_scan_ns = (uint64_t)now.tv_sec * 1000000000ULL + (uint64_t)now.tv_nsec;
    return -1;
}

static inline void reqrep_slot_free(ReqRepHandle *h, RespSlotHeader *slot, uint32_t gen) {
    reqrep_slot_wake(slot, gen);
    reqrep_wake_slot_waiters(h);
}

/* This handle ended one of its own requests: owner and tag were read before the CAS that ended it. */
static inline void reqrep_inflight_end(ReqRepHandle *h, uint32_t owner, uint32_t tag) {
    if (h->inflight && owner == reqrep_self_pid() && (tag & ~REQREP_TAG_NOTIFY) == h->tag) h->inflight--;
}

static void reqrep_unmarked_forget(ReqRepHandle *h, uint32_t slot, uint32_t gen) {
    for (int i = 0; i < REQREP_UNMARKED_MEMO; i++) {
        ReqRepUnmarked *u = &h->unmarked[i];
        if (u->since_ns && u->slot == slot && u->gen == gen) {
            u->since_ns = 0;
            h->unmarked_used--;
            return;
        }
    }
}

/* Give up on id. A reply already READY is left for the caller to drain; one still being written
 * by a live responder is marked ABANDONED, and that responder frees the slot. */
static void reqrep_cancel(ReqRepHandle *h, uint64_t id) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return;
    if (h->unmarked_used) reqrep_unmarked_forget(h, slot_idx, gen);
    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    for (int tries = 0; tries < REQREP_CANCEL_RETRIES; tries++) {
        uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
        uint32_t state = REQREP_CTL_STATE(c);
        uint64_t want = REQREP_CTL(gen, 0, RESP_FREE);
        if (REQREP_CTL_GEN(c) != gen) return;
        if (state == RESP_WRITING || state == RESP_ABANDONED) {
            if (reqrep_pid_alive(h, REQREP_CTL_PID(c))) {
                if (state == RESP_ABANDONED) return;
                want = REQREP_CTL(gen, REQREP_CTL_PID(c), RESP_ABANDONED);
            }
        } else if (state != RESP_ACQUIRED && state != RESP_DISPATCHED) {
            return;
        }
        uint32_t owner = __atomic_load_n(&slot->owner, __ATOMIC_RELAXED), otag = __atomic_load_n(&slot->owner_tag, __ATOMIC_RELAXED);
        if (reqrep_ctl_cas(slot, c, want)) {
            if (state != RESP_ABANDONED) reqrep_inflight_end(h, owner, otag);
            if (REQREP_CTL_STATE(want) == RESP_FREE) reqrep_slot_free(h, slot, gen);
            else reqrep_slot_wake(slot, gen);
            return;
        }
    }
}

/* 1 if the reply for gen is ready, 0 if one may still come, -4 if none will. */
static inline int reqrep_slot_readable(uint64_t c, uint32_t gen) {
    if (REQREP_CTL_GEN(c) != gen) return -4;
    uint32_t state = REQREP_CTL_STATE(c);
    if (state == RESP_READY) return 1;
    return state == RESP_ACQUIRED || state == RESP_DISPATCHED || state == RESP_WRITING ? 0 : -4;
}

/* Free a READY slot read as c. Nothing writes into a READY slot, so success also proves
 * the bytes copied out were one whole reply. */
static inline int reqrep_slot_take_reply(ReqRepHandle *h, RespSlotHeader *slot, uint64_t c) {
    uint32_t owner = __atomic_load_n(&slot->owner, __ATOMIC_RELAXED), otag = __atomic_load_n(&slot->owner_tag, __ATOMIC_RELAXED);
    if (!reqrep_ctl_cas(slot, c, REQREP_CTL(REQREP_CTL_GEN(c), 0, RESP_FREE))) return 0;
    reqrep_inflight_end(h, owner, otag);
    reqrep_slot_free(h, slot, REQREP_CTL_GEN(c));
    return 1;
}

static void reqrep_drop_reply(ReqRepHandle *h, uint64_t id) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    if (slot_idx >= h->resp_slots) return;
    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
    if (reqrep_slot_readable(c, REQREP_ID_GEN(id)) == 1) reqrep_slot_take_reply(h, slot, c);
}

/* Mark id's slot as received by this process. */
static inline void reqrep_slot_dispatch(ReqRepHandle *h, uint64_t id) {
    reqrep_proc_register(h);
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return;
    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint32_t mypid = reqrep_self_pid();
    /* The reply will notify its owner: open the socket now, before a full descriptor table can refuse it. */
    if (h->notify_sock < 0 && (__atomic_load_n(&slot->owner_tag, __ATOMIC_ACQUIRE) & REQREP_TAG_NOTIFY))
        h->notify_sock = socket(AF_UNIX, SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);
    for (int tries = 0; tries < REQREP_CANCEL_RETRIES; tries++) {
        uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
        if (REQREP_CTL_GEN(c) != gen || REQREP_CTL_STATE(c) != RESP_ACQUIRED) return;
        if (reqrep_ctl_cas(slot, c, REQREP_CTL(gen, mypid, RESP_DISPATCHED))) return;
    }
}

/* Only the word this process dispatched matches, never a stale or duplicate id. */
static inline int reqrep_slot_take_write(RespSlotHeader *slot, uint32_t gen, uint32_t mypid,
                                         uint32_t *owner) {
    uint64_t c = REQREP_CTL(gen, mypid, RESP_DISPATCHED);
    if (__atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE) != c) return 0;
    *owner = __atomic_load_n(&slot->owner, __ATOMIC_RELAXED);
    return reqrep_ctl_cas(slot, c, REQREP_CTL(gen, mypid, RESP_WRITING));
}

/* The abstract socket a client listens on for replies to its requests. */
static socklen_t reqrep_ready_addr(ReqRepHandle *h, uint32_t pid, uint32_t tag, struct sockaddr_un *addr) {
    memset(addr, 0, sizeof *addr);
    addr->sun_family = AF_UNIX;
    int n = snprintf(addr->sun_path + 1, sizeof(addr->sun_path) - 1, "reqrep-%016llx-%u-%x",
                     (unsigned long long)h->hdr->channel_id, (unsigned)pid, (unsigned)(tag & ~REQREP_TAG_NOTIFY));
    return (socklen_t)(offsetof(struct sockaddr_un, sun_path) + 1 + (size_t)n);
}

static inline uint32_t *reqrep_lost_counter(ReqRepHandle *h, uint32_t pid, uint32_t tag) {
    uint32_t k = pid * 2654435761u ^ (tag & ~REQREP_TAG_NOTIFY) * 0x85EBCA6Bu;
    return &h->lost[k >> (32 - REQREP_LOST_BITS)];
}

static void reqrep_notify_owner(ReqRepHandle *h, uint64_t id, uint32_t pid, uint32_t tag) {
    struct sockaddr_un addr;
    socklen_t len = reqrep_ready_addr(h, pid, tag, &addr);
    /* Datagrams any client has yet to read count against the sending socket's buffer, so only
     * a fresh socket's refusal shows that this client's own queue is full. */
    for (int fresh = 0; ; ) {
        if (h->notify_sock < 0) {
            h->notify_sock = socket(AF_UNIX, SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);
            if (h->notify_sock < 0) break;
            fresh = 1;
        }
        if (sendto(h->notify_sock, &id, sizeof id, MSG_DONTWAIT | MSG_NOSIGNAL, (struct sockaddr *)&addr, len) >= 0
                || (errno != EAGAIN && errno != EWOULDBLOCK && errno != ENOBUFS && errno != ENOMEM))
            return;
        if (fresh) break;
        close(h->notify_sock);
        h->notify_sock = -1;
    }
    __atomic_add_fetch(reqrep_lost_counter(h, pid, tag), 1, __ATOMIC_RELEASE);
    /* The client may have drained its queue before the count moved, leaving it nothing to wake it:
     * one more try either lands, or finds the queue unread still, which will bring the client back. */
    if (h->notify_sock >= 0)
        (void)sendto(h->notify_sock, &id, sizeof id, MSG_DONTWAIT | MSG_NOSIGNAL, (struct sockaddr *)&addr, len);
}

/* Returns 1, or -2 if the owner gave up meanwhile, in which case the slot is freed. */
static int reqrep_slot_publish(ReqRepHandle *h, RespSlotHeader *slot, uint32_t gen,
                               uint32_t owner, uint32_t mypid) {
    if (reqrep_ctl_cas(slot, REQREP_CTL(gen, mypid, RESP_WRITING), REQREP_CTL(gen, owner, RESP_READY))) {
        reqrep_slot_wake(slot, gen);
        uint32_t tag = __atomic_load_n(&slot->owner_tag, __ATOMIC_ACQUIRE);
        if (tag & REQREP_TAG_NOTIFY) {
            uint32_t idx = (uint32_t)(((uint8_t *)slot - h->resp_area) / h->resp_stride);
            reqrep_notify_owner(h, REQREP_MAKE_ID(idx, gen), owner, tag);
        }
        __atomic_add_fetch(&h->hdr->stat_replies, 1, __ATOMIC_RELAXED);
        return 1;
    }
    if (reqrep_ctl_cas(slot, REQREP_CTL(gen, mypid, RESP_ABANDONED), REQREP_CTL(gen, 0, RESP_FREE)))
        reqrep_slot_free(h, slot, gen);
    return -2;
}

/* Is the receiver or mutex holder a wait depends on dead? Zombies and reused pids take a /proc read,
 * which every wait would pay: one found alive is looked at once a tick at most, the memo's worth a
 * tick in all however many there are, and none in a handle's first tick. */
static inline int reqrep_receiver_dead(ReqRepHandle *h, uint32_t pid, uint64_t now) {
    ReqRepProbe *p = NULL, *oldest = &h->probe[0];
    for (int i = 0; i < REQREP_PROBE_MEMO && !p; i++) {
        if (h->probe[i].pid == pid) p = &h->probe[i];
        else if (h->probe[i].when_ns < oldest->when_ns) oldest = &h->probe[i];
    }
    uint64_t since = p ? p->when_ns : h->born_ns;
    if (now - since < REQREP_TICK_NS) return reqrep_pid_gone(pid);
    if (!p) {
        if (now - oldest->when_ns < REQREP_TICK_NS) return reqrep_pid_gone(pid);
        p = oldest;
    }
    p->pid = pid;
    int dead = !reqrep_pid_alive(h, pid);
    /* A dead verdict is not kept: the next wait on that pid looks again. */
    p->when_ns = dead ? 0 : now;
    return dead;
}

/* Since when this handle has seen (slot, gen) taken but unmarked: now for a first sighting, 0 when
 * every entry still names a request in that state. */
static uint64_t reqrep_unmarked_since(ReqRepHandle *h, uint32_t slot, uint32_t gen, uint64_t now) {
    ReqRepUnmarked *room = NULL;
    for (int i = 0; i < REQREP_UNMARKED_MEMO; i++) {
        ReqRepUnmarked *u = &h->unmarked[i];
        if (u->since_ns && u->slot == slot && u->gen == gen) return u->since_ns;
        if (room) continue;
        if (!u->since_ns) {
            room = u;
        } else {
            /* An entry whose slot has moved on is free again. */
            uint64_t c = __atomic_load_n(&reqrep_resp_slot(h, u->slot)->ctl, __ATOMIC_ACQUIRE);
            if (REQREP_CTL_GEN(c) != u->gen || REQREP_CTL_STATE(c) != RESP_ACQUIRED) room = u;
        }
    }
    if (!room) return 0;
    if (!room->since_ns) h->unmarked_used++;
    room->slot = slot;
    room->gen = gen;
    room->since_ns = now;
    return now;
}

/* Wait until the reply to id is ready: 1, 0 on timeout, -4 if none will come, or REQREP_EINTR.
 * Its clocks live in the handle, so waits resumed after a signal, or for another id, count on. */
static int reqrep_await_reply(ReqRepHandle *h, uint64_t id, const struct timespec *deadline) {
    RespSlotHeader *slot = reqrep_resp_slot(h, REQREP_ID_SLOT(id));
    uint32_t gen = REQREP_ID_GEN(id);
    struct timespec remaining;
    uint64_t now = reqrep_now_ns();
    for (;;) {
        uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
        int r = reqrep_slot_readable(c, gen);
        if (r != 0) {
            if (h->unmarked_used) reqrep_unmarked_forget(h, REQREP_ID_SLOT(id), gen);
            return r;
        }
        if ((REQREP_CTL_STATE(c) == RESP_DISPATCHED || REQREP_CTL_STATE(c) == RESP_WRITING)
                && reqrep_receiver_dead(h, REQREP_CTL_PID(c), now)) {
            reqrep_cancel(h, id);
            return reqrep_slot_readable(__atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE), gen) == 1 ? 1 : -4;
        }
        /* Taken off the queue yet still unmarked two ticks on: its receiver died between the two.
         * Timed per request, since a client may wait for several such replies in turn. */
        if (REQREP_CTL_STATE(c) != RESP_ACQUIRED
                || __atomic_load_n(&h->hdr->req_head, __ATOMIC_ACQUIRE) <= __atomic_load_n(&slot->claim_pos, __ATOMIC_ACQUIRE)) {
            if (h->unmarked_used) reqrep_unmarked_forget(h, REQREP_ID_SLOT(id), gen);
        } else {
            uint64_t since = reqrep_unmarked_since(h, REQREP_ID_SLOT(id), gen, now);
            if (since && now - since >= 2 * REQREP_TICK_NS) {
                reqrep_cancel(h, id);
                return reqrep_slot_readable(__atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE), gen) == 1 ? 1 : -4;
            }
        }

        if (REQREP_INTERRUPTED(h)) return REQREP_EINTR;
        if (!reqrep_slot_waiters_add(slot, gen)) continue;
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        if (__atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE) != c) {
            reqrep_slot_waiters_sub(slot, gen);
            continue;
        }
        /* A receiver that dies wakes nobody: look again every tick. */
        struct timespec tick = { REQREP_LOCK_TIMEOUT_SEC, 0 };
        struct timespec *pts = &tick;
        if (deadline) {
            if (!reqrep_remaining_time(deadline, &remaining)) {
                reqrep_slot_waiters_sub(slot, gen);
                return 0;
            }
            if (remaining.tv_sec < tick.tv_sec) pts = &remaining;
        }
        long rc = reqrep_futex_wait(reqrep_slot_futex(slot), (uint32_t)c, pts);
        int err = rc == -1 ? errno : 0;
        reqrep_slot_waiters_sub(slot, gen);
        now = reqrep_now_ns();
        if (err == EINTR
                && reqrep_slot_readable(__atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE), gen) == 0)
            return REQREP_EINTR;
    }
}

/* Reset every slot past its request. An ACQUIRED one is still its sender's to fill (the caller
 * cancels the requests it discards); a reply still being written is left to its live responder
 * as ABANDONED. */
static void reqrep_clear_slots(ReqRepHandle *h) {
    for (uint32_t i = 0; i < h->resp_slots; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        for (int tries = 0; tries < REQREP_CANCEL_RETRIES; tries++) {
            uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
            uint32_t state = REQREP_CTL_STATE(c);
            uint64_t want = REQREP_CTL(REQREP_CTL_GEN(c), 0, RESP_FREE);
            if (state == RESP_FREE || state == RESP_ACQUIRED) break;
            if ((state == RESP_WRITING || state == RESP_ABANDONED)
                    && reqrep_pid_alive(h, REQREP_CTL_PID(c))) {
                if (state == RESP_ABANDONED) break;
                want = REQREP_CTL(REQREP_CTL_GEN(c), REQREP_CTL_PID(c), RESP_ABANDONED);
            }
            if (reqrep_ctl_cas(slot, c, want)) {
                reqrep_slot_wake(slot, REQREP_CTL_GEN(c));
                break;
            }
        }
    }
}

#define REQREP_ERR(fmt, ...) do { if (errbuf) snprintf(errbuf, REQREP_ERR_BUFLEN, fmt, ##__VA_ARGS__); } while(0)

static void reqrep_proc_register(ReqRepHandle *h);

static uint64_t reqrep_random64(void) {
    uint64_t v = 0;
#ifdef SYS_getrandom
    if (syscall(SYS_getrandom, &v, sizeof v, 1 /* GRND_NONBLOCK */) != (long)sizeof v)
#endif
    {
        struct timespec t;
        clock_gettime(CLOCK_REALTIME, &t);
        v = ((uint64_t)t.tv_sec * 1000000000ULL + (uint64_t)t.tv_nsec) ^ ((uint64_t)getpid() << 40);
    }
    return v;
}

/* Tags start at a random point in each process, so a reused pid does not bring back the name of a
 * socket that a dead client's forked children still hold. */
static uint32_t reqrep_next_tag(void) {
    static uint32_t base, base_pid, count;
    uint32_t pid = reqrep_self_pid();
    if (__atomic_load_n(&base_pid, __ATOMIC_ACQUIRE) != pid) {
        __atomic_store_n(&base, (uint32_t)reqrep_random64(), __ATOMIC_RELAXED);
        __atomic_store_n(&base_pid, pid, __ATOMIC_RELEASE);
    }
    uint32_t tag;
    do tag = (__atomic_load_n(&base, __ATOMIC_RELAXED) + __atomic_add_fetch(&count, 1, __ATOMIC_RELAXED))
            & ~REQREP_TAG_NOTIFY;
    while (!tag);
    return tag;
}

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
    h->procs         = (ReqRepProc *)((char *)base + hdr->proc_off);
    h->lost          = (uint32_t *)(h->procs + REQREP_PROC_SLOTS);
    h->path          = path ? strdup(path) : NULL;
    struct stat st;
    if (path && lstat(path, &st) == 0) {
        h->file_dev = st.st_dev;
        h->file_ino = st.st_ino;
    }
    h->notify_fd     = -1;
    h->reply_fd      = -1;
    h->backing_fd    = backing_fd;
    h->ready_sock    = -1;
    h->notify_sock   = -1;
    h->tag           = reqrep_next_tag();
    h->born_ns       = reqrep_now_ns();
    /* Now rather than on first use, which can fall between taking a request and marking it. */
    reqrep_proc_register(h);

    return h;
}

static int reqrep_env_on(const char *name) {
    const char *v = getenv(name);
    if (!v) return 0;
    while (isspace((unsigned char)*v)) v++;
    size_t n = strlen(v);
    while (n && isspace((unsigned char)v[n - 1])) n--;
    if (!n || (n == 5 && !strncasecmp(v, "false", 5)) || (n == 2 && !strncasecmp(v, "no", 2))
            || (n == 3 && !strncasecmp(v, "off", 3)))
        return 0;
    char *end;
    double x = strtod(v, &end);
    return end != v + n || x != 0;
}

/* Growing a file past RLIMIT_FSIZE raises SIGXFSZ, which kills by default: refuse with EFBIG. */
static int reqrep_ftruncate(int fd, uint64_t size) {
    struct rlimit rl;
    if (getrlimit(RLIMIT_FSIZE, &rl) == 0 && rl.rlim_cur != RLIM_INFINITY && size > (uint64_t)rl.rlim_cur) {
        errno = EFBIG;
        return -1;
    }
    return ftruncate(fd, (off_t)size);
}

/* A sparse segment would SIGBUS at the first write its filesystem cannot back. */
static int reqrep_reserve(int fd, uint64_t size) {
    if (reqrep_env_on("DATA_REQREP_SHARED_SPARSE")) return 0;
    /* Before Linux 6.11 tmpfs gives up at any pending signal and undoes the allocation, so a
     * periodic one could keep it from ever completing; SIGSTOP cannot be blocked. */
    sigset_t all, old;
    sigfillset(&all);
    pthread_sigmask(SIG_BLOCK, &all, &old);
    int e;
    do e = posix_fallocate(fd, 0, (off_t)size); while (e == EINTR);
    pthread_sigmask(SIG_SETMASK, &old, NULL);
    if (e == 0 || e == EOPNOTSUPP || e == EINVAL) return 0;
    errno = e;
    return -1;
}

typedef struct { uint64_t ino; uint32_t boot; } ReqRepProvenance;

/* This process's PID namespace and boot id. Read before a create opens anything: with the fd table
 * full, a zero stored in the header would make the file unattachable for good. */
static int reqrep_read_provenance(ReqRepProvenance *prov, char *errbuf) {
    memset(prov, 0, sizeof(*prov));
    prov->ino = reqrep_pidns_ino();
    if (!prov->ino) {
        REQREP_ERR("cannot read /proc/self/ns/pid: %s", strerror(errno));
        return reqrep_env_on("DATA_REQREP_SHARED_UNSAFE_PIDNS");
    }
    prov->boot = reqrep_boot_id_hash();
    if (!prov->boot) {
        REQREP_ERR("cannot read /proc/sys/kernel/random/boot_id: %s", strerror(errno));
        return reqrep_env_on("DATA_REQREP_SHARED_UNSAFE_PIDNS");
    }
    return 1;
}

/* Stored PIDs are resolved in the caller's namespace: a peer from another PID namespace or boot
 * would read live processes as dead and steal their slots. */
static int reqrep_check_provenance(ReqRepHeader *hdr, char *errbuf) {
    if (reqrep_env_on("DATA_REQREP_SHARED_UNSAFE_PIDNS")) return 1;

    ReqRepProvenance prov;
    if (!reqrep_read_provenance(&prov, errbuf)) return 0;
    if (!hdr->pidns_ino || !hdr->boot_id_hash) {
        REQREP_ERR("this file records no PID namespace or boot id (/proc was unreadable "
                   "when it was created); set DATA_REQREP_SHARED_UNSAFE_PIDNS=1 to attach anyway");
        return 0;
    }
    uint64_t ino  = prov.ino;
    uint32_t boot = prov.boot;
    if (hdr->boot_id_hash != boot) {
        REQREP_ERR("this file was created before the current boot or on another host; its stored "
                   "PIDs name unrelated processes here -- unless another host uses it, remove it and recreate");
        return 0;
    }
    if (hdr->pidns_ino != ino) {
        REQREP_ERR("this segment belongs to a different PID namespace; peers must "
                   "share one (docker --pid=container:NAME, Kubernetes "
                   "shareProcessNamespace: true)");
        return 0;
    }
    return 1;
}

/* O_EXCL stops a squatter only until the EEXIST fallback opens its file. */
static int reqrep_check_attach(ReqRepHeader *hdr, const struct stat *st,
                               const char *path, char *errbuf) {
    if (st->st_uid != geteuid() && (st->st_mode & S_IWOTH)) {
        REQREP_ERR("%s: refusing a world-writable file owned by another user", path);
        return 0;
    }
    return reqrep_check_provenance(hdr, errbuf);
}

/* Any process that can open the file can hold its lock for ever: fail rather than hang. */
static int reqrep_flock_timed(int fd, int op) {
    struct timespec deadline, remaining, tick = { 0, 1000000L };
    reqrep_make_deadline(REQREP_LOCK_TIMEOUT_SEC * 5, &deadline);
    for (;;) {
        if (flock(fd, op | LOCK_NB) == 0) return 0;
        if (errno != EWOULDBLOCK && errno != EINTR) return -1;
        if (!reqrep_remaining_time(&deadline, &remaining)) { errno = ETIMEDOUT; return -1; }
        nanosleep(&tick, NULL);
    }
}

static const char *reqrep_flock_strerror(int err) {
    return err == ETIMEDOUT ? "timed out waiting for the lock" : strerror(err);
}

/* An upgrade leaves channel files of another format behind: say so rather than call them invalid. */
static const char *reqrep_header_refusal(const void *base, char *buf, size_t len, const char *redo) {
    const ReqRepHeader *hdr = (const ReqRepHeader *)base;
    if (hdr->magic == REQREP_MAGIC && hdr->version != REQREP_VERSION)
        snprintf(buf, len, "made by another version of this module (format %u, this one reads %u); "
                 "%s", (unsigned)hdr->version, (unsigned)REQREP_VERSION, redo);
    else
        snprintf(buf, len, "invalid or incompatible reqrep file");
    return buf;
}

static int reqrep_validate_header(ReqRepHeader *hdr, size_t file_size, uint32_t expected_mode) {
    if (hdr->magic != REQREP_MAGIC) return 0;
    if (hdr->version != REQREP_VERSION) return 0;
    if (hdr->mode != expected_mode) return 0;
    if (hdr->req_cap < 2 || (hdr->req_cap & (hdr->req_cap - 1)) != 0) return 0;
    if (hdr->total_size != (uint64_t)file_size) return 0;
    if (hdr->req_slots_off != sizeof(ReqRepHeader)) return 0;
    if (hdr->resp_slots == 0 || hdr->resp_slots > INT32_MAX) return 0;
    if (hdr->resp_stride < sizeof(RespSlotHeader)) return 0;
    if ((uint64_t)hdr->resp_stride < (uint64_t)sizeof(RespSlotHeader) + hdr->resp_data_max) return 0;
    /* Int stores an int64 per slot unconditionally, and both offsets carry
     * atomics that fault unaligned on aarch64. */
    if (expected_mode == REQREP_MODE_INT && hdr->resp_data_max < sizeof(int64_t)) return 0;
    if (hdr->resp_off % 8 != 0 || hdr->resp_stride % 8 != 0) return 0;
    uint64_t req_slot_size = (expected_mode == REQREP_MODE_STR)
                           ? sizeof(ReqSlot) : sizeof(ReqIntSlot);
    uint64_t req_slots_end = (uint64_t)hdr->req_slots_off
                           + (uint64_t)hdr->req_cap * req_slot_size;
    if (req_slots_end > hdr->total_size) return 0;
    if (expected_mode == REQREP_MODE_STR) {
        if (hdr->req_arena_off < req_slots_end) return 0;
        if ((uint64_t)hdr->req_arena_off + hdr->req_arena_cap > hdr->total_size) return 0;
        if (hdr->resp_off < (uint64_t)hdr->req_arena_off + hdr->req_arena_cap) return 0;
    }
    if (hdr->resp_off < req_slots_end) return 0;
    if ((uint64_t)hdr->resp_off + (uint64_t)hdr->resp_slots * hdr->resp_stride > hdr->total_size) return 0;
    if (hdr->proc_slots != REQREP_PROC_SLOTS || hdr->lost_slots != REQREP_LOST_SLOTS || hdr->proc_off % 8 != 0) return 0;
    if (hdr->proc_off < (uint64_t)hdr->resp_off + (uint64_t)hdr->resp_slots * hdr->resp_stride) return 0;
    if ((uint64_t)hdr->proc_off + REQREP_TAIL_SIZE > hdr->total_size) return 0;
    return 1;
}

static void reqrep_init_header(void *base, uint32_t req_cap, uint32_t resp_slots_n,
                                uint32_t resp_data_max, uint64_t total_size,
                                uint32_t req_slots_off, uint32_t req_arena_off,
                                uint32_t req_arena_cap, uint32_t resp_off,
                                uint32_t resp_stride, const ReqRepProvenance *prov) {
    ReqRepHeader *hdr = (ReqRepHeader *)base;
    memset(hdr, 0, sizeof(ReqRepHeader));
    hdr->version       = REQREP_VERSION;
    hdr->boot_id_hash  = prov->boot;
    hdr->pidns_ino     = prov->ino;
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
    hdr->proc_off      = (uint32_t)(total_size - REQREP_TAIL_SIZE);
    hdr->proc_slots    = REQREP_PROC_SLOTS;
    hdr->lost_slots    = REQREP_LOST_SLOTS;
    hdr->channel_id    = reqrep_random64();

    for (uint32_t i = 0; i < resp_slots_n; i++) {
        RespSlotHeader *rs = (RespSlotHeader *)((uint8_t *)base + resp_off + (uint64_t)i * resp_stride);
        memset(rs, 0, sizeof(RespSlotHeader));
    }

    /* Magic last: the commit point, so a creator killed before it leaves magic 0. */
    __atomic_store_n(&hdr->magic, REQREP_MAGIC, __ATOMIC_RELEASE);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

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

    /* Requests take the arena in multiples of 8, so a cap that is not one could not be filled. */
    if (arena_hint > (UINT32_MAX & ~(uint64_t)7)) return -1;
    uint32_t req_arena_cap = (uint32_t)((arena_hint + 7) & ~(uint64_t)7);
    if (req_arena_cap < 4096) req_arena_cap = 4096;

    uint64_t resp_stride_64 = ((uint64_t)sizeof(RespSlotHeader)
                              + (uint64_t)resp_data_max + 63) & ~(uint64_t)63;
    if (resp_stride_64 > UINT32_MAX) return -1;
    uint32_t resp_stride = (uint32_t)resp_stride_64;
    uint64_t resp_off_64 = ((uint64_t)req_arena_off + req_arena_cap + 63) & ~(uint64_t)63;
    if (resp_off_64 > UINT32_MAX) return -1;
    if (resp_slots_n > INT32_MAX) return -1;
    uint64_t total_size = resp_off_64 + (uint64_t)resp_slots_n * resp_stride
                        + REQREP_TAIL_SIZE;
    if (total_size > (uint64_t)INT64_MAX || (uint64_t)(size_t)total_size != total_size) return -1;
    /* proc_off is a uint32 field: a larger segment would put the registry inside the slots. */
    if (total_size > (uint64_t)UINT32_MAX) return -1;

    *out_req_slots_off = req_slots_off;
    *out_req_arena_off = req_arena_off;
    *out_req_arena_cap = req_arena_cap;
    *out_resp_off      = (uint32_t)resp_off_64;
    *out_resp_stride   = resp_stride;
    *out_total_size    = total_size;
    return 0;
}

/* O_EXCL refuses a pre-seeded or hard-linked file, O_NOFOLLOW a symlink swap. */
static int reqrep_secure_open(const char *path, mode_t mode, char *errbuf) {
    for (int attempt = 0; attempt < 100; attempt++) {
        int fd = open(path, O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, mode);
        if (fd >= 0) { (void)fchmod(fd, mode); return fd; }   /* umask narrowed the create */
        if (errno != EEXIST) { REQREP_ERR("create %s: %s", path, strerror(errno)); return -1; }
        fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
        if (fd >= 0) return fd;
        if (errno == ENOENT) continue;
        REQREP_ERR("open %s: %s", path, strerror(errno));
        return -1;
    }
    REQREP_ERR("open %s: create/attach kept racing", path);
    return -1;
}

/* What an abandoned mid-init creator leaves. Read, not mapped: a read fault on a tmpfs hole
 * allocates the page. */
static int reqrep_file_is_zero(int fd, uint64_t size) {
    char buf[16384];
    for (uint64_t off = 0; off < size; ) {
        ssize_t n = pread(fd, buf, size - off < sizeof buf ? (size_t)(size - off) : sizeof buf, (off_t)off);
        if (n <= 0) return 0;
        for (ssize_t i = 0; i < n; i++) if (buf[i]) return 0;
        off += (uint64_t)n;
    }
    return 1;
}

static ReqRepHandle *reqrep_create(const char *path, uint32_t req_cap,
                                    uint32_t resp_slots_n, uint32_t resp_data_max,
                                    uint64_t arena_hint, mode_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    ReqRepProvenance prov;
    if (!reqrep_read_provenance(&prov, errbuf)) return NULL;

    req_cap = reqrep_next_pow2(req_cap);
    if (req_cap == 0) { REQREP_ERR("invalid req_cap"); return NULL; }
    if (resp_slots_n == 0) { REQREP_ERR("resp_slots must be > 0"); return NULL; }

    if (arena_hint == 0) arena_hint = (uint64_t)req_cap * 256;

    uint32_t req_slots_off, req_arena_off, req_arena_cap, resp_off, resp_stride;
    uint64_t total_size;
    if (reqrep_compute_layout(req_cap, resp_slots_n, resp_data_max, arena_hint,
                               &req_slots_off, &req_arena_off, &req_arena_cap,
                               &resp_off, &resp_stride, &total_size) < 0) {
        REQREP_ERR("layout overflow: req_cap, arena_hint or resp_slots too large");
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
                            resp_off, resp_stride, &prov);
    } else {
        int fd = reqrep_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;

        if (reqrep_flock_timed(fd, LOCK_EX) < 0) {
            REQREP_ERR("flock(%s): %s", path, reqrep_flock_strerror(errno));
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

        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            REQREP_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new) {
            if (reqrep_ftruncate(fd, total_size) < 0) {
                REQREP_ERR("ftruncate(%s): %s", path, strerror(errno));
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (reqrep_reserve(fd, total_size) < 0) {
                REQREP_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)total_size, strerror(errno));
                if (ftruncate(fd, 0) < 0) { /* best effort */ }
                flock(fd, LOCK_UN); close(fd); return NULL;
            }
        }

        map_size = is_new ? (size_t)total_size : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            REQREP_ERR("mmap(%s): %s", path, strerror(errno));
            if (is_new && ftruncate(fd, 0) < 0) { /* best effort */ }
            flock(fd, LOCK_UN); close(fd); return NULL;
        }

        if (!is_new) {
            if (!reqrep_validate_header((ReqRepHeader *)base, (size_t)st.st_size, REQREP_MODE_STR)) {
                /* A creator killed between the ftruncate and the header init leaves an all-zero file. */
                if (((ReqRepHeader *)base)->magic == 0 && (uint64_t)st.st_size == total_size
                    && st.st_uid == geteuid() && reqrep_file_is_zero(fd, map_size)) {
                    if (fchmod(fd, mode) < 0) {
                        REQREP_ERR("%s: fchmod: %s", path, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    if (reqrep_reserve(fd, total_size) < 0) {
                        REQREP_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)total_size, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    reqrep_init_header(base, req_cap, resp_slots_n, resp_data_max, total_size,
                                        req_slots_off, req_arena_off, req_arena_cap,
                                        resp_off, resp_stride, &prov);
                    flock(fd, LOCK_UN); close(fd);
                    ReqRepHandle *h = reqrep_setup_handle(base, map_size, path, -1);
                    if (!h) { munmap(base, map_size); return NULL; }
                    return h;
                }
                if (((ReqRepHeader *)base)->magic == 0 && (uint64_t)st.st_size == total_size
                    && st.st_uid == geteuid())
                    REQREP_ERR("%s: incomplete reqrep file left by an interrupted create; remove it and retry", path);
                else
                    { char why[160]; REQREP_ERR("%s: %s", path, reqrep_header_refusal(base, why, sizeof why, "remove it and create it again")); }
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (!reqrep_check_attach((ReqRepHeader *)base, &st, path, errbuf)) {
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
                            resp_off, resp_stride, &prov);
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

    int fd = open(path, O_RDWR|O_NOFOLLOW|O_CLOEXEC);
    if (fd < 0) { REQREP_ERR("open(%s): %s", path, strerror(errno)); return NULL; }

    /* Shared: excludes a creator mid-init without serializing attaching peers. */
    if (reqrep_flock_timed(fd, LOCK_SH) < 0) {
        REQREP_ERR("flock(%s): %s", path, reqrep_flock_strerror(errno));
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
        char why[160];
        REQREP_ERR("%s: %s", path, reqrep_header_refusal(base, why, sizeof why, "remove it and create it again"));
        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
    }
    if (!reqrep_check_attach((ReqRepHeader *)base, &st, path, errbuf)) {
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
    ReqRepProvenance prov;
    if (!reqrep_read_provenance(&prov, errbuf)) return NULL;

    req_cap = reqrep_next_pow2(req_cap);
    if (req_cap == 0) { REQREP_ERR("invalid req_cap"); return NULL; }
    if (resp_slots_n == 0) { REQREP_ERR("resp_slots must be > 0"); return NULL; }

    if (arena_hint == 0) arena_hint = (uint64_t)req_cap * 256;

    uint32_t req_slots_off, req_arena_off, req_arena_cap, resp_off, resp_stride;
    uint64_t total_size;
    if (reqrep_compute_layout(req_cap, resp_slots_n, resp_data_max, arena_hint,
                               &req_slots_off, &req_arena_off, &req_arena_cap,
                               &resp_off, &resp_stride, &total_size) < 0) {
        REQREP_ERR("layout overflow: req_cap, arena_hint or resp_slots too large");
        return NULL;
    }

    int fd = memfd_create(name ? name : "reqrep", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { REQREP_ERR("memfd_create: %s", strerror(errno)); return NULL; }

    if (reqrep_ftruncate(fd, total_size) < 0) {
        REQREP_ERR("ftruncate(memfd): %s", strerror(errno));
        close(fd); return NULL;
    }
    if (reqrep_reserve(fd, total_size) < 0) {
        REQREP_ERR("memfd: cannot reserve %llu bytes: %s", (unsigned long long)total_size, strerror(errno));
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
                        resp_off, resp_stride, &prov);

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
        char why[160];
        REQREP_ERR("fd %d: %s", fd, reqrep_header_refusal(base, why, sizeof why, "create the channel again with this version"));
        munmap(base, map_size);
        return NULL;
    }
    if (!reqrep_check_provenance((ReqRepHeader *)base, errbuf)) {
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

/* Give up on every request this handle still has in flight: nobody else will read the replies. */
static void reqrep_cancel_own(ReqRepHandle *h) {
    uint32_t mypid = reqrep_self_pid();
    for (uint32_t i = 0; i < h->resp_slots; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
        uint32_t state = REQREP_CTL_STATE(c);
        if (state == RESP_FREE || state > RESP_ABANDONED) continue;
        /* ctl names the owner in these states; slot->owner may still be a previous owner's. */
        if ((state == RESP_ACQUIRED || state == RESP_READY) && REQREP_CTL_PID(c) != (mypid & 0xFFFFFFU)) continue;
        if (__atomic_load_n(&slot->owner, __ATOMIC_ACQUIRE) != mypid
                || (__atomic_load_n(&slot->owner_tag, __ATOMIC_ACQUIRE) & ~REQREP_TAG_NOTIFY) != h->tag)
            continue;
        uint64_t id = REQREP_MAKE_ID(i, REQREP_CTL_GEN(c));
        reqrep_cancel(h, id);
        reqrep_drop_reply(h, id);
    }
}

/* A forked child's copy of the parent's socket is replaced. */
static int reqrep_ready_fd(ReqRepHandle *h) {
    uint32_t pid = reqrep_self_pid();
    if (h->ready_sock >= 0 && h->ready_pid == pid) return h->ready_sock;
    if (h->ready_sock >= 0) close(h->ready_sock);
    h->ready_sock = socket(AF_UNIX, SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);
    if (h->ready_sock < 0) return -1;
    struct sockaddr_un addr;
    socklen_t len = reqrep_ready_addr(h, pid, h->tag, &addr);
    if (bind(h->ready_sock, (struct sockaddr *)&addr, len) < 0) {
        int e = errno;
        close(h->ready_sock);
        h->ready_sock = -1;
        errno = e;
        return -1;
    }
    free(h->told);
    h->told = (uint32_t *)calloc(h->resp_slots, sizeof *h->told);
    if (!h->told) {
        close(h->ready_sock);
        h->ready_sock = -1;
        errno = ENOMEM;
        return -1;
    }
    h->ready_pid = pid;
    h->lost_seen = h->lost_snapshot = __atomic_load_n(reqrep_lost_counter(h, pid, h->tag), __ATOMIC_ACQUIRE);
    h->lost_scan = 0;
    return h->ready_sock;
}

static int reqrep_ready_for_me(ReqRepHandle *h, uint64_t id) {
    uint32_t idx = REQREP_ID_SLOT(id);
    if (idx >= h->resp_slots) return 0;
    RespSlotHeader *slot = reqrep_resp_slot(h, idx);
    uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
    return REQREP_CTL_STATE(c) == RESP_READY && REQREP_CTL_GEN(c) == REQREP_ID_GEN(id)
        && REQREP_CTL_PID(c) == (reqrep_self_pid() & 0xFFFFFFU)
        && __atomic_load_n(&slot->owner_tag, __ATOMIC_ACQUIRE) == (h->tag | REQREP_TAG_NOTIFY);
}

static inline int reqrep_ready_list(ReqRepHandle *h, uint64_t id, uint64_t *ids, uint32_t *n) {
    if (!reqrep_ready_for_me(h, id) || h->told[REQREP_ID_SLOT(id)] == REQREP_ID_GEN(id)) return 0;
    h->told[REQREP_ID_SLOT(id)] = REQREP_ID_GEN(id);
    ids[(*n)++] = id;
    return 1;
}

/* Notifications a full queue refused are found by a scan of every slot when the loss counter
 * moves; a scan cut short resumes at the next call, or starts over if the counter moved again. */
static uint32_t reqrep_ready_ids(ReqRepHandle *h, uint64_t *ids, uint32_t max) {
    uint32_t n = 0;
    if (h->ready_sock < 0 || h->ready_pid != reqrep_self_pid()) return 0;
    uint64_t id;
    ssize_t got;
    while (n < max && (got = recv(h->ready_sock, &id, sizeof id, MSG_DONTWAIT)) >= 0) {
        if (got == (ssize_t)sizeof id) reqrep_ready_list(h, id, ids, &n);
    }
    uint32_t lost = __atomic_load_n(reqrep_lost_counter(h, h->ready_pid, h->tag), __ATOMIC_ACQUIRE);
    if (lost != h->lost_seen || h->lost_scan) {
        if (lost != h->lost_snapshot) {
            h->lost_scan = 0;
            h->lost_snapshot = lost;
        }
        uint32_t i;
        for (i = h->lost_scan; i < h->resp_slots && n < max; i++) {
            id = REQREP_MAKE_ID(i, REQREP_CTL_GEN(__atomic_load_n(&reqrep_resp_slot(h, i)->ctl, __ATOMIC_ACQUIRE)));
            reqrep_ready_list(h, id, ids, &n);
        }
        if (i == h->resp_slots) {
            h->lost_scan = 0;
            h->lost_seen = h->lost_snapshot;
        } else {
            h->lost_scan = i;
            /* Keep the descriptor readable: an event loop comes back only for a readable one. */
            struct sockaddr_un addr;
            socklen_t len = reqrep_ready_addr(h, reqrep_self_pid(), h->tag, &addr);
            uint8_t more = 0;
            (void)sendto(h->ready_sock, &more, 1, MSG_DONTWAIT | MSG_NOSIGNAL, (struct sockaddr *)&addr, len);
        }
    }
    return n;
}

static void reqrep_destroy(ReqRepHandle *h) {
    if (!h) return;
    if (h->hdr && h->inflight) reqrep_cancel_own(h);
    if (h->notify_fd >= 0) close(h->notify_fd);
    if (h->reply_fd >= 0) close(h->reply_fd);
    if (h->backing_fd >= 0) close(h->backing_fd);
    if (h->ready_sock >= 0) close(h->ready_sock);
    if (h->notify_sock >= 0) close(h->notify_sock);
    if (h->hdr) munmap(h->hdr, h->mmap_size);
    free(h->copy_buf);
    free(h->told);
    free(h->path);
    free(h);
}

/* The handle whose waiting send this thread's signal handlers run inside, 0 for none. */
static __thread uint32_t reqrep_handler_tag;

/* Returns 1=ok, 0=full, -2=too long. A sender that will wait and does not fit reserves the room it
 * needs, unless someone needs more, so a large request is not kept out for good by small ones. */
static inline int reqrep_send_locked(ReqRepHandle *h, const char *str,
                                      uint32_t len, bool utf8,
                                      uint32_t resp_slot_idx, uint32_t resp_gen, int reserve) {
    ReqRepHeader *hdr = h->hdr;

    if (len > REQREP_STR_LEN_MASK) return -2;

    if (hdr->req_tail - hdr->req_head >= h->req_cap) {
        __atomic_add_fetch(&hdr->stat_send_full, 1, __ATOMIC_RELAXED);
        return 0;
    }

    uint32_t alloc = (len + 7) & ~7u;
    if (alloc == 0) alloc = 8;
    if (alloc > h->req_arena_cap) return -2;
    uint32_t pos = hdr->arena_wpos;
    uint64_t skip = alloc;

    if ((uint64_t)pos + alloc > h->req_arena_cap) {
        skip += h->req_arena_cap - pos;
        pos = 0;
    }

    uint32_t mypid = reqrep_self_pid();
    uint32_t reserved = __atomic_load_n(&hdr->arena_reserved, __ATOMIC_RELAXED);
    int mine = reserved && __atomic_load_n(&hdr->arena_reserver, __ATOMIC_RELAXED) == mypid
            && __atomic_load_n(&hdr->arena_reserver_tag, __ATOMIC_RELAXED) == h->tag;
    if ((uint64_t)hdr->arena_used + skip > h->req_arena_cap) {
        if (hdr->req_tail == hdr->req_head) {
            hdr->arena_wpos = 0;
            hdr->arena_used = 0;
            pos = 0;
            skip = alloc;
        } else {
            if (reserve && (mine || skip > reserved)) {
                /* Holder first: a sender killed before the amount leaves room named after a dead pid. */
                __atomic_store_n(&hdr->arena_reserver, mypid, __ATOMIC_RELAXED);
                __atomic_store_n(&hdr->arena_reserver_tag, h->tag, __ATOMIC_RELAXED);
                __atomic_store_n(&hdr->arena_reserved, skip > UINT32_MAX ? UINT32_MAX : (uint32_t)skip, __ATOMIC_RELEASE);
                h->reserving = 1;
            }
            __atomic_add_fetch(&hdr->stat_send_full, 1, __ATOMIC_RELAXED);
            return 0;
        }
    }
    /* Room is held across signals, so a send from a handler inside the reserving call passes. */
    if (reserved && !mine
            && !(reqrep_handler_tag && __atomic_load_n(&hdr->arena_reserver_tag, __ATOMIC_RELAXED) == reqrep_handler_tag
                 && __atomic_load_n(&hdr->arena_reserver, __ATOMIC_RELAXED) == mypid)
            && (uint64_t)hdr->arena_used + skip + reserved > h->req_arena_cap) {
        h->reserve_blocker = __atomic_load_n(&hdr->arena_reserver, __ATOMIC_RELAXED);
        h->reserve_blocker_tag = __atomic_load_n(&hdr->arena_reserver_tag, __ATOMIC_RELAXED);
        __atomic_add_fetch(&hdr->stat_send_full, 1, __ATOMIC_RELAXED);
        return 0;
    }
    if (mine) __atomic_store_n(&hdr->arena_reserved, 0, __ATOMIC_RELEASE);

    memcpy(h->req_arena + pos, str, len);

    uint32_t idx = (uint32_t)(hdr->req_tail & h->req_cap_mask);
    ReqSlot *slot = &h->req_slots[idx];
    slot->arena_off = pos;
    slot->packed_len = len | (utf8 ? REQREP_UTF8_FLAG : 0);
    slot->arena_skip = (uint32_t)skip;
    slot->resp_slot = resp_slot_idx;
    slot->resp_gen = resp_gen;
    __atomic_store_n(&reqrep_resp_slot(h, resp_slot_idx)->claim_pos, hdr->req_tail, __ATOMIC_RELEASE);

    hdr->arena_wpos = pos + alloc;
    hdr->arena_used += (uint32_t)skip;
    /* The tail is the commit point, and plain stores reorder: a sender killed before it must
     * leave nothing published, not a message whose arena the next sender writes over. */
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    hdr->req_tail++;
    __atomic_add_fetch(&hdr->stat_requests, 1, __ATOMIC_RELAXED);
    return 1;
}

/* Drop the arena reservation if the named holder still has it, and let parked senders look again. */
static void reqrep_drop_reservation(ReqRepHandle *h, uint32_t pid, uint32_t tag) {
    ReqRepHeader *hdr = h->hdr;
    if (reqrep_mutex_lock_until(h, NULL, 0) == 1) {
        int held = __atomic_load_n(&hdr->arena_reserved, __ATOMIC_ACQUIRE)
                && __atomic_load_n(&hdr->arena_reserver, __ATOMIC_RELAXED) == pid
                && __atomic_load_n(&hdr->arena_reserver_tag, __ATOMIC_RELAXED) == tag;
        if (held) __atomic_store_n(&hdr->arena_reserved, 0, __ATOMIC_RELEASE);
        reqrep_mutex_unlock(h);
        if (held) reqrep_wake_producers(h, INT_MAX);
        return;
    }
    /* The mutex is out of reach, behind a stopped holder say, and room reserved for a sender that
     * gave up blocks every other one: only its named holder takes it back, so one word is enough. */
    uint32_t reserved = __atomic_load_n(&hdr->arena_reserved, __ATOMIC_ACQUIRE);
    if (reserved && __atomic_load_n(&hdr->arena_reserver, __ATOMIC_RELAXED) == pid
            && __atomic_load_n(&hdr->arena_reserver_tag, __ATOMIC_RELAXED) == tag
            && __atomic_compare_exchange_n(&hdr->arena_reserved, &reserved, 0, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED))
        reqrep_wake_producers(h, INT_MAX);
}

/* Release what a dead process with this pid held, now that another process has the pid. */
static void reqrep_proc_release(ReqRepHandle *h, uint32_t pid) {
    ReqRepHeader *hdr = h->hdr;
    for (uint32_t i = 0; i < h->resp_slots; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        for (int tries = 0; tries < REQREP_CANCEL_RETRIES; tries++) {
            uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
            uint32_t state = REQREP_CTL_STATE(c), gen = REQREP_CTL_GEN(c);
            uint64_t want;
            if (state == RESP_FREE || state > RESP_ABANDONED) break;
            if (REQREP_CTL_PID(c) == (pid & 0xFFFFFFU))
                want = REQREP_CTL(gen, 0, RESP_FREE);
            else if (state == RESP_DISPATCHED && __atomic_load_n(&slot->owner, __ATOMIC_ACQUIRE) == pid)
                want = REQREP_CTL(gen, 0, RESP_FREE);
            else if (state == RESP_WRITING && __atomic_load_n(&slot->owner, __ATOMIC_ACQUIRE) == pid)
                want = REQREP_CTL(gen, REQREP_CTL_PID(c), RESP_ABANDONED);
            else
                break;
            if (!reqrep_ctl_cas(slot, c, want)) continue;
            if (REQREP_CTL_STATE(want) == RESP_FREE) reqrep_slot_free(h, slot, gen);
            else reqrep_slot_wake(slot, gen);
            __atomic_add_fetch(&hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
            break;
        }
    }
    uint32_t m = __atomic_load_n(&hdr->mutex, __ATOMIC_ACQUIRE);
    if (m >= REQREP_MUTEX_WRITER_BIT && (m & REQREP_MUTEX_PID_MASK) == (pid & REQREP_MUTEX_PID_MASK))
        reqrep_recover_stale_mutex(h, m);
    if (__atomic_load_n(&hdr->arena_reserved, __ATOMIC_ACQUIRE) && __atomic_load_n(&hdr->arena_reserver, __ATOMIC_RELAXED) == pid)
        reqrep_drop_reservation(h, pid, __atomic_load_n(&hdr->arena_reserver_tag, __ATOMIC_RELAXED));
}

/* Channels this program has registered in. After an exec, the first registration in a channel
 * finds the record the program before it left, same pid and start, and releases what it held. */
static uint64_t reqrep_image_channels[64];

static int reqrep_image_first(uint64_t channel) {
    if (!channel) channel = 1;
    for (int i = 0; i < 64; i++) {
        uint64_t c = __atomic_load_n(&reqrep_image_channels[i], __ATOMIC_ACQUIRE);
        if (!c && __atomic_compare_exchange_n(&reqrep_image_channels[i], &c, channel, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE))
            return 1;
        if (c == channel) return 0;
    }
    return 0;
}

/* Our start time cannot be read just now: a record of our pid with another start would make peers
 * take us for dead, so make its start unknown, which reads as alive. */
static void reqrep_proc_unknown(ReqRepHandle *h, uint32_t pid) {
    uint32_t mask = REQREP_PROC_SLOTS - 1;
    for (uint32_t k = 0; k < REQREP_PROC_SLOTS; k++) {
        ReqRepProc *e = &h->procs[(pid + k) & mask];
        ReqRepProc r = reqrep_proc_load(e);
        if (!r.pid) return;
        if (r.pid != pid) continue;
        if (r.start != REQREP_START_RELEASING) reqrep_proc_cas(e, r, pid, 0);
        return;
    }
}

/* Record this process before its pid goes anywhere in the channel. A record left for the same pid
 * with another start time belongs to a process that died, whose holdings would otherwise pass
 * for ours: the first registrant to claim the record releases them. */
static void reqrep_proc_register(ReqRepHandle *h) {
    uint32_t pid = reqrep_self_pid();
    if (h->registered_pid == pid) return;
    if (h->register_failed_pid == pid && reqrep_now_ns() - h->register_failed_ns < REQREP_RECOVERY_INTERVAL_NS) return;
    uint32_t start = __atomic_load_n(&reqrep_start_cache, __ATOMIC_RELAXED);
    if (!start && reqrep_proc_stat(pid, &start) != 1) {
        /* A shortage passes, so retry at the next call; no /proc does not, so not every call. */
        if (errno != EMFILE && errno != ENFILE && errno != ENOMEM) {
            h->register_failed_pid = pid;
            h->register_failed_ns = reqrep_now_ns();
        }
        reqrep_proc_unknown(h, pid);
        return;
    }
    __atomic_store_n(&reqrep_start_cache, start, __ATOMIC_RELAXED);
    h->registered_pid = pid;
    uint64_t channel = h->hdr->channel_id;
    uint32_t mask = REQREP_PROC_SLOTS - 1;
    for (int evict = 0; evict < 2; evict++) {
        for (uint32_t k = 0; k < REQREP_PROC_SLOTS; k++) {
            ReqRepProc *e = &h->procs[(pid + k) & mask];
            for (long spins = 0; ; spins++) {
                ReqRepProc r = reqrep_proc_load(e);
                if (r.pid == pid) {
                    if (r.start == start) {
                        /* Only a record this program image did not make: one left from before an exec. */
                        if (reqrep_image_first(channel)) reqrep_proc_release(h, pid);
                        return;
                    }
                    /* Another thread of ours releasing, or a process with our pid that died doing so. */
                    if (r.start == REQREP_START_RELEASING && spins < (1L << 20)) {
                        reqrep_spin_pause();
                        continue;
                    }
                    (void)reqrep_image_first(channel);
                    /* An unknown start is taken as ours; another is a dead process's. */
                    if (!reqrep_proc_cas(e, r, pid, r.start ? REQREP_START_RELEASING : start)) continue;
                    if (r.start) {
                        reqrep_proc_release(h, pid);
                        reqrep_proc_cas(e, (ReqRepProc){ pid, REQREP_START_RELEASING }, pid, start);
                    }
                    return;
                }
                /* Records are never emptied, so a lookup stops at the first empty one. */
                if (r.pid && !(evict && reqrep_record_dead(r))) break;
                (void)reqrep_image_first(channel);
                if (!reqrep_proc_cas(e, r, pid, start)) continue;
                /* The record was what told the dead process apart from a later one with its pid. */
                if (r.pid) reqrep_proc_release(h, r.pid);
                return;
            }
        }
    }
}

/* One send attempt, locking as reqrep_mutex_lock_until: also returns REQREP_EINTR. */
static int reqrep_send_attempt(ReqRepHandle *h, const char *str, uint32_t len, bool utf8,
                               uint64_t *out_id, const struct timespec *deadline, double timeout) {
    uint32_t gen;
    int32_t slot = reqrep_slot_acquire(h, &gen);
    if (slot < 0) return -3;

    h->reserve_blocker = 0;
    int r = reqrep_mutex_lock_until(h, deadline, timeout);
    if (r == 1) {
        r = reqrep_send_locked(h, str, len, utf8, (uint32_t)slot, gen, timeout != 0);
        reqrep_mutex_unlock(h);
    }

    if (r == 1) {
        reqrep_wake_consumers(h);
        *out_id = REQREP_MAKE_ID((uint32_t)slot, gen);
        return 1;
    }

    reqrep_cancel(h, REQREP_MAKE_ID((uint32_t)slot, gen));
    if (r == 0 && h->reserve_blocker) {
        /* A reservation outlives a holder that died waiting: look at the holder now and then. */
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        uint64_t now_ns = (uint64_t)now.tv_sec * 1000000000ULL + (uint64_t)now.tv_nsec;
        if (now_ns - h->last_reserve_check_ns >= REQREP_RECOVERY_INTERVAL_NS) {
            h->last_reserve_check_ns = now_ns;
            if (!reqrep_pid_alive(h, h->reserve_blocker))
                reqrep_drop_reservation(h, h->reserve_blocker, h->reserve_blocker_tag);
        }
    }
    return r;
}

static inline int reqrep_try_send(ReqRepHandle *h, const char *str, uint32_t len,
                                  bool utf8, uint64_t *out_id) {
    return reqrep_send_attempt(h, str, len, utf8, out_id, NULL, 0);
}

static inline uint64_t reqrep_size(ReqRepHandle *h) {
    ReqRepHeader *hdr = h->hdr;
    /* Head before tail keeps the difference non-negative. */
    uint64_t head = __atomic_load_n(&hdr->req_head, __ATOMIC_RELAXED);
    uint64_t tail = __atomic_load_n(&hdr->req_tail, __ATOMIC_RELAXED);
    uint64_t n = (tail >= head) ? (tail - head) : 0;
    /* A receive and refills between the two loads can make the snapshot exceed the capacity. */
    return n > h->req_cap ? h->req_cap : n;
}

/* One receive wakes one sender but may free room for several: a woken one that got in passes it on. */
static inline void reqrep_pass_send_wake(ReqRepHandle *h) {
    ReqRepHeader *hdr = h->hdr;
    if (REQREP_WAITERS(__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED))
            && reqrep_size(h) < h->req_cap
            && __atomic_load_n(&hdr->arena_used, __ATOMIC_RELAXED) < h->req_arena_cap)
        reqrep_wake_producers(h, 1);
}

static int reqrep_send_wait_reserving(ReqRepHandle *h, const char *str, uint32_t len,
                                      bool utf8, uint64_t *out_id, double timeout);

/* The wait is over: room this handle still holds goes back unless the send used it. */
static void reqrep_send_done(ReqRepHandle *h, int sent) {
    if (!h->reserving) return;
    h->reserving = 0;
    if (!sent) reqrep_drop_reservation(h, reqrep_self_pid(), h->tag);
}

/* Blocking send with timeout. Returns 1=ok, 0=timeout, -2=too long, -3=no slots (timeout), or
 * REQREP_EINTR still holding any room reserved: the caller retries, or calls reqrep_send_done. */
static int reqrep_send_wait(ReqRepHandle *h, const char *str, uint32_t len,
                             bool utf8, uint64_t *out_id, double timeout) {
    int r = reqrep_send_wait_reserving(h, str, len, utf8, out_id, timeout);
    if (r != REQREP_EINTR) reqrep_send_done(h, r == 1);
    return r;
}

static int reqrep_send_wait_reserving(ReqRepHandle *h, const char *str, uint32_t len,
                                      bool utf8, uint64_t *out_id, double timeout) {
    ReqRepHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);
    const struct timespec *lock_by = has_deadline ? &deadline : NULL;

    int r = reqrep_send_attempt(h, str, len, utf8, out_id, lock_by, timeout);
    if (r == 1 || r == -2 || r == REQREP_EINTR) return r;
    if (timeout == 0) return r;

    for (;;) {
        r = reqrep_send_attempt(h, str, len, utf8, out_id, lock_by, timeout);
        if (r == 1 || r == -2 || r == REQREP_EINTR) return r;
        if (REQREP_INTERRUPTED(h)) return REQREP_EINTR;

        uint32_t *futex_word  = (r == -3) ? &hdr->slot_futex : &hdr->send_futex;
        uint64_t *waiter_cnt = (r == -3) ? &hdr->slot_waiters : &hdr->send_waiters;

        uint32_t fseq = __atomic_load_n(futex_word, __ATOMIC_ACQUIRE);
        uint32_t epoch = reqrep_waiters_add(waiter_cnt);
        /* StoreLoad: wakers skip the futex while the count is 0, so re-check after registering. A
         * re-check blocked on the other resource starts over, never parking on the wrong futex. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        { int r2 = reqrep_send_attempt(h, str, len, utf8, out_id, lock_by, timeout);
          if (r2 == 1 || r2 == -2 || r2 != r) {
              reqrep_waiters_sub(waiter_cnt, epoch);
              if (r2 == 1 || r2 == -2 || r2 == REQREP_EINTR) return r2;
              continue;
          } }
        /* Nothing wakes a slot waiter when holders die, a sender refused by a reservation when its
         * holder dies, or one waiting for room a receiver freed and died before waking: only an
         * attempt finds out, so look again every tick. */
        struct timespec tick = { REQREP_LOCK_TIMEOUT_SEC, 0 };
        struct timespec *pts = &tick;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                reqrep_waiters_sub(waiter_cnt, epoch);
                return r;
            }
            if (remaining.tv_sec < tick.tv_sec) pts = &remaining;
        }
        long rc = reqrep_futex_wait(futex_word, fseq, pts);
        int timed_out = rc == -1 && errno == ETIMEDOUT && pts != &tick;
        int interrupted = rc == -1 && errno == EINTR;
        reqrep_waiters_sub(waiter_cnt, epoch);

        r = reqrep_send_attempt(h, str, len, utf8, out_id, lock_by, timeout);
        if (r == 1 && futex_word == &hdr->send_futex) reqrep_pass_send_wake(h);
        if (r == 1 || r == -2 || r == REQREP_EINTR) return r;
        if (timed_out) return r;
        if (interrupted) return REQREP_EINTR;
    }
}

/* Returns 1=ok, 0=empty, -1=OOM. */
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
    uint32_t arena_off = slot->arena_off;
    *out_utf8 = (slot->packed_len & REQREP_UTF8_FLAG) != 0;
    *out_id = REQREP_MAKE_ID(slot->resp_slot, slot->resp_gen);

    /* Peer-writable: a corrupt entry delivers empty rather than read out of bounds. */
    if ((uint64_t)arena_off + len > (uint64_t)h->req_arena_cap)
        len = 0;

    if (!reqrep_ensure_copy_buf(h, len + 1))
        return -1;
    if (len > 0)
        memcpy(h->copy_buf, h->req_arena + arena_off, len);
    h->copy_buf[len] = '\0';
    *out_str = h->copy_buf;
    *out_len = len;

    /* Consume before crediting the bytes back: a crash between the two then
     * leaves a self-healing over-count, not a message the next send overwrites. */
    hdr->req_head++;
    __atomic_signal_fence(__ATOMIC_SEQ_CST);

    if (hdr->arena_used >= slot->arena_skip)
        hdr->arena_used -= slot->arena_skip;
    else
        hdr->arena_used = 0;
    if (hdr->arena_used == 0)
        hdr->arena_wpos = 0;

    return 1;
}

/* One receive attempt, locking as reqrep_mutex_lock_until: 0 also when the time is up. */
static inline int reqrep_recv_attempt(ReqRepHandle *h, const char **out_str, uint32_t *out_len,
                                      bool *out_utf8, uint64_t *out_id,
                                      const struct timespec *deadline, double timeout) {
    int r = reqrep_mutex_lock_until(h, deadline, timeout);
    if (r != 1) return r;
    r = reqrep_recv_locked(h, out_str, out_len, out_utf8, out_id);
    reqrep_mutex_unlock(h);
    if (r == 1) {
        reqrep_slot_dispatch(h, *out_id);
        reqrep_wake_producers(h, 1);
    }
    return r;
}

static inline int reqrep_try_recv(ReqRepHandle *h, const char **out_str,
                                  uint32_t *out_len, bool *out_utf8, uint64_t *out_id) {
    return reqrep_recv_attempt(h, out_str, out_len, out_utf8, out_id, NULL, 0);
}

/* Returns 1=ok, 0=timeout, -1=OOM. */
static int reqrep_recv_wait(ReqRepHandle *h, const char **out_str,
                             uint32_t *out_len, bool *out_utf8,
                             uint64_t *out_id, double timeout) {
    ReqRepHeader *hdr = h->hdr;
    struct timespec deadline, remaining;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);
    const struct timespec *lock_by = has_deadline ? &deadline : NULL;

    int r = reqrep_recv_attempt(h, out_str, out_len, out_utf8, out_id, lock_by, timeout);
    if (r != 0) return r;
    if (timeout == 0) return 0;

    for (;;) {
        uint32_t fseq = __atomic_load_n(&hdr->recv_futex, __ATOMIC_ACQUIRE);
        r = reqrep_recv_attempt(h, out_str, out_len, out_utf8, out_id, lock_by, timeout);
        if (r != 0) return r;
        if (REQREP_INTERRUPTED(h)) return REQREP_EINTR;

        uint32_t epoch = reqrep_waiters_add(&hdr->recv_waiters);
        /* StoreLoad: wakers skip the futex while the count is 0, so re-check after registering. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        r = reqrep_recv_attempt(h, out_str, out_len, out_utf8, out_id, lock_by, timeout);
        if (r != 0) {
            reqrep_waiters_sub(&hdr->recv_waiters, epoch);
            return r;
        }
        /* The one wake a send gives may go to a receiver killed as it came: look again every tick. */
        struct timespec tick = { REQREP_LOCK_TIMEOUT_SEC, 0 };
        struct timespec *pts = &tick;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                reqrep_waiters_sub(&hdr->recv_waiters, epoch);
                return 0;
            }
            if (remaining.tv_sec < tick.tv_sec) pts = &remaining;
        }
        long rc = reqrep_futex_wait(&hdr->recv_futex, fseq, pts);
        int err = rc == -1 ? errno : 0;
        reqrep_waiters_sub(&hdr->recv_waiters, epoch);

        r = reqrep_recv_attempt(h, out_str, out_len, out_utf8, out_id, lock_by, timeout);
        if (r != 0) return r;
        if (err == ETIMEDOUT && pts != &tick) return 0;
        if (err == EINTR) return REQREP_EINTR;
    }
}

/* Returns 1=ok, -1=bad slot, -2=stale (cancelled or recycled), -3=too long. */
static int reqrep_reply(ReqRepHandle *h, uint64_t id,
                         const char *str, uint32_t len, bool utf8) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return -1;
    if (len > h->resp_data_max) return -3;

    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint32_t mypid = reqrep_self_pid();
    uint32_t owner;
    if (!reqrep_slot_take_write(slot, gen, mypid, &owner)) return -2;

    uint8_t *data = (uint8_t *)slot + sizeof(RespSlotHeader);
    if (len > 0) memcpy(data, str, len);
    slot->resp_len = len;
    slot->resp_flags = utf8 ? 1 : 0;
    return reqrep_slot_publish(h, slot, gen, owner, mypid);
}

/* Returns 1=ok, 0=not ready, -1=bad slot, -2=out of memory, -4=stale. */
static int reqrep_try_get(ReqRepHandle *h, uint64_t id,
                           const char **out_str, uint32_t *out_len, bool *out_utf8) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    if (slot_idx >= h->resp_slots) return -1;

    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
    int r = reqrep_slot_readable(c, REQREP_ID_GEN(id));
    if (r != 1) return r;

    uint32_t len = slot->resp_len;
    /* resp_len is peer-writable: a corrupt one delivers empty rather than overrun the slot. */
    if (len > h->resp_data_max) len = 0;
    bool utf8 = (slot->resp_flags & 1) != 0;
    if (!reqrep_ensure_copy_buf(h, len + 1)) return -2;

    uint8_t *data = (uint8_t *)slot + sizeof(RespSlotHeader);
    if (len > 0) memcpy(h->copy_buf, data, len);
    h->copy_buf[len] = '\0';

    if (!reqrep_slot_take_reply(h, slot, c)) return -4;
    *out_str = h->copy_buf;
    *out_len = len;
    *out_utf8 = utf8;
    return 1;
}

static int reqrep_get_wait(ReqRepHandle *h, uint64_t id,
                            const char **out_str, uint32_t *out_len, bool *out_utf8,
                            double timeout) {
    int r = reqrep_try_get(h, id, out_str, out_len, out_utf8);
    if (r != 0 || timeout == 0) return r;
    struct timespec deadline;
    if (timeout > 0) reqrep_make_deadline(timeout, &deadline);
    for (;;) {
        r = reqrep_await_reply(h, id, timeout > 0 ? &deadline : NULL);
        if (r != 1) return r;
        r = reqrep_try_get(h, id, out_str, out_len, out_utf8);
        if (r != 0) return r;
    }
}

/* Returns 1=ok, 0=timeout, -2=too long, -3=no slots, -4=stale, -5=out of memory, or REQREP_EINTR
 * with *inflight (the id already sent, 0 for none) kept so a retry waits rather than resends. */
static int reqrep_request_step(ReqRepHandle *h, const char *req_str, uint32_t req_len,
                               bool req_utf8, const char **out_str, uint32_t *out_len,
                               bool *out_utf8, double timeout, uint64_t *inflight) {
    uint64_t id = *inflight;
    struct timespec deadline;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);

    if (!id) {
        int r = reqrep_send_wait(h, req_str, req_len, req_utf8, &id, timeout);
        if (r != 1) return r;
        *inflight = id;
    }

    double get_timeout = timeout;
    if (has_deadline) {
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        get_timeout = (double)(deadline.tv_sec - now.tv_sec) +
                      (double)(deadline.tv_nsec - now.tv_nsec) / 1e9;
        if (get_timeout <= 0) {
            reqrep_cancel(h, id);
            reqrep_drop_reply(h, id);
            *inflight = 0;
            return 0;
        }
    }

    int r = reqrep_get_wait(h, id, out_str, out_len, out_utf8, get_timeout);
    if (r == REQREP_EINTR) return r;
    *inflight = 0;
    if (r != 1) {
        reqrep_cancel(h, id);
        /* Here -2 is a failed copy, not an oversized request. */
        reqrep_drop_reply(h, id);
        if (r == -2) r = -5;
    }
    return r;
}

static inline int reqrep_request(ReqRepHandle *h, const char *req_str, uint32_t req_len,
                          bool req_utf8, const char **out_str, uint32_t *out_len,
                          bool *out_utf8, double timeout) {
    uint64_t inflight = 0;
    struct timespec deadline;
    if (timeout > 0) reqrep_make_deadline(timeout, &deadline);
    int r;
    while ((r = reqrep_request_step(h, req_str, req_len, req_utf8, out_str, out_len,
                                    out_utf8, timeout, &inflight)) == REQREP_EINTR)
        if (timeout > 0) timeout = reqrep_time_left(&deadline);
    return r;
}

/* Approximate under contention. */
static uint32_t reqrep_pending(ReqRepHandle *h) {
    uint32_t mypid = reqrep_self_pid();
    uint32_t count = 0;
    for (uint32_t i = 0; i < h->resp_slots; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
        uint32_t state = REQREP_CTL_STATE(c);
        if (state == RESP_DISPATCHED || state == RESP_WRITING)
            count += __atomic_load_n(&slot->owner, __ATOMIC_RELAXED) == mypid;
        else if (state == RESP_ACQUIRED || state == RESP_READY)
            count += REQREP_CTL_PID(c) == (mypid & 0xFFFFFFU);
    }
    return count;
}

/* 1, or REQREP_EINTR on a signal while waiting for the mutex, having changed nothing. */
static int reqrep_clear(ReqRepHandle *h) {
    ReqRepHeader *hdr = h->hdr;
    if (reqrep_mutex_lock_until(h, NULL, -1) != 1) return REQREP_EINTR;
    for (uint64_t pos = hdr->req_head, n = 0; pos != hdr->req_tail && n < h->req_cap; pos++, n++) {
        ReqSlot *slot = &h->req_slots[pos & h->req_cap_mask];
        reqrep_cancel(h, REQREP_MAKE_ID(slot->resp_slot, slot->resp_gen));
    }
    /* Positions only grow, so a taken request's claim_pos stays comparable with the head. */
    hdr->req_head = hdr->req_tail;
    __atomic_signal_fence(__ATOMIC_SEQ_CST);
    hdr->arena_wpos = 0;
    hdr->arena_used = 0;
    /* The arena is empty again, so room held for a parked sender holds nobody up any longer. */
    __atomic_store_n(&hdr->arena_reserved, 0, __ATOMIC_RELEASE);
    reqrep_mutex_unlock(h);

    reqrep_clear_slots(h);

    reqrep_broadcast(&hdr->slot_futex, &hdr->slot_waiters);
    reqrep_broadcast(&hdr->send_futex, &hdr->send_waiters);
    reqrep_wake_consumers(h);
    return 1;
}

static inline int reqrep_sync(ReqRepHandle *h) {
    return msync(h->hdr, h->mmap_size, MS_SYNC);
}

static inline int reqrep_eventfd_create(ReqRepHandle *h) {
    if (h->notify_fd >= 0) return h->notify_fd;
    h->notify_fd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    return h->notify_fd;
}

/* Keep our own duplicate: the caller still owns fd and may close it. */
static inline int reqrep_eventfd_set(ReqRepHandle *h, int fd) {
    if (fd == h->notify_fd) return 0;
    int nfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (nfd < 0) return -1;
    if (h->notify_fd >= 0) close(h->notify_fd);
    h->notify_fd = nfd;
    return 0;
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

/* See reqrep_eventfd_set. */
static inline int reqrep_reply_eventfd_set(ReqRepHandle *h, int fd) {
    if (fd == h->reply_fd) return 0;
    int nfd = fcntl(fd, F_DUPFD_CLOEXEC, 0);
    if (nfd < 0) return -1;
    if (h->reply_fd >= 0) close(h->reply_fd);
    h->reply_fd = nfd;
    return 0;
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

/* Int mode: lock-free Vyukov MPMC request queue, inline int64 response. */

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
    if (resp_slots_n > INT32_MAX) return -1;
    uint64_t total_size = resp_off + (uint64_t)resp_slots_n * resp_stride
                        + REQREP_TAIL_SIZE;
    if (total_size > (uint64_t)INT64_MAX || (uint64_t)(size_t)total_size != total_size) return -1;
    /* proc_off is a uint32 field: a larger segment would put the registry inside the slots. */
    if (total_size > (uint64_t)UINT32_MAX) return -1;
    *out_total_size    = total_size;
    return 0;
}

static void reqrep_int_init_header(void *base, uint32_t req_cap, uint32_t resp_slots_n,
                                    uint64_t total_size, uint32_t req_slots_off,
                                    uint32_t resp_off, uint32_t resp_stride,
                                    const ReqRepProvenance *prov) {
    ReqRepHeader *hdr = (ReqRepHeader *)base;
    memset(hdr, 0, sizeof(ReqRepHeader));
    hdr->version       = REQREP_VERSION;
    hdr->boot_id_hash  = prov->boot;
    hdr->pidns_ino     = prov->ino;
    hdr->mode          = REQREP_MODE_INT;
    hdr->req_cap       = req_cap;
    hdr->total_size    = total_size;
    hdr->req_slots_off = req_slots_off;
    hdr->resp_slots    = resp_slots_n;
    hdr->resp_data_max = sizeof(int64_t);
    hdr->resp_off      = resp_off;
    hdr->resp_stride   = resp_stride;
    hdr->proc_off      = (uint32_t)(total_size - REQREP_TAIL_SIZE);
    hdr->proc_slots    = REQREP_PROC_SLOTS;
    hdr->lost_slots    = REQREP_LOST_SLOTS;
    hdr->channel_id    = reqrep_random64();

    ReqIntSlot *slots = (ReqIntSlot *)((char *)base + req_slots_off);
    for (uint32_t i = 0; i < req_cap; i++)
        slots[i].sequence = i;

    for (uint32_t i = 0; i < resp_slots_n; i++) {
        RespSlotHeader *rs = (RespSlotHeader *)((uint8_t *)base + resp_off + (uint64_t)i * resp_stride);
        memset(rs, 0, sizeof(RespSlotHeader));
    }

    /* Magic last: the commit point, so a creator killed before it leaves magic 0. */
    __atomic_store_n(&hdr->magic, REQREP_MAGIC, __ATOMIC_RELEASE);
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

static ReqRepHandle *reqrep_create_int(const char *path, uint32_t req_cap,
                                        uint32_t resp_slots_n, mode_t mode, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    ReqRepProvenance prov;
    if (!reqrep_read_provenance(&prov, errbuf)) return NULL;
    req_cap = reqrep_next_pow2(req_cap);
    if (req_cap == 0) { REQREP_ERR("invalid req_cap"); return NULL; }
    if (resp_slots_n == 0) { REQREP_ERR("resp_slots must be > 0"); return NULL; }

    uint32_t req_slots_off, resp_off, resp_stride;
    uint64_t total_size;
    if (reqrep_int_compute_layout(req_cap, resp_slots_n, &req_slots_off,
                                   &resp_off, &resp_stride, &total_size) < 0) {
        REQREP_ERR("layout overflow: req_cap or resp_slots too large");
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
        int fd = reqrep_secure_open(path, mode, errbuf);
        if (fd < 0) return NULL;
        if (reqrep_flock_timed(fd, LOCK_EX) < 0) { REQREP_ERR("flock(%s): %s", path, reqrep_flock_strerror(errno)); close(fd); return NULL; }
        struct stat st;
        if (fstat(fd, &st) < 0) { REQREP_ERR("fstat: %s", strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL; }
        int is_new = (st.st_size == 0);
        if (!is_new && (uint64_t)st.st_size < sizeof(ReqRepHeader)) {
            REQREP_ERR("%s: file too small", path); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && (st.st_uid != geteuid() || fchmod(fd, mode) < 0)) {
            REQREP_ERR("%s: refusing to initialize file not owned by us", path);
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && reqrep_ftruncate(fd, total_size) < 0) {
            REQREP_ERR("ftruncate(%s): %s", path, strerror(errno)); flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (is_new && reqrep_reserve(fd, total_size) < 0) {
            REQREP_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)total_size, strerror(errno));
            if (ftruncate(fd, 0) < 0) { /* best effort */ }
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        map_size = is_new ? (size_t)total_size : (size_t)st.st_size;
        base = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            REQREP_ERR("mmap(%s): %s", path, strerror(errno));
            if (is_new && ftruncate(fd, 0) < 0) { /* best effort */ }
            flock(fd, LOCK_UN); close(fd); return NULL;
        }
        if (!is_new) {
            if (!reqrep_validate_header((ReqRepHeader *)base, map_size, REQREP_MODE_INT)) {
                /* A creator killed between the ftruncate and the header init leaves an all-zero file. */
                if (((ReqRepHeader *)base)->magic == 0 && (uint64_t)st.st_size == total_size
                    && st.st_uid == geteuid() && reqrep_file_is_zero(fd, map_size)) {
                    if (fchmod(fd, mode) < 0) {
                        REQREP_ERR("%s: fchmod: %s", path, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    if (reqrep_reserve(fd, total_size) < 0) {
                        REQREP_ERR("%s: cannot reserve %llu bytes: %s", path, (unsigned long long)total_size, strerror(errno));
                        munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
                    }
                    reqrep_int_init_header(base, req_cap, resp_slots_n, total_size,
                                            req_slots_off, resp_off, resp_stride, &prov);
                    flock(fd, LOCK_UN); close(fd);
                    ReqRepHandle *h = reqrep_setup_handle(base, map_size, path, -1);
                    if (!h) { munmap(base, map_size); return NULL; }
                    return h;
                }
                if (((ReqRepHeader *)base)->magic == 0 && (uint64_t)st.st_size == total_size
                    && st.st_uid == geteuid())
                    REQREP_ERR("%s: incomplete reqrep file left by an interrupted create; remove it and retry", path);
                else
                    { char why[160]; REQREP_ERR("%s: %s", path, reqrep_header_refusal(base, why, sizeof why, "remove it and create it again")); }
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            if (!reqrep_check_attach((ReqRepHeader *)base, &st, path, errbuf)) {
                munmap(base, map_size); flock(fd, LOCK_UN); close(fd); return NULL;
            }
            flock(fd, LOCK_UN); close(fd);
            ReqRepHandle *h = reqrep_setup_handle(base, map_size, path, -1);
            if (!h) { munmap(base, map_size); return NULL; }
            return h;
        }
        reqrep_int_init_header(base, req_cap, resp_slots_n, total_size,
                                req_slots_off, resp_off, resp_stride, &prov);
        flock(fd, LOCK_UN); close(fd);
        ReqRepHandle *h = reqrep_setup_handle(base, map_size, path, -1);
        if (!h) { munmap(base, map_size); return NULL; }
        return h;
    }

    reqrep_int_init_header(base, req_cap, resp_slots_n, total_size,
                            req_slots_off, resp_off, resp_stride, &prov);
    ReqRepHandle *h = reqrep_setup_handle(base, map_size, path, -1);
    if (!h) { munmap(base, map_size); return NULL; }
    return h;
}

static ReqRepHandle *reqrep_create_int_memfd(const char *name, uint32_t req_cap,
                                              uint32_t resp_slots_n, char *errbuf) {
    if (errbuf) errbuf[0] = '\0';
    ReqRepProvenance prov;
    if (!reqrep_read_provenance(&prov, errbuf)) return NULL;
    req_cap = reqrep_next_pow2(req_cap);
    if (req_cap == 0) { REQREP_ERR("invalid req_cap"); return NULL; }
    if (resp_slots_n == 0) { REQREP_ERR("resp_slots must be > 0"); return NULL; }

    uint32_t req_slots_off, resp_off, resp_stride;
    uint64_t total_size;
    if (reqrep_int_compute_layout(req_cap, resp_slots_n, &req_slots_off,
                                   &resp_off, &resp_stride, &total_size) < 0) {
        REQREP_ERR("layout overflow: req_cap or resp_slots too large");
        return NULL;
    }

    int fd = memfd_create(name ? name : "reqrep_int", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    if (fd < 0) { REQREP_ERR("memfd_create: %s", strerror(errno)); return NULL; }
    if (reqrep_ftruncate(fd, total_size) < 0) {
        REQREP_ERR("ftruncate(memfd): %s", strerror(errno)); close(fd); return NULL;
    }
    if (reqrep_reserve(fd, total_size) < 0) {
        REQREP_ERR("memfd: cannot reserve %llu bytes: %s", (unsigned long long)total_size, strerror(errno));
        close(fd); return NULL;
    }
    (void)fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW);
    void *base = mmap(NULL, (size_t)total_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { REQREP_ERR("mmap: %s", strerror(errno)); close(fd); return NULL; }

    reqrep_int_init_header(base, req_cap, resp_slots_n, total_size,
                            req_slots_off, resp_off, resp_stride, &prov);
    ReqRepHandle *h = reqrep_setup_handle(base, (size_t)total_size, NULL, fd);
    if (!h) { munmap(base, (size_t)total_size); close(fd); return NULL; }
    return h;
}

static inline int reqrep_int_try_send(ReqRepHandle *h, int64_t value, uint64_t *out_id) {
    uint32_t gen;
    int32_t rslot = reqrep_slot_acquire(h, &gen);
    if (rslot < 0) return -3;

    ReqRepHeader *hdr = h->hdr;
    /* Not from the peer-writable hdr->req_slots_off. */
    ReqIntSlot *slots = (ReqIntSlot *)h->req_slots;
    RespSlotHeader *resp = reqrep_resp_slot(h, (uint32_t)rslot);
    uint32_t mask = h->req_cap_mask;
    uint64_t pos = __atomic_load_n(&hdr->req_tail, __ATOMIC_RELAXED);

    for (int tries = 0; ; tries++) {
        ReqIntSlot *slot = &slots[pos & mask];
        uint64_t seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);
        int64_t diff = (int64_t)seq - (int64_t)pos;
        if (diff == 0) {
            /* Named before it is claimed, so a receiver finding the claim unpublished can tell
             * whether we died. */
            __atomic_store_n(&resp->claim_pos, pos, __ATOMIC_RELEASE);
            if (__atomic_compare_exchange_n(&hdr->req_tail, &pos, pos + 1,
                    1, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                slot->value = value;
                slot->resp_slot = (uint32_t)rslot;
                slot->resp_gen = gen;
                uint64_t claimed = pos;
                if (!__atomic_compare_exchange_n(&slot->sequence, &claimed, pos + 1,
                        0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE))
                    break;  /* a receiver took us for dead and skipped the position */
                __atomic_add_fetch(&hdr->stat_requests, 1, __ATOMIC_RELAXED);
                reqrep_wake_consumers(h);
                *out_id = REQREP_MAKE_ID((uint32_t)rslot, gen);
                return 1;
            }
        } else if (diff < 0) {
            /* A cell published a lap ago with the head already past it was taken by a receiver
             * that has not marked it yet, or never will: mark it for the receiver. */
            uint64_t taken = pos - h->req_cap + 1;
            if (seq == taken && __atomic_load_n(&hdr->req_head, __ATOMIC_ACQUIRE) >= taken) {
                __atomic_compare_exchange_n(&slot->sequence, &seq, pos, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
                continue;
            }
            __atomic_add_fetch(&hdr->stat_send_full, 1, __ATOMIC_RELAXED);
            break;
        } else {
            /* Bounded: a peer-corrupted sequence would otherwise spin for ever. */
            if (tries >= REQREP_CANCEL_RETRIES) {
                __atomic_add_fetch(&hdr->stat_send_full, 1, __ATOMIC_RELAXED);
                break;
            }
            if (tries >= REQREP_SPIN_LIMIT) reqrep_spin_pause();
            pos = __atomic_load_n(&hdr->req_tail, __ATOMIC_RELAXED);
        }
    }
    reqrep_cancel(h, REQREP_MAKE_ID((uint32_t)rslot, gen));
    return 0;
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
        r = reqrep_int_try_send(h, value, out_id);
        if (r == 1) return 1;
        if (REQREP_INTERRUPTED(h)) return REQREP_EINTR;

        uint32_t *futex_word = (r == -3) ? &hdr->slot_futex : &hdr->send_futex;
        uint64_t *waiter_cnt = (r == -3) ? &hdr->slot_waiters : &hdr->send_waiters;

        uint32_t fseq = __atomic_load_n(futex_word, __ATOMIC_ACQUIRE);
        uint32_t epoch = reqrep_waiters_add(waiter_cnt);
        /* StoreLoad + re-check, as in reqrep_send_wait_reserving. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        { int r2 = reqrep_int_try_send(h, value, out_id);
          if (r2 == 1 || r2 != r) {
              reqrep_waiters_sub(waiter_cnt, epoch);
              if (r2 == 1) return r2;
              continue;
          } }
        /* Nothing wakes a slot waiter when holders die, or one waiting for room a receiver freed
         * and died before waking: only an attempt finds out, so look again every tick. */
        struct timespec tick = { REQREP_LOCK_TIMEOUT_SEC, 0 };
        struct timespec *pts = &tick;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                reqrep_waiters_sub(waiter_cnt, epoch);
                return r;
            }
            if (remaining.tv_sec < tick.tv_sec) pts = &remaining;
        }
        long rc = reqrep_futex_wait(futex_word, fseq, pts);
        int timed_out = rc == -1 && errno == ETIMEDOUT && pts != &tick;
        int interrupted = rc == -1 && errno == EINTR;
        reqrep_waiters_sub(waiter_cnt, epoch);
        r = reqrep_int_try_send(h, value, out_id);
        if (r == 1) return 1;
        if (timed_out) return r;
        if (interrupted) return REQREP_EINTR;
    }
}

/* A position claimed but never published blocks every receive behind it. Skip it once no live
 * process still names that claim; 1 if the cell is no longer an unpublished claim at pos. */
static int reqrep_int_skip_dead_claim(ReqRepHandle *h, ReqIntSlot *cell, uint64_t pos) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    uint64_t now_ns = (uint64_t)now.tv_sec * 1000000000ULL + (uint64_t)now.tv_nsec;
    if (h->last_claim_scan_ns && now_ns - h->last_claim_scan_ns < REQREP_RECOVERY_INTERVAL_NS) return 0;
    for (uint32_t i = 0; i < h->resp_slots; i++) {
        RespSlotHeader *slot = reqrep_resp_slot(h, i);
        if (__atomic_load_n(&slot->claim_pos, __ATOMIC_ACQUIRE) != pos) continue;
        uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
        if (REQREP_CTL_STATE(c) == RESP_ACQUIRED && reqrep_pid_alive(h, REQREP_CTL_PID(c))) {
            h->last_claim_scan_ns = now_ns;
            return 0;
        }
    }
    uint64_t expected = pos;
    if (!__atomic_compare_exchange_n(&cell->sequence, &expected, pos + h->req_cap,
            0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE))
        return 1;
    __atomic_add_fetch(&h->hdr->stat_recoveries, 1, __ATOMIC_RELAXED);
    uint64_t head = pos;
    __atomic_compare_exchange_n(&h->hdr->req_head, &head, pos + 1, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
    reqrep_wake_producers(h, 1);
    return 1;
}

static inline int reqrep_int_try_recv(ReqRepHandle *h, int64_t *out_value, uint64_t *out_id) {
    /* Now rather than in the dispatch, between taking a request and marking it received. */
    reqrep_proc_register(h);
    ReqRepHeader *hdr = h->hdr;
    ReqIntSlot *slots = (ReqIntSlot *)h->req_slots;
    uint32_t mask = h->req_cap_mask;
    uint64_t cap = h->req_cap;
    uint64_t pos = __atomic_load_n(&hdr->req_head, __ATOMIC_RELAXED);
    for (int tries = 0; ; tries++) {
        ReqIntSlot *slot = &slots[pos & mask];
        uint64_t seq = __atomic_load_n(&slot->sequence, __ATOMIC_ACQUIRE);
        if (seq == pos + 1) {
            int64_t value = slot->value;
            uint32_t resp_slot = slot->resp_slot, resp_gen = slot->resp_gen;
            /* Moving the head past the cell proves nobody else took or reused it since it was read. */
            uint64_t head = pos;
            if (__atomic_compare_exchange_n(&hdr->req_head, &head, pos + 1,
                    0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED)) {
                uint64_t published = pos + 1;
                __atomic_compare_exchange_n(&slot->sequence, &published, pos + cap, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
                *out_value = value;
                *out_id = REQREP_MAKE_ID(resp_slot, resp_gen);
                reqrep_slot_dispatch(h, *out_id);
                reqrep_wake_producers(h, 1);
                return 1;
            }
        } else if (seq >= pos + cap) {
            /* Skipped by a receiver that has not moved the head past it yet, or never will. */
            uint64_t head = pos;
            __atomic_compare_exchange_n(&hdr->req_head, &head, pos + 1, 0, __ATOMIC_ACQ_REL, __ATOMIC_RELAXED);
        } else if (seq != pos || __atomic_load_n(&hdr->req_tail, __ATOMIC_ACQUIRE) <= pos) {
            /* Nothing claimed here, or a corrupt cell. */
            __atomic_add_fetch(&hdr->stat_recv_empty, 1, __ATOMIC_RELAXED);
            return 0;
        } else if (tries < REQREP_SPIN_LIMIT) {
            reqrep_spin_pause();
        } else if (!reqrep_int_skip_dead_claim(h, slot, pos)) {
            __atomic_add_fetch(&hdr->stat_recv_empty, 1, __ATOMIC_RELAXED);
            return 0;
        }
        pos = __atomic_load_n(&hdr->req_head, __ATOMIC_RELAXED);
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
        if (REQREP_INTERRUPTED(h)) return REQREP_EINTR;
        uint32_t epoch = reqrep_waiters_add(&hdr->recv_waiters);
        /* StoreLoad + re-check, as in reqrep_recv_wait. */
        __atomic_thread_fence(__ATOMIC_SEQ_CST);
        if (reqrep_int_try_recv(h, out_value, out_id)) {
            reqrep_waiters_sub(&hdr->recv_waiters, epoch);
            return 1;
        }
        /* A sender that dies holding the claim in the way wakes nobody, and the one wake a send
         * gives may go to a receiver killed as it came: look again every tick. */
        struct timespec tick = { REQREP_LOCK_TIMEOUT_SEC, 0 };
        struct timespec *pts = &tick;
        if (has_deadline) {
            if (!reqrep_remaining_time(&deadline, &remaining)) {
                reqrep_waiters_sub(&hdr->recv_waiters, epoch);
                return 0;
            }
            if (remaining.tv_sec < tick.tv_sec) pts = &remaining;
        }
        long rc = reqrep_futex_wait(&hdr->recv_futex, fseq, pts);
        int err = rc == -1 ? errno : 0;
        reqrep_waiters_sub(&hdr->recv_waiters, epoch);
        if (reqrep_int_try_recv(h, out_value, out_id)) return 1;
        if (err == ETIMEDOUT && pts != &tick) return 0;
        if (err == EINTR) return REQREP_EINTR;
    }
}

static int reqrep_int_reply(ReqRepHandle *h, uint64_t id, int64_t value) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    uint32_t gen = REQREP_ID_GEN(id);
    if (slot_idx >= h->resp_slots) return -1;

    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint32_t mypid = reqrep_self_pid();
    uint32_t owner;
    if (!reqrep_slot_take_write(slot, gen, mypid, &owner)) return -2;

    *(int64_t *)((uint8_t *)slot + sizeof(RespSlotHeader)) = value;
    return reqrep_slot_publish(h, slot, gen, owner, mypid);
}

static int reqrep_int_try_get(ReqRepHandle *h, uint64_t id, int64_t *out_value) {
    uint32_t slot_idx = REQREP_ID_SLOT(id);
    if (slot_idx >= h->resp_slots) return -1;

    RespSlotHeader *slot = reqrep_resp_slot(h, slot_idx);
    uint64_t c = __atomic_load_n(&slot->ctl, __ATOMIC_ACQUIRE);
    int r = reqrep_slot_readable(c, REQREP_ID_GEN(id));
    if (r != 1) return r;
    int64_t v = *(int64_t *)((uint8_t *)slot + sizeof(RespSlotHeader));
    if (!reqrep_slot_take_reply(h, slot, c)) return -4;
    *out_value = v;
    return 1;
}

static int reqrep_int_get_wait(ReqRepHandle *h, uint64_t id, int64_t *out_value,
                                double timeout) {
    int r = reqrep_int_try_get(h, id, out_value);
    if (r != 0 || timeout == 0) return r;
    struct timespec deadline;
    if (timeout > 0) reqrep_make_deadline(timeout, &deadline);
    for (;;) {
        r = reqrep_await_reply(h, id, timeout > 0 ? &deadline : NULL);
        if (r != 1) return r;
        r = reqrep_int_try_get(h, id, out_value);
        if (r != 0) return r;
    }
}

/* See reqrep_request_step. */
static int reqrep_int_request_step(ReqRepHandle *h, int64_t req_value, int64_t *out_value,
                                   double timeout, uint64_t *inflight) {
    uint64_t id = *inflight;
    struct timespec deadline;
    int has_deadline = (timeout > 0);
    if (has_deadline) reqrep_make_deadline(timeout, &deadline);
    if (!id) {
        int r = reqrep_int_send_wait(h, req_value, &id, timeout);
        if (r != 1) return r;
        *inflight = id;
    }
    double get_timeout = timeout;
    if (has_deadline) {
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        get_timeout = (double)(deadline.tv_sec - now.tv_sec) +
                      (double)(deadline.tv_nsec - now.tv_nsec) / 1e9;
        if (get_timeout <= 0) {
            reqrep_cancel(h, id);
            reqrep_drop_reply(h, id);
            *inflight = 0;
            return 0;
        }
    }
    int r = reqrep_int_get_wait(h, id, out_value, get_timeout);
    if (r == REQREP_EINTR) return r;
    *inflight = 0;
    if (r != 1) {
        reqrep_cancel(h, id);
        reqrep_drop_reply(h, id);
    }
    return r;
}

static inline int reqrep_int_request(ReqRepHandle *h, int64_t req_value, int64_t *out_value,
                              double timeout) {
    uint64_t inflight = 0;
    struct timespec deadline;
    if (timeout > 0) reqrep_make_deadline(timeout, &deadline);
    int r;
    while ((r = reqrep_int_request_step(h, req_value, out_value, timeout, &inflight)) == REQREP_EINTR)
        if (timeout > 0) timeout = reqrep_time_left(&deadline);
    return r;
}

static inline uint64_t reqrep_int_size(ReqRepHandle *h) {
    /* Head before tail keeps the difference non-negative; a head not yet moved past a taken cell
     * can trail the tail by one more than the capacity. */
    uint64_t head = __atomic_load_n(&h->hdr->req_head, __ATOMIC_RELAXED);
    uint64_t tail = __atomic_load_n(&h->hdr->req_tail, __ATOMIC_RELAXED);
    uint64_t n = (tail >= head) ? (tail - head) : 0;
    return n > h->req_cap ? h->req_cap : n;
}

static void reqrep_int_clear(ReqRepHandle *h) {
    ReqRepHeader *hdr = h->hdr;

    /* Taken as a receiver takes them: a sender still writing its claim keeps its cell, and the
     * drain stops there. */
    uint64_t end = __atomic_load_n(&hdr->req_tail, __ATOMIC_ACQUIRE);
    int64_t value;
    uint64_t id;
    while (__atomic_load_n(&hdr->req_head, __ATOMIC_ACQUIRE) < end && reqrep_int_try_recv(h, &value, &id))
        reqrep_cancel(h, id);

    reqrep_clear_slots(h);

    reqrep_broadcast(&hdr->slot_futex, &hdr->slot_waiters);
    reqrep_broadcast(&hdr->send_futex, &hdr->send_waiters);
    reqrep_wake_consumers(h);
}

#endif /* REQREP_H */
