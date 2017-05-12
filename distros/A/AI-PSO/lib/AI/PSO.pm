package AI::PSO;

use strict;
use warnings;
use Math::Random;
use Callback;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    pso_set_params
    pso_register_fitness_function
    pso_optimize
    pso_get_solution_array
);

our $VERSION = '0.86';


######################## BEGIN MODULE CODE #################################

#---------- BEGIN GLOBAL PARAMETERS ------------

#-#-# search parameters #-#-#
my $numParticles  = 'null';            # This is the number of particles that actually search the problem hyperspace
my $numNeighbors  = 'null';            # This is the number of neighboring particles that each particle shares information with
                                       # which must obviously be less than the number of particles and greater than 0.
                                         # TODO: write code to preconstruct different topologies.  Such as fully connected, ring, star etc.
                                         #       Currently, neighbors are chosen by a simple hash function.  
                                         #       It would be fun (no theoretical benefit that I know of) to play with different topologies.
my $maxIterations = 'null';            # This is the maximum number of optimization iterations before exiting if the fitness goal is never reached.
my $exitFitness   = 'null';            # this is the exit criteria.  It must be a value between 0 and 1.
my $dimensions    = 'null';            # this is the number of variables the user is optimizing


#-#-# pso position parameters #-#-#
my $deltaMin       = 'null';           # This is the minimum scalar position change value when searching
my $deltaMax       = 'null';           # This is the maximum scalar position change value when searching

#-#-# my 'how much do I trust myself verses my neighbors' parameters #-#-#
my $meWeight   = 'null';               # 'individuality' weighting constant (higher weight (than group) means trust individual more, neighbors less)
my $meMin      = 'null';               # 'individuality' minimum random weight (this should really be between 0, 1)
my $meMax      = 'null';               # 'individuality' maximum random weight (this should really be between 0, 1)
my $themWeight = 'null';               # 'social' weighting constant (higher weight (than individual) means trust group more, self less)
my $themMin    = 'null';               # 'social' minimum random weight (this should really be between 0, 1)
my $themMax    = 'null';               # 'social' maximum random weight (this should really be between 0, 1)

my $psoRandomRange = 'null';           # PSO::.86 new variable to support original unmodified algorithm
my $useModifiedAlgorithm = 'null';

#-#-# user/debug parameters #-#-#
my $verbose    = 0;                    # This one defaults for obvious reasons...

#NOTE: $meWeight and $themWeight should really add up to a constant value.  
#      Swarm Intelligence defines a 'pso random range' constant and then computes two random numbers
#      within this range by first getting a random number and then subtracting it from the range.
#      e.g. 
#           $randomRange = 4.0
#           $meWeight   = random(0, $randomRange);
#           $themWeight = $randomRange - $meWeight.
#
#

#----------   END  GLOBAL PARAMETERS ------------

#---------- BEGIN GLOBAL DATA STRUCTURES --------
#
# a particle is a hash of arrays of positions and velocities:
#
# The position of a particle in the problem hyperspace is defined by the values in the position array...
# You can think of each array value as being a dimension,
# so in N-dimensional hyperspace, the size of the position vector is N
# 
# A particle updates its position according the Euler integration equation for physical motion:
#   Xi(t) = Xi(t-1) + Vi(t)
#   The velocity portion of this contains the stochastic elements of PSO and is defined as:
#   Vi(t) = Vi(t-1)  +  P1*[pi - Xi(t-1)]  +  P2*[pg - Xi(t-1)]
#   where P1 and P2 add are two random values who's sum adds up to the PSO random range (4.0)
#   and pi is the individual's best location
#   and pg is the global (or neighborhoods) best position
#
#   The velocity vector is obviously updated before the position vector...
#
#
my @particles = ();
my $user_fitness_function;
my @solution = ();
#----------   END GLOBAL DATA STRUCTURES --------


#---------- BEGIN EXPORTED SUBROUTINES ----------

