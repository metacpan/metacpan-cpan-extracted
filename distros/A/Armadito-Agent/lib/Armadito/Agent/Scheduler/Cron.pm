package Armadito::Agent::Scheduler::Cron;

use strict;
use warnings;
use base 'Armadito::Agent::Task::Scheduler';

use Armadito::Agent::Tools::File qw (writeFile readFile);
use Armadito::Agent::Tools::Time qw (nowToISO8601);
use Armadito::Agent::Patterns::Matcher;
use Cwd 'abs_path';
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
	$parser->addPattern( 'logfile', 'Logfile\s*=\s*(.*)\s*$' );
	$parser->addPattern( 'user',    'User\s*=\s*(.*)\s*$' );

	my $labels = [ 'freq', 'name', 'args' ];
	my $pattern = '^([\s\*\d\/,]*?);(.*?);(.*?)$';
	$parser->addPattern( 'tasks', $pattern, $labels );

	$parser->run( $conf_file, '\n' );
	$parser->addHookForLabel( 'freq', \&trimSpaces );
	$parser->addHookForLabel( 'name', \&trimSpaces );
	$parser->addHookForLabel( 'args', \&trimSpaces );

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

sub _updateCronTab {
	my ($self) = @_;

	my $cron_path = "/etc/cron.d/armadito-agent";
	my $content   = "#\n# Cron configuration for armadito-agent\n#\n";

	$content .= "# last modification by armadito-agent : " . nowToISO8601('Local') . "\n\n";
	$content .= "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\n\n";

	foreach ( @{ $self->{config}->{tasks} } ) {
		$content .= $self->_addCronTask($_);
	}

	writeFile(
		content  => $content,
		mode     => '>',
		filepath => $cron_path
	);
}

sub _addCronTask {
	my ( $self, $task ) = @_;

	return
		  $task->{freq} . "\t"
		. $self->{config}->{user}[0] . "\t"
		. abs_path($0)
		. " -t \""
		. $task->{name} . "\" "
		. $task->{args} . " " . ">>"
		. $self->{config}->{logfile}[0] . ' 2>&1' . "\n";
}

sub run {
	my ( $self, %params ) = @_;

	$self = $self->SUPER::run(%params);
	$self->_loadConf();
	$self->_updateCronTab();

	return $self;
}

1;

__END__

=head1 NAME

Armadito::Agent::Scheduler::Cron - base class used for task scheduling management

=head1 DESCRIPTION

This task inherits from L<Armadito::Agent::Task::Scheduler>. It allows remote management of agent's crontab configuration.

=head1 FUNCTIONS

=head2 run ( $self, %params )

Run the task.

