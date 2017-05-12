#include "champlain-perl.h"


MODULE = Champlain::Marker  PACKAGE = Champlain::Marker  PREFIX = champlain_marker_


ClutterActor*
champlain_marker_new (class)
	C_ARGS: /* No args */


ClutterActor*
champlain_marker_new_with_text (class, const gchar *text, const gchar_ornull *font = NULL, ClutterColor_ornull *text_color = NULL, ClutterColor_ornull *marker_color = NULL)
	C_ARGS: text, font, text_color, marker_color


ClutterActor*
champlain_marker_new_from_file (class, const gchar *filename)
	PREINIT:
		GError *error = NULL;

	CODE:
		RETVAL = champlain_marker_new_from_file(filename, &error);
		if (error) {
			gperl_croak_gerror(NULL, error);
		}

	OUTPUT:
		RETVAL


ClutterActor*
champlain_marker_new_full (class, const gchar *text, ClutterActor_ornull *actor)
	C_ARGS: text, actor


ClutterActor*
champlain_marker_new_with_image (class, ClutterActor* actor)
	C_ARGS: actor


void
champlain_marker_set_text (ChamplainMarker *marker, const gchar *text)


void
champlain_marker_set_image (ChamplainMarker *marker, ClutterActor_ornull *image)


void
champlain_marker_set_use_markup (ChamplainMarker *marker, gboolean use_markup)


void
champlain_marker_set_alignment (ChamplainMarker *marker, PangoAlignment alignment)


void
champlain_marker_set_color (ChamplainMarker *marker, const ClutterColor_ornull *color)


void
champlain_marker_set_text_color (ChamplainMarker *marker, const ClutterColor_ornull *color)


void
champlain_marker_set_font_name (ChamplainMarker *marker, const gchar_ornull *font_name)


void
champlain_marker_set_wrap (ChamplainMarker *marker, gboolean wrap)


void
champlain_marker_set_wrap_mode (ChamplainMarker *marker, PangoWrapMode wrap_mode)


void
champlain_marker_set_attributes (ChamplainMarker *marker, PangoAttrList *list)


void
champlain_marker_set_single_line_mode (ChamplainMarker *marker, gboolean mode)


void
champlain_marker_set_ellipsize (ChamplainMarker *marker, PangoEllipsizeMode mode)


void
champlain_marker_set_draw_background (ChamplainMarker *marker, gboolean background)


gboolean
champlain_marker_get_use_markup (ChamplainMarker *marker)


const gchar*
champlain_marker_get_text (ChamplainMarker *marker)


ClutterActor*
champlain_marker_get_image (ChamplainMarker *marker)


PangoAlignment
champlain_marker_get_alignment (ChamplainMarker *marker)


ClutterColor*
champlain_marker_get_color (ChamplainMarker *marker)


ClutterColor*
champlain_marker_get_text_color (ChamplainMarker *marker)


const gchar*
champlain_marker_get_font_name (ChamplainMarker *marker)


gboolean
champlain_marker_get_wrap (ChamplainMarker *marker)


PangoWrapMode
champlain_marker_get_wrap_mode (ChamplainMarker *marker)


PangoEllipsizeMode
champlain_marker_get_ellipsize (ChamplainMarker *marker)


gboolean
champlain_marker_get_single_line_mode (ChamplainMarker *marker)


gboolean
champlain_marker_get_draw_background (ChamplainMarker *marker)


void
champlain_marker_set_highlight_color (class, ClutterColor *color);
	C_ARGS: color


void
champlain_marker_set_highlight_text_color (class, ClutterColor *color);
	C_ARGS: color


const ClutterColor*
champlain_marker_get_highlight_color (class)
	C_ARGS:  /* No args */


const ClutterColor*
champlain_marker_get_highlight_text_color (class)
	C_ARGS:  /* No args */


void
champlain_marker_queue_redraw (ChamplainMarker *marker)
