
#include "morefann.h"
#include <string.h>

static fann_type **allocvv(unsigned int n1, unsigned int n2) {
	fann_type **ptr = (fann_type **)malloc(n1 * sizeof(fann_type *));
	fann_type *v = (fann_type *)malloc(n1 * n2 * sizeof(fann_type));
	if (ptr && v) {
		unsigned int i;
		for (i = 0; i < n1; i++) {
			ptr[i] = v + i * n2;
		}
		return ptr;
	}
	return 0;
}

struct fann_train_data *
fann_train_data_create(unsigned int num_data, unsigned int num_input, unsigned int num_output) {
	struct fann_train_data *data = (struct fann_train_data *)calloc(1, sizeof(*data));
	if (data) {
		fann_init_error_data((struct fann_error *)data);
		data->input = allocvv(num_data, num_input);
		data->output = allocvv(num_data, num_output);
		if (data->input && data->output) {
			data->num_data = num_data;
			data->num_input = num_input;
			data->num_output = num_output;
			return data;
		}
	}
	return 0;
}

void
fann_train_data_set(struct fann_train_data *data, unsigned int ix,
					fann_type *input, fann_type *output ) {
	if (ix < data->num_data) {
		memcpy(data->input[ix], input, data->num_input * sizeof(fann_type));
		memcpy(data->output[ix], output, data->num_output * sizeof(fann_type));
	}
	else {
		fann_error((struct fann_error *)data, FANN_E_INDEX_OUT_OF_BOUND, ix);
	}
}

/*
enum fann_activationfunc_enum
fann_get_activation_function(struct fann *ann, unsigned int layer, int neuron_index) {
    struct fann_neuron *neuron = fann_get_neuron(ann, layer, neuron_index);
    if (neuron) {
        return neuron->activation_function;
    }
    return 0;
}
*/

/*
fann_type
fann_get_activation_steepness(struct fann *ann, unsigned int layer, int neuron_index) {
    struct fann_neuron *neuron = fann_get_neuron(ann, layer, neuron_index);
    if (neuron) {
        return neuron->activation_steepness;
    }
    return 0;
}
*/

/*
unsigned int
fann_get_num_layers(struct fann *ann) {
    return ann->last_layer - ann->first_layer;
}
*/

unsigned int
fann_get_num_neurons(struct fann *ann, unsigned int layer_index) {
    struct fann_layer * layer = fann_get_layer(ann, layer_index);
    if (layer) {
        return layer->last_neuron - layer->first_neuron;
    }
    return 0;
}