#
# pso_set_params
#  - sets the global module parameters from the hash passed in
#
sub pso_set_params(%) {
    my (%params) = %{$_[0]};
    my $retval = 0;

    #no strict 'refs';
    #foreach my $key (keys(%params)) {
    #    $$key = $params{$key};
    #}
    #use strict 'refs';

    $numParticles   = defined($params{numParticles})   ? $params{numParticles}   : 'null';
    $numNeighbors   = defined($params{numNeighbors})   ? $params{numNeighbors}   : 'null';
    $maxIterations  = defined($params{maxIterations})  ? $params{maxIterations}  : 'null';
    $dimensions     = defined($params{dimensions})     ? $params{dimensions}     : 'null';
    $exitFitness    = defined($params{exitFitness})    ? $params{exitFitness}    : 'null';
    $deltaMin       = defined($params{deltaMin})       ? $params{deltaMin}       : 'null';
    $deltaMax       = defined($params{deltaMax})       ? $params{deltaMax}       : 'null';
    $meWeight       = defined($params{meWeight})       ? $params{meWeight}       : 'null';
    $meMin          = defined($params{meMin})          ? $params{meMin}          : 'null';
    $meMax          = defined($params{meMax})          ? $params{meMax}          : 'null';
    $themWeight     = defined($params{themWeight})     ? $params{themWeight}     : 'null';
    $themMin        = defined($params{themMin})        ? $params{themMin}        : 'null';
    $themMax        = defined($params{themMax})        ? $params{themMax}        : 'null';

    $psoRandomRange = defined($params{psoRandomRange}) ? $params{psoRandomRange} : 'null';

    $verbose        = defined($params{verbose})        ? $params{verbose}        : $verbose;

    my $param_string;
	if($psoRandomRange =~ m/null/) {
		$param_string =  "$numParticles:$numNeighbors:$maxIterations:$dimensions:$exitFitness:$deltaMin:$deltaMax:$meWeight:$meMin:$meMax:$themWeight:$themMin:$themMax";
	} else {
		$param_string =  "$numParticles:$numNeighbors:$maxIterations:$dimensions:$exitFitness:$deltaMin:$deltaMax:$psoRandomRange";
	}
    
    $retval = 1 if($param_string =~ m/null/);

    return $retval;
}


#
# pso_register_fitness_function
#  - sets the user-defined callback fitness function
#
sub pso_register_fitness_function($) {
    my ($func) = @_;
    $user_fitness_function = new Callback(\&{"main::$func"});
    return 0;
}


#
# pso_optimize
#  - runs the particle swarm optimization algorithm
#
sub pso_optimize() {
	&init();
    return &swarm();
}

#
# pso_get_solution_array
#  - returns the array of parameters corresponding to the best solution so far
sub pso_get_solution_array() {
	return @solution;
}


#----------  END  EXPORTED SUBROUTINES ----------



#--------- BEGIN INTERNAL SUBROUTINES -----------

#
# init
#   - initializes global variables
#   - initializes particle data structures
#
sub init() {
	if($psoRandomRange =~ m/null/) {
		$useModifiedAlgorithm = 1;
	} else {
		$useModifiedAlgorithm = 0;
	}
	&initialize_particles();
}

#
# initialize_particles
#    - sets up internal data structures
#    - initializes particle positions and velocities with an element of randomness
#
sub initialize_particles() {
    for(my $p = 0; $p < $numParticles; $p++) {
        $particles[$p]           = {};  # each particle is a hash of arrays with the array sizes being the dimensionality of the problem space
        $particles[$p]{nextPos}  = [];  # nextPos is the array of positions to move to on the next positional update
        $particles[$p]{bestPos}  = [];  # bestPos is the position of that has yielded the best fitness for this particle (it gets updated when a better fitness is found)
        $particles[$p]{currPos}  = [];  # currPos is the current position of this particle in the problem space
        $particles[$p]{velocity} = [];  # velocity ... come on ...

        for(my $d = 0; $d < $dimensions; $d++) {
            $particles[$p]{nextPos}[$d]  = &random($deltaMin, $deltaMax);
            $particles[$p]{currPos}[$d]  = &random($deltaMin, $deltaMax);
            $particles[$p]{bestPos}[$d]  = &random($deltaMin, $deltaMax);
            $particles[$p]{velocity}[$d] = &random($deltaMin, $deltaMax);
        }
    }
}



#
# initialize_neighbors
# NOTE: I made this a separate subroutine so that different topologies of neighbors can be created and used instead of this.
# NOTE: This subroutine is currently not used because we access neighbors by index to the particle array rather than storing their references
# 
#  - adds a neighbor array to the particle hash data structure
#  - sets the neighbor based on the default neighbor hash function
#
sub initialize_neighbors() {
    for(my $p = 0; $p < $numParticles; $p++) {
        for(my $n = 0; $n < $numNeighbors; $n++) {
            $particles[$p]{neighbor}[$n] = $particles[&get_index_of_neighbor($p, $n)];
        }
    }
}


