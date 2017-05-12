// medial_axis.hpp header file
// derived from
// Boost.Polygon library voronoi_diagram.hpp header file
// which is
//          Copyright Andrii Sydorchuk 2010-2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

// See http://www.boost.org for updates, documentation, and revision history.

// Derivative work by Michael E. Sheldrake, Copyright 2013, distributed
// under the same terms as the license above.

// This is essentially boost/polygon/voronoi_diagram.hpp adapted to further 
// process the Voronoi diagram graph structure to make it represent the 
// medial axis of a polygon (with holes) represented by segment input.

#ifndef BOOST_POLYGON_MEDIAL_AXIS
#define BOOST_POLYGON_MEDIAL_AXIS

#include <vector>
#include <utility>
#include <cstdio>
#include <string>
#include <math.h>

#include "boost/lexical_cast.hpp"
#include "boost/polygon/detail/voronoi_ctypes.hpp"
#include "boost/polygon/detail/voronoi_structures.hpp"

#include "boost/polygon/voronoi_geometry_type.hpp"

#define to_str(n) boost::lexical_cast<std::string>( n )

namespace boost {
namespace polygon {

// Forward declarations.
template <typename T>
class medial_axis_edge;
 
// Represents Voronoi cell.
// Data members:
//   1) index of the source within the initial input set
//   2) pointer to the incident edge
//   3) mutable color member
// Cell may contain point or segment site inside.
template <typename T>
class medial_axis_cell {
 public:
  typedef T coordinate_type;
  typedef std::size_t color_type;
  typedef medial_axis_edge<coordinate_type> medial_axis_edge_type;
  typedef std::size_t source_index_type;
  typedef SourceCategory source_category_type;

  medial_axis_cell(source_index_type source_index,
               source_category_type source_category) :
      source_index_(source_index),
      incident_edge_(NULL),
      color_(source_category) {}

  // Returns true if the cell contains point site, false else.
  bool contains_point() const {
    source_category_type source_category = this->source_category();
    return belongs(source_category, GEOMETRY_CATEGORY_POINT);
  }

  // Returns true if the cell contains segment site, false else.
  bool contains_segment() const {
    source_category_type source_category = this->source_category();
    return belongs(source_category, GEOMETRY_CATEGORY_SEGMENT);
  }

  source_index_type source_index() const {
    return source_index_;
  }

  source_category_type source_category() const {
    return static_cast<source_category_type>(color_ & SOURCE_CATEGORY_BITMASK);
  }

  // Degenerate cells don't have any incident edges.
  bool is_degenerate() const { return incident_edge_ == NULL; }

  medial_axis_edge_type* incident_edge() { return incident_edge_; }
  const medial_axis_edge_type* incident_edge() const { return incident_edge_; }
  void incident_edge(medial_axis_edge_type* e) { incident_edge_ = e; }

  color_type color() const { return color_ >> BITS_SHIFT; }
  void color(color_type color) const {
    color_ &= BITS_MASK;
    color_ |= color << BITS_SHIFT;
  }

 private:
  // 5 color bits are reserved.
  enum Bits {
    BITS_SHIFT = 0x5,
    BITS_MASK = 0x1F
  };

  source_index_type source_index_;
  medial_axis_edge_type* incident_edge_;
  mutable color_type color_;
};

// Represents Voronoi vertex.
// Data members:
//   1) vertex coordinates
//   2) radius of a maximal inscribed circle to the polygon at the vertex
//   3) pointer to the incident edge
//   4) mutable color member
template <typename T>
class medial_axis_vertex {
 public:
  typedef T coordinate_type;
  typedef std::size_t color_type;
  typedef medial_axis_edge<coordinate_type> medial_axis_edge_type;

  medial_axis_vertex(const coordinate_type& x, const coordinate_type& y,
                     const coordinate_type& r=0) :
      x_(x),
      y_(y),
      r_(r),
      incident_edge_(NULL),
      color_(0) {}

  const coordinate_type& x() const { return x_; }
  const coordinate_type& y() const { return y_; }
  const coordinate_type& r() const { return r_; }

  bool is_degenerate() const { return incident_edge_ == NULL; }

  medial_axis_edge_type* incident_edge() { return incident_edge_; }
  const medial_axis_edge_type* incident_edge() const { return incident_edge_; }
  void incident_edge(medial_axis_edge_type* e) { incident_edge_ = e; }

  color_type color() const { return color_ >> BITS_SHIFT; }
  void color(color_type color) const {
    color_ &= BITS_MASK;
    color_ |= color << BITS_SHIFT;
  }

 private:
  // 5 color bits are reserved.
  enum Bits {
    BITS_SHIFT = 0x5,
    BITS_MASK = 0x1F
  };

  coordinate_type x_;
  coordinate_type y_;
  coordinate_type r_;
  medial_axis_edge_type* incident_edge_;
  mutable color_type color_;
};

// Half-edge data structure. Represents Voronoi edge.
// Data members:
//   1) pointer to the corresponding cell
//   2) pointer to the vertex that is the starting
//      point of the half-edge
//   3) pointer to the twin edge
//   4) pointer to the CCW next edge
//   5) pointer to the CCW prev edge
//   6) boolean indicating whether foot coordinates have been set
//   7) mutable color member
template <typename T>
class medial_axis_edge {
 public:
  typedef T coordinate_type;
  typedef medial_axis_cell<coordinate_type> medial_axis_cell_type;
  typedef medial_axis_vertex<coordinate_type> medial_axis_vertex_type;
  typedef medial_axis_edge<coordinate_type> medial_axis_edge_type;
  typedef std::size_t color_type;

  medial_axis_edge(bool is_linear, bool is_primary) :
      cell_(NULL),
      vertex_(NULL),
      twin_(NULL),
      next_(NULL),
      prev_(NULL),
      footset_(false),
      color_(0) {
    if (is_linear)
      color_ |= BIT_IS_LINEAR;
    if (is_primary)
      color_ |= BIT_IS_PRIMARY;
  }

  medial_axis_cell_type* cell() { return cell_; }
  const medial_axis_cell_type* cell() const { return cell_; }
  void cell(medial_axis_cell_type* c) { cell_ = c; }

  medial_axis_vertex_type* vertex0() { return vertex_; }
  const medial_axis_vertex_type* vertex0() const { return vertex_; }
  void vertex0(medial_axis_vertex_type* v) { vertex_ = v; }

  medial_axis_vertex_type* vertex1() { return twin_->vertex0(); }
  const medial_axis_vertex_type* vertex1() const { return twin_->vertex0(); }

  medial_axis_edge_type* twin() { return twin_; }
  const medial_axis_edge_type* twin() const { return twin_; }
  void twin(medial_axis_edge_type* e) { twin_ = e; }

  medial_axis_edge_type* next() { return next_; }
  const medial_axis_edge_type* next() const { return next_; }
  void next(medial_axis_edge_type* e) { next_ = e; }

  medial_axis_edge_type* prev() { return prev_; }
  const medial_axis_edge_type* prev() const { return prev_; }
  void prev(medial_axis_edge_type* e) { prev_ = e; }

  // Returns a pointer to the rotation next edge
  // over the starting point of the half-edge.
  medial_axis_edge_type* rot_next() { return prev_->twin(); }
  const medial_axis_edge_type* rot_next() const { return prev_->twin(); }

  // Returns a pointer to the rotation prev edge
  // over the starting point of the half-edge.
  medial_axis_edge_type* rot_prev() { return twin_->next(); }
  const medial_axis_edge_type* rot_prev() const { return twin_->next(); }

  // Returns true if the edge is finite (segment, parabolic arc).
  // Returns false if the edge is infinite (ray, line).
  bool is_finite() const { return vertex0() && vertex1(); }

  // Returns true if the edge is infinite (ray, line).
  // Returns false if the edge is finite (segment, parabolic arc).
  bool is_infinite() const { return !vertex0() || !vertex1(); }

  // Returns true if the edge is linear (segment, ray, line).
  // Returns false if the edge is curved (parabolic arc).
  bool is_linear() const {
    return (color_ & BIT_IS_LINEAR) ? true : false;
  }

  // Returns true if the edge is curved (parabolic arc).
  // Returns false if the edge is linear (segment, ray, line).
  bool is_curved() const {
    return (color_ & BIT_IS_LINEAR) ? false : true;
  }

  // Returns false if edge goes through the endpoint of the segment.
  // Returns true else.
  bool is_primary() const {
    return (color_ & BIT_IS_PRIMARY) ? true : false;
  }

  // Returns true if edge goes through the endpoint of the segment.
  // Returns false else.
  bool is_secondary() const {
    return (color_ & BIT_IS_PRIMARY) ? false : true;
  }

  color_type color() const { return color_ >> BITS_SHIFT; }
  void color(color_type color) const {
    color_ &= BITS_MASK;
    color_ |= color << BITS_SHIFT;
  }
  
  // foot: where radius from vertex0 touches source segment at a 90 degree angle
  const detail::point_2d<default_voronoi_builder::int_type>* foot() const { 
    if (!footset_) {return NULL;}
    return &foot_;
  }
  void foot(coordinate_type x, coordinate_type y) {
    footset_ = true;
    foot_.x(x);
    foot_.y(y);
  }

 private:
  // 5 color bits are reserved.
  enum Bits {
    BIT_IS_LINEAR = 0x1,  // linear is opposite to curved
    BIT_IS_PRIMARY = 0x2,  // primary is opposite to secondary

    BITS_SHIFT = 0x5,
    BITS_MASK = 0x1F
  };

