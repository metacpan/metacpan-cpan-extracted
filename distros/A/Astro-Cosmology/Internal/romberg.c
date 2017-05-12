/*
 * $Id: romberg.c,v 1.0 2001/07/27 18:08:22 dburke Exp $
 *
 * romberg.c
 *
 * integrate, using the romberg method, the supplied
 * function. This is specifically for cosmological
 * 'distance' measure calculations, since the function
 * to be integrated must match
 *   double func( double x, double omega_matter, double omega_lambda )
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

#include <math.h>

/*
 * note: extremely simplistic error handling 
 */

#define MINN  4
#define MAXN  12

#define MINNP1  ((MINN) + 1)
#define MAXNP1  ((MAXN) + 1)

unsigned int 
romberg_d( double func( double x, double om, double ol ),
	   double om, double ol, 
	   double start, double finish,
	   double abstol,
	   double *answer_p, double *error_p ) 
{
  double r[MAXNP1][MAXNP1];

  register double step, sum;

  register int j, jm1, k, km1, m;

  unsigned int retval = 1;       /* 1 for okay, 0 for error */

  /* code */
  *error_p = 1.0;
  step     = finish - start;
  m        = 1;
  j        = 0;
  jm1      = j - 1;

  r[0][0] = step * 0.5 * 
    ( func(start, om, ol) + func(finish, om, ol) );
			  
  while ( (j < MINN) ||
	  ( (*error_p > abstol) && (j < MAXN) ) )
  {
    j++;
    jm1++;
    step *= 0.5;

    sum = 0.0;
    for( k = 1; k <= m; k++ ) {
      sum += func( start + step * (2.0*k - 1.0), om, ol );
    }

    r[0][j] = step * sum + 0.5 * r[0][jm1];

    m *= 2;
    for( k = 1, km1 = 0; k <= j; km1++, k++ ) {
      r[k][j] = r[km1][j] +
	( r[km1][j] - r[km1][jm1] ) / ( pow(4.0,(double) k) - 1.0 );
    }

    *error_p = fabs( r[jm1][jm1] - r[j][j] );

  } /* while( j < MINN ... ) */

  *answer_p = r[j][j];

  if ( *error_p > abstol ) { retval = 0; }

  return retval;

} /*** romberg_d() ***/


unsigned int 
romberg_f( float func( float x, float om, float ol ),
	   float om, float ol, 
	   float start, float finish,
	   float abstol,
	   float *answer_p, float *error_p ) 
{
  float r[MAXNP1][MAXNP1];

  register float step, sum;

  register int j, jm1, k, km1, m;

  unsigned int retval = 1;       /* 1 for okay, 0 for error */

  /* code */
  *error_p = 1.0;
  step     = finish - start;
  m        = 1;
  j        = 0;
  jm1      = j - 1;

  r[0][0] = step * 0.5 * 
    ( func(start, om, ol) + func(finish, om, ol) );
			  
  while ( (j < MINN) ||
	  ( (*error_p > abstol) && (j < MAXN) ) )
  {
    j++;
    jm1++;
    step *= 0.5;

    sum = 0.0;
    for( k = 1; k <= m; k++ ) {
      sum += func( start + step * (2.0*k - 1.0), om, ol );
    }

    r[0][j] = step * sum + 0.5 * r[0][jm1];

    m *= 2;
    for( k = 1, km1 = 0; k <= j; km1++, k++ ) {
      r[k][j] = r[km1][j] +
	( r[km1][j] - r[km1][jm1] ) / ( pow(4.0,(double) k) - 1.0 );
    }

    *error_p = fabs( r[jm1][jm1] - r[j][j] );

  } /* while( j < MINN ... ) */

  *answer_p = r[j][j];

  if ( *error_p > abstol ) { retval = 0; }

  return retval;

} /*** romberg_f() ***/

