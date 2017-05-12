use v5.14;
use autodie;
use utf8;
use Test::Modern;

use CHI;

use Attean;
use Attean::RDF;
use AtteanX::QueryPlanner::Cache;
use AtteanX::Store::Memory;
use Data::Dumper;
#use Carp::Always;


package TestStore {
	use Moo;
	use namespace::clean;
	extends 'AtteanX::Store::Memory';
	
	sub cost_for_plan {
		# we do this because the superclass would return a cost of 0 for quads when the store is empty
		# and if 0 was returned, there won't be any meaningful difference between the cost of different join algorithms 
		my $self	= shift;
		my $plan	= shift;
		if ($plan->isa('Attean::Plan::Quad')) {
			return 3;
		} elsif ($plan->isa('Attean::Plan::Iterator')) {
			return 2;
		} elsif ($plan->isa('AtteanX::Plan::SPARQLBGP')) {
			return 20;
		} 
		return;
	}
};

package TestModel {
	use Moo;
	use Types::Standard qw(InstanceOf);

	extends 'Attean::MutableQuadModel';

	has 'cache' => (
						 is => 'ro',
						 isa => InstanceOf['CHI::Driver'],
						 required => 1
					);
};

my $cache = CHI->new( driver => 'Memory', global => 1 );

my $p	= AtteanX::QueryPlanner::Cache->new;
isa_ok($p, 'Attean::QueryPlanner');
isa_ok($p, 'AtteanX::QueryPlanner::Cache');
does_ok($p, 'Attean::API::CostPlanner');


# TODO: add data to the cache
# for two bound: An array of variable
# For one bound: A hash (or two hashes?)
# Dictionary?

