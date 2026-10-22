#include <unistd.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <time.h>
#include <pthread.h>
#include <sys/wait.h>
#include <stdint.h>

static int observe_wakes, wake_sent;
static long observed_futex(long nr, uint32_t *addr, int op, uint32_t val,
                           const struct timespec *timeout, void *addr2, int val2) {
    if (observe_wakes) {
        if (op == FUTEX_WAKE) wake_sent = 1;
        return 0;
    }
    return syscall(nr, addr, op, val, timeout, addr2, val2);
}

#define syscall observed_futex
#include "minhash.h"
#undef syscall

#define ROUNDS 500000
static pthread_barrier_t gate;
static MnhHandle *handle;
static int blocked, recover, draining;

static void *unlocker(void *arg) {
    (void)arg;
    for (unsigned i = 0; i < ROUNDS; i++) {
        pthread_barrier_wait(&gate);
        if (draining) {
            uint32_t expected = 0;
            __atomic_compare_exchange_n(&handle->hdr->wlock, &expected,
                MNH_RWLOCK_WR(getpid()), 0, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED);
            blocked = __atomic_load_n(&handle->reader_slots[handle->my_slot_idx].rdepth,
                                     __ATOMIC_SEQ_CST) != 0;
        } else if (recover) mnh_recover_stale_lock(handle, MNH_RWLOCK_WR(getpid()));
        else mnh_rwlock_wrunlock(handle);
        pthread_barrier_wait(&gate);
    }
    return NULL;
}

static void *waiter(void *arg) {
    (void)arg;
    for (unsigned i = 0; i < ROUNDS; i++) {
        pthread_barrier_wait(&gate);
        if (draining) {
            mnh_rdepth_dec(handle);
            mnh_reader_wake_drain(handle);
        } else {
            mnh_park(handle);
            blocked = __atomic_load_n(&handle->hdr->wlock, __ATOMIC_SEQ_CST) != 0;
        }
        pthread_barrier_wait(&gate);
    }
    return NULL;
}

static int check_wakes(int kind) {
    pthread_t u, w;
    unsigned missed = 0;
    recover = kind == 1;
    draining = kind == 2;
    observe_wakes = 1;
    if (pthread_barrier_init(&gate, NULL, 3) ||
        pthread_create(&u, NULL, unlocker, NULL) ||
        pthread_create(&w, NULL, waiter, NULL)) return 1;
    for (unsigned i = 0; i < ROUNDS; i++) {
        __atomic_store_n(&handle->hdr->wlock, draining ? 0 : MNH_RWLOCK_WR(getpid()), __ATOMIC_RELAXED);
        __atomic_store_n(&handle->hdr->rwait, 0, __ATOMIC_RELAXED);
        __atomic_store_n(&handle->reader_slots[handle->my_slot_idx].rdepth,
                         draining ? 1 : 0, __ATOMIC_RELAXED);
        wake_sent = 0;
        pthread_barrier_wait(&gate);
        pthread_barrier_wait(&gate);
        if (!wake_sent && blocked) missed++;
    }
    pthread_join(u, NULL);
    pthread_join(w, NULL);
    pthread_barrier_destroy(&gate);
    observe_wakes = 0;
    __atomic_store_n(&handle->hdr->rwait, 0, __ATOMIC_RELAXED);
    mnh_rwlock_wrunlock(handle);
    printf("# %s: %u missed wakes\n", draining ? "reader drain" : recover ? "recovery unlock" : "normal unlock", missed);
    return missed != 0;
}

static int check_dead_owner(int reader) {
    int ready[2], status;
    char byte;
    if (pipe(ready)) return 1;
    pid_t child = fork();
    if (child == -1) return 1;
    if (child == 0) {
        close(ready[0]);
        if (reader) mnh_rwlock_rdlock(handle);
        else mnh_rwlock_wrlock(handle);
        if (write(ready[1], "x", 1) != 1) _exit(1);
        for (;;) pause();
    }
    close(ready[1]);
    if (read(ready[0], &byte, 1) != 1) return 1;
    close(ready[0]);
    if (kill(child, SIGKILL)) return 1;
    /* Keep the dead holder unreaped to exercise zombie recovery. */
    mnh_rwlock_wrlock(handle);
    mnh_rwlock_wrunlock(handle);
    if (waitpid(child, &status, 0) != child || !WIFSIGNALED(status) ||
        WTERMSIG(status) != SIGKILL) return 1;
    printf("# recovered dead %s\n", reader ? "reader" : "writer");
    return 0;
}

int main(void) {
    char err[MNH_ERR_BUFLEN];
    alarm(60);
    handle = mnh_create(NULL, 64, 0600, err);
    if (!handle) return 1;
    mnh_claim_reader_slot(handle);
    int failed = check_wakes(0) | check_wakes(1);
    failed |= check_dead_owner(1) | check_dead_owner(0);
    mnh_destroy(handle);
    return failed;
}
