/*______________________________________________________________________________
  BoostGraph_i.h
  Description: This library provides a simple interface to the Boost Graph 
  C++ Libraries so that other applications can ignore much of the templating
  and syntax details. This library implements accessors to algorithms within
  boost graph that are applicable to both directed and undirected graphs
  ______________________________________________________________________________
*/

#ifndef _BOOSTGRAPH_I_H_
#define _BOOSTGRAPH_I_H_

#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <utility>
#include <algorithm>
#include "TwoDArray.h"
#include <boost/config.hpp>
#include <boost/property_map.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/graph_traits.hpp>
#include <boost/graph/graphviz.hpp>
#include <boost/pending/indirect_cmp.hpp>
#include <boost/pending/integer_range.hpp>
#include <boost/static_assert.hpp>

#include <boost/graph/breadth_first_search.hpp>
#include <boost/graph/depth_first_search.hpp>

#include <boost/graph/dijkstra_shortest_paths.hpp>
#include <boost/graph/johnson_all_pairs_shortest.hpp>
#include <boost/graph/floyd_warshall_shortest.hpp>

using namespace std;
using namespace boost;

typedef property<edge_weight_t, double> Weight;
typedef std::pair<int,int> Pair;
typedef std::pair<Pair*,double> GEdge; // Edge nodes with weight
typedef std::pair<std::vector<int>, double> Path; // Path of nodes with path weight

//______________________________________________________________________________
// CLASS DEFINITION
template <typename G>
class BoostGraph_i
{
public:
  // Type declarations
  typedef typename graph_traits<G>::vertices_size_type size_type;
  typedef typename graph_traits<G>::edge_descriptor edge_descriptor; // Boost edge
  typedef typename graph_traits<G>::vertex_descriptor vertex_descriptor; // Boost vertex
  struct dijkstraPath { // Hold node distances and parent paths for dijkstras shortest paths algorithm
    int sourceNodeId;
    std::vector<int>* distances;
    std::vector<vertex_descriptor>* parents;
  };

  BoostGraph_i();
  virtual ~BoostGraph_i();

  G* boostGraph;     
  virtual bool addNode(int nodeId);
  virtual bool addEdge(int nodeIdSource, int nodeIdSink, double weightVal);
  virtual int nodeCount() const;
  virtual int edgeCount() const;
  // ALGORITHMS
  virtual std::vector<int> breadthFirstSearch(int startNodeId);
  virtual std::vector<int> depthFirstSearch(int startNodeId);
  virtual Path dijkstraShortestPath(int nodeIdStart, int nodeIdEnd); 
  virtual double allPairsShortestPathsJohnson(int nodeIdStart, int nodeIdEnd);
  virtual double allPairsShortestPathsFloydWarshall(int nodeIdStart, int nodeIdEnd); 
  
//protected:
  int isDirected;
  int _changed; // -1 for no graph object, 0 for no change, 1 for change in graph 
  std::vector<GEdge*>* _edges; // holds the edge pairs
  std::map<int,int>* _nodes; // holds a slot for each node
  typename property_map<G,edge_weight_t>::type _weightmap;
  std::map<int,dijkstraPath> _dijkstraPaths; // Dijkstra's shortest paths storage
  TwoDArray<double>* _allPairsDistanceJohnson; // Path distance for Johnson All Pairs Shortest Paths
  TwoDArray<double>* _allPairsDistanceFloydWarshall; // Path distance for Floyd-Warshall APSP
  virtual typename graph_traits<G>::vertex_descriptor _getNode(int nodeId);
  virtual void _fillGraph(); // instantiate boostGraph and adds nodes and edges   

};
 

