/**
 * Copyright (c) 2025 Sanko Robinson
 *
 * This source code is dual-licensed under the Artistic License 2.0 or the MIT License.
 * You may choose to use this code under the terms of either license.
 *
 * SPDX-License-Identifier: (Artistic-2.0 OR MIT)
 *
 * The documentation blocks within this file are licensed under the
 * Creative Commons Attribution 4.0 International License (CC BY 4.0).
 *
 * SPDX-License-Identifier: CC-BY-4.0
 */
/**
 * @file double_tap.h
 * @brief A lightweight, single-header TAP (Test Anything Protocol) library.
 * @ingroup internal_test_harness
 *
 * @details This file provides a simple, self-contained testing harness that produces
 * TAP-compliant output, which is ideal for integration with CI/CD systems and other
 * testing tools. It is used for all unit and regression tests within the `infix` project.
 *
 * The library is designed to be trivial to use:
 * 1.  Define `DBLTAP_ENABLE` and `DBLTAP_IMPLEMENTATION` in a single test file.
 * 2.  Write all test logic within a function named `test_body(void)` using the `TEST` macro.
 * 3.  Use the provided macros (`plan`, `ok`, `subtest`, etc.) to structure tests.
 *
 * The library provides its own `main` function that initializes the harness, calls
 * the user-defined `test_body`, and reports the final results.
 *
 * @section thread_safety Thread Safety
 *
 * The design uses thread-local storage (`_Thread_local`, `__thread`) to manage the
 * test state (test counts, subtest nesting, etc.). This allows multiple threads to
 * run tests concurrently without interfering with each other's output or results,
 * making it suitable for testing thread-safe code. Global counters use atomic
 * operations where available to ensure correctness.
 *
 * @internal
 */
#pragma once
#ifdef DBLTAP_ENABLE
#define TAP_VERSION 13
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined(__unix__) || defined(__APPLE__) || defined(__OpenBSD__)
#include <unistd.h>
#endif
#if defined(_WIN32) || defined(__CYGWIN__)
#include <windows.h>
#elif (defined(__unix__) || defined(__APPLE__)) && !defined(__OpenBSD__)
// Do not include pthread.h on OpenBSD to prevent linking/cleanup issues if -pthread is not used.
#include <pthread.h>
#endif

// Portability Macros for Atomics and Thread-Local Storage
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L && !defined(__STDC_NO_ATOMICS__)
#include <stdatomic.h>
#define TAP_ATOMIC_SIZE_T _Atomic size_t
#define TAP_ATOMIC_FETCH_ADD(ptr, val) atomic_fetch_add(ptr, val)
#elif defined(__GNUC__) || defined(__clang__)
#define TAP_ATOMIC_SIZE_T size_t
#define TAP_ATOMIC_FETCH_ADD(ptr, val) __sync_fetch_and_add(ptr, val)
#else
// Fallback for older compilers without atomics support. This is not thread-safe.
#define TAP_ATOMIC_SIZE_T size_t
#define TAP_ATOMIC_FETCH_ADD(ptr, val) ((*ptr) += (val))
#warning "Compiler does not support C11 atomics or GCC builtins; global counters will not be thread-safe."
#endif

#if defined(__OpenBSD__)
// OpenBSD has known issues with TLS cleanup in some linking scenarios.
// Disable TLS to prevent segfaults at exit.
#define TAP_THREAD_LOCAL
#elif defined(_MSC_VER)
// Microsoft Visual C++
#define TAP_THREAD_LOCAL __declspec(thread)
#elif defined(_WIN32) && defined(__clang__)
// Clang on Windows
#define TAP_THREAD_LOCAL __declspec(thread)
#elif defined(__GNUC__)
// GCC (including MinGW) and Clang on *nix
#define TAP_THREAD_LOCAL __thread
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L && !defined(__STDC_NO_THREADS__)
#define TAP_THREAD_LOCAL _Thread_local
#else
#define TAP_THREAD_LOCAL
#warning "Compiler does not support thread-local storage; tests will not be thread-safe."
#endif

