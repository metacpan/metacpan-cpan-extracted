/*
 * clay_impl.c - The one and only compilation unit that materialises the
 * Clay v0.14 implementation, plus the few binding helpers that need to
 * see Clay's internals (declared in src/clay_impl_helpers.h).
 *
 * Clay is a header-only library. The convention requires exactly one .c
 * file in the project to define CLAY_IMPLEMENTATION before including
 * clay.h; every other file includes clay.h normally and gets only the
 * declarations. The helpers below live here because struct Clay_Context
 * and the default counts are only visible inside the implementation
 * section. This file includes no Perl headers.
 *
 * The diagnostic suppression below silences four categories of warning
 * that Clay v0.14 emits under -Wall -Wextra. They are upstream issues
 * (unused locals, sign mismatch in a comparison, a partially initialised
 * compound literal) and are not bugs in
 * the binding. Suppressing them here keeps Clay::XS's own diagnostic
 * output clean for users running tests under default flags.
 */

#if defined(__GNUC__) || defined(__clang__)
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wunused-variable"
# pragma GCC diagnostic ignored "-Wunused-function"
# pragma GCC diagnostic ignored "-Wsign-compare"
# pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#define CLAY_IMPLEMENTATION
#include "clay/clay.h"

#if defined(__GNUC__) || defined(__clang__)
# pragma GCC diagnostic pop
#endif

#include "clay_impl_helpers.h"

#include <stdlib.h>

/* Upper bound on the alignment padding Clay adds between its arena arrays:
 * less than 64 bytes per array, and Clay allocates fewer than 64 arrays. */
#define CLAY_PERL_ALIGNMENT_SLACK ((uint64_t) 64 * 64)

/* Unless the frame exceeded the element cap, Clay_EndLayout clones every
 * element with an exit transition and its subtree into the top of
 * layoutElements
 * (Clay__CloneElementsWithExitTransition), with their children in the top
 * of layoutElementChildren and their id strings at the same indices of
 * layoutElementIdStrings. The walk follows those clones from each exiting
 * transition's elementThisFrame, depth first, with an explicit stack:
 * every index is checked against the arrays' capacity, and an element is
 * never visited twice. */
static bool is_exiting(const Clay__TransitionDataInternal *transition)
{
    return transition->state == CLAY_TRANSITION_STATE_EXITING || transition->transitionOut;
}

static void visit_element_buffers(Clay_Context *context, int32_t index,
                                  clay_perl_buffer_visitor visit, void *data)
{
    const Clay_LayoutElement *element = &context->layoutElements.internalArray[index];
    if (element->isTextElement && element->textElementData.text.length > 0) {
        visit(element->textElementData.text.chars, data);
    }
    const Clay_String *id_string = &context->layoutElementIdStrings.internalArray[index];
    if (id_string->length > 0 && id_string->chars) {
        visit(id_string->chars, data);
    }
}

void clay_perl_clay_visit_exiting_buffers(clay_perl_buffer_visitor visit, void *data)
{
    Clay_Context *context = Clay_GetCurrentContext();
    if (!context) return;

    bool any_exiting = false;
    for (int32_t i = 0; i < context->transitionDatas.length && !any_exiting; ++i) {
        any_exiting = is_exiting(&context->transitionDatas.internalArray[i]);
    }
    if (!any_exiting) return;

    /* A frame over the element cap makes no clones and drops every exit
     * transition (patches/0004), so nothing exits after it; an exiting
     * transition left then would not point at a clone. Report the walk
     * incomplete. */
    int32_t capacity = context->layoutElements.capacity;
    if (context->booleanWarnings.maxElementsExceeded || capacity <= 0) {
        visit(NULL, data);
        return;
    }

    int32_t *stack   = (int32_t *) malloc(sizeof(int32_t) * (size_t) capacity);
    bool    *visited = (bool *) calloc((size_t) capacity, sizeof(bool));
    if (!stack || !visited) {
        free(stack);
        free(visited);
        visit(NULL, data);   /* tells the caller the walk is incomplete */
        return;
    }

    for (int32_t i = 0; i < context->transitionDatas.length; ++i) {
        const Clay__TransitionDataInternal *transition = &context->transitionDatas.internalArray[i];
        if (!is_exiting(transition)) continue;
        if (!transition->elementThisFrame) continue;
        int32_t root = (int32_t) (transition->elementThisFrame - context->layoutElements.internalArray);
        if (root < 0 || root >= capacity || visited[root]) continue;

        int32_t depth = 0;
        stack[depth++] = root;
        visited[root] = true;
        while (depth > 0) {
            int32_t index = stack[--depth];
            visit_element_buffers(context, index, visit, data);
            const Clay_LayoutElement *element = &context->layoutElements.internalArray[index];
            if (element->isTextElement || !element->children.elements) continue;
            for (int32_t j = 0; j < element->children.length; ++j) {
                int32_t child = element->children.elements[j];
                if (child < 0 || child >= capacity || visited[child]) continue;
                visited[child] = true;
                stack[depth++] = child;
            }
        }
    }
    free(stack);
    free(visited);
}

void clay_perl_clay_default_counts(int32_t *element_count, int32_t *word_count)
{
    *element_count = Clay__defaultMaxElementCount;
    *word_count    = Clay__defaultMaxMeasureTextWordCacheCount;
}

