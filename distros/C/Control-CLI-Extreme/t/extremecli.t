#!/usr/bin/perl

#use lib '.';
use strict;
use warnings;
use Test::More;
use IO::Interactive qw(is_interactive);

############################################################
# Overrides can be specified for variables in this section #
############################################################
my $TestMultiple	= 1;		# Set to 0 if you only want to test against only one switch
my $ConnectionType	;
my $Blocking		;		# blocking mode
my $Binmode		= 0;		# binmode = 0 (default) does newline translation; binmode = 1 does not
my $Timeout		= 30;		# seconds
my $ConnectionTimeout	= 15;		# seconds
my $ErrorMode		= 'return';	# always return, so we check outcome in this test script
my $ErrMsgFormat	= 'verbose';
my $InputLog		;# = 'extremecli.t.in';
my $OutputLog		;# = 'extremecli.t.out';
my $DumpLog		;# = 'extremecli.t.dump';
my $DebugLog		;# = 'extremecli.t.dbg';
my $Host		;
my $TcpPort		;
my $Username		;# = 'rwa';
my $Password		;# = 'rwa';
my $PublicKeyPath	;# = 'C:\Users\<user>\.ssh\id_dsa.pub';	# '/export/home/<user>/.ssh/id_dsa.pub'
my $PrivateKeyPath	;# = 'C:\Users\<user>\.ssh\id_dsa';	# '/export/home/<user>/.ssh/id_dsa'
my $Passphrase		;
my $Baudrate		;# = 9600;	# Baudrate to use for initial connection
my $UseBaudrate		;# = 'max';	# Baudrate to switch to during tests
my $Databits		= 8;	
my $Parity		= 'none';	
my $Stopbits		= 1;
my $Handshake		= 'none';
my %Cmd = (		# CLI commands to test with (output should be long enough to be more paged)
			PassportERS_cli		=> 'show sys info',
			PassportERS_acli	=> 'show sys-info',
			BaystackERS		=> 'show sys-info',
			SecureRouter		=> 'show chassis',
			WLAN2300		=> 'show system',
			Accelar			=> 'show sys info',
			WLAN9100		=> 'show running-config',
			ExtremeXOS		=> 'show system | exclude UpTime', # Suppress uptime line as seconds count risks modifying the output length between compares
			ISW			=> 'show version',
			ISWmarvell		=> 'show version',
			Series200		=> 'show interfaces switchport general',
			Wing			=> 'show wireless radio detail',
#			SLX			=> 'show system',
			SLX			=> 'show interface stats brief', # Better test, on serial port, SLX really fills the output of this command with garbage..
			HiveOS			=> 'show running-config | exclude "console page"',
			Ipanema			=> 'ifconfig',
			EnterasysOS		=> 'show running-config all',
);
my %CmdRefreshed = (	# CLI commands whose output is refreshed; to test that we can exit the refresh
			PassportERS_cli		=> 'monitor ports stats interface utilization',
			PassportERS_acli	=> 'monitor ports statistics interface utilization',
			ExtremeXOS		=> 'show ports',
);
my $PromptCredentials	= 1;		# Test the module prompting for username/password 
my $PollInterval	= 0.1;		# If testing non-blocking mode, we print a dot to screen every $PollInterval secs
my $DataWithError	= 0;
my $SendWakeConsole	= undef;	# Set to 0 to always disable Sending Wake Console string; set to 1 to force sending it (needed with Telnet to XOS with banner before-login with acknowledge enabled)
my $WakeConsoleString	= undef;	# When undef, default '\n' is used; set to "\n\n" if connecting via serial port to XOS with banner before-login with acknowledge enabled
my $Debug		= 0; # 13 is good
############################################################


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

	$ok = $cli->login(Blocking => 0);
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing login() fails correctly $string $errmsg" );

	$ok = $cli->cmd(Blocking => 0, Poll_syntax => 1);
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing cmd() fails correctly $string $errmsg" );

	$ok = $cli->attribute(Blocking => 0, Poll_syntax => 1, Attribute => 'family_type');
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing attribute() fails correctly $string $errmsg" );

	$ok = $cli->change_baudrate(Blocking => 0, Poll_syntax => 1, BaudRate => 9600);
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing change_baudrate() fails correctly $string => " . $cli->errmsg );

	$ok = $cli->enable;
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing enable() fails correctly $string => " . $cli->errmsg );

	$ok = $cli->device_more_paging;
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing device_more_paging() fails correctly $string => " . $cli->errmsg );

	$ok = $cli->device_peer_cpu;
	$errmsg = defined $ok ? '' : " => " . $cli->errmsg;
	ok(!defined $ok, "Testing device_peer_cpu() fails correctly $string => " . $cli->errmsg );

	$cli->errmsg('');	# Clear the stored errmsg
	return;
}

