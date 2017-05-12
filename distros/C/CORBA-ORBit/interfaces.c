/* -*- mode: C; c-file-style: "bsd" -*- */

#include "errors.h"
#include "interfaces.h"
#include "globals.h"
#include "types.h"

/* Forward declarations */
XS(_porbit_callStub);

static CORBA_Repository iface_repository = NULL;

PORBitIfaceInfo *
porbit_find_interface_description (const char *repoid) 
{
    HV *hv = perl_get_hv("CORBA::ORBit::_interfaces", TRUE);
    SV **result = hv_fetch (hv, (char *)repoid, strlen(repoid), 0);
    
    if (!result)
	return NULL;
    else
	return (PORBitIfaceInfo *)SvIV(*result);
}

static void
free_interface_info (PORBitIfaceInfo *info)
{
    g_free (info->pkg);
    CORBA_free (info->desc);
    g_free (info);
}

static PORBitIfaceInfo *
store_interface_description (CORBA_InterfaceDef_FullInterfaceDescription *desc,
			     const char *package_name)
{
    SV *pkg_sv;
    char *varname;

    HV *hv = perl_get_hv("CORBA::ORBit::_interfaces", TRUE);
    PORBitIfaceInfo *info = g_new (PORBitIfaceInfo, 1);

    info->pkg = g_strdup (package_name);

    info->desc = desc;
    info->class_id = 0;
    
    hv_store (hv, (char *)desc->id, strlen (desc->id), newSViv((IV)info), 0);

    varname = g_strconcat (info->pkg, "::", PORBIT_REPOID_KEY, NULL);
    pkg_sv = perl_get_sv (varname, TRUE );
    g_free (varname);
    
    sv_setpv (pkg_sv, desc->id);
    
    return info;
}

static gboolean
ensure_iface_repository (CORBA_Environment *ev)
{
    if (iface_repository == NULL)
	iface_repository = CORBA_ORB_resolve_initial_references(porbit_orb, "InterfaceRepository", ev);
    
    if (ev->_major != CORBA_NO_EXCEPTION || iface_repository == NULL) {
	
	CORBA_exception_set_system (ev, ex_CORBA_INTF_REPOS, CORBA_COMPLETED_NO);
	warn("Cannot locate interface repository");
	return FALSE;
    }

    return TRUE;
}

static void
define_exception (const char *repoid, CORBA_Environment *ev)
{
    CORBA_char *pack = NULL;
    char *pkg;
    CORBA_Contained contained = NULL;
    
    if (porbit_find_exception(repoid))
	return;

    if (!ensure_iface_repository (ev))
	goto error;
    
    contained = CORBA_Repository_lookup_id (iface_repository, ((char *)repoid), ev);
    if (ev->_major != CORBA_NO_EXCEPTION)
	goto error;

    pack = CORBA_Contained__get_absolute_name (contained, ev);
    if (ev->_major != CORBA_NO_EXCEPTION)
	goto error;

    pkg = pack;
    if (!strncmp(pkg, "::", 2))
	pkg += 2;

    porbit_setup_exception (repoid, pkg, "CORBA::UserException");

 error:
    if (pack)
	CORBA_free (pack);
    if (contained)
	CORBA_Object_release (contained, ev);
}

static void
define_method (const char *pkg, const char *prefix, const char *name, I32 index)
{
    gchar *fullname = g_strconcat (pkg, prefix, name, NULL);

    CV *method_cv = newXS ((char *)fullname, _porbit_callStub, __FILE__); 
    CvXSUBANY(method_cv).any_i32 = index;
    CvSTASH (method_cv) = gv_stashpv ((char *)pkg, 0);
      
    g_free (fullname);
}

XS(_porbit_repoid) {
    dXSARGS;

    ST(0) = (SV *)CvXSUBANY(cv).any_ptr;

    XSRETURN(1);
}

