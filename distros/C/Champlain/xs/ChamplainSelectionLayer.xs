#include "champlain-perl.h"


MODULE = Champlain::SelectionLayer  PACKAGE = Champlain::SelectionLayer  PREFIX = champlain_selection_layer_


ChamplainLayer*
champlain_selection_layer_new (class)
	C_ARGS: /* No args */


ChamplainBaseMarker*
champlain_selection_layer_get_selected (ChamplainSelectionLayer *layer)


void
champlain_selection_layer_get_selected_markers (ChamplainSelectionLayer *layer)
	PREINIT:
		const GList *item = NULL;
	
	PPCODE:
		item = champlain_selection_layer_get_selected_markers(layer);
		if (!item) {
			XSRETURN_EMPTY;
		}

		for (; item != NULL; item = item->next) {
			ChamplainBaseMarker *marker = CHAMPLAIN_BASE_MARKER(item->data);
			XPUSHs(sv_2mortal(newSVChamplainBaseMarker(marker)));
		}
		
		/* The doc says that the list shouldn't be freed! */


guint
champlain_selection_layer_count_selected_markers (ChamplainSelectionLayer *layer)


void
champlain_selection_layer_select (ChamplainSelectionLayer *layer, ChamplainBaseMarker *marker)


void
champlain_selection_layer_unselect (ChamplainSelectionLayer *layer, ChamplainBaseMarker *marker)


gboolean
champlain_selection_layer_marker_is_selected (ChamplainSelectionLayer *layer, ChamplainBaseMarker *marker)


void
champlain_selection_layer_select_all (ChamplainSelectionLayer *layer)


void
champlain_selection_layer_unselect_all (ChamplainSelectionLayer *layer)


void
champlain_selection_layer_set_selection_mode (ChamplainSelectionLayer *layer, ChamplainSelectionMode mode);


ChamplainSelectionMode
champlain_selection_layer_get_selection_mode (ChamplainSelectionLayer *layer);
