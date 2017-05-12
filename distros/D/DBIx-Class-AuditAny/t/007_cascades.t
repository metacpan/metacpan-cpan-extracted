# -*- perl -*-

use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;

use SQL::Translator 0.11016;

use_ok( 'DBIx::Class::AuditAny' );

use TestSchema::Two;

my @connect = ('dbi:SQLite::memory:','','', { on_connect_call => 'use_foreign_keys' });

ok(
	my $schema = TestSchema::Two->connect(@connect),
	"Initialize Test Database"
);

$schema->deploy;


ok(
	my $Auditor = DBIx::Class::AuditAny->track(
		schema => $schema, 
		track_all_sources => 1,
		collector_class => 'Collector::AutoDBIC',
		collector_params => {
			sqlite_db => TestEnv->vardir->file('audit_two.db')->stringify,
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
	$schema->resultset('Player')->create({
		first => 'Payton',
		last => 'Manning',
		team_id => 1,
		position => 'Quarterback'
	}),
	"Insert a test row (Player table)"
);

ok(
	$Position->update({ name => 'QB' }),
	"Update fk that should cascade"
);

ok(
	my $Player = $schema->resultset('Player')->search_rs({ last => 'Manning' })->first,
	"Find the test Player row"
);

is(
	$Player->get_column('position'),
	'QB',
	'Confirm the cascade update happened'
);

### finish me


done_testing;