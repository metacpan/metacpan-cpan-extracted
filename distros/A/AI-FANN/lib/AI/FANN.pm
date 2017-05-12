package AI::FANN;

our $VERSION = '0.10';

use strict;
use warnings;
use Carp;

require XSLoader;
XSLoader::load('AI::FANN', $VERSION);

use Exporter qw(import);

{
    my @constants = _constants();

    our %EXPORT_TAGS = ( 'all' => [ @constants ] );
    our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

    require constant;
    for my $constant (@constants) {
        constant->import($constant, $constant);
    }
}

sub num_neurons {

    @_ == 1 or croak "Usage: AI::FANN::get_neurons(self)";

    my $self = shift;
    if (wantarray) {
        map { $self->layer_num_neurons($_) } (0 .. $self->num_layers - 1);
    }
    else {
        $self->total_neurons;
    }
}

1;
__END__

=head1 NAME

AI::FANN - Perl wrapper for the Fast Artificial Neural Network library

=head1 SYNOPSIS

Train...

  use AI::FANN qw(:all);

  # create an ANN with 2 inputs, a hidden layer with 3 neurons and an
  # output layer with 1 neuron:
  my $ann = AI::FANN->new_standard(2, 3, 1);

  $ann->hidden_activation_function(FANN_SIGMOID_SYMMETRIC);
  $ann->output_activation_function(FANN_SIGMOID_SYMMETRIC);

  # create the training data for a XOR operator:
  my $xor_train = AI::FANN::TrainData->new( [-1, -1], [-1],
                                            [-1, 1], [1],
                                            [1, -1], [1],
                                            [1, 1], [-1] );

  $ann->train_on_data($xor_train, 500000, 1000, 0.001);

  $ann->save("xor.ann");

Run...

  use AI::FANN;

  my $ann = AI::FANN->new_from_file("xor.ann");

  for my $a (-1, 1) {
    for my $b (-1, 1) {
      my $out = $ann->run([$a, $b]);
      printf "xor(%f, %f) = %f\n", $a, $b, $out->[0];
    }
  }

=head1 DESCRIPTION


  WARNING:  THIS IS A VERY EARLY RELEASE,
            MAY CONTAIN CRITICAL BUGS!!!

AI::FANN is a Perl wrapper for the Fast Artificial Neural Network
(FANN) Library available from L<http://fann.sourceforge.net>:

  Fast Artificial Neural Network Library is a free open source neural
  network library, which implements multilayer artificial neural
  networks in C with support for both fully connected and sparsely
  connected networks. Cross-platform execution in both fixed and
  floating point are supported. It includes a framework for easy
  handling of training data sets. It is easy to use, versatile, well
  documented, and fast. PHP, C++, .NET, Python, Delphi, Octave, Ruby,
  Pure Data and Mathematica bindings are available. A reference manual
  accompanies the library with examples and recommendations on how to
  use the library. A graphical user interface is also available for
  the library.

AI::FANN object oriented interface provides an almost direct map to
the C library API. Some differences have been introduced to make it
more perlish:

=over 4

=item *

Two classes are used: C<AI::FANN> that wraps the C C<struct fann> type
and C<AI::FANN::TrainData> that wraps C<struct fann_train_data>.

=item *

Prefixes and common parts on the C function names referring to those
structures have been removed. For instance C
C<fann_train_data_shuffle> becomes C<AI::FANN::TrainData::shuffle> that
will be usually called as...

  $train_data->shuffle;

=item *

Pairs of C get/set functions are wrapped in Perl with dual accessor
methods named as the attribute (and without any C<set_>/C<get_>
prefix). For instance:

  $ann->bit_fail_limit($limit); # sets the bit_fail_limit

  $bfl = $ann->bit_fail_limit;  # gets the bit_fail_limit


Pairs of get/set functions requiring additional indexing arguments are
also wrapped inside dual accessors:

  # sets:
  $ann->neuron_activation_function($layer_ix, $neuron_ix, $actfunc);

  # gets:
  $af = $ann->neuron_activation_function($layer_ix, $neuron_ix);

Important: note that on the Perl version, the optional value argument
is moved to the last position (on the C version of the C<set_> method
it is usually the second argument).

=item *

Some functions have been renamed to make the naming more consistent
and to follow Perl conventions:

  C                                      Perl
  -----------------------------------------------------------
  fann_create_from_file               => new_from_file
  fann_create_standard                => new_standard
  fann_get_num_input                  => num_inputs
  fann_get_activation_function        => neuron_activation_function
  fann_set_activation_function        => ^^^
  fann_set_activation_function_layer  => layer_activation_function
  fann_set_activation_function_hidden => hidden_activation_function
  fann_set_activation_function_output => output_activation_function

