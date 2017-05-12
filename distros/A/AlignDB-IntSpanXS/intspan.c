#include "intspan.h"

veci* veci_create(size_t capacity) {
    veci *v = (veci *)malloc(sizeof(veci));

    v->size = 0;
    v->capacity = capacity;
    v->elements = (int *)malloc(capacity * sizeof(int));
    v->elements[0] = MY_I32_MAX;

    return v;
}

void veci_destroy(veci *v) {
    free(v->elements);
    free(v);
}

void veci_insert(veci *v, size_t index, int element) {
    size_t i;

    if (v->size >= v->capacity - 1) {
        v->capacity = v->capacity * 2;
        v->elements = (int *)realloc(v->elements, v->capacity * sizeof(int));
    }

    if (element != MY_I32_MAX) {
        for (i = v->size; i > index; i--) {
            v->elements[i] = v->elements[i - 1];
        }
        v->elements[index] = element;
        v->size++;
    }
}

void veci_add(veci *v, int element) {
    veci_insert(v, (v)->size, element);
}

int veci_remove(veci *v, size_t index) {
    int element = v->elements[index];
    size_t i;
    for (i = index + 1; i < v->size; i++) {
        v->elements[i - 1] = v->elements[i];
    }
    v->size--;
    v->elements[v->size] = MY_I32_MAX;
    return element;
}

void veci_clear(veci *v) {
    while (v->size) {
        v->elements[--(v->size)] = MY_I32_MAX;
    }
}

int* veci_to_array(veci *v) {
    return (int *)v->elements;
}

intspan* intspan_new(void) {
    intspan *this_intspan = (intspan *)malloc(sizeof(intspan));
    this_intspan->edge_ =  veci_create(1024);

    return this_intspan;
}

void intspan_destroy(intspan *this_intspan) {
    veci_destroy(this_intspan->edge_);
    free(this_intspan);
}

veci* intspan_edges(intspan *this_intspan) {
    return this_intspan->edge_;
}

void intspan_clear(intspan *this_intspan) {
    veci_clear(this_intspan->edge_);
}

int intspan_edge_size(intspan *this_intspan) {
    return veci_size(this_intspan->edge_);
}

int intspan_edge_capacity(intspan *this_intspan) {
    return this_intspan->edge_->capacity;
}

int intspan_is_empty(intspan *this_intspan) {
    return intspan_edge_size(this_intspan) == 0;
}

int intspan_is_not_empty(intspan *this_intspan) {
    return intspan_edge_size(this_intspan) != 0;
}

int intspan_is_neg_inf(intspan *this_intspan) {
    veci * edges = intspan_edges(this_intspan);
    return veci_get(edges, 0) == NEG_INF;
}

int intspan_is_pos_inf(intspan *this_intspan) {
    veci * edges = intspan_edges(this_intspan);
    int size = veci_size(edges);
    return veci_get(edges, size - 1) == POS_INF;
}

int intspan_is_infinite(intspan *this_intspan) {
    return intspan_is_neg_inf(this_intspan) || intspan_is_pos_inf(this_intspan);
}

int intspan_is_finite(intspan *this_intspan) {
    return ! intspan_is_infinite(this_intspan);
}

int intspan_is_universal(intspan *this_intspan) {
    return intspan_edge_size(this_intspan) == 2 && intspan_is_neg_inf(this_intspan) && intspan_is_pos_inf(this_intspan);
}

int intspan_span_size(intspan *this_intspan) {
    return intspan_edge_size(this_intspan) / 2;
}

void intspan_as_string(intspan *this_intspan, char **runlist, int len) {
    if (intspan_is_empty(this_intspan)) {
        strcpy(*runlist, EMPTY_STRING);
        return;
    }

    if (len == 0) {
        len = 1024;
    }
    strcpy(*runlist, "");

    int i, lower, upper;
    int first_flag = 1;
    veci *edges = intspan_edges(this_intspan);
    int buf_size = 512;
    char buf[buf_size];
    for (i = 0; i <  intspan_span_size(this_intspan); i++) {
        strcpy(buf, "");
        lower = veci_get(edges, i * 2);
        upper = veci_get(edges, i * 2 + 1) - 1;
        if (first_flag) {
            first_flag = 0;
            if (lower == upper) {
                sprintf(buf, "%d", lower);
            } else {
                sprintf(buf, "%d-%d", lower, upper);
            }
        } else {
            if (lower == upper) {
                sprintf(buf, ",%d", lower);
            } else {
                sprintf(buf, ",%d-%d", lower, upper);
            }
        }

        if (len - strlen(*runlist) < buf_size) {
            len = strlen(*runlist) + buf_size + 1;
            kroundup32(len);
            *runlist = (char *) realloc(*runlist, len);
        }
        strncat(*runlist, buf, buf_size);
    }
    return;
}