sub attribute { # Read, test, print and return a attribute
	my ($cli, $attribute, $optional) = @_;
	my $displayValue;

	my ($ok, $attribValue) = $cli->attribute($attribute);
	if (defined $ok && $ok == 0) { # Non-blocking mode not ready
		until ($ok) { # This loop will be executed while $ok = 0
			print '.';					# Show activity
			Time::HiRes::sleep($PollInterval);		# Short timer
			($ok, $attribValue) = $cli->attribute_poll;	# Poll
			last unless defined $ok;			# Come out if error
		}
		print "\n";
	}
	if ($ok) {
		if (!defined $attribValue) {
			$displayValue = '( undefined )';
		}
		elsif (!ref $attribValue) {
			$displayValue = '(' . $attribValue . ')';
		}
		elsif (ref $attribValue eq 'ARRAY') {
			if (scalar @$attribValue == 0 && $optional) {
				$displayValue = '( empty list )';
			}
			elsif (!defined $attribValue->[0] || ref $attribValue->[0] eq 'ARRAY') { # Port array
				foreach my $slot (0..$#{$attribValue}) {
					$displayValue .= "\nslot $slot: " . join(',', @{$attribValue->[$slot]}) if defined $attribValue->[$slot];
				}
				$displayValue = "( array ):" . $displayValue;
			}
			else { # Regular list
				$displayValue = '(list:' . join(',', @$attribValue) . ')';
			}
		}
		elsif (ref $attribValue eq 'HASH') { # Port Hash (ISW)
			$displayValue = '';
			foreach my $slot (keys %$attribValue) {
				$displayValue .= "\nslot $slot: " . join(',', @{$attribValue->{$slot}}) if defined $attribValue->{$slot};
			}
			$displayValue = "( hash ):" . $displayValue;
		}
	}
	if ($optional) {
		ok( $ok && defined $displayValue, "Testing '$attribute' attribute" . (defined $displayValue ? ' '.$displayValue : ''));
	}
	else {
		ok( $ok && defined $attribValue && defined $displayValue, "Testing '$attribute' attribute" . (defined $displayValue ? ' '.$displayValue : ''));
	}
	diag $cli->errmsg unless $ok;
	return $attribValue;
}

sub checkCallback { # Connect() callback
	my ($blocking, $cli) = @_;
	my $ssh2 = $cli->parent;
	my @types = ('LIBSSH2_HOSTKEY_TYPE_UNKNOWN', 'LIBSSH2_HOSTKEY_TYPE_RSA', 'LIBSSH2_HOSTKEY_TYPE_DSS');
	my ($key, $type) = $ssh2->remote_hostkey;
	print "\n" unless $blocking;
	ok( defined $types[$type], "Testing callback can retrieve host key" );
	diag "SSH Server Key Type = $types[$type]" if defined $types[$type];
#	return (undef, "Error from connect Callback");	# To test error from callback
	return 1;
}

BEGIN {
	use_ok( 'Control::CLI::Extreme' ) || die "Bail out!";
}

my $modules =	((Control::CLI::Extreme::useTelnet) ? "Net::Telnet $Net::Telnet::VERSION, ":'').
		((Control::CLI::Extreme::useSsh)    ? "Net::SSH2 $Net::SSH2::VERSION / libssh2 " . &Net::SSH2::version . ", ":'').
		((Control::CLI::Extreme::useSerial) ? ($^O eq 'MSWin32' ?
						"Win32::SerialPort $Win32::SerialPort::VERSION, ":
						"Device::SerialPort $Device::SerialPort::VERSION, "):
					      '');
chop $modules; # trailing space
chop $modules; # trailing comma

diag "Testing Control::CLI::Extreme $Control::CLI::Extreme::VERSION";
diag "Using Control::CLI $Control::CLI::VERSION";
diag "Available connection types to test with: $modules";

if (Control::CLI::Extreme::useTelnet || Control::CLI::Extreme::useSsh) {
	if (Control::CLI::Extreme::useIPv6) {
		diag "Support for both IPv4 and IPv6";
	}
	else {
		diag "Only IPv4 support (install IO::Socket::IP for IPv6 support)";
	}
}

						##############################
