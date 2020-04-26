package Control::CLI::Extreme;

use strict;
use warnings;
use Exporter qw( import );
use Carp;
use Control::CLI qw( :all );

my $Package = __PACKAGE__;
our $VERSION = '1.04';
our @ISA = qw(Control::CLI);
our %EXPORT_TAGS = (
		use	=> [qw(useTelnet useSsh useSerial useIPv6)],
		prompt	=> [qw(promptClear promptHide promptCredential)],
		args	=> [qw(parseMethodArgs suppressMethodArgs)],
		coderef	=> [qw(validCodeRef callCodeRef)],
		_rest	=> [qw(passphraseRequired parse_errmode stripLastLine poll)],
	);
push @{$EXPORT_TAGS{all}}, @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
Exporter::export_ok_tags('all');

########################################### Global Class Variables ###########################################

my $Space = " ";
my $CTRL_C = "\cC";
my $CTRL_U = "\cU";
my $CTRL_X = "\cX";
my $CTRL_Y = "\cY";
my $CTRL_Z = "\cZ";

my %LoginPatterns = ( # Patterns to check for during device login (Telnet/Serial) and initial connection to CLI
	bell		=>	"\x07",
	banner		=>	'Enter Ctrl-Y to begin',
	menu		=>	'Use arrow keys to highlight option, press <Return> or <Enter> to select option',
	submenu		=>	'Press Ctrl-R to return to previous menu.  Press Ctrl-C to return to Main Menu',
	username	=>	'Enter Username: ',
	password	=>	"Enter Password: \e[?", # Should match only on the initial password prompt and not subsequent ones where * are printed
	lastlogin	=>	'Failed retries since last login:',
	localfail	=>	'Incorrect',
	localfail_xos	=>	'Login incorrect',
	radiusfail	=>	'Access Denied from RADIUS',
	radiustimeout1	=>	'no response from RADIUS servers',
	radiustimeout2	=>	'No reply from RADIUS server',
	srbanner	=>	"\((?:Secure Router|VSP4K)",
	xlrbanner	=>	"\x0d************************************\n",
	ersbanner	=>	"\x0d* Ethernet Routing Switch",
	passportbanner	=>	"\x0d* Passport 8",
	pp1600banner	=>	"\x0d* Passport 16", # The 6 ensures this does not trigger on old Accelar 1x00
	vspbanner	=>	"All Rights Reserved.\n\x0dVirtual Services Platform",
	consoleLogMsg1	=>	"connected via console port", #On serial port: GlobalRouter SW INFO user rwa connected via console port
	consoleLogMsg2	=>	"Blocked unauthorized ACLI access",
	more1		=>	'----More (q=Quit, space/return=Continue)----',
	more2		=>	'--More--',
	wlan9100banner	=>	'Avaya Wi-Fi Access Point',
	xos		=>	'ExtremeXOS',
	isw		=>	'Product: ISW',
	slx		=>	'Welcome to the Extreme SLX-OS Software'
);
my %Prm = ( # Hash containing list of named parameters returned by attributes
	bstk	=>	'BaystackERS',
	pers	=>	'PassportERS',
	xlr	=>	'Accelar',
	sr	=>	'SecureRouter',
	trpz	=>	'WLAN2300',
	xirrus	=>	'WLAN9100',
	xos	=>	'ExtremeXOS',
	isw	=>	'ISW',
	s200	=>	'Series200',
	wing	=>	'Wing',
	slx	=>	'SLX',
	generic	=>	'generic',
);

my %Attribute = (
	Global		=> [
			'family_type',
			'is_nncli',
			'is_acli',
			'model',
			'sw_version',
			'fw_version',
			'slots',
			'ports',
			'sysname',
			'base_mac',
			'baudrate',
			'max_baud',
			],

	$Prm{pers}	=> [
			'is_voss',
			'is_apls',
			'apls_box_type',
			'brand_name',
			'is_master_cpu',
			'is_dual_cpu',
			'cpu_slot',
			'is_ha',
			'stp_mode',
			'oob_ip',
			'oob_virt_ip',
			'oob_standby_ip',
			'is_oob_connected',
			],

	$Prm{bstk}	=> [
			'unit_number',
			'base_unit',
			'switch_mode',
			'stack_size',
			'stp_mode',
			'mgmt_vlan',
			'mgmt_ip',
			'oob_ip',
			'is_oob_connected',
			],

	$Prm{xos}	=> [
			'is_xos',
			'unit_number',
			'master_unit',
			'switch_mode',
			'stack_size',
			'stp_mode',
			'oob_ip',
			'is_oob_connected',
			],

	$Prm{isw}	=> [
			'is_isw',
			],

	$Prm{wing}	=> [
			'is_wing',
			],

	$Prm{s200}	=> [
			'unit_number',
			'manager_unit',
			'switch_mode',
			'stack_size',
			'stp_mode',
			'oob_ip',
			'is_oob_connected',
			],

	$Prm{slx}	=> [
			'is_slx',
			'is_slx_r',
			'is_slx_s',
			'is_slx_x',
			'switch_type',
			'is_active_mm',
			'is_dual_mm',
			'mm_number',
			'is_ha',
			'stp_mode',
			'oob_ip',
			'oob_virt_ip',
			'oob_standby_ip',
			'is_oob_connected',
			],

	$Prm{xlr}	=> [
			'is_master_cpu',
			'is_dual_cpu',
			],
);

my @InitPromptOrder = ("$Prm{pers}_cli", "$Prm{pers}_nncli", $Prm{xos}, 'generic');
my %InitPrompt = ( # Initial prompt pattern expected at login
	# Capturing brackets: $1 = switchName, $2 = login_cpu_slot, $3 = configContext;
	$Prm{bstk}		=>	'\x0d?([^\n\x0d\x0a]{1,50}?)()(?:\((.+?)\))?[>#]$',
	"$Prm{pers}_cli"	=>	'\x0d?([^\n\x0d\x0a]+):([1356])((?:\/[\w\d\.-]+)*)[>#] $',
	"$Prm{pers}_nncli"	=>	'\x0d?([^\n\x0d\x0a]+):([12356])(?:\((.+?)\))?[>#]$',
	$Prm{xlr}		=>	'\x0d?([^\n\x0d\x0a]+?)()((?:\/[\w\d-]+)*)[>#] $',
	$Prm{sr}		=>	'\x0d? *\x0d([^\n\x0d\x0a]+?)()((?:\/[\w\d\s-]+(?: \(\d+\/\d+\))?)*)# $',
	$Prm{trpz}		=>	'([^\n\x0d\x0a]+)[>#] $',
	$Prm{xirrus}		=>	'(?:\x10\x00)?([^\n\x0d\x0a]+?)()(?:\((.+?)\))?# $',
	$Prm{xos}		=>	'(?:! )?(?:\* )?(?:\([^\n\x0d\x0a\)]+\) )?([^\n\x0d\x0a]+)\.\d+ [>#] $',
	$Prm{isw}		=>	'([^\n\x0d\x0a]{1,50}?)()(?:\((.+?)\))?[>#] $',
	$Prm{s200}		=>	'\(([^\n\x0d\x0a\)]+)\) ()(?:\((.+?)\))?[>#]$',
	$Prm{wing}		=>	'([^\n\x0d\x0a\)]+?)()(?:\((.+?)\))?\*?[>#]$',
	$Prm{slx}		=>	'([^\n\x0d\x0a\)]+)()(?:\((.+?)\))?# $',
	$Prm{generic}		=>	'[^\n\x0d\x0a]*[\?\$%#>]\s?$',
);

my %Prompt = ( # Prompt pattern templates; SWITCHNAME gets replaced with actual switch prompt during login
	$Prm{bstk}		=>	'SWITCHNAME(?:\((.+?)\))?[>#]$',
	"$Prm{pers}_cli"	=>	'SWITCHNAME:[1356]((?:\/[\w\d\.-]+)*)[>#] $',
	"$Prm{pers}_nncli"	=>	'SWITCHNAME:[12356](?:\((.+?)\))?[>#]$',
	$Prm{xlr}		=>	'SWITCHNAME((?:\/[\w\d-]+)*)[>#] $',
	$Prm{sr}		=>	'\x0d? *\x0dSWITCHNAME((?:\/[\w\d\s-]+(?: \(\d+\/\d+\))?)*)# $',
	$Prm{trpz}		=>	'SWITCHNAME[>#] $',
	$Prm{xirrus}		=>	'(?:\x10\x00)?SWITCHNAME(?:\((.+?)\))?# $',
	$Prm{xos}		=>	'(?:! )?(?:\* )?(?:\([^\n\x0d\x0a\)]+\) )?SWITCHNAME\.\d+ [>#] $',
	$Prm{isw}		=>	'SWITCHNAME(?:\((.+?)\))?[>#] $',
	$Prm{s200}		=>	'\(SWITCHNAME\) (?:\((.+?)\))?[>#]$',
	$Prm{wing}		=>	'SWITCHNAME(?:\((.+?)\))?\*?[>#]$',
	$Prm{slx}		=>	'SWITCHNAME(?:\((.+?)\))?# $',
	$Prm{generic}		=>	'[^\n\x0d\x0a]*[\?\$%#>]\s?$',
);

my @PromptConfigContext = ( # Used to extract config_context in _setLastPromptAndConfigContext(); these patterns need to condense the above 
	'\((.+?)\)\*?[>#]\s?$',	# NNCLI CLIs
	'((?:\/[\w\d\.-]+)*)[>#]\s?$',	# PassportERS in PPCLI mode & Accelar
);

my $LastPromptClense = '^(?:\x0d? *\x0d|\x10\x00)'; # When capturing lastprompt, SecureRouter and Xirrus sometimes precede the prompt with these characters

my %MorePrompt = ( # Regular expression character like ()[]. need to be backslashed
	$Prm{bstk}		=>	'----More \(q=Quit, space/return=Continue\)----',
	"$Prm{pers}_cli"	=>	'\n\x0d?--More-- \(q = quit\) ',
	"$Prm{pers}_nncli"	=>	'\n\x0d?--More-- \(q = quit\) |--More--',
	$Prm{xlr}		=>	'--More-- \(q = quit\) ',
	$Prm{sr}		=>	'Press any key to continue \(q : quit\) :\x00|Press any key to continue \(q : quit \| enter : next line\) :\x00',
	$Prm{trpz}		=>	'press any key to continue, q to quit\.',
	$Prm{xirrus}		=>	'--MORE--\x10?',
	$Prm{xos}		=>	'\e\[7mPress <SPACE> to continue or <Q> to quit:(?:\e\[m)?',
	$Prm{isw}		=>	'-- more --, next page: Space, continue: g, quit: \^C',
	$Prm{s200}		=>	'--More-- or \(q\)uit',
	$Prm{wing}		=>	'--More-- ',
	$Prm{slx}		=>	'(?:\e\[7m)?(?:--More--|\(END\))(?:\e\[27m)?',
	$Prm{generic}		=>	'----More \(q=Quit, space/return=Continue\)----'
					. '|--More-- \(q = quit\) '
					. '|Press any key to continue \(q : quit\) :\x00'
					. '|press any key to continue, q to quit\.'
					. '|--MORE--'
					. '|\e\[7mPress <SPACE> to continue or <Q> to quit:(?:\e\[m)?'
					. '|-- more --, next page: Space, continue: g, quit: \^C'
					. '|--More-- or \(q\)uit'
					. '|(?:\e\[7m)?(?:--More--|\(END\))(?:\e\[27m)?'
);
my %MorePromptDelay = ( # Only when a possible more prompt can be matched as subset of other more prompt patterns; for these an extra silent read is required
	"$Prm{pers}_nncli"	=>	'--More--',
	$Prm{generic}		=>	'--More--',
);

our %MoreSkipWithin = ( # Only on family type switches where possible, set to the character used to skip subsequent more prompts
	$Prm{isw}		=>	'g',
	$Prm{wing}		=>	'r',
);

my %ExitPrivExec = ( # Override (instead of usual 'disable') to use to exit PrivExec mode and return to UserExec
	$Prm{s200}		=>	$CTRL_Z,
);

my %RefreshCommands = ( # Some commands on some devices endlessly refresh the output requested; not desireable when scripting CLI; these paterns determine how to exit such commands
	"$Prm{pers}_cli"	=> {
					pattern	=> '^Monitor Interval: \d+sec \| Monitor Duration: \d+sec',
					send	=> "\n",
				},
	"$Prm{pers}_nncli"	=> {
					pattern	=> '^Monitor Interval: \d+sec \| Monitor Duration: \d+sec',
					send	=> "\n",
				},
	$Prm{xos}		=> {
					pattern	=> '^   U->page up  D->page down ESC->exit',
					send	=> "\e",
				},
);

our %ErrorPatterns = ( # Patterns which indicated the last command sent generated a syntax error on the host device (if regex does not match full error message, it must end with .+)
	$Prm{bstk}		=>	'^('
					. '\s+\^\n.+'
					. '|% Invalid input detected at \'\^\' marker\.'
					. '|% Cannot modify settings'
					. '|% Bad (?:port|unit) number\.'
					. '|% MLT \d+ does not exist or it is not enabled'
					. '|% No such VLAN'
					. '|% Bad VLAN list format\.'
					. '|% View name does not exist'					# snmp-server user admin read-view root write-view root notify-view root
					. '|% Partial configuration of \'.+?\' already exists\.'	# same as above
					. '|% View already exists, you must first delete it\.'		# snmp-server view root 1
					. '|% User \w+ does not exist'					# no snmp-server user admindes
					. '|% User \'.+?\' already exists'				# snmp-server user admin md5 passwdvbn read-view root write-view root notify-view root
					. '|% Password length must be in range:' 			# username add rwa role-name RW password // rwa // rwa (with password security)
					. '|% Bad format, use forms:.+'					# vlan members add 71 1/6-1/7 (1/6-7 is correct)
				. ')',
	$Prm{pers}		=>	'^('
					. '\x07?\s+\^\n.+'
					. '|% Invalid input detected at \'\^\' marker\.'
					. '|.+? not found in path .+'
					. '|(?:parameter|object) .+? is out of range'
					. '|\x07?Error ?: .+'
					. '|Unable to .+'
					. '|% Not allowed on secondary cpu\.'
					. '|% Incomplete command\.'
					. '|% Vrf "[^"]+" does not exist'
					. '| ERROR: copy failed \(code:0x[\da-fA-F]+\)'
					. '|Save config to file [^ ]+ failed\.'
					. '|% Vlan \d+ does not exist'
					. '|Command not allowed MSTP RSTP mode\.'			# On MSTP switch : vlan create 101 type port 1
					. '|% Permission denied\.'					# TACACS commands not allowed
					. '|% Only (?:gigabit|fast) ethernet ports allowed'		# config interface gig on fastEth port or vice-versa
					. '|There are \d+ releases already on system. Please remove 1 to proceed'
					. '|can\'t \w+ ".+?" 0x\d+'					# delete /flash/.ssh -y : can't remove "/flash/.ssh" 0x300042
					. '|".+?" is ambiguous in path /.+'				# AccDist3:5#% do
					. '|Password change aborted\.'					# Creating snmpv3 usm user with enh-secure-mode and password does not meet complexity requirements
					. '|Invalid password. Authentication failed'			# username teamnoc level ro // invalid-old-pwd // ...
					. '|Passwords do not match. Password change aborted'		# username teamnoc level ro // valid-old-pwd // newpwd // diffpwd
					. '|Error: Prefix List ".+?" not found'				# no ip prefix-list "<non-existent>"
					. '|Invalid ipv4 address\.'					# filter acl ace action 11 6 permit redirect-next-hop 2000:100::201 (on a non-ipv6 acl)
					. '|\x07?error in getting .+'					# mlt 1 member 1/1 (where mlt does not exist)
				. ')',
	$Prm{xlr}		=>	'^('
					. '.+? not found'
					. '|(?:parameter|object) .+? is out of range'
				. ')',
	$Prm{sr}		=>	'^('
					. '\s+\^\n.+'
					. '|Error : Command .+? does not exist'
					. '|Config is locked by some other user'
				. ')',
	$Prm{trpz}		=>	'^('
					. '\s+\^\n.+'
					. '|Unrecognized command:.+'
					. '|Unrecognized command in this mode:.+'
				. ')',
	$Prm{xirrus}		=>	'^('
					. '\s+\^\n.+'
				. ')',
	$Prm{xos}		=>	'^('
					. '\x07?\s+\^\n.+'
					. '|Error: .*(?:already|not).+'
				. ')',
	$Prm{isw}		=>	'^('
					. '\s+\^\n.+'
					. '|% Incomplete command.'
					. '|% Invalid .+'						# ISW3(config)#% interface vlan 101; ISW3(config-if-vlan)#% ip igmp snooping : % Invalid IGMP VLAN 101!
				. ')',
	$Prm{s200}		=>	'^('
					. '\s+\^\n.+'
					. '|Command not found / Incomplete command.'
					. '|Failed to create.+'						# (Extreme 220) (Vlan)#vlan 6666
				. ')',
	$Prm{wing}		=>	'^('
					. '\s+\^\n.+'
					. '|%% Error:.+'
				. ')',
	$Prm{slx}		=>	'^('
					. '-+\^\n.+'
					. '|(?:%% )?Error ?: .+'
					. '|Error\(s\):\n.+'
				. ')',
);
our $CmdConfirmPrompt = '[\(\[] *(?:[yY](?:es)? *(?:[\\\/]|or) *[nN]o?|[nN]o? *(?:[\\\/]|or) *[yY](?:es)?|y - .+?, n - .+?, <cr> - .+?) *[\)\]](?: *[?:] *| )$'; # Y/N prompt
our $CmdInitiatedPrompt = '[?:=]\h*(?:\(.+?\)\h*)?$'; # Prompt for additional user info
our $WakeConsole = "\n"; # Sequence to send when connecting to console to wake device

my $LoginReadAttempts = 10;		# Number of read attempts for readwait() method used in login()
my $CmdPromptReadAttempts = 8;		# Number of read attempts for readwait() method used in poll_cmd()
my $ReadwaitTimer = 100;		# Timer to use when calling readwait()
my $CmdTimeoutRatio = 0.1;		# In cmd() if read times out, a 2nd read is attempted with timeout * this ratio
my $NonRecognizedLogin = 0;		# In login() determines whether a non-recognized login output sequence makes method return using error mode action
my $GenericLogin = 0;			# In login(), if set, disables extended discovery

my %Default = ( # Hash of default object settings which can be modified on a per object basis
	morePaging		=>	0,	# For --more-- prompt, number of pages accepted before sending q to quit
						# 0 = accept all pages; 1 = send q after 1st page, i.e. only 1 page; etc
	progressDots		=>	0,	# After how many bytes received, an activity dot is printed; 0 = disabled
	return_result		=>	0,	# Whether cmd methods return true/false result or output of command
	cmd_confirm_prompt	=>	$CmdConfirmPrompt,
	cmd_initiated_prompt	=>	$CmdInitiatedPrompt,
	cmd_feed_timeout	=>	10,	# Command requests for data, we have none, after X times we give up 
	wake_console		=>	$WakeConsole,
	ors			=> 	"\r",	# Override of Control::CLI's Output Record Separator used by print() & cmd()
);

our @ConstructorArgs = ( @Control::CLI::ConstructorArgs, 'return_result', 'more_paging', 'debug_file',
			'cmd_confirm_prompt', 'cmd_initiated_prompt', 'cmd_feed_timeout', 'console', 'wake_console',
			);

# Debug levels can be set using the debug() method or via debug argument to new() constructor
# Debug levels defined:
# 	0	: No debugging
# 	bit 1	: Control::CLI - Debugging activated for polling methods + readwait() + Win32/Device::SerialPort constructor $quiet flag reset
# 	bit 2	: Control::CLI - Debugging is activated on underlying Net::SSH2 and Win32::SerialPort / Device::SerialPort
# 	bit 4	: Control::CLI::Extreme - Basic debugging
# 	bit 8	: Control::CLI::Extreme - Extended debugging of login() & cmd() methods


############################################# Constructors/Destructors #######################################

sub new {
	my $pkgsub = "${Package}::new";
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my (%args, %cliArgs);
	my $debugLevel = $Default{debug};
	if (@_ == 1) { # Method invoked with just the connection type argument
		$cliArgs{use} = shift;
	}
	else {
		%args = parseMethodArgs($pkgsub, \@_, \@ConstructorArgs);
		my @suppressArgs = ('prompt', 'return_result', 'more_paging', 'cmd_confirm_prompt',
				'cmd_initiated_prompt', 'cmd_feed_timeout', 'console', 'wake_console', 'debug_file');
		%cliArgs = suppressMethodArgs(\@_, \@suppressArgs);
	}
	my $self = $class->SUPER::new(%cliArgs) or return;
	$self->{$Package} = {
		# Lower Case ones can be set by user; Upper case ones are set internaly in the class
		morePaging		=>	$Default{morePaging},
		progressDots		=>	$Default{progressDots},
		prompt			=>	undef,
		prompt_qr		=>	undef,
		morePrompt		=>	undef,
		morePrompt_qr		=>	undef,
		morePromptDelay_qr	=>	undef,
		last_cmd_success	=>	undef,
		last_cmd_errmsg		=>	undef,
		return_result		=>	$Default{return_result},
		cmd_confirm_prompt	=>	$Default{cmd_confirm_prompt},
		cmd_confirm_prompt_qr	=>	qr/$Default{cmd_confirm_prompt}/,
		cmd_initiated_prompt	=>	$Default{cmd_initiated_prompt},
		cmd_initiated_prompt_qr	=>	qr/$Default{cmd_initiated_prompt}/,
		cmd_feed_timeout	=>	$Default{cmd_feed_timeout},
		console			=>	undef,
		wake_console		=>	$Default{wake_console},
		noRefreshCmdPattern	=>	undef,
		noRefreshCmdSend	=>	undef,
		PROMPTTYPE		=>	undef,
		ENABLEPWD		=>	undef,
		ORIGBAUDRATE		=>	undef,
		ATTRIB			=>	undef,
		ATTRIBFLAG		=>	undef,
		CONFIGCONTEXT		=>	'',
		DEBUGLOGFH		=>	undef,
	};
	unless (defined $args{output_record_separator}) {	# If not already set in constructor...
		$self->output_record_separator($Default{ors});	# ...we override Control::CLI's default with our own default
	}
	foreach my $arg (keys %args) { # Accepted arguments on constructor
		if    ($arg eq 'prompt')			{ $self->prompt($args{$arg}) }
		elsif ($arg eq 'return_result')			{ $self->return_result($args{$arg}) }
		elsif ($arg eq 'more_paging')			{ $self->more_paging($args{$arg}) }
		elsif ($arg eq 'cmd_confirm_prompt')		{ $self->cmd_confirm_prompt($args{$arg}) }
		elsif ($arg eq 'cmd_initiated_prompt')		{ $self->cmd_initiated_prompt($args{$arg}) }
		elsif ($arg eq 'cmd_feed_timeout')		{ $self->cmd_feed_timeout($args{$arg}) }
		elsif ($arg eq 'console')			{ $self->console($args{$arg}) }
		elsif ($arg eq 'wake_console')			{ $self->wake_console($args{$arg}) }
		elsif ($arg eq 'debug_file')			{ $self->debug_file($args{$arg}) }
	}
	return $self;
}


# sub DESTROY {} # We don't need to override Control::CLI's destroy method


############################################### Object methods ###############################################

sub connect { # All the steps necessary to connect to a CLI session on an Extreme Networking device
	my $pkgsub = "${Package}::connect";
	my $self = shift;
	my %args;
	if (@_ == 1) { # Method invoked in the shorthand form
		$args{host} = shift;
		if ($args{host} =~ /^(.+?)\s+(\d+)$/) {
			($args{host}, $args{port}) = ($1, $2);
		}
	}
	else {
		my @validArgs = ('host', 'port', 'username', 'password', 'publickey', 'privatekey', 'passphrase',
				 'prompt_credentials', 'baudrate', 'parity', 'databits', 'stopbits', 'handshake',
				 'errmode', 'connection_timeout', 'timeout', 'read_attempts', 'wake_console',
				 'return_reference', 'blocking', 'data_with_error', 'terminal_type', 'window_size',
				 'callback', 'forcebaud', 'atomic_connect', 'non_recognized_login', 'generic_login');
		%args = parseMethodArgs($pkgsub, \@_, \@validArgs);
	}

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pkgsub,
				__PACKAGE__->can('connect_poll'),
				defined $args{blocking} ? $args{blocking} : $self->{blocking},
				defined $args{connection_timeout} ? $args{connection_timeout} : $self->{connection_timeout},
				defined $args{errmode} ? parse_errmode($pkgsub, $args{errmode}) : undef,
				1,
				wantarray,
				defined $args{return_reference} ? $args{return_reference} : $self->{return_reference},
				undef,	# n/a
			);
	$self->{POLL}{$pkgsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		host			=>	$args{host},
		port			=>	$args{port},
		username		=>	$args{username},
		password		=>	$args{password},
		publickey		=>	$args{publickey},
		privatekey		=>	$args{privatekey},
		passphrase		=>	$args{passphrase},
		baudrate		=>	$args{baudrate},
		parity			=>	$args{parity},
		databits		=>	$args{databits},
		stopbits		=>	$args{stopbits},
		handshake		=>	$args{handshake},
		prompt_credentials	=>	defined $args{prompt_credentials} ? $args{prompt_credentials} : $self->{prompt_credentials},
		terminal_type		=>	$args{terminal_type},
		window_size		=>	$args{window_size},
		callback		=>	$args{callback},
		forcebaud		=>	$args{forcebaud},
		atomic_connect		=>	$args{atomic_connect},
		login_timeout		=>	defined $args{timeout} ? $args{timeout} : $self->{timeout},
		read_attempts		=>	defined $args{read_attempts} ? $args{read_attempts} : $LoginReadAttempts,
		data_with_error		=>	defined $args{data_with_error} ? $args{data_with_error} : $self->{data_with_error},
		wake_console		=>	defined $args{wake_console} ? $args{wake_console} : $self->{$Package}{wake_console},
		non_recognized_login	=>	defined $args{non_recognized_login} ? $args{non_recognized_login} : $NonRecognizedLogin,
		generic_login		=>	defined $args{generic_login} ? $args{generic_login} : $GenericLogin,
		# Declare method storage keys which will be used
		stage			=>	$self->{LOGINSTAGE} ? 1 : 0,
	};
	if (!$self->{LOGINSTAGE} && $self->{TYPE} ne 'SERIAL' && useIPv6 && defined $args{blocking} && !$args{blocking}) {
		carp "$pkgsub: IO::Socket::IP is required for non-blocking connect";
	}
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};
	return __PACKAGE__->can('poll_connect')->($self, $pkgsub); # Do not call a sub-classed version
}
		

sub connect_poll { # Poll status of connection (non-blocking mode)
	my $pkgsub = "${Package}::connect_poll";
	my $self = shift;
	carp "$pkgsub: No arguments expected" if @_; # No arguments expected

	unless (defined $self->{POLL} && $self->{POLL}{coderef} == __PACKAGE__->can('connect_poll')) {
		return $self->error("$pkgsub: Method connect() needs to be called first with blocking false");
	}
	$self->{POLL}{output_requested} = wantarray; # This might change at every call
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	# If already completed (1) or we got an error (undef) from previous call (errmsg is already set) then we go no further
	return $self->poll_return($self->{POLL}{complete}) unless defined $self->{POLL}{complete} && $self->{POLL}{complete} == 0;

	# We get here only if we are not complete: $self->{POLL}{complete} == 0
	return __PACKAGE__->can('poll_connect')->($self, $pkgsub); # Do not call a sub-classed version
}


sub disconnect { # Perform check on restoring buadrate on device before doing Control::CLI's disconnect
	my $self = shift;
	$self->_restoreDeviceBaudrate if $self->connection_type eq 'SERIAL';
	return $self->SUPER::disconnect(@_);
}


sub login { # Handles steps necessary to get to CLI session, including menu, banner and Telnet/Serial login
	my $pkgsub = "${Package}::login";
	my $self =shift;
	my @validArgs = ('username', 'password', 'prompt_credentials', 'timeout', 'errmode', 'return_reference',
			 'read_attempts', 'wake_console', 'blocking', 'data_with_error', 'non_recognized_login', 'generic_login');
	my %args = parseMethodArgs($pkgsub, \@_, \@validArgs);

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pkgsub,
				__PACKAGE__->can('login_poll'),
				defined $args{blocking} ? $args{blocking} : $self->{blocking},
				defined $args{timeout} ? $args{timeout} : $self->{timeout},
				defined $args{errmode} ? parse_errmode($pkgsub, $args{errmode}) : undef,
				1,
				wantarray,
				defined $args{return_reference} ? $args{return_reference} : $self->{return_reference},
				undef,	# n/a
			);
	$self->{POLL}{$pkgsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		username		=>	$args{username},
		password		=>	$args{password},
		prompt_credentials	=>	defined $args{prompt_credentials} ? $args{prompt_credentials} : $self->{prompt_credentials},
		read_attempts		=>	defined $args{read_attempts} ? $args{read_attempts} : $LoginReadAttempts,
		data_with_error		=>	defined $args{data_with_error} ? $args{data_with_error} : $self->{data_with_error},
		wake_console		=>	defined $args{wake_console} ? $args{wake_console} : $self->{$Package}{wake_console},
		non_recognized_login	=>	defined $args{non_recognized_login} ? $args{non_recognized_login} : $NonRecognizedLogin,
		generic_login		=>	defined $args{generic_login} ? $args{generic_login} : $GenericLogin,
		# Declare method storage keys which will be used
		stage			=>	0,
		login_attempted		=>	undef,
		password_sent		=>	undef,
		login_error		=>	'',
		family_type		=>	undef,
		cpu_slot		=>	undef,
		detectionFromPrompt	=>	undef,
	};
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};
	return __PACKAGE__->can('poll_login')->($self, $pkgsub); # Do not call a sub-classed version
}


sub login_poll { # Poll status of login (non-blocking mode)
	my $pkgsub = "${Package}::login_poll";
	my $self = shift;
	carp "$pkgsub: No arguments expected" if @_; # No arguments expected

	unless (defined $self->{POLL} && $self->{POLL}{coderef} == __PACKAGE__->can('login_poll')) {
		return $self->error("$pkgsub: Method login() needs to be called first with blocking false");
	}
	$self->{POLL}{output_requested} = wantarray; # This might change at every call
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	# If already completed (1) or we got an error (undef) from previous call (errmsg is already set) then we go no further
	return $self->poll_return($self->{POLL}{complete}) unless defined $self->{POLL}{complete} && $self->{POLL}{complete} == 0;

	# We get here only if we are not complete: $self->{POLL}{complete} == 0
	return __PACKAGE__->can('poll_login')->($self, $pkgsub); # Do not call a sub-classed version
}


sub cmd { # Sends a CLI command to host and returns result or output data
	my $pkgsub = "${Package}::cmd";
	my $self = shift;
	my %args;
	if (@_ == 1) { # Method invoked with just the command argument
		$args{command} = shift;
	}
	else {
		my @validArgs = ('command', 'prompt', 'reset_prompt', 'more_prompt', 'cmd_confirm_prompt', 'more_pages',
				 'timeout', 'errmode', 'return_reference', 'return_result', 'progress_dots', 'blocking', 'poll_syntax');
		%args = parseMethodArgs($pkgsub, \@_, \@validArgs);
	}
	$args{command} = '' unless defined $args{command};

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pkgsub,
				__PACKAGE__->can('cmd_poll'),
				defined $args{blocking} ? $args{blocking} : $self->{blocking},
				defined $args{timeout} ? $args{timeout} : $self->{timeout},
				defined $args{errmode} ? parse_errmode($pkgsub, $args{errmode}) : undef,
				(defined $args{return_result} ? $args{return_result} : $self->{$Package}{return_result}) ? 2 : 1,
				undef, # This is set below
				defined $args{return_reference} ? $args{return_reference} : $self->{return_reference},
				undef,	# n/a
			);
	$self->{POLL}{$pkgsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		command			=>	$args{command},
		prompt			=>	defined $args{prompt} ? $args{prompt} : $self->{$Package}{prompt_qr},
		more_prompt		=>	defined $args{more_prompt} ? $args{more_prompt} : $self->{$Package}{morePrompt_qr},
		more_prompt_delay	=>	defined $args{more_prompt} ? undef : $self->{$Package}{morePromptDelay_qr},
		more_pages		=>	defined $args{more_pages} ? $args{more_pages} : $self->{$Package}{morePaging},
		reset_prompt		=>	$args{reset_prompt} && defined $self->{$Package}{PROMPTTYPE},
		yn_prompt		=>	defined $args{cmd_confirm_prompt} ? $args{cmd_confirm_prompt} : $self->{$Package}{cmd_confirm_prompt_qr},
		cmd_prompt		=>	undef,
		feed_data		=>	undef,
		progress_dots		=>	defined $args{progress_dots} ? $args{progress_dots} : $self->{$Package}{progressDots},
		# Declare method storage keys which will be used
		stage			=>	0,
		lastLine		=>	'',
		outputNewline		=>	'',
		progress		=>	undef,
		alreadyCmdTimeout	=>	0,
		ynPromptCount		=>	undef,
		cmdPromptCount		=>	undef,
		cmdEchoRemoved		=>	0,
		lastPromptEchoedCmd	=>	undef,
		cache_timeout		=>	$self->{POLL}{timeout},
		noRefreshCmdDone	=>	undef,
	};
	$self->{POLL}{output_requested} = !$args{poll_syntax} || wantarray; # Always true in legacy syntax and in poll_syntax if wantarray
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	my ($ok, $output) = $self->poll_cmd($pkgsub);
	# We have a different syntax for scalar output in blocking and non-blocking modes
	if ($args{poll_syntax}) { # New syntax
		return wantarray ? ($ok, $output) : $ok;
	}
	else { # Old syntax
		return wantarray ? ($ok, $output) : $output;
	}
}


sub cmd_prompted { # Sends a CLI command to host, feed additional data and return any output
	my $pkgsub = "${Package}::cmd_prompted";
	my $pollsub = "${Package}::cmd";
	my $self = shift;
	my ($cmd, @feedData, $errmode, $reset_prompt, $pollSyntax);
	my $morePages = $self->{$Package}{morePaging};
	my $progressDots = $self->{$Package}{progressDots};
	my $timeout = $self->{timeout};
	my $blocking = $self->{blocking};
	my $returnRef = $self->{return_reference};
	my $returnRes = $self->{$Package}{return_result};
	my $prompt = $self->{$Package}{prompt_qr};
	my $morePrompt = $self->{$Package}{morePrompt_qr};
	my $morePromptDelay = $self->{$Package}{morePromptDelay_qr};
	my $cmdPrompt = $self->{$Package}{cmd_initiated_prompt_qr};
	if (lc($_[0]) ne 'command' && lc($_[0]) ne 'poll_syntax') { # No command or poll_syntax argument, assume list form
		$cmd = shift;
		@feedData = @_;
	}
	else { # Method invoked with multiple arguments form
		my @validArgs = ('command', 'feed', 'feed_list', 'prompt', 'reset_prompt', 'more_prompt', 'cmd_initiated_prompt', 'more_pages',
				 'timeout', 'errmode', 'return_reference', 'return_result', 'progress_dots', 'blocking', 'poll_syntax');
		my @args = parseMethodArgs($pkgsub, \@_, \@validArgs);
		for (my $i = 0; $i < $#args; $i += 2) {
			$cmd = $args[$i + 1] if $args[$i] eq 'command';
			push @feedData, $args[$i + 1] if $args[$i] eq 'feed';
			push @feedData, @{$args[$i + 1]} if $args[$i] eq 'feed_list' && ref($args[$i + 1]) eq "ARRAY";
			$prompt = $args[$i + 1] if $args[$i] eq 'prompt';
			$morePages = $args[$i + 1] if $args[$i] eq 'more_pages';
			$timeout = $args[$i + 1] if $args[$i] eq 'timeout';
			$blocking = $args[$i + 1] if $args[$i] eq 'blocking';
			$returnRef = $args[$i + 1] if $args[$i] eq 'return_reference';
			$returnRes = $args[$i + 1] if $args[$i] eq 'return_result';
			$reset_prompt = $args[$i + 1] if $args[$i] eq 'reset_prompt';
			($morePrompt, $morePromptDelay) = ($args[$i + 1], undef) if $args[$i] eq 'more_prompt';
			$progressDots = $args[$i + 1] if $args[$i] eq 'progress_dots';
			$cmdPrompt = $args[$i + 1] if $args[$i] eq 'cmd_initiated_prompt';
			$errmode = parse_errmode($pkgsub, $args[$i + 1]) if $args[$i] eq 'errmode';
			$pollSyntax = $args[$i + 1] if $args[$i] eq 'poll_syntax';
		}
	}
	$cmd = '' unless defined $cmd;

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pollsub,
				__PACKAGE__->can('cmd_poll'),
				$blocking,
				$timeout,
				$errmode,
				$returnRes ? 2 : 1,
				$blocking || wantarray, # Always true in blocking mode; if wantarray otherwise
				$returnRef,
				undef,	# n/a
			);
	$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		command			=>	$cmd,
		prompt			=>	$prompt,
		more_prompt		=>	$morePrompt,
		more_prompt_delay	=>	$morePromptDelay,
		more_pages		=>	$morePages,
		reset_prompt		=>	$reset_prompt && defined $self->{$Package}{PROMPTTYPE},
		yn_prompt		=>	undef,
		cmd_prompt		=>	$cmdPrompt,
		feed_data		=>	\@feedData,
		progress_dots		=>	$progressDots,
		# Declare method storage keys which will be used
		stage			=>	0,
		lastLine		=>	'',
		outputNewline		=>	'',
		progress		=>	undef,
		alreadyCmdTimeout	=>	0,
		ynPromptCount		=>	undef,
		cmdPromptCount		=>	undef,
		cmdEchoRemoved		=>	0,
		lastPromptEchoedCmd	=>	undef,
		cache_timeout		=>	$self->{POLL}{timeout},
		noRefreshCmdDone	=>	undef,
	};
	$self->{POLL}{output_requested} = !$pollSyntax || wantarray; # Always true in legacy syntax and in poll_syntax if wantarray
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	my ($ok, $output) = __PACKAGE__->can('poll_cmd')->($self, $pkgsub); # Do not call a sub-classed version
	# We have a different syntax for scalar output in blocking and non-blocking modes
	if ($pollSyntax) { # New syntax
		return wantarray ? ($ok, $output) : $ok;
	}
	else { # Old syntax
		return wantarray ? ($ok, $output) : $output;
	}
}