veci* intspan_as_veci(intspan *this_intspan) {
    veci *elements = veci_create(1024);
    int i, j, lower, upper;
    veci *edges;
    if (intspan_is_empty(this_intspan)) {
        return elements;
    }

    edges = intspan_edges(this_intspan);
    for (i = 0; i <  intspan_span_size(this_intspan); i++) {
        lower = veci_get(edges, i * 2);
        upper = veci_get(edges, i * 2 + 1) - 1;

        if (lower == upper) {
            veci_add(elements, lower);
        } else {
            for (j = lower; j <= upper; j++) {
                veci_add(elements, j);
            }
        }
    }

    return elements;
}

veci* intspan_ranges(intspan *this_intspan) {
    veci *ranges = veci_create(1024);
    if (intspan_is_empty(this_intspan)) {
        return ranges;
    }

    int i, lower, upper;
    veci *edges = intspan_edges(this_intspan);
    for (i = 0; i <  intspan_span_size(this_intspan); i++) {
        lower = veci_get(edges, i * 2);
        upper = veci_get(edges, i * 2 + 1) - 1;
        veci_add(ranges, lower);
        veci_add(ranges, upper);
    }
    return ranges;
}

int intspan_cardinality(intspan *this_intspan) {
    int card = 0;

    int i, lower, upper;
    veci *edges = intspan_edges(this_intspan);
    for (i = 0; i <  intspan_span_size(this_intspan); i++) {
        lower = veci_get(edges, i * 2);
        upper = veci_get(edges, i * 2 + 1) - 1;

        card += upper - lower + 1;
    }

    return card;
}

int intspan_find_pos(intspan *this_intspan, int val, int low) {
    int high = intspan_edge_size(this_intspan);
    veci *edge = intspan_edges(this_intspan);

    while (low < high) {
        int mid = (low + high) / 2;
        if (val < veci_get(edge, mid)) {
            high = mid;
        } else if (val > veci_get(edge, mid)) {
            low  = mid + 1;
        } else {
            return mid;
        }
    }

    return low;
}

int intspan_contains(intspan *this_intspan, int val) {
    int pos;
    pos = intspan_find_pos(this_intspan, val + 1, 0);
    if (pos & 1) {
        return 1;
    } else {
        return 0;
    }
}

int intspan_contains_all(intspan *this_intspan, veci *vec) {
    int i, j;
    for (i = 0; i < veci_size(vec); i++) {
        j = veci_get(vec, i);
        if (!intspan_contains(this_intspan, j)) {
            return 0;
        }
    }
    return 1;
}

int intspan_contains_any(intspan *this_intspan, veci *vec) {
    int i, j;
    for (i = 0; i < veci_size(vec); i++) {
        j = veci_get(vec, i);
        if (intspan_contains(this_intspan, j)) {
            return 1;
        }
    }
    return 0;
}

veci* veci_to_range(veci *vec) {
    int size = veci_size(vec);
    int *ary;
    ary = veci_to_array(vec);
    qsort(ary, size, sizeof(int), compare_int);

    veci *ranges = veci_create(64);
    int pos = 0;
    int end;
    while (pos < size) {
        end = pos + 1;
        while ((end < size) && (ary[end] <= ary[end - 1] + 1)) {
            ++end;
        }
        veci_add(ranges, ary[pos]);
        veci_add(ranges, ary[end - 1]);
        pos = end;
    }

    return ranges;
}

veci* runlist_to_range(char *runlist) {
    veci *ranges = veci_create(64);
    if (strcmp(EMPTY_STRING, runlist) == 0) {
        return ranges;
    }

    char str[strlen(runlist) + 1], *token;
    strcpy(str, runlist);
    int lower, upper;
    int number;
    for (token = strtok(str, ",");
         token != NULL;
         token = strtok(NULL, ",")
        ) {

        number = sscanf(token, "%d-%d", &lower, &upper);
        if (number == 1) {
            upper = lower;
        }
        veci_add(ranges, lower);
        veci_add(ranges, upper);
    }
    return ranges;
}

