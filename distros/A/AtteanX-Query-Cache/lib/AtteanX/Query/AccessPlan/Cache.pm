use 5.010001;
use strict;
use warnings;
use feature "state";

package AtteanX::Query::AccessPlan::Cache;
use Class::Method::Modifiers;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Moo::Role;
use Carp;

with 'MooX::Log::Any';

around 'access_plans' => sub {
	my $orig = shift;
	my @params = @_;
	my $self	= shift;
	my $model = shift;
	my $active_graphs	= shift;
	my $pattern	= shift;

	# First, add any plans coming from the original planner (which will
	# include queries to the remote SPARQL endpoint
	my @plans = $orig->(@params);
	my @vars	= $pattern->values_consuming_role('Attean::API::Variable');
	my @varstrings = map { $_->value } @vars;

	# Start checking the cache
	my $keypattern = $pattern->canonicalize->tuples_string;
	my $cached = $model->cache->get($keypattern);
	if (defined($cached)) {
		$self->log->info("Found data in the cache for " . $keypattern);
		my $parser = Attean->get_parser('NTriples')->new(lazy_iris => 1);
		my $iter;
		my $size = 0;
		if (ref($cached) eq 'ARRAY') {
			$size = scalar @{$cached};
			# Then, the cache resulted from a TP with just one variable
			$iter = Attean::CodeIterator->new(
														 generator => sub {
															 state $i = 0;
															 return undef if ($i > $#{$cached});
															 my $term = $parser->parse_term_from_string(${$cached}[$i]);
															 $i++;
															 return Attean::Result->new(bindings => { $vars[0]->value => $term });
														 },
														 item_type => 'Attean::API::Result',
														 variables => \@varstrings
														);
		} elsif (ref($cached) eq 'HASH') {
			# Cache resulted from TP with two variables
			my @firsts = keys(%{$cached});
			$size = scalar @firsts;
			$iter = Attean::CodeIterator->new(
														 generator => sub {
															 state $i = 0;
															 return undef if ($i > $#firsts);
															 state $j = 0;
															 my $term1 = $parser->parse_term_from_string($firsts[$i]);
															 my @seconds = @{${$cached}{$firsts[$i]}};
															 my $term2 = $parser->parse_term_from_string($seconds[$j]);
															 $j++;
															 if ($j > $#seconds) {
																 $j = 0;
																	 $i++;
															 }
															 return Attean::Result->new(bindings => {$vars[0]->value => $term1,
																												  $vars[1]->value => $term2});
														 },
														 item_type => 'Attean::API::Result',
														 variables => \@varstrings
														);
		} else {
			croak 'Unknown data structure found in cache for key ' . $keypattern;
		}
		push(@plans, Attean::Plan::Iterator->new( variables => \@vars,
																iterator => $iter,
																size_estimate => $size,
																distinct => 0,
																ordered => [] ));
	} else {
		$self->log->debug("Found no data in the cache for " . $keypattern);
	}

	return @plans;
};


sub _join_vars {
	my ($self, $lhs, $rhs) = @_;
	my @vars	= (@{ $lhs->in_scope_variables }, @{ $rhs->in_scope_variables });
	my %vars;
	my %join_vars;
	foreach my $v (@vars) {
		if ($vars{$v}++) {
			$join_vars{$v}++;
		}
	}
	return keys %join_vars;	
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AtteanX::Query::AccessPlan::Cache - Role to create plans for accessing triples in the cache.

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

