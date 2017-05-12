package AI::FANN::Evolving::Experiment;
use strict;
use warnings;
use AI::FANN ':all';
use AI::FANN::Evolving;
use File::Temp 'tempfile';
use Algorithm::Genetic::Diploid;
use base 'Algorithm::Genetic::Diploid::Experiment';

my $log = __PACKAGE__->logger;

=head1 NAME

AI::FANN::Evolving::Experiment - an experiment in evolving artificial intelligence

=head1 METHODS

=over

=item new

Constructor takes named arguments, sets default factory to L<AI::FANN::Evolving::Factory>

=cut

sub new { shift->SUPER::new( 'factory' => AI::FANN::Evolving::Factory->new, @_ ) }

=item workdir

Getter/Setter for the workdir where L<AI::FANN> artificial neural networks will be
written during the experiment. The files will be named after the ANN's error, which 
needs to be minimized.

=cut

sub workdir {
	my $self = shift;
	if ( @_ ) {
		my $value = shift;
		$log->info("assigning new workdir $value");
		$self->{'workdir'} = $value;
	}
	else {
		$log->debug("retrieving workdir");
	}
	return $self->{'workdir'};
}

=item traindata

Getter/setter for the L<AI::FANN::TrainData> object.

=cut

sub traindata {
	my $self = shift;
	if ( @_ ) {
		my $value = shift;
		$log->info("assigning new traindata $value");
		$self->{'traindata'} = $value;
	}
	else {
		$log->debug("retrieving traindata");
	}
	return $self->{'traindata'};
}

=item run

Runs the experiment!

=cut

sub run {
	my $self = shift;
	my $log = $self->logger;
	
	$log->info("going to run experiment");
	my @results;
	for my $i ( 1 .. $self->ngens ) {
	
		# modify workdir
		my $wd = $self->{'workdir'};
		$wd =~ s/\d+$/$i/;
		$self->{'workdir'} = $wd;
		mkdir $wd;
		
		my $optimum = $self->optimum($i);
		
		$log->debug("optimum at generation $i is $optimum");
		my ( $fittest, $fitness ) = $self->population->turnover($i,$self->env,$optimum);
		push @results, [ $fittest, $fitness ];
	}
	my ( $fittest, $fitness ) = map { @{ $_ } } sort { $a->[1] <=> $b->[1] } @results;
	return $fittest, $fitness;
}

=item optimum

The optimal fitness is zero error in the ANN's classification. This method returns 
that value: 0.

=cut

sub optimum { 0 }

sub _sign {
	my ( $obs, $exp ) = @_;
	my $fitness = 0;
	for my $i ( 0 .. $#{ $obs } ) {
		$fitness += ( ( $obs->[$i] > 0 ) xor ( $exp->[$i] > 0 ) );
	}
	return $fitness / scalar(@{$obs});
}

sub _mse {
	my ( $obs, $exp ) = @_;
	my $fitness = 0;
	for my $i ( 0 .. $#{ $obs } ) {
		$fitness += ( ( (1+$obs->[$i]) - (1+$exp->[$i]) ) ** 2 );
	}
	return $fitness / scalar(@{$obs});	
}

=item error_func

Returns a function to compute the error. Given an argument, the following can happen:
 'sign' => error is the average number of times observed and expected have different signs
 'mse'  => error is the mean squared difference between observed and expected
 CODE   => error function is the provided code reference

=back

=cut

sub error_func {
	my $self = shift;
	
	# process the argument
	if ( @_ ) {
		my $arg = shift;
		if ( ref $arg eq 'CODE' ) {
			$self->{'error_func'} = $arg;
			$log->info("using custom error function");
		}
		elsif ( $arg eq 'sign' ) {
			$self->{'error_func'} = \&_sign;
			$log->info("using sign test error function");
		}
		elsif ( $arg eq 'mse' ) {
			$self->{'error_func'} = \&_mse;
			$log->info("using MSE error function");
		}
		else {
			$log->warn("don't understand error func '$arg'");
		}
	}
	
	# map the constructor-supplied argument
	if ( $self->{'error_func'} and $self->{'error_func'} eq 'sign' ) {
		$self->{'error_func'} = \&_sign;
		$log->info("using error function 'sign'");
	}
	elsif ( $self->{'error_func'} and $self->{'error_func'} eq 'mse' ) {
		$self->{'error_func'} = \&_mse;
		$log->info("using error function 'mse'");
	}	
	
	return $self->{'error_func'} || \&_mse;
}

1;
