#include "champlain-perl.h"


MODULE = Champlain::TileCache  PACKAGE = Champlain::TileCache  PREFIX = champlain_tile_cache_


gboolean
champlain_tile_cache_get_persistent (ChamplainTileCache *tile_cache)


void
champlain_tile_cache_store_tile (ChamplainTileCache *tile_cache, ChamplainTile *tile, SV *sv_contents)
	PREINIT:
		STRLEN length;
		char *contents;

	CODE:
		contents = SvPV(sv_contents, length);
		champlain_tile_cache_store_tile (tile_cache, tile, contents, length);


void
champlain_tile_cache_refresh_tile_time (ChamplainTileCache *tile_cache, ChamplainTile *tile)


void
champlain_tile_cache_on_tile_filled (ChamplainTileCache *tile_cache, ChamplainTile *tile)


void
champlain_tile_cache_clean (ChamplainTileCache *tile_cache)
