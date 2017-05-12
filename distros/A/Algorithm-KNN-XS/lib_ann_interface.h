#ifndef _LibANNInterface_h_
#define _LibANNInterface_h_

#include <algorithm>
#include <exception>
#include <iostream>
#include <sstream>
#include <vector>

#include <ANN/ANN.h> // http://www.cs.umd.edu/~mount/ANN/
#include <ANN/ANNperf.h> // http://www.cs.umd.edu/~mount/ANN/

using namespace std;

class InvalidParameterValueException : public std::exception {
    public:
        explicit InvalidParameterValueException(const std::string& what) : m_what(what) {}
        virtual ~InvalidParameterValueException() throw() {}
        virtual const char * what() const throw() {
            return m_what.c_str();
        }

    private:
        std::string m_what;
};

// libANN can do a exit(1) if a a given dump file is incorrect

class LibANNInterface {
    public:
        LibANNInterface(std::vector< std::vector<double> >&, string&, bool, int, int, int);
        ~LibANNInterface();

        void set_annMaxPtsVisit(int);
        std::vector< std::vector<double> > annkSearch(std::vector<double>&, int, double);
        std::vector< std::vector<double> > annkPriSearch(std::vector<double>&, int, double);
        std::vector< std::vector<double> > annkFRSearch(std::vector<double>&, int, double, double);
        int annCntNeighbours(std::vector<double>&, double, double);
        int theDim();
        int nPoints();
        std::string Print(bool);
        std::string Dump(bool);
        std::vector<double> getStats();

    private:
        std::vector< std::vector<double> > ann_search(std::vector<double>&, int, double, bool);
        int dim, count_data_pts;
        bool is_bd_tree;
        ANNpointArray data_pts;
        ANNkd_tree* kd_tree;
        ANNbd_tree* bd_tree;
};

#endif

