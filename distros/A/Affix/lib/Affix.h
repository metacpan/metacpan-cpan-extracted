#pragma once

#define DEBUG 0

// Disables the implicit 'pTHX_' context pointer argument, which is good practice for
// modern Perl XS code that uses the 'aTHX_' macro explicitly.
#define PERL_NO_GET_CONTEXT 1
#include <EXTERN.h>
#include <perl.h>
// Disables Perl's internal locking mechanisms for certain structures.
// This is often used when the XS module manages its own thread safety.
#define NO_XSLOCKS
#include <XSUB.h>
// Redirect infix's internal memory allocation to use Perl's safe allocation functions.
// This ensures all memory is tracked by Perl's memory manager, which is safer and
// helps with leak detection tools like valgrind.
#define infix_malloc safemalloc
#define infix_calloc safecalloc
#define infix_free safefree
#define infix_realloc saferealloc

#include "common/infix_internals.h"
#include <infix/infix.h>
// This structure defines the thread-local storage for our module. Under ithreads,
// each Perl thread will get its own private instance of this struct.
typedef struct {
    /// A per-thread hash table to store loaded libraries.
    /// Maps library path -> LibRegistryEntry*.
    /// This prevents reloading the same .so/.dll and manages its lifecycle.
    HV * lib_registry;
    // A per-thread hash table to cache callback trampolines, preventing re-creation and leaks.
    // Maps the memory address of a Perl CV* to its corresponding Implicit_Callback_Magic* struct.
    HV * callback_registry;
    /// Type alias for an infix type registry. Represents a collection of named types.
    infix_registry_t * registry;
    /// // Smart enums
    HV * enum_registry;
} my_cxt_t;
START_MY_CXT;
// Helper macro to fetch a value from a hash if it exists, otherwise return a default.
#define hv_existsor(hv, key, _or) hv_exists(hv, key, strlen(key)) ? *hv_fetch(hv, key, strlen(key), 0) : _or
// Macros to handle passing the Perl interpreter context ('THX') explicitly,
// which is necessary for thread-safe code.
#ifdef MULTIPLICITY
#define storeTHX(var) (var) = aTHX
#define dTHXfield(var) tTHX var;
#else
#define storeTHX(var) dNOOP
#define dTHXfield(var)
#endif


// Forward-declare the primary structures.
typedef struct Affix Affix;
typedef struct Affix_Backend Affix_Backend;
typedef struct Affix_Plan_Step Affix_Plan_Step;
typedef struct OutParamInfo OutParamInfo;
/**
 * The single, homogeneous function pointer signature for all steps in the execution plan.
 * @param pTHX_ The Perl interpreter context.
 * @param affix The main Affix context object.
 * @param step A pointer to the current plan step, containing its pre-calculated data.
 * @param perl_stack_frame A pointer to the base of the Perl stack frame (&ST(0)).
 * @param c_args The array of pointers to be passed to the C function.
 * @param ret_buffer A pointer to the memory allocated for the C function's return value.
 */
typedef void (*Affix_Step_Executor)(pTHX_ Affix * affix,
                                    Affix_Plan_Step * step,
                                    SV ** perl_stack_frame,
                                    void * args_buffer,
                                    void ** c_args,
                                    void * ret_buffer);
/// Function pointer type for a "pull" operation: marshalling from C (void*) to Perl (SV).
typedef void (*Affix_Pull)(pTHX_ Affix * affix, SV *, const infix_type *, void *);
/// Function pointer type for a "push" operation: marshalling from Perl (SV) to C (void*).
typedef void (*Affix_Push_Handler)(pTHX_ Affix * affix, SV *, void *);
/**
 * Function pointer for a specialized out-parameter write-back handler.
 * By pre-resolving this function, we avoid conditional logic in the hot path.
 * @param pTHX_ The Perl interpreter context.
 * @param affix The main Affix context object.
 * @param info A pointer to the OutParamInfo struct for this parameter.
 * @param perl_sv The referenced SV* to be modified (e.g., the scalar backing `$$foo`).
 * @param c_arg_ptr The pointer from the c_args array (e.g., `T**` for a `T*` out-param).
 */
typedef void (*Affix_Out_Param_Writer)(pTHX_ Affix * affix, const OutParamInfo * info, SV * perl_sv, void * c_arg_ptr);
/// Stores the pre-calculated information needed to write back an "out" parameter.
struct OutParamInfo {
    size_t perl_stack_index;          // Index of the SV* in the perl_stack_frame
    const infix_type * pointee_type;  // The type of the data pointed to (e.g., 'int' for 'int*')
    Affix_Out_Param_Writer writer;    // Pre-resolved handler to perform the write-back.
};
/// The data payload for a single step in the execution plan.
typedef struct {
    const infix_type * type;  // Type info for this step (arg or ret).
    size_t index;             // Index into perl_stack_frame for args, or c_args for out-params.
    Affix_Pull pull_handler;  // Pre-resolved pull handler for the return step.
    size_t c_arg_offset;      // Pre-calculated offset into the C arguments buffer.
} Affix_Step_Data;

