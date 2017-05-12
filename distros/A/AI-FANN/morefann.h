
#include <doublefann.h>

void
fann_train_data_set(struct fann_train_data *data, unsigned int ix,
					fann_type *input, fann_type *output );

struct fann_train_data *
fann_train_data_create(unsigned int num_data,
					   unsigned int num_input, unsigned int num_output);


struct fann_layer*
fann_get_layer(struct fann *ann, int layer);

struct fann_neuron*
fann_get_neuron_layer(struct fann *ann, struct fann_layer* layer, int neuron);

struct fann_neuron*
fann_get_neuron(struct fann *ann, unsigned int layer, int neuron);

/*
enum fann_activationfunc_enum
fann_get_activation_function(struct fann *ann, unsigned int layer, int neuron);
*/

/*
unsigned int
fann_get_num_layers(struct fann *ann);
*/

unsigned int
fann_get_num_neurons(struct fann *ann, unsigned int layer_index);
