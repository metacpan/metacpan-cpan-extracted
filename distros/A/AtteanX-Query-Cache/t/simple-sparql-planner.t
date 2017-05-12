=pod

=encoding utf-8

=head1 PURPOSE

Test that produced plans are correct.

=head1 SYNOPSIS

It may come in handy to enable logging for debugging purposes, e.g.:

  LOG_ADAPTER=Screen DEBUG=1 prove -lv t/idp_sparql_planner.t

This requires that L<Log::Any::Adapter::Screen> is installed.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use v5.14;
use autodie;
use utf8;
use Test::Modern;

use CHI;

use Attean;
use Attean::RDF;
use AtteanX::QueryPlanner::Cache;
use AtteanX::Store::Memory;
#use Carp::Always;
use Data::Dumper;
use AtteanX::Store::SPARQL;
use AtteanX::Model::SPARQLCache;
use Log::Any::Adapter;
Log::Any::Adapter->set($ENV{LOG_ADAPTER} ) if ($ENV{LOG_ADAPTER});

my $cache = CHI->new( driver => 'Memory', global => 1 );

my $p	= AtteanX::QueryPlanner::Cache->new;
isa_ok($p, 'Attean::QueryPlanner');
isa_ok($p, 'AtteanX::QueryPlanner::Cache');
does_ok($p, 'Attean::API::CostPlanner');

