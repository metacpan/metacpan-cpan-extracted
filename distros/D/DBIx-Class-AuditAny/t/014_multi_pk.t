# -*- perl -*-

use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;

use SQL::Translator 0.11016;

use_ok( 'DBIx::Class::AuditAny' );

use TestSchema::Three;

my @connect = ('dbi:SQLite::memory:','','', { on_connect_call => 'use_foreign_keys' });

ok(
	my $schema = TestSchema::Three->connect(@connect),
	"Initialize Test Database"
);

$schema->deploy;


ok(
	my $Auditor = DBIx::Class::AuditAny->track(
		schema => $schema, 
		track_all_sources => 1,
		collector_class => 'Collector::AutoDBIC',
		collector_params => {
			sqlite_db => TestEnv->vardir->file('audit_three.db')->stringify,
		},
		datapoints => [
			(qw(schema schema_ver changeset_ts changeset_elapsed)),
			(qw(change_elapsed action source pri_key_value)),
			(qw(column_name old_value new_value)),
		],
		rename_datapoints => {
			changeset_elapsed => 'total_elapsed',
			change_elapsed => 'elapsed',
			pri_key_value => 'row_key',
			new_value => 'new',
			old_value => 'old',
			column_name => 'column',
		},
	),
	"Setup tracker configured to write to auto configured schema"
);

ok( 
	$schema->resultset('Team')->create({
		id => 1,
		name => 'Denver Broncos' 
	}),
	"Insert a test row (Team table)"
);

ok( 
	my $Position = $schema->resultset('Position')->create({
		name => 'Quarterback' 
	}),
	"Insert a test row (Position table)"
);

ok( 
  # have to specify id and sec_id due to limitation in sqlite
	$schema->resultset('Player')->create({
    id => 1,
    sec_id => 1,
		first => 'Payton',
		last => 'Manning',
		team_id => 1,
		position => 'Quarterback'
	}),
	"Insert a test row (Player table)"
);

ok(
  $Auditor->collector->target_schema->resultset('AuditChange')->search({row_key => '1|~|1'})->first,
  "Found audit of dual primary key insert"
);

done_testing;
