#include "champlain-perl.h"


MODULE = Champlain::LocalMapDataSource  PACKAGE = Champlain::LocalMapDataSource  PREFIX = champlain_local_map_data_source_


ChamplainLocalMapDataSource*
champlain_local_map_data_source_new (class)
	C_ARGS: /* no args */


void
champlain_local_map_data_source_load_map_data (ChamplainLocalMapDataSource *map_data_source, const gchar *map_path);
