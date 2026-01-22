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
 * @file infix_internals.h
 * @brief Internal data structures, function prototypes, and constants.
 * @ingroup internal_common
 *
 * @details This is the primary internal header for the `infix` library. It defines the
 * complete layout of all opaque public structs (like `infix_forward_t`) and
 * declares internal-only functions (`_infix_*`) that are shared between modules.
 *
 * Its most important role is to define the core ABI abstraction layer through v-tables
 * (`infix_forward_abi_spec`, `infix_reverse_abi_spec`). These structures form the
 * contract between the platform-agnostic JIT engine (`trampoline.c`) and the
 * platform-specific ABI implementations (`arch/...`), making them key to the
 * library's portability and architectural design.
 *
 * This header also brings together all other internal type definitions, creating a
 * single source of truth for the library's internal data model.
 * @internal
 */
#pragma once
#include "common/infix_config.h"
#include "common/platform.h"
#include <infix/infix.h>
/**
 * @struct infix_executable_t
 * @brief Internal representation of an executable memory block for JIT code.
 *
 * @details This struct encapsulates the platform-specific details of allocating and
 * managing executable memory in a way that is compliant with modern OS security
 * features like W^X (Write XOR Execute). It supports two primary strategies:
 *
 * 1.  **Single-Mapping W^X (Windows/macOS/Android):** A single memory region is
 *     allocated as Read-Write (`rw_ptr`). After the JIT compiler writes the
 *     machine code to this region, its permissions are changed to Read-Execute.
 *     In this model, `rx_ptr` and `rw_ptr` point to the same address.
 *
 * 2.  **Dual-Mapping W^X (Linux/BSD):** A single underlying shared memory object
 *     is mapped into the process's address space twice: once as Read-Write
 *     (`rw_ptr`) and once as Read-Execute (`rx_ptr`). The pointers have different
 *     virtual addresses but point to the same physical memory. This is required
 *     on systems with stricter W^X enforcement.
 */
typedef struct {
#if defined(INFIX_OS_WINDOWS)
    HANDLE handle; /**< The handle from `VirtualAlloc`, needed for `VirtualFree`. */
#else
    int shm_fd; /**< The file descriptor for shared memory on dual-mapping POSIX systems. -1 otherwise. */
#endif
    void * rx_ptr; /**< The read-execute memory address. This is the callable function pointer. */
    void * rw_ptr; /**< The read-write memory address. The JIT compiler writes machine code here. */
    size_t size;   /**< The size of the allocated memory region in bytes. */
} infix_executable_t;
/**
 * @struct infix_protected_t
 * @brief Internal representation of a memory block that will be made read-only.
 *
 * @details This is used to harden the `infix_reverse_t` context against runtime
 * memory corruption. The context is allocated in a standard read-write memory
 * region, fully populated, and then its permissions are changed to read-only
 * using this handle.
 */
typedef struct {
    void * rw_ptr; /**< The read-write pointer before being made read-only. */
    size_t size;   /**< The size of the allocated memory region in bytes. */
} infix_protected_t;
/**
 * @struct infix_forward_t
 * @brief Internal definition of a forward trampoline handle.
 * @details This is the concrete implementation of the opaque `infix_forward_t` pointer
 * returned to the user. It is a self-contained object that owns all memory and
 * metadata required for its operation. The type information (`return_type`,
 * `arg_types`) is a deep copy stored in the trampoline's private `arena`,
 * ensuring its lifetime is independent of the types used to create it.
 */
struct infix_forward_t {
    infix_arena_t * arena;   /**< Private or shared arena holding all type metadata for this trampoline. */
    bool is_external_arena;  /**< True if the arena is user-provided and should not be freed by `infix_forward_destroy`.
                              */
    infix_executable_t exec; /**< The executable memory containing the JIT-compiled code. */
    infix_type * return_type;  /**< A deep copy of the function's return type. */
    infix_type ** arg_types;   /**< A deep copy of the function's argument types. */
    size_t num_args;           /**< The total number of arguments. */
    size_t num_fixed_args;     /**< The number of non-variadic arguments. */
    void * target_fn;          /**< The target C function pointer (for bound trampolines), or `nullptr` for unbound. */
    bool is_direct_trampoline; /**< If true, this is a high-performance direct marshalling trampoline. */
};
/**
 * @brief A function pointer to the universal C dispatcher for reverse calls.
 * @details This is the C function that the JIT-compiled reverse trampoline stub calls
 * after marshalling all arguments into a standard C format.
 */
