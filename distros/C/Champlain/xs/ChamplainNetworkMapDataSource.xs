#include "champlain-perl.h"


MODULE = Champlain::NetworkMapDataSource  PACKAGE = Champlain::NetworkMapDataSource  PREFIX = champlain_network_map_data_source_



ChamplainNetworkMapDataSource*
champlain_network_map_data_source_new (class)
	C_ARGS: /* No args */


void
champlain_network_map_data_source_load_map_data (ChamplainNetworkMapDataSource *map_data_source, gdouble bound_left, gdouble bound_bottom, gdouble bound_right, gdouble bound_top)


const gchar*
champlain_network_map_data_source_get_api_uri (ChamplainNetworkMapDataSource *map_data_source)


void
champlain_network_map_data_source_set_api_uri (ChamplainNetworkMapDataSource *map_data_source, const gchar *api_uri)
