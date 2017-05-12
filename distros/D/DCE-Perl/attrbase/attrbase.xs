#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <dce/sec_attr_base.h>

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'a':
	break;
    case 'b':
	break;
    case 'c':
	break;
    case 'd':
	break;
    case 'e':
	break;
    case 'f':
	break;
    case 'g':
	break;
    case 'h':
	break;
    case 'i':
	break;
    case 'j':
	break;
    case 'k':
	break;
    case 'l':
	break;
    case 'm':
	break;
    case 'n':
	break;
    case 'o':
	break;
    case 'p':
	break;
    case 'q':
	break;
    case 'r':
	break;
    case 's':
	if (strEQ(name, "sec_attr_base_v0_0_included"))
#ifdef sec_attr_base_v0_0_included
	    return sec_attr_base_v0_0_included;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_bind_type_string"))
#ifdef sec_attr_bind_type_string
	    return sec_attr_bind_type_string;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_bind_type_svrname"))
#ifdef sec_attr_bind_type_svrname
	    return sec_attr_bind_type_svrname;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_bind_type_twrs"))
#ifdef sec_attr_bind_type_twrs
	    return sec_attr_bind_type_twrs;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_sch_entry_multi_inst"))
#ifdef sec_attr_sch_entry_multi_inst
	    return sec_attr_sch_entry_multi_inst;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_sch_entry_none"))
#ifdef sec_attr_sch_entry_none
	    return sec_attr_sch_entry_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_sch_entry_reserved"))
#ifdef sec_attr_sch_entry_reserved
	    return sec_attr_sch_entry_reserved;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_sch_entry_unique"))
#ifdef sec_attr_sch_entry_unique
	    return sec_attr_sch_entry_unique;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_sch_entry_use_defaults"))
#ifdef sec_attr_sch_entry_use_defaults
	    return sec_attr_sch_entry_use_defaults;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_acl_mgrs"))
#ifdef sec_attr_schema_part_acl_mgrs
	    return sec_attr_schema_part_acl_mgrs;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_comment"))
#ifdef sec_attr_schema_part_comment
	    return sec_attr_schema_part_comment;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_defaults"))
#ifdef sec_attr_schema_part_defaults
	    return sec_attr_schema_part_defaults;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_intercell"))
#ifdef sec_attr_schema_part_intercell
	    return sec_attr_schema_part_intercell;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_multi_inst"))
#ifdef sec_attr_schema_part_multi_inst
	    return sec_attr_schema_part_multi_inst;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_name"))
#ifdef sec_attr_schema_part_name
	    return sec_attr_schema_part_name;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_reserved"))
#ifdef sec_attr_schema_part_reserved
	    return sec_attr_schema_part_reserved;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_scope"))
#ifdef sec_attr_schema_part_scope
	    return sec_attr_schema_part_scope;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_trig_bind"))
#ifdef sec_attr_schema_part_trig_bind
	    return sec_attr_schema_part_trig_bind;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_trig_types"))
#ifdef sec_attr_schema_part_trig_types
	    return sec_attr_schema_part_trig_types;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_schema_part_unique"))
#ifdef sec_attr_schema_part_unique
	    return sec_attr_schema_part_unique;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_trig_type_none"))
#ifdef sec_attr_trig_type_none
	    return sec_attr_trig_type_none;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_trig_type_query"))
#ifdef sec_attr_trig_type_query
	    return sec_attr_trig_type_query;
#else
	    goto not_there;
#endif
	if (strEQ(name, "sec_attr_trig_type_update"))
#ifdef sec_attr_trig_type_update
	    return sec_attr_trig_type_update;
#else
	    goto not_there;
#endif
	break;
    case 't':
	break;
    case 'u':
	break;
    case 'v':
	if (strEQ(name, "volatile"))
#ifdef volatile
	    return volatile;
#else
	    goto not_there;
#endif
	break;
    case 'w':
	break;
    case 'x':
	break;
    case 'y':
	break;
    case 'z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = DCE::attrbase		PACKAGE = DCE::attrbase		


double
constant(name,arg)
	char *		name
	int		arg

