/*
 * clay_perl_context.c - Per-Perl-context state, the per-frame string arena,
 * the element id intern table and the frame module.
 *
 * Each Clay::XS::Context Perl object owns one clay_perl_context. The
 * object is a reference to a read-only scalar carrying the context pointer
 * in private ext magic; copies (Storable::dclone) and forged objects lack
 * the magic and are rejected. DESTROY frees the context and clears the
 * magic pointer, so a second DESTROY is a no-op.
 *
 * The frame module (the last section) owns the frame state and decides
 * when the arena chunks, the interned ids and the hover callbacks may go.
 */

#include "clay_perl.h"

#include <stdlib.h>
#include <string.h>

#define MIN_STRING_CHUNK_BYTES 4096

static MGVTBL clay_perl_context_vtbl = { 0, 0, 0, 0, 0, 0, 0, 0 };

/* ---------------------------------------------------------------------------
 * String arena chunks.
 * ------------------------------------------------------------------------ */

static clay_perl_arena_chunk *chunk_new(size_t capacity)
{
    clay_perl_arena_chunk *chunk =
        (clay_perl_arena_chunk *) malloc(offsetof(clay_perl_arena_chunk, bytes) + capacity);
    if (!chunk) return NULL;
    chunk->next     = NULL;
    chunk->capacity = capacity;
    chunk->used     = 0;
    return chunk;
}

static void chunk_list_free(clay_perl_arena_chunk *chunk)
{
    while (chunk) {
        clay_perl_arena_chunk *next = chunk->next;
        free(chunk);
        chunk = next;
    }
}

/* ---------------------------------------------------------------------------
 * Context lifecycle.
 * ------------------------------------------------------------------------ */

clay_perl_context *clay_perl_context_new(pTHX_ size_t clay_arena_capacity)
{
    char *arena_memory = (char *) malloc(clay_arena_capacity);
    if (!arena_memory) return NULL;

    clay_perl_arena_chunk *first_chunk = chunk_new(MIN_STRING_CHUNK_BYTES);
    if (!first_chunk) {
        free(arena_memory);
        return NULL;
    }

    clay_perl_context *self;
    Newxz(self, 1, clay_perl_context);

    self->owner             = CLAY_PERL_THIS_INTERPRETER;
    self->clay_arena_memory = arena_memory;
    self->clay_arena        = Clay_CreateArenaWithCapacityAndMemory(clay_arena_capacity, arena_memory);
    self->strings.current   = first_chunk;
    self->interned_ids      = newHV();
    self->hover_callbacks   = newHV();
    self->layout_state      = CLAY_PERL_LAYOUT_COMPLETE;
    return self;
}

void clay_perl_context_free(pTHX_ clay_perl_context *self)
{
    if (!self) return;

    clay_perl_callbacks_free(aTHX_ self);
    SvREFCNT_dec(self->held_error);
    SvREFCNT_dec((SV *) self->hover_callbacks);
    SvREFCNT_dec((SV *) self->interned_ids);

    chunk_list_free(self->strings.current);
    chunk_list_free(self->strings.retained);
    free(self->clay_arena_memory);

    Safefree(self);
}

/* ---------------------------------------------------------------------------
 * SV <-> context bridging via ext magic on a shared referent.
 * ------------------------------------------------------------------------ */

SV *clay_perl_context_bless(pTHX_ clay_perl_context *self)
{
    SV *referent = newSV(0);
    sv_magicext(referent, NULL, PERL_MAGIC_ext, &clay_perl_context_vtbl, (const char *) self, 0);
    self->referent = referent;

    SV *ref = newRV_noinc(referent);
    sv_bless(ref, gv_stashpvs("Clay::XS::Context", GV_ADD));
    SvREADONLY_on(referent);
    return ref;
}

SV *clay_perl_context_to_sv(pTHX_ clay_perl_context *self)
{
    return newRV_inc(self->referent);
}

