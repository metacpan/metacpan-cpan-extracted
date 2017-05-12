#ifndef bgu_point2av_h_
#define bgu_point2av_h_

#include "myinit.h"

SV*
point_xy2perl(pTHX_ const point_xy& point)
{
  AV* av = newAV();
  av_fill(av, 1);
  av_store_point_xy(av, point.x(), point.y());
  return (SV*)newRV_noinc((SV*)av);
}

point_xy*
perl2point_xy(pTHX_ AV* theAv)
{
    using boost::geometry::make;
    
  point_xy* retval = new point_xy(av_fetch_point_xy(theAv));
  return retval;
}

#endif