  medial_axis_cell_type* cell_;
  medial_axis_vertex_type* vertex_;
  medial_axis_edge_type* twin_;
  medial_axis_edge_type* next_;
  medial_axis_edge_type* prev_;
  mutable color_type color_;
  mutable detail::point_2d<default_voronoi_builder::int_type> foot_;
  bool footset_;
  mutable detail::point_2d<default_voronoi_builder::int_type> p1_;

};

template <typename T>
struct medial_axis_traits {
  typedef T coordinate_type;
  typedef medial_axis_cell<coordinate_type> cell_type;
  typedef medial_axis_vertex<coordinate_type> vertex_type;
  typedef medial_axis_edge<coordinate_type> edge_type;
  typedef class {
   public:
    enum { ULPS = 128 };
    bool operator()(const vertex_type& v1, const vertex_type& v2) const {
      return (ulp_cmp(v1.x(), v2.x(), ULPS) ==
              detail::ulp_comparison<T>::EQUAL) &&
             (ulp_cmp(v1.y(), v2.y(), ULPS) ==
              detail::ulp_comparison<T>::EQUAL);
    }
   private:
    typename detail::ulp_comparison<T> ulp_cmp;
  } vertex_equality_predicate_type;
};

// Voronoi output data structure.
// CCW ordering is used on the faces perimeter and around the vertices.
template <typename T, typename TRAITS = medial_axis_traits<T> >
class medial_axis {
 public:
  typedef typename TRAITS::coordinate_type coordinate_type;
  typedef typename TRAITS::cell_type cell_type;
  typedef typename TRAITS::vertex_type vertex_type;
  typedef typename TRAITS::edge_type edge_type;

  typedef std::vector<cell_type> cell_container_type;
  typedef typename cell_container_type::const_iterator const_cell_iterator;

  typedef std::vector<vertex_type> vertex_container_type;
  typedef typename vertex_container_type::const_iterator const_vertex_iterator;

  typedef std::vector<edge_type> edge_container_type;
  typedef typename edge_container_type::const_iterator const_edge_iterator;

  medial_axis() {}

  void clear() {
    cells_.clear();
    vertices_.clear();
    edges_.clear();
  }

  const cell_container_type& cells() const {
    return cells_;
  }

  const vertex_container_type& vertices() const {
    return vertices_;
  }

  const edge_container_type& edges() const {
    return edges_;
  }

  const std::string& event_log() const {
    return event_log_;
  }

  std::size_t num_cells() const {
    return cells_.size();
  }

  std::size_t num_edges() const {
    return edges_.size();
  }

  std::size_t num_vertices() const {
    return vertices_.size();
  }

  void _reserve(int num_sites) {
    cells_.reserve(num_sites);
    vertices_.reserve(num_sites << 1);
    edges_.reserve((num_sites << 2) + (num_sites << 1));
  }

  template <typename CT>
  void _process_single_site(const detail::site_event<CT>& site) {
    cells_.push_back(cell_type(site.initial_index(), site.source_category()));
  }

