/*
 * clay_perl.h - Shared types and prototypes for the Clay::XS XS binding.
 *
 * This header is included by the XS file and by every helper .c file under
 * src/. It pulls in Perl's API headers and the Clay v0.14 header (without
 * its implementation - exactly one file defines CLAY_IMPLEMENTATION).
 *
 * Conventions used throughout:
 *
 *   - clay_perl_*   : functions implemented in this binding
 *   - SV/HV/AV      : standard Perl reference-counted value types
 *
 * Memory ownership rules (read these before touching the helpers):
 *
 *   - Text strings handed to Clay (Clay__OpenTextElement) are copied into
 *     the per-context string arena, a list of chunks that never move or
 *     shrink while Clay may still read them. Clay keeps the text pointer
 *     of a text element until the end of the following frame (an element
 *     can start an exit transition one frame after its last declaration)
 *     and for as long as an exit transition of its element is running.
 *     The arena therefore retains the previous frame's chunks and every
 *     older chunk an exiting element still points into.
 *     isStaticallyAllocated is always false.
 *
 *   - Element id strings (Clay_ElementId.stringId) are interned in a
 *     per-context hash. Clay copies element ids into its persistent hash
 *     map, into pointerOverIds and into the id strings of exiting
 *     elements, so the interned buffers live until the id has been unused
 *     for two completed frames, no exiting element carries it and it is
 *     not part of the current pointer-over list.
 *
 *   - Callback and userdata slots hold private copies (newSVsv) of the
 *     values the caller passed, one refcount each. Replacing a slot
 *     copies the new value before releasing the old one.
 *
 *   - hover_callbacks maps element ids (decimal strings) to plain
 *     arrayrefs [coderef, userdata, stamp]; the HV owns one refcount
 *     per entry.
 *
 *   - clay_arena_memory is a malloc()-ed buffer owned by the context. It
 *     is freed on context DESTROY. Clay itself never frees it.
 */

#ifndef CLAY_PERL_H
#define CLAY_PERL_H

/*
 * Every helper takes the interpreter explicitly (pTHX_ / aTHX_), so the
 * cheaper PERL_NO_GET_CONTEXT calling convention is used throughout.
 * Trampolines called by Clay (which knows nothing about Perl) fetch the
 * interpreter with dTHX.
 *
 * NO_XSLOCKS keeps XSUB.h from turning malloc / realloc / free into
 * Perl's per-interpreter allocator on Windows (PERL_IMPLICIT_SYS); the
 * binding's own buffers use the C library's allocator on every platform.
 */
#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "clay/clay.h"
#include "clay_impl_helpers.h"

#include <stddef.h>
#include <stdint.h>

/* Upstream implements Clay_SetExternalScrollHandlingEnabled but does not
 * declare it in the public API section of clay.h. */
void Clay_SetExternalScrollHandlingEnabled(bool enabled);

/* The interpreter a context belongs to. Contexts must not be touched
 * from another interpreter (ithreads): Clay keeps one process-wide
 * current-context pointer. */
#ifdef MULTIPLICITY
#  define CLAY_PERL_THIS_INTERPRETER ((void *) aTHX)
#else
#  define CLAY_PERL_THIS_INTERPRETER ((void *) NULL)
#endif

/* ---------------------------------------------------------------------------
 * Per-frame string arena.
 *
 * A singly linked list of chunks. Copies append to the head chunk of the
 * current frame; when it is full a new chunk of max(needed, 2 x previous)
 * bytes is pushed. Chunks are never reallocated or freed while Clay may
 * read from them (the frame module applies the lifetime rule, see
 * src/clay_perl_context.c).
 * ------------------------------------------------------------------------ */

typedef struct clay_perl_arena_chunk {
    struct clay_perl_arena_chunk *next;
    size_t capacity;
    size_t used;
    char   bytes[1];
} clay_perl_arena_chunk;

