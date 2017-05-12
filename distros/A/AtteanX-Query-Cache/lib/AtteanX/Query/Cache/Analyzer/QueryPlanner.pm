use 5.010001;
use strict;
use warnings;


package AtteanX::Query::Cache::Analyzer::QueryPlanner;
use Class::Method::Modifiers;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Moo;
use Attean::RDF qw(triplepattern variable iri);
use Carp;
use feature "state";

extends 'AtteanX::QueryPlanner::Cache::LDF';

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
	
	# Start checking the cache
	my $keypattern = $pattern->canonicalize->tuples_string;
	if ($model->is_cached($keypattern)) {
		$self->log->debug("Already accounted for by cache: $keypattern");
	} elsif ($model->try eq $keypattern) {
		$self->log->debug("Creating dummy iterator for $keypattern");
		my %row;
		foreach my $var (@vars) {
			$row{$var->value} = iri('urn:x-internal:dummy');
		}
		my $iter = Attean::CodeIterator->new(generator => sub {
															 state $i = 0;
															 warn $i;
															 if ($i) {
																 return undef
															 } else {
																 $i++;
																 return Attean::Result->new(bindings => \%row);
															 }
														 },
														 item_type => 'Attean::API::Result',
														 variables => [map { $_->value } @vars]
														);
		push(@plans, Attean::Plan::Iterator->new( variables => \@vars,
																iterator => $iter,
																distinct => 0,
																ordered => [] ));
	}
	return @plans;
};

1;