  // Insert a new half-edge into the output data structure.
  // Takes as input left and right sites that form a new bisector.
  // Returns a pair of pointers to a new half-edges.
  template <typename CT>
  std::pair<void*, void*> _insert_new_edge(
      const detail::site_event<CT>& site1,
      const detail::site_event<CT>& site2) {
    //printf("site event\n");
    // Get sites' indexes.
    int site_index1 = site1.sorted_index();
    int site_index2 = site2.sorted_index();

    bool is_linear = is_linear_edge(site1, site2);
    bool is_primary = is_primary_edge(site1, site2);

    // Create a new half-edge that belongs to the first site.
    edges_.push_back(edge_type(is_linear, is_primary));
    edge_type& edge1 = edges_.back();
 
    // Create a new half-edge that belongs to the second site.
    edges_.push_back(edge_type(is_linear, is_primary));
    edge_type& edge2 = edges_.back();

    // Add the initial cell during the first edge insertion.
    if (cells_.empty()) {
      cells_.push_back(cell_type(
          site1.initial_index(), site1.source_category()));
    }

    // The second site represents a new site during site event
    // processing. Add a new cell to the cell records.
    cells_.push_back(cell_type(
        site2.initial_index(), site2.source_category()));

    // Set up pointers to cells.
    edge1.cell(&cells_[site_index1]);
    edge2.cell(&cells_[site_index2]);

    // Set up twin pointers.
    edge1.twin(&edge2);
    edge2.twin(&edge1);
    
// if the edge is curved we can display a parabola between the point and
// segment that define it, and we know the start and end feet for the 
// half edge on the point side - just the point. We might be able to 
// figure the feet on the segment too, but not sure.

// if the edge is straight, feet at start and end are probably just
// site vertices - but which? first or second? and what about seeing
// a vertex multiple times for the three events from a segment?
// Maybe only figure foot when the segment event happens. What about the
// inverted segment? maybe only deal with foot when handling the segment the
// second time around.

    event_log_ += "<g id=\"sites"+to_str((UV) &site1)+"_"+to_str((UV) &site2)+"\" ";
    event_log_ += " class=\"ine1"+to_str(is_linear?"linear":"curved")+to_str(is_primary?"primary":"secondary")+"\">\n";

    bool showfeet = false;

    if (false) {
    if (belongs(site1.source_category(), GEOMETRY_CATEGORY_POINT)) {
      event_log_ += "<circle id=\"site" + to_str((UV) &site1) + "\" ";
      event_log_ += "cx=\""+to_str(site1.point0().x())+"\" cy=\""+to_str(site1.point0().y())+"\" r=\"8000\" class=\"es1p\"/>\n";
    } else if (belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
      event_log_ += "<line id=\"site" + to_str((UV) &site1) + "\" ";
      event_log_ += " x1=\""+to_str(site1.point0().x())+"\" y1=\""+to_str(site1.point0().y())+"\"";
      event_log_ += " x2=\""+to_str(site1.point1().x())+"\" y2=\""+to_str(site1.point1().y())+"\"/>\n";
    } else {
      event_log_ += "<!-- no site 1 -->\n";
    }
    if (belongs(site2.source_category(), GEOMETRY_CATEGORY_POINT)) {
      event_log_ += "<circle id=\"site" + to_str((UV) &site2) + "\" ";
      event_log_ += "cx=\""+to_str(site2.point0().x())+"\" cy=\""+to_str(site2.point0().y())+"\" r=\"8000\" class=\"es2p\"/>\n";
    } else if (belongs(site2.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
      event_log_ += "<line id=\"site" + to_str((UV) &site2) + "\" ";
      event_log_ += " x1=\""+to_str(site2.point0().x())+"\" y1=\""+to_str(site2.point0().y())+"\"";
      event_log_ += " x2=\""+to_str(site2.point1().x())+"\" y2=\""+to_str(site2.point1().y())+"\"/>\n";
    } else {
      event_log_ += "<!-- no site 2 -->\n";
    }
    if (!is_linear) {
      event_log_ += "<!-- curved -->\n";
    } else {
      event_log_ += "<!-- linear -->\n";
    }
    }
    
    //set foot
    // this needs work - see note for "set foot" below in the 
    // _insert_new_edge() function for circle events
    
    // Though the foot determined here for curved edges is likely correct
    // it's also likely it's getting reset later when a vertex is available.
    
    if (!is_linear
        //belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)
        //|| belongs(site2.source_category(), GEOMETRY_CATEGORY_SEGMENT)
       ) {
      if (edge1.cell()->contains_point() 
          //&& edge2.cell()->contains_segment()
         ) {
        // belongs(site1.source_category(), GEOMETRY_CATEGORY_POINT)
        // && belongs(site2.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
        edge1.foot(site1.point0().x(), site1.point0().y());
        //printf("ine1 foot 1\n");
        if (showfeet) {
        event_log_ += "<circle id=\"foot" + to_str((UV) &site1) + "_f\" ";
        event_log_ += "cx=\""+to_str(site1.point0().x())+"\" cy=\""+to_str(site1.point0().y())+"\" r=\"5000\" class=\"ine1f\"/>\n";
        }
      }
      if (edge2.cell()->contains_point() 
          //&& edge1.cell()->contains_segment()
         ) {
        // belongs(site2.source_category(), GEOMETRY_CATEGORY_POINT)
        // && belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
        edge2.foot(site2.point0().x(), site2.point0().y());
        //printf("ine1 foot 2\n");
        if (showfeet) {
        event_log_ += "<circle id=\"foot" + to_str((UV) &site2) + "_f\" ";
        event_log_ += "cx=\""+to_str(site2.point0().x())+"\" cy=\""+to_str(site2.point0().y())+"\" r=\"5000\" class=\"ine1f\"/>\n";
        }
      }

    }
    
    event_log_ += "</g>\n";

    // Return a pointer to the new half-edge.
    return std::make_pair(&edge1, &edge2);
  }

  // Insert a new half-edge into the output data structure with the
  // start at the point where two previously added half-edges intersect.
  // Takes as input two sites that create a new bisector, circle event
  // that corresponds to the intersection point of the two old half-edges,
  // pointers to those half-edges. Half-edges' direction goes out of the
  // new Voronoi vertex point. Returns a pair of pointers to a new half-edges.
  template <typename CT1, typename CT2>
  std::pair<void*, void*> _insert_new_edge(
      const detail::site_event<CT1>& site1,
      const detail::site_event<CT1>& site3,
      const detail::circle_event<CT2>& circle,
      void* data12, void* data23) {
    edge_type* edge12 = static_cast<edge_type*>(data12);
    edge_type* edge23 = static_cast<edge_type*>(data23);
    //printf("circle event\n");

    // Add a new Voronoi vertex.
    vertices_.push_back(vertex_type(circle.x(), circle.y(), 
                                    circle.lower_x() - circle.x()));
    vertex_type& new_vertex = vertices_.back();

    event_log_ += "<g id=\"sites"+to_str((UV) &site1)+"_"+to_str((UV) &site3)+"\" ";
    event_log_ += " class=\"ine2"+to_str(is_linear_edge(site1, site3)?"linear":"curved")+to_str(is_primary_edge(site1, site3)?"primary":"secondary")+"\">\n";
    
    if (false) {
    event_log_ += "<!-- edge12 is "+to_str(edge12->is_curved()?"curved":"linear")+" "+to_str(edge12->is_primary()?"primary":"secondary")+" -->\n";
    event_log_ += "<!-- edge23 is "+to_str(edge23->is_curved()?"curved":"linear")+" "+to_str(edge23->is_primary()?"primary":"secondary")+" -->\n";
    event_log_ += "<circle id=\"sites" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"_pt\" ";
    event_log_ += "cx=\""+to_str(new_vertex.x())+"\" cy=\""+to_str(new_vertex.y())+"\" r=\"8000\" class=\"cirevtpt\"/>\n";
    event_log_ += "<circle id=\"sites" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"_cir\" ";
    event_log_ += "cx=\""+to_str(new_vertex.x())+"\" cy=\""+to_str(new_vertex.y())+"\" r=\""+to_str(new_vertex.r())+"\" class=\"cirevtcir\"/>\n";
    }
    
    //printf("whatverts? %d %d %d %d\n",(edge12->vertex0()?1:0),(edge12->vertex1()?1:0),(edge23->vertex0()?1:0),(edge23->vertex1()?1:0));

    // Update vertex pointers of the old edges.
    edge12->vertex0(&new_vertex);
    edge23->vertex0(&new_vertex);
    
// It appears that the "old" edges never have vertex0 set before the above.
// But often one or both of them already have vertex1 set.

if (false) {
    if (edge12->vertex0() && edge12->vertex1()) {
      event_log_ += "<line id=\"e12_" + to_str((UV) &site1) + "_" + to_str((UV) &site3) + "\" class=\"edge12\" ";
      event_log_ += " x1=\""+to_str(edge12->vertex0()->x())+"\" y1=\""+to_str(edge12->vertex0()->y())+"\"";
      event_log_ += " x2=\""+to_str(edge12->vertex1()->x())+"\" y2=\""+to_str(edge12->vertex1()->y())+"\"/>\n";
      event_log_ += "<!-- "+to_str(edge12->is_curved()?"curved":"linear")+" -->\n";
      //printf( "WE ARE HERE1\n");
    }
    if (edge23->vertex0() && edge23->vertex1()) {
      event_log_ += "<line id=\"e12_" + to_str((UV) &site1) + "_" + to_str((UV) &site3) + "\" class=\"edge23\" ";
      event_log_ += " x1=\""+to_str(edge23->vertex0()->x())+"\" y1=\""+to_str(edge23->vertex0()->y())+"\"";
      event_log_ += " x2=\""+to_str(edge23->vertex1()->x())+"\" y2=\""+to_str(edge23->vertex1()->y())+"\"/>\n";
      event_log_ += "<!-- "+to_str(edge23->is_curved()?"curved":"linear")+" -->\n";
      //printf( "WE ARE HERE2\n");
    }
    if (belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
      event_log_ += "<line id=\"siteseg1_" + to_str((UV) &site1) + "_" + to_str((UV) &site3) + "\" class=\"siteseg1\" ";
      event_log_ += " x1=\""+to_str(site1.point0().x())+"\" y1=\""+to_str(site1.point0().y())+"\"";
      event_log_ += " x2=\""+to_str(site1.point1().x())+"\" y2=\""+to_str(site1.point1().y())+"\"/>\n";
    } else if (belongs(site1.source_category(), GEOMETRY_CATEGORY_POINT)) {
      event_log_ += "<circle id=\"sitepoint1_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(site1.point0().x())+"\" cy=\""+to_str(site1.point0().y())+"\" r=\"40000\" class=\"sitept1\"/>\n";
    }
    if (belongs(site3.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
      event_log_ += "<line id=\"siteseg3_" + to_str((UV) &site1) + "_" + to_str((UV) &site3) + "\" class=\"siteseg3\" ";
      event_log_ += " x1=\""+to_str(site3.point0().x())+"\" y1=\""+to_str(site3.point0().y())+"\"";
      event_log_ += " x2=\""+to_str(site3.point1().x())+"\" y2=\""+to_str(site3.point1().y())+"\"/>\n";
    } else if (belongs(site3.source_category(), GEOMETRY_CATEGORY_POINT)) {
      event_log_ += "<circle id=\"sitepoint3_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(site3.point0().x())+"\" cy=\""+to_str(site3.point0().y())+"\" r=\"40000\" class=\"sitept3\"/>\n";
    }
}
    bool is_linear = is_linear_edge(site1, site3);
    bool is_primary = is_primary_edge(site1, site3);

    // Add a new half-edge.
    edges_.push_back(edge_type(is_linear, is_primary));
    edge_type& new_edge1 = edges_.back();
    new_edge1.cell(&cells_[site1.sorted_index()]);

    // Add a new half-edge.
    edges_.push_back(edge_type(is_linear, is_primary));
    edge_type& new_edge2 = edges_.back();
    new_edge2.cell(&cells_[site3.sorted_index()]);

    // Update twin pointers.
    new_edge1.twin(&new_edge2);
    new_edge2.twin(&new_edge1);

    // Update vertex pointer.
    new_edge2.vertex0(&new_vertex);

    // Update Voronoi prev/next pointers.
    edge12->prev(&new_edge1);
    new_edge1.next(edge12);
    edge12->twin()->next(edge23);
    edge23->prev(edge12->twin());
    edge23->twin()->next(&new_edge2);
    new_edge2.prev(edge23->twin());

    //set foot
    // It's possible that we can do all foot-finding in this event processing
    // (here in the circle event, and in the other site even code above).
    // But we haven't completely understood or diagramed exactly what edges and 
    // vertices are available during these events. With a rough mental sketch
    // of whats going on, we've been able to quickly work up this code to 
    // calculate enough feet, and infer others later, to handle most cases, and
    // demonstrate that this medial axis refinement of the Voronoi diagram
    // should work.
    // 
    // What's needed next is to properly analyze-diagram-understand what's
    // happening during site/circle events, so the code here can be extended
    // a bit to really cover all cases of calculating the foot, or as many
    // cases as possible.
    

    bool showfeet = false;


    // for edges going into corners

    // edge12 into corner

    // note the cast from float to int for these ==s : LHS is an int type, RHS is float
    // nope: that didn't fix it, and that's what we want to avoid anyway
    if (edge12->vertex1()
        //&& (  (site1.point1().x() == (coordinate_type) edge12->vertex1()->x() && site1.point1().y() == (coordinate_type) edge12->vertex1()->y())
        //   || (site1.point0().x() == (coordinate_type) edge12->vertex1()->x() && site1.point0().y() == (coordinate_type) edge12->vertex1()->y())
        //   )
// If this really works, do same/similar for next if for edge23
// ... catches more cases than the target case, putting some feet not on polygon segments
//     but see if something similarly topological can do the job here
        && edge12->is_primary() 
        && edge12->next() && !edge12->next()->is_primary()
        && (  edge12->next()->cell()->contains_point()
           || edge12->next()->twin()->cell()->contains_point()
           )
        && belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)
       ) {
      
      double x0 = site1.point0().x();
      double y0 = site1.point0().y();
      double x1 = site1.point1().x();
      double y1 = site1.point1().y();
      double x = new_vertex.x();
      double y = new_vertex.y();
      makefoot(x, y, x0, y0, x1, y1);
      edge12->foot(x, y);
      if (showfeet) {
      event_log_ += "<circle id=\"footcornert_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"220000\" class=\"evtfootc\"/>\n";
      }

      // and probably:
      //edge12->twin()->foot(edge12->vertex1()->x(), edge12->vertex1()->y());

      //event_log_ += "<circle id=\"footcorner_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      //event_log_ += "cx=\""+to_str(edge12->vertex1()->x())+"\" cy=\""+to_str(edge12->vertex1()->y())+"\" r=\"50000\" class=\"evtfootc\"/>\n";


      // and probably too:

      // this had bad effect in one place in t/test, similar to case below for edge23
      //reflect(x, y, edge12->vertex0()->x(), edge12->vertex0()->y(),
      //              edge12->vertex1()->x(), edge12->vertex1()->y());
      //edge23->foot(x, y);
      if (showfeet) {
      //event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      //event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"220000\" class=\"evtfootc\"/>\n";
      }
      //printf("pre3_1\n");
      //printf("AH 1\n");
    }

    // edge23 into corner
    if (edge23->vertex1()
        //&& 
        //(  (edge23->vertex1()->x() == site3.point1().x() && edge23->vertex1()->y() == site3.point1().y())
        //|| (edge23->vertex1()->x() == site3.point0().x() && edge23->vertex1()->y() == site3.point0().y())
        //)
        //&& edge23->is_primary() && edge23->next() && !edge23->next()->is_primary()

        && edge23->is_primary() 
        && edge23->next() && !edge23->next()->is_primary()
        && (
           edge23->next()->cell()->contains_point()
           || 
           edge23->next()->twin()->cell()->contains_point()
           )


       && belongs(site3.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
      
      // this one for edge12 made extraneous feet
      // so commenting out here too - but without demonstrating it's wrong here too
      //edge23->twin()->foot(edge23->vertex1()->x(), edge23->vertex1()->y());
      //event_log_ += "<circle id=\"footcorneraa_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      //event_log_ += "cx=\""+to_str(edge23->vertex1()->x())+"\" cy=\""+to_str(edge23->vertex1()->y())+"\" r=\"110000\" class=\"evtfootc\"/>\n";
      
      // and :
      double x0 = site3.point0().x();
      double y0 = site3.point0().y();
      double x1 = site3.point1().x();
      double y1 = site3.point1().y();
      double x = new_vertex.x();
      double y = new_vertex.y();
      makefoot(x, y, x0, y0, x1, y1);
      new_edge2.foot(x, y);
      
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerbb_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfootc\"/>\n";
      }
      // this had bad effect in couple places in t/test
      //reflect(x, y, edge23->vertex0()->x(), edge23->vertex0()->y(),
      //              edge23->vertex1()->x(), edge23->vertex1()->y());
      //edge23->foot(x, y);
      
      if (showfeet) {
      //event_log_ += "<circle id=\"footcornercc_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      //event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfootc\"/>\n";
      }

      //printf("AH 3\n");      
    }

    // maybe
    if (edge12->is_primary()
        && edge12->vertex1()
        && belongs(site1.source_category(), GEOMETRY_CATEGORY_POINT)
        && (edge12->vertex1()->x() == site1.point0().x() && edge12->vertex1()->y() == site1.point0().y())
        ) {
      edge12->twin()->foot(edge12->vertex1()->x(), edge12->vertex1()->y());
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(edge12->vertex1()->x())+"\" cy=\""+to_str(edge12->vertex1()->y())+"\" r=\"110000\" class=\"evtfootc\"/>\n";
      }
    }
    // maybe
    if (edge23->is_primary()
        && edge23->vertex1()
        && belongs(site3.source_category(), GEOMETRY_CATEGORY_POINT)
        && (edge23->vertex1()->x() == site3.point0().x() && edge23->vertex1()->y() == site3.point0().y())
        ) {
      edge23->twin()->foot(edge23->vertex1()->x(), edge23->vertex1()->y());
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(edge23->vertex1()->x())+"\" cy=\""+to_str(edge23->vertex1()->y())+"\" r=\"110000\" class=\"evtfootc\"/>\n";
      }
    }

