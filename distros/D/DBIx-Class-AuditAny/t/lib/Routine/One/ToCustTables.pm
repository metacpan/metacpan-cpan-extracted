package # hide from PAUSE
     Routine::One::ToCustTables;
use strict;
use warnings;

use Test::Routine;
with 'Routine::One','Routine::AuditAny';

use Test::More; 
use namespace::autoclean;

my $user_id = 42;
my $client_ip = '1.2.3.4';

has 'record_different_schema', is => 'ro', isa => 'Bool', default => 0;

has 'track_params', is => 'ro', lazy => 1, default => sub {
	my $self = shift;
	my $params = {
		track_all_sources => 1,
		collector_class => 'Collector::DBIC',
		collector_params => {
			target_source => 'AuditChangeSet',
			change_data_rel => 'audit_changes',
			column_data_rel => 'audit_change_columns',
		},
		datapoints => [
			(qw(changeset_ts changeset_elapsed)),
			(qw(change_elapsed action source pri_key_value)),
			(qw(column_name old_value new_value)),
		],
		datapoint_configs => [
			{
				name	=> 'client_ip',
				context => 'set',
				method => sub { $client_ip }
			},
			{
				name	=> 'user_id',
				context => 'set',
				method => sub { $user_id }
			}
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
	
	$params->{collector_params}->{target_schema} = 
		$self->new_test_schema($self->test_schema_class)
			if ($self->record_different_schema);
	
	return $params;
};


test 'Verify Collected Data' => sub {
	my $self = shift;
	my $schema = $self->Auditor->collector->target_schema;
	
	is(
		$schema->resultset('AuditChangeSet')->count => 3,
		"Expected number of ChangeSets"
	);

	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			old => undef,
			new => 'Smith',
			column => 'last',
			'change.action' => 'insert',
			'changeset.user_id' => $user_id
		},{
			join => { change => 'changeset' }
		})->count => 1,
		"Expected specific INSERT column change record exists"
	);


	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			old => 'Smith',
			new => 'Doe',
			column => 'last',
			'change.action' => 'update',
			'changeset.user_id' => $user_id
		},{
			join => { change => 'changeset' }
		})->count => 1,
		"Expected specific UPDATE column change record exists"
	);


	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			old => 'Doe',
			new => undef,
			column => 'last',
			'change.action' => 'delete',
			'changeset.client_ip' => $client_ip
		},{
			join => { change => 'changeset' }
		})->count => 1,
		"Expected specific DELETE column change record exists"
	);

	is(
		$schema->resultset('AuditChange')->search_rs({
			'changeset.client_ip' => $client_ip
		},{
			join => 'changeset'
		})->first->audit_change_columns->count => 3,
		"Expected number of specific column changes via rel accessor"
	);
};

1;