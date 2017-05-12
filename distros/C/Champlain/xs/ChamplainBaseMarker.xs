#include "champlain-perl.h"


MODULE = Champlain::BaseMarker  PACKAGE = Champlain::BaseMarker  PREFIX = champlain_base_marker_


ClutterActor*
champlain_base_marker_new (class)
	C_ARGS: /* No args */


void
champlain_base_marker_set_position (ChamplainBaseMarker *marker, gdouble longitude, gdouble latitude)


void
champlain_base_marker_set_highlighted (ChamplainBaseMarker *champlainBaseMarker, gboolean value)


gboolean
champlain_base_marker_get_highlighted (ChamplainBaseMarker *champlainBaseMarker)


void
champlain_base_marker_animate_in (ChamplainBaseMarker *marker)


void
champlain_base_marker_animate_in_with_delay (ChamplainBaseMarker *marker, guint delay)


void
champlain_base_marker_animate_out (ChamplainBaseMarker *marker)


void
champlain_base_marker_animate_out_with_delay (ChamplainBaseMarker *marker, guint delay)


gdouble
champlain_base_marker_get_latitude (ChamplainBaseMarker *marker)


gdouble
champlain_base_marker_get_longitude (ChamplainBaseMarker *marker)
