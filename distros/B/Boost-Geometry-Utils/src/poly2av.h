#ifndef bgu_poly2av_h_
#define bgu_poly2av_h_

#include <iostream>
#include "myinit.h"
#include <boost/geometry/algorithms/num_points.hpp>

void add_ring_perl(AV* polygon_av, ring& theRing)
{
    AV* ring_av = newAV();
    AV* point_av;
    
    // number of points in the ring
    const unsigned int len = boost::geometry::num_points(theRing);
    av_extend(ring_av, len-1);
    //fprintf(stderr, "Points in ring: len=%d\n", len);
  
    for(unsigned int i = 0; i < len; i++) {
        point_av = newAV();
        av_store(ring_av, i, newRV_noinc((SV*)point_av));
        av_fill(point_av, 1);
        av_store_point_xy(point_av, theRing[i].x(), theRing[i].y());
    }
    
    av_push(polygon_av, newRV_noinc((SV*)ring_av));
}

SV*
polygon2perl(pTHX_ const polygon& poly)
{
    AV* av = newAV();
    
    ring my_ring = poly.outer();
    add_ring_perl(av, my_ring);
    
    std::vector<ring>::size_type sz = poly.inners().size();
    for (unsigned i = 0; i < sz; i++) {
        my_ring = poly.inners()[i];
        add_ring_perl(av, my_ring);
    }
    
    return (SV*)newRV_noinc((SV*)av);
}

SV*
multi_polygon2perl(pTHX_ const multi_polygon& multi_poly)
{
    AV* av = newAV();
    
    // number of polygons in this multi_polygon
    std::size_t poly_count = boost::geometry::num_geometries(multi_poly);
    
    for (unsigned i = 0; i < poly_count; i++) {
        polygon poly = multi_poly[i];
        AV* polyav = newAV();
        
        // add contour
        ring my_ring = poly.outer();
        add_ring_perl(polyav, my_ring);
        
        // add holes
        std::vector<ring>::size_type sz = poly.inners().size();
        for (unsigned j= 0; j < sz; j++) {
            my_ring = poly.inners()[j];
            add_ring_perl(polyav, my_ring);
        }
        
        av_push(av, newRV_noinc((SV*)polyav));
    }
    
    return (SV*)newRV_noinc((SV*)av);
}

int add_ring(AV* theAv, polygon& poly, const int ring_index)
{
    using boost::geometry::append;
    using boost::geometry::make;

  const unsigned int len = av_len(theAv)+1;
  SV** elem;
  AV* innerav;
  for (unsigned int i = 0; i < len; i++) {
    elem = av_fetch(theAv, i, 0);
    if (!SvROK(*elem)
        || SvTYPE(SvRV(*elem)) != SVt_PVAV
        || av_len((AV*)SvRV(*elem)) != 1)  // require two coordinates per point
    {
      return 0;
    }
    innerav = (AV*)SvRV(*elem);
    append(poly, av_fetch_point_xy(innerav), ring_index);
  }
  return 1;
}

polygon*
perl2polygon(pTHX_ AV* theAv)
{
    using boost::geometry::interior_rings;
    
    // read number of input rings
    const unsigned int len = av_len(theAv)+1;
    
    // initialize resulting polygon
    polygon* retval = new polygon();
    
    // create interior rings (append doesn't create them automatically)
    interior_rings(*retval).resize(len-1);
  
    SV** elem;
    for (unsigned int i = 0; i < len; i++) {
        // validate input data
        elem = av_fetch(theAv, i, 0);
        if (!SvROK(*elem)
            || SvTYPE(SvRV(*elem)) != SVt_PVAV
            || av_len((AV*)SvRV(*elem)) < 1)  // require at least two points in ring
        {
            delete retval;
            return NULL;
        }
    
        // append point to ring i-1 (-1 is outer ring)
        if (!add_ring((AV*)SvRV(*elem), *retval, i-1)) {
            delete retval;
            return NULL;
        }
    }
    return retval;
}

multi_polygon*
perl2multi_polygon(pTHX_ AV* theAv)
{
    // initialize resulting multi_polygon
    multi_polygon* retval = new multi_polygon();
  
    SV** elem;
    const unsigned int len = av_len(theAv)+1;
    for (unsigned int i = 0; i < len; i++) {
        // validate input data
        elem = av_fetch(theAv, i, 0);
        if (!SvROK(*elem)
            || SvTYPE(SvRV(*elem)) != SVt_PVAV
            || av_len((AV*)SvRV(*elem)) < 0)  // require at least one polygon
        {
            delete retval;
            return NULL;
        }
        
        polygon* poly = perl2polygon(aTHX_ (AV*)SvRV(*elem));
        retval->push_back(*poly);
        delete poly;
    }
    return retval;
}

#endif
