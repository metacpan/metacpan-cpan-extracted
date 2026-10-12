/*
 * callbacks.c - C trampolines that forward Clay's function-pointer
 * callbacks into Perl coderefs, and the held-error slot they report
 * failures through.
 *
 * Clay holds several function-pointer slots that user code provides:
 *
 *   - Clay_SetMeasureTextFunction       (one per context)
 *   - Clay_Initialize errorHandler      (one per context)
 *   - Clay_SetQueryScrollOffsetFunction (one per context)
 *   - Clay_OnHover                      (per element)
 *   - Clay_TransitionElementConfig.handler / enter.setInitialState /
 *     exit.setFinalState                (per element with transitions,
 *                                        but bridged through a single
 *                                        per-context handler set; see
 *                                        clay_perl.h for rationale)
 *
 * Each is bridged by a fixed C function defined here. Clay calls them in
 * the middle of its own C code, which must never be unwound by a Perl
 * exception. Every trampoline therefore makes exactly one Perl call: the
 * internal Clay::XS::_dispatch XSUB, under G_EVAL. The dispatcher calls
 * the user's coderef and parses its return value into a C result slot;
 * any exception - from the callback, from overloaded or tied return
 * values, from FATAL warnings, or from a malformed result - lands in that
 * G_EVAL. The trampoline then holds it as the context's held error and
 * returns a neutral value to Clay. The XS wrapper that called into Clay
 * re-throws the held error once Clay has returned (see
 * clay_perl_raise_held_error and the wrappers in lib/Clay/XS.xs). The
 * other ways out of Perl code are kept from Clay's frames too: the call
 * runs on a Perl stack of its own, where loop control finds no outer loop
 * and dies, and an exit is caught and deferred until the wrapper has
 * Clay's result (see call_dispatcher).
 *
 * Threading the active context to the trampolines:
 *
 *   - For per-context callbacks (measure_text, error_handler,
 *     query_scroll_offset), Clay's userData slot carries the
 *     clay_perl_context*. Clay_Initialize installs the measure and
 *     query-scroll trampolines for every new context, so the userData is
 *     always set, whether or not a Perl function was installed.
 *
 *   - For hover, the element id is supplied as a function argument; the
 *     context is supplied as Clay's userData. The trampoline looks up the
 *     registered Perl coderef in ctx->hover_callbacks.
 *
 *   - For transitions, the callback signatures lack any way to pass our
 *     context pointer. The Clay_EndLayout wrapper sets the thread-local
 *     clay_perl_active_transition_ctx around the Clay_EndLayout call.
 *
 * Clay forgets an element's hover function whenever the element is
 * declared again (Clay__AddHashMapItem clears onHoverFunction), so hover
 * callbacks must be registered every frame. The frame module
 * (src/clay_perl_context.c) sweeps the entries no frame can reach any
 * more, by their stamp.
 */

#include "clay_perl.h"

#include <stdio.h>
#include <string.h>

/* The context the binding treats as current; mirrors Clay's global. */
clay_perl_context *clay_perl_current_ctx = NULL;

/* How often Clay ran a Perl transition handler, i.e. animated an element
 * (see src/clay_perl.h). Process-wide, like Clay's current context. */
UV clay_perl_transition_handler_calls = 0;

/* ---------------------------------------------------------------------------
 * Thread-local active transition context.
 *
 * Set by the Clay_EndLayout wrapper around Clay_EndLayout. The transition
 * trampolines fall back to identity behaviour if it is NULL, which keeps
 * them safe to call even outside an EndLayout.
 * ------------------------------------------------------------------------ */

CLAY_PERL_THREAD_LOCAL clay_perl_context *clay_perl_active_transition_ctx = NULL;

CLAY_PERL_THREAD_LOCAL uint32_t clay_perl_callback_depth = 0;

CLAY_PERL_THREAD_LOCAL clay_perl_active_dispatch clay_perl_pending_dispatch = { 0, NULL };

CLAY_PERL_THREAD_LOCAL clay_perl_deferred_exit clay_perl_pending_exit = { false, 0 };