sub cmd_poll { # Poll status of cmd (non-blocking mode)
	my $pkgsub = "${Package}::cmd_poll";
	my $self = shift;
	carp "$pkgsub: No arguments expected" if @_; # No arguments expected

	unless (defined $self->{POLL} && $self->{POLL}{coderef} == __PACKAGE__->can('cmd_poll')) {
		return $self->error("$pkgsub: Method cmd() needs to be called first with blocking false");
	}
	$self->{POLL}{output_requested} = wantarray; # This might change at every call
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	# If already completed (1) or we got an error (undef) from previous call (errmsg is already set) then we go no further
	return $self->poll_return($self->{POLL}{complete}) unless defined $self->{POLL}{complete} && $self->{POLL}{complete} == 0;

	# We get here only if we are not complete: $self->{POLL}{complete} == 0
	return __PACKAGE__->can('poll_cmd')->($self, $pkgsub); # Do not call a sub-classed version
}


sub attribute { # Read attributes for host device
	my $pkgsub = "${Package}::attribute";
	my $self = shift;
	my %args;
	if (@_ == 1) { # Method invoked with just the command argument
		$args{attribute} = shift;
	}
	else {
		my @validArgs = ('attribute', 'reload', 'blocking', 'timeout', 'errmode', 'poll_syntax');
		%args = parseMethodArgs($pkgsub, \@_, \@validArgs);
	}

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pkgsub,
				__PACKAGE__->can('attribute_poll'),
				defined $args{blocking} ? $args{blocking} : $self->{blocking},
				defined $args{timeout} ? $args{timeout} : $self->{timeout},
				defined $args{errmode} ? parse_errmode($pkgsub, $args{errmode}) : undef,
				2,
				undef, # This is set below
				0,
				undef,	# n/a
			);
	$self->{POLL}{$pkgsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		attribute		=>	$args{attribute},
		reload			=>	$args{reload},
		# Declare method storage keys which will be used
		stage			=>	0,
		debugMsg		=>	0,
	};
	$self->{POLL}{output_requested} = !$args{poll_syntax} || wantarray; # Always true in legacy syntax and in poll_syntax if wantarray
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	my ($ok, $attribute) = __PACKAGE__->can('poll_attribute')->($self, $pkgsub); # Do not call a sub-classed version
	# We have a different syntax for scalar output in blocking and non-blocking modes
	if ($args{poll_syntax}) { # New syntax
		return wantarray ? ($ok, $attribute) : $ok;
	}
	else { # Old syntax
		return wantarray ? ($ok, $attribute) : $attribute;
	}
}


sub attribute_poll { # Poll status of attribute (non-blocking mode)
	my $pkgsub = "${Package}::attribute_poll";
	my $self = shift;
	carp "$pkgsub: No arguments expected" if @_; # No arguments expected

	unless (defined $self->{POLL} && $self->{POLL}{coderef} == __PACKAGE__->can('attribute_poll')) {
		return $self->error("$pkgsub: Method attribute() needs to be called first with blocking false");
	}
	$self->{POLL}{output_requested} = wantarray; # This might change at every call
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	# If already completed (1) or we got an error (undef) from previous call (errmsg is already set) then we go no further
	return $self->poll_return($self->{POLL}{complete}) unless defined $self->{POLL}{complete} && $self->{POLL}{complete} == 0;

	# We get here only if we are not complete: $self->{POLL}{complete} == 0
	return __PACKAGE__->can('poll_attribute')->($self, $pkgsub); # Do not call a sub-classed version
}


sub change_baudrate { # Change baud rate on device and on current connection, if serial
	my $pkgsub = "${Package}::change_baudrate";
	my $self = shift;
	my (%args);
	if (@_ == 1) { # Method invoked with just the command argument
		$args{baudrate} = shift;
	}
	else {
		my @validArgs = ('baudrate', 'parity', 'databits', 'stopbits', 'handshake', 'forcebaud',
				 'timeout', 'errmode', 'local_side_only', 'blocking', 'poll_syntax');
		%args = parseMethodArgs($pkgsub, \@_, \@validArgs);
	}

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pkgsub,
				__PACKAGE__->can('change_baudrate_poll'),
				defined $args{blocking} ? $args{blocking} : $self->{blocking},
				defined $args{timeout} ? $args{timeout} : $self->{timeout},
				defined $args{errmode} ? parse_errmode($pkgsub, $args{errmode}) : undef,
				2,
				undef, # This is set below
				0,
				undef,	# n/a
			);
	$self->{POLL}{$pkgsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		baudrate		=>	$args{baudrate},
		parity			=>	$args{parity},
		databits		=>	$args{databits},
		stopbits		=>	$args{stopbits},
		handshake		=>	$args{handshake},
		forcebaud		=>	$args{forcebaud},
		local_side_only		=>	$args{local_side_only},
		# Declare method storage keys which will be used
		stage			=>	0,
		userExec		=>	undef,
		privExec		=>	undef,
		maxMode			=>	$args{baudrate} eq 'max' ? 1:0,
	};
	$self->{POLL}{output_requested} = !$args{poll_syntax} || wantarray; # Always true in legacy syntax and in poll_syntax if wantarray
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	my ($ok, $baudrate) = __PACKAGE__->can('poll_change_baudrate')->($self, $pkgsub); # Do not call a sub-classed version
	# We have a different syntax for scalar output in blocking and non-blocking modes
	if ($args{poll_syntax}) { # New syntax
		return wantarray ? ($ok, $baudrate) : $ok;
	}
	else { # Old syntax
		return wantarray ? ($ok, $baudrate) : $baudrate;
	}
}


sub change_baudrate_poll { # Poll status of change_baudrate (non-blocking mode)
	my $pkgsub = "${Package}::change_baudrate_poll";
	my $self = shift;
	carp "$pkgsub: No arguments expected" if @_; # No arguments expected

	unless (defined $self->{POLL} && $self->{POLL}{coderef} == __PACKAGE__->can('change_baudrate_poll')) {
		return $self->error("$pkgsub: Method change_baudrate() needs to be called first with blocking false");
	}
	$self->{POLL}{output_requested} = wantarray; # This might change at every call
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	# If already completed (1) or we got an error (undef) from previous call (errmsg is already set) then we go no further
	return $self->poll_return($self->{POLL}{complete}) unless defined $self->{POLL}{complete} && $self->{POLL}{complete} == 0;

	# We get here only if we are not complete: $self->{POLL}{complete} == 0
	return __PACKAGE__->can('poll_change_baudrate')->($self, $pkgsub); # Do not call a sub-classed version
}


sub enable { # Enter PrivExec mode (handle enable password for WLAN2300)
	my $pkgsub = "${Package}::enable";
	my $self = shift;
	my %args;
	if (@_ == 1) { # Method invoked with just the command argument
		$args{password} = shift;
	}
	else {
		my @validArgs = ('password', 'prompt_credentials', 'timeout', 'errmode', 'blocking');
		%args = parseMethodArgs($pkgsub, \@_, \@validArgs);
	}

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pkgsub,
				__PACKAGE__->can('enable_poll'),
				defined $args{blocking} ? $args{blocking} : $self->{blocking},
				defined $args{timeout} ? $args{timeout} : $self->{timeout},
				defined $args{errmode} ? parse_errmode($pkgsub, $args{errmode}) : undef,
				0,	# no output
				0,	# no output
				undef,	# n/a
				undef,	# n/a
			);
	$self->{POLL}{$pkgsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		enable_password		=>	defined $args{password} ? $args{password} : $self->{$Package}{ENABLEPWD},
		prompt_credentials	=>	defined $args{prompt_credentials} ? $args{prompt_credentials} : $self->{prompt_credentials},
		# Declare method storage keys which will be used
		stage			=>	0,
		login_attempted		=>	undef,
		password_sent		=>	undef,
		login_failed		=>	undef,
	};
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};
	return __PACKAGE__->can('poll_enable')->($self, $pkgsub); # Do not call a sub-classed version
}


sub enable_poll { # Poll status of enable (non-blocking mode)
	my $pkgsub = "${Package}::enable_poll";
	my $self = shift;
	carp "$pkgsub: No arguments expected" if @_; # No arguments expected

	unless (defined $self->{POLL} && $self->{POLL}{coderef} == __PACKAGE__->can('enable_poll')) {
		return $self->error("$pkgsub: Method enable() needs to be called first with blocking false");
	}
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	# If already completed (1) or we got an error (undef) from previous call (errmsg is already set) then we go no further
	return $self->poll_return($self->{POLL}{complete}) unless defined $self->{POLL}{complete} && $self->{POLL}{complete} == 0;

	# We get here only if we are not complete: $self->{POLL}{complete} == 0
	return __PACKAGE__->can('poll_enable')->($self, $pkgsub); # Do not call a sub-classed version
}


sub device_more_paging { # Enable/Disable more paging on host device
	my $pkgsub = "${Package}::device_more_paging";
	my $self = shift;
	my (%args, $familyType);
	if (@_ == 1) { # Method invoked with just the command argument
		$args{enable} = shift;
	}
	else {
		my @validArgs = ('enable', 'timeout', 'errmode', 'blocking');
		%args = parseMethodArgs($pkgsub, \@_, \@validArgs);
	}

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pkgsub,
				__PACKAGE__->can('device_more_paging_poll'),
				defined $args{blocking} ? $args{blocking} : $self->{blocking},
				defined $args{timeout} ? $args{timeout} : $self->{timeout},
				defined $args{errmode} ? parse_errmode($pkgsub, $args{errmode}) : undef,
				0,	# no output
				0,	# no output
				undef,	# n/a
				undef,	# n/a
			);
	$self->{POLL}{$pkgsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		enable			=>	$args{enable},
		# Declare method storage keys which will be used
		stage			=>	0,
		cmdString		=>	undef,
	};
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};
	return __PACKAGE__->can('poll_device_more_paging')->($self, $pkgsub); # Do not call a sub-classed version
}


sub device_more_paging_poll { # Poll status of device_more_paging (non-blocking mode)
	my $pkgsub = "${Package}::device_more_paging_poll";
	my $self = shift;
	carp "$pkgsub: No arguments expected" if @_; # No arguments expected

	unless (defined $self->{POLL} && $self->{POLL}{coderef} == __PACKAGE__->can('device_more_paging_poll')) {
		return $self->error("$pkgsub: Method device_more_paging() needs to be called first with blocking false");
	}
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	# If already completed (1) or we got an error (undef) from previous call (errmsg is already set) then we go no further
	return $self->poll_return($self->{POLL}{complete}) unless defined $self->{POLL}{complete} && $self->{POLL}{complete} == 0;

	# We get here only if we are not complete: $self->{POLL}{complete} == 0
	return __PACKAGE__->can('poll_device_more_paging')->($self, $pkgsub); # Do not call a sub-classed version
}


sub device_peer_cpu { # Connect to peer CPU on ERS8x00 / VSP9000
	my $pkgsub = "${Package}::device_peer_cpu";
	my $self = shift;
	my $familyType;
	my @validArgs = ('username', 'password', 'prompt_credentials', 'timeout', 'errmode', 'blocking');
	my %args = parseMethodArgs($pkgsub, \@_, \@validArgs);

	# Initialize the base POLL structure
	$self->poll_struct( # $methodName, $codeRef, $blocking, $timeout, $errmode, $outputType, $outputRequested, $returnReference, $returnList
				$pkgsub,
				__PACKAGE__->can('device_peer_cpu_poll'),
				defined $args{blocking} ? $args{blocking} : $self->{blocking},
				defined $args{timeout} ? $args{timeout} : $self->{timeout},
				defined $args{errmode} ? parse_errmode($pkgsub, $args{errmode}) : undef,
				0,	# no output
				0,	# no output
				undef,	# n/a
				undef,	# n/a
			);
	$self->{POLL}{$pkgsub} = { # Populate structure with method arguments/storage
		# Set method argument keys
		username		=>	defined $args{username} ? $args{username} : $self->username,
		password		=>	defined $args{password} ? $args{password} : $self->password,
		prompt_credentials	=>	defined $args{prompt_credentials} ? $args{prompt_credentials} : $self->{prompt_credentials},
		# Declare method storage keys which will be used
		stage			=>	0,
	};
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};
	return __PACKAGE__->can('poll_device_peer_cpu')->($self, $pkgsub); # Do not call a sub-classed version
}


sub device_peer_cpu_poll { # Poll status of device_peer_cpu (non-blocking mode)
	my $pkgsub = "${Package}::device_peer_cpu_poll";
	my $self = shift;
	carp "$pkgsub: No arguments expected" if @_; # No arguments expected

	unless (defined $self->{POLL} && $self->{POLL}{coderef} == __PACKAGE__->can('device_peer_cpu_poll')) {
		return $self->error("$pkgsub: Method device_peer_cpu() needs to be called first with blocking false");
	}
	local $self->{POLLING} = 1; # True until we come out of this polling-capable method
	local $self->{errmode} = $self->{POLL}{errmode} if defined $self->{POLL}{errmode};

	# If already completed (1) or we got an error (undef) from previous call (errmsg is already set) then we go no further
	return $self->poll_return($self->{POLL}{complete}) unless defined $self->{POLL}{complete} && $self->{POLL}{complete} == 0;

	# We get here only if we are not complete: $self->{POLL}{complete} == 0
	return __PACKAGE__->can('poll_device_peer_cpu')->($self, $pkgsub); # Do not call a sub-classed version
}


sub debug_file { # Set debug output file
	my ($self, $fh) = @_;
	my $pkgsub = "${Package}::debug_file";

	unless (defined $fh) { # No input = return current filehandle
		return $self->{$Package}{DEBUGLOGFH};
	}
	unless (ref $fh or length $fh) { # Empty input = stop logging
		$self->{$Package}{DEBUGLOGFH} = undef;
		return;
	}
	if (!ref($fh) && !defined(fileno $fh)) { # Open a new filehandle if input is a filename
		my $logfile = $fh;
		$fh = IO::Handle->new;
		open($fh, '>', "$logfile") or return $self->error("$pkgsub: Unable to open output log file: $!");
	}
	$fh->autoflush();
	$self->{$Package}{DEBUGLOGFH} = $fh;
	return $fh;
}


#################################### Methods to set/read Object variables ####################################

sub flush_credentials { # Clear the stored username, password, passphrases, and enable password, if any
	my $self = shift;
	$self->SUPER::flush_credentials;
	$self->{$Package}{ENABLEPWD} = undef;
	return 1;
}


sub prompt { # Read/Set object prompt
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{prompt};
	if (defined $newSetting) {
		$self->debugMsg(4, "\nPrompt Regex set to:\n$newSetting\n");
		$self->{$Package}{prompt} = $newSetting;
		$self->{$Package}{prompt_qr} = qr/$newSetting/;
	}
	return $currentSetting;
}


sub more_prompt { # Read/Set object more prompt
	my ($self, $newSetting, $delayPrompt) = @_;
	my $currentSetting = $self->{$Package}{morePrompt};
	if (defined $newSetting) {
		$self->debugMsg(4, "More Prompt Regex set to:\n$newSetting\n");
		$self->{$Package}{morePrompt} = $newSetting;
		$self->{$Package}{morePrompt_qr} = $newSetting ? qr/$newSetting/ : undef;
		$self->{$Package}{morePromptDelay_qr} = $delayPrompt ? qr/$delayPrompt/ : undef;
	}
	return $currentSetting;
}


sub more_paging { # Set the number of pages to read in the resence of --more-- prompts from host
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{morePaging};
	$self->{$Package}{morePaging} = $newSetting if defined $newSetting;
	return $currentSetting;
}


sub progress_dots { # Enable/disable activity dots
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{progressDots};
	$self->{$Package}{progressDots} = $newSetting if defined $newSetting;
	return $currentSetting;
}


sub return_result { # Set/read return_result mode
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{return_result};
	$self->{$Package}{return_result} = $newSetting if defined $newSetting;
	return $currentSetting;
}


sub cmd_confirm_prompt { # Read/Set object cmd_confirm_prompt prompt
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{cmd_confirm_prompt};
	if (defined $newSetting) {
		$self->{$Package}{cmd_confirm_prompt} = $newSetting;
		$self->{$Package}{cmd_confirm_prompt_qr} = qr/$newSetting/;
	}
	return $currentSetting;
}


sub cmd_initiated_prompt { # Read/Set object cmd_initiated_prompt prompt
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{cmd_initiated_prompt};
	if (defined $newSetting) {
		$self->{$Package}{cmd_initiated_prompt} = $newSetting;
		$self->{$Package}{cmd_initiated_prompt_qr} = qr/$newSetting/;
	}
	return $currentSetting;
}


sub cmd_feed_timeout { # Read/Set object value of cmd_feed_timeout
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{cmd_feed_timeout};
	$self->{$Package}{cmd_feed_timeout} = $newSetting if defined $newSetting;
	return $currentSetting;
}


sub console { # Read/Set value of console
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{console};
	$self->{$Package}{console} = $newSetting if defined $newSetting;
	return $currentSetting;
}


sub wake_console { # Read/Set object value of wake_console
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{wake_console};
	$self->{$Package}{wake_console} = $newSetting if defined $newSetting;
	return $currentSetting;
}


sub last_cmd_success { # Return the result of the last command sent via cmd methods
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{last_cmd_success};
	$self->{$Package}{last_cmd_success} = $newSetting if defined $newSetting;
	return $currentSetting;
}


sub last_cmd_errmsg { # Set/read the last generated error message from host
	my ($self, $newSetting) = @_;
	my $currentSetting = $self->{$Package}{last_cmd_errmsg};
	$self->{$Package}{last_cmd_errmsg} = $newSetting if defined $newSetting;
	return $currentSetting;
}


sub no_refresh_cmd { # Read/Set object no_refresh_cmd pattern
	my ($self, $newSetting, $sendChar) = @_;
	my $currentSetting = $self->{$Package}{noRefreshCmdPattern};
	if (defined $newSetting && (defined $sendChar || !$newSetting)) {
		$self->debugMsg(4, "NoRefreshCmdPattern Regex set to:\n$newSetting\n");
		$self->{$Package}{noRefreshCmdPattern} = $newSetting ? $newSetting : undef;
		$self->{$Package}{noRefreshCmdSend} = "\n" eq $sendChar ? $self->{ors} : $sendChar;
	}
	return $currentSetting;
}


################################# Methods to read read-only Object variables #################################

sub config_context { # Return the configuration context contained in the last prompt
	my $self = shift;
	return $self->{$Package}{CONFIGCONTEXT};
}


sub enable_password { # Read the enable password (WLAN2300)
	my $self = shift;
	return $self->{$Package}{ENABLEPWD};
}


#################################### Private poll methods for sub classes ####################################

sub poll_connect { # Internal method to connect to host and perform login (used for both blocking & non-blocking modes)
	my $self = shift;
	my $pkgsub = shift;
	my $pollsub = "${Package}::connect";

	unless ($self->{POLLING}) { # Sanity check
		my (undef, $fileName, $lineNumber) = caller;
		croak "$pollsub (called from $fileName line $lineNumber) can only be used within polled methods";
	}

	unless (defined $self->{POLL}{$pollsub}) { # Only applicable if called from another method already in polling mode
		my @validArgs = ('host', 'port', 'username', 'password', 'publickey', 'privatekey', 'passphrase',
				 'prompt_credentials', 'baudrate', 'parity', 'databits', 'stopbits', 'handshake',
				 'errmode', 'connection_timeout', 'login_timeout', 'read_attempts', 'wake_console',
				 'data_with_error', 'terminal_type', 'window_size', 'callback', 'forcebaud',
				 'atomic_connect', 'non_recognized_login', 'generic_login');
		my %args = parseMethodArgs($pkgsub, \@_, \@validArgs, 1);
		if (@_ && !%args) { # Legacy syntax
			($args{host}, $args{port}, $args{username}, $args{password}, $args{publickey}, $args{privatekey},
			 $args{passphrase}, $args{baudrate}, $args{parity}, $args{databits}, $args{stopbits},
			 $args{handshake}, $args{prompt_credentials}, $args{read_attempts}, $args{wake_console},
			 $args{connection_timeout}, $args{login_timeout}, $args{errmode}) = @_;
		}
		# In which case we need to setup the poll structure for them here (the main poll structure remains unchanged)
		$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
			# Set method argument keys
			host			=>	$args{host},
			port			=>	$args{port},
			username		=>	defined $args{username} ? $args{username} : $self->{USERNAME},
			password		=>	defined $args{password} ? $args{password} : $self->{PASSWORD},
			publickey		=>	$args{publickey},
			privatekey		=>	$args{privatekey},
			passphrase		=>	defined $args{passphrase} ? $args{passphrase} : $self->{PASSPHRASE},
			baudrate		=>	$args{baudrate},
			parity			=>	$args{parity},
			databits		=>	$args{databits},
			stopbits		=>	$args{stopbits},
			handshake		=>	$args{handshake},
			prompt_credentials	=>	defined $args{prompt_credentials} ? $args{prompt_credentials} : $self->{prompt_credentials},
			terminal_type		=>	$args{terminal_type},
			window_size		=>	$args{window_size},
			callback		=>	$args{callback},
			forcebaud		=>	$args{forcebaud},
			atomic_connect		=>	$args{atomic_connect},
			login_timeout		=>	defined $args{login_timeout} ? $args{login_timeout} : $self->{timeout},
			read_attempts		=>	defined $args{read_attempts} ? $args{read_attempts} : $LoginReadAttempts,
			data_with_error		=>	defined $args{data_with_error} ? $args{data_with_error} : $self->{data_with_error},
			wake_console		=>	defined $args{wake_console} ? $args{wake_console} : $self->{$Package}{wake_console},
			non_recognized_login	=>	defined $args{non_recognized_login} ? $args{non_recognized_login} : $NonRecognizedLogin,
			generic_login		=>	defined $args{generic_login} ? $args{generic_login} : $GenericLogin,
			# Declare method storage keys which will be used
			stage			=>	$self->{LOGINSTAGE} ? 1 : 0,
			# Declare keys to be set if method called from another polled method
			errmode			=>	$args{errmode},
		};
		# Cache poll structure keys which this method will use
		$self->poll_struct_cache($pollsub, $args{connection_timeout});
	}
	my $connect = $self->{POLL}{$pollsub};
	local $self->{errmode} = $connect->{errmode} if defined $connect->{errmode};

	if ($connect->{stage} < 1) { # Connect stage
		my $ok = $self->SUPER::poll_connect($pkgsub,
			Host			=> $connect->{host},
			Port			=> $connect->{port},
			Username		=> $connect->{username},
			Password		=> $connect->{password},
			PublicKey		=> $connect->{publickey},
			PrivateKey		=> $connect->{privatekey},
			Passphrase		=> $connect->{passphrase},
			BaudRate		=> $connect->{baudrate},
			ForceBaud		=> $connect->{forcebaud},
			Parity			=> $connect->{parity},
			DataBits		=> $connect->{databits},
			StopBits		=> $connect->{stopbits},
			Handshake		=> $connect->{handshake},
			Prompt_credentials	=> $connect->{prompt_credentials},
			Terminal_type		=> $connect->{terminal_type},
			Window_size		=> $connect->{window_size},
			Callback		=> $connect->{callback},
			Atomic_connect		=> $connect->{atomic_connect},
		);
		return $self->poll_return($ok) unless $ok; # Come out if error (if errmode='return'), or if nothing to read in non-blocking mode
		# Unless console already set, set it now; will determine whether or not wake_console is sent upon login
		$self->console(	 $self->connection_type eq 'SERIAL' ||
				($self->connection_type eq 'TELNET' && $self->port != 23) ||
				($self->connection_type eq 'SSH'    && $self->port != 22) ) unless defined $self->console;
		$connect->{stage}++; # Ensure we don't come back here in non-blocking mode
	}

	# Login stage
	my ($ok, $outRef) = $self->poll_login($pkgsub,
			Username		=> $connect->{username},
			Password		=> $connect->{password},
			Read_attempts		=> $connect->{read_attempts},
			Wake_console		=> $connect->{wake_console},
			Data_with_error		=> $connect->{data_with_error},
			Non_recognized_login	=> $connect->{non_recognized_login},
			Generic_login		=> $connect->{generic_login},
			Prompt_credentials	=> $connect->{prompt_credentials},
			Timeout			=> $connect->{login_timeout},
	);
	$self->{POLL}{output_buffer} = $$outRef if $ok;
	return $self->poll_return($ok);
}


