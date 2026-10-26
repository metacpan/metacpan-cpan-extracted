/**
 * @file Parataxis.c
 * @brief Low-level Green Threads (Fibers) and Hybrid Thread Pool for Perl.
 *
 * @section Overview
 * This file implements a cooperative multitasking system (Fibers) integrated with a preemptive native thread pool. It
 * allows Perl to run thousands of user-mode fibers that can offload blocking C-level tasks to background OS threads
 * without stalling the main interpreter.
 *
 * @section Architecture
 * - **Fibers**: The primitive unit of execution. Each fiber has its own OS context and a complete set of Perl
 * interpreter stacks (Argument, Mark, Scope, Save, Mortal).
 * - **Coroutines**: The execution pattern (yield/call/transfer) used by fibers to pass control.
 * - **Thread Pool**: A fixed pool of worker threads that poll a job queue for blocking operations like sleep, I/O, or
 * heavy computation.
 * - **Context Switching**: The `swap_perl_state` function manually saves and restores the global state of the Perl
 * interpreter (`PL_*` variables) to allow disjoint execution flows.
 *
 * @section Caveats
 * Shared subroutines (CVs) with re-entrant yielding calls are handled by a specialized pad-clearing mechanism in
 * `_activate_current_depths` to satisfy Perl's internal `AvFILLp`/`AvREAL` assertions in DEBUGGING builds.
 */

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0601
#endif
#else
/*
 * glibc exposes POSIX declarations only when a feature-test macro asks for them, but NetBSD and DragonFly go the other
 * way and hide their own types behind one. NetBSD's <sys/types.h> keeps u_int and devmajor_t behind _NETBSD_SOURCE,
 * which <sys/featuretest.h> only defines on its own when no other major macro is set, so define it explicitly (the
 * documented union namespace takes care of the rest). DragonFly's <sys/cdefs.h> derives _POSIX_C_SOURCE from
 * _XOPEN_SOURCE, never assigns __BSD_VISIBLE in that branch, and its footer then defaults that to 0, so
 * <sys/types.h> skips the u_int that <sys/sysctl.h> prototypes use; its default namespace already shows everything,
 * so leave the macro off there.
 */
#if !defined(__DragonFly__) && !defined(_XOPEN_SOURCE)
#define _XOPEN_SOURCE 600
#endif
#if defined(__NetBSD__) && !defined(_NETBSD_SOURCE)
#define _NETBSD_SOURCE
#endif
#ifndef _BSD_SOURCE
#define _BSD_SOURCE
#endif
#ifndef _DEFAULT_SOURCE
#define _DEFAULT_SOURCE
#endif
#ifdef __APPLE__
#ifndef _DARWIN_C_SOURCE
#define _DARWIN_C_SOURCE
#endif
#endif
#endif

/*
 * Assembly-based coroutine context switching.
 *
 * glibc's swapcontext() saves/restores the signal mask (rt_sigprocmask) on every context switch which dominates the
 * cost of fiber switches. On x86_64 we instead switch with a tiny assembly routine that only saves the callee-saved
 * registers and the stack pointer, avoiding the syscall entirely. All other platforms keep the portable ucontext path
 * for now...
 *
 * This has to be decided before the includes below: OpenBSD ships no <ucontext.h> at all, so the assembly path must
 * be able to skip it, and Haiku ships no <sys/syscall.h>.
 */
#if defined(__x86_64__) && !defined(_WIN32) && defined(__ELF__)
#define USE_ASM_CORO 1
#endif

#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "XSUB.h"
#include "perl.h"

#ifdef _WIN32
/** @brief Export macro for Windows DLLs */
#define DLLEXPORT __declspec(dllexport)
/** @brief Handle for the underlying OS fiber context */
typedef LPVOID coro_handle_t;
/** @brief Handle for a native OS thread */
typedef HANDLE para_thread_t;
/** @brief Mutex type for queue synchronization */
typedef CRITICAL_SECTION para_mutex_t;
#define LOCK(m) EnterCriticalSection(&m)
#define UNLOCK(m) LeaveCriticalSection(&m)
#define LOCK_INIT(m) InitializeCriticalSection(&m)
#else
#include <pthread.h>
#include <sched.h>
#include <signal.h>
#include <sys/select.h>
#include <sys/socket.h>
#ifndef __HAIKU__
#include <sys/syscall.h>
#endif
#include <sys/time.h>
#include <time.h>
#include <errno.h>
#ifndef USE_ASM_CORO
#include <ucontext.h>
#endif
#include <unistd.h>
#include <sys/mman.h>
#include <sys/resource.h>
#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__NetBSD__) || defined(__DragonFly__)
#include <sys/sysctl.h>
#include <sys/types.h>
#endif
/** @brief Export macro for Unix systems */
#define DLLEXPORT __attribute__((visibility("default")))
#ifdef USE_ASM_CORO
/** @brief Handle for the underlying OS fiber context (only the assembly path's rsp slot is used) */
typedef void * coro_handle_t;
#else
/** @brief Handle for the underlying OS fiber context (ucontext_t) */
typedef ucontext_t coro_handle_t;
#endif
/** @brief Handle for a native OS thread (pthread_t) */
typedef pthread_t para_thread_t;
/** @brief Mutex type for queue synchronization (pthread_mutex_t) */
typedef pthread_mutex_t para_mutex_t;
#define LOCK(m) pthread_mutex_lock(&m)
#define UNLOCK(m) pthread_mutex_unlock(&m)
#define LOCK_INIT(m) pthread_mutex_init(&m, NULL)
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// Forward declarations
DLLEXPORT SV * coro_yield(SV * ret_val);
DLLEXPORT SV * coro_transfer(int fiber_id, SV * args);
DLLEXPORT SV * coro_call(int fiber_id, SV * args);
DLLEXPORT void destroy_coro(int fiber_id);
#ifndef _WIN32
static void install_stack_guard(void);
static void rightsize_fiber_limit(void);
#endif

typedef struct para_fiber_t para_fiber_t;

/*
 * These three symbols are wired together by hand (the asm trampoline, the stack layout in arm_fiber_context) and are
 * never referenced outside this translation unit, so keep them non-preemptible. A shared object whose text holds an
 * absolute reference to a default-visibility global has to process that relocation at load time, and link editors
 * that refuse relocations against non-writable sections (Solaris and OmniOS ld: "relocations remain against
 * allocatable but non-writable sections") reject the object outright. Hidden symbols resolve at link time instead.
 */
#if defined(__GNUC__) && !defined(_WIN32)
#define PARA_HIDDEN __attribute__((visibility("hidden")))
#else
#define PARA_HIDDEN
#endif

/* C-level entry point invoked when a freshly created fiber starts running. */
PARA_HIDDEN void para_entry_point(para_fiber_t * c);

#if defined(USE_ASM_CORO)
/**
 * @brief Raw register-only context switch.
 *
 * Saves the callee-saved registers and the current stack pointer into *from, restores them from *to, then returns
 * (popping the return address off the target stack). A freshly created fiber's stack is pre-arranged so that the return
 * address lands in para_trampoline.
 *
 * @param from Pointer to the storage slot holding the current stack pointer.
 * @param to   Pointer to the storage slot holding the target stack pointer.
 */
PARA_HIDDEN extern void para_coro_switch(void ** from, void ** to);
/** @brief Initial jump target for brand-new fiber stacks. */
PARA_HIDDEN extern void para_trampoline(void);

__asm__(
    ".text\n"
    ".p2align 4\n"
    ".globl para_coro_switch\n"
    ".hidden para_coro_switch\n"
    ".type para_coro_switch, @function\n"
    "para_coro_switch:\n"
    "    pushq %rbx\n"
    "    pushq %rbp\n"
    "    pushq %r12\n"
    "    pushq %r13\n"
    "    pushq %r14\n"
    "    pushq %r15\n"
    "    movq %rsp, (%rdi)\n"
    "    movq (%rsi), %rsp\n"
    "    popq %r15\n"
    "    popq %r14\n"
    "    popq %r13\n"
    "    popq %r12\n"
    "    popq %rbp\n"
    "    popq %rbx\n"
    "    ret\n"
    ".size para_coro_switch, .-para_coro_switch\n"
    ".p2align 4\n"
    ".globl para_trampoline\n"
    ".hidden para_trampoline\n"
    ".type para_trampoline, @function\n"
    "para_trampoline:\n"
    "    popq %rdi\n"
    "    call para_entry_point\n"
    "    ud2\n"
    ".size para_trampoline, .-para_trampoline\n");
#endif /* USE_ASM_CORO */

/**
 * @brief Get the Operating System's unique Thread ID.
 *
 * Useful for debugging to prove that background tasks are running on different OS threads than the main Perl
 * interpreter.
 *
 * @return int The TID (Windows) or LWP ID (Linux/BSD/macOS).
 */
int get_os_thread_id() {
#ifdef _WIN32
    return (int)GetCurrentThreadId();
#elif defined(__APPLE__)
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
    return (int)tid;
#elif defined(SYS_gettid)
    return (int)syscall(SYS_gettid);
#else
    return (int)(intptr_t)pthread_self();
#endif
}

/**
 * @brief Pin the current thread to a specific CPU core.
 *
 * Used by the Thread Pool to ensure worker threads are distributed across available hardware cores
 * for maximum parallelism.
 *
 * @param core_id The zero-based index of the CPU core.
 */
void pin_to_core(int core_id) {
#ifdef _WIN32
    DWORD_PTR mask = (1ULL << core_id);
    SetThreadAffinityMask(GetCurrentThread(), mask);
#elif defined(__linux__)
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(core_id, &cpuset);
    pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);
#else
    (void)core_id; /* Not supported on macOS/BSD standard APIs */
#endif
}

/**
 * @brief Get the index of the CPU core currently executing this thread.
 *
 * @return int Core ID (0..N) or -1 if unsupported.
 */
int get_current_cpu() {
#ifdef _WIN32
    return GetCurrentProcessorNumber();
#elif defined(__linux__)
    return sched_getcpu();
#else
    return -1;
#endif
}

/**
 * @brief Detects the number of logical cores available on the system.
 *
 * @return int CPU count (minimum 1).
 */
int get_cpu_count() {
#ifdef _WIN32
    SYSTEM_INFO sysinfo;
    GetSystemInfo(&sysinfo);
    int count = sysinfo.dwNumberOfProcessors;
    return (count > 0) ? count : 1;
#elif defined(__APPLE__) || defined(__FreeBSD__) || defined(__NetBSD__) || defined(__DragonFly__)
    /* NetBSD and DragonFly never declare _SC_NPROCESSORS_ONLN; hw.ncpu exists on all four of these. */
    int nm[2];
    uint32_t count = 0;
    size_t len = sizeof(count);
    nm[0] = CTL_HW;
    nm[1] = HW_NCPU;
    /* A failed sysctl leaves count untouched, and the caller divides by the result (thread_id % cpu_count), so
     * an indeterminate value is not a cosmetic problem here. Treat failure as "one core" and let the pool clamp. */
    if (sysctl(nm, 2, &count, &len, NULL, 0) != 0)
        return 1;
    return (count > 0) ? (int)count : 1;
#else
    long count = sysconf(_SC_NPROCESSORS_ONLN);
    return (count > 0) ? (int)count : 1;
#endif
}

/**
 * @brief The highest descriptor number this platform's fd_set can represent.
 *
 * FD_SETSIZE belongs to the platform's C library, not to us, and it is not 1024 everywhere: it is 1024 on
 * Linux, macOS and FreeBSD, 256 on NetBSD, and 64 for the winsock fd_set on Win32. It bounds the descriptor
 * NUMBER rather than how many descriptors are being watched, so a process that has opened 300 sockets can
 * still be holding descriptor 605 - past a 256-entry set on NetBSD. FD_SET is a bare array index with no
 * bounds check of its own and select() rejects an oversized nfds with EINVAL, so a descriptor at or past
 * this cannot be waited on through an fd_set at all. Exposed so a caller can size a workload against the
 * real ceiling instead of assuming the number they are used to.
 *
 * @return int FD_SETSIZE for this platform.
 */
DLLEXPORT int get_fd_setsize() { return FD_SETSIZE; }

/**
 * @struct para_fiber_t
 * @brief The complete execution context of a Perl Fiber.
 *
 * This structure encapsulates both the OS-level register state (via context) and the entire internal state of the Perl
 * interpreter required to pause and resume execution of Perl code.
 */
typedef struct para_fiber_t {
    coro_handle_t context; /**< OS-specific context handle */

#ifndef _WIN32
    void * stack_p;  /**< Pointer to dynamically allocated fiber stack (Unix only) */
    size_t stack_sz; /**< Size of the allocated stack (Unix only) */
#ifdef USE_ASM_CORO
    void * rsp; /**< Saved stack pointer for the assembly switch (Unix x86_64) */
#endif
#endif

    /*
     * Perl Interpreter State Pointers.
     * These must be saved and restored during every context switch.
     */
    PERL_SI * si;            /**< Current Stack Info (tracks recursion and eval frames) */
    AV * curstack;           /**< The active Argument Stack (AV*) */
    AV * mainstack;          /**< Main argument stack target for exit()/POPSTACK_TO (per-fiber) */
    SSize_t stack_sp_offset; /**< Stack Pointer offset from stack base */

    I32 * markstack;     /**< Base of the Mark Stack (tracks list start points) */
    I32 * markstack_ptr; /**< Current pointer into the Mark Stack */
    I32 * markstack_max; /**< Limit of the Mark Stack */

    I32 * scopestack;   /**< Base of the Scope Stack (tracks block nesting) */
    I32 scopestack_ix;  /**< Current index in the Scope Stack */
    I32 scopestack_max; /**< Limit of the Scope Stack */
#ifdef DEBUGGING
    const char ** scopestack_name; /**< DEBUGGING-only names parallel to scopestack */
#endif

    ANY * savestack;   /**< Base of the Save Stack (tracks local/my variables for cleanup) */
    I32 savestack_ix;  /**< Current index in the Save Stack */
    I32 savestack_max; /**< Limit of the Save Stack */

    SV ** tmps_stack; /**< Base of the Mortal Stack (tracks SVs needing refcnt decrement) */
    I32 tmps_ix;      /**< Current index in the Mortal Stack */
    I32 tmps_floor;   /**< Current floor of the Mortal Stack */
    I32 tmps_max;     /**< Limit of the Mortal Stack */

    JMPENV * top_env;   /**< Pointer to the top exception environment (eval/die buffers) */
    COP * curcop;       /**< Current Op Pointer (location in the source/bytecode) */
    OP * op;            /**< Current Operation being executed */
    PAD * comppad;      /**< Current lexical Pad (variable storage) */
    SV ** curpad;       /**< Array pointer to the current lexical Pad */
    PMOP * curpm;       /**< Current pattern match state */
    PMOP * curpm_under; /**< Current pattern match state under */
    PMOP * reg_curpm;   /**< Current regex match state */

    GV * defgv;      /**< The $_ global */
    GV * last_in_gv; /**< GV used in last <FH> */
    SV * rs;         /**< The $/ global */
    GV * ofsgv;      /**< The $, global */
    SV * ors_sv;     /**< The $\ global */
    GV * defoutgv;   /**< The default output filehandle */
    HV * curstash;   /**< Current package stash */
    HV * defstash;   /**< Default package stash */
    SV * errors;     /**< Outstanding queued errors */

    SV * user_cv;  /**< The Perl sub/coderef this fiber is running */
    SV * self_ref; /**< The Acme::Parataxis Perl object wrapper */

    SV * transfer_data; /**< Arguments or return values passed during yield/transfer */

    void * owner;       /**< PerlInterpreter that allocated this record (arena ownership); NULL never matches */

    int id;          /**< Numeric ID of this fiber */
    int finished;    /**< Flag: 1 if the fiber has completed its entry_point */
    int started;     /**< Flag: 1 once the fiber has actually begun running */
    int parent_id;   /**< ID of the fiber that 'called' this one (asymmetric) */
    int last_sender; /**< ID of the fiber that last switched control to this one */

    /* exit() interception. perl's exit() longjmps up the JMPENV chain. The coro_call guard lives on the
     * caller's (parent) stack and is popped after every resume, so a fiber resumed a second time runs with a
     * stale top_env pointing at the popped guard: an exit() then longjmps to freed stack memory and dies in
     * __longjmp (unreadable jump target). It must be captured on the fiber's own stack and re-raised on the
     * caller's stack instead (see parataxis_pp_exit / para_entry_point / coro_call). exit_pending is set when
     * exit() was called by this fiber or a fiber it called; exit_status carries the requested exit code.
     * (On x64 Windows there is the extra constraint that the CRT longjmp cannot cross stacks at all.) */
    int exit_pending;
    int exit_status;
} para_fiber_t;

/** @name Job Status Constants */
///@{
#define JOB_FREE 0 /**< Slot is available for new tasks */
#define JOB_NEW 1  /**< Task is submitted but not yet picked up by a worker */
#define JOB_BUSY 2 /**< Task is currently being processed by a worker thread */
#define JOB_DONE 3 /**< Task has completed and results are ready */
///@}

/** @name Task Type Constants */
///@{
#define TASK_SLEEP 0   /**< Sleep for N milliseconds */
#define TASK_GET_CPU 1 /**< Retrieve current core ID */
#define TASK_READ 2    /**< Wait for read-readiness on a file descriptor */
#define TASK_WRITE 3   /**< Wait for write-readiness on a file descriptor */
///@}

/**
 * @union value_t
 * @brief Generic container for task input/output data.
 */
typedef union {
    int64_t i; /**< Integer/Pointer storage */
    double d;  /**< Floating point storage */
    char * s;  /**< String storage */
} value_t;

/**
 * @struct job_t
 * @brief Represents a task in the background thread pool queue.
 */
typedef struct {
    int fiber_id;      /**< ID of the Fiber that submitted this task */
    int target_thread; /**< Index of the assigned worker thread */
    int type;          /**< Type of task to perform (TASK_*) */
    value_t input;     /**< Input data for the task */
    value_t output;    /**< Result data populated by the worker */
    int timeout_ms;    /**< Timeout duration for I/O tasks */
    int status;        /**< Current lifecycle state (JOB_*) */
    volatile int recall; /**< Set to 1 when the owner fiber wants an armed sleep abandoned early */
} job_t;

// Global Registry and State

/** @brief Size of the fiber table when it is first allocated: big enough that an ordinary program never has to
 *  reallocate it, small enough that the four per-slot arrays cost a few tens of kilobytes. */
#define DEFAULT_FIBER_TABLE 1024
/** @brief Default limit on how many fibers may exist at once. Generous on purpose: the table grows up to it on
 *  demand, so memory (64MB of lazily mapped stack per fiber) runs out long before this does. Adjustable with
 *  set_max_fibers(). */
#define DEFAULT_FIBER_LIMIT 65536
/** @brief Absolute bound on table growth, independent of the limit above. Growth only ever happens when every
 *  allocated slot is already in use, so the table stays within a doubling of the fibers actually present and this is
 *  never approached in practice. */
#define HARD_FIBER_LIMIT    (1 << 20)
/** @brief Fibers that may exist at once; create_fiber refuses past this. Adjustable with set_max_fibers(). */
static int max_fibers = DEFAULT_FIBER_LIMIT;
/** @brief Entries allocated in every table below. Fibers are only ever indexed from the scheduler thread, so growing
 *  these (realloc) never races a worker thread. */
static int fiber_capacity = 0;
/** @brief Slots currently handed out, whether the fiber is live or still waiting for its jobs to drain. Capped by
 *  max_fibers, which is what makes "the table is full" a policy decision rather than a property of the array. */
