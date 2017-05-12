/*
 * Copyright (c) 2014, cPanel, Inc.
 * All rights reserved.
 * http://cpanel.net/
 *
 * This is free software; you can redistribute it and/or modify it under the
 * same terms as Perl itself.  See the Perl manual section 'perlartistic' for
 * further information.
 */

#ifndef _B_STACK_H
#define _B_STACK_H

#include <sys/types.h>

#define B_STACK_DEFAULT_GROWTH_FACTOR 128
#define B_STACK_DESTRUCTOR(ds)        ((void (*)(void *))ds)

typedef struct _b_stack {
    size_t  size;
    size_t  count;
    size_t  growth_factor;
    void ** items;
    void    (*destructor)(void *);
} b_stack;

b_stack * b_stack_new(size_t grow_by);
void      b_stack_set_destructor(b_stack *stack, void (*destructor)(void *));
void *    b_stack_push(b_stack *stack, void *item);
void *    b_stack_pop(b_stack *stack);
void *    b_stack_shift(b_stack *stack);
void *    b_stack_top(b_stack *stack);
void *    b_stack_item_at(b_stack *stack, size_t index);
size_t    b_stack_count(b_stack *stack);
b_stack * b_stack_reverse(b_stack *stack);
void      b_stack_destroy(b_stack *stack);

#endif /* _B_STACK_H */