sub poll_login { # Method to handle login for poll methods (used for both blocking & non-blocking modes)
	my $self = shift;
	my $pkgsub = shift;
	my $pollsub = "${Package}::login";

	unless ($self->{POLLING}) { # Sanity check
		my (undef, $fileName, $lineNumber) = caller;
		croak "$pollsub (called from $fileName line $lineNumber) can only be used within polled methods";
	}

	unless (defined $self->{POLL}{$pollsub}) { # Only applicable if called from another method already in polling mode
		my @validArgs = ('username', 'password', 'prompt_credentials', 'timeout', 'errmode', 'read_attempts', 'wake_console',
				 'data_with_error', 'non_recognized_login', 'generic_login');
		my %args = parseMethodArgs($pkgsub, \@_, \@validArgs, 1);
		if (@_ && !%args) { # Legacy syntax
			($args{username}, $args{password}, $args{read_attempts}, $args{wake_console},
			 $args{prompt_credentials}, $args{data_with_error}, $args{timeout}, $args{errmode}) = @_;
		}
		# In which case we need to setup the poll structure for them here (the main poll structure remains unchanged)
		$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
			# Set method argument keys
			username		=>	defined $args{username} ? $args{username} : $self->{USERNAME},
			password		=>	defined $args{password} ? $args{password} : $self->{PASSWORD},
			prompt_credentials	=>	defined $args{prompt_credentials} ? $args{prompt_credentials} : $self->{prompt_credentials},
			read_attempts		=>	defined $args{read_attempts} ? $args{read_attempts} : $LoginReadAttempts,
			data_with_error		=>	defined $args{data_with_error} ? $args{data_with_error} : $self->{data_with_error},
			wake_console		=>	defined $args{wake_console} ? $args{wake_console} : $self->{$Package}{wake_console},
			non_recognized_login	=>	defined $args{non_recognized_login} ? $args{non_recognized_login} : $NonRecognizedLogin,
			generic_login		=>	defined $args{generic_login} ? $args{generic_login} : $GenericLogin,
			# Declare method storage keys which will be used
			stage			=>	0,
			login_attempted		=>	undef,
			password_sent		=>	undef,
			login_error		=>	'',
			family_type		=>	undef,
			cpu_slot		=>	undef,
			detectionFromPrompt	=>	undef,
			# Declare keys to be set if method called from another polled method
			errmode			=>	$args{errmode},
		};
		# Cache poll structure keys which this method will use
		$self->poll_struct_cache($pollsub, $args{timeout});
	}
	my $login = $self->{POLL}{$pollsub};
	local $self->{errmode} = $login->{errmode} if defined $login->{errmode};
	return $self->poll_return($self->error("$pkgsub: No connection to login to")) if $self->eof;

	my $usernamePrompt = $self->username_prompt;
	my $passwordPrompt = $self->password_prompt;

	if ($login->{stage} < 1) { # Initial loginstage & setup - do only once
		$login->{stage}++; # Ensure we don't come back here in non-blocking mode
		if ($self->{LOGINSTAGE}) {
			$login->{family_type} = $self->{$Package}{ATTRIB}{'family_type'}; # Might be already set from previous login attempt
		}
		else {	# Flush all attributes, as we assume we are connecting to a new device
			$self->{$Package}{ATTRIB} = undef;
			$self->{$Package}{ATTRIBFLAG} = undef;
		}
		# Handle resuming previous login attempt
		if ($self->{LOGINSTAGE} eq 'username' && $login->{username}) { # Resume login from where it was left
			$self->print(line => $login->{username}, errmode => 'return')
				or return $self->poll_return($self->error("$pkgsub: Unable to send username // ".$self->errmsg));
			$self->{LOGINSTAGE} = '';
			$login->{login_attempted} = 1;
		}
		elsif ($self->{LOGINSTAGE} eq 'password' && $login->{password}) { # Resume login from where it was left
			$self->print(line => $login->{password}, errmode => 'return')
				or return $self->poll_return($self->error("$pkgsub: Unable to send password // ".$self->errmsg));
			$self->{LOGINSTAGE} = '';
			$login->{login_attempted} = 1;
		}
		elsif ($self->console && $login->{wake_console}) {
			$self->debugMsg(8,"\nlogin() Sending wake_console sequence >$login->{wake_console}<\n");
			$self->put(string => $login->{wake_console}, errmode => 'return') # Bring connection into life
				or return $self->poll_return($self->error("$pkgsub: Unable to send bring alive character sequence // ".$self->errmsg));
		}
	}
	if ($login->{stage} < 2) { # Main login loop
		my ($pattern, $patdepth, $deepest);
		my ($promptType, $capturedPrompt, $switchName, $cliType, $configContext);
		LOGINLOOP: while (1) {
			# Wait until we have read in all available data
			my $ok = $self->poll_readwait($pkgsub, 1, $login->{read_attempts}, $ReadwaitTimer, $login->{login_error}.'Failed reading login prompt', $login->{data_with_error});
			return $self->poll_return($ok) unless $ok; # Come out if error (if errmode='return'), or if nothing to read in non-blocking mode

			$self->debugMsg(8,"\nlogin() Connection input to process:\n>", \$self->{POLL}{read_buffer}, "<\n");
			$self->{POLL}{output_buffer} .= $self->{POLL}{read_buffer}; # This buffer preserves all the output, in case it is requested
			$self->{POLL}{local_buffer} = $self->{POLL}{read_buffer} =~ /\n/ ? '' : stripLastLine(\$self->{POLL}{local_buffer}); # Flush or keep lastline
			$self->{POLL}{local_buffer} .= $self->{POLL}{read_buffer};  # If read was single line, this buffer appends it to lastline from previous read

			# Pattern matching; try and detect patterns, and record their depth in the input stream
			$pattern = '';
			$deepest = -1;
			foreach my $key (keys %LoginPatterns) {
				if (($patdepth = rindex($self->{POLL}{read_buffer}, $LoginPatterns{$key})) >= 0) { # We have a match
					$self->debugMsg(8,"\nlogin() Matched pattern $key @ depth $patdepth\n");
					unless ($login->{family_type}) { # Only if family type not already detected
						# If a banner is seen, try and extract attributes from it also
						if ($key eq 'banner' || $key eq 'menu' || $key eq 'submenu') {
							$login->{family_type} = $Prm{bstk};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 1);
							if ($key eq 'banner') {
								$self->{POLL}{read_buffer} =~ /\*\*\* ((?:[^\*\n]+?) (?:Switch|Controller|Platform) (?:WC)?\d+.*?)\s+/ &&
									$self->_setModelAttrib($1);
								$self->{POLL}{read_buffer} =~ /FW:([\d\.]+)\s+SW:v([\d\.]+)/ && do {
									$self->_setAttrib('fw_version', $1);
									$self->_setAttrib('sw_version', $2);
								};
							}
						}
						elsif ($key eq 'srbanner') {
							$login->{family_type} = $Prm{sr};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 1);
							$self->{POLL}{read_buffer} =~ /\((Secure Router \d+)\)/ && $self->_setModelAttrib($1);
							$self->{POLL}{read_buffer} =~ /Version: (.+)/ && $self->_setAttrib('sw_version', $1);
						}
						elsif ($key eq 'xlrbanner') {
							$login->{family_type} = $Prm{xlr};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 0);
							$self->{POLL}{read_buffer} =~ /\* Software Release (?i:v|REL)?(.+?) / && $self->_setAttrib('sw_version', $1);
						}
						elsif ($key eq 'ersbanner' || $key eq 'passportbanner' || $key eq 'pp1600banner') {
							$login->{family_type} = $Prm{pers};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 0);
							$self->{POLL}{read_buffer} =~ /\* Software Release (?i:v|REL)?(.+?) / && $self->_setAttrib('sw_version', $1);
						}
						elsif ($key eq 'vspbanner') {
							$login->{family_type} = $Prm{pers};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 1);
							$self->{POLL}{read_buffer} =~ /Software Release Build (.+?) / && $self->_setAttrib('sw_version', $1);
						}
						elsif ($key eq 'wlan9100banner') {
							$login->{family_type} = $Prm{xirrus};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 1);
							$self->{POLL}{read_buffer} =~ /AvayaOS Version (.+?) / && $self->_setAttrib('sw_version', $1);
						}
						elsif ($key eq 'xos') {
							$login->{family_type} = $Prm{xos};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 0, is_xos => 1);
						}
						elsif ($key eq 'isw') {
							$login->{family_type} = $Prm{isw};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 1, is_isw => 1, baudrate => 115200);
						}
						elsif ($key eq 'slx') {
							$login->{family_type} = $Prm{slx};
							$self->debugMsg(8,"login() Detected family_type = $login->{family_type}\n");
							$self->_setFamilyTypeAttrib($login->{family_type}, is_nncli => 1, is_slx => 1);
						}
					}
					if ($patdepth > $deepest) { # We have a deeper match, we keep it
						($pattern, $deepest) = ($key, $patdepth);
					}
				}
			}
			$self->debugMsg(8,"\nlogin() Retaining pattern: $pattern\n") if $deepest > -1;

			# Try and match CLI prompts now; this is the only exit point of the loop
			if ($login->{family_type}) { # A family type was already detected from banner
				if ($login->{family_type} eq $Prm{pers}) {
					foreach my $type ('cli', 'nncli') {
						$promptType = "$login->{family_type}_$type";
						if ($self->{POLL}{local_buffer} =~ /($InitPrompt{$promptType})/) {
							($capturedPrompt, $switchName, $login->{cpu_slot}, $configContext) = ($1, $2, $3, $4);
							$cliType = $type;
							last;
						}
					}
				}
				else {
					if ($self->{POLL}{local_buffer} =~ /($InitPrompt{$login->{family_type}})/) {
						($capturedPrompt, $switchName, $configContext) = ($1, $2, $4);
						$promptType = $login->{family_type};
					}
				}
			}
			else { # A family type has not been detected yet; try and detect from received prompt
				foreach my $key (@InitPromptOrder) {
					if ($self->{POLL}{local_buffer} =~ /($InitPrompt{$key})/) {
						($capturedPrompt, $switchName, $login->{cpu_slot}, $configContext) = ($1, $2, $3, $4);
						$promptType = $key;
						($login->{family_type} = $key) =~ s/_(\w+)$//;
						$cliType = $1;
						$login->{detectionFromPrompt} = 1;
						last;
					}
				}
			}
			if ($capturedPrompt) { # We have a prompt, we can exit loop
				$self->debugMsg(8,"\nlogin() Got CLI prompt for family type $login->{family_type} !\n");
				$capturedPrompt =~ s/^\x0d//; # Remove initial carriage return if there
				$capturedPrompt =~ s/\x0d$//; # Remove trailing carriage return if there (possible if we match on not the last prompt, as we do /m matching above
				if ($login->{family_type} eq $Prm{slx}) { # SLX with vt100 spoils the 1st prompt, correct it here
					$capturedPrompt =~ s/^\e\[\?7h//;
					$switchName =~ s/^\e\[\?7h//;
				}
				$self->_setDevicePrompts($promptType, $switchName);
				$self->_setLastPromptAndConfigContext($capturedPrompt, $configContext);
				$self->_setAttrib('cpu_slot', $login->{cpu_slot}) if $login->{family_type} eq $Prm{pers};
				if ($login->{detectionFromPrompt}) {
					if ($login->{family_type} eq $Prm{bstk} || (defined $cliType && $cliType eq 'nncli')) {
						$self->_setAttrib('is_nncli', 1);
					}
					else {
						$self->_setAttrib('is_nncli', 0);
					}
				}
				last LOGINLOOP;
			}

			# Now try and match other prompts expected to be seen at the very end of received input stream
			if ($self->{POLL}{read_buffer} =~ /$usernamePrompt/) { # Handle Modular login prompt
				$self->debugMsg(8,"\nlogin() Matched Login prompt\n\n");
				$pattern = 'username';
			}
			elsif ($self->{POLL}{read_buffer} =~ /$passwordPrompt/) { # Handle Modular password prompt
				$self->debugMsg(8,"\nlogin() Matched Password prompt\n\n");
				$pattern = 'password';
			}

			# Now handle any pattern matches we had above
			if ($pattern eq 'banner' || $pattern eq 'bell') { # We got the banner, send a CTRL-Y to get in
				$self->debugMsg(8,"\nlogin() Processing Stackable Banner\n\n");
				$self->put(string => $CTRL_Y, errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to send CTRL-Y sequence // ".$self->errmsg));
				next;
			}
			elsif ($pattern eq 'menu') { # We got the menu, send a 'c' and get into CLI
				$self->debugMsg(8,"\nlogin() Processing Stackable Menu\n\n");
				$self->put(string => 'c', errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to select 'Command Line Interface...' // ".$self->errmsg));
				next;
			}
			elsif ($pattern eq 'submenu') { # We are in a sub-menu page, send a 'CTRL_C' to get to main menu page
				$self->debugMsg(8,"\nlogin() Processing Stackable Sub-Menu page\n\n");
				$self->put(string => $CTRL_C, errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to go back to main menu page // ".$self->errmsg));
				next;
			}
			elsif ($pattern =~ /^more\d$/) { # We are connecting on the console port, and we are in the midst of more-paged output
				$self->debugMsg(8,"\nlogin() Quitting residual more-paged output for serial port access\n");
				$self->put(string => 'q', errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to quit more-paged output found after serial connect // ".$self->errmsg));
				next;
			}
			elsif ($pattern =~ /^consoleLogMsg\d$/) { # We are connecting on the console port, and this log message is spoiling our 1st prompt
				$self->debugMsg(8,"\nlogin() Sending extra carriage return after password for serial port access\n");
				# On Modular VSPs Console port, immediately after login you get log message :SW INFO user rwa connected via console port
				# As this message is appended to the very 1st prompt, we are not able to lock on that initial prompt
				# So we feed an extra carriage return so that we can lock on a fresh new prompt
				$self->print(errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to get new prompt after console log message // ".$self->errmsg));
				next;
			}
			elsif ($pattern eq 'lastlogin') { # Last login splash screen; skip it with RETURN key
				# This screen appears on ERS4800 release 5.8
				$self->debugMsg(8,"\nlogin() Processing Last Login screen\n\n");
				$self->print(errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to send Carriage Return // ".$self->errmsg));
				next;
			}
			elsif ($pattern eq 'username') { # Handle login prompt
				$self->debugMsg(8,"\nlogin() Processing Login/Username prompt\n\n");
				if ($login->{login_attempted}) {
					$self->{LOGINSTAGE} = 'username';
					return $self->poll_return($self->error("$pkgsub: Incorrect Username or Password"));
				}
				unless ($login->{username}) {
					if ($self->{TYPE} eq 'SSH') { # If an SSH connection, we already have the username
						$login->{username} = $self->{USERNAME};
					}
					else {
						unless ($login->{prompt_credentials}) {
							$self->{LOGINSTAGE} = 'username';
							return $self->poll_return($self->error("$pkgsub: Username required"));
						}
						$login->{username} = promptCredential($login->{prompt_credentials}, 'Clear', 'Username');
					}
				}
				$self->print(line => $login->{username}, errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to send username // ".$self->errmsg));
				$self->{LOGINSTAGE} = '';
				$login->{login_attempted} = 1;
				next;
			}
			elsif ($pattern eq 'password') { # Handle password prompt
				$self->debugMsg(8,"\nlogin() Processing Password prompt\n\n");
				if ($login->{password_sent}) {
					$self->{LOGINSTAGE} = 'password';
					return $self->poll_return($self->error("$pkgsub: Incorrect Username or Password"));
				}
				unless (defined $login->{password}) {
					unless ($login->{prompt_credentials}) {
						$self->{LOGINSTAGE} = 'password';
						return $self->poll_return($self->error("$pkgsub: Password required"));
					}
					$login->{password} = promptCredential($login->{prompt_credentials}, 'Hide', 'Password');
				}
				$self->print(line => $login->{password}, errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to send password // ".$self->errmsg));
				$self->{LOGINSTAGE} = '';
				$login->{password_sent} = 1;
				next;
			}
			elsif ($pattern =~ /^localfail/) { # Login failure
				return $self->poll_return($self->error("$pkgsub: Incorrect Username or Password"));
			}
			elsif ($pattern eq 'radiusfail') { # Radius Login failure
				return $self->poll_return($self->error("$pkgsub: Switch got access denied from RADIUS"));
			}
			elsif ($pattern =~ /^radiustimeout\d$/) { # Radius timeout
				$login->{login_error} = "Switch got no response from RADIUS servers\n";
				next; # In this case don't error, as radius falback might still get us in
			}
			if (!$login->{family_type} && $login->{non_recognized_login}) { # If we have some complete output, which does not match any of the above, we can come out if we asked to
				return $self->poll_return($self->error("$pkgsub: Non recognized login output"));
			}
		}
		if (!$login->{generic_login} && ($login->{family_type} eq $Prm{generic} || ($login->{detectionFromPrompt} && $self->{LASTPROMPT} !~ /^@/)) ) { # Can't tell, need extended discovery
			$login->{stage}++; # Move to next section in non-blocking mode
		}
		else {
			$login->{stage} += 2; # Move to section after next
		}
		return $self->poll_return(0) unless $self->{POLL}{blocking};
	}
	if ($login->{stage} < 3) { # Extended discovery
		my ($ok, $familyType) = $self->discoverDevice($pkgsub);
		return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
		$login->{family_type} = $familyType;
		if ($login->{family_type} eq $Prm{generic} && ($self->{errmode} eq 'croak' || $self->{errmode} eq 'die')) {
			carp "\n$pkgsub Warning! Device type not detected; using $Prm{generic}\n";
		}
		$login->{stage} += 2; # Move to final section
	}
	if ($login->{stage} < 4) { # Generic_login OR family type was detected, not just from the prompt (though we do rely on prompt alone for Standby CPUs on PassportERS)
		if ($login->{family_type} eq $Prm{pers} || $login->{family_type} eq $Prm{xlr}) {
			$self->_setAttrib('is_master_cpu', $self->{LASTPROMPT} =~ /^@/ ? 0 : 1);
			$self->_setAttrib('is_dual_cpu', 1) if $self->{LASTPROMPT} =~ /^@/;
		}
		$self->_setFamilyTypeAttrib($login->{family_type}) if $login->{detectionFromPrompt};
	}

	# Store credentials if these were used
	($self->{USERNAME}, $self->{PASSWORD}) = ($login->{username}, $login->{password}) if $login->{login_attempted};
	return $self->poll_return(1);
}


sub poll_cmd { # Method to handle cmd for poll methods (used for both blocking & non-blocking modes)
	my $self = shift;
	my $pkgsub = shift;
	my $pollsub = "${Package}::cmd";

	unless ($self->{POLLING}) { # Sanity check
		my (undef, $fileName, $lineNumber) = caller;
		croak "$pollsub (called from $fileName line $lineNumber) can only be used within polled methods";
	}

	unless (defined $self->{POLL}{$pollsub}) { # Only applicable if called from another method already in polling mode
		my @validArgs = ('command', 'feed_list', 'prompt', 'reset_prompt', 'more_prompt', 'cmd_confirm_prompt',
				  'cmd_initiated_prompt', 'more_pages', 'timeout', 'errmode', 'progress_dots');
		my %args = parseMethodArgs($pkgsub, \@_, \@validArgs, 1);
		if (@_ && !%args) { # Legacy syntax
			($args{command}, $args{more_pages}, $args{prompt}, $args{reset_prompt}, $args{timeout}, $args{errmode},
			 $args{feed_list}, $args{cmd_confirm_prompt}, $args{cmd_initiated_prompt}) = @_;
		}
		$args{feed_list} = [$args{feed_list}] if defined $args{feed_list} && !ref($args{feed_list}) eq "ARRAY";	# We want it as an array reference
		# In which case we need to setup the poll structure for them here (the main poll structure remains unchanged)
		$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
			# Set method argument keys
			command			=>	$args{command},
			prompt			=>	defined $args{prompt} ? $args{prompt} : $self->{$Package}{prompt_qr},
			more_prompt		=>	defined $args{more_prompt} ? $args{more_prompt} : $self->{$Package}{morePrompt_qr},
			more_prompt_delay	=>	defined $args{more_prompt} ? undef : $self->{$Package}{morePromptDelay_qr},
			more_pages		=>	defined $args{more_pages} ? $args{more_pages} : $self->{$Package}{morePaging},
			reset_prompt		=>	$args{reset_prompt} && defined $self->{$Package}{PROMPTTYPE},
			yn_prompt		=>	defined $args{cmd_confirm_prompt} ? $args{cmd_confirm_prompt} : $self->{$Package}{cmd_confirm_prompt_qr},
			cmd_prompt		=>	defined $args{cmd_initiated_prompt} ? $args{cmd_initiated_prompt} : $self->{$Package}{cmd_initiated_prompt_qr},
			feed_data		=>	$args{feed_list},
			progress_dots		=>	defined $args{progress_dots} ? $args{progress_dots} : $self->{$Package}{progressDots},
			# Declare method storage keys which will be used
			stage			=>	0,
			lastLine		=>	'',
			outputNewline		=>	'',
			progress		=>	undef,
			alreadyCmdTimeout	=>	0,
			ynPromptCount		=>	undef,
			cmdPromptCount		=>	undef,
			cmdEchoRemoved		=>	0,
			lastPromptEchoedCmd	=>	undef,
			cache_timeout		=>	defined $args{timeout} ? $args{timeout} : $self->{POLL}{timeout},
			noRefreshCmdDone	=>	undef,
			# Declare keys to be set if method called from another polled method
			errmode			=>	$args{errmode},
		};
		# Cache poll structure keys which this method will use
		$self->poll_struct_cache($pollsub, $args{timeout});
	}

	my $cmd = $self->{POLL}{$pollsub};
	local $self->{errmode} = $cmd->{errmode} if defined $cmd->{errmode};
	return $self->poll_return($self->error("$pkgsub: No connection to send cmd to")) if $self->eof;
	$cmd->{prompt} = $InitPrompt{$self->{$Package}{PROMPTTYPE}} if $cmd->{reset_prompt};
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';
	my $newLineLastLine = 0;

	if ($cmd->{stage} < 1) { # Send command - do only once
		$cmd->{stage}++; # Ensure we don't come back here in non-blocking mode
		if (defined $cmd->{command}) {
			my $command = $cmd->{command};
			# In NNCLI mode, if command ends with ?, append CTRL-X otherwise partial command will appear after next prompt
			if ($command =~ /\?\s*$/ && $self->{$Package}{ATTRIB}{'is_nncli'}) {
				if ($familyType eq $Prm{sr}) { $command .= $CTRL_U }
				else { $command .= $CTRL_X }
			}
			# Flush any unread data which might be pending
			$self->read(blocking => 0);
			# Send the command
			$self->debugMsg(8,"\ncmd() Sending command:>", \$command, "<\n");
			$self->print(line => $command, errmode => 'return')
				or return $self->poll_return($self->error("$pkgsub: Unable to send CLI command: $command // ".$self->errmsg));
		}
	}
	CMDLOOP: while (1) {
		# READ in data
		if ($cmd->{stage} == 1) { # Normal data read
			my $ok = $self->poll_read($pkgsub); # We always come back even in case of error
			return $self->poll_return($ok) if defined $ok && $ok == 0; # Come out only in case of non-blocking not ready
			unless (defined $ok) { # We catch timeout event here
				if ($cmd->{alreadyCmdTimeout} || !length $familyType || $familyType eq $Prm{generic}) {
					return $self->poll_return($self->error("$pkgsub: Failed after sending command // ".$self->errmsg));
				}
				$self->debugMsg(4, "\ncmd() Initial cmd timeout; attempting reset_prompt\n");
				$self->print(errmode => 'return') # Send a carriage return and we have a 2nd try at catching prompt
					or return $self->poll_return($self->error("$pkgsub: Unable to send Carriage Return // ".$self->errmsg));
				$self->{POLL}{timeout} = $cmd->{cache_timeout} * $CmdTimeoutRatio; # Re-arm timeout
				$cmd->{prompt} = $InitPrompt{$self->{$Package}{PROMPTTYPE}};
				$cmd->{alreadyCmdTimeout} = 1; # Ensures that at next timeout we generate the error mode action (so cannot loop)
				$cmd->{reset_prompt} = 1;
				return $self->poll_return(0) unless $self->{POLL}{blocking};
				next CMDLOOP;
			}
		}
		elsif ($cmd->{stage} == 2) { # cmd_prompt / Wait if more data coming
			my $ok = $self->poll_readwait($pkgsub, 0, $CmdPromptReadAttempts, $ReadwaitTimer, "Cmd_prompt; unable to check for more data");
			return $self->poll_return($ok) unless $ok; # Come out if error (if errmode='return'), or if nothing to read in non-blocking mode
			$cmd->{stage} = 1; # Whatever the outcome below, we will revert to normal data reads
			unless (length $self->{POLL}{read_buffer}) { # No more data => no false trigger
				$self->debugMsg(8,"\ncmd() Detected CMD embedded prompt\n");
				my $feed;
				if ($feed = shift(@{$cmd->{feed_data}})) {
					$self->debugMsg(8,"cmd()  - Have data to feed:>", \$feed, "<\n");
				}
				else {
					if (++$cmd->{cmdPromptCount} > $self->{$Package}{cmd_feed_timeout}) {
						return $self->poll_return($self->error("$pkgsub: Command embedded prompt timeout"));
					}
					$feed = '';
					$self->debugMsg(8,"cmd()  - No data to feed!\n");
				}
				$self->print(line => $feed, errmode => 'return')
					or return $self->poll_return($self->error("$pkgsub: Unable to feed data at cmd prompt // ".$self->errmsg));

				return $self->poll_return(0) unless $self->{POLL}{blocking};
				next CMDLOOP;
			}
		}
		else { # Stage = 3 ; more prompt delay / 1 non-blocking read to ascertain if partial more prompt can be processed or not
			my $ok = $self->poll_readwait($pkgsub, 0, 1, $ReadwaitTimer, "Delayed More prompt; unable to check for more data");
			return $self->poll_return($ok) unless $ok; # Come out if error (if errmode='return'), or if nothing to read in non-blocking mode
			$cmd->{stage} = 1; # We immediately revert to normal data reads
		}

		# Process data
		if ($cmd->{progress_dots}) { # Print dots for progress
			_printDot() unless defined $cmd->{progress};
			if ( ( $cmd->{progress} += length($self->{POLL}{read_buffer}) ) > $cmd->{progress_dots}) {
				_printDot();
				$cmd->{progress} -= $cmd->{progress_dots};
			}
		}

		unless ($cmd->{cmdEchoRemoved}) { # If the echoed cmd was not yet removed
			$self->{POLL}{local_buffer} .= $self->{POLL}{read_buffer};	# Append to local_buffer
			if ($self->{POLL}{local_buffer} =~ s/(^.*\n)//) { # if we can remove it now
				$self->debugMsg(8,"\ncmd() Stripped echoed command\n");
				$cmd->{lastPromptEchoedCmd} = $self->{LASTPROMPT} . $1;
				$cmd->{lastPromptEchoedCmd} =~ s/\x10?\x00//g if $familyType eq $Prm{xirrus};	# WLAN9100 in telnet
				$cmd->{cmdEchoRemoved} = 1;
				$self->{POLL}{read_buffer} = $self->{POLL}{local_buffer};	# Re-prime read_buffer so that we fall through below with what's left
				$self->{POLL}{local_buffer} = '';				# Empty local_buffer so that we fall through below
				next CMDLOOP unless length $self->{POLL}{read_buffer};		# If we have remaining data, fall through, else do next cycle
			}
			else { # if we can't then no point processing patterns below
				next CMDLOOP;	# Do next read
			}
		}
		# If we get here, it means that the echo-ed cmd has been removed
		# read_buffer will either hold remaining output after removing echoed cmd
		# or it will hold the most recent data read

		my $output = $cmd->{lastLine}.$self->{POLL}{read_buffer};	# New output appended to previous lastLine
		$self->{POLL}{output_buffer} .= $cmd->{outputNewline};		# Re-add newLine if had been withheld
		$self->debugMsg(8,"\ncmd() Output for new cycle:\n>", \$output, "<\n") if length $output;

		# We check for refresh patterns here, as the patterns may not be in the lastline
		if ($self->{$Package}{noRefreshCmdPattern} && !$cmd->{noRefreshCmdDone} && $output =~ /$self->{$Package}{noRefreshCmdPattern}/m) { # We have a refreshed command
			$self->debugMsg(8,"\ncmd() Refreshed command output detected; feeding noRefreshCmdSend\n");
			$self->put(string => $self->{$Package}{noRefreshCmdSend}, errmode => 'return')
				or return $self->poll_return($self->error("$pkgsub: Unable to cancel refreshed command // ".$self->errmsg));
			$cmd->{noRefreshCmdDone} = 1;	# Make sure we do this only once
		}

		if (length $output) { # Clean up patterns
			$output =~ s/^(?:\x08 \x08)+//;					# Remove backspace chars following a more prompt, if any
			$output =~ s/^\x08+ +\x08+//;     				# Remove backspace chars following a more prompt, if any (Wing and SLX)
			$output =~ s/^\x0d *\x0d//	 if $familyType eq $Prm{s200};	# Remove Secure Router CR+spaces+0+CR sequence following more prompt
			$output =~ s/^\x0d *\x00\x0d//	 if $familyType eq $Prm{sr};	# Remove Secure Router CR+spaces+0+CR sequence following more prompt
			$output =~ s/^(?:\e\[D \e\[D)+// if $familyType eq $Prm{isw};	# Remove ISW escape sequences following more prompt
			if ($familyType eq $Prm{slx}) {
				$output =~ s/(?:(?:\e\[[58]D|\x0d)?\e\[K|(?:\e\[\dD|\x08)*\x0d {8}(?:\e\[\dD|\x08)*\x0d?|\x08{8} {8}\x08{8})//; # Remove SLX escape sequence following more prompt or final END prompt (Telnet/ssh | Console)
				$output =~ s/ ?\e\[\d+;\d+H//g; # Remove SLX escape sequences on Console output of some command
				$output =~ s/\e\[m\x0f(?:\e\[7m)?//g; # SLX9850 on serial port, spits these all the time..
			}
			$output =~ s/^(?:\e\[60;D|(?:\e\[m)?\x0d)\e\[K// if $familyType eq $Prm{xos};	# Remove ExtremeXOS escape sequence following more prompt
			$output =~ s/\e\[2J\e\[H//       if $cmd->{noRefreshCmdDone} && $familyType eq $Prm{pers}; # Recover from ExtremeXOS refreshed command
			$output =~ s/\x0d\e\[23A\e\[J/\n/ if $cmd->{noRefreshCmdDone} && $familyType eq $Prm{xos}; # Recover from ExtremeXOS refreshed command
			$output =~ s/$cmd->{more_prompt}(?:\e\[D \e\[D)+//g if $familyType eq $Prm{isw} && $cmd->{more_prompt};	# Remove double --more-- prompt which is not used
			if ($familyType eq $Prm{xirrus}) {
				$output =~ s/\x10?\x00//g; 				# Remove weird chars that WLAN9100 peppers output with, with telnet only, 
											# ...in some case even not at beginning of line..
				$output =~ s/^ ?\x0d *\x0d//;				# Remove WLAN9100 CR+spaces+CR sequence following more prompt
											# .. with telnet, the WLAN9100 echoes back the space which was sent to page
			}
			# Note, order of these matches is important
			$output =~ s/^\x0d+//mg;					# Remove spurious CarriageReturns at beginning of line, a BPS/470 special 
			$output =~ s/\x0d+$//mg;					# Remove spurious CarriageReturns at end of each line, 5500, 4500... 
		}
		$cmd->{lastLine} = stripLastLine(\$output);			# We strip a new lastLine from it

		# Here we either hold data in $output or in $cmd->{lastLine} or both
		$self->debugMsg(8,"\ncmd() Output to keep:\n>", \$output, "<\n") if length $output;
		$self->debugMsg(8,"\ncmd() Lastline stripped:\n>", \$cmd->{lastLine}, "<\n") if length $cmd->{lastLine};

		if (length $output) { # Append output now
			$self->{POLL}{local_buffer} .= $output;			# Append to local_buffer
			$self->{POLL}{output_buffer} .= $output;		# Append to output_buffer as well
		}
		
		# Since some more prompt pattern matches can include an initial \n newline which needs removing, we need lastLine to hold that \n
		if (length $cmd->{lastLine} && $self->{POLL}{local_buffer} =~ s/\n\n$/\n/) { 	# If output had x2 trailing newlines, strip last ...
			$cmd->{lastLine} = "\n" . $cmd->{lastLine}; 	# ... and pre-pend it to lastLine
			$cmd->{outputNewline} = chop $self->{POLL}{output_buffer};	# And chop & store \n from output_buffer
			$newLineLastLine = 1;				# and remember it
			$self->debugMsg(8,"\ncmd() Lastline adjusted:\n>", \$cmd->{lastLine}, "<\n");
		}
		else {
			$cmd->{outputNewline} = '';			# Clear it
			$newLineLastLine = 0;				# Clear it
		}

		next CMDLOOP unless length $cmd->{lastLine};

		if ($cmd->{lastLine} =~ s/($cmd->{prompt})//) {
			my ($cap1, $cap2, $cap3) = ($1, $2, $3); # We need to store these in temporary variables
			$self->_setDevicePrompts(undef, $cap2) if $cmd->{reset_prompt};
			$self->_setLastPromptAndConfigContext($cap1, $cmd->{reset_prompt} ? $cap3 : $cap2);
			unless ($newLineLastLine && !length $cmd->{lastLine}) { # Only if we did not gobble the \n ...
				$self->{POLL}{output_buffer} .= $cmd->{outputNewline}; # ... re-add to output its final \n
			}
			$self->debugMsg(8,"\ncmd() prompt detected; cmd complete!\n");
			last CMDLOOP;
		}
		if ($cmd->{more_prompt_delay} && !$cmd->{morePromptDelayed} && $cmd->{lastLine} =~ /(?:$cmd->{more_prompt_delay})$/) { # We have a more prompt which requires a delay
			$self->debugMsg(8,"\ncmd() more prompt delay pattern detected; forcing 1 cycle readwait\n");
			$cmd->{stage} = 3; # Force a 1 cycle readwait at next cycle
			$cmd->{morePromptDelayed} = 1;	# Make sure we don't come back here at next cycle
			return $self->poll_return(0) unless $self->{POLL}{blocking};
			next CMDLOOP;
		}
		if ($cmd->{more_prompt} && $cmd->{lastLine} =~ s/(?:$cmd->{more_prompt})$//) { # We have a more prompt
			$cmd->{morePromptDelayed} = 0;	# Reset this flag
			if ($cmd->{lastLine} =~ s/^\n//) { # If we did not gobble the \n remove it and re-add it (residual lastLine can still be rolled over)
				$self->{POLL}{local_buffer} .= "\n";
				$self->{POLL}{output_buffer} .= $cmd->{outputNewline} if $newLineLastLine;
			}
			$cmd->{outputNewline} = '' if $newLineLastLine; # Either way (\n gobbled or not) we clear it
			my $char;
			if (defined $MoreSkipWithin{$familyType} && $cmd->{more_pages} == 0) { # On ISW we have an option to skip more paging
				$char = $MoreSkipWithin{$familyType};
				$self->debugMsg(8,"\ncmd() More prompt detected; skipping subsequent by feeding '$char'\n");
			}
			elsif ($cmd->{more_pages} == 0 || $cmd->{more_pages}-- > 1) { # We get the next page
				$char = $Space;
				$self->debugMsg(8,"\ncmd() More prompt detected; feeding 'SPACE'\n");
			}
			else { # We quit here
				$char = 'q';
				$self->debugMsg(8,"\ncmd() More prompt detected; feeding 'Q'\n");
			}
			$self->put(string => $char, errmode => 'return')
				or return $self->poll_return($self->error("$pkgsub: Unable to page at more prompt // ".$self->errmsg));
			return $self->poll_return(0) unless $self->{POLL}{blocking};
			next CMDLOOP;
		}
		if ($cmd->{yn_prompt} && $cmd->{lastLine} =~ /$cmd->{yn_prompt}/) { # We have a Y/N prompt
			if (++$cmd->{ynPromptCount} > $self->{$Package}{cmd_feed_timeout}) {
				return $self->poll_return($self->error("$pkgsub: Y/N confirm prompt timeout"));
			}
			$self->debugMsg(8,"\ncmd() Y/N prompt detected; feeding 'Y'\n");
			$self->print(line => 'y', errmode => 'return')
				or return $self->poll_return($self->error("$pkgsub: Unable to confirm at Y/N prompt // ".$self->errmsg));
			return $self->poll_return(0) unless $self->{POLL}{blocking};
			next CMDLOOP;
		}
		if ($cmd->{cmd_prompt} && $cmd->{lastLine} =~ /$cmd->{cmd_prompt}/) { # We have a prompt for additional input
			# But, this pattern risks matching against transient data; so check if more data coming
			$self->debugMsg(8,"\ncmd() cmd-prompt detected; forcing readwait\n");
			$cmd->{stage} = 2; # Force a readwait at next cycle
			return $self->poll_return(0) unless $self->{POLL}{blocking};
			next CMDLOOP;
		}

		# Having lastLine with \n newline can screw up cleanup patterns above, so after above prompt matching we have it removed here
		$self->{POLL}{local_buffer} .= "\n" if $cmd->{lastLine} =~ s/^\n//; # If it's there we take it off
	}# CMDLOOP
	$self->{POLL}{output_result} = $self->_determineOutcome(\$self->{POLL}{local_buffer}, $cmd->{lastPromptEchoedCmd});
	return $self->poll_return(1);
}


sub poll_attribute { # Method to handle attribute for poll methods (used for both blocking & non-blocking modes)
	my $self = shift;
	my $pkgsub = shift;
	my $pollsub = "${Package}::attribute";

	unless ($self->{POLLING}) { # Sanity check
		my (undef, $fileName, $lineNumber) = caller;
		croak "$pollsub (called from $fileName line $lineNumber) can only be used within polled methods";
	}

	unless (defined $self->{POLL}{$pollsub}) { # Only applicable if called from another method already in polling mode
		my @validArgs = ('attribute', 'reload', 'timeout', 'errmode');
		my %args = parseMethodArgs($pkgsub, \@_, \@validArgs, 1);
		if (@_ && !%args) { # Legacy syntax
			($args{attribute}, $args{reload}, $args{timeout}, $args{errmode}) = @_;
		}
		# In which case we need to setup the poll structure for them here (the main poll structure remains unchanged)
		$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
			# Set method argument keys
			attribute		=>	$args{attribute},
			reload			=>	$args{reload},
			# Declare method storage keys which will be used
			stage			=>	0,
			debugMsg		=>	0,
			# Declare keys to be set if method called from another polled method
			errmode			=>	$args{errmode},
		};
		# Cache poll structure keys which this method will use
		$self->poll_struct_cache($pollsub, $args{timeout});
	}
	my $attrib = $self->{POLL}{$pollsub};
	local $self->{errmode} = $attrib->{errmode} if defined $attrib->{errmode};
	return $self->poll_return($self->error("$pkgsub: No connection for attributes")) if $self->eof;
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';

	if ($attrib->{stage} < 1) { # 1st stage
		return $self->poll_return($self->error("$pkgsub: No attribute provided")) unless defined $attrib->{attribute};
		return $self->poll_return(1) unless $familyType; # Value returned is undef

		$attrib->{stage} += 2; # Assume no login() required and that we move directly to 3rd stage
		if ($attrib->{reload}) { # Force reload, either via forced login() or resetting ATTRIBFLAG
			if ($attrib->{attribute} eq 'family_type' || $attrib->{attribute} eq 'is_nncli' || $attrib->{attribute} eq 'is_acli'
			 || $attrib->{attribute} eq 'is_master_cpu' || $attrib->{attribute} eq 'cpu_slot') {
				$self->print or return $self->poll_return($self->error("$pkgsub: Unable to refresh device connection"));
				$attrib->{stage}--; # Move to 2nd stage
			}
			else {
				$self->{$Package}{ATTRIBFLAG}{$attrib->{attribute}} = undef;
			}
		}
	}

	if ($attrib->{stage} < 2) { # 2nd stage - wait for login to complete
		my $ok = $self->poll_login($pkgsub);
		return $self->poll_return($ok) unless $ok;
		$attrib->{stage}++; # Move to 3rd stage
	}

	if ($attrib->{stage} < 3) { # 3rd stage
		# If the attribute is set already, return it at once and quit
		if (defined $self->{$Package}{ATTRIBFLAG}{$attrib->{attribute}}) {
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		}
		# Go no further if generic family type
		return $self->poll_return(1) if $familyType eq $Prm{generic}; # Value returned is undef
		$attrib->{stage}++; # Move to next stage
	}

	# Otherwise go set the attribute
	if ($familyType eq $Prm{pers}) {
		$attrib->{attribute} eq 'is_ha' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show ha-state', 'show ha-state']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Current CPU State : Disabled State./) {
				$self->_setAttrib('is_ha', 0);
			}
			elsif ($$outref =~ /Current CPU State/) {
				$self->_setAttrib('is_ha', 1);
			}
			else { # For example on ERS8300 or ERS1600
				$self->_setAttrib('is_ha', undef);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'sw_version' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show sys sw', 'show sys software']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Version : Build (?i:v|REL)?(.+?) / && $self->_setAttrib('sw_version', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'fw_version' && do {
			if ($attrib->{stage} < 4) { # 4th stage
				my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show bootconfig info', 'show boot config general']);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				if ($$outref =~ /Version:\s+(?i:v|REL)?(.+)/) {
					$self->_setAttrib('fw_version', $1);
					$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
					return $self->poll_return(1);
				}
				else {
					$attrib->{stage}++; # Move to next stage
					$attrib->{debugMsg} = 0;
				}
			}
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show bootconfig info', 'show boot config info']); # On 8300 it's 'show boot config info'
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Version:\s+(?i:v|REL)?(.+)/) {
				$self->_setAttrib('fw_version', $1);
			}
			else { # VSP9000 has no fw_version (when command executed on standby CPU)
				$self->_setAttrib('fw_version', undef);				
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'stp_mode' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show bootconfig flags', 'show boot config flags'], 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /flags spanning-tree-mode (mstp|rstp)/) {
				$self->_setAttrib('stp_mode', $1);
			}
			else {
				$self->_setAttrib('stp_mode', 'stpg');
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'baudrate' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show bootconfig sio', 'show boot config sio'], 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /sio (?:console )?baud (\d+)/) { # On VSP/8600 it's "sio console baud 9600"; on 8300/1600 "sio baud 9600"
				$self->_setAttrib('baudrate', $1);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'max_baud' && do {
			if ($attrib->{stage} < 4) { # 4th stage
				my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['config bootconfig sio console baud ?', "boot config sio console baud ?$CTRL_C"], undef, 1);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				# VSP9k		:   <9600 - 115200>  Baud rate {9600 | 19200 | 38400 | 57600 | 115200}
				# 8600acli	:   <1200-115200>  Rate
				# 8600ppcli	:<rate>           = what rate {1200..115200}
				if ($$outref =~ /(?:-|\.\.)\s?(\d+)[>}]/) {
					$self->_setAttrib('max_baud', $1);
					$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
					return $self->poll_return(1);
				}
				else {
					$attrib->{stage}++; # Move to next stage
					$attrib->{debugMsg} = 0;
				}
			}
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['config bootconfig sio baud ?', "boot config sio baud ?$CTRL_C"], undef, 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			# 8300nncli	:   <1200-115200>  rate
			# 8300ppcli	:<rate>           = what rate {2400|4800|9600|19200|38400|57600|115200} IN {1200..115200}
			# 1600		:<rate>           = what rate {1200..115200}
			if ($$outref =~ /(?:-|\.\.)\s?(\d+)[>}]/) {
				$self->_setAttrib('max_baud', $1);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		if ($self->{$Package}{ATTRIB}{'is_master_cpu'}) { # On Master CPU
			($attrib->{attribute} eq 'is_dual_cpu' || $attrib->{attribute} eq 'base_mac') && do {
				my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show sys info', 'show sys-info'], 4);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				$$outref =~ /SysDescr\s+: (.+?) \(/g && do {
					my $model = $1; # Record it, we need to set the model type after is_apls
					if ($$outref =~ / BoxType: (.+)/gc) { # APLS boxes show a boxtype on same line
						$self->_setBoxTypeAttrib($1);
						$self->_setAttrib('is_apls', 1);
						$self->_setModelAttrib($model); # Must be set after is_apls so that is_voss gets set as well
					}
					else {
						$self->_setAttrib('apls_box_type', undef);
						$self->_setAttrib('is_apls', 0);
						$self->_setModelAttrib($model);
					}
				};
				$$outref =~ /SysName\s+: (.+)/g && $self->_setAttrib('sysname', $1);
				if ($self->{$Package}{ATTRIB}{'is_voss'}) {
					if ($$outref =~ /BrandName:?\s+: (.+)/gc) { # On VOSS VSPs we read it
						(my $brandname = $1) =~ s/, Inc\.$//; # Remove 'Inc.'
						$brandname =~ s/\.$//; # Remove trailing full stop
						$self->_setAttrib('brand_name', $brandname);
					}
					else { # VSP9000 case, it is_voss, but reports no BrandName, so we set it..
						$self->_setAttrib('brand_name', 'Avaya');
					}
				}
				else { # Non-VOSS PassportERS
					$self->_setAttrib('brand_name', undef);
				}
				$$outref =~ /BaseMacAddr\s+: (.+)/g && $self->_setBaseMacAttrib($1);
				if ($$outref =~ /CP.+ dormant /		# 8600 & VSP9000
				 || ($$outref =~ /\s1\s+\d{4}\S{2}\s+1\s+CPU\s+(?:\d+\s+){4}/ &&
				     $$outref =~ /\s2\s+\d{4}\S{2}\s+1\s+CPU\s+(?:\d+\s+){4}/)	# VSP8600 just check for presence of slot1&2
				  ) {
					$self->_setAttrib('is_dual_cpu', 1);
				}
				else {
					$self->_setAttrib('is_dual_cpu', 0);
				}
				# Attributes below are beyond demanded pages of output, but we still check them in case more paging was disabled
				$$outref =~ /Virtual IP\s+: (.+)/g && $self->_setAttrib('oob_virt_ip', $1);
				$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
				return $self->poll_return(1);
			};
			($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'sysname' || $attrib->{attribute} eq 'is_apls' || $attrib->{attribute} eq 'is_voss' ||
			 $attrib->{attribute} eq 'apls_box_type' || $attrib->{attribute} eq 'brand_name' || # Any new attributes added here, need to be added on exit to this if block below
			 (!$self->{$Package}{ATTRIBFLAG}{'model'} && ($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports')) || # We need 'model' attrib for port/slot ones
			 (!$self->{$Package}{ATTRIBFLAG}{'is_voss'} && $attrib->{attribute} =~ /^(?:is_)?oob_/) # We need 'is_voss' attrib for oob ones
			) && do {
				my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show sys info', 'show sys-info'], 1);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				$$outref =~ /SysDescr\s+: (.+?) \(/g && do {
					my $model = $1; # Record it, we need to set the model type after is_apls
					if ($$outref =~ / BoxType: (.+)/gc) { # APLS boxes show a boxtype on same line
						$self->_setBoxTypeAttrib($1);
						$self->_setAttrib('is_apls', 1);
						$self->_setModelAttrib($model); # Must be set after is_apls so that is_voss gets set as well
					}
					else {
						$self->_setAttrib('apls_box_type', undef);
						$self->_setAttrib('is_apls', 0);
						$self->_setModelAttrib($model);
					}
				};
				$$outref =~ /SysName\s+: (.+)/g && $self->_setAttrib('sysname', $1);
				if ($self->{$Package}{ATTRIB}{'is_voss'}) {
					if ($$outref =~ /BrandName:?\s+: (.+)/gc) { # On VOSS VSPs we read it
						(my $brandname = $1) =~ s/, Inc\.$//; # Remove 'Inc.'
						$brandname =~ s/\.$//; # Remove trailing full stop
						$self->_setAttrib('brand_name', $brandname);
					}
					else { # VSP9000 case, it is_voss, but reports no BrandName, so we set it..
						$self->_setAttrib('brand_name', 'Avaya');
					}
				}
				else { # Non-VOSS PassportERS
					$self->_setAttrib('brand_name', undef);
				}
				$$outref =~ /BaseMacAddr\s+: (.+)/g && $self->_setBaseMacAttrib($1); # Might not match on 8600 as on page 2
				# Attributes below are beyond demanded pages of output, but we still check them in case more paging was disabled
				if ($$outref =~ /CP.+ dormant /		# 8600 & VSP9000
				 || ($$outref =~ /\s1\s+\d{4}\S{2}\s+1\s+CPU\s+(?:\d+\s+){4}/ &&
				     $$outref =~ /\s2\s+\d{4}\S{2}\s+1\s+CPU\s+(?:\d+\s+){4}/)	# VSP8600 just check for presence of slot1&2
				  ) {
					$self->_setAttrib('is_dual_cpu', 1);
				}
				elsif ($$outref =~ /System Error Info :/) { # Output which follows Card Info, i.e. the output was there but no CP dormant matched
					$self->_setAttrib('is_dual_cpu', 0);
				}
				$$outref =~ /Virtual IP\s+: (.+)/g && $self->_setAttrib('oob_virt_ip', $1);
				if ($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'sysname' || $attrib->{attribute} eq 'is_apls' || $attrib->{attribute} eq 'is_voss' ||
				    $attrib->{attribute} eq 'apls_box_type' || $attrib->{attribute} eq 'brand_name') { # Needs to match the same listed on beginning of if block above
					$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
					return $self->poll_return(1);
				}
				else { # If an attribute that just needed 'model', fall through to appropriate section below
					$attrib->{debugMsg} = 0;
				}
			};
			($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
				if ($self->{$Package}{ATTRIB}{'is_nncli'} && $self->{$Package}{ATTRIB}{'model'} =~ /(?:Passport|ERS)-8[36]\d\d/) { # 8300/8600 NNCLI case
					if ($attrib->{stage} < 4) { # 4th stage
						my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show interfaces fastEthernet name']);
						return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
						$self->_setSlotPortAttrib($outref);
						$attrib->{stage}++; # Move to next stage
						$attrib->{debugMsg} = 0;
					}
					my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show interfaces gigabitEthernet name']);
					return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
					$self->_setSlotPortAttrib($outref);
					$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
					return $self->poll_return(1);
				}
				else { # All other cases: 8300/8600/8800 PPCLI, 8800 NNCLI, VSP
					my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show ports info name', 'show interfaces gigabitEthernet high-secure']);
					return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
					$self->_setSlotPortAttrib($outref);
					$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
					return $self->poll_return(1);
				}
			};
			$attrib->{attribute} =~ /^(?:is_)?oob_/ && do {
				if ($self->{$Package}{ATTRIB}{'is_voss'}) { # VSP based PassportERS (VOSS)
					my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show ip interface vrf MgmtRouter']);
					return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
					my ($ip1, $ip2, $ipv);
					$ip1 = $1 if $$outref =~ /Portmgmt\s+ ([\d\.]+)/g;
					$ip1 = $1 if $$outref =~ /Port1\/1\s+ ([\d\.]+)/g;
					$ipv = $1 if $$outref =~ /MgmtVirtIp\s+ ([\d\.]+)/g;
					$ip2 = $1 if $$outref =~ /Port2\/1\s+ ([\d\.]+)/g;
					$ip2 = $1 if $$outref =~ /Portmgmt2\s+ ([\d\.]+)/g;
					if ($self->{$Package}{ATTRIB}{'cpu_slot'} == 1) { # Could be any VSP: 9k, 8k, 4k
						$self->_setAttrib('oob_ip', $ip1);
						$self->_setAttrib('oob_standby_ip', $ip2);
						$self->_setAttrib('oob_virt_ip', $ipv);
					}
					else { # cpu slot = 2 only on VSP9000
						$self->_setAttrib('oob_ip', $ip2);
						$self->_setAttrib('oob_standby_ip', $ip1);
						$self->_setAttrib('oob_virt_ip', $ipv);
					}
					$self->_setAttrib('is_oob_connected', defined $self->socket &&
						( (defined $self->{$Package}{ATTRIB}{'oob_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_ip'}) ||
						  (defined $self->{$Package}{ATTRIB}{'oob_virt_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_virt_ip'}) ) ?
						1 : 0 );
					$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
					return $self->poll_return(1);
				}
				else { # ERS based PassportERS
					if ($attrib->{stage} < 4) { # 4th stage
						my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show sys info', 'show sys-info']);
						return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
						# No need to set Model, Sysname and BaseMAC as we only get here if Model is set
						if ($$outref =~ /CP.+ dormant /		# 8600 & VSP9000
						 || ($$outref =~ /\s1\s+\d{4}\S{2}\s+1\s+CPU\s+(?:\d+\s+){4}/ &&
						     $$outref =~ /\s2\s+\d{4}\S{2}\s+1\s+CPU\s+(?:\d+\s+){4}/)	# VSP8600 just check for presence of slot1&2
						  ) {
							$self->_setAttrib('is_dual_cpu', 1);
						}
						else {
							$self->_setAttrib('is_dual_cpu', 0);
						}
						if ($$outref =~ /Virtual IP\s+: (.+)/g) {
							$self->_setAttrib('oob_virt_ip', $1);
						}
						else { # Not set
							$self->_setAttrib('oob_virt_ip', undef);
						}
						$attrib->{stage}++; # Move to next stage
						$attrib->{debugMsg} = 0;
					}
					my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show bootconfig config', 'show boot config running-config']);
					return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
					my ($ip1, $ip2);
					$ip1 = $1 if $$outref =~ /^net mgmt ip ([\d\.]+)\/[\d\.]+ *(?:cpu-slot [35])?$/m;
					$ip2 = $1 if $$outref =~ /^net mgmt ip ([\d\.]+)\/[\d\.]+ cpu-slot 6$/m;
					if ($self->{$Package}{ATTRIB}{'cpu_slot'} < 5) {
						$self->_setAttrib('oob_ip', $ip1);
						$self->_setAttrib('oob_standby_ip', undef);
					}
					elsif ($self->{$Package}{ATTRIB}{'cpu_slot'} == 5) {
						$self->_setAttrib('oob_ip', $ip1);
						$self->_setAttrib('oob_standby_ip', $self->{$Package}{ATTRIB}{'is_dual_cpu'} ? $ip2 : undef);
					}
					else { # cpu slot = 6
						$self->_setAttrib('oob_ip', $ip2);
						$self->_setAttrib('oob_standby_ip', $self->{$Package}{ATTRIB}{'is_dual_cpu'} ? $ip1 : undef);
					}
					$self->_setAttrib('is_oob_connected', defined $self->socket &&
						( (defined $self->{$Package}{ATTRIB}{'oob_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_ip'}) ||
						  (defined $self->{$Package}{ATTRIB}{'oob_virt_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_virt_ip'}) ) ?
						1 : 0 );
					$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
					return $self->poll_return(1);
				}
			};
		}
		else { # On standby CPU
			($attrib->{attribute} eq 'is_apls') && do { # APLS is never dual_cpu
				$self->_setAttrib('is_apls', 0);
				$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
				return $self->poll_return(1);
			};
			($attrib->{attribute} eq 'is_voss') && do {
				my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['cd /', 'cd /']);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				if ($$outref =~ /Only devices \/intflash/) {
					$self->_setAttrib('is_voss', 1);
				}
				else {
					$self->_setAttrib('is_voss', 0);
				}
				$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
				return $self->poll_return(1);
			};
		}
	}
	elsif ($familyType eq $Prm{bstk}) {
		($attrib->{attribute} eq 'fw_version' || $attrib->{attribute} eq 'sw_version' || $attrib->{attribute} eq 'switch_mode' ||
		 $attrib->{attribute} eq 'unit_number' || $attrib->{attribute} eq 'base_unit' || $attrib->{attribute} eq 'stack_size' ||
		 $attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'sysname' || $attrib->{attribute} eq 'base_mac') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show sys-info']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Operation Mode:\s+(Switch)/g) {
				$self->_setAttrib('switch_mode', $1);
				$self->_setAttrib('unit_number', undef);
				$self->_setAttrib('stack_size', undef);
				$self->_setAttrib('base_unit', undef);
			}
			elsif ($$outref =~ /Operation Mode:\s+(Stack), Unit # (\d)/g) {
				$self->_setAttrib('switch_mode', $1);
				$self->_setAttrib('unit_number', $2);
				$$outref =~ /Size Of Stack:         (\d)/gc; # Use /gc modifier to maintain position at every match
				$self->_setAttrib('stack_size', $1);
				$$outref =~ /Base Unit:             (\d)/gc; # With /gc modifiers, fileds have to be matched in the right order
				$self->_setAttrib('base_unit', $1);
			}
			$$outref =~ /MAC Address:\s+(.+)/gc && $self->_setBaseMacAttrib($1);
			$$outref =~ /sysDescr:\s+(.+?)(?:\n|\s{4})/gc && # Match up to end of line, or 4 or more spaces (old baystacks append FW/SW version here)
				$self->_setModelAttrib($1);
			$$outref =~ /FW:([\d\.]+)\s+SW:v([\d\.]+)/gc && do {
				$self->_setAttrib('fw_version', $1);
				$self->_setAttrib('sw_version', $2);
			};
			$$outref =~ /sysName: +(\S.*)/gc && $self->_setAttrib('sysname', $1); # \S avoids match when field is blank
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show interfaces']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'stp_mode' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show spanning-tree mode']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Current STP Operation Mode: (STPG|MSTP|RSTP)/) {
				$self->_setAttrib('stp_mode', lc($1));
			}
			else { # Older stackables will not know the command and only support stpg
				$self->_setAttrib('stp_mode', 'stpg');
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'mgmt_vlan' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show vlan mgmt']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Management VLAN: (\d+)/ && $self->_setAttrib('mgmt_vlan', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'mgmt_ip' || $attrib->{attribute} eq 'oob_ip' || $attrib->{attribute} eq 'is_oob_connected') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show ip']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /(?:Switch|Stack) IP Address:\s+[\d\.]+\s+([\d\.]+)\s+[\d\.]+/g && $self->_setAttrib('mgmt_ip', $1);
			if ($$outref =~ /Mgmt (?:Switch|Stack) IP Address:\s+[\d\.]+\s+([\d\.]+)\s/g) {
				$self->_setAttrib('oob_ip', $1);
			}
			else { # No OOB port on this device
				$self->_setAttrib('oob_ip', undef);
			}
			$self->_setAttrib('is_oob_connected', defined $self->socket &&
				(defined $self->{$Package}{ATTRIB}{'oob_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_ip'}) ?
				1 : 0 );
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'baudrate' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show terminal']); # Don't need to be in privExec for this
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Terminal speed: (\d+)/) {
				$self->_setAttrib('baudrate', $1);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'max_baud' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ["terminal speed ?$CTRL_C"]); # Don't need to be in privExec for this
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			my $baudRate;
			while ($$outref =~ /^  (\d+)\s*$/mg) {
				$baudRate = $1 if !defined $baudRate || $1 > $baudRate;
			}
			$self->_setAttrib('max_baud', $baudRate);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{sr}) {
		$attrib->{attribute} eq 'model' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show chassis']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Chassis Model: (.+)/ && $self->_setModelAttrib($1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'fw_version' || $attrib->{attribute} eq 'sw_version') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show version']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Runtime: (.+)/g && $self->_setAttrib('sw_version', $1);
			$$outref =~ /Boot: (.+?) / && $self->_setAttrib('fw_version', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			if ($attrib->{stage} < 4) { # 4th stage
				my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show interface ethernets']);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				$self->_setSlotPortAttrib($outref);
				$attrib->{stage}++; # Move to next stage
				$attrib->{debugMsg} = 0;
			}
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show module configuration all']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'sysname' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show hostname']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /HostName: (.+)/g && $self->_setAttrib('sysname', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'base_mac' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show system configuration'], 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Mac Address\s+0x(.+)/g && $self->_setBaseMacAttrib($1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{trpz}) {
		($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'sysname' || $attrib->{attribute} eq 'base_mac') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show system']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Product Name:\s+(.+)/g && $self->_setModelAttrib($1);
			$$outref =~ /System Name:\s+(.+)/g && $self->_setAttrib('sysname', $1);
			$$outref =~ /System MAC:\s+(.+)/g && $self->_setBaseMacAttrib($1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'fw_version' || $attrib->{attribute} eq 'sw_version') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show version']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Version: (.+?) REL/g && $self->_setAttrib('sw_version', $1);
			$$outref =~ /BootLoader:\s+(.+)/ && $self->_setAttrib('fw_version', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show port status']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{xlr}) {
		($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'fw_version' || $attrib->{attribute} eq 'sw_version')&& do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show config'], 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /# box type\s+: (.+)/g && $self->_setModelAttrib($1);
			$$outref =~ /# boot monitor version\s+: v?(.+)/g && $self->_setAttrib('fw_version', $1);
			$$outref =~ /# software version\s+: v?(.+)/g && $self->_setAttrib('sw_version', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'is_dual_cpu' || $attrib->{attribute} eq 'sysname') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show sys info'], 3);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /SysDescr\s+: (.+?) \(/g && $self->_setModelAttrib($1);
			$$outref =~ /SysName\s+: (.+)/g && $self->_setAttrib('sysname', $1);
			if ($$outref =~ /CPU.+ dormant /) {
				$self->_setAttrib('is_dual_cpu', 1);
			}
			else {
				$self->_setAttrib('is_dual_cpu', 0);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show ports info arp']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{xirrus}) {
		($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'base_mac' ||
		 $attrib->{attribute} eq 'fw_version' || $attrib->{attribute} eq 'sw_version')&& do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show system-info']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Model: (.+?),/g && $self->_setModelAttrib($1);
			$$outref =~ /IAPs\s+(.+?)-/g && $self->_setBaseMacAttrib($1);
			$$outref =~ /Boot Loader\s+(.+?) \(.+?\), Build: (.+)/g && $self->_setAttrib('fw_version', "$1-$2");
			$$outref =~ /System Software\s+(.+?) \(.+?\), Build: (.+)/g && $self->_setAttrib('sw_version', "$1-$2");
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'sysname') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show contact-info']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Access Point Hostname\s*(.+)/g && $self->_setAttrib('sysname', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show ethernet']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{xos}) {
		($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'sysname' || $attrib->{attribute} eq 'base_mac')&& do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show switch'], 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /SysName:          (.+)/g && $self->_setAttrib('sysname', $1);
			$$outref =~ /System MAC:       (.+)/g && $self->_setBaseMacAttrib($1);
			$$outref =~ /System Type:      (?:VPEX )?(\S+)( \(Stack\))?/g && $self->_setModelAttrib($1);
			$self->_setAttrib('switch_mode', 'Stack') if defined $2;
			$$outref =~ /Image Booted:     (primary|secondary)/ && do {
				if ($1 eq 'primary') {
					$$outref =~ /Primary ver:      (\S+)/g && $self->_setAttrib('sw_version', $1);
				}
				else { # secondary
					$$outref =~ /Secondary ver:    (\S+)/g && $self->_setAttrib('sw_version', $1);
				}
			};
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'sw_version' || $attrib->{attribute} eq 'fw_version') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show version']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Image   : ExtremeXOS version (.+) by /g && $self->_setAttrib('sw_version', $1);
			$$outref =~ /BootROM : (.+)/g && $self->_setAttrib('fw_version', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show port debounce']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'switch_mode' || $attrib->{attribute} eq 'stack_size' ||
		 $attrib->{attribute} eq 'unit_number' || $attrib->{attribute} eq 'master_unit') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show stacking']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /(?:This node is not in an Active Topology|stacking-support:\s+\w+\s+Disabled|\*[\d:a-f]+  -     Disabled)/) {
				$self->_setAttrib('switch_mode', 'Switch');
				$self->_setAttrib('unit_number', undef);
				$self->_setAttrib('stack_size', undef);
				$self->_setAttrib('master_unit', undef);
			}
			else {
				$self->_setAttrib('switch_mode', 'Stack');
				my $unitCount = 0;
				while ($$outref =~ /([\* ])(?:[\da-f]{2}:){5}[\da-f]{2}  (\d)     \w+\s+(Master|\w+)/g) {
					$unitCount++;
					$self->_setAttrib('unit_number', $2) if $1 eq '*';
					$self->_setAttrib('master_unit', $2) if $3 eq 'Master';
				}
				$self->_setAttrib('stack_size', $unitCount);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'stp_mode') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show stpd s0 | include "Operational Mode"']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Operational Mode: (802.1D|802.1W|MSTP)/) {
				$self->_setAttrib('stp_mode', 'stpg') if $1 eq '802.1D';
				$self->_setAttrib('stp_mode', 'rstp') if $1 eq '802.1W';
				$self->_setAttrib('stp_mode', 'mstp') if $1 eq 'MSTP';
			}
			else { # Instance s0 does not exit ?
				$self->_setAttrib('stp_mode', undef);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'oob_ip' || $attrib->{attribute} eq 'is_oob_connected') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show vlan mgmt | include "Primary IP"']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Primary IP:		 ([\d\.]+)\/\d+/g) {
				$self->_setAttrib('oob_ip', $1);
			}
			else { # No OOB port on this device
				$self->_setAttrib('oob_ip', undef);
			}
			$self->_setAttrib('is_oob_connected', defined $self->socket &&
				(defined $self->{$Package}{ATTRIB}{'oob_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_ip'}) ?
				1 : 0 );
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{isw}) {
		($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'sysname' || $attrib->{attribute} eq 'base_mac' ||
		 $attrib->{attribute} eq 'sw_version')&& do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['do show version']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /MAC Address      : (.+)/g && $self->_setBaseMacAttrib($1);
			$$outref =~ /System Name      : (.+)/g && $self->_setAttrib('sysname', $1);
			$$outref =~ /Product          : (.+)/g && $self->_setModelAttrib($1);
			$$outref =~ /Software Version : V(.+)/g && $self->_setAttrib('sw_version', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['do show interface * veriphy']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortHashAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{s200}) {
		($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'base_mac' || $attrib->{attribute} eq 'sw_version' ||
		 $attrib->{attribute} eq 'fw_version') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show version']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Machine Model\.+ (.+)/g && $self->_setModelAttrib($1);
			$$outref =~ /Burned In MAC Address\.+ (.+)/g && $self->_setBaseMacAttrib($1);
			$$outref =~ /Software Version\.+ (.+)/g && $self->_setAttrib('sw_version', $1);
			$$outref =~ /Operating System\.+ Linux (.+)/g && $self->_setAttrib('fw_version', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'sysname') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show sysinfo'], 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			my ($defSsysname, $setSsysname);
			$$outref =~ /System Description\.+ (.+?)-/g && do {$defSsysname = $1}; # Will use this, if no sysname set on device
			$$outref =~ /System Name\.+ (.+)/g && do {$setSsysname = $1};
			if ($setSsysname) {
				$self->_setAttrib('sysname', $setSsysname);
			}
			elsif ($defSsysname) {
				$self->_setAttrib('sysname', $defSsysname);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show interfaces switchport general']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'switch_mode' || $attrib->{attribute} eq 'stack_size' ||
		 $attrib->{attribute} eq 'unit_number' || $attrib->{attribute} eq 'manager_unit') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show switch']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			my $unitCount = 0;
			while ($$outref =~ /(\d)   (Mgmt Sw|Stack Mbr)\s/g) {
				$unitCount++;
				if ($2 eq 'Mgmt Sw') {
					$self->_setAttrib('unit_number', $1);
					$self->_setAttrib('manager_unit', $1);
				}
			}
			if ($unitCount) {
				$self->_setAttrib('switch_mode', 'Stack');
				$self->_setAttrib('stack_size', $unitCount);
			}
			else {
				$self->_setAttrib('switch_mode', 'Switch');
				$self->_setAttrib('unit_number', undef);
				$self->_setAttrib('stack_size', undef);
				$self->_setAttrib('manager_unit', undef);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'stp_mode') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show spanning-tree active']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Mode: (stp|rstp|mstp)/) {
				$self->_setAttrib('stp_mode', $1 eq 'stp' ? 'stpg' : $1);
			}
			elsif ($$outref =~ /Spanning-tree enabled protocol (pvst|rpvst)/) {
				$self->_setAttrib('stp_mode', $1);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'oob_ip' || $attrib->{attribute} eq 'is_oob_connected') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show serviceport']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /IP Address\.+ (.+)/g) {
				$self->_setAttrib('oob_ip', $1);
			}
			else { # No OOB port on this device
				$self->_setAttrib('oob_ip', undef);
			}
			$self->_setAttrib('is_oob_connected', defined $self->socket &&
				(defined $self->{$Package}{ATTRIB}{'oob_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_ip'}) ?
				1 : 0 );
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'baudrate' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, ['show serial']); # Don't need to be in privExec for this
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Baud Rate \(bps\)\.+ (\d+)/) {
				$self->_setAttrib('baudrate', $1);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'max_baud' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, "line console\nserial baudrate ?$CTRL_U"], undef, 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			my $baudRate;
			while ($$outref =~ /^(\d+)                   Set serial speed to \d+\.$/mg) {
				$baudRate = $1 if !defined $baudRate || $1 > $baudRate;
			}
			$self->_setAttrib('max_baud', $baudRate);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{wing}) {
		($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'base_mac' || $attrib->{attribute} eq 'sw_version' ||
		 $attrib->{attribute} eq 'fw_version' || $attrib->{attribute} eq 'sysname') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show version']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /(\S+) version (.+)/g && do {
				$self->_setModelAttrib($1);
				$self->_setAttrib('sw_version', $2);
				$self->_setAttrib('fw_version', undef);
			};
			$$outref =~ /(\S+) uptime is/g && $self->_setAttrib('sysname', $1);
			$$outref =~ /Base ethernet MAC address is (.+)/g && $self->_setBaseMacAttrib($1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [undef, 'show interface switchport']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'baudrate' || $attrib->{attribute} eq 'max_baud') && do {
			$self->_setAttrib('baudrate', 115200);
			$self->_setAttrib('max_baud', undef);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}
	elsif ($familyType eq $Prm{slx}) {
		($attrib->{attribute} eq 'sysname' || $attrib->{attribute} eq 'base_mac') && do {
			# This command is remarkably slow on SLX, so only use it if we have to
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [($self->config_context ? 'do ':'') . 'show system'], 1);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Stack MAC                     : (.+)/g && $self->_setBaseMacAttrib($1);
			$$outref =~ /Unit Name                     : (.+)/g && $self->_setAttrib('sysname', $1);
			$$outref =~ /SLX-OS Version                : (\d+([rsx])?.+)/g && do {
				$self->_setAttrib('sw_version', $1);
				for my $rsx ('r', 's', 'x') {
					$self->_setAttrib("is_slx_$rsx", $2 eq $rsx ? 1 : undef);
				}
			};
			if ($self->{$Package}{ATTRIBFLAG}{'is_dual_mm'}) {
				$$outref =~ /Management IP                 : (.+)/g &&
					$self->_setAttrib($self->{$Package}{ATTRIB}{'is_dual_mm'} ? 'oob_virt_ip' : 'oob_ip', $1);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'model' || $attrib->{attribute} eq 'switch_type' || $attrib->{attribute} eq 'baudrate') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [($self->config_context ? 'do ':'') . 'show chassis | include "Chassis Name:|switchType:"']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Chassis Name:(?:\t|\e\[\d\w)(?:BR|EN)-(.+)/g && $self->_setModelAttrib($1); # On serial port SLX uses \e[3C instead of tab char
			$self->_setAttrib('baudrate', $self->{$Package}{ATTRIB}{'model'} =~ /9030/ ? 115200 : undef);
			$$outref =~ /switchType: (\d+)/g && $self->_setAttrib('switch_type', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'sw_version' || $attrib->{attribute} eq 'fw_version' || $attrib->{attribute} =~ /^is_slx_[rsx]$/) && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [($self->config_context ? 'do ':'') . 'show version']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /Firmware name:      (\d+([rsx])?.+)/g && do {
				$self->_setAttrib('sw_version', $1);
				for my $rsx ('r', 's', 'x') {
					$self->_setAttrib("is_slx_$rsx", $2 eq $rsx ? 1 : undef);
				}
			};
			$$outref =~ /Kernel:             (.+)/g && $self->_setAttrib('fw_version', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'slots' || $attrib->{attribute} eq 'ports') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [($self->config_context ? 'do ':'') . 'show interface description']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$self->_setSlotPortAttrib($outref);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'is_ha' || $attrib->{attribute} eq 'mm_number' || $attrib->{attribute} eq 'is_dual_mm' ||
		 $attrib->{attribute} eq 'is_active_mm' ||
		 (!$self->{$Package}{ATTRIBFLAG}{'mm_number'} && $attrib->{attribute} =~ /oob/) # We need 'mm_number' attrib for oob ones below
		 ) && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [($self->config_context ? 'do ':'') . 'show ha']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			my ($m1, $m2);
			$$outref =~ /M1: (Active|Standby)/g && do {$m1 = $1};
			$$outref =~ /M2: (Active|Standby)/g && do {$m2 = $1};
			if ($m1 && $m2) {
				$self->_setAttrib('is_ha', 1);
				$self->_setAttrib('mm_number', $m1 ? 1 : 2);
				$self->_setAttrib('is_dual_mm', 1);
				$self->_setAttrib('is_active_mm', 1);
			}
			else {
				$self->_setAttrib('is_ha', $m1 || $m2 ? 0 : undef);
				$self->_setAttrib('mm_number', $m2 ? 2 : $m1 ? 1 : 0);
				$self->_setAttrib('is_dual_mm', 0);
				$self->_setAttrib('is_active_mm', 1);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'stp_mode') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [($self->config_context ? 'do ':'') . 'show spanning-tree brief | include "Spanning-tree Mode:"']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			if ($$outref =~ /Spanning-tree Mode: (.+)/g) {
				$self->_setAttrib('stp_mode', 'mstp') if $1 == 'Multiple Spanning Tree Protocol';
				$self->_setAttrib('stp_mode', 'rstp') if $1 == 'Rapid Spanning Tree Protocol';
				$self->_setAttrib('stp_mode', 'stpg') if $1 == 'Spanning Tree Protocol';
				$self->_setAttrib('stp_mode', 'pvst') if $1 == 'Per-VLAN Spanning Tree Protocol';
				$self->_setAttrib('stp_mode', 'rpvst') if $1 == 'Rapid Per-VLAN Spanning Tree Protocol';
			}
			else {
				$self->_setAttrib('stp_mode', undef);
			}
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		($attrib->{attribute} eq 'oob_ip' || $attrib->{attribute} eq 'oob_standby_ip' || $attrib->{attribute} eq 'is_oob_connected') && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [($self->config_context ? 'do ':'') . 'show interface Management']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			for my $i (1..2) { # Do this twice
				$$outref =~ /interface Management (\d)/g && do {
					my $mslot = $1;
					$$outref =~ /ip address \"static (.+)\//g &&
						$self->_setAttrib($mslot == $self->{$Package}{ATTRIB}{'mm_number'} ? 'oob_ip' : 'oob_standby_ip', $1);
				};
			}
			$self->_setAttrib('is_oob_connected', defined $self->socket &&
				( (defined $self->{$Package}{ATTRIB}{'oob_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_ip'}) ||
				  (defined $self->{$Package}{ATTRIB}{'oob_virt_ip'} && $self->socket->peerhost eq $self->{$Package}{ATTRIB}{'oob_virt_ip'}) ) ?
				1 : 0 );
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
		$attrib->{attribute} eq 'oob_virt_ip' && do {
			my ($ok, $outref) = $self->_attribExecuteCmd($pkgsub, $attrib, [($self->config_context ? 'do ':'') . 'show chassis virtual-ip']);
			return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			$$outref =~ /chassis virtual-ip \"static (.+)\//g && $self->_setAttrib('oob_virt_ip', $1);
			$self->{POLL}{output_result} = $self->{$Package}{ATTRIB}{$attrib->{attribute}};
			return $self->poll_return(1);
		};
	}

	return $self->poll_return(1); # Undefined output_result for unrecognized attributes
}


sub poll_change_baudrate { # Method to handle change_baudrate for poll methods (used for both blocking & non-blocking modes)
	my $self = shift;
	my $pkgsub = shift;
	my $pollsub = "${Package}::change_baudrate";

	unless ($self->{POLLING}) { # Sanity check
		my (undef, $fileName, $lineNumber) = caller;
		croak "$pollsub (called from $fileName line $lineNumber) can only be used within polled methods";
	}

	unless (defined $self->{POLL}{$pollsub}) { # Only applicable if called from another method already in polling mode
		my @validArgs = ('baudrate', 'timeout', 'errmode', 'forcebaud');
		my %args = parseMethodArgs($pkgsub, \@_, \@validArgs, 1);
		if (@_ && !%args) { # Legacy syntax
			($args{baudrate}, $args{timeout}, $args{errmode}) = @_;
		}
		# In which case we need to setup the poll structure for them here (the main poll structure remains unchanged)
		$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
			# Set method argument keys
			baudrate		=>	$args{baudrate},
			parity			=>	undef,
			databits		=>	undef,
			stopbits		=>	undef,
			handshake		=>	undef,
			forcebaud		=>	$args{forcebaud},
			local_side_only		=>	0, # For that functionality, just call Control::CLI's poll_change_baudrate
			# Declare method storage keys which will be used
			stage			=>	0,
			userExec		=>	undef,
			privExec		=>	undef,
			maxMode			=>	$args{baudrate} eq 'max' ? 1:0,
			# Declare keys to be set if method called from another polled method
			errmode			=>	$args{errmode},
		};
		# Cache poll structure keys which this method will use
		$self->poll_struct_cache($pollsub, $args{timeout});
	}
	my $changeBaud = $self->{POLL}{$pollsub};
	local $self->{errmode} = $changeBaud->{errmode} if defined $changeBaud->{errmode};
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';

	if ($changeBaud->{local_side_only}) { # Same functionality as Control::CLI::change_baudrate()
		my $ok = $self->SUPER::poll_change_baudrate($pkgsub,
			BaudRate	=> $changeBaud->{baudrate},
			Parity		=> $changeBaud->{parity},
			DataBits	=> $changeBaud->{databits},
			StopBits	=> $changeBaud->{stopbits},
			Handshake	=> $changeBaud->{handshake},
			ForceBaud	=> $changeBaud->{forcebaud},
		);
		return $self->poll_return($ok); # Come out if error (if errmode='return'), or if nothing to read in non-blocking mode, or completed
	}

	if ($changeBaud->{stage} < 1) { # 1st stage
		unless ($self->connection_type eq 'SERIAL') {
			return $self->poll_return($self->error("$pkgsub: Cannot change baudrate on Telnet/SSH"));
		}
		unless (defined $self->baudrate) { # If no active connection come out
			return $self->poll_return($self->error("$pkgsub: No serial connection established yet"));
		}
		unless (defined $changeBaud->{baudrate}) {
			return $self->poll_return($self->error("$pkgsub: No baudrate specified!"));
		}
		unless ($familyType) {
			return $self->poll_return($self->error("$pkgsub: Family type of remote device is not detected"));
		}
		$changeBaud->{stage}++; # Move to 2nd stage
	}

	if ($changeBaud->{stage} < 2) { # 2nd stage
		unless (defined $self->{$Package}{ATTRIB}{'baudrate'}) { # Make sure this attribute is set
			my $ok = $self->poll_attribute($pkgsub, 'baudrate');
			return $self->poll_return($ok) unless $ok;
		}
		unless (defined $self->{$Package}{ATTRIB}{'baudrate'}) {
			return $self->poll_return($self->error("$pkgsub: Baudrate cannot be changed on device")) unless $changeBaud->{maxMode};
			$self->debugMsg(4,"ChangeBaudrate: baudrate attrib undefined - maxMode return success\n");
			$self->{POLL}{output_result} = $changeBaud->{baudrate};
			return $self->poll_return(1);	# Can't maximize baudrate, but no error in maxMode
		}
		unless (defined $self->{$Package}{ATTRIB}{'max_baud'}) { # Make sure this attribute is set
			my $ok = $self->poll_attribute($pkgsub, 'max_baud');
			return $self->poll_return($ok) unless $ok;
		}
		if ($changeBaud->{maxMode} && !defined $self->{$Package}{ATTRIB}{'max_baud'}) {
			$self->debugMsg(4,"ChangeBaudrate: max_baud attrib undefined - maxMode return success\n");
			$self->{POLL}{output_result} = $changeBaud->{baudrate};
			return $self->poll_return(1);	# Can't maximize baudrate, but no error in maxMode
		}
		$changeBaud->{baudrate} = $self->{$Package}{ATTRIB}{'max_baud'} if $changeBaud->{maxMode};

		if ($changeBaud->{baudrate} == $self->baudrate) { # Desired baudrate is already set
			$self->{POLL}{output_result} = $changeBaud->{baudrate};
			return $self->poll_return(1);
		}

		# Now, depending on family type of connected device, ensure we change the baud rate on the device first
		if ($familyType eq $Prm{generic}) {
			return $self->poll_return($self->error("$pkgsub: Unable to complete on $Prm{generic} family_type device"));
		}
		elsif ($familyType eq $Prm{bstk}) {
			unless ($changeBaud->{baudrate} == 9600 || $changeBaud->{baudrate} == 19200 || $changeBaud->{baudrate} == 38400) {
				return $self->poll_return($self->error("$pkgsub: Supported baud rates for $Prm{bstk} = 9600, 19200, 38400"));
			}
		}
		elsif ($familyType eq $Prm{pers}) {
			unless ($changeBaud->{baudrate} == 9600 || $changeBaud->{baudrate} == 19200 || $changeBaud->{baudrate} == 38400 ||
				$changeBaud->{baudrate} == 57600 || $changeBaud->{baudrate} == 115200) {
				return $self->poll_return($self->error("$pkgsub: Supported baud rates for $Prm{pers} = 9600, 19200, 38400, 57600, 115200"));
			}
		}
		elsif ($familyType eq $Prm{s200}) {
			unless ($changeBaud->{baudrate} == 9600 || $changeBaud->{baudrate} == 19200 || $changeBaud->{baudrate} == 38400 ||
				$changeBaud->{baudrate} == 57600 || $changeBaud->{baudrate} == 115200) {
				return $self->poll_return($self->error("$pkgsub: Supported baud rates for $Prm{s200} = 9600, 19200, 38400, 57600, 115200"));
			}
		}
		else { # Other family types not supported
			return $self->poll_return($self->error("$pkgsub: Only supported on $Prm{pers} and $Prm{bstk} family_type")) unless $changeBaud->{maxMode};
			$self->debugMsg(4,"ChangeBaudrate: Not $Prm{pers} or $Prm{bstk} family_type - maxMode return success\n");
			$self->{POLL}{output_result} = $changeBaud->{baudrate};
			return $self->poll_return(1);	# Can't maximize baudrate, but no error in maxMode
		}
		$changeBaud->{stage}++; # Move to 3rd stage
	}

	if ($changeBaud->{stage} < 3) { # 3rd stage
		if ($familyType eq $Prm{pers}) {
			unless (defined $self->{$Package}{ATTRIB}{'model'}) { # Make sure this attribute is set
				my $ok = $self->poll_attribute($pkgsub, 'model');
				return $self->poll_return($ok) unless $ok;
			}
			if ($changeBaud->{userExec} = $self->last_prompt =~ />\s?$/) {
				my $ok = $self->poll_enable($pkgsub);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			}
		}
		elsif ($familyType eq $Prm{s200}) {
			if ($changeBaud->{userExec} = $self->last_prompt =~ />\s?$/) {
				my $ok = $self->poll_enable($pkgsub);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
			}
		}
		$changeBaud->{stage}++; # Move to 4th stage
	}

	if ($changeBaud->{stage} < 4) { # 4th stage
		if ($familyType eq $Prm{pers} && $self->{$Package}{ATTRIB}{'is_nncli'}) {
			if ($changeBaud->{privExec} = !$self->config_context) {
				my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, 'config term');
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				return $self->poll_return($self->error("$pkgsub: Unable to set new baud rate on device")) unless $$resref;
			}
		}
		elsif ($familyType eq $Prm{s200}) {
			if ($changeBaud->{privExec} = !$self->config_context) {
				my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, "config\nline console");
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				return $self->poll_return($self->error("$pkgsub: Unable to set new baud rate on device")) unless $$resref;
			}
		}
		$changeBaud->{stage}++; # Move to 5th stage
	}

	if ($changeBaud->{stage} < 5) { # 5th stage
		if ($familyType eq $Prm{bstk}) {
			$self->print(line => "terminal speed $changeBaud->{baudrate}", errmode => 'return')
				or return $self->poll_return($self->error("$pkgsub: Unable to set new baud rate on device // ".$self->errmsg));
		}
		elsif ($familyType eq $Prm{pers}) {
			if ($self->{$Package}{ATTRIB}{'model'}  =~ /(?:Passport|ERS)-(?:83|16)\d\d/) { # 8300 & 1600
				if ($self->{$Package}{ATTRIB}{'is_nncli'}) {
					$self->print(line => "boot config sio baud $changeBaud->{baudrate}", errmode => 'return')
						or return $self->poll_return($self->error("$pkgsub: Unable to set new baud rate on device // ".$self->errmsg));
				}
				else {
					$self->print(line => "config bootconfig sio baud $changeBaud->{baudrate}", errmode => 'return')
						or return $self->poll_return($self->error("$pkgsub: Unable to set new baud rate on device // ".$self->errmsg));
				}
			}
			else { # All other PassportERS devices
				if ($self->{$Package}{ATTRIB}{'is_nncli'}) {
					$self->print(line => "boot config sio console baud $changeBaud->{baudrate}", errmode => 'return')
						or return $self->poll_return($self->error("$pkgsub: Unable to set new baud rate on device // ".$self->errmsg));
				}
				else {
					$self->print(line => "config bootconfig sio console baud $changeBaud->{baudrate}", errmode => 'return')
						or return $self->poll_return($self->error("$pkgsub: Unable to set new baud rate on device // ".$self->errmsg));
				}
			}
		}
		elsif ($familyType eq $Prm{s200}) {
			$self->print(line => "serial baudrate $changeBaud->{baudrate}", errmode => 'return')
				or return $self->poll_return($self->error("$pkgsub: Unable to set new baud rate on device // ".$self->errmsg));
		}
		$self->debugMsg(4,"ChangeBaudrate: set device to ", \$changeBaud->{baudrate}, "\n");
		$changeBaud->{stage}++; # Move to 6th stage
	}

	if ($changeBaud->{stage} < 6) { # 6th stage
		my $ok = $self->poll_readwait($pkgsub, 0);
		return $self->poll_return($ok) unless $ok; # Come out if error, or if nothing to read in non-blocking mode
		if (length $self->{POLL}{read_buffer} && $self->{POLL}{read_buffer} =~ /$self->{$Package}{prompt_qr}/) {
			# This is a failure, as it would imply that we can see a prompt back, even though we changed the baudrate on the device
			return $self->poll_return($self->error("$pkgsub: Baudrate change had no effect on device; still at $self->baudrate baud")) unless $changeBaud->{maxMode};
			$self->debugMsg(4,"ChangeBaudrate: Baudrate change had no effect on device - maxMode return success\n");
			$self->{POLL}{output_result} = $self->baudrate;
			return $self->poll_return(1);	# Can't maximize baudrate, but no error in maxMode
		}
		if (defined $self->{$Package}{ORIGBAUDRATE}) { # Clear note following restore
			$self->{$Package}{ORIGBAUDRATE} = undef if $self->{$Package}{ORIGBAUDRATE} == $changeBaud->{baudrate};
		}
		else { # 1st time this method is run, make a note of original baudrate (needed in DESTROY)
			$self->{$Package}{ORIGBAUDRATE} = $self->baudrate;
		}
		$changeBaud->{stage}++; # Move to 7th stage
	}

	if ($changeBaud->{stage} < 7) { # 7th stage
		my $ok = $self->SUPER::poll_change_baudrate($pkgsub,
			BaudRate	=> $changeBaud->{baudrate},
			ForceBaud	=> $changeBaud->{forcebaud},
		);
		return $self->poll_return($ok) unless $ok; # Come out if error (if errmode='return'), or if nothing to read in non-blocking mode
		$self->debugMsg(4,"ChangeBaudrate: changed local serial port to ", \$changeBaud->{baudrate}, "\n");
		$self->_setAttrib('baudrate', $changeBaud->{baudrate});	# Adjust the attribute as we are sure we changed it now
		$changeBaud->{stage}++; # Move to 8th stage
	}

	if ($changeBaud->{stage} < 8) { # 8th stage
		my $ok = $self->poll_cmd($pkgsub, ''); # Send carriage return + ensure we get valid prompt back
		return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
		$changeBaud->{stage}++; # Move to 9th stage
	}

	if ($changeBaud->{stage} < 9) { # 9th stage
		if ( ($familyType eq $Prm{pers} && $self->{$Package}{ATTRIB}{'is_nncli'}) || $familyType eq $Prm{s200}) {
			if ($changeBaud->{privExec}) {
				my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, 'end');
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				return $self->poll_return($self->error("$pkgsub: Error while changing baud rate")) unless $$resref;
			}
		}
		$changeBaud->{stage}++; # Move to 10th stage
	}

	if ($changeBaud->{stage} < 10) { # 10th stage
		$changeBaud->{stage}++; # Move to 1th stage
		if ( ($familyType eq $Prm{pers} && $self->{$Package}{ATTRIB}{'is_nncli'}) || $familyType eq $Prm{s200}) {
			if ($changeBaud->{userExec}) {
				my $disableCmd;
				if (defined $ExitPrivExec{$familyType}) {
					$disableCmd = $ExitPrivExec{$familyType};
					$self->put($disableCmd);
				}
				else {
					$disableCmd = 'disable';
					$self->print($disableCmd);
				}
				$self->debugMsg(8,"\npoll_change_baudrate() Sending command:>", \$disableCmd, "<\n");
			}
		}
	}
	if ($changeBaud->{stage} < 11) { # 11th stage
		if ( ($familyType eq $Prm{pers} && $self->{$Package}{ATTRIB}{'is_nncli'}) || $familyType eq $Prm{s200}) {
			if ($changeBaud->{userExec}) {
				my ($ok, undef, $resref) = $self->poll_cmd($pkgsub);
				return $self->poll_return($ok) unless $ok; # Come out if error or if not done yet in non-blocking mode
				return $self->poll_return($self->error("$pkgsub: Error while changing baud rate")) unless $$resref;
			}
		}
	}
	$self->{POLL}{output_result} = $changeBaud->{baudrate};
	return $self->poll_return(1);
}


sub poll_enable { # Method to handle enable for poll methods (used for both blocking & non-blocking modes)
	my $self = shift;
	my $pkgsub = shift;
	my $pollsub = "${Package}::enable";

	unless ($self->{POLLING}) { # Sanity check
		my (undef, $fileName, $lineNumber) = caller;
		croak "$pollsub (called from $fileName line $lineNumber) can only be used within polled methods";
	}

	unless (defined $self->{POLL}{$pollsub}) { # Only applicable if called from another method already in polling mode
		my @validArgs = ('password', 'prompt_credentials', 'timeout', 'errmode');
		my %args = parseMethodArgs($pkgsub, \@_, \@validArgs, 1);
		if (@_ && !%args) { # Legacy syntax
			($args{password}, $args{prompt_credentials}, $args{timeout}, $args{errmode}) = @_;
		}
		# In which case we need to setup the poll structure for them here (the main poll structure remains unchanged)
		$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
			# Set method argument keys
			enable_password		=>	defined $args{password} ? $args{password} : $self->{$Package}{ENABLEPWD},
			prompt_credentials	=>	defined $args{prompt_credentials} ? $args{prompt_credentials} : $self->{prompt_credentials},
			# Declare method storage keys which will be used
			stage			=>	0,
			login_attempted		=>	undef,
			login_failed		=>	undef,
			# Declare keys to be set if method called from another polled method
			errmode			=>	$args{errmode},
		};
		# Cache poll structure keys which this method will use
		$self->poll_struct_cache($pollsub, $args{timeout});
	}
	my $enable = $self->{POLL}{$pollsub};
	local $self->{errmode} = $enable->{errmode} if defined $enable->{errmode};
	return $self->poll_return($self->error("$pkgsub: No connection to enable")) if $self->eof;
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';
	my $prompt = $self->{$Package}{prompt_qr};
	my $passwordPrompt = $self->{password_prompt_qr};
	my $enablePwd;

	if ($enable->{stage} < 1) { # 1st stage
		$enable->{stage}++; # Ensure we don't come back here in non-blocking mode
		return $self->poll_return($self->error("$pkgsub: No connection established")) unless $familyType;
		return $self->poll_return(1) unless $self->{$Package}{ATTRIB}{'is_nncli'}; # Come out if not in NNCLI mode
		return $self->poll_return(1) unless $self->last_prompt =~ />\s?$/; # Come out if not in UserExec mode
		# Flush any unread data which might be pending
		$self->read(blocking => 0);
		# Send enable command
		$self->print(line => 'enable', errmode => 'return')
			or return $self->poll_return($self->error("$pkgsub: Unable to send CLI command: enable // ".$self->errmsg));
	}

	# Main loop
	do {
		my $ok = $self->poll_read($pkgsub, 'Failed after enable command');
		return $self->poll_return($ok) unless $ok;

		$self->{POLL}{local_buffer} .= $self->{POLL}{read_buffer};
		$enable->{login_failed}++ if $self->{POLL}{local_buffer} =~ /error: Access denied/;
		if ($self->{POLL}{local_buffer} =~ /$passwordPrompt/) { # Handle password prompt
			$enable->{login_attempted}++;
			if (defined $enable->{enable_password}) { # An enable password is supplied
				if ($enable->{login_attempted} == 1) {	# First try; use supplied
					$enablePwd = $enable->{enable_password};
					$self->debugMsg(4,"enable() Sending supplied password\n");
					$self->print(line => $enablePwd, errmode => 'return')
						or return $self->poll_return($self->error("$pkgsub: Unable to send enable password // ".$self->errmsg));
				}
				else {				# Next tries, enter blanks
					$enablePwd = '';
					$self->debugMsg(4,"enable() Sending carriage return instead of supplied password\n");
					$self->print(errmode => 'return')
						or return $self->poll_return($self->error("$pkgsub: Unable to send blank password // ".$self->errmsg));
				}
			}
			else { # No password supplied
				if ($enable->{login_attempted} == 1) {	# First try; use blank
					$enablePwd = '';
					$self->debugMsg(4,"enable() Sending carriage return for password\n");
					$self->print(errmode => 'return')
						or return $self->poll_return($self->error("$pkgsub: Unable to send blank password // ".$self->errmsg));
				}
				elsif ($enable->{login_attempted} == 2) {	# Second try; use cached login password
					$enablePwd = $self->password || '';
					$self->debugMsg(4,"enable() Sending login password for enable password\n");
					$self->print(line => $enablePwd, errmode => 'return')
						or return $self->poll_return($self->error("$pkgsub: Unable to send cached password // ".$self->errmsg));
				}
				else {				# Third try; prompt?
					if ($enable->{prompt_credentials}) {
						$enablePwd = promptCredential($enable->{prompt_credentials}, 'Hide', 'Enable Password');
						$self->print(line => $enablePwd, errmode => 'return')
							or return $self->poll_return($self->error("$pkgsub: Unable to send enable password // ".$self->errmsg));
					}
					else {			# Enter blanks
						$enablePwd = '';
						$self->debugMsg(4,"enable() Sending carriage return instead of prompting for password\n");
						$self->print(errmode => 'return')
							or return $self->poll_return($self->error("$pkgsub: Unable to send blank password // ".$self->errmsg));
					}
				}
			}
			$self->{POLL}{local_buffer} = '';
		}
	} until ($self->{POLL}{local_buffer} =~ /($prompt)/);
	$self->_setLastPromptAndConfigContext($1, $2);
	return $self->poll_return($self->error("$pkgsub: Password required")) if $enable->{login_failed};
	return $self->poll_return($self->error("$pkgsub: Failed to enter PrivExec mode")) if $self->last_prompt =~ />\s?$/; # If still in UserExec mode
	$self->{$Package}{ENABLEPWD} = $enablePwd if defined $enablePwd;
	return $self->poll_return(1);
}


sub poll_device_more_paging { # Method to handle device_more_paging for poll methods (used for both blocking & non-blocking modes)
	my $self = shift;
	my $pkgsub = shift;
	my $pollsub = "${Package}::device_more_paging";

	unless ($self->{POLLING}) { # Sanity check
		my (undef, $fileName, $lineNumber) = caller;
		croak "$pollsub (called from $fileName line $lineNumber) can only be used within polled methods";
	}

	unless (defined $self->{POLL}{$pollsub}) { # Only applicable if called from another method already in polling mode
		my @validArgs = ('enable', 'timeout', 'errmode');
		my %args = parseMethodArgs($pkgsub, \@_, \@validArgs, 1);
		if (@_ && !%args) { # Legacy syntax
			($args{enable}, $args{timeout}, $args{errmode}) = @_;
		}
		# In which case we need to setup the poll structure for them here (the main poll structure remains unchanged)
		$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
			# Set method argument keys
			enable			=>	$args{enable},
			# Declare method storage keys which will be used
			stage			=>	0,
			cmdString		=>	undef,
			# Declare keys to be set if method called from another polled method
			errmode			=>	$args{errmode},
		};
		# Cache poll structure keys which this method will use
		$self->poll_struct_cache($pollsub, $args{timeout});
	}
	my $devMorePage = $self->{POLL}{$pollsub};
	local $self->{errmode} = $devMorePage->{errmode} if defined $devMorePage->{errmode};
	return $self->poll_return($self->error("$pkgsub: No connection to set more paging on")) if $self->eof;
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';

	return $self->poll_return($self->error("$pkgsub: No connection established")) unless $familyType;
	return $self->poll_return(1) if $familyType eq $Prm{isw};
	if ($familyType eq $Prm{bstk}) {
		$devMorePage->{cmdString} = $devMorePage->{enable} ? 23 : 0 unless defined $devMorePage->{cmdString};
		my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, "terminal length $devMorePage->{cmdString}");
		return $self->poll_return($ok) unless $ok;
		return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
	}
	elsif ($familyType eq $Prm{pers} || $familyType eq $Prm{xlr}) {
		if ($self->{$Package}{ATTRIB}{'is_nncli'}) { # NNCLI
			if ($devMorePage->{stage} < 1) {
				unless (defined $self->{$Package}{ATTRIB}{'model'}) { # This attribute may not yet be set
					my $ok = $self->poll_attribute($pkgsub, 'model');
					return $self->poll_return($ok) unless $ok;
				}
				if (defined $self->{$Package}{ATTRIB}{'model'} && $self->{$Package}{ATTRIB}{'model'} =~ /(?:Passport|ERS)-83\d\d/) { # 8300 NNCLI
					$devMorePage->{stage} += 2; # Go to section after next
				}
				else { # NNCLI on 8600 or VSP (or if 'model' is not defined we could be on a Standby CPU of 8600 or VSP or 8300..)
					$devMorePage->{stage}++; # Go to next section
				}
			}
			if ($devMorePage->{stage} < 2) { # NNCLI on 8600 or VSP (or if 'model' is not defined we could be on a Standby CPU of 8600 or VSP or 8300..)
				$devMorePage->{cmdString} = $devMorePage->{enable} ? 'enable' : 'disable' unless defined $devMorePage->{cmdString};
				my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, "terminal more $devMorePage->{cmdString}");
				return $self->poll_return($ok) unless $ok;
				return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) if !$$resref && defined $self->{$Package}{ATTRIB}{'model'};
				$devMorePage->{stage}++; # Go to next section (8300) if we failed here and 'model' attrib not defined
				$devMorePage->{stage}++ if $$resref; # Skip next section if we succeded
				$devMorePage->{cmdString} = undef;
			}
			if ($devMorePage->{stage} < 3) { # 8300 NNCLI
				$devMorePage->{cmdString} = $devMorePage->{enable} ? '' : 'no ' unless defined $devMorePage->{cmdString};
				my ($ok, undef, $resref) = $self->cmdConfig($pkgsub, '', "$devMorePage->{cmdString}more");
				return $self->poll_return($ok) unless $ok;
				return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
			}
		}
		else { # CLI
			$devMorePage->{cmdString} = $devMorePage->{enable} ? 'true' : 'false' unless defined $devMorePage->{cmdString};
			my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, "config cli more $devMorePage->{cmdString}");
			return $self->poll_return($ok) unless $ok;
			return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
		}
	}
	elsif ($familyType eq $Prm{sr}) {
		$devMorePage->{cmdString} = $devMorePage->{enable} ? 23 : 0 unless defined $devMorePage->{cmdString};
		my ($ok, undef, $resref) = $self->cmdConfig($pkgsub, '', "terminal length $devMorePage->{cmdString}");
		return $self->poll_return($ok) unless $ok;
		return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
	}
	elsif ($familyType eq $Prm{trpz}) {
		$devMorePage->{cmdString} = $devMorePage->{enable} ? 23 : 0 unless defined $devMorePage->{cmdString};
		my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, "set length $devMorePage->{cmdString}");
		return $self->poll_return($ok) unless $ok;
		return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
	}
	elsif ($familyType eq $Prm{xirrus}) {
		$devMorePage->{cmdString} = $devMorePage->{enable} ? 'enable' : 'disable' unless defined $devMorePage->{cmdString};
		my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, "more $devMorePage->{cmdString}");
		return $self->poll_return($ok) unless $ok;
		return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
	}
	elsif ($familyType eq $Prm{xos}) {
		$devMorePage->{cmdString} = $devMorePage->{enable} ? 'enable' : 'disable' unless defined $devMorePage->{cmdString};
		my ($ok, undef, $resref) = $self->poll_cmd($pkgsub, "$devMorePage->{cmdString} clipaging");
		return $self->poll_return($ok) unless $ok;
		return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
	}
	elsif ($familyType eq $Prm{s200}) {
		$devMorePage->{cmdString} = $devMorePage->{enable} ? '24' : '0' unless defined $devMorePage->{cmdString};
		my ($ok, undef, $resref) = $self->cmdPrivExec($pkgsub, undef, "terminal length $devMorePage->{cmdString}");
		return $self->poll_return($ok) unless $ok;
		return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
	}
	elsif ($familyType eq $Prm{wing}) {
		$devMorePage->{cmdString} = $devMorePage->{enable} ? '24' : '0' unless defined $devMorePage->{cmdString};
		my ($ok, undef, $resref) = $self->cmdPrivExec($pkgsub, undef, ($self->config_context ? 'do ':'') . "terminal length $devMorePage->{cmdString}");
		return $self->poll_return($ok) unless $ok;
		return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
	}
	elsif ($familyType eq $Prm{slx}) {
		$devMorePage->{cmdString} = $devMorePage->{enable} ? 'no length' : 'length 0' unless defined $devMorePage->{cmdString};
		my ($ok, undef, $resref) = $self->cmdPrivExec($pkgsub, undef, ($self->config_context ? 'do ':'') . "terminal $devMorePage->{cmdString}");
		return $self->poll_return($ok) unless $ok;
		return $self->poll_return($self->error("$pkgsub: Failed to set more-paging mode")) unless $$resref;
	}
	else {
		return $self->poll_return($self->error("$pkgsub: Cannot configure more paging on family type $familyType"));
	}
	return $self->poll_return(1);
}