=item *

Boolean methods return true on success and undef on failure.

=item *

Any error reported from the C side is automaticaly converter to a Perl
exception. No manual error checking is required after calling FANN
functions.

=item *

Memory management is automatic, no need to call destroy methods.

=item *

Doubles are used for computations (using floats or fixed
point types is not supported).

=back

=head1 CONSTANTS

All the constants defined in the C documentation are exported from the module:

  # import all...
  use AI::FANN ':all';

  # or individual constants...
  use AI::FANN qw(FANN_TRAIN_INCREMENTAL FANN_GAUSSIAN);

The values returned from this constant subs yield the integer value on
numerical context and the constant name when used as strings.

The constants available are:

  # enum fann_train_enum:
  FANN_TRAIN_INCREMENTAL
  FANN_TRAIN_BATCH
  FANN_TRAIN_RPROP
  FANN_TRAIN_QUICKPROP

  # enum fann_activationfunc_enum:
  FANN_LINEAR
  FANN_THRESHOLD
  FANN_THRESHOLD_SYMMETRIC
  FANN_SIGMOID
  FANN_SIGMOID_STEPWISE
  FANN_SIGMOID_SYMMETRIC
  FANN_SIGMOID_SYMMETRIC_STEPWISE
  FANN_GAUSSIAN
  FANN_GAUSSIAN_SYMMETRIC
  FANN_GAUSSIAN_STEPWISE
  FANN_ELLIOT
  FANN_ELLIOT_SYMMETRIC
  FANN_LINEAR_PIECE
  FANN_LINEAR_PIECE_SYMMETRIC
  FANN_SIN_SYMMETRIC
  FANN_COS_SYMMETRIC
  FANN_SIN
  FANN_COS

  # enum fann_errorfunc_enum:
  FANN_ERRORFUNC_LINEAR
  FANN_ERRORFUNC_TANH

  # enum fann_stopfunc_enum:
  FANN_STOPFUNC_MSE
  FANN_STOPFUNC_BIT

=head1 CLASSES

The classes defined by this package are:

=head2 AI::FANN

Wraps C C<struct fann> types and provides the following methods
(consult the C documentation for a full description of their usage):

=over 4

=item AI::FANN->new_standard(@layer_sizes)

-

=item AI::FANN->new_sparse($connection_rate, @layer_sizes)

-

=item AI::FANN->new_shortcut(@layer_sizes)

-

=item AI::FANN->new_from_file($filename)

-

=item $ann->save($filename)

-

=item $ann->run($input)

C<input> is an array with the input values.

returns an array with the values on the output layer.

  $out = $ann->run([1, 0.6]);
  print "@$out\n";

=item $ann->randomize_weights($min_weight, $max_weight)

=item $ann->train($input, $desired_output)

C<$input> and C<$desired_output> are arrays.

=item $ann->test($input, $desired_output)

C<$input> and C<$desired_output> are arrays.

It returns an array with the values of the output layer.

=item $ann->reset_MSE

-

=item $ann->train_on_file($filename, $max_epochs, $epochs_between_reports, $desired_error)

-

=item $ann->train_on_data($train_data, $max_epochs, $epochs_between_reports, $desired_error)

C<$train_data> is a AI::FANN::TrainData object.

=item $ann->cascadetrain_on_file($filename, $max_neurons, $neurons_between_reports, $desired_error)

-

=item $ann->cascadetrain_on_data($train_data, $max_neurons, $neurons_between_reports, $desired_error)

C<$train_data> is a AI::FANN::TrainData object.

=item $ann->train_epoch($train_data)

C<$train_data> is a AI::FANN::TrainData object.

=item $ann->print_connections

-

=item $ann->print_parameters

-

=item $ann->cascade_activation_functions()

returns a list of the activation functions used for cascade training.

=item $ann->cascade_activation_functions(@activation_functions)

sets the list of activation function to use for cascade training.

=item $ann->cascade_activation_steepnesses()

returns a list of the activation steepnesses used for cascade training.

=item $ann->cascade_activation_steepnesses(@activation_steepnesses)

sets the list of activation steepnesses to use for cascade training.

=item $ann->training_algorithm

=item $ann->training_algorithm($training_algorithm)

-

=item $ann->train_error_function

=item $ann->train_error_function($error_function)

-

=item $ann->train_stop_function

=item $ann->train_stop_function($stop_function)

-

=item $ann->learning_rate

=item $ann->learning_rate($rate)

-

=item $ann->learning_momentum

=item $ann->learning_momentum($momentun)

-

=item $ann->bit_fail_limit

=item $ann->bit_fail_limit($bfl)

-

=item $ann->quickprop_decay

=item $ann->quickprop_decay($qpd)

