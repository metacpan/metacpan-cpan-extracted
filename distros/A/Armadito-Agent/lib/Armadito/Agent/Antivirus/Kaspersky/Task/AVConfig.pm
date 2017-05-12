package Armadito::Agent::Antivirus::Kaspersky::Task::AVConfig;

use strict;
use warnings;
use base 'Armadito::Agent::Task::AVConfig';
use IPC::System::Simple qw(capture $EXITVAL EXIT_ANY);
use Armadito::Agent::Tools::File qw(rmFile);
use Armadito::Agent::Tools qw(getOSTempDir);
use XML::LibXML;
use Data::Dumper;

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);

	my $export_path = getOSTempDir() . "exported_settings.xml";
	rmFile( filepath => $export_path );

	if ( $self->_exportSettings($export_path) == 0 ) {
		$self->_parseSettings($export_path);
		$self->_sendToGLPI();
	}
}

sub _exportSettings {
	my ( $self, $export_path ) = @_;

	my $bin_path = $self->{agent}->{antivirus}->{scancli_path};

	my $cmdline = "\"" . $bin_path . "\" EXPORT \"" . $export_path . "\"";
	my $output = capture( EXIT_ANY, $cmdline );
	$self->{logger}->info($output);
	$self->{logger}->info( "Program exited with " . $EXITVAL . "\n" );

	return $EXITVAL;
}

sub _parseSettings {
	my ( $self, $export_path ) = @_;

	my $parser = XML::LibXML->new();
	my $doc    = $parser->parse_file($export_path);

	my ($ondemand_settings)        = $doc->findnodes('/root/ekaSettings/on_demand_tasks');
	my ($monitoring_settings)      = $doc->findnodes('/root/ekaSettings/monitoring_tasks');
	my ($services_settings)        = $doc->findnodes('/root/ekaSettings/services');
	my ($persistent_data_settings) = $doc->findnodes('/root/persistentData');

	$self->_parseItemNode( $ondemand_settings,        "On_demand" );
	$self->_parseItemNode( $monitoring_settings,      "Monitoring" );
	$self->_parseItemNode( $services_settings,        "Services" );
	$self->_parseItemNode( $persistent_data_settings, "PersistentData" );
}

sub _parseItemNode {
	my ( $self, $node, $path ) = @_;

	foreach ( $node->findnodes('./item') ) {
		$self->_parseSubNode( $_, $path . ":" . $_->getAttribute('name') );
	}
}

sub _parseSubNode {
	my ( $self, $node, $path ) = @_;

	foreach ( $node->findnodes('./*') ) {
		my $nodeName   = $_->nodeName;
		my @attributes = $_->attributes;
		foreach my $attr (@attributes) {
			$self->_addConfEntry( $path . ":" . $nodeName . ":" . $attr->nodeName, $attr->value );
		}

		$self->_parseSubNode( $_, $path . ":" . $nodeName );
	}
}

1;

__END__

=head1 NAME

Armadito::Agent::Antivirus::Kaspersky::Task::AVConfig - AVConfig Task for Kaspersky Antivirus.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task:AVConfig>. Get Antivirus configuration and then send it in a json formatted POST request to Armadito plugin for GLPI.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.
