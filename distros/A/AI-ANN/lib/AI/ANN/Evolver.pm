#!/usr/bin/perl
package AI::ANN::Evolver;
BEGIN {
  $AI::ANN::Evolver::VERSION = '0.008';
}
# ABSTRACT: an evolver for an artificial neural network simulator

use strict;
use warnings;

use Moose;

use AI::ANN;
use Storable qw(dclone);
use Math::Libm qw(tan);


has 'max_value' => (is => 'rw', isa => 'Num', default => 1);
has 'min_value' => (is => 'rw', isa => 'Num', default => 0);
has 'mutation_chance' => (is => 'rw', isa => 'Num', default => 0);
has 'mutation_amount' => (is => 'rw', isa => 'CodeRef', default => sub{sub{2 * rand() - 1}});
has 'add_link_chance' => (is => 'rw', isa => 'Num', default => 0);
has 'kill_link_chance' => (is => 'rw', isa => 'Num', default => 0);
has 'sub_crossover_chance' => (is => 'rw', isa => 'Num', default => 0);
has 'gaussian_tau' => (is => 'rw', isa => 'CodeRef', default => sub{sub{1/sqrt(2*sqrt(shift))}});
has 'gaussian_tau_prime' => (is => 'rw', isa => 'CodeRef', default => sub{sub{1/sqrt(2*shift)}});

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %data;
    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        %data = %{$_[0]};
    } else {
        %data = @_;
    }
    if ((not (ref $data{'mutation_amount'})) || ref $data{'mutation_amount'} ne 'CODE') {
	my $range = $data{'mutation_amount'};
        $data{'mutation_amount'} = sub { $range * (rand() * 2 - 1) };
    }
    return $class->$orig(%data);
};


sub crossover {
	my $self = shift;
	my $network1 = shift;
	my $network2 = shift;
	my $class = ref($network1);
	my $inputcount = $network1->input_count();
	my $minvalue = $network1->minvalue();
	my $maxvalue = $network1->maxvalue();
	my $afunc = $network1->afunc();
	my $dafunc = $network1->dafunc();
	# They better have the same number of inputs
	$inputcount == $network2->input_count() || return -1; 
	my $networkdata1 = $network1->get_internals();
	my $networkdata2 = $network2->get_internals();
	my $neuroncount = $#{$networkdata1};
	# They better also have the same number of neurons
	$neuroncount == $#{$networkdata2} || return -1;
	my $networkdata3 = [];

	for (my $i = 0; $i <= $neuroncount; $i++) {
		if (rand() < $self->{'sub_crossover_chance'}) {
			$networkdata3->[$i] = { 'inputs' => [], 'neurons' => [] };
			$networkdata3->[$i]->{'iamanoutput'} = 
				$networkdata1->[$i]->{'iamanoutput'};
			for (my $j = 0; $j < $inputcount; $j++) {
				$networkdata3->[$i]->{'inputs'}->[$j] = 
					(rand() > 0.5) ?
					$networkdata1->[$i]->{'inputs'}->[$j] :
					$networkdata2->[$i]->{'inputs'}->[$j];
				# Note to self: Don't get any silly ideas about dclone()ing 
				# these, that's a good way to waste half an hour debugging.
			}
			for (my $j = 0; $j <= $neuroncount; $j++) {
				$networkdata3->[$i]->{'neurons'}->[$j] =
					(rand() > 0.5) ?
					$networkdata1->[$i]->{'neurons'}->[$j] :
					$networkdata2->[$i]->{'neurons'}->[$j];
			}
		} else {
			$networkdata3->[$i] = dclone(
				(rand() > 0.5) ?
				$networkdata1->[$i] :
				$networkdata2->[$i] );
		}		
	}
	my $network3 = $class->new ( 'inputs' => $inputcount, 
								  'data' => $networkdata3,
								  'minvalue' => $minvalue,
								  'maxvalue' => $maxvalue,
								  'afunc' => $afunc,
								  'dafunc' => $dafunc);
	return $network3;
}


