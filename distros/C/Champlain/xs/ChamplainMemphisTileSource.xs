#include "champlain-perl.h"


MODULE = Champlain::MemphisTileSource  PACKAGE = Champlain::MemphisTileSource  PREFIX = champlain_memphis_tile_source_


ChamplainMemphisTileSource*
champlain_memphis_tile_source_new_full (class, const gchar *id, const gchar *name, const gchar *license, const gchar *license_uri, guint min_zoom, guint max_zoom, guint tile_size, ChamplainMapProjection projection, ChamplainMapDataSource *map_data_source)
	C_ARGS: id, name, license, license_uri, min_zoom, max_zoom, tile_size, projection, map_data_source


void
champlain_memphis_tile_source_load_rules (ChamplainMemphisTileSource *tile_source, const gchar *rules_path)


void
champlain_memphis_tile_source_set_map_data_source (ChamplainMemphisTileSource *tile_source, ChamplainMapDataSource *map_data_source)


ChamplainMapDataSource*
champlain_memphis_tile_source_get_map_data_source (ChamplainMemphisTileSource *tile_source)


ClutterColor*
champlain_memphis_tile_source_get_background_color (ChamplainMemphisTileSource *tile_source)


void
champlain_memphis_tile_source_set_background_color (ChamplainMemphisTileSource *tile_source, const ClutterColor *color)


void
champlain_memphis_tile_source_get_rule_ids (ChamplainMemphisTileSource *tile_source)
	PREINIT:
		GList *list = NULL;
		GList *item = NULL;

	PPCODE:
		list = champlain_memphis_tile_source_get_rule_ids(tile_source);
		if (!list) {
			XSRETURN_EMPTY;
		}

		for (item = list; item != NULL; item = item->next) {
			gchar *id = (gchar *) item->data;
			XPUSHs(sv_2mortal(newSVGChar(id)));
		}

		g_list_free(list);


void
champlain_memphis_tile_source_set_rule (ChamplainMemphisTileSource *tile_source, MemphisRule *rule)


MemphisRule*
champlain_memphis_tile_source_get_rule (ChamplainMemphisTileSource *tile_source, const gchar *id)


void
champlain_memphis_tile_source_remove_rule (ChamplainMemphisTileSource *tile_source, const gchar *id)
