package Armadito::Agent::Antivirus::Armadito::Task::Scan;

use strict;
use warnings;
use MIME::Base64;
use base 'Armadito::Agent::Task::Scan';
use Armadito::Agent::HTTP::Client::ArmaditoAV;

sub getScanAPIMessage {
	my ($self) = @_;

	return "{ 'path' : '" . $self->{job}->{obj}->{scan_path} . "' }";
}

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);

	$self->{logger}->info("Armadito Scan launched.");
	$self->{av_client} = Armadito::Agent::HTTP::Client::ArmaditoAV->new( taskobj => $self );
	$self->{av_client}->register();

	my $response = $self->{av_client}->sendRequest(
		"url"   => $self->{av_client}->{server_url} . "/api/scan",
		message => $self->getScanAPIMessage(),
		method  => "POST"
	);

	die "ArmaditoAV Scan request failed." if ( !$response->is_success() );

	$self->{av_client}->pollEvents();
	$self->{av_client}->unregister();

	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Antivirus::Armadito::Task::Scan - Scan Task for Armadito Antivirus.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task:Scan>. Launch an Armadito Antivirus on-demand scan using AV's API REST protocol and then send a brief report in a json formatted POST request to Armadito plugin for GLPI.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.

