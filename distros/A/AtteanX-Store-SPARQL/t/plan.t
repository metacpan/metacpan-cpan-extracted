use v5.14;
use Test::Modern;
use Attean;
use Attean::RDF;
use AtteanX::Model::SPARQL;
use Data::Dumper;
#use Carp::Always;

my $p = Attean::IDPQueryPlanner->new();
isa_ok($p, 'Attean::IDPQueryPlanner');

my $store	= Attean->get_store('SPARQL')->new('endpoint_url' => iri('http://test.invalid/'));
isa_ok($store, 'AtteanX::Store::SPARQL');
does_ok($store, 'Attean::API::TripleStore');

my $model	= AtteanX::Model::SPARQL->new( store => $store );
isa_ok($model, 'AtteanX::Model::SPARQL');
does_ok($model, 'Attean::API::CostPlanner');

can_ok($model, 'get_sparql');
my $graph = iri('http://example.org');
my $t		= triplepattern(variable('s'), iri('p'), literal('1'));
my $u		= triplepattern(variable('s'), iri('p'), variable('o'));
my $v		= triplepattern(variable('s'), iri('q'), blank('xyz'));
my $w		= triplepattern(variable('a'), iri('b'), iri('c'));

subtest '1-triple BGP two variables' => sub {
	my $bgp		= Attean::Algebra::BGP->new(triples => [$u]);
	my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
	does_ok($plan, 'Attean::API::Plan', '1-triple BGP');
	isa_ok($plan, 'Attean::Plan::Quad');
	is($plan->plan_as_string, 'Quad { ?s, <p>, ?o, <http://example.org> }', 'plan_as_string gives the correct string');
};

subtest '3-triple BGP two variables' => sub {
	my $bgp		= Attean::Algebra::BGP->new(triples => [$u, $t, $v]);
	my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
	does_ok($plan, 'Attean::API::Plan', '3-triple BGP');
	isa_ok($plan, 'AtteanX::Plan::SPARQLBGP');
	like($plan->plan_as_string, qr/^SPARQLBGP/, 'plan_as_string begins with the correct string');
	cmp_deeply([sort @{@{$plan->children}[0]->in_scope_variables}], ['o','s'], 'in_scope_variable is correct for first quad');
	cmp_deeply(@{$plan->children}[1]->in_scope_variables, ['s'], 'in_scope_variable is correct for second quad');
};

subtest 'Make sure Quad plans are accepted by the BGP' => sub {
	my $p1 = Attean::Plan::Quad->new(subject => variable('s'), 
												predicate => iri('p'), 
												object => variable('o'), 
												graph => $graph, 
												distinct => 0);
	my $p2 = Attean::Plan::Quad->new(subject => variable('a'), 
												predicate => iri('b'), 
												object => iri('c'), 
												graph => $graph, 
												distinct => 0);
	my $p3 = Attean::Plan::Quad->new(subject => variable('s'), 
												predicate => iri('p2'), 
												object => literal('o'), 
												graph => $graph, 
												distinct => 0);
	my $bgpplan = AtteanX::Plan::SPARQLBGP->new(children => [$p1,$p2],
																		  distinct => 0
																		 );
	isa_ok($bgpplan, 'AtteanX::Plan::SPARQLBGP');
	does_ok($bgpplan, 'Attean::API::Plan');
	is(scalar @{$bgpplan->children}, 2, 'Has two kids');

	foreach my $plan (@{$bgpplan->children}) {
		isa_ok($plan, 'Attean::Plan::Quad', 'Plans are quads');
	}

};

done_testing;
