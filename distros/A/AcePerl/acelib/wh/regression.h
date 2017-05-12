/*  Last edited: Dec  4 14:48 1998 (fw) */



/*  header file for regression.c */

/* $Id: regression.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

#ifndef DEFINE_REGRESSION_h
#define DEFINE_REGRESSION_h

#include "regular.h"

typedef struct point {double x, y ;} POINT ;

void linearRegression(Array a, double *ap, double *bp, double *rp, double *wp) ;
void plotLinearRegression(char *title, Array a) ;

#endif

