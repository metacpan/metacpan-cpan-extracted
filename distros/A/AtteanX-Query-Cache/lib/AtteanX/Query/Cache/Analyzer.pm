package AtteanX::Query::Cache::Analyzer;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Moo;
use Attean::RDF qw(triplepattern variable iri);
use Types::Standard qw(Str Int InstanceOf ConsumerOf);
use Types::URI -all;
use AtteanX::Parser::SPARQL;
use AtteanX::Query::Cache::Analyzer::Model;
use AtteanX::QueryPlanner::Cache;
use AtteanX::Query::Cache::Analyzer::QueryPlanner;
use AtteanX::Query::Cache::Retriever;

use Carp;

has 'query' => (is => 'ro', required => 1, isa => Str);
has 'algebra' => (is => 'ro', isa => ConsumerOf['Attean::API::Algebra'], builder => '_parse_query', lazy => 1);
has 'base_uri' => (is => 'ro', default => 'http://default.invalid/');

has 'model' => (is => 'ro', isa => InstanceOf['AtteanX::Query::Cache::Analyzer::Model'], required => 1);

has 'graph' => (is => 'ro', isa => InstanceOf['Attean::IRI'], default => sub { return iri('http://example.invalid')});

has 'improvement_threshold' => (is => 'ro', isa => Int, default => '10');
has 'improvement_top' => (is => 'ro', isa => Int, default => '3');

has 'count_threshold' => (is => 'ro', isa => Int, default => '3');

has 'max_triples' => (is => 'ro', isa => Int, default => sub { return $ENV{'LDF_MAX_TRIPLES'} || 100000 });

with 'MooX::Log::Any';

=pod

=over

=item C<< store >>

A L<Redis> object. This has two purposes: First, to store any
data the analyzer needs to persist to decide when to prefetch. Second,
it uses Redis' publish-subscribe system to publish the URLs containing
queries that the prefetcher should fetch.

=cut

has store => (is => 'ro',
				  isa => InstanceOf['Redis'],
				  required => 1
				 );

sub _parse_query {
	my $self = shift;
	my $parser = AtteanX::Parser::SPARQL->new();
	my ($algebra) = $parser->parse_list_from_bytes($self->query, $self->base_uri); # TODO: this is a bit of cargocult
	return $algebra;
}

sub best_cost_improvement {
	my $self = shift;
	# First, we find the cost of the plan with the current cache:
	my $algebra = $self->algebra;
	my $curplanner = AtteanX::QueryPlanner::Cache::LDF->new;
	my $curplan = $curplanner->plan_for_algebra($algebra, $self->model, [$self->graph]);
	my $curcost = $curplanner->cost_for_plan($curplan, $self->model);
	$self->log->trace("Cost of incumbent plan: $curcost");
	my %costs;
	my %triples;
	my $percentage = 1-($self->improvement_threshold/100);
	my $planner = AtteanX::Query::Cache::Analyzer::QueryPlanner->new;
	foreach my $bgp ($algebra->subpatterns_of_type('Attean::Algebra::BGP')) { # TODO: Parallelize
		foreach my $triple (@{ $bgp->triples }) { # TODO: May need quads
			my $key = $triple->canonicalize->tuples_string;
			next if ($self->model->is_cached($key));
			next if ($self->model->ldf_store->count_triples_estimate($triple->values) > $self->max_triples);
			$self->model->try($key);
			if ($self->log->is_trace) {
				foreach my $plan ($planner->plans_for_algebra($algebra, $self->model, [$self->graph])) {
					my $cost = $planner->cost_for_plan($plan, $self->model);
					$self->log->trace("Cost $cost for:\n" . $plan->as_string);
				}
			}
			my $plan = $planner->plan_for_algebra($algebra, $self->model, [$self->graph]);
			$self->log->debug("Alternative plan after fetching $key:\n" . $plan->as_string);
			$costs{$key} = $planner->cost_for_plan($plan, $self->model);
			$self->log->info("Triple $key has cost $costs{$key}, current $curcost");
			if ($costs{$key} < $curcost * $percentage) {
				$triples{$key} = $triple;
			}
		}
	}
	no sort 'stable';
	my @worthy = map { $triples{$_} } sort {$costs{$a} <=> $costs{$b}} keys(%triples);
	return splice(@worthy,0, $self->improvement_top-1);
}


=item C<< count_patterns >>

Loops the triple patterns, checks if any of them have a cached result
(TODO) and increments the number of times a certain predicate has been
seen in the store. When that number exceeds the C<count_threshold>, a
single-element array of L<Attean::TriplePattern>s will be returned.


=back

=cut

sub count_patterns {
	my $self = shift;
	my $algebra = $self->algebra;
	my @worthy = ();
	# TODO: Return undef if we can't process the query
	foreach my $bgp ($algebra->subpatterns_of_type('Attean::Algebra::BGP')) {
		foreach my $triple (@{ $bgp->triples }) { # TODO: May need quads
			my $patternkey = $triple->canonicalize->tuples_string; # This is the key for the triple we process
			next if ($self->model->is_cached($patternkey));
			next if ($self->model->ldf_store->count_triples_estimate($triple->values) > $self->max_triples);
			my $key = $triple->predicate->as_string; # This is the key for the predicate we count
			# Update the storage and return the triple pattern
			$self->store->incr($key);
			my $count = $self->store->get($key);
			$self->log->debug("Count for key '$key' in database is $count");
			if ($count >= $self->count_threshold) { # TODO: A way to expire counts
				$self->log->info("Triple '$patternkey' has predicate with $count counts");
				push(@worthy, $triple);
			}
		}
	}
	return @worthy;
}

sub analyze_and_cache {
	my ($self, @analyzers) = @_;
	croak 'No analyzers given to analyze and cache' unless @analyzers;
	if ($analyzers[0] eq 'all') {
		@analyzers = ('count_patterns', 'best_cost_improvement');
	}
	foreach my $analyzer (@analyzers) {
		croak "Could not find analyzer method $analyzer" unless $self->can($analyzer);
	}
	$self->log->info('Running analyzers named ' . join(', ', @analyzers));
	my $retriever = AtteanX::Query::Cache::Retriever->new(model => $self->model); # TODO: Only OK if we don't do query planning
	my $i = 0;
	my %done;
	foreach my $analyzer (@analyzers) {
		foreach my $triple ($self->$analyzer) {
			my $key = $triple->canonicalize->tuples_string;
			next if $done{$key}; # Skip if some other analyzer already did fetch
			$self->log->debug('Fetching triple pattern ' . $triple->as_string);
			my $data = $retriever->fetch($triple);
			if (defined($data)) {
				$done{$key} = 1;
				$i++;
			}
			$self->model->cache->set($key, $data);
		}
	}
	$self->log->info("Got results from prefetching $i triple patterns");
	return $i;
}

1;
