/*
 * clay_impl_helpers.h - Binding helpers compiled together with the Clay
 * implementation in src/clay_impl.c.
 *
 * They read Clay internals (struct Clay_Context, the default counts, the
 * arena allocation routines) that the public clay.h API does not expose.
 * This header is Perl-free so src/clay_impl.c stays a pure Clay
 * compilation unit; src/clay_perl.h includes it for the rest of the
 * binding.
 */

#ifndef CLAY_IMPL_HELPERS_H
#define CLAY_IMPL_HELPERS_H

#include <stdbool.h>
#include <stdint.h>

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

/* True while the current context's frame has more elements than its
 * element count allows: Clay then drops every further element, and
 * configuring or hovering one does nothing. */
bool clay_perl_clay_max_elements_exceeded(void);

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
