package Algorithm::Evolve;

use strict;
use Carp qw/croak carp/;
use List::Util qw/shuffle/;

our (%SELECTION, %REPLACEMENT);
our $VERSION = '0.03';
our $DEBUG   = 0;

my $rand_max = (1 << 31); ## close enough

###########################

sub debug {
    print @_, "\n" if $DEBUG;
}

sub new {
    my $pkg = shift;

    my $p = bless {
        generations      => 0,
        parents_per_gen  => 2,
        @_
    }, $pkg;
   
    $p->{random_seed}      ||= int(rand $rand_max);
    srand( $p->random_seed );

    $p->{selection}        ||= $p->{replacement};
    $p->{replacement}      ||= $p->{selection};
    $p->{children_per_gen} ||= $p->{parents_per_gen};

    $p->_validate_args;

    return $p;
}

sub _validate_args {
    my $p = shift;
    
    {
        no strict 'refs';
        croak "Invalid selection/replacement criteria"
            unless *{"Algorithm::Evolve::selection::" . $p->selection}{CODE}
               and *{"Algorithm::Evolve::replacement::" . $p->replacement}{CODE};
    }

    croak "Please specify the size of the population" unless $p->size;
    croak "parents_per_gen must be even" if $p->parents_per_gen % 2;
    croak "parents_per_gen must divide children_per_gen"
        if $p->children_per_gen % $p->parents_per_gen;
    croak "parents_per_gen and children_per_gen must be no larger than size"
        if $p->children_per_gen > $p->size
        or $p->parents_per_gen  > $p->size;
        
    $p->{children_per_parent} = $p->children_per_gen / $p->parents_per_gen;

}

############################

sub start {
    my $p = shift;
    $p->_initialize;
        
    until ($p->is_suspended) {
        no strict 'refs';
        
        my @parent_indices
            = ("Algorithm::Evolve::selection::" . $p->selection)
                ->($p, $p->parents_per_gen);

        my @children;
        while (@parent_indices) {
            my @parents = @{$p->critters}[ splice(@parent_indices, 0, 2) ];
            
            push @children, $p->critter_class->crossover(@parents)
                for (1 .. $p->children_per_parent);
        }

        $_->mutate for @children;
    
        my @replace_indices
            = ("Algorithm::Evolve::replacement::" . $p->replacement)
                ->($p, $p->children_per_gen);

        ## place the new critters first, then sort. maybe fixme:
        
        @{$p->critters}[ @replace_indices ] = @children;
        @{$p->fitnesses}[ @replace_indices ] = () if $p->use_fitness;
        
        $p->_sort_critters;

        $p->{generations}++;    
        $p->callback->($p) if (ref $p->callback eq 'CODE');
    }
}

###################

sub suspend {
    my $p = shift;
    $p->{is_suspended} = 1;
}

sub resume {
    my $p = shift;
    $p->{is_suspended} = 0;
    $p->start;
}

sub best_fit {
    my $p = shift;
    carp "It's hard to pick the most fit when fitness is relative!"
        unless ($p->use_fitness);
    $p->critters->[-1];
}

sub avg_fitness {
    my $p = shift;
    my $sum = 0;
    $sum += $_ for @{$p->fitnesses};
    return $sum / $p->size;
}

sub selection {
    my ($p, $method) = @_;
    return $p->{selection} unless defined $method;
    $p->{selection} = $method;
    $p->_validate_args;
    return $p->{selection};
}

sub replacement {
    my ($p, $method) = @_;
    return $p->{replacement} unless defined $method;
    $p->{replacement} = $method;
    $p->_validate_args;
    return $p->{replacement};
}

sub parents_children_per_gen {
    my ($p, $parents, $children) = @_;
    return unless defined $parents and defined $children;
    $p->{parents_per_gen} = $parents;
    $p->{children_per_gen} = $children;
    $p->_validate_args;
}

####################

