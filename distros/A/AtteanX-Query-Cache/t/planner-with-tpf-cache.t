use v5.14;
use autodie;
use utf8;
use Test::Modern;

use CHI;
use Attean;
use Attean::RDF;
use AtteanX::QueryPlanner::Cache::LDF;
#use Carp::Always;
use Data::Dumper;
use AtteanX::Store::SPARQL;
use AtteanX::Store::LDF;
use AtteanX::Model::SPARQLCache::LDF;
use Log::Any::Adapter;
use Redis;
use Test::RedisServer;


Log::Any::Adapter->set($ENV{LOG_ADAPTER}) if ($ENV{LOG_ADAPTER});

my $cache = CHI->new( driver => 'Memory', global => 1 );

my $p	= AtteanX::QueryPlanner::Cache::LDF->new;
isa_ok($p, 'AtteanX::QueryPlanner::Cache::LDF');

my $redis_server = Test::RedisServer->new;
my $redis1 = Redis->new( $redis_server->connect_info );
my $redis2 = Redis->new( $redis_server->connect_info );

is $redis1->ping, 'PONG', 'Redis Pubsub ping pong ok';
is $redis2->ping, 'PONG', 'Redis store ping pong ok';


package TestLDFCreateStore {
        use Moo;
        with 'Test::Attean::Store::LDF::Role::CreateStore';
};

my $test = TestLDFCreateStore->new;


my $sparqlstore	= Attean->get_store('SPARQL')->new('endpoint_url' => iri('http://test.invalid/sparql'));
isa_ok($sparqlstore, 'AtteanX::Store::SPARQL');

my $graph = iri('http://test.invalid/graph');
my $t		= triplepattern(variable('s'), iri('http://example.org/m/p'), literal('1'));
my $u		= triplepattern(variable('s'), iri('http://example.org/m/p'), variable('o'));
my $v		= triplepattern(variable('s'), iri('http://example.org/m/q'), blank('xyz'));
my $w		= triplepattern(variable('a'), iri('http://example.org/m/b'), iri('http://example.org/m/c'));
my $x		= triplepattern(variable('s'), iri('http://example.org/m/q'), iri('http://example.org/m/a'));
my $y		= triplepattern(variable('o'), iri('http://example.org/m/b'), literal('2'));
my $z		= triplepattern(variable('a'), iri('http://example.org/m/c'), variable('s'));
my $s		= triplepattern(iri('http://example.org/m/a'), variable('p'), variable('o'));

my $ldfstore	= $test->create_store(triples => [
																 triple(iri('http://example.org/foo'), iri('http://example.org/m/p'), literal('1')),
																 triple(iri('http://example.org/foo'), iri('http://example.org/m/p'), iri('http://example.org/bar')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/p'), iri('http://example.org/bar')),
																 triple(iri('http://example.org/bar'), iri('http://example.org/m/p'), literal('1')),
																 triple(iri('http://example.org/bar'), iri('http://example.org/m/p'), literal('o')),
																 triple(iri('http://example.org/bar'), iri('http://example.org/m/p'), literal('dahut')),
																 triple(iri('http://example.com/foo'), iri('http://example.org/m/p'), literal('dahut')),
																 triple(iri('http://example.com/foo'), iri('http://example.org/m/p'), iri('http://example.org/baz')),
																 triple(iri('http://example.com/foo'), iri('http://example.org/m/p'), iri('http://example.org/foobar')),
																 triple(iri('http://example.com/bar'), iri('http://example.org/m/p'), literal('dahut')),
																 triple(iri('http://example.org/dahut'), iri('http://example.org/m/dahut'), literal('1')),
																 triple(iri('http://example.org/dahut'), iri('http://example.org/m/dahut'), literal('Foobar')),
																 triple(iri('http://example.org/dahut'), iri('http://example.org/m/q'), literal('xyz')),
																 triple(iri('http://example.com/dahut'), iri('http://example.org/m/b'), iri('http://example.org/m/c')),
																 triple(iri('http://example.com/dahut'), iri('http://example.org/m/b'), literal('2')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/q'), iri('http://example.org/baz')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/q'), iri('http://example.org/foobar')),
																 triple(iri('http://example.org/ma'), iri('http://example.org/m/c'), iri('http://example.org/foo')),
																 triple(iri('http://example.org/m/a'), iri('http://example.org/m/p'), iri('http://example.org/m/o')),
																]);


isa_ok($ldfstore, 'AtteanX::Store::LDF');
my $model	= AtteanX::Model::SPARQLCache::LDF->new( store => $sparqlstore,
																	  ldf_store => $ldfstore,
																	  cache => $cache,
																	  publisher => $redis2);
isa_ok($model, 'AtteanX::Model::SPARQLCache::LDF');

my $checkquery = sub {
	my $string = shift;
	
	subtest "Parsing pattern '$string'" => sub {
		ok($string, 'Pattern is given as string');
		ok(my $pattern = Attean::TriplePattern->parse($string), 'Pattern parsed');
		isa_ok($pattern, 'Attean::TriplePattern');
		is($pattern->canonicalize->tuples_string, '?v002 <http://example.org/m/p> ?v001 .', 'Correct canonicalization');
	};
};

$redis1->subscribe('prefetch.triplepattern', $checkquery);


subtest '1-triple BGP single variable, with cache, not cached' => sub {
	note("A 1-triple BGP should produce a single Attean::Plan::Iterator plan object");
	$cache->set('?v001 <http://example.org/m/p> "1" .', ['<http://example.org/foo>', '<http://example.org/bar>']);
	$cache->set('?v001 <http://example.org/m/p> "dahut" .', ['<http://example.com/foo>', '<http://example.com/bar>']);
	$cache->set('?v001 <http://example.org/m/dahut> "1" .', ['<http://example.org/dahut>']);
	# plan skip_all => 'it works';
	
	ok($model->is_cached(triplepattern(variable('foo'), iri('http://example.org/m/p'), literal('1'))->canonicalize->tuples_string), 'Cache has been set');
	my $bgp		= Attean::Algebra::BGP->new(triples => [$u]);
	my @plans = $p->plans_for_algebra($bgp, $model, [$graph]);
	my $plan = shift @plans;
	does_ok($plan, 'Attean::API::Plan', '1-triple BGP');
	isa_ok($plan, 'AtteanX::Plan::LDF::Triple::EnterCache');
	is($plan->plan_as_string, 'LDFTriple { ?s, <http://example.org/m/p>, ?o } (publish)', 'Good LDF plan');
	ok($plan->impl($model), 'Run plan');
	is($redis1->wait_for_messages(1), 1, 'Got a message');
};


done_testing;