//______________________________________________________________________________
// IMPLEMENTATION
template <typename G> 
BoostGraph_i<G>::BoostGraph_i() {
  _changed = -1;
  _edges = new std::vector<GEdge*>;
  _nodes = new std::map<int,int>;
  _allPairsDistanceJohnson = NULL;
}
//______________________________________________________________________________
template <typename G> 
BoostGraph_i<G>::~BoostGraph_i() {
  // delete GEdge and Pair objects
  for(unsigned int i=0; i<_edges->size(); i++) {
    delete (*_edges)[i]->first; // Pair pointer
    delete (*_edges)[i];
  }
  for(unsigned int i=0; i<_dijkstraPaths.size(); i++) {
    delete _dijkstraPaths[i].distances;
    delete _dijkstraPaths[i].parents;
  }

  delete boostGraph;
  delete _edges;
  delete _nodes;
} 
//______________________________________________________________________________
template <typename G>
bool BoostGraph_i<G>::addNode(int nodeId) {
  if((*_nodes)[nodeId]==nodeId) return false; // node exists
  (*_nodes)[nodeId]=nodeId;
  _changed=1;
  return true;
}
//______________________________________________________________________________
template <typename G>
bool BoostGraph_i<G>::addEdge(int nodeIdSource, int nodeIdSink, double weightVal=1.0) {
  Pair* twoNodes = new Pair(nodeIdSource,nodeIdSink);
  GEdge* thisEdge = new GEdge(twoNodes,weightVal);
  addNode(nodeIdSource);
  addNode(nodeIdSink);
  _edges->push_back(thisEdge);
  _changed=1;
  return true; 
}
//______________________________________________________________________________
template <typename G>
int BoostGraph_i<G>::nodeCount() const {
  return _nodes->size();
}
//______________________________________________________________________________
template <typename G>
int BoostGraph_i<G>::edgeCount() const {
  return _edges->size();
}
//______________________________________________________________________________
template <typename G>
typename graph_traits<G>::vertex_descriptor BoostGraph_i<G>::_getNode(int nodeId) {
  typename graph_traits<G>::vertex_descriptor n;
  if((*_nodes)[nodeId]==nodeId) {
    n = vertex(nodeId, *this->boostGraph);  
  }
  return n;
}
//______________________________________________________________________________
template <typename G>
void BoostGraph_i<G>::_fillGraph() {
  int numNodes = nodeCount();
  // zero out stored data
  _dijkstraPaths.clear();
  _allPairsDistanceJohnson = NULL;
  
  this->boostGraph = new G(numNodes);  // Boost Graph instance  
  // add nodes, in edges or not
  for(std::map<int,int>::iterator Ni = _nodes->begin(); Ni != _nodes->end(); Ni++) { 
    vertex((*Ni).first,*this->boostGraph);
  } 
  // add edges
  _weightmap = get(edge_weight, *this->boostGraph);
  for(unsigned int i=0; i<_edges->size(); i++) {
    GEdge* ge = (*_edges)[i];
    edge_descriptor e; bool inserted;
    if (ge->first->first>=0 && ge->first->second>=0) { // skip any malformed edges
      tie(e, inserted) = add_edge(ge->first->first, ge->first->second, Weight(ge->second), *this->boostGraph);
      _weightmap[e] = ge->second; 
    }
  }
  _changed=0;
  return;
} 


//______________________________________________________________________________ 
// ALGORITHMS