typedef struct clay_perl_string_arena {
    clay_perl_arena_chunk *current;   /* chunks written during this frame */
    clay_perl_arena_chunk *retained;  /* chunks of earlier frames Clay may still read */
    size_t frame_bytes;               /* bytes copied during this frame */
} clay_perl_string_arena;

/* ---------------------------------------------------------------------------
 * Where the context is in Clay's frame cycle. Clay's own layout tree is
 * only consistent in LAYOUT_COMPLETE: Clay_BeginLayout throws the last
 * layout away, and the tree is half built until Clay_EndLayout.
 * ------------------------------------------------------------------------ */

typedef enum {
    /* No frame open; Clay holds the last completed layout (or none yet). */
    CLAY_PERL_LAYOUT_COMPLETE = 0,
    /* Between Clay_BeginLayout and Clay_EndLayout. */
    CLAY_PERL_LAYOUT_DECLARING
} clay_perl_layout_state;

/* ---------------------------------------------------------------------------
 * Per-Perl-context state.
 *
 * One of these is allocated per successful Clay_Initialize. The blessed
 * Clay::XS::Context object is a reference to a read-only scalar that
 * carries a pointer to this struct in private ext magic; every Perl
 * handle to the context shares that one referent, so DESTROY runs once.
 * ------------------------------------------------------------------------ */

/* ---------------------------------------------------------------------------
 * Callback kinds and slots.
 *
 * Every Perl callback Clay can reach has a kind; it selects how the
 * dispatcher parses the callback's result and, for the per-context kinds,
 * the context slot holding the callback. Kinds start at 1 so a zeroed
 * dispatch record names none.
 * ------------------------------------------------------------------------ */

typedef enum {
    CLAY_PERL_DISPATCH_MEASURE_TEXT = 1,
    CLAY_PERL_DISPATCH_ERROR_HANDLER,
    CLAY_PERL_DISPATCH_QUERY_SCROLL_OFFSET,
    CLAY_PERL_DISPATCH_HOVER,
    CLAY_PERL_DISPATCH_TRANSITION_HANDLER,
    CLAY_PERL_DISPATCH_TRANSITION_SET_INITIAL,
    CLAY_PERL_DISPATCH_TRANSITION_SET_FINAL,
    CLAY_PERL_DISPATCH_KIND_COUNT
} clay_perl_dispatch_kind;

/* A Perl callback and the userdata passed as its last argument; both are
 * private copies, NULL when unset. */
typedef struct clay_perl_callback {
    SV *code;
    SV *userdata;
} clay_perl_callback;

typedef struct clay_perl_context {
    /* Owning interpreter and the blessed referent (not ref-counted). */
    void *owner;
    SV   *referent;

    /* Underlying Clay state. */
    Clay_Context *clay_ctx;
    Clay_Arena    clay_arena;
    char         *clay_arena_memory;

    /* Element and measure-cache word counts Clay_Initialize sized the
     * arena for. Clay's persistent arrays keep these sizes, so a count
     * changed afterwards is unsafe until the next Clay_Initialize. */
    int32_t max_element_count;
    int32_t max_measure_text_cache_word_count;

    /* Frame state, written only by the frame module (clay_perl_frame_*)
     * and read by the wrapper guards: the frame state, the open/close
     * balance, and whether the innermost open element may still be
     * configured (only right after it was opened). */
    clay_perl_layout_state layout_state;
    int32_t  open_depth;
    bool     open_element_configurable;

    /* Frames that reached Clay_EndLayout. Interned ids and hover entries
     * are stamped with it when used, so a stamp names the frame being
     * declared and the sweeps count completed frames. */
    uint32_t completed_frames;

    /* Per-frame text copies and interned element id strings. */
    clay_perl_string_arena strings;
    HV *interned_ids;

    /* Held callback error: the first exception raised by a Perl
     * callback while Clay was running, re-thrown at the next safe point.
     * Later errors of the same period are only counted. */
    SV      *held_error;
    uint32_t suppressed_errors;
    bool     measure_cache_poisoned;

    /* Per-context callbacks, indexed by kind (set and freed through
     * clay_perl_callback_set / clay_perl_callbacks_free). The HOVER slot
     * stays empty: hover callbacks are per element (hover_callbacks).
     * Clay's transition callback signatures carry no element id (see the
     * handler / setInitialState / setFinalState calls in Clay_EndLayout),
     * so one handler set per context serves every transitioning element;
     * Clay_SetTransitionHandlers stores its userdata in all three
     * transition slots. */
    clay_perl_callback callbacks[CLAY_PERL_DISPATCH_KIND_COUNT];

    /* Per-element hover callbacks, keyed by element id (decimal string).
     * Each value is an arrayref [coderef, userdata, stamp]. */
    HV *hover_callbacks;
} clay_perl_context;