    // special case derived from visual debug
    if (   belongs(site1.source_category(), GEOMETRY_CATEGORY_POINT)
        && belongs(site3.source_category(), GEOMETRY_CATEGORY_SEGMENT)
       ) {
      if (
         (    (site3.point0().x() == site1.point0().x() && site3.point0().y() == site1.point0().y())
           || (site3.point1().x() == site1.point0().x() && site3.point1().y() == site1.point0().y())
         )
         && edge23->is_primary()
         && (edge23->vertex0()->x() == site1.point0().x() && edge23->vertex0()->y() == site1.point0().y())
         ) {
        
        // visually, looked like this was already there
        // but maybe that was wrongly associated with another edge?
        // so set/reset to see...
        // yeah this wasn't set, even though there appeared to be a foot there
        // so that was probably a wrong foot from something else
        // and this is maybe right
        edge23->foot(site1.point0().x(), site1.point0().y());


        double x0 = site3.point0().x();
        double y0 = site3.point0().y();
        double x1 = site3.point1().x();
        double y1 = site3.point1().y();
        double x = edge23->vertex1()->x();
        double y = edge23->vertex1()->y();
        makefoot(x, y, x0, y0, x1, y1);
        edge23->twin()->foot(x, y);
        if (showfeet) {
        event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfootc\"/>\n";
        }
        reflect(x, y, edge23->vertex0()->x(), edge23->vertex0()->y(),
                      edge23->vertex1()->x(), edge23->vertex1()->y());
        edge23->next()->foot(x, y);
        if (showfeet) {
        event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfootc\"/>\n";
        }
        //printf("\nMAYBEMAYBE 1\n");
      }
    }
    // similar special case derived from above, but maybe doesn't happen?
    if (   belongs(site3.source_category(), GEOMETRY_CATEGORY_POINT)
        && belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)
       ) {
      if (
         (site1.point0().x() == site3.point0().x() && site1.point0().y() == site3.point0().y())
         ||
         (site1.point1().x() == site3.point0().x() && site1.point1().y() == site3.point0().y())
         ) {
        //printf("\nMAYBEMAYBE 2\n");
      }
    }


    // for straight edges
    if (edge23->vertex1() && !edge23->twin()->foot() 
        && edge23->is_linear() 
        //&& edge23->twin()->is_primary() 
        && belongs(site3.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
      double x0 = site3.point0().x();
      double y0 = site3.point0().y();
      double x1 = site3.point1().x();
      double y1 = site3.point1().y();
      double x = edge23->vertex1()->x();
      double y = edge23->vertex1()->y();
      makefoot(x, y, x0, y0, x1, y1);
      edge23->twin()->foot(x, y);
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfootc\"/>\n";
      }
    }

    

    if (edge23->vertex1() && !new_edge2.foot() 
        && new_edge2.is_linear() 
        //&& new_edge2.is_primary() 
        && belongs(site3.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
      double x0 = site3.point0().x();
      double y0 = site3.point0().y();
      double x1 = site3.point1().x();
      double y1 = site3.point1().y();
      double x = new_vertex.x();
      double y = new_vertex.y();
      makefoot(x, y, x0, y0, x1, y1);
      new_edge2.foot(x, y);
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfootc\"/>\n";
      }
    }