// Compiler-specific attribute for printf-style format checking.
#if defined(__GNUC__) || defined(__clang__)
#define DBLTAP_PRINTF_FORMAT(fmt_index, arg_index) __attribute__((format(printf, fmt_index, arg_index)))
#else
#define DBLTAP_PRINTF_FORMAT(fmt_index, arg_index)
#endif

// Public Test Harness Functions (wrapped by macros for convenience)
void tap_init(void);
void tap_plan(size_t count);
int tap_done(void);
void tap_bail_out(const char * reason, ...) DBLTAP_PRINTF_FORMAT(1, 2);
bool tap_ok(bool condition, const char * file, int line, const char * func, const char * expr, const char * name, ...)
    DBLTAP_PRINTF_FORMAT(6, 7);
bool tap_subtest_start(const char * name);
bool tap_subtest_end(void);
void tap_todo_start(const char * reason, ...) DBLTAP_PRINTF_FORMAT(1, 2);
void tap_todo_end(void);
void tap_skip(size_t count, const char * reason, ...) DBLTAP_PRINTF_FORMAT(2, 3);
void tap_skip_all(const char * reason, ...) DBLTAP_PRINTF_FORMAT(1, 2);
void diag(const char * fmt, ...) DBLTAP_PRINTF_FORMAT(1, 2);
void tap_note(const char * fmt, ...) DBLTAP_PRINTF_FORMAT(1, 2);

// Public Test Harness Macros
/** @brief Declares the total number of tests to be run in the current scope. Must be called before any tests. */
#define plan(count) tap_plan(count)
/** @brief Concludes testing, validates the plan, and returns an exit code based on success or failure. */
#define done() tap_done()
/** @brief Immediately terminates the entire test suite with a failure message. Useful for fatal setup errors. */
#define bail_out(...) tap_bail_out(__VA_ARGS__)
/** @brief The core assertion macro. Checks a condition and prints an "ok" or "not ok" TAP line with diagnostics on
 * failure. */
#define ok(cond, ...) tap_ok(!!(cond), __FILE__, __LINE__, __func__, #cond, __VA_ARGS__)
/** @brief A convenience macro that always passes. Equivalent to `ok(true, ...)`. */
#define pass(...) ok(true, __VA_ARGS__)
/** @brief A convenience macro that always fails. Equivalent to `ok(false, ...)`. */
#define fail(...) ok(false, __VA_ARGS__)
/** @brief Defines a block of tests as a nested subtest, which gets its own plan and pass/fail status. */
#define subtest(name) \
    for (bool _tap_subtest_once = tap_subtest_start(name); _tap_subtest_once; _tap_subtest_once = tap_subtest_end())
/** @brief Marks a specified number of subsequent tests as skipped with a given reason. */
#define skip(count, ...) tap_skip(count, __VA_ARGS__)
/** @brief Marks all subsequent tests in the current scope as skipped. */
#define skip_all(...) tap_skip_all(__VA_ARGS__)
/** @brief Defines a block of tests that are expected to fail. A failure in a TODO block does not fail the overall
 * suite. */
#define TODO(reason) \
    for (int _tap_todo_once = (tap_todo_start(reason), 1); _tap_todo_once; _tap_todo_once = (tap_todo_end(), 0))
/** @brief Prints a diagnostic message to stderr, prefixed with '#'. Standard TAP practice for auxiliary information. */
#define diag(...) diag(__VA_ARGS__)
/** @brief Prints a diagnostic message (a note) to stdout, prefixed with '#'. */
#ifndef note
#define note(...) tap_note(__VA_ARGS__)
#endif
/** @brief Defines the main test function body where all tests are written. */
#define TEST void test_body(void)
void test_body(void);

#else  // If DBLTAP_ENABLE is not defined, provide stub macros to allow code to compile without the harness.
#define plan(count) ((void)0)
#define done() (0)
#define bail_out(...)                  \
    do {                               \
        fprintf(stderr, "Bail out! "); \
        fprintf(stderr, __VA_ARGS__);  \
        fprintf(stderr, "\n");         \
        exit(1);                       \
    } while (0)
