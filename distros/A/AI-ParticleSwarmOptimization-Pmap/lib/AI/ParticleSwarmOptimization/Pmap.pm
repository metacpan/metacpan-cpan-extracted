package AI::ParticleSwarmOptimization::Pmap;

use strict;
use warnings;
use base qw( 
	AI::ParticleSwarmOptimization
);
#-----------------------------------------------------------------------
use List::Util 					qw( min );
use Parallel::parallel_map;
#-----------------------------------------------------------------------
$AI::ParticleSwarmOptimization::Pmap::VERSION = '1.006';
#=======================================================================
sub _initParticles {
    my ($self) = @_;

	@{ $self->{ prtcls } } = map {
		my %prt = ( id => $_ );
		$self->_initParticle( \%prt );
		\%prt;
	} 0 .. $self->{ numParticles } - 1;
}
#=======================================================================
# Thanks Mario :-)
my $_pid = $$;
my $_srn = 0;
#-----------------------------------------------------------------------
sub _randInRange {
    my ($self, $min, $max) = @_;
    if( $$ != $_pid and not $_srn ){
        $self->{ rndGen }->set_seed( abs( $$ ) );
        $_srn = 1;
    }
    return $min + $self->{ rndGen }->rand( $max - $min );
}
#=======================================================================
sub _moveParticles {
    my ($self, $iter) = @_;

    print "Iter $iter\n" if $self->{verbose} & AI::ParticleSwarmOptimization::kLogIter;

	my @lst = grep { defined $_ } parallel_map {
		my $prtcl = $_;
		#---------------------------------------------------------------
		@{$prtcl->{currPos}} = @{$prtcl->{nextPos}};
        $prtcl->{currFit} = $prtcl->{nextFit};

        my $fit = $prtcl->{currFit};

        if ($self->_betterFit ($fit, $prtcl->{bestFit})) {
            # Save position - best fit for this particle so far
            $self->_saveBest ($prtcl, $fit, $iter);
        }

		my $ret;
		if( defined $self->{exitFit} and $fit < $self->{exitFit} ){
			$ret = $fit;
		}elsif( !($self->{verbose} & AI::ParticleSwarmOptimization::kLogIterDetail) ){
			$ret = undef;
		}else{        
			printf "Part %3d fit %8.2f", $prtcl->{id}, $fit
				if $self->{verbose} >= 2;
			printf " (%s @ %s)",
				join (', ', map {sprintf '%5.3f', $_} @{$prtcl->{velocity}}),
				join (', ', map {sprintf '%5.2f', $_} @{$prtcl->{currPos}})
				if $self->{verbose} & AI::ParticleSwarmOptimization::kLogDetail;
			print "\n";
			
			$ret = undef;
		}
		#---------------------------------------------------------------
		[ $prtcl, $ret ]
	} @{ $self->{ prtcls } };

	@{ $self->{ prtcls } } = map { $_->[ 0 ] } @lst;
	
	$self->{ bestBest } = min map { $_->{ bestFit } } @{ $self->{ prtcls } };
	
	my @fit = map { $_->[ 1 ] } grep { defined $_->[ 1 ] } @lst;

    return scalar( @fit ) ? ( sort { $a <=> $b } @fit )[ 0 ] : undef;
}
#=======================================================================
sub _updateVelocities {
    my ($self, $iter) = @_;

	@{ $self->{ prtcls } } = parallel_map {
		my $prtcl = $_;
		#---------------------------------------------------------------
		my $bestN = $self->{prtcls}[$self->_getBestNeighbour ($prtcl)];
        my $velSq;

        for my $d (0 .. $self->{dimensions} - 1) {
            my $meFactor =
                $self->_randInRange (-$self->{meWeight}, $self->{meWeight});
            my $themFactor =
                $self->_randInRange (-$self->{themWeight}, $self->{themWeight});
            my $meDelta   = $prtcl->{bestPos}[$d] - $prtcl->{currPos}[$d];
            my $themDelta = $bestN->{bestPos}[$d] - $prtcl->{currPos}[$d];

            $prtcl->{velocity}[$d] =
                $prtcl->{velocity}[$d] * $self->{inertia} +
                $meFactor * $meDelta +
                $themFactor * $themDelta;
            $velSq += $prtcl->{velocity}[$d]**2;
        }

        my $vel = sqrt ($velSq);
        if (!$vel or $self->{stallSpeed} and $vel <= $self->{stallSpeed}) {
            $self->_initParticle ($prtcl);
            printf "#%05d: Particle $prtcl->{id} stalled (%6f)\n", $iter, $vel
                if $self->{verbose} & AI::ParticleSwarmOptimization::kLogStall;
        }

        $self->_calcNextPos ($prtcl);
		#---------------------------------------------------------------
		$prtcl;
	} @{ $self->{ prtcls } };
}
#=======================================================================
1;

__END__

=head1 NAME

AI::ParticleSwarmOptimization::Pmap - Particle Swarm Optimization (object oriented) with support for multi-core processing

=head1 SYNOPSIS

    use AI::ParticleSwarmOptimization::Pmap;

    my $pso = AI::ParticleSwarmOptimization::Pmap->new (
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
multi-core processing with use of Pmap. Below you can find original documentation
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

    my $pso = AI::ParticleSwarmOptimization::Pmap->new(
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

