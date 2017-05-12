package Armadito::Agent::Task;

use strict;
use warnings;
use Armadito::Agent;
use Armadito::Agent::HTTP::Client::ArmaditoGLPI;
use Armadito::Agent::Tools::Inventory qw(getUUID);

sub run {
	my ( $self, %params ) = @_;

	if ( $self->{use_glpiclient} ) {
		$self->initGLPIClient();
	}

	return $self;
}

sub initGLPIClient {
	my ($self) = @_;

	$self->{glpi_client} = Armadito::Agent::HTTP::Client::ArmaditoGLPI->new(
		logger       => $self->{logger},
		user         => $self->{agent}->{config}->{user},
		password     => $self->{agent}->{config}->{password},
		proxy        => $self->{agent}->{config}->{proxy},
		ca_cert_file => $self->{agent}->{config}->{ca_cert_file},
		ca_cert_dir  => $self->{agent}->{config}->{ca_cert_dir},
		no_ssl_check => $self->{agent}->{config}->{no_ssl_check},
		debug        => $self->{agent}->{config}->{debug}
	);

	die "Error when creating ArmaditoGLPI client!" unless $self->{glpi_client};
}

sub new {
	my ( $class, %params ) = @_;

	my $use_glpiclient = defined( $params{use_glpiclient} ) ? $params{use_glpiclient} : 1;

	my $self = {
		logger         => $params{agent}->{logger},
		agent          => $params{agent},
		use_glpiclient => $use_glpiclient
	};

	$self->{jobj} = {
		agent_id      => $self->{agent}->{agent_id},
		agent_version => $Armadito::Agent::VERSION,
		uuid          => getUUID(),
		task          => ""
	};

	bless $self, $class;
	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Task - Armadito Agent Task base class.

=head1 DESCRIPTION

This is a base class for each Tasks used to interact with Armadito Antivirus and Armadito plugin for GLPI.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Armadito module. Set task's default logger.

