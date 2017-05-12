
#include "collision2d.h"


MODULE = Collision::2D::Collision 	PACKAGE = Collision::2D::Collision    PREFIX = co_


 # _new -- used internally
Collision *
co__new (CLASS, ent1, ent2, time, axis)
	char* CLASS
	SV * ent1
	SV * ent2
	float  time
	SV * axis
	CODE:
		RETVAL = (Collision *) safemalloc (sizeof(Collision));
		RETVAL->ent1 = ent1;
		RETVAL->ent2 = ent2;
		SvREFCNT_inc(ent1);
		SvREFCNT_inc(ent2);
		RETVAL->time = time;
      if (!SvOK(axis)){  //axis is not defined
         RETVAL->axis_type = NO_AXIS;
      } else if (SvROK(axis)) { // axis is arrayref
         AV * axis_arr = (AV*)SvRV(axis);
         SV * axis_x = (*av_fetch (axis_arr, 0, 0));
         RETVAL->axis_x = SvNV(axis_x);
         SV * axis_y = (*av_fetch (axis_arr, 1, 0));
         RETVAL->axis_y = SvNV(axis_y);
         RETVAL->axis_type = VECTOR_AXIS;
      }
      else{
         char * axis_str = SvPV_nolen(axis);
         RETVAL->axis = axis_str[0]; //'x' or 'y'
         RETVAL->axis_type = XORY_AXIS;
      }

	OUTPUT:
		RETVAL


SV *
co_ent1 ( self )
	Collision *self
	PREINIT:
		char* CLASS = "Collision::2D::Entity";
	CODE:
      RETVAL = self->ent1;
      SvREFCNT_inc (RETVAL);
	OUTPUT:
		RETVAL

SV *
co_ent2 ( self )
	Collision *self
	PREINIT:
		char* CLASS = "Collision::2D::Entity";
	CODE:
      RETVAL = self->ent2;
      SvREFCNT_inc (RETVAL);
	OUTPUT:
		RETVAL

float
co_time ( self )
	Collision *self
	CODE:
		RETVAL = self->time;
	OUTPUT:
		RETVAL

float
co_axis_type ( self )
	Collision *self
	CODE:
		RETVAL = self->axis_type;
	OUTPUT:
		RETVAL

SV *
co_axis ( self )
	Collision *self
	CODE:
      if (self->axis_type == NO_AXIS){
         RETVAL = newSVsv(&PL_sv_undef);
      }else if (self->axis_type == XORY_AXIS){
         RETVAL = newSVpvn (&self->axis, 1);
      }
      else{ //VECTOR_AXIS
         AV* axis_vec = newAV();
         av_push (axis_vec, newSVnv(self->axis_x));
         av_push (axis_vec, newSVnv(self->axis_y));
         RETVAL = newRV_inc((SV*) axis_vec);
      }
	OUTPUT:
		RETVAL


SV *
co_vaxis ( self )
   Collision *self
   ALIAS:
      maxis = 1
   CODE:
      if ( self->axis_type == NO_AXIS ){
         RETVAL = newSVsv(&PL_sv_undef);
      }
      else if (self->axis_type == VECTOR_AXIS) {
         AV* axis_vec = newAV();
         sv_2mortal((SV*)axis_vec);
         av_push (axis_vec, newSVnv(self->axis_x));
         av_push (axis_vec, newSVnv(self->axis_y));
         RETVAL = newRV_inc((SV*) axis_vec);
      } 
      else { //XORY_AXIS
         void** pointers = (void**)(SvIV((SV*)SvRV( self->ent1 ))); 
         Entity * ent1 = (Entity*)(pointers[0]);
         pointers = (void**)(SvIV((SV*)SvRV( self->ent2 ))); 
         Entity * ent2 = (Entity*)(pointers[0]);
         if (self->axis == 'x'){
            AV* axis_vec = newAV();
            sv_2mortal((SV*)axis_vec);
            if (ent1->xv - ent2->xv > 0){
               av_push (axis_vec, newSViv(1));
            } else {
               av_push (axis_vec, newSViv(-1));
            }
            av_push (axis_vec, newSViv(0));
            RETVAL = newRV_inc((SV*) axis_vec);
         } else { //'y'
            AV* axis_vec = newAV();
            sv_2mortal((SV*)axis_vec);
            av_push (axis_vec, newSViv(0));
            if (ent1->yv - ent2->yv > 0){
               av_push (axis_vec, newSViv(1));
            } else {
               av_push (axis_vec, newSViv(-1));
            }
            RETVAL = newRV_inc((SV*) axis_vec);
         }
      }
   OUTPUT:
      RETVAL



void
co_DESTROY(self)
	Collision *self
	CODE:
		SvREFCNT_dec ( (SV*) self->ent1 );
		SvREFCNT_dec ( (SV*) self->ent2 );
		safefree( (char *)self );


 // axis type constants

int
co_NO_AXIS()
	CODE:
      RETVAL = NO_AXIS;
   OUTPUT:
      RETVAL

int
co_XORY_AXIS()
	CODE:
      RETVAL = XORY_AXIS;
   OUTPUT:
      RETVAL
      
int
co_VECTOR_AXIS()
	CODE:
      RETVAL = VECTOR_AXIS;
   OUTPUT:
      RETVAL


