#ifndef TREE_H
#define TREE_H

# include "src/Listable.h"

typedef struct {
	Listable listable;
	int is_default;
	int is_unrooted;
} Tree;

void initialize_tree(Tree* self);

#endif
