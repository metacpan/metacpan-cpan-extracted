
#ifndef _CDR_h_
#define _CDR_h_

#include <corba.h>


#define ALIGN1(idx)			idx = (idx)
#define ALIGN2(idx)			idx = ((idx+1) & (~1))
#define ALIGN4(idx)			idx = ((idx+3) & (~3))
#define ALIGN8(idx)			idx = ((idx+7) & (~7))
#define PTR_ALIGN1(p)		p = (p)
#define PTR_ALIGN2(p)		p = (char *)((1+(unsigned)p) & (~1))
#define PTR_ALIGN4(p)		p = (char *)((3+(unsigned)p) & (~3))
#define PTR_ALIGN8(p)		p = (char *)((7+(unsigned)p) & (~7))

/*
 *	Section 15.3.1	Primitive Types
 */

#define SIZEOF_CORBA_char(v)								1
#if _USE_WCHAR
#define SIZEOF_CORBA_wchar(v)								4
#endif
#define SIZEOF_CORBA_octet(v)								1
#define SIZEOF_CORBA_short(v)								2
#define SIZEOF_CORBA_unsigned_short(v)					2
#define SIZEOF_CORBA_long(v)								4
#define SIZEOF_CORBA_unsigned_long(v)					4
#define SIZEOF_CORBA_long_long(v)						8
#define SIZEOF_CORBA_unsigned_long_long(v)			8
#define SIZEOF_CORBA_float(v)								4
#define SIZEOF_CORBA_double(v)							8
#define SIZEOF_CORBA_long_double(v)						16
#define SIZEOF_CORBA_boolean(v)							1


#define ALIGN_CORBA_char(idx)		{	\
				_align = 1;	\
			}
#if _USE_WCHAR
#define ALIGN_CORBA_wchar(idx)		{	\
				if (_align < 4) {	\
					ALIGN4(idx);	\
					_align = 4;		\
				}	\
			}
#endif
#define ALIGN_CORBA_octet(idx)	{	\
				_align = 1;	\
			}
#define ALIGN_CORBA_short(idx)	{	\
				if (_align < 2) {	\
					ALIGN2(idx);	\
				}	\
				_align = 2;		\
			}
#define ALIGN_CORBA_unsigned_short(idx)	{	\
				if (_align < 2) {	\
					ALIGN2(idx);	\
				}	\
				_align = 2;		\
			}
#define ALIGN_CORBA_long(idx)		{	\
				if (_align < 4) {	\
					ALIGN4(idx);	\
				}	\
				_align = 4;		\
			}
#define ALIGN_CORBA_unsigned_long(idx)		{	\
				if (_align < 4) {	\
					ALIGN4(idx);	\
				}	\
				_align = 4;		\
			}
#define ALIGN_CORBA_long_long(idx)		{	\
				if (_align < 8) {	\
					ALIGN8(idx);	\
				}	\
				_align = 8;		\
			}
#define ALIGN_CORBA_unsigned_long_long(idx)		{	\
				if (_align < 8) {	\
					ALIGN8(idx);	\
				}	\
				_align = 8;		\
			}
#define ALIGN_CORBA_float(idx)	{	\
				if (_align < 4) {	\
					ALIGN4(idx);	\
				}	\
				_align = 4;		\
			}
#define ALIGN_CORBA_double(idx)		{	\
				if (_align < 8) {	\
					ALIGN8(idx);	\
				}	\
				_align = 8;		\
			}
#define ALIGN_CORBA_long_double(idx)	{	\
				if (_align < 8) {	\
					ALIGN8(idx);	\
				}	\
				_align = 8;		\
			}
#define ALIGN_CORBA_boolean(idx)		{ \
				_align = 1; \
			}


#define ADD_SIZE_CORBA_char(size,v)	{	\
				ALIGN_CORBA_char(size);			\
				size += SIZEOF_CORBA_char(v);	\
			}
#if _USE_WCHAR
#define ADD_SIZE_CORBA_wchar(size,v)	{	\
				ALIGN_CORBA_wchar(size);			\
				size += SIZEOF_CORBA_wchar(v);	\
			}
#endif
#define ADD_SIZE_CORBA_octet(size,v)	{	\
				ALIGN_CORBA_octet(size);			\
				size += SIZEOF_CORBA_octet(v);	\
			}
