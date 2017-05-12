use strict;
use warnings;
use Test::More;
use Test::Roo;
use AtteanX::Plan::LDF::Triple;
use Attean::RDF;

package TestCreateStore {
        use Moo;
        with 'Test::Attean::Store::LDF::Role::CreateStore';
};

my $triples = [
					triple(iri('http://example.org/bar'), iri('http://example.org/c'), iri('http://example.org/foo')),
					triple(iri('http://example.org/foo'), iri('http://example.org/p'), iri('http://example.org/baz')),
					triple(iri('http://example.org/baz'), iri('http://example.org/b'), literal('2')),
					triple(iri('http://example.com/foo'), iri('http://example.org/p'), literal('dahut')),
					triple(iri('http://example.org/dahut'), iri('http://example.org/dahut'), literal('1')),
				  ];

my $test = TestCreateStore->new;
my $plan = AtteanX::Plan::LDF::Triple->new(subject => variable('s'),
																  predicate => iri('http://example.org/p'),
																  object => variable('o'),
																  distinct => 0
																 );
my $planner = Attean::QueryPlanner->new;

isa_ok($plan, 'AtteanX::Plan::LDF::Triple');
is($plan->as_string, "- LDFTriple { ?s, <http://example.org/p>, ?o }\n", 'Serialized plan ok');


{
	my $model = Attean::TripleModel->new( stores => {
																	 'http://example.org/graph1' => $test->create_store(triples => [])
																	 });
	can_ok($model, 'cost_for_plan');
	can_ok($model, 'plans_for_algebra');
	is($model->cost_for_plan($plan, $planner), 10000, 'Correct cost for plan with empty store');
}

{
	my $model = Attean::TripleModel->new( stores => {
																	 'http://example.org/graph1' => $test->create_store(triples => $triples)
																	});
	is($model->cost_for_plan($plan, $planner), 406, 'Correct cost for plan with populated store');
}

{
	my $plan2 = AtteanX::Plan::LDF::Triple->new(subject => variable('s'),
																		predicate => iri('http://example.org/nothere'),
																		object => variable('o'),
																		distinct => 0
																	  );
	isa_ok($plan2, 'AtteanX::Plan::LDF::Triple');
	is($plan2->as_string, "- LDFTriple { ?s, <http://example.org/nothere>, ?o }\n", 'Serialized plan ok');
	my $model = Attean::TripleModel->new( stores => {
																	 'http://example.org/graph1' => $test->create_store(triples => $triples)
																	});
	is($model->cost_for_plan($plan2, $planner), 10, 'Correct cost for plan with populated store but no hits');
}

done_testing;
