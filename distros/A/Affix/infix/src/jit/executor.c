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
 * @file executor.c
 * @brief Implements platform-specific memory management for JIT code and execution.
 * @ingroup internal_jit
 *
 * @details This module serves as the critical OS abstraction layer for the JIT engine.
 * Its primary responsibilities are:
 *
 * 1.  **Executable Memory Management:** It allocates, protects, and frees executable
 *     memory in a way that is secure and compliant with modern OS security features
 *     like **W^X (Write XOR Execute)**. It implements different strategies (single-
 *     vs. dual-mapping) depending on the platform's capabilities and security model.
 *
 * 2.  **Security Hardening:** It provides mechanisms to make memory regions read-only,
 *     which is used to protect the `infix_reverse_t` context from runtime memory
 *     corruption. It also implements "guard pages" on freed memory to immediately
 *     catch use-after-free bugs.
 *
 * 3.  **Universal Dispatch:** It contains the `infix_internal_dispatch_callback_fn_impl`,
 *     the universal C entry point that is the final target of all reverse trampoline
 *     stubs. This function is the bridge between the low-level JIT code and the
 *     high-level user-provided C handlers.
 */
#include "common/infix_internals.h"
#include "common/utility.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
// Platform-Specific Includes
#if defined(INFIX_OS_WINDOWS)
#include <windows.h>
#else
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
#endif
#if defined(INFIX_OS_MACOS)
#include <dlfcn.h>
#include <libkern/OSCacheControl.h>
#include <pthread.h>
#endif
// Polyfills for mmap flags for maximum POSIX compatibility.
#if defined(INFIX_ENV_POSIX) && !defined(INFIX_OS_WINDOWS)
#if !defined(MAP_ANON) && defined(MAP_ANONYMOUS)
#define MAP_ANON MAP_ANONYMOUS
#endif
#endif
// macOS JIT Security Hardening Logic
#if defined(INFIX_OS_MACOS)
/**
 * @internal
 * @brief macOS-specific function pointers and types for checking JIT entitlements.
 *
 * @details To support hardened runtimes on Apple platforms (especially Apple Silicon),
 * `infix` must use special APIs like `MAP_JIT` and `pthread_jit_write_protect_np`.
 * However, these are only effective if the host application has been granted the
 * `com.apple.security.cs.allow-jit` entitlement.
 *
 * This logic performs a runtime check for these APIs and the entitlement, gracefully
 * falling back to the legacy (but less secure) `mprotect` method if they are not
 * available. This provides maximum security for production apps while maintaining
 * maximum convenience for developers who may not have codesigned their test executables.
 */
typedef const struct __CFString * CFStringRef;
typedef const void * CFTypeRef;
typedef struct __SecTask * SecTaskRef;
typedef struct __CFError * CFErrorRef;
#define kCFStringEncodingUTF8 0x08000100
// A struct to hold dynamically loaded function pointers from macOS frameworks.
static struct {
    void (*CFRelease)(CFTypeRef);
    bool (*CFBooleanGetValue)(CFTypeRef boolean);
    CFStringRef (*CFStringCreateWithCString)(CFTypeRef allocator, const char * cStr, uint32_t encoding);
    CFTypeRef kCFAllocatorDefault;
    SecTaskRef (*SecTaskCreateFromSelf)(CFTypeRef allocator);
    CFTypeRef (*SecTaskCopyValueForEntitlement)(SecTaskRef task, CFStringRef entitlement, CFErrorRef * error);
    void (*pthread_jit_write_protect_np)(int enabled);
    void (*sys_icache_invalidate)(void * start, size_t len);
} g_macos_apis;
/**
 * @internal
 * @brief One-time initialization to dynamically load macOS framework functions.
 * @details Uses `dlopen` and `dlsym` to find the necessary CoreFoundation and Security
 * framework functions at runtime. This avoids a hard link-time dependency,
 * making the library more portable and resilient if these frameworks change.
 */
