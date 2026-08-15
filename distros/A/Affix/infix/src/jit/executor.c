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
#include <pthread.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
#endif
#if defined(INFIX_OS_MACOS)
#include <dlfcn.h>
#include <libkern/OSCacheControl.h>
#endif
// Polyfills for mmap flags for maximum POSIX compatibility.
#if defined(INFIX_ENV_POSIX) && !defined(INFIX_OS_WINDOWS)
#if !defined(MAP_ANON) && defined(MAP_ANONYMOUS)
#define MAP_ANON MAP_ANONYMOUS
#endif
static pthread_mutex_t g_dwarf_mutex = PTHREAD_MUTEX_INITIALIZER;
#endif

#if defined(INFIX_OS_WINDOWS) && defined(INFIX_ARCH_X64)
// SEH Unwind Info Opcodes and Structures for JIT code on Windows x64.
// These are defined in winnt.h but we redefine them here for clarity and to ensure availability.
#define UWOP_PUSH_NONVOL 0
#define UWOP_ALLOC_LARGE 1
#define UWOP_ALLOC_SMALL 2
#define UWOP_SET_FPREG 3

#pragma pack(push, 1)
typedef struct _UNWIND_CODE {
    uint8_t CodeOffset;
    uint8_t UnwindOp : 4;
    uint8_t OpInfo : 4;
} UNWIND_CODE;

typedef struct _UNWIND_INFO {
    uint8_t Version : 3;
    uint8_t Flags : 5;
    uint8_t SizeOfPrologue;
    uint8_t CountOfCodes;
    uint8_t FrameRegister : 4;
    uint8_t FrameOffset : 4;
    UNWIND_CODE UnwindCode[1];  // Variable length array
} UNWIND_INFO;

// We reserve 512 bytes at the end of every JIT block for SEH metadata.
#define INFIX_SEH_METADATA_SIZE 256
#elif defined(INFIX_OS_WINDOWS) && defined(INFIX_ARCH_AARCH64)
#pragma pack(push, 1)
typedef struct _UNWIND_INFO_ARM64 {
    uint32_t FunctionLength : 18;
    uint32_t Version : 2;
    uint32_t X : 1;
    uint32_t E : 1;
    uint32_t EpilogueCount : 5;
    uint32_t CodeWords : 5;
} UNWIND_INFO_ARM64;
#pragma pack(pop)
#define INFIX_SEH_METADATA_SIZE 256
#else
#define INFIX_SEH_METADATA_SIZE 0
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
#if defined(INFIX_OS_LINUX) && defined(_GNU_SOURCE)
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
#if defined(INFIX_OS_LINUX) && defined(MFD_CLOEXEC)
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
    infix_executable_t exec = {
        .rx_ptr = nullptr, .rw_ptr = nullptr, .size = 0, .handle = nullptr, .seh_registration = nullptr};
#else
    infix_executable_t exec = {.rx_ptr = nullptr, .rw_ptr = nullptr, .size = 0, .shm_fd = -1, .eh_frame_ptr = nullptr};
#endif
    if (size == 0)
        return exec;

