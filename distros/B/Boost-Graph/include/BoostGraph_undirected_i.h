/*______________________________________________________________________________
  BoostGraph_undirected_i.h
  Description: This library implements algorithms specific to ONLY undirected
  graphs.
  ______________________________________________________________________________
*/

#ifndef _BOOSTGRAPH_UNDIRECTED_I_H_
#define _BOOSTGRAPH_UNDIRECTED_I_H_

#include "BoostGraph_i.h"

#include <boost/graph/connected_components.hpp>

using namespace std;
using namespace boost;

typedef property<edge_weight_t, double> Weight;
typedef std::pair<int,int> Pair;
typedef std::pair<Pair*,double> GEdge; // Edge nodes with weight
typedef std::pair<std::vector<int>, double> Path; // Path of nodes with path weight


//______________________________________________________________________________
// CLASS DEFINITION
template <typename G>
class BoostGraph_undirected_i : public BoostGraph_i<G>
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

  int _changed; // -1 for no graph object, 0 for no change, 1 for change in graph
  BoostGraph_undirected_i();
  virtual ~BoostGraph_undirected_i();
  
  virtual std::vector<int> connectedComponents();

};

//______________________________________________________________________________
// IMPLEMENTATION
template <typename G> 
BoostGraph_undirected_i<G>::BoostGraph_undirected_i() {
}
//______________________________________________________________________________
template <typename G> 
BoostGraph_undirected_i<G>::~BoostGraph_undirected_i() {
} 
//______________________________________________________________________________ 
template <typename G>
std::vector<int> BoostGraph_undirected_i<G>::connectedComponents() {
  if(_changed!=0) this->_fillGraph();
  int N = num_vertices(*this->boostGraph);// number of nodes
  std::vector<int> component(N);  
  if (N==0) return component;
  int num = connected_components(*this->boostGraph, &component[0]);
  return component;
}
//______________________________________________________________________________



#endif // _BOOSTGRAPH_UNDIRECTED_I_H_