clay_perl_context *clay_perl_context_peek(pTHX_ SV *sv, MAGIC **magic_out)
{
    if (magic_out) *magic_out = NULL;
    if (!sv || !SvROK(sv)) return NULL;
    SV *referent = SvRV(sv);
    if (!SvMAGICAL(referent)) return NULL;
    MAGIC *mg = mg_findext(referent, PERL_MAGIC_ext, &clay_perl_context_vtbl);
    if (!mg) return NULL;
    if (magic_out) *magic_out = mg;
    return (clay_perl_context *) mg->mg_ptr;
}

clay_perl_context *clay_perl_context_from_sv(pTHX_ SV *sv)
{
    clay_perl_context *ctx = clay_perl_context_peek(aTHX_ sv, NULL);
    if (!ctx) {
        croak("Clay::XS: argument is not a live Clay::XS::Context");
    }
    return ctx;
}

/* ---------------------------------------------------------------------------
 * Buffers exiting elements still use.
 *
 * A sorted array of the text and id-string pointers Clay's exiting
 * element clones hold (clay_perl_clay_visit_exiting_buffers). When it
 * could not be collected (out of memory) it is marked incomplete, and
 * its users keep everything.
 * ------------------------------------------------------------------------ */

typedef struct buffer_set {
    const char **items;
    size_t length;
    size_t capacity;
    bool complete;
} buffer_set;

static void buffer_set_add(const char *chars, void *data)
{
    buffer_set *set = (buffer_set *) data;
    if (!set->complete) return;
    if (!chars) {
        set->complete = false;
        return;
    }
    if (set->length == set->capacity) {
        size_t capacity = set->capacity ? set->capacity * 2 : 64;
        const char **items = (const char **) realloc((void *) set->items, capacity * sizeof(*items));
        if (!items) {
            set->complete = false;
            return;
        }
        set->items    = items;
        set->capacity = capacity;
    }
    set->items[set->length++] = chars;
}

static int compare_pointers(const void *a, const void *b)
{
    uintptr_t left  = (uintptr_t) *(const char *const *) a;
    uintptr_t right = (uintptr_t) *(const char *const *) b;
    return left < right ? -1 : left > right ? 1 : 0;
}

static buffer_set exiting_buffers_collect(void)
{
    buffer_set set = { NULL, 0, 0, true };
    clay_perl_clay_visit_exiting_buffers(buffer_set_add, &set);
    if (set.complete && set.length > 1) {
        qsort((void *) set.items, set.length, sizeof(*set.items), compare_pointers);
    }
    return set;
}

static void buffer_set_free(buffer_set *set)
{
    free((void *) set->items);
    set->items  = NULL;
    set->length = set->capacity = 0;
}

/* True when some pointer of the set lies in [start, start + length). */
static bool buffer_set_hits(const buffer_set *set, const char *start, size_t length)
{
    if (!set->complete) return true;
    size_t low = 0, high = set->length;
    while (low < high) {   /* first pointer >= start */
        size_t middle = low + (high - low) / 2;
        if ((uintptr_t) set->items[middle] < (uintptr_t) start) low = middle + 1;
        else high = middle;
    }
    return low < set->length && (uintptr_t) set->items[low] < (uintptr_t) start + length;
}

/* ---------------------------------------------------------------------------
 * Per-frame string arena.
 *
 * Clay stores the Clay_String of every text element and reads it again in
 * Clay_EndLayout (measure-cache hashing, wrapping, render commands). It
 * also keeps text pointers beyond the frame: Clay_EndLayout copies the
 * subtree of every element with an exit transition into the next frame's
 * layout, and when such an element stops being declared it keeps being
 * rendered, with its old text, until the exit transition finishes.
 *
 * Lifetime rule, applied by the frame module at the start of every frame:
 *   - Chunks are never reallocated or freed while Clay may read them.
 *   - The previous frame's chunks stay alive for one more frame (an
 *     element starts exiting in the first frame it is no longer declared,
 *     with the text of the frame before).
 *   - An older chunk stays alive while an exiting element's text points
 *     into it; memory during long exit animations stays bounded by the
 *     text those elements show.
 * Steady state: one chunk for this frame and one for the last, recycled
 * without any per-frame allocation. A new chunk gets half again the
 * bytes it needs, so text that grows a little every frame does not
 * reallocate every frame.
 * ------------------------------------------------------------------------ */

