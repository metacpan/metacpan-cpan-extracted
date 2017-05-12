#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"

double _execute_internals ( AV* inputs, AV* neurons, AV* inputweights, AV* neuronweights ) {
    double output = 0.0;
	int i;
	int v1 = av_len(inputweights);
	int v2 = av_len(inputs);
	if (v2 < v1) {
		v1 = v2;
	}
	if (v1 >= 0) {
		for (i=0; i<=v1; i++) {
			SV** val = av_fetch(inputs, i, 0);
			SV** weight = av_fetch(inputweights, i, 0);
			output += SvNV(*val) * SvNV(*weight);
		}
	}
	int v1 = av_len(neuronweights);
	int v2 = av_len(neurons);
	if (v2 < v1) {
		v1 = v2;
	}
	if (v1 >= 0) {
		for (i=0; i<=v1; i++) {
			SV** val = av_fetch(neurons, i, 0);
			SV** weight = av_fetch(neuronweights, i, 0);
			output += SvNV(*val) * SvNV(*weight);
		}
	}
	return output;
}


MODULE = AI::ANN::Neuron_6185	PACKAGE = AI::ANN::Neuron	

PROTOTYPES: DISABLE


double
_execute_internals (inputs, neurons, inputweights, neuronweights)
	AV *	inputs
	AV *	neurons
	AV *	inputweights
	AV *	neuronweights

