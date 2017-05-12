package Armadito::Agent::Antivirus::Eset::Task::Alerts;

use strict;
use warnings;
use base 'Armadito::Agent::Task::Alerts';
use Armadito::Agent::Patterns::Matcher;
use Parse::Syslog;

sub _getSystemLogs {
	my ($self) = @_;

	my $selected_logs = "";
	my $tsnow         = time;
	my $tssince       = $tsnow - 3600;                           # last hour
	my $parser        = Parse::Syslog->new('/var/log/syslog');

	while ( my $sl = $parser->next ) {
		$selected_logs .= "timestamp=\"" . $sl->{timestamp} . "\", " . $sl->{text} . "\n"
			if ( $sl->{program} eq "esets_daemon" && $sl->{timestamp} >= $tssince );
	}

	return $selected_logs;
}

# Nov 23 14:22:33 n5trusty32a esets_daemon[6974]: summ[1b3e0300]: vdb=31502, agent=pac, name="/home/malwares/contagio-malware/rtf/MALWARE_RTF_CVE-2012-0158_300_files/CVE-2012-0158_E94F9B67A66FFAF62FB5CE87B677DC5C.rtf", virus="Win32/Exploit.CVE-2012-0158.AJ trojan", action="cleaned by deleting", info="Event occurred on a new file created by the application: /usr/bin/scp (EEBC3C511B955D5AE2A52A5CE66EC472398AB6B9).", avstatus="clean (deleted)", hop="discarded"

sub _parseLogs {
	my ( $self, $logs ) = @_;

	my $parser = Armadito::Agent::Patterns::Matcher->new( logger => $self->{logger} );

	my $labels = [ 'detection_time', 'filepath', 'name', 'action', 'info' ];
	my $pattern = 'timestamp="(.*?)".*?name="(.*?)", virus="(.*?)", action="(.*?)", info="(.*?)",';
	$parser->addPattern( "alerts", $pattern, $labels );
	$parser->addExclusionPattern(', avstatus="not scanned"');
	$parser->run( $logs, '\n' );

	return $parser->getResults();
}

sub run {
	my ( $self, %params ) = @_;
	$self = $self->SUPER::run(%params);

	my $eset_logs = $self->_getSystemLogs();
	if ( $eset_logs eq "" ) {
		$self->{logger}->info("No alerts found.");
		return $self;
	}

	my $alerts   = $self->_parseLogs($eset_logs);
	my $n_alerts = @{ $alerts->{alerts} };
	$self->{logger}->info( $n_alerts . " alert(s) found." );
	$self->_sendAlerts($alerts);

	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Antivirus::Eset::Task::Alerts - Alerts Task for ESET Antivirus.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task:Alerts>. Get Antivirus' alerts and send them as json messages to armadito glpi plugin.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.

