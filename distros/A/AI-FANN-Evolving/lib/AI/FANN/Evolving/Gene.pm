package AI::FANN::Evolving::Gene;
use strict;
use warnings;
use List::Util 'shuffle';
use File::Temp 'tempfile';
use Scalar::Util 'refaddr';
use AI::FANN::Evolving;
use Algorithm::Genetic::Diploid::Gene;
use base 'Algorithm::Genetic::Diploid::Gene';
use Data::Dumper;

my $log = __PACKAGE__->logger;

=head1 NAME

AI::FANN::Evolving::Gene - gene that codes for an artificial neural network (ANN)

=head1 METHODS

=over

=item new

Constructor is passed named arguments. Instantiates a trained L<AI::FANN::Evolving> ANN

=cut

sub new {

	# initialize self up the inheritance tree
	my $self = shift->SUPER::new(@_);
			
	# instantiate and train the FANN object
	my $traindata = $self->experiment->traindata;
	$self->ann( AI::FANN::Evolving->new( 'data' => $traindata ) );
	return $self;
}

=item ann

Getter/setter for an L<AI::FANN::Evolving> ANN

=cut

sub ann {
	my $self = shift;
	if ( @_ ) {
		my $ann = shift;	
		$log->debug("setting ANN $ann");
		return $self->{'ann'} = $ann;
	}
	else {
		$log->debug("getting ANN");
		return $self->{'ann'};
	}
}

=item make_function

Returns a code reference to the fitness function, which when executed returns a fitness
value and writes the corresponding ANN to file

=cut

sub make_function {
	my $self = shift;
	my $ann = $self->ann;
	my $error_func = $self->experiment->error_func;
	$log->debug("making fitness function");
	
	# build the fitness function
	return sub {		
	
		# train the AI
		$ann->train( $self->experiment->traindata );
	
		# isa TrainingData object, this is what we need to use
		# to make our prognostications. It is a different data 
		# set (out of sample) than the TrainingData object that
		# the AI was trained on.
		my $env = shift;		
		
		# this is a number which we try to keep as near to zero
		# as possible
		my $fitness = 0;
		
		# iterate over the list of input/output pairs
		for my $i ( 0 .. ( $env->length - 1 ) ) {
			my ( $input, $expected ) = $env->data($i);
			my $observed = $ann->run($input);
			
			use Data::Dumper;
			$log->debug("Observed: ".Dumper($observed));
			$log->debug("Expected: ".Dumper($expected));
			
			# invoke the error_func provided by the experiment
			$fitness += $error_func->($observed,$expected);
		}
		$fitness /= $env->length;
		
		# store result
		$self->{'fitness'} = $fitness;

		# store the AI		
		my $outfile = $self->experiment->workdir . "/${fitness}.ann";
		$self->ann->save($outfile);
		return $self->{'fitness'};
	}
}

=item fitness

Stores the fitness value after expressing the fitness function

=cut

sub fitness { shift->{'fitness'} }

=item clone

Clones the object

=cut

sub clone {
	my $self = shift;
	my $ann = delete $self->{'ann'};
	my $ann_clone = $ann->clone;
	my $self_clone = $self->SUPER::clone;
	$self_clone->ann( $ann_clone );
	$self->ann( $ann );
	return $self_clone;
}

=item mutate

Mutates the ANN by stochastically altering its properties in proportion to 
the mutation_rate

=back

=cut

sub mutate {
	my $self = shift;
	
	# probably 0.05
	my $mu = $self->experiment->mutation_rate;

	# make a clone, whose untrained ANN properties are mutated
	my $self_clone = $self->clone;
	my $ann = AI::FANN::Evolving->new( 'ann' => $self->ann );
	$ann->mutate($mu);
	$self_clone->ann($ann);
	
	return $self_clone;
}

1;
