#!/usr/local/bin/perl

# Simple example of using threads

use strict;
use warnings;
use threads;
use Control::CLI::Extreme;
use Time::HiRes qw( sleep );
my $connectionType = 'TELNET';
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


sub cliThread { # Thread to each device
	my $switch = shift;
	my $tid = threads->tid();
	my ($cli, $output);

	#
	# Create CLI object
	#
	$cli = new Control::CLI::Extreme(
		Use			=> $connectionType,
	  	Timeout 		=> $timeout,
		Connection_timeout	=> $connectionTimeout,
		Return_result		=> 0,
		Input_log		=> $debug ? $switch.'.in' : undef,
		Output_log		=> $debug ? $switch.'.out' : undef,
		Dump_log		=> $debug ? $switch.'.dump' : undef,
       		Debug			=> $debug,
	);

	#
	# Connect to switch
	#
	$cli->connect(
		Host			=>	$Devices{$switch},
		Username		=>	$username,
		Password		=>	$password,
	) or die "ERROR => Unable to connect to $switch";
	print "$connectionType connected to $switch (thread $tid)\n";

	#
	# Get into enable mode
	#
	$cli->enable or die "ERROR => Cannot enter PrivExec on $switch";
	print "Entered PrivExec mode on $switch (thread $tid)\n";

	#
	# Send commands
	#
	foreach my $cmd (@{$Cmds{$switch}}) {
		$output .= $cli->cmd($cmd) or die "ERROR => $switch failed command: $cmd";
	}
	print "Sent commands to $switch (thread $tid)\n";

	#
	# Disconnect
	#
	$cli->disconnect;

	#
	# Return output if any
	#
	$output = "\nOutput from $switch:\n---------------------\n" . $output if length $output;
	return $output;
}


MAIN:{
	#
	# Start threads
	#
	print "\nStarting threads to connect to hosts:\n";
	foreach my $switch (keys %Devices) {
		print " - $switch\n";
		threads->create({'scalar' => 1}, 'cliThread', $switch);
	}
	print "\n";

	# Wait for threads to complete
	sleep 0.1 while (scalar threads->list(threads::running));
	
	foreach my $thread (threads->list(threads::joinable)) {
		my $output = $thread->join();
		print $output if length $output;
	}
}
