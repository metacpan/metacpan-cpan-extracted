package # hide from PAUSE
     Routine::One::ToAutoDBIC;
use strict;
use warnings;

use Test::Routine;
with 'Routine::One','Routine::AuditAny','Routine::AutoDBIC';

use Test::More; 
use namespace::autoclean;

has 'track_params', is => 'ro', lazy => 1, default => sub {
	my $self = shift;
	my $params = {
		track_all_sources => 1,
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
	};
	
	return $params;
};


has 'colnames', is => 'ro', isa => 'HashRef[Str]', default => sub {{
	old		=> 'old',
	new		=> 'new',
	column	=> 'column'
}};


test 'Verify Collected Data' => sub {
	my $self = shift;
	my $schema = $self->Auditor->collector->target_schema;
	my $c = $self->colnames;
	
	is(
		$schema->resultset('AuditChangeSet')->count => 3,
		"Expected number of ChangeSets"
	);


	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			$c->{old} => undef,
			$c->{new} => 'Smith',
			$c->{column} => 'last',
			'change.action' => 'insert'
		},{
			join => { change => 'changeset' }
		})->count => 1,
		"Expected specific INSERT column change record exists"
	);


	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			$c->{old} => 'Smith',
			$c->{new} => 'Doe',
			$c->{column} => 'last',
			'change.action' => 'update',
		},{
			join => { change => 'changeset' }
		})->count => 1,
		"Expected specific UPDATE column change record exists"
	);


	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			$c->{old} => 'Doe',
			$c->{new} => undef,
			$c->{column} => 'last',
			'change.action' => 'delete'
		},{
			join => { change => 'changeset' }
		})->count => 1,
		"Expected specific DELETE column change record exists"
	);

};

1;