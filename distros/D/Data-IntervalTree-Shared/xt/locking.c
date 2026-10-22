#include <stdint.h>
#include <time.h>
#include <unistd.h>

static uint32_t *claim_word, *drain_word, *claim_ready, *drain_ready;
static void pause_slot_reset(void *word);
static long lock_syscall(long n, uint32_t *word, int op, uint32_t val,
                         const struct timespec *timeout, void *a, int b);

/* Pause a claimant after its pid is published, until the writer starts draining. */
#define __atomic_store_n(p, v, o) (pause_slot_reset((void *)(p)), __atomic_store_n(p, v, o))
#define __atomic_exchange_n(p, v, o) (pause_slot_reset((void *)(p)), __atomic_exchange_n(p, v, o))
#define syscall lock_syscall
#include "intervaltree.h"
#undef syscall
#undef __atomic_store_n
#undef __atomic_exchange_n
#include <sys/wait.h>

#define CHECK(expr) do { if (!(expr)) { fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, #expr); exit(1); } } while (0)

static void pause_slot_reset(void *word) {
    if (!claim_word || word != claim_word) return;
    __atomic_store_n(claim_ready, 1, __ATOMIC_RELEASE);
    while (!__atomic_load_n(drain_ready, __ATOMIC_ACQUIRE)) it_rwlock_spin_pause();
    claim_word = NULL;
}

static long lock_syscall(long n, uint32_t *word, int op, uint32_t val,
                         const struct timespec *timeout, void *a, int b) {
    if (drain_word && word == drain_word && op == FUTEX_WAIT)
        __atomic_store_n(drain_ready, 1, __ATOMIC_RELEASE);
    return syscall(n, word, op, val, timeout, a, b);
}

static ItHandle *tree(const char *path, uint32_t capacity) {
    char err[IT_ERR_BUFLEN];
    ItHandle *h = it_create(path, capacity, 0600, err);
    if (!h) { fprintf(stderr, "%s\n", err); exit(1); }
    return h;
}

static void reap(pid_t pid) {
    int status;
    CHECK(waitpid(pid, &status, 0) == pid);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0);
}

static void dead_holders(void) {
    for (int writer = 0; writer <= 1; writer++) {
        ItHandle *h = tree(NULL, 16);
        it_rwlock_wrlock(h);
        CHECK(it_add_locked(h, 10, 20, 1) == 0);
        it_build_locked(h);
        it_rwlock_wrunlock(h);
        int ready[2];
        CHECK(pipe(ready) == 0);
        pid_t pid = fork();
        CHECK(pid >= 0);
        if (pid == 0) {
            alarm(45);
            close(ready[0]);
            if (writer) {
                it_rwlock_wrlock(h);
                CHECK(it_add_locked(h, 12, 18, 2) == 1);
            } else {
                it_rwlock_rdlock(h);
            }
            CHECK(write(ready[1], "x", 1) == 1);
            for (;;) pause();
        }
        close(ready[1]);
        char byte;
        CHECK(read(ready[0], &byte, 1) == 1);
        close(ready[0]);
        CHECK(kill(pid, SIGKILL) == 0);
        siginfo_t info;
        CHECK(waitid(P_PID, pid, &info, WEXITED | WNOWAIT) == 0);
        it_rwlock_wrlock(h);
        CHECK(h->hdr->count == (uint64_t)(writer + 1));
        if (h->hdr->dirty) it_build_locked(h);
        ItRes hits[16];
        CHECK(it_overlaps_locked(h, 15, 15, hits, 16) == h->hdr->count);
        it_rwlock_wrunlock(h);
        int status;
        CHECK(waitpid(pid, &status, 0) == pid);
        CHECK(WIFSIGNALED(status) && WTERMSIG(status) == SIGKILL);
        it_destroy(h);
    }
}

typedef struct {
    uint32_t ready, start, finished;
    uint64_t max_wait_ns;
} Control;

static uint64_t now_ns(void) {
    struct timespec ts;
    CHECK(clock_gettime(CLOCK_MONOTONIC, &ts) == 0);
    return (uint64_t)ts.tv_sec * 1000000000 + (uint64_t)ts.tv_nsec;
}