sub _initialize {
    my $p = shift;
    return if defined $p->critters;
    
    $p->{critters}    = [ map { $p->critter_class->new } 1 .. $p->size ];
    $p->{use_fitness} = !! $p->critters->[0]->can('fitness');
    $p->{fitnesses}   = [ map { $p->critters->[$_]->fitness } 0 .. $p->size-1 ]
        if ($p->use_fitness);

    $p->_sort_critters;
}


sub _sort_critters {
    my $p = shift;

    return unless $p->use_fitness;

    my $fitnesses = $p->fitnesses;
    my $critters = $p->critters;
    for (0 .. $p->size-1) {
        $fitnesses->[$_] = $critters->[$_]->fitness
            unless defined $fitnesses->[$_];            
    }
    
    my @sorted_indices =
        sort { $fitnesses->[$a] <=> $fitnesses->[$b] } 0 .. $p->size-1;

    $p->{critters}  = [ @{$critters} [ @sorted_indices ] ];
    $p->{fitnesses} = [ @{$fitnesses}[ @sorted_indices ] ];
}


############################
## picks N indices randomly, using the given weights

sub _pick_n_indices_weighted {
    my $num = shift;
    my $relative_prob = shift;

    croak("Tried to pick $num items, with only " . @$relative_prob . " choices!")
        if $num > @$relative_prob;
    
    my $sum = 0;
    $sum += $_ for @$relative_prob;

    my @indices;
    
    while ($num--) {
        my $dart = rand($sum);
        my $index = -1;
    
        $dart -= $relative_prob->[++$index] while ($dart > 0);
        
        $sum -= $relative_prob->[$index];
        $relative_prob->[$index] = 0;
        push @indices, $index;
    }
    
    return @indices;
}

#############################
## Selection / replacement routines: these take a population object and a 
## number, and return a list of indices. Keep in mind that the critter
## array is already sorted by fitness.

#############################

## these two go crazy with negative fitness values. fixme later maybe

sub Algorithm::Evolve::selection::roulette {
    my ($p, $num) = @_;
    croak "Can't use roulette selection/replacement without a fitness function"
        unless ($p->use_fitness);
    _pick_n_indices_weighted( $num, [ @{$p->fitnesses} ] );
};

sub Algorithm::Evolve::replacement::roulette {
    my ($p, $num) = @_;
    croak "Can't use roulette selection/replacement without a fitness function"
        unless ($p->use_fitness);
    _pick_n_indices_weighted( $num, [ map { 1/($_+1) } @{$p->fitnesses} ] );
};

###############
    
sub Algorithm::Evolve::selection::rank {
    my ($p, $num) = @_;
    croak "Can't use rank selection/replacement without a fitness function"
        unless ($p->use_fitness);
    _pick_n_indices_weighted( $num, [ 1 .. $p->size ] );
};
    
sub Algorithm::Evolve::replacement::rank {
    my ($p, $num) = @_;
    croak "Can't use rank selection/replacement without a fitness function"
        unless ($p->use_fitness);
    _pick_n_indices_weighted( $num, [ reverse(1 .. $p->size) ] );
};

###############

sub Algorithm::Evolve::selection::random {
    my ($p, $num) = @_;
    _pick_n_indices_weighted( $num, [ (1) x $p->size ] );

}
sub Algorithm::Evolve::replacement::random {
    my ($p, $num) = @_;
    _pick_n_indices_weighted( $num, [ (1) x $p->size ] );
};

################

sub Algorithm::Evolve::selection::absolute {
    my ($p, $num) = @_;
    croak "Can't use absolute selection/replacement without a fitness function"
        unless ($p->use_fitness);
    return ( $p->size - $num .. $p->size - 1 );
};

sub Algorithm::Evolve::replacement::absolute {
    my ($p, $num) = @_;
    croak "Can't use absolute selection/replacement without a fitness function"
        unless ($p->use_fitness);
    return ( 0 .. $num-1 );
};

