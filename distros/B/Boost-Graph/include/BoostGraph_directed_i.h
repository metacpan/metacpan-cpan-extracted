/*______________________________________________________________________________
  BoostGraph_directed_i.h
  Description: This library implements algorithms specific to ONLY directed
  graphs.
  ______________________________________________________________________________
*/

#ifndef _BOOSTGRAPH_DIRECTED_I_H_
#define _BOOSTGRAPH_DIRECTED_I_H_

#include "BoostGraph_i.h"

using namespace std;
using namespace boost;

typedef property<edge_weight_t, double> Weight;
typedef std::pair<int,int> Pair;
typedef std::pair<Pair*,double> GEdge; // Edge nodes with weight
typedef std::pair<std::vector<int>, double> Path; // Path of nodes with path weight


//______________________________________________________________________________
// CLASS DEFINITION
template <typename G>
class BoostGraph_directed_i : public BoostGraph_i<G>
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
  BoostGraph_directed_i();
  virtual ~BoostGraph_directed_i();
  

};

//______________________________________________________________________________
// IMPLEMENTATION
template <typename G> 
BoostGraph_directed_i<G>::BoostGraph_directed_i() {
}
//______________________________________________________________________________
template <typename G> 
BoostGraph_directed_i<G>::~BoostGraph_directed_i() {
} 
//______________________________________________________________________________ 


#endif // _BOOSTGRAPH_DIRECTED_I_H_