static void reclamation(void) {
    ItHandle *h = tree(NULL, 16);
    uint32_t *flags = mmap(NULL, 8, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    CHECK(flags != MAP_FAILED);
    claim_ready = flags;
    drain_ready = flags + 1;
    drain_word = &h->hdr->drain_seq;
    pid_t pid = fork();
    CHECK(pid >= 0);
    if (pid == 0) {
        alarm(45);
        uint32_t slot = (uint32_t)getpid() % IT_READER_SLOTS;
        claim_word = &h->reader_slots[slot].rdepth;
        __atomic_store_n(claim_word, 1, __ATOMIC_RELAXED);
        it_occ_set(h, slot);
        it_claim_reader_slot(h);
        it_destroy(h);
        _exit(0);
    }
    while (!__atomic_load_n(claim_ready, __ATOMIC_ACQUIRE)) it_rwlock_spin_pause();
    uint64_t begin = now_ns();
    it_rwlock_wrlock(h);
    uint64_t elapsed = now_ns() - begin;
    it_rwlock_wrunlock(h);
    reap(pid);
    printf("# slot reclamation wait: %.3f ms\n", elapsed / 1000000.0);
    CHECK(elapsed < (uint64_t)IT_LOCK_TIMEOUT_SEC * 1000000000);
    drain_word = NULL;
    CHECK(munmap(flags, 8) == 0);
    it_destroy(h);
}

static void mixed(void) {
    ItHandle *h = tree(NULL, 64);
    Control *ctrl = mmap(NULL, sizeof(*ctrl), PROT_READ | PROT_WRITE,
                        MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    CHECK(ctrl != MAP_FAILED);
    enum { KIDS = 6, WRITERS = 2, ROUNDS = 12000 };
    pid_t pids[KIDS];
    it_claim_reader_slot(h);
    for (int child = 0; child < KIDS; child++) {
        CHECK((pids[child] = fork()) >= 0);
        if (pids[child] != 0) continue;
        alarm(45);
        __atomic_add_fetch(&ctrl->ready, 1, __ATOMIC_RELEASE);
        while (!__atomic_load_n(&ctrl->start, __ATOMIC_ACQUIRE)) it_rwlock_spin_pause();
        ItRes hits[64];
        for (int round = 0; round < ROUNDS ||
             (child >= WRITERS && __atomic_load_n(&ctrl->finished, __ATOMIC_ACQUIRE) < WRITERS); round++) {
            uint64_t begin = now_ns();
            if (child < WRITERS) it_rwlock_wrlock(h); else it_rwlock_rdlock(h);
            uint64_t elapsed = now_ns() - begin;
            uint64_t prev = __atomic_load_n(&ctrl->max_wait_ns, __ATOMIC_RELAXED);
            while (elapsed > prev && !__atomic_compare_exchange_n(&ctrl->max_wait_ns,
                    &prev, elapsed, 0, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {}
            if (child < WRITERS) {
                if (h->hdr->count == h->capacity) it_clear_locked(h);
                uint64_t id = h->hdr->count;
                CHECK(it_add_locked(h, (int64_t)id, 100, id) == (int64_t)id);
                it_build_locked(h);
            }
            uint64_t n = it_overlaps_locked(h, 64, 64, hits, 64);
            CHECK(n == h->hdr->count);
            for (uint64_t i = 0; i < n; i++) {
                CHECK(hits[i].id == i && hits[i].lo == (int64_t)i && hits[i].hi == 100);
            }
            if (child < WRITERS) it_rwlock_wrunlock(h); else it_rwlock_rdunlock(h);
        }
        if (child < WRITERS) __atomic_add_fetch(&ctrl->finished, 1, __ATOMIC_RELEASE);
        it_destroy(h);
        _exit(0);
    }
    while (__atomic_load_n(&ctrl->ready, __ATOMIC_ACQUIRE) < KIDS) it_rwlock_spin_pause();
    __atomic_store_n(&ctrl->start, 1, __ATOMIC_RELEASE);
    for (int i = 0; i < KIDS; i++) reap(pids[i]);
    printf("# maximum live lock wait: %.3f ms\n", ctrl->max_wait_ns / 1000000.0);
    CHECK(ctrl->max_wait_ns < (uint64_t)IT_LOCK_TIMEOUT_SEC * 1000000000);
    CHECK(munmap(ctrl, sizeof(*ctrl)) == 0);
    it_destroy(h);
}

static void freezing(const char *path) {
    ItHandle *h = tree(path, 50000);
    it_rwlock_wrlock(h);
    for (int i = 0; i < 50000; i++) CHECK(it_add_locked(h, i, 50000, i) == i);
    it_rwlock_wrunlock(h);
    int ready[2];
    CHECK(pipe(ready) == 0);
    pid_t pid = fork();
    CHECK(pid >= 0);
    if (pid == 0) {
        alarm(45);
        close(ready[0]);
        char err[IT_ERR_BUFLEN];
        CHECK(it_open_readonly(path, err) == NULL);
        CHECK(strstr(err, "not frozen") != NULL);
        CHECK(write(ready[1], "x", 1) == 1);
        close(ready[1]);
        ItHandle *ro;
        while (!(ro = it_open_readonly(path, err))) CHECK(strstr(err, "not frozen") != NULL);
        CHECK(ro->hdr->dirty == 0);
        ItRes *hits = malloc(ro->capacity * sizeof(*hits));
        CHECK(hits != NULL);
        CHECK(it_overlaps_locked(ro, 50000, 50000, hits, ro->capacity) == 50000);
        for (int i = 0; i < 50000; i++) CHECK(hits[i].id == (uint64_t)i && hits[i].lo == i && hits[i].hi == 50000);
        free(hits);
        it_destroy(ro);
        it_destroy(h);
        _exit(0);
    }
    close(ready[1]);
    char byte;
    CHECK(read(ready[0], &byte, 1) == 1);
    close(ready[0]);
    CHECK(it_freeze(h) == 0);
    reap(pid);
    it_destroy(h);
}

int main(int argc, char **argv) {
    alarm(45);
    CHECK(argc >= 2);
    if (!strcmp(argv[1], "dead")) dead_holders();
    else if (!strcmp(argv[1], "mixed")) mixed();
    else if (!strcmp(argv[1], "reclaim")) reclamation();
    else { CHECK(argc == 3 && !strcmp(argv[1], "freeze")); freezing(argv[2]); }
    return 0;
}