sub poll_device_peer_cpu { # Method to handle device_peer_cpu for poll methods (used for both blocking & non-blocking modes)
	my $self = shift;
	my $pkgsub = shift;
	my $pollsub = "${Package}::device_peer_cpu";

	unless ($self->{POLLING}) { # Sanity check
		my (undef, $fileName, $lineNumber) = caller;
		croak "$pollsub (called from $fileName line $lineNumber) can only be used within polled methods";
	}

	unless (defined $self->{POLL}{$pollsub}) { # Only applicable if called from another method already in polling mode
		my @validArgs = ('username', 'password', 'prompt_credentials', 'timeout', 'errmode');
		my %args = parseMethodArgs($pkgsub, \@_, \@validArgs, 1);
		if (@_ && !%args) { # Legacy syntax
			($args{username}, $args{password}, $args{prompt_credentials}, $args{timeout}, $args{errmode}) = @_;
		}
		# In which case we need to setup the poll structure for them here (the main poll structure remains unchanged)
		$self->{POLL}{$pollsub} = { # Populate structure with method arguments/storage
			# Set method argument keys
			username		=>	defined $args{username} ? $args{username} : $self->username,
			password		=>	defined $args{password} ? $args{password} : $self->password,
			prompt_credentials	=>	defined $args{prompt_credentials} ? $args{prompt_credentials} : $self->{prompt_credentials},
			# Declare method storage keys which will be used
			stage			=>	0,
			# Declare keys to be set if method called from another polled method
			errmode			=>	$args{errmode},
		};
		# Cache poll structure keys which this method will use
		$self->poll_struct_cache($pollsub, $args{timeout});
	}
	my $devPeerCpu = $self->{POLL}{$pollsub};
	local $self->{errmode} = $devPeerCpu->{errmode} if defined $devPeerCpu->{errmode};
	return $self->poll_return($self->error("$pkgsub: No connection established")) if $self->eof;
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';

	if ($devPeerCpu->{stage} < 1) { # 1st stage
		unless ($familyType) {
			return $self->poll_return($self->error("$pkgsub: Attribute family_type not set"));
		}
		unless ($familyType eq $Prm{pers}) {
			return $self->poll_return($self->error("$pkgsub: No peer CPU on family_type $familyType"));
		}
		unless (($devPeerCpu->{username} && $devPeerCpu->{password}) || $devPeerCpu->{prompt_credentials}) {
			return $self->poll_return($self->error("$pkgsub: Username & password required"));
		}
		$devPeerCpu->{stage}++; # Move to 2nd stage
	}

	if ($devPeerCpu->{stage} < 2) { # 2nd stage
		my $ok = $self->poll_enable($pkgsub); # If in nncli mode, need to be in PrivExec
		return $self->poll_return($ok) unless $ok;

		$self->print(line => 'peer telnet', errmode => 'return')
			or return $self->poll_return($self->error("$pkgsub: Unable to send peer telnet command // ".$self->errmsg));
		$devPeerCpu->{stage}++; # Move to 3rd stage
	}

	if ($devPeerCpu->{stage} < 3) { # 3rd stage
		my $ok = $self->poll_waitfor($pkgsub, 'Login: $', undef, 'return');
		return $self->poll_return($self->error("$pkgsub: Never got peer login prompt // ".$self->errmsg)) unless defined $ok;
		return $self->poll_return($ok) unless $ok;

		$devPeerCpu->{username} = promptCredential($devPeerCpu->{prompt_credentials}, 'Clear', 'Username') unless defined $devPeerCpu->{username};
		$self->print(line => $devPeerCpu->{username}, errmode => 'return')
			or return $self->poll_return($self->error("$pkgsub: Unable to send username // ".$self->errmsg));
		$devPeerCpu->{stage}++; # Move to 4th stage
	}

	if ($devPeerCpu->{stage} < 4) { # 4th stage
		my $ok = $self->poll_waitfor($pkgsub, 'Password: $', undef, 'return');
		return $self->poll_return($self->error("$pkgsub: Never got peer password prompt // ".$self->errmsg)) unless defined $ok;
		return $self->poll_return($ok) unless $ok;

		$devPeerCpu->{password} = promptCredential($devPeerCpu->{prompt_credentials}, 'Hide', 'Password') unless defined $devPeerCpu->{password};
		$self->print(line => $devPeerCpu->{password}, errmode => 'return')
			or return $self->poll_return($self->error("$pkgsub: Unable to send password // ".$self->errmsg));
		$devPeerCpu->{stage}++; # Move to last stage
	}

	# Use cmd() to expect a new prompt now
	my $ok = $self->poll_cmd($pkgsub, More_pages => 0, Reset_prompt => 1);
	return $self->poll_return($ok) unless $ok;

	$self->{LASTPROMPT} =~ /$InitPrompt{$self->{$Package}{PROMPTTYPE}}/;
	$self->_setAttrib('cpu_slot', $2);
	$self->_setAttrib('is_master_cpu', $self->{LASTPROMPT} =~ /^@/ ? 0 : 1);
	$self->_setAttrib('is_dual_cpu', 1) if $self->{LASTPROMPT} =~ /^@/;
	return $self->poll_return(1);
}