static void initialize_macos_apis(void) {
    // We don't need to link against these frameworks, which makes building simpler.
    void * cf = dlopen("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation", RTLD_LAZY);
    void * sec = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_LAZY);

    // Hardened Runtime helpers found in libSystem/libpthread
    g_macos_apis.pthread_jit_write_protect_np = dlsym(RTLD_DEFAULT, "pthread_jit_write_protect_np");
    g_macos_apis.sys_icache_invalidate = dlsym(RTLD_DEFAULT, "sys_icache_invalidate");

    if (!cf || !sec) {
        INFIX_DEBUG_PRINTF("Warning: Could not dlopen macOS frameworks. JIT security features will be degraded.");
        if (cf)
            dlclose(cf);
        if (sec)
            dlclose(sec);
        return;
    }
    g_macos_apis.CFRelease = dlsym(cf, "CFRelease");
    g_macos_apis.CFBooleanGetValue = dlsym(cf, "CFBooleanGetValue");
    g_macos_apis.CFStringCreateWithCString = dlsym(cf, "CFStringCreateWithCString");
    void ** pAlloc = (void **)dlsym(cf, "kCFAllocatorDefault");
    if (pAlloc)
        g_macos_apis.kCFAllocatorDefault = *pAlloc;
    g_macos_apis.SecTaskCreateFromSelf = dlsym(sec, "SecTaskCreateFromSelf");
    g_macos_apis.SecTaskCopyValueForEntitlement = dlsym(sec, "SecTaskCopyValueForEntitlement");
    dlclose(cf);
    dlclose(sec);
}
/**
 * @internal
 * @brief Checks if the current process has the `com.apple.security.cs.allow-jit` entitlement.
 * @return `true` if the entitlement is present and set to true, `false` otherwise.
 */
static bool has_jit_entitlement(void) {
    // Use pthread_once to ensure the dynamic loading happens exactly once, thread-safely.
    static pthread_once_t init_once = PTHREAD_ONCE_INIT;
    pthread_once(&init_once, initialize_macos_apis);

    // Secure JIT path on macOS requires both the entitlement check and the toggle API.
    if (!g_macos_apis.pthread_jit_write_protect_np)
        return false;

    if (!g_macos_apis.SecTaskCopyValueForEntitlement || !g_macos_apis.CFStringCreateWithCString)
        return false;
    bool result = false;
    SecTaskRef task = g_macos_apis.SecTaskCreateFromSelf(g_macos_apis.kCFAllocatorDefault);
    if (!task)
        return false;
    CFStringRef key = g_macos_apis.CFStringCreateWithCString(
        g_macos_apis.kCFAllocatorDefault, "com.apple.security.cs.allow-jit", kCFStringEncodingUTF8);
    CFTypeRef value = nullptr;
    if (key) {
        // This is the core check: ask the system for the value of the entitlement.
        value = g_macos_apis.SecTaskCopyValueForEntitlement(task, key, nullptr);
        g_macos_apis.CFRelease(key);
    }
    g_macos_apis.CFRelease(task);
    if (value) {
        // The value of the entitlement is a CFBoolean, so we must extract its value.
        if (g_macos_apis.CFBooleanGetValue && g_macos_apis.CFBooleanGetValue(value))
            result = true;
        g_macos_apis.CFRelease(value);
    }
    return result;
}
#endif  // INFIX_OS_MACOS
// Hardened POSIX Anonymous Shared Memory Allocator (for Dual-Mapping W^X)
#if !defined(INFIX_OS_WINDOWS) && !defined(INFIX_OS_MACOS) && !defined(INFIX_OS_ANDROID) && !defined(INFIX_OS_OPENBSD)
#include <fcntl.h>
#include <stdint.h>
#if defined(__linux__) && defined(_GNU_SOURCE)
#include <sys/syscall.h>
#endif

