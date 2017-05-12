#undef read
#undef bind
#undef times
#undef open
#undef seekdir
#undef setbuf
#undef abort
#undef close
#undef select
#include <boost/foreach.hpp>
#include <boost/geometry.hpp>
#include <boost/geometry/geometries/point_xy.hpp>
#include <boost/geometry/geometries/polygon.hpp>
#include <boost/geometry/geometries/linestring.hpp>
#include <boost/geometry/geometries/ring.hpp>
#include <boost/geometry/multi/geometries/multi_linestring.hpp>
#include <boost/geometry/multi/geometries/multi_polygon.hpp>
#include <boost/geometry/io/wkt/wkt.hpp>
#include <boost/geometry/geometries/adapted/boost_polygon.hpp>
#include <boost/polygon/voronoi.hpp>

typedef boost::geometry::model::d2::point_xy<double> point_xy;
typedef boost::geometry::model::polygon<point_xy,false,false> polygon;
typedef boost::geometry::model::multi_polygon<polygon> multi_polygon;
typedef boost::geometry::model::linestring<point_xy> linestring;
typedef boost::geometry::model::multi_linestring<linestring> multi_linestring;
typedef boost::geometry::model::ring<point_xy,false,false> ring;

/* Boost::Polygon::Voronoi's default config calls for 32 bit integer input. */
typedef boost::polygon::point_data<I32> bp_point_xy;

// Support old API
typedef boost::geometry::model::polygon<point_xy,false,false> opolygon;
typedef boost::geometry::model::multi_polygon<polygon> omultipolygon;
typedef boost::geometry::model::multi_linestring<linestring> omultilinestring;


// for av_fetch, use SvIV() 
// this library then supports 64 bit ints.
#define av_fetch_x(AV) SvNV(*av_fetch(AV, 0, 0))
#define av_fetch_y(AV) SvNV(*av_fetch(AV, 1, 0))

// for av_store, use newSViv()
#define av_store_point_xy(AV, X, Y)              \
  av_store(AV, 0, newSVnv(X));                   \
  av_store(AV, 1, newSVnv(Y))

#define av_fetch_point_xy(AV)                    \
  make<point_xy>(av_fetch_x(AV), av_fetch_y(AV))

#include "poly2av.h"
#include "mline2av.h"
#include "point2av.h"
#include "line2av.h"
#include "medial_axis.hpp"
#include "voronoi2perl.h"
