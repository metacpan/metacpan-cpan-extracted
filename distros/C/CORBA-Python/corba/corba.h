
#ifndef _CORBA_defined
#define _CORBA_defined

#include "Python.h"
#include <stdint.h>

/*
 *  Basic Data Types
 */

typedef signed short int   CORBA_short;
typedef signed long int    CORBA_long;
typedef int64_t            CORBA_long_long;
typedef unsigned short int CORBA_unsigned_short;
typedef unsigned long int  CORBA_unsigned_long;
typedef uint64_t           CORBA_unsigned_long_long;
typedef float              CORBA_float;
typedef double             CORBA_double;
typedef long double        CORBA_long_double;
typedef char               CORBA_char;
typedef Py_UNICODE         CORBA_wchar;
typedef unsigned char      CORBA_boolean;

typedef void * CORBA_Object;
typedef unsigned char      CORBA_octet;

typedef struct CORBA_any {
#if 0
	CORBA_TypeCode    _type;
#endif       
	void *            _value;
} CORBA_any;

extern void CORBA_free(void * storage);
extern void * CORBA_alloc(CORBA_unsigned_long size);

#define CORBA_string__alloc(len)        (CORBA_char *)CORBA_alloc((len) + 1)
#define CORBA_wstring__alloc(len)       (CORBA_wchar *)CORBA_alloc(((len) + 1) * sizeof(CORBA_wchar))

/*
 *  exception
 */

typedef enum {
	CORBA_NO_EXCEPTION = 0,
	CORBA_USER_EXCEPTION,      // Exceptions that can be raised only by those
	                           // operations that explicitly declare them in
	                           // the raises clause of their signature.
	CORBA_SYSTEM_EXCEPTION     // These exceptions cannot appear in a raises clause.
	                           // Clients must be prepared to handle these
	                           // exceptions even though they are not declared
	                           // in a raises clause.
} CORBA_exception_type;

struct CORBA_Environment_type {
	CORBA_exception_type _major;
	CORBA_char *_repo_id;
	void *_params;
	CORBA_any *_any;
};
typedef struct CORBA_Environment_type CORBA_Environment;

extern void CORBA_exception_set(
	CORBA_Environment *ev,
	CORBA_exception_type major,
	CORBA_char *except_repos_id,
	void *param
);

/*
   CORBA_exception_id() returns a pointer to the character string identifying the
   exception. The character string contains the repository ID for the exception.
   If invoked on a CORBA_Environment which identifies a non-exception,
   (_major==CORBA_NO_EXCEPTION) a null pointer is returned. Note that ownership
   of the returned pointer does not transfer to the caller; instead, the pointer
   remains valid until CORBA_exception_free() is called.
*/
#define CORBA_exception_id(ev) ((ev)->_repo_id)

/*
   CORBA_exception_value() returns a pointer to the structure corresponding to
   this exception. If invoked on a CORBA_Environment which identifies a non-exception
   or an exception for which there is no associated information, a null pointer is
   returned. Note that ownership of the returned pointer does not transfer to the caller;
   instead, the pointer remains valid until CORBA_exception_free() is called.
*/
#define CORBA_exception_value(ev) ((ev)->_params)

/*
 *  system exception
 */

typedef enum {
	CORBA_COMPLETED_YES = 0,   // The object implementation has completed
	                           // processing prior to the exception being raised.
	CORBA_COMPLETED_NO,        // The object implementation was never initiated
	                           // prior to the exception being raised.
	CORBA_COMPLETED_MAYBE      // The status of implementation completion is
	                           // indeterminate.
} CORBA_completion_status;

typedef struct CORBA_system_exception {
	CORBA_unsigned_long minor;
	CORBA_completion_status completed;
} CORBA_SystemException;

#define ex_CORBA_UNKNOWN 1                   // the unknown exception
#define ex_CORBA_BAD_PARAM 2                 // an invalid parameter was passed
#define ex_CORBA_NO_MEMORY 3                 // dynamic memory allocation failure
#define ex_CORBA_IMP_LIMIT 4                 // violated implementation limit
#define ex_CORBA_COMM_FAILURE 5              // communication failure
#define ex_CORBA_INV_OBJREF 6                // invalid object reference
#define ex_CORBA_NO_PERMISSION 7             // no permission for attempted op.
#define ex_CORBA_INTERNAL 8                  // ORB internal error
#define ex_CORBA_MARSHAL 9                   // error marshaling param/result
#define ex_CORBA_INITIALIZE 10               // ORB initialization failure
#define ex_CORBA_NO_IMPLEMENT 11             // operation implementation unavailable
#define ex_CORBA_BAD_TYPECODE 12             // bad typecode
#define ex_CORBA_BAD_OPERATION 13            // invalid operation
#define ex_CORBA_NO_RESOURCES 14             // insufficient resources for req.
#define ex_CORBA_NO_RESPONSE 15              // response to req. not yet available
#define ex_CORBA_PERSIST_STORE 16            // persistent storage failure
#define ex_CORBA_BAD_INV_ORDER 17            // routine invocations out of order
#define ex_CORBA_TRANSIENT 18                // transient failure - reissue request
#define ex_CORBA_FREE_MEM 19                 // cannot free memory
#define ex_CORBA_INV_IDENT 20                // invalid identifier syntax
#define ex_CORBA_INV_FLAG 21                 // invalid flag was specified
#define ex_CORBA_INTF_REPOS 22               // error accessing interface repository
#define ex_CORBA_BAD_CONTEXT 23              // error processing context object
#define ex_CORBA_OBJ_ADAPTER 24              // failure detected by object adapter
#define ex_CORBA_DATA_CONVERSION 25          // data conversion error
#define ex_CORBA_OBJECT_NOT_EXIST 26         // non-existent object, delete reference
#define ex_CORBA_TRANSACTION_REQUIRED 27     // transaction required
#define ex_CORBA_TRANSACTION_ROLLEDBACK 28   // transaction rolled back
#define ex_CORBA_INVALID_TRANSACTION 29      // invalid transaction
#define ex_CORBA_INV_POLICY 30               // invalid policy
#define ex_CORBA_CODESET_INCOMPATIBLE 31     // incompatible code set
#define ex_CORBA_REBIND 32                   // rebind needed
#define ex_CORBA_TIMEOUT 33                  // operation timed out
#define ex_CORBA_TRANSACTION_UNAVAILABLE 34  // no transaction
#define ex_CORBA_TRANSACTION_MODE 35         // invalid transaction mode
#define ex_CORBA_BAD_QOS 36                  // bad quality of service

extern void CORBA_exception_set_system(
	CORBA_Environment *ev,
	CORBA_unsigned_long minor,
	CORBA_completion_status completed
);

#endif
