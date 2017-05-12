package Armadito::Agent;

use 5.008000;
use strict;
use warnings;
use English qw(-no_match_vars);
use UNIVERSAL::require;

require Exporter;

use Armadito::Agent::Config;
use Armadito::Agent::Storage;
use Armadito::Agent::Antivirus;
use Armadito::Agent::Logger qw (LOG_DEBUG LOG_INFO LOG_DEBUG2);

our $VERSION = "0.10.1";

my @supported_antiviruses = ( "Armadito", "Eset", "Kaspersky" );
my @supported_tasks  = ( "State",      "Enrollment", "Getjobs", "Runjobs", "Alerts", "Scan", "AVConfig", "Scheduler" );
my @unspecific_tasks = ( "Enrollment", "Getjobs",    "Runjobs" );

sub new {
	my ( $class, %params ) = @_;

	my $self = {
		status  => 'unknown',
		confdir => $params{confdir},
		datadir => $params{datadir},
		libdir  => $params{libdir},
		vardir  => $params{vardir},
		sigterm => $params{sigterm},
		targets => [],
		tasks   => []
	};

	bless $self, $class;
	return $self;
}

sub init {
	my ( $self, %params ) = @_;

	$self->_loadAgentConfiguration(%params);

	my $verbosity
		= $self->{config}->{debug} && $self->{config}->{debug} == 1 ? LOG_DEBUG
		: $self->{config}->{debug} && $self->{config}->{debug} == 2 ? LOG_DEBUG2
		:                                                             LOG_INFO;

	$self->_validateOptions(%params);

	$self->{logger} = Armadito::Agent::Logger->new(
		config    => $self->{config},
		backends  => $self->{config}->{logger},
		verbosity => $verbosity
	);

	$self->{armadito_storage} = Armadito::Agent::Storage->new(
		logger    => $self->{logger},
		directory => $self->{vardir}
	);

	$self->{key}          = defined( $params{options}->{key} ) ? $params{options}->{key} : "";
	$self->{agent_id}     = 0;
	$self->{scheduler_id} = 0;
	$self->_getArmaditoIds();

	my $class = "Armadito::Agent::Antivirus::$self->{config}->{antivirus}";
	$class->require();
	$self->{antivirus} = $class->new( logger => $self->{logger} );
}

sub _loadAgentConfiguration {
	my ( $self, %params ) = @_;

	$self->{config} = Armadito::Agent::Config->new();
	$self->{config}->loadDefaults( $self->_getDefaultConf() );
	$self->{config}->loadFromFile( $self->{confdir} . "/agent.cfg" );
	$self->{config}->overrideWithArgs(%params);
	$self->{config}->checkContent();
}

sub _getDefaultConf {
	my ($self) = @_;

	return {
		'ca-cert-dir'          => undef,
		'ca-cert-file'         => undef,
		'color'                => undef,
		'conf-reload-interval' => 0,
		'debug'                => undef,
		'force'                => undef,
		'html'                 => undef,
		'local'                => undef,
		'logger'               => 'Stderr',
		'logfile'              => undef,
		'logfacility'          => 'LOG_USER',
		'logfile-maxsize'      => undef,
		'no-ssl-check'         => undef,
		'proxy'                => undef,
		'server'               => undef,
		'timeout'              => 180,
		'user'                 => undef,
		'password'             => undef,
		'stdout'               => undef,
		'antivirus'            => undef,
		'scheduler'            => undef
	};
}

sub _validateOptions {
	my ( $self, %params ) = @_;

	$self->isAVSupported( $self->{config}->{antivirus} )
		or die "Unsupported Antivirus. Use --list-avs to see which antiviruses are supported.";

	if ( $params{options}->{task} ) {
		$self->isTaskSupported( $params{options}->{task} )
			or die "Unsupported Task. Use --list-tasks to see which tasks are supported.";
	}
}

