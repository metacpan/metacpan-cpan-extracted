
#include "collision2d.h"

MODULE = Collision::2D::Entity::Rect 	PACKAGE = Collision::2D::Entity::Rect    PREFIX = rect_

 # _new -- used internally
Rect *
rect__new (CLASS, x, y, xv, yv, relative_x, relative_y, relative_xv, relative_yv, w, h)
	char* CLASS
	float  x
	float  y
	float  xv
	float  yv
	float  relative_x
	float  relative_y
	float  relative_xv
	float  relative_yv
   float  w
   float  h
	CODE:
		RETVAL = (Rect *) safemalloc (sizeof(Rect));
		RETVAL->x = x;
		RETVAL->y = y;
		RETVAL->w = w;
		RETVAL->h = h;
		RETVAL->xv = xv;
		RETVAL->yv = yv;
		RETVAL->relative_x = relative_x;
		RETVAL->relative_y = relative_y;
		RETVAL->relative_xv = relative_xv;
		RETVAL->relative_yv = relative_yv;

	OUTPUT:
		RETVAL





float
rect_w ( self )
	Rect *self
	CODE:
		RETVAL = self->w;
	OUTPUT:
		RETVAL

float
rect_h ( self )
	Rect *self
	CODE:
		RETVAL = self->h;
	OUTPUT:
		RETVAL


void
rect_DESTROY(self)
	Rect *self
	CODE:
		safefree( (char *)self );