typedef void (*infix_internal_dispatch_callback_fn)(infix_reverse_t *, void *, void **);
/**
 * @struct infix_reverse_t
 * @brief Internal definition of a reverse trampoline (callback/closure) handle.
 * @details This is the concrete implementation of the opaque `infix_reverse_t` pointer.
 * The entire struct is allocated in a page-aligned memory region that is made read-only
 * after initialization to prevent memory corruption vulnerabilities. Like the forward
 * trampoline, it is self-contained and owns deep copies of all its type metadata.
 */
struct infix_reverse_t {
    infix_arena_t * arena;           /**< Private arena for type metadata. */
    infix_executable_t exec;         /**< Executable memory for the JIT stub. */
    infix_protected_t protected_ctx; /**< The read-only memory region holding this struct. */
    infix_type * return_type;        /**< Deep copy of the function's return type. */
    infix_type ** arg_types;         /**< Deep copy of the function's argument types. */
    size_t num_args;                 /**< Total number of arguments. */
    size_t num_fixed_args;           /**< Number of non-variadic arguments. */
    bool is_variadic;                /**< `true` if the signature contains variadic arguments. */
    void * user_callback_fn;         /**< The user-provided handler function pointer (type-safe or generic). */
    void * user_data;                /**< The user-provided context pointer for closures. */
    infix_internal_dispatch_callback_fn
        internal_dispatcher; /**< Pointer to the universal C dispatcher implementation. */
    infix_forward_t *
        cached_forward_trampoline; /**< For type-safe callbacks, a pre-generated trampoline to call the C handler. */
};
/**
 * @struct infix_arena_t
 * @brief Internal definition of a memory arena.
 * @details An arena is a fast, region-based allocator. It pre-allocates a single
 * block of memory and serves subsequent small allocation requests by simply
 * "bumping" a pointer. All memory allocated from an arena is freed at once by
 * destroying the arena itself, eliminating the need to track individual allocations.
 */
struct infix_arena_t {
    char * buffer;                     /**< The backing memory buffer for the arena. */
    size_t capacity;                   /**< The total size of the buffer. */
    size_t current_offset;             /**< The current high-water mark of allocation. */
    bool error;                        /**< A flag set if any allocation fails, preventing subsequent allocations. */
    struct infix_arena_t * next_block; /**< A pointer to the next block in the chain, if this one is full. */
    size_t block_size;                 /**< The size of this specific block's buffer, for chained arenas. */
};
/**
 * @struct _infix_registry_entry_t
 * @brief A single entry in the registry's hash table.
 * @details This is a node in a singly-linked list used for chaining in the
 * event of a hash collision.
 */
typedef struct _infix_registry_entry_t {
    const char * name;                     /**< The registered name of the type. */
    infix_type * type;                     /**< A pointer to the canonical `infix_type` object. */
    bool is_forward_declaration;           /**< `true` if this is just a forward declaration (`@Name;`). */
    struct _infix_registry_entry_t * next; /**< The next entry in the hash bucket chain. */
} _infix_registry_entry_t;
/**
 * @struct infix_registry_t
 * @brief Internal definition of a named type registry.
 * @details Implemented as a hash table with separate chaining for collision resolution.
 * All memory for the table, its entries, and the canonical `infix_type` objects
 * it stores are owned by a single arena for simple lifecycle management.
 */
struct infix_registry_t {
    infix_arena_t * arena;              /**< The arena that owns all type metadata and entry structs. */
    bool is_external_arena;             /**< True if the arena is user-provided and should not be freed. */
    size_t num_buckets;                 /**< The number of buckets in the hash table. */
    size_t num_items;                   /**< The total number of items in the registry. */
    _infix_registry_entry_t ** buckets; /**< The array of hash table buckets (linked list heads). */
};
/**
 * @struct code_buffer
 * @brief A dynamic buffer for staged machine code generation.
 * @details This structure is used during the JIT compilation process. ABI-specific
 * emitters append instruction bytes to this buffer. It automatically grows as needed,
 * allocating memory from a temporary arena that is destroyed after the final
 * code is copied to executable memory.
 */
typedef struct {
    uint8_t * code;        /**< A pointer to the code buffer, allocated from the arena. */
    size_t capacity;       /**< The current capacity of the buffer. */
    size_t size;           /**< The number of bytes currently written to the buffer. */
    bool error;            /**< A flag set on allocation failure. */
    infix_arena_t * arena; /**< The temporary arena used for code generation. */
} code_buffer;
/**
 * @struct infix_library_t
 * @brief Internal definition of a dynamic library handle.
 * @details This is a simple wrapper around the platform's native library handle to provide a consistent API.
 *
 * On Windows, GetModuleHandle(NULL) returns a special handle to the main executable that must NOT be freed with
 * FreeLibrary. This flag tracks that state to ensure infix_library_close behaves correctly.
 */
