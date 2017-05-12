/// \file NeuralNet.h
/// \brief Header file for simple 3 layer feed forward NeuralNet classes / DLL
/// 
/// \author Kyle Schlansker
/// \date August 2004
///////////////////////////////////////////////////////////////////////////


#include <iostream>
#include <cmath>
#include <string>
using namespace std;

#ifdef WIN32
#  ifdef NEURALNET_EXPORTS
#    define NEURALNET_API __declspec(dllexport)
#  else
#    define NEURALNET_API __declspec(dllimport)
#  endif
#else
#  define NEURALNET_API
#endif

#ifndef NEURAL_NET
#define NEURAL_NET


///
/// \class TransferFunction NeuralNet.h NeuralNet
/// \brief defines a transfer function object
/// 
class NEURALNET_API TransferFunction
{
    public:

        ///
        /// \fn TransferFunction(double val)
        /// \brief constructor
        /// \param val a double
        ///
        TransferFunction(double val = 1)
        {
        }


        ///
        /// \fn ~TransferFunction()
        /// \brief destructor
        ///
        virtual ~TransferFunction()
        {
        }


        /// 
        /// \fn virtual double compute()
        /// \brief computes the transfer function and returns result
        /// \param val a double
        /// \return double
        /// 
        virtual double compute(double val) = 0;


    protected:

        double m_value;        /// value on which to compute the transfer function
};



///
/// \class UnityGain NeuralNet.h NeuralNet
/// \brief defines a transfer function that passes its output as its input (good for input neurons)
///
class NEURALNET_API UnityGain : public TransferFunction
{
    public:
        
        ///
        /// \fn UnityGain(double val) 
        /// \brief constructor
        /// \param val a double
        ///
        UnityGain(double val = 1) : TransferFunction(val)
        {
        }


        ///
        /// \fn ~UnityGain()
        /// \brief destructor
        ///
        ~UnityGain()
        {
        }


        ///
        /// \fn compute(double val)
        /// \brief computes the transfer function by returning the input
        /// \return double
        ///
        double compute(double val)
        {
            return m_value = val;
        }
};



///
/// \class Logistic  NeuralNet.h NeuralNet
/// \brief defines the Logistic transfer function
///
class NEURALNET_API Logistic : public TransferFunction
{
    public:
        
        ///
        /// \fn Logistic()
        /// \brief constructor
        /// 
        Logistic(double val = 1) : TransferFunction(val)
        {
        }


        ///
        /// \fn ~Logistic()
        /// \brief denstructor
        /// 
        ~Logistic()
        {
        }

        
        ///
        /// \fn double compute(double val)
        /// \brief computes the Logistic function on val
        /// \return double
        double compute(double val)
        {
            m_value = 1.0 / (1.0 + exp(val));
            return m_value = val;
        }
};


///
/// \class Neuron NeuralNet.h NeuralNet
/// \brief exported class which simulates a neruon within a Neural Net
///
class NEURALNET_API Neuron
{
    public:

        ///
        /// \fn Neuron()
        /// \brief constructor
        /// \note, add flag in constructor to choose what type of TransferFunction to use
        ///
        Neuron()
        {
            m_capacity = 1;
            m_numConnections = 0;
            m_neurons = new Neuron*[m_capacity];
            m_weights = new double[m_capacity];
            m_value = 0;
            xfer = new UnityGain();
        }


        ///
        /// \fn ~Neuron()
        /// \brief destructor
        ///
        virtual ~Neuron()
        {
            delete [] m_neurons;
            delete [] m_weights;
            delete xfer;
        }

        
        ///
        /// \fn virtual double value()
        /// \brief calculates the value of the neuron.  It is virtual
        ///            because the value is calculated differently for
        ///            different types of Neurons.
        ///
        virtual double value()
        {
            for(int i = 0; i < m_numConnections; i++)
                m_value += m_neurons[i]->value() * m_weights[i];
            return m_value = xfer->compute(m_value);
        }


        ///
        /// \fn void addConnection(Neuron *neuron)
        /// \brief adds a connection to another neuron
        /// \param neuron a pointer to the connected Neuron
        ///
        void addConnection(Neuron *neuron)
        {
            checkSize();
            m_neurons[m_numConnections++] = neuron;
        }


