#!/usr/bin/perl

use lib '.', './t';
use strict;
use warnings;
use Test::More;
use IO::Interactive qw(is_interactive);

############################################################
# Overrides can be specified for variables in this section #
############################################################
my $SeriaPort		= '';		# To manually set the a Serial port to test with; e.g 'COM1', '/dev/ttyS0'
my $TestMultiple	= 1;		# Set to 0 if you only want to test against one device
my $ConnectionType	;
my $Blocking		;		# blocking mode
my $Binmode		= 0;		# binmode = 0 (default) does newline translation; binmode = 1 does not
my $Timeout		= 10;		# seconds
my $ConnectionTimeout	= 15;		# seconds
my $ErrorMode		= 'return';	# always return, so we check outcome in this test script
my $ErrMsgFormat	= 'verbose';
my $InputLog		;# = 'control-cli.t.in';
my $OutputLog		;# = 'control-cli.t.out';
my $DumpLog		;# = 'control-cli.t.dump';
my $TelOptLog		;# = 'control-cli.t.telopt';
my $Host		;
my $TcpPort		;
my $Username		;
my $Password		;
my $PublicKeyPath	;# = 'C:\Users\<user>\.ssh\id_dsa.pub';	# '/export/home/<user>/.ssh/id_dsa.pub'
my $PrivateKeyPath	;# = 'C:\Users\<user>\.ssh\id_dsa';	# '/export/home/<user>/.ssh/id_dsa'
my $Passphrase		;
my $Baudrate		;# = 9600;
my $ForceBaud		= 0;
my $Databits		= 8;	
my $Parity		= 'none';	
my $Stopbits		= 1;
my $Handshake		= 'none';
my $Cmd			;
my $PromptCredentials	= 1;		# Test the module prompting for username/password 
my $PollInterval	= 0.1;		# If testing non-blocking mode, we print a dot to screen every $PollInterval secs
my $TermType		= 'vt100';	# Negotiate vt100; not because we need to, but because we want to test that this works
my $WinSize		= [132, 24],	# Negotiate window size; not because we need to, but because we want to test that this works
my $Debug		= 0; # 3 activates both levels
############################################################

# If no $SeriaPort set above, see if one manually specified when running Build.pl or Makefile.pl
if ( !$SeriaPort && eval { require DefaultPort } && $DefaultPort::Serial_Test_Port) {
	$SeriaPort = $DefaultPort::Serial_Test_Port;
}

sub prompt { # For interactive testing to prompt user
	my $varRef = shift;
	my $message = shift;
	my $default = shift;
	return if defined $$varRef; # Come out if variable already set
	print "\n", $message;
	chomp($$varRef = <STDIN>);
	print "\n";
	unless (length $$varRef) {
		if (defined $default) {
			$$varRef = $default;
			return;
		}
		done_testing();
		exit;
	}
}

sub checkMethodsWithoutConnection {
	my ($cli, $string) = @_;
	my ($ok, $errmsg);

	$ok = $cli->read(Blocking => 1, Timeout => 1);
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing read(blocking) fails correctly $string $errmsg" );

	$ok = $cli->read(Blocking => 0);
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing read(non-blocking) fails correctly $string $errmsg" );

	$ok = $cli->waitfor(Blocking => 0, Poll_syntax => 1, Match => '.');
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing waitfor() fails correctly $string $errmsg" );

	$ok = $cli->print;
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing print() fails correctly $string $errmsg" );

	$ok = $cli->login(Blocking => 0);
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing login() fails correctly $string $errmsg" );

	$ok = $cli->cmd(Blocking => 0, Poll_syntax => 1);
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing cmd() fails correctly $string $errmsg" );

	$ok = $cli->change_baudrate;
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing change_baudrate() fails correctly $string => " . $cli->errmsg );

	$ok = $cli->break;
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing break() fails correctly $string => " . $cli->errmsg );

	$cli->errmsg('');	# Clear the stored errmsg
	return;
}

