#ifndef bgu_line2av_h_
#define bgu_line2av_h_

#include "myinit.h"
#include <boost/geometry/algorithms/num_points.hpp>

SV*
linestring2perl(pTHX_ const linestring& ls)
{
  AV* av = newAV();
  const unsigned int line_len = boost::geometry::num_points(ls);
  av_extend(av, line_len-1);

  for (int i = 0; i < line_len; i++) {
    AV* pointav = newAV();
    av_store(av, i, newRV_noinc((SV*)pointav));
    av_fill(pointav, 1);
    av_store_point_xy(pointav, ls[i].x(), ls[i].y());
  }
    
  return (SV*)newRV_noinc((SV*)av);
}

linestring*
perl2linestring(pTHX_ AV* theAv)
{
    using boost::geometry::make;

  const unsigned int len = av_len(theAv)+1;
  if (len == 0)
    return NULL;
  
  linestring* retval = new linestring();
  
  SV** elem;
  AV* innerav;
  for (unsigned int i = 0; i < len; i++) {
    elem = av_fetch(theAv, i, 0);
    if (!SvROK(*elem)
        || SvTYPE(SvRV(*elem)) != SVt_PVAV
        || av_len((AV*)SvRV(*elem)) < 1)
    {
      delete retval;
      return NULL;
    }
    innerav = (AV*)SvRV(*elem);
    retval->push_back(av_fetch_point_xy(innerav));
  }
  return retval;
}

#endif
