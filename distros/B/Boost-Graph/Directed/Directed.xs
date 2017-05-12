#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef do_open
#undef do_close
#undef apply
#undef ref
#ifdef __cplusplus
} 
#endif
//____________________________________________________________________________________________________
// C++
#undef list
#include <iostream>
#include <algorithm>
#include <boost/config.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/property_map.hpp>
#include <string>
#include "BoostGraph_i.h"
#include <list>

using namespace std;
using namespace boost;

typedef property<edge_weight_t, double> Weight;
typedef adjacency_list<vecS, vecS, directedS,
    no_property, Weight> DirectedGraph;
typedef std::pair<std::vector<int>, double> Path;   
  
class BoostGraph {
public:
	BoostGraph_i<DirectedGraph>* BGi;

	BoostGraph() {
		this->BGi = new BoostGraph_i<DirectedGraph>;
	}
	~BoostGraph() {
//		delete BGi;
	}

	bool _addNode(int nodeId) {
		bool ret = BGi->addNode(nodeId);
//		cout << "_addNode(" << nodeId << ")\n";
		return ret;
	}

	bool _addEdge(int nodeIdSource, int nodeIdSink, double weightVal) {
		bool ret = BGi->addEdge(nodeIdSource, nodeIdSink, weightVal);
//		cout << "_addEdge(" << nodeIdSource <<","<< nodeIdSink <<","<< weightVal << ")\n";
		return ret;
	}	

	double allPairsShortestPathsJohnson(int nodeIdStart, int nodeIdEnd) {
		double ret = BGi->allPairsShortestPathsJohnson(nodeIdStart,nodeIdEnd);
		return ret;
	}

};    

//____________________________________________________________________________________________________
// C-Perl tying
MODULE = Boost::Graph::Directed		PACKAGE = Boost::Graph::Directed		

BoostGraph * 
BoostGraph::new()
 
void 
BoostGraph::DESTROY()

bool 
BoostGraph::_addNode(int nodeId)

bool 
BoostGraph::_addEdge(int nodeIdSource, int nodeIdSink, double weightVal)

void
BoostGraph::breadthFirstSearch(int startNodeId)
PPCODE:
	std::vector<int> bfs = THIS->BGi->breadthFirstSearch(startNodeId);
	for(unsigned int i=0; i<bfs.size(); i++) {
		XPUSHs(sv_2mortal(newSVnv(bfs[i])));
	}	

void
BoostGraph::depthFirstSearch(int startNodeId)
PPCODE:
	std::vector<int> dfs = THIS->BGi->depthFirstSearch(startNodeId);
	for(unsigned int i=0; i<dfs.size(); i++) {
		XPUSHs(sv_2mortal(newSVnv(dfs[i])));
	}	
	
void
BoostGraph::dijkstraShortestPath(int nodeIdStart, int nodeIdEnd)
PPCODE:
	Path pInfo = THIS->BGi->dijkstraShortestPath(nodeIdStart, nodeIdEnd);
	XPUSHs(sv_2mortal(newSVnv(pInfo.second))); // the path weight
	for(unsigned int i=0; i<pInfo.first.size(); i++) {
		XPUSHs(sv_2mortal(newSVnv(pInfo.first[i]))); // nodes in the path
	}

double 
BoostGraph::allPairsShortestPathsJohnson(int nodeIdStart, int nodeIdEnd)
