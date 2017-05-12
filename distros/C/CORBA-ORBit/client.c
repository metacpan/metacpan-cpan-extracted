/* -*- mode: C; c-file-style: "bsd" -*- */

#include <orb/interface_repository.h>
#include "client.h"
#include "errors.h"
#include "interfaces.h"
#include "types.h"

typedef struct {
    CORBA_unsigned_long len;
    char opname[1];
} OpNameData;

static GPtrArray *
do_marshal (CV *cv, I32 ax, I32 items,
	    CORBA_InterfaceDef_FullInterfaceDescription *desc, I32 index,
	    CORBA_Object obj, GIOPConnection *connection, GIOP_unsigned_long request_id)
{
    OpNameData *operation_name_data;
    static struct iovec operation_vec;
    char *name = NULL;
    GIOPSendBuffer *send_buffer = NULL;
    SV *error_sv = NULL;
    GPtrArray *return_types = NULL;
    dTHR;
    
    /* Determine the operation name used over GIOP
     */
    if (index >= PORBIT_OPERATION_BASE && index < PORBIT_GETTER_BASE) {
	name = g_strdup (desc->operations._buffer[index-PORBIT_OPERATION_BASE].name);
    } else if (index >= PORBIT_GETTER_BASE && index < PORBIT_SETTER_BASE) {
	name = g_strconcat ("_get_", desc->attributes._buffer[index-PORBIT_GETTER_BASE].name, NULL);
    } else if (index >= PORBIT_SETTER_BASE) {
	name = g_strconcat ("_set_", desc->attributes._buffer[index-PORBIT_SETTER_BASE].name, NULL);
    }

    /* Create a SendBuffer for the result
     */
    operation_name_data = (OpNameData *)g_malloc (sizeof (OpNameData) + strlen(name));
    operation_name_data->len = strlen(name) + 1;
    strcpy (operation_name_data->opname, name);
    
    operation_vec.iov_base = operation_name_data;
    operation_vec.iov_len = sizeof(CORBA_unsigned_long) + operation_name_data->len;
    
    send_buffer =
	giop_send_request_buffer_use(connection, NULL, request_id, CORBA_TRUE,
				     &(obj->active_profile->object_key_vec),
				     &operation_vec, &ORBit_default_principal_iovec);
    
    if (!send_buffer) {
	error_sv =
	    porbit_system_except ("IDL:omg.org/CORBA/COMM_FAILURE:1.0",
				  0, CORBA_COMPLETED_NO);
	goto exception;
    }

    /* Do the marshalling. We accumulate the return types into an array for
     * use while demarshalling.
     */

    return_types = g_ptr_array_new();
    
    if (index >= PORBIT_OPERATION_BASE && index < PORBIT_GETTER_BASE) {
        CORBA_OperationDescription *opr = &desc->operations._buffer[index-PORBIT_OPERATION_BASE];
	CORBA_unsigned_long i, st_index;

	if (opr->result->kind != CORBA_tk_void)
	    g_ptr_array_add (return_types, opr->result);
	
	st_index = 1;
	for (i = 0 ; i<opr->parameters._length; i++) {
	    SV *arg = (st_index<(CORBA_unsigned_long)items) ? ST(st_index) : &PL_sv_undef;

	    switch (opr->parameters._buffer[i].mode) {
	    case CORBA_PARAM_IN:
		if (!porbit_put_sv (send_buffer, opr->parameters._buffer[i].type, arg)) {
		    warn ("Error marshalling parameter '%s'",
			  opr->parameters._buffer[i].name);
		    error_sv =
			porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0",
					      0, CORBA_COMPLETED_NO);
		    goto exception;
		}
		st_index++;
		break;
	    case CORBA_PARAM_INOUT:
		if (!SvROK(arg) ||
		    !porbit_put_sv (send_buffer, opr->parameters._buffer[i].type, SvRV (arg))) {
		    
		    if (!SvROK (arg))
			warn ("INOUT parameter must be a reference");
		    else
			warn ("Error marshalling parameter '%s'", opr->parameters._buffer[i].name);
		    
		    error_sv =
			porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0",
					      0, CORBA_COMPLETED_NO);

		    goto exception;
		}
		st_index++;
		/* Fall through */
	    case CORBA_PARAM_OUT:
		g_ptr_array_add (return_types, opr->parameters._buffer[i].type);
		break;
	    }
	}

    } else if (index >= PORBIT_GETTER_BASE && index < PORBIT_SETTER_BASE) {
	g_ptr_array_add (return_types, desc->attributes._buffer[index-PORBIT_GETTER_BASE].type);

    } else if (index >= PORBIT_SETTER_BASE) {
        if (items < 2) {
	    warn("%s::%s called without second argument", HvNAME(CvSTASH(cv)), name);
	    error_sv =
		porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0",
				      0, CORBA_COMPLETED_NO);
	    goto exception;
	}

	if (!porbit_put_sv (send_buffer, 
			    desc->attributes._buffer[index-PORBIT_SETTER_BASE].type, 
			    ST(1))) {
	    warn ("Error marshalling attribute value");
	    error_sv =
		porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0",
				      0, CORBA_COMPLETED_NO);
	    goto exception;
	}
    }

    /* Invoke the operation
     */
    giop_send_buffer_write(send_buffer);

 exception:
    giop_send_buffer_unuse(send_buffer);
    g_free (operation_name_data);
    g_free (name);

    if (error_sv) {
	if (return_types)
	    g_ptr_array_free (return_types, TRUE);
	porbit_throw (error_sv);
    }

    return return_types;
}