#if defined(INFIX_OS_WINDOWS)
    // Add headroom for SEH metadata on Windows.
    size_t total_size = size + INFIX_SEH_METADATA_SIZE;

    // Windows: Single-mapping W^X. Allocate as RW, later change to RX via VirtualProtect.
    void * code = VirtualAlloc(nullptr, total_size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
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

#if defined(INFIX_OS_WINDOWS)
/**
 * @internal
 * @brief The personality routine for safe trampolines on Windows.
 *
 * @details This function is called by the Windows unwinder when an exception
 * occurs within a safe trampoline or its callees. It catches the exception,
 * sets the `INFIX_CODE_NATIVE_EXCEPTION` error, and redirects execution to
 * the trampoline's epilogue by modifying the instruction pointer in the
 * current context record and continuing execution.
 */
static EXCEPTION_DISPOSITION _infix_seh_personality_routine(PEXCEPTION_RECORD ExceptionRecord,
                                                            void * EstablisherFrame,
                                                            c23_maybe_unused PCONTEXT ContextRecord,
                                                            void * DispatcherContext) {
    PDISPATCHER_CONTEXT dc = (PDISPATCHER_CONTEXT)DispatcherContext;

    // If we are already unwinding, don't do anything.
    if (ExceptionRecord->ExceptionFlags & (EXCEPTION_UNWINDING | EXCEPTION_EXIT_UNWIND))
        return ExceptionContinueSearch;

    // Set the thread-local error.
    _infix_set_error(INFIX_CATEGORY_ABI, INFIX_CODE_NATIVE_EXCEPTION, 0);

    // Retrieve the target epilogue IP from our HandlerData.
    // The HandlerData points to the 4-byte epilogue offset we stored in UNWIND_INFO.
    uint32_t epilogue_offset = *(uint32_t *)dc->HandlerData;
    void * target_ip = (void *)(dc->ImageBase + epilogue_offset);

    // Perform a non-local unwind to the epilogue.
    RtlUnwind(EstablisherFrame, target_ip, ExceptionRecord, nullptr);

    return ExceptionContinueSearch;  // Unreachable
}

#if defined(INFIX_ARCH_X64)
// Internal: Populates and registers SEH metadata for a Windows x64 JIT block.
static void _infix_register_seh_windows_x64(infix_executable_t * exec,
                                            infix_executable_category_t category,
                                            uint32_t prologue_size,
                                            uint32_t epilogue_offset) {
    // metadata_ptr starts after the machine code.
    uint8_t * metadata_base = (uint8_t *)exec->rw_ptr + exec->size;

    // RUNTIME_FUNCTION (PDATA) - Must be 4-byte aligned.
    RUNTIME_FUNCTION * rf = (RUNTIME_FUNCTION *)_infix_align_up((size_t)metadata_base, 4);

    // UNWIND_INFO (XDATA) - Follows PDATA.
    UNWIND_INFO * ui = (UNWIND_INFO *)_infix_align_up((size_t)(rf + 1), 2);

    ui->Version = 1;
    ui->Flags = 0;
    if (category == INFIX_EXECUTABLE_SAFE_FORWARD)
        ui->Flags |= UNW_FLAG_EHANDLER;
    ui->FrameRegister = 5;  // RBP
    ui->FrameOffset = 0;
    ui->SizeOfPrologue = (uint8_t)prologue_size;

    if (category == INFIX_EXECUTABLE_REVERSE) {
        // Reverse Trampoline: push rbp, push rsi, push rdi, mov rbp, rsp, and rsp -mask, [sub rsp, alloc]
        ui->CountOfCodes = 4;
        ui->UnwindCode[0].CodeOffset = 6;  // After mov rbp, rsp
        ui->UnwindCode[0].UnwindOp = UWOP_SET_FPREG;
        ui->UnwindCode[0].OpInfo = 0;

        ui->UnwindCode[1].CodeOffset = 3;  // After push rdi
        ui->UnwindCode[1].UnwindOp = UWOP_PUSH_NONVOL;
        ui->UnwindCode[1].OpInfo = 7;  // RDI

        ui->UnwindCode[2].CodeOffset = 2;  // After push rsi
        ui->UnwindCode[2].UnwindOp = UWOP_PUSH_NONVOL;
        ui->UnwindCode[2].OpInfo = 6;  // RSI

        ui->UnwindCode[3].CodeOffset = 1;  // After push rbp
        ui->UnwindCode[3].UnwindOp = UWOP_PUSH_NONVOL;
        ui->UnwindCode[3].OpInfo = 5;  // RBP
    }
    else {
        // Forward or Direct Trampoline: push rbp, push r12-r15, mov rbp, rsp, and rsp -16, [sub rsp, alloc]
        ui->CountOfCodes = 6;
        // Opcodes in reverse order:
        ui->UnwindCode[0].CodeOffset = 12;  // After mov rbp, rsp
        ui->UnwindCode[0].UnwindOp = UWOP_SET_FPREG;
        ui->UnwindCode[0].OpInfo = 0;

        ui->UnwindCode[1].CodeOffset = 9;  // After push r15
        ui->UnwindCode[1].UnwindOp = UWOP_PUSH_NONVOL;
        ui->UnwindCode[1].OpInfo = 15;  // R15

        ui->UnwindCode[2].CodeOffset = 7;  // After push r14
        ui->UnwindCode[2].UnwindOp = UWOP_PUSH_NONVOL;
        ui->UnwindCode[2].OpInfo = 14;  // R14

        ui->UnwindCode[3].CodeOffset = 5;  // After push r13
        ui->UnwindCode[3].UnwindOp = UWOP_PUSH_NONVOL;
        ui->UnwindCode[3].OpInfo = 13;  // R13

        ui->UnwindCode[4].CodeOffset = 3;  // After push r12
        ui->UnwindCode[4].UnwindOp = UWOP_PUSH_NONVOL;
        ui->UnwindCode[4].OpInfo = 12;  // R12

        ui->UnwindCode[5].CodeOffset = 1;  // After push rbp
        ui->UnwindCode[5].UnwindOp = UWOP_PUSH_NONVOL;
        ui->UnwindCode[5].OpInfo = 5;  // RBP
    }

    // 3. Personality Routine Stub - Follows UNWIND_INFO.
    // The ExceptionHandler field is at offset: 4 + ((CountOfCodes + 1) & ~1) * 2
    uint32_t * eh_field_ptr = (uint32_t *)&ui->UnwindCode[(ui->CountOfCodes + 1) & ~1];

    // Position the stub AFTER the ExceptionHandler RVA and HandlerData (8 bytes total).
    uint8_t * stub = (uint8_t *)_infix_align_up((size_t)(eh_field_ptr + 2), 16);

    stub[0] = 0x48;
    stub[1] = 0xB8;  // mov rax, imm64
    *(uint64_t *)(stub + 2) = (uint64_t)_infix_seh_personality_routine;
    stub[10] = 0xFF;
    stub[11] = 0xE0;  // jmp rax

    // BaseAddress should be 64KB aligned for maximum compatibility.
    DWORD64 base_address = (DWORD64)exec->rx_ptr & ~0xFFFF;
    DWORD rva_offset = (DWORD)((uint8_t *)exec->rx_ptr - (uint8_t *)base_address);

    rf->BeginAddress = rva_offset;  // Relative to BaseAddress
    // EndAddress covers the entire code block.
    rf->EndAddress = rva_offset + (DWORD)exec->size;
    rf->UnwindData = rva_offset + (DWORD)((uint8_t *)ui - (uint8_t *)exec->rx_ptr);

    if (ui->Flags & UNW_FLAG_EHANDLER) {
        // ExceptionHandler RVA points to our absolute jump stub.
        eh_field_ptr[0] = rva_offset + (uint32_t)(stub - (uint8_t *)exec->rx_ptr);
        // HandlerData field stores our target epilogue offset.
        eh_field_ptr[1] = epilogue_offset;
    }

    if (RtlAddFunctionTable(rf, 1, base_address)) {
        exec->seh_registration = rf;
        INFIX_DEBUG_PRINTF(
            "Registered SEH PDATA at %p (XDATA at %p, Stub at %p) for JIT code at %p", rf, ui, stub, exec->rx_ptr);
    }
    else {
        INFIX_DEBUG_PRINTF("infix: RtlAddFunctionTable failed! GetLastError=%lu\n", GetLastError());
    }
}
#elif defined(INFIX_ARCH_AARCH64)
// Internal: Populates and registers SEH metadata for a Windows ARM64 JIT block.
static void _infix_register_seh_windows_arm64(infix_executable_t * exec,
                                              infix_executable_category_t category,
                                              uint32_t prologue_size,
                                              uint32_t epilogue_offset) {
    uint8_t * metadata_base = (uint8_t *)exec->rw_ptr + exec->size;

    // RUNTIME_FUNCTION (PDATA) - Must be 4-byte aligned.
    // On ARM64, we use two entries: one for the function and a sentinel for the end.
    RUNTIME_FUNCTION * rf = (RUNTIME_FUNCTION *)_infix_align_up((size_t)metadata_base, 4);

    // UNWIND_INFO (XDATA) - Follows PDATA.
    UNWIND_INFO_ARM64 * ui = (UNWIND_INFO_ARM64 *)_infix_align_up((size_t)(rf + 2), 4);
    infix_memset(ui, 0, sizeof(UNWIND_INFO_ARM64));

    ui->FunctionLength = (uint32_t)(exec->size / 4);
    ui->Version = 0;
    ui->X = (category == INFIX_EXECUTABLE_SAFE_FORWARD);
    ui->E = 0;
    ui->EpilogueCount = 1;

    uint8_t * unwind_codes = (uint8_t *)(ui + 1);
    uint32_t code_idx = 0;

    if (category == INFIX_EXECUTABLE_REVERSE) {
        // Reverse Prologue: stp x29, x30, [sp, #-16]!; mov x29, sp; sub sp, sp, #alloc
        // Opcodes in REVERSE order:
        unwind_codes[code_idx++] = 0xE1;  // mov x29, sp
        unwind_codes[code_idx++] = 0xC8;  // stp x29, x30, [sp, #-16]!
        unwind_codes[code_idx++] = 0xE4;  // end
    }
    else {
        // Forward or Direct Prologue: stp x29, x30, [sp, #-16]!; stp x19, x20, ...; stp x21, x22, ...; mov x29, sp; sub
        // sp, sp, #alloc
        unwind_codes[code_idx++] = 0xE1;  // mov x29, sp
        unwind_codes[code_idx++] = 0xD4;  // stp x21, x22, [sp, #-16]!
        unwind_codes[code_idx++] = 0xD2;  // stp x19, x20, [sp, #-16]!
        unwind_codes[code_idx++] = 0xC8;  // stp x29, x30, [sp, #-16]!
        unwind_codes[code_idx++] = 0xE4;  // end
    }

    ui->CodeWords = (code_idx + 3) / 4;

    // On ARM64, if X=1, the Exception Handler RVA and Handler Data follow the epilogue scopes
    // and unwind codes.
    // XDATA layout: [Header] [Epilogue Scopes] [Unwind Codes] [Padding] [Handler RVA] [Handler Data]

    uint32_t * epilogue_scopes = (uint32_t *)(ui + 1);
    // Each epilogue scope is 4 bytes. We have ui->EpilogueCount of them.
    epilogue_scopes[0] = (epilogue_offset / 4);  // Epilogue Start Index (instructions)

    uint8_t * unwind_codes_ptr = (uint8_t *)(epilogue_scopes + ui->EpilogueCount);
    // Clear and then copy the codes
    infix_memset(unwind_codes_ptr, 0, ui->CodeWords * 4);
    infix_memcpy(unwind_codes_ptr, unwind_codes, code_idx);

    // Handler info must follow unwind codes (which are already padded to 4 bytes by ui->CodeWords).
    uint32_t * handler_info_ptr = (uint32_t *)(unwind_codes_ptr + ui->CodeWords * 4);

    uint8_t * stub = (uint8_t *)_infix_align_up((size_t)(handler_info_ptr + 2), 16);

    // stub:
    // ldr x9, personality_addr
    // br x9
    // personality_addr: .quad _infix_seh_personality_routine
    *(uint32_t *)stub = 0x58000049;        // ldr x9, #8
    *(uint32_t *)(stub + 4) = 0xD61F0120;  // br x9
    *(uint64_t *)(stub + 8) = (uint64_t)_infix_seh_personality_routine;

    DWORD64 base_address = (DWORD64)exec->rx_ptr & ~0xFFFF;
    DWORD rva_offset = (DWORD)((uint8_t *)exec->rx_ptr - (uint8_t *)base_address);

    rf[0].BeginAddress = rva_offset;
    rf[0].UnwindData = rva_offset + (DWORD)((uint8_t *)ui - (uint8_t *)exec->rx_ptr);

    // Sentinel entry defines the end of the previous function
    rf[1].BeginAddress = rva_offset + (DWORD)exec->size;
    rf[1].UnwindData = 0;

    if (ui->X) {
        // According to the spec, the Exception Handler RVA and Handler Data
        // are located at the end of the XDATA, which is 4-byte aligned.
        handler_info_ptr[0] = rva_offset + (uint32_t)(stub - (uint8_t *)exec->rx_ptr);
        handler_info_ptr[1] = epilogue_offset;
    }

    if (RtlAddFunctionTable(rf, 2, base_address)) {
        exec->seh_registration = rf;
        INFIX_DEBUG_PRINTF(
            "Registered SEH PDATA at %p (XDATA at %p, Stub at %p) for JIT code at %p", rf, ui, stub, exec->rx_ptr);
    }
    else {
        INFIX_DEBUG_PRINTF("infix: RtlAddFunctionTable failed! GetLastError=%lu\n", GetLastError());
    }
}
#endif
#endif

#if defined(INFIX_OS_LINUX) && defined(INFIX_ARCH_X64)
/**
 * @internal
 * @brief Registers DWARF unwind information for a JIT-compiled block on Linux x64.
 * @details This allows the C++ exception unwinder to correctly walk through
 *          JIT-compiled frames. We manually construct a Common Information Entry (CIE)
 *          and a Frame Description Entry (FDE) that match the stack behavior
 *          of our trampolines (standard RBP-based frame).
 */
static void _infix_register_eh_frame_linux_x64(infix_executable_t * exec, infix_executable_category_t category) {
    // Simplified .eh_frame layout: [ CIE | FDE | Terminator ]
    const size_t cie_size = 32;
    const size_t fde_size = 64;
    const size_t total_size = cie_size + fde_size + 4;  // +4 for null terminator

    uint8_t * eh = infix_malloc(total_size);
    if (!eh)
        return;
    infix_memset(eh, 0, total_size);

    uint8_t * p = eh;

    // CIE
    *(uint32_t *)p = (uint32_t)(cie_size - 4);
    p += 4;
    *(uint32_t *)p = 0;
    p += 4;
    *p++ = 1;     // version
    *p++ = '\0';  // augmentation
    *p++ = 1;     // code align
    *p++ = 0x78;  // data align (-8)
    *p++ = 16;    // ret reg (rip)

    // Initial state: CFA = rsp + 8, rip at CFA - 8
    *p++ = 0x0c;
    *p++ = 0x07;
    *p++ = 0x08;
    *p++ = 0x90;
    *p++ = 0x01;
    while ((size_t)(p - eh) < cie_size)
        *p++ = 0;

    // FDE
    uint8_t * fde_start = eh + cie_size;
    p = fde_start;
    *(uint32_t *)p = (uint32_t)(fde_size - 4);
    p += 4;
    *(uint32_t *)p = (uint32_t)(p - eh);
    p += 4;  // back-offset

    *(void **)p = exec->rx_ptr;
    p += 8;
    *(uint64_t *)p = (uint64_t)exec->size;
    p += 8;
    *p++ = 0;  // aug data len

    // Instructions:
    if (category == INFIX_EXECUTABLE_REVERSE) {
        // push rbp; mov rbp, rsp; push rsi; push rdi
        *p++ = 0x41;  // loc +1 (after push rbp)
        *p++ = 0x0e;
        *p++ = 16;  // def_cfa_offset 16
        *p++ = 0x86;
        *p++ = 0x02;  // offset rbp (6), 2
        *p++ = 0x43;  // loc +3 (after mov rbp, rsp)
        *p++ = 0x0d;
        *p++ = 0x06;  // def_cfa_register rbp (6)
        *p++ = 0x41;  // loc +1 (after push rsi)
        *p++ = 0x84;
        *p++ = 0x03;  // offset rsi (4), 3
        *p++ = 0x41;  // loc +1 (after push rdi)
        *p++ = 0x85;
        *p++ = 0x04;  // offset rdi (5), 4
    }
    else {
        // push rbp; mov rbp, rsp; push r12; push r13; push r14; push r15
        *p++ = 0x41;  // loc +1 (after push rbp)
        *p++ = 0x0e;
        *p++ = 16;  // def_cfa_offset 16
        *p++ = 0x86;
        *p++ = 0x02;  // offset rbp (6), 2
        *p++ = 0x43;  // loc +3 (after mov rbp, rsp)
        *p++ = 0x0d;
        *p++ = 0x06;  // def_cfa_register rbp (6)
        *p++ = 0x42;  // loc +2 (after push r12)
        *p++ = 0x8c;
        *p++ = 0x03;  // offset r12, 3
        *p++ = 0x42;  // loc +2 (after push r13)
        *p++ = 0x8d;
        *p++ = 0x04;  // offset r13, 4
        *p++ = 0x42;  // loc +2 (after push r14)
        *p++ = 0x8e;
        *p++ = 0x05;  // offset r14, 5
        *p++ = 0x42;  // loc +2 (after push r15)
        *p++ = 0x8f;
        *p++ = 0x06;  // offset r15, 6
    }

    while ((size_t)(p - eh) < (cie_size + fde_size))
        *p++ = 0;
    *(uint32_t *)p = 0;  // Terminator

    extern void __register_frame(void *);
    pthread_mutex_lock(&g_dwarf_mutex);
    __register_frame(eh);
    pthread_mutex_unlock(&g_dwarf_mutex);

    exec->eh_frame_ptr = eh;
    INFIX_DEBUG_PRINTF("Registered DWARF .eh_frame at %p for JIT code at %p", (void *)eh, exec->rx_ptr);
}
#elif defined(INFIX_OS_LINUX) && defined(INFIX_ARCH_AARCH64)
/**
 * @internal
 * @brief Registers DWARF unwind information for a JIT-compiled block on ARM64 Linux.
 * @details This allows the C++ exception unwinder to correctly walk through
 *          JIT-compiled frames. We manually construct a Common Information Entry (CIE)
 *          and a Frame Description Entry (FDE) that match the stack behavior
 *          of our ARM64 trampolines.
 */
static void _infix_register_eh_frame_arm64(infix_executable_t * exec, infix_executable_category_t category) {
    // Simplified .eh_frame layout: [ CIE | FDE | Terminator ]
    const size_t cie_size = 32;
    const size_t fde_size = 64;
    const size_t total_size = cie_size + fde_size + 4;  // +4 for null terminator

    uint8_t * eh = infix_malloc(total_size);
    if (!eh)
        return;
    infix_memset(eh, 0, total_size);

    uint8_t * p = eh;

    // CIE (Common Information Entry)
    *(uint32_t *)p = (uint32_t)(cie_size - 4);
    p += 4;  // length
    *(uint32_t *)p = 0;
    p += 4;       // cie_id (0)
    *p++ = 1;     // version
    *p++ = '\0';  // augmentation string ("")
    *p++ = 4;     // code_alignment_factor (AArch64 instructions are 4 bytes)
    *p++ = 0x78;  // data_alignment_factor (-8 in SLEB128)
    *p++ = 30;    // return_address_register (30 = lr on arm64)

    // CIE Instructions: Initial state
    // DW_CFA_def_cfa sp, 0
    *p++ = 0x0c;
    *p++ = 31;
    *p++ = 0;
    while ((size_t)(p - eh) < cie_size)
        *p++ = 0;

    // FDE (Frame Description Entry)
    uint8_t * fde_start = eh + cie_size;
    p = fde_start;
    *(uint32_t *)p = (uint32_t)(fde_size - 4);
    p += 4;  // length
    *(uint32_t *)p = (uint32_t)(p - eh);
    p += 4;  // cie_pointer (back-offset)

    *(void **)p = exec->rx_ptr;
    p += 8;  // pc_begin (absolute)
    *(uint64_t *)p = (uint64_t)exec->size;
    p += 8;    // pc_range (absolute)
    *p++ = 0;  // aug data len

    // Instructions: match our trampoline prologue
    if (category == INFIX_EXECUTABLE_REVERSE) {
        // stp x29, x30, [sp, #-16]!; mov x29, sp
        *p++ = 0x41;  // loc +1 (4 bytes, after stp)
        *p++ = 0x0e;
        *p++ = 16;  // def_cfa_offset 16
        *p++ = 0x9d;
        *p++ = 2;  // offset r29 (x29), 2 (CFA - 16)
        *p++ = 0x9e;
        *p++ = 1;     // offset r30 (x30/lr), 1 (CFA - 8)
        *p++ = 0x41;  // loc +1 (4 bytes, after mov)
        *p++ = 0x0d;
        *p++ = 29;  // def_cfa_register r29
    }
    else {
        // stp x29, x30, [sp, #-16]!; stp x19, x20, ...; stp x21, x22, ...; mov x29, sp
        *p++ = 0x41;  // after stp x29, x30
        *p++ = 0x0e;
        *p++ = 16;
        *p++ = 0x9d;
        *p++ = 2;  // x29 at CFA - 16
        *p++ = 0x9e;
        *p++ = 1;     // x30 at CFA - 8
        *p++ = 0x41;  // after stp x19, x20
        *p++ = 0x0e;
        *p++ = 32;
        *p++ = 0x93;
        *p++ = 4;  // x19 at CFA - 32
        *p++ = 0x94;
        *p++ = 3;     // x20 at CFA - 24
        *p++ = 0x41;  // after stp x21, x22
        *p++ = 0x0e;
        *p++ = 48;
        *p++ = 0x95;
        *p++ = 6;  // x21 at CFA - 48
        *p++ = 0x96;
        *p++ = 5;     // x22 at CFA - 40
        *p++ = 0x41;  // after mov x29, sp
        *p++ = 0x0d;
        *p++ = 29;  // def_cfa_register x29 (offset remains 48)
    }

    while ((size_t)(p - eh) < (cie_size + fde_size))
        *p++ = 0;
    *(uint32_t *)p = 0;  // Terminator

    // Register the frame with the runtime.
    extern void __register_frame(void *);
    pthread_mutex_lock(&g_dwarf_mutex);
    __register_frame(eh);
    pthread_mutex_unlock(&g_dwarf_mutex);

    exec->eh_frame_ptr = eh;
    INFIX_DEBUG_PRINTF("Registered ARM64 DWARF .eh_frame at %p for JIT code at %p", (void *)eh, exec->rx_ptr);
}
#endif

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
#if defined(INFIX_ARCH_X64) || defined(INFIX_ARCH_AARCH64)
    if (exec.seh_registration)
        RtlDeleteFunctionTable((PRUNTIME_FUNCTION)exec.seh_registration);
#endif
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
    if (exec.eh_frame_ptr) {
        extern void __deregister_frame(void *);
        pthread_mutex_lock(&g_dwarf_mutex);
        __deregister_frame(exec.eh_frame_ptr);
        pthread_mutex_unlock(&g_dwarf_mutex);
        infix_free(exec.eh_frame_ptr);
    }
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
 * @param category The category of the trampoline.
 * @param prologue_size The size of the prologue.
 * @return `true` on success, `false` on failure.
 */
c23_nodiscard bool infix_executable_make_executable(infix_executable_t * exec,
                                                    c23_maybe_unused infix_executable_category_t category,
                                                    c23_maybe_unused uint32_t prologue_size,
                                                    c23_maybe_unused uint32_t epilogue_offset) {
    if (exec->rw_ptr == nullptr || exec->size == 0)
        return false;

    // On AArch64 (and other RISC architectures), the instruction and data caches can be
    // separate. We must explicitly flush the D-cache (where the JIT wrote the code)
    // and invalidate the I-cache so the CPU fetches the new instructions.
    // We might as well do it on x64 too.
    // NOTE: key on the OS, not the compiler. clang on Windows defines `__clang__`
    // (checked before `_MSC_VER`), so `INFIX_COMPILER_MSVC` is not set for it; the
    // `dc cvau`/`ic ivau` inline-asm path below is illegal at EL0 on Windows NT and
    // SIGILLs every JIT call (STATUS_ILLEGAL_INSTRUCTION, 0xC000001D).
#if defined(INFIX_OS_WINDOWS)
    // Use the Windows-specific API.
    FlushInstructionCache(GetCurrentProcess(), exec->rw_ptr, exec->size);
#elif defined(INFIX_OS_MACOS)
    // Use the Apple-specific API if available (required for Apple Silicon correctness)
    if (g_macos_apis.sys_icache_invalidate)
        g_macos_apis.sys_icache_invalidate(exec->rw_ptr, exec->size);
    else
        __builtin___clear_cache((char *)exec->rw_ptr, (char *)exec->rw_ptr + exec->size);
#elif defined(INFIX_ARCH_AARCH64)
    // Robust manual cache clearing for AArch64 Linux/BSD.
    // We clean the D-cache to point of unification and invalidate the I-cache.
    uintptr_t start = (uintptr_t)exec->rw_ptr;
    uintptr_t end = start + exec->size;
    uintptr_t ctr_el0;
    __asm__ __volatile__("mrs %0, ctr_el0" : "=r"(ctr_el0));

    // D-cache line size is in bits [19:16] as log2 of number of words.
    uintptr_t d_line_size = 4 << ((ctr_el0 >> 16) & 0xf);
    for (uintptr_t addr = start & ~(d_line_size - 1); addr < end; addr += d_line_size)
        __asm__ __volatile__("dc cvau, %0" ::"r"(addr) : "memory");
    __asm__ __volatile__("dsb ish" ::: "memory");

    // I-cache line size is in bits [3:0] as log2 of number of words.
    uintptr_t i_line_size = 4 << (ctr_el0 & 0xf);
    for (uintptr_t addr = start & ~(i_line_size - 1); addr < end; addr += i_line_size)
        __asm__ __volatile__("ic ivau, %0" ::"r"(addr) : "memory");
    __asm__ __volatile__("dsb ish\n\tisb" ::: "memory");
#elif defined(INFIX_ARCH_RISCV)
    // `__builtin___clear_cache` expands to `fence.i`, which lives in the Zifencei
    // extension. Some RISC-V toolchains (e.g. OpenBSD's egcc with a newer binutils)
    // do not enable Zifencei in the default `-march` and reject the opcode, so
    // enable it explicitly for the flush.
    __asm__ __volatile__(".option arch, +zifencei\n\tfence.i" ::: "memory");
#else
    // Use the GCC/Clang built-in for other platforms.
    __builtin___clear_cache((char *)exec->rw_ptr, (char *)exec->rw_ptr + exec->size);
#endif

    bool result = false;
#if defined(INFIX_OS_WINDOWS)
    // On Windows, we register SEH unwind info before making the memory executable.
#if defined(INFIX_ARCH_X64)
    _infix_register_seh_windows_x64(exec, category, prologue_size, epilogue_offset);
#elif defined(INFIX_ARCH_AARCH64)
    _infix_register_seh_windows_arm64(exec, category, prologue_size, epilogue_offset);
#endif
    // Finalize permissions to Read+Execute.
    // We include the SEH metadata in the protected region.
    result = VirtualProtect(exec->rw_ptr, exec->size + INFIX_SEH_METADATA_SIZE, PAGE_EXECUTE_READ, &(DWORD){0});
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
#if defined(INFIX_OS_LINUX) && defined(INFIX_ARCH_X64)
    _infix_register_eh_frame_linux_x64(exec, category);
#elif defined(INFIX_OS_LINUX) && defined(INFIX_ARCH_AARCH64)
    _infix_register_eh_frame_arm64(exec, category);
#endif
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
        _infix_set_system_error(INFIX_CATEGORY_ABI, INFIX_CODE_PROTECTION_FAILURE, errno, nullptr);
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
    INFIX_DEBUG_PRINTF("REVERSE_DISPATCH: context=%p ret=%p args=%p num_args=%zu\n",
                       (void *)context,
                       return_value_ptr,
                       (void *)args_array,
                       context->num_args);
    if (args_array) {
        for (size_t i = 0; i < context->num_args; i++) {
            INFIX_DEBUG_PRINTF("  args[%zu] = %p", i, args_array[i]);
            if (args_array[i])
                INFIX_DEBUG_PRINTF(" (val32: %d %d)", ((int *)args_array[i])[0], ((int *)args_array[i])[1]);
            INFIX_DEBUG_PRINTF("\n");
        }
    }
    INFIX_DEBUG_PRINTF("Dispatching reverse call. Context: %p, User Fn: %p, ret=%p, args=%p",
                       (void *)context,
                       context->user_callback_fn,
                       return_value_ptr,
                       (void *)args_array);
    if (args_array) {
        for (size_t i = 0; i < context->num_args; i++) {
            INFIX_DEBUG_PRINTF(
                "  args[%zu] = %p (val: 0x%04X)", i, args_array[i], args_array[i] ? *(uint16_t *)args_array[i] : 0);
        }
    }
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