sub _getArmaditoIds {
	my ($self) = @_;

	my $data = $self->{armadito_storage}->restore( name => 'Armadito-Agent' );

	$self->{agent_id}     = $data->{agent_id}     if ( defined( $data->{agent_id} ) );
	$self->{scheduler_id} = $data->{scheduler_id} if ( defined( $data->{scheduler_id} ) );

	$self->{logger}->debug( "agent_id = " . $self->{agent_id} );
	$self->{logger}->debug( "scheduler_id = " . $self->{scheduler_id} );
}

sub _storeArmaditoIds {
	my ($self) = @_;

	$self->{armadito_storage}->save(
		name => 'Armadito-Agent',
		data => {
			agent_id     => $self->{agent_id},
			scheduler_id => $self->{scheduler_id}
		}
	);
}

sub isAVSupported {
	my ( $self, $antivirus ) = @_;
	foreach (@supported_antiviruses) {
		if ( $antivirus eq $_ ) {
			return 1;
		}
	}
	return 0;
}

sub isTaskSupported {
	my ( $self, $task ) = @_;
	foreach (@supported_tasks) {
		if ( $task eq $_ ) {
			return 1;
		}
	}
	return 0;
}

sub isTaskSpecificToAV {
	my ( $self, $task ) = @_;
	foreach (@unspecific_tasks) {
		if ( $task eq $_ ) {
			return 0;
		}
	}
	return 1;
}

sub displaySupportedTasks {
	my ($self) = @_;
	print "List of supported tasks :\n";
	foreach (@supported_tasks) {
		print $_. "\n";
	}
}

sub displaySupportedAVs {
	my ($self) = @_;
	print "List of supported antiviruses :\n";
	foreach (@supported_antiviruses) {
		print $_. "\n";
	}
}

sub runTask {
	my ( $self, $task ) = @_;

	my $class     = "Armadito::Agent::Task::$task";
	my $antivirus = $self->{config}->{antivirus};

	if ( $self->isTaskSpecificToAV($task) ) {
		$class = "Armadito::Agent::Antivirus::" . $antivirus . "::Task::" . $task;
	}

	if ( $task eq "Scheduler" ) {
		$class = "Armadito::Agent::Scheduler::" . $self->{config}->{scheduler};
	}

	$class->require();
	my $taskclass = $class->new( agent => $self );
	$taskclass->run();
}

1;
__END__
=head1 NAME

Armadito::Agent - Armadito Agent

=head1 VERSION

0.10.1

=head1 DESCRIPTION

Agent interfacing between Armadito Antivirus and Armadito plugin for GLPI for Windows and Linux.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<confdir>

the configuration directory.

=item I<datadir>

the read-only data directory.

=item I<vardir>

the read-write data directory.

=item I<options>

the options to use.

=back

=head2 init()

Initialize the agent.

=head2 isAVSupported($antivirus)

Returns true if given antivirus is supported by the current version of the agent.

=head2 isTaskSupported($task)

Returns true if given task is supported by the current version of the agent.

=head2 isTaskSpecificToAV($task)

Returns true if given task is specific to an Antivirus.

=head2 displaySupportedTasks()

Display all currently supported tasks to stdout.

=head2 displaySupportedAVs()

Display all currently supported Antiviruses to stdout.

=head2 runTask($task)

Run a given task.

=head1 SEE ALSO

=over 4

=item * L<http://armadito-glpi.readthedocs.io/en/dev/>

Armadito for GLPI online documentation.

=item * L<https://github.com/armadito>

Armadito organization on github.

=item * L<http://www.glpi-project.org/>

GLPI Project main page.

=back

=cut

=head1 AUTHOR

vhamon, E<lt>vhamon@teclib.comE<gt>

=head1 COPYRIGHTS

Copyright (C) 2006-2010 OCS Inventory contributors
Copyright (C) 2010-2012 FusionInventory Team
Copyright (C) 2011-2017 Teclib'

=head1 LICENSE

This software is licensed under the terms of GPLv3, see COPYING file for
details.

=cut