/**
 * @internal
 * @brief Creates an anonymous file descriptor suitable for dual-mapping.
 *
 * @details Attempts multiple strategies in order of preference:
 * 1. `memfd_create`: Modern Linux (kernel 3.17+). Best for security (no filesystem path).
 * 2. `shm_open(SHM_ANON)`: FreeBSD/DragonFly. Automatic anonymity.
 * 3. `shm_open(random_name)`: Fallback for older Linux/POSIX. Manually unlinked immediately.
 */
static int create_anonymous_file(void) {
#if defined(__linux__) && defined(MFD_CLOEXEC)
    // Strategy 1: memfd_create (Linux 3.17+)
    // MFD_CLOEXEC ensures the FD isn't leaked to child processes.
    int linux_fd = memfd_create("infix_jit", MFD_CLOEXEC);
    if (linux_fd >= 0)
        return linux_fd;
    // If it fails (e.g. old kernel, ENOSYS), fall through to shm_open.
#endif

#if defined(__FreeBSD__) && defined(SHM_ANON)
    // Strategy 2: SHM_ANON (FreeBSD)
    int bsd_fd = shm_open(SHM_ANON, O_RDWR | O_CREAT | O_EXCL, 0600);
    if (bsd_fd >= 0)
        return bsd_fd;
#endif

    // Strategy 3: shm_open with randomized name (Legacy POSIX)
    char shm_name[64];
    uint64_t random_val = 0;
    // Generate a sufficiently random name to avoid collisions if multiple processes
    // are running this code simultaneously. Using /dev/urandom is a robust way to do this.
    int rand_fd = open("/dev/urandom", O_RDONLY);
    if (rand_fd < 0)
        return -1;
    ssize_t bytes_read = read(rand_fd, &random_val, sizeof(random_val));
    close(rand_fd);
    if (bytes_read != sizeof(random_val))
        return -1;

    snprintf(shm_name, sizeof(shm_name), "/infix-jit-%d-%llx", getpid(), (unsigned long long)random_val);
    // Create the shared memory object exclusively.
    int fd = shm_open(shm_name, O_RDWR | O_CREAT | O_EXCL, 0600);
    if (fd >= 0) {
        // Unlink immediately. The name is removed, but the inode persists until close().
        shm_unlink(shm_name);
        return fd;
    }
    return -1;
}
#endif
// Public API: Executable Memory Management
/**
 * @internal
 * @brief Allocates a block of memory suitable for holding JIT-compiled code,
 *        respecting platform-specific W^X (Write XOR Execute) security policies.
 * @param size The number of bytes to allocate. Must be a multiple of the system page size.
 * @return An `infix_executable_t` structure. On failure, its pointers will be `nullptr`.
 */
