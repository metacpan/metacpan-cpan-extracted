# -*- perl -*-

use strict;
use warnings;
use Test::More;
use DBICx::TestDatabase 0.04;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;


use_ok( 'DBIx::Class::AuditAny' );

ok(
	my $schema = DBICx::TestDatabase->new('TestSchema::One'),
	"Initialize Test Database"
);


ok(
	my $Auditor = DBIx::Class::AuditAny->track(
		schema => $schema, 
		track_all_sources => 1,
		collector_class => 'Collector::AutoDBIC',
		collector_params => {
			sqlite_db => TestEnv->vardir->file('audit9.db')->stringify,
		},
	),
	"Setup tracker configured to write to auto configured schema"
);



$schema->txn_do(sub {
	ok( 
		$schema->resultset('Contact')->create({
			first => 'John', 
			last => 'Smith' 
		}),
		"Insert a test row (1)"
	);

	ok( 
		$schema->resultset('Contact')->create({
			first => 'Larry', 
			last => 'Smith' 
		}),
		"Insert a test row (2)"
	);

	ok( 
		$schema->resultset('Contact')->create({
			first => 'Ricky', 
			last => 'Bobby' 
		}),
		"Insert a test row (3)"
	);
});

#####################

ok(
	my $audit_schema = $Auditor->collector->target_schema,
	"Get the active Collector schema object"
);


is(
	$audit_schema->resultset('AuditChangeSet')->count => 1,
	"Expected number of ChangeSets"
);


done_testing;