static size_t chunk_bytes_for(size_t wanted)
{
    size_t padded = wanted + wanted / 2;
    return padded > MIN_STRING_CHUNK_BYTES ? padded : MIN_STRING_CHUNK_BYTES;
}

static void arena_begin_frame(clay_perl_string_arena *arena, const buffer_set *exiting)
{
    size_t wanted = arena->frame_bytes;
    clay_perl_arena_chunk *older = arena->retained;

    arena->retained    = arena->current;
    arena->current     = NULL;
    arena->frame_bytes = 0;

    /* Sort the older chunks into the ones Clay may still read and the
     * free ones; the first free chunk large enough becomes this frame's. */
    clay_perl_arena_chunk *spare = NULL;
    while (older) {
        clay_perl_arena_chunk *chunk = older;
        older = chunk->next;
        bool in_use = buffer_set_hits(exiting, chunk->bytes, chunk->used);
        if (in_use) {
            chunk->next     = arena->retained;
            arena->retained = chunk;
        } else if (!arena->current && chunk->capacity >= wanted) {
            chunk->next    = NULL;
            chunk->used    = 0;
            arena->current = chunk;
        } else {
            chunk->next = spare;
            spare       = chunk;
        }
    }
    chunk_list_free(spare);

    /* If this allocation fails, current stays NULL and arena_reserve
     * allocates (or croaks) on the next copy. */
    if (!arena->current) arena->current = chunk_new(chunk_bytes_for(wanted));
}

static char *arena_reserve(pTHX_ clay_perl_string_arena *arena, size_t len)
{
    clay_perl_arena_chunk *head = arena->current;
    if (!head || head->capacity - head->used < len) {
        size_t previous = head ? head->capacity : MIN_STRING_CHUNK_BYTES / 2;
        size_t capacity = previous * 2 > len ? previous * 2 : chunk_bytes_for(len);
        clay_perl_arena_chunk *chunk = chunk_new(capacity);
        if (!chunk) {
            croak("Clay::XS: cannot allocate %" UVuf " bytes for text", (UV) capacity);
        }
        chunk->next    = head;
        arena->current = chunk;
        head           = chunk;
    }
    char *dst = head->bytes + head->used;
    head->used         += len;
    arena->frame_bytes += len;
    return dst;
}

Clay_String clay_perl_arena_copy_text(pTHX_ clay_perl_context *self, SV *sv, const char *what)
{
    if (!sv) croak("%s: text is missing", what);
    SvGETMAGIC(sv);
    if (!SvOK(sv)) croak("%s: text must be a defined string", what);

    /* A Latin-1 string is encoded straight into the arena; the caller's
     * SV is never upgraded. */
    STRLEN pv_len = 0;
    const char *pv = SvPV_nomg(sv, pv_len);
    bool encode = !SvUTF8(sv) && clay_perl_latin1_needs_encoding(pv, pv_len);
    STRLEN len = encode ? clay_perl_latin1_utf8_length(pv, pv_len) : pv_len;
    /* Clay_String.length is int32_t; refuse rather than truncate. */
    if (len > (STRLEN) INT32_MAX) {
        croak("%s: text length %" UVuf " exceeds INT32_MAX", what, (UV) len);
    }

    Clay_String s = { false, (int32_t) len, NULL };
    if (len == 0) return s;
    char *dst = arena_reserve(aTHX_ &self->strings, len);
    if (encode) {
        clay_perl_latin1_to_utf8(dst, pv, pv_len);
    } else {
        memcpy(dst, pv, len);
    }
    s.chars = dst;
    return s;
}

/* ---------------------------------------------------------------------------
 * Element id interning.
 *
 * Clay copies Clay_ElementId (including the stringId pointer) into its
 * persistent element hash map, the per-frame id-string array (read by the
 * debug view, and carried along with exiting elements) and
 * pointerOverIds. The intern table keeps one SV per id string; its buffer
 * never moves, and the SV's IV slot records the frame that last used it
 * (completed_frames at the time), the stamp the frame module sweeps by.
 * ------------------------------------------------------------------------ */

