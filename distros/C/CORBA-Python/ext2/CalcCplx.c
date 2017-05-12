/* This file was partialy generated (by idl2pyext.pl).*/
/* From file : CalcCplx.idl, 212 octets, Mon May 23 09:42:34 2005
 */

/* START_EDIT */

/* STOP_EDIT */

#include "CalcCplx.h"

/*
 * begin of module Cplx
 */
/* START_EDIT (Cplx_CalcCplx) */

/* STOP_EDIT (Cplx_CalcCplx) */

/*
 * begin of interface Cplx_CalcCplx
 */

/* START_COMMENT (Cplx_CalcCplx_Add) */
/* STOP_COMMENT (Cplx_CalcCplx_Add) */
/* ARGSUSED */
Cplx_Complex
Cplx_CalcCplx_Add(
	Cplx_CalcCplx _o,
	Cplx_Complex * val1, // in (fixed length)
	Cplx_Complex * val2, // in (fixed length)
	CORBA_Environment * _ev
)
{
/* START_EDIT (Cplx_CalcCplx_Add) */
	Cplx_Complex _ret;

	_ret.re = val1->re + val2->re;
	_ret.im = val1->im + val2->im;
//	printf("add -> %f, %f\n", _ret.re, _ret.im);
	return _ret;
/* STOP_EDIT (Cplx_CalcCplx_Add) */
}


/* START_COMMENT (Cplx_CalcCplx_Sub) */
/* STOP_COMMENT (Cplx_CalcCplx_Sub) */
/* ARGSUSED */
Cplx_Complex
Cplx_CalcCplx_Sub(
	Cplx_CalcCplx _o,
	Cplx_Complex * val1, // in (fixed length)
	Cplx_Complex * val2, // in (fixed length)
	CORBA_Environment * _ev
)
{
/* START_EDIT (Cplx_CalcCplx_Sub) */
	Cplx_Complex _ret;

	_ret.re = val1->re - val2->re;
	_ret.im = val1->im - val2->im;
//	printf("sub -> %f, %f\n", _ret.re, _ret.im);
	return _ret;
/* STOP_EDIT (Cplx_CalcCplx_Sub) */
}

/*
 * end of interface Cplx_CalcCplx
 */
/*
 * end of module Cplx
 */

/* end of file : CalcCplx.c */