    if (!edge12->foot() 
        && edge12->is_linear() 
        //&& edge12->is_primary() 
        && belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)
        && edge12->vertex1()
        ) {
      double x0 = site1.point0().x();
      double y0 = site1.point0().y();
      double x1 = site1.point1().x();
      double y1 = site1.point1().y();
      double x = new_vertex.x();
      double y = new_vertex.y();
      makefoot(x, y, x0, y0, x1, y1);
      edge12->foot(x, y);
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"330000\" class=\"evtfootc\"/>\n";
      }
      if (new_vertex.r() == 0 && edge12->vertex1()) {
        edge12->twin()->foot(edge12->vertex1()->x(), edge12->vertex1()->y());
        if (showfeet) {
        event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(edge12->vertex1()->x())+"\" cy=\""+to_str(edge12->vertex1()->y())+"\" r=\"220000\" class=\"evtfootc\"/>\n";
        }
      }
    }

    // didn't see change with this
    // might be redundant - or not right
    // thinking not right, though it is picking up a case that the first
    // foot finding conditional should get
    // ... yeah doesn't seem right
    if (false
        && edge12->vertex1()
        && !edge12->next()->foot() 
        && edge12->is_linear() 
        //&& edge12->is_primary() 
        && belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
      double x0 = site1.point0().x();
      double y0 = site1.point0().y();
      double x1 = site1.point1().x();
      double y1 = site1.point1().y();
      double x = edge12->vertex1()->x();
      double y = edge12->vertex1()->y();
      makefoot(x, y, x0, y0, x1, y1);
      edge12->next()->foot(x, y);
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"220000\" class=\"evtfootc\"/>\n";
      }
    }
    
    // trying to fill in corner feet
    // seems to work without creating feet where they don't belong
    if (!edge12->is_primary()
        &&  edge12->vertex1()
        && !edge12->twin()->prev()->is_primary()
        &&  edge12->next()->is_primary()
        && !edge12->next()->foot()
       ) {
      edge12->next()->foot(edge12->vertex1()->x(), edge12->vertex1()->y());
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(edge12->vertex1()->x())+"\" cy=\""+to_str(edge12->vertex1()->y())+"\" r=\"30000\" class=\"evtfootc\"/>\n";
      }
    }
    if (   !edge23->is_primary()
        &&  edge23->vertex1()
        && !edge23->twin()->prev()->is_primary()
        &&  edge23->next()->is_primary()
        && !edge23->next()->foot()
       ) {
      edge23->next()->foot(edge23->vertex1()->x(), edge23->vertex1()->y());
      if (showfeet) {
      event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(edge23->vertex1()->x())+"\" cy=\""+to_str(edge23->vertex1()->y())+"\" r=\"40000\" class=\"evtfootc\"/>\n";
      }
    }

    
    // another based on special case, that hopefully has general utility
    // this worked for that one special case
    if (  !edge23->foot()
        && edge23->vertex1()
        && edge23->is_linear()
        && edge23->twin()->next()->foot()
       ) {
        double x = edge23->twin()->next()->foot()->x();
        double y = edge23->twin()->next()->foot()->y();
        reflect(x, y, edge23->vertex0()->x(), edge23->vertex0()->y(),
                      edge23->vertex1()->x(), edge23->vertex1()->y());
        edge23->foot(x, y);
        if (showfeet) {
        event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"40000\" class=\"evtfootc\"/>\n";
        }
    }
    // same as above but for edge12 - no test case to demonstrate it yet though
    if (  !edge12->foot()
        && edge12->vertex1()
        && edge12->is_linear()
        && edge12->twin()->next()->foot()
       ) {
        double x = edge12->twin()->next()->foot()->x();
        double y = edge12->twin()->next()->foot()->y();
        reflect(x, y, edge12->vertex0()->x(), edge12->vertex0()->y(),
                      edge12->vertex1()->x(), edge12->vertex1()->y());
        edge12->foot(x, y);
        if (showfeet) {
        event_log_ += "<circle id=\"footcornerm_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"40000\" class=\"evtfootc\"/>\n";
        }
    }

    // another special case
    // got it - that was last of first round of many missing feet
    if (   !edge23->foot()
        && !edge12->is_primary()
        //&& !edge23->is_curved()
        &&  edge23->is_primary()
        &&  edge12->vertex1()
       ) {
      edge23->foot(edge12->vertex1()->x(), edge12->vertex1()->y());
    }
    // might need similar but not same as above for similar edge12 case
    // if that's possible, but should demonstrate or illustrate need for that


    // curved edges
    
    // on t/test this might not have significant effect with or without
    // ... this fixes missing feet on full hex grid test
    if (
        //!edge12->foot() && 
        edge12->is_curved()) {
      if (belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
        double x0 = site1.point0().x();
        double y0 = site1.point0().y();
        double x1 = site1.point1().x();
        double y1 = site1.point1().y();
        double x = new_vertex.x();
        double y = new_vertex.y();
        makefoot(x, y, x0, y0, x1, y1);
        edge12->foot(x, y);
        //printf("pre3_1\n");
        if (showfeet) {
        event_log_ += "<circle id=\"footpre3_1_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }
      } else if (belongs(site1.source_category(), GEOMETRY_CATEGORY_POINT)) {
        edge12->foot(site1.point0().x(), site1.point0().y());
        //printf("pre3_2\n");
        if (showfeet) {
        event_log_ += "<circle id=\"footpre3_2_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(site1.point0().x())+"\" cy=\""+to_str(site1.point0().y())+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }
      }
    }

    // on t/test this is not good
    if (false && 
        //!edge23->twin()->foot() && 
        edge23->is_curved()) {
      if (belongs(site3.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
        double x0 = site3.point0().x();
        double y0 = site3.point0().y();
        double x1 = site3.point1().x();
        double y1 = site3.point1().y();
        double x = new_vertex.x();
        double y = new_vertex.y();
        makefoot(x, y, x0, y0, x1, y1);
        //edge23->foot(x, y);
        edge23->twin()->foot(x, y);
        //printf("NEWpre3_1\n");
        if (showfeet) {
        event_log_ += "<circle id=\"footNEWpre3_1_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }
      }
      if (belongs(site3.source_category(), GEOMETRY_CATEGORY_POINT)) {
        //edge12->foot(site3.point0().x(), site3.point0().y());
        edge23->twin()->foot(site3.point0().x(), site3.point0().y());
        //printf("NEWpre3_2\n");
        if (showfeet) {
        event_log_ += "<circle id=\"footNEWpre3_2_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(site3.point0().x())+"\" cy=\""+to_str(site3.point0().y())+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }
      }
    }
    
    if (edge12->twin()->foot() && edge12->twin()->cell()->contains_point()
        && !edge23->foot()) {
        edge23->foot(edge12->twin()->foot()->x(), edge12->twin()->foot()->y());
        //printf("around point\n");
        if (showfeet) {
        event_log_ += "<circle id=\"footNEWpre3_2_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(edge12->twin()->foot()->x())+"\" cy=\""+to_str(edge12->twin()->foot()->y())+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }
    }

    if (edge23->foot() && edge23->cell()->contains_point()
        && edge23->next() && !edge23->next()->foot() 
        && edge23->next()->is_primary()) {
        // rare
        edge23->next()->foot(edge23->foot()->x(), edge23->foot()->y());
        //printf("around point SOME MORE\n");
        if (showfeet) {
        event_log_ += "<circle id=\"footNEWpre3_2_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(edge23->foot()->x())+"\" cy=\""+to_str(edge23->foot()->y())+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }
    }

    if (edge23->twin()->foot() && edge23->twin()->cell()->contains_point()
        && !new_edge2.foot()) {
        new_edge2.foot(edge23->twin()->foot()->x(), edge23->twin()->foot()->y());
        //printf("around point TO NEW 2\n");
        if (showfeet) {
        event_log_ += "<circle id=\"footNEWpre3_2_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(edge23->twin()->foot()->x())+"\" cy=\""+to_str(edge23->twin()->foot()->y())+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }
    }
    
    if (edge12->foot() && edge12->cell()->contains_point()
        && !new_edge1.foot()) {
        new_edge1.foot(edge12->foot()->x(), edge12->foot()->y());
        //printf("around point TO NEW 1\n");
        if (showfeet) {
        event_log_ += "<circle id=\"footNEWpre3_2_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(edge12->foot()->x())+"\" cy=\""+to_str(edge12->foot()->y())+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }
    }

    // derived from lingering special case on hex fan housing (way above hex mesh)
    // ... but also handles at least three feet in t/test, so this is legit
    // ... yes this is happening in several cases that are also handled by other
    // cases above, and then a few those miss
    if (
       !edge23->foot()
       && edge23->is_curved() && new_edge2.is_curved()
       && edge23->twin()->cell()->contains_point()
       && new_edge2.cell()->contains_point()
       && edge12->foot()
       ) {
      double x = edge12->foot()->x();
      double y = edge12->foot()->y();
      reflect(x, y, edge12->vertex0()->x(), edge12->vertex0()->y(),
                   edge12->vertex1()->x(), edge12->vertex1()->y());
      edge23->foot(x, y);
      event_log_ += "<circle id=\"footNEWpre3_2_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
      event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfootworking\"/>\n";
    }

    if (!is_linear) {
      if (belongs(site1.source_category(), GEOMETRY_CATEGORY_POINT)
          && belongs(site3.source_category(), GEOMETRY_CATEGORY_SEGMENT)
         ) {
        if (new_edge2.vertex0()) {
          double x0 = site3.point0().x();
          double y0 = site3.point0().y();
          double x1 = site3.point1().x();
          double y1 = site3.point1().y();
          double x = new_edge2.vertex0()->x();
          double y = new_edge2.vertex0()->y();
          //printf("mf3");
          makefoot(x, y, x0, y0, x1, y1);
          //printf("\n");
          new_edge2.foot(x, y);
         
          if (showfeet) {
          event_log_ += "<circle id=\"foot3_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
          event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
          }

        }
      }
      
      if (belongs(site3.source_category(), GEOMETRY_CATEGORY_POINT)
          && belongs(site1.source_category(), GEOMETRY_CATEGORY_SEGMENT)) {
        
        new_edge2.foot(site3.point0().x(),  site3.point0().y());
      
        if (showfeet) {
        event_log_ += "<circle id=\"foot_after_3_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
        event_log_ += "cx=\""+to_str(site3.point0().x())+"\" cy=\""+to_str(site3.point0().y())+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
        }

        //printf("premf4\n");
        if (
          false
          //new_edge2.vertex0() 
          //&& new_edge2.vertex1()
          
        ) {
          double x0 = site1.point0().x();
          double y0 = site1.point0().y();
          double x1 = site1.point1().x();
          double y1 = site1.point1().y();
          double x = new_edge1.vertex0()->x();
          double y = new_edge1.vertex0()->y();
          //double x = new_vertex.x();
          //double y = new_vertex.y();
          //printf("mf4");
          makefoot(x, y, x0, y0, x1, y1);
          //printf("\n");
          // We were getting in here often, but this foot is probably 
          // getting reset most of the time by one of the other conditionals.
          // Only noticed one foot affected by perturbing this foot.
          new_edge1.foot(x, y);
          if (showfeet) {
          event_log_ += "<circle id=\"foot4_" + to_str((UV) &site1) + "_"+to_str((UV) &site3)+"\" ";
          event_log_ += "cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfoot2\"/>\n";
          }
        }
      }
    }
    
    event_log_ += "</g>\n";

    // Return a pointer to the new half-edge.
    return std::make_pair(&new_edge1, &new_edge2);
  }

  void _build() {
    // Remove degenerate edges.
    edge_iterator last_edge = edges_.begin();
    for (edge_iterator it = edges_.begin(); it != edges_.end(); it += 2) {
      const vertex_type* v1 = it->vertex0();
      const vertex_type* v2 = it->vertex1();
      if (v1 && v2 && vertex_equality_predicate_(*v1, *v2)) {
        remove_edge(&(*it));
      }
      else {
        if (it != last_edge) {
          edge_type* e1 = &(*last_edge = *it);
          edge_type* e2 = &(*(last_edge + 1) = *(it + 1));

          e1->twin(e2);
          e2->twin(e1);
          if (e1->prev()) {
            e1->prev()->next(e1);
            e2->next()->prev(e2);
          }
          if (e2->prev()) {
            e1->next()->prev(e1);
            e2->prev()->next(e2);
          }
        }
        last_edge += 2;
      }
    }
    edges_.erase(last_edge, edges_.end());

    // Set up incident edge pointers for cells and vertices.
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      it->cell()->incident_edge(&(*it));
      if (it->vertex0()) {
        it->vertex0()->incident_edge(&(*it));
      }
    }

    // Remove degenerate vertices.
    vertex_iterator last_vertex = vertices_.begin();
    for (vertex_iterator it = vertices_.begin(); it != vertices_.end(); ++it) {
      if (it->incident_edge()) {
        if (it != last_vertex) {
          *last_vertex = *it;
          vertex_type* v = &(*last_vertex);
          edge_type* e = v->incident_edge();
          do {
            e->vertex0(v);
            e = e->rot_next();
          } while (e != v->incident_edge());
        }
        ++last_vertex;
      }
    }
    vertices_.erase(last_vertex, vertices_.end());

    // Set up next/prev pointers for infinite edges.
    if (vertices_.empty()) {
      if (!edges_.empty()) {
        // Update prev/next pointers for the line edges.
        edge_iterator edge_it = edges_.begin();
        edge_type* edge1 = &(*edge_it);
        edge1->next(edge1);
        edge1->prev(edge1);
        ++edge_it;
        edge1 = &(*edge_it);
        ++edge_it;

        while (edge_it != edges_.end()) {
          edge_type* edge2 = &(*edge_it);
          ++edge_it;

          edge1->next(edge2);
          edge1->prev(edge2);
          edge2->next(edge1);
          edge2->prev(edge1);

          edge1 = &(*edge_it);
          ++edge_it;
        }

        edge1->next(edge1);
        edge1->prev(edge1);
      }
    } else {
      // Update prev/next pointers for the ray edges.
      for (cell_iterator cell_it = cells_.begin();
         cell_it != cells_.end(); ++cell_it) {
        if (cell_it->is_degenerate())
          continue;
        // Move to the previous edge while
        // it is possible in the CW direction.
        edge_type* left_edge = cell_it->incident_edge();
        while (left_edge->prev() != NULL) {
          left_edge = left_edge->prev();
          // Terminate if this is not a boundary cell.
          if (left_edge == cell_it->incident_edge())
            break;
        }

        if (left_edge->prev() != NULL)
          continue;

        edge_type* right_edge = cell_it->incident_edge();
        while (right_edge->next() != NULL)
          right_edge = right_edge->next();
        left_edge->prev(right_edge);
        right_edge->next(left_edge);
      }
    }

    // The above gets us the complete Voronoi diagram.
    // Now we'll narrow that down to just the medial axis for the polygon.
    
    if (0) { // handy data dump to copy-paste between stages while debugging
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      printf("edge %lld: %lld, %lld, %lld, %ld, %ld, %s, %s, %s, %s, %s\n",
          (long long unsigned int) &(*it),
          (long long unsigned int) it->twin(),
          (long long unsigned int) it->next(),
          (long long unsigned int) it->prev(),
          it->color(),
          it->cell()->source_index(),
          it->is_curved()?"curved":"      ",
          it->is_finite()?"finite":"      ",
          it->is_primary()?"primary":"      ",
          it->twin() == it->next() ? "next=twin":"twok",
          &(*it) == it->next() ? "next=itself":"nxtok"
      );
    }
    }

    // Mark edges exterior to the polygon by setting color attribute to 1.
    // (Adjacent vertices and cells are also marked.)
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (!it->is_finite()) { mark_exterior(&(*it)); }
    }

    // Now all the cells associated with the polygon's outer contour segments 
    // have color() == 1, while all cells associated with holes still have 
    // color() == 0. This isn't always enough information to label all edges
    // inside holes correctly. We'll go ahead and label edges not associated
    // with the outer cells as edges in holes, and then later correct
    // mislabeled edges.

    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (  it->cell()->color() == 0
         // cells with color 0 at this point are either holes
         // or regions within the polygon associated with concavites
         && it->twin()->cell()->color() == 0
         // this avoids labeling edges coming directly off
         // of the inner side of the medial axis that surrounds a hole
         && (  it->next()->twin()->cell()->color() != 1
            && it->prev()->twin()->cell()->color() != 1)
         ) {
        it->color(1);
      }
    }

    // Now we find cells with a mix of primary edges labeled as inside and 
    // outside. Adjacent primary edges can't have different inside-outside 
    // status. We're sure about the edges we've labled as within the polygon 
    // so far. So we recursively label adjacent primary edges as within if they
    // don't have that label already, and non-primary edges associated with
    // curved edges get their labels fixed too.

    for (cell_iterator it = cells_.begin(); it != cells_.end(); ++it) {
      //printf("    cell source_index %ld\n",it->source_index());
      edge_type* e = it->incident_edge();
      do {
        if (e->is_primary() && e->next()->is_primary()) {
          if (e->color() == 0 && e->next()->color() != 0) {
            //printf("    start first recurse\n");
            mark_interior(e->next());
            } 
          if (e->color() != 0 && e->next()->color() == 0) {
            //printf("    start second recurse\n");
            mark_interior(e, true);
            }
        }
        e = e->next();
      } while (e != it->incident_edge());
    }

    // Deeper edges still escape recursive stuff above
    
    
    
    
    
    
    