#define ADD_SIZE_CORBA_short(size,v)	{	\
				ALIGN_CORBA_short(size);			\
				size += SIZEOF_CORBA_short(v);	\
			}
#define ADD_SIZE_CORBA_unsigned_short(size,v)	{	\
				ALIGN_CORBA_unsigned_short(size);			\
				size += SIZEOF_CORBA_unsigned_short(v);	\
			}
#define ADD_SIZE_CORBA_long(size,v)	{	\
				ALIGN_CORBA_long(size);			\
				size += SIZEOF_CORBA_long(v);	\
			}
#define ADD_SIZE_CORBA_unsigned_long(size,v)	{	\
				ALIGN_CORBA_unsigned_long(size);			\
				size += SIZEOF_CORBA_unsigned_long(v);	\
			}
#define ADD_SIZE_CORBA_long_long(size,v)	{	\
				ALIGN_CORBA_long_long(size);			\
				size += SIZEOF_CORBA_long_long(v);	\
			}
#define ADD_SIZE_CORBA_unsigned_long_long(size,v)	{	\
				ALIGN_CORBA_unsigned_long_long(size);			\
				size += SIZEOF_CORBA_unsigned_long_long(v);	\
			}
#define ADD_SIZE_CORBA_float(size,v)	{	\
				ALIGN_CORBA_float(size);			\
				size += SIZEOF_CORBA_float(v);	\
			}
#define ADD_SIZE_CORBA_double(size,v)	{	\
				ALIGN_CORBA_double(size);			\
				size += SIZEOF_CORBA_double(v);	\
			}
#define ADD_SIZE_CORBA_long_double(size,v)	{	\
				ALIGN_CORBA_long_double(size);			\
				size += SIZEOF_CORBA_long_double(v);	\
			}
#define ADD_SIZE_CORBA_boolean(size,v)	{	\
				ALIGN_CORBA_boolean(size);			\
				size += SIZEOF_CORBA_boolean(v);	\
			}
#define ADD_SIZE_CORBA_string(size,v)	{	\
				ALIGN_CORBA_unsigned_long(size);		\
				size += SIZEOF_CORBA_unsigned_long(x) + SIZEOF_CORBA_char(x) * (strlen(v) + 1);	\
				ALIGN_CORBA_char(size);					\
			}
#if _USE_WCHAR
#define ADD_SIZE_CORBA_wstring(size,v)	{	\
				ALIGN_CORBA_unsigned_long(size);		\
				size += SIZEOF_CORBA_unsigned_long(x) + SIZEOF_CORBA_wchar(x) * (wcslen(v) + 1);	\
				ALIGN_CORBA_wchar(size);				\
			}
#endif

#define PTR_ALIGN_CORBA_char(idx)		{	\
				_align = 1;	\
			}
#if _USE_WCHAR
#define PTR_ALIGN_CORBA_wchar(idx)		{	\
				if (_align < 4) {	\
					PTR_ALIGN4(idx);	\
					_align = 4;		\
				}	\
			}
#endif
#define PTR_ALIGN_CORBA_octet(idx)	{	\
				_align = 1;	\
			}
#define PTR_ALIGN_CORBA_short(idx)	{	\
				if (_align < 2) {	\
					PTR_ALIGN2(idx);	\
				}	\
				_align = 2;		\
			}
#define PTR_ALIGN_CORBA_unsigned_short(idx)	{	\
				if (_align < 2) {	\
					PTR_ALIGN2(idx);	\
				}	\
				_align = 2;		\
			}
#define PTR_ALIGN_CORBA_long(idx)		{	\
				if (_align < 4) {	\
					PTR_ALIGN4(idx);	\
				}	\
				_align = 4;		\
			}
#define PTR_ALIGN_CORBA_unsigned_long(idx)		{	\
				if (_align < 4) {	\
					PTR_ALIGN4(idx);	\
				}	\
				_align = 4;		\
			}
#define PTR_ALIGN_CORBA_long_long(idx)		{	\
				if (_align < 8) {	\
					PTR_ALIGN8(idx);	\
				}	\
				_align = 8;		\
			}