Clay_String clay_perl_intern_id(pTHX_ clay_perl_context *self, const char *bytes, STRLEN len)
{
    Clay_String s = { false, 0, NULL };
    if (len == 0) return s;
    if (len > (STRLEN) INT32_MAX) {
        croak("Clay::XS: element id length %" UVuf " exceeds INT32_MAX", (UV) len);
    }

    SV **slot = hv_fetch(self->interned_ids, bytes, (I32) len, 0);
    SV *entry;
    if (slot && *slot) {
        entry = *slot;
    } else {
        entry = newSVpvn(bytes, len);
        SvUPGRADE(entry, SVt_PVIV);
        SvREADONLY_on(entry);
        hv_store(self->interned_ids, bytes, (I32) len, entry, 0);
    }
    SvIV_set(entry, (IV) self->completed_frames);

    s.length = (int32_t) len;
    s.chars  = SvPVX(entry);
    return s;
}

/* ===========================================================================
 * The frame module.
 *
 * Owns a context's frame state and every retention rule that follows from
 * it. The XS wrappers of the frame and element functions call it; after
 * clay_perl_context_new nothing else writes these fields (the wrapper
 * guards only read them):
 *
 *   layout_state   COMPLETE --Clay_BeginLayout--> DECLARING
 *                  DECLARING --Clay_EndLayout--> COMPLETE
 *                  DECLARING --Clay_BeginLayout--> the unfinished frame is
 *                              finished (COMPLETE), then the next one
 *                              begins (DECLARING), unless that re-throws
 *                              a held error
 *   open_depth, open_element_configurable
 *                  the open/close balance and whether the innermost open
 *                  element may still be configured (only right after it
 *                  was opened, before any child, as the C CLAY() macro
 *                  does: Clay pushes the clip stack and floating roots per
 *                  configuration but pops them once per element).
 *   completed_frames
 *                  frames that reached Clay_EndLayout; the stamp of the
 *                  stamped registries.
 * ======================================================================== */

/* ---------------------------------------------------------------------------
 * Stamped registries.
 *
 * The interned ids and the hover callbacks are hashes whose entries carry
 * a stamp: completed_frames when a frame last used them, so a stamp names
 * the frame being declared. The sweep at the start of a frame keeps what
 * the last N completed frames used: an entry stamped s survives while
 * s >= completed_frames - N. N per registry:
 *
 *   interned ids     2: Clay copies an element id, with its string, into
 *                    its persistent element hash map and the frame's
 *                    id-string array; an element that stops being
 *                    declared starts its exit transition in the next frame
 *                    with the id of the frame before. Ids under the
 *                    pointer and ids of exiting elements are kept while
 *                    Clay holds them, whatever their stamp.
 *   hover callbacks  1: Clay_SetPointerState dispatches the callbacks
 *                    registered while the last completed frame was
 *                    declared; Clay forgets them when the element is
 *                    declared again.
 *
 * The stamps live where each registry keeps its data: in the IV slot of
 * an interned id's own SV (whose buffer Clay points into), and as the
 * third element of a hover entry [coderef, userdata, stamp] in
 * src/callbacks.c.
 * ------------------------------------------------------------------------ */

#define INTERNED_ID_KEEP_COMPLETED_FRAMES 2
#define HOVER_KEEP_COMPLETED_FRAMES       1

/* The stamp of a registry value. */
typedef uint32_t (*registry_stamp)(pTHX_ SV *value);

/* True when a stale entry must stay anyway. */
typedef bool (*registry_holds)(SV *value, const void *data);

