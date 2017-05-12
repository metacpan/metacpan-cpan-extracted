
#include "collision2d.h"

MODULE = Collision::2D::Entity::Circle 	PACKAGE = Collision::2D::Entity::Circle    PREFIX = circle_

 # _new -- used internally
Circle *
circle__new (CLASS, x, y, xv, yv, relative_x, relative_y, relative_xv, relative_yv, radius)
	char* CLASS
	float  x
	float  y
	float  xv
	float  yv
	float  relative_x
	float  relative_y
	float  relative_xv
	float  relative_yv
	float  radius
	CODE:
		RETVAL = (Circle *) safemalloc (sizeof(Circle));
		RETVAL->x = x;
		RETVAL->y = y;
		RETVAL->radius = radius;
		RETVAL->xv = xv;
		RETVAL->yv = yv;
		RETVAL->relative_x = relative_x;
		RETVAL->relative_y = relative_y;
		RETVAL->relative_xv = relative_xv;
		RETVAL->relative_yv = relative_yv;
	OUTPUT:
		RETVAL



float
circle_radius ( self )
	Circle *self
	CODE:
		RETVAL = self->radius;
	OUTPUT:
		RETVAL



void
circle_DESTROY(self)
	Circle *self
	CODE:
		safefree( (char *)self );
