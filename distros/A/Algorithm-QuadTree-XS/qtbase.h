#ifndef QTBASE_H
#define QTBASE_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct QuadTreeNode QuadTreeNode;
typedef struct QuadTreeRootNode QuadTreeRootNode;
typedef struct DynArr DynArr;
typedef enum ShapeType ShapeType;
typedef struct Shape Shape;

struct QuadTreeNode {
	QuadTreeNode *children;
	QuadTreeNode *parent;
	DynArr *values;
	double xmin, ymin, xmax, ymax;
	bool has_objects;
};

struct QuadTreeRootNode {
	QuadTreeNode *node;
	HV *backref;
	DynArr *objects;
};

struct DynArr {
	void **ptr;
	unsigned int count;
	unsigned int max_size;
};

enum ShapeType {
	shape_rectangle,
	shape_circle
};

struct Shape {
	ShapeType type;
	double dimensions[4];
};


typedef enum ShapeType ShapeType;

DynArr* create_array();
void destroy_array(DynArr* arr);
void push_array(DynArr *arr, void *ptr);
void push_array_SV(DynArr *arr, SV *ptr);
QuadTreeNode* create_nodes(int count, QuadTreeNode *parent);
void destroy_node(QuadTreeNode *node);
void clear_has_objects (QuadTreeNode *node);
QuadTreeRootNode* create_root();
QuadTreeRootNode* create_root_nobackref();
void store_backref(QuadTreeRootNode *root, QuadTreeNode* node, SV *value);
void node_add_level(QuadTreeNode* node, double xmin, double ymin, double xmax, double ymax, int depth);
void find_nodes(QuadTreeNode *node, AV *ret, Shape *param);
bool fill_nodes(QuadTreeRootNode *root, QuadTreeNode *node, SV *value, Shape *param);
bool fill_nodes_nobackref(QuadTreeNode *node, SV *value, Shape *param);
void clear_tree(QuadTreeRootNode *root);

/* XS helpers */

SV* get_hash_key (HV* hash, const char* key);
QuadTreeRootNode* get_root_from_perl(SV *self);

#endif