################

my @tournament_replace_indices;
my $tournament_warn = 0;
    
sub Algorithm::Evolve::selection::tournament {
    my ($p, $num) = @_;
    my $t_size    = $p->{tournament_size};
    
    croak "Invalid (or no) tournament size specified" 
        if not defined $t_size or $t_size < 2 or $t_size > $p->size;
    croak "Tournament size * #tournaments must be no greater than population size" 
        if ($num/2) * $t_size > $p->size;
    carp "Tournament selection without tournament replacement is insane"
        unless ($p->replacement eq 'tournament' or $tournament_warn++);
        
    my $tournament_groups          = $num / 2;
    my @indices                    = shuffle(0 .. $p->size-1);
    my @tournament_choose_indices  = 
       @tournament_replace_indices = ();
    
    for my $i (0 .. $tournament_groups-1) {
        my $beg = $t_size * $i;
        my $end = $beg + $t_size - 1;
        
        ## the critters are already sorted by fitness within $p->critters -- 
        ## so we can sort them by their index number, without having to
        ## consult the fitness function (or fitness array) again.

        my @sorted_group_indices = sort { $b <=> $a } @indices[ $beg .. $end ];
        push @tournament_choose_indices,  @sorted_group_indices[0,1];
        push @tournament_replace_indices, @sorted_group_indices[-2,-1];
    }

    return @tournament_choose_indices;        
};

sub Algorithm::Evolve::replacement::tournament {
    my ($p, $num) = @_;
    croak "parents_per_gen must equal children_per_gen with tournament selection"
        if @tournament_replace_indices != $num;
    croak "Can't use tournament replacement without tournament selection"
        unless ($p->selection eq 'tournament');
                
    return @tournament_replace_indices;
};

#######################################

my @gladitorial_replace_indices;
my $gladitorial_warn          = 0;
my $gladitorial_attempts_warn = 0;

sub Algorithm::Evolve::selection::gladitorial {
    my ($p, $num) = @_;
    
    carp "Gladitorial selection without gladitorial replacement is insane"
        unless ($p->replacement eq 'gladitorial' or $gladitorial_warn++);

    my $max_attempts                = $p->{max_gladitorial_attempts} || 100;
    my $fetched                     = 0;
    my $attempts                    = 0;
    
    my @available_indices           = 0 .. $#{$p->critters};
    my @gladitorial_select_indices  =
       @gladitorial_replace_indices = ();
    
    while ($fetched != $p->parents_per_gen) {
        my ($i1, $i2) = (shuffle @available_indices)[0,1];

        if ($attempts++ > $max_attempts) {
            carp "Max gladitorial attempts exceeded -- choosing at random"
                unless $gladitorial_attempts_warn++;
            my $remaining = $p->parents_per_gen - @gladitorial_select_indices;

            push @gladitorial_replace_indices, 
                (shuffle @available_indices)[0 .. $remaining-1];
            push @gladitorial_select_indices,
                (shuffle @available_indices)[0 .. $remaining-1];

            last;                            
        }
    
        my $cmp = $p->critter_class->compare( @{$p->critters}[$i1, $i2] );
        
        next if $cmp == 0; ## tie
            
        my ($select, $remove) = $cmp > 0 ? ($i1,$i2) : ($i2,$i1);
        @available_indices = grep { $_ != $remove } @available_indices;
        
        push @gladitorial_replace_indices, $remove;
        push @gladitorial_select_indices,  $select;
        $fetched++;    
    }

    return @gladitorial_select_indices;
};

sub Algorithm::Evolve::replacement::gladitorial {
    my ($p, $num) = @_;
    croak "parents_per_gen must equal children_per_gen with gladitorial selection"
        if @gladitorial_replace_indices != $num;
    croak "Can't use gladitorial replacement without gladitorial selection"
        unless ($p->selection eq 'gladitorial');
                
    return @gladitorial_replace_indices;
};