static PORBitIfaceInfo *
load_ancestor (const char *id, CORBA_Environment *ev)
{
    PORBitIfaceInfo *info;
    CORBA_Contained base;
    CORBA_DefinitionKind defkind;
    
    info = porbit_find_interface_description (id);
    if (info)
	return info;

    if (!ensure_iface_repository (ev))
	return NULL;
    
    base = CORBA_Repository_lookup_id (iface_repository, (char *)id, ev);
    if (ev->_major != CORBA_NO_EXCEPTION || !base)
	return NULL;

    /* Paranoia */
    defkind = CORBA_IRObject__get_def_kind (base, ev);
    if (ev->_major != CORBA_NO_EXCEPTION || defkind != CORBA_dk_Interface) {
	CORBA_Object_release (base, ev);
	return NULL;
    }
    
    info = porbit_load_contained (base, NULL, ev);
    CORBA_Object_release (base, ev);

    return info;
}	

PORBitIfaceInfo *
porbit_init_interface (CORBA_InterfaceDef_FullInterfaceDescription *desc,
		       const char *package_name,
		       CORBA_Environment *ev)
{
    PORBitIfaceInfo *info;
    CORBA_unsigned_long i, j;
    char *tmp_str;
    AV *isa_av;
    CV *method_cv;

    info = porbit_find_interface_description (desc->id);
    if (info) {
	CORBA_free (desc);
	return info;
    }
    
    info = store_interface_description (desc, package_name);

    /* Set up the interface's operations and attributes
     */
    for (i = 0 ; i < desc->operations._length ; i++) {
        CORBA_OperationDescription *opr = &desc->operations._buffer[i];
	
	define_method (info->pkg, "::", opr->name, PORBIT_OPERATION_BASE + i);
	for (j = 0 ; j < opr->exceptions._length ; j++) {
	    define_exception (opr->exceptions._buffer[j].id, ev);
	    if (ev->_major != CORBA_NO_EXCEPTION)
		return NULL;
	}
    }

    for (i = 0; i < desc->attributes._length; i++) {
	if (desc->attributes._buffer[i].mode == CORBA_ATTR_NORMAL) {
	    define_method (info->pkg, "::_set_", desc->attributes._buffer[i].name, 
			   PORBIT_SETTER_BASE + i);
	}
	define_method (info->pkg, "::_get_", desc->attributes._buffer[i].name, 
		       PORBIT_GETTER_BASE + i);
    }

    /* Register the base interfaces
     */
    tmp_str = g_strconcat (info->pkg, "::ISA", NULL);
    isa_av = perl_get_av (tmp_str, TRUE );
    g_free (tmp_str);

    for (i = 0; i < desc->base_interfaces._length ; i++) {
	PORBitIfaceInfo *info = load_ancestor (desc->base_interfaces._buffer[i], ev);
	if (ev->_major != CORBA_NO_EXCEPTION) {
	    warn ("Can't find interface description for ancestor '%s'",
		  desc->base_interfaces._buffer[i]);
	    return NULL;
	}
	
	if (info)
	    av_push (isa_av, newSVpv(info->pkg, 0));
    }

    if (desc->base_interfaces._length == 0) {
	av_push (isa_av, newSVpv("CORBA::Object", 0));
    }

    /* Set up the server side package
     */
    tmp_str = g_strconcat ("POA_", info->pkg, "::ISA", NULL);
    isa_av = perl_get_av (tmp_str, TRUE);
    g_free (tmp_str);
    
    av_push (isa_av, newSVpv("PortableServer::ServantBase", 0));

    /* Create a package method that will allow us to determine the
     * repository id before we have the ORBit object set up
     */
    tmp_str = g_strconcat ("POA_", info->pkg, "::_porbit_repoid", NULL);
    method_cv = newXS (tmp_str, _porbit_repoid, __FILE__);
    g_free (tmp_str);
    
    CvXSUBANY(method_cv).any_ptr = (void *)newSVpv((char *)desc->id, 0);

    return info;
}

/* Assumes ownership of SV's refcount */
void
porbit_init_constant (const char *pkgname, const char *name, SV *sv)
{
    HV *stash = gv_stashpv ((char *)pkgname, TRUE);
    newCONSTSUB (stash, (char *)name, sv);
}