static int fiber_used = 0;
/** @brief Array of active fiber structures (fiber_capacity entries) */
static para_fiber_t ** fibers = NULL;
/** @brief LIFO of free fiber slot indexes (O(1) allocation), fiber_capacity entries */
static int * free_slots = NULL;
/** @brief Number of free slots currently on the free list */
static int free_slot_count = 0;
/** @brief The context representing the main Perl thread */
static para_fiber_t main_context;
/** @brief ID of the currently executing fiber (-1 for Main) */
static int current_fiber_id = -1;

/** @brief Size of the background job queue */
#define MAX_JOBS 1024
/** @brief Fixed-size array for background tasks */
static job_t job_slots[MAX_JOBS];
/** @brief Mutex protecting access to the job queue */
static para_mutex_t queue_lock;

/*
 * Completed-job notification ring.
 *
 * Workers push the index of every finished job into this ring so that check_for_completion() can find completed work in
 * O(1) instead of scanning all MAX_JOBS slots under the lock on every scheduler tick.
 */
static int done_queue[MAX_JOBS + 1];
static int done_head = 0;
static int done_tail = 0;

/*
 * Number of jobs that have been submitted but not yet reclaimed by the main thread via free_job_slot(). Only touched by
 * the main thread, so it needs no lock. The scheduler uses it to skip polling entirely when no background work is in
 * flight.
 */
static int outstanding_jobs = 0;

#ifdef _WIN32
/** @brief Reuse cache for freed fiber stacks (Windows fibers allocate nothing) */
#define MAX_CACHED_STACKS 0
/** @brief Maximum number of fiber objects to park for reuse */
#define MAX_FIBER_CACHE 64
#else
#if !defined(MAP_ANON) && defined(MAP_ANON)
#define MAP_ANON MAP_ANON
#endif
#if !defined(MAP_ANON)
#define MAP_ANON 0x1000
#endif

#ifndef MAP_STACK
#define MAP_STACK 0
#endif

/**
 * @brief Red zone protecting the bottom of each fiber stack.
 *
 * Set at runtime to the system page size (via sysconf) so the PROT_NONE guard
 * region always covers at least one full page, even on macOS ARM64 where the
 * page size is 16 KiB.
 */
static size_t fiber_guard_sz;

/**
 * @brief Virtual size of each fiber stack, selected per platform.
 *
 * The full region is mapped lazily so physical memory is only committed for pages the fiber actually touches. Linux
 * and FreeBSD map it with MAP_NORESERVE, which makes a large reservation free. macOS has no MAP_NORESERVE, so every
 * anonymous mapping counts against the process memory budget at full size but a 64 MB stack times a tableful of fibers
 * gets the process SIGKILLed on Apple Silicon. For macOS we use a small reservation instead (depth - 20000).
 * OpenBSD defines MAP_NORESERVE as 0 too, so it also gets an 8 MiB reservation; its RLIMIT_DATA counts every
 * anonymous mmap at full size and rightsize_fiber_limit clamps the limit to fit. DragonFly has no MAP_NORESERVE
 * either but charges only brk/sbrk to RLIMIT_DATA, so 8 MiB is safe there too.
 *
 * Perl recursion fits in a ~1 MB OS fiber on Windows, so 8 MB leaves ample headroom even in a DEBUGGING build. The
 * bottom fiber_guard_sz bytes are PROT_NONE; hitting them means genuine >FIBER_STACK_SZ C-stack usage, which the
 * SIGSEGV guard handler reports instead of corrupting the heap.
 */
#ifdef __linux__
#define FIBER_STACK_SZ   (64 * 1024 * 1024)
#define FIBER_MMAP_FLAGS (MAP_PRIVATE | MAP_ANON | MAP_NORESERVE | MAP_STACK)
#elif defined(__APPLE__)
#define FIBER_STACK_SZ   (8 * 1024 * 1024)
#define FIBER_MMAP_FLAGS (MAP_PRIVATE | MAP_ANON | MAP_STACK)
#else
#if defined(MAP_NORESERVE) && MAP_NORESERVE != 0
#define FIBER_STACK_SZ   (64 * 1024 * 1024)
#define FIBER_MMAP_FLAGS (MAP_PRIVATE | MAP_ANON | MAP_NORESERVE | MAP_STACK)
#else
#define FIBER_STACK_SZ   (8 * 1024 * 1024)
#define FIBER_MMAP_FLAGS (MAP_PRIVATE | MAP_ANON | MAP_STACK)
#endif
#endif
/** @brief Lazy-init: set fiber_guard_sz to the system page size. */
static void init_guard_sz(void) {
    if (!fiber_guard_sz)
        fiber_guard_sz = (size_t)sysconf(_SC_PAGESIZE);
}
/** @brief Maximum number of fiber stacks to keep around for reuse */
#define MAX_CACHED_STACKS 64
/** @brief LIFO cache of free fiber stack allocations */
static void * stack_cache[MAX_CACHED_STACKS];
/** @brief Number of stacks currently in the cache */
static int stack_cache_count = 0;

/** @brief Maximum number of whole fiber contexts to park for reuse */
#define MAX_FIBER_CACHE 64
/** @brief LIFO cache of idle fiber contexts (Perl stacks + OS stack included) */
static para_fiber_t * fiber_cache[MAX_FIBER_CACHE];
/** @brief Number of fiber contexts currently in the cache */
static int fiber_cache_count = 0;
#endif

#ifdef _WIN32
static CONDITION_VARIABLE queue_cond;
#else
static pthread_cond_t queue_cond;
#endif

static int threads_initialized = 0;
static int system_initialized = 0;

// Forward declarations for thread safety wrappers
#ifdef _WIN32
#define PARA_COND_WAIT(c, m) SleepConditionVariableCS(&c, &m, INFINITE)
#define PARA_COND_SIGNAL(c) WakeConditionVariable(&c)
#define PARA_COND_BROADCAST(c) WakeAllConditionVariable(&c)
#define PARA_COND_INIT(c) InitializeConditionVariable(&c)
#define PARA_COND_TIMEDWAIT(c, m, ms) SleepConditionVariableCS(&c, &m, (ms))
#else
#define PARA_COND_WAIT(c, m) pthread_cond_wait(&c, &m)
#define PARA_COND_SIGNAL(c) pthread_cond_signal(&c)
#define PARA_COND_BROADCAST(c) pthread_cond_broadcast(&c)
#define PARA_COND_INIT(c) pthread_cond_init(&c, NULL)

/**
 * @brief Timed wait on the queue condition variable (POSIX).
 *
 * Waits until \p deadline (absolute, in the same CLOCK_REALTIME clock a condition variable created with
 * a NULL attribute uses) or until signalled/broadcast. Returns nonzero when the wait was interrupted by
 * a signal or broadcast, zero when it timed out. Spurious wakeups are reported as nonzero too, so
 * callers must re-check their predicate and re-wait against the same deadline.
 */
static int para_cond_timedwait(pthread_cond_t * cond, pthread_mutex_t * lock, const struct timespec * deadline) {
    return pthread_cond_timedwait(cond, lock, deadline) != ETIMEDOUT;
}
#define PARA_COND_TIMEDWAIT(c, m, deadline) para_cond_timedwait(&c, &m, (deadline))
#endif

/** @brief Threshold for automatic preemption (0 to disable) */
static long long preempt_threshold = 0;
/** @brief Count of operations since last preemption yield */
static long long preempt_count = 0;

/** @brief Maximum worker threads allowed in the pool */
#define MAX_THREADS 64
/** @brief Floor for the default pool size. The pool seeds 2 workers and only grows when jobs pile up, so a machine
 *  reporting 1-2 cores would pin it at the seed and a freshly submitted job could never get its own worker until an
 *  unrelated long sleep ended. Sleeping workers are blocked rather than computing, so a small floor costs nothing. */
#define MIN_THREAD_POOL 8
/** @brief Native OS handles for pool threads */
static para_thread_t thread_handles[MAX_THREADS];
/** @brief Maximum allowed threads in the pool */
static int max_thread_pool_size = 0;
/** @brief Number of currently running worker threads */
static int current_thread_count = 0;
/** @brief Workers currently executing a job (guarded by queue_lock); idle = current_thread_count - busy_thread_count. */
static int busy_thread_count = 0;
/** @brief Flag to signal worker threads to terminate */
static volatile int threads_keep_running = 1;

#ifndef _WIN32
/** @brief Pipe used to wake worker threads blocked in select() during shutdown. */
static int shutdown_pipe[2] = { -1, -1 };
#endif

/** @brief Submitted-but-unreclaimed job count per fiber id (avoids fiber slot reuse while jobs are in flight),
 *  fiber_capacity entries. */
static int * job_refcount = NULL;
/** @brief Set when a fiber id is destroyed but still has outstanding jobs; the id must not be reused until they
 *  drain. fiber_capacity entries. */
static bool * fiber_destroyed = NULL;

#ifdef _WIN32
/** @brief Windows-only handle for the main thread converted to fiber */
static void * main_fiber_handle = NULL;
#endif

/** @brief Sets the maximum number of worker threads allowed in the pool. */
DLLEXPORT void set_max_threads(int max) {
    if (max > 0 && max <= MAX_THREADS)
        max_thread_pool_size = max;
}

/**
 * @brief Sets how many fibers may exist at once.
 *
 * The limit is enforced against the slots in use rather than against the allocated table, so it may be raised or
 * lowered at any time: lowering it never disturbs fibers that already exist, it only stops the next create_fiber from
 * succeeding until some of them are gone. Values below 1 are ignored (as in set_max_threads) and values above
 * HARD_FIBER_LIMIT are clamped to it, so what this reports is always what the table could actually hold.
 *
 * @param max Requested limit.
 */
DLLEXPORT void set_max_fibers(int max) {
    if (max < 1)
        return;
    max_fibers = max > HARD_FIBER_LIMIT ? HARD_FIBER_LIMIT : max;
}

/** @brief Returns how many fibers may exist at once. */
DLLEXPORT int get_max_fibers(void) { return max_fibers; }

/**
 * @brief Grows the fiber table to at least `want` entries, doubling so allocation stays amortized O(1).
 *
 * New slots start empty and join the tail of the free list in descending order, so popping still hands out ascending
 * ids: the first allocation on an empty table reproduces the old static seeding exactly (ids 0, 1, 2, ...). Growth is
 * bounded by HARD_FIBER_LIMIT and deliberately ignores max_fibers - the table may outlive the live-fiber limit, which
 * costs only a few tens of kilobytes and lets set_max_fibers be raised again without reallocating anything.
 *
 * @param want Minimum number of entries wanted.
 * @return 1 if the table now holds at least `want` entries, 0 if an allocation was refused.
 */
static int _fiber_table_grow(int want) {
    if (want <= fiber_capacity)
        return 1;
    if (want < DEFAULT_FIBER_TABLE)
        want = DEFAULT_FIBER_TABLE;
    if (want > HARD_FIBER_LIMIT)
        want = HARD_FIBER_LIMIT;
    if (want <= fiber_capacity)
        return 0;

    /* All four tables must reach the new size together, so each pointer is committed the moment its own realloc
     * succeeds (discarding a moved pointer would leak the old block) while fiber_capacity is only recorded once every
     * one of them made it. A partial failure therefore leaves a table larger than fiber_capacity knows about, which
     * is harmless: the next attempt simply reallocs it again. */
    para_fiber_t ** nf = (para_fiber_t **)realloc(fibers, (size_t)want * sizeof(*nf));
    if (!nf)
        return 0;
    fibers = nf;
    int * nfree = (int *)realloc(free_slots, (size_t)want * sizeof(*nfree));
    if (!nfree)
        return 0;
    free_slots = nfree;
    int * nref = (int *)realloc(job_refcount, (size_t)want * sizeof(*nref));
    if (!nref)
        return 0;
    job_refcount = nref;
    bool * ndes = (bool *)realloc(fiber_destroyed, (size_t)want * sizeof(*ndes));
    if (!ndes)
        return 0;
    fiber_destroyed = ndes;

    for (int i = want - 1; i >= fiber_capacity; i--) {
        fibers[i] = NULL;
        job_refcount[i] = 0;
        fiber_destroyed[i] = false;
        free_slots[free_slot_count++] = i;
    }
    fiber_capacity = want;
    return 1;
}

/**
 * @brief Returns a slot to the free list, undoing the moment create_fiber took it.
 *
 * Every release path funnels through here so a taken slot and its `fiber_used` increment can never come apart: the
 * allocation failure paths below, a fiber destroyed outright, and a fiber whose id is only released once its jobs
 * drain.
 *
 * @param idx Slot index to give back.
 */
static void _release_slot(int idx) {
    if (idx < 0 || idx >= fiber_capacity)
        return;
    if (free_slot_count < fiber_capacity)
        free_slots[free_slot_count++] = idx;
    if (fiber_used > 0)
        fiber_used--;
}

/** @brief Forward declaration of worker_thread */
#ifdef _WIN32
DWORD WINAPI worker_thread(LPVOID arg);
#else
void * worker_thread(void * arg);
#endif

/** @brief Internal helper to spawn N threads into the pool */
static void _spawn_workers(int count) {
    for (int i = 0; i < count; i++) {
        if (current_thread_count >= max_thread_pool_size || current_thread_count >= MAX_THREADS)
            break;

        int tid = current_thread_count;
#ifdef _WIN32
        HANDLE h = CreateThread(NULL, 0, worker_thread, (LPVOID)(intptr_t)tid, 0, NULL);
        if (h) {
            thread_handles[tid] = h;
            current_thread_count++;
        }
#else
        if (pthread_create(&thread_handles[tid], NULL, worker_thread, (void *)(intptr_t)tid) == 0) {
            current_thread_count++;
        }
#endif
    }
}

/**
 * @brief Background Worker Thread Loop.
 *
 * Each thread pins itself to a core and continuously waits for jobs.
 *
 * @param arg Integer thread ID passed as a pointer.
 */