unless (IO::Interactive::is_interactive) {	# Not an interactive session #
						##############################
	# Test Telnet constructor only
	my $cli = new Control::CLI::Extreme(Use => 'TELNET', Errmode => 'return');
	ok( defined $cli, "Testing constructor for Telnet" );

	# Test isa
	isa_ok($cli, 'Control::CLI::Extreme');

	diag "Once installed, to test connection to an Extreme device, please run test script extremecli.t manually and follow interactive prompts";
	done_testing();
	exit;
}

#####################################################
# For an interactive session we can test everything #
#####################################################

# Accept input parameters from command line if provided
# Syntax:
# 	extremecli.t telnet|ssh [username:password@]host [blocking]
# 	extremecli.t <COM-port-name> connectBaudrate[:useBaudrate] [username:password] [blocking]
if (@ARGV) {
	$TestMultiple = 0;
	$ConnectionType = shift(@ARGV);
	if ($ConnectionType =~ /^(?i:TELNET|SSH)$/) {
		$Host = shift(@ARGV) if @ARGV;
	}
	else {
		$Baudrate = shift(@ARGV) if @ARGV;
		$UseBaudrate = $Baudrate =~ s/:(\w+)$// ? $1 : $Baudrate;
		$Username = shift(@ARGV) if @ARGV;
		$Password = $2 if $Username =~ s/^([^:\s]+):(\S*)$/$1/;
	}
	if ($ARGV[0] =~ /\d{2,}/) { # TCP port number next
		$Host .= ' ' . shift(@ARGV);
	}
	$Blocking = @ARGV ? shift(@ARGV) : undef;
}