/* ---------------------------------------------------------------------------
 * Held callback errors.
 * ------------------------------------------------------------------------ */

void clay_perl_hold_callback_error(pTHX_ clay_perl_context *ctx)
{
    if (ctx->held_error) {
        ctx->suppressed_errors++;
    } else {
        ctx->held_error = newSVsv(ERRSV);
    }
    sv_setpvs(ERRSV, "");
}

void clay_perl_hold_error_message(pTHX_ clay_perl_context *ctx, const char *message)
{
    if (ctx->held_error) {
        ctx->suppressed_errors++;
        return;
    }
    ctx->held_error = newSVpv(message, 0);
}

SV *clay_perl_take_held_error(pTHX_ clay_perl_context *ctx, const char *note)
{
    SV *error = ctx->held_error;
    if (!error || clay_perl_callback_depth > 0) return NULL;

    uint32_t suppressed = ctx->suppressed_errors;
    ctx->held_error     = NULL;
    ctx->suppressed_errors = 0;
    sv_2mortal(error);

    /* A failed or skipped measurement returned 0x0, which Clay cached per
     * text and config; drop the cache so the next frame measures again. */
    if (ctx->measure_cache_poisoned) {
        ctx->measure_cache_poisoned = false;
        Clay_ResetMeasureTextCache();
    }

    if (SvROK(error) || (suppressed == 0 && !note)) return error;

    STRLEN len;
    const char *pv = SvPV(error, len);
    bool newline = len > 0 && pv[len - 1] == '\n';
    SV *message = sv_2mortal(newSVpvn_flags(pv, newline ? len - 1 : len, SvUTF8(error)));
    if (suppressed > 0) {
        sv_catpvf(message, " (and %" UVuf " more callback error%s this frame)",
                  (UV) suppressed, suppressed == 1 ? "" : "s");
    }
    if (note) sv_catpv(message, note);
    if (newline) sv_catpvs(message, "\n");
    return message;
}

void clay_perl_raise_held_error(pTHX_ clay_perl_context *ctx)
{
    SV *error = clay_perl_take_held_error(aTHX_ ctx, NULL);
    if (error) croak_sv(error);
}

/* ---------------------------------------------------------------------------
 * Deferred exit.
 *
 * Perl's exit unwinds the whole interpreter with a longjmp, which must
 * not pass through Clay's C frames. call_dispatcher catches it and
 * records it here; Perl's state is unwound by then, so no Perl code may
 * run until the outermost XS wrapper re-issues the exit once Clay has
 * returned (clay_perl_exit_if_pending).
 * ------------------------------------------------------------------------ */

void clay_perl_exit_if_pending(pTHX_ clay_perl_context *ctx)
{
    if (!clay_perl_pending_exit.pending) return;
    /* A measurement skipped for the exit returned 0x0, which Clay cached;
     * END blocks may still lay out frames. */
    if (ctx && ctx->measure_cache_poisoned) {
        ctx->measure_cache_poisoned = false;
        Clay_ResetMeasureTextCache();
    }
    U32 status = clay_perl_pending_exit.status;
    clay_perl_pending_exit.pending = false;
    clay_perl_pending_exit.status  = 0;
    my_exit(status);
}

/* ---------------------------------------------------------------------------
 * Dispatch.
 *
 * call_dispatcher publishes (kind, result slot) in clay_perl_pending_dispatch,
 * pushes (callback, args...) and calls Clay::XS::_dispatch under G_EVAL, on
 * a Perl stack of its own (as perl runs magic methods): loop control in a
 * callback cannot reach a loop outside it, so "last LABEL" dies inside
 * the eval like any other error. An exit is caught by the JMPENV around
 * the call and deferred (see above). The previous pending dispatch is
 * restored afterwards, so nested dispatches (an error reported while a
 * callback runs) work. It runs inside invoke_callback's ENTER/SAVETMPS ...
 * FREETMPS/LEAVE, with $@ localised there, so the caller's $@ survives the
 * callback.
 * ------------------------------------------------------------------------ */

