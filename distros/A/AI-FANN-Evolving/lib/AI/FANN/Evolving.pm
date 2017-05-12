package AI::FANN::Evolving;
use strict;
use warnings;
use AI::FANN ':all';
use List::Util 'shuffle';
use File::Temp 'tempfile';
use AI::FANN::Evolving::Gene;
use AI::FANN::Evolving::Chromosome;
use AI::FANN::Evolving::Experiment;
use AI::FANN::Evolving::Factory;
use Algorithm::Genetic::Diploid;
use base qw'Algorithm::Genetic::Diploid::Base';

our $VERSION = '0.4';
our $AUTOLOAD;
my $log = __PACKAGE__->logger;

my %enum = (
	'train' => {
#		'FANN_TRAIN_INCREMENTAL' => FANN_TRAIN_INCREMENTAL, # only want batch training
		'FANN_TRAIN_BATCH'       => FANN_TRAIN_BATCH,
		'FANN_TRAIN_RPROP'       => FANN_TRAIN_RPROP,
		'FANN_TRAIN_QUICKPROP'   => FANN_TRAIN_QUICKPROP,	
	},
	'activationfunc' => {
		'FANN_LINEAR'                     => FANN_LINEAR,
#		'FANN_THRESHOLD'                  => FANN_THRESHOLD, # can not be used during training
#		'FANN_THRESHOLD_SYMMETRIC'        => FANN_THRESHOLD_SYMMETRIC, # can not be used during training
#		'FANN_SIGMOID'                    => FANN_SIGMOID, # range is between 0 and 1
#		'FANN_SIGMOID_STEPWISE'           => FANN_SIGMOID_STEPWISE, # range is between 0 and 1
		'FANN_SIGMOID_SYMMETRIC'          => FANN_SIGMOID_SYMMETRIC,
		'FANN_SIGMOID_SYMMETRIC_STEPWISE' => FANN_SIGMOID_SYMMETRIC_STEPWISE,
#		'FANN_GAUSSIAN'                   => FANN_GAUSSIAN, # range is between 0 and 1
		'FANN_GAUSSIAN_SYMMETRIC'         => FANN_GAUSSIAN_SYMMETRIC,
		'FANN_GAUSSIAN_STEPWISE'          => FANN_GAUSSIAN_STEPWISE,
#		'FANN_ELLIOT'                     => FANN_ELLIOT, # range is between 0 and 1
		'FANN_ELLIOT_SYMMETRIC'           => FANN_ELLIOT_SYMMETRIC,
#		'FANN_LINEAR_PIECE'               => FANN_LINEAR_PIECE, # range is between 0 and 1
		'FANN_LINEAR_PIECE_SYMMETRIC'     => FANN_LINEAR_PIECE_SYMMETRIC,
		'FANN_SIN_SYMMETRIC'              => FANN_SIN_SYMMETRIC,
		'FANN_COS_SYMMETRIC'              => FANN_COS_SYMMETRIC,
#		'FANN_SIN'                        => FANN_SIN, # range is between 0 and 1
#		'FANN_COS'                        => FANN_COS, # range is between 0 and 1
	},
	'errorfunc' => {
		'FANN_ERRORFUNC_LINEAR' => FANN_ERRORFUNC_LINEAR,
		'FANN_ERRORFUNC_TANH'   => FANN_ERRORFUNC_TANH,	
	},
	'stopfunc' => {
		'FANN_STOPFUNC_MSE' => FANN_STOPFUNC_MSE,
#		'FANN_STOPFUNC_BIT' => FANN_STOPFUNC_BIT,
	}	
);

my %constant;
for my $hashref ( values %enum ) {
	while( my ( $k, $v ) = each %{ $hashref } ) {
		$constant{$k} = $v;
	}
}

my %default = (
	'error'               => 0.0001,
	'epochs'              => 5000,
	'train_type'          => 'ordinary',
	'epoch_printfreq'     => 100,
	'neuron_printfreq'    => 0,
	'neurons'             => 15,
	'activation_function' => FANN_SIGMOID_SYMMETRIC,
);

=head1 NAME

AI::FANN::Evolving - artificial neural network that evolves

=head1 METHODS

=over

=item new

Constructor requires 'file', or 'data' and 'neurons' arguments. Optionally takes 
'connection_rate' argument for sparse topologies. Returns a wrapper around L<AI::FANN>.

=cut

sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = {};
	bless $self, $class;
	$self->_init(%args);
	
	# de-serialize from a file
	if ( my $file = $args{'file'} ) {
		$self->{'ann'} = AI::FANN->new_from_file($file);
		$log->debug("instantiating from file $file");
		return $self;
	}
	
	# build new topology from input data
	elsif ( my $data = $args{'data'} ) {
		$log->debug("instantiating from data $data");
		$data = $data->to_fann if $data->isa('AI::FANN::Evolving::TrainData');
		
		# prepare arguments
		my $neurons = $args{'neurons'} || ( $data->num_inputs + 1 );
		my @sizes = ( 
			$data->num_inputs, 
			$neurons,
			$data->num_outputs
		);
		
		# build topology
		if ( $args{'connection_rate'} ) {
			$self->{'ann'} = AI::FANN->new_sparse( $args{'connection_rate'}, @sizes );
		}
		else {
			$self->{'ann'} = AI::FANN->new_standard( @sizes );
		}
		
		# finalize the instance
		return $self;
	}
	
	# build new ANN using argument as a template
	elsif ( my $ann = $args{'ann'} ) {
		$log->debug("instantiating from template $ann");
		
		# copy the wrapper properties
		%{ $self } = %{ $ann };
		
		# instantiate the network dimensions
		$self->{'ann'} = AI::FANN->new_standard(
			$ann->num_inputs, 
			$ann->num_inputs + 1,
			$ann->num_outputs,
		);
		
		# copy the AI::FANN properties
		$ann->template($self->{'ann'});
		return $self;
	}
	else {
		die "Need 'file', 'data' or 'ann' argument!";
	}
}

=item template

Uses the object as a template for the properties of the argument, e.g.
$ann1->template($ann2) applies the properties of $ann1 to $ann2

=cut

sub template {
	my ( $self, $other ) = @_;
	
	# copy over the simple properties
	$log->debug("copying over simple properties");
	my %scalar_properties = __PACKAGE__->_scalar_properties;
	for my $prop ( keys %scalar_properties ) {
		my $val = $self->$prop;
		$other->$prop($val);
	}
	
	# copy over the list properties
	$log->debug("copying over list properties");
	my %list_properties = __PACKAGE__->_list_properties;
	for my $prop ( keys %list_properties ) {
		my @values = $self->$prop;
		$other->$prop(@values);
	}
	
	# copy over the layer properties
	$log->debug("copying over layer properties");
	my %layer_properties = __PACKAGE__->_layer_properties;
	for my $prop ( keys %layer_properties ) {
		for my $i ( 0 .. $self->num_layers - 1 ) {
			for my $j ( 0 .. $self->layer_num_neurons($i) - 1 ) {
				my $val = $self->$prop($i,$j);
				$other->$prop($i,$j,$val);			
			}
		}
	}
	return $self;
}

=item recombine

Recombines (exchanges) properties between the two objects at the provided rate, e.g.
$ann1->recombine($ann2,0.5) means that on average half of the object properties are
exchanged between $ann1 and $ann2

=cut

sub recombine {
	my ( $self, $other, $rr ) = @_;
	
	# recombine the simple properties
	my %scalar_properties = __PACKAGE__->_scalar_properties;
	for my $prop ( keys %scalar_properties ) {
		if ( rand(1) < $rr ) {			
			my $vals = $self->$prop;
			my $valo = $other->$prop;
			$other->$prop($vals);
			$self->$prop($valo);
		}
	}
	
	# copy over the list properties
	my %list_properties = __PACKAGE__->_list_properties;
	for my $prop ( keys %list_properties ) {
		if ( rand(1) < $rr ) {
			my @values = $self->$prop;
			my @valueo = $other->$prop;
			$other->$prop(@values);
			$self->$prop(@valueo);
		}
	}
	
	# copy over the layer properties
	my %layer_properties = __PACKAGE__->_layer_properties;
	for my $prop ( keys %layer_properties ) {
		for my $i ( 0 .. $self->num_layers - 1 ) {
			for my $j ( 0 .. $self->layer_num_neurons($i) - 1 ) {
				my $val = $self->$prop($i,$j);
				$other->$prop($i,$j,$val);			
			}
		}
	}
	return $self;	
}

=item mutate

Mutates the object by the provided mutation rate

=cut

