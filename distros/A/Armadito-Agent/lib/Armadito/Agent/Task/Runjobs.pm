package Armadito::Agent::Task::Runjobs;

use strict;
use warnings;
use base 'Armadito::Agent::Task';

use Armadito::Agent::Storage;
use Data::Dumper;
use MIME::Base64;
use Try::Tiny;
use JSON;

sub new {
	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	if ( $params{debug} ) {
		$self->{debug} = 1;
	}

	my $task = {
		name      => "Runjobs",
		antivirus => $self->{agent}->{antivirus}->getJobj()
	};

	$self->{jobj}->{task} = $task;

	return $self;
}

sub _getStoredJobs {
	my ($self) = @_;

	my $data = $self->{agent}->{armadito_storage}->restore( name => 'Armadito-Agent-Jobs' );
	if ( defined( $data->{jobs} ) ) {
		foreach my $job ( @{ $data->{jobs} } ) {
			$self->{logger}->info( "Job " . $job->{job_id} . " - " . $job->{job_priority} );
		}
		$self->{jobs} = $data->{jobs};
	}

	return $self;
}

sub _rmJobFromStorage {
	my ( $self, $job_id ) = @_;

	my $jobs = ();
	my $data = $self->{agent}->{armadito_storage}->restore( name => 'Armadito-Agent-Jobs' );
	if ( defined( $data->{jobs} ) ) {
		foreach ( @{ $data->{jobs} } ) {
			push( @$jobs, $_ ) if $_->{job_id} ne $job_id;
		}
	}

	$self->{agent}->{armadito_storage}->save(
		name => 'Armadito-Agent-Jobs',
		data => {
			jobs => $jobs
		}
	);
}

sub _sortJobsByPriority {
	my ($self) = @_;

	@{ $self->{jobs} } = reverse sort { $a->{job_priority} <=> $b->{job_priority} } @{ $self->{jobs} };

	return $self;
}

sub _handleError {
	my ( $self, $response ) = @_;

	$self->{logger}->info( "Error Response : " . $response->content() );
	my $obj = from_json( $response->content(), { utf8 => 1 } );
	$self->{logger}->error( Dumper($obj) );

	return $self;
}

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);
	$self = $self->_getStoredJobs();
	$self = $self->_sortJobsByPriority();
	$self = $self->_runJobs();

	return $self;
}

sub _runJob {
	my ( $self, $job ) = @_;
	my $config     = ();
	my $start_time = time;

	try {
		my $antivirus = $self->{jobj}->{task}->{antivirus}->{name};
		my $task      = $job->{job_type};
		my $class     = "Armadito::Agent::Task::$task";

		if ( $self->{agent}->isTaskSpecificToAV($task) ) {
			$class = "Armadito::Agent::Antivirus::" . $antivirus . "::Task::" . $task;
		}

		$class->require();
		my $taskclass = $class->new( agent => $self->{agent}, job => $job );
		$taskclass->run();
	}
	catch {
		$self->{logger}->error($_);
		$self->{jobj}->{task}->{obj} = {
			code       => 1,
			message    => encode_base64($_),
			job_id     => $job->{job_id},
			start_time => $start_time,
			end_time   => time
		};

		return $self;
	};

	$self->{jobj}->{task}->{obj} = {
		code       => 0,
		message    => "runJob successful",
		job_id     => $job->{job_id},
		start_time => $start_time,
		end_time   => time
	};

	return $self;
}

sub _runJobs {
	my ($self) = @_;

	foreach my $job ( @{ $self->{jobs} } ) {
		$self->_runJob($job);
		$self->_sendStatus();
		$self->_rmJobFromStorage( $job->{job_id} );
	}

	return $self;
}

sub _sendStatus {
	my ($self) = @_;

	my $json_text = to_json( $self->{jobj} );

	my $response = $self->{glpi_client}->sendRequest(
		"url"   => $self->{agent}->{config}->{server}[0] . "/api/jobs",
		message => $json_text,
		method  => "POST"
	);

	if ( $response->is_success() ) {
		$self->{logger}->info("Runjobs sendStatus successful...");
	}
	else {
		$self->_handleError($response);
		$self->{logger}->info("Runjobs sendStatus failed...");
	}
}

1;

__END__

=head1 NAME

Armadito::Agent::Task::Runjobs - Runjobs Task base class.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task>. Run jobs and send results to /jobs REST API of Armadito Plugin for GLPI.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.



