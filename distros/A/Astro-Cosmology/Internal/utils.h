/*
 * $Id: utils.h,v 1.0 2001/07/27 18:08:38 dburke Exp $
 *
 * utility routines for the cosmology code
 */

float 
comov_dist_fn_f( float z, float om, float ol );

float 
lookback_time_fn_f( float z, float om, float ol );

double 
comov_dist_fn_d( double z, double om, double ol );

double 
lookback_time_fn_d( double z, double om, double ol );

