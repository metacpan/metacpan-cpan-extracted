#ifndef bgu_voronoi2perl_h_
#define bgu_voronoi2perl_h_

#include <cstdio>
#include <map>
#include <cmath>

using namespace boost::polygon;

typedef medial_axis<double> VD;
typedef segment_data<int> bp_segment;

static const unsigned int EXTERNAL_COLOR = (unsigned int) 1;
static const unsigned int IS_LEAF        = (unsigned int) 2;
static const unsigned int AT_JUNCTION    = (unsigned int) 4;
static const unsigned int PROCESSED      = (unsigned int) 8;

typedef double CT;
typedef double AT;

double pi = 4 * atan2(1, 1);

void rotate_2d(double &x, double &y, const double theta, const double xo = 0, const double yo = 0) {
  double xp;
  x -= xo;
  y -= yo;
  xp = (x * cos(theta) - y * sin(theta)) + xo;
  y  = (y * cos(theta) + x * sin(theta)) + yo;
  x  = xp;
}
template <typename CT>
void reflect_point_about_line(CT &x, CT &y, const CT x0, const CT y0, const CT x1, const CT y1) {
  double dy = (double) (y1 - y0);
  double dx = (double) (x1 - x0);
  if (dy == 0 && dx == 0) {return;}
  double theta = atan2(dy, dx);
  rotate_2d(x, y, -theta, x0, y0);
  y -= y0;
  y *= -1.0;
  y += y0;
  rotate_2d(x, y, theta, x0, y0);
}