sub checkCallback { # Connect() callback
	my $cli = shift;
	my $ssh2 = $cli->parent;
	my @types = ('LIBSSH2_HOSTKEY_TYPE_UNKNOWN', 'LIBSSH2_HOSTKEY_TYPE_RSA', 'LIBSSH2_HOSTKEY_TYPE_DSS');
	my ($key, $type) = $ssh2->remote_hostkey;
	ok( defined $types[$type], "Testing callback can retrieve host key" );
	diag "SSH Server Key Type = $types[$type]" if defined $types[$type];
#	return (undef, "Error from connect Callback");	# To test error from callback
	return 1;
}

BEGIN {
	use_ok( 'Control::CLI' ) || die "Bail out!";
}

my $modules =	((Control::CLI::useTelnet) ? "Net::Telnet $Net::Telnet::VERSION, ":'').
		((Control::CLI::useSsh)    ? "Net::SSH2 $Net::SSH2::VERSION / libssh2 " . &Net::SSH2::version . ", ":'').
		((Control::CLI::useSerial) ? ($^O eq 'MSWin32' ?
						"Win32::SerialPort $Win32::SerialPort::VERSION, ":
						"Device::SerialPort $Device::SerialPort::VERSION, "):
					      '');
chop $modules; # trailing space
chop $modules; # trailing comma
diag "Testing Control::CLI $Control::CLI::VERSION";
diag "Available modules to test with: $modules";

if (Control::CLI::useTelnet || Control::CLI::useSsh) {
	if (Control::CLI::useIPv6) {
		diag "Using IO::Socket::IP ==> IPv4 and IPv6 support";
	}
	else {
		diag "Using IO::Socket::INET ==> IPv4 only (install IO::Socket::IP for IPv6 support)";
	}
}

						##############################
unless (IO::Interactive::is_interactive) {	# Not an interactive session #
						##############################
	my ($cli, $testcli, $serialPortUndetected);

	# Test only the constructors
	SKIP: {
		skip "Net::Telnet not installed, skipping Telnet constructor test", 1 unless Control::CLI::useTelnet;
		# Create the object instance for Telnet
		$testcli = new Control::CLI(Use => 'TELNET', Errmode => 'return');
		ok( defined $testcli, "Testing constructor for Telnet" );
		$cli = $testcli if defined $testcli;
	}
	
	SKIP: {
		skip "Net::SSH not installed, skipping SSH constructor test", 1 unless Control::CLI::useSsh;
		# Create the object instance for SSH
		$testcli = new Control::CLI(Use => 'SSH', Errmode => 'return');
		ok( defined $testcli, "Testing constructor for SSH" );
		$cli = $testcli if defined $testcli;
	}
	
	SKIP: {
		skip "Win32::SerialPort not installed, skipping Serial constructor test", 1 unless Control::CLI::useSerial;
		unless ($SeriaPort) {	# Try and detect serial port to use
			if ($^O eq 'MSWin32') { # On Windows easy, use the registry
				unless (eval {require Win32::TieRegistry}) {
					$serialPortUndetected = 1;
					skip "Cannot make out available serial ports for Serial constructor test", 1;
				}
				import Win32::TieRegistry;
				$Win32::TieRegistry::Registry->Delimiter("/");
				my $comports = $Win32::TieRegistry::Registry->{"HKEY_LOCAL_MACHINE/HARDWARE/DEVICEMAP/SERIALCOMM"};
				unless (defined $comports) {
					$serialPortUndetected = 1;
					skip "Cannot make out available serial ports for Serial constructor test", 1;
				}
				foreach( keys %$comports ) {
					$SeriaPort = $comports->{$_} if $comports->{$_} =~ /^COM\d$/;
					last;
				}
			}
			else { # On Unix, just try the usual /dev/ttyS? ones...
				my @devttys = glob '/dev/ttyS?';
				if (@devttys && eval {require POSIX}) {
					foreach my $port (@devttys) {
						if ($port =~ /^(\/dev\/ttyS\d)$/) { # Untaint what we have detected
							my $tryport = $1;
							my $fd = POSIX::open($tryport, &POSIX::O_RDWR | &POSIX::O_NOCTTY | &POSIX::O_NONBLOCK);
							my $to = POSIX::Termios->new();
							if ( $to && $fd && $to->getattr($fd) ) {
								$SeriaPort = $tryport;
								last;
							}
						}
					}
				}
				unless ($SeriaPort) {
					$serialPortUndetected = 1;
					skip "Cannot make out available serial ports for Serial constructor test", 1;
				}
			}
			diag "Serial Port detected for testing Serial constructor with: $SeriaPort";
		}
		# Create the object instance for Serial
		$testcli = new Control::CLI(Use => $SeriaPort, Errmode => 'return');
		ok( defined $testcli, "Testing constructor for Serial Port (using $SeriaPort)" );
		$cli = $testcli if defined $testcli;
	}
	if ($serialPortUndetected) {
		diag "Skipped serial port constructor test as no serial port detected";
		diag "- can manually set one with 'perl <Build.PL|Makefile.PL> TESTPORT=<DEVICE>'";
	}
	
	ok( defined $cli, "Testing constructor for either Telnet/SSH/Serial" );
	isa_ok($cli, 'Control::CLI');

	diag "Once installed, to test connection to a device, please run test script control-cli.t manually and follow interactive prompts";
	done_testing();
	exit;
}