-

=item $ann->quickprop_mu

=item $ann->quickprop_mu($qpmu)

-

=item $ann->rprop_increase_factor

=item $ann->rprop_increase_factor($factor)

-

=item $ann->rprop_decrease_factor

=item $ann->rprop_decrease_factor($factor)

-

=item $ann->rprop_delta_min

=item $ann->rprop_delta_min($min)

-

=item $ann->rprop_delta_max

=item $ann->rprop_delta_max($max)

-

=item $ann->num_inputs

-

=item $ann->num_outputs

-

=item $ann->total_neurons

-

=item $ann->total_connections

-

=item $ann->MSE

-

=item $ann->bit_fail

-

=item cascade_output_change_fraction

=item cascade_output_change_fraction($fraction)

-

=item $ann->cascade_output_stagnation_epochs

=item $ann->cascade_output_stagnation_epochs($epochs)

-

=item $ann->cascade_candidate_change_fraction

=item $ann->cascade_candidate_change_fraction($fraction)

-

=item $ann->cascade_candidate_stagnation_epochs

=item $ann->cascade_candidate_stagnation_epochs($epochs)

-

=item $ann->cascade_weight_multiplier

=item $ann->cascade_weight_multiplier($multiplier)

-

=item $ann->cascade_candidate_limit

=item $ann->cascade_candidate_limit($limit)

-

=item $ann->cascade_max_out_epochs

=item $ann->cascade_max_out_epochs($epochs)

-

=item $ann->cascade_max_cand_epochs

=item $ann->cascade_max_cand_epochs($epochs)

-

=item $ann->cascade_num_candidates

-

=item $ann->cascade_num_candidate_groups

=item $ann->cascade_num_candidate_groups($groups)

-

=item $ann->neuron_activation_function($layer_index, $neuron_index)

=item $ann->neuron_activation_function($layer_index, $neuron_index, $activation_function)

-

=item $ann->layer_activation_function($layer_index, $activation_function)

-

=item $ann->hidden_activation_function($layer_index, $activation_function)

-

=item $ann->output_activation_function($layer_index, $activation_function)

-

=item $ann->neuron_activation_steepness($layer_index, $neuron_index)

=item $ann->neuron_activation_steepness($layer_index, $neuron_index, $activation_steepness)

-

=item $ann->layer_activation_steepness($layer_index, $activation_steepness)

-

=item $ann->hidden_activation_steepness($layer_index, $activation_steepness)

-

=item $ann->output_activation_steepness($layer_index, $activation_steepness)

-

=item $ann->num_layers

returns the number of layers on the ANN

=item $ann->layer_num_neurons($layer_index)

return the number of neurons on layer C<$layer_index>.

=item $ann->num_neurons

return a list with the number of neurons on every layer

=back

=head2 AI::FANN::TrainData

Wraps C C<struct fann_train_data> and provides the following method:

=over 4

=item AI::FANN::TrainData->new_from_file($filename)

-

=item AI::FANN::TrainData->new($input1, $output1 [, $input2, $output2, ...])

C<$inputx> and C<$outputx> are arrays with the values of the input and
output layers.

=item AI::FANN::TrainData->new_empty($num_data, $num_inputs, $num_outputs)

returns a new AI::FANN::TrainData object of the sizes indicated on the
arguments. The initial values of the data contained inside the object
are random and should be set before using the train data object for
training an ANN.

=item $train->data($index)

returns two arrays with the values of the input and output layer
respectively for that index.

=item $train->data($index, $input, $output)

C<$input> and C<$output> are two arrays.

The input and output layers at the index C<$index> are set to the
values on these arrays.

=item $train->shuffle

-

=item $train->scale_input($new_min, $new_max)

-

=item $train->scale_output($new_min, $new_max)

-

=item $train->scale($new_min, $new_max)

-

=item $train->subset($pos, $length)

-

=item $train->num_inputs

-

=item $train->num_outputs

-

=item $train->length

-

=back

=head1 INSTALLATION

See the README file for instruction on installing this module.

=head1 BUGS

Only tested on Linux.

I/O is not performed through PerlIO because the C library doesn't have
the required infrastructure to do that.

Send bug reports to my email address or use the CPAN RT system.

=head1 SEE ALSO

FANN homepage at L<http://leenissen.dk/fann/index.php>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Salvador FandiE<ntilde>o
(sfandino@yahoo.com).

This Perl module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either Perl version
5.8.8 or, at your option, any later version of Perl 5 you may have
available.

The Fast Artificial Neural Network Library (FANN)
Copyright (C) 2003-2006 Steffen Nissen (lukesky@diku.dk) and others.

Distributed under the GNU Lesser General Public License.

=cut
