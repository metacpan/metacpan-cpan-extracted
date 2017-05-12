#ifndef bgu_mline2av_h_
#define bgu_mline2av_h_

#include "myinit.h"
#include <boost/geometry/algorithms/num_points.hpp>

SV*
multi_linestring2perl(pTHX_ const multi_linestring& mls)
{
  AV* av = newAV();
  const unsigned int size = mls.size();
  av_extend(av, size-1);

  for (int i = 0; i < size; i++) {
    AV* lineav = newAV();
    linestring ls = mls[i];
    av_store(av, i, newRV_noinc((SV*)lineav));
    av_fill(lineav, 1);
    const unsigned int line_len = boost::geometry::num_points(ls);
    for (int j = 0; j < line_len; j++) {
      AV* pointav = newAV();
      av_store(lineav, j, newRV_noinc((SV*)pointav));
      av_fill(pointav, 1);
      av_store_point_xy(pointav, ls[j].x(), ls[j].y());
    }
  }
    
  return (SV*)newRV_noinc((SV*)av);
}

void add_line(AV* theAv, multi_linestring* mls)
{
    using boost::geometry::make;

  const unsigned int len = av_len(theAv)+1;
  SV** elem;
  AV* innerav;
  linestring ls;
  for (unsigned int i = 0; i < len; i++) {
    elem = av_fetch(theAv, i, 0);
    if (!SvROK(*elem)
        || SvTYPE(SvRV(*elem)) != SVt_PVAV
        || av_len((AV*)SvRV(*elem)) < 1)
    {
      return;
    }
    innerav = (AV*)SvRV(*elem);
    ls.push_back(av_fetch_point_xy(innerav));
  }
  mls->push_back(ls);
}

multi_linestring*
perl2multi_linestring(pTHX_ AV* theAv)
{
  const unsigned int len = av_len(theAv)+1;
  multi_linestring* retval = new multi_linestring();
  
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
    add_line((AV*)SvRV(*elem), retval);
  }
  return retval;
}

#endif
