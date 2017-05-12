
#include <stdlib.h>
#include <corba.h>

void CORBA_free(void * storage)
{
	free(storage);
}

void * CORBA_alloc(CORBA_unsigned_long size)
{
	return malloc(size);
}

/*
 *
 *   CORBA_exception_set() allows a method implementation to raise an exception.
 *   The ev parameter is the environment parameter passed into the method. The caller
 *   must supply a value for the major parameter. The value of the major parameter
 *   constrains the other parameters in the call as follows:
 *      - If the major parameter has the value CORBA_NO_EXCEPTION, this is a normal
 *      outcome to the operation. In this case, both except_repos_id and param
 *      must be NULL. Note that it is not necessary to invoke
 *      CORBA_exception_set() to indicate a normal outcome; it is the default
 *      behavior if the method simply returns.
 *      - For any other value of major it specifies either a user-defined or system
 *      exception. The except_repos_id parameter is the repository ID representing
 *      the exception type. If the exception is declared to have members, the param
 *      parameter must be the address of an instance of the exception struct containing
 *      the parameters according to the C language mapping, coerced to a void*. In this
 *      case, the exception struct must be allocated using the appropriate T__alloc()
 *      function, and the CORBA_exception_set() function adopts the allocated
 *      memory and frees it when it no longer needs it. Once the allocated exception
 *      struct is passed to CORBA_exception_set(), the application is not allowed to
 *      access it because it no longer owns it. If the exception takes no parameters,
 *      param must be NULL.
 *   If the CORBA_Environment argument to CORBA_exception_set() already has
 *   an exception set in it, that exception is properly freed before the new exception
 *   information is set.
 *
 */

void CORBA_exception_set(
	CORBA_Environment *ev,
	CORBA_exception_type major,
	CORBA_char *except_repos_id,
	void *param
)
{
	ev->_major = major;
	ev->_repo_id = except_repos_id;
	ev->_params = param;
}

void CORBA_exception_set_system(
	CORBA_Environment *ev,
	CORBA_unsigned_long minor,
	CORBA_completion_status completed
)
{
	const char * const exception_table[] = {
		NULL,
		"IDL:CORBA/UNKNOWN:1.0",                /* 1 */
		"IDL:CORBA/BAD_PARAM:1.0",              /* 2 */
		"IDL:CORBA/NO_MEMORY:1.0",              /* 3 */
		"IDL:CORBA/IMP_LIMIT:1.0",              /* 4 */
		"IDL:CORBA/COMM_FAILURE:1.0",           /* 5 */
		"IDL:CORBA/INV_OBJREF:1.0",             /* 6 */
		"IDL:CORBA/NO_PERMISSION:1.0",          /* 7 */
		"IDL:CORBA/INTERNAL:1.0",               /* 8 */
		"IDL:CORBA/MARSHAL:1.0",                /* 9 */
		"IDL:CORBA/INITIALIZE:1.0",             /* 10 */
		"IDL:CORBA/NO_IMPLEMENT:1.0",           /* 11 */
		"IDL:CORBA/BAD_TYPECODE:1.0",           /* 12 */
		"IDL:CORBA/BAD_OPERATION:1.0",          /* 13 */
		"IDL:CORBA/NO_RESOURCES:1.0",           /* 14 */
		"IDL:CORBA/NO_RESPONSE:1.0",            /* 15 */
		"IDL:CORBA/PERSIST_STORE:1.0",          /* 16 */
		"IDL:CORBA/BAD_INV_ORDER:1.0",          /* 17 */
		"IDL:CORBA/TRANSIENT:1.0",              /* 18 */
		"IDL:CORBA/FREE_MEM:1.0",               /* 19 */
		"IDL:CORBA/INV_IDENT:1.0",              /* 20 */
		"IDL:CORBA/INV_FLAG:1.0",               /* 21 */
		"IDL:CORBA/INTF_REPOS:1.0",             /* 22 */
		"IDL:CORBA/BAD_CONTEXT:1.0",            /* 23 */
		"IDL:CORBA/OBJ_ADAPTER:1.0",            /* 24 */
		"IDL:CORBA/DATA_CONVERSION:1.0",        /* 25 */
		"IDL:CORBA/OBJECT_NOT_EXIST:1.0",       /* 26 */
		"IDL:CORBA/TRANSACTION_REQUIRED:1.0",   /* 27 */
		"IDL:CORBA/TRANSACTION_ROLLEDBACK:1.0", /* 28 */
		"IDL:CORBA/INVALID_TRANSACTION:1.0",    /* 29 */
		"IDL:CORBA/INV_POLICY:1.0",             /* 30 */
		"IDL:CORBA/CODESET_INCOMPATIBLE:1.0",   /* 31 */
		"IDL:CORBA/REBIND:1.0",                 /* 32 */
		"IDL:CORBA/TIMEOUT:1.0",                /* 33 */
		"IDL:CORBA/TRANSACTION_UNAVAILABLE:1.0",/* 34 */
		"IDL:CORBA/TRANSACTION_MODE:1.0",       /* 35 */
		"IDL:CORBA/BAD_QOS:1.0",                /* 36 */
	};
	static CORBA_SystemException _CORBA_SystemException;
	char * repo_id = NULL;

	if (minor > 0 && minor <= 36) {
		repo_id = (char *)exception_table[minor];
	}
	_CORBA_SystemException.minor = minor;
	_CORBA_SystemException.completed = completed;

	CORBA_exception_set(ev, CORBA_SYSTEM_EXCEPTION, repo_id, &_CORBA_SystemException);
}