sub mutate {
	my ( $self, $mu ) = @_;
	$log->debug("going to mutate at rate $mu");
	
	# mutate the simple properties
	$log->debug("mutating scalar properties");
	my %scalar_properties = __PACKAGE__->_scalar_properties;
	for my $prop ( keys %scalar_properties ) {
		my $handler = $scalar_properties{$prop};
		my $val = $self->$prop;
		if ( ref $handler ) {
			$self->$prop( $handler->($val,$mu) );
		}
		else {
			$self->$prop( _mutate_enum($handler,$val,$mu) );
		}
	}	
	
	# mutate the list properties
	$log->debug("mutating list properties");
	my %list_properties = __PACKAGE__->_list_properties;
	for my $prop ( keys %list_properties ) {
		my $handler = $list_properties{$prop};		
		my @values = $self->$prop;
		if ( ref $handler ) {
			$self->$prop( map { $handler->($_,$mu) } @values );
		}
		else {
			$self->$prop( map { _mutate_enum($handler,$_,$mu) } @values );
		}		
	}	
	
	# mutate the layer properties
	$log->debug("mutating layer properties");
	my %layer_properties = __PACKAGE__->_layer_properties;
	for my $prop ( keys %layer_properties ) {
		my $handler = $layer_properties{$prop};
		for my $i ( 1 .. $self->num_layers ) {
			for my $j ( 1 .. $self->layer_num_neurons($i) ) {
				my $val = $self->$prop($i,$j);
				if ( ref $handler ) {
					$self->$prop( $handler->($val,$mu) );
				}
				else {
					$self->$prop( _mutate_enum($handler,$val,$mu) );
				}
			}
		}
	}
	return $self;
}

sub _mutate_double {
	my ( $value, $mu ) = @_;
	my $scale = 1 + ( rand( 2 * $mu ) - $mu );
	return $value * $scale;
}

sub _mutate_int {
	my ( $value, $mu ) = @_;
	if ( rand(1) < $mu ) {
		my $inc = ( int(rand(2)) * 2 ) - 1;
		while( ( $value < 0 ) xor ( ( $value + $inc ) < 0 ) ) {
			$inc = ( int(rand(2)) * 2 ) - 1;
		}
		return $value + $inc;
	}
	return $value;
}

sub _mutate_enum {
	my ( $enum_name, $value, $mu ) = @_;
	if ( rand(1) < $mu ) {
		my ($newval) = shuffle grep { $_ != $value } values %{ $enum{$enum_name} };
		$value = $newval if defined $newval;
	}
	return $value;
}

sub _list_properties {
	(
#		cascade_activation_functions   => 'activationfunc',
		cascade_activation_steepnesses => \&_mutate_double,
	)
}

sub _layer_properties {
	(
#		neuron_activation_function  => 'activationfunc',
#		neuron_activation_steepness => \&_mutate_double,
	)
}

sub _scalar_properties {
	(
		training_algorithm                   => 'train',
		train_error_function                 => 'errorfunc',
		train_stop_function                  => 'stopfunc',
		learning_rate                        => \&_mutate_double,
		learning_momentum                    => \&_mutate_double,
		quickprop_decay                      => \&_mutate_double,
		quickprop_mu                         => \&_mutate_double,
		rprop_increase_factor                => \&_mutate_double,
		rprop_decrease_factor                => \&_mutate_double,
		rprop_delta_min                      => \&_mutate_double,
		rprop_delta_max                      => \&_mutate_double,
		cascade_output_change_fraction       => \&_mutate_double,
		cascade_candidate_change_fraction    => \&_mutate_double,
		cascade_output_stagnation_epochs     => \&_mutate_int,
		cascade_candidate_stagnation_epochs  => \&_mutate_int,
		cascade_max_out_epochs               => \&_mutate_int,
		cascade_max_cand_epochs              => \&_mutate_int,
		cascade_num_candidate_groups         => \&_mutate_int,
		bit_fail_limit                       => \&_mutate_double, # 'fann_type',
		cascade_weight_multiplier            => \&_mutate_double, # 'fann_type',
		cascade_candidate_limit              => \&_mutate_double, # 'fann_type',
	)
}

=item defaults

Getter/setter to influence default ANN configuration

=cut

sub defaults {
	my $self = shift;
	my %args = @_;
	for my $key ( keys %args ) {
		$log->info("setting $key to $args{$key}");
		if ( $key eq 'activation_function' ) {
			$args{$key} = $constant{$args{$key}};
		}
		$default{$key} = $args{$key};
	}
	return %default;
}

sub _init {
	my $self = shift;
	my %args = @_;
	for ( qw(error epochs train_type epoch_printfreq neuron_printfreq neurons activation_function) ) {
		$self->{$_} = $args{$_} // $default{$_};
	}
	return $self;
}

=item clone

Clones the object

=cut

sub clone {
	my $self = shift;
	$log->debug("cloning...");
	
	# we delete the reference here so we can use 
	# Algorithm::Genetic::Diploid::Base's cloning method, which
	# dumps and loads from YAML. This wouldn't work if the 
	# reference is still attached because it cannot be 
	# stringified, being an XS data structure
	my $ann = delete $self->{'ann'};
	my $clone = $self->SUPER::clone;
	
	# clone the ANN by writing it to a temp file in "FANN/FLO"
	# format and reading that back in, then delete the file
	my ( $fh, $file ) = tempfile();
	close $fh;
	$ann->save($file);
	$clone->{'ann'} = __PACKAGE__->new_from_file($file);
	unlink $file;
	
	# now re-attach the original ANN to the invocant
	$self->{'ann'} = $ann;
	
	return $clone;
}