{
	# These tests does not actually look up anything in a real store, it just simulates
	my $store	= Attean->get_store('SPARQL')->new('endpoint_url' => iri('http://test.invalid/'));
	isa_ok($store, 'AtteanX::Store::SPARQL');
	my $model	= AtteanX::Model::SPARQLCache->new( store => $store, cache => $cache );
	my $graph = iri('http://test.invalid/graph');
	my $t		= triplepattern(variable('s'), iri('p'), literal('1'));
	my $u		= triplepattern(variable('s'), iri('p'), variable('o'));
	my $v		= triplepattern(variable('s'), iri('q'), blank('xyz'));
	my $w		= triplepattern(variable('a'), iri('b'), iri('c'));
	my $x		= triplepattern(variable('s'), iri('q'), iri('a'));
	my $y		= triplepattern(variable('o'), iri('b'), literal('2'));
	my $z		= triplepattern(variable('a'), iri('c'), variable('s'));
	my $s		= triplepattern(iri('a'), variable('p'), variable('o'));

	subtest 'Empty BGP, to test basics' => sub {
		note("An empty BGP should produce the join identity table plan");
		my $bgp		= Attean::Algebra::BGP->new(triples => []);
		my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
		does_ok($plan, 'Attean::API::Plan', 'Empty BGP');
		isa_ok($plan, 'Attean::Plan::Table');
		my $rows	= $plan->rows;
		is(scalar(@$rows), 1);
	};


	subtest '1-triple BGP single variable, with cache, not cached' => sub {
		note("A 1-triple BGP should produce a single Attean::Plan::Iterator plan object");
		$cache->set('?v001 <p> "1" .', ['<http://example.org/foo>', '<http://example.org/bar>']);
		$cache->set('?v001 <p> "dahut" .', ['<http://example.com/foo>', '<http://example.com/bar>']);
		$cache->set('?v001 <dahut> "1" .', ['<http://example.org/dahut>']);
		
		ok($model->is_cached(triplepattern(variable('foo'), iri('p'), literal('1'))->canonicalize->tuples_string), 'Cache has been set');
		ok(! $model->is_cached(triplepattern(variable('foo'), iri('q'), literal('1'))->canonicalize->tuples_string), 'Cache has not been set');
		my $bgp		= Attean::Algebra::BGP->new(triples => [$u]);
		my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
		does_ok($plan, 'Attean::API::Plan', '1-triple BGP');
		isa_ok($plan, 'AtteanX::Plan::SPARQLBGP');
		is(scalar @{$plan->children}, 1, '1-triple BGP child');
		like($plan->as_string, qr|SPARQLBGP.*?Quad \{ \?s, <p>, \?o, <http://test.invalid/graph> }|s, 'Good plan');
		is($plan->plan_as_string, 'SPARQLBGP', 'Good plan_as_string');
	};

	subtest '4-triple BGP with join variable with cache one cached' => sub {
		my $bgp		= Attean::Algebra::BGP->new(triples => [$t, $u, $y, $x]);
		my @plans	= $p->plans_for_algebra($bgp, $model, [$graph]);
		is(scalar @plans, 5, 'Got 5 plans');
		my $plan = $plans[0];
		does_ok($plan, 'Attean::API::Plan::Join');
		my @c1plans = sort @{$plan->children};
		isa_ok($c1plans[0], 'Attean::Plan::Iterator', 'First child when sorted is an iterator');
		isa_ok($c1plans[1], 'AtteanX::Plan::SPARQLBGP', 'Second child when sorted is a BGP');
		is(scalar @{$c1plans[1]->children}, 3, '...with three children');
		foreach my $plan (@{$c1plans[1]->children}) {
			isa_ok($plan, 'Attean::Plan::Quad', 'All children are quads');
		}
	};


	subtest '1-triple BGP two variables, with cache' => sub {
		note("A 1-triple BGP should produce a single Attean::Plan::Iterator plan object");
		$cache->set('?v002 <p> ?v001 .', {'<http://example.org/foo>' => ['<http://example.org/bar>'],
													 '<http://example.com/foo>' => ['<http://example.org/baz>', '<http://example.org/foobar>']});
		$cache->set('?v001 <p> "dahut" .', ['<http://example.com/foo>', '<http://example.com/bar>']);
		$cache->set('?v002 <dahut> ?v001 .', {'<http://example.org/dahut>' => ['"Foobar"']});
		ok($model->is_cached(triplepattern(variable('foo'), iri('p'), variable('bar'))->canonicalize->tuples_string), 'Cache has been set');
		my $bgp		= Attean::Algebra::BGP->new(triples => [$u]);

		my @plans = $p->plans_for_algebra($bgp, $model, [$graph]);
		is(scalar @plans, 2, "Got two plans");
		my $plan = $plans[0];
#		warn $plan->as_string;
		does_ok($plan, 'Attean::API::Plan', '1-triple BGP');
		isa_ok($plan, 'Attean::Plan::Iterator');
		my @rows = $plan->iterator->elements;
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

		does_ok($plans[1], 'Attean::API::Plan', '1-triple BGP');
		isa_ok($plans[1], 'AtteanX::Plan::SPARQLBGP');
		is(scalar @{$plans[1]->children}, 1, '1-triple BGP child');
		like($plans[1]->as_string, qr|SPARQLBGP.*?Quad \{ \?s, <p>, \?o, <http://test.invalid/graph> }|s, 'Good plan');
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
		my @plans	= $p->plans_for_algebra($bgp, $model, [$graph]);
		is(scalar @plans, 2, 'Got two plans');
		my $plan = $plans[0];
		does_ok($plan, 'Attean::API::Plan', '1-triple BGP');
		isa_ok($plan, 'Attean::Plan::Iterator');
		my @rows = $plan->iterator->elements;
		is(scalar(@rows), 2, 'Got two rows back');
		foreach my $row (@rows) {
			my @vars = $row->variables;
			is($vars[0], 'name', 'Variable name is correct');
			does_ok($row->value('name'), 'Attean::API::Literal');
		}
		ok($rows[0]->value('name')->equals(langliteral('Le Dahu', 'fr')), 'First literal is OK'); 
		ok($rows[1]->value('name')->equals(langliteral('Dahut', 'en')), 'Second literal is OK'); 

		does_ok($plans[1], 'Attean::API::Plan', '1-triple BGP');
		isa_ok($plans[1], 'AtteanX::Plan::SPARQLBGP');
		is(scalar @{$plans[1]->children}, 1, '1-triple BGP child');
		like($plans[1]->as_string, qr|SPARQLBGP.*?Quad \{ <http://example.org/foo>, <dahut>, \?name, <http://test.invalid/graph> }|s, 'Good plan');
	};

	subtest '2-triple BGP with join variable with cache on both' => sub {
		note("A 2-triple BGP with a join variable and without any ordering should produce two iterators joined");
		my $bgp		= Attean::Algebra::BGP->new(triples => [$t, $u]);
		my @plans	= $p->plans_for_algebra($bgp, $model, [$graph]);
		is(scalar @plans, 1, 'Got just 1 plan');
		my $plan = shift @plans;
		does_ok($plan, 'Attean::API::Plan::Join', 'Plans are join plans');
		ok($plan->distinct, 'Plans should be distinct');
		foreach my $cplan (@{$plan->children}) {
			does_ok($cplan, 'Attean::API::Plan', 'Each child of 2-triple BGP');
			isa_ok($cplan, 'Attean::Plan::Iterator', 'All children should be Iterator');
		}
		isa_ok($plan, 'Attean::Plan::HashJoin', '2-triple BGP with Tables should return HashJoin');
	};

	subtest '2-triple BGP with join variable with cache none cached' => sub {
		my $bgp		= Attean::Algebra::BGP->new(triples => [$w, $z]);
		my @plans	= $p->plans_for_algebra($bgp, $model, [$graph]);
		is(scalar @plans, 1, 'Got 1 plan');
		foreach my $plan (@plans) {
#			warn $plan->as_string;
			isa_ok($plan, 'AtteanX::Plan::SPARQLBGP', 'Plans are SPARQLBGP');
		}
		my $plan = $plans[0];
		does_ok($plan, 'Attean::API::Plan', '2-triple BGP');
		like($plan->as_string, qr/SPARQLBGP/, 'SPARQL BGP serialisation');
		foreach my $cplan (@{$plan->children}) {
			does_ok($cplan, 'Attean::API::Plan', 'Each child of 2-triple BGP');
			isa_ok($cplan, 'Attean::Plan::Quad', 'Child is a Quad');
		}
	};

	subtest '2-triple BGP with join variable with cache one cached' => sub {
		my $bgp		= Attean::Algebra::BGP->new(triples => [$t, $x]);
		my @plans	= $p->plans_for_algebra($bgp, $model, [$graph]);
		is(scalar @plans, 5, 'Got 5 plans');
		
		# The first two plans should be the "best", containing a HashJoin over
		# a Table and a SPARQLBGP. The order or the join operands is irrelevant,
		# because we don't know enough about cardinality of SPARQLBGP plans to
		# estimate which side is going to be smaller.
		foreach my $plan (@plans[0..1]) {
			does_ok($plan, 'Attean::API::Plan::Join', 'First 2 plans are joins');
			my @tables	= $plan->subpatterns_of_type('Attean::Plan::Iterator');
			is(scalar(@tables), 1, 'First 2 plans contain 1 table sub-plan');
		}

		my $plan = $plans[0];
		
		# sorting the strings should result in the Attean::Plan::Iterator being first
		my @children	= sort { "$a" cmp "$b" } @{$plan->children};
		foreach my $cplan (@children) {
			does_ok($cplan, 'Attean::API::Plan', 'Each child of 2-triple BGP');
		}
		
		my ($table, $bgpplan)	= @children;
		isa_ok($table, 'Attean::Plan::Iterator', 'Should join on Table first');
		isa_ok($bgpplan, 'AtteanX::Plan::SPARQLBGP', 'Then on SPARQL BGP');
		isa_ok(${$bgpplan->children}[0], 'Attean::Plan::Quad', 'That has a Quad child');
		is(${$bgpplan->children}[0]->plan_as_string, 'Quad { ?s, <q>, <a>, <http://test.invalid/graph> }', 'Child plan OK');
	};

	subtest '5-triple BGP with join variable with cache two cached' => sub {
		my $bgp		= Attean::Algebra::BGP->new(triples => [$t, $u, $v, $w, $x]);
		my @plans	= $p->plans_for_algebra($bgp, $model, [$graph]);
		is(scalar @plans, 5, 'Got 5 plans');
		my $plan = $plans[0];
		does_ok($plan, 'Attean::API::Plan::Join');
		my @c1plans = sort @{$plan->children};
		does_ok($c1plans[0], 'Attean::API::Plan::Join', 'First child when sorted is a join');
		does_ok($c1plans[1], 'AtteanX::Plan::SPARQLBGP', 'Second child when sorted is a BGP');
		is(scalar @{$c1plans[1]->children}, 2, '...with two quads');
		my @c2plans = sort @{$c1plans[0]->children};
		isa_ok($c2plans[0], 'Attean::Plan::HashJoin', 'First grandchild when sorted is a hash join');
	 	foreach my $cplan (@{$c2plans[0]->children}) {
			isa_ok($cplan, 'Attean::Plan::Iterator', 'and children of them are iterators');
		}
		isa_ok($c2plans[1], 'AtteanX::Plan::SPARQLBGP', 'Second grandchild when sorted is a BGP');
		is(scalar @{$c2plans[1]->children}, 1, '...with one quad');
	};

	subtest '3-triple BGP where cache breaks the join to cartesian' => sub {
		my $bgp		= Attean::Algebra::BGP->new(triples => [$z, $u, $y]);
		my @plans	= $p->plans_for_algebra($bgp, $model, [$graph]);
		is(scalar @plans, 5, 'Got 5 plans');
		my $plan = shift @plans;
		isa_ok($plan, 'AtteanX::Plan::SPARQLBGP', 'The winning plan should be BGP');
		is(scalar @{$plan->children}, 3, 'with three children');
		$plan = shift @plans;
		isa_ok($plan, 'Attean::Plan::HashJoin', 'The next plan should be a join');
		
		# sorting the strings should result in a HashJoin followed by a SPARQLBGP
		my @children	= sort { "$a" cmp "$b" } @{ $plan->children };
		foreach my $cplan (@children) {
			does_ok($cplan, 'Attean::API::Plan');
		}
		
		my @triples;
		my ($join, $bgpplan1)	= @children;
		isa_ok($join, 'Attean::Plan::HashJoin') || diag $plan->as_string;
		isa_ok($bgpplan1, 'AtteanX::Plan::SPARQLBGP');
		is(scalar(@{ $bgpplan1->children }), 1);
		push(@triples, @{ $bgpplan1->children });
		
		# sorting the strings should result in a Table followed by a SPARQLBGP
		my @grandchildren	= sort { "$a" cmp "$b" } @{ $join->children };
		foreach my $cplan (@grandchildren) {
			does_ok($cplan, 'Attean::API::Plan');
		}
		my ($table, $bgpplan2)	= @grandchildren;
		isa_ok($table, 'Attean::Plan::Iterator');
		isa_ok($bgpplan2, 'AtteanX::Plan::SPARQLBGP');
		is(scalar(@{ $bgpplan2->children }), 1);
		push(@triples, @{ $bgpplan2->children });
		my @strings	= sort map { $_->as_string } @triples;
		my @expected	= (
			qq[- Quad { ?a, <c>, ?s, <http://test.invalid/graph> }\n],
			qq[- Quad { ?o, <b>, "2", <http://test.invalid/graph> }\n],
		);
		is_deeply(\@strings, \@expected);
	};

	subtest '3-triple BGP chain with cache on two' => sub {
		# TODO: Also improve with cost model
		$cache->set('?v001 <b> "2" .', ['<http://example.com/dahut>']);
		my $bgp		= Attean::Algebra::BGP->new(triples => [$z, $u, $y]);
		my @plans	= $p->plans_for_algebra($bgp, $model, [$graph]);
		my $plan = shift @plans;
		does_ok($plan, 'Attean::API::Plan::Join');
		my @tables	= $plan->subpatterns_of_type('Attean::Plan::Iterator');
		is(scalar @tables, 2, 'Should be 2 tables in the plan');
		my @bgps	= $plan->subpatterns_of_type('AtteanX::Plan::SPARQLBGP');
		is(scalar @bgps, 1, 'Should be only one BGP in the plan');
		is(scalar @{ $bgps[0]->children }, 1, 'And that should just have one child');
		isa_ok(${ $bgps[0]->children }[0], 'Attean::Plan::Quad', 'That has a Quad child');
	};


	subtest '3-triple BGP with predicate variable' => sub {
		$cache->set('<a> ?v002 ?v001 .', {'<p>' => ['<http://example.org/bar>'],
													 '<q>' => ['<http://example.org/baz>', '<http://example.org/foobar>']});
		my $bgp		= Attean::Algebra::BGP->new(triples => [$s, $u, $y]);
		my $plan	= $p->plan_for_algebra($bgp, $model, [$graph]);
		does_ok($plan, 'Attean::API::Plan::Join');
		isa_ok($plan, 'Attean::Plan::HashJoin');
		my @cplans = sort @{$plan->children};
		isa_ok($cplans[0], 'Attean::Plan::HashJoin', 'First child is hashjoin');
		foreach my $c2plan (@{$cplans[0]->children}) {
			isa_ok($c2plan, 'Attean::Plan::Iterator', 'and children of them are tables');
		}
		isa_ok($cplans[1], 'Attean::Plan::Iterator', 'Other child is a table');

	};
}

done_testing();
