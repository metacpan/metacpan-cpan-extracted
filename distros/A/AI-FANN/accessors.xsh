
MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

enum fann_train_enum
accessor_training_algorithm(self, value = NO_INIT)
    struct fann * self;
    enum fann_train_enum value
  CODE:
    if (items > 1) {
        fann_set_training_algorithm(self, value);
    }
    RETVAL = fann_get_training_algorithm(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

enum fann_errorfunc_enum
accessor_train_error_function(self, value = NO_INIT)
    struct fann * self;
    enum fann_errorfunc_enum value
  CODE:
    if (items > 1) {
        fann_set_train_error_function(self, value);
    }
    RETVAL = fann_get_train_error_function(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

enum fann_stopfunc_enum
accessor_train_stop_function(self, value = NO_INIT)
    struct fann * self;
    enum fann_stopfunc_enum value
  CODE:
    if (items > 1) {
        fann_set_train_stop_function(self, value);
    }
    RETVAL = fann_get_train_stop_function(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_learning_rate(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_learning_rate(self, value);
    }
    RETVAL = fann_get_learning_rate(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_learning_momentum(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_learning_momentum(self, value);
    }
    RETVAL = fann_get_learning_momentum(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

fann_type
accessor_bit_fail_limit(self, value = NO_INIT)
    struct fann * self;
    fann_type value
  CODE:
    if (items > 1) {
        fann_set_bit_fail_limit(self, value);
    }
    RETVAL = fann_get_bit_fail_limit(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_quickprop_decay(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_quickprop_decay(self, value);
    }
    RETVAL = fann_get_quickprop_decay(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_quickprop_mu(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_quickprop_mu(self, value);
    }
    RETVAL = fann_get_quickprop_mu(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_rprop_increase_factor(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_rprop_increase_factor(self, value);
    }
    RETVAL = fann_get_rprop_increase_factor(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_rprop_decrease_factor(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_rprop_decrease_factor(self, value);
    }
    RETVAL = fann_get_rprop_decrease_factor(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_rprop_delta_min(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_rprop_delta_min(self, value);
    }
    RETVAL = fann_get_rprop_delta_min(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_rprop_delta_max(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_rprop_delta_max(self, value);
    }
    RETVAL = fann_get_rprop_delta_max(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_num_inputs(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_num_input(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_num_outputs(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_num_output(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_total_neurons(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_total_neurons(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_total_connections(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_total_connections(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_connection_rate(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_connection_rate(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_MSE(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_MSE(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_bit_fail(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_bit_fail(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_cascade_output_change_fraction(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_cascade_output_change_fraction(self, value);
    }
    RETVAL = fann_get_cascade_output_change_fraction(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_cascade_output_stagnation_epochs(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_cascade_output_stagnation_epochs(self, value);
    }
    RETVAL = fann_get_cascade_output_stagnation_epochs(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

double
accessor_cascade_candidate_change_fraction(self, value = NO_INIT)
    struct fann * self;
    double value
  CODE:
    if (items > 1) {
        fann_set_cascade_candidate_change_fraction(self, value);
    }
    RETVAL = fann_get_cascade_candidate_change_fraction(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_cascade_candidate_stagnation_epochs(self, value = NO_INIT)
    struct fann * self;
    unsigned int value
  CODE:
    if (items > 1) {
        fann_set_cascade_candidate_stagnation_epochs(self, value);
    }
    RETVAL = fann_get_cascade_candidate_stagnation_epochs(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

fann_type
accessor_cascade_weight_multiplier(self, value = NO_INIT)
    struct fann * self;
    fann_type value
  CODE:
    if (items > 1) {
        fann_set_cascade_weight_multiplier(self, value);
    }
    RETVAL = fann_get_cascade_weight_multiplier(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

fann_type
accessor_cascade_candidate_limit(self, value = NO_INIT)
    struct fann * self;
    fann_type value
  CODE:
    if (items > 1) {
        fann_set_cascade_candidate_limit(self, value);
    }
    RETVAL = fann_get_cascade_candidate_limit(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_cascade_max_out_epochs(self, value = NO_INIT)
    struct fann * self;
    unsigned int value
  CODE:
    if (items > 1) {
        fann_set_cascade_max_out_epochs(self, value);
    }
    RETVAL = fann_get_cascade_max_out_epochs(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_cascade_max_cand_epochs(self, value = NO_INIT)
    struct fann * self;
    unsigned int value
  CODE:
    if (items > 1) {
        fann_set_cascade_max_cand_epochs(self, value);
    }
    RETVAL = fann_get_cascade_max_cand_epochs(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_cascade_num_candidates(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_cascade_num_candidates(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_cascade_num_candidate_groups(self, value = NO_INIT)
    struct fann * self;
    unsigned int value
  CODE:
    if (items > 1) {
        fann_set_cascade_num_candidate_groups(self, value);
    }
    RETVAL = fann_get_cascade_num_candidate_groups(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

enum fann_activationfunc_enum
accessor_neuron_activation_function(self, layer, neuron_index, value = NO_INIT)
    struct fann * self;
    unsigned int layer;
    unsigned int neuron_index;
    enum fann_activationfunc_enum value
  CODE:
    if (items > 3) {
        fann_set_activation_function(self, value, layer, neuron_index);
    }
    RETVAL = fann_get_activation_function(self, layer, neuron_index);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_
void
accessor_layer_activation_function(self, layer, value)
    struct fann * self;
    unsigned int layer;
    enum fann_activationfunc_enum value;
  CODE:
    fann_set_activation_function_layer(self, value, layer);
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_
void
accessor_hidden_activation_function(self, value)
    struct fann * self;
    enum fann_activationfunc_enum value;
  CODE:
    fann_set_activation_function_hidden(self, value);
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_
void
accessor_output_activation_function(self, value)
    struct fann * self;
    enum fann_activationfunc_enum value;
  CODE:
    fann_set_activation_function_output(self, value);
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

fann_type
accessor_neuron_activation_steepness(self, layer, neuron, value = NO_INIT)
    struct fann * self;
    unsigned int layer;
    unsigned int neuron;
    fann_type value
  CODE:
    if (items > 3) {
        fann_set_activation_steepness(self, value, layer, neuron);
    }
    RETVAL = fann_get_activation_steepness(self, layer, neuron);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_
void
accessor_layer_activation_steepness(self, layer, value)
    struct fann * self;
    unsigned int layer;
    fann_type value;
  CODE:
    fann_set_activation_steepness_layer(self, value, layer);
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_
void
accessor_hidden_activation_steepness(self, value)
    struct fann * self;
    fann_type value;
  CODE:
    fann_set_activation_steepness_hidden(self, value);
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_
void
accessor_output_activation_steepness(self, value)
    struct fann * self;
    fann_type value;
  CODE:
    fann_set_activation_steepness_output(self, value);
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_layer_num_neurons(self, layer)
	struct fann * self;
    unsigned int layer;
  CODE:
    RETVAL = fann_get_num_neurons(self, layer);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN    PREFIX = accessor_

unsigned int
accessor_num_layers(self)
	struct fann * self;
  CODE:
    RETVAL = fann_get_num_layers(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN::TrainData    PREFIX = accessor_

unsigned int
accessor_num_inputs(self)
	struct fann_train_data * self;
  CODE:
    RETVAL = fann_train_data_num_input(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN::TrainData    PREFIX = accessor_

unsigned int
accessor_num_outputs(self)
	struct fann_train_data * self;
  CODE:
    RETVAL = fann_train_data_num_output(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);


MODULE = AI::FANN    PACKAGE = AI::FANN::TrainData    PREFIX = accessor_

unsigned int
accessor_length(self)
	struct fann_train_data * self;
  CODE:
    RETVAL = fann_train_data_length(self);
  OUTPUT:
    RETVAL
  CLEANUP:
    _check_error(aTHX_ (struct fann_error *)self);