#ifdef _WIN32
DWORD WINAPI worker_thread(LPVOID arg) {
#else
void * worker_thread(void * arg) {
#endif
    int thread_id = (int)(intptr_t)arg;
    int cpu_count = get_cpu_count();
    pin_to_core(thread_id % cpu_count);

    /* Process-directed signals (SIGINT/SIGTERM/SIGPIPE/SIGCHLD/...) are handed to an arbitrary thread that has them
     * unblocked. A pool worker is a C-only thread with no perl interpreter on it, so if a worker catches one of these
     * perl's $SIG{...} handler never runs: the shutdown request is swallowed until the interrupted job finishes on
     * its own schedule (a sleeping fiber can therefore ride out its full deadline and a Ctrl-C or kill -TERM becomes
     * ineffective, or fires tens of seconds late). Permanently block them here so the kernel can only deliver them to
     * the main (interpreting) thread, where perl installs and dispatches its handlers. */
#ifndef _WIN32
    sigset_t block_set;
    sigemptyset(&block_set);
    sigaddset(&block_set, SIGINT);
    sigaddset(&block_set, SIGTERM);
    sigaddset(&block_set, SIGQUIT);
    sigaddset(&block_set, SIGHUP);
    sigaddset(&block_set, SIGPIPE);
    sigaddset(&block_set, SIGCHLD);
    sigaddset(&block_set, SIGALRM);
    sigaddset(&block_set, SIGUSR1);
    sigaddset(&block_set, SIGUSR2);
    /* No other thread in this process ever unblocks these, so per POSIX the kernel must deliver any pending occurrence
     * to the main thread immediately on arrival. */
    pthread_sigmask(SIG_BLOCK, &block_set, NULL);
#endif

    while (threads_keep_running) {
        int found_idx = -1;

        LOCK(queue_lock);
        while (threads_keep_running) {
            for (int i = 0; i < MAX_JOBS; i++) {
                if (job_slots[i].status == JOB_NEW) {
                    job_slots[i].status = JOB_BUSY;
                    found_idx = i;
                    break;
                }
            }
            if (found_idx != -1 || !threads_keep_running)
                break;
            PARA_COND_WAIT(queue_cond, queue_lock);
        }
        if (found_idx != -1)
            busy_thread_count++;    /* busy from claim until the job is marked done, all under queue_lock */
        UNLOCK(queue_lock);

        if (found_idx != -1 && threads_keep_running) {
            job_t * job = &job_slots[found_idx];
            // ... processing ...

            if (job->type == TASK_SLEEP) {
                int ms = (int)job->input.i;
                int recalled = 0;
                LOCK(queue_lock);
                if (ms > 0 && !job->recall && threads_keep_running) {
                    /* Timed condition-variable wait instead of quantized polling: the OS sleeps for (almost) the whole
                     * remainder in one call, so a 1000 ms arm costs ~1000 ms on any platform (the old 4 ms quantum
                     * inflated Windows sleeps ~4x through the ~15.6 ms system timer tick). The wait releases
                     * queue_lock, so notifying threads (submit/recall/shutdown) are never blocked by a sleeping worker.
                     * Recall and shutdown wakes are observed by re-checking the predicate; the deadline is fixed, so
                     * spurious or broadcast wakeups just re-wait to it. */
#ifdef _WIN32
                    /* Absolute deadline as ms since boot; unsigned subtraction is wrap-safe. */
                    DWORD deadline = GetTickCount() + (DWORD)ms;
                    while (!job->recall && threads_keep_running) {
                        DWORD remaining = deadline - GetTickCount();
                        if ((int)remaining <= 0)
                            break;
                        PARA_COND_TIMEDWAIT(queue_cond, queue_lock, remaining);
                    }
#else
                    struct timespec deadline;
                    clock_gettime(CLOCK_REALTIME, &deadline);
                    deadline.tv_sec += ms / 1000;
                    deadline.tv_nsec += (long)(ms % 1000) * 1000000L;
                    if (deadline.tv_nsec >= 1000000000L) {
                        deadline.tv_sec++;
                        deadline.tv_nsec -= 1000000000L;
                    }
                    while (!job->recall && threads_keep_running &&
                           PARA_COND_TIMEDWAIT(queue_cond, queue_lock, &deadline)) {
                        /* woken (recall, spurious, or shutdown); re-check and re-wait to the same deadline */
                    }
#endif
                }
                recalled = job->recall;
                UNLOCK(queue_lock);
                /* output.i = -1 signals an early recall (interrupted or shutdown); otherwise the full duration elapses. */
                job->output.i = (recalled || !threads_keep_running) ? -1 : ms;
            }
            else if (job->type == TASK_GET_CPU) {
                int cpu = get_current_cpu();
                job->output.i = cpu;
            }
            else if (job->type == TASK_READ || job->type == TASK_WRITE) {
                fd_set read_fds, write_fds;
                FD_ZERO(&read_fds);
                FD_ZERO(&write_fds);
                int nfds = 0;
                int res = -1;    /* an unrepresentable descriptor can never become ready, so -1 from the start */
#ifdef _WIN32
                SOCKET s = (SOCKET)job->input.i;
                if (job->type == TASK_READ) FD_SET(s, &read_fds);
                else                        FD_SET(s, &write_fds);
                nfds = 0;
                int timeout = job->timeout_ms > 0 ? job->timeout_ms : 5000;
                struct timeval tv;
                tv.tv_sec = timeout / 1000;
                tv.tv_usec = (timeout % 1000) * 1000;

                /* Pass both sets to select */
                res = select(nfds, &read_fds, &write_fds, NULL, &tv);
#else
                int fd = (int)job->input.i;

                /* FD_SET is a bare array index with no bounds check, and read_fds/write_fds are FD_SETSIZE-bit
                 * sets sitting in this thread's stack frame - 128 bytes where FD_SETSIZE is 1024, but only 32 on
                 * NetBSD, whose FD_SETSIZE is 256. A descriptor at or past FD_SETSIZE
                 * writes off the end of them - into the neighbouring set, then into this frame's canary - and
                 * select() would reject the oversized nfds with EINVAL anyway, so there is nothing to gain by
                 * trying. Refuse it and report "not ready", the same answer a deadline produces. The Windows
                 * branch above needs no equivalent: a WinSock fd_set is a full descriptor bitmask, not a
                 * 1024-entry array, and has no FD_SETSIZE to exceed. */
                if (fd >= 0 && fd < FD_SETSIZE) {
                    if (job->type == TASK_READ) FD_SET(fd, &read_fds);
                    else                        FD_SET(fd, &write_fds);
                    nfds = fd + 1;

                    if (shutdown_pipe[0] >= 0) {
                        FD_SET(shutdown_pipe[0], &read_fds); /* ALWAYS read_fds */
                        if (shutdown_pipe[0] + 1 > nfds)
                            nfds = shutdown_pipe[0] + 1;
                    }

                    int timeout = job->timeout_ms > 0 ? job->timeout_ms : 5000;
                    struct timeval tv;
                    tv.tv_sec = timeout / 1000;
                    tv.tv_usec = (timeout % 1000) * 1000;

                    /* Pass both sets to select */
                    res = select(nfds, &read_fds, &write_fds, NULL, &tv);

                    if (shutdown_pipe[0] >= 0 && FD_ISSET(shutdown_pipe[0], &read_fds))
                        res = -1;    /* woken for shutdown, not readiness */
                }
#endif
                job->output.i = (res > 0) ? 1 : -1;
            }

            LOCK(queue_lock);
            job->status = JOB_DONE;
            busy_thread_count--;
            done_queue[done_tail] = found_idx;
            done_tail = (done_tail + 1) % (MAX_JOBS + 1);
            UNLOCK(queue_lock);
        }
        else {
            if (found_idx != -1) { /* claimed, but shutting down before it ran: keep the busy count honest */
                LOCK(queue_lock);
                busy_thread_count--;
                UNLOCK(queue_lock);
            }
#ifdef _WIN32
            Sleep(1);
#else
            usleep(1000);
#endif
        }
    }
    return 0;
}

/**
 * @brief Initializes the background thread pool.
 *
 * Automatically detects the CPU count and spawns worker threads. This function is called
 * automatically by `init_system` and `submit_c_job`.
 */
DLLEXPORT void init_threads() {
    dTHX;
    if (threads_initialized)
        return;
    LOCK_INIT(queue_lock);
    PARA_COND_INIT(queue_cond);
#ifndef _WIN32
    if (pipe(shutdown_pipe) != 0)
        shutdown_pipe[0] = shutdown_pipe[1] = -1;
#endif
    for (int i = 0; i < MAX_JOBS; i++)
        job_slots[i].status = JOB_FREE;

    if (max_thread_pool_size == 0) {
        max_thread_pool_size = get_cpu_count();
        if (max_thread_pool_size < MIN_THREAD_POOL)
            max_thread_pool_size = MIN_THREAD_POOL;
        if (max_thread_pool_size > MAX_THREADS)
            max_thread_pool_size = MAX_THREADS;
    }

    /* Start with a small "seed" pool of 2 threads */
    _spawn_workers(2);

    threads_initialized = 1;
}

/**
 * @brief Submits a C-level task to the background pool.
 *
 * @param type The task type constant (TASK_*).
 * @param arg Input integer or pointer data.
 * @param timeout_ms Timeout for I/O operations.
 * @return int The index of the submitted job, or -1 if the queue is full.
 */
DLLEXPORT int submit_c_job(int type, int64_t arg, int timeout_ms) {
    if (!threads_initialized)
        init_threads();
    int idx = -1;
    LOCK(queue_lock);

    for (int i = 0; i < MAX_JOBS; i++) {
        if (job_slots[i].status == JOB_FREE) {
            idx = i;
            break;
        }
    }
    if (idx != -1) {
        job_slots[idx].fiber_id = current_fiber_id;
        job_slots[idx].type = type;
        job_slots[idx].input.i = arg;
        job_slots[idx].timeout_ms = timeout_ms;
        job_slots[idx].status = JOB_NEW;
        job_slots[idx].recall = 0;
        outstanding_jobs++;
        if (current_fiber_id >= 0 && current_fiber_id < fiber_capacity)
            job_refcount[current_fiber_id]++;

        /* Dynamic scaling: spawn exactly the deficit (pending - idle), bounded by the configured pool size. This
         * must run AFTER the job is inserted: the previous check counted only jobs that were already pending, so a
         * lone submission against a pool whose every worker sat in a long TASK_SLEEP saw pending == 0, spawned
         * nothing, and queued behind sleeps lasting hundreds of milliseconds. A 10 ms await_sleep submitted while
         * both seeded workers held a 400 ms and a 600 ms sleep woke at 400 ms instead of 10 ms. Pending work with
         * no idle worker to claim it is exactly the case that needs a worker, so now that is what is measured. */
        int pending_count = 0;
        for (int i = 0; i < MAX_JOBS; i++)
            if (job_slots[i].status == JOB_NEW)
                pending_count++;
        int idle_count = current_thread_count - busy_thread_count;
        if (pending_count > idle_count)
            _spawn_workers(pending_count - idle_count); /* stops at max_thread_pool_size / MAX_THREADS */

        /* Broadcast (not signal): a single wakeup may be swallowed by a worker parked in its timed sleep wait
         * (which only re-checks its absolute deadline and continues), leaving idle workers with no wakeup and
         * JOB_NEW entries unclaimed until some long sleep ends. */
        PARA_COND_BROADCAST(queue_cond);
    }
    UNLOCK(queue_lock);
    return idx;
}

/**
 * @brief Polls the queue for any completed background jobs.
 *
 * @return int Index of a finished job, or -1 if none are ready.
 */
DLLEXPORT int check_for_completion() {
    if (!threads_initialized)
        init_threads();
    int job_idx = -1;
    LOCK(queue_lock);
    if (done_head != done_tail) {
        job_idx = done_queue[done_head];
        done_head = (done_head + 1) % (MAX_JOBS + 1);
    }
    UNLOCK(queue_lock);
    return job_idx;
}

/**
 * @brief Returns the number of background jobs not yet reclaimed.
 *
 * Only the main thread touches this counter, so it is a plain read. The scheduler uses it to skip polling entirely when
 * no work is in flight.
 *
 * @return int Number of outstanding jobs.
 */
DLLEXPORT int get_outstanding_jobs() { return outstanding_jobs; }

/**
 * @brief Recalls (abandons early) every armed TASK_SLEEP job owned by the given fiber.
 *
 * Used when a fiber parked in `await_sleep` is interrupted; the recall flags are set under the queue
 * lock and queue_cond is broadcast so the owning worker aborts its timed wait immediately
 * (sub-millisecond) instead of sleeping out the remainder of its armed duration. That lets the fiber
 * fail-fast and keeps the scheduler from staying alive until the sleep would have expired naturally.
 *
 * @param fid The fiber whose armed sleeps should be recalled.
 * @return int The number of armed sleeps that were recalled.
 */
DLLEXPORT int recall_sleep_jobs_for_fiber(int fid) {
    if (!threads_initialized)
        return 0;
    int count = 0;
    LOCK(queue_lock);
    for (int i = 0; i < MAX_JOBS; i++) {
        if (job_slots[i].fiber_id != fid)
            continue;
        if (job_slots[i].type != TASK_SLEEP)
            continue;
        if (job_slots[i].status != JOB_NEW && job_slots[i].status != JOB_BUSY)
            continue;
        job_slots[i].recall = 1;
        count++;
    }
    if (count > 0)
        PARA_COND_BROADCAST(queue_cond); /* Wake the armed worker(s) immediately instead of waiting for the next job signal */
    UNLOCK(queue_lock);
    return count;
}

/**
 * @brief Retrieves the result of a completed job as a Perl SV.
 *
 * @param idx The job index in the queue.
 * @return SV* A mortalized Perl SV containing the result (IV).
 */
DLLEXPORT SV * get_job_result(int idx) {
    dTHX;
    if (idx < 0 || idx >= MAX_JOBS)
        return &PL_sv_undef;
    SV * res = &PL_sv_undef;
    LOCK(queue_lock);
    if (job_slots[idx].status == JOB_DONE || job_slots[idx].status == JOB_BUSY) {
        if (job_slots[idx].type == TASK_SLEEP || job_slots[idx].type == TASK_GET_CPU ||
            job_slots[idx].type == TASK_READ || job_slots[idx].type == TASK_WRITE) {
            res = newSViv(job_slots[idx].output.i);
            sv_2mortal(res);
        }
    }
    UNLOCK(queue_lock);
    return res;
}

/**
 * @brief Gets the ID of the Fiber that submitted a specific job.
 *
 * @param idx Job index.
 * @return int Fiber ID.
 */
DLLEXPORT int get_job_coro_id(int idx) {
    if (idx < 0 || idx >= MAX_JOBS)
        return -1;
    return job_slots[idx].fiber_id;
}

/**
 * @brief Frees a job slot in the queue after the result has been retrieved.
 *
 * @param idx Job index.
 */
DLLEXPORT void free_job_slot(int idx) {
    if (idx < 0 || idx >= MAX_JOBS)
        return;
    int owner = job_slots[idx].fiber_id;
    LOCK(queue_lock);
    job_slots[idx].status = JOB_FREE;
    outstanding_jobs--;
    UNLOCK(queue_lock);

    /* Release the owner fiber id only once every job it submitted has been reclaimed, and only if the fiber has been
     * destroyed. This keeps a stale completion from ever waking a newer fiber that reused the same id. */
    if (owner >= 0 && owner < fiber_capacity && job_refcount[owner] > 0) {
        job_refcount[owner]--;
        if (job_refcount[owner] == 0 && fiber_destroyed[owner]) {
            fiber_destroyed[owner] = 0;
            _release_slot(owner);
        }
    }
}

/**
 * @brief Resets the call depth of a Perl CV to zero.
 *
 * Used to ensure that a newly created fiber starts its coderef with a clean execution state.
 *
 * @param cv_ref SV reference to the coderef.
 */
DLLEXPORT void force_depth_zero(SV * cv_ref) {
    dTHX;
    CV * cv = NULL;
    if (SvROK(cv_ref))
        cv = (CV *)SvRV(cv_ref);
    else if (SvTYPE(cv_ref) == SVt_PVCV)
        cv = (CV *)cv_ref;
    if (cv && SvTYPE((SV *)cv) == SVt_PVCV)
        ((XPVCV *)MUTABLE_PTR(SvANY(cv)))->xcv_depth = 0;
}

/** @brief Returns the ID of the currently executing fiber. */
DLLEXPORT int get_current_parataxis_id() { return current_fiber_id; }
/** @brief Returns the OS-level thread ID of the main interpreter thread. */
DLLEXPORT int get_os_thread_id_export() { return get_os_thread_id(); }
/** @brief Returns the number of worker threads currently running in the pool. */
DLLEXPORT int get_thread_pool_size() { return current_thread_count; }
/** @brief Returns the maximum number of worker threads allowed in the pool. */
DLLEXPORT int get_max_thread_pool_size() { return max_thread_pool_size; }
/** @brief Returns the current count towards the preemption threshold. */
DLLEXPORT int64_t get_preempt_count() { return preempt_count; }
/** @brief Sets the threshold for automatic yield-based preemption. */
DLLEXPORT void set_preempt_threshold(int64_t threshold) { preempt_threshold = threshold; }

/**
 * @brief Checks if automatic preemption should occur.
 *
 * Increments the internal counter and triggers a `coro_yield` if the threshold is reached.
 *
 * @return SV* Result of the yield, or undef if no yield occurred.
 */
DLLEXPORT SV * maybe_yield() {
    dTHX;
    preempt_count++;
    if (preempt_threshold > 0 && preempt_count >= preempt_threshold) {
        preempt_count = 0;
        return coro_yield(&PL_sv_undef);
    }
    return &PL_sv_undef;
}

/**
 * @brief DEBUGGING-only: name a CV whose pad @_ (slot 0) is AvREAL.
 *
 * A fiber that parks while a shared subroutine's @_ slot is AvREAL leaves that state in the CV's shared PadList.
 * When a different fiber later enters the same CV at the same depth, pp_entersub's assert(!AvREAL(av)) panics in
 * DEBUGGING builds. Printing the offending CV name + depth + where, at the moment the state is created or cleaned,
 * localizes the parked-AvREAL-@_ corruption beyond pp_hot.c's bare "(on line N")" message.
 */
static void para_report_avreal_pad(pTHX_ CV * cv, I32 depth, const char * where) {
    if (!cv || SvTYPE((SV *)cv) != SVt_PVCV)
        return;
    const char * pkg = (CvSTASH(cv) && HvNAME_get(CvSTASH(cv))) ? HvNAME_get(CvSTASH(cv)) : "?";
    const char * name = "?";
    GV * gv = CvGV(cv);
    if (gv && isGV_with_GP(gv) && GvNAME_HEK(gv))
        name = GvNAME(gv);
#ifdef DEBUGGING
    fprintf(stderr, "PARATAXIS_PAD: %s %s::%s depth=%ld\n", where, pkg, name, (long)depth);
#else
    PERL_UNUSED_VAR(pkg);
    PERL_UNUSED_VAR(name);
#endif
}

/**
 * @brief DEBUGGING-only: report every just-parked fiber sub-frame whose pad @_ (slot 0) is AvREAL.
 *
 * Called from swap_perl_state after the depositing fiber's context stack has been recaptured, i.e. for every
 * park/yield. A hit names the fiber-victim CV whose reified @_ slot will later trip pp_entersub when another fiber
 * enters the same CV at the same depth.
 */
static void para_report_reified_at_switch(pTHX_ para_fiber_t * from, const char * where) {
    if (!from || !from->si || !from->si->si_cxstack)
        return;
    for (I32 i = 0; i <= from->si->si_cxix; i++) {
        PERL_CONTEXT * cx = &(from->si->si_cxstack[i]);
        if (CxTYPE(cx) != CXt_SUB && CxTYPE(cx) != CXt_FORMAT)
            continue;
        CV * cv = cx->blk_sub.cv;
        I32 depth = cx->blk_sub.olddepth + 1;
        PADLIST * pl = (cv && SvTYPE((SV *)cv) == SVt_PVCV) ? CvPADLIST(cv) : NULL;
        if (!pl || depth <= 0 || depth > PadlistMAX(pl))
            continue;
        AV * pad = (AV *)PadlistARRAY(pl)[depth];
        if (!pad || SvTYPE((SV *)pad) != SVt_PVAV)
            continue;
        SV ** array = AvARRAY(pad);
        if (!array || AvMAX(pad) < 0)
            continue;
        SV * args = array[0];
        if (args && SvTYPE(args) == SVt_PVAV && AvREAL(args))
            para_report_avreal_pad(aTHX_ cv, depth, where);
    }
}

/* diagnostic: PARA_DIAG=1 dumps swap-time depth/pad state */
static int para_diag_enabled(void) {
    static int on = -1;
    if (on < 0)
        on = (getenv("PARA_DIAG") != NULL);
    return on;
}

#define PARA_DIAGF(...) do { if (para_diag_enabled()) fprintf(stderr, __VA_ARGS__); } while (0)

/** @brief Monotonic swap counter, so the PARA_DIAG dumps from one swap can be told apart. */
static unsigned long para_diag_swapno = 0;

/* ------------------------------------------------------------------------------------------
 * Parked-frame depth registry.
 *
 * CvDEPTH is a single per-CV counter, but every fiber that parks inside a subroutine leaves a
 * live frame (and a live pad) behind in the shared PadList. pp_entersub allocates its pad as
 * depth = ++CvDEPTH(cv) and Perl_pad_push() reuses an existing pad at that depth as-is, so any
 * CvDEPTH value below a parked frame's depth makes the next call land *on* that frame and
 * overwrite its $self/@_/my lexicals in place (the parked-frame pad wipe). Leaves make dips
 * unavoidable: cx_popsub_common() restores CvDEPTH(cv) = cx->blk_sub.olddepth, the value baked
 * when *that* frame entered, which can be shallower than where other fibers sit parked, and a
 * fiber resuming with no frame of a CV leaves that CV's CvDEPTH untouched at whatever stale
 * value the last leaver assigned.
 *
 * The registry tracks, per CV, the pad depths of frames currently parked in non-running
 * fibers. It is maintained incrementally at each swap by walking only the depositing and
 * resuming context stacks (nobody walks all fibers), so the cost stays O(stack depth), and it
 * is purged in destroy_coro so a killed parked fiber cannot pin CvDEPTH forever.
 *
 * _activate_current_depths() then restores:
 *   - CVs on the resuming fiber's stack: CvDEPTH = that fiber's deepest frame depth
 *     (olddepth + 1), exactly as before. A resuming fiber is inside its own frames, so it
 *     cannot re-enter them before leaving, and its post-leave re-entries land on the pad it
 *     just vacated (no other fiber can hold that depth); this exact value is also what keeps
 *     core's cx_popsub_args() assert (Padlist[CvDEPTH] == PL_curpad) true at each leave.
 *   - CVs parked somewhere but absent from the resuming stack: CvDEPTH = the deepest parked
 *     depth, so the next ++CvDEPTH() lands at max + 1, strictly above every parked frame.
 *
 * The fabricated depth is a loan, repaid only by the pops of the frames that occupy the pads
 * it reserves, and a pop restores CvDEPTH to that frame's own olddepth -- one level too high
 * per parker. Pass 1c settles the loan at the swap boundary: once no fiber claims the CV and
 * no frame of it is live on the resuming stack, the fabricated depth is unwound to perl's
 * ordinary 0 and the landing pad is made canonical again. The swap is the one reversible point
 * this module is invoked from; a sub-return hook is not, because perl bakes op_ppaddr
 * snapshots into every compiled op (see init_system).
 *
 * Known limitation: a *recursive* re-entry of a CV that is on the resuming stack while other
 * fibers are parked deeper in that same CV could still climb into a parked pad (fixing that
 * would require inflating CvDEPTH above the leaving frame's depth, which breaks core's
 * DEBUGGING leave asserts). The library's own park sites (get/put/down/up/await_sleep/_park/
 * run) are non-recursive, so they cannot reach this case.
 * --------------------------------------------------------------------------------------- */

typedef struct {
    CV * cv;             /* key; NULL marks a free table slot (a dead key keeps its cv set) */
    I32 * counts;        /* counts[d] = parked frames at pad depth d; NULL when inactive */
    I32 arr_len;         /* valid length of counts[] */
    I32 max_depth;       /* highest d with counts[d] > 0; 0 when inactive */
    I32 active_pos;      /* index into para_cvreg_active, or -1 when inactive */
    int on_stack;        /* scratch: Pass 1 saw a frame of this CV on the resuming stack */
    int pinned;          /* CvDEPTH was fabricated above the live frame count by Pass 1b */
    I32 pinned_pos;      /* index into para_cvreg_pinned, or -1 when not pinned */
} para_cvreg_entry_t;

static para_cvreg_entry_t * para_cvreg = NULL; /* open-addressed table; capacity is always a power of 2 */
static U32 para_cvreg_cap = 0;
static U32 para_cvreg_used = 0;
static I32 * para_cvreg_active = NULL; /* slots with max_depth > 0, so Pass 1b is O(parked CVs) */
static U32 para_cvreg_active_n = 0;
static U32 para_cvreg_active_cap = 0;

/* Slots whose `pinned` flag is set: CVs Pass 1b fabricated a CvDEPTH for. The list is separate from
 * para_cvreg_active because a pin stays behind after its claims drain (max_depth back to 0), and the
 * debt can only be settled once no frame of the CV is live anywhere -- which the swap boundary knows,
 * and the claim cache alone does not. */
static I32 * para_cvreg_pinned = NULL;
static U32 para_cvreg_pinned_n = 0;
static U32 para_cvreg_pinned_cap = 0;

static void para_cvreg_pin(para_cvreg_entry_t * e);
static void para_cvreg_unpin(para_cvreg_entry_t * e);

#define PARA_CVREG_HASH(cv) (((U32)(((PTRV)(cv) >> 4) * 2654435761u)) & (para_cvreg_cap - 1))

static void para_cvreg_activate(para_cvreg_entry_t * e) {
    if (e->active_pos >= 0)
        return;
    if (para_cvreg_active_n >= para_cvreg_active_cap) {
        U32 new_cap = para_cvreg_active_cap ? para_cvreg_active_cap * 2 : 16;
        Renew(para_cvreg_active, new_cap, I32);
        para_cvreg_active_cap = new_cap;
    }
    e->active_pos = (I32)para_cvreg_active_n;
    para_cvreg_active[para_cvreg_active_n++] = (I32)(e - para_cvreg);
}

static void para_cvreg_deactivate(para_cvreg_entry_t * e) {
    if (e->active_pos < 0)
        return;
    I32 pos = e->active_pos;
    I32 last_slot = para_cvreg_active[--para_cvreg_active_n];
    para_cvreg_active[pos] = last_slot;
    para_cvreg[last_slot].active_pos = pos;
    e->active_pos = -1;
}

static void para_cvreg_pin(para_cvreg_entry_t * e) {
    dTHX;
    if (e->pinned_pos >= 0)
        return;
    if (para_cvreg_pinned_n >= para_cvreg_pinned_cap) {
        U32 new_cap = para_cvreg_pinned_cap ? para_cvreg_pinned_cap * 2 : 16;
        Renew(para_cvreg_pinned, new_cap, I32);
        para_cvreg_pinned_cap = new_cap;
    }
    /* The pin outlives every claim and every parked frame, so the registry cannot rely on a suspended
     * fiber to keep the CV alive until Pass 1c settles the debt -- at global destruction there may be
     * no fiber left holding it, and a bare key is no reference at all. Owning one of our own is what
     * makes the settlement write non-fatal. */
    SvREFCNT_inc(e->cv);
    e->pinned = 1;
    e->pinned_pos = (I32)para_cvreg_pinned_n;
    para_cvreg_pinned[para_cvreg_pinned_n++] = (I32)(e - para_cvreg);
}

static void para_cvreg_unpin(para_cvreg_entry_t * e) {
    dTHX;
    if (e->pinned_pos < 0)
        return;
    I32 pos = e->pinned_pos;
    I32 last_slot = para_cvreg_pinned[--para_cvreg_pinned_n];
    para_cvreg_pinned[pos] = last_slot;
    para_cvreg[last_slot].pinned_pos = pos;
    e->pinned_pos = -1;
    e->pinned = 0;
    SvREFCNT_dec(e->cv);
}

static void para_cvreg_grow(void) {
    para_cvreg_entry_t * old = para_cvreg;
    U32 old_cap = para_cvreg_cap;
    U32 new_cap = old_cap ? old_cap * 2 : 64;
    Newxz(para_cvreg, new_cap, para_cvreg_entry_t);
    para_cvreg_cap = new_cap;
    para_cvreg_used = 0;
    for (U32 i = 0; i < old_cap; i++) {
        if (!old[i].cv)
            continue;
        U32 j = PARA_CVREG_HASH(old[i].cv);
        while (para_cvreg[j].cv)
            j = (j + 1) & (new_cap - 1);
        para_cvreg[j] = old[i];
        if (old[i].active_pos >= 0)
            para_cvreg_active[old[i].active_pos] = (I32)j; /* active[] stores slots: remap after the move */
        if (old[i].pinned_pos >= 0)
            para_cvreg_pinned[old[i].pinned_pos] = (I32)j; /* same for the pinned list */
        para_cvreg_used++;
    }
    if (old)
        Safefree(old);
}

/* Lookup an existing key (create == 0: NULL on miss) or insert on an empty slot (create == 1;
 * the caller grows first, so a probe chain always ends at a free slot). Dead keys (counts
 * cleared, cv retained) are still found and reused, which keeps probing correct without
 * tombstones. */
static para_cvreg_entry_t * para_cvreg_lookup(CV * cv, int create) {
    if (!cv)
        return NULL;
    if (!para_cvreg_cap) {
        if (!create)
            return NULL;
        para_cvreg_grow();
    }
    U32 mask = para_cvreg_cap - 1;
    U32 i = PARA_CVREG_HASH(cv);
    for (;;) {
        para_cvreg_entry_t * e = &para_cvreg[i];
        if (e->cv == cv)
            return e;
        if (!e->cv) {
            if (!create)
                return NULL;
            e->cv = cv;
            e->counts = NULL;
            e->arr_len = 0;
            e->max_depth = 0;
            e->active_pos = -1;
            e->on_stack = 0;
            e->pinned = 0;
            e->pinned_pos = -1;
            para_cvreg_used++;
            return e;
        }
        i = (i + 1) & mask;
    }
}

/* Defined below, next to the rest of the swap-time pad handling. */
static void _clean_landing_pad(pTHX_ CV * cv, I32 depth);

static void para_cvreg_add(CV * cv, I32 depth) {
    if (!cv || SvTYPE((SV *)cv) != SVt_PVCV || depth <= 0)
        return;
    para_cvreg_entry_t * e = para_cvreg_lookup(cv, 0);
    if (!e) {
        if ((para_cvreg_used + 1) * 4 >= para_cvreg_cap * 3)
            para_cvreg_grow();
        e = para_cvreg_lookup(cv, 1);
    }
    if (!e->counts) {
        Newxz(e->counts, depth + 1, I32);
        e->arr_len = depth + 1;
        e->on_stack = 0; /* the stale marker must not survive a dead-key reuse */
    }
    else if (depth >= e->arr_len) {
        I32 old_len = e->arr_len;
        Renew(e->counts, depth + 1, I32);
        Zero(e->counts + old_len, (depth + 1) - old_len, I32);
        e->arr_len = depth + 1;
    }
    if (e->active_pos < 0)
        para_cvreg_activate(e);
    e->counts[depth]++;
    if (depth > e->max_depth)
        e->max_depth = depth;
}

static void para_cvreg_dec(para_cvreg_entry_t * e, I32 depth) {
    if (!e || !e->counts || depth <= 0 || depth >= e->arr_len || e->counts[depth] <= 0)
        return; /* defensive: never unregister a depth we did not register */
    if (--e->counts[depth] > 0)
        return;
    while (e->max_depth > 0 && e->counts[e->max_depth] <= 0)
        e->max_depth--;
    if (e->max_depth == 0) {
        para_cvreg_deactivate(e);
        Safefree(e->counts);
        e->counts = NULL;
        e->arr_len = 0;
    }
}

static void para_cvreg_remove(CV * cv, I32 depth) {
    if (!cv || depth <= 0)
        return;
    para_cvreg_dec(para_cvreg_lookup(cv, 0), depth);
}

/** @brief Ground truth for "is a frame of this CV live anywhere": walk the running stack and every fiber's.
 *
 * The registry is a cache of where parked frames are, populated on every swap (Pass 0) and drained on
 * every resume (Pass 1). A frame that leaves without a swap in between (a longjmp out of a cancelled
 * or timed-out fiber body, or a fiber whose cxstack is unwound by a die) is never drained, so the
 * cache can claim a depth that nothing occupies. Callers that need to know whether a CV is *really*
 * active must ask the stacks, not the cache. */
static int para_si_cx_has_frame(PERL_SI * si, CV * cv);
static int para_si_has_frame(PERL_SI * si, CV * cv);

static int para_cv_frame_live(pTHX_ CV * cv) {
    PERL_SI * si = PL_curstackinfo;
    if (para_si_has_frame(si, cv))
        return 1;
    /* The main context (id -1) is not in fibers[], but it is parked with a live frame whenever a
     * fiber runs, so it has to be asked directly. */
    if (main_context.si && main_context.si != si && para_si_has_frame(main_context.si, cv))
        return 1;
    for (int i = 0; i < fiber_capacity; i++) {
        PERL_SI * fs = fibers[i] ? fibers[i]->si : NULL;
        if (!fs || fs == si)
            continue;
        if (para_si_has_frame(fs, cv))
            return 1;
    }
    return 0;
}

/** @brief TRUE if a live CXt_SUB/CXt_FORMAT frame for cv sits in this single si's own context stack. */
static int para_si_cx_has_frame(PERL_SI * si, CV * cv) {
    if (!si || !si->si_cxstack)
        return 0;
    for (I32 i = 0; i <= si->si_cxix; i++) {
        PERL_CONTEXT * cx = &(si->si_cxstack[i]);
        if ((CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) && cx->blk_sub.cv == cv)
            return 1;
    }
    return 0;
}

/** @brief TRUE if a live CXt_SUB/CXt_FORMAT frame for cv sits anywhere in this si's runlevel chain.
 *
 * A runlevel chain is not one context stack. push_scope()/new_stackinfo_flags() hands each nested
 * runlevel its own si with a fresh cxstack whose si_cxix starts at -1, and links it into the current
 * chain with si_prev/si_next. Frames created inside the nested runlevel therefore live in *its*
 * cxstack and are absent from the outer one, so a scan of si->si_cxstack alone reports "not live"
 * for a CV whose frame is live two runlevels down. Test2's subtest buffer is exactly such a runlevel:
 * subtest_buffered()/run_subtest() frames sit in a nested si of the main context, which is why the
 * settle pass used to zero CvDEPTH for a CV that had a live frame. */
static int para_si_has_frame(PERL_SI * si, CV * cv) {
    for (PERL_SI * s = si; s; s = s->si_prev)
        if (para_si_cx_has_frame(s, cv))
            return 1;
    for (PERL_SI * s = si ? si->si_next : NULL; s; s = s->si_next)
        if (para_si_cx_has_frame(s, cv))
            return 1;
    return 0;
}

/** @brief TRUE if a live frame for cv sits on the depositing (from) or resuming (to) stack.
 *
 * Pass 1c runs after PL_curstackinfo already points at the resuming stack, so the depositing stack is
 * only reachable through the fiber struct. Both are asked directly, over their whole runlevel chain,
 * because a pinned CV can still own a frame that no claim in the register accounts for. Settling such
 * a CV to CvDEPTH 0 zeroes the depth its live frame needs, and the frame's own pop then trips core's
 * cx_popsub_args assert (Padlist[CvDEPTH] == PL_curpad) or, in a non-debug build, reads @_ out of
 * the wrong pad. */
static int para_cv_live_on_swap(pTHX_ para_fiber_t * from, para_fiber_t * to, CV * cv) {
    if (from && from->si && para_si_has_frame(from->si, cv))
        return 1;
    if (to && to != from && to->si && para_si_has_frame(to->si, cv))
        return 1;
    return 0;
}

/** @brief Drops every claim the registry holds for a CV, leaving the (dead) key in place.
 *
 * Withdrawing a claim is not optional once the depth it justifies is being cleared: Pass 1b pins
 * CvDEPTH back to max_depth for every still-active entry, so a stale claim would resurrect the very
 * value we just released on the next swap. */
static void para_cvreg_purge(CV * cv) {
    para_cvreg_entry_t * e = para_cvreg_lookup(cv, 0);
    if (!e)
        return;
    para_cvreg_unpin(e);
    para_cvreg_deactivate(e);
    if (e->counts)
        Safefree(e->counts);
    e->counts = NULL;
    e->arr_len = 0;
    e->max_depth = 0;
}

/* Reset slot 0 of the pad a call would land on: slot 0 of a fresh perl pad is a REIFY-only,
 * empty AV (pad_push), so a call re-entering a shared subroutine must find its @_ slot in
 * exactly that state for pp_entersub's assert(!AvREAL(av)) / AvFILLp(av) == -1 invariants.
 * AvREIFY_only -- not bare AvREAL_off -- restores the full canonical state perl expects (else
 * the slot is neither-REAL-nor-REIFY and a later av_store re-turns it AvREAL). */
static void _clean_landing_pad(pTHX_ CV * cv, I32 depth) {
    PADLIST * pl = CvPADLIST(cv);
    if (!pl || depth <= 0 || depth > PadlistMAX(pl))
        return;
    /* A depth the registry still counts as occupied belongs to a fiber parked *inside* this CV, which will read
     * its @_ again on resume. Resetting it destroys the victim's live state two ways: the handle read back out
     * of $_[0] comes back undef, and since $_[1] is an alias for the caller's buffer, the caller's buffer is
     * emptied too -- silently, after the read itself already succeeded. Only a genuinely unoccupied depth may
     * be reset. See the depth invariant above for why an occupied landing depth exists in the first place. */
    para_cvreg_entry_t * e = para_cvreg_lookup(cv, 0);
    if (e && e->counts && depth < e->arr_len && e->counts[depth] > 0)
        return;
    AV * pad = (AV *)PadlistARRAY(pl)[depth];
    if (!pad || SvTYPE((SV *)pad) != SVt_PVAV)
        return;
    SV ** array = AvARRAY(pad);
    if (!array || AvMAX(pad) < 0)
        return;
    SV * args = array[0];
    if (args && SvTYPE(args) == SVt_PVAV) {
        if (AvREAL(args))
            para_report_avreal_pad(aTHX_ cv, depth, "pass2-cleaning");
        AvFILLp((AV *)args) = -1;
        AvREIFY_only((AV *)args);
    }
}

/* diagnostic: swap-time pad dump */
static void para_diag_pads(pTHX_ const char * tag, PERL_SI * si) {
    if (!si || !si->si_cxstack)
        return;
    for (I32 i = 0; i <= si->si_cxix; i++) {
        PERL_CONTEXT * cx = &(si->si_cxstack[i]);
        if (CxTYPE(cx) != CXt_SUB && CxTYPE(cx) != CXt_FORMAT)
            continue;
        CV * cv = cx->blk_sub.cv;
        if (!cv || SvTYPE((SV *)cv) != SVt_PVCV)
            continue;
        I32 occ = cx->blk_sub.olddepth + 1;
        PADLIST * pl = CvPADLIST(cv);
        I32 plmax = pl ? PadlistMAX(pl) : -1;
        /* This is core's own assert, restated so a mismatch can be reported instead of aborting:
         * cx_popsub_args() wants AvARRAY(PadlistARRAY(CvPADLIST(cv))[CvDEPTH]) == PL_curpad, and
         * PadlistARRAY yields the PAD (an AV) that holds each depth's pad. */
        AV * pad_occ = (pl && occ >= 0 && occ <= plmax) ? (AV *)PadlistARRAY(pl)[occ] : NULL;
        AV * pad_cd  = (pl && CvDEPTH(cv) >= 0 && CvDEPTH(cv) <= plmax) ? (AV *)PadlistARRAY(pl)[CvDEPTH(cv)] : NULL;
        SV ** at_occ = pad_occ ? AvARRAY(pad_occ) : NULL;
        SV ** at_cd  = pad_cd ? AvARRAY(pad_cd) : NULL;
        PARA_DIAGF("[diag] %s i=%d cv=%p dep=%d old=%d occ=%d pad@occ=%p pad@dep=%p curpad=%p%s%s%s\n",
            tag, i, (void*)cv, CvDEPTH(cv), cx->blk_sub.olddepth, occ, (void*)at_occ, (void*)at_cd, (void*)PL_curpad,
            (CvDEPTH(cv) != occ) ? "  <== DEPTH MISMATCH (assert would fire at pop)" : "",
            (at_cd != at_occ) ? "  <== DEPTH-PAD MISMATCH" : "",
            (!at_occ || at_occ == &PL_sv_undef) ? "  <== MISSING PAD" : "");
    }
}

/**
 * @brief Restores subroutine call depths, syncs the parked-depth registry, and cleans argument pads.
 *
 * Runs at every swap. See the registry block above for the invariant this maintains.
 *
 * @param from The fiber being deposited (its frames become parked).
 * @param to The fiber being resumed.
 */
static void _activate_current_depths(pTHX_ para_fiber_t * from, para_fiber_t * to) {
    para_diag_swapno++;
    /* Pass 0: the depositing fiber is parked now, so publish its live frame depths. Runs first
     * so a CV shared by both fibers ends the swap with exactly `from` registered and `to` not. */
    if (from && from != to && from->si && from->si->si_cxstack) {
        for (I32 i = 0; i <= from->si->si_cxix; i++) {
            PERL_CONTEXT * cx = &(from->si->si_cxstack[i]);
            if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
                CV * cv = cx->blk_sub.cv;
                if (cv && SvTYPE((SV *)cv) == SVt_PVCV)
                    para_cvreg_add(cv, cx->blk_sub.olddepth + 1);
            }
        }
    }

    PERL_SI * si = to->si;
    if (!si || !si->si_cxstack)
        return;

    /* Pass 1: Restore CvDEPTH for all active frames of the resuming fiber (its own deepest
     * frame depth per CV), deregister those depths now that the frames are live again, and
     * flag CVs on this stack so Pass 1b leaves them at their exact value and Pass 1c does
     * not settle a debt that a live frame is still entitled to. */
    for (I32 i = 0; i <= si->si_cxix; i++) {
        PERL_CONTEXT * cx = &(si->si_cxstack[i]);
        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
            CV * cv = cx->blk_sub.cv;
            if (cv && SvTYPE((SV *)cv) == SVt_PVCV) {
                I32 depth = cx->blk_sub.olddepth + 1;
                CvDEPTH(cv) = depth;
                para_cvreg_entry_t * e = para_cvreg_lookup(cv, 0);
                if (e) {
                    para_cvreg_dec(e, depth);
                    e->on_stack = 1; /* even once the last claim drains: Pass 1c needs this */
                }
            }
        }
    }

    /* Pass 1b: CVs parked somewhere but absent from the resuming stack: pin CvDEPTH to the
     * deepest parked frame so the next ++CvDEPTH() lands at max + 1, above every parked pad,
     * and clean that landing pad.
     *
     * Pinning is a loan, not a gift: the pads it reserves are released only by the pops of the frames
     * that occupy them, and a pop restores CvDEPTH to that frame's own olddepth. So the second parker of
     * a CV enters at 2 rather than 1 and pops back to 1, the third enters at 3 and pops back to 2 -- each
     * pop entirely correct, yet the counter settles one level above where it started, once per parker.
     * Pass 1c below -- run on every swap, never on a sub-return path -- is the repayment. */
    for (U32 k = 0; k < para_cvreg_active_n; k++) {
        para_cvreg_entry_t * e = &para_cvreg[para_cvreg_active[k]];
        int was_on_stack = e->on_stack;
        if (was_on_stack)
            continue; /* Pass 1 set this CV to its exact value; a pin here would gift a level.
                       * Keep on_stack set so Pass 1c knows a live frame is being resumed. */
        e->on_stack = 0;
        CvDEPTH(e->cv) = e->max_depth;
        _clean_landing_pad(aTHX_ e->cv, e->max_depth + 1);
        para_cvreg_pin(e);
    }

    /* Pass 1c: settle the pins. The registry only knows who *claims* a depth; it cannot know whether
     * the frame that justified a claim ever popped. The resuming stack is ground truth for one fiber,
     * and the swap is the only place this module is invoked while perl holds every live stack in a
     * known place, so the debt a pin represents is settled here, not from a sub-return hook.
     *
     * A pinned CV is released only when (a) no fiber claims a depth in it and (b) no frame of it is
     * live on the resuming stack. That is exactly the state in which nothing can ever use the pad or
     * the depth again, so the fabricated CvDEPTH is unwound to perl's ordinary 0 -- the same release
     * para_release_cv_depth() performs -- and the landing pad is made canonical once more.
     *
     * Pops that happen to be followed by a *later* swap are always repaid there: a fiber that pops its
     * last frame of a CV must hand control back over a swap, and that swap's Pass 1c sees the register
     * empty and the fiber bare. */
    for (U32 k = 0; k < para_cvreg_pinned_n; k++) {
        para_cvreg_entry_t * e = &para_cvreg[para_cvreg_pinned[k]];
        int was_on_stack = e->on_stack;
        e->on_stack = 0;
        if (e->max_depth > 0)
            continue; /* still claimed by a parked fiber: Pass 1b repinned it this swap */
        if (was_on_stack)
            continue; /* a live frame is entitled to the depth Pass 1 gave it */
        /* The register only knows *claims*, never frames. A frame that is still live can be parked on
         * either stack including in a nested runlevel of it, which is not visible from the si the
         * context happens to have stored so ask the runlevel chains of both stacks before unwinding
         * the fabricated depth. A live frame means nothing may use pad 0 or depth 0 until it pops, so
         * the entry stays pinned and the next swap retries this settle. */
        if (para_cv_live_on_swap(aTHX_ from, to, e->cv)) {
            PARA_DIAGF("[diag] SETTLE-SKIP-LIVE swap=%lu cv=%p dep=%d\n", para_diag_swapno, (void*)e->cv, CvDEPTH(e->cv));
            continue;
        }
        PARA_DIAGF("[diag] SETTLE swap=%lu from=%p to=%p cv=%p dep=%d -> 0 live=%d\n",
            para_diag_swapno, (void*)from, (void*)to, (void*)e->cv, CvDEPTH(e->cv), para_cv_frame_live(aTHX_ e->cv));
        CvDEPTH(e->cv) = 0;
        _clean_landing_pad(aTHX_ e->cv, 1);
        para_cvreg_unpin(e); /* index k reused: do not advance */
        k--;
    }

    /* Pass 2: Clean the landing pad for the NEXT call in each CV on the resuming stack. */
    for (I32 i = 0; i <= si->si_cxix; i++) {
        PERL_CONTEXT * cx = &(si->si_cxstack[i]);
        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
            CV * cv = cx->blk_sub.cv;
            if (cv && SvTYPE((SV *)cv) == SVt_PVCV)
                _clean_landing_pad(aTHX_ cv, CvDEPTH(cv) + 1);
        }
    }
    para_diag_pads(aTHX_ "TO", si);
    para_diag_pads(aTHX_ "FROM", from->si);
}