// Breadth First Search
//  - parameters:
//    - startNodeId, the start node for the traversal
//  - returns: a vector of integers identifying the node order of the traversal
// BFS time visitor
template <typename TimeMap> 
class bfs_time_visitor : public default_bfs_visitor 
{
  typedef typename property_traits < TimeMap >::value_type T;
public:
  bfs_time_visitor(TimeMap tmap, T & t):m_timemap(tmap), m_time(t) { }
  template < typename Vertex, typename Graph >
    void discover_vertex(Vertex u, const Graph & g) const
  {
    put(m_timemap, u, m_time++);
  }
  TimeMap m_timemap;
  T & m_time;
};
template <typename G>
std::vector<int> BoostGraph_i<G>::breadthFirstSearch(int startNodeId) {
  std::vector<int> ret; // list of nodes to return

  if(_changed!=0) this->_fillGraph();
  int N = num_vertices(*this->boostGraph);// number of nodes

  // Typedefs
  
  typedef typename graph_traits<G>::vertices_size_type Size;
  typedef Size* Iiter;

  // a vector to hold the discover time property for each vertex
  std::vector <Size> dtime(num_vertices(*this->boostGraph));

  Size time = 0;
  bfs_time_visitor<Size*> vis(&dtime[0], time);
  breadth_first_search(*this->boostGraph, vertex(startNodeId, *this->boostGraph), visitor(vis));

  // Use std::sort to order the vertices by their discover time
  std::vector<size_type> discover_order(N);
  integer_range<int> range(0, N);
  std::copy(range.begin(), range.end(), discover_order.begin());
  std::sort(discover_order.begin(), discover_order.end(),
            indirect_cmp< Iiter, std::less<Size> >(&dtime[0]));

  for (int i = 0; i < N; ++i) 
    ret.push_back(int(discover_order[i]));
  return ret;
}
//______________________________________________________________________________ 
// Depth First Search
//  - parameters:
//    - startNodeId, the start node for the traversal
//  - returns: a vector of integers identifying the node order of the traversal
// DFS time visitor
template < typename TimeMap > class dfs_time_visitor:public default_dfs_visitor {
  typedef typename property_traits < TimeMap >::value_type T;
public:
  dfs_time_visitor(TimeMap dmap, TimeMap fmap, T & t)
:  m_dtimemap(dmap), m_ftimemap(fmap), m_time(t) {
  }
  template < typename Vertex, typename Graph >
    void discover_vertex(Vertex u, const Graph & g) const
  {
    put(m_dtimemap, u, m_time++);
  }
  template < typename Vertex, typename Graph >
    void finish_vertex(Vertex u, const Graph & g) const
  {
    put(m_ftimemap, u, m_time++);
  }
  TimeMap m_dtimemap;
  TimeMap m_ftimemap;
  T & m_time;
};
template <typename G>
std::vector<int> BoostGraph_i<G>::depthFirstSearch(int startNodeId) {
  std::vector<int> ret; // list of nodes to return
  
  if(_changed!=0) this->_fillGraph();
  int N = num_vertices(*this->boostGraph);// number of nodes

  // Typedefs
  typedef size_type* Iiter;

  // discover time and finish time properties
  std::vector<size_type> dtime(num_vertices(*this->boostGraph));
  std::vector<size_type> ftime(num_vertices(*this->boostGraph));
  size_type t = 0;
  dfs_time_visitor<size_type*> vis(&dtime[0], &ftime[0], t);

  depth_first_search(*this->boostGraph, visitor(vis));

  // use std::sort to order the vertices by their discover time
  std::vector<size_type> discover_order(N);
  integer_range<size_type> r(0, N);
  std::copy(r.begin(), r.end(), discover_order.begin());
  std::sort(discover_order.begin(), discover_order.end(),
            indirect_cmp<Iiter, std::less<size_type> >(&dtime[0]));
            
  for (int i = 0; i < N; ++i)
    ret.push_back(int(discover_order[i]));
  return ret;
}
//______________________________________________________________________________ 
// Dijksta's Shortest Paths
//  - parameters:
//    - nodeIdStart, the root node id. the paths starts from here
//    - nodeIdEnd, the end node id in the path
//  - returns: a Path were the vector gives the path order and the double give the weight
//  - note: 
template <typename G>
Path BoostGraph_i<G>::dijkstraShortestPath(int nodeIdStart, int nodeIdEnd) {
  if(_changed!=0) this->_fillGraph();
  
  Path ret;  
  // compute shortest paths if not done already
  if(_dijkstraPaths[nodeIdStart].sourceNodeId >=0) {
    std::vector<vertex_descriptor>* p = new std::vector<vertex_descriptor>(num_vertices(*this->boostGraph));
    std::vector<int>* d = new std::vector<int>(num_vertices(*this->boostGraph));
    _dijkstraPaths[nodeIdStart].distances = d;
    _dijkstraPaths[nodeIdStart].parents = p;
  
    vertex_descriptor source = vertex(nodeIdStart, *this->boostGraph);  
    dijkstra_shortest_paths(*this->boostGraph, source, predecessor_map(&(*p)[0]).distance_map(&(*d)[0]));
  }
  
  // retrieve path and distance
  Path tmp; // push nodes on backwards, then reverse for return
  int Vi=nodeIdEnd;
  tmp.first.push_back(Vi);
  while(nodeIdStart != Vi && Vi>=0) {
    int Vt = (*_dijkstraPaths[nodeIdStart].parents)[Vi];
    tmp.first.push_back(Vt);
    Vi = Vt;
  }
  std::vector<int>* distances = _dijkstraPaths[nodeIdStart].distances;
  ret.second = (*distances)[nodeIdEnd];
  
  // reverse tmp path
  for (std::vector<int>::iterator i=tmp.first.end()-1; i!=tmp.first.begin(); i--) {
    ret.first.push_back((*i));
  }
  ret.first.push_back((*tmp.first.begin()));
  
  return ret;
}
//______________________________________________________________________________ 
// Johnson All Pairs Shortest Paths (Good for sparse interaction graphs)
//  - parameters:
//    - nodeIdStart, the root node id. the paths starts from here
//    - nodeIdEnd, the end node id in the path
//  - returns: a Path were the vector gives the path order and the double give the weight
//  - note: the all-pairs distance matrix is stored and stable until alteration of the graph,
//          at which point it will 
template <typename G>
double BoostGraph_i<G>::allPairsShortestPathsJohnson(int nodeIdStart, int nodeIdEnd) {
  double pathWt=0.0;
  // compute all pairs matrix if needed
  if(this->_allPairsDistanceJohnson == NULL || _changed!=0) {
    if(_changed!=0) this->_fillGraph();
    int V = num_vertices(*this->boostGraph);
    this->_allPairsDistanceJohnson = new TwoDArray<double>(V,V); // the distance matrix (D)
    std::vector<double>* d = new std::vector<double>(V, std::numeric_limits < double >::max()); // path distances
    johnson_all_pairs_shortest_paths(*this->boostGraph, (*this->_allPairsDistanceJohnson), distance_map(&(*d)[0]));
  }
  
  // return path weight
  pathWt = (*this->_allPairsDistanceJohnson)[nodeIdStart][nodeIdEnd];
  return pathWt;
}
//______________________________________________________________________________ 
// Floyd-Warshall All Pairs Shortest Paths (Good for dense interaction graphs)
//  - parameters:
//    - nodeIdStart, the root node id. the paths starts from here
//    - nodeIdEnd, the end node id in the path
//  - returns: a Path were the vector gives the path order and the double give the weight
//  - note: the all-pairs distance matrix is stored and stable until alteration of the graph,
//          at which point it will 
template <typename G>
double BoostGraph_i<G>::allPairsShortestPathsFloydWarshall(int nodeIdStart, int nodeIdEnd) {
  double pathWt=0.0;
  // compute all pairs matrix if needed
  if(this->_allPairsDistanceFloydWarshall == NULL || _changed!=0) {
    if(_changed!=0) this->_fillGraph();
    int V = num_vertices(*this->boostGraph);
    this->_allPairsDistanceFloydWarshall = new TwoDArray<double>(V,V); // the distance matrix (D)
    std::vector<double>* d = new std::vector<double>(V, std::numeric_limits < double >::max()); // path distances
    floyd_warshall_all_pairs_shortest_paths(*this->boostGraph, (*this->_allPairsDistanceFloydWarshall), distance_map(&(*d)[0]));
  }
  
  // return path weight
  pathWt = (*this->_allPairsDistanceFloydWarshall)[nodeIdStart][nodeIdEnd];
  return pathWt;
}
//______________________________________________________________________________ 


#endif // _BOOSTGRAPH_I_H_