typedef enum {
    DISPATCH_RETURNED = 0,   /* the callback returned a result */
    DISPATCH_FAILED,         /* it died; the error is held on ctx */
    DISPATCH_EXITED          /* it called exit; Perl's state is unwound */
} dispatch_outcome;

/* Pushes (callback, args...) on the current Perl stack and calls the
 * dispatcher under G_EVAL. */
static void push_and_dispatch(pTHX_ CV *dispatch_cv, SV *callback, SV **args, int argc)
{
    dSP;
    PUSHMARK(SP);
    EXTEND(SP, 1 + argc);
    /* A private reference keeps the callback alive even if it replaces
     * its own slot while running. */
    PUSHs(sv_2mortal(newSVsv(callback)));
    for (int i = 0; i < argc; i++) {
        PUSHs(args[i]);
    }
    PUTBACK;
    call_sv((SV *) dispatch_cv, G_VOID | G_DISCARD | G_EVAL);
}

/* push_and_dispatch inside a JMPENV. G_EVAL catches every die, so only
 * my_exit jumps out of call_sv; returns that jump (0 when none). */
static int dispatch_catching_exit(pTHX_ CV *dispatch_cv, SV *callback, SV **args, int argc)
{
    dJMPENV;
    int jump;
    JMPENV_PUSH(jump);
    if (jump == 0) push_and_dispatch(aTHX_ dispatch_cv, callback, args, argc);
    JMPENV_POP;
    return jump;
}

static dispatch_outcome call_dispatcher(pTHX_ clay_perl_context *ctx, clay_perl_dispatch_kind kind,
                                        clay_perl_dispatch_result *result, SV *callback,
                                        SV **args, int argc)
{
    clay_perl_active_dispatch saved = clay_perl_pending_dispatch;
    {
        dSP;
        PUSHSTACKi(PERLSI_MAGIC);
    }
    clay_perl_pending_dispatch.kind   = kind;
    clay_perl_pending_dispatch.result = result;
    int jump = dispatch_catching_exit(aTHX_ clay_perl_dispatcher(aTHX), callback, args, argc);
    clay_perl_pending_dispatch = saved;

    /* my_exit has popped every Perl stack down to the main one and unwound
     * the scopes already. */
    if (jump != 0) {
        clay_perl_pending_exit.pending = true;
        clay_perl_pending_exit.status  = STATUS_EXIT;
        return DISPATCH_EXITED;
    }
    POPSTACK;

    /* Test for an exception without truth-testing it: an exception object
     * with an overloaded bool could itself die here, outside any eval. */
    SV *error = ERRSV;
    if (!SvROK(error) && !SvTRUE_nomg(error)) return DISPATCH_RETURNED;
    clay_perl_hold_callback_error(aTHX_ ctx);
    return DISPATCH_FAILED;
}

/* Upper bound on the arguments a trampoline passes before the userdata. */
#define MAX_CALLBACK_ARGS 2

/* Fills args with up to MAX_CALLBACK_ARGS mortal SVs built from a
 * trampoline's own data and returns how many. */
typedef int (*callback_args_builder)(pTHX_ const void *data, SV **args);

/* Calls a Perl callback for a trampoline: builds its arguments (plus the
 * userdata, always last) inside a temporaries scope of their own, with $@
 * localised, and dispatches. Returns true when the trampoline must give
 * Clay its neutral result: the callback failed (the error is held on
 * ctx), or an exit is pending, in which case no callback runs at all.
 *
 * The whole scope counts as running a callback (clay_perl_callback_depth):
 * freeing the arguments and restoring $@ can run DESTROY methods, and
 * Clay is still inside its own function while they run. After an exit
 * that scope is gone already, and only the depth is restored. */
