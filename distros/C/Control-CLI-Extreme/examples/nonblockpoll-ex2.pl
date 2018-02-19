#!/usr/local/bin/perl

# Same as nonblockpoll-ex1 except that activity shows a count of completed switches / commands sent

use strict;
use warnings;
use Control::CLI::Extreme qw( poll );
my $connectionType = 'SSH';
my $connectionTimeout = 15;	# seconds
my $timeout = 10;		# seconds
my $username = 'rwa';
my $password = 'rwa';
my $debug = 0;

my %Devices = (
	'8600A'		=> '10.134.161.11',
	'8600B'		=> '10.134.161.12',
	'8600C'		=> '10.134.161.13',
	'8600D'		=> '10.134.161.14',
);

my %Cmds = (
	'8600A'	=> [
				'config term',
				'snmp-server location "this is a test!"',
				'show snmp-server',
				'default snmp-server location',
			],
	'8600B'	=> [
				'config term',
				'snmp-server location "this is a test!"',
				'show snmp-server',
				'default snmp-server location',
			],
	'8600C'	=> [
				'config term',
				'snmp-server location "this is a test!"',
				'show snmp-server',
				'default snmp-server location',
			],
	'8600D'	=> [
				'config term',
				'snmp-server location "this is a test!"',
				'show snmp-server',
				'default snmp-server location',
			],
);

print "Using Control::CLI $Control::CLI::VERSION\n";
print "Using Control::CLI::Extreme $Control::CLI::Extreme::VERSION\n";


MAIN:{
	my (%cli, %output, $count, $running, $completed);

	#
	# Create CLI objects
	#
	print "\nCreated CLI object for:\n";
	foreach my $switch (keys %Devices) {
		$cli{$switch} = new Control::CLI::Extreme(
			Use			=> $connectionType,
		  	Timeout 		=> $timeout,
			Connection_timeout	=> $connectionTimeout,
			Return_result		=> 0,
			Input_log		=> $debug ? $switch.'.in' : undef,
			Output_log		=> $debug ? $switch.'.out' : undef,
			Dump_log		=> $debug ? $switch.'.dump' : undef,
			Blocking		=> 0,
			Debug			=> $debug,
		);
		print " - $switch\n";
	}

	#
	# Connect to all switches
	#
	print "$connectionType connecting to switches ";
	foreach my $switch (keys %Devices) {
		$cli{$switch}->connect(
			Host			=>	$Devices{$switch},
			Username		=>	$username,
			Password		=>	$password,
		);
	}
	# Poll all complete
	do {
		($running, $completed) = poll(
			Object_list	=>	\%cli,
			Object_complete	=>	'next',
			Poll_code	=>	sub { local $| = 1; print '.' },
		);
		print "<$completed>";
	} while $running;
	print " done!\n";

	#
	# Get into enable mode
	#
	print "Entering PrivExec mode ";
	foreach my $switch (keys %Devices) {
		$cli{$switch}->enable;
	}
	# Poll all complete
	do {
		($running, $completed) = poll(
			Object_list	=>	\%cli,
			Object_complete	=>	'next',
			Poll_code	=>	sub { local $| = 1; print '.' },
		);
		print "<$completed>";
	} while $running;
	print " done!\n";

	#
	# Send commands
	#
	print "Sending commands ";
	while (scalar keys %Cmds) {
		foreach my $switch (keys %Cmds) {
			if (my $cmd = shift @{$Cmds{$switch}}) {
				$cli{$switch}->cmd($cmd);
				$count++;
			}
			else {
				delete $Cmds{$switch};	# Nibble away at the Cmd hash
				next;
			}
		}
		last unless scalar keys %Cmds; # All commands sent, come out

		# Poll all complete
		poll(
			Object_list	=>	\%cli,
			Poll_code	=>	sub { local $| = 1; print '.' },
		);

		# Retrieve output
		foreach my $switch (keys %Cmds) {
			$output{$switch} .= ($cli{$switch}->cmd_poll)[1];
		}
		print "<$count>";
	}
	print " done!\n";

	#
	# Disconnect
	#
	foreach my $switch (keys %Devices) {
		$cli{$switch}->disconnect;
	}

	#
	# Print output if any
	#
	foreach my $switch (keys %Devices) {
		print "\nOutput from $switch:\n---------------------\n", $output{$switch} if length $output{$switch};
	}
}
