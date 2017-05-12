/* -*- mode: C; c-file-style: "bsd" -*- */

#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <libIDL/IDL.h>
#include <orb/orbit.h>

#include "errors.h"
#include "exttypes.h"
#include "interfaces.h"

static gboolean tree_pre_func  (IDL_tree_func_data *tfd, gpointer user_data);
static gboolean tree_post_func (IDL_tree_func_data *tfd, gpointer user_data);

CORBA_TypeCode get_typecode (IDL_tree tree);

#define duplicate_typecode(a) (CORBA_TypeCode)CORBA_Object_duplicate ((CORBA_Object)a, NULL)

static CORBA_TypeCode
alloc_typecode ()
{
    CORBA_TypeCode result = g_new0 (struct CORBA_TypeCode_struct, 1);
    ORBit_pseudo_object_init ((ORBit_PseudoObject)result,
			      ORBIT_PSEUDO_TYPECODE, NULL);
    ORBit_RootObject_set_interface((ORBit_RootObject)result,
				   (ORBit_RootObject_Interface *)&ORBit_TypeCode_epv,
				   NULL);
    return duplicate_typecode (result);
}

static CORBA_TypeCode
get_declarator_typecode (IDL_tree tree, CORBA_TypeCode base_type)
{
    if (IDL_NODE_TYPE (tree) == IDLN_TYPE_ARRAY) {
	
	IDL_tree size_list = IDL_TYPE_ARRAY(tree).size_list;
	IDL_tree tmp_list;
	CORBA_TypeCode result = duplicate_typecode (base_type);
	CORBA_TypeCode child_tc;

	tmp_list = IDL_LIST(size_list)._tail;
	while (tmp_list) {
	    IDL_tree size = IDL_LIST(tmp_list).data;

	    child_tc = result;
	    
	    result = alloc_typecode ();
	    result->kind = CORBA_tk_array;
	    result->length = IDL_INTEGER(size).value;
	    result->sub_parts = 1;
	    result->subtypes = g_new (CORBA_TypeCode, 1);
	    result->subtypes[0] = child_tc;
	    
	    tmp_list = IDL_LIST(tmp_list).prev;
	}

	return result;
	
    } else if (IDL_NODE_TYPE (tree) == IDLN_IDENT) {
	return duplicate_typecode (base_type);
	
    } else {
	g_warning ("get_declarator_typecode() called on non-ident / non-array");
    }

    return NULL;
}

static gchar *
get_declarator_name (IDL_tree tree)
{
    if (IDL_NODE_TYPE (tree) == IDLN_TYPE_ARRAY) {
	return g_strdup (IDL_IDENT(IDL_TYPE_ARRAY (tree).ident).str);

    } else if (IDL_NODE_TYPE (tree) == IDLN_IDENT) {
	return g_strdup (IDL_IDENT(tree).str);

    } else {
	g_warning ("get_declator_name called on non-ident / non-array");
    }

    return NULL;
}

static gchar *
peek_declarator_repoid (IDL_tree tree)
{
    if (IDL_NODE_TYPE (tree) == IDLN_TYPE_ARRAY) {
	return IDL_IDENT_REPO_ID(IDL_TYPE_ARRAY (tree).ident);

    } else if (IDL_NODE_TYPE (tree) == IDLN_IDENT) {
	return IDL_IDENT_REPO_ID(tree);

    } else {
	g_warning ("peek_declarator_repoid called on non-ident / non-array");
	return NULL;
    }


}

static CORBA_TypeCode
get_enum_typecode (IDL_tree tree) 
{
    IDL_tree ident = IDL_TYPE_ENUM(tree).ident;
    IDL_tree enumerator_list = IDL_TYPE_ENUM(tree).enumerator_list;

    IDL_tree tmp_list;
    char *repoid;
    CORBA_TypeCode result;
    int i;

    repoid = IDL_IDENT_REPO_ID (ident);

    result = porbit_find_typecode (repoid);
    if (result)
	return result;

    result = alloc_typecode();
    result->name = g_strdup (IDL_IDENT(ident).str); 
    result->kind = CORBA_tk_enum;
    result->repo_id = g_strdup (repoid);

    /* Count the number of members */
    result->sub_parts = 0;
    tmp_list = enumerator_list;
    while (tmp_list) {
	result->sub_parts++;
	tmp_list = IDL_LIST(tmp_list).next;
    }
    
    result->subnames = g_new(const gchar *, result->sub_parts);

    i = 0;
    tmp_list = enumerator_list;
    while (tmp_list) {
	IDL_tree ident = IDL_LIST(tmp_list).data;
	result->subnames[i] = g_strdup (IDL_IDENT (ident).str);
	
	tmp_list = IDL_LIST(tmp_list).next;
	i++;
    }

    porbit_store_typecode (repoid, result);

    return result;
}