/* ---------------------------------------------------------------------------
 * Context lifecycle (src/clay_perl_context.c).
 * ------------------------------------------------------------------------ */

/* Allocates a context and its Clay arena. Returns NULL (after freeing
 * everything) when the arena cannot be allocated. */
clay_perl_context *clay_perl_context_new(pTHX_ size_t clay_arena_capacity);
void               clay_perl_context_free(pTHX_ clay_perl_context *self);

/* Creates the blessed Clay::XS::Context object for a new context and
 * records its referent. Returns a new (non-mortal) reference. */
SV *clay_perl_context_bless(pTHX_ clay_perl_context *self);

/* Returns a new (non-mortal) reference to the context's shared referent. */
SV *clay_perl_context_to_sv(pTHX_ clay_perl_context *self);

/* Recovers the context from a Clay::XS::Context object. Croaks "not a
 * live Clay::XS::Context" for copies, forgeries and destroyed contexts. */
clay_perl_context *clay_perl_context_from_sv(pTHX_ SV *sv);

/* Like clay_perl_context_from_sv but never croaks. Returns NULL for any
 * SV that does not carry a live context, and the magic slot through
 * *magic_out when it exists (so DESTROY can clear it). */
clay_perl_context *clay_perl_context_peek(pTHX_ SV *sv, MAGIC **magic_out);

/* ---------------------------------------------------------------------------
 * The frame module (src/clay_perl_context.c): the frame state machine,
 * the open/close bookkeeping and the retention of everything Clay keeps
 * pointers to across frames. Call only while ctx is Clay's current
 * context.
 * ------------------------------------------------------------------------ */

/* Clay_BeginLayout: finishes a frame left DECLARING first (closes its
 * open elements and calls Clay_EndLayout, discarding the commands; the
 * frame counts as completed; an exit a callback called then is
 * re-issued), then re-throws a held error left by it without beginning a
 * frame. Otherwise recycles the string arena, sweeps the interned ids and
 * hover callbacks, calls Clay_BeginLayout and moves to DECLARING. */
void clay_perl_frame_begin(pTHX_ clay_perl_context *ctx);

/* Clay_EndLayout: croaks unless DECLARING, closes the elements still
 * open, calls Clay_EndLayout with ctx as the active transition context,
 * moves to COMPLETE and counts the frame. Re-issues an exit a callback
 * called, then croaks for elements that were still open once Clay has
 * returned; returns Clay's commands otherwise. */
Clay_RenderCommandArray clay_perl_frame_end(pTHX_ clay_perl_context *ctx, float delta_time);

/* Element bookkeeping, called by the element wrappers. An element may be
 * configured once, right after it is opened: element_configured croaks
 * "<who>: the open element is already configured or has children; ..."
 * otherwise. A text element is a child, so its parent can no longer be
 * configured. */
void clay_perl_frame_element_opened(clay_perl_context *ctx);
void clay_perl_frame_element_configured(pTHX_ clay_perl_context *ctx, const char *who);
void clay_perl_frame_text_element_opened(clay_perl_context *ctx);
void clay_perl_frame_element_closed(clay_perl_context *ctx);

