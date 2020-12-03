package Test::AtteanX::Store::DBI;

use utf8;
use v5.14;
use warnings;
use Test::Roo::Role;
use Test::Modern;
use Test::Moose;
use Attean;
use Attean::RDF;

requires 'create_store';	# create_store( quads => \@triples )

sub test_quads {
	my @q;
	for my $i (0 .. 5) {
		push(@q, quad(iri('s'), iri('p'), literal($i), iri('g')));
		push(@q, quad(iri('s'), iri('p'), blank("b$i"), iri('g')));
	}

	my @strings;
	push(@strings, literal('Hi'));
	push(@strings, langliteral('Hello', 'en'));
	push(@strings, langliteral('火星', 'ja'));
	push(@strings, dtliteral(787, 'http://www.w3.org/2001/XMLSchema#integer'));
	foreach my $s (@strings) {
		push(@q, quad(iri('s'), iri('str'), $s, iri('strings')));
	}

	return \@q;
}

test 'ISLITERAL type constraint SARG' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );
	my $dbh		= $store->dbh;
	my $typecol	= $dbh->quote_identifier('type');
	
	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER ISLITERAL(?o) }');
	my $default_graphs	= [iri('g')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	
	like($sql, qr<SELECT term_id FROM term WHERE $typecol = [?]>, 'generated SQL');
	is($bind[-1], 'literal');
};

test 'ISBLANK type constraint SARG' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );
	my $dbh		= $store->dbh;
	my $typecol	= $dbh->quote_identifier('type');

	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER isBlank(?o) }');
	my $default_graphs	= [iri('g')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	like($sql, qr<SELECT term_id FROM term WHERE $typecol = [?]>, 'generated SQL');
	is($bind[-1], 'blank', 'bound values');
};

test 'ISLITERAL type constraint SARG' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );
	my $dbh		= $store->dbh;
	my $typecol	= $dbh->quote_identifier('type');

	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER ISLITERAL(?o) }');
	my $default_graphs	= [iri('strings')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	like($sql, qr<SELECT term_id FROM term WHERE $typecol = [?]>, 'generated SQL');
	is($bind[-1], 'literal', 'bound values');
};

test 'ISIRI type constraint SARG' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );
	my $dbh		= $store->dbh;
	my $typecol	= $dbh->quote_identifier('type');

	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER ISIRI(?o) }');
	my $default_graphs	= [iri('g')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	like($sql, qr<SELECT term_id FROM term WHERE $typecol = [?]>, 'generated SQL');
	is($bind[-1], 'iri');
};

test 'STRSTARTS' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );
	
	subtest 'STR()' => sub {
		my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER STRSTARTS(STR(?o), "H") }');
		my $default_graphs	= [iri('strings')];
		my $planner	= Attean::IDPQueryPlanner->new();
		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

		my @rows	= $plan->evaluate($model)->elements;
		is(scalar(@rows), 2, 'result count');
		foreach my $r (@rows) {
			like($r->value('o')->value, qr/^H/, 'literal value');
		}
	};
	
	subtest 'xsd:string' => sub {
		my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER STRSTARTS(?o, "H") }');
		my $default_graphs	= [iri('strings')];
		my $planner	= Attean::IDPQueryPlanner->new();
		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

		isa_ok($plan, 'AtteanX::Store::DBI::Plan');
		my $iter	= $plan->evaluate($model);
		my @rows	= $iter->elements;
		is(scalar(@rows), 2, 'result count');
		foreach my $r (@rows) {
			like($r->value('o')->value, qr/^H/, 'literal value');
		}
	};
	
	subtest 'language string' => sub {
		my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER STRSTARTS(?o, "H"@en) }');
		my $default_graphs	= [iri('strings')];
		my $planner	= Attean::IDPQueryPlanner->new();
		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

		isa_ok($plan, 'AtteanX::Store::DBI::Plan');
		my @rows	= $plan->evaluate($model)->elements;
		is(scalar(@rows), 1, 'result count');
		is($rows[0]->value('o')->value, 'Hello', 'literal value');
	};
};


1;