struct infix_library_t {
    void * handle; /**< The platform-native library handle (`HMODULE` on Windows, `void*` on POSIX). */
#if defined(INFIX_OS_WINDOWS)
    bool is_pseudo_handle; /**< True if the handle is a "pseudo-handle" from GetModuleHandle. */
#endif
};
// ABI Abstraction Layer
/**
 * @def INFIX_MAX_STACK_ALLOC
 * @brief A safety limit (4MB) for the total stack space a trampoline can allocate.
 *        This prevents stack exhaustion from malformed or malicious type layouts.
 */
#define INFIX_MAX_STACK_ALLOC (1024 * 1024 * 4)
/**
 * @def INFIX_MAX_ARG_SIZE
 * @brief A safety limit (64KB) for the size of a single argument.
 */
#define INFIX_MAX_ARG_SIZE (1024 * 64)
/**
 * @enum infix_arg_location_type
 * @brief Describes the physical location where a function argument is passed according to the ABI.
 *
 * This enumeration abstracts away the differences in how various ABIs use
 * registers and the stack to pass data. It is the primary output of the ABI
 * classification process.
 */
typedef enum {
    /** @brief Argument is passed in a general-purpose integer register (e.g., `RCX`, `RDI`, `X0`). */
    ARG_LOCATION_GPR,
#if defined(INFIX_ABI_AAPCS64)
    /** @brief (AArch64) Argument is passed in a vector/floating-point register (e.g., `V0`). */
    ARG_LOCATION_VPR,
    /** @brief (AArch64) A struct <= 16 bytes passed in a pair of GPRs (e.g., `X0`, `X1`). */
    ARG_LOCATION_GPR_PAIR,
    /** @brief (AArch64) A large struct (> 16 bytes) passed by reference; the pointer is in a GPR. */
    ARG_LOCATION_GPR_REFERENCE,
    /** @brief (AArch64) A Homogeneous Floating-point Aggregate passed in consecutive VPRs. */
    ARG_LOCATION_VPR_HFA,
#else  // x64 ABIs
    /** @brief (x64) Argument is passed in an SSE/XMM register (e.g., `XMM0`). */
    ARG_LOCATION_XMM,
    /** @brief (SysV x64) A struct passed in two GPRs (e.g., `RDI`, `RSI`). */
    ARG_LOCATION_GPR_PAIR,
    /** @brief (SysV x64) A struct passed in two SSE registers (e.g., `XMM0`, `XMM1`). */
    ARG_LOCATION_SSE_SSE_PAIR,
    /** @brief (SysV x64) A struct split between a GPR and an SSE register. */
    ARG_LOCATION_INTEGER_SSE_PAIR,
    /** @brief (SysV x64) A struct split between an SSE and a GPR register. */
    ARG_LOCATION_SSE_INTEGER_PAIR,
#endif
    /** @brief Argument is passed on the stack. */
    ARG_LOCATION_STACK
} infix_arg_location_type;
/**
 * @struct infix_arg_location
 * @brief Detailed location information for a single function argument.
 * @details This struct is the result of the ABI classification process for one
 * argument. It provides all the information the code emitters need to generate
 * the correct move/load/store instructions.
 */
typedef struct {
    infix_arg_location_type type; /**< The classification of the argument's location. */
    uint8_t reg_index;            /**< The index of the primary register used. */
    uint8_t reg_index2;           /**< The index of the second register (for pairs). */
    uint32_t num_regs;            /**< Number of regs OR scratch buffer offset. */
    uint32_t stack_offset;        /**< The byte offset from the stack pointer. */
} infix_arg_location;
/**
 * @struct infix_call_frame_layout
 * @brief A complete layout blueprint for a forward call frame.
 * @details This structure is the primary output of `prepare_forward_call_frame`. It serves
 * as a complete plan for the JIT engine, detailing every register and stack slot
 * that needs to be populated before making the `call` instruction.
 */
typedef struct {
    size_t total_stack_alloc; /**< Total bytes to allocate on the stack for arguments and ABI-required space. */
    uint8_t num_gpr_args;     /**< The number of GPRs used for arguments. */
#if defined(INFIX_ABI_AAPCS64)
    uint8_t num_vpr_args; /**< The number of VPRs used for arguments. */
#else
    uint8_t num_xmm_args; /**< The number of XMMs used for arguments. */
#endif
    infix_arg_location * arg_locations; /**< An array of location info for each argument. */
    bool return_value_in_memory; /**< `true` if the return value uses a hidden pointer argument (struct return). */
    bool is_variadic;            /**< `true` if the function is variadic. */
    size_t num_stack_args;       /**< The number of arguments passed on the stack. */
    size_t num_args;             /**< The total number of arguments. */
    void * target_fn;            /**< The target function address. */
} infix_call_frame_layout;
/**
 * @struct infix_reverse_call_frame_layout
 * @brief A complete layout blueprint for a reverse call frame.
 * @details This structure serves as a plan for the JIT-compiled reverse call stub.
 * It contains the offsets for all data structures that the stub needs to create
 * on its stack frame before calling the universal C dispatcher.
 */