sub dump_particle($) {
    $| = 1;
    my ($index) = @_;
    print STDERR "[particle $index]\n";
    print STDERR "\t[bestPos] ==> " . &compute_fitness(@{$particles[$index]{bestPos}}) . "\n";
    foreach my $pos (@{$particles[$index]{bestPos}}) {
        print STDERR "\t\t$pos\n";
    }
    print STDERR "\t[currPos] ==> " . &compute_fitness(@{$particles[$index]{currPos}}) . "\n";
    foreach my $pos (@{$particles[$index]{currPos}}) {
        print STDERR "\t\t$pos\n";
    }
    print STDERR "\t[nextPos] ==> " . &compute_fitness(@{$particles[$index]{nextPos}}) . "\n";
    foreach my $pos (@{$particles[$index]{nextPos}}) {
        print STDERR "\t\t$pos\n";
    }
    print STDERR "\t[velocity]\n";
    foreach my $pos (@{$particles[$index]{velocity}}) {
        print STDERR "\t\t$pos\n";
    }
}

#
# swarm 
#  - runs the particle swarm algorithm
#
sub swarm() {
    for(my $iter = 0; $iter < $maxIterations; $iter++) { 
        for(my $p = 0; $p < $numParticles; $p++) { 

            ## update position
            for(my $d = 0; $d < $dimensions; $d++) {
                $particles[$p]{currPos}[$d] = $particles[$p]{nextPos}[$d];
            }

            ## test _current_ fitness of position
            my $fitness = &compute_fitness(@{$particles[$p]{currPos}});
            # if this position in hyperspace is the best so far...
            if($fitness > &compute_fitness(@{$particles[$p]{bestPos}})) {
                # for each dimension, set the best position as the current position
                for(my $d2 = 0; $d2 < $dimensions; $d2++) {
                    $particles[$p]{bestPos}[$d2] = $particles[$p]{currPos}[$d2];
                }
            }

            ## check for exit criteria
            if($fitness >= $exitFitness) {
                #...write solution
                print "Y:$iter:$p:$fitness\n";
                &save_solution(@{$particles[$p]{bestPos}});
                &dump_particle($p);
                return 0;
            } else {
	    	if($verbose == 1) {
			print "N:$iter:$p:$fitness\n"
		}
		if($verbose == 2) {
			&dump_particle($p);
		}
            }
        }

        ## at this point we've updated our position, but haven't reached the end of the search
        ## so we turn to our neighbors for help.
        ## (we see if they are doing any better than we are, 
        ##  and if so, we try to fly over closer to their position)

        for(my $p = 0; $p < $numParticles; $p++) {
            my $n = &get_index_of_best_fit_neighbor($p);
            my @meDelta = ();       # array of self position updates
            my @themDelta = ();     # array of neighbor position updates
            for(my $d = 0; $d < $dimensions; $d++) {
				if($useModifiedAlgorithm) { # this if shold be moved out much further, but i'm working on code refactoring first
					my $meFactor = $meWeight * &random($meMin, $meMax);
					my $themFactor = $themWeight * &random($themMin, $themMax);
					$meDelta[$d] = $particles[$p]{bestPos}[$d] - $particles[$p]{currPos}[$d];
					$themDelta[$d] = $particles[$n]{bestPos}[$d] - $particles[$p]{currPos}[$d];
					my $delta = ($meFactor * $meDelta[$d]) + ($themFactor * $themDelta[$d]);
					$delta += $particles[$p]{velocity}[$d];

					# do the PSO position and velocity updates
					$particles[$p]{velocity}[$d] = &clamp_velocity($delta);
					$particles[$p]{nextPos}[$d] = $particles[$p]{currPos}[$d] + $particles[$p]{velocity}[$d];
				} else {
					my $rho1 = &random(0, $psoRandomRange);
					my $rho2 = $psoRandomRange - $rho1;
					$meDelta[$d] = $particles[$p]{bestPos}[$d] - $particles[$p]{currPos}[$d];
					$themDelta[$d] = $particles[$n]{bestPos}[$d] - $particles[$p]{currPos}[$d];
					my $delta = ($rho1 * $meDelta[$d]) + ($rho2 * $themDelta[$d]);
					$delta += $particles[$p]{velocity}[$d];

					# do the PSO position and velocity updates
					$particles[$p]{velocity}[$d] = &clamp_velocity($delta);
					$particles[$p]{nextPos}[$d] = $particles[$p]{currPos}[$d] + $particles[$p]{velocity}[$d];
				}
            }
        }

    }

    #
    # at this point we have exceeded the maximum number of iterations, so let's at least print out the best result so far
    #
    print STDERR "MAX ITERATIONS REACHED WITHOUT MEETING EXIT CRITERION...printing best solution\n";
    my $bestFit = -1;
    my $bestPartIndex = -1;
    for(my $p = 0; $p < $numParticles; $p++) {
    	my $endFit = &compute_fitness(@{$particles[$p]{bestPos}});
	if($endFit >= $bestFit) {
		$bestFit = $endFit;
		$bestPartIndex = $p;
	}
	
    }
    &save_solution(@{$particles[$bestPartIndex]{bestPos}});
    &dump_particle($bestPartIndex);
    return 1;
}