=item train

Trains the AI on the provided data object

=cut

sub train {
	my ( $self, $data ) = @_;
	if ( $self->train_type eq 'cascade' ) {
		$log->debug("cascade training");
	
		# set learning curve
		$self->cascade_activation_functions( $self->activation_function );
		
		# train
		$self->{'ann'}->cascadetrain_on_data(
			$data,
			$self->neurons,
			$self->neuron_printfreq,
			$self->error,
		);
	}
	else {
		$log->debug("normal training");
	
		# set learning curves
		$self->hidden_activation_function( $self->activation_function );
		$self->output_activation_function( $self->activation_function );
		
		# train
		$self->{'ann'}->train_on_data(
			$data,
			$self->epochs,
			$self->epoch_printfreq,
			$self->error,
		);	
	}
}

=item enum_properties

Returns a hash whose keys are names of enums and values the possible states for the
enum

=cut

=item error

Getter/setter for the error rate. Default is 0.0001

=cut

sub error {
	my $self = shift;
	if ( @_ ) {
		my $value = shift;
		$log->debug("setting error threshold to $value");
		return $self->{'error'} = $value;
	}
	else {
		$log->debug("getting error threshold");
		return $self->{'error'};
	}
}

=item epochs

Getter/setter for the number of training epochs, default is 500000

=cut

sub epochs {
	my $self = shift;
	if ( @_ ) {
		my $value = shift;
		$log->debug("setting training epochs to $value");
		return $self->{'epochs'} = $value;
	}
	else {
		$log->debug("getting training epochs");
		return $self->{'epochs'};
	}
}

=item epoch_printfreq

Getter/setter for the number of epochs after which progress is printed. default is 1000

=cut

sub epoch_printfreq {
	my $self = shift;
	if ( @_ ) {
		my $value = shift;
		$log->debug("setting epoch printfreq to $value");
		return $self->{'epoch_printfreq'} = $value;
	}
	else {
		$log->debug("getting epoch printfreq");
		return $self->{'epoch_printfreq'}
	}
}

=item neurons

Getter/setter for the number of neurons. Default is 15

=cut

sub neurons {
	my $self = shift;
	if ( @_ ) {
		my $value = shift;
		$log->debug("setting neurons to $value");
		return $self->{'neurons'} = $value;
	}
	else {
		$log->debug("getting neurons");
		return $self->{'neurons'};
	}
}

=item neuron_printfreq

Getter/setter for the number of cascading neurons after which progress is printed. 
default is 10

=cut

sub neuron_printfreq {
	my $self = shift;
	if ( @_ ) {
		my $value = shift;
		$log->debug("setting neuron printfreq to $value");
		return $self->{'neuron_printfreq'} = $value;
	}
	else {	
		$log->debug("getting neuron printfreq");
		return $self->{'neuron_printfreq'};
	}
}

=item train_type

Getter/setter for the training type: 'cascade' or 'ordinary'. Default is ordinary

=cut

sub train_type {
	my $self = shift;
	if ( @_ ) {
		my $value = lc shift;
		$log->debug("setting train type to $value"); 
		return $self->{'train_type'} = $value;
	}
	else {
		$log->debug("getting train type");
		return $self->{'train_type'};
	}
}

=item activation_function

Getter/setter for the function that maps inputs to outputs. default is 
FANN_SIGMOID_SYMMETRIC

=back

=cut

sub activation_function {
	my $self = shift;
	if ( @_ ) {
		my $value = shift;
		$log->debug("setting activation function to $value");
		return $self->{'activation_function'} = $value;
	}
	else {
		$log->debug("getting activation function");
		return $self->{'activation_function'};
	}
}

# this is here so that we can trap method calls that need to be 
# delegated to the FANN object. at this point we're not even
# going to care whether the FANN object implements these methods:
# if it doesn't we get the normal error for unknown methods, which
# the user then will have to resolve.
sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.+://;
	
	# ignore all caps methods
	if ( $method !~ /^[A-Z]+$/ ) {
	
		# determine whether to invoke on an object or a package
		my $invocant;
		if ( ref $self ) {
			$invocant = $self->{'ann'};
		}
		else {
			$invocant = 'AI::FANN';
		}
		
		# determine whether to pass in arguments
		if ( @_ ) {
			my $arg = shift;
			$arg = $constant{$arg} if exists $constant{$arg};
			return $invocant->$method($arg);
		}
		else {		
			return $invocant->$method;
		}
	}
	
}

1;