#define PTR_ALIGN_CORBA_unsigned_long_long(idx)		{	\
				if (_align < 8) {	\
					PTR_ALIGN8(idx);	\
				}	\
				_align = 8;		\
			}
#define PTR_ALIGN_CORBA_float(idx)	{	\
				if (_align < 4) {	\
					PTR_ALIGN4(idx);	\
				}	\
				_align = 4;		\
			}
#define PTR_ALIGN_CORBA_double(idx)		{	\
				if (_align < 8) {	\
					PTR_ALIGN8(idx);	\
				}	\
				_align = 8;		\
			}
#define PTR_ALIGN_CORBA_long_double(idx)	{	\
				if (_align < 8) {	\
					PTR_ALIGN8(idx);	\
				}	\
				_align = 8;		\
			}
#define PTR_ALIGN_CORBA_boolean(idx)		{ \
				_align = 1; \
			}


#define PUT_CORBA_char(ptr,v)		{	\
				PTR_ALIGN_CORBA_char(ptr);		\
				*((CORBA_char *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_char(v);	\
			}
#if _USE_WCHAR
#define PUT_CORBA_wchar(ptr,v)		{	\
				PTR_ALIGN_CORBA_wchar(ptr);		\
				*((CORBA_wchar *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_wchar(v);		\
			}
#endif
#define PUT_CORBA_octet(ptr,v)		{	\
				PTR_ALIGN_CORBA_octet(ptr);		\
				*((CORBA_octet *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_octet(v);		\
			}
#define PUT_CORBA_short(ptr,v)		{	\
				PTR_ALIGN_CORBA_short(ptr);		\
				*((CORBA_short *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_short(v);		\
			}
#define PUT_CORBA_unsigned_short(ptr,v)		{	\
				PTR_ALIGN_CORBA_unsigned_short(ptr);		\
				*((CORBA_unsigned_short *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_unsigned_short(v);		\
			}
#define PUT_CORBA_long(ptr,v)		{	\
				PTR_ALIGN_CORBA_long(ptr);		\
				*((CORBA_long *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_long(v);	\
			}
#define PUT_CORBA_unsigned_long(ptr,v)		{	\
				PTR_ALIGN_CORBA_unsigned_long(ptr);		\
				*((CORBA_unsigned_long *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_unsigned_long(v);	\
			}
#define PUT_CORBA_long_long(ptr,v)		{	\
				PTR_ALIGN_CORBA_long_long(ptr);		\
				*((CORBA_long_long *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_long_long(v);	\
			}
#define PUT_CORBA_unsigned_long_long(ptr,v)		{	\
				PTR_ALIGN_CORBA_unsigned_long_long(ptr);		\
				*((CORBA_unsigned_long_long *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_unsigned_long_long(v);	\
			}
#define PUT_CORBA_float(ptr,v)		{	\
				PTR_ALIGN_CORBA_float(ptr);		\
				*((CORBA_float *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_float(v);		\
			}
#define PUT_CORBA_double(ptr,v)		{	\
				PTR_ALIGN_CORBA_double(ptr);		\
				*((CORBA_double *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_double(v);	\
			}
#define PUT_CORBA_long_double(ptr,v)		{	\
				PTR_ALIGN_CORBA_long_double(ptr);		\
				*((CORBA_long_double *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_long_double(v);		\
			}
#define PUT_CORBA_boolean(ptr,v)		{	\
				PTR_ALIGN_CORBA_boolean(ptr);		\
				*((CORBA_boolean *)(ptr)) = (v);	\
				ptr += SIZEOF_CORBA_boolean(v);	\
			}
#define PUT_CORBA_string(ptr,v)		{	\
				int len = strlen(v) + 1;				\
				PUT_CORBA_unsigned_long(ptr,len);	\
				memcpy(ptr,(v),len);						\
				ptr += len;									\
				PTR_ALIGN_CORBA_char(ptr);				\
			}
#if _USE_WCHAR
#define PUT_CORBA_wstring(ptr,v)		{\
				int len = wcslen(v) + 1;							\
				PUT_CORBA_unsigned_long(ptr,len);				\
				memcpy(ptr,(v),len * SIZEOF_CORBA_wchar(x));	\
				ptr += len * SIZEOF_CORBA_wchar(x);				\
				PTR_ALIGN_CORBA_char(offset);						\
			}
#endif

#define GET_CORBA_char(ptr,v)		{	\
				PTR_ALIGN_CORBA_char(ptr);			\
				*(v) = *((CORBA_char *)(ptr));	\
				ptr += SIZEOF_CORBA_char(v);		\
			}
#define GET_inout_CORBA_char	GET_CORBA_char
#define GET_out_CORBA_char		GET_CORBA_char
#if _USE_WCHAR
#define PUT_CORBA_wchar(ptr,v)		{	\
				PTR_ALIGN_CORBA_wchar(ptr);		\
				*(v) = *((CORBA_wchar *)(ptr));	\
				ptr += SIZEOF_CORBA_wchar(v);		\
			}
#define GET_inout_CORBA_wchar	GET_CORBA_wchar
#define GET_out_CORBA_wchar	GET_CORBA_wchar
#endif
#define GET_CORBA_octet(ptr,v)		{	\
				PTR_ALIGN_CORBA_octet(ptr);		\
				*(v) = *((CORBA_octet *)(ptr));	\
				ptr += SIZEOF_CORBA_octet(v);		\
			}
#define GET_inout_CORBA_octet	GET_CORBA_octet
#define GET_out_CORBA_octet	GET_CORBA_octet
#define GET_CORBA_short(ptr,v)		{	\
				PTR_ALIGN_CORBA_short(ptr);		\
				*(v) = *((CORBA_short *)(ptr));	\
				ptr += SIZEOF_CORBA_short(v);		\
			}
#define GET_inout_CORBA_short	GET_CORBA_short
#define GET_out_CORBA_short	GET_CORBA_short
#define GET_CORBA_unsigned_short(ptr,v)		{	\
				PTR_ALIGN_CORBA_unsigned_short(ptr);		\
				*(v) = *((CORBA_unsigned_short *)(ptr));	\
				ptr += SIZEOF_CORBA_unsigned_short(v);		\
			}
#define GET_inout_CORBA_unsigned_short	GET_CORBA_unsigned_short
#define GET_out_CORBA_unsigned_short	GET_CORBA_unsigned_short
#define GET_CORBA_long(ptr,v)		{	\
				PTR_ALIGN_CORBA_long(ptr);			\
				*(v) = *((CORBA_long *)(ptr));	\
				ptr += SIZEOF_CORBA_long(v);		\
			}
#define GET_inout_CORBA_long	GET_CORBA_long
#define GET_out_CORBA_long		GET_CORBA_long
#define GET_CORBA_unsigned_long(ptr,v)		{	\
				PTR_ALIGN_CORBA_unsigned_long(ptr);			\
				*(v) = *((CORBA_unsigned_long *)(ptr));	\
				ptr += SIZEOF_CORBA_unsigned_long(v);		\
			}
#define GET_inout_CORBA_unsigned_long	GET_CORBA_unsigned_long
#define GET_out_CORBA_unsigned_long		GET_CORBA_unsigned_long
#define GET_CORBA_long_long(ptr,v)		{	\
				PTR_ALIGN_CORBA_long_long(ptr);		\
				*(v) = *((CORBA_long_long *)(ptr));	\
				ptr += SIZEOF_CORBA_long_long(v);	\
			}
#define GET_inout_CORBA_long_long	GET_CORBA_long_long
#define GET_out_CORBA_long_long		GET_CORBA_long_long
#define GET_CORBA_unsigned_long_long(ptr,v)		{	\
				PTR_ALIGN_CORBA_unsigned_long_long(ptr);		\
				*(v) = *((CORBA_unsigned_long_long *)(ptr));	\
				ptr += SIZEOF_CORBA_unsigned_long_long(v);	\
			}