/* { arena_chunks, interned_ids, hover_entries, layout_state (complete or
 * declaring), open_depth, completed_frames, callback_depth (the thread's
 * clay_perl_callback_depth) } as a new hash reference, for
 * Clay::XS::_context_stats. */
SV  *clay_perl_frame_stats(pTHX_ const clay_perl_context *ctx);

/* ---------------------------------------------------------------------------
 * String arena and id interning (src/clay_perl_context.c).
 * ------------------------------------------------------------------------ */

/* Copies the characters of sv into the arena as UTF-8 (a Latin-1 string is
 * encoded on the way; sv is never upgraded). Croaks if sv is undef. */
Clay_String clay_perl_arena_copy_text(pTHX_ clay_perl_context *self, SV *sv, const char *what);

/* Returns a Clay_String pointing at the interned copy of the given bytes. */
Clay_String clay_perl_intern_id(pTHX_ clay_perl_context *self, const char *bytes, STRLEN len);

/* ---------------------------------------------------------------------------
 * Held callback errors (src/callbacks.c).
 * ------------------------------------------------------------------------ */

/* Holds the current $@ as the context's held error (or counts it if one
 * is already held) and clears $@. */
void clay_perl_hold_callback_error(pTHX_ clay_perl_context *ctx);

/* Holds a plain message as the held error (or counts it). */
void clay_perl_hold_error_message(pTHX_ clay_perl_context *ctx, const char *message);

/* Removes and returns the held error as a mortal SV, or NULL when
 * nothing is held. A string message gains " (and N more callback
 * errors this frame)" when N > 0 and then the optional note. Resets
 * Clay's measure-text cache when a failed measurement may have been
 * cached. Returns NULL while a Clay callback runs: Clay is then inside
 * one of its own functions, and the held error stays held until the
 * wrapper that called into Clay has Clay's result. Call only while ctx is
 * Clay's current context. */
SV  *clay_perl_take_held_error(pTHX_ clay_perl_context *ctx, const char *note);

/* Croaks with the held error, if any. */
void clay_perl_raise_held_error(pTHX_ clay_perl_context *ctx);

/* ---------------------------------------------------------------------------
 * HV/AV <-> Clay struct converters (src/marshal.c).
 *
 * Naming convention:
 *   *_from_sv  : Perl value -> C struct (used at function entry)
 *   *_to_sv    : C struct  -> Perl value (used at function return)
 *
 * All _from_sv helpers croak a Clay::XS::StructError on invalid input
 * (wrong reference type, non-numeric or non-finite numbers, integers out
 * of the C field's range) naming the struct and field. They never return
 * half-initialised structs. The clay_perl_parse_* scalar helpers croak
 * plain strings. All _to_sv helpers return a new, non-mortal SV; those of
 * structs with a schema run its write mode, so input and output use the
 * same keys.
 * ------------------------------------------------------------------------ */

/* Scalar parsing shared by the XS wrappers. */
double   clay_perl_parse_float(pTHX_ SV *sv, const char *what);
double   clay_perl_parse_float_in(pTHX_ SV *sv, const char *what, double min, double max);
double   clay_perl_parse_max_float(pTHX_ SV *sv, const char *what);
UV       clay_perl_parse_uint(pTHX_ SV *sv, const char *what, UV max);
NV       clay_perl_parse_integer(pTHX_ SV *sv, const char *what, NV min, NV max);

/* Optional arguments: fallback for undef. Get-magic runs once, before
 * the definedness test. */
double   clay_perl_parse_float_or(pTHX_ SV *sv, const char *what, double fallback);
double   clay_perl_parse_max_float_or(pTHX_ SV *sv, const char *what, double fallback);
UV       clay_perl_parse_uint_or(pTHX_ SV *sv, const char *what, UV max, UV fallback);

/* NULL for undef when allow_undef, else a mortal, non-magical copy of a
 * CODE reference; croaks for anything else. */