sub cmdPrivExec { # If nncli send command in PrivExec mode and restore mode on exit; if not nncli just sends command; used for show commands
	my ($self, $pkgsub, $cmdcli, $cmdnncli, $morePages) = @_;
	my $pollsub = "${Package}::cmdPrivExec";
	my ($ok, $outref, $resref);

	unless (defined $self->{POLL}{$pollsub}) { # Create polling structure on 1st call
		$self->{POLL}{$pollsub} = {
			stage		=>	0,
			userExec	=>	undef,
			outref		=>	undef,
			resref		=>	undef,
		};
	}
	my $cmdPrivExec = $self->{POLL}{$pollsub};
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';

	if ($self->{$Package}{ATTRIB}{'is_nncli'}) {
		if ($cmdPrivExec->{stage} < 1) { # 1st stage
			if ($cmdPrivExec->{userExec} = $self->last_prompt =~ />\s?$/) {
				$ok = $self->poll_enable($pkgsub);
				return $ok unless $ok;
			}
			$cmdPrivExec->{stage}++; # Move to 2nd stage
		}
		if ($cmdPrivExec->{stage} < 2) { # 2nd stage
			($ok, $outref, $resref) = $self->poll_cmd($pkgsub, Command => $cmdnncli, More_pages => $morePages);
			return $ok unless $ok;
			$cmdPrivExec->{outref} = $outref;
			$cmdPrivExec->{resref} = $resref;
			$cmdPrivExec->{stage}++; # Move to 3rd stage
		}
		if ($cmdPrivExec->{stage} < 3) { # 3rd stage
			$cmdPrivExec->{stage}++; # Move to 4th stage - we only spend one cycle here
			if ($cmdPrivExec->{userExec}) {
				my $disableCmd;
				if (defined $ExitPrivExec{$familyType}) {
					$disableCmd = $ExitPrivExec{$familyType};
					$self->put($disableCmd);
				}
				else {
					$disableCmd = 'disable';
					$self->print($disableCmd);
				}
				$self->debugMsg(8,"\ncmdPrivExec() Sending command:>", \$disableCmd, "<\n");
			}
		}
		if ($cmdPrivExec->{stage} < 4) { # 4th stage
			if ($cmdPrivExec->{userExec}) {
				($ok, undef, $resref) = $self->poll_cmd($pkgsub);
				return $ok unless $ok;
				return ($ok, undef, $resref) unless $$resref;
			}
			($outref, $resref) = ($cmdPrivExec->{outref}, $cmdPrivExec->{resref});
			$self->{POLL}{$pollsub} = undef;	# Undef once completed
			return (1, $outref, $resref);
		}
	}
	else {
		($ok, $outref, $resref) = $self->poll_cmd($pkgsub, Command => $cmdcli, More_pages => $morePages);
		return $ok unless $ok;
		$self->{POLL}{$pollsub} = undef;	# Undef once completed
		return (1, $outref, $resref);
	}
}


sub cmdConfig { # If nncli send command in Config mode and restore mode on exit; if not nncli just sends command; used for config commands
	my ($self, $pkgsub, $cmdcli, $cmdnncli) = @_;
	my $pollsub = "${Package}::cmdConfig";
	my ($ok, $outref, $resref);

	unless (defined $self->{POLL}{$pollsub}) { # Create polling structure on 1st call
		$self->{POLL}{$pollsub} = {
			stage		=>	0,
			userExec	=>	undef,
			privExec	=>	undef,
			outref		=>	undef,
			resref		=>	undef,
		};
	}
	my $cmdConfig = $self->{POLL}{$pollsub};
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';

	if ($self->{$Package}{ATTRIB}{'is_nncli'}) {
		if ($cmdConfig->{stage} < 1) { # 1st stage
			if ($cmdConfig->{userExec} = $self->last_prompt =~ />\s?$/) {
				$ok = $self->poll_enable($pkgsub);
				return $ok unless $ok;
			}
			$cmdConfig->{stage}++; # Move to 2nd stage
		}
		if ($cmdConfig->{stage} < 2) { # 2nd stage
			if ($cmdConfig->{privExec} = !$self->config_context) { # This needs to match '(config[-if])' or SecureRouter '/configure' or '(conf-if..)' SLX
				my $configCmd = $familyType eq 'WLAN9100' || $familyType eq 'Series200' ? 'config' : 'config term';
				($ok, undef, $resref) = $self->poll_cmd($pkgsub, $configCmd);
				return $ok unless $ok;
				return ($ok, undef, $resref) unless $$resref;
			}
			$cmdConfig->{stage}++; # Move to 3rd stage
		}
		if ($cmdConfig->{stage} < 3) { # 3rd stage
			($ok, $outref, $resref) = $self->poll_cmd($pkgsub, $cmdnncli);
			return $ok unless $ok;
			$cmdConfig->{outref} = $outref;
			$cmdConfig->{resref} = $resref;
			$cmdConfig->{stage}++; # Move to 4th stage
		}
		if ($cmdConfig->{stage} < 4) { # 4th stage
			if ($cmdConfig->{privExec}) {
				($ok, undef, $resref) = $self->poll_cmd($pkgsub, 'end');
				return $ok unless $ok;
				return ($ok, undef, $resref) unless $$resref;
			}
			$cmdConfig->{stage}++; # Move to 5th stage
		}
		if ($cmdConfig->{stage} < 5) { # 5th stage
			$cmdConfig->{stage}++; # Move to 6th stage - we only spend one cycle here
			if ($cmdConfig->{userExec}) {
				my $disableCmd;
				if (defined $ExitPrivExec{$familyType}) {
					$disableCmd = $ExitPrivExec{$familyType};
					$self->put($disableCmd);
				}
				else {
					$disableCmd = 'disable';
					$self->print($disableCmd);
				}
				$self->debugMsg(8,"\cmdConfig() Sending command:>", \$disableCmd, "<\n");
			}
		}
		if ($cmdConfig->{stage} < 6) { # 6th stage
			if ($cmdConfig->{userExec}) {
				($ok, undef, $resref) = $self->poll_cmd($pkgsub);
				return $ok unless $ok;
				return ($ok, undef, $resref) unless $$resref;
			}
			($outref, $resref) = ($cmdConfig->{outref}, $cmdConfig->{resref});
			$self->{POLL}{$pollsub} = undef;	# Undef once completed
			return (1, $outref, $resref);
		}
	}
	else {
		$cmdcli = "config $cmdcli" unless $cmdcli =~ /^config /; # Prepend config if not already there
		($ok, $outref, $resref) = $self->poll_cmd($pkgsub, $cmdcli);
		return $ok unless $ok;
		$self->{POLL}{$pollsub} = undef;	# Undef once completed
		return (1, $outref, $resref);
	}
}


sub discoverDevice { # Issues CLI commands to host, to determine what family type it belongs to
	my ($self, $pkgsub) = @_;
	my $pollsub = "${Package}::discoverDevice";

	unless (defined $self->{POLL}{$pollsub}) { # Create polling structure on 1st call
		$self->{POLL}{$pollsub} = {
			stage		=>	0,
		};
	}
	my $discDevice = $self->{POLL}{$pollsub};

	if ($discDevice->{stage} < 1) { # Initial loginstage checking - do only once
		$discDevice->{stage}++; # Ensure we don't come back here in non-blocking mode
		$self->debugMsg(4,"\nATTEMPTING EXTENDED DISCOVERY OF HOST DEVICE !\n");
		# Output from commands below is prone to false triggers on the generic prompt;
		# On top of that, the 1st prompt received from login() can be "spoilt" with extra character pre-pended (SLX does that).
	}
	if ($discDevice->{stage} < 2) { # Get a fresh new prompt
		# .. so we get a fresh new promp
		my $ok = $self->poll_cmd($pkgsub, '');	# Send just carriage return
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		# .. and we lock it down to the minimum length required
		$self->last_prompt =~ /(.*)([\?\$%#>]\s?)$/;
		$self->prompt(join('', ".{", length($1), ",}\\$2\$"));
	}

	# Prefer commands unique to platform, and with small output (not more paged)

	if ($discDevice->{stage} < 3) { # Next stage
		# BaystackERS detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show ip address');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /\s+Configured\s+In Use\s+Last BootP/) {
			$self->_setFamilyTypeAttrib($Prm{bstk}, is_nncli => 1);
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{bstk}}/;
			$self->_setDevicePrompts($Prm{bstk}, $1);
			return (1, $Prm{bstk});
		}
	}
	if ($discDevice->{stage} < 4) { # Next stage
		# PassportERS-nncli detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show basic config');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^\s+auto-recover-delay :/m) {
			$self->_setFamilyTypeAttrib($Prm{pers}, is_nncli => 1, is_master_cpu => 1);
			$self->{LASTPROMPT} =~ /$InitPrompt{"$Prm{pers}_nncli"}/;
			$self->_setDevicePrompts("$Prm{pers}_nncli", $1);
			return (1, $Prm{pers});
		}
	}
	if ($discDevice->{stage} < 5) { # Next stage
		# SLX detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, ($self->config_context ? 'do ':'') . 'show chassis | include "Chassis Name:|switchType:"');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^Chassis Name:(?:\t|\e\[\d\w)(?:BR|EN)-(.+)/m) { # On serial port SLX uses \e[3C instead of tab char
			my $model = $1;
			$self->_setFamilyTypeAttrib($Prm{slx}, is_nncli => 1, is_slx => 1);
			$self->_setModelAttrib($model);
			$self->_setAttrib('baudrate', $self->{$Package}{ATTRIB}{'model'} =~ /9030/ ? 115200 : undef);
			$self->_setAttrib('switch_type', $1) if	$$outref =~ /switchType: (\d+)/g;
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{slx}}/;
			$self->_setDevicePrompts($Prm{slx}, $1);
			return (1, $Prm{slx});
		}
	}
	if ($discDevice->{stage} < 6) { # Next stage
		# ExtremeXOS detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show version | include XOS');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^Image   : ExtremeXOS version (.+) by /m) {
			$self->_setFamilyTypeAttrib($Prm{xos}, is_nncli => 0, is_xos => 1, sw_version => $1);
			$self->_setAttrib('fw_version', $1) if $$outref =~ /^BootROM :(.+)$/m;
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{xos}}/;
			$self->_setDevicePrompts($Prm{xos}, $1);
			return (1, $Prm{xos});
		}
	}
	if ($discDevice->{stage} < 7) { # Next stage
		# ISW detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'do show version | include ISW'); # Must add do, as we may be in config mode
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^Product          : (.+)(?:, PoE Switch)?/m) {
			my $model = $1;
			$self->_setFamilyTypeAttrib($Prm{isw}, is_nncli => 1, is_isw => 1, baudrate => 115200);
			$self->_setModelAttrib($model);
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{isw}}/;
			$self->_setDevicePrompts($Prm{isw}, $1);
			return (1, $Prm{isw});
		}
	}
	if ($discDevice->{stage} < 8) { # Next stage
		# Wing detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show version | include version|Extreme|MAC|uptime');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^(\S+) version (.+)\nCopyright \(c\) [\d-]+ Extreme Networks/m) {
			my $model = $1;
			$self->_setFamilyTypeAttrib($Prm{wing}, is_nncli => 1, is_wing => 1, baudrate => 115200, sw_version => $2, fw_version => undef);
			$self->_setModelAttrib($model);
			$self->_setAttrib('sysname', $1) if $$outref =~ /^(\S+) uptime is/m;
			$self->_setBaseMacAttrib($1) if $$outref =~ /^Base ethernet MAC address is (.+)$/m;
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{wing}}/;
			$self->_setDevicePrompts($Prm{wing}, $1);
			return (1, $Prm{wing});
		}
	}
	if ($discDevice->{stage} < 9) { # Next stage
		# Series200 detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show slot');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^\d(?:\/\d)?\s+\S+\s+\S+\s+\S+\s+Extreme\s+(\S+)/m) {
			my $model = $1;
			$self->_setFamilyTypeAttrib($Prm{s200}, is_nncli => 1);
			$self->_setModelAttrib($model);
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{s200}}/;
			$self->_setDevicePrompts($Prm{s200}, $1);
			return (1, $Prm{s200});
		}
	}
	if ($discDevice->{stage} < 10) { # Next stage
		# PassportERS-cli detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show bootconfig info');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^Version:\s+(?i:v|REL)?(.+)/m) {
			my $version = $1;
			$self->_setFamilyTypeAttrib($Prm{pers}, is_nncli => 0, is_master_cpu => 1);
			$self->_setAttrib('fw_version', $version);
			$self->{LASTPROMPT} =~ /$InitPrompt{"$Prm{pers}_cli"}/;
			$self->_setDevicePrompts("$Prm{pers}_cli", $1);
			return (1, $Prm{pers});
		}
	}
	if ($discDevice->{stage} < 11) { # Next stage
		# WLAN 9100 detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show contact-info');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^Access Point Hostname\s*(.+)$/m) {
			my $sysname = $1;
			$self->_setFamilyTypeAttrib($Prm{xirrus}, is_nncli => 1);
			$self->_setAttrib('sysname', $sysname);
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{xirrus}}/;
			$self->_setDevicePrompts($Prm{xirrus}, $1);
			return (1, $Prm{xirrus});
		}
	}
	if ($discDevice->{stage} < 12) { # Next stage
		# Secure Router detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show chassis');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^Chassis Model: (.+)$/m) {
			my $model = $1;
			$self->_setFamilyTypeAttrib($Prm{sr}, is_nncli => 1);
			$self->_setModelAttrib($model);
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{sr}}/;
			$self->_setDevicePrompts($Prm{sr}, $1);
			return (1, $Prm{sr});
		}
	}
	if ($discDevice->{stage} < 13) { # Next stage
		# WLAN 2300 detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show system');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /Product Name:\s+(.+)/g) {
			my $model = $1;
			$self->_setFamilyTypeAttrib($Prm{trpz}, is_nncli => 1);
			$self->_setModelAttrib($model);
			$$outref =~ /System Name:\s+(.+)/g && $self->_setAttrib('sysname', $1);
			$$outref =~ /System MAC:\s+(.+)/g && $self->_setBaseMacAttrib($1);
			$self->{LASTPROMPT} =~ /$InitPrompt{$Prm{trpz}}/;
			$self->_setDevicePrompts($Prm{trpz}, $1);
			return (1, $Prm{trpz});
		}
	}
	if ($discDevice->{stage} < 14) { # Next stage
		# Accelar detection command
		my ($ok, $outref) = $self->poll_cmd($pkgsub, 'show sys perf');
		return $ok unless $ok;
		$discDevice->{stage}++; # Move to next stage on next cycle
		if ($$outref =~ /^\s+NVRamSize:/m) {
			$self->_setFamilyTypeAttrib($Prm{xlr}, is_nncli => 0, is_master_cpu => 1);
			$self->{$Package}{PROMPTTYPE} = $Prm{xlr};
			$self->_setDevicePrompts($Prm{xlr}, $1);
			return (1, $Prm{xlr});
		}
	}

	# We give up; set as generic device
	$self->_setFamilyTypeAttrib($Prm{generic}, is_nncli => 0);
	$self->_setDevicePrompts($Prm{generic});
	return (1, $Prm{generic});
}


