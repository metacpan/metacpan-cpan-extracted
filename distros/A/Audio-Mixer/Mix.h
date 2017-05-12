/*
 * Library to query / set various sound mixer parameters.
 *
 * This code is based on setmixer program by Michal Jaegermann
 *
 * Copyright (c) 2000 Sergey Gribov <sergey@sergey.com>
 * This is free software with ABSOLUTELY NO WARRANTY.
 * You can redistribute and modify it freely, but please leave
 * this message attached to this file.
 *
 * Subject to terms of GNU General Public License (www.gnu.org) 
 *
 * Last update: $Date: 2002/04/30 00:48:21 $ by $Author: sergey $
 * Revision: $Revision: 1.3 $
 *
 */

#define MIXER "/dev/mixer"

int get_param_val(char *cntrl);

int set_param_val(char *cntrl, int lcval, int rcval);

int init_mixer();
int close_mixer();

int get_params_num();

char *get_params_list();

int set_mixer_dev(char *fname);

char *get_source();

int set_source(char *cntrl);