/* FIXME: 95% of this is the same as get_struct typecode; they should
 * be merged to call a common backend
 */
static CORBA_TypeCode
get_exception_typecode (IDL_tree tree) 
{
    IDL_tree ident = IDL_EXCEPT_DCL(tree).ident;
    IDL_tree members = IDL_EXCEPT_DCL(tree).members;
    IDL_tree tmp_list1, tmp_list2;
    char *repoid;
    CORBA_TypeCode result;
    int i;

    repoid = IDL_IDENT_REPO_ID (ident);

    result = porbit_find_typecode (repoid);
    if (result)
	return result;

    result = alloc_typecode();
    result->kind = CORBA_tk_except;
    result->repo_id = g_strdup (repoid);
    result->name = g_strdup (IDL_IDENT(ident).str); 

    /* Count the number of members */
    result->sub_parts = 0;
    tmp_list1 = members;
    while (tmp_list1) {
	IDL_tree member = IDL_LIST(tmp_list1).data;
	IDL_tree dcls = IDL_MEMBER(member).dcls;
	result->sub_parts += IDL_list_length (dcls);

	tmp_list1 = IDL_LIST(tmp_list1).next;
    }
    
    result->subnames = g_new(const gchar *, result->sub_parts);
    result->subtypes = g_new(CORBA_TypeCode, result->sub_parts);

    i = 0;
    tmp_list1 = members;
    while (tmp_list1) {
	IDL_tree member = IDL_LIST(tmp_list1).data;
	IDL_tree type_spec = IDL_MEMBER(member).type_spec;
	IDL_tree dcls = IDL_MEMBER(member).dcls;
	CORBA_TypeCode base_tc = get_typecode (type_spec);

	tmp_list2 = dcls;
	while (tmp_list2) {
	    IDL_tree dcl = IDL_LIST(tmp_list2).data;
	    
	    result->subnames[i] = get_declarator_name (dcl);
	    result->subtypes[i] = get_declarator_typecode (dcl, base_tc);

	    tmp_list2 = IDL_LIST(tmp_list2).next;
	    i++;
	}
	CORBA_Object_release ((CORBA_Object) base_tc, NULL);
	
	tmp_list1 = IDL_LIST(tmp_list1).next;
    }

    porbit_store_typecode (repoid, result);

    return result;
}

static CORBA_TypeCode
get_integer_typecode (IDL_tree tree)
{
    gboolean f_signed = IDL_TYPE_INTEGER(tree).f_signed;
    enum IDL_integer_type f_type = IDL_TYPE_INTEGER(tree).f_type;

    if (f_signed) {
	switch (f_type) {
	case IDL_INTEGER_TYPE_SHORT:   
	    return duplicate_typecode (TC_CORBA_short);
	case IDL_INTEGER_TYPE_LONG:   
	    return duplicate_typecode (TC_CORBA_long);
	case IDL_INTEGER_TYPE_LONGLONG:
	    return duplicate_typecode (TC_CORBA_longlong);
	}
    } else {
	switch (f_type) {
	case IDL_INTEGER_TYPE_SHORT:   
	    return duplicate_typecode (TC_CORBA_ushort);
	case IDL_INTEGER_TYPE_LONG:   
	    return duplicate_typecode (TC_CORBA_ulong);
	case IDL_INTEGER_TYPE_LONGLONG:
	    return duplicate_typecode (TC_CORBA_ulonglong);
	}
    }

    g_assert_not_reached ();
    return NULL;
}

static CORBA_TypeCode
get_fixed_typecode (IDL_tree tree) 
{
    CORBA_TypeCode result;

    IDL_tree positive_int_const = IDL_TYPE_FIXED(tree).positive_int_const;
    IDL_tree integer_lit = IDL_TYPE_FIXED(tree).integer_lit;

    result = alloc_typecode();
    result->kind = CORBA_tk_fixed;
    result->digits = IDL_INTEGER(positive_int_const).value;
    result->scale = IDL_INTEGER(integer_lit).value;

    return result;
}

static CORBA_TypeCode
get_float_typecode (IDL_tree tree)
{
    enum IDL_float_type f_type = IDL_TYPE_FLOAT(tree).f_type;

    switch (f_type) {
    case IDL_FLOAT_TYPE_FLOAT:   
	return duplicate_typecode (TC_CORBA_float);
    case IDL_FLOAT_TYPE_DOUBLE:   
	return duplicate_typecode (TC_CORBA_double);
    case IDL_FLOAT_TYPE_LONGDOUBLE:
	return duplicate_typecode (TC_CORBA_longdouble);
    }

    g_assert_not_reached();
    return NULL;
}