c23_nodiscard infix_executable_t infix_executable_alloc(size_t size) {
#if defined(INFIX_OS_WINDOWS)
    infix_executable_t exec = {.rx_ptr = nullptr, .rw_ptr = nullptr, .size = 0, .handle = nullptr};
#else
    infix_executable_t exec = {.rx_ptr = nullptr, .rw_ptr = nullptr, .size = 0, .shm_fd = -1};
#endif
    if (size == 0)
        return exec;
#if defined(INFIX_OS_WINDOWS)
    // Windows: Single-mapping W^X. Allocate as RW, later change to RX via VirtualProtect.
    void * code = VirtualAlloc(nullptr, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (code == nullptr) {
        _infix_set_system_error(
            INFIX_CATEGORY_ALLOCATION, INFIX_CODE_EXECUTABLE_MEMORY_FAILURE, GetLastError(), nullptr);
        return exec;
    }
    exec.rw_ptr = code;
    exec.rx_ptr = code;
#elif defined(INFIX_OS_MACOS) || defined(INFIX_OS_ANDROID) || defined(INFIX_OS_OPENBSD) || defined(INFIX_OS_DRAGONFLY)
    // Single-mapping POSIX platforms. Allocate as RW, later change to RX via mprotect.
    void * code = MAP_FAILED;
#if defined(MAP_ANON)
    int flags = MAP_PRIVATE | MAP_ANON;
#if defined(INFIX_OS_MACOS)
    // On macOS, we perform a one-time check for JIT support.
    static bool g_use_secure_jit_path = false;
    static bool g_checked_jit_support = false;
    if (!g_checked_jit_support) {
        g_use_secure_jit_path = has_jit_entitlement();
        INFIX_DEBUG_PRINTF("macOS JIT check: Entitlement found = %s. Using %s API.",
                           g_use_secure_jit_path ? "yes" : "no",
                           g_use_secure_jit_path ? "secure (MAP_JIT)" : "legacy (mprotect)");
        g_checked_jit_support = true;
    }
    // If entitled, use the modern, more secure MAP_JIT flag.
    if (g_use_secure_jit_path)
        flags |= MAP_JIT;
#endif  // INFIX_OS_MACOS
    code = mmap(nullptr, size, PROT_READ | PROT_WRITE, flags, -1, 0);
#if defined(INFIX_OS_MACOS)
    if (code != MAP_FAILED && g_use_secure_jit_path) {
        // Switch thread to Write mode. enabled=0 means Write allowed.
        g_macos_apis.pthread_jit_write_protect_np(0);
    }
#endif
#endif  // MAP_ANON
    if (code == MAP_FAILED) {  // Fallback for older systems without MAP_ANON
        int fd = open("/dev/zero", O_RDWR);
        if (fd != -1) {
            code = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
            close(fd);
        }
    }
    if (code == MAP_FAILED) {
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_EXECUTABLE_MEMORY_FAILURE, errno, nullptr);
        return exec;
    }
    exec.rw_ptr = code;
    exec.rx_ptr = code;
#else
    // Dual-mapping POSIX platforms (e.g., Linux, FreeBSD). Create two separate views of the same memory.
    exec.shm_fd = create_anonymous_file();
    if (exec.shm_fd < 0) {
        _infix_set_system_error(
            INFIX_CATEGORY_ALLOCATION, INFIX_CODE_EXECUTABLE_MEMORY_FAILURE, errno, "create_anonymous_file failed");
        return exec;
    }
    if (ftruncate(exec.shm_fd, size) != 0) {
        _infix_set_system_error(
            INFIX_CATEGORY_ALLOCATION, INFIX_CODE_EXECUTABLE_MEMORY_FAILURE, errno, "ftruncate failed");
        close(exec.shm_fd);
        exec.shm_fd = -1;  // Ensure clean state
        return exec;
    }
    // The RW mapping.
    exec.rw_ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, exec.shm_fd, 0);
    // The RX mapping of the exact same physical memory.
    exec.rx_ptr = mmap(nullptr, size, PROT_READ | PROT_EXEC, MAP_SHARED, exec.shm_fd, 0);
    // If either mapping fails, clean up both and return an error.
    if (exec.rw_ptr == MAP_FAILED || exec.rx_ptr == MAP_FAILED) {
        int err = errno;  // Capture errno before cleanup
        if (exec.rw_ptr != MAP_FAILED)
            munmap(exec.rw_ptr, size);
        if (exec.rx_ptr != MAP_FAILED)
            munmap(exec.rx_ptr, size);
        close(exec.shm_fd);
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_EXECUTABLE_MEMORY_FAILURE, err, "mmap failed");
        return (infix_executable_t){.rx_ptr = nullptr, .rw_ptr = nullptr, .size = 0, .shm_fd = -1};
    }

    // The mmap mappings hold a reference to the shared memory object, so we don't
    // need the FD anymore. Keeping it open consumes a file descriptor per trampoline,
    // causing "shm_open failed" after ~1024 trampolines.
    close(exec.shm_fd);
    exec.shm_fd = -1;