static void registry_sweep(pTHX_ HV *registry, uint32_t completed_frames, uint32_t keep_frames,
                           registry_stamp stamp_of, registry_holds holds, const void *data)
{
    if (completed_frames < keep_frames) return;
    uint32_t cutoff = completed_frames - keep_frames;

    /* Collect first, delete afterwards: deleting invalidates the iterator. */
    AV *stale = (AV *) sv_2mortal((SV *) newAV());
    HE *he;
    hv_iterinit(registry);
    while ((he = hv_iternext(registry)) != NULL) {
        SV *value = HeVAL(he);
        if (stamp_of(aTHX_ value) >= cutoff) continue;
        if (holds && holds(value, data)) continue;
        av_push(stale, newSVhek(HeKEY_hek(he)));
    }

    SSize_t count = av_top_index(stale) + 1;
    for (SSize_t i = 0; i < count; i++) {
        SV **key = av_fetch(stale, i, 0);
        (void) hv_delete_ent(registry, *key, G_DISCARD, 0);
    }
}

static uint32_t interned_id_stamp(pTHX_ SV *value)
{
    PERL_UNUSED_CONTEXT;
    return (uint32_t) SvIVX(value);
}

/* What Clay holds on to beyond the keep window: the pointer-over ids of
 * the last frame and the buffers of exiting elements. */
typedef struct interned_id_holders {
    Clay_ElementIdArray pointer_over;
    const buffer_set   *exiting;
} interned_id_holders;

static bool interned_id_held(SV *value, const void *data)
{
    const interned_id_holders *holders = (const interned_id_holders *) data;
    const char *chars = SvPVX(value);
    for (int32_t i = 0; i < holders->pointer_over.length; i++) {
        if (holders->pointer_over.internalArray[i].stringId.chars == chars) return true;
    }
    return buffer_set_hits(holders->exiting, chars, 1);
}

/* Must run while this context is Clay's current context, with the last
 * frame completed and before Clay_BeginLayout discards it. */
static void sweep_retained(pTHX_ clay_perl_context *self)
{
    buffer_set exiting = exiting_buffers_collect();
    interned_id_holders holders = { Clay_GetPointerOverIds(), &exiting };
    arena_begin_frame(&self->strings, &exiting);
    registry_sweep(aTHX_ self->interned_ids, self->completed_frames, INTERNED_ID_KEEP_COMPLETED_FRAMES,
                   interned_id_stamp, interned_id_held, &holders);
    buffer_set_free(&exiting);
    registry_sweep(aTHX_ self->hover_callbacks, self->completed_frames, HOVER_KEEP_COMPLETED_FRAMES,
                   clay_perl_hover_entry_stamp, NULL, NULL);
}

/* ---------------------------------------------------------------------------
 * Frame transitions.
 * ------------------------------------------------------------------------ */

static void reset_open_elements(clay_perl_context *self)
{
    self->open_depth                = 0;
    self->open_element_configurable = false;
}

/* Closes the elements still open and lets Clay finish the frame with
 * ctx as the active transition context; the frame then counts as
 * completed. Returns Clay's commands and, through still_open, how many
 * elements were left open. Callback errors stay held. */
static Clay_RenderCommandArray finish_frame(clay_perl_context *self, float delta_time, int32_t *still_open)
{
    *still_open = self->open_depth;
    reset_open_elements(self);
    for (int32_t i = 0; i < *still_open; i++) {
        Clay__CloseElement();
    }

    /* The transition trampolines find their handlers through this. */
    clay_perl_context *outer_transition_ctx = clay_perl_active_transition_ctx;
    clay_perl_active_transition_ctx = self;
    Clay_RenderCommandArray commands = Clay_EndLayout(delta_time);
    clay_perl_active_transition_ctx = outer_transition_ctx;

    self->layout_state = CLAY_PERL_LAYOUT_COMPLETE;
    self->completed_frames++;
    return commands;
}

