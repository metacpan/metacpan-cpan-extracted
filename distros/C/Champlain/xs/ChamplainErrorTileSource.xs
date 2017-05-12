#include "champlain-perl.h"


MODULE = Champlain::ErrorTileSource  PACKAGE = Champlain::ErrorTileSource  PREFIX = champlain_error_tile_source_


ChamplainErrorTileSource*
champlain_error_tile_source_new_full (class, guint tile_size)
	C_ARGS: tile_size
