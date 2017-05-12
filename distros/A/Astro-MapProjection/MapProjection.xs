#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <math.h>
#include <stdlib.h>

void
hammer_projection(double latitude, double longitude, double* xOut, double* yOut)
{
  const double cosLat = cos(latitude);
  const double longHalf = longitude/2.;
  const double factor = 1./sqrt(1. + cosLat*cos(longHalf));
  *xOut = 2.*sqrt(2.) * cosLat*sin(longHalf) * factor;
  *yOut = sqrt(2.) * sin(latitude) * factor;
}

void
sinusoidal_projection(double latitude, double longitude, double* xOut, double* yOut)
{
  *xOut = longitude*cos(latitude);
  *yOut = latitude;
}

void
miller_projection(double latitude, double longitude, double* xOut, double* yOut)
{
  *xOut = longitude;
  *yOut = 5./4. * log(tan(M_PI/4.+2./5. * latitude));
}


MODULE = Astro::MapProjection		PACKAGE = Astro::MapProjection		

PROTOTYPES: DISABLE


void
miller_projection(double latitude, double longitude, OUTLIST double xOut, OUTLIST double yOut)

void
hammer_projection(double latitude, double longitude, OUTLIST double xOut, OUTLIST double yOut)

void
sinusoidal_projection(double latitude, double longitude, OUTLIST double xOut, OUTLIST double yOut)

