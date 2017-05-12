#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "gctpc/main_interface.h"

#include "const-c.inc"

MODULE = Cartography::Projection::GCTP		PACKAGE = Cartography::Projection::GCTP		

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

void
_exec_gctp_interface(in_x,in_y,in_sys,in_zone,in_parm_0,in_parm_1,in_parm_2,in_parm_3,in_parm_4,in_parm_5,in_parm_6,in_parm_7,in_parm_8,in_parm_9,in_parm_10,in_parm_11,in_parm_12,in_parm_13,in_parm_14,in_unit,in_datum,out_x,out_y,out_sys,out_zone,out_parm_0,out_parm_1,out_parm_2,out_parm_3,out_parm_4,out_parm_5,out_parm_6,out_parm_7,out_parm_8,out_parm_9,out_parm_10,out_parm_11,out_parm_12,out_parm_13,out_parm_14,out_unit,out_datum,eflag)
		double in_x
		double in_y
		long in_sys
		long in_zone
		double in_parm_0
		double in_parm_1
		double in_parm_2
		double in_parm_3
		double in_parm_4
		double in_parm_5
		double in_parm_6
		double in_parm_7
		double in_parm_8
		double in_parm_9
		double in_parm_10
		double in_parm_11
		double in_parm_12
		double in_parm_13
		double in_parm_14
		long in_unit
		long in_datum
		double out_x
		double out_y
		long out_sys
		long out_zone
		double out_parm_0
		double out_parm_1
		double out_parm_2
		double out_parm_3
		double out_parm_4
		double out_parm_5
		double out_parm_6
		double out_parm_7
		double out_parm_8
		double out_parm_9
		double out_parm_10
		double out_parm_11
		double out_parm_12
		double out_parm_13
		double out_parm_14
		long out_unit
		long out_datum
		long eflag
	CODE:
		_call_gctpc(in_x,in_y,in_sys,in_zone,in_parm_0,in_parm_1,in_parm_2,in_parm_3,in_parm_4,in_parm_5,in_parm_6,in_parm_7,in_parm_8,in_parm_9,in_parm_10,in_parm_11,in_parm_12,in_parm_13,in_parm_14,in_unit,in_datum,&out_x,&out_y,out_sys,out_zone,out_parm_0,out_parm_1,out_parm_2,out_parm_3,out_parm_4,out_parm_5,out_parm_6,out_parm_7,out_parm_8,out_parm_9,out_parm_10,out_parm_11,out_parm_12,out_parm_13,out_parm_14,out_unit,out_datum,&eflag);
	OUTPUT:
		out_x
		out_y
		eflag