sub mutate {
	my $self = shift;
	my $network = shift;
	my $class = ref($network);
	my $networkdata = $network->get_internals();
	my $inputcount = $network->input_count();
	my $minvalue = $network->minvalue();
	my $maxvalue = $network->maxvalue();
	my $afunc = $network->afunc();
	my $dafunc = $network->dafunc();
	my $neuroncount = $#{$networkdata}; # BTW did you notice that this 
										# isn't what it says it is?
	$networkdata = dclone($networkdata); # For safety.
	for (my $i = 0; $i <= $neuroncount; $i++) {
		# First each input/neuron pair
		for (my $j = 0; $j < $inputcount; $j++) {
			my $weight = $networkdata->[$i]->{'inputs'}->[$j];
			if (defined $weight && $weight != 0) {
				if (rand() < $self->{'mutation_chance'}) {
					$weight += (rand() * 2 - 1) * $self->{'mutation_amount'};
					if ($weight > $self->{'max_value'}) { 
						$weight = $self->{'max_value'};
					}
					if ($weight < $self->{'min_value'}) { 
						$weight = $self->{'min_value'} + 0.000001;
					}
				} 
				if (abs($weight) < $self->{'mutation_amount'}) {
					if (rand() < $self->{'kill_link_chance'}) {
						$weight = undef;
					}
				}
			} else {
				if (rand() < $self->{'add_link_chance'}) {
					$weight = rand() * $self->{'mutation_amount'};
					# We want to Do The Right Thing. Here, that means to 
					# detect whether the user is using weights in (0, x), and
					# if so make sure we don't accidentally give them a 
					# negative weight, because that will become 0.000001. 
					# Instead, we'll generate a positive only value at first 
					# (it's easier) and then, if the user will accept negative 
					# weights, we'll let that happen.
					if ($self->{'min_value'} < 0) {
						($weight *= 2) -= $self->{'mutation_amount'};
					}
					# Of course, we have to check to be sure...
					if ($weight > $self->{'max_value'}) { 
						$weight = $self->{'max_value'};
					}
					if ($weight < $self->{'min_value'}) { 
						$weight = $self->{'min_value'} + 0.000001;
					}
					# But we /don't/ need to to a kill_link_chance just yet.
				}
			}
			# This would be a bloody nightmare if we hadn't done that dclone 
			# magic before. But look how easy it is!
			$networkdata->[$i]->{'inputs'}->[$j] = $weight;
		}
		# Now each neuron/neuron pair
		for (my $j = 0; $j <= $neuroncount; $j++) {
		# As a reminder to those cursed with the duty of maintaining this code:
		# This should be an exact copy of the code above, except that 'inputs' 
		# would be replaced with 'neurons'. 
			my $weight = $networkdata->[$i]->{'neurons'}->[$j];
			if (defined $weight && $weight != 0) {
				if (rand() < $self->{'mutation_chance'}) {
					$weight += (rand() * 2 - 1) * $self->{'mutation_amount'};
					if ($weight > $self->{'max_value'}) { 
						$weight = $self->{'max_value'};
					}
					if ($weight < $self->{'min_value'}) { 
						$weight = $self->{'min_value'} + 0.000001;
					}
				} 
				if (abs($weight) < $self->{'mutation_amount'}) {
					if (rand() < $self->{'kill_link_chance'}) {
						$weight = undef;
					}
				}

			} else {
				if (rand() < $self->{'add_link_chance'}) {
					$weight = rand() * $self->{'mutation_amount'};
					# We want to Do The Right Thing. Here, that means to 
					# detect whether the user is using weights in (0, x), and
					# if so make sure we don't accidentally give them a 
					# negative weight, because that will become 0.000001. 
					# Instead, we'll generate a positive only value at first 
					# (it's easier) and then, if the user will accept negative 
					# weights, we'll let that happen.
					if ($self->{'min_value'} < 0) {
						($weight *= 2) -= $self->{'mutation_amount'};
					}
					# Of course, we have to check to be sure...
					if ($weight > $self->{'max_value'}) { 
						$weight = $self->{'max_value'};
					}
					if ($weight < $self->{'min_value'}) { 
						$weight = $self->{'min_value'} + 0.000001;
					}
					# But we /don't/ need to to a kill_link_chance just yet.
				}
			}
			# This would be a bloody nightmare if we hadn't done that dclone 
			# magic before. But look how easy it is!
			$networkdata->[$i]->{'neurons'}->[$j] = $weight;
		}
		# That was rather tiring, and that's only for the first neuron!!
	}
	# All done. Let's pack it back into an object and let someone else deal
	# with it.
	$network = $class->new ( 'inputs' => $inputcount, 
							 'data' => $networkdata,
							 'minvalue' => $minvalue,
							 'maxvalue' => $maxvalue,
							 'afunc' => $afunc,
							 'dafunc' => $dafunc);
	return $network;
}