do {{ # Test loop, we keep testing until user satisfied

	my ($cli, $ok, $output, $output2, $result, $prompt, $lastPrompt, $diffPrompt, $more_prompt, $familyType, $acli, $masterCpu, $dualCpu, $cmd, $origBaudrate, $slx, $morePagingDisable);
	my ($connectionType, $username, $password, $host, $tcpPort, $baudrate, $useBaudrate, $blocking)
	 = ($ConnectionType, $Username, $Password, $Host, $TcpPort, $Baudrate, $UseBaudrate, $Blocking);

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
	$cli = new Control::CLI::Extreme(
			Use			=> $connectionType,
			Prompt_Credentials	=> $PromptCredentials,	# optional, default = 0 (no)
		  	Timeout 		=> $Timeout,		# optional; default timeout = 10 secs
			Blocking		=> $blocking,		# optional, blocking mode
		  	Connection_timeout	=> $ConnectionTimeout,	# optional; default is not set
			Errmode 		=> $ErrorMode,		# optional; default = 'croak'
			Binmode			=> $Binmode,		# optional; defalut = 0
			Errmsg_format		=> $ErrMsgFormat,
			Data_with_error		=> $DataWithError,	# optional; used by my acli.pl
			Console			=> $SendWakeConsole,	# optional; needed with Telnet if XOS has banner before-login with acknowledge
			Wake_console		=> $WakeConsoleString,	# optional;
			Input_log		=> $InputLog,
			Output_log		=> $OutputLog,
			Dump_log		=> $DumpLog,
			Debug			=> $Debug ? $Debug : undef, # If set to 0, test code as if not provided
			Debug_file		=> $DebugLog,
		);
	ok( defined $cli, "Testing constructor for '$connectionType'" );
	if (!defined $cli && $connectionType !~ /^(?i:TELNET|SSH)$/) {
		diag "Cannot open serial port provided";
		last;
	}

	# Test isa
	isa_ok($cli, 'Control::CLI::Extreme');

	# Test/Display connection type
	$connectionType = $cli->connection_type;
	ok( $connectionType, "Testing connection type = $connectionType" );

	# Test how methods behave if called when no connection exists
	checkMethodsWithoutConnection($cli, "before connecting");

	# Test connection to switch
	if ($connectionType =~ /^(?i:TELNET|SSH)$/) {
		my $complexInput;
		prompt(\$host, "Provide an Extreme device IP|hostname to test with (no config commands will be executed);\n [[username][:password]@]<host|IP> [port]; ENTER to end test]\n : ");
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
		prompt(\$baudrate, "Specify baudrate to use for initial connection [just ENTER for 9600 baud]: ", 9600);
		prompt(\$useBaudrate, "Baudrate to use for tests ('max' to use fastest possible) [just ENTER to stay @ $baudrate baud]: ", $baudrate);
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
			DataBits		=>	$Databits,		# optional, only serial
			Parity			=>	$Parity,		# optional, only serial
			StopBits		=>	$Stopbits,		# optional, only serial
			Handshake		=>	$Handshake,		# optional, only serial
			Callback		=>	[\&checkCallback, $blocking],	# optional, ssh callback to check remote key
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
	if ($blocking) { ok( $ok, "Testing connection & login" ) }
	else { ok( $ok, "Testing connection & login & polling methods") }
	unless ($ok) {
		diag $cli->errmsg;
		last;
	}

	# Verify last prompt is recorded
	$lastPrompt = $cli->last_prompt;
	ok( $lastPrompt, "Checking last_prompt is set" );
	diag "First prompt after login : $lastPrompt";

	# Test automatic locking on device prompt
	$prompt = $cli->prompt;
	ok( $prompt !~ /^[\n\x0d]/, "Checking autoset prompt" );
	diag "Automatically set prompt (inside =-> <-=):\n=->$prompt<-=";

	# Test automatic locking on device more-prompt
	$more_prompt = $cli->more_prompt;
	ok( defined $more_prompt, "Checking autoset --more-- prompt" );
	diag "Automatically set --more-- prompt (inside =-> <-=):\n=->$more_prompt<-=";

	# Test family_type attribute
	$familyType = attribute($cli, 'family_type');
	isnt( $familyType, 'generic', "Testing that an Extreme Networks product was detected" );
	if ($familyType eq 'generic') {
		$cli->disconnect;
		last;
	}

	if ($connectionType =~ /^(?i:SERIAL)$/ && $useBaudrate ne $baudrate) {

		# We try and switch to a different baudrate
		$origBaudrate = $baudrate;
		($ok, $baudrate) = $cli->change_baudrate($useBaudrate);
		if (defined $ok && $ok == 0) { # Non-blocking mode not ready
			ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
			until ($ok) { # This loop will be executed while $ok = 0
				print '.';					# Show activity
				Time::HiRes::sleep($PollInterval);		# Short timer
				($ok, $baudrate) = $cli->change_baudrate_poll;	# Poll
				last unless defined $ok;			# Come out if error
			}
			print "\n";
		}
		if ($blocking) { ok( $ok, "Testing change_baudrate() method" ) }
		else { ok( $ok, "Testing change_baudrate() & change_baudrate_poll() methods") }
		if ($ok) {
			diag "Switched connection to $baudrate baud";
		}
		else { # If this failed, we most likely lost the switch now
			diag $cli->errmsg;
			$cli->disconnect;
			last;
		}
	}

	# Test enabling more paging on device (except where not supported: Ipanema & PassportERS Standby CPUs)
	# - More paging is usually already enabled on device
	# - This test is to check that device_more_paging() behaves correctly before attribute 'model' is set 
	unless ($familyType eq 'Ipanema' || $familyType eq 'ISWmarvell' || $familyType eq 'PassportERS' && !$cli->attribute('is_master_cpu')) {
		$ok = $cli->device_more_paging(1);
		if (defined $ok && $ok == 0) { # Non-blocking mode not ready
			ok( !$blocking, "Checking 0 return value only in non-blocking mode" );

			$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
#			until ($ok) { # This loop will be executed while $ok = 0
#				print '.';				# Show activity
#				Time::HiRes::sleep($PollInterval);	# Short timer
#				$ok = $cli->device_more_paging_poll;	# Poll
#				last unless defined $ok;		# Come out if error
#			}

			print "\n";
		}
		if ($blocking) { ok( $ok, "Testing device_more_paging(1) method") }
		else { ok( $ok, "Testing device_more_paging(1) and device_more_paging_poll() methods") }
		diag $cli->errmsg unless $ok;
	}
	# Test global attributes
	attribute($cli, 'model',1); # might be undefined if executed on a Standby CPU
	attribute($cli, 'sysname',1); # might be undefined if executed on a Standby CPU
	attribute($cli, 'base_mac',1); # might be undefined (if executed on a Standby CPU or some products)
	attribute($cli, 'is_apls',1); # will be undefined on non-PassportERS products
	attribute($cli, 'is_voss',1); # will be undefined on non-PassportERS products
	attribute($cli, 'is_xos',1); # will be undefined on non-ExtremeXOS products
	attribute($cli, 'is_isw',1); # will be undefined on non-ISW products
	attribute($cli, 'is_wing',1); # will be undefined on non-Wing products
	attribute($cli, 'is_hiveos',1); # will be undefined on non-HiveOS products
	attribute($cli, 'is_sdwan',1); # will be undefined on non-Ipanema products
	attribute($cli, 'is_eos',1); # will be undefined on non-EnterasysOS products
	$slx = attribute($cli, 'is_slx',1); # will be undefined on non-SLX products
	if ($slx) {
		attribute($cli, 'is_slx_r',1); # will be undefined on non-SLX products
		attribute($cli, 'is_slx_s',1); # will be undefined on non-SLX products
		attribute($cli, 'is_slx_x',1); # will be undefined on non-SLX products
	}
	attribute($cli, 'apls_box_type',1); # might be undefined if is_apls is false
	attribute($cli, 'brand_name',1); # might be undefined if is_voss is false
	$acli = attribute($cli, 'is_acli');
	attribute($cli, 'sw_version');
	attribute($cli, 'fw_version',1); # might be undefined (VSP9000)
	attribute($cli, 'slots',1); # might be undefined on standalone BaystackERS / WLAN2300
	attribute($cli, 'ports',1); # might be undefined if executed on a Standby CPU
	attribute($cli, 'baudrate',1); # might be undefined if not configurable on device
	attribute($cli, 'max_baud',1); # might be undefined if not configurable on device or if on Standby CP of VSP9000

	# Test family_type specific attributes
	if ($familyType eq 'PassportERS') {
		$masterCpu = attribute($cli, 'is_master_cpu');
		$dualCpu = attribute($cli, 'is_dual_cpu');
		attribute($cli, 'cpu_slot');
		attribute($cli, 'is_ha',1); # might be undefined
		attribute($cli, 'stp_mode');
		attribute($cli, 'oob_ip',1); # might be undefined
		attribute($cli, 'oob_virt_ip',1); # might be undefined
		attribute($cli, 'oob_standby_ip',1); # might be undefined
		attribute($cli, 'is_oob_connected',1); # might be undefined, on Standby CPU
	}
	elsif ($familyType eq 'BaystackERS') {
		if ('Stack' eq attribute($cli, 'switch_mode')) {
			attribute($cli, 'base_unit');
			attribute($cli, 'unit_number');
			attribute($cli, 'stack_size');
		}
		attribute($cli, 'stp_mode');
		attribute($cli, 'mgmt_vlan');
		attribute($cli, 'mgmt_ip',1); # might be undefined
		attribute($cli, 'oob_ip',1); # might be undefined
		attribute($cli, 'is_oob_connected');
	}
	elsif ($familyType eq 'ExtremeXOS') {
		if ('Stack' eq attribute($cli, 'switch_mode')) {
			attribute($cli, 'master_unit');
			attribute($cli, 'unit_number');
			attribute($cli, 'stack_size');
		}
		attribute($cli, 'stp_mode');
		attribute($cli, 'oob_ip',1); # might be undefined
		attribute($cli, 'is_oob_connected');
	}
	elsif ($familyType eq 'ISW' || $familyType eq 'ISWmarvell') {
		attribute($cli, 'is_isw_marvell');
	}
	elsif ($familyType eq 'Series200') {
		if ('Stack' eq attribute($cli, 'switch_mode')) {
			attribute($cli, 'manager_unit');
			attribute($cli, 'unit_number');
			attribute($cli, 'stack_size');
		}
		attribute($cli, 'stp_mode');
		attribute($cli, 'oob_ip',1); # might be undefined
		attribute($cli, 'is_oob_connected');
	}
	elsif ($familyType eq 'SLX') {
		attribute($cli, 'switch_type');
		attribute($cli, 'is_active_mm');
		attribute($cli, 'is_dual_mm');
		attribute($cli, 'mm_number');
		attribute($cli, 'is_ha',1); # might be undefined
		attribute($cli, 'stp_mode',1); # might be undefined
		attribute($cli, 'oob_ip',1); # might be undefined
		attribute($cli, 'oob_virt_ip',1); # might be undefined
		attribute($cli, 'oob_standby_ip',1); # might be undefined
		attribute($cli, 'is_oob_connected',1); # might be undefined
	}
	elsif ($familyType eq 'Accelar') {
		attribute($cli, 'is_master_cpu');
		attribute($cli, 'is_dual_cpu');
	}

	# Test 'all' attribute
	attribute($cli, 'all');

	# Test entering privExec mode (not applicable on some product / CLI modes)
	$ok = $cli->enable;
	if (defined $ok && $ok == 0) { # Non-blocking mode not ready
		ok( !$blocking, "Checking 0 return value only in non-blocking mode" );

		$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
#		until ($ok) { # This loop will be executed while $ok = 0
#			print '.';				# Show activity
#			Time::HiRes::sleep($PollInterval);	# Short timer
#			$ok = $cli->enable_poll;		# Poll
#			last unless defined $ok;		# Come out if error
#		}

		print "\n";
	}
	if ($blocking) { ok( $ok, "Testing enable() method" ) }
	else { ok( $ok, "Testing enable() & enable_poll() methods") }
	unless ($ok) {
		diag $cli->errmsg;
		$cli->disconnect;
		last;
	}

	# Verify last prompt is recorded
	$lastPrompt = $cli->last_prompt;
	ok( $lastPrompt, "Checking last_prompt is set" );
	diag "New prompt after enable (PrivExec) : $lastPrompt";

	unless ($familyType eq 'WLAN2300' || $familyType eq 'ExtremeXOS' ||
		$familyType eq 'HiveOS'   || $familyType eq 'Ipanema') { # Skip this test for family types which have no config context

		# Test entering config mode (not applicable on some product / CLI modes)
		if    ( ($familyType eq 'PassportERS' && !$acli) || $familyType eq 'Accelar' || $familyType eq 'WLAN9100' ||
			 $familyType eq 'Series200' || $familyType eq 'SLX') {
			($ok, $result) = $cli->cmd(
					Command			=>	'config',
					Return_result		=>	1,
				);
		}
		elsif ( ($familyType eq 'PassportERS' && $acli) || $familyType eq 'BaystackERS') {
			($ok, $result) = $cli->cmd_prompted(
					Command			=>	'config',
					Feed			=>	'terminal',
					Return_result		=>	1,
				);
		}
		elsif ($familyType eq 'SecureRouter' || $familyType eq 'ISW' || $familyType eq 'Wing') {
			($ok, $result) = $cli->cmd(
					Command			=>	'config term',
					Return_result		=>	1,
				);
		}
		elsif ($familyType eq 'ISWmarvell' || $familyType eq 'EnterasysOS') {
			($ok, $result) = $cli->cmd(
					Command			=>	'configure',
					Return_result		=>	1,
				);
		}
		else {
			ok( 0, "Unexpected family type for testing config mode" );
			$cli->disconnect;
			last;
		}

		if (defined $ok && $ok == 0) { # Non-blocking mode not ready
			ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
			until ($ok) { # This loop will be executed while $ok = 0
				print '.';				# Show activity
				Time::HiRes::sleep($PollInterval);	# Short timer
				($ok, $result) = $cli->cmd_poll;	# Poll
				last unless defined $ok;		# Come out if error
			}
			print "\n";
		}
		ok( defined $result, "Checking that cmd() returns a defined value for result" );
		ok( $result, "Testing entering config context" );
		diag $cli->errmsg unless $ok;
		if ($result) { # If we made it into config mode

			# Verify last prompt is recorded
			$diffPrompt = $cli->last_prompt;
			ok( $diffPrompt, "Checking last_prompt is set" );
			diag "New prompt after entering config mode : $diffPrompt";

			# Test obtaining the config context
			$result = $cli->config_context;
			ok( $result, "Testing config_context method" );
			diag "Correctly detected config context:$result" if $result;
	
			# Test coming out of config mode
			if    ( ($familyType eq 'PassportERS' && !$acli) || $familyType eq 'Accelar') {
				($ok, $result) = $cli->cmd(
						Command			=>	'box',
						Return_result		=>	1,
					);
			}
			elsif ( $familyType eq 'ISWmarvell' || $familyType eq 'EnterasysOS' ) {
				($ok, $result) = $cli->cmd(
						Command			=>	'exit',
						Return_result		=>	1,
					);
			}
			else {
				($ok, $result) = $cli->cmd(
						Command			=>	'end',
						Return_result		=>	1,
					);
			}
			if (defined $ok && $ok == 0) { # Non-blocking mode not ready
				ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
				until ($ok) { # This loop will be executed while $ok = 0
					print '.';				# Show activity
					Time::HiRes::sleep($PollInterval);	# Short timer
					($ok, $result) = $cli->cmd_poll;	# Poll
					last unless defined $ok;		# Come out if error
				}
				print "\n";
			}
			ok( defined $result, "Checking that cmd() returns a defined value for result" );
			ok( $result, "Testing leaving config context" );
			diag $cli->errmsg unless $ok;
		}
        }

	# Test sending a show command like 'show sys info', with more paging enabled
	if ($familyType eq 'PassportERS') {
		$cmd = $acli ? $Cmd{PassportERS_acli} : $Cmd{PassportERS_cli};
	}
	else {
		$cmd = $Cmd{$familyType};
	}
	unless (defined $cmd) {
		ok( 0, "Unexpected family type for testing show command with more paging enabled" );
		$cli->disconnect;
		last;
	}
	($ok, $output) = $cli->cmd(
			Command			=>	$cmd,
			Return_reference	=>	0,
			Return_result		=>	0,
		);
	if (defined $ok && $ok == 0) { # Non-blocking mode not ready
		ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
		until ($ok) { # This loop will be executed while $ok = 0
			print '.';				# Show activity
			Time::HiRes::sleep($PollInterval);	# Short timer
			($ok, $output2) = $cli->cmd_poll;	# Poll & get partial output
			$output .= $output2;			# Append it
			last unless defined $ok;		# Come out if error
		}
		print "\n";
	}
	ok( defined $output, "Checking that cmd() returns a defined value for output" );
	if ($blocking) { ok( $ok, "Testing cmd() method with more paging enabled") }
	else { ok( $ok, "Testing cmd() and cmd_poll() methods with more paging enabled") }
	diag "Obtained output of command '$cmd':\n$output" if length $output;
	diag $cli->errmsg unless $ok;
	open(OUTPUT1, '>', 'output1.txt') and print OUTPUT1 $output;
	close OUTPUT1;
	diag "Output saved as 'output1.txt'";

	# Test disabling more paging on device (except on PassportERS Standby CPUs)
	$morePagingDisable = 0;
	unless ($familyType eq 'Ipanema' || ($familyType eq 'PassportERS' && !$masterCpu)) {
		$ok = $cli->device_more_paging(0);
		if (defined $ok && $ok == 0) { # Non-blocking mode not ready
			ok( !$blocking, "Checking 0 return value only in non-blocking mode" );

			$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
#			until ($ok) { # This loop will be executed while $ok = 0
#				print '.';				# Show activity
#				Time::HiRes::sleep($PollInterval);	# Short timer
#				$ok = $cli->device_more_paging_poll;	# Poll
#				last unless defined $ok;		# Come out if error
#			}

			print "\n";
		}
		if ($blocking) { ok( $ok, "Testing device_more_paging(0) method") }
		else { ok( $ok, "Testing device_more_paging(0) and device_more_paging_poll() methods") }
		diag $cli->errmsg unless $ok;
		$morePagingDisable = 1 if $ok;
	}

	if ($morePagingDisable) { # If we disabled more paging above...

		# Test sending same show command as above ('show sys info'), with more paging disabled
		($ok, $output2) = $cli->cmd(
				Poll_syntax             =>	1,
				Command			=>	$cmd,
				Return_reference	=>	0,
				Return_result		=>	0,
			);
		if (defined $ok && $ok == 0) { # Non-blocking mode not ready
			ok( !$blocking, "Checking 0 return value only in non-blocking mode" );

			$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
#			until ($ok) { # This loop will be executed while $ok = 0
#				print '.';				# Show activity
#				Time::HiRes::sleep($PollInterval);	# Short timer
#				$ok = $cli->cmd_poll;			# Poll
#				last unless defined $ok;		# Come out if error
#			}

			print "\n";
			$output2 = ($cli->cmd_poll)[1]; # Recover output
		}
		ok( defined $output2, "Checking that cmd() returns a defined value for output" );
		if ($blocking) { ok( $ok, "Testing cmd() method with more paging disabled") }
		else { ok( $ok, "Testing cmd() and cmd_poll() methods with more paging disabled") }
		diag $cli->errmsg unless $ok;

		if (length $output2 && length $output) { # Compare both outputs if we have them
			ok( length($output) == length($output2), "Testing that 1st & 2nd output of same command is of same length");
			unless ( length $output == length $output2 ) {
				open(OUTPUT2, '>', 'output2.txt') and print OUTPUT2 $output2;
				close OUTPUT2;
				diag "Output saved as 'output2.txt'";
			}
		}
	}

	# Test sending a show command with refreshed output; must be able to come out of it
	if ($familyType eq 'PassportERS') {
		$cmd = $acli ? $CmdRefreshed{PassportERS_acli} : $CmdRefreshed{PassportERS_cli};
	}
	else {
		$cmd = $CmdRefreshed{$familyType};
	}
	if (defined $cmd) {
		$ok = $cli->cmd(
				Poll_syntax             =>	1,
				Command			=>	$cmd,
				Return_reference	=>	0,
				Return_result		=>	0,
			);
		if (defined $ok && $ok == 0) { # Non-blocking mode not ready
			ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
			$ok = $cli->poll( Poll_timer => $PollInterval*1000, Poll_code => sub { print '.' } ); # Replaces commented code below
			print "\n";
			$output = ($cli->cmd_poll)[1]; # Recover output
		}
		ok( defined $output, "Checking that cmd() returns a defined value for output" );
		if ($blocking) { ok( $ok, "Testing cmd() method with refreshed output") }
		else { ok( $ok, "Testing cmd() and cmd_poll() methods with refreshed output") }
		diag "Obtained output of command '$cmd':\n$output" if length $output;
		diag $cli->errmsg unless $ok;
	}

	# Send an invalid command; test that device syntax error is captured by cmd() method
	($ok, $result) = $cli->cmd(
			Command			=>	'non_existent_command_to_cause_error_on_host',
			Return_result		=>	1,
		);
	if (defined $ok && $ok == 0) { # Non-blocking mode not ready
		ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
		until ($ok) { # This loop will be executed while $ok = 0
			print '.';				# Show activity
			Time::HiRes::sleep($PollInterval);	# Short timer
			($ok, $result) = $cli->cmd_poll;	# Poll
			last unless defined $ok;		# Come out if error
		}
		print "\n";
	}
	ok( defined $result, "Checking that cmd() returns a defined value for result" );
	ok( !$result, "Testing cmd() method return_result" );
	diag $cli->errmsg unless $ok;
	$output = $cli->last_cmd_errmsg;
	ok( $output, "Testing last_cmd_errmsg() method" );
	diag "Correctly detected device error message:\n$output" if length $output;

	if ($dualCpu) { # Test ability to connect to other CPU
		$ok = $cli->device_peer_cpu(
			Username		=>	$username,	# might be needed if connecting via serial port, and no login was done to start with
			Password		=>	$password,	# might be needed if connecting via serial port, and no login was done to start with
		);
		if (defined $ok && $ok == 0) { # Non-blocking mode not ready
			ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
			until ($ok) { # This loop will be executed while $ok = 0
				print '.';				# Show activity
				Time::HiRes::sleep($PollInterval);	# Short timer
				($ok, $output2) = $cli->device_peer_cpu_poll;	# Poll
				last unless defined $ok;		# Come out if error
			}
			print "\n";
		}
		if ($blocking) { ok( $ok, "Testing device_peer_cpu() method") }
		else { ok( $ok, "Testing device_peer_cpu() and device_peer_cpu_poll() methods") }
		diag $cli->errmsg unless $ok;

		if ($ok) { # Come back to 1st CPU
			$diffPrompt = $cli->last_prompt;
			diag "Peer CPU prompt : $diffPrompt";
			ok( $lastPrompt ne $diffPrompt, "Testing that we have a different prompt on peer CPU");

			# Now logout
			($ok, $result) = $cli->cmd(Command => 'logout', Reset_prompt => 1, Return_result => 1);
			if (defined $ok && $ok == 0) { # Non-blocking mode not ready
				ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
				until ($ok) { # This loop will be executed while $ok = 0
					print '.';				# Show activity
					Time::HiRes::sleep($PollInterval);	# Short timer
					($ok, $result) = $cli->cmd_poll;	# Poll
					last unless defined $ok;		# Come out if error
				}
				print "\n";
			}
			ok( $result, "Testing logout from peer CPU");
			diag $cli->errmsg unless $ok;
			if ($result) {
				$diffPrompt = $cli->last_prompt;
				diag "Back to 1st CPU prompt : $diffPrompt";
				ok( $lastPrompt eq $diffPrompt, "Testing that we have again the original prompt");
			}
		}
		
	}

	if ($connectionType =~ /^(?i:SERIAL)$/ && defined $origBaudrate) {

		# We retore the baudrate we used initially
		($ok, $baudrate) = $cli->change_baudrate($origBaudrate);
		if (defined $ok && $ok == 0) { # Non-blocking mode not ready
			ok( !$blocking, "Checking 0 return value only in non-blocking mode" );
			until ($ok) { # This loop will be executed while $ok = 0
				print '.';					# Show activity
				Time::HiRes::sleep($PollInterval);		# Short timer
				($ok, $baudrate) = $cli->change_baudrate_poll;	# Poll
				last unless defined $ok;			# Come out if error
			}
			print "\n";
		}
		if ($blocking) { ok( $ok, "Testing change_baudrate() method" ) }
		else { ok( $ok, "Testing change_baudrate() & change_baudrate_poll() methods") }
		ok( $baudrate == $origBaudrate, "Testing that the original $origBaudrate baud was restored" );
		diag "Restored original baudrate of $baudrate baud" if $baudrate == $origBaudrate;
		diag $cli->errmsg unless $ok;
	}

	# Disconnect from host, and resume loop for further tests
	$cli->disconnect;

	# Test how methods behave after connection closed
	checkMethodsWithoutConnection($cli, "after disconnecting");

}} while ($TestMultiple);

done_testing();