bool clay_perl_clay_open_text_element(Clay_String text, Clay_TextElementConfig config, Clay_ElementId *id)
{
    Clay_Context *context = Clay_GetCurrentContext();
    int32_t index = context->layoutElements.length;
    Clay__OpenTextElement(text, config);
    if (context->layoutElements.length == index) return false;   /* dropped at the cap */

    Clay_LayoutElement *element = &context->layoutElements.internalArray[index];
    const Clay_LayoutElementHashMapItem *item = Clay__GetHashMapItem(element->id);
    if (item->layoutElement != element) return false;
    *id = item->elementId;
    return true;
}

bool clay_perl_clay_max_elements_exceeded(void)
{
    return Clay_GetCurrentContext()->booleanWarnings.maxElementsExceeded;
}

int32_t clay_perl_clay_declarable_elements(void)
{
    Clay_Context *context = Clay_GetCurrentContext();
    if (context->booleanWarnings.maxElementsExceeded) return 0;
    int32_t free_slots = context->layoutElements.capacity - 1 - context->exitingElementsLength
                       - context->layoutElements.length;
    return free_slots > 0 ? free_slots : 0;
}

bool clay_perl_clay_scroll_container_declared(uint32_t element_id)
{
    Clay_Context *context = Clay_GetCurrentContext();
    for (int32_t i = 0; i < context->scrollContainerDatas.length; i++) {
        const Clay__ScrollContainerDataInternal *data = Clay__ScrollContainerDataInternalArray_Get(&context->scrollContainerDatas, i);
        if (data->elementId == element_id) return data->generation == context->generation;
    }
    return false;
}

void clay_perl_clay_release_pointer(void)
{
    Clay_GetCurrentContext()->pointerInfo.state = CLAY_POINTER_DATA_RELEASED;
}

void clay_perl_clay_cancel_scroll_momentum(uint32_t element_id)
{
    Clay_Context *context = Clay_GetCurrentContext();
    for (int32_t i = 0; i < context->scrollContainerDatas.length; i++) {
        Clay__ScrollContainerDataInternal *data = Clay__ScrollContainerDataInternalArray_Get(&context->scrollContainerDatas, i);
        if (data->elementId != element_id) continue;
        data->scrollMomentum = CLAY__INIT(Clay_Vector2) CLAY__DEFAULT_STRUCT;
        return;
    }
}

/* Clay_MinMemorySize and Clay_Initialize read the counts of the current
 * context or, with none, Clay's process-wide defaults. Both helpers below
 * hand them explicit counts that way: they make the counts the defaults,
 * call Clay with no current context and put the defaults back. No Perl
 * code can change the defaults meanwhile (the callbacks Clay_Initialize
 * may run cannot call the setters), so they always come back. */
typedef struct {
    int32_t element_count;
    int32_t word_count;
} default_counts;

static default_counts swap_default_counts(default_counts counts)
{
    default_counts previous = { Clay__defaultMaxElementCount, Clay__defaultMaxMeasureTextWordCacheCount };
    Clay__defaultMaxElementCount              = counts.element_count;
    Clay__defaultMaxMeasureTextWordCacheCount = counts.word_count;
    return previous;
}

uint32_t clay_perl_clay_min_memory_size(int32_t element_count, int32_t word_count)
{
    default_counts counts = { element_count, word_count };
    Clay_Context *current = Clay_GetCurrentContext();
    default_counts previous = swap_default_counts(counts);
    Clay_SetCurrentContext(NULL);
    uint32_t size = Clay_MinMemorySize();
    Clay_SetCurrentContext(current);
    swap_default_counts(previous);
    return size;
}

Clay_Context *clay_perl_clay_initialize(Clay_Arena arena, Clay_Dimensions dimensions, Clay_ErrorHandler handler,
                                        int32_t element_count, int32_t word_count)
{
    default_counts counts = { element_count, word_count };
    default_counts previous = swap_default_counts(counts);
    Clay_SetCurrentContext(NULL);
    Clay_Context *context = Clay_Initialize(arena, dimensions, handler);
    swap_default_counts(previous);
    return context;
}

/* Bytes the sizing-group patch spends beyond 2 x element_count int32 slots:
 * it rounds its hash table up to the next power of two of at least
 * 2 x maxElementCount slots (see Clay__InitializeEphemeralMemory). */
static uint64_t sizing_group_slot_rounding(int32_t element_count)
{
    uint64_t wanted = 2 * (uint64_t) element_count;
    uint64_t slots  = 1;
    while (slots < wanted) slots *= 2;
    return (slots - wanted) * sizeof(int32_t);
}

/* Clay's arena size is affine in the two counts except for alignment
 * padding and the sizing-group table's power-of-two rounding: with both
 * counts a power of two of at least 64, every count-sized array is a
 * multiple of 64 bytes and the table is exactly 2 x count slots, so the
 * per-element and per-word costs fall out exactly from three small
 * probes. The bound adds the table rounding and the worst-case padding
 * for arbitrary counts. */
uint64_t clay_perl_clay_arena_bytes_upper_bound(int32_t element_count, int32_t word_count)
{
    uint64_t base        = clay_perl_clay_min_memory_size(64, 64);
    uint64_t per_element = (clay_perl_clay_min_memory_size(128, 64) - base) / 64;
    uint64_t per_word    = (clay_perl_clay_min_memory_size(64, 128) - base) / 64;
    uint64_t fixed       = base - 64 * per_element - 64 * per_word;

    return fixed
         + per_element * (uint64_t) element_count
         + per_word    * (uint64_t) word_count
         + sizing_group_slot_rounding(element_count)
         + CLAY_PERL_ALIGNMENT_SLACK;
}