/**
 * @brief Swaps the internal Perl Interpreter state pointers.
 *
 * This is the core of the fiber implementation. It manually saves all global pointers that define the "state" of the
 * Perl virtual machine for the current context and restores them for the target context.
 *
 * @param from Context being paused.
 * @param to Context being resumed.
 */
void swap_perl_state(para_fiber_t * from, para_fiber_t * to) {
    dTHX;
    /* Save current state into 'from' context */
    from->si = PL_curstackinfo;

    // R4 localization: the just-deposited fiber's live frames are still intact here; any sub-frame whose pad @_
    // slot 0 is AvREAL is the state that will later trip pp_entersub for another fiber entering the same CV.
    para_report_reified_at_switch(aTHX_ from, "park");

    // The Argument Stack (Main Perl stack)
    from->curstack = PL_curstack;
    from->mainstack = PL_mainstack;
    from->stack_sp_offset = PL_stack_sp - PL_stack_base;

    // The Mark Stack (Tracks where lists begin on the argument stack)
    from->markstack = PL_markstack;
    from->markstack_ptr = PL_markstack_ptr;
    from->markstack_max = PL_markstack_max;

    // The Scope Stack (Tracks block entry/exit for cleanup)
    from->scopestack = PL_scopestack;
    from->scopestack_ix = PL_scopestack_ix;
    from->scopestack_max = PL_scopestack_max;
#ifdef DEBUGGING
    from->scopestack_name = PL_scopestack_name;
#endif
    // The Save Stack (Tracks 'local' variables and destructors)
    from->savestack = PL_savestack;
    from->savestack_ix = PL_savestack_ix;
    from->savestack_max = PL_savestack_max;

    // The Mortal Stack (Tracks temporary SVs that need decrementing)
    from->tmps_stack = PL_tmps_stack;
    from->tmps_ix = PL_tmps_ix;
    from->tmps_floor = PL_tmps_floor;
    from->tmps_max = PL_tmps_max;

    // Exception Environment (setjmp/longjmp buffers for eval/die)
    from->top_env = PL_top_env;

    // Op and Pad pointers (Where we are in the bytecode)
    from->curcop = PL_curcop;
    from->op = PL_op;
    from->comppad = PL_comppad;
    from->curpad = PL_curpad;
    from->curpm = PL_curpm;
    from->curpm_under = PL_curpm_under;
    from->reg_curpm = PL_reg_curpm;
    from->defgv = PL_defgv;
    from->last_in_gv = PL_last_in_gv;
    from->rs = PL_rs;
    from->ofsgv = PL_ofsgv;
    from->ors_sv = PL_ors_sv;
    from->defoutgv = PL_defoutgv;
    from->curstash = PL_curstash;
    from->defstash = PL_defstash;
    from->errors = PL_errors;

    // Load target state from 'to' context
    PL_curstackinfo = to->si;
    PL_curstack = to->curstack;
    PL_mainstack = to->mainstack;

    // Re-calculate stack bounds based on the new array (AV)
    PL_stack_base = AvARRAY(PL_curstack);
    PL_stack_max = PL_stack_base + AvMAX(PL_curstack);
    PL_stack_sp = PL_stack_base + to->stack_sp_offset;
    AvFILLp(PL_curstack) = to->stack_sp_offset;  // Keep stack AV metadata synced
    //
    PL_markstack = to->markstack;
    PL_markstack_ptr = to->markstack_ptr;
    PL_markstack_max = to->markstack_max;
    //
    PL_scopestack = to->scopestack;
    PL_scopestack_ix = to->scopestack_ix;
    PL_scopestack_max = to->scopestack_max;
#ifdef DEBUGGING
    PL_scopestack_name = to->scopestack_name;
#endif
    PL_savestack = to->savestack;
    PL_savestack_ix = to->savestack_ix;
    PL_savestack_max = to->savestack_max;

    //
    PL_tmps_stack = to->tmps_stack;
    PL_tmps_ix = to->tmps_ix;
    PL_tmps_floor = to->tmps_floor;
    PL_tmps_max = to->tmps_max;

    //
    PL_top_env = to->top_env;
    PL_curcop = to->curcop;
    PL_op = to->op;
    PL_comppad = to->comppad;
    PL_curpm = to->curpm;
    PL_curpm_under = to->curpm_under;
    PL_reg_curpm = to->reg_curpm;
    PL_defgv = to->defgv;
    PL_last_in_gv = to->last_in_gv;
    PL_rs = to->rs;
    PL_ofsgv = to->ofsgv;
    PL_ors_sv = to->ors_sv;
    PL_defoutgv = to->defoutgv;
    PL_curstash = to->curstash;
    PL_defstash = to->defstash;
    PL_errors = to->errors;

    if (PL_comppad)
        PL_curpad = AvARRAY(PL_comppad);
    else
        PL_curpad = to->curpad;

    // Restore CvDEPTH, sync the parked-depth registry, and clean landing pads
    _activate_current_depths(aTHX_ from, to);
}