#define GET_inout_CORBA_unsigned_long_long	GET_CORBA_unsigned_long_long
#define GET_out_CORBA_unsigned_long_long		GET_CORBA_unsigned_long_long
#define GET_CORBA_float(ptr,v)		{	\
				PTR_ALIGN_CORBA_float(ptr);		\
				*(v) = *((CORBA_float *)(ptr));	\
				ptr += SIZEOF_CORBA_float(v);		\
			}
#define GET_inout_CORBA_float	GET_CORBA_float
#define GET_out_CORBA_float	GET_CORBA_float
#define GET_CORBA_double(ptr,v)		{	\
				PTR_ALIGN_CORBA_double(ptr);		\
				*(v) = *((CORBA_double *)(ptr));	\
				ptr += SIZEOF_CORBA_double(v);	\
			}
#define GET_inout_CORBA_double	GET_CORBA_double
#define GET_out_CORBA_double		GET_CORBA_double
#define GET_CORBA_long_double(ptr,v)		{	\
				PTR_ALIGN_CORBA_long_double(ptr);		\
				*(v) = *((CORBA_long_double *)(ptr));	\
				ptr += SIZEOF_CORBA_long_double(v);		\
			}
#define GET_inout_CORBA_long_double	GET_CORBA_long_double
#define GET_out_CORBA_long_double	GET_CORBA_long_double
#define GET_CORBA_boolean(ptr,v)		{	\
				PTR_ALIGN_CORBA_boolean(ptr);			\
				*(v) = *((CORBA_boolean *)(ptr));	\
				ptr += SIZEOF_CORBA_boolean(v);		\
			}