        ///
        /// \fn void setWeight(int index, double weight)
        /// \brief sets the connection weight of connection at
        ///           index to weight
        /// \param index an int
        /// \param weight a double
        ///
        void setWeight(int index, double weight)
        {
            if(index >= 0 && index <= m_numConnections)
                m_weights[index] = weight;
        }


        ///
        /// \fn int numConnections()
        /// \brief returns the number of connections this Neuron has
        /// \return int
        ///
        int numConnections()
        {
            return m_numConnections;
        }



    protected:

        ///
        /// \fn void checkSize()
        /// \brief checks the size of the connection array for this Neuron.
        ///            if a connection needs to be added past the capacity, then
        ///            new connection array space is allocated.
        /// 
        void checkSize()
        {
            if( m_numConnections >= m_capacity )
            {
                m_capacity *= 2;
                Neuron **newNeuronArr = new Neuron*[m_capacity];
                double *newWeightArr = new double[m_capacity];

                for(int i = 0; i < m_numConnections; i++)
                {
                    newNeuronArr[i] = m_neurons[i];
                    newWeightArr[i] = m_weights[i];
                }

                delete [] m_neurons;
                delete [] m_weights;

                m_neurons = newNeuronArr;
                m_weights = newWeightArr;
            }
        }


        ///
        /// \fn double transferFunction(double val)
        /// \brief applies a transfer function to val and returns the result
        /// \param val a double
        /// \return double
        ///
        double transferFunc(double val)
        {
            return val;
        }


        int        m_numConnections;    /// number of connections to other Neurons
        int        m_capacity;        /// capacity of connection array
        Neuron **m_neurons;            /// connection array of pointers to other Neurons
        double *m_weights;            /// weight array of connections
        double    m_value;            /// value of this Neuron
        TransferFunction *xfer;        
};




/// 
/// \class Input NeuralNet.h NeuralNet
/// \brief Simulates an input neuron in a Neural net.  This class extends Neuron
///            but allows for its value to be set directly and it also overrides 
///            the virtual value function so that it returns its value directly 
///            rather than passing though a transfer function.
///
class NEURALNET_API Input : public Neuron
{
    public:


        ///
        /// \fn Input(double value)
        /// \brief constructor
        ///
        Input(double value = 0) : Neuron()
        {
            m_value = value;
        }


        ///
        /// \fn ~Input()
        /// \brief destructor
        ///
        virtual ~Input()
        {
        }


        ///
        /// \fn void setValue(double value)
        /// \brief sets the value of this input Neuron to value
        /// \param value a double
        ///
        void setValue(double value)
        {
            m_value = value;
        }


        ///
        /// \fn double value()
        /// \brief override of virtual function.
        /// \return double
        ///
//        double value()
//        {
//            return m_value;
//        }

    protected:
};



///
/// \class Hidden NeuralNet.h NeuralNet
/// \brief simulates a hidden Neuron
///
class NEURALNET_API Hidden : public Neuron
{

    public:

        ///
        /// \fn Hidden()
        /// \brief constructor which sets transfer function
        ///
        Hidden() : Neuron()
        {
//            delete xfer;
//            xfer = new Logistic();
        }


        ///
        /// \fn ~Hidden()
        /// \brief destructor
        ///
        virtual ~Hidden()
        {
        }


        ///
        /// \fn void setTransferFunction(char *xferFunc)
        /// \brief sets the transfer function for this Neuron
        ///
        void setTransferFunction(const char *xferFunc)
        {
            string xferName = string(xferFunc);
            if(xferName != "UnityGain")
            {
                if(xferName == "Logistic")
                {
                    delete xfer;
                    xfer = new Logistic();
                }
                // add if statements for each new transfer function object
            }
        }
};



///
/// \class NeuralNet NeuralNet.h NeuralNet
/// \brief Simulates a NeuralNet made up of Neurons and Input Neurons
/// 
class NEURALNET_API NeuralNet 
{
    public:

