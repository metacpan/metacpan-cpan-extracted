
#include "collision2d.h"

MODULE = Collision::2D::Entity::Grid 	PACKAGE = Collision::2D::Entity::Grid    PREFIX = grid_

 # _new -- used internally
Grid *
grid__new (CLASS, x, y, xv, yv, relative_x, relative_y, relative_xv, relative_yv, w,h,cells_x,cells_y,cell_size)
	char* CLASS
	float  x
	float  y
	float  xv
	float  yv
	float  relative_x
	float  relative_y
	float  relative_xv
	float  relative_yv
   int w
   int h
   int cells_x
   int cells_y
   float  cell_size
	CODE:
		RETVAL = (Grid *) safemalloc (sizeof(Grid));
		RETVAL->x = x;
		RETVAL->y = y;
		RETVAL->xv = xv;
		RETVAL->yv = yv;
		RETVAL->relative_x = relative_x;
		RETVAL->relative_y = relative_y;
		RETVAL->relative_xv = relative_xv;
		RETVAL->relative_yv = relative_yv;
		RETVAL->w = w;
		RETVAL->h = h;
		RETVAL->cells_x = cells_x;
		RETVAL->cells_y = cells_y;
		RETVAL->cell_size = cell_size;
		AV* tablaeieu = newAV();
		sv_2mortal((SV*)tablaeieu);
		SvREFCNT_inc ((SV*)tablaeieu);
		RETVAL->table = tablaeieu;
	OUTPUT:
		RETVAL




float
grid_w ( self )
	Grid *self
	CODE:
		RETVAL = self->w;
	OUTPUT:
		RETVAL

float
grid_h ( self )
	Grid *self
	CODE:
		RETVAL = self->h;
	OUTPUT:
		RETVAL

float
grid_cell_size ( self )
	Grid *self
	CODE:
		RETVAL = self->cell_size;
	OUTPUT:
		RETVAL

int
grid_cells_x ( self )
	Grid *self
	CODE:
		RETVAL = self->cells_x;
	OUTPUT:
		RETVAL

int
grid_cells_y ( self )
	Grid *self
	CODE:
		RETVAL = self->cells_y;
	OUTPUT:
		RETVAL

SV*
grid_table ( self )
	Grid *self
	CODE:
	//	RETVAL = self->table;
      RETVAL = newRV_inc((SV*)self->table);
	OUTPUT:
		RETVAL



void
grid_DESTROY(self)
	Grid *self
	CODE:
		SvREFCNT_dec ( (SV*) self->table );
		safefree( (char *)self );