#define ok(cond, ...) (true)
#define pass(...) ((void)0)
#define fail(...) ((void)0)
#define subtest(name) if (0)
#define skip(count, ...) ((void)0)
#define skip_all(...) ((void)0)
#define TODO(reason, ...) if (0)
#define diag(...) ((void)0)
#ifndef note
#define note(...) ((void)0)
#endif
#define TEST \
    int main(void) { return 0; }
#endif  // DBLTAP_ENABLE

#if defined(DBLTAP_ENABLE) && defined(DBLTAP_IMPLEMENTATION)
// Internal Test State Management
/**
 * @internal
 * @brief Holds the complete state for a single test scope (main test or a subtest).
 *
 * A stack of these structs is maintained in thread-local storage to allow for
 * nested subtests and concurrent test execution across threads.
 */
typedef struct {
    size_t plan;            /**< The number of planned tests for this scope. */
    size_t count;           /**< The number of tests executed so far. */
    size_t failed;          /**< The number of failed tests in this scope. */
    size_t failed_todo;     /**< The number of failed tests within a TODO block. */
    int indent_level;       /**< The nesting level for indented TAP output. */
    bool has_plan;          /**< `true` if a plan has been declared for this scope. */
    bool skipping;          /**< `true` if `skip_all` is active for this scope. */
    bool todo;              /**< `true` if inside a `TODO` block. */
    char subtest_name[256]; /**< The name of the current subtest. */
    char todo_reason[256];  /**< The reason for the current `TODO` block. */
    char skip_reason[256];  /**< The reason for the current `skip_all`. */
} tap_state_t;

#define MAX_DEPTH 16         /**< Maximum nesting depth for subtests. */
#define NO_PLAN ((size_t)-1) /**< Sentinel value for an undeclared plan. */

/** @internal The thread-local stack of test states. */
static TAP_THREAD_LOCAL tap_state_t state_stack[MAX_DEPTH];
/** @internal A pointer to the current test state on the thread-local stack. */
static TAP_THREAD_LOCAL tap_state_t * current_state = NULL;
/** @internal A global, thread-safe counter for the total number of failed tests across all threads. */
static TAP_ATOMIC_SIZE_T g_total_failed = 0;

// One-Time Initialization for TAP Header
#if defined(_WIN32) || defined(__CYGWIN__)
static INIT_ONCE g_tap_init_once = INIT_ONCE_STATIC_INIT;
static BOOL CALLBACK _tap_init_routine(PINIT_ONCE initOnce, PVOID param, PVOID * context) {
    (void)initOnce;
    (void)param;
    (void)context;
    printf("TAP version %d\n", TAP_VERSION);
    fflush(stdout);
    return TRUE;
}
#elif (defined(__unix__) || defined(__APPLE__)) && !defined(__OpenBSD__)
static pthread_once_t g_tap_init_once = PTHREAD_ONCE_INIT;
static void _tap_init_routine(void) {
    printf("TAP version %d\n", TAP_VERSION);
    fflush(stdout);
}
#else  // OpenBSD or other platforms without robust pthread_once support in this context
static bool g_tap_initialized = false;
#endif

/**
 * @internal
 * @brief Ensures the TAP header has been printed and thread-local state is initialized.
 * Uses `pthread_once` or `InitOnceExecuteOnce` to guarantee the TAP version header
 * is printed exactly once per process, even with multiple threads. It also initializes
 * the thread-local state for the current thread if it's the first test call on that thread.
 */
static void _tap_ensure_initialized(void) {
#if defined(_WIN32) || defined(__CYGWIN__)
    InitOnceExecuteOnce(&g_tap_init_once, _tap_init_routine, NULL, NULL);
#elif (defined(__unix__) || defined(__APPLE__)) && !defined(__OpenBSD__)
    pthread_once(&g_tap_init_once, _tap_init_routine);
#else
    // Fallback for OpenBSD/single-threaded builds
    if (!g_tap_initialized) {
        printf("TAP version %d\n", TAP_VERSION);
        fflush(stdout);
        g_tap_initialized = true;
    }
#endif
    if (!current_state) {
        current_state = &state_stack[0];
        memset(current_state, 0, sizeof(tap_state_t));
        current_state->plan = NO_PLAN;
    }
}

