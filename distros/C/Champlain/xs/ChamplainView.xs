#include "champlain-perl.h"


MODULE = Champlain::View  PACKAGE = Champlain::View  PREFIX = champlain_view_


ClutterActor*
champlain_view_new (class)
	C_ARGS: /* No args */


void
champlain_view_center_on (ChamplainView *view, gdouble latitude, gdouble longitude)


void
champlain_view_zoom_in (ChamplainView *view)


void
champlain_view_zoom_out (ChamplainView *view)


void
champlain_view_add_layer (ChamplainView *view, ChamplainLayer *layer)


void
champlain_view_get_coords_from_event (ChamplainView *view, ClutterEvent *event, OUTLIST gdouble latitude, OUTLIST gdouble longitude)


void
champlain_view_set_zoom_level (ChamplainView *view, gint zoom_level)


void
champlain_view_set_map_source (ChamplainView *view, ChamplainMapSource *map_source);


void
champlain_view_go_to (ChamplainView *view, gdouble latitude, gdouble longitude)


void
champlain_view_stop_go_to (ChamplainView *view)


void
champlain_view_set_min_zoom_level (ChamplainView *view, gint zoom_level)


void
champlain_view_set_max_zoom_level (ChamplainView *view, gint zoom_level)


void
champlain_view_ensure_visible (ChamplainView *view, gdouble lat1, gdouble lon1, gdouble lat2, gdouble lon2, gboolean animate)


void
champlain_view_set_decel_rate (ChamplainView *view, gdouble rate)


void
champlain_view_set_scroll_mode (ChamplainView *view, ChamplainScrollMode mode)


void
champlain_view_set_keep_center_on_resize (ChamplainView *view, gboolean value)


void
champlain_view_set_show_license (ChamplainView *view, gboolean value)


void
champlain_view_set_zoom_on_double_click (ChamplainView *view, gboolean value)


void
champlain_view_get_coords_at (ChamplainView *view, guint x, guint y, OUTLIST gdouble latitude, OUTLIST gdouble longitude)


void
champlain_view_ensure_markers_visible (ChamplainView *view, AV *av_markers, gboolean animate)
	PREINIT:
		ChamplainBaseMarker** markers = NULL;
		int i = 0;
		int last_index = 0;
	
	CODE:
		last_index = av_len(av_markers);
		markers = g_new0(ChamplainBaseMarker*, last_index + 2); /* size + NULL ended */
		
		for (i = last_index; i >= 0; --i) {
			SV **sv_ref = av_fetch(av_markers, i, FALSE);
			ChamplainBaseMarker *marker = SvChamplainBaseMarker(*sv_ref);
			markers[i] = marker;
		}
		
		champlain_view_ensure_markers_visible(view, markers, animate);
		g_free(markers);

gint
champlain_view_get_zoom_level (ChamplainView *view)


gint
champlain_view_get_min_zoom_level (ChamplainView *view)


gint
champlain_view_get_max_zoom_level (ChamplainView *view)


ChamplainMapSource*
champlain_view_get_map_source (ChamplainView *view)

gdouble
champlain_view_get_decel_rate (ChamplainView *view)


ChamplainScrollMode
champlain_view_get_scroll_mode (ChamplainView *view)


gboolean
champlain_view_get_keep_center_on_resize (ChamplainView *view)


gboolean
champlain_view_get_show_license (ChamplainView *view)


gboolean
champlain_view_get_zoom_on_double_click (ChamplainView *view)


void
champlain_view_add_polygon (ChamplainView *view, ChamplainPolygon *polygon)


void
champlain_view_remove_polygon (ChamplainView *view, ChamplainPolygon *polygon)


void
champlain_view_remove_layer (ChamplainView *view, ChamplainLayer *layer)


const gchar_ornull *
champlain_view_get_license_text (ChamplainView *view)


void
champlain_view_set_license_text (ChamplainView *view, const gchar_ornull *text)


guint
champlain_view_get_max_scale_width (ChamplainView *view)


ChamplainUnit
champlain_view_get_scale_unit (ChamplainView *view)


gboolean
champlain_view_get_show_scale (ChamplainView *view)


void
champlain_view_set_max_scale_width (ChamplainView *view, guint value)


void
champlain_view_set_scale_unit (ChamplainView *view, ChamplainUnit unit)


void
champlain_view_set_show_scale (ChamplainView *view, gboolean value)