static GIOPConnection *
do_demarshal (CV *cv, I32 ax, I32 items,
	      CORBA_InterfaceDef_FullInterfaceDescription *desc, I32 index, 
	      GPtrArray *return_types,
	      CORBA_Object obj, GIOPConnection *connection, GIOP_unsigned_long request_id)
{
    GIOPRecvBuffer *recv_buffer;
    SV *error_sv = NULL;
    SV **results = NULL;
    CORBA_unsigned_long i;
    CORBA_OperationDescription *opr = NULL;

    dTHR;
    
    if (index >= PORBIT_OPERATION_BASE && index < PORBIT_GETTER_BASE)
	opr = &desc->operations._buffer[index-PORBIT_OPERATION_BASE];

    recv_buffer = giop_recv_reply_buffer_use_2(connection, request_id, TRUE);
    if (!recv_buffer) {
	    error_sv =
		porbit_system_except ("IDL:omg.org/CORBA/COMM_FAILURE:1.0",
				      0, CORBA_COMPLETED_MAYBE);
	    goto exception;
    }
	
    if (recv_buffer->message.u.reply.reply_status == GIOP_LOCATION_FORWARD) {

	if (obj->forward_locations != NULL)
	    ORBit_delete_profiles(obj->forward_locations);
	obj->forward_locations = ORBit_demarshal_IOR(recv_buffer);
	connection = ORBit_object_get_forwarded_connection(obj);
	
	giop_recv_buffer_unuse(recv_buffer);

	return connection;
	
    } else if (recv_buffer->message.u.reply.reply_status != GIOP_NO_EXCEPTION) {
	error_sv = porbit_get_exception (recv_buffer, NULL,
					 recv_buffer->message.u.reply.reply_status, opr);
	if (!error_sv)
	    error_sv = porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0", 
					     0, CORBA_COMPLETED_YES);

	goto exception;
    }

    /* Demarshal return parameters */

    results = g_new0 (SV *, return_types->len);
    for (i=0; i<return_types->len; i++) {
	results[i] = porbit_get_sv (recv_buffer, return_types->pdata[i]);
	if (!results[i]) {
	    warn ("Error demarshalling result");
	    error_sv = porbit_system_except ("IDL:omg.org/CORBA/MARSHAL:1.0", 
					     0, CORBA_COMPLETED_YES);

	    goto exception;
	}
    }
    
    if (index >= PORBIT_OPERATION_BASE && index < PORBIT_GETTER_BASE) {

	CORBA_unsigned_long i, st_index, ret_index;

	/* First write back INOUT parameters into their references.
	 * (Is this safe? If we end up calling back to perl, could the
	 *  stack already be overridden?)
	 */
	st_index = 1;
	ret_index = (opr->result->kind == CORBA_tk_void) ? 0 : 1;
	for (i = 0 ; i<opr->parameters._length; i++) {
	    switch (opr->parameters._buffer[i].mode) {
	    case CORBA_PARAM_IN:
		st_index++;
		break;
	    case CORBA_PARAM_INOUT:
		sv_setsv (SvRV(ST(st_index)), results[ret_index]);
		st_index++;
		ret_index++;
		break;
	    case CORBA_PARAM_OUT:
		ret_index++;
		break;
	    }
	}

	/* Now write out return value and OUT parameters to stack
	 */
	ret_index = 0;
	if (opr->result->kind != CORBA_tk_void) {
	    /* FIXME, do the right thing in array and scalar contexts
	     */
	    ST(0) = sv_2mortal(results[0]);
	    ret_index++;
	}

	for (i = 0 ; i<opr->parameters._length; i++) {
	    switch (opr->parameters._buffer[i].mode) {
	    case CORBA_PARAM_IN:
		break;
	    case CORBA_PARAM_INOUT:
		ret_index++;
		break;
	    case CORBA_PARAM_OUT:
		ST(ret_index) = sv_2mortal (results[ret_index]);
		ret_index++;
		break;
	    }
	}
    } else if (index >= PORBIT_GETTER_BASE && index < PORBIT_SETTER_BASE) {
	ST(0) = sv_2mortal(results[0]);
    }
    
    g_free (results);
    results = NULL;
    
 exception:
    if (results) {
	for (i=0; i < return_types->len; i++)
	    if (results[i])
		SvREFCNT_dec (results[i]);
	g_free (results);
    }
    g_ptr_array_free (return_types, TRUE);
    giop_recv_buffer_unuse(recv_buffer);
    
    if (error_sv)
	porbit_throw (error_sv);

    return NULL;
}