static bool invoke_callback(pTHX_ clay_perl_context *ctx, clay_perl_dispatch_kind kind,
                            clay_perl_dispatch_result *result, const clay_perl_callback *callback,
                            callback_args_builder build_args, const void *data)
{
    if (clay_perl_pending_exit.pending) return true;

    SV *args[MAX_CALLBACK_ARGS + 1];

    clay_perl_callback_depth++;
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);
    int argc = build_args(aTHX_ data, args);
    args[argc++] = sv_2mortal(newSVsv(callback->userdata ? callback->userdata : &PL_sv_undef));
    dispatch_outcome outcome = call_dispatcher(aTHX_ ctx, kind, result, callback->code, args, argc);
    if (outcome != DISPATCH_EXITED) {
        FREETMPS;
        LEAVE;
    }
    clay_perl_callback_depth--;
    return outcome != DISPATCH_RETURNED;
}

/* A result the callback must return: undef (usually a forgotten return)
 * croaks instead of reading as zero. */
static SV *required_result(pTHX_ SV *ret, const char *what)
{
    SvGETMAGIC(ret);
    if (!SvOK(ret)) {
        croak("%s: expected a hash or array reference, got undef (did the callback return its result?)", what);
    }
    return ret;
}

void clay_perl_dispatch_store_result(pTHX_ clay_perl_dispatch_kind kind,
                                     clay_perl_dispatch_result *result,
                                     SV *ret, SV *args_sv)
{
    switch (kind) {
    case CLAY_PERL_DISPATCH_MEASURE_TEXT:
        result->dimensions = clay_dimensions_from_sv(aTHX_
            required_result(aTHX_ ret, "measure_text callback result"), "measure_text callback result");
        return;

    case CLAY_PERL_DISPATCH_QUERY_SCROLL_OFFSET:
        result->vector = clay_vector2_from_sv(aTHX_
            required_result(aTHX_ ret, "query_scroll_offset callback result"), "query_scroll_offset callback result");
        return;

    case CLAY_PERL_DISPATCH_TRANSITION_HANDLER: {
        if (!args_sv || !SvROK(args_sv) || SvTYPE(SvRV(args_sv)) != SVt_PVHV) {
            croak("Clay::XS: transition handler replaced its argument hash");
        }
        SvGETMAGIC(ret);
        result->complete = SvOK(ret) ? cBOOL(SvTRUE_nomg(ret)) : true;
        SV **current = hv_fetchs((HV *) SvRV(args_sv), "current", 0);
        if (current && *current) {
            result->transition_data = clay_transition_data_from_sv(
                aTHX_ *current, result->transition_data, "transition handler args.current");
        }
        return;
    }

    case CLAY_PERL_DISPATCH_TRANSITION_SET_INITIAL:
        result->transition_data = clay_transition_data_from_sv(
            aTHX_ ret, result->transition_data, "transition setInitialState result");
        return;

    case CLAY_PERL_DISPATCH_TRANSITION_SET_FINAL:
        result->transition_data = clay_transition_data_from_sv(
            aTHX_ ret, result->transition_data, "transition setFinalState result");
        return;

    case CLAY_PERL_DISPATCH_ERROR_HANDLER:
    case CLAY_PERL_DISPATCH_HOVER:
        return;

    case CLAY_PERL_DISPATCH_KIND_COUNT:
        break;
    }
    croak("Clay::XS: internal error: unknown dispatch kind %d", (int) kind);
}

/* ---------------------------------------------------------------------------
 * Per-context callback slots.
 * ------------------------------------------------------------------------ */

/* Replaces a slot with a copy of new_value (NULL for undef), copying
 * before the old value is released. Get-magic runs once. */
static void replace_sv_slot(pTHX_ SV **slot, SV *new_value)
{
    SV *copy = NULL;
    if (new_value) {
        SvGETMAGIC(new_value);
        if (SvOK(new_value)) {
            copy = newSV(0);
            sv_setsv_nomg(copy, new_value);
        }
    }
    SV *old  = *slot;
    *slot = copy;
    SvREFCNT_dec(old);
}

