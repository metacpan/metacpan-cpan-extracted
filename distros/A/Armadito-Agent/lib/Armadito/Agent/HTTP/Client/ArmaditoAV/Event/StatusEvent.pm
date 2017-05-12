package Armadito::Agent::HTTP::Client::ArmaditoAV::Event::StatusEvent;

use strict;
use warnings;
use base 'Armadito::Agent::HTTP::Client::ArmaditoAV::Event';
use JSON;

sub new {
	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	return $self;
}

sub _sendToGLPI {
	my ( $self, $message ) = @_;

	my $response = $self->{taskobj}->{glpi_client}->sendRequest(
		"url"   => $self->{taskobj}->{agent}->{config}->{server}[0] . "/api/states",
		message => $message,
		method  => "POST"
	);

	if ( $response->is_success() ) {
		$self->{taskobj}->{logger}->info("Send ArmaditoAV State successful...");
	}
	else {
		$self->{taskobj}->_handleError($response);
		$self->{taskobj}->{logger}->info("Send ArmaditoAV State failed...");
	}

	return;
}

sub run {
	my ( $self, %params ) = @_;

	my $obj = {
		dbinfo    => $self->{jobj},
		avdetails => []
	};

	$self->{taskobj}->{jobj}->{task}->{obj} = $obj;
	my $json_text = to_json( $self->{taskobj}->{jobj} );
	print "JSON formatted str : \n" . $json_text . "\n";

	$self->_sendToGLPI($json_text);
	$self->{end_polling} = 1;

	return $self;
}
1;

__END__

=head1 NAME

Armadito::Agent::HTTP::Client::ArmaditoAV::Event::StatusEvent - ArmaditoAV StatusEvent class

=head1 DESCRIPTION

This is the class dedicated to StatusEvent of ArmaditoAV api.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run event related stuff. Send ArmaditoAV status to Armadito Plugin for GLPI.

=head2 new ( $class, %params )

Instanciate this class.
