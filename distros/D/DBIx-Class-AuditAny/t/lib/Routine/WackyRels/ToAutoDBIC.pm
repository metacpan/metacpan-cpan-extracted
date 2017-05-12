package # hide from PAUSE
     Routine::WackyRels::ToAutoDBIC;
use strict;
use warnings;

use Test::Routine;
with 'Routine::WackyRels','Routine::AuditAny','Routine::AutoDBIC';

use Test::More; 
use namespace::autoclean;

has 'track_params', is => 'ro', lazy => 1, default => sub {
	my $self = shift;
	my $params = {
		track_all_sources => 1,
		datapoints => [
			(qw(schema schema_ver changeset_ts changeset_elapsed)),
			(qw(change_elapsed action source pri_key_value orig_pri_key_value)),
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
	
	# Verify tracking of DB-SIDE CASCADE:
	
	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			$c->{old} => 'big',
			$c->{new} => 'venti',
			$c->{column} => 'size',
			'change.action' => 'update',
			'change.source' => 'Product'
		},{
			join => { change => 'changeset' }
		})->count => 3,
		"Expected Product UPDATE records - generated from 1-layer db-side cascade"
	);

	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			$c->{old} => 'big',
			$c->{new} => 'venti',
			$c->{column} => 'size',
			'change.action' => 'update',
			'change.source' => 'Child'
		},{
			join => { change => 'changeset' }
		})->count => 3,
		"Expected Child UPDATE records - generated from 2-layer db-side cascade"
	);
	
	is(
		$schema->resultset('AuditChangeColumn')->search_rs({
			$c->{old} => 'big',
			$c->{new} => undef,
			$c->{column} => 'size',
			'change.action' => 'update',
			'change.source' => 'Thing'
		},{
			join => { change => 'changeset' }
		})->count => 1,
		"Expected Thing UPDATE records - 'SET NULL' from db-side cascade"
	);

};

1;