void clay_perl_callback_set(pTHX_ clay_perl_context *ctx, clay_perl_dispatch_kind kind,
                            SV *code, SV *userdata)
{
    if (kind <= 0 || kind >= CLAY_PERL_DISPATCH_KIND_COUNT || kind == CLAY_PERL_DISPATCH_HOVER) {
        croak("Clay::XS: internal error: no context slot for callback kind %d", (int) kind);
    }
    replace_sv_slot(aTHX_ &ctx->callbacks[kind].code, code);
    replace_sv_slot(aTHX_ &ctx->callbacks[kind].userdata, userdata);
}

void clay_perl_callbacks_free(pTHX_ clay_perl_context *ctx)
{
    for (int kind = 0; kind < CLAY_PERL_DISPATCH_KIND_COUNT; kind++) {
        replace_sv_slot(aTHX_ &ctx->callbacks[kind].code, NULL);
        replace_sv_slot(aTHX_ &ctx->callbacks[kind].userdata, NULL);
    }
}

/* ---------------------------------------------------------------------------
 * The hover registry.
 * ------------------------------------------------------------------------ */

/* Each entry is [coderef, userdata, stamp]; the stamp is completed_frames
 * when the callback was registered (see the frame module's stamped
 * registries). */
static void make_id_key(uint32_t id, char buf[16])
{
    snprintf(buf, 16, "%u", (unsigned) id);
}

void clay_perl_hover_register(pTHX_ clay_perl_context *ctx,
                              uint32_t element_id, SV *cb, SV *userdata)
{
    AV *entry = newAV();
    av_push(entry, newSVsv(cb));
    av_push(entry, newSVsv(userdata ? userdata : &PL_sv_undef));
    av_push(entry, newSVuv(ctx->completed_frames));

    char key[16];
    make_id_key(element_id, key);
    (void) hv_store(ctx->hover_callbacks, key, (I32) strlen(key), newRV_noinc((SV *) entry), 0);
}

uint32_t clay_perl_hover_entry_stamp(pTHX_ SV *entry)
{
    SV **stamp = av_fetch((AV *) SvRV(entry), 2, 0);
    return (uint32_t) SvUV(*stamp);
}

/* ---------------------------------------------------------------------------
 * Trampoline: text measurement.
 *
 *     $cb->( $text, \%config, $userdata ) -> { width, height } or [ w, h ]
 *
 * Once an error is pending, measurement is skipped (0x0) until the error
 * is raised, so one broken measurer produces one exception per frame.
 * ------------------------------------------------------------------------ */

typedef struct measure_text_call {
    Clay_StringSlice        text;
    Clay_TextElementConfig *config;
} measure_text_call;

static int measure_text_args(pTHX_ const void *data, SV **args)
{
    const measure_text_call *call = (const measure_text_call *) data;
    args[0] = sv_2mortal(clay_perl_utf8_sv(aTHX_ call->text.chars, call->text.length));
    args[1] = sv_2mortal(clay_text_element_config_to_sv(aTHX_ *call->config));
    return 2;
}

Clay_Dimensions clay_perl_measure_text_trampoline(Clay_StringSlice text,
                                                  Clay_TextElementConfig *config,
                                                  void *userData)
{
    dTHX;
    Clay_Dimensions zero = { 0, 0 };

    clay_perl_context *ctx = (clay_perl_context *) userData;
    if (!ctx) return zero;
    if (ctx->held_error) {
        ctx->measure_cache_poisoned = true;
        return zero;
    }
    const clay_perl_callback *callback = &ctx->callbacks[CLAY_PERL_DISPATCH_MEASURE_TEXT];
    if (!callback->code) {
        clay_perl_hold_error_message(aTHX_ ctx,
            "Clay::XS: text measured but no measure_text function is installed for this context");
        ctx->measure_cache_poisoned = true;
        return zero;
    }

    clay_perl_dispatch_result result;
    memset(&result, 0, sizeof(result));
    measure_text_call call = { text, config };
    if (invoke_callback(aTHX_ ctx, CLAY_PERL_DISPATCH_MEASURE_TEXT, &result, callback,
                        measure_text_args, &call)) {
        ctx->measure_cache_poisoned = true;
        return zero;
    }
    return result.dimensions;
}

