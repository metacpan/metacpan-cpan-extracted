#ifndef INTSPAN_H_
#define INTSPAN_H_

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

// from kseq.h
// rounded to the next closest 2^k
#ifndef kroundup32
#define kroundup32(x)                                          \
    (--(x), (x) |= (x) >> 1, (x) |= (x) >> 2, (x) |= (x) >> 4, \
     (x) |= (x) >> 8, (x) |= (x) >> 16, ++(x))
#endif

enum {
    MY_I32_MAX = 2147483647,
    MY_I32_MIN = (-2147483647 - 1)
};

typedef struct {
    size_t size, capacity;
    int *elements;
} veci;

veci* veci_create(size_t);
void veci_destroy(veci *);

#define veci_size(v) (v)->size

void veci_insert(veci *, size_t, int);
void veci_add(veci *, int);

#define veci_set(v, index, element) (v)->elements[index] = element

int veci_remove(veci *, size_t);

#define veci_get(v, index) (v)->elements[index]

void veci_clear(veci *);

int* veci_to_array(veci *v);

typedef struct {
    veci *edge_;
} intspan;

enum {
    POS_INF = MY_I32_MAX - 1,
    NEG_INF = MY_I32_MIN + 1
};
static const char EMPTY_STRING[] = "-";

intspan* intspan_new(void);
void intspan_destroy(intspan *);

veci* intspan_edges(intspan *);
int intspan_edge_size(intspan *);
int intspan_edge_capacity(intspan *);

void intspan_clear(intspan *);
int intspan_is_empty(intspan *);
int intspan_is_not_empty(intspan *);

int intspan_is_neg_inf(intspan *);
int intspan_is_pos_inf(intspan *);
int intspan_is_infinite(intspan *);
int intspan_is_finite(intspan *);
int intspan_is_universal(intspan *);

int intspan_span_size(intspan *);

void intspan_as_string(intspan *, char **, int);
veci* intspan_as_veci(intspan *);

veci* intspan_ranges(intspan *);

int intspan_cardinality(intspan *);

int intspan_find_pos(intspan *, int, int);

int intspan_contains(intspan *, int);
int intspan_contains_all(intspan *, veci *);
int intspan_contains_any(intspan *, veci *);

/* for qsort */
static int compare_int(const void *a, const void *b) {
    return (*(int *)a - *(int *)b);
}
veci* veci_to_range(veci *);
veci* runlist_to_range(char *);

void intspan_add_range(intspan *, veci *);
void intspan_add_pair(intspan *, int, int);
void intspan_add(intspan *, int);
void intspan_add_vec(intspan *, veci *);
void intspan_add_runlist(intspan *, char *);

void intspan_invert(intspan *);

void intspan_remove_pair(intspan *, int, int);
void intspan_remove_range(intspan *, veci *);
void intspan_remove(intspan *, int);
void intspan_remove_vec(intspan *, veci *);
void intspan_remove_runlist(intspan *, char *);

void intspan_merge(intspan *, intspan *);
void intspan_subtract(intspan *, intspan *);

intspan* intspan_copy(intspan*);

#endif