static CORBA_TypeCode
get_interface_typecode (IDL_tree tree)
{
    IDL_tree ident = IDL_INTERFACE (tree).ident;
    CORBA_TypeCode result;
    char *repoid;

    repoid = IDL_IDENT_REPO_ID (ident);

    result = porbit_find_typecode (repoid);
    if (result)
	return result;

    result = alloc_typecode();
    result->kind = CORBA_tk_objref;
    result->repo_id = g_strdup (repoid);
    result->name = g_strdup (IDL_IDENT(ident).str);

    porbit_store_typecode (repoid, result);

    return result;
}

static CORBA_TypeCode
get_sequence_typecode (IDL_tree tree) 
{
    IDL_tree simple_type_spec = IDL_TYPE_SEQUENCE(tree).simple_type_spec;
    IDL_tree positive_int_const = IDL_TYPE_SEQUENCE(tree).positive_int_const;
    CORBA_TypeCode result;
    
    result = alloc_typecode();
    result->kind = CORBA_tk_sequence;
    result->sub_parts = 1;
    result->subtypes = g_new (CORBA_TypeCode, 1);
    result->subtypes[0] = get_typecode(simple_type_spec);
    
    if (positive_int_const)
	result->length = IDL_INTEGER(positive_int_const).value;
    else
	result->length = 0;

    return result;
}

static CORBA_TypeCode
get_string_typecode (IDL_tree tree) 
{
    IDL_tree positive_int_const = IDL_TYPE_STRING(tree).positive_int_const;
    CORBA_TypeCode result = alloc_typecode();

    result->kind = CORBA_tk_string;
    if (positive_int_const)
	result->length = IDL_INTEGER(positive_int_const).value;
    else
	result->length = 0;

    return result;
}

static CORBA_TypeCode
get_struct_typecode (IDL_tree tree) 
{
    IDL_tree ident = IDL_TYPE_STRUCT(tree).ident;
    IDL_tree member_list = IDL_TYPE_STRUCT(tree).member_list;
    IDL_tree tmp_list1, tmp_list2;
    char *repoid;
    CORBA_TypeCode result;
    int i;

    repoid = IDL_IDENT_REPO_ID (ident);

    result = porbit_find_typecode (repoid);
    if (result)
	return result;

    result = alloc_typecode();
    result->kind = CORBA_tk_struct;
    result->repo_id = g_strdup (repoid);
    result->name = g_strdup (IDL_IDENT(ident).str); 

    /* Count the number of members */
    result->sub_parts = 0;
    tmp_list1 = member_list;
    while (tmp_list1) {
	IDL_tree member = IDL_LIST(tmp_list1).data;
	IDL_tree dcls = IDL_MEMBER(member).dcls;
	result->sub_parts += IDL_list_length (dcls);

	tmp_list1 = IDL_LIST(tmp_list1).next;
    }
    
    result->subnames = g_new(const gchar *, result->sub_parts);
    result->subtypes = g_new(CORBA_TypeCode, result->sub_parts);

    i = 0;
    tmp_list1 = member_list;
    while (tmp_list1) {
	IDL_tree member = IDL_LIST(tmp_list1).data;
	IDL_tree type_spec = IDL_MEMBER(member).type_spec;
	IDL_tree dcls = IDL_MEMBER(member).dcls;
	CORBA_TypeCode base_tc = get_typecode (type_spec);

	tmp_list2 = dcls;
	while (tmp_list2) {
	    IDL_tree dcl = IDL_LIST(tmp_list2).data;
	    
	    result->subnames[i] = get_declarator_name (dcl);
	    result->subtypes[i] = get_declarator_typecode (dcl, base_tc);

	    tmp_list2 = IDL_LIST(tmp_list2).next;
	    i++;
	}
	CORBA_Object_release ((CORBA_Object) base_tc, NULL);
	
	tmp_list1 = IDL_LIST(tmp_list1).next;
    }

    porbit_store_typecode (repoid, result);

    return result;
}

static int
enumerator_index (IDL_tree label)
{
    IDL_tree tmp_list = IDL_NODE_UP (label);
    int i = 0;

    do {
	tmp_list = IDL_LIST(tmp_list).prev;
	i++;
    } while (tmp_list);

    return i - 1;
}

