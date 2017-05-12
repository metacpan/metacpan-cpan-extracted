#!/usr/local/bin/perl

# Simple example of using threads

use strict;
use warnings;
use threads;
use Control::CLI qw( :prompt poll );
use Time::HiRes qw( sleep );
my $connectionType = 'TELNET';
my $connectionTimeout = 15;	# seconds
my $timeout = 10;		# seconds
my $username = defined $ARGV[0] ? shift : undef;
my $password = defined $ARGV[0] ? shift : undef;
my $debug = 0;

my %Devices = (
	'cosimo'	=> '135.64.95.133',
	'vulcano'	=> '10.134.163.130',
	'rospo'		=> '10.134.161.9',
);

my %Cmds = (
	'cosimo'	=> [
				'uname -a',
				'netstat',
			],
	'vulcano'	=> [
				'uname -a',
				'netstat',
			],
	'rospo'	=> [
				'uname -a',
				'netstat',
			],
);

print "Using Control::CLI $Control::CLI::VERSION\n";


sub cliThread { # Thread to each device
	my $host = shift;
	my $tid = threads->tid();
	my ($cli, $output);

	#
	# Create CLI object
	#
	$cli = new Control::CLI(
		Use			=> $connectionType,
	  	Timeout 		=> $timeout,
		Connection_timeout	=> $connectionTimeout,
		Input_log		=> $debug ? $host.'.in' : undef,
		Output_log		=> $debug ? $host.'.out' : undef,
		Dump_log		=> $debug ? $host.'.dump' : undef,
       		Debug			=> $debug,
	);

	#
	# Connect to host
	#
	$cli->connect(
		Host			=>	$Devices{$host},
		Username		=>	$username,
		Password		=>	$password,
	) or die "ERROR => Unable to connect to $host";
	print "$connectionType connected to $host (thread $tid)\n";

	#
	# Login to host
	#
	$cli->login(
		Username		=>	$username,
		Password		=>	$password,
	) or die "ERROR => Unable to login to $host";
	print "Logged into $host (thread $tid)\n";

	#
	# Send commands
	#
	foreach my $cmd (@{$Cmds{$host}}) {
		$output .= $cli->cmd($cmd) or die "ERROR => $host failed command: $cmd";
	}
	print "Sent commands to $host (thread $tid)\n";

	#
	# Disconnect
	#
	$cli->disconnect;

	#
	# Return output if any
	#
	$output = "\nOutput from $host:\n---------------------\n" . $output if length $output;
	return $output;
}


MAIN:{
	#
	# Get credentials if not already set
	#
	$username = promptClear("Please enter username to use for hosts") unless defined $username;
	$password = promptHide("Please enter password to use for hosts") unless defined $password;

	#
	# Start threads
	#
	print "\nStarting threads to connect to hosts:\n";
	foreach my $host (keys %Devices) {
		print " - $host\n";
		threads->create({'scalar' => 1}, 'cliThread', $host);
	}
	print "\n";

	# Wait for threads to complete
	sleep 0.1 while (scalar threads->list(threads::running));
	
	foreach my $thread (threads->list(threads::joinable)) {
		my $output = $thread->join();
		print $output if length $output;
	}
}