#
# save solution
#   - simply copies the given array into the global solution array
#
sub save_solution(@) {
	@solution = @_;
}


#
# compute_fitness
# - computes the fitness of a particle by using the user-specified fitness function
# 
# NOTE: I originally had a 'fitness cache' so that particles that stumbled upon the same
#       position wouldn't have to recalculate their fitness (which is often expensive).
#       However, this may be undesirable behavior for the user (if you come across the same position
#       then you may be settling in on a local maxima so you might want to randomize things and
#       keep searching.  For this reason, I'm leaving the cache out.  It would be trivial
#       for users to implement their own cache since they are passed the same array of values.
#
sub compute_fitness(@) {
    my (@values) = @_;
    my $return_fitness = 0;

#    no strict 'refs';
#    if(defined(&{"main::$user_fitness_function"})) {
#        $return_fitness = &$user_fitness_function(@values);
#    } else {
#        warn "error running user_fitness_function\n";
#        exit 1;
#    }
#    use strict 'refs';

    $return_fitness = $user_fitness_function->call(@values);

    return $return_fitness;
}


#
# random
# - returns a random number that is between the first and second arguments using the Math::Random module
#
sub random($$) {
    my ($min, $max) = @_;
    return random_uniform(1, $min, $max)
}


#
# get_index_of_neighbor
#
# - returns the index of Nth neighbor of the index for particle P
# ==> A neighbor is one of the next K particles following P where K is the neighborhood size.
#    So, particle 1 has neighbors 2, 3, 4, 5 if K = 4.  particle 4 has neighbors 5, 6, 7, 8
#    ...
# 
sub get_index_of_neighbor($$) {
    my ($particleIndex, $neighborNum) = @_;
    # TODO: insert error checking code / defensive programming
    return ($particleIndex + $neighborNum) % $numParticles;
}


#
# get_index_of_best_fit_neighbor
# - returns the index of the neighbor with the best fitness (when given a particle index)...
# 
sub get_index_of_best_fit_neighbor($) {
    my ($particleIndex) = @_;
    my $bestNeighborFitness   = 0;
    my $bestNeighborIndex     = 0;
    my $particleNeighborIndex = 0;
    for(my $neighbor = 0; $neighbor < $numNeighbors; $neighbor++) {
        $particleNeighborIndex = &get_index_of_neighbor($particleIndex, $neighbor);
        if(&compute_fitness(@{$particles[$particleNeighborIndex]{bestPos}}) > $bestNeighborFitness) { 
            $bestNeighborFitness = &compute_fitness(@{$particles[$particleNeighborIndex]{bestPos}});
            $bestNeighborIndex = $particleNeighborIndex;
        }
    }
    # TODO: insert error checking code / defensive programming
    return $particleNeighborIndex;
}

#
# clamp_velocity
# - restricts the change in velocity to be within a certain range (prevents large jumps in problem hyperspace)
#
sub clamp_velocity($) {
    my ($dx) = @_;
    if($dx < $deltaMin) {
        $dx = $deltaMin;
    } elsif($dx > $deltaMax) {
        $dx = $deltaMax;
    }
    return $dx;
}
#---------  END  INTERNAL SUBROUTINES -----------


1;
########################  END  MODULE CODE #################################
__END__

=head1 NAME

AI::PSO - Module for running the Particle Swarm Optimization algorithm

