#include "champlain-perl.h"


MODULE = Champlain::MapDataSource  PACKAGE = Champlain::MapDataSource  PREFIX = champlain_map_data_source_


MemphisMap*
champlain_map_data_source_get_map_data (ChamplainMapDataSource *data_source)