static CORBA_TypeCode
get_union_typecode (IDL_tree tree) 
{
    IDL_tree ident = IDL_TYPE_UNION(tree).ident;
    IDL_tree switch_type_spec = IDL_TYPE_UNION(tree).switch_type_spec;
    IDL_tree switch_body = IDL_TYPE_UNION(tree).switch_body;
    CORBA_unsigned_long i;

    IDL_tree tmp_list1, tmp_list2;
    char *repoid;
    CORBA_TypeCode result;

    repoid = IDL_IDENT_REPO_ID (ident);

    result = porbit_find_typecode (repoid);
    if (result)
	return result;

    result = alloc_typecode();
    result->kind = CORBA_tk_union;
    result->repo_id = g_strdup (repoid);
    result->name = g_strdup (IDL_IDENT(ident).str); 

    /* When building a union, if the default case has another label,
     * we don't add a separate arm for it
     *
     * Count the number of arms
     */
    result->sub_parts = 0;
    tmp_list1 = switch_body;
    while (tmp_list1) {
	IDL_tree case_stmt = IDL_LIST(tmp_list1).data;
	IDL_tree labels = IDL_CASE_STMT(case_stmt).labels;
	gint length = 0;

	tmp_list2 = labels;
	while (tmp_list2) {
	    if (IDL_LIST(tmp_list2).data == NULL) {
		if (IDL_LIST(tmp_list2).prev == NULL &&
		    IDL_LIST(tmp_list2).next == NULL)
		    length++;
	    } else
		length++;
	    
	    tmp_list2 = IDL_LIST(tmp_list2).next;
	}

	result->sub_parts += length;

	tmp_list1 = IDL_LIST(tmp_list1).next;
    }
    
    result->subnames = g_new(const gchar *, result->sub_parts);
    result->subtypes = g_new(CORBA_TypeCode, result->sub_parts);
    result->sublabels = g_new(CORBA_any, result->sub_parts);
    result->default_index = -1;
    result->discriminator = get_typecode (switch_type_spec);

    i = 0;
    tmp_list1 = switch_body;
    while (tmp_list1) {
	IDL_tree case_stmt = IDL_LIST(tmp_list1).data;
	IDL_tree labels = IDL_CASE_STMT(case_stmt).labels;
	IDL_tree element_spec = IDL_CASE_STMT(case_stmt).element_spec;
	IDL_tree type_spec = IDL_MEMBER(element_spec).type_spec;
	IDL_tree dcls = IDL_MEMBER(element_spec).dcls;
	IDL_tree declarator = IDL_LIST(dcls).data;
	    
	tmp_list2 = labels;
	while (tmp_list2) {
	    IDL_tree label = IDL_LIST(tmp_list2).data;
	    
	    if (label == NULL) {
		result->default_index = i;
		
		if (IDL_LIST(tmp_list2).prev != NULL ||
		    IDL_LIST(tmp_list2).next != NULL) {
		    tmp_list2 = IDL_LIST(tmp_list2).next;
		    continue;
		}
	    }

	    result->subnames[i] = get_declarator_name (declarator);
	    result->subtypes[i] = get_declarator_typecode (declarator,
							   get_typecode (type_spec));
	    
	    if (label == NULL) {
		CORBA_octet *val;
		
		result->sublabels[i]._type = duplicate_typecode (TC_CORBA_octet);
		result->sublabels[i]._release = TRUE;
		val = g_new (CORBA_octet, 1);
		*val = 0;
		result->sublabels[i]._value = val;
	    } else {
		
		result->sublabels[i]._type = duplicate_typecode (result->discriminator);
		result->sublabels[i]._release = TRUE;

#define CASE_MEMBER(kind,type,value)         \
    case kind: {                             \
	 type *val;	 	             \
	 val = g_new (type, 1);              \
         *val = value;                       \
         result->sublabels[i]._value = val;  \
    } break
               switch (result->discriminator->kind) {
		   CASE_MEMBER(CORBA_tk_enum,
			       CORBA_long,
			       enumerator_index (label));
		   CASE_MEMBER(CORBA_tk_long,
			       CORBA_long,
			       IDL_INTEGER(label).value);
		   CASE_MEMBER(CORBA_tk_ulong,
			       CORBA_unsigned_long,
			       IDL_INTEGER(label).value);
		   CASE_MEMBER(CORBA_tk_boolean,
			       CORBA_boolean,
			       IDL_INTEGER(label).value);
		   CASE_MEMBER(CORBA_tk_char,
			       CORBA_char,
			       *IDL_CHAR(label).value);
		   CASE_MEMBER(CORBA_tk_short,
			       CORBA_short,
			       IDL_INTEGER(label).value);
		   CASE_MEMBER(CORBA_tk_ushort,
			       CORBA_unsigned_short,
			       IDL_INTEGER(label).value);
		   CASE_MEMBER(CORBA_tk_longlong,
			       CORBA_long_long,
			       IDL_INTEGER(label).value);
		   CASE_MEMBER(CORBA_tk_ulonglong,
			       CORBA_unsigned_long_long,
			       IDL_INTEGER(label).value);
	       default:
		   g_warning ("Bad union discriminator type %d", result->discriminator->kind);
		   exit(1);
	       }
#undef CASE_MEMBER		
	    }
	    tmp_list2 = IDL_LIST(tmp_list2).next;
	    i++;
	}

	tmp_list1 = IDL_LIST(tmp_list1).next;
    }
    
    porbit_store_typecode (repoid, result);
    
    return result;
}

