package Armadito::Agent::Scheduler::Win32Native;

use strict;
use warnings;
use base 'Armadito::Agent::Task::Scheduler';

use Armadito::Agent::Tools::File qw (writeFile readFile);
use Armadito::Agent::Tools::Time qw (nowToISO8601);
use Armadito::Agent::Patterns::Matcher;
use IPC::System::Simple qw(capture $EXITVAL EXIT_ANY);
use Data::Dumper;

sub _loadConf {
	my ( $self, %params ) = @_;

	$self->{config} = $self->_parseConf( $self->_getConfPath() );
}

sub _parseConf {
	my ( $self, $conf_path ) = @_;

	my $conf_file = readFile( filepath => $conf_path );

	my $parser = Armadito::Agent::Patterns::Matcher->new( logger => $self->{logger} );
	$parser->addExclusionPattern('^#');

	my $labels = [ 'options', 'name', 'args' ];
	my $pattern = '^(.*?);(.*?);(.*?)$';
	$parser->addPattern( 'tasks', $pattern, $labels );

	$parser->run( $conf_file, '\n' );
	$parser->addHookForLabel( 'options', \&trimSpaces );
	$parser->addHookForLabel( 'name',    \&trimSpaces );
	$parser->addHookForLabel( 'args',    \&trimSpaces );

	return $parser->getResults();
}

sub trimSpaces {
	my ($match) = @_;

	$match =~ s/\s+$//ms;
	$match =~ s/^\s+//ms;

	return $match;
}

sub _getDefaultConf {
	my ($self) = @_;

	return {
		'user'    => undef,
		'Logfile' => undef
	};
}

sub _getConfPath {
	my ($self) = @_;

	return $self->{agent}->{confdir} . "/scheduler-" . lc( $self->{scheduler}->{name} ) . ".cfg";
}

sub _createScheduledTask {
	my ( $self, $task ) = @_;

	my $taskname = "ArmaditoAgentTask" . $task->{name};
	my $cmdline  = "schtasks /Create /F /RU SYSTEM ";
	$cmdline .= $task->{options} . " /TN " . $taskname . " ";
	$cmdline .= "/TR \"\\\"C:\\Program Files\\Armadito-Agent\\bin\\armadito-agent.bat\\\" -t ";
	$cmdline .= "'" . $task->{name} . "' " . $task->{args} . " ";
	$cmdline .= "1>> \\\"C:\\Program Files\\Armadito-Agent\\var\\armadito-agent-" . $task->{name} . ".log\\\" 2>>&1 \"";

	$self->{logger}->info($cmdline);

	my $output = capture( EXIT_ANY, $cmdline );
	$self->{logger}->info($output);
	$self->{logger}->info( "Program exited with " . $EXITVAL . "\n" );
}

sub _createAllTasks {
	my ($self) = @_;

	foreach ( @{ $self->{config}->{tasks} } ) {
		$self->_createScheduledTask($_);
	}
}

sub _getExistingTasks {
	my ($self) = @_;

	my $cmdline = "schtasks /Query /FO CSV";
	my $output = capture( EXIT_ANY, $cmdline );
	$self->{logger}->info( "Program exited with " . $EXITVAL . "\n" );

	my $parser  = Armadito::Agent::Patterns::Matcher->new( logger => $self->{logger} );
	my $labels  = ['name'];
	my $pattern = '^"(\\\\ArmaditoAgentTask.*?)"';
	$parser->addPattern( 'tasks', $pattern, $labels );
	$parser->run( $output, '\n' );
	$parser->addHookForLabel( 'name', \&trimSlashes );

	return $parser->getResults();
}

sub trimSlashes {
	my ($match) = @_;
	$match =~ s/^\\+//ms;
	return $match;
}

sub _deleteExistingTask {
	my ( $self, $task ) = @_;

	my $cmdline = "schtasks /Delete /F /TN \"" . $task->{name} . "\"";
	$self->{logger}->info($cmdline);

	my $output = capture( EXIT_ANY, $cmdline );
	$self->{logger}->info($output);
	$self->{logger}->info( "Program exited with " . $EXITVAL . "\n" );
}

sub _deleteExistingTasks {
	my ($self) = @_;

	my $existing_tasks = $self->_getExistingTasks();

	foreach ( @{ $existing_tasks->{tasks} } ) {
		$self->_deleteExistingTask($_);
	}
}

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);
	$self->_loadConf();
	$self->_deleteExistingTasks();
	$self->_createAllTasks();

	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Scheduler::Win32Native - class for managing native Win32 Scheduler.

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task::Scheduler>. It allows remote management of agent's crontab configuration.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

