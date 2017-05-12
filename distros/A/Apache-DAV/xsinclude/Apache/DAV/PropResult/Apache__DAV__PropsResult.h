

dav_get_props_result * dav_glue_get_props(dav_propdb * db, dav_xml_doc *doc)

    {
    dav_get_props_result * result = (dav_get_props_result *)ap_palloc (db -> p, sizeof (dav_get_props_result)) ;
    *result = dav_get_props(db, doc) ;

    return result ;
    }

dav_get_props_result * dav_glue_get_allprops(dav_propdb * db, int getvals)

    {
    dav_get_props_result * result = (dav_get_props_result *)ap_palloc (db -> p, sizeof (dav_get_props_result)) ;
    *result = dav_get_allprops(db, getvals) ;

    return result ;
    }