static CORBA_TypeCode
get_wstring_typecode (IDL_tree tree) 
{
    IDL_tree positive_int_const = IDL_TYPE_WIDE_STRING(tree).positive_int_const;

    CORBA_TypeCode result = alloc_typecode();
    result->kind = CORBA_tk_wstring;
    if (positive_int_const)
	result->length = IDL_INTEGER(positive_int_const).value;
    else
	result->length = 0;

    return result;
}

CORBA_TypeCode
get_ident_typecode (IDL_tree tree)
{
    IDL_tree parent;
    CORBA_TypeCode result;
    char *repoid;

    repoid = IDL_IDENT_REPO_ID (tree);
    result = porbit_find_typecode (repoid);
    if (result)
	return result;

    parent = IDL_NODE_UP (tree);
    switch (IDL_NODE_TYPE (parent)) {
    case IDLN_TYPE_ENUM:
    case IDLN_EXCEPT_DCL:
    case IDLN_INTERFACE:
    case IDLN_TYPE_STRUCT:
    case IDLN_TYPE_UNION:
	return get_typecode (parent);
    case IDLN_TYPE_ARRAY:
        {
	    IDL_tree list;
	    IDL_tree dcl;
	    CORBA_TypeCode base_tc;

	    g_assert (IDL_NODE_TYPE (IDL_NODE_UP (parent)) == IDLN_LIST);
	    list = IDL_NODE_UP (parent);
	    
	    g_assert (IDL_NODE_TYPE (IDL_NODE_UP (list)) == IDLN_TYPE_DCL);
	    dcl = IDL_NODE_UP (list);

	    base_tc = get_typecode (IDL_TYPE_DCL (dcl).type_spec);
	    result = get_declarator_typecode (parent, base_tc);
	    CORBA_Object_release ((CORBA_Object)base_tc, NULL);

	    porbit_store_typecode (repoid, result);
	    
	    return result;
	}
    case IDLN_LIST:
        {
	    IDL_tree dcl;
	    
	    g_assert (IDL_NODE_TYPE (IDL_NODE_UP (parent)) == IDLN_TYPE_DCL);
	    dcl = IDL_NODE_UP (parent);

	    result = get_typecode (IDL_TYPE_DCL (dcl).type_spec);

	    porbit_store_typecode (repoid, result);

	    return result;
	}
    default:
	g_warning ("Reference to node type %s invalid\n", IDL_NODE_TYPE_NAME (parent));
    }

    g_assert_not_reached();
    return NULL;
}

CORBA_TypeCode
get_typecode (IDL_tree tree)
{
    switch (IDL_NODE_TYPE (tree)) {
	/* Simple types */
    case IDLN_TYPE_ANY:
	return duplicate_typecode (TC_CORBA_any);
    case IDLN_TYPE_CHAR:
	return duplicate_typecode (TC_CORBA_char);
    case IDLN_TYPE_BOOLEAN:
	return duplicate_typecode (TC_CORBA_boolean);
    case IDLN_TYPE_OBJECT:
	return duplicate_typecode (TC_CORBA_Object);
    case IDLN_TYPE_OCTET:
	return duplicate_typecode (TC_CORBA_octet);
    case IDLN_TYPE_TYPECODE:
	return duplicate_typecode (TC_CORBA_TypeCode);
    case IDLN_TYPE_WIDE_CHAR:
	return duplicate_typecode (TC_CORBA_wchar);

	/* Complex types */
    case IDLN_TYPE_ENUM:
	return get_enum_typecode (tree);
    case IDLN_EXCEPT_DCL:
	return get_exception_typecode (tree);
    case IDLN_TYPE_FIXED:
	return get_fixed_typecode (tree);
    case IDLN_TYPE_FLOAT:
	return get_float_typecode (tree);
    case IDLN_IDENT:
	return get_ident_typecode (tree);
    case IDLN_INTERFACE:
	return get_interface_typecode (tree);
    case IDLN_TYPE_INTEGER:
	return get_integer_typecode (tree);
    case IDLN_TYPE_SEQUENCE:
	return get_sequence_typecode (tree);
    case IDLN_TYPE_STRING:
	return get_string_typecode (tree);
    case IDLN_TYPE_STRUCT:
	return get_struct_typecode (tree);
    case IDLN_TYPE_UNION:
	return get_union_typecode (tree);
    case IDLN_TYPE_WIDE_STRING:
	return get_wstring_typecode (tree);
	
    default:
	croak ("get_typecode called on node type %s", IDL_NODE_TYPE_NAME(tree));
    }
}