// Adjust this or copy modify to capture a few more cases
// prob bring back req that at least one is primary
// and consider looking at consective primary by doing a next->twin->next
// jump over any secondary () and then if you do a 1 to 0 color conversion
// probably change color of the hopped-over secondary too.



    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (
          //it->is_primary() &&
           (  
           //it->next()->is_primary() && 
           it->next()->color() == 0
           && 
           //it->prev()->is_primary() && 
           it->prev()->color() == 0
           )
         ) {
        it->color(0);
        it->twin()->color(0);
      }
    }


    // yes, this fixed some missed cases
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (
          it->is_primary() && it->color() == 0
          && !it->next()->is_primary() 
          && it->next()->twin()->next()->is_primary()
          && it->next()->twin()->next()->color() == 1
         ) {
        it->next()->twin()->next()->color(0);
        it->next()->twin()->next()->twin()->color(0);
        // the hopped-over non primaries should be changed too
        it->next()->color(0);
        it->next()->twin()->color(0);
      }
    }
    
    
    
    
    // Some non-primary edges of more complex cells don't get corrected
    // by the steps above. But now they're easy to identify and fix.
    
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (!it->is_primary() &&
           (  it->rot_next()->is_primary() && it->rot_next()->color() == 0
           && it->rot_prev()->is_primary() && it->rot_prev()->color() == 0
           )
         ) {
        it->color(0);
        it->twin()->color(0);
      }
    }
//event_log_ += "<!-- magentas -->\n";

    // Still missing some - think it's secondaries.
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (
          !it->is_primary() && it->color() == 1
          && it->vertex0() && it->vertex1()
           &&
           (
           (
            it->twin()->prev()->is_curved() &&
           //&& (it->twin()->prev()->is_curved() 
           //    || (it->twin()->prev()->is_finite() && it->twin()->prev()->is_primary()) )
           it->prev()->color() == 1 && it->prev()->is_primary()
           && it->twin()->prev()->color() == 0
           && it->twin()->prev()->prev()->color() == 0
           )
           //||
           //(
           //&& (it->prev()->is_curved() 
           //    || (it->prev()->is_finite() && it->prev()->is_primary()) )
           //it->next()->color() == 1 && it->next()->is_primary()
           //it->prev()->color() == 0
           //&& it->prev()->prev()->color() == 0
           //)
           )
         ) {
        printf("\n\nYES\n\n");
        //it->color(0);
        //it->twin()->color(0);
        if (it->vertex0() && it->vertex1()) {
event_log_ += "<line style=\"stroke-width:200000;stroke:magenta;\" ";
event_log_ += "x1=\""+to_str(it->vertex0()->x())+"\" y1=\""+to_str(it->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(it->vertex1()->x())+"\" y2=\""+to_str(it->vertex1()->y())+"\" />\n";
}
      }
    }