// Internal Helper Functions
/** @internal Prints the indentation corresponding to the current subtest depth. */
static void print_indent(FILE * stream) {
    _tap_ensure_initialized();
    for (int i = 0; i < current_state->indent_level; ++i)
        fprintf(stream, "    ");
}

/** @internal Pushes a new state onto the thread-local stack for entering a subtest. */
static void push_state(void) {
    if (current_state >= &state_stack[MAX_DEPTH - 1])
        tap_bail_out("Exceeded maximum subtest depth of %d", MAX_DEPTH);
    tap_state_t * parent = current_state;
    current_state++;
    memset(current_state, 0, sizeof(tap_state_t));
    current_state->plan = NO_PLAN;
    current_state->indent_level = parent->indent_level + 1;
    // A subtest inherits the 'todo' state from its parent.
    if (parent->todo) {
        current_state->todo = true;
        snprintf(current_state->todo_reason, sizeof(current_state->todo_reason), "%s", parent->todo_reason);
    }
}

/** @internal Pops the current state from the stack when a subtest ends. */
static void pop_state(void) {
    if (current_state <= &state_stack[0])
        tap_bail_out("Internal error: Attempted to pop base test state");
    current_state--;
}

// Public API Implementation
void tap_init(void) { _tap_ensure_initialized(); }

void tap_plan(size_t count) {
    _tap_ensure_initialized();
    if (current_state->has_plan || current_state->count > 0)
        tap_bail_out("Plan declared after tests have run or a plan was already set");
    current_state->plan = count;
    current_state->has_plan = true;
    print_indent(stdout);
    printf("1..%llu\n", (unsigned long long)count);
    fflush(stdout);
}

bool tap_ok(bool condition, const char * file, int line, const char * func, const char * expr, const char * name, ...) {
    _tap_ensure_initialized();
    if (current_state->skipping) {
        current_state->count++;
        return true;
    }
    char name_buffer[256] = {0};
    if (name && name[0] != '\0') {
        va_list args;
        va_start(args, name);
        vsnprintf(name_buffer, sizeof(name_buffer), name, args);
        va_end(args);
    }
    current_state->count++;
    if (!condition) {
        if (current_state->todo)
            current_state->failed_todo++;
        else {
            current_state->failed++;
            if (current_state == &state_stack[0])  // Only increment global fail count for top-level tests
                TAP_ATOMIC_FETCH_ADD(&g_total_failed, 1);
        }
    }
    print_indent(stdout);
    printf("%s %llu", condition ? "ok" : "not ok", (unsigned long long)current_state->count);
    if (name_buffer[0] != '\0')
        printf(" - %s", name_buffer);
    if (current_state->todo)
        printf(" # TODO %s", current_state->todo_reason);
    printf("\n");
    if (!condition && !current_state->todo) {
        // Print detailed diagnostics in YAML block format on failure.
        print_indent(stdout);
        fprintf(stdout, "#\n");
        print_indent(stdout);
        fprintf(stdout, "#   message: 'Test failed'\n");
        print_indent(stdout);
        fprintf(stdout, "#   severity: fail\n");
        print_indent(stdout);
        fprintf(stdout, "#   data:\n");
        print_indent(stdout);
        fprintf(stdout, "#     file: %s\n", file);
        print_indent(stdout);
        fprintf(stdout, "#     line: %d\n", line);
        print_indent(stdout);
        fprintf(stdout, "#     function: %s\n", func);
        print_indent(stdout);
        fprintf(stdout, "#     expression: '%s'\n", expr);
        print_indent(stdout);
        fprintf(stdout, "#   ...\n");
    }
    fflush(stdout);
    return condition;
}

void tap_skip(size_t count, const char * reason, ...) {
    _tap_ensure_initialized();
    char buffer[256];
    va_list args;
    va_start(args, reason);
    vsnprintf(buffer, sizeof(buffer), reason, args);
    va_end(args);
    for (size_t i = 0; i < count; ++i) {
        current_state->count++;
        print_indent(stdout);
        printf("ok %llu # SKIP %s\n", (unsigned long long)current_state->count, buffer);
    }
    fflush(stdout);
}

