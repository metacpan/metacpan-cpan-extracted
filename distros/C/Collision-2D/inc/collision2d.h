
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef aTHX_
#define aTHX_
#endif


#define ENTITY_AS(ENT_TYPE) \
typedef struct ENT_TYPE{ \
   float x, y; \
   float xv, yv;\
   float relative_x, relative_y;\
   float relative_xv, relative_yv;\
   float radius; \
   float h,w; \
   AV* table; \
   int cells_x, cells_y; \
   float cell_size; \
} ENT_TYPE;

ENTITY_AS(Entity)
ENTITY_AS(Circle)
ENTITY_AS(Point)
ENTITY_AS(Rect)
ENTITY_AS(Grid)



enum AXIS_TYPE {NO_AXIS, XORY_AXIS, VECTOR_AXIS};
//enum AXIS_XORY {X_AXIS, Y_AXIS};

typedef struct Collision{
   SV* ent1;
   SV* ent2;
   float time;
   int axis_type;
   char axis; // 'x' or 'y', if XORY_AXIS
   float axis_x; // if VECTOR_AXIS
   float axis_y; // if VECTOR_AXIS
} Collision;



