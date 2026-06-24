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

enum ShapeType {
	shape_rectangle,
	shape_circle
};

struct Shape {
	ShapeType type;
	double x, y, x2, y2;
	double radius;

	double x0, y0;
	double radius_sq;
};

struct QuadTreeNode {
	QuadTreeNode *children;
	QuadTreeNode *parent;
	DynArr *values;
	Shape *dimensions;
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


typedef enum ShapeType ShapeType;

Shape* create_shape();
void prepare_rectangle(Shape *s, double x, double y, double x2, double y2);
void prepare_circle(Shape *s, double x0, double y0, double radius);
void destroy_shape(Shape *s);

DynArr* create_array();
void destroy_array(DynArr* arr);
void push_array(DynArr *arr, void *ptr);

QuadTreeNode* create_nodes(int count, QuadTreeNode *parent);
void destroy_node(QuadTreeNode *node);
QuadTreeRootNode* create_root();

void adopt_object (QuadTreeRootNode *root, SV *value, Shape *s);
void disown_object (QuadTreeRootNode *root, SV *value);

void node_add_level(QuadTreeNode* node, double xmin, double ymin, double xmax, double ymax, int depth);
void find_nodes(QuadTreeNode *node, HV *ret, Shape *param, bool fully_contained);
bool fill_nodes(QuadTreeNode *node, SV *value, Shape *param);
void delete_nodes(QuadTreeNode *node, SV *value, Shape *param, bool fully_contained);
void clear_tree(QuadTreeRootNode *root);

void filter_geometry(HV* results, HV* shapes, Shape *s);

/* XS helpers */

SV* get_hash_key (HV* hash, const char* key, int len);
QuadTreeRootNode* get_root_from_perl(SV *self);
AV* get_hash_values (HV* hash);

#endif

