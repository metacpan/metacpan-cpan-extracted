package Armadito::Agent::Task::Getjobs;

use strict;
use warnings;
use base 'Armadito::Agent::Task';

use Armadito::Agent::Storage;
use Data::Dumper;
use JSON;

sub new {
	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	if ( $params{debug} ) {
		$self->{debug} = 1;
	}

	my $task = {
		name      => "Getjobs",
		antivirus => $self->{agent}->{antivirus}->getJobj()
	};

	$self->{jobj}->{task} = $task;

	return $self;
}

sub _storeJobs {
	my ( $self, $jobs ) = @_;

	# We merge stored jobs with new ones
	my $data = $self->{agent}->{armadito_storage}->restore( name => 'Armadito-Agent-Jobs' );
	if ( defined( $data->{jobs} ) ) {
		foreach ( @{ $data->{jobs} } ) {
			push( @$jobs, $_ );
		}
	}

	$self->{agent}->{armadito_storage}->save(
		name => 'Armadito-Agent-Jobs',
		data => {
			jobs => $jobs
		}
	);
}

sub _handleResponse {
	my ( $self, $response ) = @_;

	$self->{logger}->info( "Successful Response : " . $response->content() );
	my $obj = from_json( $response->content(), { utf8 => 1 } );

	if ( defined( $obj->{jobs} ) && ref( $obj->{jobs} ) eq "ARRAY" ) {
		$self->_storeJobs( $obj->{jobs} );
	}

	$self->{logger}->info( "all Jobs : " . Dumper($obj) );
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

	my $response = $self->{glpi_client}->sendRequest(
		"url" => $self->{agent}->{config}->{server}[0] . "/api/jobs",
		args  => {
			antivirus => $self->{jobj}->{task}->{antivirus}->{name},
			agent_id  => $self->{jobj}->{agent_id}
		},
		method => "GET"
	);

	if ( $response->is_success() ) {
		$self->_handleResponse($response);
		$self->{logger}->info("Getjobs successful...");
	}
	else {
		$self->_handleError($response);
		$self->{logger}->info("Getjobs failed...");
	}

	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Task::Getjobs - Getjobs Task base class.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task>. Send a pull GET request to get jobs agent has to do according to Armadito Plugin for GLPI.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.