typedef struct {
    size_t total_stack_alloc;     /**< Total bytes of local stack space needed. */
    int32_t return_buffer_offset; /**< Stack offset for the buffer to store the return value. */
    int32_t args_array_offset;    /**< Stack offset for the `void**` array passed to the C dispatcher. */
    int32_t saved_args_offset;    /**< Stack offset for the area where argument data is stored/marshalled. */
    int32_t gpr_save_area_offset; /**< (Win x64) Stack offset for saving non-volatile GPRs. */
    int32_t xmm_save_area_offset; /**< (Win x64) Stack offset for saving non-volatile XMMs. */
} infix_reverse_call_frame_layout;
/**
 * @brief Defines the ABI-specific implementation interface for forward trampolines.
 *
 * @details This structure is a virtual function table (v-table) that decouples the
 * platform-agnostic JIT engine (`trampoline.c`) from the platform-specific
 * code generation logic (`arch/...`). Each supported ABI (e.g., SysV x64,
 * Win x64, AArch64) provides a concrete implementation of this interface.
 *
 * The JIT pipeline for a forward call proceeds in a well-defined order:
 * 1. `prepare_forward_call_frame` is called first to analyze the function
 *    signature and produce a complete `infix_call_frame_layout` blueprint.
 * 2. The `generate_*` functions are then called in sequence, consuming the layout
 *    blueprint to emit the corresponding machine code into a `code_buffer`.
 */