XS(_porbit_callStub)
{
    dXSARGS;

    GIOP_unsigned_long request_id;
    GIOPConnection *connection, *new_connection;
    GPtrArray *return_types;
    guint return_count;
    I32 index;
    PORBitIfaceInfo *info;
    CORBA_Object obj;
    char *repoid;
    SV **repoidp;

    index = XSANY.any_i32;
    
    repoidp = hv_fetch(CvSTASH(cv), PORBIT_REPOID_KEY, strlen(PORBIT_REPOID_KEY), 0);
    if (!repoidp)
	croak("_pmico_callStub called with bad package (no %s)",PORBIT_REPOID_KEY);
    
    repoid = SvPV(GvSV(*repoidp), PL_na);
    
    info = porbit_find_interface_description (repoid);
    if (!info)
	croak("_pmico_callStub called on undefined interface");

    /* Get the discriminator
     */
    if (items < 1)
	croak("method must have object as first argument");

    obj = porbit_sv_to_objref(ST(0)); /* may croak */
    connection = ORBit_object_get_connection(obj);

 retry_request:
    /* This is utterly broken and I'm ashamed to copy it from ORBit. But,
     * it is necessary for compatibility.
     */
    request_id = GPOINTER_TO_UINT(alloca(0));

    return_types = do_marshal (cv, ax, items,
			       info->desc, index,
			       obj, connection, request_id);
    return_count = return_types->len;

    /* FIXME: Somewhat dubious stack growing code */
    if (PL_stack_max - &ST(0) < return_count)
       stack_grow (PL_stack_sp, &ST(0), return_count);

    if ((index >= PORBIT_OPERATION_BASE && index < PORBIT_GETTER_BASE) &&
	info->desc->operations._buffer[index-PORBIT_OPERATION_BASE].mode == CORBA_OP_ONEWAY) {
	if (return_count != 0) {
	    warn ("Oneway operation has output parameters or a return value!\n");
	}
    } else {
	new_connection = do_demarshal (cv, ax, items,
				       info->desc, index, return_types,
				       obj, connection, request_id);

	if (new_connection) {
	    connection = new_connection;
	    goto retry_request;
	}
    }

    XSRETURN(return_count);
}