sub debugMsg { # Print a debug message
	my $self = shift;
	if (shift() & $self->{debug}) {
		my $string1 = shift();
		my $stringRef = shift() || \"";#" Ultraedit hack!
		my $string2 = shift() || "";
		if ($self->{$Package}{DEBUGLOGFH}) {
			print {$self->{$Package}{DEBUGLOGFH}} $string1, $$stringRef, $string2;
		}
		else {
			print $string1, $$stringRef, $string2;
		}
	}
	return;
}


########################################## Internal Private Methods ##########################################

sub _attribExecuteCmd { # Executes commands for attribute retrieval
	my ($self, $pkgsub, $attrib, $cmd, $pages, $cmdConfig) = @_;

	unless ($attrib->{debugMsg}) {
		my $cmdInfo = $#$cmd ? $cmd->[$self->{$Package}{ATTRIB}{'is_nncli'}] : $cmd->[0];
		my $pageInfo = defined $pages ? "($pages pages)" : '';
		$self->debugMsg(4,"Seeking attribute $attrib->{attribute} value by issuing command: ", \$cmdInfo, " $pageInfo\n");
		$attrib->{debugMsg} = 1;
	}
	return $self->cmdConfig($pkgsub, $cmd->[0], $cmd->[1]) if $#$cmd && $cmdConfig;
	return $self->cmdPrivExec($pkgsub, $cmd->[0], $cmd->[1], $pages) if $#$cmd;
	return $self->poll_cmd($pkgsub, $cmd->[0], $pages);
}


sub _setDevicePrompts { # Steps to set the actual device prompt & more prompt
	my ($self, $keyType, $actualPrompt) = @_;
	my $setPrompt;

	if (defined $keyType) {
		$self->{$Package}{PROMPTTYPE} = $keyType;
		$self->debugMsg(4,"setDevicePrompts() Prompt type = $self->{$Package}{PROMPTTYPE}\n");
	}
	else {
		$keyType = $self->{$Package}{PROMPTTYPE};
	}
	$setPrompt = $Prompt{$keyType};
	if ($actualPrompt) { # Generic prompt will skip this
		# If Perl's metacharacters are used in the switch prompt, backslash them not to mess up prompt regex
		$actualPrompt =~ s/([\{\}\[\]\(\)\^\$\.\|\*\+\?\\])/\\$1/g;
		$setPrompt =~ s/SWITCHNAME/$actualPrompt/;
		$self->debugMsg(4,"setDevicePrompts() Embedding in prompt switch name = '$actualPrompt'\n");
	}
	$self->prompt($setPrompt);
	$self->more_prompt($MorePrompt{$keyType}, defined $MorePromptDelay{$keyType} ? $MorePromptDelay{$keyType} : undef);
	$self->no_refresh_cmd($RefreshCommands{$keyType}{pattern}, $RefreshCommands{$keyType}{send}) if defined $RefreshCommands{$keyType};
	return;
}


sub _setLastPromptAndConfigContext { # Sets the LASTPROMPT and package CONFIGCONTEXT keys
	my ($self, $capturedPrompt, $configContext) = @_;
	($self->{LASTPROMPT} = $capturedPrompt) =~ s/$LastPromptClense//o;
	$self->debugMsg(4,"_setLastPromptAndConfigContext() LASTPROMPT = >$self->{LASTPROMPT}<\n");
	if (defined $configContext) {
		$self->{$Package}{CONFIGCONTEXT} = $configContext;
	}
	else { # With generic prompt or the one used by discoverDevice() it will be undefined, so we need extract it from last prompt
		my $match;
		for my $regex (@PromptConfigContext) {
			if ($self->{LASTPROMPT} =~ /$regex/) {
				$self->{$Package}{CONFIGCONTEXT} = $1;
				$match = 1;
				last;
			}
		}
		$self->{$Package}{CONFIGCONTEXT} = '' unless $match;
	}
	$self->debugMsg(4,"_setLastPromptAndConfigContext() CONFIGCONTEXT = >$self->{$Package}{CONFIGCONTEXT}<\n");
}


sub _setFamilyTypeAttrib { # Set family_type attribute and other related settings
	my ($self, $family, %attribList) = @_;
	$self->_setAttrib('family_type', $family);
	if (defined $Attribute{$family}) {
		$self->_setAttrib('all', [@{$Attribute{Global}}, @{$Attribute{$family}}]);
		$self->debugMsg(4,"Attribute - all = Global + $family attributes\n");
	}
	else {
		$self->_setAttrib('all', $Attribute{Global});
		$self->debugMsg(4,"Attribute - all = Global only\n");
	}
	if (%attribList) { # Set other fixed value attributes
		foreach my $attrib (keys %attribList) {
			$self->_setAttrib($attrib, $attribList{$attrib});
		}
	}
	return;
}


sub _setSlotPortAttrib { # Set the Slot & Port attributes
	my ($self, $outref) = @_;
	my (@slots, @ports, $currentSlot);
	# Get current attribute if partly stored
	@slots = @{$self->{$Package}{ATTRIB}{'slots'}} if $self->{$Package}{ATTRIBFLAG}{'slots'};
	@ports = @{$self->{$Package}{ATTRIB}{'ports'}} if $self->{$Package}{ATTRIBFLAG}{'ports'};
	while ($$outref =~ /^(?:\s*|interface\s+ethernet|Eth )?(?:(\d{1,3})[\/:])?((?:\d{1,3}|(?:gig|ge|fe)\d|s\d)(?:\/\d{1,2})?)/mg) {
		if (defined $1 && (!defined $currentSlot || $1 != $currentSlot)) { # New slot
			$currentSlot = $1;
			push(@slots, $currentSlot) unless grep {$_ eq $currentSlot} @slots;
		}
		if (defined $currentSlot) {
			push(@{$ports[$currentSlot]}, $2) unless grep {$_ eq $2} @{$ports[$currentSlot]};
		}
		else {
			push(@ports, $2) unless grep {$_ eq $2} @ports;
		}
	}
	@slots = sort {$a <=> $b} @slots; # Slots might need re-arranging on older swithes with fastEther & gigEther ports 
	$self->_setAttrib('slots', \@slots);
	$self->_setAttrib('ports', \@ports);
	return;
}


sub _setSlotPortHashAttrib { # Set the Slot & Port attributes where the port attribute is a hash (not an array)
	my ($self, $outref) = @_;
	my (@slots, %ports, $currentHash);
	# Get current attribute if partly stored
	@slots = @{$self->{$Package}{ATTRIB}{'slots'}} if $self->{$Package}{ATTRIBFLAG}{'slots'};
	%ports = %{$self->{$Package}{ATTRIB}{'ports'}} if $self->{$Package}{ATTRIBFLAG}{'ports'};
	while ($$outref =~ /^(FastEthernet|GigabitEthernet) (\d\/\d{1,2})/mg) {
		if (!defined $currentHash || $1 ne $currentHash) { # New hash
			$currentHash = $1;
			push(@slots, $currentHash) unless grep {$_ eq $currentHash} @slots;
		}
		push(@{$ports{$currentHash}}, $2) unless grep {$_ eq $2} @{$ports{$currentHash}};
	}
	@slots = sort {$a cmp $b} @slots; # Slots might need re-arranging on older swithes with fastEther & gigEther ports 
	$self->_setAttrib('slots', \@slots);
	$self->_setAttrib('ports', \%ports);
	return;
}


sub _setModelAttrib { # Set & re-format the Model attribute
	my ($self, $model) = @_;

	$model =~ s/\s+$//; # Remove trailing spaces
	$model =~ s/^\s+//; # Remove leading spaces

	if ($self->{$Package}{ATTRIB}{'family_type'} eq $Prm{bstk}) {
		# Try and reformat the model number into something like ERS-5510
		$model =~ s/Ethernet Routing Switch /ERS-/;
		$model =~ s/Ethernet Switch /ES-/;
		$model =~ s/Business Policy Switch /BPS-/;
		$model =~ s/Wireless LAN Controller WC/WC-/;
		$model =~ s/Virtual Services Platform /VSP-/;
		$model =~ s/(-\d{3,})([A-Z])/$1-$2/;
	}
	elsif ($self->{$Package}{ATTRIB}{'family_type'} eq $Prm{pers}) {
		$model =~ s/(-\d{3,})([A-Z])/$1-$2/;
	}
	elsif ($self->{$Package}{ATTRIB}{'family_type'} eq $Prm{sr}) {
		# Try and reformat the model number into something like SR-4134
		$model =~ s/SR(\d+)/SR-$1/;		# From show chassis
		$model =~ s/Secure Router /SR-/;	# From banner
	}
	elsif ($self->{$Package}{ATTRIB}{'family_type'} eq $Prm{trpz}) {
		# Try and reformat the model number into something like WSS-2380
		$model = 'WSS-' . $model;
	}
	elsif ($self->{$Package}{ATTRIB}{'family_type'} eq $Prm{xirrus}) {
		# Try and reformat the model number into something like WAP-9132
		$model =~ s/(\D+)(\d+)/$1-$2/;		# From show chassis
	}
	elsif ($self->{$Package}{ATTRIB}{'family_type'} eq $Prm{isw}) {
		# Try and reformat the model number into something like ISW_8-10/100P_4-SFP
		$model =~ s/, (?:PoE )?Switch$//;
		$model =~ s/ /_/g;		# From: ISW 8-10/100P, 4-SFP
		$model =~ s/,//g;		# From: ISW_8-10/100P_4-SFP
	}
	elsif ($self->{$Package}{ATTRIB}{'is_apls'}) {
		# Try and reformat from DSG6248CFP to DSG-6248-CFP
		$model =~ s/^([A-Z]{3})(\d{3,})/$1-$2/;
		$model =~ s/(-\d{3,})([A-Z])/$1-$2/;
	}
	$self->_setAttrib('model', $model);

	# VOSS is a PassportERS with a VSP model name
	if ($self->{$Package}{ATTRIB}{'family_type'} eq $Prm{pers}) {
		if ($self->{$Package}{ATTRIB}{'is_apls'} || $model =~ /^(?:VSP|XA)/) { # Requires is_apls to always be set before is_voss
			$self->_setAttrib('is_voss', 1);
		}
		else {
			$self->_setAttrib('is_voss', 0);
		}
	}
	return;
}


sub _setBoxTypeAttrib { # Set & re-format the APLS BoxType attribute
	my ($self, $boxType) = @_;

	$boxType =~ s/\s+$//; # Remove trailing spaces
	$boxType =~ s/^\s+//; # Remove leading spaces

	$boxType =~ s/^([A-Z]{3})(\d{3,})/$1-$2/;
	$boxType =~ s/(-\d{3,})([A-Z])/$1-$2/;
	$self->_setAttrib('apls_box_type', $boxType);
	return;
}


sub _setBaseMacAttrib { # Set & re-format the Base_Mac attribute
	my ($self, $mac) = @_;

	$mac =~ s/\s+$//; # Remove trailing spaces
	$mac =~ s/^\s+//; # Remove leading spaces

	# Reformat the MAC from xx:xx:xx:xx:xx:xx to xx-xx-xx-xx-xx-xx
	$mac =~ s/:/-/g;

	# Reformat the MAC from xxxxxxxxxxxx to xx-xx-xx-xx-xx-xx
	$mac =~ s/([\da-f]{2})([\da-f]{2})([\da-f]{2})([\da-f]{2})([\da-f]{2})([\da-f]{2})/$1-$2-$3-$4-$5-$6/;

	$self->_setAttrib('base_mac', $mac);
	return;
}


sub _setAttrib { # Set attribute
	my ($self, $attrib, $value) = @_;
	if ($attrib eq 'is_nncli' || $attrib eq 'is_acli') {
		$self->{$Package}{ATTRIB}{'is_nncli'} = $value;
		$self->{$Package}{ATTRIBFLAG}{'is_nncli'} = 1;
		$self->{$Package}{ATTRIB}{'is_acli'} = $value;
		$self->{$Package}{ATTRIBFLAG}{'is_acli'} = 1;
	}
	else {
		$self->{$Package}{ATTRIB}{$attrib} = $value;
		$self->{$Package}{ATTRIBFLAG}{$attrib} = 1;
	}
	if (defined $value) {
		$self->debugMsg(4,"Attribute - $attrib => $value\n");
	}
	else {
		$self->debugMsg(4,"Attribute - $attrib => undef\n");
	}
	return;
}


sub _determineOutcome { # Determine if an error message was returned by host
	my ($self, $outref, $lastPromptEchoedCmd) = @_;
	my $familyType;

	return unless $familyType = $self->{$Package}{ATTRIB}{'family_type'};
	return if $familyType eq $Prm{generic};
	if ($$outref =~ /$ErrorPatterns{$familyType}/m) {
		(my $errmsg = $1) =~ s/\x07//g; # Suppress bell chars if any
		$self->debugMsg(4,"\ncmd() Detected error message from host:\n", \$errmsg, "\n");
		$self->{$Package}{last_cmd_errmsg} = $lastPromptEchoedCmd . $errmsg;
		return $self->{$Package}{last_cmd_success} = 0;
	}
	else {
		return $self->{$Package}{last_cmd_success} = 1;
	}
}


sub _restoreDeviceBaudrate { # Check done in disconnect and DESTROY to restore device baudrate before quiting
	my $self = shift;
	my $familyType = $self->{$Package}{ATTRIB}{'family_type'} || '';
	# If change_bauderate() was called and serial connection still up...
	if (defined $self->baudrate && defined (my $origBaud = $self->{$Package}{ORIGBAUDRATE}) ) {
		# ...try and restore original baudrate on device before quiting
		if ($familyType eq $Prm{bstk}) {
			$self->errmode('return');
			$self->put($CTRL_C);
			$self->print("terminal speed $origBaud");
		}
		elsif ($familyType eq $Prm{pers}) {
			$self->errmode('return');
			if ($self->{$Package}{ATTRIB}{'is_nncli'}) {
				$self->printlist('enable', 'config term', "boot config sio console baud $origBaud");
			}
			else {
				$self->print("config bootconfig sio console baud $origBaud");
			}
		}
	}
	return 1;
}


sub _printDot {
	local $| = 1; # Flush STDOUT buffer
	print '.';
	return;
}


1;
__END__;


######################## User Documentation ##########################
## To format the following documentation into a more readable format,
## use one of these programs: perldoc; pod2man; pod2html; pod2text.

=head1 NAME

Control::CLI::Extreme - Interact with CLI of Extreme Networking products over any of Telnet, SSH or Serial port

=head1 SYNOPSIS

	use Control::CLI::Extreme;

=head2 Connecting with Telnet

	# Create the object instance for Telnet
	$cli = new Control::CLI::Extreme('TELNET');
	# Connect to host
	$cli->connect(	Host		=> 'hostname',
			Username	=> $username,
			Password	=> $password,
		     );

=head2 Connecting with SSH - password authentication

	# Create the object instance for SSH
	$cli = new Control::CLI::Extreme('SSH');
	# Connect to host
	$cli->connect(	Host		=> 'hostname',
			Username	=> $username,
			Password	=> $password,
		     );

=head2 Connecting with SSH - publickey authentication

	# Create the object instance for SSH
	$cli = new Control::CLI::Extreme('SSH');
	# Connect to host
	$cli->connect(	Host		=> 'hostname',
			Username	=> $username,
			PublicKey	=> '.ssh/id_dsa.pub',
			PrivateKey	=> '.ssh/id_dsa',
			Passphrase	=> $passphrase,
		     );

=head2 Connecting via Serial port

	# Create the object instance for Serial port e.g. /dev/ttyS0 or COM1
	$cli = new Control::CLI::Extreme('COM1');
	# Connect to host
	$cli->connect(	BaudRate	=> 9600,
			Parity		=> 'none',
			DataBits	=> 8,
			StopBits	=> 1,
			Handshake	=> 'none',
			Username	=> $username,
			Password	=> $password,
		     );

=head2 Sending commands once connected and disconnecting

	$cli->enable;

	# Configuration commands
	$cli->return_result(1);
	$cli->cmd('config terminal') or die $cli->last_cmd_errmsg;
	$cli->cmd('no banner') or die $cli->last_cmd_errmsg;
	$cli->cmd('exit') or die $cli->last_cmd_errmsg;

	# Show commands
	$cli->device_more_paging(0);
	$cli->return_result(0);
	$config = $cli->cmd('show running-config');
	die $cli->last_cmd_errmsg unless $cli->last_cmd_success;
	print $config;

	$cli->disconnect;