=head1 SYNOPSIS

  use AI::PSO;

  my %params = (
      numParticles   => 4,     # total number of particles involved in search 
      numNeighbors   => 3,     # number of particles with which each particle will share its progress
      maxIterations  => 1000,  # maximum number of iterations before exiting with no solution found
      dimensions     => 4,     # number of parameters you want to optimize
      deltaMin       => -4.0,  # minimum change in velocity during PSO update
      deltaMax       =>  4.0,  # maximum change in velocity during PSO update
      meWeight       => 2.0,   # 'individuality' weighting constant (higher means more individuality)
      meMin          => 0.0,   # 'individuality' minimum random weight
      meMax          => 1.0,   # 'individuality' maximum random weight
      themWeight     => 2.0,   # 'social' weighting constant (higher means trust group more)
      themMin        => 0.0,   # 'social' minimum random weight 
      themMax        => 1.0,   # 'social' maximum random weight
      exitFitness    => 0.9,   # minimum fitness to achieve before exiting
      verbose        => 0,     # 0 prints solution
                               # 1 prints (Y|N):particle:fitness at each iteration
                               # 2 dumps each particle (+1)
      psoRandomRange => 4.0,   # setting this enables the original PSO algorithm and
                               # also subsequently ignores the  me*/them* parameters
  );


  sub custom_fitness_function(@input) {	
        # this is a callback function.  
        # @input will be passed to this, you do not need to worry about setting it...
        # ... do something with @input which is an array of floats
        # return a value in [0,1] with 0 being the worst and 1 being the best
  }

  pso_set_params(\%params);
  pso_register_fitness_function('custom_fitness_function');
  pso_optimize();
  my @solutionArray = pso_get_solution_array();

E<32>

=head2  General Guidelines

=over 2

=item 1. Sociality versus individuality

    I suggest that meWeight and themWeight add up up to 4.0, or that 
    psoRandomRange = 4.0.  Also, you should also be setting meMin 
    and themMin to 0, and meMin and themMax to 1 unless you really 
    know what you are doing.

=item 2. Search space coverage

    If you have a large search space, increasing deltaMin and deltaMax 
    and delta max can help cover more area. Conversely, if you have a 
    small search space, then decreasing them will fine tune the search.

=item 3. Swarm Topology

    I've personally found that using a global (fully connected) topology 
    where each particle is neighbors with all other particles 
    (numNeighbors == numParticles - 1) converges more quickly.  However, 
    this will drastically increase the number of calls to your fitness 
    function.  So, if your fitness function is the bottleneck, then you 
    should tune this value for the appropriate time/accuracy trade-off.  
    Also, I highly suggest you implement a simple fitness cache so you 
    don't end up recomputing fitness values.  This can easily be done 
    with a perl hash that is keyed on the string concatenation of the 
    array values passed to your fitness function.  Note that these are 
    floating point values, so determine how significant the values are 
    and you can use sprintf to essentially limit the precision of the 
    particle positions.

=item 4. Number of particles

    The number of particles increases cooperation and search space 
    coverage at the expense of compute.  Typical applications should 
    suffice using 20-40 particles.

=back

=over 8

=item * NOTE: 

    I force people to define all parameters, but guidelines 1-4 are 
    standard and pretty safe.

=back