static GSList *
do_attribute(IDL_tree tree)
{
    CORBA_AttributeDescription *attr_desc;
    gboolean f_readonly = IDL_ATTR_DCL (tree).f_readonly;
    GSList *result = NULL;
    IDL_tree param_type_spec = IDL_ATTR_DCL (tree).param_type_spec;
    IDL_tree simple_declarations = IDL_ATTR_DCL (tree).simple_declarations;

    while (simple_declarations) {
	IDL_tree ident = IDL_LIST (simple_declarations).data;
	
	attr_desc = g_new (CORBA_AttributeDescription, 1);
	attr_desc->name = g_strdup (IDL_IDENT(ident).str);
	attr_desc->id = g_strdup (IDL_IDENT_REPO_ID (ident));;
	attr_desc->type = get_typecode (param_type_spec);
	attr_desc->mode = f_readonly ? CORBA_ATTR_READONLY : CORBA_ATTR_NORMAL;

	result = g_slist_prepend (result, attr_desc);
	
	/* We don't need the following */
	attr_desc->version = NULL ;
	attr_desc->defined_in = NULL;

	simple_declarations = IDL_LIST(simple_declarations).next;
    }

    return result;
}

static CORBA_OperationDescription *
do_operation(IDL_tree tree)
{
    gboolean f_oneway = IDL_OP_DCL (tree).f_oneway;
    IDL_tree op_type_spec = IDL_OP_DCL (tree).op_type_spec;
    IDL_tree ident = IDL_OP_DCL (tree).ident;
    IDL_tree parameter_dcls = IDL_OP_DCL (tree).parameter_dcls;
    IDL_tree raises_expr = IDL_OP_DCL (tree).raises_expr;
    CORBA_unsigned_long i;

    CORBA_OperationDescription *op_desc = g_new0 (CORBA_OperationDescription, 1);

    op_desc->name = g_strdup (IDL_IDENT (ident).str);
    op_desc->id = g_strdup (IDL_IDENT_REPO_ID (ident));

    if (op_type_spec)
	op_desc->result = get_typecode (op_type_spec);
    else
	op_desc->result = duplicate_typecode (TC_void);
    op_desc->mode = f_oneway ? CORBA_OP_ONEWAY : CORBA_OP_NORMAL;

    op_desc->parameters._length = IDL_list_length (parameter_dcls);
    op_desc->parameters._buffer =
	CORBA_sequence_CORBA_ParameterDescription_allocbuf (op_desc->parameters._length);
    op_desc->parameters._release = TRUE;

    for (i=0; i<op_desc->parameters._length; i++) {
	CORBA_ParameterDescription *par_desc = &op_desc->parameters._buffer[i];
	IDL_tree param_dcl = IDL_LIST (parameter_dcls).data;

	par_desc->name = IDL_IDENT (IDL_PARAM_DCL (param_dcl).simple_declarator).str;
	par_desc->type = get_typecode (IDL_PARAM_DCL (param_dcl).param_type_spec);
	switch (IDL_PARAM_DCL (param_dcl).attr) {
	case IDL_PARAM_IN:
	    par_desc->mode = CORBA_PARAM_IN;
	    break;
	case IDL_PARAM_OUT:
	    par_desc->mode = CORBA_PARAM_OUT;
	    break;
	case IDL_PARAM_INOUT:
	    par_desc->mode = CORBA_PARAM_INOUT;
	    break;
	}
	par_desc->type_def = CORBA_OBJECT_NIL;
	
	parameter_dcls = IDL_LIST (parameter_dcls).next;
    }
    
    op_desc->exceptions._length = IDL_list_length (raises_expr);
    op_desc->exceptions._buffer =
	CORBA_sequence_CORBA_ExceptionDescription_allocbuf (op_desc->exceptions._length);
    op_desc->exceptions._release = TRUE;

    for (i=0; i<op_desc->exceptions._length; i++) {
	CORBA_ExceptionDescription *exc_desc = &op_desc->exceptions._buffer[i];
	IDL_tree ref = IDL_LIST (raises_expr).data;

	/* Fixme, we could merge exception descriptions here
	 */
	exc_desc->type = get_ident_typecode (ref);
	if (exc_desc->type->kind != CORBA_tk_except) {
	    g_warning ("Raises spec refers to non-exception");
	    exit (1);
	}

	exc_desc->id = g_strdup (exc_desc->type->repo_id);
	
	/* We don't need the following */
	exc_desc->name = NULL;
	exc_desc->defined_in = NULL;
	exc_desc->version = NULL;

	raises_expr = IDL_LIST (raises_expr).next;
    }

    /* We don't need the following */
    /* op_desc->defined_in */
    /* op_desc->contexts  */
    /* op_desc->version */;

    return op_desc;
}

