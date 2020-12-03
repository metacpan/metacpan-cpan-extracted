use Test::Roo;
use Test::Modern;
use Test::Exception;
use List::MoreUtils qw(all);
use File::Temp qw(tempfile);
use DBIx::MultiStatementDo;
use File::Slurp;

use v5.14;
use warnings;
no warnings 'redefine';

use Attean;
use Attean::RDF;
use AtteanX::Store::DBI;

sub create_store {
	my $self	= shift;
	my %args	= @_;
	my $quads	= $args{quads} // [];
	(undef, my $filename)	= tempfile();
	my @connect		= AtteanX::Store::DBI->dbi_connect_args(
		'sqlite',
		database	=> $filename,
	);
	my $dbh			= DBI->connect(@connect);
	my $batch	= DBIx::MultiStatementDo->new( dbh => $dbh );
	my $store	= Attean->get_store('DBI')->new( dbh => $dbh );

	if (my $file = $store->create_schema_file) {
		my $sql	= read_file($file);
		$batch->do($sql);
	} else {
		plan skip_all => "No schema files available for SQLite";
		exit(0);
	}

	foreach my $q (@$quads) {
		$store->add_quad($q);
	}
	return $store;
}

test 'SQLite STRSTARTS SARG with string literal' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );

	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER STRSTARTS(?o, "foo") }');
	my $default_graphs	= [iri('g')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	like($sql, qr#SELECT "t0"."subject" AS "s", "t0"."predicate" AS "p", "t0"."object" AS "o" FROM quad t0, term (\S+) WHERE [(]t0.graph IN [(][?][)][)] AND [(]"t0"."object" = \1.term_id[)] AND [(]\1."type" = [?][)] AND [(]INSTR[(]\1.value, [?][)] = 1[)] AND [(]\1.datatype_id IN [(][?], [?][)][)]#, 'generated SQL');
	is_deeply([splice(@bind, 1, 2)], ['literal', 'foo'], 'bound values');
};

test 'SQLite STRSTARTS SARG with language literal' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );

	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER STRSTARTS(?o, "foo"@en) }');
	my $default_graphs	= [iri('g')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	like($sql, qr#SELECT "t0"."subject" AS "s", "t0"."predicate" AS "p", "t0"."object" AS "o" FROM quad t0, term (\S+) WHERE [(]t0.graph IN [(][?][)][)] AND [(]"t0"."object" = \1.term_id[)] AND [(]\1."type" = [?][)] AND [(]INSTR[(]\1.value, [?][)] = 1[)] AND [(]\1.language = [?][)]#, 'generated SQL');
	is_deeply([splice(@bind, 1)], ['literal', 'foo', 'en'], 'bound values');
};

with 'Test::Attean::QuadStore', 'Test::Attean::MutableQuadStore';
with 'Test::AtteanX::Store::DBI';
run_me;

done_testing();