SV* 
medial_axis2perl(const VD &vd, const bool internal_only = true) {

  std::size_t num_edges = 0;
  if (internal_only) {
    for (VD::const_edge_iterator it = vd.edges().begin(); it != vd.edges().end(); ++it) {
      if (!(it->color() & EXTERNAL_COLOR)) { ++num_edges; }
    }
  } else {
    num_edges = vd.num_edges();
  }
  
  AV* edges_out = newAV();
  av_extend(edges_out, num_edges - 1);
  AV* vertices_out = newAV();
  av_extend(vertices_out, vd.num_vertices() - 1);

  // lookup tables used in recreating the medial axis data structure for perl
  std::map<const VD::edge_type*, AV*> thisToThis;
  std::map<const VD::edge_type*, AV*> thisToTwin;
  std::map<const VD::edge_type*, AV*> thisToNext;
  std::map<const VD::edge_type*, AV*> thisToPrev;
  std::map<const VD::vertex_type*, AV*> vertToAV;

  std::size_t count = 0;
  
  const VD::edge_type* start_edge = NULL;
  for (VD::const_edge_iterator it = vd.edges().begin(); it != vd.edges().end(); ++it) {
    // Get the primary edge corresponding to the first input
    // segment, which should be the first segment of the outer contour
    // of a polygon with holes.
    if (!(it->color() & EXTERNAL_COLOR) && it->cell()->source_index() == 0 && it->is_primary()) {
      start_edge = &(*it);
      break;
    }
  }
  
  while (start_edge != NULL) {
    const VD::edge_type* it = start_edge;
    do {

      // For all primary edges, calculate:
      //   theta = direction of the edge
      //     phi = direction to polygon edge, as deflection from theta
      //           (although in practice that may not be the most practical
      //            so might change that to just the plain angle, or vector...)
      //
      // TODO: also need some kind of parabola parameter for the curved edges
      // which replaces all the non-primary edges related to curved edges.
      // A convenient parameter for display is just the quadratic bezier
      // control point, which occures at the intersection of the tangent lines
      // at the two ends of the curved edge - easy to feed that to SVG path.
      // It's not clear it that's the best parameterization for working out 
      // sampled toolpaths though.

      double theta = 0;
      double phi = 0;

      if (it->is_primary() && it->is_finite()
          && (!internal_only || !(it->color() & EXTERNAL_COLOR))
         ) {
        
        // calculate theta
        if (it->is_curved()) {
          theta = atan2( -(it->foot()->x()                 - it->vertex0()->x())
                        + (it->twin()->next()->foot()->x() - it->vertex0()->x())
                        , (it->foot()->y()                 - it->vertex0()->y())
                        - (it->twin()->next()->foot()->y() - it->vertex0()->y())
                       );
        } else {
          theta = atan2((double) it->vertex1()->y() - it->vertex0()->y(),
                        (double) it->vertex1()->x() - it->vertex0()->x());
        }

        // calculate phi
        double tdx = (double) it->foot()->x() - it->vertex0()->x();
        double tdy = (double) it->foot()->y() - it->vertex0()->y();
        
        if (it->prev() == it->twin()) {
          tdx = (double) it->next()->foot()->x() - it->next()->vertex0()->x();
          tdy = (double) it->next()->foot()->y() - it->next()->vertex0()->y();
        }

        if (tdx == 0 && tdy == 0) {phi = theta;}
        else {phi = atan2(tdy, tdx) - theta;}

        while (phi >  pi) {phi-=2*pi;}
        while (phi < -pi) {phi+=2*pi;}

      }
      
      // load up perl data

      if (!(it->color() & PROCESSED)
          && it->is_primary()
          && !(it->color() & EXTERNAL_COLOR)
         ) {
        std::size_t ec1 = it->color();
        it->color(ec1 | PROCESSED);

        // Make the edge AV
        AV* edgeav      = newAV();
        av_store(edges_out, count++, newRV_noinc((SV*) edgeav));

        // Process each vertex just once, the first time we see it.
        // Each vertex gets one edge reference -
        // doesn't matter which, so the first.
        // Ray edges have NULL vertices, so always check for that.

        if (it->vertex0() && !(it->vertex0()->color() & PROCESSED)) {
          if (it->vertex0()) {
            std::size_t vc1 = it->vertex0()->color();
            it->vertex0()->color(vc1 | PROCESSED);
            AV* pointav     = newAV();
            vertToAV[it->vertex0()] = pointav;
            av_push(vertices_out, newRV_noinc((SV*) pointav));
            av_fill(pointav,     3);
            av_store_point_xy(pointav,     it->vertex0()->x(),         it->vertex0()->y());
            av_store(pointav,     2, newSVnv(it->vertex0()->r()));
            av_store(pointav,     3, newRV_inc((SV*) edgeav));
          }
        }

        // fill in edge data
        av_fill(edgeav,     10);
        // cell ref - index corresponding to original segment input
        av_store(edgeav,     0, newSVuv(it->cell()->source_index()));
        // start vertex ref (rays coming in from infinity don't have one)
        if (it->vertex0()) {
          if (vertToAV[it->vertex0()]) {
            av_store(edgeav,     1, newRV_inc((SV*) vertToAV[it->vertex0()]));
          }
        } 
        
        // indeces 2, 3 and 4 are for twin, next and prev edges, 
        // to be filled in later
        
        // edge direction
        av_store(edgeav,     5, newSVnv(theta));
        // radius direction to source segment, as rotation from edge direction
        av_store(edgeav,     6, newSVnv(phi));
        // is it a parabolic curve?
        av_store(edgeav,     7, newSViv(        it->is_curved() ? 1 : 0));
        // is it primary?
        av_store(edgeav,     8, newSViv(        it->is_primary() ? 1 : 0));
        // is it internal?
        int intr1 = (        it->color() - PROCESSED > 0) ? 0 : 1;
        av_store(edgeav,     9, newSViv(intr1));

        // an edge's start vertex, with it's radius, and the edge's angle phi
        // are enough to calculate the foot. So including the foot in the data
        // structure is redundant. But until we see what's most practical in
        // use, we'll include the foot too. Besides, it helps with dev and debug
        // visualizations.
        
        if (it->foot()) {
          AV* footav     = newAV();
          av_fill(footav,     1);
          av_store_point_xy(footav, it->foot()->x(), it->foot()->y());
          av_store(edgeav,     10, newRV_inc((SV*) footav));
        }
        
        // fill in the lookup tables to finish off the data structure in a 
        // second pass through the edge list, after this loop is done
        thisToThis[it]                 = edgeav;
        thisToTwin[it->twin()]         = edgeav;
        thisToNext[it->prev()]         = edgeav;
        thisToPrev[it->next()]         = edgeav;
      }
      
      it = it->next();
      
    } while (it != start_edge);
    
    // If there are multiple loops, find a start edge for the next one.
    start_edge = NULL;
    for (VD::const_edge_iterator it = vd.edges().begin(); it != vd.edges().end(); ++it) {
      if (
          !(it->color() & PROCESSED)
          && it->is_primary()
          && !(it->color() & EXTERNAL_COLOR)
         ) {
        start_edge = &(*it);
        break;
      }
    }
  }

  // fill in all the edge-to-edge references from the lookup tables
  for (VD::const_edge_iterator it = vd.edges().begin(); it != vd.edges().end(); ++it) {
    if (it->is_primary() && !(it->color() & EXTERNAL_COLOR)) {
      const VD::edge_type* ep = &(*it);
      AV* edgeav     = thisToThis[ep];
      AV* edgeavtwin = thisToTwin[ep];
      AV* edgeavnext = thisToNext[ep];
      AV* edgeavprev = thisToPrev[ep];

      /* debug notices */
      /*
            Line commented because they fail to compile under Windows with the following error:
            src/voronoi2perl.h:242:76: error: cast from 'const edge_type* {aka const boost::
            polygon::medial_axis_edge<double>*}' to 'long unsigned int' loses precision [-fp
            ermissive]
      if (!edgeav    ) {printf("av     not def. ep: %lu\n",(unsigned long) ep);}
      if (!edgeavtwin) {printf("avtwin not def. ep: %lu\n",(unsigned long) ep);}
      if (!edgeavprev) {printf("avprev not def. ep: %lu\n",(unsigned long) ep);}
      if (!edgeavnext) {printf("avnext not def. ep: %lu\n",(unsigned long) ep);}
        */
      if (edgeavtwin != NULL) {
        av_store(edgeav, 2, newRV_inc((SV*) edgeavtwin));
      }
      if (edgeavnext != NULL) {
        av_store(edgeav, 3, newRV_inc((SV*) edgeavnext));
      }
      if (edgeavprev != NULL) {
        av_store(edgeav, 4, newRV_inc((SV*) edgeavprev));
      }
    }
  }


  // Debug report
  
  if (0) {
    printf("\n\nfiltered edges\n");
    printf("srcInd isInf curved   color  this     twin       next       prev        point\n");
    for (VD::const_edge_iterator it = vd.edges().begin(); it != vd.edges().end(); ++it) {
      if (1
          //&& it->is_primary()
          //&& it->vertex0() && it->vertex1() 
          //&& it->is_finite() 
          //&& !(it->color() & EXTERNAL_COLOR)
          ) {

          printf("%3ld   %5s  %7s  %2ld%1s ",
            it->cell()->source_index(),
            (it->is_finite() ? "     ":" INF "),
            (it->is_curved() ? " curve ":" line  "),
            it->color(),
            (it->is_primary() ? "p" : "s")
          );
          printf("%llu, %llu , %llu, %llu ",
            (unsigned long long int) &(*it),
            (unsigned long long int) it->twin(),
            (unsigned long long int) it->next(),
            (unsigned long long int) it->prev()
          );
       if (it->vertex0()) {printf("[%f , %f , %f]",it->vertex0()->x(),it->vertex0()->y(),it->vertex0()->r());}
       else {printf("no vert0");}
       printf("\n");
      }
    }
  }
  

  HV * result = newHV();
  (void)hv_store(result, "edges",    strlen("edges"),    newRV_noinc((SV*) edges_out), 0);
  (void)hv_store(result, "vertices", strlen("vertices"), newRV_noinc((SV*) vertices_out), 0);
  (void)hv_store(result, "events",   strlen("events"),   newSVpv(vd.event_log().c_str(), 0), 0);

  return newRV_noinc((SV*) result);

}

template <typename RingLike, typename VBT>
void builder_segments_from_ring(const RingLike &my_ring, VBT & vb) {
  BOOST_AUTO(it, boost::begin(my_ring));
  BOOST_AUTO(end, boost::end(my_ring));
  BOOST_AUTO(previous, it);
  for (it++; it != end; ++previous, ++it) {
    const bp_segment s( bp_point_xy(previous->template get<0>(),previous->template get<1>()), 
                        bp_point_xy(it->template get<0>(), it->template get<1>()) );
    
    boost::polygon::insert( s, &vb );
  }
  // If ring wasn't closed, add one more closing segment
  if (boost::size(my_ring) > 2) {
    if (boost::geometry::disjoint(*boost::begin(my_ring), *(boost::end(my_ring) - 1))) {
        const bp_segment s( bp_point_xy((end - 1)->template get<0>(),(end - 1)->template get<1>()), 
                            bp_point_xy(my_ring.begin()->template get<0>(), my_ring.begin()->template get<1>()) );
        boost::polygon::insert( s, &vb );
    }
  }
}

#endif