#endif
    exec.size = size;
    INFIX_DEBUG_PRINTF("Allocated JIT memory. RW at %p, RX at %p", exec.rw_ptr, exec.rx_ptr);
    return exec;
}
/**
 * @internal
 * @brief Frees a block of executable memory with use-after-free hardening.
 *
 * @details Before freeing the memory, this function first attempts to change the
 * memory protection to be inaccessible (`PROT_NONE` or `PAGE_NOACCESS`). This
 * creates a "guard page" that will cause an immediate, safe crash if a dangling
 * pointer to the freed trampoline is ever used, making use-after-free bugs
 * much easier to detect and debug.
 *
 * @param exec The executable memory block to free.
 */
void infix_executable_free(infix_executable_t exec) {
    if (exec.size == 0)
        return;
#if defined(INFIX_OS_WINDOWS)
    if (exec.rw_ptr) {
        // Change protection to NOACCESS to catch use-after-free bugs immediately.
        if (!VirtualProtect(exec.rw_ptr, exec.size, PAGE_NOACCESS, &(DWORD){0}))
            INFIX_DEBUG_PRINTF("WARNING: VirtualProtect failed to set PAGE_NOACCESS guard page.");
        VirtualFree(exec.rw_ptr, 0, MEM_RELEASE);
    }
#elif defined(INFIX_OS_MACOS)
    // On macOS with MAP_JIT, the memory is managed with special thread-local permissions.
    // We only need to unmap the single mapping.
    if (exec.rw_ptr) {
        // Creating a guard page before unmapping is good practice.
        mprotect(exec.rw_ptr, exec.size, PROT_NONE);
        munmap(exec.rw_ptr, exec.size);
    }
#elif defined(INFIX_OS_ANDROID) || defined(INFIX_OS_OPENBSD) || defined(INFIX_OS_DRAGONFLY)
    // Other single-mapping POSIX systems.
    if (exec.rw_ptr) {
        mprotect(exec.rw_ptr, exec.size, PROT_NONE);
        munmap(exec.rw_ptr, exec.size);
    }
#else
    // Dual-mapping POSIX: protect and unmap both views.
    if (exec.rx_ptr)
        mprotect(exec.rx_ptr, exec.size, PROT_NONE);
    if (exec.rw_ptr)
        munmap(exec.rw_ptr, exec.size);
    if (exec.rx_ptr && exec.rx_ptr != exec.rw_ptr)  // rw_ptr might be same as rx_ptr on some platforms
        munmap(exec.rx_ptr, exec.size);
    if (exec.shm_fd >= 0)
        close(exec.shm_fd);
#endif
}
/**
 * @internal
 * @brief Makes a block of JIT memory executable and flushes instruction caches.
 *
 * @details This function completes the W^X process.
 * - On single-mapping platforms, it changes the memory protection from RW to RX.
 * - On dual-mapping platforms, this is a no-op as the RX mapping already exists.
 *
 * Crucially, it also handles flushing the CPU's instruction cache on architectures
 * that require it (like AArch64). This is necessary because the CPU may have cached
 * old (zeroed) data from the memory location, and it must be explicitly told to
 * re-read the newly written machine code instructions.
 *
 * @param exec The executable memory block.
 * @return `true` on success, `false` on failure.
 */