        ///
        /// \fn NeuralNet(int numInputs, int numHidden)
        /// \brief constructor
        /// \param numInputs an int
        /// \param numHidden an int
        ///
        NeuralNet(int numInputs = 3, int numHidden = 2, const char *xferFunc = "Logistic") : m_numInputs(numInputs), m_numHidden(numHidden)
        {
            m_inputs = new Input[m_numInputs];
//            m_hidden = new Neuron[m_numHidden];
            m_hidden = new Hidden[m_numHidden];
            for(int i = 0; i < m_numHidden; i++)
                m_hidden[i].setTransferFunction(xferFunc);
            m_xferFunc = string(xferFunc);
            connectionize();
        }


        ///
        /// \fn ~NeuralNet()
        /// \brief destructor 
        ///
        ~NeuralNet()
        {
            delete [] m_inputs;
            delete [] m_hidden;
        }


        ///
        /// \fn void setInput(int index, double value)
        /// \brief sets the value of the Input Neuron given by index to value
        /// \param index an int
        /// \param value a double
        ///
        void setInput(int index, double value)
        {
            if(index >= 0 && index < m_numInputs)
                m_inputs[index].setValue(value);
        }


        ///
        /// \fn void setWeightsToOne()
        /// \brief sets all of the connections weights to unity
        /// \note this is really only used for testing/debugging purposes
        ///
        void setWeightsToOne()
        {
            for(int i = 0; i < m_numHidden; i++)
                for(int j = 0; j < m_hidden[i].numConnections(); j++)
                    m_hidden[i].setWeight(j, 1.0);
            for(int k = 0; k < m_output.numConnections(); k++)
                m_output.setWeight(k, 1.0);
        }


        ///
        /// \fn double value()
        /// \brief returns the final network value 
        /// \return double
        ///
        double value()
        {
            return m_output.value();
        }


        ///
        /// \fn void setHiddenWeight(int indexHidden, int indexInput, double weight)
        /// \brief sets the connection weight between a pair of input and hidden neurons
        /// \param indexHidden an int
        /// \param indexInput an int
        /// \param weight a double
        ///
        void setHiddenWeight(int indexHidden, int indexInput, double weight)
        {
            if(indexHidden >= 0 && indexHidden < m_numHidden)
                m_hidden[indexHidden].setWeight(indexInput, weight);
        }


        ///
        /// \fn void setOutputWeight(int index, double weight)
        /// \brief sets the connection weight between a pair of hidden and output neurons
        /// \param index an int
        /// \param weight a double
        ///
        void setOutputWeight(int index, double weight)
        {
            m_output.setWeight(index, weight);
        }

/*
        void read(istream & in)
        {
            in  >> m_numInputs
                >> m_numHidden;
            
            delete [] m_inputs;
            delete [] m_hidden;

            m_inputs = new Input[m_numInputs];
            m_hidden = new Neuron[m_numHidden];
            connectionize();

            double weight;

            for(int i = 0; i < m_numHidden; i++)
                for(int j = 0; j < m_hidden[i].numConnections(); j++)
                {
                    in >> weight;
                    m_hidden[i].setWeight(j, weight);
                }
            for(int k = 0; k < m_output.numConnections(); k++)
            {
                in >> weight;
                m_output.setWeight(k, weight);
            }
            
        }

        friend istream & operator>>(istream & in, NeuralNet & ann)
        {
            ann.read(in);
            return in;
        }

        void print(ostream & out)
        {
        }
*/
    protected:

        ///
        /// \fn connectionize()
        /// \brief builds a fully connected network once the Neurons are constructed
        /// 
        void connectionize()
        {
            for(int i = 0; i < m_numInputs; i++)
                for(int j = 0; j < m_numHidden; j++)
                    m_hidden[j].addConnection(&m_inputs[i]);

            for(int k = 0; k < m_numHidden; k++)
                m_output.addConnection(&m_hidden[k]);
        }


        int        m_numInputs;    /// number of input Neurons    in network
        int        m_numHidden;    /// number of hidden Neurons in network
        Input  *m_inputs;        /// array of Input Neurons
//        Neuron *m_hidden;        /// array of hidden Neurons
        Hidden *m_hidden;        /// array of hidden Neurons
        Neuron    m_output;        /// the single output Neuron (it is more efficient to have a separate network for each output)
        string  m_xferFunc;        /// type of transfer function for hidden neurons
};

#endif
