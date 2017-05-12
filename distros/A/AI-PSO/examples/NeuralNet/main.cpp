/// \file main.cpp
/// \brief Source file for testing a simple three layer feed forward neural network class
///
/// \author Kyle Schlansker
/// \date August 2004
//////////////////////////////////////////////////////////////

#include <iostream>
#include <fstream>
#include <string>
using namespace std;

#include "NeuralNet.h"


///
/// \fn int main()
/// \brief calculates the Neural Network value from ann configuration file
///
int main(int argc, char **argv) {

    string annConfigFile = "sample.ann";
    string annDataFile   = "sample.dat";

    if(argc > 1) {
        annConfigFile = string(argv[1]);
    }
    if(argc > 2) {
        annDataFile = string(argv[2]);
    }

    int numInputs, numHidden;
    ifstream ifs;
    ifs.open(annConfigFile.data());
    if(!ifs.is_open()) {
        cerr << "Error opening neural network configuration file" << endl;
    }
    ifs  >> numInputs >> numHidden;

    string xferFunc;
    ifs >> xferFunc;

    double *dataForNet = new double[numInputs];

    ifstream ids;
    ids.open(annDataFile.data());
    if(!ids.is_open()) {
        cerr << "Error opening neural network data file" << endl;
    }
    for(int i = 0; i < numInputs; i++) {
        ids >> dataForNet[i];
    }
    ids.close();


    NeuralNet *m_ann = new NeuralNet(numInputs, numHidden, xferFunc.c_str());

    double weight;
    for(int c = 0; c < numHidden; c++) {
        for(int j = 0; j < numInputs; j++) {
            ifs >> weight;
            m_ann->setHiddenWeight(c, j, weight);
        }
    }
    for(int k = 0; k < numHidden; k++) {
        ifs >> weight;
        m_ann->setOutputWeight(k, weight);
    }
    
    for(int d = 0; d < numInputs; d++) {
        m_ann->setInput(d, dataForNet[d]);
    }

    delete [] dataForNet;

    ifs.close();
    if(ifs.is_open()) {
        cerr << "Error closing neural network configuration file" << endl;
    }

    cout << m_ann->value() << endl;

    delete m_ann;
}
