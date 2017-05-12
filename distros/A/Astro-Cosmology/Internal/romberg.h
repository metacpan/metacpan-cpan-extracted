/*
 * $Id: romberg.h,v 1.0 2001/07/27 18:08:32 dburke Exp $
 *
 * romberg.h
 *
 * Based on FORTRAN version of:
 *
 *    NUMERICAL METHODS: FORTRAN Programs, (c) John H. Mathews 1994
 *    To accompany the text:
 *    NUMERICAL METHODS for Mathematics, Science and Engineering, 2nd Ed, 1992
 *    Prentice Hall, Englewood Cliffs, New Jersey, 07632, U.S.A.
 *    This free software is complements of the author.
 *
 *    Algorithm 7.3 (Recursive Trapezoidal Rule).
 *    Algorithm 7.4 (Romberg Integration).
 *    Section 7.3, Recursive Rules and Romberg Integration, Page 379
 *
 */

unsigned int 
romberg_f( float func( float x, float om, float ol ),
	   float om, float ol, 
	   float start, float finish,
	   float abstol,
	   float *answer_p, float *error_p ) ;

unsigned int 
romberg_d( double func( double x, double om, double ol ),
	   double om, double ol, 
	   double start, double finish,
	   double abstol,
	   double *answer_p, double *error_p ) ;

