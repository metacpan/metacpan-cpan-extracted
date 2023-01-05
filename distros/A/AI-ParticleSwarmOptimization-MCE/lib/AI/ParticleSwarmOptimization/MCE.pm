package AI::ParticleSwarmOptimization::MCE;

use strict;
use warnings;
use base qw( 
	AI::ParticleSwarmOptimization
	Class::Accessor::Fast 
);
#-----------------------------------------------------------------------
use Clone 			qw( clone 	 	);
use List::Util 		qw( min shuffle );
use Storable;
use MCE				( Sereal => 0 );
use MCE::Map;
use MCE::Util;
#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors( qw(
	_pop
	_tpl
	_wrk
));
#-----------------------------------------------------------------------	
$Storable::Deparse 	= 1;
$Storable::Eval 	= 1;
#-----------------------------------------------------------------------
$AI::ParticleSwarmOptimization::MCE::VERSION = '1.003';
#=======================================================================
sub new {
    my ($class, %params) = @_;
    
    #-------------------------------------------------------------------
    my $self = bless {}, $class;
    $self->SUPER::setParams( %params );
    
    #-------------------------------------------------------------------
	$self->_init_mce( \%params );
	$self->_init_pop( \%params );
	$self->_init_tpl( \%params );
	
    #-------------------------------------------------------------------
    return $self;
}
#=======================================================================
sub _init_tpl {
	my ( $self, $params ) = @_;
	
	my $cln = clone( $params );
	delete $cln->{ $_ } for qw( 
		-iterCount
		-iterations	
		-numParticles 
		-workers
		
		_pop 
		_tpl 
		_wrk 
	);
	
	$self->_tpl( $cln );
	
	return;
}
#=======================================================================
sub _init_pop {
	my ( $self, $params ) = @_;
	
	my $pop = int( $self->{ numParticles } / $self->_wrk );
	my $rst = $self->{ numParticles } % $self->_wrk;
	
	my @pop = ( $pop ) x $self->_wrk;
	$pop[ 0 ] += $rst;
	
	$self->_pop( \@pop );
}
#=======================================================================
sub _init_mce {
	my ( $self, $params ) = @_;
	
	#-------------------------------------------------------------------
	$self->_wrk( $params->{ '-workers' } || MCE::Util::get_ncpu() );
	
	#-------------------------------------------------------------------
	MCE::Map->init(
		chunk_size 	=> 1,				# Thanks Roy :-)
		#chunk_size => q[auto],			# The old one. Currently it should be the same... 
		max_workers => $self->_wrk,
		posix_exit  => 1,				# Thanks Roy :-)
	);
	
	#-------------------------------------------------------------------
	return;
}
#=======================================================================
sub setParams {
	my ( $self, %params ) = @_;
	
	my $fles = __PACKAGE__->new( %params );
	
	$self->{ $_ } = $fles->{ $_ } for keys %$fles;
	
	return 1;
}
#=======================================================================
sub init {
	my ( $self ) = @_;
	
	#-------------------------------------------------------------------
	my $pop = $self->{ numParticles };
	$self->{ numParticles } = 1;
	$self->SUPER::init();
	$self->{ numParticles } = $pop;
	$self->{ prtcls } = [ ];
	
	#-------------------------------------------------------------------
	my $cnt = 0;
	my $tpl = $self->_tpl;
	
	@{ $self->{ prtcls } } = map { 
		$_->{ id } = $cnt++; 
		$_ 
	} mce_map {
		my $arg = clone( $tpl );
		$arg->{ -numParticles } = $_;
		
		my $swm = AI::ParticleSwarmOptimization->new( %$arg );
		$swm->init;
		
		@{ $swm->{ prtcls } };
		
	} @{ $self->_pop };
	
	#-------------------------------------------------------------------
	return 1;
}
#=======================================================================
sub _chunks {
	my ( $self ) = @_;
	
	#-------------------------------------------------------------------
	@{ $self->{ prtcls } } = shuffle @{ $self->{ prtcls } };
	
	#-------------------------------------------------------------------
	my @chk;
	for my $idx ( 0 .. $#{ $self->_pop } ){
		#my $cnt = 0;
		#my @tmp = map { 
		#	$_->{ id } = $cnt++; 
		#	$_ 
		#} splice @{ $self->{ prtcls } }, 0, $self->_pop->[ $idx ];
		
		# Faster and smaller memory consumption...
		my $cnt = 0;
		my @tmp = splice @{ $self->{ prtcls } }, 0, $self->_pop->[ $idx ];
		$_->{ id } = $cnt++ for @tmp;

		push @chk, \@tmp;
	}
	
	#-------------------------------------------------------------------
	return \@chk;
}
#=======================================================================
sub _updateVelocities {
    my ( $self, $iter ) = @_;

	#-------------------------------------------------------------------
    print "Iter $iter\n" if $self->{verbose} & AI::ParticleSwarmOptimization::kLogIter;

	my $tpl = $self->_tpl;

	my @lst = mce_map {
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		my $ary = $_;
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		my $arg = clone( $tpl );
		$arg->{ -numParticles } = 1;
		
		my $swm = AI::ParticleSwarmOptimization->new( %$arg );
		$swm->init;
		$swm->{ numParticles } = scalar( @$ary );
		$swm->{ prtcls } = $ary;
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		$swm->_updateVelocities( $iter );
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		[
			$swm->{ prtcls 			},
		    $swm->{ bestBest 		},
		]
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	} $self->_chunks;

	#-------------------------------------------------------------------
	#my $cnt = 0;
	#@{ $self->{ prtcls } } = map { 
	#	$_->{ id } = $cnt++; 
	#	$_ 
	#} map { 
	#	@{ $_->[ 0 ] }
	#} @lst;

	# Faster and smaller memory consumption...
	my $cnt = 0;
	@{ $self->{ prtcls } } = map { @{ $_->[ 0 ] } } @lst;
	$_->{ id } = $cnt++ for @{ $self->{ prtcls } };
	
	#-------------------------------------------------------------------
	$self->{ bestBest } = min grep { defined $_ } map { $_->[ 1 ] } @lst;
	
	#-------------------------------------------------------------------
	return;
}
#=======================================================================
sub _moveParticles {
    my ( $self, $iter ) = @_;

	#-------------------------------------------------------------------
    print "Iter $iter\n" if $self->{verbose} & AI::ParticleSwarmOptimization::kLogIter;

	my $tpl = $self->_tpl;

	my @lst = mce_map {
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		my $ary = $_;
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		my $arg = clone( $tpl );
		$arg->{ -numParticles } = 1;
		
		my $swm = AI::ParticleSwarmOptimization->new( %$arg );
		$swm->init;
		$swm->{ numParticles } = scalar( @$ary );
		$swm->{ prtcls } = $ary;
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		[
			$swm->_moveParticles( $iter ),
			$swm->{ prtcls }
		]
		#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	} $self->_chunks;

	#-------------------------------------------------------------------
	#my $cnt = 0;
	#@{ $self->{ prtcls } } = map { 
	#	$_->{ id } = $cnt++; 
	#	$_ 
	#} map { 
	#	@{ $_->[ 1 ] }
	#} @lst;

	# Faster and smaller memory consumption...
	my $cnt = 0;
	@{ $self->{ prtcls } } = map { @{ $_->[ 1 ] } } @lst;
	$_->{ id } = $cnt++ for @{ $self->{ prtcls } };

	#-------------------------------------------------------------------
	return unless grep { defined $_ } map { $_->[ 0 ] } @lst;
	return 1;
}
#=======================================================================
1;

__END__

=head1 NAME

AI::ParticleSwarmOptimization::MCE - Particle Swarm Optimization (object oriented) with support for multi-core processing

=head1 SYNOPSIS

    use AI::ParticleSwarmOptimization::MCE;

    my $pso = AI::ParticleSwarmOptimization::MCE->new (
        -fitFunc        => \&calcFit,
        -dimensions     => 3,
        -iterations     => 10,
        -numParticles   => 1000,
        
        # only for many-core version # the best if == $#cores of your system
        # selecting best value if undefined
        -workers		=> 4,							
    );
    
    my $fitValue       = $pso->optimize ();
    my ($best)         = $pso->getBestParticles (1);
    my ($fit, @values) = $pso->getParticleBestPos ($best);

    printf "Fit %.4f at (%s)\n",
        $fit, join ', ', map {sprintf '%.4f', $_} @values;

    sub calcFit {
        my @values = @_;
        my $offset = int (-@values / 2);
        my $sum;
        
        select( undef, undef, undef, 0.01 );    # Simulation of heavy processing...
    
        $sum += ($_ - $offset++) ** 2 for @values;
        return $sum;
    }
=head1 Description

This module is enhancement of on original AI::ParticleSwarmOptimization to support 
multi-core processing with use of MCE. Below you can find original documentation
of that module, but with one difference. There is new parameter "-workers", which
one can use to define of number of parallel processes that will be used during 
computations.

The Particle Swarm Optimization technique uses communication of the current best
position found between a number of particles moving over a hyper surface as a
technique for locating the best location on the surface (where 'best' is the
minimum of some fitness function). For a Wikipedia discussion of PSO see
http://en.wikipedia.org/wiki/Particle_swarm_optimization.

This pure Perl module is an implementation of the Particle Swarm Optimization
technique for finding minima of hyper surfaces. It presents an object oriented
interface that facilitates easy configuration of the optimization parameters and
(in principle) allows the creation of derived classes to reimplement all aspects
of the optimization engine (a future version will describe the replaceable
engine components).

This implementation allows communication of a local best point between a
selected number of neighbours. It does not support a single global best position
that is known to all particles in the swarm.

=head1 Methods

AI::ParticleSwarmOptimization provides the following public methods. The parameter lists shown
for the methods denote optional parameters by showing them in [].

=over 4

=item new (%parameters)

Create an optimization object. The following parameters may be used:

=over 4

=item I<-workers>: positive number, optional

The number of workers (processes), that will be used during computations. 

=item I<-dimensions>: positive number, required

The number of dimensions of the hypersurface being searched.

=item I<-exitFit>: number, optional

If provided I<-exitFit> allows early termination of optimize if the
fitness value becomes equal or less than I<-exitFit>.

=item I<-fitFunc>: required

I<-fitFunc> is a reference to the fitness function used by the search. If extra
parameters need to be passed to the fitness function an array ref may be used
with the code ref as the first array element and parameters to be passed into
the fitness function as following elements. User provided parameters are passed
as the first parameters to the fitness function when it is called:

    my $pso = AI::ParticleSwarmOptimization::MCE->new(
        -fitFunc    => [\&calcFit, $context],
        -dimensions => 3,
    );

    ...

    sub calcFit {
        my ($context, @values) = @_;
        ...
        return $fitness;
    }

In addition to any user provided parameters the list of values representing the
current particle position in the hyperspace is passed in. There is one value per
hyperspace dimension.

=item I<-inertia>: positive or zero number, optional

Determines what proportion of the previous velocity is carried forward to the
next iteration. Defaults to 0.9

See also I<-meWeight> and I<-themWeight>.

=item I<-iterations>: number, optional

Number of optimization iterations to perform. Defaults to 1000.

=item I<-meWeight>: number, optional

Coefficient determining the influence of the current local best position on the
next iterations velocity. Defaults to 0.5.

See also I<-inertia> and I<-themWeight>.

=item I<-numNeighbors>: positive number, optional

Number of local particles considered to be part of the neighbourhood of the
current particle. Defaults to the square root of the total number of particles.

=item I<-numParticles>: positive number, optional

Number of particles in the swarm. Defaults to 10 times the number of dimensions.

=item I<-posMax>: number, optional

Maximum coordinate value for any dimension in the hyper space. Defaults to 100.

=item I<-posMin>: number, optional

Minimum coordinate value for any dimension in the hyper space. Defaults to
-I<-posMax> (if I<-posMax> is negative I<-posMin> should be set more negative).

=item I<-randSeed>: number, optional

Seed for the random number generator. Useful if you want to rerun an
optimization, perhaps for benchmarking or test purposes.

=item I<-randStartVelocity>: boolean, optional

Set true to initialize particles with a random velocity. Otherwise particle
velocity is set to 0 on initalization.

A range based on 1/100th of -I<-posMax> - I<-posMin> is used for the initial
speed in each dimension of the velocity vector if a random start velocity is
used.

=item I<-stallSpeed>: positive number, optional

Speed below which a particle is considered to be stalled and is repositioned to
a new random location with a new initial speed.

By default I<-stallSpeed> is undefined but particles with a speed of 0 will be
repositioned.

=item I<-themWeight>: number, optional

Coefficient determining the influence of the neighbourhod best position on the
next iterations velocity. Defaults to 0.5.

See also I<-inertia> and I<-meWeight>.

=item I<-exitPlateau>: boolean, optional

Set true to have the optimization check for plateaus (regions where the fit
hasn't improved much for a while) during the search. The optimization ends when
a suitable plateau is detected following the burn in period.

Defaults to undefined (option disabled).

=item I<-exitPlateauDP>: number, optional

Specify the number of decimal places to compare between the current fitness
function value and the mean of the previous I<-exitPlateauWindow> values.

Defaults to 10.

=item I<-exitPlateauWindow>: number, optional

Specify the size of the window used to calculate the mean for comparison to
the current output of the fitness function.  Correlates to the minimum size of a
plateau needed to end the optimization.

Defaults to 10% of the number of iterations (I<-iterations>).

=item I<-exitPlateauBurnin>: number, optional

Determines how many iterations to run before checking for plateaus.

Defaults to 50% of the number of iterations (I<-iterations>).

=item I<-verbose>: flags, optional

If set to a non-zero value I<-verbose> determines the level of diagnostic print
reporting that is generated during optimization.

The following constants may be bitwise ored together to set logging options:

=over 4

=item * kLogBetter

prints particle details when its fit becomes bebtter than its previous best.

=item * kLogStall

prints particle details when its velocity reaches 0 or falls below the stall
threshold.

=item * kLogIter

Shows the current iteration number.

=item * kLogDetail

Shows additional details for some of the other logging options.

=item * kLogIterDetail

Shorthand for C<kLogIter | kLogIterDetail>

=back

=back

=item B<setParams (%parameters)>

Set or change optimization parameters. See I<-new> above for a description of
the parameters that may be supplied.

=item B<init ()>

Reinitialize the optimization. B<init ()> will be called during the first call
to B<optimize ()> if it hasn't already been called.

=item B<optimize ()>

Runs the minimization optimization. Returns the fit value of the best fit
found. The best possible fit is negative infinity.

B<optimize ()> may be called repeatedly to continue the fitting process. The fit
processing on each subsequent call will continue from where the last call left
off.

=item B<getParticleState ()>

Returns the vector of position

=item B<getBestParticles ([$n])>

Takes an optional count.

Returns a list containing the best $n particle numbers. If $n is not specified
only the best particle number is returned.

=item B<getParticleBestPos ($particleNum)>

Returns a list containing the best value of the fit and the vector of its point
in hyper space.

    my ($fit, @vector) = $pso->getParticleBestPos (3)

=item B<getIterationCount ()>

Return the number of iterations performed. This may be useful when the
I<-exitFit> criteria has been met or where multiple calls to I<optimize> have
been made.

=back

=head1 BUGS

None... I hope.

If any: A small script which yields the problem will probably be of help.

=head1 SEE ALSO

http://en.wikipedia.org/wiki/Particle_swarm_optimization

=head1 THANKS

Mario Roy for suggestions about efficiency.

=head1 AUTHOR

Strzelecki Lukasz <lukasz@strzeleccy.eu>

=head1 SEE ALSO

L<AI::ParticleSwarmOptimization>
L<AI::ParticleSwarmOptimization::Pmap>

=head1 COPYRIGHT

Copyright (c) Strzelecki Lukasz. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

