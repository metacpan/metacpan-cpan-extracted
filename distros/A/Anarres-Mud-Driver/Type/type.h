#ifndef __AMDP_TYPE_H__
#define __AMDP_TYPE_H__

#include <stdarg.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "amd.h"



	/* Type indicators */
#define C_VOID			'v'
#define C_NIL			'n'
#define C_UNKNOWN		'?'
#define C_BOOL			'b'
#define C_CLOSURE		'f'
#define C_INTEGER		'i'
#define C_OBJECT		'o'
#define C_STRING		's'
#define C_M_ARRAY		'*'
#define C_M_MAPPING		'#'
#define C_M_CLASS_BEGIN	'{'
#define C_M_CLASS_MID	':'
#define C_M_CLASS_END	'}'

#define C_FAILED		'!'



	/* Type modifiers */
	/* Accessibility stuff */
#define M_NOMASK        0x0000001
#define M_NOSAVE        0x0000002
#define M_STATIC        0x0000004
#define M_PRIVATE       0x0000010
#define M_PROTECTED     0x0000020
#define M_PUBLIC        0x0000040
	/* Does this apply to the method or the last arg? */ 
#define M_VARARGS       0x0000100
	/* Properties of the method */
#define M_EFUN          0x0001000
#define M_APPLY         0x0002000
#define M_INHERITED     0x0004000
#define M_HIDDEN        0x0010000
#define M_UNKNOWN       0x0020000
	/* Let's leave this alone for now. */ 
#define M_PURE          0x0100000



	/* Exported functions from Type.xs */
SV	*amd_type_new(const char *str);

#endif
