package Armadito::Agent::Task::State;

use strict;
use warnings;
use base 'Armadito::Agent::Task';

use Data::Dumper;
use JSON;

sub new {
	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	if ( $params{debug} ) {
		$self->{debug} = 1;
	}

	my $task = {
		name      => "State",
		antivirus => $self->{agent}->{antivirus}->getJobj()
	};

	$self->{jobj}->{task} = $task;

	return $self;
}

sub _sendToGLPI {
	my ( $self, $stateobj ) = @_;

	$self->{jobj}->{task}->{obj} = $stateobj;
	my $json_text = to_json( $self->{jobj} );

	my $response = $self->{glpi_client}->sendRequest(
		"url"   => $self->{agent}->{config}->{server}[0] . "/api/states",
		message => $json_text,
		method  => "POST"
	);

	if ( $response->is_success() ) {
		$self->{logger}->info("Send AV State successful...");
	}
	else {
		$self->_handleError($response);
		$self->{logger}->info("Send AV State failed...");
	}
}

sub _addAVDetail {
	my ( $self, $attr, $value ) = @_;

	$attr =~ s/^://;

	my $avdetail = {
		attr  => $attr,
		value => $value
	};

	push( @{ $self->{data}->{avdetails} }, $avdetail );
}

sub _handleError {
	my ( $self, $response ) = @_;

	$self->{logger}->info( "Error Response : " . $response->content() );
	my $obj = from_json( $response->content(), { utf8 => 1 } );
	$self->{logger}->error( Dumper($obj) );

	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Task::State - State Task base class

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task>. Get Antivirus state and send it to GPLI server Armadito plugin.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.