/**
 * @brief Restores a context's saved Perl interpreter state in-place.
 *
 * Loads every saved interpreter global from @p to without performing an OS context switch. Used when a fiber longjmps
 * out of the system (e.g. via exit()) so that the top-level main context's perl-owned stacks are current again before
 * the jump propagates to perl_run/perl_destruct.
 *
 * Unlike swap_perl_state this deliberately leaves PL_top_env alone: the caller manages the jump environment so the
 * rethrow continues past the wrapper that caught the exit.
 *
 * @param to The context whose saved state should become current.
 */
void restore_perl_state(para_fiber_t * to) {
    dTHX;
    PL_curstackinfo = to->si;
    PL_curstack = to->curstack;
    PL_mainstack = to->mainstack;
    //
    PL_stack_base = AvARRAY(PL_curstack);
    PL_stack_max = PL_stack_base + AvMAX(PL_curstack);
    PL_stack_sp = PL_stack_base + to->stack_sp_offset;
    AvFILLp(PL_curstack) = to->stack_sp_offset;
    //
    PL_markstack = to->markstack;
    PL_markstack_ptr = to->markstack_ptr;
    PL_markstack_max = to->markstack_max;
    //
    PL_scopestack = to->scopestack;
    PL_scopestack_ix = to->scopestack_ix;
    PL_scopestack_max = to->scopestack_max;
#ifdef DEBUGGING
    PL_scopestack_name = to->scopestack_name;
#endif
    PL_savestack = to->savestack;
    PL_savestack_ix = to->savestack_ix;
    PL_savestack_max = to->savestack_max;
    //
    PL_tmps_stack = to->tmps_stack;
    PL_tmps_ix = to->tmps_ix;
    PL_tmps_floor = to->tmps_floor;
    PL_tmps_max = to->tmps_max;
    //
    PL_curcop = to->curcop;
    PL_op = to->op;
    PL_comppad = to->comppad;
    PL_curpm = to->curpm;
    PL_curpm_under = to->curpm_under;
    PL_reg_curpm = to->reg_curpm;
    PL_defgv = to->defgv;
    PL_last_in_gv = to->last_in_gv;
    PL_rs = to->rs;
    PL_ofsgv = to->ofsgv;
    PL_ors_sv = to->ors_sv;
    PL_defoutgv = to->defoutgv;
    PL_curstash = to->curstash;
    PL_defstash = to->defstash;
    PL_errors = to->errors;
    //
    if (PL_comppad)
        PL_curpad = AvARRAY(PL_comppad);
    else
        PL_curpad = to->curpad;
}

/** @brief Number of 16-byte slots in each fiber control stack. */
#define FIBER_STACK_DEPTH 2048

/**
 * @brief Allocates a fiber's Perl control stacks.
 *
 * The Mark, Scope, Save and Mortal stacks, plus the Stack Info context stack, are each allocated independently so perl
 * can grow them in place with realloc() when deep recursion or heavy scoping overflows the initial size. A shared block
 * would crash ("realloc(): invalid pointer") the moment perl tried to grow an interior pointer.
 *
 * @param c The fiber context to initialize.
 */
static void alloc_perl_stacks(pTHX_ para_fiber_t * c) {
    I32 sz = FIBER_STACK_DEPTH;

    /* Use perl's allocator (Newx/Safefree) so that when perl grows these stacks with Renew()/realloc() it recognizes
     * them as its own memory. Plain malloc'd memory panics ("realloc ... from wrong pool") in threaded-DEBUGGING perls
     * that tag allocations per interpreter. */
    PERL_SI * si = NULL;
    PERL_CONTEXT * ctx_stack = NULL;
    Newx(si, 1, PERL_SI);
    Newx(ctx_stack, 65, PERL_CONTEXT);
    Newx(c->markstack, sz, I32);
    Newx(c->scopestack, sz, I32);
#ifdef DEBUGGING
    Newx(c->scopestack_name, sz, const char *);
#endif
    Newx(c->savestack, sz + SS_MAXPUSH, ANY);
    Newx(c->tmps_stack, sz, SV *);
    if (!si || !ctx_stack || !c->markstack || !c->scopestack || !c->savestack || !c->tmps_stack) {
        Safefree(si);
        Safefree(ctx_stack);
        Safefree(c->markstack);
        Safefree(c->scopestack);
#ifdef DEBUGGING
        Safefree(c->scopestack_name);
#endif
        Safefree(c->savestack);
        Safefree(c->tmps_stack);
        c->markstack = NULL;
        c->scopestack = NULL;
        c->savestack = NULL;
        c->tmps_stack = NULL;
        return;
    }

    /* Only the SI header needs zeroing; the control stacks are managed through their own ix/count fields and never read
     * beyond them. */
    memset(si, 0, sizeof(PERL_SI));
    //
    si->si_cxmax = 64;
    si->si_cxstack = ctx_stack;
    si->si_cxix = -1;
    si->si_cxsubix = -1;
    si->si_type = PERLSI_MAIN;

    /* Link this fiber's stackinfo back to the permanent main stackinfo so that perl's POPSTACK_TO(PL_mainstack) (run on
     * exit()) can pop out of the fiber and land on the main argument stack. pop_stackinfo panics ("panic: POPSTACK")
     * and recurses via croak->my_exit if si_prev is NULL. We walk to the root rather than using the immediate current
     * stackinfo so the chain never dangles after an intermediate fiber is destroyed. */
    {
        PERL_SI * root = PL_curstackinfo;
        while (root->si_prev)
            root = root->si_prev;
        si->si_prev = root;
    }
    //
    c->si = si;
}

/**
 * @brief Resets a fiber's Perl control stacks back to their initial state.
 *
 * Called when a fiber is destroyed and its memory parked in the reuse cache. The stacks keep whatever size they grew to
 * and are simply re-initialized; resetting the bounds conservatively back to the starting size just means perl grows
 * them again if a new fiber recurses deep.
 *
 * @param c The fiber context to reset.
 */
static void reset_perl_stacks(pTHX_ para_fiber_t * c) {
    I32 sz = FIBER_STACK_DEPTH;
    PERL_SI * si = c->si;

    /* Release any mortal SVs still parked on the tmps stack */
    if (c->tmps_stack) {
        for (I32 i = 0; i <= c->tmps_ix; i++) {
            SV * sv = c->tmps_stack[i];
            if (sv && sv != &PL_sv_undef)
                SvREFCNT_dec(sv);
        }
    }

    if (c->curstack) {
        /* Do NOT av_clear the fiber's argument stack here. Slots below the last-saved stack pointer may already have
         * been popped and freed during earlier resume/yield cycles, so clearing them would double-decrement live SVs.
         * The AV is reused verbatim; new pushes overwrite the stale slots before they are ever read. */
        AvARRAY(c->curstack)[0] = &PL_sv_undef;
        AvFILLp(c->curstack) = 0;
    }
    c->stack_sp_offset = 0;
    if (si) {
        si->si_cxix = -1;
        si->si_stack = c->curstack;
    }
    /* exit()/POPSTACK_TO(PL_mainstack) inside this fiber must stop at the fiber's own argument stack instead of
     * unwinding the shared main contexts whose pads are not current while a fiber runs. */
    c->mainstack = c->curstack;
    //
    c->markstack_ptr = c->markstack;
    *c->markstack_ptr = 0;
    c->markstack_max = c->markstack + sz;
    //
    c->scopestack_ix = 0;
    c->scopestack_max = sz;
    //
    c->savestack_ix = 0;
    c->savestack_max = sz;
    //
    c->tmps_ix = -1;
    c->tmps_floor = -1;
    c->tmps_max = sz;

    /* Inherit globals from the current interpreter state */
    c->curcop = PL_curcop;
    c->op = PL_op;
    c->top_env = PL_top_env;
    c->curpm = PL_curpm;
    c->curpm_under = PL_curpm_under;
    c->reg_curpm = NULL;
    c->defgv = PL_defgv;
    c->last_in_gv = PL_last_in_gv;
    c->rs = PL_rs;
    c->ofsgv = PL_ofsgv;
    c->ors_sv = PL_ors_sv;
    c->defoutgv = PL_defoutgv;
    c->curstash = PL_curstash;
    c->defstash = PL_defstash;
    c->errors = PL_errors;
    c->comppad = NULL;
    c->curpad = NULL;
}

/**
 * @brief Allocates and initializes new Perl stacks for a fiber.
 *
 * Each fiber needs a complete set of independent stacks (Argument, Mark, Scope, Save, Mortal) to function as a separate
 * execution thread. The control stacks share a single allocation block for speed.
 *
 * @param c The fiber context to initialize.
 */
void init_perl_stacks(para_fiber_t * c) {
    dTHX;

    alloc_perl_stacks(aTHX_ c);
    if (!c->si)
        return;

    // Allocate Argument Stack (AV)
    c->curstack = newAV();
    AvREAL_off(c->curstack);  // Stacks do not 'own' their elements in the refcnt sense
    av_extend(c->curstack, 128);

    /* The control stacks are uninitialized beyond the SI header, so mark the tmps stack empty before reset runs its
     * release loop. */
    c->tmps_ix = -1;
    c->tmps_floor = -1;
    //
    reset_perl_stacks(aTHX_ c);
}

/**
 * @brief Frees the Perl stacks.
 *
 * @param c The fiber context whose stacks should be released.
 */
static void free_perl_stacks(pTHX_ para_fiber_t * c) {
    if (c->curstack) {
        /* Skip av_clear: stale slots may already be freed (see reset_perl_stacks). */
        SvREFCNT_dec((SV *)c->curstack);
        c->curstack = NULL;
    }
    if (c->si) {
        Safefree(c->si->si_cxstack);
        Safefree(c->si);
        c->si = NULL;
    }
    Safefree(c->markstack);
    Safefree(c->scopestack);
#ifdef DEBUGGING
    Safefree(c->scopestack_name);
#endif
    Safefree(c->savestack);
    Safefree(c->tmps_stack);
    c->markstack = NULL;
    c->scopestack = NULL;
    c->savestack = NULL;
    c->tmps_stack = NULL;
}

/** @brief Original perl OP_EXIT handler, saved when parataxis_pp_exit installs. */
static Perl_ppaddr_t parataxis_saved_pp_exit = NULL;

/** @brief Fiber-aware replacement for perl's pp_exit (OP_EXIT).
 *
 * perl's exit() longjmps up the JMPENV chain. A fiber resumed after a yield runs with a stale top_env
 * (the coro_call guard from its previous resume was popped), so a raw longjmp would jump to freed stack
 * memory and crash in __longjmp; on x64 Windows the CRT longjmp cannot jump across stacks at all
 * (0xC0000028 / STATUS_BAD_STACK). To keep exit() working inside fibers we capture the exit code at the
 * opcode, record it on the current fiber, and hand control back to perl's exit machinery on the caller's
 * stack (see para_entry_point / coro_call).
 *
 * Outside of a running fiber this delegates to the original pp_exit, so normal program exits are byte-for-byte
 * unchanged.
 */
static OP * parataxis_pp_exit(pTHX) {
    if (current_fiber_id < 0 || current_fiber_id >= fiber_capacity || !fibers[current_fiber_id])
        return parataxis_saved_pp_exit(aTHX);
    dSP;
    I32 anum;
    if (MAXARG < 1)
        anum = 0;
    else if (!TOPs) {
        anum = 0;
        (void)POPs;
    }
    else
        anum = SvIVx(POPs);
    PL_exit_flags |= PERL_EXIT_EXPECTED;
    para_fiber_t * c = fibers[current_fiber_id];
    c->exit_pending = 1;
    c->exit_status = (int)anum;
    /* Same as pp_exit: rethrow the exit within this fiber's own stack, so the JMPENV pushed by para_entry_point catches
     * it. */
    my_exit((U32)anum);
    /* NOTREACHED */
    return 0;
}