/* ---------------------------------------------------------------------------
 * Trampoline: error handler.
 *
 *     $cb->( { errorType => $type, errorText => $string }, $userdata )
 *
 * With no Perl handler installed, Clay errors are ignored (as in C).
 * ------------------------------------------------------------------------ */

static int error_handler_args(pTHX_ const void *data, SV **args)
{
    const Clay_ErrorData *error = (const Clay_ErrorData *) data;
    HV *err_hv = newHV();
    (void) hv_stores(err_hv, "errorType", newSViv((IV) error->errorType));
    (void) hv_stores(err_hv, "errorText",
                     clay_perl_utf8_sv(aTHX_ error->errorText.chars, error->errorText.length));
    args[0] = sv_2mortal(newRV_noinc((SV *) err_hv));
    return 1;
}

void clay_perl_error_handler_trampoline(Clay_ErrorData error)
{
    dTHX;
    clay_perl_context *ctx = (clay_perl_context *) error.userData;
    if (!ctx || !ctx->callbacks[CLAY_PERL_DISPATCH_ERROR_HANDLER].code) return;

    clay_perl_dispatch_result result;
    memset(&result, 0, sizeof(result));
    (void) invoke_callback(aTHX_ ctx, CLAY_PERL_DISPATCH_ERROR_HANDLER, &result,
                           &ctx->callbacks[CLAY_PERL_DISPATCH_ERROR_HANDLER],
                           error_handler_args, &error);
}

/* ---------------------------------------------------------------------------
 * Trampoline: query scroll offset.
 *
 *     $cb->( $element_id, $userdata ) -> { x, y } or [ x, y ]
 * ------------------------------------------------------------------------ */

static int query_scroll_offset_args(pTHX_ const void *data, SV **args)
{
    args[0] = sv_2mortal(newSVuv(*(const uint32_t *) data));
    return 1;
}

Clay_Vector2 clay_perl_query_scroll_offset_trampoline(uint32_t element_id,
                                                      void *userData)
{
    dTHX;
    Clay_Vector2 zero = { 0, 0 };

    clay_perl_context *ctx = (clay_perl_context *) userData;
    if (!ctx) return zero;
    const clay_perl_callback *callback = &ctx->callbacks[CLAY_PERL_DISPATCH_QUERY_SCROLL_OFFSET];
    if (!callback->code) {
        clay_perl_hold_error_message(aTHX_ ctx,
            "Clay::XS: external scroll handling is enabled but no query_scroll_offset function is installed for this context");
        return zero;
    }

    clay_perl_dispatch_result result;
    memset(&result, 0, sizeof(result));
    bool failed = invoke_callback(aTHX_ ctx, CLAY_PERL_DISPATCH_QUERY_SCROLL_OFFSET, &result,
                                  callback, query_scroll_offset_args, &element_id);
    return failed ? zero : result.vector;
}

/* ---------------------------------------------------------------------------
 * Trampoline: per-element hover.
 *
 *     $cb->( \%element_id, \%pointer_data, $userdata )
 * ------------------------------------------------------------------------ */

typedef struct hover_call {
    Clay_ElementId   element_id;
    Clay_PointerData pointer;
} hover_call;

static int hover_args(pTHX_ const void *data, SV **args)
{
    const hover_call *call = (const hover_call *) data;
    args[0] = sv_2mortal(clay_element_id_to_sv(aTHX_ call->element_id));
    args[1] = sv_2mortal(clay_pointer_data_to_sv(aTHX_ call->pointer));
    return 2;
}

