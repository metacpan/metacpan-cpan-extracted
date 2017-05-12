#include "champlain-perl.h"


MODULE = Champlain::Polygon  PACKAGE = Champlain::Polygon  PREFIX = champlain_polygon_


ChamplainPolygon*
champlain_polygon_new (class)
	C_ARGS: /* No args */


ChamplainPoint*
champlain_polygon_append_point (ChamplainPolygon *polygon, gdouble lat, gdouble lon)


ChamplainPoint*
champlain_polygon_insert_point (ChamplainPolygon *polygon, gdouble lat, gdouble lon, gint pos)


void
champlain_polygon_clear_points (ChamplainPolygon *polygon)


void
champlain_polygon_get_points (ChamplainPolygon *polygon)
	PREINIT:
		GList *item = NULL;
	
	PPCODE:
		item = champlain_polygon_get_points(polygon);

		if (!item) {
			XSRETURN_EMPTY;
		}

		for (; item != NULL; item = item->next) {
			ChamplainPoint *point = CHAMPLAIN_POINT(item->data);
			XPUSHs(sv_2mortal(newSVChamplainPoint(point)));
		}
		
		/* The doc says that the list shouldn't be freed! */


void
champlain_polygon_set_fill_color (ChamplainPolygon *polygon, const ClutterColor *color)


void
champlain_polygon_set_stroke_color (ChamplainPolygon *polygon, const ClutterColor *color)


ClutterColor*
champlain_polygon_get_fill_color (ChamplainPolygon *polygon)


ClutterColor*
champlain_polygon_get_stroke_color (ChamplainPolygon *polygon)


gboolean
champlain_polygon_get_fill (ChamplainPolygon *polygon)


void
champlain_polygon_set_fill (ChamplainPolygon *polygon, gboolean value)


gboolean
champlain_polygon_get_stroke (ChamplainPolygon *polygon)


void
champlain_polygon_set_stroke (ChamplainPolygon *polygon, gboolean value)


void
champlain_polygon_set_stroke_width (ChamplainPolygon *polygon, gdouble value)


gdouble
champlain_polygon_get_stroke_width (ChamplainPolygon *polygon)


void
champlain_polygon_show (ChamplainPolygon *polygon)


void
champlain_polygon_hide (ChamplainPolygon *polygon)


void
champlain_polygon_remove_point (ChamplainPolygon *self, ChamplainPoint *point)


void
champlain_polygon_set_mark_points (ChamplainPolygon *polygon, gboolean value)


gboolean
champlain_polygon_get_mark_points (ChamplainPolygon *polygon)