#######################################

BEGIN {
    ## creates very basic readonly accessors - very loosely based on an
    ## idea by Juerd in http://perlmonks.org/index.pl?node_id=222941

    my @fields = qw/critters size generations callback critter_class
                    random_seed is_suspended use_fitness fitnesses
                    parents_per_gen children_per_gen children_per_parent/;

    no strict 'refs';
    for my $f (@fields) { 
        *$f = sub { carp "$f method is readonly" if $#_; $_[0]->{$f} };
    }
}

##########################################
##########################################
##########################################
1;
__END__

=head1 NAME

Algorithm::Evolve - An extensible and generic framework for executing 
evolutionary algorithms

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use Algorithm::Evolve;
    use MyCritters;     ## Critter class providing appropriate methods
    
    sub callback {
        my $p = shift;  ## get back the population object

        ## Output some stats every 10 generations
        print $p->avg_fitness, $/ unless $p->generations % 10;
        
        ## Stop after 2000 generations
        $p->suspend if $p->generations >= 2000;
    }
    
    my $p = Algorithm::Evolve->new(
        critter_class    => MyCritters,
        selection        => rank,
        size             => 400,
        callback         => \&callback,
    );
    
    $p->start;
    
    ## Print out final population statistics, cleanup, etc..

=cut

=head1 DESCRIPTION

This module is intended to be a useful tool for quick and easy implementation
of evolutionary algorithms. It aims to be flexible, yet simple. For this
reason, it is not a comprehensive implementation of all possible evolutionary
algorithm configurations. The flexibility of Perl allows the evolution of
any type of object conceivable: a simple string or array, a deeper structure
like a hash of arrays, or even something as complex as graph object from
another CPAN module, etc. 

It's also worth mentioning that evolutionary algorithms are generally very
CPU-intensive. There are a great deal of calls to C<rand()> and a lot of
associated floating-point math. If you want a lightning-fast framework, then
searching CPAN at all is probably a bad place to start. However, this doesn't
mean that I've ignored efficiency. The fitness function is often the biggest
bottleneck.

=head2 Framework Overview

The configurable parts of an evolutionary algorithm can be split up into two 
categories:

=over

=item Dependent on the internal representation of genes to evolve:

These include fitness function, crossover and mutation operators. For example,
evolving string genes requires a different mutation operator than evolving
array genes.

=item Independent of representation:

These include selection and replacement methods, population size, number of
mating events, etc.

=back

In Algorithm::Evolve, the first group of options is implemented by the user 
for maximum flexibility. These functions are abstracted to class of evolvable
objects (a B<critter class> in this document). The module itself handles the
representation-independent parts of the algorithm using simple configuration
switches and methods.

=head1 USAGE

If you're of the ilk that prefers to learn things hands-on, you should
probably stop here and look at the contents of the F<examples/> directory
first. 

=head2 Designing a class of critter objects (interface specification)

Algorithm::Evolve maintains a population of critter objects to be evolved. You 
may evolve any type of objects you want, provided the class supplies the 
following methods:

=over

=item C<Class-E<gt>new()>

This method will be called as a class method with no arguments. It must return
a blessed critter object. It is recommended that the returned critter's genes
be randomly initialized.

=item C<Class-E<gt>crossover( $critter1, $critter2 )>

This method will also be called as a class method, with two critter objects as 
arguments. It should return a list of two new critter objects based on the 
genes of the passed objects.

=item C<$critter-E<gt>mutate()>

This method will be called as an instance method, with no arguments. It should
randomly modify the genes of the critter. Its return value is ignored.

=item C<$critter-E<gt>fitness()>

This method will also be called as an instance method, with no arguments. It 
should return the critter's fitness measure within the problem space, which
should always be a nonnegative number. This method need not be memo-ized, as 
it is only called once per critter by Algorithm::Evolve.

This method may be omitted only if using gladitorial selection/replacement
(see below).

=item C<Class-E<gt>compare( $critter1, $critter2 )>

This method is used for L</Co_Evolution|co-evolution> with the gladitorial
selection method. It should return a number less than zero if $critter1 is
"better," 0 if the two are equal, or a number greater than zero if $critter2
is "better." 

=back

You may also want to use the C<DESTROY> method as a hook for detecting when
critters are removed from the population.

See the F<examples/> directory for example critter classes. Also, take a look
at L<Algorithm::Evolve::Util> which provides some useful utilities for 
implementing a critter class.




=head2 Algorithm::Evolve population interface

=over

=item C<$p = Algorithm::Evolve-E<gt>new( option =E<gt> value, ... )>

Takes a hash of arguments and returns a population object. The relevant options 
are:

B<critter_class>, the name of the critter class whose objects are to be 
evolved. This class should already be C<use>'d or C<require>'d by your code.

B<selection> and B<replacement>, the type of selection and replacement methods 
to use. Available methods for both currently include: 

=over

=item *

B<tournament>: Create tournament groups of the desired size (see below).
The two highest-fitness group members get to breed, and the two lowest-fitness
members get replaced (This is also called single-tournament selection). Must be
specified for both selection and replacement.

=item *

B<gladitorial>: See below under L</Co_Evolution|co-evolution>. Must be used
for both selection and replacement.

=item *

B<random>: Choose critters completely at random.

=item *

B<roulette>: Choose critters with weighted probability based on their
fitness. For selection, each critter's weight is its fitness. For replacement,
each critter's weight is 1/(fitness + 1).

=item *

B<rank>: Choose critters with weighted probability based on their rank. For
selection, the most-fit critter's weight is C<< $p->size >>, while the 
least-fit critter's weight is 1. For replacement, the weights are in reverse
order.

=item *

B<absolute>: Choose the N most-fit critters for selection, or the N least-fit
for replacement.

=back

You may mix and match different kinds of selection and replacement methods. The
only exceptions are C<tournament> and C<gladitorial>, which must be used as
both selection and replacement method.

If both selection and replacement methods are the same, you may omit one from
the list of arguments.



B<tournament_size>, only required if you choose tournament 
selection/replacement. Should be at least 4 unless you know what you're doing.

B<max_gladitorial_attempts>: Because comparisons in gladitorial selection may
result in a tie, this is the number of ties permitted before giving up and
picking critters at random instead during that breeding event. The first time
this occurs, the module will C<carp> a message.

B<parents_per_gen> and B<children_per_gen> control the number of breedings per 
generation. children_per_gen must be a multiple of parents_per_gen. 
parents_per_gen must also be an even number. Each pair of parents selected in a 
generation will produce the same number of children, calling the crossover 
method in the critter class as many times as necessary. Basically, each 
selected parent gets a gene copy count of children_per_gen/parents_per_gen. 

You may omit children_per_gen, it will default to equal parents_per_gen. If
you omit both options, they will default to 2.

In tournament and gladitorial selection, children_per_gen must be equal to
parents_per_gen. The number of tournaments each generation is equal to
parents_per_gen/2.

B<size>, the number of critters to have in the population.

B<callback>, an optional (but highly recommended) reference to a function. It 
should expect one argument, the population object. It is called after each 
generation. You may find it useful for printing out current statistical 
information. You must also use it if you intend to stop the algorithm after a 
certain number of generations (or some other criteria).

B<random_seed>, an optional number that will be fed to C<srand> before the 
algorithm starts. Use this to reproduce previous results. If this is not given, 
Algorithm::Evolve will generate a random seed that you can retrieve.


=item C<$p-E<gt>size()>

Returns the size of the population, as given above. As of now, you cannot
change the population's size during the runtime of the evolutionary algorithm.

=item C<$p-E<gt>run()>

Begins execution of the algorithm, and returns when the population has been 
C<suspend>'ed.

=item C<$p-E<gt>suspend()>

Call this method from within the callback function to stop the algorithm's 
iterations and return from the C<run> method.

=item C<$p-E<gt>resume()>

Start up the algorithm again after being C<suspend>'ed.

=item C<$p-E<gt>generations()>

=item C<$p-E<gt>avg_fitness()>

=item C<$p-E<gt>best_fit()>

These return basic information about the current state of the population. You 
probably will use these methods from within the callback sub. The best_fit 
method returns the most-fit critter in the population.

=item C<$p-E<gt>critters()>

Returns a reference to an array containing all the critters in the population, 
sorted by increasing fitness. You can use this to iterate over the entire
population, but please don't modify the array.

=item C<$p-E<gt>fitnesses()>

Returns a reference to an array containing all the fitnesses of the
population (in increasing order), if appropriate. The order of this array
corresponds to the order of the critters array. You might use this if you
write your own seleciton and replacement methods. Please don't modify the
array.

=item C<$p-E<gt>random_seed()>

Returns the random seed that was used for this execution.

=item C<$p-E<gt>selection( [ $new_method ] )>

=item C<$p-E<gt>replacement( [ $new_method ] )>

Fetch or change the selection/replacement method while the algorithm is
running.

=item C<$p-E<gt>parents_children_per_gen($parents, $children)>

Changes the parents_per_gen and children_per_gen attributes of the population
while the algorithm is running. Both are changed at once because the latter
must always be a multiple of the former.

=back


=head2 Co-Evolution

When there is no absolute measure of fitness for a problem, and a critter's
fitness depends on the other memebers of the population, this is called
B<co-evolution>. A good example of such a problem is rock-paper-scissors. If
we were to evolve strategies for this game, any strategy's success would be
dependent on what the rest of the population is doing.

To perform such an evolutionary algorithm, implement the C<compare> method
in your critter class and choose gladitorial selection and replacement. 
Gladitorial selection/replacement chooses random pairs of critters and
C<compare>s them. If the result is not a tie, the winner receives reproduction
rights, and the loser is chosen for replacement. This happens until the
desired number of parents have been selected, or until a timeout occurs.

=head2 Adding Selection/Replacement Methods

To add your own selection and replacement methods, simply declare them in
the C<Algorithm::Evolve::selection> or C<Algorithm::Evolve::replacement> 
namespaces, respectively. The first argument will be the population object,
and the second will be the number of critters to choose for
selection/replacement. You should return a list of the I<indices> you chose.

    use Algorithm::Evolve;
    
    sub Algorithm::Evolve::selection::reverse_absolute {
        my ($p, $num) = @_;
        
        ## Select the indices of the $num lowest-fitness critters.
        ## Remember that they are sorted by increasing fitness.
        return (0 .. $num-1);
    }
    sub Algorithm::Evolve::replacement::reverse_absolute {
        my ($p, $num) = @_;
        
        ## Select indices of the $num highest-fitness critters.
        return ($p->size - $num .. $p->size - 1);
    }
    
    ## These are like absolute selection/replacement, but reversed, so that
    ## the evolutionary algorithm *minimizes* the fitness function.
    
    my $p = Algorithm::Evolve->new(
        selection => reverse_absolute,
        replacement => reverse_absolute,
        ...
    );

See the source of this module to see how the various selection/replacement
methods are implemented.
The mechanism for adding additional selection/replacement methods may change
in future versions.

=head1 SEE ALSO

L<Algorithm::Evolve::Util|Algorithm::Evolve::Util>, the F<examples/>
directory.

=head1 AUTHOR

Algorithm::Evolve is written by Mike Rosulek E<lt>mike@mikero.comE<gt>. Feel 
free to contact me with comments, questions, patches, or whatever.

=head1 COPYRIGHT

Copyright (c) 2003 Mike Rosulek. All rights reserved. This module is free 
software; you can redistribute it and/or modify it under the same terms as Perl 
itself.