sub mutate_gaussian {
    my $self = shift;
    my $network = shift;
	my $class = ref($network);
	my $networkdata = $network->get_internals();
	my $inputcount = $network->input_count();
	my $minvalue = $network->minvalue();
	my $maxvalue = $network->maxvalue();
	my $afunc = $network->afunc();
	my $dafunc = $network->dafunc();
	my $neuroncount = $#{$networkdata}; # BTW did you notice that this 
										# isn't what it says it is?
	$networkdata = dclone($networkdata); # For safety.
	for (my $i = 0; $i <= $neuroncount; $i++) {
        my $n = 0;
        for (my $j = 0; $j < $inputcount; $j++) {
			my $weight = $networkdata->[$i]->{'inputs'}->[$j];
            $n++ if $weight;
        }
        for (my $j = 0; $j <= $neuroncount; $j++) {
			my $weight = $networkdata->[$i]->{'neurons'}->[$j];
            $n++ if $weight;
        }
        next if $n == 0;
        my $tau = &{$self->{'gaussian_tau'}}($n);
        my $tau_prime = &{$self->{'gaussian_tau_prime'}}($n);
        my $random1 = 2 * rand() - 1;
        for (my $j = 0; $j < $inputcount; $j++) {
			my $weight = $networkdata->[$i]->{'inputs'}->[$j];
            next unless $weight;
            my $random2 = 2 * rand() - 1;
			$networkdata->[$i]->{'eta_inputs'}->[$j] *= exp($tau_prime*$random1+$tau*$random2);
			$networkdata->[$i]->{'inputs'}->[$j] += $networkdata->[$i]->{'eta_inputs'}->[$j]*$random2;
        }
        for (my $j = 0; $j <= $neuroncount; $j++) {
			my $weight = $networkdata->[$i]->{'neurons'}->[$j];
            next unless $weight;
            my $random2 = 2 * rand() - 1;
			$networkdata->[$i]->{'eta_neurons'}->[$j] *= exp($tau_prime*$random1+$tau*$random2);
			$networkdata->[$i]->{'neurons'}->[$j] += $networkdata->[$i]->{'eta_neurons'}->[$j]*$random2;
        }
    }
	# All done. Let's pack it back into an object and let someone else deal
	# with it.
	$network = $class->new ( 'inputs' => $inputcount, 
							 'data' => $networkdata,
							 'minvalue' => $minvalue,
							 'maxvalue' => $maxvalue,
							 'afunc' => $afunc,
							 'dafunc' => $dafunc);
	return $network;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

AI::ANN::Evolver - an evolver for an artificial neural network simulator

=head1 VERSION

version 0.008

=head1 METHODS

=head2 new

AI::ANN::Evolver->new( { mutation_chance => $mutationchance, 
	mutation_amount => $mutationamount, add_link_chance => $addlinkchance, 
	kill_link_chance => $killlinkchance, sub_crossover_chance => 
	$subcrossoverchance, min_value => $minvalue, max_value => $maxvalue } )

All values have a sane default.

mutation_chance is the chance that calling mutate() will add a random value
	on a per-link basis. It only affects existing (nonzero) links. 
mutation_amount is the maximum change that any single mutation can introduce. 
	It affects the result of successful mutation_chance rolls, the maximum 
	value after an add_link_chance roll, and the maximum strength of a link 
	that can be deleted by kill_link_chance rolls. It can either add or 
	subtract.
add_link_chance is the chance that, during a mutate() call, each pair of 
	unconnected neurons or each unconnected neuron => input pair will 
	spontaneously develop a connection. This should be extremely small, as
	it is not an overall chance, put a chance for each connection that does
	not yet exist. If you wish to ensure that your neural net does not become 
	recursive, this must be zero. 
kill_link_chance is the chance that, during a mutate() call, each pair of 
	connected neurons with a weight less than mutation_amount or each 
	neuron => input pair with a weight less than mutation_amount will be
	disconnected. If add_link_chance is zero, this should also be zero, or 
	your network will just fizzle out.
sub_crossover_chance is the chance that, during a crossover() call, each 
	neuron will, rather than being inherited fully from each parent, have 
	each element within it be inherited individually.
min_value is the smallest acceptable weight. It must be less than or equal to 
	zero. If a value would be decremented below min_value, it will instead 
	become an epsilon above min_value. This is so that we don't accidentally 
	set a weight to zero, thereby killing the link.
max_value is the largest acceptable weight. It must be greater than zero.
gaussian_tau and gaussian_tau_prime are the terms to the gaussian mutation 
    method. They are coderefs which accept one parameter, n, the number of
    non-zero-weight inputs to the given neuron.

=head2 crossover

$evolver->crossover( $network1, $network2 )

Returns a $network3 consisting of the shuffling of $network1 and $network2
As long as the same neurons in network1 and network2 are outputs, network3 
	will always have those same outputs.
This method, at least if the sub_crossover_chance is nonzero, expects neurons 
	to be labeled from zero to n. 
You probably don't want to do this. This is the least effective way to evolve 
    neural networks. This is because, due to the hidden intermediate steps, it 
    is possible for two networks which output exactly the same with completely
    different internal representations.

=head2 mutate

$evolver->mutate($network)

Returns a version of $network mutated according to the parameters set for 
	$evolver, followed by a series of counters. The original is not modified. 
	The counters are, in order, the number of times we compared against the 
	following thresholds: mutation_chance, kill_link_chance, add_link_chance. 
	This is useful if you want to try to normalize your probabilities. For 
	example, if you want to make links be killed about as often as they are 
	added, keep a running total of the counters, and let:
	$kill_link_chance = $add_link_chance * $add_link_counter / $kill_link_counter
	This will probably make kill_link_chance much larger than add_link_chance, 
	but in doing so will make links be added at overall the same rate as they 
	are killed. Since new links tend to be killed particularly quickly, it may 
	be wise to add an additional optional multiplier to mutation_amount just 
	for new links.

=head2 mutate_gaussian

$evolver->mutate_gaussian($network)

Returns a version of $network modified according to the Gaussian mutation 
    rules discussed in X. Yao, Evolving Artifical Neural Networks, and X. Yao 
    and Y. Liu, Fast Evolution Strategies. Uses the gaussian_tau and 
    gaussian_tau_prime values from the initializer if they are present, or
    sane defaults proposed by the above. These are both functions of 'n', the 
    number of inputs to each neuron with nonzero weight.

=head1 AUTHOR

Dan Collins <DCOLLINS@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dan Collins.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

