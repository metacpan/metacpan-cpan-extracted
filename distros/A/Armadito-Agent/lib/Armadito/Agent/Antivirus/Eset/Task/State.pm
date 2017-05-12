package Armadito::Agent::Antivirus::Eset::Task::State;

use strict;
use warnings;
use base 'Armadito::Agent::Task::State';
use Armadito::Agent::Tools::File qw( readFile );
use Armadito::Agent::Patterns::Matcher;

sub _getDatabasesInfo {
	my ($self) = @_;

	my $parser = Armadito::Agent::Patterns::Matcher->new( logger => $self->{logger} );
	$parser->addPattern( 'install_time',            'InstallTime=(\d+)' );
	$parser->addPattern( 'global_update_timestamp', 'LastUpdate=(\d+)' );
	$parser->addPattern( 'last_update_attempt',     'LastUpdateAttempt=(\d+)' );

	my $data_filepath = "/var/opt/eset/esets/lib/data/data.txt";
	my $data = readFile( filepath => $data_filepath );

	$parser->run( $data, '\n' );
	return $parser->getResults();
}

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);

	my $dbinfo = $self->_getDatabasesInfo();

	$self->_sendToGLPI($dbinfo);
}

1;

__END__

=head1 NAME

Armadito::Agent::Antivirus::Eset::Task::State - State Task for ESET Antivirus.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task:State>. Get Antivirus state and then send it in a json formatted POST request to Armadito plugin for GLPI.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

=head2 new ( $self, %params )

Instanciate Task.