typedef struct {
    /**
     * @brief Analyzes a function signature to create a complete call frame layout.
     * @details This is the "classification" stage. It determines where each argument
     *          and the return value will be placed (in which registers or on what
     *          stack offset) according to the target ABI's rules. The resulting
     *          layout is a complete plan for the code emitters.
     * @param[in] arena A temporary arena for allocating the layout struct.
     * @param[out] out_layout Receives the newly created layout blueprint.
     * @param[in] ret_type The function's return type.
     * @param[in] arg_types Array of argument types.
     * @param[in] num_args Total number of arguments.
     * @param[in] num_fixed_args Number of non-variadic arguments.
     * @param[in] target_fn The target function address.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*prepare_forward_call_frame)(infix_arena_t * arena,
                                               infix_call_frame_layout ** out_layout,
                                               infix_type * ret_type,
                                               infix_type ** arg_types,
                                               size_t num_args,
                                               size_t num_fixed_args,
                                               void * target_fn);
    /**
     * @brief Generates the function prologue (stack setup, saving registers).
     * @param[in,out] buf The code buffer to append machine code to.
     * @param[in] layout The layout blueprint from the previous step.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*generate_forward_prologue)(code_buffer * buf, infix_call_frame_layout * layout);
    /**
     * @brief Generates code to move arguments from the `void**` array into registers and/or the stack.
     * @param[in,out] buf The code buffer.
     * @param[in] layout The layout blueprint.
     * @param[in] arg_types The array of argument types.
     * @param[in] num_args Total number of arguments.
     * @param[in] num_fixed_args Number of fixed arguments.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*generate_forward_argument_moves)(code_buffer * buf,
                                                    infix_call_frame_layout * layout,
                                                    infix_type ** arg_types,
                                                    size_t num_args,
                                                    size_t num_fixed_args);
    /**
     * @brief Generates the `call` instruction to the target function.
     * @param[in,out] buf The code buffer.
     * @param[in] layout The layout blueprint.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*generate_forward_call_instruction)(code_buffer * buf, infix_call_frame_layout * layout);
    /**
     * @brief Generates the function epilogue (handling return value, restoring stack, returning).
     * @param[in,out] buf The code buffer.
     * @param[in] layout The layout blueprint.
     * @param[in] ret_type The function's return type.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*generate_forward_epilogue)(code_buffer * buf,
                                              infix_call_frame_layout * layout,
                                              infix_type * ret_type);
} infix_forward_abi_spec;
/**
 * @brief Defines the ABI-specific implementation interface for reverse trampolines.
 * @details This v-table defines the contract for generating the JIT stub for a
 * reverse call (callback). The stub's primary job is to receive arguments in
 * native ABI format, marshal them into a generic `void**` array, and call the
 * universal C dispatcher.
 */
typedef struct {
    /**
     * @brief Analyzes a function signature to create a layout for the reverse call stub's stack frame.
     * @param[in] arena The temporary arena for allocations.
     * @param[out] out_layout Receives the newly created layout blueprint.
     * @param[in] context The reverse trampoline context, containing all type info.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*prepare_reverse_call_frame)(infix_arena_t * arena,
                                               infix_reverse_call_frame_layout ** out_layout,
                                               infix_reverse_t * context);
    /**
     * @brief Generates the reverse stub's prologue (stack setup).
     * @param[in,out] buf The code buffer.
     * @param[in] layout The layout blueprint.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*generate_reverse_prologue)(code_buffer * buf, infix_reverse_call_frame_layout * layout);
    /**
     * @brief Generates code to marshal arguments from their native locations (registers/stack) into a `void**` array.
     * @param[in,out] buf The code buffer.
     * @param[in] layout The layout blueprint.
     * @param[in] context The reverse context.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*generate_reverse_argument_marshalling)(code_buffer * buf,
                                                          infix_reverse_call_frame_layout * layout,
                                                          infix_reverse_t * context);
    /**
     * @brief Generates the call to the universal C dispatcher (`infix_internal_dispatch_callback_fn_impl`).
     * @param[in,out] buf The code buffer.
     * @param[in] layout The layout blueprint.
     * @param[in] context The reverse context.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*generate_reverse_dispatcher_call)(code_buffer * buf,
                                                     infix_reverse_call_frame_layout * layout,
                                                     infix_reverse_t * context);
    /**
     * @brief Generates the reverse stub's epilogue (handling return value, restoring stack, returning).
     * @param[in,out] buf The code buffer.
     * @param[in] layout The layout blueprint.
     * @param[in] context The reverse context.
     * @return `INFIX_SUCCESS` on success.
     */
    infix_status (*generate_reverse_epilogue)(code_buffer * buf,
                                              infix_reverse_call_frame_layout * layout,
                                              infix_reverse_t * context);
} infix_reverse_abi_spec;

/**
 * @struct infix_direct_arg_layout
 * @brief Internal layout information for a single argument in a direct marshalling trampoline.
 *
 * This struct combines the ABI location information with pointers to the type and
 * handler information needed by the JIT emitters.
 */
typedef struct {
    infix_arg_location location;                 ///< The physical location (register/stack) of the argument.
    const infix_type * type;                     ///< The `infix_type` of this argument.
    const infix_direct_arg_handler_t * handler;  ///< Pointer to the user-provided handler struct for this argument.
} infix_direct_arg_layout;

/**
 * @struct infix_direct_call_frame_layout
 * @brief A complete layout blueprint for a direct marshalling forward call frame.
 *
 * This structure serves as the plan for the JIT engine, detailing every register,
 * stack slot, and marshaller/write-back call needed to execute a direct FFI call.
 */
typedef struct {
    size_t total_stack_alloc;        ///< Total bytes to allocate on the stack for arguments and ABI-required space.
    size_t num_args;                 ///< The total number of arguments.
    void * target_fn;                ///< The target C function address.
    bool return_value_in_memory;     ///< `true` if the return value uses a hidden pointer argument.
    infix_direct_arg_layout * args;  ///< An array of layout info for each argument.
} infix_direct_call_frame_layout;

/**
 * @brief Defines the ABI-specific implementation interface for direct marshalling forward trampolines.
 *
 * This v-table defines the contract for generating a high-performance, direct-marshalling
 * trampoline. It is parallel to `infix_forward_abi_spec`.
 */
typedef struct {
    /** @brief Analyzes a function signature to create a complete direct call frame layout.     */
    infix_status (*prepare_direct_forward_call_frame)(infix_arena_t * arena,
                                                      infix_direct_call_frame_layout ** out_layout,
                                                      infix_type * ret_type,
                                                      infix_type ** arg_types,
                                                      size_t num_args,
                                                      infix_direct_arg_handler_t * handlers,
                                                      void * target_fn);
    /** @brief Generates the function prologue (stack setup, saving registers).   */
    infix_status (*generate_direct_forward_prologue)(code_buffer * buf, infix_direct_call_frame_layout * layout);
    /** @brief Generates code to call marshallers and move arguments into their native locations.     */
    infix_status (*generate_direct_forward_argument_moves)(code_buffer * buf, infix_direct_call_frame_layout * layout);
    /** @brief Generates the `call` instruction to the target function. */
    infix_status (*generate_direct_forward_call_instruction)(code_buffer * buf,
                                                             infix_direct_call_frame_layout * layout);
    /** @brief Generates the function epilogue (handling return value, calling write-back handlers, returning).   */
    infix_status (*generate_direct_forward_epilogue)(code_buffer * buf,
                                                     infix_direct_call_frame_layout * layout,
                                                     infix_type * ret_type);

} infix_direct_forward_abi_spec;

// Internal Function Prototypes (Shared across modules)
/**
 * @brief Sets the thread-local error state with detailed information.
 * @details Located in `src/core/error.c`, this function is the primary mechanism
 * for reporting errors from within the library. It populates the thread-local
 * `g_infix_last_error` struct. For parser errors, it generates a rich diagnostic
 * message with a code snippet.
 * @param category The general category of the error.
 * @param code The specific error code.
 * @param position For parser errors, the byte offset into the signature string where the error occurred.
 */
INFIX_INTERNAL void _infix_set_error(infix_error_category_t category, infix_error_code_t code, size_t position);
/**
 * @brief Sets the thread-local error state for a system-level error.
 * @details Located in `src/core/error.c`, this is used for errors originating from
 * the operating system, such as `dlopen` or `mmap` failures.
 * @param category The general category of the error.
 * @param code The `infix` error code that corresponds to the failure.
 * @param system_code The OS-specific error code (e.g., from `errno` or `GetLastError`).
 * @param msg An optional custom message from the OS (e.g., from `dlerror`).
 */
INFIX_INTERNAL void _infix_set_system_error(infix_error_category_t category,
                                            infix_error_code_t code,
                                            long system_code,
                                            const char * msg);
/**
 * @brief Clears the thread-local error state.
 * @details Located in `src/core/error.c`. This is called at the beginning of every public
 * API function to ensure that a prior error from an unrelated call is not accidentally returned.
 */
INFIX_INTERNAL void _infix_clear_error(void);
/**
 * @brief Recalculates the layout of a fully resolved type graph.
 * @details Located in `src/core/types.c`. This is the "Layout" stage of the data pipeline.
 * It recursively walks a type graph and computes the final `size`, `alignment`, and
 * member `offset` fields for all aggregate types. It must only be called on a fully
 * resolved graph.
 * @param[in,out] type The root of the type graph to recalculate. The graph is modified in-place.
 */
INFIX_INTERNAL void _infix_type_recalculate_layout(infix_type * type);
/**
 * @brief Resolves all named type references in a type graph in-place.
 * @details Located in `src/core/type_registry.c`. This is the "Resolve" stage of the
 * data pipeline. It traverses a type graph and replaces all `INFIX_TYPE_NAMED_REFERENCE`
 * nodes (`@Name`) with direct pointers to the canonical `infix_type` objects from the registry.
 * @param[in,out] type_ptr A pointer to the root of the type graph to resolve. The pointer may be changed.
 * @param[in] registry The registry to use for lookups.
 * @return `INFIX_SUCCESS` on success, or an error if a name cannot be resolved.
 */
INFIX_INTERNAL c23_nodiscard infix_status _infix_resolve_type_graph_inplace(infix_type ** type_ptr,
                                                                            infix_registry_t * registry);
/**
 * @brief The internal core of the signature parser.
 * @details Located in `src/core/signature.c`. This is the "Parse" stage of the data pipeline.
 * It takes a signature string and produces a raw, unresolved `infix_type` graph in a new,
 * temporary arena. It does not perform any copying, resolution, or layout calculation.
 * @param[out] out_type On success, receives the parsed type graph.
 * @param[out] out_arena On success, receives the temporary arena holding the graph.
 * @param[in] signature The signature string to parse.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_INTERNAL c23_nodiscard infix_status _infix_parse_type_internal(infix_type **, infix_arena_t **, const char *);
/**
 * @brief An internal-only function to serialize a type's body without its registered name.
 * @details Located in `src/core/signature.c`. Unlike `infix_type_print`, which will
 * print `@Name` for a named struct, this function will always print the full `{...}`
 * body. This is essential for `infix_registry_print` to function correctly.
 * @param[out] buffer The output buffer.
 * @param[in] buffer_size The size of the buffer.
 * @param[in] type The type to print.
 * @param[in] dialect The output format dialect.
 * @return `INFIX_SUCCESS` on success.
 */
INFIX_INTERNAL c23_nodiscard infix_status _infix_type_print_body_only(char *,
                                                                      size_t,
                                                                      const infix_type *,
                                                                      infix_print_dialect_t);
/**
 * @brief Performs a deep copy of a type graph into a destination arena.
 * @details Located in `src/core/types.c`. This is the "Copy" stage of the data pipeline,
 * crucial for creating self-contained trampoline objects and ensuring memory safety. It uses
 * memoization to correctly handle cycles and shared type objects.
 * @param[in] dest_arena The destination arena for the new type graph.
 * @param[in] src_type The source type graph to copy.
 * @return A pointer to the newly created copy in `dest_arena`, or `nullptr` on failure.
 */
INFIX_INTERNAL infix_type * _copy_type_graph_to_arena(infix_arena_t *, const infix_type *);
/**
 * @brief Estimates the total memory required to deep-copy a complete type graph.
 * @details Located in `src/core/types.c`. This function recursively walks the entire
 * type graph, including all nested aggregates and function arguments, to calculate
 * the exact size needed for an arena that will hold a deep copy.
 * @param[in] temp_arena A temporary arena used for the estimator's own bookkeeping (e.g., cycle detection).
 * @param[in] type The root of the type graph to estimate.
 * @return The estimated size in bytes required for a deep copy.
 */
INFIX_INTERNAL size_t _infix_estimate_graph_size(infix_arena_t * temp_arena, const infix_type * type);
/**
 * @brief Gets the ABI v-table for forward calls for the current platform.
 * @details See `src/jit/trampoline.c`. This function is the entry point to the ABI
 * abstraction layer, returning the correct set of function pointers based on the
 * compile-time ABI detection.
 * @return A pointer to the active `infix_forward_abi_spec`.
 */
INFIX_INTERNAL const infix_forward_abi_spec * get_current_forward_abi_spec(void);
/**
 * @brief Gets the ABI v-table for reverse calls for the current platform.
 * @details See `src/jit/trampoline.c`. This function mirrors `get_current_forward_abi_spec`
 * for reverse call trampolines.
 * @return A pointer to the active `infix_reverse_abi_spec`.
 */
INFIX_INTERNAL const infix_reverse_abi_spec * get_current_reverse_abi_spec(void);
/**
 * @brief Gets the ABI v-table for direct marshalling forward calls for the current platform.
 * @return A pointer to the active `infix_direct_forward_abi_spec`.
 */
INFIX_INTERNAL const infix_direct_forward_abi_spec * get_current_direct_forward_abi_spec(void);
/**
 * @brief Initializes a code buffer for JIT code generation.
 * @details See `src/jit/trampoline.c`. Associates the buffer with a temporary
 * arena and sets its initial capacity.
 * @param[out] buf A pointer to the `code_buffer` to initialize.
 * @param[in] arena The temporary arena to use for the buffer's memory.
 */
INFIX_INTERNAL void code_buffer_init(code_buffer * buf, infix_arena_t * arena);
/**
 * @brief Appends raw bytes to a code buffer, reallocating within its arena if necessary.
 * @details See `src/jit/trampoline.c`. This is the fundamental operation for building
 * the machine code. If the buffer runs out of space, it is grown exponentially.
 * @param[in,out] buf The code buffer to append to.
 * @param[in] data A pointer to the bytes to append.
 * @param[in] len The number of bytes to append.
 */
INFIX_INTERNAL void code_buffer_append(code_buffer * buf, const void * data, size_t len);
/**
 * @brief A convenience wrapper to append a single byte to a code buffer.
 * @param[in,out] buf The code buffer.
 * @param[in] byte The byte to append.
 */
INFIX_INTERNAL void emit_byte(code_buffer * buf, uint8_t byte);
/**
 * @brief A convenience wrapper to append a 32-bit integer (little-endian) to a code buffer.
 * @param[in,out] buf The code buffer.
 * @param[in] value The 32-bit integer to append.
 */
INFIX_INTERNAL void emit_int32(code_buffer * buf, int32_t value);
/**
 * @brief A convenience wrapper to append a 64-bit integer (little-endian) to a code buffer.
 * @param[in,out] buf The code buffer.
 * @param[in] value The 64-bit integer to append.
 */
INFIX_INTERNAL void emit_int64(code_buffer * buf, int64_t value);
/**
 * @brief Allocates a block of executable memory using the platform's W^X strategy.
 * @details Located in `src/jit/executor.c`. This is a platform-specific function
 * that abstracts `VirtualAlloc`, `mmap` with `MAP_JIT`, or `shm_open` with dual-mapping.
 * @param size The number of bytes to allocate.
 * @return An `infix_executable_t` handle containing pointers to the allocated memory.
 */
INFIX_INTERNAL c23_nodiscard infix_executable_t infix_executable_alloc(size_t size);
/**
 * @brief Frees a block of executable memory and applies guard pages to prevent use-after-free.
 * @details Located in `src/jit/executor.c`. Before freeing, it attempts to change
 * the memory's protection to be inaccessible, causing an immediate crash on a UAF.
 * @param exec The handle to the memory block to free.
 */
INFIX_INTERNAL void infix_executable_free(infix_executable_t exec);
/**
 * @brief Makes a block of JIT memory executable, completing the W^X process.
 * @details Located in `src/jit/executor.c`. For single-map platforms, this calls
 * `VirtualProtect` or `mprotect`. For dual-map platforms, this is a no-op. It
 * also handles instruction cache flushing on relevant architectures like AArch64.
 * @param exec The handle to the memory block to make executable.
 * @return `true` on success, `false` on failure.
 */
INFIX_INTERNAL c23_nodiscard bool infix_executable_make_executable(infix_executable_t * exec);
/**
 * @brief Allocates a block of standard memory for later protection.
 * @details Located in `src/jit/executor.c`. This is used to allocate the memory
 * for an `infix_reverse_t` context before it is made read-only.
 * @param size The number of bytes to allocate.
 * @return An `infix_protected_t` handle.
 */
INFIX_INTERNAL c23_nodiscard infix_protected_t infix_protected_alloc(size_t size);
/**
 * @brief Frees a block of protected memory.
 * @details Located in `src/jit/executor.c`.
 * @param prot The memory block to free.
 */
INFIX_INTERNAL void infix_protected_free(infix_protected_t prot);
/**
 * @brief Makes a block of memory read-only for security hardening.
 * @details Located in `src/jit/executor.c`. This is called on the `infix_reverse_t`
 * context after it has been fully initialized.
 * @param prot The memory block to make read-only.
 * @return `true` on success, `false` on failure.
 */
INFIX_INTERNAL c23_nodiscard bool infix_protected_make_readonly(infix_protected_t prot);
/**
 * @brief The universal C entry point for all reverse call trampolines.
 * @details Located in `src/jit/executor.c`, this function is called by the JIT-compiled
 * stub. It receives the marshalled arguments and dispatches the call to either
 * the type-safe callback (via a cached forward trampoline) or the generic closure handler.
 * @param[in] context The `infix_reverse_t` context for this call.
 * @param[out] return_value_ptr A pointer to the stack buffer for the return value.
 * @param[in] args_array A pointer to the `void**` array of argument pointers.
 */
INFIX_INTERNAL void infix_internal_dispatch_callback_fn_impl(infix_reverse_t * context,
                                                             void * return_value_ptr,
                                                             void ** args_array);
// Utility Macros & Inlines
/** @brief Appends a sequence of bytes (e.g., an instruction opcode) to a code buffer. */
#define EMIT_BYTES(buf, ...)                             \
    do {                                                 \
        const uint8_t bytes[] = {__VA_ARGS__};           \
        code_buffer_append((buf), bytes, sizeof(bytes)); \
    } while (0)
/**
 * @brief Aligns a value up to the next multiple of a power-of-two alignment.
 * @param value The value to align.
 * @param alignment The alignment boundary (must be a power of two).
 * @return The aligned value.
 */
static inline size_t _infix_align_up(size_t value, size_t alignment) {
    return (value + alignment - 1) & ~(alignment - 1);
}
/**
 * @brief A fast inline check to determine if an `infix_type` is a `float`.
 * @param type The type to check.
 * @return `true` if the type is a float primitive.
 */
static inline bool is_float(const infix_type * type) {
    return type->category == INFIX_TYPE_PRIMITIVE && type->meta.primitive_id == INFIX_PRIMITIVE_FLOAT;
}
/**
 * @brief A fast inline check to determine if an `infix_type` is a `double`.
 * @param type The type to check.
 * @return `true` if the type is a double primitive.
 */
static inline bool is_double(const infix_type * type) {
    return type->category == INFIX_TYPE_PRIMITIVE && type->meta.primitive_id == INFIX_PRIMITIVE_DOUBLE;
}
/**
 * @brief A fast inline check to determine if an `infix_type` is a `long double`.
 * @param type The type to check.
 * @return `true` if the type is a long double primitive.
 */
static inline bool is_long_double(const infix_type * type) {
    return type->category == INFIX_TYPE_PRIMITIVE && type->meta.primitive_id == INFIX_PRIMITIVE_LONG_DOUBLE;
}
// Include architecture-specific emitter prototypes for internal use by the JIT engine.
#if defined(INFIX_ABI_SYSV_X64) || defined(INFIX_ABI_WINDOWS_X64)
#include "arch/x64/abi_x64_emitters.h"
#elif defined(INFIX_ABI_AAPCS64)
#include "arch/aarch64/abi_arm64_emitters.h"
#endif
/** @endinternal */