SV      *clay_perl_require_code(pTHX_ SV *sv, const char *what, bool allow_undef);

Clay_Color           clay_color_from_sv(pTHX_ SV *sv, const char *what);
SV                  *clay_color_to_sv(pTHX_ Clay_Color value);

Clay_Vector2         clay_vector2_from_sv(pTHX_ SV *sv, const char *what);
SV                  *clay_vector2_to_sv(pTHX_ Clay_Vector2 value);

Clay_Dimensions      clay_dimensions_from_sv(pTHX_ SV *sv, const char *what);
SV                  *clay_dimensions_to_sv(pTHX_ Clay_Dimensions value);

SV                  *clay_bounding_box_to_sv(pTHX_ Clay_BoundingBox value);

SV                  *clay_corner_radius_to_sv(pTHX_ Clay_CornerRadius value);
SV                  *clay_padding_to_sv(pTHX_ Clay_Padding value);
SV                  *clay_border_width_to_sv(pTHX_ Clay_BorderWidth value);
SV                  *clay_sizing_axis_to_sv(pTHX_ Clay_SizingAxis value);

Clay_TextElementConfig  clay_text_element_config_from_sv(pTHX_ SV *sv);
SV                     *clay_text_element_config_to_sv(pTHX_ Clay_TextElementConfig value);

Clay_ElementDeclaration clay_element_declaration_from_sv(pTHX_ SV *sv);

/* Check mode: walks value against the schema of the named struct (exact
 * C type name) without building anything for Clay. Strict about unknown
 * keys, array lengths and references used as booleans; croaks a
 * Clay::XS::StructError whose path starts at root (default: the type
 * name). An unknown type name croaks a plain string. */
void clay_perl_check_struct(pTHX_ const char *type, SV *value, const char *root);

/* Every struct schema, for Clay::XS::_struct_schemas:
 * { name => [ { name, kind, min, max, nested }, ... ] } with the fields in
 * schema order. Named schemas appear under their C type name, the
 * anonymous ones (transition enter and exit) under "<outer>.<field>".
 * min and max are set for integers and bounded floats, nested (a schema
 * name) for nested structs; they are undef otherwise. */
SV *clay_perl_struct_schemas(pTHX);

/* Transition data: from_sv starts from base and overrides the keys present
 * in the hash; undef returns base unchanged. */
Clay_TransitionData clay_transition_data_from_sv(pTHX_ SV *sv, Clay_TransitionData base, const char *what);
SV                 *clay_transition_data_to_sv(pTHX_ Clay_TransitionData data);

/* Transition callback arguments (a transition handler's hash, the
 * argument of Clay_EaseOut). from_sv requires a hash reference (undef
 * croaks); the returned args.current points at *current, which holds the
 * given `current` or, when that is missing, a copy of `initial`. */
Clay_TransitionCallbackArguments clay_transition_arguments_from_sv(pTHX_ SV *sv, const char *what,
                                                                   Clay_TransitionData *current);
SV *clay_transition_arguments_to_sv(pTHX_ const Clay_TransitionCallbackArguments *args);

/* Element ids. Both from_sv functions require an element-id hash
 * reference (undef croaks). clay_element_id_from_sv leaves stringId
 * empty, for lookups Clay does not keep the id of;
 * clay_element_id_from_sv_interned also interns a given stringId in ctx,
 * for ids Clay keeps (Clay__OpenElementWithId). */
Clay_ElementId      clay_element_id_from_sv(pTHX_ SV *sv, const char *what);
Clay_ElementId      clay_element_id_from_sv_interned(pTHX_ clay_perl_context *ctx, SV *sv, const char *what);
SV                 *clay_element_id_to_sv(pTHX_ Clay_ElementId id);

SV                 *clay_pointer_data_to_sv(pTHX_ Clay_PointerData data);

/* Render command output (src/marshal.c). */
SV *clay_render_command_array_to_sv(pTHX_ const Clay_RenderCommandArray *array);