void clay_perl_on_hover_trampoline(Clay_ElementId element_id,
                                   Clay_PointerData pointer,
                                   void *userData)
{
    dTHX;
    clay_perl_context *ctx = (clay_perl_context *) userData;
    if (!ctx) return;

    char key[16];
    make_id_key(element_id.id, key);
    SV **entry_slot = hv_fetch(ctx->hover_callbacks, key, (I32) strlen(key), 0);
    if (!entry_slot) return;

    AV *entry = (AV *) SvRV(*entry_slot);
    clay_perl_callback callback = { *av_fetch(entry, 0, 0), *av_fetch(entry, 1, 0) };

    clay_perl_dispatch_result result;
    memset(&result, 0, sizeof(result));
    hover_call call = { element_id, pointer };
    (void) invoke_callback(aTHX_ ctx, CLAY_PERL_DISPATCH_HOVER, &result, &callback, hover_args, &call);
}

/* ---------------------------------------------------------------------------
 * Transition trampolines.
 *
 * All three fish the active context out of the thread-local and call the
 * matching per-context Perl coderef if installed. Without a coderef (or
 * after a failure) they fall back to identity behaviour: the handler
 * reports completion, setInitialState returns the target and
 * setFinalState returns the initial state.
 *
 * args.current is a writeable pointer; the Perl handler updates the
 * `current` entry of the argument hash and the dispatcher copies it back.
 * ------------------------------------------------------------------------ */

static int transition_handler_args(pTHX_ const void *data, SV **args)
{
    args[0] = sv_2mortal(clay_transition_arguments_to_sv(aTHX_ (const Clay_TransitionCallbackArguments *) data));
    return 1;
}

bool clay_perl_transition_handler_trampoline(Clay_TransitionCallbackArguments args)
{
    dTHX;
    clay_perl_transition_handler_calls++;
    clay_perl_context *ctx = clay_perl_active_transition_ctx;
    if (!ctx || !ctx->callbacks[CLAY_PERL_DISPATCH_TRANSITION_HANDLER].code) return true;

    clay_perl_dispatch_result result;
    memset(&result, 0, sizeof(result));
    result.complete        = true;
    result.transition_data = *args.current;

    if (invoke_callback(aTHX_ ctx, CLAY_PERL_DISPATCH_TRANSITION_HANDLER, &result,
                        &ctx->callbacks[CLAY_PERL_DISPATCH_TRANSITION_HANDLER],
                        transition_handler_args, &args)) {
        return true;
    }
    *args.current = result.transition_data;
    return result.complete;
}

typedef struct transition_state_call {
    Clay_TransitionData     state;
    Clay_TransitionProperty properties;
} transition_state_call;

static int transition_state_args(pTHX_ const void *data, SV **args)
{
    const transition_state_call *call = (const transition_state_call *) data;
    args[0] = sv_2mortal(clay_transition_data_to_sv(aTHX_ call->state));
    args[1] = sv_2mortal(newSVuv((UV) call->properties));
    return 2;
}

/* setInitialState / setFinalState: the callback of `kind`, or `state`
 * unchanged when none is installed or it failed. */
static Clay_TransitionData dispatch_transition_state(clay_perl_dispatch_kind kind,
                                                     Clay_TransitionData state,
                                                     Clay_TransitionProperty properties)
{
    dTHX;
    clay_perl_context *ctx = clay_perl_active_transition_ctx;
    if (!ctx || !ctx->callbacks[kind].code) return state;

    clay_perl_dispatch_result result;
    memset(&result, 0, sizeof(result));
    result.transition_data = state;
    transition_state_call call = { state, properties };
    bool failed = invoke_callback(aTHX_ ctx, kind, &result, &ctx->callbacks[kind],
                                  transition_state_args, &call);
    return failed ? state : result.transition_data;
}

Clay_TransitionData clay_perl_transition_set_initial_trampoline(
    Clay_TransitionData target, Clay_TransitionProperty properties)
{
    return dispatch_transition_state(CLAY_PERL_DISPATCH_TRANSITION_SET_INITIAL, target, properties);
}

Clay_TransitionData clay_perl_transition_set_final_trampoline(
    Clay_TransitionData initial, Clay_TransitionProperty properties)
{
    return dispatch_transition_state(CLAY_PERL_DISPATCH_TRANSITION_SET_FINAL, initial, properties);
}