typedef enum {
    // argument marshalling opcodes
    OP_PUSH_BOOL,
    OP_PUSH_SINT8,
    OP_PUSH_UINT8,
    OP_PUSH_SINT16,
    OP_PUSH_UINT16,
    OP_PUSH_SINT32,
    OP_PUSH_UINT32,
    OP_PUSH_SINT64,
    OP_PUSH_UINT64,
    OP_PUSH_FLOAT,
    OP_PUSH_DOUBLE,
    OP_PUSH_LONGDOUBLE,
    OP_PUSH_SINT128,
    OP_PUSH_UINT128,
    OP_PUSH_POINTER,    // fallback for pins/refs
    OP_PUSH_PTR_CHAR,   // char* optimization
    OP_PUSH_PTR_WCHAR,  // wchar_t* optimization
    OP_PUSH_SV,         // SV*
    OP_PUSH_STRUCT,     // aggregates ...
    OP_PUSH_UNION,
    OP_PUSH_ARRAY,
    OP_PUSH_CALLBACK,
    OP_PUSH_ENUM,
    OP_PUSH_COMPLEX,
    OP_PUSH_VECTOR,  // optimized vector
    OP_DONE,         // sentinel to stop the threaded dispatcher
    OP_RET_VOID,     // retval marshalling opcodes ...
    OP_RET_BOOL,
    OP_RET_SINT8,
    OP_RET_UINT8,
    OP_RET_SINT16,
    OP_RET_UINT16,
    OP_RET_SINT32,
    OP_RET_UINT32,
    OP_RET_SINT64,
    OP_RET_UINT64,
    OP_RET_FLOAT,
    OP_RET_DOUBLE,
    OP_RET_LONGDOUBLE,
    OP_RET_SINT128,
    OP_RET_UINT128,
    OP_RET_PTR,        // Generic pin return
    OP_RET_PTR_CHAR,   // Returns Perl String (UTF8)
    OP_RET_PTR_WCHAR,  // Returns Perl String (from Wide)
    OP_RET_SV,         // Returns SV* directly
    OP_RET_CUSTOM      // Complex types (structs, arrays)
} Affix_Opcode;

/// A single step in the pre-compiled execution plan.
struct Affix_Plan_Step {
    Affix_Step_Executor executor;  // Function pointer to the executor for this step.
    Affix_Opcode opcode;           // The instruction for the VM
    Affix_Step_Data data;          // Pre-calculated data needed by the executor.
};
/// Represents a forward FFI call (a Perl sub that calls a C function).
/// This struct holds the pre-compiled execution plan and is attached to the generated XS subroutine.
struct Affix {
    infix_forward_t * infix;       ///< Handle to the infix trampoline and type info.
    infix_arena_t * args_arena;    ///< Fast memory allocator for arguments during a call.
    infix_arena_t * ret_arena;     ///< Fast memory allocator for return value during a call.
    infix_cif_func cif;            ///< A direct function pointer to the JIT-compiled trampoline code.
    infix_library_t * lib_handle;  ///< If affix() loaded a library itself, stores the handle for cleanup.
    SV * return_sv;                ///< Pre-allocated, reusable SV to hold the return value.
    Affix_Plan_Step * plan;        ///< The linear array of operations (the "execution plan").
    size_t plan_length;            ///< The total number of steps in the plan.
    size_t num_args;               ///< Cached number of arguments for faster access.
    size_t total_args_size;        ///< Pre-calculated total size of the C arguments buffer.
    // Pre-compiled plan for handling "out" parameters after the C call.
    OutParamInfo * out_param_info;
    size_t num_out_params;
    const infix_type * ret_type;
    Affix_Pull ret_pull_handler;  ///< Cached handler for marshalling the return value.
    Affix_Opcode ret_opcode;      ///< Optimized return opcode.
    void ** c_args;