{

	my $store	= TestStore->new();
	my $model	= TestModel->new( store => $store,
											cache => $cache
										 );
	my $graph	= iri('http://example.org/');
	my $t		= triplepattern(variable('s'), iri('p'), literal('1'));
	my $u		= triplepattern(variable('s'), iri('p'), variable('o'));
	my $v		= triplepattern(variable('s'), iri('q'), blank('xyz'));
	my $w		= triplepattern(variable('a'), iri('b'), iri('c'));
	$cache->set('?v001 <p> "1" .', ['<http://example.org/foo>', '<http://example.org/bar>']);
	$cache->set('?v001 <p> "dahut" .', ['<http://example.com/foo>', '<http://example.com/bar>']);
	$cache->set('?v001 <dahut> "1" .', ['<http://example.org/dahut>']);

	subtest 'Empty BGP, to test basics' => sub {
		note("An empty BGP should produce the join identity table plan");
		my $bgp		= Attean::Algebra::BGP->new(triples => []);
		my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
		does_ok($plan, 'Attean::API::Plan', 'Empty BGP');
		isa_ok($plan, 'Attean::Plan::Table');
		my $rows	= $plan->rows;
		is(scalar(@$rows), 1);
	};


	subtest '1-triple BGP single variable, with cache' => sub {
		note("A 1-triple BGP should produce a single Attean::Plan::Iterator plan object");
		my $bgp		= Attean::Algebra::BGP->new(triples => [$t]);
		my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
		does_ok($plan, 'Attean::API::Plan', '1-triple BGP');
		isa_ok($plan, 'Attean::Plan::Iterator');
		my @rows	= $plan->iterator->elements;
		is(scalar(@rows), 2, 'Got two rows back');
		foreach my $row (@rows) {
			my @vars = $row->variables;
			is($vars[0], 's', 'Variable name is correct');
			does_ok($row->value('s'), 'Attean::API::IRI');
		}
		ok($rows[0]->value('s')->equals(iri('http://example.org/foo')), 'First IRI is OK'); 
		ok($rows[1]->value('s')->equals(iri('http://example.org/bar')), 'Second IRI is OK'); 

	};

	subtest '1-triple BGP two variables, with cache' => sub {
		note("A 1-triple BGP should produce a single Attean::Plan::Iterator plan object");
		$cache->set('?v002 <p> ?v001 .', {'<http://example.org/foo>' => ['<http://example.org/bar>'],
															'<http://example.com/foo>' => ['<http://example.org/baz>', '<http://example.org/foobar>']});
		$cache->set('?v001 <p> "dahut" .', ['<http://example.com/foo>', '<http://example.com/bar>']);
		$cache->set('?v002 <dahut> ?v001 .', {'<http://example.org/dahut>' => ['"Foobar"']});
		my $bgp		= Attean::Algebra::BGP->new(triples => [$u]);
		my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
		does_ok($plan, 'Attean::API::Plan', '1-triple BGP');
		isa_ok($plan, 'Attean::Plan::Iterator');
		my @rows	= $plan->iterator->elements;
		is(scalar(@rows), 3, 'Got three rows back');
		foreach my $row (@rows) {
			my @vars = sort $row->variables;
			is(scalar(@vars), 2, 'Each result has two variables');
			is($vars[0], 'o', 'First variable name is correct');
			is($vars[1], 's', 'Second variable name is correct');
			does_ok($row->value('s'), 'Attean::API::IRI');
			does_ok($row->value('o'), 'Attean::API::IRI');
		}
		my @testrows = sort {$a->value('o')->as_string cmp $b->value('o')->as_string} @rows;

		ok($testrows[0]->value('s')->equals(iri('http://example.org/foo')), 'First triple subject IRI is OK'); 
		ok($testrows[0]->value('o')->equals(iri('http://example.org/bar')), 'First triple object IRI is OK'); 
		ok($testrows[1]->value('s')->equals(iri('http://example.com/foo')), 'Second triple subject IRI is OK'); 
		ok($testrows[1]->value('o')->equals(iri('http://example.org/baz')), 'Second triple object IRI is OK'); 
		ok($testrows[2]->value('s')->equals(iri('http://example.com/foo')), 'Third triple subject IRI is OK'); 
		ok($testrows[2]->value('o')->equals(iri('http://example.org/foobar')), 'Third triple object IRI is OK'); 

	};

	subtest '1-triple BGP single variable object, with cache' => sub {
		note("A 1-triple BGP should produce a single Attean::Plan::Iterator plan object");
		$cache->set('<http://example.org/foo> <p> ?v001 .', ['<http://example.org/foo>', '<http://example.org/bar>']);
		$cache->set('<http://example.org/foo> <dahut> ?v001 .', ['"Le Dahu"@fr', '"Dahut"@en']);
		$cache->set('?v001 <dahut> "Dahutten"@no .', ['<http://example.org/dahut>']);
		my $tp = triplepattern(iri('http://example.org/foo'),
									  iri('dahut'),
									  variable('name'));
		my $bgp		= Attean::Algebra::BGP->new(triples => [$tp]);
		my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
		does_ok($plan, 'Attean::API::Plan', '1-triple BGP');
		isa_ok($plan, 'Attean::Plan::Iterator');
		my @rows	= $plan->iterator->elements;
		is(scalar(@rows), 2, 'Got two rows back');
		foreach my $row (@rows) {
			my @vars = $row->variables;
			is($vars[0], 'name', 'Variable name is correct');
			does_ok($row->value('name'), 'Attean::API::Literal');
		}
		ok($rows[0]->value('name')->equals(langliteral('Le Dahu', 'fr')), 'First literal is OK'); 
		ok($rows[1]->value('name')->equals(langliteral('Dahut', 'en')), 'Second literal is OK'); 

	};


	subtest '2-triple BGP with join variable with cache on both' => sub {
		note("A 2-triple BGP with a join variable and without any ordering should produce two tables joined");
		my $bgp		= Attean::Algebra::BGP->new(triples => [$t, $u]);
		my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
		does_ok($plan, 'Attean::API::Plan', '2-triple BGP');
		does_ok($plan, 'Attean::API::Plan::Join');
		ok($plan->distinct);
		foreach my $cplan (@{$plan->children}) {
			does_ok($cplan, 'Attean::API::Plan', 'Each child of 2-triple BGP');
			isa_ok($cplan, 'Attean::Plan::Iterator');
		}
	};

}

done_testing();
