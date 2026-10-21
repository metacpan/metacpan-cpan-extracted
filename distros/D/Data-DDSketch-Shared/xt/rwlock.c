#include <string.h>
#include <errno.h>
#include <sys/wait.h>
#include <sched.h>
#include <assert.h>

static int fail_path_copy;
static char *test_strdup(const char *s) {
    if (fail_path_copy) { errno = ENOMEM; return NULL; }
    return strdup(s);
}
#define strdup test_strdup
#include "ddsketch.h"
#undef strdup

#define WORKERS 4
#define ROUNDS 20000
static DdHandle *handles[WORKERS];
static uint32_t failed;
static pthread_barrier_t start;
static DdHandle *recovery_peer;
static uint32_t recovery_done;
static uint64_t recovered_count;

static void *recover(void *arg) {
    (void)arg;
    dd_rwlock_rdlock(recovery_peer);
    recovered_count = recovery_peer->hdr->total_count;
    dd_rwlock_rdunlock(recovery_peer);
    __atomic_store_n(&recovery_done, 1, __ATOMIC_RELEASE);
    return NULL;
}

static void *contend(void *arg) {
    unsigned idx = (unsigned)(uintptr_t)arg;
    DdHandle *h = handles[idx];
    pthread_barrier_wait(&start);
    for (unsigned i = 0; i < ROUNDS; i++) {
        if (idx < 2) {
            dd_rwlock_wrlock(h);
            dd_insert_locked(h, 2.0, 1);
            h->hdr->stat_ops++;
            dd_rwlock_wrunlock(h);
        } else {
            dd_rwlock_rdlock(h);
            if (h->hdr->sum != 2.0 * (double)h->hdr->total_count)
                __atomic_store_n(&failed, 1, __ATOMIC_RELAXED);
            dd_rwlock_rdunlock(h);
        }
    }
    return NULL;
}

int main(void) {
    alarm(30);
    char err[DD_ERR_BUFLEN];
    DdHandle *h = dd_create_memfd("rwlock-test", .01, 2048, err);
    assert(h);

    int ready[2];
    assert(pipe(ready) == 0);
    pid_t child = fork();
    assert(child >= 0);
    if (!child) {
        close(ready[0]);
        dd_rwlock_rdlock(h);
        assert(write(ready[1], "r", 1) == 1);
        pause();
        _exit(2);
    }
    close(ready[1]);
    char token;
    assert(read(ready[0], &token, 1) == 1);
    close(ready[0]);
    assert(kill(child, SIGKILL) == 0);
    while (dd_pid_alive((uint32_t)child)) sched_yield();
    dd_rwlock_wrlock(h);   /* recover the unreaped dead reader */
    dd_insert_locked(h, 2.0, 1);
    dd_rwlock_wrunlock(h);
    assert(waitpid(child, NULL, 0) == child);
    assert(h->hdr->total_count == 1);

    dd_rwlock_rdlock(h);
    child = fork();
    assert(child >= 0);
    if (!child) {
        dd_rwlock_wrlock(h);   /* cannot drain the parent's live read lock */
        _exit(2);
    }
    while (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != DD_RWLOCK_WR(child))
        sched_yield();
    assert(kill(child, SIGKILL) == 0);
    while (dd_pid_alive((uint32_t)child)) sched_yield();
    dd_rwlock_rdlock(h);   /* recovering while reading must not wait on itself */
    assert(h->hdr->sum == 2.0);
    dd_rwlock_rdunlock(h);
    dd_rwlock_rdunlock(h);
    assert(waitpid(child, NULL, 0) == child);

    dd_rwlock_wrlock(h);
    dd_clear_locked(h);
    dd_rwlock_wrunlock(h);
    recovery_peer = dd_open_fd(h->backing_fd, err);
    assert(recovery_peer);
    assert(__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) == 0);
    assert(pipe(ready) == 0);
    child = fork();
    assert(child >= 0);
    if (!child) {
        close(ready[0]);
        dd_rwlock_wrlock(h);
        dd_pos(h)[h->bias]++;   /* killed between the bucket and total updates */
        assert(write(ready[1], "r", 1) == 1);
        pause();
        _exit(2);
    }
    close(ready[1]);
    assert(read(ready[0], &token, 1) == 1);
    close(ready[0]);
    assert(kill(child, SIGKILL) == 0);
    assert(waitpid(child, NULL, 0) == child);
    dd_rdepth_inc(h);   /* a reader resumes before rechecking the writer gate */
    pthread_t recovery;
    assert(pthread_create(&recovery, NULL, recover, NULL) == 0);
    while (!__atomic_load_n(&recovery_done, __ATOMIC_ACQUIRE) &&
           __atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != DD_RWLOCK_WR(getpid()))
        sched_yield();
    usleep(10000);
    dd_rdepth_dec(h);
    dd_reader_wake_drain(h);
    assert(pthread_join(recovery, NULL) == 0);
    assert(recovered_count == 1);
    dd_destroy(recovery_peer);
    dd_rwlock_wrlock(h);
    dd_clear_locked(h);
    dd_rwlock_wrunlock(h);
    pthread_t threads[WORKERS];
    assert(pthread_barrier_init(&start, NULL, WORKERS) == 0);
    for (unsigned i = 0; i < WORKERS; i++) {
        handles[i] = dd_open_fd(h->backing_fd, err);
        assert(handles[i]);
        assert(pthread_create(&threads[i], NULL, contend, (void *)(uintptr_t)i) == 0);
    }
    for (unsigned i = 0; i < WORKERS; i++) {
        assert(pthread_join(threads[i], NULL) == 0);
        dd_destroy(handles[i]);
    }
    pthread_barrier_destroy(&start);
    assert(!failed);
    assert(h->hdr->total_count == 2 * ROUNDS);
    assert(h->hdr->stat_ops == 2 * ROUNDS);
    assert(h->hdr->sum == 4.0 * ROUNDS);

    int fd = dup(h->backing_fd);
    assert(fd >= 0);
    void *base = mmap(NULL, h->mmap_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    assert(base != MAP_FAILED);
    fail_path_copy = 1;
    assert(dd_setup(base, h->mmap_size, "backing.dd", fd) == NULL);
    assert(fcntl(fd, F_GETFD) == -1 && errno == EBADF);
    unsigned char resident;
    assert(mincore(base, 4096, &resident) == -1 && errno == ENOMEM);
    dd_destroy(h);
    return 0;
}