bool dbge = false;
if (dbge) {
for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
edge_type* edge = &(*it);
if (edge->color() == 1 && edge->vertex0() && edge->vertex1()) {
event_log_ += "<line style=\"stroke-width:300000;stroke:yellow;\" ";
event_log_ += "x1=\""+to_str(edge->vertex0()->x())+"\" y1=\""+to_str(edge->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(edge->vertex1()->x())+"\" y2=\""+to_str(edge->vertex1()->y())+"\" />\n";
if (edge->is_primary()) {
event_log_ += "<line style=\"stroke-width:200000;stroke:orange;\" ";
event_log_ += "x1=\""+to_str(edge->vertex0()->x())+"\" y1=\""+to_str(edge->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(edge->vertex1()->x())+"\" y2=\""+to_str(edge->vertex1()->y())+"\" />\n";
} else if (!edge->is_primary()) {
event_log_ += "<line style=\"stroke-width:200000;stroke:aqua;\" ";
event_log_ += "x1=\""+to_str(edge->vertex0()->x())+"\" y1=\""+to_str(edge->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(edge->vertex1()->x())+"\" y2=\""+to_str(edge->vertex1()->y())+"\" />\n";
}
}
}
}

    // Now all edges within the polygon have color() == 0 and all edges
    // outside of the polygon or inside holes in the polygon have 
    // color() == 1.

    /////////////
    // At this point we modify the half edge graph to better represent the 
    // the medial axis.
    // The main thing to do is update next() and prev() pointers to follow
    // along the primary edges that represent the medial axis, instead
    // of having them point just to the next/prev within each Voronoi cell.

    // Get the edge corresponding to the first polygon input segment
    // so the first loop we traverse is the outer polygon loop.
    // Currently it doesn't matter that we process that first, but we
    // may want to enhance the output data structure later to reflect 
    // inside vs outside/in-concavity/in-hole medial axis edge collections.

    edge_type * start_edge = NULL;
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (it->cell()->source_index() == 0
          && it->color() == 0
          && it->is_primary()
         ) {
        start_edge = &(*it);
        break;
      }
    }

    // Walk the edge references and modify to represent medial axis.
    while (start_edge != NULL) {
      edge_type * edge = start_edge;
      //start_edge->color(2);
      do {
        // mark visited internal edges (will restore to 0 afterward)
        edge->color(2);

        // if next edge is within polygon
        if (edge->next()->color() == 0 || edge->next()->color() == 2) {
          if (edge->next()->is_primary()) { 
            // go to next edge within same cell 
            edge = edge->next();
          } else { 
            // skip over a non-primary edge to the primary edge that follows it
            edge_type* prev = edge;
            edge = edge->next()->twin()->next();
            // get foot from non-primary endpoint and
            // mirror foot info from the non-primary to the twin
            if (prev->twin()->vertex0() && prev->twin()->vertex1() && prev->next()->vertex1()) {
              // The reflect about line case is simple:
              double x = prev->next()->vertex1()->x();
              double y = prev->next()->vertex1()->y();
              
              if (!edge->foot()) {
                edge->foot(x, y);
              }
              
              double x0 = prev->twin()->vertex0()->x();
              double y0 = prev->twin()->vertex0()->y();
              double x1, y1;
              // would like to already have foot in place
              // but not quite there yet, and this performs well
              if (true || !prev->twin()->foot()) {
                if (!prev->twin()->is_curved()) {
                  double x1 = prev->twin()->vertex1()->x() + 0;
                  double y1 = prev->twin()->vertex1()->y() + 0;
                  reflect(x, y, x0, y0, x1, y1);
                  prev->twin()->foot(x, y);
                  //printf("reflect foot to line\n");
                } else {
                  // The case for a curved edge isn't as simple, but 
                  // it seems most feet in this case are already properly
                  // calculated by the event-processing code.
                  // It may be that we never get to, or should never need to 
                  // get into this else{}. Maybe eliminate this after foot-finding
                  // in the event-processing has been fully understood and
                  // implemented.
                  // ... "reflect foot for parabola" still happens a lot -
                  //     still depending on it
                  if (!prev->twin()->prev()->is_primary()) {
                    //printf("from prev twin prev non-primary\n");
                    prev->twin()->foot(prev->twin()->prev()->vertex0()->x(),
                                       prev->twin()->prev()->vertex0()->y()
                                      );       
                  }
                  else {
                    double x = prev->next()->vertex1()->x();
                    double y = prev->next()->vertex1()->y();
                    if (!edge->is_curved()) {
                      double x0 = edge->vertex0()->x();
                      double y0 = edge->vertex0()->y();
                      double x1 = edge->vertex1()->x();
                      double y1 = edge->vertex1()->y();
                      reflect(x, y, x0, y0, x1, y1);
                      prev->twin()->foot(x, y);
                      //printf("reflect foot for parabola\n");
                    }                  
                  }
                }
              }
            }
            // first make the clipped-out edges ahead link to themselves
            prev->next()->twin()->next(prev->next());
            prev->next()->prev(prev->next()->twin());
            // now link this to new next
            prev->next(edge);
            edge->prev(prev);
          }
        } else {
          // corner - end touches polygon, so turn around
          edge_type * prev = edge;
          edge = edge->twin();
if (dbge) {
event_log_ += "<line style=\"stroke-width:15000;stroke:red;\" ";
event_log_ += "x1=\""+to_str(prev->vertex0()->x())+"\" y1=\""+to_str(prev->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(prev->vertex1()->x())+"\" y2=\""+to_str(prev->vertex1()->y())+"\" />\n";
event_log_ += "<line style=\"stroke-width:15000;stroke:red;\" ";
event_log_ += "x1=\""+to_str(edge->vertex0()->x())+"\" y1=\""+to_str(edge->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(edge->vertex1()->x())+"\" y2=\""+to_str(edge->vertex1()->y())+"\" />\n";
}

// This may be obsolete now that we're doing corner foot processing in site events
// and it actually gives some bad results only in combination with the new
// processing there.
// It also may be that missing foot code later picks up some of these ? when we
// don't do this here.
if (false) {
          // figure feet
          double theta = atan2(edge->vertex1()->y() - edge->vertex0()->y(),
                               edge->vertex1()->x() - edge->vertex0()->x());
          double footx = prev->vertex0()->x() + prev->vertex0()->r();
          double footy = prev->vertex0()->y();
          // This should always come out <= 1 and > 0.
          // Sometimes it spills over just beyond 1 in the case of 
          // a corner so shallow it's practically flat.
          // So snap to 1 if > 1.
          double for_acos = prev->vertex0()->r() 
            / sqrt(pow(prev->vertex1()->x() - prev->vertex0()->x(),2)
                 + pow(prev->vertex1()->y() - prev->vertex0()->y(),2)
                  );
          if (for_acos > 1) { for_acos = 1; }
          double phi = acos( for_acos );

          rotate_2d(footx, footy, theta + phi, prev->vertex0()->x(), 
                                               prev->vertex0()->y()
          );
          
          if (!prev->foot()) {
          prev->foot(footx, footy);
          }

          rotate_2d(footx, footy, -2*phi, prev->vertex0()->x(), 
                                          prev->vertex0()->y()
          );
          
          if (!edge->next()->foot()) {
          edge->next()->foot(footx, footy);
          }

          if (!edge->foot()) {
          edge->foot(edge->vertex0()->x(), edge->vertex0()->y());
          }
}
          // first connect edges ahead to eachother
          prev->next()->prev(edge->prev());
          edge->prev()->next(prev->next());
if (dbge) {
if (prev->next()->vertex0() && prev->next()->vertex1()) {
event_log_ += "<line style=\"stroke-width:15000;stroke:blue;\" ";
event_log_ += "x1=\""+to_str(prev->next()->vertex0()->x())+"\" y1=\""+to_str(prev->next()->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(prev->next()->vertex1()->x())+"\" y2=\""+to_str(prev->next()->vertex1()->y())+"\" />\n";
}
if (edge->prev()->vertex0() && edge->prev()->vertex1()) {
event_log_ += "<line style=\"stroke-width:15000;stroke:blue;\" ";
event_log_ += "x1=\""+to_str(edge->prev()->vertex0()->x())+"\" y1=\""+to_str(edge->prev()->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(edge->prev()->vertex1()->x())+"\" y2=\""+to_str(edge->prev()->vertex1()->y())+"\" />\n";
}

if (prev->next()->prev()->vertex1() && prev->next()->prev()->vertex0()) {
event_log_ += "<line style=\"stroke-width:10000;stroke:gray;\" ";
event_log_ += "x1=\""+to_str(prev->next()->prev()->vertex0()->x())+"\" y1=\""+to_str(prev->next()->prev()->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(prev->next()->prev()->vertex1()->x())+"\" y2=\""+to_str(prev->next()->prev()->vertex1()->y())+"\" />\n";
}
if (edge->prev()->next()->vertex0() && edge->prev()->next()->vertex1()) {
event_log_ += "<line style=\"stroke-width:10000;stroke:gray;\" ";
event_log_ += "x1=\""+to_str(edge->prev()->next()->vertex0()->x())+"\" y1=\""+to_str(edge->prev()->next()->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(edge->prev()->next()->vertex1()->x())+"\" y2=\""+to_str(edge->prev()->next()->vertex1()->y())+"\" />\n";
}
}
          // now link the corner edges together
          prev->next(edge);
          edge->prev(prev);
if (dbge) {
event_log_ += "<line style=\"stroke-width:10000;stroke:pink;\" ";
event_log_ += "x1=\""+to_str(prev->vertex0()->x())+"\" y1=\""+to_str(prev->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(prev->vertex1()->x())+"\" y2=\""+to_str(prev->vertex1()->y())+"\" />\n";
event_log_ += "<line style=\"stroke-width:10000;stroke:pink;\" ";
event_log_ += "x1=\""+to_str(edge->vertex0()->x())+"\" y1=\""+to_str(edge->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(edge->vertex1()->x())+"\" y2=\""+to_str(edge->vertex1()->y())+"\" />\n";

event_log_ += "<line style=\"stroke-width:5000;stroke:purple;\" ";
event_log_ += "x1=\""+to_str(prev->next()->vertex0()->x())+"\" y1=\""+to_str(prev->next()->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(prev->next()->vertex1()->x())+"\" y2=\""+to_str(prev->next()->vertex1()->y())+"\" />\n";
event_log_ += "<line style=\"stroke-width:5000;stroke:purple;\" ";
event_log_ += "x1=\""+to_str(edge->prev()->vertex0()->x())+"\" y1=\""+to_str(edge->prev()->vertex0()->y())+"\" ";
event_log_ += "x2=\""+to_str(edge->prev()->vertex1()->x())+"\" y2=\""+to_str(edge->prev()->vertex1()->y())+"\" />\n";
}

        }
      } while (edge != start_edge && edge->color() != 2);

      // After the first run, any further runs are following internal hole 
      // loops. Find the first edge of the first/next hole.
      start_edge = NULL;
      for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
        if (it->color() == 0
            && it->is_primary()
           ) {
          start_edge = &(*it);
          break;
        }
      }
    }

    // Restore color() == 0 for internal edges.
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (it->color() == 2) {
        it->color(0);
      }
    }

    // add some missing feet

    event_log_ += "<g id=\"missingfeet\">\n";

    start_edge = NULL;
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (it->color() == 0
          && it->is_primary()
         ) {
        start_edge = &(*it);
        break;
      }
    }
    while (start_edge != NULL) {
      edge_type * edge = start_edge;
      do {
        if (!edge->foot()
           && edge->next()->foot()
           && edge->color() == 0
           && edge->is_primary()
           ) {
           
          if (edge->cell()->contains_point()) {
          edge->foot(edge->next()->foot()->x(), edge->next()->foot()->y());
          event_log_ += "<circle cx=\""+to_str(edge->next()->foot()->x())+"\" cy=\""+to_str(edge->next()->foot()->y())+"\" r=\"110000\" class=\"evtfoot3\"/>\n";
          }
          else {
            double x  = edge->vertex0()->x();
            double y  = edge->vertex0()->y();
            double x0 = edge->next()->foot()->x();
            double y0 = edge->next()->foot()->y();
            double x1 = edge->next()->vertex0()->x();
            double y1 = edge->next()->vertex0()->y();
            rotate_2d(x1, y1, 3.14159/2, x0, y0);
            makefoot(x, y, x0, y0, x1, y1);
            edge->foot(x, y);
            event_log_ += "<circle cx=\""+to_str(x)+"\" cy=\""+to_str(y)+"\" r=\"110000\" class=\"evtfoot3\"/>\n";
          }
          //printf("fixed missing foot for consecutive linear edges\n");
          if (! edge->prev()->foot()
              && ( !edge->prev()->is_curved()
                 || edge->prev()->cell()->contains_point() )
              && (edge->prev()->color() == 0 || edge->prev()->color() == 2)
              && edge->prev()->is_primary()) {
            edge = edge->prev();
            edge->color(0);
            edge = edge->prev();
            edge->color(0);
          }
        }
        // mark visited internal edges (will restore to 0 afterward)
        edge->color(2);
        edge = edge->next();
      } while (edge != start_edge && edge->color() != 2);
      
      // After the first run, any further runs are following internal hole 
      // loops. Find the first edge of the first/next hole.
      start_edge = NULL;
      for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
        if (it->color() == 0
            && it->is_primary()
           ) {
          start_edge = &(*it);
          break;
        }
      }
    }
    
    event_log_ += "</g>\n";

    // Restore color() == 0 for internal edges.
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (it->color() == 2) {
        it->color(0);
      }
    }

    // check for any missing feet
    for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
      if (it->color() == 0
          && it->is_primary()
         ) {
        if (!it->foot()) {
          //croak("\nNO FOOT\n\n");          
          printf("NO FOOT\n");
          event_log_ += "<line class=\"edge_missing_foot\" ";
          event_log_ += " x1=\""+to_str(it->vertex0()->x())+"\" y1=\""+to_str(it->vertex0()->y())+"\"";
          event_log_ += " x2=\""+to_str(it->vertex1()->x())+"\" y2=\""+to_str(it->vertex1()->y())+"\"/>\n";

          // For debugging, put in placeholders for missing feet 
          // in some rediculous location, so we can still get some kind of 
          // output without a segfault.
          it->foot(0, 0);
          }
        if (it->next() &&  !it->next()->next()) {printf("NO NEXT\n\n");}
      }
    } 

    
    // Debug reporting
    /*
    if (0) {
      printf("original edges\n");
      printf("srcInd isInf curved   color");
      printf("  this     twin       next       prev        point\n");
      for (edge_iterator it = edges_.begin(); it != edges_.end(); ++it) {
        printf("%3d   %5s  %7s  %2d  ",
          it->cell()->source_index(),
          (it->is_finite() ? "     ":" INF "),
          (it->is_curved() ? " curve ":" line  "),
          it->color()
        );
        printf("%llu, %llu , %llu, %llu ",
          (unsigned long long int) &(*it),
          (unsigned long long int) it->twin(),
          (unsigned long long int) it->next(),
          (unsigned long long int) it->prev()
        );
      if (it->vertex0()) {
        printf("[%f , %f , %f]",
          it->vertex0()->x(),
          it->vertex0()->y(),
          it->vertex0()->r()
        );
      }
      else {printf("no vert0");}
      printf("\n");
      }
    }
    */
  }

 private:
  typedef typename cell_container_type::iterator cell_iterator;
  typedef typename vertex_container_type::iterator vertex_iterator;
  typedef typename edge_container_type::iterator edge_iterator;
  typedef typename TRAITS::vertex_equality_predicate_type
    vertex_equality_predicate_type;

  template <typename SEvent>
  bool is_primary_edge(const SEvent& site1, const SEvent& site2) const {
    bool flag1 = site1.is_segment();
    bool flag2 = site2.is_segment();
    if (flag1 && !flag2) {
      return (site1.point0() != site2.point0()) &&
             (site1.point1() != site2.point0());
    }
    if (!flag1 && flag2) {
      return (site2.point0() != site1.point0()) &&
             (site2.point1() != site1.point0());
    }
    return true;
  }

  template <typename SEvent>
  bool is_linear_edge(const SEvent& site1, const SEvent& site2) const {
    if (!is_primary_edge(site1, site2)) {
      return true;
    }
    return !(site1.is_segment() ^ site2.is_segment());
  }

  // Remove degenerate edge.
  void remove_edge(edge_type* edge) {
    
    // Are these two ifs necessary?
    // Put these in for debugging, where the problem was something else,
    // but these do fill in/transfer some missing feet.
    // After revising the foot-finding (trying to do it all in the sweepline
    // event processing), see if these are still needed.
    if (edge->foot() && !edge->next()->foot()) {
      edge->next()->foot(edge->foot()->x(), edge->foot()->y());
    }
    if (edge->twin()->foot() && !edge->twin()->next()->foot()) {
      edge->twin()->next()->foot(edge->twin()->foot()->x(), edge->twin()->foot()->y());
    }

    // Update the endpoints of the incident edges to the second vertex.
    vertex_type* vertex = edge->vertex0();
    edge_type* updated_edge = edge->twin()->rot_next();
    while (updated_edge != edge->twin()) {
      updated_edge->vertex0(vertex);
      updated_edge = updated_edge->rot_next();
    }
    
    edge_type* edge1 = edge;
    edge_type* edge2 = edge->twin();

    edge_type* edge1_rot_prev = edge1->rot_prev();
    edge_type* edge1_rot_next = edge1->rot_next();

    edge_type* edge2_rot_prev = edge2->rot_prev();
    edge_type* edge2_rot_next = edge2->rot_next();

    // Update prev/next pointers for the incident edges.
    edge1_rot_next->twin()->next(edge2_rot_prev);
    edge2_rot_prev->prev(edge1_rot_next->twin());
    edge1_rot_prev->prev(edge2_rot_next->twin());
    edge2_rot_next->twin()->next(edge1_rot_prev);

  }

  void mark_exterior(edge_type* edge) {
    if (edge->color() == 1) {
      return;
    }
    edge->color(1);
    edge->twin()->color(1);
    edge->cell()->color(1);
    edge->twin()->cell()->color(1);
    vertex_type* v = edge->vertex1();
    if (!v) {v = edge->vertex0();}
    if (v == NULL || !edge->is_primary()) {
      return;
    }
    v->color(1);
    edge_type* e = v->incident_edge();
    do {
      mark_exterior(e);
      e = e->rot_next();
    } while (e != v->incident_edge());
  }

  void mark_interior(edge_type* edge, bool backward = false) {
    // This function seems to work as intended, though it's still
    // on probation. The conditionals in the do {} while(); might not all be
    // correct or necessary (or they might be). 
    edge->color(0);
    edge->twin()->color(0);
    vertex_type* v = edge->vertex0();
    edge_type* e;
    if (edge->is_curved()) {
      edge_type* start_e = (edge->cell()->contains_point()) ? edge : edge->twin();
      e = start_e;
      do {
        if (!e->is_primary()) { 
          e->color(0);
          e->twin()->color(0);
        }
        e = e->next();
      } while (e != start_e);
    }

    if (!backward) {
      v = edge->vertex1();
    } 

    if (!v) {
      return;
    }
    e = v->incident_edge();
    v->color(0);
    e = v->incident_edge();
    do {
      if (e->is_primary() && e->next()->is_primary()) {
        if (e->color() == 0 && e->next()->color() != 0) {
          mark_interior(e->next());
        }
        if (e->color() != 0 && e->next()->color() == 0) {
          mark_interior(e, true);
        }
      }
      if (e->is_primary() && e->prev()->is_primary()) {
        if (e->color() == 0 && e->prev()->color() != 0) {
          mark_interior(e->prev(), true);
        }
        if (e->color() != 0 && e->prev()->color() == 0) {
          mark_interior(e);
        }
      }
      e = e->rot_next();
    } while (e != v->incident_edge());
  }

  bool is_exterior (const edge_type& e) { return (e->color() != 0); }

  void rotate_2d(double &x, double &y, const double theta, const double xo = 0, const double yo = 0) {
    double xp;
    x -= xo;
    y -= yo;
    xp = (x * cos(theta) - y * sin(theta)) + xo;
    y  = (y * cos(theta) + x * sin(theta)) + yo;
    x  = xp;
  }
  template <typename CT>
  void reflect(CT &x, CT &y, const CT x0, const CT y0, const CT x1, const CT y1) {
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

void makefoot(double & x, double & y, const double x0, const double y0,
                                      const double x1, const double y1) {
    // infinite slope case first
    if (x1 - x0 == 0) {
        x = x0;
    } else {
      double m  = (y1 - y0)/(x1 - x0);
      if (m == 0) {
          y = y0;
      }
      else {
        double intersect_x = ((m * x0) - y0 + ((1 / m) * x) + (y)) / (m + (1 / m));
          double intersect_y = -(x0 - intersect_x) * m + y0;
            x = intersect_x;
            y = intersect_y;
      }
    }
  }

  cell_container_type cells_;
  vertex_container_type vertices_;
  edge_container_type edges_;
  std::string event_log_;
  vertex_equality_predicate_type vertex_equality_predicate_;

  // Disallow copy constructor and operator=
  medial_axis(const medial_axis&);
  void operator=(const medial_axis&);
};
}  // polygon
}  // boost

#endif  // BOOST_POLYGON_MEDIAL_AXIS
