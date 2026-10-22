#include <string.h>
#include <errno.h>
#include <sys/wait.h>

static int fail_path_alloc;
static char *checked_strdup(const char *s) {
    if (fail_path_alloc) { errno = ENOMEM; return NULL; }
    return strdup(s);
}
#define strdup checked_strdup
#include "hll.h"
#undef strdup

static int child_ok(pid_t pid) {
    int status;
    return waitpid(pid, &status, 0) == pid && WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

static HllHandle *fresh(void) {
    char err[HLL_ERR_BUFLEN];
    HllHandle *h = hll_create(NULL, 10, 0600, err);
    if (h) { hll_rwlock_rdlock(h); hll_rwlock_rdunlock(h); }
    return h;
}

static int setup_failure(void) {
    int fd = memfd_create("setup-failure", MFD_CLOEXEC);
    size_t size = hll_total_size(1024);
    if (fd < 0 || ftruncate(fd, size)) return 1;
    void *base = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == MAP_FAILED) { close(fd); return 1; }
    hll_init_header(base, 10, 1024, size);
    fail_path_alloc = 1;
    HllHandle *h = hll_setup(base, size, "backing.hll", fd);
    if (h) { hll_destroy(h); return 1; }
    if (fcntl(fd, F_GETFD) != -1 || errno != EBADF) { close(fd); return 1; }
    unsigned char vec;
    int rc = mincore(base, 1, &vec);
    if (rc == 0) { munmap(base, size); return 1; }
    return errno != ENOMEM;
}

static int dead_holder(int writer, int zombie) {
    HllHandle *h = fresh();
    if (!h) return 1;
    pid_t pid = fork();
    if (pid < 0) { hll_destroy(h); return 1; }
    if (!pid) {
        alarm(10);
        if (writer) hll_rwlock_wrlock(h); else hll_rwlock_rdlock(h);
        _exit(0);
    }
    siginfo_t info;
    int ok = zombie ? waitid(P_PID, pid, &info, WEXITED | WNOWAIT) == 0 : child_ok(pid);
    if (ok) {
        hll_rwlock_wrlock(h);
        ok = hll_add_locked(h, "after-crash", 11) == 1;
        hll_rwlock_wrunlock(h);
        hll_rwlock_rdlock(h);
        ok = ok && hll_count_locked(h) >= 1;
        hll_rwlock_rdunlock(h);
    }
    if (zombie) ok = child_ok(pid) && ok;
    hll_destroy(h);
    return !ok;
}

static int stress(void) {
    HllHandle *h = fresh();
    if (!h) return 1;
    pid_t pids[6];
    int started = 0, ok = 1;
    for (int k = 0; k < 6; k++) {
        pid_t pid = fork();
        if (pid < 0) { ok = 0; break; }
        if (!pid) {
            alarm(20);
            uint8_t *regs = hll_regs(h);
            uint64_t last = 0;
            for (int i = 0; i < 20000; i++) {
                if (k < 4) {
                    hll_rwlock_wrlock(h);
                    uint8_t v = i % 50 + 1;
                    __atomic_store_n(&regs[0], v, __ATOMIC_RELAXED);
                    __atomic_store_n(&regs[1], v, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
                    hll_rwlock_wrunlock(h);
                } else {
                    hll_rwlock_rdlock(h);
                    uint8_t a = __atomic_load_n(&regs[0], __ATOMIC_RELAXED);
                    uint8_t b = __atomic_load_n(&regs[1], __ATOMIC_RELAXED);
                    uint64_t ops = __atomic_load_n(&h->hdr->stat_ops, __ATOMIC_RELAXED);
                    hll_rwlock_rdunlock(h);
                    if (a != b || ops < last) _exit(2);
                    last = ops;
                }
            }
            hll_destroy(h);
            _exit(0);
        }
        pids[started++] = pid;
    }
    for (int k = 0; k < started; k++) ok = child_ok(pids[k]) && ok;
    ok = ok && h->hdr->stat_ops == 80000;
    hll_destroy(h);
    return !ok;
}

static int publication(const char *path) {
    char err[HLL_ERR_BUFLEN];
    HllHandle *h = hll_create(path, 10, 0600, err);
    if (!h) return 1;
    hll_rwlock_rdlock(h); hll_rwlock_rdunlock(h);
    pid_t pid = fork();
    if (pid < 0) { hll_destroy(h); unlink(path); return 1; }
    if (!pid) {
        alarm(10);
        for (int i = 0; i < 10000; i++) {
            hll_rwlock_wrlock(h);
            hll_add_locked(h, &i, sizeof i);
            hll_rwlock_wrunlock(h);
        }
        _exit(hll_freeze(h) != 0);
    }
    HllHandle *ro = NULL;
    for (int i = 0; i < 5000 && !ro; i++) {
        ro = hll_open_readonly(path, err);
        if (!ro && !strstr(err, "not frozen")) break;
        if (!ro) usleep(1000);
    }
    double count = ro ? hll_count_locked(ro) : 0;
    int ok = child_ok(pid) && ro && count > 9000 && count < 11000 && count == hll_count_locked(h);
    hll_destroy(ro);
    hll_destroy(h);
    unlink(path);
    return !ok;
}

int main(int argc, char **argv) {
    alarm(30);
    if (argc < 2) return 2;
    if (!strcmp(argv[1], "allocation")) return setup_failure();
    if (!strcmp(argv[1], "writer")) return dead_holder(1, 0);
    if (!strcmp(argv[1], "reader")) return dead_holder(0, 0);
    if (!strcmp(argv[1], "zombie-writer")) return dead_holder(1, 1);
    if (!strcmp(argv[1], "zombie-reader")) return dead_holder(0, 1);
    if (!strcmp(argv[1], "stress")) return stress();
    if (!strcmp(argv[1], "publication") && argc == 3) return publication(argv[2]);
    return 2;
}
