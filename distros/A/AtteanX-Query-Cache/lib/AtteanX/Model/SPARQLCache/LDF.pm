package AtteanX::Model::SPARQLCache::LDF;


use v5.14;
use warnings;

use Moo;
use Types::Standard qw(InstanceOf);
use Class::Method::Modifiers;
use List::MoreUtils qw(any);
use namespace::clean;

extends 'AtteanX::Model::SPARQLCache';
with 'MooX::Log::Any';

has 'ldf_store' => (is => 'ro',
						  isa => InstanceOf['AtteanX::Store::LDF'],
						  required => 1);

has 'publisher' => (is => 'ro',
					  isa => InstanceOf['Redis'],
					  predicate => 'has_publisher'
					 );

around 'cost_for_plan' => sub {
	my $orig = shift;
	my @params = @_;
	my $self	= shift;
 	my $plan	= shift;
 	my $planner	= shift;
	my @passthroughs = qw/Attean::Plan::Iterator Attean::Plan::Quad/;
	my $cost = $orig->(@params);
	if ($self->log->is_debug) {
		my $logcost = $cost || 'not defined';
		$self->log->debug('Cost for original plan \'' . ref($plan) . "' was $logcost.");
	}
	if ($plan->isa('AtteanX::Plan::LDF::Triple')) {
		$cost = $self->ldf_store->cost_for_plan($plan, $planner);
		return $cost;
	}
	if ($cost && any { $plan->isa($_) } @passthroughs) {
		# In here, we just pass the plans that probably do not need
		# balancing against others
		$self->log->debug("Use original's cost for '" . ref($plan) . "'");
		return $cost;
	} 
	# This is where the plans that needs to be balanced against LDFs go
	if ($plan->isa('AtteanX::Plan::SPARQLBGP')) {
		if ($cost <= 1000 && (scalar(@{ $plan->children }) == 1)) {
			$self->log->trace("Set cost for single BGP SPARQL plan");
			$cost = 1001;
		} else {
			$cost = ($cost + 1) * 5;
		}
		return $cost;
	}
	if ($plan->does('Attean::API::Plan::Join')) {
		# Then, penalize the plan by the number of LDFs
		my $countldfs = scalar $plan->subpatterns_of_type('AtteanX::Plan::LDF::Triple');
		return unless ($countldfs);
		unless ($cost) {
			my @children	= @{ $plan->children };
			if ($plan->isa('Attean::Plan::NestedLoopJoin')) {
				my $lcost		= $planner->cost_for_plan($children[0], $self);
				my $rcost		= $planner->cost_for_plan($children[1], $self);
				if ($lcost == 0) {
					$cost	= $rcost;
				} elsif ($rcost == 0) {
					$cost	= $lcost;
				} else {
					$cost	= $lcost * $rcost;
				}
				$cost++ if ($rcost > $lcost);
			} elsif ($plan->isa('Attean::Plan::HashJoin')) {
				my $lcost		= $planner->cost_for_plan($children[0], $self);
				my $rcost		= $planner->cost_for_plan($children[1], $self);
				$cost	= ($lcost + $rcost);
				$cost++ if ($rcost > $lcost);
			}
		}
		unless ($plan->children_are_variable_connected) {
			$cost	*= 10 if $plan->isa('Attean::Plan::NestedLoopJoin');
			$cost	*= 100 if $plan->isa('Attean::Plan::HashJoin');
		}

		$cost *= $countldfs; # TODO: This is assuming that it is better to join remotely
	}

	# Now, penalize plan if any SPARQLBGP has a common variable with a LDFTriple
	my %bgpvars;
	my %ldfvars;
	my $shared = 0;
	$plan->walk(prefix => sub {
						my $node = shift;
						if ($node->isa('AtteanX::Plan::SPARQLBGP')) {
							map { $bgpvars{$_} = 1 } @{$node->in_scope_variables};
						}
						elsif ($node->isa('AtteanX::Plan::LDF::Triple')) {
							map { $ldfvars{$_} = 1 } @{$node->in_scope_variables};
							# TODO: A single loop should be sufficient
						}
						foreach my $lid (keys(%ldfvars)) {
							if ($bgpvars{$lid}) {
								$shared = $lid;
								last;
								# TODO: Jump out of the walk here
							}
						}
					});
	if ($shared) {
		$self->log->debug("Penalizing for SPARQL and LDF common variable '?$shared'.");
		$cost += 1000;
	}
#		$cost *= 10; # TODO: Just multiply by a factor for now...
	
	return $cost;
};



1;