static void
do_const(IDL_tree tree)
{
    CORBA_TypeCode type = get_typecode (IDL_CONST_DCL(tree).const_type);

    IDL_tree value = IDL_CONST_DCL (tree).const_exp;
    IDL_tree ident = IDL_CONST_DCL (tree).ident;
    const char *name = IDL_IDENT (ident).str;
    IDL_tree container = IDL_NODE_UP (IDL_NODE_UP (tree));
    char *pkgname = NULL;
    SV *sv;

    switch (IDL_NODE_TYPE (container)) {
    case IDLN_INTERFACE:
	pkgname = IDL_ns_ident_to_qstring (IDL_INTERFACE (container).ident, "::", 0);
	break;
    case IDLN_MODULE:
	pkgname = IDL_ns_ident_to_qstring (IDL_MODULE (container).ident, "::", 0);
	break;
    default:
	g_warning ("Constant isn't contained within an interface or module!\n");
	goto error;
    }
    
    switch (type->kind) {
	/* FIXME: check ranges */
    case CORBA_tk_long:
    case CORBA_tk_short:
    case CORBA_tk_ushort:
	sv = newSViv(IDL_INTEGER (value).value);
	break;
    case CORBA_tk_ulong:
	sv = newSV(0);
	sv_setuv (sv, IDL_INTEGER (value).value);
	break;
    case CORBA_tk_boolean:
	sv = newSVsv(IDL_BOOLEAN(value).value?&PL_sv_yes:&PL_sv_no);
	break;
    case CORBA_tk_char:
	sv = newSVpv(IDL_CHAR(value).value, 1);
	break;
    case CORBA_tk_float:
    case CORBA_tk_double:
	sv = newSVnv(IDL_FLOAT(value).value);
	break;
    case CORBA_tk_string:
	sv = newSVpv(IDL_STRING(value).value, 0);
	break;
    /* FIXME: these are all broken because libIDL doesn't handle
     *        long constants as far as I can tell.
     */
    case CORBA_tk_longdouble:
	sv = ld_from_longdouble ((CORBA_long_double)IDL_FLOAT(value).value);
	break;
    case CORBA_tk_longlong:
	sv = ll_from_longlong ((CORBA_long_long)IDL_INTEGER(value).value);
	break;
    case CORBA_tk_ulonglong:
	sv = ull_from_ulonglong ((CORBA_unsigned_long_long)IDL_INTEGER(value).value);
	break;

    case CORBA_tk_wchar:
    case CORBA_tk_fixed:
    case CORBA_tk_wstring:
	g_warning ("Unsupported constant type: %d\n", type->kind);
	goto error;
    default:
	g_warning ("Impossible constant type: %d!\n", type->kind);
	goto error;
    }

    porbit_init_constant (pkgname, name, sv);

 error:
    g_free (pkgname);
    CORBA_Object_release ((CORBA_Object)type, NULL);
}

static void
do_except(IDL_tree tree)
{
    IDL_tree ident = IDL_TYPE_ENUM(tree).ident;
    char *abs_name = IDL_ns_ident_to_qstring (ident, "::", 0);
    char *repoid = IDL_IDENT_REPO_ID (ident);

    porbit_setup_exception (repoid, abs_name, "CORBA::UserException");
    g_free (abs_name);
}

static void
do_type_dcl(IDL_tree tree)
{
    IDL_tree type_spec = IDL_TYPE_DCL(tree).type_spec;
    IDL_tree dcls = IDL_TYPE_DCL(tree).dcls;

    while (dcls) {
	IDL_tree dcl = IDL_LIST(dcls).data;
	char *repoid = peek_declarator_repoid (dcl);
	CORBA_TypeCode tc;

	if (repoid && !porbit_find_typecode (repoid)) {
	    tc = get_declarator_typecode (dcl, get_typecode (type_spec));
	    porbit_store_typecode (repoid, tc);
	}
	
	dcls = IDL_LIST(dcls).next;	
    }
}

typedef struct {
    GSList *operations;
    GSList *attributes;
} InterfaceData;

static gboolean
tree_pre_func (IDL_tree_func_data *tfd, gpointer user_data)
{
    InterfaceData *idata;
    
    switch (IDL_NODE_TYPE (tfd->tree)) {
    case IDLN_LIST:
	return TRUE;
    case IDLN_MODULE:
	return TRUE;
	
    case IDLN_INTERFACE:
	idata = g_new (InterfaceData, 1);
	idata->operations = NULL;
	idata->attributes = NULL;
	
	tfd->data = idata;

	return TRUE;
	
    case IDLN_ATTR_DCL:
	idata = tfd->up->up->data;
	idata->attributes = g_slist_concat (do_attribute (tfd->tree),
					    idata->attributes);
					     
	return FALSE;
	
    case IDLN_OP_DCL:
	idata = tfd->up->up->data;
	idata->operations = g_slist_prepend (idata->operations,
					     do_operation (tfd->tree));
	return FALSE;
	
    case IDLN_CONST_DCL:
	do_const (tfd->tree);
	return FALSE;
    case IDLN_EXCEPT_DCL:
	do_except (tfd->tree);
	return FALSE;
    case IDLN_TYPE_DCL:
	do_type_dcl (tfd->tree);
	return FALSE;

    default:
	return FALSE;
    }
}

