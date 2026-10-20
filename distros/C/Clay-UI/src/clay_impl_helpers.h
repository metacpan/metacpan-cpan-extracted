/*
 * clay_impl_helpers.h - Binding helpers compiled together with the Clay
 * implementation in src/clay_impl.c.
 *
 * They read Clay internals (struct Clay_Context, the default counts) that
 * the public clay.h API does not expose.
 * This header is Perl-free so src/clay_impl.c stays a pure Clay
 * compilation unit; src/clay_perl.h includes it for the rest of the
 * binding.
 */

#ifndef CLAY_IMPL_HELPERS_H
#define CLAY_IMPL_HELPERS_H

#include <stdbool.h>
#include <stdint.h>

#include "clay/clay.h"

/* Receives one buffer Clay keeps reading (see the visit function below). */
typedef void (*clay_perl_buffer_visitor)(const char *chars, void *data);

/* Calls visit(chars, data) for the text and the id string of every
 * element in the subtrees of the current context's exiting elements:
 * Clay keeps those clones, with the buffers of their last declaration,
 * until the exit transitions finish. Calls visit(NULL, data) when it
 * cannot tell (an exiting transition after a frame over the element cap,
 * which made no clones, or memory ran out): the caller must then keep
 * everything. Only valid while the context holds a completed layout. */
void clay_perl_clay_visit_exiting_buffers(clay_perl_buffer_visitor visit, void *data);

/* Clay's default element and measure-cache word counts, used by
 * Clay_Initialize when no context is current. */
void clay_perl_clay_default_counts(int32_t *element_count, int32_t *word_count);

/* Clay_MinMemorySize() for explicit counts: Clay's own computation,
 * whatever context is current and whatever Clay's defaults are (both are
 * left as they were). Exact only while the arena fits Clay's 32-bit size
 * arithmetic: callers check clay_perl_clay_arena_bytes_upper_bound first. */
uint32_t clay_perl_clay_min_memory_size(int32_t element_count, int32_t word_count);

/* Clay_Initialize(arena, dimensions, handler) for a context with exactly
 * these counts. Clay's defaults and the counts of the previous current
 * context stay as they were. Leaves the new context current; when Clay
 * returns NULL, no context is current. */
Clay_Context *clay_perl_clay_initialize(Clay_Arena arena, Clay_Dimensions dimensions, Clay_ErrorHandler handler,
                                        int32_t element_count, int32_t word_count);

/* Calls Clay__OpenTextElement(text, config) on the current context and
 * reports the id Clay gave the new text element: true with *id the
 * complete id as Clay computed it (read from the element's hash-map item,
 * never recomputed), false when Clay keeps no element under an id for
 * the text: it dropped the text at the element cap, or another element of
 * this frame already holds the id. (Clay also adds no item when its id
 * hash map is full, which its element count keeps from happening: the
 * map is pruned every frame and has a slot per element.) */
bool clay_perl_clay_open_text_element(Clay_String text, Clay_TextElementConfig config, Clay_ElementId *id);

/* True while the current context's frame has more elements than its
 * element count allows: Clay then drops every further element, and
 * configuring or hovering one does nothing. */
bool clay_perl_clay_max_elements_exceeded(void);

/* How many more elements the frame being declared on the current context
 * can hold: Clay stops declaring one slot short of its element count and
 * keeps the slots of the elements still playing an exit transition (see
 * Clay__LayoutElementsFull); 0 once Clay dropped an element. */
int32_t clay_perl_clay_declarable_elements(void);

/* True when the current context's scroll container with that element id
 * was declared in the current frame (or, between frames, in the last
 * completed one): only then does its layout element pointer, through
 * which Clay reads the container's clip config, point at the container.
 * False for an unknown id. */
bool clay_perl_clay_scroll_container_declared(uint32_t element_id);

/* Sets the current context's pointer state to CLAY_POINTER_DATA_RELEASED.
 * Clay zeroes it, and zero is CLAY_POINTER_DATA_PRESSED_THIS_FRAME. */
void clay_perl_clay_release_pointer(void);

/* Drops the drag-scroll momentum of the current context's scroll
 * container with that element id (nothing happens for other ids), so a
 * position written from outside stays put. */
void clay_perl_clay_cancel_scroll_momentum(uint32_t element_id);

/* Upper bound of the arena bytes Clay needs for the given counts, computed
 * in 64 bits. Clay's own size arithmetic is 32-bit and wraps silently, so
 * callers keep this bound below 4 GiB. */
uint64_t clay_perl_clay_arena_bytes_upper_bound(int32_t element_count, int32_t word_count);

#endif /* CLAY_IMPL_HELPERS_H */