c23_nodiscard bool infix_executable_make_executable(infix_executable_t * exec) {
    if (exec->rw_ptr == nullptr || exec->size == 0)
        return false;
    // On AArch64 (and other RISC architectures), the instruction and data caches can be
    // separate. We must explicitly flush the D-cache (where the JIT wrote the code)
    // and invalidate the I-cache so the CPU fetches the new instructions.
    // We might as well do it on x64 too.
#if defined(_MSC_VER)
    // Use the Windows-specific API.
    FlushInstructionCache(GetCurrentProcess(), exec->rw_ptr, exec->size);
#elif defined(INFIX_OS_MACOS)
    // Use the Apple-specific API if available (required for Apple Silicon correctness)
    if (g_macos_apis.sys_icache_invalidate)
        g_macos_apis.sys_icache_invalidate(exec->rw_ptr, exec->size);
    else
        __builtin___clear_cache((char *)exec->rw_ptr, (char *)exec->rw_ptr + exec->size);
#else
    // Use the GCC/Clang built-in for other platforms.
    __builtin___clear_cache((char *)exec->rw_ptr, (char *)exec->rw_ptr + exec->size);
#endif
    bool result = false;
#if defined(INFIX_OS_WINDOWS)
    // Finalize permissions to Read+Execute.
    result = VirtualProtect(exec->rw_ptr, exec->size, PAGE_EXECUTE_READ, &(DWORD){0});
    if (!result)
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_PROTECTION_FAILURE, GetLastError(), nullptr);
#elif defined(INFIX_OS_MACOS)
    static bool g_use_secure_jit_path = false;
    static bool g_checked_jit_support = false;
    if (!g_checked_jit_support) {
        g_use_secure_jit_path = has_jit_entitlement();
        g_checked_jit_support = true;
    }

    if (g_use_secure_jit_path && g_macos_apis.pthread_jit_write_protect_np) {
        // Switch thread state to Execute allowed (enabled=1)
        g_macos_apis.pthread_jit_write_protect_np(1);
        result = true;
    }
    else {
        result = (mprotect(exec->rw_ptr, exec->size, PROT_READ | PROT_EXEC) == 0);
    }
    if (!result)
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_PROTECTION_FAILURE, errno, nullptr);
#elif defined(INFIX_OS_ANDROID) || defined(INFIX_OS_OPENBSD) || defined(INFIX_OS_DRAGONFLY)
    // Other single-mapping POSIX platforms use mprotect.
    result = (mprotect(exec->rw_ptr, exec->size, PROT_READ | PROT_EXEC) == 0);
    if (!result)
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_PROTECTION_FAILURE, errno, nullptr);
#else
    // Dual-mapping POSIX (Linux, FreeBSD).
    // The RX mapping is already executable.
    // SECURITY CRITICAL: We MUST unmap the RW view now. If we leave it mapped,
    // an attacker with a heap disclosure could find it and overwrite the JIT code,
    // bypassing W^X.
    if (munmap(exec->rw_ptr, exec->size) == 0) {
        exec->rw_ptr = nullptr;  // Clear the pointer to prevent double-free or misuse.
        result = true;
    }
    else {
        _infix_set_system_error(
            INFIX_CATEGORY_ALLOCATION, INFIX_CODE_PROTECTION_FAILURE, errno, "munmap of RW view failed");
        result = false;
    }
#endif
    if (result)
        INFIX_DEBUG_PRINTF("Memory at %p is now executable.", exec->rx_ptr);
    return result;
}
// Public API: Protected (Read-Only) Memory
/**
 * @internal
 * @brief Allocates a block of standard read-write memory for a context object.
 *
 * @details This is used to allocate the memory for an `infix_reverse_t` context. The
 * memory is allocated as standard RW memory, populated, and then made read-only
 * via `infix_protected_make_readonly` for security hardening.
 *
 * @param size The number of bytes to allocate.
 * @return An `infix_protected_t` handle, or a zeroed struct on failure.
 */
c23_nodiscard infix_protected_t infix_protected_alloc(size_t size) {
    infix_protected_t prot = {.rw_ptr = nullptr, .size = 0};
    if (size == 0)
        return prot;
#if defined(INFIX_OS_WINDOWS)
    prot.rw_ptr = VirtualAlloc(nullptr, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!prot.rw_ptr)
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, GetLastError(), nullptr);
#else
#if defined(MAP_ANON)
    prot.rw_ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
#else
    int fd = open("/dev/zero", O_RDWR);
    if (fd == -1)
        prot.rw_ptr = MAP_FAILED;
    else {
        prot.rw_ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
        close(fd);
    }
#endif
    if (prot.rw_ptr == MAP_FAILED) {
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_OUT_OF_MEMORY, errno, nullptr);
        prot.rw_ptr = nullptr;
    }
#endif
    if (prot.rw_ptr)
        prot.size = size;
    return prot;
}
/**
 * @internal
 * @brief Frees a block of protected memory.
 * @param prot The memory block to free.
 */
