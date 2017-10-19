#ifndef LISTABLE_H
#define LISTABLE_H

# include "src/Identifiable.h"
# include "src/Writable.h"

typedef struct {
	Writable writable;
    AV* entities;
    int index;
} Listable;

void initialize_listable(Listable* self);
void insert_at_index(Listable* self, Identifiable* element, int index);
void insert(Listable* self, Identifiable* element);
AV* get_entities(Listable* self);
void splice_at_index(Listable* self, Identifiable* element, int index);
void destroy_listable(Listable* self);

#endif