=head1 DESCRIPTION OF ALGORITHM

  Particle Swarm Optimization is an optimization algorithm designed by 
  Russell Eberhart and James Kennedy from Purdue University.  The 
  algorithm itself is based off of the emergent behavior among societal 
  groups ranging from marching of ants, to flocking of birds, to 
  swarming of bees.

  PSO is a cooperative approach to optimization rather than an 
  evolutionary approach which kills off unsuccessful members of the 
  search team.  In the swarm framework each particle, is a relatively 
  unintelligent search agent.  It is in the collective sharing of 
  knowledge that solutions are found.  Each particle simply shares its 
  information with its neighboring particles.  So, if one particle is 
  not doing to well (has a low fitness), then it looks to its neighbors 
  for help and tries to be more like them while still maintaining a 
  sense of individuality.

  A particle is defined by its position and velocity.  The parameters a 
  user wants to optimize define the dimensionality of the problem 
  hyperspace.  So, if you want to optimize three variables, a particle 
  will be three dimensional and will have 3 values that devine its 
  position 3 values that define its velocity.  The position of a 
  particle determines how good it is by a user-defined fitness function.  
  The velocity of a particle determines how quickly it changes location.  
  Larger velocities provide more coverage of hyperspace at the cost of 
  solution precision.  With large velocities, a particle may come close 
  to a maxima but over-shoot it because it is moving too quickly.  With 
  smaller velocities, particles can really hone in on a local solution 
  and find the best position but they may be missing another, possibly 
  even more optimal, solution because a full search of the hyperspace 
  was not conducted.  Techniques such as simulated annealing can be 
  applied in certain areas so that the closer a partcle gets to a 
  solution, the smaller its velocity will be so that in bad areas of 
  the hyperspace, the particles move quickly, but in good areas, they 
  spend some extra time looking around.

  In general, particles fly around the problem hyperspace looking for 
  local/global maxima.  At each position, a particle computes its 
  fitness.  If it does not meet the exit criteria then it gets 
  information from neighboring particles about how well they are doing.  
  If a neighboring particle is doing better, then the current particle 
  tries to move closer to its neighbor by adjusting its position.  As 
  mentioned, the velocity controls how quickly a particle changes 
  location in the problem hyperspace.  There are also some stochastic 
  weights involved in the positional updates so that each particle is 
  truly independent and can take its own search path while still 
  incorporating good information from other particles.  In this 
  particluar perl module, the user is able to choose from two 
  implementations of the algorithm.  One is the original implementation 
  from I<Swarm Intelligence> which requires the definition of a 
  'random range' to which the two stochastic weights are required to 
  sum.  The other implementation allows the user to define the weighting
  of how much a particle follows its own path versus following its 
  peers.  In both cases there is an element of randomness.

  Solution convergence is quite fast once one particle becomes close to 
  a local maxima.  Having more particles active means there is more of 
  a chance that you will not be stuck in a local maxima.  Often times 
  different neighborhoods (when not configured in a global neighborhood 
  fashion) will converge to different maxima.  It is quite interesting 
  to watch graphically.  If the fitness function is expensive to 
  compute, then it is often useful to start out with a small number of
  particles first and get a feel for how the algorithm converges.

  The algorithm implemented in this module is taken from the book 
  I<Swarm Intelligence> by Russell Eberhart and James Kennedy.  
  I highly suggest you read the book if you are interested in this 
  sort of thing.  


=head1 EXPORTED FUNCTIONS

=over 4

=item pso_set_params()

  Sets the particle swarm configuration parameters to use for the search.

=item pso_register_fitness_function()

  Sets the user defined fitness function to call.  The fitness function 
  should return a value between 0 and 1.  Users may want to look into 
  the sigmoid function [1 / (1+e^(-x))] and it's variants to implement 
  this.  Also, you may want to take a look at either t/PSO.t for the 
  simple test or examples/NeuralNetwork/pso_ann.pl for an example on 
  how to train a simple 3-layer feed forward neural network.  (Note 
  that a real training application would have a real dataset with many 
  input-output pairs...pso_ann.pl is a _very_ simple example.  Also note 
  that the neural network exmaple requires g++.  Type 'make run' in the 
  examples/NeuralNetwork directory to run the example.  Lastly, the 
  neural network c++ code is in a very different coding style.  I did 
  indeed write this, but it was many years ago when I was striving to 
  make my code nicely formatted and good looking :)).

=item pso_optimize()

  Runs the particle swarm optimization algorithm.  This consists of 
  running iterations of search and many calls to the fitness function 
  you registered with pso_register_fitness_function()

=item pso_get_solution_array()

  By default, pso_optimize() will print out to STDERR the first 
  solution, or the best solution so far if the max iterations were 
  reached.  This function will simply return an array of the winning 
  (or best so far) position of the entire swarm system.  It is an 
  array of floats to be used how you wish (like weights in a 
  neural network!).

=back



=head1 EXAMPLES

=over 4

=item examples/NeuralNet/pso_ann.pl

=item t/PSO.t

=back



=head1 SEE ALSO

1.  I<Swarm intelligence> by James Kennedy and Russell C. Eberhart. 
    ISBN 1-55860-595-9

2.  A Hybrid Particle Swarm and Neural Network Approach for Reactive Power Control
    AI-PSO-0.86/extradocs/ReactivePower-PSO-wks.pdf
    L<http://webapps.calvin.edu/~pribeiro/courses/engr302/Samples/ReactivePower-PSO-wks.pdf>



=head1 AUTHOR

W. Kyle Schlansker 
kylesch@gmail.com



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by W. Kyle Schlansker

This code is released under the Mozilla Public License Version 1.1.
A copy of this license may be found along with this module or at:
L<http://www.mozilla.org/MPL/MPL-1.1.txt>

=cut