void infix_protected_free(infix_protected_t prot) {
    if (prot.size == 0)
        return;
#if defined(INFIX_OS_WINDOWS)
    VirtualFree(prot.rw_ptr, 0, MEM_RELEASE);
#else
    munmap(prot.rw_ptr, prot.size);
#endif
}
/**
 * @internal
 * @brief Makes a block of memory read-only for security hardening.
 *
 * @details This function is called on the `infix_reverse_t` context after it has been
 * fully initialized. By making the context read-only, it helps prevent bugs or
 * security vulnerabilities from corrupting critical state like function pointers.
 *
 * @param prot The memory block to make read-only.
 * @return `true` on success, `false` on failure.
 */
c23_nodiscard bool infix_protected_make_readonly(infix_protected_t prot) {
    if (prot.size == 0)
        return false;
    bool result = false;
#if defined(INFIX_OS_WINDOWS)
    result = VirtualProtect(prot.rw_ptr, prot.size, PAGE_READONLY, &(DWORD){0});
    if (!result)
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_PROTECTION_FAILURE, GetLastError(), nullptr);
#else
    result = (mprotect(prot.rw_ptr, prot.size, PROT_READ) == 0);
    if (!result)
        _infix_set_system_error(INFIX_CATEGORY_ALLOCATION, INFIX_CODE_PROTECTION_FAILURE, errno, nullptr);
#endif
    return result;
}
// Universal Reverse Call Dispatcher
/**
 * @internal
 * @brief The universal C entry point for all reverse call trampolines.
 *
 * @details The JIT-compiled stub for a reverse call performs the minimal work of
 * marshalling all arguments from their native ABI locations (registers and stack)
 * into a standard `void**` array on its own stack. It then calls this function.
 *
 * This dispatcher inspects the `infix_reverse_t` context and takes one of two paths:
 *
 * 1.  **Type-Safe Callback Path:** If `cached_forward_trampoline` is not null, it
 *     means this is a type-safe callback. The dispatcher uses this pre-generated
 *     forward trampoline to call the user's C handler, which has a clean, native
 *     C function signature.
 *
 * 2.  **Generic Closure Path:** If there is no cached trampoline, it's a generic
 *     closure. The dispatcher directly calls the user's generic handler function,
 *     passing it the context, return buffer, and the `void**` args array.
 *
 * @param context The `infix_reverse_t` context for this call.
 * @param return_value_ptr A pointer to the stack buffer where the return value must be written.
 * @param args_array A pointer to the `void**` array of argument pointers.
 */
void infix_internal_dispatch_callback_fn_impl(infix_reverse_t * context, void * return_value_ptr, void ** args_array) {
    INFIX_DEBUG_PRINTF(
        "Dispatching reverse call. Context: %p, User Fn: %p", (void *)context, context->user_callback_fn);
    if (context->user_callback_fn == nullptr) {
        // If no handler is set, do nothing. If the function has a return value,
        // it's good practice to zero it out to avoid returning garbage.
        if (return_value_ptr && context->return_type->size > 0)
            infix_memset(return_value_ptr, 0, context->return_type->size);
        return;
    }
    if (context->cached_forward_trampoline != nullptr) {
        // Path 1: Type-safe "callback". Use the pre-generated forward trampoline to
        // call the user's C function with the correct signature. This is efficient
        // and provides a clean interface for the C developer.
        infix_cif_func cif_func = infix_forward_get_code(context->cached_forward_trampoline);
        cif_func(return_value_ptr, args_array);
    }
    else {
        // Path 2: Generic "closure". Directly call the user's generic handler.
        // This path is more flexible and is intended for language bindings where the
        // handler needs access to the context and raw argument pointers.
        infix_closure_handler_fn handler = (infix_closure_handler_fn)context->user_callback_fn;
        handler(context, return_value_ptr, args_array);
    }
    INFIX_DEBUG_PRINTF("Exiting reverse call dispatcher.");
}
