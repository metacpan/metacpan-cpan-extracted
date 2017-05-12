#include "champlain-perl.h"


MODULE = Champlain::TileSource  PACKAGE = Champlain::TileSource  PREFIX = champlain_tile_source_


ChamplainTileCache*
champlain_tile_source_get_cache (ChamplainTileSource *tile_source)


void
champlain_tile_source_set_cache (ChamplainTileSource *tile_source, ChamplainTileCache *cache)


void
champlain_tile_source_set_id (ChamplainTileSource *tile_source, const gchar *id)


void
champlain_tile_source_set_name (ChamplainTileSource *tile_source, const gchar *name)


void
champlain_tile_source_set_license (ChamplainTileSource *tile_source, const gchar *license)


void
champlain_tile_source_set_license_uri (ChamplainTileSource *tile_source, const gchar *license_uri)


void
champlain_tile_source_set_min_zoom_level (ChamplainTileSource *tile_source, guint zoom_level)


void
champlain_tile_source_set_max_zoom_level (ChamplainTileSource *tile_source, guint zoom_level)


void
champlain_tile_source_set_tile_size (ChamplainTileSource *tile_source, guint tile_size)


void
champlain_tile_source_set_projection (ChamplainTileSource *tile_source, ChamplainMapProjection projection)