    /* Reconstruction info for threading/cloning */
    char * sig_str;
    char * sym_name;
    void * target_addr;
};
/// Represents an Affix::Pin object, a blessed Perl scalar that wraps a raw C pointer.
typedef struct {
    void * pointer;              ///< The raw C memory address.
    const infix_type * type;     ///< Infix's description of the data type at 'pointer'. Used for dereferencing.
    infix_arena_t * type_arena;  ///< Memory arena that owns the 'type' structure.
    bool managed;                ///< If true, Perl owns the 'pointer' and will safefree() it on DESTROY.
    UV ref_count;                ///< Refcount to prevent premature freeing when SVs are copied.
    size_t size;                 ///< Size of malloc'd void pointers.
} Affix_Pin;
/// Holds the necessary data for a callback, specifically the Perl subroutine to call.
typedef struct {
    SV * coderef_rv;  ///< A reference (RV) to the Perl coderef. We hold this to keep it alive.
    dTHXfield(perl)   ///< The thread context in which the callback was created.
} Affix_Callback_Data;
/// Internal struct holding the C resources that are magically attached
///        to a user's coderef (CV*) when it is first used as a callback.
typedef struct {
    infix_reverse_t * reverse_ctx;  ///< Handle to the infix reverse-call trampoline.
} Implicit_Callback_Magic;
/// An entry in the thread-local library registry hash.
typedef struct {
    infix_library_t * lib;  ///< The handle to the opened library.
    UV ref_count;           ///< Reference count. The library is closed only when this reaches 0.
} LibRegistryEntry;

// Struct for the Direct Marshalling (aka "bundle") backend.
/// Represents a forward FFI call created with the high-performance direct marshalling API.
struct Affix_Backend {
    infix_forward_t * infix;       ///< Handle to the infix trampoline and type info.
    infix_direct_cif_func cif;     ///< Direct pointer to the specialized JIT code.
    infix_library_t * lib_handle;  ///< Handle for library cleanup.
    const infix_type * ret_type;   ///< Cached return type info.
    Affix_Pull pull_handler;       ///< Pre-resolved handler for marshalling the return value.
    Affix_Opcode ret_opcode;       ///< Optimized return opcode.
    size_t num_args;               ///< Cached number of arguments.
};

// Trigger function for the experimental backend (shh!)
extern void Affix_trigger_backend(pTHX_ CV *);

// Main execution trigger
extern void Affix_trigger_stack(pTHX_ CV *);
extern void Affix_trigger_arena(pTHX_ CV *);

// Marshalling (Perl -> C)
void sv2ptr(pTHX_ Affix * affix, SV * perl_sv, void * c_ptr, const infix_type * type);
void push_struct(pTHX_ Affix * affix, const infix_type * type, SV * sv, void * p);
void push_array(pTHX_ Affix * affix, const infix_type * type, SV * sv, void * p);
void push_reverse_trampoline(pTHX_ Affix * affix, const infix_type * type, SV * sv, void * p);

// Marshalling (Perl <- C)
void ptr2sv(pTHX_ Affix * affix, void * c_ptr, SV * perl_sv, const infix_type * type);
void _populate_hv_from_c_struct(pTHX_ Affix * affix, HV * hv, const infix_type * type, void * p);

// Handler resolution
Affix_Step_Executor get_plan_step_executor(const infix_type * type);
Affix_Pull get_pull_handler(pTHX_ const infix_type * type);
Affix_Out_Param_Writer get_out_param_writer(const infix_type * type);

// Pin management
void _pin_sv(pTHX_ SV * sv, const infix_type * type, void * pointer, bool managed);
bool is_pin(pTHX_ SV * sv);
Affix_Pin * _get_pin_from_sv(pTHX_ SV * sv);

// Reverse trampolines
void _affix_callback_handler_entry(infix_context_t *, void *, void **);

// Misc.
void _export_function(pTHX_ HV *, const char *, const char *);

// XS Bootstrap
void boot_Affix(pTHX_ CV *);

// 'Portable' XS MACROS
#ifdef newXS_flags
#define newXSproto_portable(name, c_impl, file, proto) newXS_flags(name, c_impl, file, proto, 0)
#else
#define newXSproto_portable(name, c_impl, file, proto) \
    (PL_Sv = (SV *)newXS(name, c_impl, file), sv_setpv(PL_Sv, proto), (CV *)PL_Sv)
#endif
#define newXS_deffile(a, b) Perl_newXS_deffile(aTHX_ a, b)
#define export_function(package, what, tag) \
    _export_function(aTHX_ get_hv(form("%s::EXPORT_TAGS", package), GV_ADD), what, tag)

// Debugging Macros
#if DEBUG > 1
#define PING warn("Ping at %s line %d", __FILE__, __LINE__);
#else
#define PING
#endif
#define DumpHex(addr, len) _DumpHex(aTHX_ addr, len, __FILE__, __LINE__)
void _DumpHex(pTHX_ const void *, size_t, const char *, int);
#define DD(scalar) _DD(aTHX_ scalar, __FILE__, __LINE__)
void _DD(pTHX_ SV *, const char *, int);

#include <string.h>
#include <wchar.h>