static void
load_container (CORBA_Container container, PORBitIfaceInfo *info, CORBA_Environment *ev)
{
    CORBA_unsigned_long i;
    CORBA_ContainedSeq *contents = NULL;
    CORBA_char *pkg = NULL;
	      
    contents = CORBA_Container_contents (container, CORBA_dk_Constant, CORBA_TRUE, ev);
    if (ev->_major != CORBA_NO_EXCEPTION)
	return;
    
    if (contents->_length > 0) {
	char *pkgname;
	
	if (info)
	    pkgname = g_strdup (info->pkg);
	else {
	    CORBA_char *pkg = CORBA_Contained__get_absolute_name(container, ev);
	    if (!strncmp(pkg, "_", 2))
		pkgname = &pkg[2];
	    else
		pkgname = pkg;
	}
	
	for (i = 0; i<contents->_length; i++)
	    ;
	    //porbit_init_constant (pkgname, contents->_buffer[i]);
    }
    CORBA_free (contents);
    
    contents = CORBA_Container_contents (container, CORBA_dk_Interface, CORBA_TRUE, ev);
    if (ev->_major != CORBA_NO_EXCEPTION) {
	contents = NULL;
	goto error;
    }
    
    for (i = 0; i<contents->_length; i++) {
	CORBA_char *id;

	id = CORBA_Contained__get_id (contents->_buffer[i], ev);
	if (ev->_major != CORBA_NO_EXCEPTION)
	    goto error;

	if (!porbit_find_interface_description (id))
	    porbit_load_contained (contents->_buffer[i], NULL, ev);

	CORBA_free (id);

	if (ev->_major != CORBA_NO_EXCEPTION)
	    goto error;
    }

 error:
    if (pkg)
	CORBA_free (pkg);
    if (contents)
	CORBA_free (contents);

}

PORBitIfaceInfo *
load_interface (CORBA_InterfaceDef iface, CORBA_Environment *ev)
{
    CORBA_InterfaceDef_FullInterfaceDescription *desc;
    CORBA_char *absolute_name;
    const char *package_name;
    PORBitIfaceInfo *retval;
    
    desc = CORBA_InterfaceDef_describe_interface (iface, ev);
    if (ev->_major != CORBA_NO_EXCEPTION)
	return NULL;

    absolute_name = CORBA_InterfaceDef__get_absolute_name (iface, ev);
    if (ev->_major != CORBA_NO_EXCEPTION) {
	CORBA_free (desc);
	return NULL;
    }
    
    package_name = absolute_name;
    if (!strncmp(package_name, "::", 2))
	package_name += 2;
    
    retval = porbit_init_interface (desc, package_name, ev);

    CORBA_free (absolute_name);
    CORBA_free (desc);

    return retval;
}

PORBitIfaceInfo *
porbit_load_contained (CORBA_Contained _contained, const char *_id, CORBA_Environment *ev)
{
    PORBitIfaceInfo *retval = NULL;
    CORBA_DefinitionKind defkind;
    CORBA_char *id;
    
    CORBA_Contained contained;

    assert (_contained != NULL || _id != NULL);

    id = (CORBA_char *)_id;
    
    if (_contained) {
	contained = CORBA_Object_duplicate (_contained, ev);
	if (ev->_major != CORBA_NO_EXCEPTION)
	    return NULL;
	
	if (!id) {
	    id = CORBA_Contained__get_id (contained, ev);
	    if (ev->_major != CORBA_NO_EXCEPTION) {
		id = NULL;
		goto error;
	    }
	}

    } else {
	if (!ensure_iface_repository (ev))
	    return NULL;
	
	contained = CORBA_Repository_lookup_id (iface_repository, id, ev);
	if (ev->_major != CORBA_NO_EXCEPTION)
	    return NULL;
	
	if (!contained) {
	    warn ("Cannot find '%s' in interface repository", id);
	    CORBA_exception_set_system (ev, ex_CORBA_BAD_PARAM, CORBA_COMPLETED_NO);
	    return NULL;
	}
    }

    defkind = CORBA_IRObject__get_def_kind (contained, ev);
    if (ev->_major != CORBA_NO_EXCEPTION)
	goto error;
    
    /* If the container is an interface, suck all the information
     * out of it for later use.
     */
    if (defkind == CORBA_dk_Interface) {
	retval = porbit_find_interface_description (id);
	if (!retval) {
	    retval = load_interface (contained, ev);
	    if (ev->_major != CORBA_NO_EXCEPTION)
		goto error;
	}
    }

    /* Initialize all constants in the container, and all
     * enclosed interfaces.
     */
    switch (defkind) {
    case CORBA_dk_Exception:
    case CORBA_dk_Interface:
    case CORBA_dk_Module:
    case CORBA_dk_Struct:
    case CORBA_dk_Union:
    case CORBA_dk_Repository:
	load_container (contained, retval, ev);
	break;
    default:
    }

 error:
    if (id && id != _id)
	CORBA_free (id);
    if (contained)
	CORBA_Object_release (contained, ev);

    return retval;
}