/**
 * @brief Initializes the fiber system and converts the main thread.
 *
 * This function must be called once before any other fiber operations. It captures the state of the main Perl
 * interpreter thread.
 *
 * @return int 0 on success.
 */
DLLEXPORT int init_system() {
    dTHX;
    if (system_initialized)
        return 0;
    if (!fiber_capacity)
        _fiber_table_grow(DEFAULT_FIBER_TABLE);
    if (max_thread_pool_size == 0) {
        max_thread_pool_size = get_cpu_count();
        if (max_thread_pool_size < MIN_THREAD_POOL)
            max_thread_pool_size = MIN_THREAD_POOL;
        if (max_thread_pool_size > MAX_THREADS)
            max_thread_pool_size = MAX_THREADS;
    }
    main_context.si = PL_curstackinfo;
    main_context.mainstack = PL_mainstack;
    main_context.transfer_data = &PL_sv_undef;
    main_context.id = -1;
    main_context.finished = 0;
    main_context.last_sender = -1;
    main_context.curpm = PL_curpm;
    main_context.curpm_under = PL_curpm_under;
    main_context.reg_curpm = PL_reg_curpm;
    main_context.defgv = PL_defgv;
    main_context.last_in_gv = PL_last_in_gv;
    main_context.rs = PL_rs;
    main_context.ofsgv = PL_ofsgv;
    main_context.ors_sv = PL_ors_sv;
    main_context.defoutgv = PL_defoutgv;
    main_context.curstash = PL_curstash;
    main_context.defstash = PL_defstash;
    main_context.errors = PL_errors;
    system_initialized = 1;
    /* Route exit() through our fiber-aware handler. Perl dispatches the pp table through per-op pointers
     * (op->op_ppaddr) captured at compile time, and init_system runs at BEGIN, so every op compiled after this module
     * loads already points at parataxis_pp_exit. */
    if (!parataxis_saved_pp_exit) {
        parataxis_saved_pp_exit = PL_ppaddr[OP_EXIT];
        PL_ppaddr[OP_EXIT] = parataxis_pp_exit;
    }
#ifndef _WIN32
    install_stack_guard();
    rightsize_fiber_limit();
#endif
#ifdef _WIN32
    /* Convert the main thread into a fiber so it can be switched out */
    if (!main_fiber_handle) {
        main_fiber_handle = ConvertThreadToFiber(NULL);
        if (!main_fiber_handle) {
            if (GetLastError() == ERROR_ALREADY_FIBER)
                main_fiber_handle = GetCurrentFiber();
        }
    }
#endif
    init_threads();
    return 0;
}

/**
 * @brief Performs the low-level OS context switch.
 *
 * Saves the Perl state and then uses OS primitives (SwitchToFiber or swapcontext) to change execution flow.
 *
 * @param target_id ID of the target fiber (-1 for Main).
 */
void perform_switch(int target_id, int set_last_sender) {
    dTHX;
    if (target_id == current_fiber_id)
        return;
    para_fiber_t * from = (current_fiber_id == -1) ? &main_context : fibers[current_fiber_id];
    para_fiber_t * to = (target_id == -1) ? &main_context : fibers[target_id];
    if (set_last_sender)
        to->last_sender = current_fiber_id;
    current_fiber_id = target_id;
    swap_perl_state(from, to);
#ifdef _WIN32
    if (target_id == -1)
        SwitchToFiber(main_fiber_handle);
    else
        SwitchToFiber(to->context);
#elif defined(USE_ASM_CORO)
    para_coro_switch(&from->rsp, &to->rsp);
#else
    swapcontext(&from->context, &to->context);
#endif
}

/**
 * @brief Yields execution back to the caller or the main thread.
 *
 * Suspends the current fiber and returns a value to the context that last resumed or called this fiber.
 *
 * @param ret_val The Perl SV to "return" to the caller.
 * @return SV* The value passed in when this fiber is eventually resumed.
 */
DLLEXPORT SV * coro_yield(SV * ret_val) {
    dTHX;
    if (current_fiber_id == -1)
        return &PL_sv_undef;
    para_fiber_t * self = fibers[current_fiber_id];
    int parent = self->parent_id;
    if (parent != -1 && (!fibers[parent] || fibers[parent]->finished))
        parent = self->last_sender;
    else if (parent == -1)
        parent = self->last_sender;
    if (parent >= 0 && (!fibers[parent] || fibers[parent]->finished))
        parent = -1;
    para_fiber_t * caller = (parent == -1) ? &main_context : fibers[parent];

    /* Pass return value to caller */
    if (caller->transfer_data != ret_val) {
        if (caller->transfer_data && caller->transfer_data != &PL_sv_undef)
            SvREFCNT_dec(caller->transfer_data);
        caller->transfer_data = ret_val;
        if (ret_val && ret_val != &PL_sv_undef)
            SvREFCNT_inc(ret_val);
    }

    perform_switch(parent, 0);

    /* Retrieve value passed back during resume */
    SV * res = self->transfer_data;
    self->transfer_data = &PL_sv_undef;
    if (res && res != &PL_sv_undef)
        sv_2mortal(res);
    return res;
}

/**
 * @brief Entry point function for all new fibers.
 *
 * Sets up the Perl environment (ENTER/SAVETMPS), unpacks arguments, calls the user coderef, handles results/errors, and
 * manages the fiber's completion lifecycle.
 *
 * @param c Pointer to the fiber context being started.
 */
void para_entry_point(para_fiber_t * c) {
    dTHX;
    c->started = 1;
    ENTER;
    SAVETMPS;
    dSP;
    dJMPENV;
    PUSHMARK(SP);

    /* Unpack arguments passed during coro_call */
    if (c->transfer_data && SvROK(c->transfer_data) && SvTYPE(SvRV(c->transfer_data)) == SVt_PVAV) {
        AV * args = (AV *)SvRV(c->transfer_data);
        I32 len = av_top_index(args) + 1;
        for (I32 i = 0; i < len; i++) {
            SV ** svp = av_fetch(args, i, 0);
            if (svp)
                XPUSHs(*svp);
        }
    }
    PUTBACK;

    int count;
    {
        int volatile ret;
        JMPENV_PUSH(ret);
        if (ret == 2) {
            /* exit() landed here. The fiber's saved top_env goes stale after its first yield (the coro_call
             * guard it points at is popped), so a raw longjmp across stacks would jump to freed memory and
             * crash in __longjmp; on x64 Windows the CRT cannot longjmp across stacks at all (0xC0000028 /
             * STATUS_BAD_STACK). Either way we must NOT rethrow from this fiber stack. Record that this
             * fiber's subtree asked to exit, mark it finished, and switch back to whoever called it.
             * coro_call sees exit_pending and re-enters perl's exit machinery on the caller's stack, where
             * the whole JMPENV chain lives on one stack. */
            int fid = current_fiber_id;
            if (fid >= 0 && fid < fiber_capacity && fibers[fid])
                fibers[fid]->exit_pending = 1;
            JMPENV_POP;
            para_fiber_t * fc = (fid >= 0 && fid < fiber_capacity) ? fibers[fid] : c;
            if (fc) {
                fc->finished = true;
                int parent = fc->parent_id;
                if (parent != -1 && (!fibers[parent] || fibers[parent]->finished))
                    parent = -1;
                perform_switch(parent, 0);
            }
            while (1)
                coro_yield(&PL_sv_undef);
        }
        else if (ret != 0) {
            /* A non-exit longjmp (die) that escaped the body's G_EVAL. This should not normally happen; finish the
             * fiber with whatever is in $@ and hand control back to the caller. */
            JMPENV_POP;
            para_fiber_t * fc = (current_fiber_id >= 0 && current_fiber_id < fiber_capacity) ? fibers[current_fiber_id] : c;
            if (fc) {
                fc->finished = true;
                int parent = fc->parent_id;
                if (parent != -1 && (!fibers[parent] || fibers[parent]->finished))
                    parent = -1;
                perform_switch(parent, 0);
            }
            while (1)
                coro_yield(&PL_sv_undef);
        }
        count = call_sv(c->user_cv, G_SCALAR | G_EVAL);
    }

    SPAGAIN;
    SV * ret_val = &PL_sv_undef;
    if (count == 1)
        ret_val = POPs;
    PUTBACK;

    c->finished = true;

    /* Cleanup transfer data and store result */
    if (c->transfer_data && c->transfer_data != &PL_sv_undef) {
        SvREFCNT_dec(c->transfer_data);
        c->transfer_data = &PL_sv_undef;
    }
    if (ret_val && ret_val != &PL_sv_undef) {
        SvREFCNT_inc(ret_val);
        c->transfer_data = ret_val;
    }

    /* Update the Perl-level Acme::Parataxis object.
     *
     * The object is a blessed flat arrayref; slot layout mirrors the Perl-side constants F_ERROR=2, F_RESULT=3,
     * F_IS_READY=5, F_CALLBACKS=6. Writing the result/error slots directly avoids a method dispatch per fiber
     * completion; the callback dispatch sub is only invoked when callbacks were actually registered. */
    if (c->self_ref && SvROK(c->self_ref)) {
        AV * obj = (AV *)SvRV(c->self_ref);
        SV ** ready = av_fetch(obj, 5, 0);
        if (!(ready && *ready && SvTRUE(*ready))) {
            int died;
            if (SvROK(ERRSV) && SvOBJECT(SvRV(ERRSV)))
                died = 1;    /* blessed exceptions are always errors; e.g. Error::Timeout with an overloaded "" */
            else
                died = SvTRUE(ERRSV);
            if (died) {
                av_store(obj, 2, newSVsv(ERRSV));
                av_store(obj, 5, &PL_sv_yes);
            }
            else {
                if (ret_val != &PL_sv_undef)
                    av_store(obj, 3, SvREFCNT_inc(ret_val));
                av_store(obj, 5, &PL_sv_yes);
            }
            /* F_IS_DONE=1, F_FID=-1: the fiber is finished, so the object is marked done and must not touch the
             * (already recycled) C context from DESTROY/is_done. */
            av_store(obj, 1, &PL_sv_yes);
            SV ** fp = av_fetch(obj, 4, 0);
            if (fp && *fp)
                sv_setiv(*fp, -1);
            SV ** cbs = av_fetch(obj, 6, 0);
            if (cbs && *cbs && SvROK(*cbs) && SvTYPE(SvRV(*cbs)) == SVt_PVAV) {
                AV * cbav = (AV *)SvRV(*cbs);
                if (av_len(cbav) >= 0) {
                    dSP;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(c->self_ref);
                    PUTBACK;
                    call_method("_dispatch_callbacks", G_DISCARD);
                    FREETMPS;
                    LEAVE;
                }
            }
        }
    }
    FREETMPS;
    LEAVE;

    /* Final yield back to caller */
    coro_yield(c->transfer_data ? c->transfer_data : &PL_sv_undef);

    /* Loop indefinitely if resumed after finish */
    while (1)
        coro_yield(&PL_sv_undef);
}

#ifdef _WIN32
/** @brief Windows fiber callback wrapper. */
static void WINAPI fiber_entry(void * param) { para_entry_point((para_fiber_t *)param); }
#else
/** @brief POSIX makecontext callback wrapper. */
static void posix_entry(int fiber_id) { para_entry_point(fibers[fiber_id]); }
#endif

#ifndef _WIN32
/**
 * @brief Allocates a fiber stack backed by a lazily-committed mmap mapping.
 *
 * The usable stack is FIBER_STACK_SZ with a PROT_NONE guard page below it. The mapping uses FIBER_MMAP_FLAGS:
 * MAP_NORESERVE as a real flag (Linux, FreeBSD), so a 64 MB reservation is free until touched, and a small
 * FIBER_STACK_SZ where it is missing or a 0-valued legacy no-op (macOS, OpenBSD), so a tableful of fibers stays
 * under the process memory budget. No
 * physical pages are consumed until they are used.
 *
 * @param sz Requested usable size (ignored; all stacks are FIBER_STACK_SZ).
 * @return void* Pointer to the usable stack (guard page below it), or NULL.
 */
static void * alloc_fiber_stack(size_t sz) {
    (void)sz;
    init_guard_sz();
    if (stack_cache_count > 0)
        return stack_cache[--stack_cache_count];
    size_t total = FIBER_STACK_SZ + fiber_guard_sz;
    void * base = mmap(NULL, total, PROT_READ | PROT_WRITE, FIBER_MMAP_FLAGS, -1, 0);
    if (base == MAP_FAILED)
        return NULL;
    mprotect(base, fiber_guard_sz, PROT_NONE);
    return (char *)base + fiber_guard_sz;
}

/** @brief Returns a fiber stack to the reuse cache or unmaps it. */
static void free_fiber_stack(void * p, size_t sz) {
    (void)sz;
    if (p && stack_cache_count < MAX_CACHED_STACKS) {
        stack_cache[stack_cache_count++] = p;
        return;
    }
    if (p)
        munmap((char *)p - fiber_guard_sz, FIBER_STACK_SZ + fiber_guard_sz);
}

/** @brief Previous SIGSEGV disposition, restored when a fault is not ours. */
static struct sigaction prev_sigsegv_act;
/** @brief Alternate signal stack the guard handler runs on. */
static char * guard_alt_stack;
/** @brief Thread that owns the fiber scheduler (main thread). */
static pthread_t guard_owner_thread;

/**
 * @brief SIGSEGV handler: reports a genuine fiber C-stack overflow.
 *
 * Runs on the alternate signal stack. A fault in the current fiber's guard page means the fiber used more than
 * FIBER_STACK_SZ of C stack; a clear message is emitted and the default disposition is restored so the process aborts
 * (with a core if enabled). Any other fault is forwarded to the previously installed handler.
 */
static void stack_guard_handler(int sig, siginfo_t * si, void * uc) {
    para_fiber_t * c = (current_fiber_id >= 0 && current_fiber_id < fiber_capacity) ? fibers[current_fiber_id] : NULL;
    if (!pthread_equal(pthread_self(), guard_owner_thread) || current_fiber_id < 0 || current_fiber_id >= fiber_capacity ||
        !fibers[current_fiber_id]) {
        if (prev_sigsegv_act.sa_flags & SA_SIGINFO)
            prev_sigsegv_act.sa_sigaction(sig, si, uc);
        else if (prev_sigsegv_act.sa_handler == SIG_DFL)
            signal(SIGSEGV, SIG_DFL);
        else if (prev_sigsegv_act.sa_handler != SIG_IGN)
            prev_sigsegv_act.sa_handler(sig);
        return;
    }
    char * guard_base = (char *)c->stack_p - fiber_guard_sz;
    char * fault = (char *)si->si_addr;
    if (c->stack_p == NULL || fault < guard_base || fault >= (char *)c->stack_p) {
        if (prev_sigsegv_act.sa_flags & SA_SIGINFO)
            prev_sigsegv_act.sa_sigaction(sig, si, uc);
        else if (prev_sigsegv_act.sa_handler == SIG_DFL)
            signal(SIGSEGV, SIG_DFL);
        else if (prev_sigsegv_act.sa_handler != SIG_IGN)
            prev_sigsegv_act.sa_handler(sig);
        return;
    }
    static const char msg[] = "Parataxis: fatal: fiber C-stack overflow (> 64MB used); aborting\n";
    write(2, msg, sizeof(msg) - 1);
    signal(SIGSEGV, SIG_DFL);
}

/** @brief Per-fiber anonymous-memory charge beyond the stack itself.
 *
 * OpenBSD's RLIMIT_DATA counts every anonymous mapping and the whole malloc arena, and each fiber additionally
 * allocates five Perl control stacks (FIBER_STACK_DEPTH entries each), a context stack, its context struct and a
 * share of the grown table. Measured on the 7.8 CI runner: 504 of the 507 predicted 8 MiB frames fit a 4 GiB
 * budget, a 64 MiB shortfall over ~500 fibers, so allow 160 KiB per fiber, comfortably over the ~130 KiB charged. */
#define FIBER_CHARGED_OVERHEAD (160 * 1024)

/**
 * @brief Right-sizes the default fiber limit to the platform's anonymous-memory budget.
 *
 * Every fiber reserves FIBER_STACK_SZ plus one guard page of anonymous memory. Where MAP_NORESERVE is a real flag
 * (Linux, FreeBSD) the mapping is a free reservation and RLIMIT_DATA does not count it, so this is a no-op. OpenBSD
 * defines MAP_NORESERVE as 0, a legacy no-op the preprocessor sees but that reserves nothing, and its RLIMIT_DATA
 * counts every anonymous mmap at full size, so the generous DEFAULT_FIBER_LIMIT would let the very first big spawn
 * explode the process budget; the failing mmap then surfaces as a confusing table-full message. DragonFly has no
 * MAP_NORESERVE but charges only brk/sbrk to RLIMIT_DATA, so it never clamps. The clamp raises the soft limit
 * to the hard limit when permitted and cuts max_fibers to the number of full frames that actually fit: each
 * frame is the stack plus the per-fiber charge FIBER_CHARGED_OVERHEAD, and four frames stay free as headroom for
 * perl, the tables, the worker pool and the guard handler's alt stack. Keying on the
 * MAP_NORESERVE macro itself would compile this OUT on OpenBSD (defined as 0) and IN on DragonFly (undefined), the
 * exact inversion of the intent, so the guard names __OpenBSD__ directly.
 */
static void rightsize_fiber_limit(void) {
#ifndef _WIN32
#if defined(__OpenBSD__)
    struct rlimit rl;
    if (getrlimit(RLIMIT_DATA, &rl) != 0 || rl.rlim_cur == RLIM_INFINITY)
        return;
    if (rl.rlim_max > rl.rlim_cur) {
        struct rlimit nr = rl;
        nr.rlim_cur = rl.rlim_max;
        if (setrlimit(RLIMIT_DATA, &nr) == 0)
            rl.rlim_cur = rl.rlim_max;
    }
    /* A hard infinity made the raise go unlimited too; nothing to clamp against. */
    if (rl.rlim_cur == RLIM_INFINITY)
        return;
    init_guard_sz();
    size_t frame = FIBER_STACK_SZ + fiber_guard_sz + FIBER_CHARGED_OVERHEAD;
    long cap = (long)( rl.rlim_cur / (rlim_t)frame ) - 4;
    if (cap < 8)
        cap = 8;
    if (cap < DEFAULT_FIBER_LIMIT)
        max_fibers = (int)cap;
#endif
#endif
}

/**
 * @brief Installs the fiber stack guard handler (POSIX).
 *
 * Sets up an alternate signal stack and hooks SIGSEGV so that a fiber running into its guard page is detected and
 * reported cleanly.
 */
static void install_stack_guard(void) {
    if (guard_alt_stack)
        return;
    init_guard_sz();
    guard_owner_thread = pthread_self();
    size_t alt_sz = 256 * 1024;
    guard_alt_stack = mmap(NULL, alt_sz, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON | MAP_STACK, -1, 0);
    if (guard_alt_stack == MAP_FAILED) {
        guard_alt_stack = NULL;
        return;
    }
    stack_t ss = {0};
    ss.ss_sp = guard_alt_stack;
    ss.ss_size = alt_sz;
    if (sigaltstack(&ss, NULL) == -1)
        return;
    struct sigaction act = {0};
    act.sa_sigaction = stack_guard_handler;
    act.sa_flags = SA_SIGINFO | SA_ONSTACK | SA_NODEFER;
    sigemptyset(&act.sa_mask);
    if (sigaction(SIGSEGV, &act, &prev_sigsegv_act) == -1)
        return;
}

