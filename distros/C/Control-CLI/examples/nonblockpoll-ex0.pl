use Control::CLI qw(poll);		# Export class poll method

my @DeviceIPs = ('10.134.161.10', '10.134.161.11', '10.134.161.12', '10.134.161.13', '10.134.161.14');

sub hostError { # Prepend hostname before error its cli object generated
	my ($host, $errmsg) = @_;
	die "\n$host -> $errmsg"; 
}

sub bulkDo { # Repeat for all hosts
	my ($cliHashRef, $method, $argsRef) = @_;

	foreach my $host (keys %$cliHashRef) { # Call $method for every object
		my $codeRef = $cliHashRef->{$host}->can($method);
		$codeRef->($cliHashRef->{$host}, @$argsRef);
	}
	poll(	# Poll all objects for completion of $method
		Object_list	=>	$cliHashRef,
		Poll_code	=>	sub { local $| = 1; print '.' },
	);
	print " done!\n";
}

print "Using Control::CLI $Control::CLI::VERSION\n";


MAIN:{
	my %cli;
	my ($username, $password) = ('rwa', 'rwa');

	# Create and Connect all the object instances
	foreach my $host (@DeviceIPs) {
		$cli{$host} = new Control::CLI(
			Use		=> 'SSH',		# or TELNET (or lots of serial ports!)
			Blocking	=> 0,			# Use non-blocking mode
			Errmode		=> [\&hostError, $host],# Error handler will add host-ip to msg
		);
		$cli{$host}->connect(
			Host		=>	$host,
			Username	=>	$username,
			Password	=>	$password,
		);
	}
	print "Connecting to all hosts ";
	poll(	# Poll all objects for completion of connect
		Object_list	=>	\%cli,
		Poll_code	=>	sub { local $| = 1; print '.' },
	);
	print " done!\n";

	print "Performing login on all hosts ";
	bulkDo(\%cli, 'login', [Password => $password]); 	# Not strictly necessary with SSH

	print "Entering PrivExec on all hosts ";
	bulkDo(\%cli, 'cmd', ['enable']);

	print "Entering Config mode on all hosts ";
	bulkDo(\%cli, 'cmd', ['config terminal']);

	print "Pushing config command on all hosts ";
	bulkDo(\%cli, 'cmd', ['snmp-server contact Jack']);

	print "Disconnecting from all hosts ";
	bulkDo(\%cli, 'disconnect');
}