use 5.010001;
use strict;
use warnings;


package AtteanX::QueryPlanner::Cache::LDF;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Moo;
use AtteanX::Query::AccessPlan::PrefetchLDF;

extends 'AtteanX::QueryPlanner::Cache';
with 'AtteanX::Query::AccessPlan::PrefetchLDF';

# Only allow rotation on joins who have one child matching: - Either a
# Attean::Plan::Quad, AtteanX::Plan::SPARQLBGP, or
# AtteanX::Plan::LDF::Triple and the other child being a join

sub allow_join_rotation {
	my $self	= shift;
	my $join	= shift;
	my $quads	= shift // 0;
	my $joins	= 0;
	my @grandchildren;
 	$self->log->trace("Seeking to rotate:\n" . $join->as_string);
	foreach my $p (@{ $join->children }) {
		$quads++ if ($p->isa('Attean::Plan::Quad'));
		$quads++ if ($p->isa('AtteanX::Plan::LDF::Triple'));
		$quads++ if ($p->isa('AtteanX::Plan::SPARQLBGP'));
		if ($p->does('Attean::API::Plan::Join')) {
			$joins++;
			push(@grandchildren, @{ $p->children });
		}
	}
	return 0 unless ($joins == 1);
	return 0 unless ($quads == 1);
	foreach my $p (@grandchildren) {
		$quads++ if ($p->isa('Attean::Plan::Quad'));
		$quads++ if ($p->isa('AtteanX::Plan::LDF::Triple'));
		$quads++ if ($p->isa('AtteanX::Plan::SPARQLBGP'));
	}
	
	if ($quads >= 2) {
		$self->log->debug("Allowing rotation for $quads quads.");
		return 1;
	} else {
 		$self->log->debug("Disallowing rotation, just $quads quad.");
		return 0;
	}
}


1;