void clay_perl_frame_begin(pTHX_ clay_perl_context *self)
{
    /* Clay must never see two Clay_BeginLayout calls without a
     * Clay_EndLayout: its transition data points into the frame being
     * declared. A frame left unfinished (an exception interrupted its
     * declaration) is finished first and its commands are discarded. */
    if (self->layout_state == CLAY_PERL_LAYOUT_DECLARING) {
        int32_t still_open;
        (void) finish_frame(self, 0, &still_open);
        clay_perl_exit_if_pending(aTHX_ self);
    }
    /* Taking the held error also resets Clay's measure cache when a failed
     * measurement may have been cached, so it runs before the frame. */
    SV *leftover = clay_perl_take_held_error(aTHX_ self, " (from the previous unfinished frame)");
    if (leftover) croak_sv(leftover);

    sweep_retained(aTHX_ self);
    Clay_BeginLayout();
    self->layout_state = CLAY_PERL_LAYOUT_DECLARING;
    reset_open_elements(self);
}

/* Croaks for elements left open at Clay_EndLayout, appending a held
 * callback error message when one is held as well. A held exception
 * object is re-thrown unchanged instead (the elements are closed either
 * way). */
static void croak_unbalanced(pTHX_ clay_perl_context *self, int32_t still_open)
{
    SV *held = clay_perl_take_held_error(aTHX_ self, NULL);
    if (held && SvROK(held)) croak_sv(held);

    SV *message = sv_2mortal(newSVpvf(
        "%d element%s still open at Clay_EndLayout "
        "(unbalanced Clay__OpenElement/Clay__CloseElement)",
        (int) still_open, still_open == 1 ? "" : "s"));
    if (held) {
        sv_catpvs(message, "; callback error: ");
        sv_catsv(message, held);
    }
    croak_sv(message);
}

Clay_RenderCommandArray clay_perl_frame_end(pTHX_ clay_perl_context *self, float delta_time)
{
    if (self->layout_state != CLAY_PERL_LAYOUT_DECLARING) {
        croak("Clay_EndLayout: called without a matching Clay_BeginLayout");
    }
    /* Closes what is still open, so Clay's state stays consistent. */
    int32_t still_open;
    Clay_RenderCommandArray commands = finish_frame(self, delta_time, &still_open);
    clay_perl_exit_if_pending(aTHX_ self);
    if (still_open > 0) croak_unbalanced(aTHX_ self, still_open);
    return commands;
}

/* ---------------------------------------------------------------------------
 * Element bookkeeping.
 * ------------------------------------------------------------------------ */

void clay_perl_frame_element_opened(clay_perl_context *self)
{
    self->open_depth++;
    self->open_element_configurable = true;
}

void clay_perl_frame_element_configured(pTHX_ clay_perl_context *self, const char *who)
{
    if (!self->open_element_configurable) {
        croak("%s: the open element is already configured or has children; "
              "configure an element once, right after opening it", who);
    }
    self->open_element_configurable = false;
}

void clay_perl_frame_text_element_opened(clay_perl_context *self)
{
    self->open_element_configurable = false;
}

void clay_perl_frame_element_closed(clay_perl_context *self)
{
    self->open_depth--;
    self->open_element_configurable = false;
}

/* ---------------------------------------------------------------------------
 * Statistics.
 * ------------------------------------------------------------------------ */

static UV chunk_count(const clay_perl_arena_chunk *chunk)
{
    UV count = 0;
    for (; chunk; chunk = chunk->next) count++;
    return count;
}

SV *clay_perl_frame_stats(pTHX_ const clay_perl_context *self)
{
    static const char *const layout_states[] = { "complete", "declaring" };
    HV *stats = newHV();
    (void) hv_stores(stats, "arena_chunks",
                     newSVuv(chunk_count(self->strings.current) + chunk_count(self->strings.retained)));
    (void) hv_stores(stats, "interned_ids",     newSVuv(HvUSEDKEYS(self->interned_ids)));
    (void) hv_stores(stats, "hover_entries",    newSVuv(HvUSEDKEYS(self->hover_callbacks)));
    (void) hv_stores(stats, "layout_state",     newSVpv(layout_states[self->layout_state], 0));
    (void) hv_stores(stats, "open_depth",       newSViv(self->open_depth));
    (void) hv_stores(stats, "completed_frames", newSVuv(self->completed_frames));
    (void) hv_stores(stats, "callback_depth",   newSVuv(clay_perl_callback_depth));
    return newRV_noinc((SV *) stats);
}