/* ScrollContainerData and ElementData returns. The scroll data hash
 * gets its config key only when with_config is true: Clay reads the
 * config through the container's layout element, which may by then hold
 * another element (see clay_perl_clay_scroll_container_declared). */
SV *clay_scroll_container_data_to_sv(pTHX_ Clay_ScrollContainerData data, bool with_config);
SV *clay_element_data_to_sv(pTHX_ Clay_ElementData data);

/* Clay bytes -> Perl character string (copied, UTF-8 flagged). */
SV *clay_perl_utf8_sv(pTHX_ const char *bytes, int32_t length);

/* Perl string -> UTF-8 bytes for Clay, never upgrading the caller's SV.
 * A non-UTF-8 SV holds Latin-1 characters; only bytes above 0x7F need
 * encoding (two bytes each). clay_perl_sv_utf8_bytes returns the SV's own
 * buffer when it is UTF-8 or ASCII-only and a mortal encoded copy
 * otherwise; get-magic must have run. */
bool        clay_perl_latin1_needs_encoding(const char *bytes, STRLEN length);
STRLEN      clay_perl_latin1_utf8_length(const char *bytes, STRLEN length);
void        clay_perl_latin1_to_utf8(char *destination, const char *bytes, STRLEN length);
const char *clay_perl_sv_utf8_bytes(pTHX_ SV *sv, STRLEN *length);

/* ---------------------------------------------------------------------------
 * Callback trampolines (src/callbacks.c).
 *
 * Clay holds these as function pointers. Each one pushes its arguments and
 * calls the dispatcher (clay_perl_dispatcher, the body of the internal
 * Clay::XS::_dispatch XSUB) once under G_EVAL; the
 * dispatcher calls the user's coderef and parses its return value, so any
 * exception (from the callback or from parsing its result) lands in the
 * trampoline's G_EVAL and never unwinds through Clay's C frames.
 * ------------------------------------------------------------------------ */

/* Result slot a trampoline hands to the dispatcher. The trampoline fills
 * in the defaults; the dispatcher overwrites the member for its kind. */
typedef struct clay_perl_dispatch_result {
    Clay_Dimensions     dimensions;
    Clay_Vector2        vector;
    Clay_TransitionData transition_data;
    bool                complete;
} clay_perl_dispatch_result;

/* Body of the Clay::XS::_dispatch XSUB: parses the callback's return
 * value (ret) for the given kind into *result. args_sv is the argument
 * hash the transition handler may have modified (NULL otherwise). */
void clay_perl_dispatch_store_result(pTHX_ clay_perl_dispatch_kind kind,
                                     clay_perl_dispatch_result *result,
                                     SV *ret, SV *args_sv);

Clay_Dimensions clay_perl_measure_text_trampoline(
    Clay_StringSlice text,
    Clay_TextElementConfig *config,
    void *userData);

void clay_perl_error_handler_trampoline(Clay_ErrorData error);

Clay_Vector2 clay_perl_query_scroll_offset_trampoline(
    uint32_t element_id,
    void *userData);

void clay_perl_on_hover_trampoline(
    Clay_ElementId element_id,
    Clay_PointerData pointer,
    void *userData);

bool clay_perl_transition_handler_trampoline(Clay_TransitionCallbackArguments args);
Clay_TransitionData clay_perl_transition_set_initial_trampoline(
    Clay_TransitionData target, Clay_TransitionProperty properties);
Clay_TransitionData clay_perl_transition_set_final_trampoline(
    Clay_TransitionData initial, Clay_TransitionProperty properties);

#if defined(__GNUC__) || defined(__clang__)
#  define CLAY_PERL_THREAD_LOCAL __thread
#elif defined(_MSC_VER)
#  define CLAY_PERL_THREAD_LOCAL __declspec(thread)
#else
#  define CLAY_PERL_THREAD_LOCAL
#endif

