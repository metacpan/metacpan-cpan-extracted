#include "champlain-perl.h"


MODULE = Champlain::BoundingBox  PACKAGE = Champlain::BoundingBox  PREFIX = champlain_bounding_box_


ChamplainBoundingBox*
champlain_bounding_box_new (class)
	C_ARGS: /* No args */


ChamplainBoundingBox*
champlain_bounding_box_copy (const ChamplainBoundingBox* box)


void
champlain_bounding_box_free (ChamplainBoundingBox* box)


#
# Provide nice accessors and modifiers to the data members of the struct.
#
SV*
left (ChamplainBoundingBox *box, ...)
	ALIAS:
		bottom = 1
		right  = 2
		top    = 3

	CODE:
		switch (ix) {
			case 0:
				RETVAL = newSVnv(box->left);
				if (items > 1) box->left = (gdouble) SvNV(ST(1));
			break;
			
			case 1:
				RETVAL = newSVnv(box->bottom);
				if (items > 1) box->bottom = (gdouble) SvNV(ST(1));
			break;
			
			case 2:
				RETVAL = newSVnv(box->right);
				if (items > 1) box->right = (gdouble) SvNV(ST(1));
			break;
			
			case 3:
				RETVAL = newSVnv(box->top);
				if (items > 1) box->top = (gdouble) SvNV(ST(1));
			break;
			
			default:
				RETVAL = &PL_sv_undef;
				g_assert_not_reached();
			break;
		}

	OUTPUT:
		RETVAL


void
champlain_bounding_box_get_center (ChamplainBoundingBox *box)
	PREINIT:
		gdouble lat, lon;
	
	PPCODE:
		champlain_bounding_box_get_center(box, &lat, &lon);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(lat)));
		PUSHs(sv_2mortal(newSVnv(lon)));
