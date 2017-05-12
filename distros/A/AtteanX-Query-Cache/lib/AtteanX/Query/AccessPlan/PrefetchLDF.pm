use 5.010001;
use strict;
use warnings;


package AtteanX::Query::AccessPlan::PrefetchLDF;
use Class::Method::Modifiers;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Moo::Role;
use Carp;
use RDF::LDF;
use AtteanX::Plan::LDF::Triple::EnterCache;


around 'access_plans' => sub {
	my $orig = shift;
	my @params = @_;
	my $self	= shift;
	my $model = shift;
	my $active_graphs	= shift;
	my $pattern	= shift;

	my $max_triples = $ENV{'LDF_MAX_TRIPLES'} || 100000;

	# First, add any plans coming from the original planner (which will
	# include queries to the remote SPARQL endpoint
	my @plans = $orig->(@params);

	# Add my plans
	# Cache only below a limit for how many LDF triples we will fetch.
	if ($model->has_publisher && $model->ldf_store->count_triples_estimate($pattern->values) <= $max_triples) {
		push(@plans, AtteanX::Plan::LDF::Triple::EnterCache->new(subject => $pattern->subject,
																					predicate => $pattern->predicate,
																					object => $pattern->object,
																					distinct => 0));
	} else {
		push(@plans, AtteanX::Plan::LDF::Triple->new(subject => $pattern->subject,
																	predicate => $pattern->predicate,
																	object => $pattern->object,
																	distinct => 0));
	}

	return @plans;
};

1;

__END__

=pod

=head1 NAME

AtteanX::Query::AccessPlan::LDF - An access plan for Linked Data Fragments

=head1 DESCRIPTION

This provides the implementation of a L<Moo::Role> that serves to wrap
any C<access_plan> in query planning. An access plan introduces a plan
object for a triple or quad pattern, in this case a
L<AtteanX::Plan::LDF::Triple> object.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2016 by Kjetil Kjernsmo

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

