#include "champlain-perl.h"


MODULE = Champlain::Layer  PACKAGE = Champlain::Layer  PREFIX = champlain_layer_


ChamplainLayer*
champlain_layer_new (class)
	C_ARGS: /* No args */


void
champlain_layer_add_marker (ChamplainLayer *layer, ChamplainBaseMarker *marker)


void
champlain_layer_hide (ChamplainLayer *layer)


void
champlain_layer_show (ChamplainLayer *layer)


void
champlain_layer_remove_marker (ChamplainLayer *layer, ChamplainBaseMarker *marker)


void
champlain_layer_animate_in_all_markers (ChamplainLayer *layer)


void
champlain_layer_animate_out_all_markers (ChamplainLayer *layer)


void
champlain_layer_hide_all_markers (ChamplainLayer *layer)


void
champlain_layer_show_all_markers (ChamplainLayer *layer)