void tap_skip_all(const char * reason, ...) {
    _tap_ensure_initialized();
    current_state->skipping = true;
    va_list args;
    va_start(args, reason);
    vsnprintf(current_state->skip_reason, sizeof(current_state->skip_reason), reason, args);
    va_end(args);
}

void tap_todo_start(const char * reason, ...) {
    _tap_ensure_initialized();
    current_state->todo = true;
    va_list args;
    va_start(args, reason);
    vsnprintf(current_state->todo_reason, sizeof(current_state->todo_reason), reason, args);
    va_end(args);
}

void tap_todo_end(void) {
    _tap_ensure_initialized();
    current_state->todo = false;
    current_state->todo_reason[0] = '\0';
}

void diag(const char * fmt, ...) {
    _tap_ensure_initialized();
    char buffer[1024];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
    print_indent(stderr);
    fprintf(stderr, "# %s\n", buffer);
    fflush(stderr);
}

void tap_note(const char * fmt, ...) {
    _tap_ensure_initialized();
    char buffer[1024];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
    print_indent(stdout);
    fprintf(stdout, "# %s\n", buffer);
    fflush(stdout);
}

void tap_bail_out(const char * reason, ...) {
    fprintf(stderr, "Bail out! ");
    va_list args;
    va_start(args, reason);
    vfprintf(stderr, reason, args);
    va_end(args);
    fprintf(stderr, "\n");
    fflush(stderr);
    exit(1);
}

bool tap_subtest_start(const char * name) {
    _tap_ensure_initialized();
    print_indent(stdout);
    fprintf(stdout, "# Subtest: %s\n", name);
    fflush(stdout);
    push_state();
    snprintf(current_state->subtest_name, sizeof(current_state->subtest_name), "%s", name);
    return true;  // Enters the `for` loop body.
}

bool tap_subtest_end(void) {
    _tap_ensure_initialized();
    if (!current_state->has_plan) {
        // If no plan was declared, implicitly plan for the number of tests that ran.
        current_state->plan = current_state->count;
        print_indent(stdout);
        printf("1..%llu\n", (unsigned long long)current_state->plan);
    }
    bool plan_ok = (current_state->plan == current_state->count);
    bool subtest_ok = (current_state->failed == 0) && plan_ok;
    char name_buffer[256];
    snprintf(name_buffer, sizeof(name_buffer), "%s", current_state->subtest_name);
    pop_state();  // Return to the parent's state.
    // Report the subtest's success or failure as a single test point in the parent scope.
    ok(subtest_ok, "%s", name_buffer);
    return false;  // Exits the `for` loop.
}

int tap_done(void) {
    _tap_ensure_initialized();
    if (current_state != &state_stack[0])
        tap_bail_out("tap_done() called inside a subtest");
    if (!current_state->has_plan) {
        current_state->plan = current_state->count;
        print_indent(stdout);
        printf("1..%llu\n", (unsigned long long)current_state->plan);
        fflush(stdout);
    }
    if (current_state->skipping) {
        print_indent(stdout);
        printf("1..%llu # SKIP %s\n", (unsigned long long)current_state->plan, current_state->skip_reason);
        fflush(stdout);
        return 0;
    }
    if (current_state->plan != current_state->count)
        fail("Test plan adherence (planned %llu, but ran %llu)",
             (unsigned long long)current_state->plan,
             (unsigned long long)current_state->count);
    size_t final_failed_count = (size_t)TAP_ATOMIC_FETCH_ADD(&g_total_failed, 0);
    if (final_failed_count > 0)
        diag("Looks like you failed %llu out of %llu tests.",
             (unsigned long long)final_failed_count,
             (unsigned long long)current_state->plan);
    return (int)final_failed_count;
}

// The main test runner that gets compiled into the test executable.
int main(void) {
    tap_init();
    test_body();
    int result = tap_done();
#if defined(__OpenBSD__) || (defined(_WIN32) && defined(__clang__))
    // OpenBSD with Clang profiling runtime has a known issue where atexit handlers
    // related to TLS or profiling can segfault. We bypass standard exit cleanup
    // to avoid this false positive failure.
    _exit(result);
#else
    return result;
#endif
}
#endif  // DBLTAP_ENABLE && DBLTAP_IMPLEMENTATION
/** @endinternal */
