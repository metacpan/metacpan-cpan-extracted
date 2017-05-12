#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include "b_stack.h"

b_stack *b_stack_new(size_t grow_by) {
    b_stack *stack;
    size_t growth_factor = grow_by > 0? grow_by: B_STACK_DEFAULT_GROWTH_FACTOR;

    if ((stack = malloc(sizeof(*stack))) == NULL) {
        goto error_malloc_stack;
    }

    if ((stack->items = calloc(growth_factor, sizeof(void *))) == NULL) {
        goto error_malloc_items;
    }

    stack->size          = growth_factor;
    stack->count         = 0;
    stack->growth_factor = growth_factor;
    stack->destructor    = NULL;

    return stack;

error_malloc_items:
    free(stack);

error_malloc_stack:
    return NULL;
}

void b_stack_set_destructor(b_stack *stack, void (*destructor)(void *)) {
    stack->destructor = destructor;
}

static void **b_stack_resize(b_stack *stack, size_t newsize) {
    void **newitems;

    if (newsize == 0) {
        return stack->items;
    }

    if ((newitems = realloc(stack->items, newsize * sizeof(void *))) == NULL) {
        goto error_realloc;
    }

    stack->size  = newsize;
    stack->items = newitems;

    return newitems;

error_realloc:
    return NULL;
}

void *b_stack_push(b_stack *stack, void *item) {
    size_t index;

    if (stack->count == stack->size) {
        if (b_stack_resize(stack, stack->size + stack->growth_factor) == NULL) {
            goto error_resize;
        }
    }

    index = stack->count;

    stack->items[index] = item;
    stack->count++;

    return item;

error_resize:
    return NULL;
}

void *b_stack_pop(b_stack *stack) {
    size_t index;
    void *item;

    if (stack == NULL)     return NULL;
    if (stack->count == 0) return NULL;

    index = stack->count - 1;
    item  = stack->items[index];

    stack->items[index] = NULL;
    stack->count--;

    if (index == stack->size - (stack->growth_factor * 2)) {
        if (b_stack_resize(stack, stack->size - stack->growth_factor) == NULL) {
            goto error_resize;
        }
    }

    return item;

error_resize:
    return NULL;
}

void *b_stack_shift(b_stack *stack) {
    size_t i, last;
    void *item;

    if (stack == NULL)     return NULL;
    if (stack->count == 0) return NULL;

    last = stack->count - 1;
    item = stack->items[0];

    for (i=1; i<stack->count; i++) {
        stack->items[i-1] = stack->items[i];
    }

    stack->items[last] = NULL;
    stack->count--;

    if (last == stack->size - (stack->growth_factor * 2)) {
        if (b_stack_resize(stack, stack->size - stack->growth_factor) == NULL) {
            goto error_resize;
        }
    }

    return item;

error_resize:
    return NULL;
}

void *b_stack_top(b_stack *stack) {
    if (stack == NULL)     return NULL;
    if (stack->count == 0) return NULL;

    return stack->items[stack->count - 1];
}

void *b_stack_item_at(b_stack *stack, size_t index) {
    if (index >= stack->count) return NULL;

    return stack->items[index];
}

size_t b_stack_count(b_stack *stack) {
    return stack->count;
}

b_stack *b_stack_reverse(b_stack *stack) {
    size_t i;
    size_t limit = stack->count / 2;

    for (i=0; i<limit; i++) {
        size_t opposite = stack->count - 1 - i;
        void *tmp = stack->items[i];

        stack->items[i]        = stack->items[opposite];
        stack->items[opposite] = tmp;
    }

    return stack;
}

void b_stack_destroy(b_stack *stack) {
    size_t i;

    if (stack == NULL) return;

    if (stack->destructor) {
        for (i=0; i<stack->count; i++) {
            stack->destructor(stack->items[i]);
            stack->items[i] = NULL;
        }
    }

    free(stack->items);
    stack->items = NULL;

    free(stack);
}