#define GET_inout_CORBA_boolean	GET_CORBA_boolean
#define GET_out_CORBA_boolean		GET_CORBA_boolean
#define GET_CORBA_string(ptr,v)		{	\
				CORBA_unsigned_long len;					\
				GET_CORBA_unsigned_long(ptr,&len);		\
				*(v) = CORBA_string__alloc(len);			\
				if (NULL == *(v)) goto err;				\
				memcpy(*(v),ptr,len);						\
				if ((*(v))[len-1] != '\0') goto err;	\
				ptr += len;										\
				PTR_ALIGN_CORBA_char(ptr);					\
			}
#define GET_inout_CORBA_string(ptr,v)		{	\
				CORBA_unsigned_long len;					\
				GET_CORBA_unsigned_long(ptr,&len);		\
				if (NULL != *(v)) {							\
					CORBA_free(*(v));							\
				}													\
				*(v) = CORBA_string__alloc(len);			\
				if (NULL == *(v)) goto err;				\
				memcpy(*(v),ptr,len);						\
				if ((*(v))[len-1] != '\0') goto err;	\
				ptr += len;										\
				PTR_ALIGN_CORBA_char(ptr);					\
			}
#define GET_out_CORBA_string(ptr,v)		{	\
				CORBA_unsigned_long len;					\
				GET_CORBA_unsigned_long(ptr,&len);		\
				*(v) = CORBA_string__alloc(len);			\
				if (NULL == *(v)) goto err;				\
				memcpy(*(v),ptr,len);						\
				if ((*(v))[len-1] != '\0') goto err;	\
				ptr += len;										\
				PTR_ALIGN_CORBA_char(ptr);					\
			}
#define ALLOC_GET_out_CORBA_string(ptr,v)		{	\
				CORBA_unsigned_long len;					\
				GET_CORBA_unsigned_long(ptr,&len);		\
				*(v) = (CORBA_char *)CORBA_alloc(len);	\
				if (NULL == *(v)) goto err;				\
				memcpy(*(v),ptr,len);						\
				if ((*(v))[len-1] != '\0') goto err;	\
				ptr += len;										\
				PTR_ALIGN_CORBA_char(ptr);					\
			}
#define FREE_CORBA_string(v) {\
				CORBA_free(*(v));\
			}
#define FREE_in_CORBA_string(v) {\
				CORBA_free(*(v));\
			}
#define FREE__inout_CORBA_string(v) {\
				CORBA_free(*(v));\
			}
#define FREE_out_CORBA_string(v) {\
				CORBA_free(*(v));\
			}
#if _USE_WCHAR
#define GET_CORBA_wstring(ptr,v)		{\
				CORBA_unsigned_long len;							\
				GET_CORBA_unsigned_long(ptr,&len);				\
				memcpy((v),ptr,len * SIZEOF_CORBA_wchar(x));	\
				ptr += len * SIZEOF_CORBA_wchar(x);				\
				PTR_ALIGN_CORBA_wchar(offset);					\
			}
#endif

#endif