############################################################
# For an interactive session we can test a real connection #
############################################################

# Accept input parameters from command line if provided
# Syntax:
# 	control-cli.t telnet|ssh [username:password@]host ["cmd"] [blocking]
# 	control-cli.t <COM-port-name> <baudrate> [username:password] ["cmd"] [blocking]
if (@ARGV) {
	$TestMultiple = 0;
	$ConnectionType = shift(@ARGV);
	if ($ConnectionType =~ /^(?i:TELNET|SSH)$/) {
		$Host = shift(@ARGV) if @ARGV;
	}
	else {
		$Baudrate = shift(@ARGV) if @ARGV;
		$Username = shift(@ARGV) if @ARGV;
		$Password = $2 if $Username =~ s/^([^:\s]+):(\S*)$/$1/;
	}
	$Cmd = shift(@ARGV) if @ARGV;
	$Blocking = @ARGV ? shift(@ARGV) : undef;
}

do {{ # Test loop, we keep testing until user satisfied

	my ($cli, $eof, $ok, $output, $match);
	my ($connectionType, $username, $password, $host, $tcpPort, $baudrate, $cmd, $blocking)
	 = ($ConnectionType, $Username, $Password, $Host, $TcpPort, $Baudrate, $Cmd, $Blocking);

	# Decide whether these tests will be done in blocking or non-blocking mode
	prompt(\$blocking, "Test blocking (1) or non-blocking (0) mode ? [just ENTER for blocking; anything else quit]: ", 1);
	if ($blocking !~ /^[01]$/) { # If not 0 or 1 quit
		done_testing();
		exit;
	}
	$blocking ? diag "Test in blocking mode" : diag "Testing in non-blocking mode";
	diag "Warning: non-blocking mode will not work on connect() unless you have IO::Socket:IP installed" if !Control::CLI::useIPv6 && !$blocking;

	# Test constructor
	prompt(\$connectionType, "Select connection type to test\n [enter string: telnet|ssh|<COM-port-name>; or just ENTER to end test]\n : ");
	$cli = new Control::CLI(
			Use			=> $connectionType,
		  	Timeout 		=> $Timeout,		# optional; default timeout = 10 secs
		  	Connection_timeout	=> $ConnectionTimeout,	# optional; default is not set
			Errmode 		=> $ErrorMode,		# optional; default = 'croak'
			Binmode			=> $Binmode,		# optional; defalut = 0
			Errmsg_format		=> $ErrMsgFormat,
			Input_log		=> $InputLog,
			Output_log		=> $OutputLog,
			Dump_log		=> $DumpLog,
			Terminal_type		=> $TermType,
			Window_size		=> $WinSize,
			Debug			=> $Debug ? $Debug : undef, # If set to 0, test code as if not provided
		);
	ok( defined $cli, "Testing constructor for '$connectionType'" );
	if (!defined $cli && $connectionType !~ /^(?i:TELNET|SSH)$/) {
		diag "Cannot open serial port provided";
		last;
	}
	# Test isa
	isa_ok($cli, 'Control::CLI');

	# Test/Display connection type
	$connectionType = $cli->connection_type;
	ok( $connectionType, "Testing connection type = $connectionType" );

	# Telnet options log is provided by Net::Telnet
	$cli->parent->option_log($TelOptLog) if $connectionType eq 'TELNET' && defined $TelOptLog;

	# Test eof is reported as true prior to connection
	$eof = $cli->eof;
	ok( $eof, "Testing eof is true before connecting" );

	# Test how methods behave if called when no connection exists
	checkMethodsWithoutConnection($cli, "before connecting");

	# Test connection
	if ($connectionType =~ /^(?i:TELNET|SSH)$/) {
		my $complexInput;
		prompt(\$host, "Provide an IP|hostname to test with (you will be prompted for commands to execute);\n [[username][:password]@]<host|IP> [port]; ENTER to end test]\n : ");
		if ($host =~ s/^(.+)@//) {
			$username = $1;
			$password = $2 if $username =~ s/^([^:\s]+):(\S*)$/$1/;
			undef $username unless length $username;
			print "Username = ", $username, "\n" if defined $username;
			print "Password = ", $password, "\n" if defined $password;
			$complexInput = 1;
		}
		if ($host =~ /^(\S+)\s+(\d+)$/) {
			($host, $tcpPort) = ($1, $2);
			$complexInput = 1;
		}
		if ($complexInput) {
			print "Host = ", $host, "\n" if defined $host;
			print "Port = ", $tcpPort, "\n" if defined $tcpPort;
			print "\n";
		}
	}
	else {
		prompt(\$baudrate, "Specify baudrate to use [just ENTER for 9600 baud]: ", 9600);
	}
	$ok = $cli->connect(
			Host			=>	$host,			# mandatory, telnet & ssh
			Port			=>	$tcpPort,		# optional, only telnet & ssh
			Username		=>	$username,		# optional (with PromptCredentials=1 will be prompted for, if required)
			Password		=>	$password,		# optional (with PromptCredentials=1 will be prompted for, if required)
			PublicKey		=>	$PublicKeyPath,		# optional, only ssh
			PrivateKey		=>	$PrivateKeyPath,	# optional, only ssh
			Passphrase		=>	$Passphrase,		# optional, only ssh  (with PromptCredentials=1 will be prompted for, if required)
			BaudRate		=>	$baudrate,		# optional, only serial
			ForceBaud		=>	$ForceBaud,		# optional, only serial on Win32 (workaround to Win32::SerialPort bug id 120068)
			DataBits		=>	$Databits,		# optional, only serial
			Parity			=>	$Parity,		# optional, only serial
			StopBits		=>	$Stopbits,		# optional, only serial
			Handshake		=>	$Handshake,		# optional, only serial
			Prompt_Credentials	=>	$PromptCredentials,	# optional, default = 0 (no)
			Blocking		=>	$blocking,		# optional, blocking mode
			Callback		=>	\&checkCallback,	# optional, ssh callback to check remote key
		);
	if (defined $ok && $ok == 0) { # Non-blocking mode not ready
		ok( !$blocking, "Checking 0 return value only in non-blocking mode" );

		$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
#		until ($ok) { # This loop will be executed while $ok = 0
#			print '.';				# Show activity
#			Time::HiRes::sleep($PollInterval);	# Short timer
#			$ok = $cli->connect_poll;		# Poll
#			last unless defined $ok;		# Come out if error
#		}

		print "\n";
	}
	if ($blocking) { ok( $ok, "Testing connect() method" ) }
	else { ok( $ok, "Testing connect() and connect_poll() methods") }
	unless ($ok) {
		diag $cli->errmsg;
		last;
	}

	# Test eof is reported as false after connection
	$eof = $cli->eof;
	ok( !$eof, "Testing eof is false after connecting" );

	# Test login (we do this also for SSH, needed if device accepts SSH connection without authentication; no harm otherwise)
	if ($connectionType eq 'SERIAL') {
		$ok = $cli->print;
		ok( $ok, "Testing print() method to prime SERIAL login");
		unless ($ok) {
			diag $cli->errmsg;
			$cli->disconnect;
			last;
		}
	}
	($ok, $output) = $cli->login(
			Username		=>	$username,		# optional (with PromptCredentials=1 will be prompted for, if required)
			Password		=>	$password,		# optional (with PromptCredentials=1 will be prompted for, if required)
			Prompt_Credentials	=>	$PromptCredentials,	# optional, default = 0 (no)
			Blocking		=>	$blocking,		# optional, blocking mode
		);
	if (defined $ok && $ok == 0) { # Non-blocking mode not ready
		ok( !$blocking, "Checking 0 return value only in non-blocking mode" );

		$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
#		until ($ok) { # This loop will be executed while $ok = 0
#			print '.';				# Show activity
#			Time::HiRes::sleep($PollInterval);	# Short timer
#			$ok = $cli->login_poll;			# Poll
#			last unless defined $ok;		# Come out if error
#		}

		print "\n";
		$output = ($cli->login_poll)[1]; # Recover output
	}
	if (length $output) { diag "Obtained output of login sequence:\n$output" }
	if ($blocking) { ok( $ok, "Testing login() method") }
	else { ok( $ok, "Testing login() and login_poll() methods") }
	unless ($ok) {
		diag $cli->errmsg;
		$cli->disconnect;
		last;
	}

	# Verify last prompt is recorded
	$match = $cli->last_prompt;
	ok( $match, "Checking last_prompt is set" );
	diag "First prompt after login :\n$match";

	# Test sending a command
	prompt(\$cmd, "Specify a command to send, which generates some output: ");

	# We are going to test sending the command & retrieving the output in 2 ways

	# First we do it the hard way, to test print() and waitfor() and waitfor_poll() methods
	diag "\nTesting using print() and waitfor() methods\n";
	$ok = $cli->print($cmd);
	ok( $ok, "Testing print() method" );
	($ok, $output, $match) = $cli->waitfor(
			Poll_syntax		=>	1,
			Match			=>	$cli->prompt,
			Return_reference	=>	0,
			Blocking		=>	$blocking,		# optional, blocking mode
		);
	if (defined $ok && $ok == 0) { # Non-blocking mode not ready
		ok( !$blocking, "Checking 0 return value only in non-blocking mode" );

		$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
#		until ($ok) { # This loop will be executed while $ok = 0
#			print '.';				# Show activity
#			Time::HiRes::sleep($PollInterval);	# Short timer
#			$ok = $cli->waitfor_poll;		# Poll
#			last unless defined $ok;		# Come out if error
#		}

		print "\n";
		$output = ($cli->waitfor_poll)[1]; # Recover output before string that matched
		$match = ($cli->waitfor_poll)[2]; # Recover string that matched
	}
	if (length $match) { diag "Matched prompt :\n$match" }
	if (length $output) { diag "Output obtained before prompt match:\n$output" }
	if ($blocking) { ok( $ok, "Testing waitfor() method") }
	else { ok( $ok, "Testing waitfor() and waitfor_poll() methods") }
	unless ($ok) {
		diag $cli->errmsg;
		$cli->disconnect;
		last;
	}

	# The we do it the easy way testing cmd() & cmd_poll() methods
	diag "\nTesting using cmd() method\n";
	($ok, $output) = $cli->cmd(
			Command			=>	$cmd,
			Return_reference	=>	0,
			Blocking		=>	$blocking,		# optional, blocking mode
		);
	if (defined $ok && $ok == 0) { # Non-blocking mode not ready
		ok( !$blocking, "Checking 0 return value only in non-blocking mode" );

		$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
#		until ($ok) { # This loop will be executed while $ok = 0
#			print '.';				# Show activity
#			Time::HiRes::sleep($PollInterval);	# Short timer
#			$ok = $cli->cmd_poll;			# Poll
#			last unless defined $ok;		# Come out if error
#		}

		print "\n";
		$output = ($cli->cmd_poll)[1]; # Recover output
	}
	if (length $output) { diag "Obtained output of command '$cmd':\n$output" }
	if ($blocking) { ok( $ok, "Testing cmd() method") }
	else { ok( $ok, "Testing cmd() and cmd_poll() methods") }
	unless ($ok) {
		diag $cli->errmsg;
		$cli->disconnect;
		last;
	}

	# Verify last prompt is recorded
	$match = $cli->last_prompt;
	ok( $match, "Checking last_prompt is set" );
	diag "Last prompt :\n$match";

	# Disconnect from host, and resume loop for further tests
	$cli->disconnect;

	# Test eof is reported as true after disconnection
	$eof = $cli->eof;
	ok( $eof, "Testing eof is true after disconnecting" );

	# Test how methods behave after connection closed
	checkMethodsWithoutConnection($cli, "after disconnecting");

}} while ($TestMultiple);

done_testing();
