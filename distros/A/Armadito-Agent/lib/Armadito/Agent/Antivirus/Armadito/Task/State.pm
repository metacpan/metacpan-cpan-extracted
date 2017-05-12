package Armadito::Agent::Antivirus::Armadito::Task::State;

use strict;
use warnings;
use base 'Armadito::Agent::Task::State';

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);
	$self->{av_client} = Armadito::Agent::HTTP::Client::ArmaditoAV->new( taskobj => $self );
	$self->{av_client}->register();

	my $response = $self->{av_client}->sendRequest(
		"url"  => $self->{av_client}->{server_url} . "/api/status",
		method => "GET"
	);

	die "Unable to get AV status with ArmaditoAV api."
		if ( !$response->is_success() );

	$self->{av_client}->pollEvents();
	$self->{av_client}->unregister();

	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Antivirus::Armadito::Task::State - State Task for Armadito Antivirus.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task:State>. Ask for Armadito Antivirus state using AV's API REST protocol and then send it in a json formatted POST request to Armadito plugin for GLPI.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.