#endif /* !_WIN32 */

/**
 * @brief Arms the OS-level context for a (possibly recycled) fiber.
 *
 * Installs the entry trampoline on the fiber's stack so that the next context switch resumes the fiber from scratch.
 *
 * @param c The fiber context to arm.
 * @param idx The fiber ID (used by the ucontext makecontext path).
 */
static void arm_fiber_context(para_fiber_t * c, int idx) {
#ifdef _WIN32
    c->context = CreateFiber(0, fiber_entry, c);
#else
#ifdef USE_ASM_CORO
    /*
     * Lay out the fresh stack for the assembly switch. When the switch routine resumes this context it first pops the
     * six dummy saved registers, then "returns" into para_trampoline. The trampoline pops the fiber pointer and
     * tail-calls para_entry_point with the correct ABI stack alignment.
     */
    void ** slot = (void **)((char *)c->stack_p + c->stack_sz);
    slot -= 8; /* 6 saved regs + return address + fiber pointer */
    for (int i = 0; i < 6; i++)
        slot[i] = NULL;
    slot[6] = (void *)&para_trampoline;
    slot[7] = c;
    c->rsp = slot;
#else
    getcontext(&c->context);
    c->context.uc_stack.ss_sp = c->stack_p;
    c->context.uc_stack.ss_size = c->stack_sz;
    c->context.uc_link = &main_context.context;
    makecontext(&c->context, (void (*)())posix_entry, 1, idx);
#endif
#endif
}

/**
 * @brief Allocates and prepares a new Fiber context.
 *
 * @param user_code Coderef to execute in the fiber.
 * @param self_ref Acme::Parataxis object to notify on completion.
 * @return int Unique ID of the new fiber, or negative on error.
 */
DLLEXPORT int create_fiber(SV * user_code, SV * self_ref) {
    dTHX;
    if (fiber_used >= max_fibers)
        return -2;
    if (!fiber_capacity)
        _fiber_table_grow(DEFAULT_FIBER_TABLE);
    int idx;
    if (free_slot_count > 0)
        idx = free_slots[--free_slot_count];
    else {
        /* Every allocated slot is taken while more fibers are still allowed: double the table (bounded by
         * HARD_FIBER_LIMIT) and take one of the slots it just added to the free list. */
        if (_fiber_table_grow(fiber_capacity * 2) && free_slot_count > 0)
            idx = free_slots[--free_slot_count];
        else {
            /* Safety net: scan for a slot if the free list is ever exhausted. */
            idx = -1;
            for (int i = 0; i < fiber_capacity; i++) {
                if (fibers[i] == NULL && !fiber_destroyed[i]) {
                    idx = i;
                    break;
                }
            }
        }
    }
    if (idx == -1)
        return -2;
    fiber_used++;

    para_fiber_t * c = NULL;
#ifndef _WIN32
    if (fiber_cache_count > 0)
        c = fiber_cache[--fiber_cache_count];
#endif
    if (c) {
        /* Recycle a parked fiber context: re-inherit globals, clear pads */
        reset_perl_stacks(aTHX_ c);
    }
    else {
        c = (para_fiber_t *)malloc(sizeof(para_fiber_t));
        if (!c) {
            _release_slot(idx);
            return -3;
        }
        memset(c, 0, sizeof(para_fiber_t));
        /* Initialize Perl stacks */
        init_perl_stacks(c);
        if (!c->si) {
            free(c);
            _release_slot(idx);
            return -3;
        }
#ifndef _WIN32
        c->stack_sz = FIBER_STACK_SZ;
        c->stack_p = alloc_fiber_stack(c->stack_sz);
        if (!c->stack_p) {
            free_perl_stacks(aTHX_ c);
            free(c);
            _release_slot(idx);
            return -3;
        }
#else
        c->context = NULL;
#endif
    }

    /* `owner` stamps which interpreter's arena owns this record, its stacks, and the SVs it references. The C tables
     * behind threads->create (perl_clone) are process-shared, so a cloned worker inherits the parent's opaque fiber
     * ids; destroy_coro() refuses a record whose owner is not the current interpreter so a worker's destruct cannot
     * free memory that belongs to the parent's pool. A recycled record re-binds to whoever is creating now. aTHX is
     * only a real expression on ithreads builds, where perl_clone (and the whole hazard) can exist at all. */
#ifdef USE_ITHREADS
    c->owner = (void *)aTHX;
#else
    c->owner = NULL;
#endif

    /* Reset the coderef's call depth so the fiber starts clean */
    if (user_code && user_code != &PL_sv_undef)
        force_depth_zero(user_code);

    c->user_cv = user_code;
    if (user_code && user_code != &PL_sv_undef)
        SvREFCNT_inc(user_code);
    c->self_ref = self_ref;
    if (self_ref && self_ref != &PL_sv_undef)
        SvREFCNT_inc(self_ref);
    c->id = idx;
    c->parent_id = -1;
    c->last_sender = -1;
    c->finished = 0;
    c->started = 0;
    c->exit_pending = 0;
    c->exit_status = 0;
    c->transfer_data = &PL_sv_undef;
    fibers[idx] = c;

    arm_fiber_context(c, idx);
    return idx;
}

/**
 * @brief Resumes a fiber (asymmetric call).
 *
 * Suspends the caller and switches execution to the specified fiber. Sets the caller as the 'parent' for future yields.
 *
 * @param fiber_id Fiber ID to call.
 * @param args Perl SV (usually arrayref) to pass as arguments to the fiber.
 * @return SV* Result yielded by the fiber.
 */
DLLEXPORT SV * coro_call(int fiber_id, SV * args) {
    dTHX;
    if (fiber_id < 0 || fiber_id >= fiber_capacity || !fibers[fiber_id] || fibers[fiber_id]->finished)
        return &PL_sv_undef;
    /* A fiber whose context stack the deadlock purger tore down (started, not finished, si_cxix == -1)
     * has no live frame to resume: perform_switch into it would run unwound perl state and underflow the
     * context stack. Its run died with it parked, so any wait that was still registered can still try to
     * wake it -- that wake must be a no-op. The record stays in the table (the fid must keep its slot). */
    if (fibers[fiber_id]->started && fibers[fiber_id]->si && fibers[fiber_id]->si->si_cxix < 0)
        return &PL_sv_undef;
    if (fibers[fiber_id]->transfer_data != args) {
        if (fibers[fiber_id]->transfer_data && fibers[fiber_id]->transfer_data != &PL_sv_undef)
            SvREFCNT_dec(fibers[fiber_id]->transfer_data);
        fibers[fiber_id]->transfer_data = args;
        if (args && args != &PL_sv_undef)
            SvREFCNT_inc(args);
    }
    fibers[fiber_id]->parent_id = current_fiber_id;

    /* Guard the fiber run with our own jump environment. When the fiber longjmps out of the system (exit(), or a die
     * that escapes the body's G_EVAL), perl never pops back into the scheduler: it unwinds the fiber's own contexts and
     * jumps to the innermost env. That env chain is anchored here, so we can restore the perl state of whoever called
     * coro_call (perl-owned stacks only) before rethrowing.
     *
     * The caller of this coro_call is the parent fiber (or main, for the top-level call). Restoring the PARENT's perl
     * state matters: the next env on the chain is the parent's G_EVAL, and its case-2 cleanup runs `my_exit_jump()`
     * which dounwinds the *current* savestack. If we left main's perl state current here, that dounwind would pop
     * main's savestack entries (e.g. the scheduler's run_fiber_checked XSUB arena destructors) and perl_run's later
     * LEAVE loop would free the same arenas a second time -> Affix "free from wrong pool" panic. Restoring the parent's
     * own state makes the dounwind pop the parent's savestack (freed exactly once there, or leaked harmlessly if the
     * parent's XSUB scopes were abandoned by the jump). Only the top-level wrapper (parent == main) restores main's
     * state, so perl_run/perl_destruct finish on the main context. */
    dJMPENV;
    int volatile ret;
    JMPENV_PUSH(ret);
    if (ret) {
        JMPENV_POP;
        int parent = (fibers[fiber_id] ? fibers[fiber_id]->parent_id : -1);
        if (parent >= 0 && parent < fiber_capacity && fibers[parent]) {
            current_fiber_id = parent;
            restore_perl_state(fibers[parent]);
        }
        else {
            current_fiber_id = -1;
            restore_perl_state(&main_context);
        }
        /* Propagate an exit() pending in the (sub)fiber we were resuming to the fiber that called us. Nested fiber
         * exits then keep unwinding one stack level at a time and only re-enter perl's exit machinery on the main
         * stack. */
        if (fibers[fiber_id] && fibers[fiber_id]->exit_pending && current_fiber_id >= 0) {
            para_fiber_t * caller = fibers[current_fiber_id];
            if (caller) {
                caller->exit_pending = 1;
                caller->exit_status = fibers[fiber_id]->exit_status;
            }
        }
        JMPENV_JUMP(ret);
    }
    if (!fibers[fiber_id]->started)
        fibers[fiber_id]->top_env = &cur_env;
    perform_switch(fiber_id, 1);
    JMPENV_POP;
    if (fibers[fiber_id] && fibers[fiber_id]->exit_pending) {
        /* The fiber's exit() was caught on the fiber stack (see para_entry_point). We are back on the caller's stack,
         * so perl's exit machinery (which longjmps up the JMPENV chain) is safe here: every env it will hit lives on
         * this same stack. */
        int exit_status = fibers[fiber_id]->exit_status;
        fibers[fiber_id]->exit_pending = 0;
        fibers[fiber_id]->exit_status = 0;
        my_exit((U32)exit_status);
        /* NOTREACHED */
    }
    if (fibers[fiber_id] && fibers[fiber_id]->finished) {
        if (fibers[fiber_id]->transfer_data && fibers[fiber_id]->transfer_data != &PL_sv_undef) {
            SvREFCNT_dec(fibers[fiber_id]->transfer_data);
            fibers[fiber_id]->transfer_data = &PL_sv_undef;
        }
        destroy_coro(fiber_id);
    }
    para_fiber_t * me = (current_fiber_id == -1) ? &main_context : fibers[current_fiber_id];
    SV * res = me->transfer_data;
    me->transfer_data = &PL_sv_undef;
    if (res && res != &PL_sv_undef)
        sv_2mortal(res);
    return res;
}

/**
 * @brief Runs a fiber to its next suspension point and cleans it up.
 *
 * Combines the scheduler's per-fiber work (resume, finish detection and destruction) into a single call so the FFI tax
 * is paid once per fiber instead of four times.
 *
 * @param fiber_id Fiber to resume.
 * @param args Argument arrayref to pass to the fiber, or NULL for none.
 * @return int -1 fiber not found, 0 still running (re-enqueue),
 *              1 finished and destroyed, 3 yielded 'WAITING'.
 */
DLLEXPORT int run_fiber_checked(int fiber_id, SV * args) {
    dTHX;
    if (fiber_id < 0 || fiber_id >= fiber_capacity || !fibers[fiber_id])
        return -1;
    para_fiber_t * c = fibers[fiber_id];
    if (c->finished) {
        destroy_coro(fiber_id);
        return 1;
    }
    /* A fiber torn down by the deadlock purger (started, not finished, si_cxix == -1) can never be run
     * again: coro_call() would underflow its unwound context stack. Report "not found" so the scheduler
     * neither re-enqueues it (status 0) nor marks it done (status 1) -- the record and its fid must stay
     * occupied. See coro_call()'s guard for the other resume paths. */
    if (c->started && c->si && c->si->si_cxix < 0)
        return -1;
    SV * ret = coro_call(fiber_id, args);
    if (!fibers[fiber_id] || fibers[fiber_id]->finished) {
        destroy_coro(fiber_id);
        return 1;
    }
    if (ret && SvROK(ret) && SvTYPE(SvRV(ret)) == SVt_PVAV) {
        AV * av = (AV *)SvRV(ret);
        if (av_len(av) == 0) {
            SV ** svp = av_fetch(av, 0, 0);
            if (svp && *svp && SvPOK(*svp) && strEQ(SvPVX(*svp), "WAITING"))
                return 3;
        }
    }
    return 0;
}

/**
 * @brief Creates a fiber object, its C context, and runs it inline.
 *
 * Merges the Perl-side spawn sequence (bless, create_fiber, run_fiber_checked) into a single FFI call. Returns the
 * blessed fiber object with the run status stored at object slot 8 (F_LAST_STATUS): 1 finished, 0 yielded (re-enqueue),
 * 3 yielded 'WAITING', -1 not found.
 *
 * @param user_code Coderef to run as the fiber body.
 * @param class     Class name to bless the fiber object into.
 * @return SV* The blessed fiber object, or &PL_sv_undef on failure.
 */
DLLEXPORT SV * spawn_fiber(SV * user_code, SV * class) {
    dTHX;
    if (!user_code || user_code == &PL_sv_undef || !class || class == &PL_sv_undef)
        return &PL_sv_undef;
    char * cls = SvPV_nolen(class);
    static HV * own_stash = NULL;
    if (!own_stash)
        own_stash = gv_stashpv("Acme::Parataxis", GV_ADD);
    HV * stash = strEQ(cls, "Acme::Parataxis") ? own_stash : gv_stashpv(cls, GV_ADD);
    AV * obj = newAV();
    av_extend(obj, 8); /* pre-size to fit every F_* slot in one allocation */
    SV * objrv = newRV_noinc((SV *)obj);
    sv_bless(objrv, stash);
    av_store(obj, 0, SvREFCNT_inc(user_code)); /* F_CODE */
    int fid = create_fiber(user_code, objrv);
    if (fid < 0) {
        SvREFCNT_dec(objrv);
        /* Carry the create_fiber error code out: -2 is the policy limit ("table full"), -3 is a failed stack mmap
         * (address-space / data-segment budget on platforms without MAP_NORESERVE). The caller distinguishes them. */
        return newSViv(fid);
    }
    av_store(obj, 4, newSViv(fid)); /* F_FID */
    int st = run_fiber_checked(fid, &PL_sv_undef);
    av_store(obj, 8, newSViv(st)); /* F_LAST_STATUS */
    return objrv;
}

/**
 * @brief Reclaims all completed background jobs in a single call.
 *
 * Returns an arrayref of [fiber_id, result] pairs for every finished job, freeing the job slots as it goes.
 *
 * @return SV* Arrayref of completed jobs (may be empty).
 */
DLLEXPORT void drain_jobs(SV * out_ref) {
    dTHX;
    if (!out_ref || !SvROK(out_ref) || SvTYPE(SvRV(out_ref)) != SVt_PVAV)
        return;
    AV * out = (AV *)SvRV(out_ref);
    av_clear(out);
    while (1) {
        int job_idx = check_for_completion();
        if (job_idx == -1)
            break;
        AV * pair = newAV();
        av_push(pair, newSViv(get_job_coro_id(job_idx)));
        SV * res = get_job_result(job_idx);
        /* get_job_result returns a mortal parked on the caller's tmps stack; copy it so the pair owns its own SV
         * instead of double-decrementing the mortal when both the pair and FREETMPS release it. */
        av_push(pair, (res && res != &PL_sv_undef) ? newSVsv(res) : &PL_sv_undef);
        av_push(out, newRV_noinc((SV *)pair));
        free_job_slot(job_idx);
    }
}

/**
 * @brief Transfers control directly to another fiber (symmetric).
 *
 * Suspends the current fiber and switches directly to the target. No parent/child relationship is established.
 *
 * @param target_id Fiber ID to transfer to.
 * @param args Arguments to pass to the target.
 * @return SV* Data eventually transferred back to this fiber.
 */
DLLEXPORT SV * coro_transfer(int target_id, SV * args) {
    dTHX;
    if (target_id < -1 || (target_id >= 0 && (target_id >= fiber_capacity || !fibers[target_id])))
        return &PL_sv_undef;
    if (target_id >= 0 && fibers[target_id]->finished)
        return &PL_sv_undef;
    /* Same guard as coro_call(): a fiber torn down by the deadlock purger has no live frame to
     * transfer to, and the wait that armed this wake (a completed job, a satisfied channel) was
     * registered before its run died. The wake is a no-op; the record stays occupied. */
    if (target_id >= 0 && fibers[target_id]->started
        && fibers[target_id]->si && fibers[target_id]->si->si_cxix < 0)
        return &PL_sv_undef;
    para_fiber_t * target = (target_id == -1) ? &main_context : fibers[target_id];
    if (target->transfer_data != args) {
        if (target->transfer_data && target->transfer_data != &PL_sv_undef)
            SvREFCNT_dec(target->transfer_data);
        target->transfer_data = args;
        if (args && args != &PL_sv_undef)
            SvREFCNT_inc(args);
    }
    perform_switch(target_id, 1);
    if (target_id >= 0 && fibers[target_id] && fibers[target_id]->finished) {
        if (fibers[target_id]->transfer_data && fibers[target_id]->transfer_data != &PL_sv_undef) {
            SvREFCNT_dec(fibers[target_id]->transfer_data);
            fibers[target_id]->transfer_data = &PL_sv_undef;
        }
        destroy_coro(target_id);
    }
    para_fiber_t * me = (current_fiber_id == -1) ? &main_context : fibers[current_fiber_id];
    SV * res = me->transfer_data;
    me->transfer_data = &PL_sv_undef;
    if (res && res != &PL_sv_undef)
        sv_2mortal(res);
    return res;
}

/** @brief Returns 1 if the fiber has finished execution. */
DLLEXPORT int is_finished(int fiber_id) {
    if (fiber_id < 0 || fiber_id >= fiber_capacity)
        return 0;
    return (fibers[fiber_id] && fibers[fiber_id]->finished) ? 1 : 0;
}

/**
 * @brief Returns the Perl object bound to a live fiber, if any.
 *
 * Replaces the Perl-level %REGISTRY lookup: the C context already owns a strong reference to the object via self_ref,
 * so no separate registry or weak-reference bookkeeping is needed on the Perl side.
 *
 * @param fiber_id The fiber ID to look up.
 * @return SV* The blessed fiber object (mortalized), or &PL_sv_undef.
 */
DLLEXPORT SV * get_fiber_by_id(int fiber_id) {
    dTHX;
    if (fiber_id < 0 || fiber_id >= fiber_capacity || !fibers[fiber_id])
        return &PL_sv_undef;
    SV * self_ref = fibers[fiber_id]->self_ref;
    if (!self_ref || self_ref == &PL_sv_undef)
        return &PL_sv_undef;
    SvREFCNT_inc(self_ref);
    return sv_2mortal(self_ref);
}

/** @brief Returns the number of currently live (non-destroyed) fibers. */
DLLEXPORT int get_live_fiber_count(void) {
    int count = 0;
    for (int i = 0; i < fiber_capacity; i++)
        if (fibers[i] && fibers[i]->started)
            count++;
    return count;
}

/** @brief Returns the number of allocated slots in the fiber table, i.e. the exclusive upper bound on a fiber id.
 *
 * The table starts at DEFAULT_FIBER_TABLE and doubles when it fills, so this is the value a caller must scan to
 * enumerate every id. Anything that walks ids (the Perl-side _live_fiber_ids, and so dump_fibers, the deadlock
 * report, and run()'s pre-run snapshot) has to read it rather than assume the old compile-time 1024. */