/* Thread-local pointer to the context currently inside Clay_EndLayout.
 * The transition trampolines read this to find their per-context handlers
 * (Clay passes them no userData). The Clay_EndLayout XS wrapper sets it
 * around the Clay_EndLayout call. */
extern CLAY_PERL_THREAD_LOCAL clay_perl_context *clay_perl_active_transition_ctx;

/* How often Clay called the transition handler trampoline: once per
 * element and frame while the element animates, so a frame that moved
 * this count drew differently from the one before it. Clay::UI::Revision
 * adds it to its revision (Clay::XS::_transition_handler_calls); a
 * renderer that skips unchanged frames then redraws while anything
 * animates. Process-wide, like Clay's current context. */
extern UV clay_perl_transition_handler_calls;

/* Number of Clay callbacks running on this thread. While it is non-zero
 * Clay is in the middle of one of its own functions, so the XS wrappers
 * that change Clay's state croak (see the guards in lib/Clay/XS.xs). */
extern CLAY_PERL_THREAD_LOCAL uint32_t clay_perl_callback_depth;

/* The dispatch a trampoline has started: set by the trampoline for the
 * duration of its call into Clay::XS::_dispatch, which takes it (and
 * clears .result, so only that one call can use it). */
typedef struct clay_perl_active_dispatch {
    clay_perl_dispatch_kind    kind;
    clay_perl_dispatch_result *result;
} clay_perl_active_dispatch;

extern CLAY_PERL_THREAD_LOCAL clay_perl_active_dispatch clay_perl_pending_dispatch;

/* The dispatcher every trampoline calls (lib/Clay/XS.xs): an anonymous
 * XSUB running the body of Clay::XS::_dispatch, made by BOOT for the
 * interpreter that loads Clay::XS and by Clay::XS::CLONE for each new
 * thread's, and kept in the interpreter's MY_CXT. No glob holds it, so
 * replacing *Clay::XS::_dispatch changes nothing for callbacks. */
CV *clay_perl_dispatcher(pTHX);

/* An exit a callback called, caught before it could unwind Clay's C
 * frames (see call_dispatcher in src/callbacks.c). While it is pending no
 * callback runs, and no Perl code may run at all: Perl's own state was
 * unwound by the exit already. */
typedef struct clay_perl_deferred_exit {
    bool pending;
    U32  status;
} clay_perl_deferred_exit;

extern CLAY_PERL_THREAD_LOCAL clay_perl_deferred_exit clay_perl_pending_exit;

/* Re-issues a pending exit with its status (it does not return then);
 * returns at once otherwise. The XS wrappers call it as soon as Clay has
 * returned, before anything that could run Perl code or croak; ctx (may
 * be NULL) gets its measure cache reset if the exit skipped a
 * measurement. */
void clay_perl_exit_if_pending(pTHX_ clay_perl_context *ctx);

/* The context the binding treats as current (mirrors Clay's global). The
 * trampolines use it for callbacks whose userData Clay leaves NULL. */
extern clay_perl_context *clay_perl_current_ctx;

/* ---------------------------------------------------------------------------
 * Callback registries (src/callbacks.c).
 * ------------------------------------------------------------------------ */

/* Installs code and userdata (copies; undef or NULL clears) as the
 * context's callback of the given kind. */
void clay_perl_callback_set(pTHX_ clay_perl_context *ctx, clay_perl_dispatch_kind kind,
                            SV *code, SV *userdata);

/* Releases every per-context callback slot. */
void clay_perl_callbacks_free(pTHX_ clay_perl_context *ctx);

void clay_perl_hover_register(pTHX_ clay_perl_context *ctx,
                              uint32_t element_id, SV *cb, SV *userdata);

/* The stamp of a hover_callbacks value (the completed_frames value when it
 * was registered), for the frame module's sweep. */
uint32_t clay_perl_hover_entry_stamp(pTHX_ SV *entry);

#endif /* CLAY_PERL_H */
