package Armadito::Agent::Antivirus::Armadito::Task::Alerts;

use strict;
use warnings;
use base 'Armadito::Agent::Task::Alerts';

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);

	# TODO : Parse::Syslog or Win32::Eventlog

	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Antivirus::Armadito::Task::Alerts - Alerts Task for Armadito Antivirus.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task:Alerts>. Get Armadito Antivirus alerts and send them as json messages to armadito glpi plugin.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.

