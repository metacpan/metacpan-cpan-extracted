#include "./main_interface.h"
#include "./proj.h"
#include <stdio.h>

void _call_gctpc(double in_x,double in_y,long in_sys,long in_zone,double in_parm_0,double in_parm_1,double in_parm_2,double in_parm_3,double in_parm_4,double in_parm_5,double in_parm_6,double in_parm_7,double in_parm_8,double in_parm_9,double in_parm_10,double in_parm_11,double in_parm_12,double in_parm_13,double in_parm_14,long in_unit,long in_datum,double *out_x,double *out_y,long out_sys,long out_zone,double out_parm_0,double out_parm_1,double out_parm_2,double out_parm_3,double out_parm_4,double out_parm_5,double out_parm_6,double out_parm_7,double out_parm_8,double out_parm_9,double out_parm_10,double out_parm_11,double out_parm_12,double out_parm_13,double out_parm_14,long out_unit,long out_datum,long *eflag) {
	double in_params[15];
	double out_params[15];
	double in_coord[2];
	double out_coord[2];
	long zero = 0;
	long print_debug_info = 3;

	in_params[0] = in_parm_0;
	in_params[1] = in_parm_1;
	in_params[2] = in_parm_2;
	in_params[3] = in_parm_3;
	in_params[4] = in_parm_4;
	in_params[5] = in_parm_5;
	in_params[6] = in_parm_6;
	in_params[7] = in_parm_7;
	in_params[8] = in_parm_8;
	in_params[9] = in_parm_9;
	in_params[10] = in_parm_10;
	in_params[11] = in_parm_11;
	in_params[12] = in_parm_12;
	in_params[13] = in_parm_13;
	in_params[14] = in_parm_14;
	out_params[0] = out_parm_0;
	out_params[1] = out_parm_1;
	out_params[2] = out_parm_2;
	out_params[3] = out_parm_3;
	out_params[4] = out_parm_4;
	out_params[5] = out_parm_5;
	out_params[6] = out_parm_6;
	out_params[7] = out_parm_7;
	out_params[8] = out_parm_8;
	out_params[9] = out_parm_9;
	out_params[10] = out_parm_10;
	out_params[11] = out_parm_11;
	out_params[12] = out_parm_12;
	out_params[13] = out_parm_13;
	out_params[14] = out_parm_14;
	in_coord[0] = in_x;
	in_coord[1] = in_y;

	gctp(
		in_coord, &in_sys, &in_zone, in_params, &in_unit, &in_datum,
		&print_debug_info, "", &print_debug_info, "",
		out_coord, &out_sys, &out_zone, out_params, &out_unit, &out_datum,
		"", "", eflag
	);

	*out_x = out_coord[0];
	*out_y = out_coord[1];
}
