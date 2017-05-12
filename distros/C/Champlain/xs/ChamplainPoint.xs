#include "champlain-perl.h"


MODULE = Champlain::Point  PACKAGE = Champlain::Point  PREFIX = champlain_point_


ChamplainPoint*
champlain_point_new (class, gdouble lat, gdouble lon)
	C_ARGS: lat, lon


ChamplainPoint*
champlain_point_copy (const ChamplainPoint* point)


void
champlain_point_free (ChamplainPoint* point)


#
# Provide nice accessors to the data members of the struct.
#
gdouble
lat (ChamplainPoint *point, gdouble newval = 0)
	ALIAS:
		lon = 1

	CODE:
		switch (ix) {
			case 0:
				RETVAL = point->lat;
				if (items > 1) point->lat = newval;
			break;

			case 1:
				RETVAL = point->lon;
				if (items > 1) point->lon = newval;
			break;

			default:
				RETVAL = 0.0;
				g_assert_not_reached();
			break;
		}

	OUTPUT:
		RETVAL
