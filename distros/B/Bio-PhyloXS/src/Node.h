#ifndef NODE_H
#define NODE_H

# include "src/Listable.h"
# include "src/Tree.h"

typedef struct Node {
	Listable listable;
	double branch_length;
	struct Node* parent;
	char * rank;
	Tree* tree;
} Node;

void initialize_node(Node* self);

#endif