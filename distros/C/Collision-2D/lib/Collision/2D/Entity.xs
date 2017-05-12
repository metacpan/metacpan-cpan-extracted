
#include "collision2d.h"

MODULE = Collision::2D::Entity 	PACKAGE = Collision::2D::Entity    PREFIX = ent_


 # _new -- do we need this?
Entity *
ent_new (CLASS)
	char* CLASS
	CODE:
		RETVAL = (Entity *) safemalloc (sizeof(Entity));
		RETVAL->x = 0;
		RETVAL->y = 0;
		RETVAL->xv = 0;
		RETVAL->yv = 0;
		RETVAL->relative_x = 0;
		RETVAL->relative_y = 0;
		RETVAL->relative_xv = 0;
		RETVAL->relative_yv = 0;

	OUTPUT:
		RETVAL

float
ent_x ( ent )
	Entity *ent
	CODE:
	//	if (items > 1 ) ent->x = SvIV(ST(1)); 
		RETVAL = ent->x;
	OUTPUT:
		RETVAL

float
ent_y ( ent )
	Entity *ent
	CODE:
	//	if (items > 1 ) ent->y = SvIV(ST(1)); 
		RETVAL = ent->y;
	OUTPUT:
		RETVAL
      
float
ent_xv ( ent )
	Entity *ent
	CODE:
	//	if (items > 1 ) ent->xv = SvIV(ST(1)); 
		RETVAL = ent->xv;
	OUTPUT:
		RETVAL

float
ent_yv ( ent )
	Entity *ent
	CODE:
	//	if (items > 1 ) ent->yv = SvIV(ST(1)); 
		RETVAL = ent->yv;
	OUTPUT:
		RETVAL

float
ent_relative_x ( ent, ... )
	Entity *ent
	CODE:
		if (items > 1 ) ent->relative_x = SvIV(ST(1)); 
		RETVAL = ent->relative_x;
	OUTPUT:
		RETVAL

float
ent_relative_y ( ent, ... )
	Entity *ent
	CODE:
		if (items > 1 ) ent->relative_y = SvIV(ST(1)); 
		RETVAL = ent->relative_y;
	OUTPUT:
		RETVAL

float
ent_relative_xv ( ent, ... )
	Entity *ent
	CODE:
		if (items > 1 ) ent->relative_xv = SvIV(ST(1)); 
		RETVAL = ent->relative_xv;
	OUTPUT:
		RETVAL

float
ent_relative_yv ( ent, ... )
	Entity *ent
	CODE:
		if (items > 1 ) ent->relative_yv = SvIV(ST(1)); 
		RETVAL = ent->relative_yv;
	OUTPUT:
		RETVAL


void
ent_normalize ( ent, other, ... )
	Entity *ent
	Entity *other
	CODE:
		ent->relative_x = ent->x - other->x;
		ent->relative_y = ent->y - other->y;
		ent->relative_xv = ent->xv - other->xv;
		ent->relative_yv = ent->yv - other->yv;



void
ent_DESTROY(self)
	Entity *self
	CODE:
		safefree( (char *)self );
