#include "champlain-perl.h"

static GPerlCallback*
champlainperl_constructor_create (SV *func, SV *data) {
	GType param_types [] = {
		CHAMPLAIN_TYPE_MAP_SOURCE_DESC,
	};
	return gperl_callback_new(
		func, data,
		G_N_ELEMENTS(param_types), param_types,
		CHAMPLAIN_TYPE_MAP_SOURCE
	);
}


static ChamplainMapSource*
champlainperl_constructor (ChamplainMapSourceDesc *desc, gpointer data) {
	GPerlCallback *callback = (GPerlCallback *) data;
	GValue return_value = { 0, };
	ChamplainMapSource *retval;
	
	if (callback == NULL) {
		croak("Chammplain::MapSourceFactory constructor callback is missing the data parameter");
	}
	
	g_value_init(&return_value, callback->return_type);
	/* FIXME desc is not passed as a Champlain::MapSourceDesc to the perl callback */
	gperl_callback_invoke(callback, &return_value, desc, callback->data);
	
	retval = g_value_get_object(&return_value);
	g_value_unset(&return_value);
	
	return retval;
}


/**
 * Returns the value of the given key or croaks if there's no such key.
 */
static SV*
champlainperl_fetch_or_croak (HV* hash , const char* key , I32 klen) {

	SV **s = hv_fetch(hash, key, klen, 0);
	if (s != NULL && SvOK(*s)) {
		return *s;
	}
	
	croak("Hashref requires the key: '%s'", key);
}


static ChamplainMapSourceDesc*
champlainperl_SvChamplainMapSourceDesc (SV *data) {
	HV *hash;
	SV *value;
	ChamplainMapSourceDesc desc = {0,};

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV)) {
		croak("SvChamplainMapSourceDesc: value must be an hashref");
	}

	hash = (HV *) SvRV(data);
	
	/* All keys are mandatory */
	if (value = champlainperl_fetch_or_croak(hash, "id", 2)) {
		desc.id = g_strdup(SvGChar(value));
	}
	
	if (value = champlainperl_fetch_or_croak(hash, "name", 4)) {
		desc.name = g_strdup(SvGChar(value));
	}
	
	if (value = champlainperl_fetch_or_croak(hash, "license", 7)) {
		desc.license = g_strdup(SvGChar(value));
	}
	
	if (value = champlainperl_fetch_or_croak(hash, "license_uri", 11)) {
		desc.license_uri = g_strdup(SvGChar(value));
	}
	
	if (value = champlainperl_fetch_or_croak(hash, "min_zoom_level", 14)) {
		desc.min_zoom_level = (gint) SvIV(value);
	}
	
	if (value = champlainperl_fetch_or_croak(hash, "max_zoom_level", 14)) {
		desc.max_zoom_level = (gint) SvIV(value);
	}
	
	if (value = champlainperl_fetch_or_croak(hash, "projection", 10)) {
		desc.projection = SvChamplainMapProjection(value);
	}
	
	if (value = champlainperl_fetch_or_croak(hash, "uri_format", 10)) {
		desc.uri_format = g_strdup(SvGChar(value));
	}

	return g_memdup(&desc, sizeof(desc));
}


MODULE = Champlain::MapSourceFactory  PACKAGE = Champlain::MapSourceFactory  PREFIX = champlain_map_source_factory_


ChamplainMapSourceFactory*
champlain_map_source_factory_dup_default (class)
	C_ARGS: /* No args */


void
champlain_map_source_factory_dup_list (ChamplainMapSourceFactory *factory)
	PREINIT:
		GSList *list = NULL;
		GSList *item = NULL;
	
	PPCODE:
		list = champlain_map_source_factory_dup_list(factory);
		
		for (item = list; item != NULL; item = item->next) {
			ChamplainMapSourceDesc *desc = CHAMPLAIN_MAP_SOURCE_DESC(item->data);
			XPUSHs(sv_2mortal(newSVChamplainMapSourceDesc(desc)));
		}
		
		g_slist_free(list);


ChamplainMapSource*
champlain_map_source_factory_create (ChamplainMapSourceFactory *factory, const gchar *id)


gboolean
champlain_map_source_factory_register (ChamplainMapSourceFactory *factory, SV *sv_desc, SV* sv_constructor, SV *sv_data=NULL)
	PREINIT:
		ChamplainMapSourceDesc *desc = NULL;
		SV *sv = NULL;
		GPerlCallback *callback = NULL;
	
	CODE:
		desc = champlainperl_SvChamplainMapSourceDesc(sv_desc);
		callback = champlainperl_constructor_create(sv_constructor, sv_data);
		RETVAL = champlain_map_source_factory_register(factory, desc, champlainperl_constructor, callback);

	OUTPUT:
		RETVAL


const gchar*
OSM_MAPNIK (class)
	CODE:
		RETVAL = CHAMPLAIN_MAP_SOURCE_OSM_MAPNIK;

	OUTPUT:
		RETVAL


const gchar*
OSM_OSMARENDER (class)
	CODE:
		RETVAL = CHAMPLAIN_MAP_SOURCE_OSM_OSMARENDER;

	OUTPUT:
		RETVAL


const gchar*
OSM_CYCLE_MAP (class)
	CODE:
		RETVAL = CHAMPLAIN_MAP_SOURCE_OSM_CYCLE_MAP;

	OUTPUT:
		RETVAL


const gchar*
OAM (class)
	CODE:
		RETVAL = CHAMPLAIN_MAP_SOURCE_OAM;

	OUTPUT:
		RETVAL


const gchar*
MFF_RELIEF (class)
	CODE:
		RETVAL = CHAMPLAIN_MAP_SOURCE_MFF_RELIEF;

	OUTPUT:
		RETVAL


#ifdef CHAMPLAINPERL_MEMPHIS

const gchar*
MEMPHIS_LOCAL_DESC (class)
	CODE:
		RETVAL = CHAMPLAIN_MAP_SOURCE_MEMPHIS_LOCAL;

	OUTPUT:
		RETVAL


const gchar*
MEMPHIS_NETWORK_DESC (class)
	CODE:
		RETVAL = CHAMPLAIN_MAP_SOURCE_MEMPHIS_NETWORK;

	OUTPUT:
		RETVAL

#endif

ChamplainMapSource*
champlain_map_source_factory_create_cached_source (ChamplainMapSourceFactory *factory, const gchar *id)
