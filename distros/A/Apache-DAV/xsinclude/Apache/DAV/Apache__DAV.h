

#include "httpd.h"
#include "http_config.h"
#include "http_core.h"
#include "http_log.h"
#include "http_main.h"
#include "http_protocol.h"
#include "http_request.h"
#include "util_script.h"



struct priv_xs_propdb /* not exported by mod_dav.h */
    {
    int	    version ;
    pool    *p ;
    } ;


dav_get_props_result * glue_dav_get_props(dav_propdb * db, dav_xml_doc *doc)

    {
    struct priv_xs_propdb * pdb = (struct priv_xs_propdb * )db ;
    dav_get_props_result * result = (dav_get_props_result *)ap_palloc (pdb -> p, sizeof (dav_get_props_result)) ;
    *result = dav_get_props(db, doc) ;

    return result ;
    }

dav_get_props_result * glue_dav_get_allprops(dav_propdb * db, int getvals)

    {
    struct priv_xs_propdb * pdb = (struct priv_xs_propdb * )db ;
    dav_get_props_result * result = (dav_get_props_result *)ap_palloc (pdb -> p, sizeof (dav_get_props_result)) ;
    *result = dav_get_allprops(db, getvals) ;

    return result ;
    }


