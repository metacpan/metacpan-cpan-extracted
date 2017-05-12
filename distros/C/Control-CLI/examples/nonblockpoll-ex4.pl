#!/usr/local/bin/perl

# Same as nonblockpoll-ex2 except that script will handle failed object devices instead of terminating

use strict;
use warnings;
use Control::CLI qw( :prompt poll );
my $connectionType = 'SSH';
my $connectionTimeout = 15;	# seconds
my $timeout = 10;		# seconds
my $username = defined $ARGV[0] ? shift : undef;
my $password = defined $ARGV[0] ? shift : undef;
my $debug = 0;

my %Devices = (
	'cosimo'	=> '135.64.95.133',
	'vulcano'	=> '10.134.163.130',
	'rospo'		=> '10.134.161.9',
	'bogus'		=> '8.8.8.8',
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
	'bogus'	=> [
				'uname -a',
				'netstat',
			],
);

print "Using Control::CLI $Control::CLI::VERSION\n";


MAIN:{
	my (%cli, %output, $count, $running, $completed, $failed, $lastCompleted, $lastFailed);

	#
	# Get credentials if not already set
	#
	$username = promptClear("Please enter username to use for hosts") unless defined $username;
	$password = promptHide("Please enter password to use for hosts") unless defined $password;

	#
	# Create CLI objects
	#
	print "\nCreated CLI object for:\n";
	foreach my $host (keys %Devices) {
		$cli{$host} = new Control::CLI(
			Use			=> $connectionType,
		  	Timeout 		=> $timeout,
			Connection_timeout	=> $connectionTimeout,
			Input_log		=> $debug ? $host.'.in' : undef,
			Output_log		=> $debug ? $host.'.out' : undef,
			Dump_log		=> $debug ? $host.'.dump' : undef,
			Blocking		=> 0,
			Prompt_credentials	=> 1,
	       		Debug			=> $debug,
	       		Errmode			=> 'return',	# Always return on error
	       		Errmsg_format		=> 'terse',
		);
		print " - $host\n";
	}

	#
	# Connect to all hosts
	#
	print "$connectionType connecting to hosts ";
	foreach my $host (keys %cli) {
		$cli{$host}->connect(
			Host			=>	$Devices{$host},
			Username		=>	$username,
			Password		=>	$password,
		);
	}
	# Poll all complete
	do {
		($running, $completed, $failed, $lastCompleted, $lastFailed) = poll(
			Object_list	=>	\%cli,
			Object_complete	=>	'next',
			Object_error	=>	'return',
			Poll_code	=>	sub { local $| = 1; print '.' },
			Errmode		=>	'return',	# Always return on error
		);
		print "\n - Have completed : ", join(',', @$lastCompleted) if @$lastCompleted;
		foreach my $key (@$lastFailed) {
			if ($key eq $lastFailed->[0]) {
				print "\n - Have failed    : ";
			}
			else {
				print "\n                    ";
			}
			print "$key	-> ", $cli{$key}->errmsg;
			delete $cli{$key};	# Don't bother communicating with it anymore below..
			delete $Cmds{$key};	# Don't bother sending commands to it below..
		}
		print "\n - Summary        : Still running = $running ; Completed = $completed ; Failed = $failed\n";
	} while $running;
	print "\n";

	#
	# Login to all hosts
	#
	print "Logging in to hosts ";
	foreach my $host (keys %cli) {
		$cli{$host}->login(
			Username		=>	$username,
			Password		=>	$password,
		);
	}
	# Poll all complete
	do {
		($running, $completed, $failed, $lastCompleted, $lastFailed) = poll(
			Object_list	=>	\%cli,
			Object_complete	=>	'next',
			Object_error	=>	'return',
			Poll_code	=>	sub { local $| = 1; print '.' },
			Errmode		=>	'return',	# Always return on error
		);
		print "\n - Have completed : ", join(',', @$lastCompleted) if @$lastCompleted;
		foreach my $key (@$lastFailed) {
			if ($key eq $lastFailed->[0]) {
				print "\n - Have failed    : ";
			}
			else {
				print "\n                    ";
			}
			print "$key	-> ", $cli{$key}->errmsg;
			delete $cli{$key};	# Don't bother communicating with it anymore below..
			delete $Cmds{$key};	# Don't bother sending commands to it below..
		}
		print "\n - Summary        : Still running = $running ; Completed = $completed ; Failed = $failed\n";
	} while $running;
	print "\n";

	#
	# Send commands
	#
	print "Sending commands ";
	while (scalar keys %Cmds) {
		foreach my $host (keys %Cmds) {
			if (defined $cli{$host} && (my $cmd = shift @{$Cmds{$host}})) {
				$cli{$host}->cmd($cmd);
				$count++;
			}
			else {
				delete $Cmds{$host};	# Nibble away at the Cmd hash
				next;
			}
		}
		last unless scalar keys %Cmds; # All commands sent, come out

		# Poll all complete
		do {
			($running, $completed, $failed, $lastCompleted, $lastFailed) = poll(
				Object_list	=>	\%cli,
				Object_complete	=>	'next',
				Object_error	=>	'return',
				Poll_code	=>	sub { local $| = 1; print '.' },
				Errmode		=>	'return',	# Always return on error
			);
			print "\n - Have completed : ", join(',', @$lastCompleted) if @$lastCompleted;
			foreach my $key (@$lastFailed) {
				if ($key eq $lastFailed->[0]) {
					print "\n - Have failed    : ";
				}
				else {
					print "\n                    ";
				}
				print "$key	-> ", $cli{$key}->errmsg;
			}
			print "\n - Summary        : Still running = $running ; Completed = $completed ; Failed = $failed\n";
		} while $running;

		# Retrieve output
		foreach my $host (keys %Cmds) {
			$output{$host} .= ($cli{$host}->cmd_poll)[1];
		}
	}
	print "\n";

	#
	# Disconnect
	#
	foreach my $host (keys %cli) {
		$cli{$host}->disconnect;
	}

	#
	# Print output if any
	#
	foreach my $host (keys %cli) {
		print "\nOutput from $host:\n---------------------\n", $output{$host} if length $output{$host};
	}
}
