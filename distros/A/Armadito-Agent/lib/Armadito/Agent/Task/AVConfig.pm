package Armadito::Agent::Task::AVConfig;

use strict;
use warnings;
use base 'Armadito::Agent::Task';
use JSON;
use Data::Dumper;

sub new {
	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	if ( $params{debug} ) {
		$self->{debug} = 1;
	}

	my $task = {
		name      => "AVConfig",
		antivirus => $self->{agent}->{antivirus}->getJobj()
	};

	$self->{jobj}->{task} = $task;
	$self->{glpi_url}     = $self->{agent}->{config}->{server}[0];
	$self->{avconfig}     = [];

	return $self;
}

sub _handleError {
	my ( $self, $response ) = @_;

	$self->{logger}->info( "Error Response : " . $response->content() );
	my $obj = from_json( $response->content(), { utf8 => 1 } );
	$self->{logger}->error( Dumper($obj) );

	return $self;
}

sub _addConfEntry {
	my ( $self, $attr, $value ) = @_;

	$attr =~ s/^://;

	my $conf_entry = {
		attr  => $attr,
		value => $value
	};

	push( @{ $self->{avconfig} }, $conf_entry );
}

sub _sendToGLPI {
	my ($self) = @_;

	$self->{jobj}->{task}->{obj} = $self->{avconfig};

	my $json_text = to_json( $self->{jobj} );
	$self->{logger}->debug($json_text);

	my $response = $self->{glpi_client}->sendRequest(
		"url"   => $self->{glpi_url} . "/api/avconfigs",
		message => $json_text,
		method  => "POST"
	);

	if ( $response->is_success() ) {
		$self->{logger}->info("AVConfig successful...");
	}
	else {
		$self->_handleError($response);
		$self->{logger}->info("AVConfig failed...");
	}

	return 1;
}

1;

__END__

=head1 NAME

Armadito::Agent::Task::AVConfig - AVConfig Task base class

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task>. Get Antivirus configuration and send them as json messages to armadito glpi plugin.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.

