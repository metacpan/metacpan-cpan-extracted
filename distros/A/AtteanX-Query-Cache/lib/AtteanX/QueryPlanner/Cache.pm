use 5.010001;
use strict;
use warnings;


package AtteanX::QueryPlanner::Cache;
use Class::Method::Modifiers;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Moo;
use Types::Standard qw(InstanceOf);
use Attean::RDF qw(triplepattern variable iri);
use Carp;
use AtteanX::Plan::SPARQLBGP;

extends 'Attean::QueryPlanner';
with 'Attean::API::NaiveJoinPlanner', 'Attean::API::SimpleCostPlanner';

with 'AtteanX::API::JoinRotatingPlanner', 'MooX::Log::Any';

with 'AtteanX::Query::AccessPlan::SingleQuadBGP', 'AtteanX::Query::AccessPlan::Cache';

# Only allow rotation on joins who have one child matching: - Either a
# Attean::Plan::Quad or AtteanX::Plan::SPARQLBGP and the
# other child being a join

sub allow_join_rotation {
	my $self	= shift;
	my $join	= shift;
	my $quads = 0;
	my $joins = 0;
	my @grandchildren;
 	$self->log->trace("Seeking to rotate:\n" . $join->as_string);
	foreach my $p (@{ $join->children }) {
		$quads++ if ($p->isa('Attean::Plan::Quad'));
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

sub coalesce_rotated_join {
	my $self	= shift;
	my $p		= shift;
	my @quads;
	my ($lhs, $rhs)	= @{ $p->children };
	my @join_vars	= $self->_join_vars($lhs, $rhs);
	if (scalar(@join_vars)) {
		foreach my $q ($lhs, $rhs) {
			if ($q->isa('Attean::Plan::Quad')) {
				push(@quads, $q);
			} elsif ($q->isa('AtteanX::Plan::SPARQLBGP')) {
				push(@quads, @{ $q->children });
			} else {
				return $p; # bail-out
			}
		}
		my $count	= scalar(@quads);
		my $c	= AtteanX::Plan::SPARQLBGP->new(children => \@quads, distinct => 0);
		if ($self->log->is_debug && $count >= 2) {
		 	$self->log->debug("Coalescing $lhs and $rhs into BGP with $count quads");
		 	$self->log->trace($c->as_string);
		}
		return $c;
	}
	return $p;
}

# Gather patterns into larger BGPs
around 'join_plans' => sub {
	my $orig = shift;
	my @params = @_;
	my $self	= shift;
	my $model			= shift;
	my $active_graphs	= shift;
	my $default_graphs	= shift;
	my $lplans			= shift;
	my $rplans			= shift;
	my @restargs      = @_;
	my @plans;
	foreach my $lhs (@{ $lplans }) {
		$self->log->trace("BGP Constructing Left:\n" . $lhs->as_string);
		foreach my $rhs (@{ $rplans }) {
			$self->log->trace("BGP Constructing Right:\n" . $rhs->as_string);
			my @join_vars = $self->_join_vars($lhs, $rhs);

			if ($lhs->isa('Attean::Plan::Iterator') && ($rhs->isa('Attean::Plan::Iterator'))) {
#				push(@plans, $orig->($self, $model, $active_graphs, $default_graphs, [$rhs], [$lhs], @restargs)); # Most general solution
				# Best known solution for now:
				if (scalar(@join_vars) > 0) {
					return Attean::Plan::HashJoin->new(children => [$lhs, $rhs], join_variables => \@join_vars, distinct => 0, ordered => []);
				} else {
					return Attean::Plan::NestedLoopJoin->new(children => [$lhs, $rhs], join_variables => \@join_vars, distinct => 0, ordered => []);
				}
			} elsif ($rhs->isa('AtteanX::Plan::SPARQLBGP') &&
					 $lhs->isa('AtteanX::Plan::SPARQLBGP')) {
				if (scalar(@join_vars)) {
					push(@plans, AtteanX::Plan::SPARQLBGP->new(children => [@{ $lhs->children || []} , @{ $rhs->children || []} ], distinct => 0, ordered => []));
				} else {
					push(@plans, $orig->($self, $model, $active_graphs, $default_graphs, [$lhs], [$rhs], @restargs));
				}
			} else {
				push(@plans, $orig->($self, $model, $active_graphs, $default_graphs, [$lhs], [$rhs], @restargs));
			}

		}
	}

	unless (@plans) {
		@plans = $orig->(@params);
	}
	return @plans;
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AtteanX::QueryPlanner::Cache - Extending the query planner with cache and SPARQL support

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