void intspan_add_range(intspan *this_intspan, veci *ranges) {
    int i, lower, upper;
    for (i = 0; i <  veci_size(ranges) / 2; i++) {
        lower = veci_get(ranges, i * 2);
        upper = veci_get(ranges, i * 2 + 1);

        intspan_add_pair(this_intspan, lower, upper);
    }
}

void intspan_add_pair(intspan *this_intspan, int lower, int upper) {
    int i, lower_pos, upper_pos;
    upper++;
    veci *edge = intspan_edges(this_intspan);

    lower_pos = intspan_find_pos(this_intspan, lower, 0);
    upper_pos = intspan_find_pos(this_intspan, upper + 1, lower_pos);

    if (lower_pos & 1) {
        lower = veci_get(edge, --lower_pos);
    }
    if (upper_pos & 1) {
        upper = veci_get(edge, upper_pos++);
    }

    for (i = lower_pos; i < upper_pos; i++) {
        veci_remove(edge, lower_pos);
    }
    veci_insert(edge, lower_pos, lower);
    veci_insert(edge, lower_pos + 1, upper);
}

void intspan_add(intspan *this_intspan, int val) {
    intspan_add_pair(this_intspan, val, val);
}

void intspan_add_vec(intspan *this_intspan, veci *vec) {
    veci *ranges = veci_to_range(vec);
    intspan_add_range(this_intspan, ranges);
    veci_destroy(ranges);
}

void intspan_add_runlist(intspan *this_intspan, char *runlist) {
    veci *ranges = runlist_to_range(runlist);
    intspan_add_range(this_intspan, ranges);
    veci_destroy(ranges);
}

void intspan_invert(intspan *this_intspan) {
    veci *edge = intspan_edges(this_intspan);
    if (intspan_is_empty(this_intspan)) {
        veci_add(edge, NEG_INF);
        veci_add(edge, POS_INF);
    } else {
        if (veci_get(edge, 0) == NEG_INF) {
            veci_remove(edge, 0);
        } else {
            veci_insert(edge, 0, NEG_INF);
        }

        if (veci_get(edge, veci_size(edge) - 1) == POS_INF) {
            veci_remove(edge, veci_size(edge) - 1);
        } else {
            veci_add(edge, POS_INF);
        }
    }
}

void intspan_remove_pair(intspan *this_intspan, int lower, int upper) {
    intspan_invert(this_intspan);
    intspan_add_pair(this_intspan, lower, upper);
    intspan_invert(this_intspan);
}

void intspan_remove_range(intspan *this_intspan, veci *ranges) {
    intspan_invert(this_intspan);
    intspan_add_range(this_intspan, ranges);
    intspan_invert(this_intspan);
}

void intspan_remove(intspan *this_intspan, int val) {
    intspan_invert(this_intspan);
    intspan_add_pair(this_intspan, val, val);
    intspan_invert(this_intspan);
}

void intspan_remove_vec(intspan *this_intspan, veci *vec) {
    veci *ranges = veci_to_range(vec);
    intspan_remove_range(this_intspan, ranges);
    veci_destroy(ranges);
}

void intspan_remove_runlist(intspan *this_intspan, char *runlist) {
    veci *ranges = runlist_to_range(runlist);
    intspan_remove_range(this_intspan, ranges);
    veci_destroy(ranges);
}

// operate current set
void intspan_merge(intspan *this_intspan, intspan *supplied) {
    veci *ranges = intspan_ranges(supplied);
    intspan_add_range(this_intspan, ranges);
    veci_destroy(ranges);
}

void intspan_subtract(intspan *this_intspan, intspan *supplied) {
    veci *ranges = intspan_ranges(supplied);
    intspan_remove_range(this_intspan, ranges);
    veci_destroy(ranges);
}

intspan* intspan_copy(intspan* this_intspan) {
    veci * this_edges = intspan_edges(this_intspan);

    intspan *copy_intspan = intspan_new();
    veci * copy_edges = intspan_edges(copy_intspan);

    int i, j;

    for (i = 0; i <  veci_size(this_edges); i++) {
        j = veci_get(this_edges, i);
        veci_add(copy_edges, j);
    }

    return copy_intspan;
}