/* TypeCode lookup */

static GHashTable *typecode_hash = NULL; 

#define duplicate_typecode(a) (CORBA_TypeCode)CORBA_Object_duplicate ((CORBA_Object)a, NULL)

CORBA_TypeCode
porbit_find_typecode (const char *repoid)
{
    if (typecode_hash) {
	CORBA_TypeCode result = g_hash_table_lookup (typecode_hash, repoid);
	return duplicate_typecode (result);
    } else {
	return NULL;
    }
}

void
porbit_store_typecode (const char *repoid, CORBA_TypeCode tc)
{
    if (!typecode_hash)
	typecode_hash = g_hash_table_new (g_str_hash, g_str_equal);

    g_hash_table_insert (typecode_hash, g_strdup (repoid), duplicate_typecode (tc));
}

void
porbit_init_typecodes  (void)
{
    porbit_store_typecode ("IDL:CORBA/Short:1.0", 
			   duplicate_typecode(TC_CORBA_short));
    porbit_store_typecode ("IDL:CORBA/Long:1.0", 
			   duplicate_typecode(TC_CORBA_long));
    porbit_store_typecode ("IDL:CORBA/LongLong:1.0", 
			   duplicate_typecode(TC_CORBA_longlong));
    porbit_store_typecode ("IDL:CORBA/UShort:1.0", 
			   duplicate_typecode(TC_CORBA_ushort));
    porbit_store_typecode ("IDL:CORBA/ULong:1.0", 
			   duplicate_typecode(TC_CORBA_ulong));
    porbit_store_typecode ("IDL:CORBA/ULongLong:1.0", 
			   duplicate_typecode(TC_CORBA_ulonglong));
    porbit_store_typecode ("IDL:CORBA/Float:1.0", 
			   duplicate_typecode(TC_CORBA_float));
    porbit_store_typecode ("IDL:CORBA/Double:1.0", 
			   duplicate_typecode(TC_CORBA_double));
    porbit_store_typecode ("IDL:CORBA/LongDouble:1.0", 
			   duplicate_typecode(TC_CORBA_longdouble));
    porbit_store_typecode ("IDL:CORBA/Boolean:1.0", 
			   duplicate_typecode(TC_CORBA_boolean));
    porbit_store_typecode ("IDL:CORBA/Char:1.0", 
			   duplicate_typecode(TC_CORBA_char));
    porbit_store_typecode ("IDL:CORBA/WChar:1.0", 
			   duplicate_typecode(TC_CORBA_wchar));
    porbit_store_typecode ("IDL:CORBA/Octet:1.0", 
			   duplicate_typecode(TC_CORBA_octet));
    porbit_store_typecode ("IDL:CORBA/Any:1.0", 
			   duplicate_typecode(TC_CORBA_any));
    porbit_store_typecode ("IDL:CORBA/TypeCode:1.0", 
			   duplicate_typecode(TC_CORBA_TypeCode));
    porbit_store_typecode ("IDL:CORBA/Principal:1.0", 
			   duplicate_typecode(TC_CORBA_Principal));
    porbit_store_typecode ("IDL:CORBA/Object:1.0", 
			   duplicate_typecode(TC_CORBA_Object));
    porbit_store_typecode ("IDL:CORBA/String:1.0", 
			   duplicate_typecode(TC_CORBA_string));
    porbit_store_typecode ("IDL:CORBA/WString:1.0", 
			   duplicate_typecode(TC_CORBA_wstring));
}