=head2 Configuring multiple Extreme Networking products simultaneously in non-blocking mode

	use Control::CLI::Extreme qw(poll);		# Export class poll method

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
	
		if ($method =~ /^cmd/) { # Check that command was accepted
			foreach my $host (keys %$cliHashRef) {
				unless ($cliHashRef->{$host}->last_cmd_success) {
					print "\n- $host error:\n", $cliHashRef->{$host}->last_cmd_errmsg, "\n\n";
				}
			}
		}
	}

	# Create and Connect all the object instances
	foreach my $host (@DeviceIPs) {
		$cli{$host} = new Control::CLI::Extreme(
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

	print "Entering PrivExec on all hosts ";
	bulkDo(\%cli, 'enable');

	print "Entering Config mode on all hosts ";
	bulkDo(\%cli, 'cmd', ['config terminal']);

	print "Pushing config command on all hosts ";
	bulkDo(\%cli, 'cmd', ['snmp-server contact Jack']);

	print "Disconnecting from all hosts ";
	bulkDo(\%cli, 'disconnect');



=head1 DESCRIPTION

Control::CLI::Extreme is a sub-class of Control::CLI allowing CLI interaction customized for Extreme (including ex-Avaya/ex Nortel Enterprise) Networking products over any of Telnet, SSH or Serial port. It is a drop in replacement for the Control::CLI::AvayaData module following the transfer of the Avaya Data business unit to Extreme Networks.
This class supports all of Extreme Summit, Virtual Services Platform (VSP), Private Label Switches (APLS DSG BoxTypes), Ethernet Routing Switch (ERS) and ex-Nortel Enterprise (Bay Networks heritage) platforms. Currently supported devices:

=over 2

=item *

VSP XA-1x00, 4x00, 7x00, 8x00, 9000

=item *

XOS Summit switches

=item *

ERS models 2500, 3x00, 4x00, 5x00

=item *

Wireless Wing APs and Controllers

=item *

SLX Data Center switches

=item *

ISW industrial switches

=item *

Series200 models 210, 220

=item *

ERS/Passport models 1600, 8300, 8600, 8800

=item *

APLS DSG models 6248, 7648, 7480, 8032, 9032

=item *

SR models 2330, 4134

=item *

WLAN 91xx

=item *

WLAN(WC) 81x0

=item *

WLAN(WSS) 2350, 236x, 238x

=item *

BPS 2000, ES 460, ES 470

=item *

Baystack models 325, 425

=item *

Accelar/Passport models 1000, 1100, 1200

=back

The devices supported by this module can have an inconsistent CLI (in terms of syntax, login sequences, terminal width-length-paging, prompts) and in some cases two separate CLI syntaxes are available on the same product.
This class is written so that all the above products can be CLI scripted in a consistent way regardless of their underlying CLI variants. The CLI commands themselves might still vary across the different products though, even here, for certain common functions (like entering privExec mode or disabling terminal more paging) a generic method is provided by this class.

Control::CLI::Extreme is a sub-class of Control::CLI (which is required) and therefore the above functionality can also be performed in a consistent manner regardless of the underlying connection type which can be any of Telnet, SSH or Serial port connection. For SSH, only SSHv2 is supported with either password or publickey authentication.
Furthermore this module leverages the non-blocking capaility of Control::CLI version 2.00 and is thus capable of operating in a non-blocking fashion for all its methods so that it can be used to drive multiple Extreme devices simultaneously without resorting to Perl threads (see examples directory).

Other refinements of this module over and above the basic functionality of Control::CLI are:

=over 4

=item *

On the stackable BaystackERS products the connect & login methods will automatically steer through the banner and menu interface (if seen) to reach the desired CLI interface.

=item *

There is no need to set the prompt string in any of this module's methods since it knows exactly what to expect from any of the supported Extreme products. Furthermore the prompt string is automatically internally set to match the actual prompt of the connected device (rather than using a generic regular expression such as '*[#>]$'). This greatly reduces the risk that the generic regular expression might trigger on a fake prompt embedded in the output stream from the device.

=item *

The connect method of this module automatically takes care of login for Telnet and Serial port access (where authentication is not part of the actual connection, unlike SSH) and so provides a consistent scripting approach whether the underlying connection is SSH or either Telnet or Serial port.

=item *

Automatic handling of output paged with --more-- prompts, including the ability to retrieve an exact number of pages of output.

=item *

A number of attributes are made available to find out basic information about the connected Extreme device.

=item *

Ability to detect whether a CLI command generated an error on the remote host and ability to report success or failure of the issued command as well as the error message details.

=back

Note that all the extra functionality that this module offers over and above Control::CLI, is only possible if connected to an Extreme (or ex Avaya/Nortel) device. To make sure that the connected device is supported, the family_type attribute can be inspected to make sure it is not set to 'generic'; see attribute().

In the syntax layout below, square brackets B<[]> represent optional parameters.
All Control::CLI::Extreme method arguments are case insensitive.




=head1 OBJECT CONSTRUCTOR

Used to create an object instance of Control::CLI::Extreme

=over 4

=item B<new()> - create a new Control::CLI::Extreme object

  $obj = new Control::CLI::Extreme ('TELNET'|'SSH'|'<COM_port_name>');

  $obj = new Control::CLI::Extreme (

  	# same as in Control::CLI :
  	Use			 => 'TELNET'|'SSH'|'<COM_port_name>',
  	[Timeout		 => $secs,]
  	[Connection_timeout	 => $secs,]
  	[Errmode		 => $errmode,]
  	[Errmsg_format		 => $msgFormat,]
  	[Return_reference	 => $flag,]
  	[Prompt			 => $prompt,]
  	[Username_prompt	 => $usernamePrompt,]
  	[Password_prompt	 => $passwordPrompt,]
  	[Input_log		 => $fhOrFilename,]
  	[Output_log		 => $fhOrFilename,]
  	[Dump_log		 => $fhOrFilename,]
  	[Blocking		 => $flag,]
  	[Prompt_credentials	 => $flag,]
  	[Read_attempts		 => $numberOfReadAttemps,]
  	[Readwait_timer		 => $millisecs,]
  	[Data_with_error	 => $flag,]
  	[Read_block_size	 => $bytes,]
  	[Output_record_separator => $ors,]
  	[Terminal_type		 => $string,]
  	[Window_size		 => [$width, $height],]
  	[Report_query_status	 => $flag,]
  	[Debug			 => $debugFlag,]

  	# added in Control::CLI::Extreme :
  	[Return_result		 => $flag,]
  	[More_paging		 => $numberOfPages,]
  	[Cmd_confirm_prompt	 => $string,]
  	[Cmd_initiated_prompt	 => $string,]
  	[Cmd_feed_timeout	 => $value,]
  	[Console		 => $string,]
  	[Wake_console		 => $string,]
  	[Debug_file		 => $fhOrFilename,]
  );

This is the constructor for Control::CLI::Extreme objects. A new object is returned on success. On failure the error mode action defined by "errmode" argument is performed. If the "errmode" argument is not specified the default is to croak. See errmode() for a description of valid settings.
The first parameter, or "use" argument, is required and should take value either "TELNET" or "SSH" (case insensitive) or the name of the Serial port such as "COM1" or "/dev/ttyS0". The other arguments are optional and are just shortcuts to methods of the same name.
The Control::CLI::Extreme constructor accpets all arguments supported by the Control::CLI constructor (which are passed to it) and defines some new arguments specific to itself.

=back




=head1 OBJECT METHODS

Methods which can be run on a previously created Control::CLI::Extreme instance



=head2 Main I/O Object Methods

=over 4

=item B<connect() & connect_poll()> - connect to host

  $ok = $obj->connect("$host[ $port]");

  ($ok, $output || $outputRef) = $obj->connect("$host[ $port]");

  $ok = $obj->connect(
  	[Host			=> $host,]
  	[Port			=> $port,]
  	[Username		=> $username,]
  	[Password		=> $password,]
  	[PublicKey		=> $publicKey,]
  	[PrivateKey		=> $privateKey,]
  	[Passphrase		=> $passphrase,]
  	[Prompt_credentials	=> $flag,]
  	[BaudRate		=> $baudRate,]
  	[ForceBaud		=> $flag,]
  	[Parity			=> $parity,]
  	[DataBits		=> $dataBits,]
  	[StopBits		=> $stopBits,]
  	[Handshake		=> $handshake,]
  	[Timeout		=> $secs,]
  	[Connection_timeout	=> $secs,]
  	[Read_attempts		=> $numberOfLoginReadAttemps,]
  	[Data_with_error	=> $flag,]
  	[Wake_console		=> $string,]
  	[Blocking               => $flag,]
  	[Errmode		=> $errmode,]
  	[Terminal_type		=> $string,]
  	[Window_size		=> [$width, $height],]
  	[Callback		=> \&codeRef,]
  	[Atomic_connect		=> $flag,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

  ($ok, $output || $outputRef) = $obj->connect(
  	[Host			=> $host,]
  	[Port			=> $port,]
  	[Username		=> $username,]
  	[Password		=> $password,]
  	[PublicKey		=> $publicKey,]
  	[PrivateKey		=> $privateKey,]
  	[Passphrase		=> $passphrase,]
  	[Prompt_credentials	=> $flag,]
  	[BaudRate		=> $baudRate,]
  	[ForceBaud		=> $flag,]
  	[Parity			=> $parity,]
  	[DataBits		=> $dataBits,]
  	[StopBits		=> $stopBits,]
  	[Handshake		=> $handshake,]
  	[Timeout		=> $secs,]
  	[Connection_timeout	=> $secs,]
  	[Return_reference	=> $flag,]
  	[Read_attempts		=> $numberOfLoginReadAttemps,]
  	[Data_with_error	=> $flag,]
  	[Wake_console		=> $string,]
  	[Blocking               => $flag,]
  	[Errmode		=> $errmode,]
  	[Terminal_type		=> $string,]
  	[Window_size		=> [$width, $height],]
  	[Callback		=> \&codeRef,]
  	[Atomic_connect		=> $flag,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

Polling method (only applicable in non-blocking mode):

  $ok = $obj->connect_poll();

  ($ok, $output || $outputRef) = $obj->connect_poll();

This method connects to the host device. The connection will use either Telnet, SSH or Serial port, depending on how the object was created with the new() constructor.
On success a true (1) value is returned. On time-out or other connection failures the error mode action is performed. See errmode().
In the first & third forms only a success/failure value is returned in scalar context, while in the second & fourth forms, in list context, both the success/failure value is returned as well as any output received from the host device during the connect/login sequence; the latter is either the output itself or a reference to that output, depending on the object setting of return_reference or the argument override provided in this method.

This method overrides Control::CLI::connect() and calls both the Control::CLI::connect() method as well as the login() method from this class. This allows the connect() method to seamlessly handle connection and login for both SSH (which normally handles authentication as part of the connection process) and Telnet and Serial port access (for which authentication needs to be dealt with after connection). In short, by calling the connect() method it is not necessary to call the login() method afterwards.

In non-blocking mode (blocking disabled) the connect() method will immediately return with a false, but defined, value of 0. You will then need to call the connect_poll() method at regular intervals until it returns a true (1) value indicating that the connection and login is complete. Note that for this method to work (with TELNET or SSH) in non-blocking mode IO::Socket::IP needs to be installed (IO::Socket:INET will always produce a blocking TCP socket setup).

The "host" argument is required by both Telnet and SSH. All the other arguments are optional.
If username/password or SSH Passphrase are not provided but are required and prompt_credentials is true, the method will automatically prompt the user for them; otherwise the error mode action is performed. The "errmode" argument is provided to override the global setting of the object error mode action. See errmode().
The "prompt_credentials" argument is provided to override the global setting of the parameter by the same name which is by default false. See prompt_credentials().
The "read_attempts" argument is simply fed to the login() method. See login().
The "connection_timeout" argument can be used to set a connection timeout when establishing Telnet and SSH TCP connections; this is fed to Control::CLI::connect(). Whereas the "timeout" argument is the normal timeout used for reading the connection once established; this is fed to login().
The "terminal_type" and "window_size" arguments are Control::CLI arguments and are not overrides, they will change the object parameter as these settings are only applied during a connection. It is not necessary to set these for Extreme devices.
Which other arguments are used depends on the whether the object was created for Telnet, SSH or Serial port. 

=over 4

=item *

For Telnet, these arguments are used:

  $ok = $obj->connect("$host[ $port]");

  $ok = $obj->connect(
  	Host			=> $host,
  	[Port			=> $port,]
  	[Username		=> $username,]
  	[Password		=> $password,]
  	[Prompt_credentials	=> $flag,]
  	[Timeout		=> $secs,]
  	[Connection_timeout	=> $secs,]
  	[Read_attempts		=> $numberOfLoginReadAttemps,]
  	[Data_with_error	=> $flag,]
  	[Wake_console		=> $string,]
  	[Blocking               => $flag,]
  	[Errmode		=> $errmode,]
  	[Terminal_type		=> $string,]
  	[Window_size		=> [$width, $height],]
  	[Atomic_connect		=> $flag,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

If not specified, the default port number for Telnet is 23. The wake_console argument is only relevant when connecting to a Telnet port other than 23 (i.e. to a Terminal Server device) or if console() has been manually set; see console(). In which case, the login() method, which is called by connect(), will automatically send the wake_console string sequence to the attached device to alert it of the connection. The default sequence will work across all Extreme Networking products but can be overridden by using the wake_console argument. See wake_console().
Another reason to use the wake_console is when connecting via Telnet to an XOS switch which is configured with a 'before-login' banner which has to be acknowledged. In this case the XOS switch will not request a login until the user has hit a key. In this case make sure to set the Console argument to 1 in the object constructor (the default wake_console string '\n' will then be sent and there is no need to specify a different wake_console string in the connect() method).

=item *

For SSH, these arguments are used:

  $ok = $obj->connect("$host[ $port]");

  $ok = $obj->connect(
  	Host			=> $host,
  	[Port			=> $port,]
  	[Username		=> $username,]
  	[Password		=> $password,]
  	[PublicKey		=> $publicKey,]
  	[PrivateKey		=> $privateKey,]
  	[Passphrase		=> $passphrase,]
  	[Prompt_credentials	=> $flag,]
  	[Timeout		=> $secs,]
  	[Connection_timeout	=> $secs,]
  	[Read_attempts		=> $numberOfLoginReadAttemps,]
  	[Data_with_error	=> $flag,]
  	[Wake_console		=> $string,]
  	[Blocking               => $flag,]
  	[Errmode		=> $errmode,]
  	[Terminal_type		=> $string,]
  	[Window_size		=> [$width, $height],]
  	[Callback		=> \&codeRef,]
  	[Atomic_connect		=> $flag,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

If not specified, the default port number for SSH is 22. The wake_console argument is only relevant when connecting to a SSH port other than 22 (i.e. to a Terminal Server device) or if console() has been manually set; see console(). In which case, the login() method, which is called by connect(), will automatically send the wake_console string sequence to the attached device to alert it of the connection. The default sequence will work across all Extreme Networking products but can be overridden by using the wake_console argument. See wake_console().

A username must always be provided for all SSH connections. If not provided and prompt_credentials is true then this method will prompt for it.
Once the SSH conection is established, this method will attempt one of two possible authentication types, based on the accepted authentications of the remote host:

=over 4

=item *

B<Publickey authentication> : If the remote host accepts it and the method was supplied with public/private keys. The public/private keys need to be in OpenSSH format. If the private key is protected by a passphrase then this must also be provided or, if prompt_credentials is true, this method will prompt for the passphrase. If publickey authentication fails for any reason and password authentication is possible, then password authentication is attempted next; otherwise the error mode action is performed. See errmode().

=item *

B<Password authentication> : If the remote host accepts either 'password' or 'keyboard-interactive' authentication methods. A password must be provided or, if prompt_credentials is true, this method will prompt for the password. If password authentication fails for any reason the error mode action is performed. See errmode(). VOSS VSP hosts can be configured for either 'password' or 'keyboard-interactive' authentication. Use of either of these SSH authentication methods (which both ultimately provide username & password credentials to the SSH server) remains completely transparent to the code using this class.

=back


=item *

For Serial port, these arguments are used:

  $ok = $obj->connect(
  	[BaudRate		=> $baudRate,]
  	[ForceBaud		=> $flag,]
  	[Parity			=> $parity,]
  	[DataBits		=> $dataBits,]
  	[StopBits		=> $stopBits,]
  	[Handshake		=> $handshake,]
  	[Username		=> $username,]
  	[Password		=> $password,]
  	[Prompt_credentials	=> $flag,]
  	[Timeout		=> $secs,]
  	[Read_attempts		=> $numberOfLoginReadAttemps,]
  	[Data_with_error	=> $flag,]
  	[Wake_console		=> $string,]
  	[Blocking		=> $flag,]
  	[Errmode		=> $errmode,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

If arguments "baudrate", "parity", "databits", "stopbits" and "handshake" are not specified, the defaults are: Baud Rate = 9600, Data Bits = 8, Parity = none, Stop Bits = 1, Handshake = none. These default values will work on all Extreme Networking products with default settings.
Allowed values for these arguments are the same allowed by Control::CLI::connect().

On Windows systems the underlying Win32::SerialPort module can have issues with some serial ports, and fail to set the desired baudrate (see bug report https://rt.cpan.org/Ticket/Display.html?id=120068); if hitting that problem (and no official Win32::SerialPort fix is yet available) set the ForceBaud argument; this will force Win32::SerialPort into setting the desired baudrate even if it does not think the serial port supports it.

For a serial connection, this method - or to be precise the login() method which is called by connect() - will automatically send the wake_console string sequence to the attached device to alert it of the connection. The default sequence will work across all Extreme Networking products but can be overridden by using the wake_console argument.

=back

If using the connect() method in non-blocking mode, the following example illustrates how this works:

	$ok = $obj->connect(Host => $ip-address, Blocking => 0);
	until ($ok) { # This loop will be executed while $ok = 0
		
		<do other stuff here..>
	
		$ok = $obj->connect_poll;
	}

Or, if you have set an error mode action of 'return':

	$ok = $obj->connect(Host => $ip-address, Blocking => 0, Errmode => 'return');
	die $obj->errmsg unless defined $ok;	# Error connecting
	until ($ok) { # This loop will be executed while $ok = 0
		
		<do other stuff here..>
	
		$ok = $obj->connect_poll;
		die $obj->errmsg unless defined $ok;	# Error or timeout connecting
	}


=item B<login() & login_poll()> - handle login for Telnet / Serial port; also set the host CLI prompt

  $ok = $obj->login(
  	[Username		=> $username,]
  	[Password		=> $password,]
  	[Prompt_credentials	=> $flag,]
  	[Timeout		=> $secs,]
  	[Read_attempts		=> $numberOfLoginReadAttemps,]
  	[Data_with_error	=> $flag,]
  	[Wake_console		=> $string,]
  	[Blocking		=> $flag,]
  	[Errmode		=> $errmode,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

  ($ok, $output || $outputRef) = $obj->login(
  	[Username		=> $username,]
  	[Password		=> $password,]
  	[Prompt_credentials	=> $flag,]
  	[Timeout		=> $secs,]
  	[Return_reference	=> $flag,]
  	[Read_attempts		=> $numberOfLoginReadAttemps,]
  	[Data_with_error	=> $flag,]
  	[Wake_console		=> $string,]
  	[Blocking		=> $flag,]
  	[Errmode		=> $errmode,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

Polling method (only applicable in non-blocking mode):

  $ok = $obj->login_poll();

  ($ok, $output || $outputRef) = $obj->login_poll();

This method handles login authentication for Telnet and Serial port access (also for SSH access in the case of the WLAN2300 WSS controllers, since they use no SSH authentication but instead use an interactive login once the SSH connection is established). For all connection types (including SSH) it also performs all the necessary steps to get to a CLI prompt; for instance on the Baystack / Stackable ERS platforms it will skip the Banner and/or Menu interface. Over a serial port connection or a ssh or telnet connection over a port other than default 22 or 23 respectively (indicating a Terminal Server connection) or if console() was manually set, it will automatically generate a wake_console sequence to wake up the attached device into producing either a login banner or CLI prompt. This sequence can be overridden by using the wake_console argument; setting this argument to the empty string will disable the wake_console sequence. Likewise use of console() can be used to control, force or disable the wake_console sequence; see wake_console() and console().

On success the method returns a true (1) value. On failure the error mode action is performed. See errmode().
In non-blocking mode (blocking disabled) the login() method will most likely immediately return with a false, but defined, value of 0. You will then need to call the login_poll() method at regular intervals until it returns a true (1) value indicating that the login is complete.
In the first form only a success/failure value is returned in scalar context, while in the second form, in list context, both the success/failure value is returned as well as any output received from the host device during the login sequence; the latter is either the output itself or a reference to that output, depending on the object setting of return_reference or the argument override provided in this method.
This method internally uses the readwait() method and by default sets the read_attemps for it to 10 (which is a safe value to ensure proper connection to any Extreme Networking device); the read_attempts argument provided by login() can be used to override that value. The non_recognized_login argument flag controls whether the method should immediately return when an initial login output sequence is not recognized or whether the method should keep trying to read login output until either a recognized login prompt is detected or expiry of the timeout. The generic_login argument flag disables extended discovery if it is desired to connect to non Extreme devices using this class.

Once a valid Extreme Networking CLI prompt is detected (using pre-configured pattern match strings), this method records the actual CLI prompt of the host device for the remainder of the session by automatically invoking the prompt() method with a new pattern match string based on the actual device CLI prompt. This ensures a more robust behaviour where the chances of triggering on a fake prompt embedded in the device output data is greatly reduced.
At the same time this method will also set the --more-- prompt used by the device when paging output as well as a number of attributes depending on what family_type was detected for the host device. See attribute().

Note that this method is automatically invoked by the connect() method and therefore should seldom need to be invoked by itself. A possible reason to invoke this method on its own could be if initially connecting to, say, an ERS8800 device and from there initiating a telnet/ssh connection onto a Stackable device (i.e. telnet/ssh hopping); since we are connecting to a new device the login() method must be invoked to set the new prompts accordingly as well as re-setting all the device attributes. An example follows:

	# Initial connection could use Telnet or SSH, depending on how object was constructed
	# Connect to 1st device, e.g. via out-of-band mgmt
	$cli->connect(
		Host		=> '<ERS8800 IP address>',
		Username	=> 'rwa',
		Password	=> 'rwa',
	);
	# From there connect to another device, perhaps on inband mgmt
	# NOTE: use print() not cmd() as there is no prompt coming back, but the login screen of the stackable
	$cli->print("telnet <Stackable IP address>");
	# Call login() to authenticate, detect the device, reset appropriate attributes 
	$cli->login(
		Username	=> 'RW',
		Password	=> 'RW',
	);
	# Execute commands on target stackable device
	$output = $cli->cmd("show running-config");
	print $output;
	[...]
	# If you want to return to the first device..
	# NOTE: use print() not cmd() as the next prompt will be from the ERS8800, not the stackable anymore
	$cli->print("logout");
	# Call login() to detect the device and reset appropriate attributes (no authentication needed though)
	$cli->login;
	# Now we are back on the 1st device
	$output = $cli->cmd("show sys info");
	print $output;
	[...]


If using the login() method in non-blocking mode, the following examples illustrate how this works:

=over 4

=item *

If you do not care to retrieve the login sequence output:

	$ok = $obj->login(Username => "admin", Password => "pwd", Blocking => 0);
	until ($ok) { # This loop will be executed while $ok = 0
		
		<do other stuff here..>
	
		$ok = $obj->login_poll;
	}

=item *

If you want to retrieve the login output sequence along the way (even in case of error/timeout):

	($ok, $output) = $obj->login(Username => "admin", Password => "pwd", Blocking => 0, Errmode => 'return');
	die $obj->errmsg unless defined $ok;	# Login failed
	until ($ok) {
		
		<do other stuff here..>
	
		($ok, $partialOutput) = $obj->login_poll;
		die $obj->errmsg unless defined $ok;	# Login failed or timeout
		$output .= $partialOutput;
	}
	print "Complete login sequence output:\n", $output;

=item *

If you only want to retrieve the full login sequence output at the end:
	
	$ok = $obj->login(Username => "admin", Password => "pwd", Blocking => 0);
	until ($ok) {
		
		<do other stuff here..>
	
		$ok = $obj->login_poll;
	}
	print "Complete login sequence output:\n", ($obj->login_poll)[1];

=back
 

=item B<cmd() & cmd_poll()> - Sends a CLI command to host and returns result or output

Backward compatible syntax:

  $result || $output || $outputRef = $obj->cmd($cliCommand);

  $result || $output || $outputRef = $obj->cmd(
  	[Command		=> $cliCommand,]
  	[Prompt			=> $prompt,]
  	[Reset_prompt		=> $flag,]
  	[More_prompt		=> $morePrompt,]
  	[More_pages		=> $numberOfPages,]
  	[Cmd_confirm_prompt	=> $ynPrompt,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Return_reference	=> $flag,]
  	[Return_result		=> $flag,]
  	[Progress_dots		=> $bytesPerDot,]
  	[Errmode		=> $errmode,]
  );

New syntax (for non-blocking use):

  $ok = $obj->cmd(
	Poll_syntax		=> 1,
  	[Command		=> $cliCommand,]
  	[Prompt			=> $prompt,]
  	[Reset_prompt		=> $flag,]
  	[More_prompt		=> $morePrompt,]
  	[More_pages		=> $numberOfPages,]
  	[Cmd_confirm_prompt	=> $ynPrompt,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Return_reference	=> $flag,]
  	[Return_result		=> $flag,]
  	[Progress_dots		=> $bytesPerDot,]
  	[Errmode		=> $errmode,]
  );

  ($ok, $result || $output || $outputRef) = $obj->cmd($cliCommand);

  ($ok, $result || $output || $outputRef) = $obj->cmd(
	[Poll_syntax		=> 1,]
  	[Command		=> $cliCommand,]
  	[Prompt			=> $prompt,]
  	[Reset_prompt		=> $flag,]
  	[More_prompt		=> $morePrompt,]
  	[More_pages		=> $numberOfPages,]
  	[Cmd_confirm_prompt	=> $ynPrompt,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Return_reference	=> $flag,]
  	[Return_result		=> $flag,]
  	[Progress_dots		=> $bytesPerDot,]
  	[Errmode		=> $errmode,]
  );

Polling method (only applicable in non-blocking mode):

  $ok = $obj->cmd_poll();

  ($ok, $result || $output || $outputRef) = $obj->cmd_poll();

This method sends a CLI command to the host and returns once a new CLI prompt is received from the host. The output record separator - which is by default "\r" in this class; see output_record_separator() - is automatically appended to the command string. If no command string is provided then this method will simply send the output record separator and expect a new prompt back.
Before sending the command to the host, any pending input data from host is read and flushed.
The CLI prompt expected by the cmd() method is either the object prompt previously set by any of connect(), login() or prompt(); or it is the override prompt specified by the optional prompt method argument. If the reset_prompt flag is activated then the prompt match pattern is automatically reset using the same initial pattern match used by connect() & login() to match the prompt for the first time; this is useful when executing a CLI command which will cause the CLI prompt to change (such as changing the switch name). If the reset_prompt flag is set any prompt supplied via the argument will be ignored.

For backwards compatibility, in scalar context, the output data from the command is returned.
The new syntax, in scalar context returns the poll status, while in list context, both the poll status together with the output data are returned. Note that to disambiguate the new scalar context syntax the 'poll_syntax' argument needs to be set (while this is not strictly necessary in list context).
In non-blocking mode, the poll status will most likely immediately return with a false, but defined, value of 0. You will then need to call the cmd_poll() method at regular intervals until it returns a true (1) value indicating that the command has completed.

When this method is retrieving the output of the command and the output is generated over multiple pages of output, each page paused with a --more-- prompt, the cmd() method will retrieve as many pages as defined globally by more_paging(). If the optional "more_pages" argument is specified then this value will override the global setting of more_paging(). Either way, if a value of 0 is specified, space characters are automatically fed to obtain all output until the next CLI prompt is received. Note that for best script performance it is recommended to disable more paging on the host device using the appropriate CLI command or the device_more_paging() method. The optional 'more_prompt' argument can be used to override the object more_prompt string though this should seldom be necessary as the correct more prompt string is automatically set by connect() & login(). See more_prompt().

If the command produces a Y/N confirmation prompt as certain Extreme Networking device CLI commands do (for example "boot" or "reset") this method will automatically detect the confirmation prompt and feed a 'y' to it as you would expect when scripting the device. If, for some reason, you wanted to feed a 'n' then refer to cmd_prompted() method instead. The optional 'cmd_confirm_prompt' argument can be used to override the object match string defined for this; see also cmd_confirm_prompt().

This method will either return the result of the command or the output. If return_result is set for the object, or it is set via the override "return_result" argument provided in this method, then only the result of the command is returned. In this case a true (1) value is returned if the command was executed without generating any error messages on the host device. While a false (0) value is returned if the command generated some error messages on the host device. The error message can be obtained via the last_cmd_errmsg() method. See last_cmd_errmsg() and last_cmd_success(). This mode of operation is useful when sending configuration commands to the host device.

If instead return_result is not set then this method will return either a hard reference to the output generated by the CLI command or the output itself. This will depend on the setting of return_reference; see return_reference(); the global setting of return_reference can also be overridden using the method argument by the same name.
Passing a refence to the output makes for much faster/efficient code, particularly if the output generated is large (for instance output of "show running-config").
The echoed command is automatically stripped from the output as well as the terminating CLI prompt (the last prompt received from the host device can be obtained with the last_prompt() method).
This mode of operation is useful when sending show commands which retrieve information from the host device.
Note that in this mode (return_result not set), sending a config command will result in either a null string or a reference pointing to a null string being returned, unless that command generated some error message on the host device. In this case the return_result mode should be used instead.

The progress_dots argument is provided as an override of the object method of the same name for the duration of this method; see progress_dots().

On I/O failure to the host device, the error mode action is performed. See errmode().
If, after expiry of the configured timeout - see timeout() -, output is no longer received from host and no valid CLI prompt has been seen, the method will send an additional carriage return character and automatically fall back on the initial generic prompt for a further 10% of the configured timeout. If even that prompt is not seen after this further timeout then the error mode action is performed. See errmode().
So even if the CLI prompt is changed by the issued command (e.g. changing the system-name or quitting the debug shell) this method should be able to recover since it will automatically revert to the initial generic prompt, but this will happen after expiry of the configured timeout. In this case, to avoid waiting expiry of timeout, set the reset_prompt argument. Here is an example showing how to revert to the normal CLI prompt when quitting the shell:

	$obj->cmd('priv');
	# Before entering the shell we need to set the prompt to match the shell prompt
	$obj->prompt('-> $');
	# Now enter the shell
	$obj->cmd('shell');
	$obj->cmd('spyReport');
	[...other shell cmds issued here...]
	# When done, logout from shell, and revert to standard CLI prompt
	$obj->cmd(Command => 'logout', Reset_prompt => 1);

Alternatively, since accessing the shell now requires a priv & shell password, if you only need to execute a few shell commands you can assume that the shell prompt is a prompt belonging to the shell command and use cmd_prompted() instead; the following example does the same thing as the previous example but does not need to change the prompt:

	# Enter the shell and execute shell commands all in one go
	$obj->cmd_prompted(
			Command			=> 'priv',
			Feed			=> $privPassword,
	);
	$obj->cmd_prompted(
			Command			=> 'shell',
			Cmd_initiated_prompt	=> '(:|->) $',
			Feed			=> $shellPassword,
			Feed			=> 'spyReport',
			Feed			=> 'logout',
	);

If the issued command returns no prompt (e.g. logout), consider using print() instead of cmd() or, if logging out, simply use the disconnect() method.

If the issued command produces a Y/N confirmation prompt but does not return a regular prompt (e.g. reset, boot) there are two possible approaches. On some Extreme Networking devices (e.g. PassportERS family_type) you can append '-y' to the command being sent to suppress the Y/N confirmation prompt, in which case you can simply do:

	$cli->print('reset -y');
	sleep 1; # Do not disconnect before switch has time to process last command...
	$cli->disconnect;

However, other Extreme Networking devices do not accept a '-y' appended to the reset/boot commands (e.g. BaystackERS family_type); on these devices use this sequence:

	$cli->print('reset');
	$cli->waitfor($cli->cmd_confirm_prompt);
	$cli->print('y');
	sleep 1; # Do not disconnect before switch has time to process last command...
	$cli->disconnect;

In non-blocking mode (blocking disabled) the cmd() method will most likely immediately return with a false, but defined, value of 0. You will then need to call the cmd_poll() method at regular intervals until it returns a true (1) value indicating that the command is complete. The following example illustrates:

=over 4

=item *

If you do not care to retrieve any output from the command:

	$ok = $obj->cmd(Poll_syntax => 1, Command => "set command", Blocking => 0);
	until ($ok) { # This loop will be executed while $ok = 0
		
		<do other stuff here..>
	
		$ok = $obj->cmd_poll;
	}

=item *

If you want to retrieve the command output sequence along the way:

	($ok, $output) = $obj->cmd(Command => "show command", Blocking => 0, Errmode => 'return');
	die $obj->errmsg unless defined $ok;	# Login failed
	until ($ok) {
		
		<do other stuff here..>
	
		($ok, $partialOutput) = $obj->cmd_poll;
		die $obj->errmsg unless defined $ok;	# Login failed or timeout
		$output .= $partialOutput;
	}
	print "Complete command output:\n", $output;

=item *

If you only want to retrieve the command output at the end:
	
	$ok = $obj->cmd(Poll_syntax => 1, Command => "show command", Blocking => 0);
	until ($ok) {
		
		<do other stuff here..>
	
		$ok = $obj->cmd_poll;
	}
	print "Complete command output:\n", ($obj->cmd_poll)[1];

=back



=item B<cmd_prompted()> - Sends a CLI command to host, feeds additional requested data and returns result or output

Backward compatible syntax:

  $result || $output || $outputRef = $obj->cmd_prompted($cliCommand, @feedData);

  $result || $output || $outputRef = $obj->cmd_prompted(
  	[Command		=> $cliCommand,]
  	[Feed			=> $feedData1,
  	 [Feed			=> $feedData2,
  	  [Feed			=> $feedData3,
  	    ... ]]]
  	[Feed_list		=> \@arrayRef,]
  	[Prompt			=> $prompt,]
  	[Reset_prompt		=> $flag,]
  	[More_prompt		=> $morePrompt,]
  	[More_pages		=> $numberOfPages,]
  	[Cmd_initiated_prompt	=> $cmdPrompt,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Return_reference	=> $flag,]
  	[Return_result		=> $flag,]
  	[Progress_dots		=> $bytesPerDot,]
  	[Errmode		=> $errmode,]
  );

New syntax (for non-blocking use):

  $ok = $obj->cmd_prompted(
	Poll_syntax		=> 1,
  	[Command		=> $cliCommand,]
  	[Feed			=> $feedData1,
  	 [Feed			=> $feedData2,
  	  [Feed			=> $feedData3,
  	    ... ]]]
  	[Feed_list		=> \@arrayRef,]
  	[Prompt			=> $prompt,]
  	[Reset_prompt		=> $flag,]
  	[More_prompt		=> $morePrompt,]
  	[More_pages		=> $numberOfPages,]
  	[Cmd_initiated_prompt	=> $cmdPrompt,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Return_reference	=> $flag,]
  	[Return_result		=> $flag,]
  	[Progress_dots		=> $bytesPerDot,]
  	[Errmode		=> $errmode,]
  );

  ($ok, $result || $output || $outputRef) = $obj->cmd_prompted(
	[Poll_syntax		=> 1,]
  	[Command		=> $cliCommand,]
  	[Feed			=> $feedData1,
  	 [Feed			=> $feedData2,
  	  [Feed			=> $feedData3,
  	    ... ]]]
  	[Feed_list		=> \@arrayRef,]
  	[Prompt			=> $prompt,]
  	[Reset_prompt		=> $flag,]
  	[More_prompt		=> $morePrompt,]
  	[More_pages		=> $numberOfPages,]
  	[Cmd_initiated_prompt	=> $cmdPrompt,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Return_reference	=> $flag,]
  	[Return_result		=> $flag,]
  	[Progress_dots		=> $bytesPerDot,]
  	[Errmode		=> $errmode,]
  );

Polling method (only applicable in non-blocking mode):

  $ok = $obj->cmd_poll();

  ($ok, $result || $output || $outputRef) = $obj->cmd_poll();

This method is identical to cmd() except that it will not automaticaly feed a 'y' to Y/N confirmation prompts but in a more general manner will detect any prompts generated by the issued CLI command (whether these are Y/N confirmation prompts or simply prompts for additional information the CLI command requires) and will feed whatever data has been provided to the method. In the first form of the backward compatible syntax, data can be provided as an array while in all other cases data is provided either as any number of "feed" arguments or via a "feed_list" array reference. In fact both "feed" and "feed_list" arguments can be provided, multiple times, in which case the data is chained in the same order in which it was provided to the method.
Note that to disambiguate the new syntaxes, then either the "command" or "poll_syntax" arguments must be the first argument supplied, otherwise the first form of the backward compatible syntax is expected.

The prompt used to detect CLI command prompts can be set via the cmd_initiated_prompt() or via the override method argument by te same name.
An example using cmd_prompted() is shown in the cmd() section above.


=item B<attribute() & attribute_poll()> - Return device attribute value

Backward compatible syntax:

  $value = $obj->attribute($attribute);

  $value = $obj->attribute(
  	Attribute		=> $attribute,
  	[Reload			=> $flag,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );

New syntax (for non-blocking use):

  $ok = $obj->attribute(
	Poll_syntax		=> 1,
  	Attribute		=> $attribute,
  	[Reload			=> $flag,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );

  ($ok, $value) = $obj->attribute($attribute);

  ($ok, $value) = $obj->attribute(
	[Poll_syntax		=> 1,]
  	Attribute		=> $attribute,
  	[Reload			=> $flag,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );

Polling method (only applicable in non-blocking mode):

  $ok = $obj->attribute_poll();

  ($ok, $value) = $obj->attribute_poll();

When connecting to an Extreme Networking device a certain number of attributes are automatically recorded if the information is readily available and does not require additional CLI commands.
The attribute() method allows to retrieve the value of such attributes.
If the attribute is already set, then the method simply returns its value.
If on the other hand the requested attribute is not yet set, then in this case the method will issue the necessary CLI command to find the relevant information to set the attribute (or multiple attributes since in some cases a CLI command yields information for multiple attributes) and will then return its value. Any subsequent lookup for the same attribute name will no longer need to issue CLI commands.
If the "reload" flag is true, then even if the attribute was already set the method will verify the setting on the connected device by re-issuing the necessary commands.
In case of any IO failures while issuing CLI commands the error mode action is performed.

Once a connection is established (including login) the I<family_type> attribute is always set.
As long as it is set to a valid Extreme Networking product type, then all other global attributes are available as well as all the relevant attributes for the family type specified (a full list of available attributes is returned by specifying attribute I<all>). Attributes for other product families different from the current value of I<family_type> will be undefined.
If the I<family_type> attribute is not yet set or is set to B<generic> then all other attributes, including the other Global ones, will be undefined.

Valid attributes and their possible values follow.

Global attributes which apply to any product family type:

=over 4

=item *

I<family_type>:

=over 4

=item *

B<ExtremeXOS> : ExtremeXOS Summit switch

=item *

B<BaystackERS> : Any of Baystack, BPS, ES, Stackable ERS (ERS-2500, ERS-3x00, ERS-4x00, ERS-5x00), Stackable VSP (VSP-7000), WLAN8100

=item *

B<PassportERS> : Any of Passport/ERS-1600, Passport/ERS-8x00, VOSS VSPs (VSP-9000, VSP-8000, VSP-7200, VSP-4000), APLS DSG BoxTypes

=item *

B<ISW> : ISW industrial switches

=item *

B<Wing> : Wireless Wing APs and Controllers

=item *

B<Series200> : Series200 switches

=item *

B<SLX> : SLX Data Center switches

=item *

B<WLAN9100> : WLAN 91xx Access Points

=item *

B<SecureRouter> : Any of the Secure Router 2330 & 4134 series

=item *

B<WLAN2300> : WLAN WSS2300 Controllers

=item *

B<Accelar> : Any of the old Accelar 1000, 1100, 1200

=item *

B<generic> : Not an Extreme Networking product; equivalent functionality to Control::CLI

=back


=item *

I<model>: Device model e.g. X460G2-24t-10G4, VSP-8284-XSQ, ERS-4526-GTX-PWR; The model naming will usually be in the format <VSP|ERS|ES|WC>-<number>-<type>-<subtype>. This attribute will remain undefined if connected to the Standby CPU of a PassportERS device. Typical ISW formatting is ISW_8-10/100P_4-SFP or ISW_4GbP_2GbT_2-SFP.

=item *

I<sysname>: System name of the device. This attribute will remain undefined if connected to the Standby CPU of a PassportERS device.

=item *

I<base_mac>: Base MAC address of the device in string format xx-xx-xx-xx-xx-xx. This is the base MAC address from which all other device MACs (VLAN, Port, etc) are derived. This attribute is useful for maintaining a unique reference for the device. This attribute will remain undefined if connected to the Standby CPU of a PassportERS device.

=item *

I<is_acli>: Flag; true(1) for Cisco like acli mode which has PrivExec & Config modes; false(0) otherwise.
So for family types B<BaystackERS>, B<SecureRouter>, B<WLAN2300>, B<WLAN9100>, B<ISW>, B<Wing>, B<Series200>, B<SLX> and B<PassportERS> (the latter in acli mode) this flag is true.
Whereas for family types B<ExtremeXOS>, B<Accelar>, B<generic> and B<PassportERS> (the latter in cli mode) this flag is false.

=item *

I<is_nncli>: Flag; alias for above I<is_acli> attribute as nncli is historically how this CLI mode was called in Nortel days

=item *

I<sw_version>: Run time software version

=item *

I<fw_version>: BootROM / Boot Monitor / Firmware / Linux verson, if applicable, undef otherwise

=item *

I<slots>: Returns a list (array reference) of all valid slot numbers (or unit numbers in a stack) or interface types (in the case of ISW there are FastEthernet & GigabitEtherne interfaces); returns an empty list if the device ports have no slot number associated (e.g. a BaystackERS or ExtremeXOS switch in non-stacking/standalone mode) and undefined if no slot/port information could be retrieved from the device, e.g. if connected to the Standby CPU of a PassportERS device

=item *

I<ports>: If the I<slots> attribute is defined, this attribute returns an array (slots are numbers) or hash (slots are names; in the case of ISW, names 'FastEthernet' and 'GigabitEthernet') reference where the index/key is the slot number (valid slot/key numbers are provided by the I<slots> attribute) and the array/hash elements are a list (array references) of valid ports for that particular slot. Note that for 40GbE/100GbE channelized ports the 10GbE/25GbE sub interfaces will be listed in port/subport fashion in this list; e.g. channelized ports 1/2/1-1/2/4 will be seen as ports 2/1,2/2,2/3,2/4 on the port list for slot 1.
If the I<slots> attribute is defined but empty (i.e. there is no slot number associated to available ports - e.g. a BaystackERS switch in standalone mode), this attribute returns a list (array reference) of valid port numbers for the device. (The test script for this class - extreme.cli.t - has an attribute method that shows how to decode the slot & port attributes).

=item *

I<baudrate>: Console port configured baudrate. This attribute only works with devices where the baudrate is configurable or shown by the system (i.e. only PassportERS and BaystackERS devices with the exceptions of ERS-4000 units and standby CPU of a VSP9000/VSP8600). On these devices this attribute will return a defined value. On other devices where the baudrate is not configurable or not shown, an undef value is returned, and in this case it is safe to assume that the valid baudrate is 9600 (with the exception of ExtremeXOS X690 or X870 series switches where it is 115200)

=item *

I<max_baud>: Maximum configurable value of baudrate on device's console port. This attribute only works with devices where the baudrate is configurable (i.e. only PassportERS and BaystackERS devices with the exceptions of ERS-4000 units andStandby CPU of a VSP9000). On these devices this attribute will return a defined value. On other devices where the baudrate is not configurable an undef value is returned, and in this case it is safe to assume that the only valid baudrate is the one returned by the I<baudrate> attribute.

=back



Attributes which only apply to B<PassportERS> family type:

=over 4

=item *

I<is_voss>: Flag; true(1) if the device is a PassportERS VSP model (only I<model> VSP-xxxx) or is an Extreme Product Label Switch (APLS) (I<is_apls> is true); false(0) otherwise.

=item *

I<is_apls>: Flag; true(1) if an Extreme Product Label Switch (APLS); false(0) otherwise.

=item *

I<apls_box_type>: Box Type of an Extreme Product Label Switch (APLS); only set if I<is_apls> is true, undefined otherwise.

=item *

I<brand_name>: Brand Name of an Extreme Product Label Switch (APLS) or a VOSS VSP; only set if I<is_voss> is true, undefined otherwise.

=item *

I<is_master_cpu>: Flag; true(1) if connected to a Master CPU; false(0) otherwise

=item *

I<is_dual_cpu>: Flag; true(1) if 2 CPUs are present in the chassis; false(0) otherwise

=item *

I<cpu_slot>: Slot number of the CPU we are connected to

=item *

I<is_ha>: Flag; true(1) if HA-mode is enabled; false(0) otherwise; undef if not applicable

=item *

I<stp_mode>: Spanning tree operational mode; possible values: B<stpg> (802.1D), B<rstp> (802.1W), B<mstp> (802.1S)

=item *

I<oob_ip>: Out-of-band IP address of Master CPU (this attribute is only set when connected to the Master CPU)

=item *

I<oob_virt_ip>: Out-of-band Virtual IP address (this attribute is only set when connected to the Master CPU)

=item *

I<oob_standby_ip>: Out-of-band IP address of Standby CPU (this attribute is only set when connected to the Master CPU)

=item *

I<is_oob_connected>: Flag; true(1) if the connection to the device is to either the oob_ip or oob_virt_ip IP address; false(0) otherwise (this attribute is only set when connected to the Master CPU; it will be undefined if connected to a Standby CPU)

=back



Attributes which only apply to B<BaystackERS> family type:

=over 4

=item *

I<unit_number>: Unit number we are connected to (Generaly the base unit, except when connecting via Serial) if a stack; undef otherwise

=item *

I<base_unit>: Base unit number, if a stack; undef otherwise

=item *

I<switch_mode>:

=over 4

=item *

B<Switch> : Standalone switch

=item *

B<Stack> : Stack of switches

=back

=item *

I<stack_size>: Number of units in the stack, if a stack; undef otherwise

=item *

I<stp_mode>: Spanning tree operational mode; possible values: B<stpg> (802.1D), B<rstp> (802.1W), B<mstp> (802.1S)

=item *

I<mgmt_vlan>: In-band management VLAN number

=item *

I<mgmt_ip>: In-band management IP address

=item *

I<oob_ip>: Out-of-band IP address (only defined on devices which have an OOB port and have an IP address configured on it)

=item *

I<is_oob_connected>: Flag; true(1) if the connection to the device is to the oob_ip IP address; false(0) otherwise

=back



Attributes which only apply to B<ExtremeXOS> family type:

=over 4

=item *

I<is_xos>: Flag; true(1) if the device is an ExtremeXOS switch; false(0) otherwise.

=item *

I<unit_number>: Unit number we are connected to (Generaly the master unit, except when connecting via Serial) if a stack; undef otherwise

=item *

I<master_unit>: Master unit number, if a stack; undef otherwise

=item *

I<switch_mode>:

=over 4

=item *

B<Switch> : Standalone switch

=item *

B<Stack> : Stack of switches

=back

=item *

I<stack_size>: Number of units in the stack, if a stack; undef otherwise

=item *

I<stp_mode>: Spanning tree operational mode; possible values: B<stpg> (802.1D), B<rstp> (802.1W), B<mstp> (802.1S)

=item *

I<oob_ip>: Out-of-band IP address (only defined on devices which have an OOB port and have an IP address configured on it)

=item *

I<is_oob_connected>: Flag; true(1) if the connection to the device is to the oob_ip IP address; false(0) otherwise

=back



Attributes which only apply to B<ISW> family type:

=over 4

=item *

I<is_isw>: Flag; true(1) if the device is an ISW industrial switch; false(0) otherwise.

=back



Attributes which only apply to B<Wing> family type:

=over 4

=item *

I<is_wing>: Flag; true(1) if the device is a Wing AP or Controller; false(0) otherwise.

=back



Attributes which only apply to B<Series200> family type:

=over 4

=item *

I<unit_number>: Unit number we are connected to (always the stack manager unit) if a stack; undef otherwise

=item *

I<manager_unit>: Stack Manager unit number, if a stack; undef otherwise

=item *

I<switch_mode>:

=over 4

=item *

B<Switch> : Standalone switch

=item *

B<Stack> : Stack of switches

=back

=item *

I<stack_size>: Number of units in the stack, if a stack; undef otherwise

=item *

I<stp_mode>: Spanning tree operational mode; possible values: B<stpg> (802.1D), B<rstp> (802.1W), B<mstp> (802.1S), B<pvst>, B<rpvst>

=item *

I<oob_ip>: Out-of-band IP address (only defined on devices which have an OOB port and have an IP address configured on it)

=item *

I<is_oob_connected>: Flag; true(1) if the connection to the device is to the oob_ip IP address; false(0) otherwise

=back



Attributes which only apply to B<SLX> family type:

=over 4

=item *

I<is_slx>: Flag; true(1) if the device is an SLX switch.

=item *

I<is_slx_r>: Flag; true(1) if the device is an SLX-R switch.

=item *

I<is_slx_s>: Flag; true(1) if the device is an SLX-S switch.

=item *

I<is_slx_x>: Flag; true(1) if the device is an SLX-X switch.

=item *

I<switch_type>: Holds the numerical switch type of the SLX switch

=item *

I<is_active_mm>: Flag; true(1) if connected to the Active Manager Module (MM); currently always true on SLX9850 chassis

=item *

I<is_dual_mm>: Flag; true(1) if 2 Manager Module (MM) are present in the SLX9850 chassis; false(0) otherwise

=item *

I<mm_number>: Slot number of the Manager Module (MM) we are connected to; 0 on non-9850 SLX

=item *

I<is_ha>: Flag; true(1) if HA-mode is enabled; false(0) otherwise; undef if not applicable

=item *

I<stp_mode>: Spanning tree operational mode; possible values: B<stpg> (802.1D), B<rstp> (802.1W), B<mstp> (802.1S), B<pvst>, B<rpvst>

=item *

I<oob_ip>: Out-of-band IP address of Active Manager Module (MM)

=item *

I<oob_virt_ip>: Out-of-band Chassis Virtual IP address

=item *

I<oob_standby_ip>: Out-of-band IP address of Standby Manager Module (MM)

=item *

I<is_oob_connected>: Flag; true(1) if the connection to the device is to either the oob_ip or oob_virt_ip IP address; false(0) otherwise

=back



Attributes which only apply to B<Accelar> family type:

=over 4

=item *

I<is_master_cpu>: Flag; true(1) if connected to a Master CPU; false(0) otherwise

=item *

I<is_dual_cpu>: Flag; true(1) if 2 CPUs are present in the chassis; false(0) otherwise

=back



All available attributes on a given connection

=over 4

=item *

I<all>: Retuns a list (array reference) of all valid attributes for the current connection; this will include all Global attributes as well as all attributes corresponding to the family type specified by I<family_type>. This is useful for iterating through all available attributes in a foreach loop.

=back

In non-blocking mode (blocking disabled), if the attribute requested is not already set and thus CLI commands need to be sent to the connected device, the attribute() method will most likely immediately return with a false, but defined, value of 0. You will then need to call the attribute_poll() method at regular intervals until it returns a true (1) value indicating that the command is complete. The following example illustrates:

	($ok, $value) = $obj->attribute(Attribute => $attribute, Blocking => 0);
	until ($ok) {
		
		<do other stuff here..>
	
		($ok, $value) = $obj->attribute_poll;
	}
	print "Attribute $attribute value = ", $value, "\n" if defined $value;
	print "Attribute $attribute undefined\n" unless defined $value;



=item B<change_baudrate() & change_baudrate_poll()> - Change baud rate on current serial connection

Changing only local serial port:

  $ok = $obj->change_baudrate(
  	Local_side_only		=> 1,
  	[BaudRate		=> $baudRate,]
  	[ForceBaud		=> $flag,]
  	[Parity			=> $parity,]
  	[DataBits		=> $dataBits,]
  	[StopBits		=> $stopBits,]
  	[Handshake		=> $handshake,]
  	[Errmode		=> $errmode,]
  );


Changing host and serial port together (backward compatible syntax):

  $baudrate = $obj->change_baudrate($baudrate);

  $baudrate = $obj->change_baudrate(
  	BaudRate		=> $baudrate,
  	[ForceBaud		=> $flag,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );


Changing host and serial port together (new syntax for non-blocking use):

  $ok = $obj->change_baudrate(
	Poll_syntax		=> 1,
  	BaudRate		=> $baudrate,
  	[ForceBaud		=> $flag,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );

  ($ok, $baudrate) = $obj->change_baudrate($baudrate);

  ($ok, $baudrate) = $obj->change_baudrate(
	[Poll_syntax		=> 1,]
  	BaudRate		=> $baudrate,
  	[ForceBaud		=> $flag,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );

Polling method (only applicable in non-blocking mode):

  $ok = $obj->change_baudrate_poll();

  ($ok, $baudrate) = $obj->change_baudrate_poll();

This method is only applicable to an already established Serial port connection and will return an error if the connection type is Telnet or SSH or if the object type is for Serial but no connection is yet established.

If the 'local_side_only' argument is set this method will simply call the Control::CLI method by the same name which will simply change the baudrate (and/or parity, databits, stopbits, handshake) of the current serial connection without trying to also change the baudrate on the device we are connected to. This is equivalent to simply calling SUPER::change_baudrate().

Without the 'local_side_only' argument set, this method combines the knowledge of the Extreme device type we are connected to by automatically changing the baudrate configuration on the attached device before actually changing the baudrate of the connection. Thus if the attribute family_type is not yet defined or is set to 'generic' then an error will be returned. From this point onwards, the behaviour of this method upon failure will depend on whether a specific baudrate was provided or whether the desired baudrate was specified as 'max'. In the former case any failure to set the requested baudrate will trigger the error mode action whereas in the latter case it is assumed that the desire is to try and maximise the connection baudrate if possible but that we do not want to generate an error if that is not possible.

The ability to change the baudrate configuration on the attached device is currently only available when the attribute family_type is either BaystackERS or PassportERS. For any other family_type (including 'generic', SecureRouter & WLAN2300) this method will simply return success in 'max' mode and the error mode action otherwise (there is no way to change the baudrate configuration on SecureRouter & WLAN2300 devices to a value other than 9600 baud; there is no knowledge on how to do so on 'generic' devices). Even on some BaystackERS or PassportERS devices it is not possible to change the baudrate (e.g. ERS-4x00, Passport-1600, Passport-8300 and some APLS switches) and again this method will simply return success in 'max' mode and the error mode action otherwise.

When changing the baudrate of the local connection this method calls Control::CLI::change_baudrate() which will restart the object serial connection with the new baudrate (in the background, the serial connection is actually disconnected and then re-connected) without losing the current CLI session.
If there is a problem restarting the serial port connection at the new baudrate then the error mode action is performed (now also in 'max' mode) - see errmode().
If the baudrate was successfully changed the value of the new baudrate (a true value) is returned.
The advantage of using this method to increase the baudrate to a higher value than 9600 is that when retrieving commands which generate a large amount of output, this can be read in a lot faster if the baudrate is increased.

Remember to restore the baudrate configuration of the attached device to default 9600 when done or anyone connecting to its serial port thereafter will have to guess the baudrate! To minimize the chance of this happening the disconnect & destroy methods for this class will automatically try to restore whatever baudrate was used when initially connecting to the device.

Supported baudrates for this method are:

=over 4

=item *

B<BaystackERS>: 9600, 19200, 38400 or 'max' (where 'max' = 38400)

=item *

B<PassportERS>: 9600, 19200, 38400, 57600, 115200 or 'max' (where 'max' = 115200)

=back

Follows an example:

	use Control::CLI;
	# Create the object instance for Serial port
	$cli = new Control::CLI('COM1');
	# Connect to switch
	$cli->connect(
			Baudrate 	=> 9600,
			Username	=> $username,
			Password	=> $password,
		);
	# Get the config
	$output = $cli->cmd(
			Command		=> "show running-config",
			Progress_dots	=> 100,
		);
	# Increase the baudrate
	$maxBaudrate = $cli->change_baudrate('max');
	print "Baudrate increased to $maxBaudrate" if $maxBaudrate;
	# Get the config a 2nd time (4 times faster on BaystackERS; 12 times faster PassportERS)
	$output = $cli->cmd(
			Command		=> "show running-config",
			Progress_dots	=> 100,
		);
	# Restore the baudrate
	$cli->change_baudrate(9600);
	# Disconnect
	$cli->disconnect;


In non-blocking mode (blocking disabled), the change_baudrate() method will most likely immediately return with a false, but defined, value of 0. You will then need to call the change_baudrate_poll() method at regular intervals until it returns a true (1) value indicating that the change is complete. The following example illustrates:

	($ok, $baudrate) = $obj->change_baudrate(BaudRate => $baudrate, Blocking => 0);
	until ($ok) {
		
		<do other stuff here..>
	
		($ok, $baudrate) = $obj->change_baudrate_poll;
	}
	print "New baudrate = ", $baudrate, "\n";


=item B<enable() & enable_poll()> - Enter PrivExec mode

  $ok = $obj->enable($enablePassword);

  $ok = $obj->enable(
  	[Password		=> $enablePassword,]
  	[Prompt_credentials	=> $flag,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );

  $ok = $obj->enable_poll();	# Only applicable in non-blocking mode

This method checks whether the 'is_acli' attribute is set and, if so, whether the last prompt ends with '>'; if both conditions are true, it will flush any unread pending input from the device and will just send an 'enable' command to enter Priviledge Executive mode. If either of the above conditions are not met then this method will simply return a true (1) value.
The method can take a password argument which only applies to the WLAN2300 series and in some older software versions of the ERS-8300 in NNCLI mode.
If a password is required, but not supplied, this method will try supplying first a blank password, then the same password which was used to connect/login and finally, if prompt_credentials is true for the object, prompt for it. On I/O failure, the error mode action is performed. See errmode().
The optional "prompt_credentials" argument is provided to override the global setting of the parameter by the same name which is by default false. See prompt_credentials().

In non-blocking mode (blocking disabled), the enable() method will most likely immediately return with a false, but defined, value of 0. You will then need to call the enable_poll() method at regular intervals until it returns a true (1) value indicating that the change is complete. The following example illustrates:

	$ok = $obj->enable(Blocking => 0);
	until ($ok) {
		
		<do other stuff here..>
	
		$ok = $obj->enable_poll;
	}



=item B<device_more_paging() & device_more_paging_poll()> - Enable/Disable more paging on host device

  $ok = $obj->device_more_paging($flag);

  $ok = $obj->device_more_paging(
  	Enable			=> $flag,
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );

  $ok = $obj->device_more_paging_poll();	# Only applicable in non-blocking mode

This method issues the necessary CLI commands to turn on/off --more-- paging on the connected device. It relies on the setting of family_type attribute - see attribute() - to send the appropriate commands.
If an error occurs while sending the necessary CLI commands, then the error mode action is performed. See errmode().
Returns a true value (1) on success.

In non-blocking mode (blocking disabled), the device_more_paging() method will most likely immediately return with a false, but defined, value of 0. You will then need to call the device_more_paging_poll() method at regular intervals until it returns a true (1) value indicating that the change is complete. The following example illustrates:

	$ok = $obj->device_more_paging(Enable => 0, Blocking => 0);
	until ($ok) {
		
		<do other stuff here..>
	
		$ok = $obj->device_more_paging_poll;
	}


=item B<device_peer_cpu() & device_peer_cpu_poll()> - Connect to peer CPU on ERS8x00 / VSP9000

  $ok = $obj->device_peer_cpu(
  	[Username		=> $username,]
  	[Password		=> $password,]
  	[Prompt_credentials	=> $flag,]
  	[Blocking		=> $flag,]
  	[Timeout		=> $secs,]
  	[Errmode		=> $errmode,]
  );

  $ok = $obj->device_peer_cpu_poll();	# Only applicable in non-blocking mode

This method, only applicable on ERS8x00 and VSP9000, will try to connect to the peer CPU. On success a true (1) value is returned otherwise the error mode action is performed. See errmode().
It should not normally be necessary to provide username/password since the credentials used to connect to the current CPU will automatically be used. If not so, or to override the cached ones, optional "username" & "password" arguments can be provided.
Attributes 'cpu_slot' and 'is_master_cpu' are automatically updated once the connection to the peer CPU succeeds. See attribute().

In non-blocking mode (blocking disabled), the device_peer_cpu() method will most likely immediately return with a false, but defined, value of 0. You will then need to call the device_peer_cpu_poll() method at regular intervals until it returns a true (1) value indicating that the change is complete. The following example illustrates:

	$ok = $obj->device_peer_cpu(Blocking => 0);
	until ($ok) {
		
		<do other stuff here..>
	
		$ok = $obj->device_peer_cpu_poll;
	}


=back



=head2 Methods to set/read Object variables

=over 4

=item B<flush_credentials> - flush the stored username, password, passphrase and enable password credentials

  $obj->flush_credentials;

The connect(), login() and enable() methods, if successful in authenticating, will automatically store the username/password/enable-password or SSH passphrase supplied to them.
These can be retrieved via the username, password, passphrase and enable_password methods. If you do not want these to persist in memory once the authentication has completed, use this method to flush them. This method always returns 1.


=item B<prompt()> - set the CLI prompt match pattern for this object

  $string = $obj->prompt;

  $prev = $obj->prompt($string);

This method sets the CLI prompt match patterns for this object. In the first form the current pattern match string is returned. In the second form a new pattern match string is set and the previous setting returned.
If no prompt has yet been set (connection not yet established) undef is returned.
The object CLI prompt pattern is automatically set by the connect(), login() and cmd(reset_prompt => 1) methods and normally does not need to be set manually unless the CLI prompt is expected to change.
Once set, the object CLI prompt match pattern is only used by the cmd() and cmd_prompted() methods.


=item B<more_prompt()> - set the CLI --More-- prompt match pattern for this object

  $string = $obj->more_prompt;

  $prev = $obj->more_prompt($string [, $delayPrompt]);

This method sets the CLI --More-- prompt match patterns for this object. In the first form the current pattern match string is returned. In the second form a new pattern match string is set and the previous setting returned (the $delayPrompt can be set as a subset of $string if $string accepts multiple patterns some of which are subsets of others).
If no prompt has yet been set (connection not yet established) undef is returned.
The object's CLI --More-- prompt pattern is automatically set by the connect() and login() methods based upon the device type detected during login. Normally there should be no need to set this manually.
Once set, the object CLI --More-- prompt match patterns is only used by the cmd() and cmd_prompted() methods.


=item B<more_paging()> - sets the number of pages to read when device output is paged by --more-- prompts

  $numberOfPages = $obj->more_paging;

  $prev = $obj->more_paging($numberOfPages);

When issuing CLI commands, using cmd() or cmd_prompted(), which generate large amount of output, the host device will automatically page the output with --more-- prompts where the user can either view the next page, by sending a Space character, or terminate the CLI command, by sending a q character.
This method sets the number of pages of output that both cmd() and cmd_prompted() will retrieve before sending a q character and thus terminating the CLI command. Hence if more_paging is set to 1, only one page of output will be collected and a q character will be sent to the first --more-- prompt received. if more_paging is set to 2, two pages of output will be collected and a q character will be sent to the second --more-- prompt received.
By default more_paging is set to 0, which means that the entire output of any issued command will be retrieved, by always feeding Space characters to every --more-- prompt encountered.
Note however that for best performance, if the entire output of a command is required, it is best to disable --more-- paging direcly on the host device rather than letting cmd() or cmd_prompted() feed a Space to every --more-- prompt encountered; see device_more_paging().
This setting can also be overridden directly in cmd() or cmd_prompted() using the 'more_pages' argument.
In the first form the current setting of more_paging is returned; in the second form a more_paging setting is configured and the previous setting returned.


=item B<progress_dots()> - configure activity dots for cmd() and cmd_prompted() methods

  $prevBytesPerDot = $obj->progress_dots($bytesPerDot);

With this method it is possible to enable cmd() - and cmd_prompted() - to print activity dots (....) as input data is read from the host device. This is useful if the command sent to the host device returns large amount of data (e.g. "show tech") and/or it takes a long time for the host device to complete the command and return a CLI prompt.
To enable the functionality set $bytesPerDot to a non zero value; this value will represent every how many bytes of input data read an activity dot will be printed. For example set a value of 1000.
To disable the functionality simply configure it with a zero value.
By default this functionality is disabled.


=item B<return_result()> - set whether cmd methods should return output or the success/failure of the command 

  $flag = $obj->return_result;

  $prev = $obj->return_result($flag);

This method gets or sets the setting for return_result for the object.
This applies to the cmd() and cmd_prompted() methods and determines whether these methods should return the success or failure of the issued command (i.e. a true/false value) or instead the output generated by the command. By default return_result is false (0) and the output of the command is returned.


=item B<last_cmd_success()> - Returns the result of the last command sent via a cmd method

  $result = $obj->last_cmd_success;

  $prev = $obj->last_cmd_success($result);

This method returns the outcome (true or false) of the last command sent to the host via any of the cmd() or cmd_prompted() methods. If the command generated no error messages on the host, then the command was successful and the result is true (1). If instead an error message was generated by the host, then the command is deemed unsuccesful and the result is false (0). The second form allows the outcome to be manually set.
Note that the same information can be directly obtained from the above mentioned cmd methods by simply enabling the 'return_result' object parameter, or method argument.
Note also that this functionality is only available if the host is detected as an Extreme Networking product, i.e. the I<family_type> attribute is set to a value other than B<generic> - see attribute(). If the I<family_type> attribute is set to B<generic> then this method will always return undef.


=item B<last_cmd_errmsg()> - returns the last command error message received from connected host

  $msg = $obj->last_cmd_errmsg;

  $prev = $obj->last_cmd_errmsg($msg);

The first calling sequence returns the cmd error message associated with the object. Undef is returned if no error has been encountered yet. The second calling sequence sets the cmd error message for the object.
If the attached device is detected as an Extreme Networking product, i.e. the I<family_type> attribute is set to a value other than B<generic>, and a command is issued to the host via cmd() or cmd_prompted(), and this command generates an error on the host, then the last_cmd_success will be set to false and the actual error message will be available via this method. The string returned will include the device prompt + command echoed back by the device (on the first line) and the error message and pointer on subsequent lines. The error message will be held until a new command generates a new error message. In general, only call this method after checking that the last_cmd_success() method returns a false value.


=item B<cmd_confirm_prompt()> - set the Y/N confirm prompt expected from certain device CLI commands

  $string = $obj->cmd_confirm_prompt;

  $prev = $obj->cmd_confirm_prompt($string);

This method sets the Y/N confirm prompt used by the object instance to match confirmation prompts that Extreme Networking devices will generate on certain CLI commands.
The cmd() method will use this patterm match to detect these Y/N confirmation prompts and automatically feed a 'Y' to them so that the command is executed as you would expect when scripting the device - see cmd(). In the event you want to feed a 'N' instead, refer to cmd_prompted().
The default prompt match pattern used is:

  '[\(\[] *(?:[yY](?:es)? *(?:[\\\/]|or) *[nN]o?|[nN]o? *(?:[\\\/]|or) *[yY](?:es)?|y - .+?, n - .+?, <cr> - .+?) *[\)\]](?: *[?:] *| )$'

The first form of this method allows reading the current setting; the latter will set the new Y/N prompt and return the previous setting.


=item B<cmd_initiated_prompt()> - Set the prompt that certain device CLI commands will generate to request additional info

  $string = $obj->cmd_initiated_prompt;

  $prev = $obj->cmd_initiated_prompt($string);

This method sets the prompt used by the object instance to match the prompt that certain Extreme Networking device CLI commands will generate to request additional info.
This is used exclusively by the cmd_prompted() method which is capable to detect these prompts and feed the required information to them. See cmd_prompted().
The default prompt match pattern used is:

  '[?:=]\h*(?:\(.+?\)\h*)?$'

This method can also be used if you wish to feed a 'N' to Y/N prompts, unlike what is automaticaly done by the cmd() method.
The first form of this method allows reading the current setting; the latter will set the new prompt and return the previous setting.


=item B<cmd_feed_timeout()> - Set the number of times we skip command prompts before giving up

  $value = $obj->cmd_feed_timeout;

  $prev = $obj->cmd_feed_timeout($value);

If a CLI command is found to generate a prompt for additional data - i.e. a match was found for string defined by cmd_initiated_prompt() - and no data was provided to feed to the command (either because of insufficient feed data in cmp_promted() or if using cmd() which cannot supply any feed data) the cmd methods will automatically feed a carriage return to such prompts in the hope of getting to the next CLI prompt and return.
If however these command prompts for additional data were indefinite, the cmd methods would never return.
This method sets a limit to the number of times that an empty carriage return is fed to these prompts for more data for which we have no data to feed. When that happens the cmd method will timeout and the error mode action is performed.
The same value will also set an upper limit to how many times a 'y' is fed to Y/N confirm prompts for the same command in the cmd() method. 
The default value is set to 10.


=item B<console()> - Enable or Disable object console mode, wich triggers sending the wake_console string on connection/login

  $value = $obj->console;

  $prev = $obj->console($flag);

When connecting to the serial console port of a device it is necessary to send some characters to trigger the device at the other end to respond. These characters are defined in wake_console() and are automatically sent when the object console mode is true. By default the object console is undefined, and automatically updates itself to true when connecting via Serial, or Telnet (with port other than 23) or SSH (with port other than 22). The latter two generally represent connection to some terminal server deivce.
To prevent the object console mode from auto updating following connection, you may set it with this method to a defined false value (0); this will result in wake_console being permanently disabled.
Alternatively, to force wake_console to be sent even on regular Telnet/SSH connections, you may set it with this method to a true value. This approach is needed when connecting via Telnet to an XOS switch which is configured with a 'before-login' banner which has to be acknowledged. In this case the XOS switch will not request a login until the user has hit a key; setting this method to 1 (or setting the Console argument to 1 in the object constructor) will ensure that the XOS banner is acknowledged and the login will not time-out.


=item B<wake_console()> - Set the character sequence to send to wake up device when connecting to console port

  $string = $obj->wake_console;

  $prev = $obj->wake_console($string);

When connecting to the serial console port of a device it is necessary to send some characters to trigger the device at the other end to respond. These characters can be defined using this method. By default the wake string is "\n". The wake string is sent when the console mode of the connection is true - see console(). By default this happens when connecting via Serial port as well as via Telnet (with port other than 23) or via SSH (with port other than 22), i.e. via a Terminal Server device. See  Setting the wake sequence to the empty string, will disable it.


=item B<no_refresh_cmd()> - set pattern and send character to automatically come out of refreshed commands

  $pattern = $obj->no_refresh_cmd;

  $prev = $obj->no_refresh_cmd($pattern, $sendCharacter);

Some commands on some devices endlessly refresh the output requested (e.g. commands showing statistics on ExtremeXOS). This is not desireable when scripting the CLI using the cmd() methods as these commands would result in cmd() the methods never returning, as output keeps being read indefinitely and no final CLI prompt is ever seen.
This method is used to set a pattern to detect the such refreshing commands from their output, as well as a send character to send to the host in order to break out immediately from the refresh cycle. Suitable patterns for ExtremeXOS and PassportERS family types are automatically setup by the connect() and login() methods based upon the device type detected during login.
Normally there should be no need to set this manually. This method can also be used to disable the automatically set pattern, by simply calling the method with $pattern set to the empty string.
Once set, these patterns are only used by the cmd() and cmd_prompted() methods.


=item B<debug()> - set debugging

  $debugLevel = $obj->debug;

  $prev = $obj->debug($debugLevel);

Enables debugging for the object methods and on underlying modules.
In the first form the current debug level is returned; in the second form a debug level is configured and the previous setting returned.
By default debugging is disabled. To disable debugging set the debug level to 0.
The following debug levels are defined:

=over 4

=item *

0 : No debugging

=item *

bit 1 : Control::CLI - Debugging activated for for polling methods + readwait() and enables carping on Win32/Device::SerialPort. This level also resets Win32/Device::SerialPort constructor $quiet flag only when supplied in Control::CLI::new()

=item *

bit 2 : Control::CLI - Debugging is activated on underlying Net::SSH2 and Win32::SerialPort / Device::SerialPort; there is no actual debugging for Net::Telnet

=item *

bit 4 : Control::CLI::Extreme - Basic debugging

=item *

bit 8 : Control::CLI::Extreme - Extended debugging of login() & cmd() methods

=back


=item B<debug_file()> - set debug output file

  $fh = $obj->debug_file;

  $fh = $obj->debug_file($fh);

  $fh = $obj->debug_file($fileName);

This method starts or stops logging debug messages to a file.
If no argument is given, the log filehandle is returned. An empty string indicates logging is off. If an open filehandle is given, it is used for logging and returned. Otherwise, the argument is assumed to be the name of a file, the file is opened for logging and a filehandle to it is returned. If the file can't be opened for writing, the error mode action is performed.
To stop logging debug messages to a file, call this method with an empty string as the argument.
Note that if no debug_file is defined all debug messages will be printed to STDOUT. To set or stop debugging use the debug() method.

=back




=head2 Methods to access Object read-only variables

=over 4

=item B<config_context> - read configuration context of last prompt

  $configContext = $obj->config_context;

Returns the configuration context included in the last prompt received from the host device.
For example if the last prompt received from the device was 'switch(config-if)#' this method will return 'config-if'.
While if the last prompt was in the form 'switch/config/ip#' this method will return '/config/ip'.
If the device was not in config mode at the last prompt, this method returns an empty string ''.


=item B<enable_password> - read enable password provided

  $enablePassword = $obj->enable_password;

Returns the last enable password which was successfully used in the enable() method, or undef otherwise.
Of the supported family types only the WLAN2300 requires a password to access privExec mode. 


=back



=head2 Methods overridden from Control::CLI 

=over 4

=item B<connect() & connect_poll()> - connect to host

=item B<login() & login_poll()> - handle login for Telnet / Serial port 

=item B<cmd() & cmd_poll()> - Sends a CLI command to host and returns output data

=item B<change_baudrate()> - Change baud rate on current serial connection

=item B<prompt()> - set the CLI prompt match pattern for this object

=item B<disconnect()> - disconnect from host

=back



=head2 Methods inherited from Control::CLI 

=over 4

=item B<read()> - read block of data from object

=item B<readwait()> - read in data initially in blocking mode, then perform subsequent non-blocking reads for more

=item B<waitfor() & waitfor_poll()> - wait for pattern in the input stream

=item B<put()> - write data to object

=item B<print()> - write data to object with trailing output_record_separator

=item B<printlist()> - write multiple lines to object each with trailing output_record_separator

=item B<input_log()> - log all input sent to host

=item B<output_log()> - log all output received from host

=item B<dump_log()> - log hex and ascii for both input and output stream

=item B<eof> - end-of-file indicator

=item B<break> - send the break signal

=item B<close> - disconnect from host

=item B<poll> - poll object(s) for completion

=item B<debug()> - set debugging

=back


=head2 Error Handling Methods inherited from Control::CLI

=over 4

=item B<errmode()> - define action to be performed on error/timeout 

=item B<errmsg()> - last generated error message for the object 

=item B<errmsg_format()> - set the format to be used for object error messages 

=item B<error()> - perform the error mode action

=back


=head2 Methods to set/read Object variables inherited from Control::CLI

=over 4

=item B<timeout()> - set I/O time-out interval 

=item B<connection_timeout()> - set Telnet and SSH connection time-out interval 

=item B<read_block_size()> - set read_block_size for either SSH or Serial port 

=item B<blocking()> - set blocking mode for read methods and polling capable methods

=item B<read_attempts()> - set number of read attempts used in readwait() method

=item B<readwait_timer()> - set the polling timer used in readwait() method

=item B<data_with_error()> - set the readwait() method behaviour in case a read error occurs after some data was read

=item B<return_reference()> - set whether read methods should return a hard reference or not 

=item B<output_record_separator()> - set the Output Record Separator automatically appended by print & cmd methods (Note that unlike Control::CLI this class will default to "\r")

=item B<prompt_credentials()> - set whether connect() and login() methods should be able to prompt for credentials 

=item B<username_prompt()> - set the login() username prompt match pattern for this object

=item B<password_prompt()> - set the login() password prompt match pattern for this object

=item B<terminal_type()> - set the terminal type for the connection

=item B<window_size()> - set the terminal window size for the connection

=item B<report_query_status()> - set if read methods should automatically respond to Query Device Status escape sequences 

=back


=head2 Methods to access Object read-only variables inherited from Control::CLI

=over 4

=item B<parent> - return parent object

=item B<ssh_channel> - return ssh channel object

=item B<ssh_authentication> - return ssh authentication type performed

=item B<connection_type> - return connection type for object

=item B<host> - return the host for the connection

=item B<port> - return the TCP port / COM port for the connection

=item B<last_prompt> - returns the last CLI prompt received from host

=item B<username> - read username provided

=item B<password> - read password provided

=item B<passphrase> - read passphrase provided

=item B<handshake> - read handshake used by current serial connection

=item B<baudrate> - read baudrate used by current serial connection

=item B<parity> - read parity used by current serial connection

=item B<databits> - read databits used by current serial connection

=item B<stopbits> - read stopbits used by current serial connection

=back



=head2 Methods for modules sub-classing Control::CLI::Extreme inherited from Control::CLI

=over 4

=item B<poll_struct()> - sets up the polling data structure for non-blocking capable methods

=item B<poll_struct_cache()> - caches selected poll structure keys, if a nested polled method is called

=item B<poll_struct_restore()> - restores previously cached poll structure keys, if a nested polled method was called

=item B<poll_reset()> - resets poll structure

=item B<poll_return()> - return status and optional output while updating poll structure

=item B<poll_sleep()> - performs a sleep in blocking or non-blocking mode

=item B<poll_open_socket()> - opens TCP socket in blocking or non-blocking mode

=item B<poll_read()> - performs a non-blocking poll read and handles timeout in non-blocking polling mode

=item B<poll_readwait()> - performs a non-blocking poll readwait and handles timeout in non-blocking polling mode

=item B<poll_waitfor()> - performs a non-blocking poll for waitfor()

=back


=head2 Methods for modules sub-classing overridden from Control::CLI

=over 4

=item B<poll_connect()> - performs a non-blocking poll for connect()

=item B<poll_login()> - performs a non-blocking poll for login()

=item B<poll_cmd()> - performs a non-blocking poll for cmd()

=item B<poll_change_baudrate()> - performs a non-blocking poll for change_baudrate()

=item B<debugMsg()> - prints out a debug message

=back


=head2 Methods for modules sub-classing Control::CLI::Extreme

=over 4

=item B<poll_connect()> - performs a non-blocking poll for connect()

  $ok = $obj->poll_connect($pkgsub,
  	[Host                   => $host,]
  	[Port                   => $port,]
  	[Username               => $username,]
  	[Password               => $password,]
  	[PublicKey              => $publicKey,]
  	[PrivateKey             => $privateKey,]
  	[Passphrase             => $passphrase,]
  	[Prompt_credentials     => $flag,]
  	[BaudRate               => $baudRate,]
  	[Parity                 => $parity,]
  	[DataBits               => $dataBits,]
  	[StopBits               => $stopBits,]
  	[Handshake              => $handshake,]
  	[Login_Timeout          => $secs,]
  	[Connection_timeout     => $secs,]
  	[Read_attempts          => $numberOfLoginReadAttemps,]
  	[Data_with_error        => $flag,]
  	[Wake_console           => $string,]
  	[Errmode                => $errmode,]
  	[Terminal_type		=> $string,]
  	[Window_size		=> [$width, $height],]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

  ($ok, $outputref) = $obj->poll_connect($pkgsub,
  	[Host                   => $host,]
  	[Port                   => $port,]
  	[Username               => $username,]
  	[Password               => $password,]
  	[PublicKey              => $publicKey,]
  	[PrivateKey             => $privateKey,]
  	[Passphrase             => $passphrase,]
  	[Prompt_credentials     => $flag,]
  	[BaudRate               => $baudRate,]
  	[Parity                 => $parity,]
  	[DataBits               => $dataBits,]
  	[StopBits               => $stopBits,]
  	[Handshake              => $handshake,]
  	[Login_Timeout          => $secs,]
  	[Connection_timeout     => $secs,]
  	[Read_attempts          => $numberOfLoginReadAttemps,]
  	[Data_with_error        => $flag,]
  	[Wake_console           => $string,]
  	[Errmode                => $errmode,]
  	[Terminal_type		=> $string,]
  	[Window_size		=> [$width, $height],]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

Normally this is the internal method used by connect() and connect_poll() methods.
Arguments after $ok will only be defined if $ok is true(1).


=item B<poll_login()> - performs a non-blocking poll for login()

  $ok = $obj->poll_login($pkgsub,
  	[Username               => $username,]
  	[Password               => $password,]
  	[Prompt_credentials     => $flag,]
  	[Timeout                => $secs,]
  	[Read_attempts          => $numberOfLoginReadAttemps,]
  	[Data_with_error        => $flag,]
  	[Wake_console           => $string,]
  	[Errmode                => $errmode,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

  ($ok, $outputref) = $obj->poll_login($pkgsub,
  	[Username               => $username,]
  	[Password               => $password,]
  	[Prompt_credentials     => $flag,]
  	[Timeout                => $secs,]
  	[Read_attempts          => $numberOfLoginReadAttemps,]
  	[Data_with_error        => $flag,]
  	[Wake_console           => $string,]
  	[Errmode                => $errmode,]
  	[Non_recognized_login	=> $flag,]
  	[Generic_login		=> $flag,]
  );

Normally this is the internal method used by login() and login_poll() methods.
Arguments after $ok will only be defined if $ok is true(1).


=item B<poll_cmd()> - performs a non-blocking poll for cmd()

  $ok = $obj->poll_cmd($pkgsub, $cliCommand);

  $ok = $obj->poll_cmd($pkgsub,
  	[Command                => $cliCommand,]
  	[Feed_list              => \@arrayRef,]
  	[Prompt                 => $prompt,]
  	[Reset_prompt           => $flag,]
  	[More_prompt            => $morePrompt,]
  	[More_pages             => $numberOfPages,]
  	[Cmd_confirm_prompt     => $ynPrompt,]
  	[Cmd_initiated_prompt   => $cmdPrompt,]
  	[Timeout                => $secs,]
  	[Progress_dots          => $bytesPerDot,]
  	[Errmode                => $errmode,]
  );

  ($ok, $outputref[, $resultref]) = $obj->poll_cmd($pkgsub, $cliCommand);

  ($ok, $outputref[, $resultref]) = $obj->poll_cmd($pkgsub,
  	[Command                => $cliCommand,]
  	[Feed_list              => \@arrayRef,]
  	[Prompt                 => $prompt,]
  	[Reset_prompt           => $flag,]
  	[More_prompt            => $morePrompt,]
  	[More_pages             => $numberOfPages,]
  	[Cmd_confirm_prompt     => $ynPrompt,]
  	[Cmd_initiated_prompt   => $cmdPrompt,]
  	[Timeout                => $secs,]
  	[Progress_dots          => $bytesPerDot,]
  	[Errmode                => $errmode,]
  );

Normally this is the internal method used by cmd(), cmd_prompted() and cmd_poll() methods.
Arguments after $ok will only be defined if $ok is true(1).


=item B<poll_attribute()> - performs a non-blocking poll for attribute()

  $ok = $obj->poll_attribute($pkgsub, $attribute);

  $ok = $obj->poll_attribute($pkgsub,
  	[Attribute               => $attribute,]
  	[Reload                 => $flag,]
  	[Timeout                => $secs,]
  	[Errmode                => $errmode,]
  );

  ($ok, $valueref) = $obj->poll_attribute($pkgsub, $attribute);

  ($ok, $valueref) = $obj->poll_attribute($pkgsub,
  	[Attribute               => $attribute,]
  	[Reload                 => $flag,]
  	[Timeout                => $secs,]
  	[Errmode                => $errmode,]
  );

Normally this is the internal method used by attribute() and attribute_poll() methods.
Arguments after $ok will only be defined if $ok is true(1).


=item B<poll_change_baudrate()> - performs a non-blocking poll for change_baudrate()

  $ok = $obj->poll_change_baudrate($pkgsub, $baudrate);

  $ok = $obj->poll_change_baudrate($pkgsub,
  	[BaudRate               => $baudRate,]
  	[Timeout		=> $secs,]
  	[Errmode                => $errmode,]
  );

  ($ok, $baudrateref) = $obj->poll_change_baudrate($pkgsub, $baudrate);

  ($ok, $baudrateref) = $obj->poll_change_baudrate($pkgsub,
  	[BaudRate               => $baudRate,]
  	[Timeout		=> $secs,]
  	[Errmode                => $errmode,]
  );

Normally this is the internal method used by change_baudrate() and change_baudrate_poll() methods.
Arguments after $ok will only be defined if $ok is true(1).


=item B<poll_enable()> - performs a non-blocking poll for enable()

  $ok = $obj->poll_enable($pkgsub, $password);

  $ok = $obj->poll_enable($pkgsub,
  	[Password               => $enablePassword,]
  	[Prompt_credentials     => $flag,]
  	[Timeout                => $secs,]
  	[Errmode                => $errmode,]
  );

Normally this is the internal method used by enable() and enable_poll() methods.

=item B<poll_device_more_paging()> - performs a non-blocking poll for device_more_paging()

  $ok = $obj->poll_device_more_paging($pkgsub, $flag);

  $ok = $obj->poll_device_more_paging($pkgsub,
  	[Enable                 => $flag,]
  	[Timeout                => $secs,]
  	[Errmode                => $errmode,]
  );

Normally this is the internal method used by device_more_paging() and device_more_paging_poll() methods.


=item B<poll_device_peer_cpu()> - performs a non-blocking poll for device_peer_cpu()

  $ok = $obj->poll_device_peer_cpu($pkgsub,
  	[Username               => $username,]
  	[Password               => $password,]
  	[Prompt_credentials     => $flag,]
  	[Timeout                => $secs,]
  	[Errmode                => $errmode,]
  );

Normally this is the internal method used by device_peer_cpu() and device_peer_cpu_poll() methods.


=item B<cmdPrivExec()> - send a command requiring PrivExec mode

  ($ok, $outputref, $resultref) = $obj->cmdPrivExec($pkgsub, $cmdcli, $cmdnncli, $morePages);

If the connected device is in ACLI mode this method will enter PrivExec mode, if not already in that mode, and then send $cmdnncli; after sending the command, if PrivExec mode was enabled, then this method will disable it to leave the device in exactly the same mode it was found in.
If instead the connected device is not in ACLI mode then it will simply send $cmdcli.
Arguments after $ok will only be defined if $ok is true(1).


=item B<cmdConfig()> - send a command requiring Config mode

  ($ok, $outputref, $resultref) = $obj->cmdConfig($pkgsub, $cmdcli, $cmdnncli);

If the connected device is in ACLI mode this method will enter PrivExec mode and then Config mode, if not already in that mode, and then send $cmdnncli; after sending the command, if PrivExec mode and/or Config mode were enabled, then this method will come out of them to leave the device in exactly the same mode it was found in.
If instead the connected device is not in ACLI mode then 'config ' is prepended to $cmdcli (if it is not already beginning with 'config ' string) and the resulting command is sent.
Arguments after $ok will only be defined if $ok is true(1).


=item B<discoverDevice()> - discover the family type of connected device

  ($ok, $familyType) = $obj->discoverDevice($pkgsub);

This method will issue CLI commands to the attached device and based on the output received will determine what family type it belongs to.
Arguments after $ok will only be defined if $ok is true(1).


=item B<debugMsg()> - prints out a debug message

  $obj->debugMsg($msgLevel, $string1 [, $stringRef [,$string2]]);

A logical AND is performed between $msgLevel and the object debug level - see debug(); if the result is true, then the message is printed.
The message can be provided in 3 chunks: $string1 is always present, followed by an optional string reference (to dump large amout of data) and $string2.
If a debug file was set - see debug_file() - then the messages are printed to that file instead of STDOUT.


=back

The above methods are exposed so that sub classing modules can leverage the functionality within new methods themselves implementing polling.
These newer methods would have already set up a polling structure of their own.
When calling poll_login() directly for the 1st time, it will detect an already existing poll structure and add itself to it (as well as caching some of it's keys; see poll_struct_cache). It will also read in the arguments provided at this point.
On subsequent calls, the arguments provided are ignored and the method simply polls the progress of the current task.



=head1 CLASS METHODS inherited from Control::CLI

Class Methods which are not tied to an object instance.
The Control::CLI::Extreme class expressly imports all of Control::CLI's class methods into itself.
However by default Control::CLI::Extreme class does not import anything when it is use-ed.
The following list is a sub-set of those Control::CLI class methods.
These should be called using their fully qualified package name or else they can be expressly imported when loading this module:

	# Import useTelnet, useSsh, useSerial & useIPv6
	use Control::CLI::Extreme qw(:use);

	# Import promptClear, promptHide & promptCredential
	use Control::CLI::Extreme qw(:prompt);

	# Import parseMethodArgs suppressMethodArgs
	use Control::CLI qw(:args);

	# Import validCodeRef callCodeRef
	use Control::CLI qw(:coderef);

	# Import all of Control::CLI class methods
	use Control::CLI::Extreme qw(:all);

	# Import just poll()
	use Control::CLI::Extreme qw(poll);

=over 4

=item B<useTelnet> - can Telnet be used ?

=item B<useSsh> - can SSH be used ?

=item B<useSerial> - can Serial port be used ?

=item B<useIPv6> - can IPv6 be used with Telnet or SSH ?

=item B<poll()> - poll objects for completion

=item B<promptClear()> - prompt for username in clear text

=item B<promptHide()> - prompt for password in hidden text

=item B<promptCredential()> - prompt for credential using either prompt class methods or code reference

=item B<passphraseRequired()> - check if private key requires passphrase

=item B<parseMethodArgs()> - parse arguments passed to a method against list of valid arguments

=item B<suppressMethodArgs()> - parse arguments passed to a method and suppress selected arguments

=item B<parse_errmode()> - parse a new value for the error mode and return it if valid or undef otherwise

=item B<stripLastLine()> - strip and return last incomplete line from string reference provided

=item B<validCodeRef()> - validates reference as either a code ref or an array ref where first element is a code ref

=item B<callCodeRef()> - calls the code ref provided (which should be a code ref or an array ref where first element is a code ref)

=back




=head1 AUTHOR

Ludovico Stevens <lstevens@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-control-cli-extreme at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Control-CLI-Extreme>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.



=head1 DISCLAIMER

Note that this module is in no way supported or endorsed by Extreme Inc.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Control::CLI::Extreme


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Control-CLI-Extreme>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Control-CLI-Extreme>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Control-CLI-Extreme>

=item * Search CPAN

L<http://search.cpan.org/dist/Control-CLI-Extreme/>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2020 Ludovico Stevens.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

# End of Control::CLI::Extreme
