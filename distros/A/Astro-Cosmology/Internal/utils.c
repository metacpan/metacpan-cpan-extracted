/*
 * $Id: utils.c,v 1.0 2001/07/27 18:08:36 dburke Exp $
 *
 * utility routines for the cosmology code
 */

#include <math.h>

double comov_dist_fn_d( double z, double om, double ol ) 
{
  register double zp1 = 1.0 + z;

  return 1.0 / 
    ( sqrt( zp1 * zp1 * (1.0 + om*z) - z * (2.0 + z) * ol ) );

} /*** lum_dist_fn_d() ***/

double lookback_time_fn_d( double z, double om, double ol ) 
{
  register double zp1 = 1.0 + z;

  return 1.0 / 
    ( zp1 * sqrt( zp1 * zp1 * (1.0 + om*z) - z * (2.0 + z) * ol ) );

} /*** lum_dist_fn_d() ***/

/* float versions */

float comov_dist_fn_f( float z, float om, float ol ) 
{
  register float zp1 = 1.0 + z;

  return 1.0 / 
    ( sqrt( zp1 * zp1 * (1.0 + om*z) - z * (2.0 + z) * ol ) );

} /*** lum_dist_fn_f() ***/

float lookback_time_fn_f( float z, float om, float ol ) 
{
  register float zp1 = 1.0 + z;

  return 1.0 / 
    ( zp1 * sqrt( zp1 * zp1 * (1.0 + om*z) - z * (2.0 + z) * ol ) );

} /*** lum_dist_fn_f() ***/