DLLEXPORT int get_fiber_capacity(void) {
    return fiber_capacity;
}

/** @brief Internal helper to reset subroutine depth for cleanup. */
static void recursive_depth_reset(pTHX_ CV * cv) {
    if (!cv || SvTYPE((SV *)cv) != SVt_PVCV)
        return;
    if (CvDEPTH(cv) > 0)
        CvDEPTH(cv) = 0;
}

/**
 * @brief Clears active pads in the fiber stack.
 *
 * Internal helper used during fiber destruction to ensure all active lexical scopes are unwound and their variables
 * freed.
 *
 * @param si The Stack Info structure of the fiber.
 */
static void _clear_pads_in_stack(pTHX_ PERL_SI * si) {
    if (!si || !si->si_cxstack)
        return;
    for (I32 i = si->si_cxix; i >= 0; i--) {
        PERL_CONTEXT * cx = &(si->si_cxstack[i]);
        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
            CV * cv = cx->blk_sub.cv;
            if (cv && SvTYPE((SV *)cv) == SVt_PVCV) {
                PADLIST * padlist = CvPADLIST(cv);
                if (padlist) {
                    I32 depth = cx->blk_sub.olddepth + 1;
                    if (depth > 0 && depth <= PadlistMAX(padlist)) {
                        AV * pad = (AV *)PadlistARRAY(padlist)[depth];
                        if (pad && SvTYPE((SV *)pad) == SVt_PVAV)
                            av_clear(pad);
                    }
                }
                if (CvDEPTH(cv) > 0)
                    CvDEPTH(cv)--;
            }
        }
    }
}

/**
 * @brief Releases the pad bookkeeping for a CV that is about to be replaced or finalised.
 *
 * Pass 1b fabricates CvDEPTH values (see the parked-frame depth registry above): a CV some fiber is
 * parked inside gets CvDEPTH = its deepest parked depth, so the next ++CvDEPTH() lands above every
 * parked pad. That is the right value while the parked frame exists, but nothing withdraws it once
 * the frame is gone -- cx_popsub_common() restores depths only for frames that actually leave, and a
 * swap resuming a fiber that holds no frame of the CV skips it entirely. The count then survives for
 * good and the CV looks permanently active to the rest of perl: cv_undef() refuses to finalise a CV
 * whose CvDEPTH is positive, so replacing it dies with "Can't undef active subroutine" and reports
 * the *replaced* sub's own definition site as the location.
 *
 * Acme::Parataxis::Compat::disable_transparent_unblocking() retires the CORE::GLOBAL overrides it
 * installed, which is precisely that finalisation, so it calls this on each override before handing
 * the glob back.
 *
 * Safety comes from asking the stacks, not the registry. The registry is a cache drained on every
 * resume, and a frame that leaves without a swap in between -- a cancelled or timed-out fiber body
 * longjmp'ing out, a die unwinding a cxstack -- never drains its claim, so the cache will happily
 * report a depth that nothing occupies and veto the release. A stale veto is a permanent croak, and
 * a *stale* claim left in place is worse still: Pass 1b pins CvDEPTH back to max_depth for every
 * still-active entry, so the next swap would undo the release. Both are handled by purging the
 * entry once no live frame is found.
 *
 * Scoped to the named CV on purpose, too. CvDEPTH is a pad high-water mark rather than a frame
 * count, so lowering it also decides which pad the next call reuses -- safe for a CV the caller is
 * contractually about to free, not in general. Sweeping every CV the registry has ever seen instead
 * trips core's cx_popsub_args() assert (AvARRAY(Padlist[CvDEPTH]) == PL_curpad) on unrelated subs;
 * measured under a -DDEBUGGING perl, where that assert is live.
 *
 * @param sv A code reference whose CV is to be released. Anything else is ignored.
 */
/* Note the signature: no pTHX_. This is an Affix entry point, and every other function in the affix
 * table that takes an SV follows the same shape; DLLEXPORT, plain C parameters, dTHX inside the body
 * (see force_depth_zero, drain_jobs, coro_yield). Written with pTHX_ it still compiled and worked on
 * the Linux build, because there aTHX_ expands to a full "PerlInterpreter *my_perl," declaration that
 * reads as a leading parameter; Affix is reading that signature to decide what to pass, and under
 * Win32's expansion it then handed over something that is not the SV at all. */
DLLEXPORT void para_release_cv_depth(SV * sv) {
    dTHX;
    if (!sv)
        return;
    /* Accept a reference to a CV or a bare CV, because either can reach here and neither should be
     * assumed. force_depth_zero() resolves its argument the same two ways. */
    SV * const rv = SvROK(sv) ? SvRV(sv) : sv;
    if (SvTYPE(rv) != SVt_PVCV)
        return;
    CV * const cv = (CV *)rv;
    if (CvDEPTH(cv) <= 0)
        return;
    /* A frame really inside the CV still owns that depth, and the CV is about to be finalised out
     * from under it. Refusing here is right: perl's own cv_undef() would croak on exactly this, and
     * forcing the count down would leave a live frame pointing at freed memory. */
    if (para_cv_frame_live(aTHX_ cv))
        return;
    /* The purge below may hand back the pin's own reference (SvREFCNT_dec), and this entry point can be
     * reached with no other reference in hand, so hold one across the reset. Same pattern the old
     * sub-return hook used across its delegated pop. */
    SvREFCNT_inc(cv);
    para_cvreg_purge(cv);
    CvDEPTH(cv) = 0;
    /* Back to perl's ordinary state -- and the pad a call at depth 0+1 lands on has to be canonical
     * again, the same treatment Pass 1b gives a landing pad. Without it the next call enters depth 1
     * onto a slot still holding an earlier frame's @_. */
    _clean_landing_pad(aTHX_ cv, 1);
    SvREFCNT_dec(cv);
}

static void _purge_fresh_pads(pTHX_ PERL_SI * si) {
    if (!si || !si->si_cxstack)
        return;
    for (I32 i = si->si_cxix; i >= 0; i--) {
        PERL_CONTEXT * cx = &(si->si_cxstack[i]);
        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
            CV * cv = cx->blk_sub.cv;
            if (cv && SvTYPE((SV *)cv) == SVt_PVCV) {
                PADLIST * padlist = CvPADLIST(cv);
                if (padlist) {
                    I32 depth = cx->blk_sub.olddepth + 1;
                    if (depth > 0 && depth <= PadlistMAX(padlist)) {
                        /* Hand the abandoned frame's pad back the way a real frame pop would: perl does not reuse a
                         * popped frame's layer, it releases it so the next call allocates fresh lexicals. The dead
                         * fiber's parked frames are never popped, so their pad slots stay resident: the next fiber
                         * re-invoking this CV reuses the layer as-is and can SEE the dead fiber's lexicals (a bare
                         * `yield` is then observed to yield the parked fiber's ["WAITING"] marker, because `my @x`
                         * reuses the slot without clearing it).
                         *
                         * We therefore clear only the CONTENTS of each array-valued pad slot in the resident layer.
                         * The layer AV itself is left untouched, because freeing it -- or even NULLing one gutter
                         * entry in a layer perl may have aliased into @_ -- leaves the defgv pointing at freed
                         * memory and the next @_ clear (pp_entersub's Perl_clear_defarray) segfaults. Clearing the
                         * child array alone (as if the dead frame had done `my @x = ()`) releases the stale lexicals
                         * while keeping every pointer perl still holds valid, so the next call re-enters these CVs
                         * with clean wait state. */
                        AV * layer = (AV *)PadlistARRAY(padlist)[depth];
                        if (layer && SvTYPE((SV *)layer) == SVt_PVAV) {
                            SSize_t fill = AvFILLp(layer);
                            if (fill >= 0) {
                                SV ** a = PadARRAY(layer);
                                for (SSize_t j = 0; j <= fill; j++) {
                                    SV * old = a[j];
                                    if (old && old != &PL_sv_undef
                                        && SvTYPE(old) == SVt_PVAV
                                        && SvPADMY(old)
                                        && SvREFCNT(old) == 1)
                                        av_clear((AV *)old);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/** @brief Tear a fiber that a dying run abandons out of the parked-depth registry.
 *
 * A run ends with remaining fibers parked in two cases: the deadlock detector fires (the "FATAL:
 * deadlock detected" report) or an unobserved fiber death aborts the scheduler loop. By design those
 * parked fibers are never destroyed (their C records keep the fids occupied so a later run cannot
 * be misread as deadlocked) but their parked frames have to leave the depth registry at the moment
 * the torn-down stack is detected, exactly as destroy_coro()'s purge leaves them on destruction.
 * Left behind, a parked claim keeps CvDEPTH fabricated above depths no live frame occupies and Pass
 * 1c refuses to settle it while the frame still counts as live, so every later park of the same CV
 * enters one level high (the "poisoned depth" residual: the shared CV stays inflated for good).
 *
 * This performs the destroy_coro() registry walk -- remove every claim on the fiber's frames -- and
 * then marks the context stack torn down (si_cxix = -1) so the frames stop counting as live. With
 * the claims gone and nothing live, the next swap's Pass 1c unwinds any pinned level back to perl's
 * ordinary 0. The fiber record itself, its pads, and its fid stay exactly where the leak design
 * expects them; nothing about this function frees or destroys the fiber, and a wake that races in
 * afterwards is made a no-op by the guards in run_fiber_checked()/coro_call()/coro_transfer().
 *
 * @param fiber_id Fiber whose parked claims are to be purged.
 */
DLLEXPORT void para_cvreg_purge_fiber(int fiber_id) {
    dTHX;
    if (fiber_id < 0 || fiber_id >= fiber_capacity)
        return;
    para_fiber_t * c = fibers[fiber_id];
    if (!c || !c->si || !c->si->si_cxstack || c->si->si_cxix < 0)
        return;

    /* Drop every claim the parked fiber registered, the same walk destroy_coro() performs, and
     * collect the unique CVs it occupied so the ones left entirely unclaimed can be settled below. */
    CV ** cvs  = NULL;
    I32  n_cvs = 0, cap_cvs = 0;
    for (I32 i = c->si->si_cxix; i >= 0; i--) {
        PERL_CONTEXT * cx = &(c->si->si_cxstack[i]);
        if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
            CV * cv = cx->blk_sub.cv;
            if (cv && SvTYPE((SV *)cv) == SVt_PVCV) {
                para_cvreg_remove(cv, cx->blk_sub.olddepth + 1);
                int dup = 0;
                for (I32 j = 0; j < n_cvs; j++)
                    if (cvs[j] == cv) { dup = 1; break; }
                if (!dup) {
                    if (n_cvs == cap_cvs) {
                        cap_cvs = cap_cvs ? cap_cvs * 2 : 8;
                        Renew(cvs, cap_cvs, CV *);
                    }
                    cvs[n_cvs++] = cv;
                }
            }
        }
    }

    /* Tear the frames down for the depth registry's live-frame check: a parked fiber of a run that is
     * ending will never resume, so its frames must stop counting as live, or Pass 1c would keep seeing
     * this exact frame and could never settle the fabricated depth. si_cxix = -1 is also the state a
     * finished fiber leaves behind, so every later destroy path treats the record the same way. */
    _purge_fresh_pads(aTHX_ c->si);
    c->si->si_cxix = -1;

    /* Settle right now every CV this purge left with no claims and no live frame anywhere. The exact
     * state Pass 1c releases a pin in, run here so the level is unwound even if the process ends before
     * any further swap. A CV another fiber still claims (max_depth > 0) or frames (para_cv_frame_live)
     * is left to that fiber's own swaps. */
    for (I32 j = 0; j < n_cvs; j++) {
        para_cvreg_entry_t * e = para_cvreg_lookup(cvs[j], 0);
        if (e && e->pinned && e->max_depth == 0 && !e->on_stack && !para_cv_frame_live(aTHX_ cvs[j])) {
            PARA_DIAGF("[diag] PURGE-SETTLE fid=%d cv=%p dep=%d -> 0\n", fiber_id, (void*)cvs[j], CvDEPTH(cvs[j]));
            CvDEPTH(cvs[j]) = 0;
            _clean_landing_pad(aTHX_ cvs[j], 1);
            para_cvreg_unpin(e);
        }
    }
    if (cvs)
        Safefree(cvs);
}

/**
 * @brief Destroys a fiber and releases all associated memory.
 *
 * This includes freeing OS-level stacks and context, but also carefully decrementing refcounts of Perl SVs stored
 * within the fiber.
 *
 * @param fiber_id Fiber ID to destroy.
 */
DLLEXPORT void destroy_coro(int fiber_id) {
    dTHX;
    if (fiber_id < 0 || fiber_id >= fiber_capacity)
        return;
    para_fiber_t * c = fibers[fiber_id];
    if (!c)
        return;

    /* A cloned interpreter (threads->create, and the spawn_blocking worker on top of it) duplicates the module's
     * Fiber handles, which carry the parent's opaque fiber ids, and the worker's perl_destruct then DESTROYs them.
     * The record itself, its stacks, and every SV it references were allocated in the parent interpreter's arena,
     * so the worker must not free [or decrement a reference on] any of it, or the CRT aborts on the cross-pool
     * free ("Free to wrong pool ... not ..."). The worker's copy is inert: the parent still owns the record and
     * frees it when the parent's own Fiber object is destroyed. Non-ithreads perls cannot run perl_clone at all, and
     * aTHX is not a real expression there, so the guard is compiled out and the single interpreter owns everything. */
#ifdef USE_ITHREADS
    if (c->owner && c->owner != (void *)aTHX)
        return;
#endif

    fibers[fiber_id] = NULL;
    if (job_refcount[fiber_id] > 0) {
        /* Keep the id out of the free list until every in-flight job it submitted has been reclaimed, so no newer
         * fiber can be woken by a stale completion targeting this id (released via free_job_slot). The slot stays
         * counted as used until then, so the limit also covers a fiber that is already gone but not yet recyclable. */
        fiber_destroyed[fiber_id] = 1;
    }
    else {
        _release_slot(fiber_id);
    }

    /* Drop this fiber's frames out of the parked-depth registry: a parked fiber registered them when it switched out,
     * and leaving them behind would pin CvDEPTH above depths no live frame occupies any more. (Pad clearing itself
     * stays skipped for parked fibers, see below: registry bookkeeping never touches pads.) */
    if (c->si && c->si->si_cxstack) {
        for (I32 i = c->si->si_cxix; i >= 0; i--) {
            PERL_CONTEXT * cx = &(c->si->si_cxstack[i]);
            if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
                CV * cv = cx->blk_sub.cv;
                if (cv && SvTYPE((SV *)cv) == SVt_PVCV)
                    para_cvreg_remove(cv, cx->blk_sub.olddepth + 1);
            }
        }
    }

    /* Unwind pads. This is only ever safe when the fiber's perl context stack has already been unwound to exhaustion
     * (a fiber that was reaped after finishing: si_cxix == -1, so the walk below is a no-op). A fiber destroyed while
     * still parked keeps live activation slots in the shared PadLists and the global CvDEPTH counters of every
     * subroutine it is currently inside (yield, the wait helpers, run, ...); _clear_pads_in_stack frees those slots
     * and adjusts CvDEPTH for the *running* fiber's bookkeeping, corrupting any other fiber that activates the same
     * sub at the same depth. The parked fiber's own closures release their pads when user_cv is decref'd below,
     * and its shared-sub slots are simply overwritten by normal later use, so skipping the unwalk is safe. */
    if (c->si && c->si->si_cxix < 0)
        _clear_pads_in_stack(aTHX_ c->si);

    /* Release Perl references */
    if (c->user_cv && c->user_cv != &PL_sv_undef) {
        SvREFCNT_dec(c->user_cv);
        c->user_cv = NULL;
    }
    if (c->self_ref && c->self_ref != &PL_sv_undef) {
        SvREFCNT_dec(c->self_ref);
        c->self_ref = NULL;
    }
    if (c->transfer_data && c->transfer_data != &PL_sv_undef) {
        SvREFCNT_dec(c->transfer_data);
        c->transfer_data = NULL;
    }

    /* Early exit if Perl is already shutting down */
    if (PL_dirty) {
#ifndef _WIN32
        if (c->stack_p)
            free_fiber_stack(c->stack_p, c->stack_sz);
#endif
        free_perl_stacks(aTHX_ c);
        free(c);
        return;
    }

#ifdef _WIN32
    if (c->context)
        DeleteFiber(c->context);
#else
    /* Park the whole context (Perl stacks + OS stack) for reuse */
    if (fiber_cache_count < MAX_FIBER_CACHE) {
        reset_perl_stacks(aTHX_ c);
        fiber_cache[fiber_cache_count++] = c;
        return;
    }
    if (c->stack_p) {
        free_fiber_stack(c->stack_p, c->stack_sz);
        c->stack_p = NULL;
    }
#endif

    free_perl_stacks(aTHX_ c);
    free(c);
}

/**
 * @brief Global cleanup function for the fiber and thread pool system.
 *
 * Signals all worker threads to terminate and destroys all remaining fibers. Should be called during global destruction
 * or system shutdown.
 */
DLLEXPORT void cleanup() {
    dTHX;
    /* Restore the original exit op so any exit() during global destruction (after this DLL could be unmapped) behaves
     * like a plain perl exit. */
    if (parataxis_saved_pp_exit && PL_ppaddr[OP_EXIT] == parataxis_pp_exit)
        PL_ppaddr[OP_EXIT] = parataxis_saved_pp_exit;
    if (threads_initialized) {
        LOCK(queue_lock);
        threads_keep_running = 0;
        PARA_COND_BROADCAST(queue_cond);
        UNLOCK(queue_lock);

#ifndef _WIN32
        /* Wake any workers blocked in select() so they observe threads_keep_running = 0 */
        if (shutdown_pipe[1] >= 0) {
            char byte = 1;
            ssize_t ignored = write(shutdown_pipe[1], &byte, 1);
            (void)ignored;
        }
#endif

        for (int i = 0; i < current_thread_count; i++) {
#ifdef _WIN32
            /* Wait for threads to finish and close handles */
            if (thread_handles[i]) {
                WaitForSingleObject(thread_handles[i], INFINITE);
                CloseHandle(thread_handles[i]);
                thread_handles[i] = NULL;
            }
#else
            if (thread_handles[i]) {
                pthread_join(thread_handles[i], NULL);
                thread_handles[i] = 0;
            }
#endif
        }
        current_thread_count = 0;
    }

    if (current_fiber_id != -1) {
        swap_perl_state(fibers[current_fiber_id], &main_context);
        current_fiber_id = -1;
    }
    for (int i = 0; i < fiber_capacity; i++)
        if (fibers[i])
            destroy_coro(i);
#ifndef _WIN32
#ifdef __linux__
    while (stack_cache_count > 0)
        munmap((char *)stack_cache[--stack_cache_count] - fiber_guard_sz, FIBER_STACK_SZ + fiber_guard_sz);
#else
    while (stack_cache_count > 0)
        munmap((char *)stack_cache[--stack_cache_count] - fiber_guard_sz, FIBER_STACK_SZ + fiber_guard_sz);
#endif
    if (shutdown_pipe[1] >= 0) {
        close(shutdown_pipe[0]);
        close(shutdown_pipe[1]);
        shutdown_pipe[0] = shutdown_pipe[1] = -1;
    }
#endif
    if (main_context.transfer_data && main_context.transfer_data != &PL_sv_undef) {
        SvREFCNT_dec(main_context.transfer_data);
        main_context.transfer_data = &PL_sv_undef;
    }
}
