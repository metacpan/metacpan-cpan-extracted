package Armadito::Agent::Antivirus::Kaspersky::Task::Alerts;

use strict;
use warnings;
use base 'Armadito::Agent::Task::Alerts';

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);

	my $osclass = $self->{agent}->{antivirus}->getOSClass();
	my $alerts = { alerts => $osclass->getAlerts() };

	my $n_alerts = @{ $alerts->{alerts} };
	$self->{logger}->info( $n_alerts . " alert(s) found." );

	$self->_sendAlerts($alerts);
}

1;

__END__

=head1 NAME

Armadito::Agent::Antivirus::Kaspersky::Task::Alerts - Alerts Task for Kaspersky Antivirus.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task:Alerts>. Get Antivirus' alerts and send them as json messages to armadito glpi plugin.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.