static void
define_interface (IDL_tree tree, InterfaceData *idata)
{
	CORBA_Environment ev;

	IDL_tree ident = IDL_INTERFACE (tree).ident;
	IDL_tree inheritance_spec = IDL_INTERFACE (tree).inheritance_spec;
	GSList *tmp_list;
	CORBA_unsigned_long i;
	char *abs_name;
	CORBA_InterfaceDef_FullInterfaceDescription *desc;

	if (porbit_find_interface_description (IDL_IDENT_REPO_ID (ident)))
	    return;
	
	abs_name = IDL_ns_ident_to_qstring (ident, "::", 0);
	desc = g_new (CORBA_InterfaceDef_FullInterfaceDescription, 1);
	desc->name = g_strdup (IDL_IDENT (ident).str);
	desc->id = g_strdup (IDL_IDENT_REPO_ID (ident));
	
	desc->operations._length = g_slist_length (idata->operations);
	desc->operations._buffer = 
	    CORBA_sequence_CORBA_OperationDescription_allocbuf (desc->operations._length);
	desc->operations._release = TRUE;

	tmp_list = idata->operations;
	for (i=0; i<desc->operations._length; i++) {
	    desc->operations._buffer[i] = *(CORBA_OperationDescription *)tmp_list->data;
	    g_free (tmp_list->data);
	    tmp_list = tmp_list->next;
	}
	g_slist_free (idata->operations);

	desc->attributes._length = g_slist_length (idata->attributes);
	desc->attributes._buffer = 
	    CORBA_sequence_CORBA_AttributeDescription_allocbuf (desc->attributes._length);
	desc->attributes._release = TRUE;

	tmp_list = idata->attributes;
	for (i=0; i<desc->attributes._length; i++) {
	    desc->attributes._buffer[i] = *(CORBA_AttributeDescription *)tmp_list->data;
	    g_free (tmp_list->data);
	    tmp_list = tmp_list->next;
	}
	g_slist_free (idata->attributes);

	desc->base_interfaces._length = IDL_list_length (inheritance_spec);
	desc->base_interfaces._buffer = 
	    CORBA_sequence_CORBA_RepositoryId_allocbuf (desc->base_interfaces._length);
	desc->base_interfaces._release = TRUE;

	for (i=0; i<desc->base_interfaces._length; i++) {
	    IDL_tree ident = IDL_LIST (inheritance_spec).data;
	    
	    desc->base_interfaces._buffer[i] = IDL_IDENT_REPO_ID (ident);
	    inheritance_spec = IDL_LIST (inheritance_spec).next;
	}
	
	/* We don't need the following fields */
	desc->version = NULL;
	desc->defined_in = NULL;
	desc->type = NULL;

	CORBA_exception_init (&ev);
	porbit_init_interface (desc, abs_name, &ev);
	if (ev._major != CORBA_NO_EXCEPTION) {
	    warn ("Registering interface '%s' failed!\n", abs_name);
	    CORBA_exception_free (&ev);
	}

	g_free (abs_name);
}

static gboolean
tree_post_func (IDL_tree_func_data *tfd, gpointer user_data)
{
    if (IDL_NODE_TYPE (tfd->tree) == IDLN_INTERFACE) {
	define_interface (tfd->tree, tfd->data);
    }

    /* Store a typecode for the type, if necessary
     */
    switch (IDL_NODE_TYPE (tfd->tree)) {
    case IDLN_TYPE_ENUM:
	get_enum_typecode (tfd->tree);
	break;
    case IDLN_EXCEPT_DCL:
	get_exception_typecode (tfd->tree);
	break;
    case IDLN_INTERFACE:
	get_interface_typecode (tfd->tree);
	break;
    case IDLN_TYPE_STRUCT:
	get_struct_typecode (tfd->tree);
	break;
    case IDLN_TYPE_UNION:
	get_union_typecode (tfd->tree);
	break;
    default:
	break;
    }

    return CORBA_TRUE;
}

CORBA_boolean
porbit_parse_idl_file (const char *file)
{
  IDL_tree tree;
  IDL_ns ns;
  int ret;

  /* In theory, we should -D__ORBIT_IDL__ here, to allow
   * people to handle libIDL peculiarities. However, the
   * main thing people enable with #ifdef __ORBIT_IDL__
   * is #pragma push inhibit, which breaks us badly, since
   * we can't rely on the definitions in some C library!
   */
  ret = IDL_parse_filename (file, "", NULL, &tree, &ns,
			    IDLF_TYPECODES | IDLF_CODEFRAGS,
			    IDL_WARNING1);

  if (ret == IDL_ERROR) {
      warn ("Error parsing IDL");
      return CORBA_FALSE;
  } else if (ret < 0) {
      warn ("Error parsing IDL: %s", g_strerror (errno));
  }

  IDL_tree_walk (tree, NULL, tree_pre_func, tree_post_func, NULL);

  IDL_tree_free (tree);
  IDL_ns_free (ns);
  
  return CORBA_TRUE;
}
