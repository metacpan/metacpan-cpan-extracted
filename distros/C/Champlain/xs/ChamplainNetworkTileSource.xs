#include "champlain-perl.h"


MODULE = Champlain::NetworkTileSource  PACKAGE = Champlain::NetworkTileSource  PREFIX = champlain_network_tile_source_


ChamplainNetworkTileSource*
champlain_network_tile_source_new_full (class, const gchar *id, const gchar *name, const gchar *license, const gchar *license_uri, guint min_zoom, guint max_zoom, guint tile_size, ChamplainMapProjection projection, const gchar *uri_format)
	C_ARGS: id, name, license, license_uri, min_zoom, max_zoom, tile_size, projection, uri_format


const gchar*
champlain_network_tile_source_get_uri_format (ChamplainNetworkTileSource *tile_source)


void
champlain_network_tile_source_set_uri_format (ChamplainNetworkTileSource *tile_source, const gchar *uri_format)


gboolean
champlain_network_tile_source_get_offline (ChamplainNetworkTileSource *tile_source)


void
champlain_network_tile_source_set_offline (ChamplainNetworkTileSource *tile_source, gboolean offline)


const gchar*
champlain_network_tile_source_get_proxy_uri (ChamplainNetworkTileSource *tile_source)


void
champlain_network_tile_source_set_proxy_uri (ChamplainNetworkTileSource *tile_source, const gchar *proxy_uri)
