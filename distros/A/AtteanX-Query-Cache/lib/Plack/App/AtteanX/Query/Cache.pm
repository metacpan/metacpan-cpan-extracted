package Plack::App::AtteanX::Query::Cache;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Attean;
use Attean::RDF;
use RDF::Trine;
use Moo;
use AtteanX::Endpoint;
use CHI;
use Redis;
use LWP::UserAgent::CHICaching;
use AtteanX::Model::SPARQLCache::LDF;
use AtteanX::QueryPlanner::Cache::LDF;
use AtteanX::Query::Cache;
use Try::Tiny;

extends 'Plack::App::AtteanX::Endpoint';
with 'MooX::Log::Any';

sub prepare_app {
	my $self = shift;
	my $config = $self->{config};
	my $redisserver = 'robin.kjernsmo.net:6379';
	my $sparqlurl = 'http://dbpedia.org/sparql';
	my $ldfurl = 'http://fragments.dbpedia.org/2015/en';
	my $sparqlstore = Attean->get_store('SPARQL')->new(endpoint_url => $sparqlurl);
	my $ldfstore    = Attean->get_store('LDF')->new(start_url => $ldfurl);
	my $cache = CHI->new(
								driver => 'Redis',
								namespace => 'cache',
								server => $redisserver,
								debug => 0
							  );
	my $redissub = Redis->new(server => $redisserver, name => 'subscriber');

	RDF::Trine::default_useragent(LWP::UserAgent::CHICaching->new(cache => $cache));

	my $model	= AtteanX::Model::SPARQLCache::LDF->new( store => $sparqlstore,
																		  ldf_store => $ldfstore,
																		  cache => $cache,
																		  publisher => $redissub);
	$self->{config} = {};

#	try {
	$self->{endpoint} = AtteanX::Query::Cache->new(model => $model,
																  planner => AtteanX::QueryPlanner::Cache->new,
																  conf => $self->{config},
																  graph => iri('http://example.org/graph'));
	#	  };
#	if ($@) {
#		$self->log->error($@);
#	}
}

1;
