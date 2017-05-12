#
# I set my vim to handle tabstops every 4 spaces
# :ts=4
#
# Utility Package used by ExecCmds

package ExecCmds::Utility;

use Socket;

# An updated Utility library which splits the login, get conf, logout process
# so that commands can be executed under enable mode.

use Net::Telnet::Cisco;

use strict;
use vars qw(@EXPORT @ISA $VERSION);
require Exporter;

$VERSION = "1.1";
@ISA	 = qw(Exporter);
@EXPORT  = qw($CISCO_IOS $CISCO_CATALYST $CISCO_WEIRD);

our $CISCO_IOS 			= 1;
our $CISCO_CATALYST 	= 2;
our $CISCO_WEIRD		= 3;

#
#=head1 NAME
#
#
#ExecCmds::Utility - Utility functions for use with Cisco devices.
#
#=head1 SYNOPSIS
#
#	my $cu = ExecCmds::Utility->new( cn=>'RN-48MA-05-2610-99' );
#
#	my @r = $cu->cmd("show mac");
#	print @r;
#	$cu->close;
#
#=head1 DESCRIPTION
#
#
#=cut

my $g_Debug = 0;


#=cut
#
#=item new
#
#Used by passing in the name of the device (cn=RN-48MA-01-6509-01), or
#passing in the ipaddress, username, password, execpassword and type. Type
#is defined as 1 for a normal IOS box or 2 for a Catalyst device.
#
#A connection is attempted straight away, enable mode is entered and paging
#is disabled.
#
#=cut

sub new {
	my $invocant    = shift;
	my $class       = ref($invocant) || $invocant;  # Object or class name
	my $self        = { @_ };
	bless($self, $class);

	my %checks;

	# Make sure we have enough to make a connection
	for my $att ('username', 'password', 'execpassword')
	{
		 unless( defined($self->{$att}))
		 {
		 	warn "Failed to find attribute: $att\n";
			return undef;
		 }
	}

	unless( defined($self->{'ipaddress'}) )
	{
		if( defined($self->{'cn'}) )
		{
			 my ($name,$aliases,$addrtype,$length,@addrs) = 
			 	gethostbyname($self->{'cn'});
			if( @addrs )
			{
				$self->{'ipaddress'} = inet_ntoa($addrs[0]);
			}
			else
			{
				warn "No IP found for ",$self->{'cn'},"\n";
				return undef;
			}

		}
		else
		{
			warn "No cn and or ipaddress defined\n";
			return undef;
		}
	}

	# get connected
	unless($self->connect() ) {
		undef($self);
	}

	return $self;
}

sub cn {
	my ($self, $cn) = @_;

	if(defined( $cn ) ) {
		$self->{'cn'} = $cn;
	}
	return $self->{'cn'};
}

sub new_password {
	my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9, qw(! @ $ % ^ & *) );
	return join("", @chars[ map { rand @chars } ( 1 .. 8 ) ]);
}


sub getTypeFromModel {
	my $model = shift;
	my %t=();

# 1:	Non-Catalyst Cisco
# 2:	Catalyst style Cisco	

	$t{'01'}	= 1;
	$t{'02'}	= 1;
	$t{'2523'}	= 1;
	$t{'0805'}	= 1;
	$t{'2610'}	= 1;
	$t{'2612'}	= 1;
	$t{'2912'}	= 1;
	$t{'2924'}	= 1;
	$t{'2948'}	= 2;
	$t{'2948G'}	= 2;
	$t{'3524'}	= 1;
	$t{'3640'}	= 1;
	$t{'3920'}	= 0;
	$t{'4006'}	= 2;
	$t{'6506'}	= 2;
	$t{'6509'}	= 2;
	$t{'7204'}	= 1;
	$t{'7206'}	= 1;
	$t{'7507'}	= 1;
	$t{'8540'}	= 1;
	$t{'MSFC'} 	= 1;
	$t{'R1'} 	= 1;

	if( defined( $t{$model} ) ) {
		return $t{$model};
	} else {
		return 0;
	}
}

# Assumes router name is like RN-XXXX-YY-MODEL-01
sub getTypeFromName {
	my $cn = shift;

	if( $cn =~ /\w\w-\w+-\w\w-(\w+)-\d+/) {
		return getTypeFromModel($1);
	} else {
#		warn "Unknown type: $cn\n";
		return 0;
	}
}

#=cut
#
#=item checkPasswordSecure
#
#This confirms that the password meets the minimum requirements of IPSM. Hand
#in the plain text password, returns true or false.
#
#=cut
sub checkPasswordSecure {
	my $pass = shift;

	return 0 unless(length($pass) >= 8);	# At least 8 characters
	return 0 unless($pass =~ /\d/);		# At least 1 digit
	return 0 unless($pass =~ /\w/);		# At least 1 letter

	return 1; 
}

#=cut
#
#=item getCiscoCommands
#
#Hand in the 'type' of the device and this returns a hash of equivalent
#commands- because the Catalyst and Cisco IOS command sets are different
#this can be used to abstracts the device from the implementation.
#
#=cut
sub getCiscoCommands {
	my $type=shift;

	my %cmd = ();

        if( $type == $CISCO_IOS ) {
                %cmd = (STOPPAGING	=> 'terminal length 0',
                	SHOWCONFIG	=> 'show running-config',
			ENPROMPTRE	=> qr|.*[\$%#>]\s?$|,
			SHOWCLOCK	=> 'show clock' );
        } elsif( $type == $CISCO_CATALYST) {
                %cmd = (STOPPAGING	=> 'set length 0',
                	SHOWCONFIG	=> 'show config all',
			ENPROMPTRE	=> qr|.*\(enable\)|,
			SHOWCLOCK	=> 'show time' );
        } else {
                warn "Weird type in getCiscoCommands\n";
        }

	return %cmd;
}

#=cut
#
#=item type
#
#If a 'type' value
#
#=cut
sub type {
	my($self, $comp) = @_;	# A possible 'comparison' type

	unless( defined($self->{'type'}) ) {
		$self->{'type'} = getTypeFromName($self->{'cn'} );
	}
	if( defined($comp) ) {
		return ( $self->{'type'} eq $comp );
	} else {
		return $self->{'type'};
	}
}

# Import elements of a hash without overwriting existing elements of
# $self.
sub subsume_hash {
	my ($self, $hr, @q) = @_;

	while(my $k = pop @q) {
		$self->{$k} = $hr->{$k} unless defined $self->{$k};
	}
}


# Dumb non-data base connection method
sub connect {
	my ($self) = @_;	# Device name and check hash ref
	
	my ($cmd, @cmd_output);

	my $cn = $self->{'cn'};
	my $timeout = $self->{'timeout'} || 60;

	# Connect
	$self->{'checks'}{'telnet'} = 0;
	my $cs = Net::Telnet::Cisco->new( Host => $self->{'ipaddress'}, 
					Dump_Log => "/tmp/$$.dump.log",
					Input_log => "/tmp/$$.input.log",
					Option_log => "/tmp/$$.option.log",
					Timeout => $timeout,
					Errmode => 'return' );
	unless(defined($cs)) {
		$self->error("Connection failed for $cn" );
		return 0;	
	}
	$self->{'CS'} = $cs;
	$self->{'checks'}{'telnet'} = 1;
	$cs->errmode( "return" );
	$cs->max_buffer_length(5 * 1024 * 1024); # 5 meg buffer
	$self->status("Telnet connected OK");

	# Login
	# Take Note:
	# This takes into account issues relating to machines that are loggin
	# to the VTY we are attached to. It relys on knowing that the ;ast 3
	# chars of the Net::Telnet::Cisco prompt regexp are $)/ and removing
	# the $ from it. This stops the prompt trying to match up to the end
	# of line
	my $oldprompt = $cs->prompt();   # save original prompt
	my $nonachored = $oldprompt;
	$nonachored =~ s%\$\)/$%)/%;
	$cs->prompt($nonachored);   # prompt minus the $ anchor
	$self->{'checks'}{'login'} = 0;
	unless(defined($cs->login( $self->{'username'}, $self->{'password'})) ) 
	{
		$self->error("Error logging in.");
		return 0;
	}
	$self->{'checks'}{'login'} = 1;
	$self->status("Logged in");

	# Enable
	$self->{'checks'}{'enable'} = 0;
	unless($cs->enable($self->{"execpassword"}))
	{
		$self->error("Can't enable: ".$cs->errmsg);
		return 0;
	}
	$self->{'checks'}{'enable'} = 1;
	$self->status("Enabled\n");

	# Now make sure we stop any message logging that maybe happening on
	# the vty. It clutters the ouput badly. It is OK for this command to
	# fail.
	my @r = $cs->cmd("set logging session disable");
	my $line = join( ' ', @r);
	if( $line =~ /Invalid input detected/ ) 
	{
		$self->{'type'} = $CISCO_IOS; # Probably IOS box
	} 
	else # System logging messages will not be sent
	{
		$self->{'type'} = $CISCO_CATALYST;
	}

	# Restore our prompt to  N:T:C original
	$cs->prompt($oldprompt);

	# Now try and determine type- uses the 'show ver' command to guess
	# Not we use $self->cmd not $cs->cmd because some routers page the
	# result back to us... grrr
	@r = $self->cmd("show ver");
	$line = join( ' ', @r);
	if( $line =~ /IOS|Catalyst 1900/ ) {
		$self->{'type'} = $CISCO_IOS;
	} else {
		$self->{'type'} = $CISCO_CATALYST;
	}
	
	# At this point we have been able to execute show ver and match the
	# prompt. So we know exactly what the prompt will look like. Lets
	# match on that in future as it is faster. we run sooo slooowly on
	# large out put
#	my $matched_prompt = $cs->last_prompt;
#	$matched_prompt =~ s/(\W)/\\$1/g;   #quote all non-"word" characters
#	$matched_prompt = '(?m:'.$matched_prompt. '$)';   # To anchor
#	$cs->prompt($matched_prompt);

	my %c = getCiscoCommands( $self->type() ); 
	unless(%c) {
		$self->error("Failed to retrieve Cisco commands");
		return 0;
	}
	$self->status("Retrieved Cisco commands");
	$self->subsume_hash(\%c, 'SHOWCLOCK', 'STOPPAGING',
				'SHOWCONFIG', 'ENPROMPTRE' );

	$self->{'checks'}{'paging'} = 0;
	$cmd = $self->{'STOPPAGING'};
	unless(my @cmd_output = $cs->cmd( $cmd ) ) {
		$self->error("Failed to execute command $cmd:\n\t".$cs->errmsg);
		$self->{'checks'}{'paging'} = 0;
		$self->status("Paging not stopped sorry\n");
		return 1;
	}
	$self->{'checks'}{'paging'} = 1;
	$self->status("Paging stopped\n");

	return 1;
}

sub getConfig {
	my ($self) = @_;
	my $cmd = $self->{'SHOWCONFIG'};

	my @c = $self->cmd($cmd);
	$self->{'config'} = \@c;
	return @c;
}

sub status {
	my ($self, $msg) = @_;

	if(defined($msg)) {
		$self->{'STATUS'} = $msg;
		warn uc($self->{'cn'}) . ": $msg\n" if( $self->{'debug'} );
	} else {
		return defined($self->{'STATUS'})?$self->{'STATUS'}:"";
	}
}

sub error {
	my ($self, $msg) = @_;

	if(defined($msg)) {
		$self->{'ERROR'} = $msg;
		warn uc($self->{'cn'}) . ": $msg\n" if( $self->{'debug'} );
	} else {
		return defined($self->{'ERROR'})?$self->{'ERROR'}:"";
	}
}

sub cmd {
	my ($self, $cmd) = @_;
	my $cs = $self->{'CS'};

	my @cmd_output;
	my $enpromptre = defined($self->{'ENPROMPTRE'})
						? $self->{'ENPROMPTRE'}
						: $cs->prompt;

	# First clean out status and error
	$self->status('');
	$self->error('');

	# If we managed to stop paging
	if($self->{'checks'}{'paging'})
	{
		unless(@cmd_output = $cs->cmd( String => $cmd, Prompt => "/$enpromptre/" ) ) {
			$self->error("Failed to execute command: $cmd\n\t".$cs->errmsg);
			return;
		}
		$self->status("Command '$cmd' completed".$cs->errmsg);

		return @cmd_output;
	}
	else # look for More ;-(
	{
		my ($pre,$prompt) = ('','');
		my $ors = $cs->output_record_separator('');

		# Clean up $enpromptre just in case it has a wrapping //
		$enpromptre =~ s%^/%%;
		$enpromptre =~ s%/$%%;

		MORE: {

			# Don't send space commands with a newline
			$cmd eq ' ' ? $cs->print($cmd) : $cs->print("$cmd\n");
			($pre,$prompt) = $cs->waitfor( "/$enpromptre|--More--/" );
			unless( $pre )
			{
				$self->error("Failed to execute command: $cmd\n\t".$cs->errmsg);
				return;
			}

			# Copy partial to @cmd_output
			for my $line (split(/\n/,$pre)) 
			{
				next if $line =~ /--More--/;
				push(@cmd_output,"$line\n"); 
			}

			# Get more if required
			if($prompt =~ /--More--/)
			{
				$cmd = ' ';
				redo MORE;
			}
		}
		$self->status("Command '$cmd' completed".$cs->errmsg);
		$cs->output_record_separator($ors);

		return @cmd_output;

	}
}


sub close {
	my ($self) = @_;
	
	$self->{'CS'}->close if(defined( $self->{'CS'} ));
}



package ExecCmds;

use strict;

=head1 NAME
 
ExecCmds.pm - execute a set of commands against devices defined in
perl arrays.

 
=head1 SYNOPSIS

    use ExecCmds;

    my %config = (
    .
    . # See CONFIG below for details
    .
    );

    my @devs = ( x.x.x.x, y.y.y.y, .... );

    my $cmds = ExecCmds->new(%config);
    $cmds->run(@devices);

=head1 DESCRIPTION

Execute a number of commands against Cisco Routers and Switches for lots
and lots of them.

We fork a number of processes to handle the bulk of the work.
Default is 5 children runing at a time but that can be changed easily.

A number of Pre/Post hard and soft conditions can be defined and executed
and changes to the device aborted if conditions fail. These conditions
can be simple commands or complete Perl proggies executed over various
information retrieved from the device in question.

Basic actions performed (eventually): 

    - Check usage options
    - Collect device information
    - Do pre-condition tests and fail if appropriately
    - Update Router\Switch Config
    - Check Router\Switch config is correct using defined
      post-conditions.
    - Log all changes

=head1 CONFIG

    The format for the arguments to new() and configure() are as follows.
    They can be handed in via a pre-built hash or straight. A bit like
    this:

    ExecCmds-_new( number=>n, debug=>1, rcmds=>[], ... );

    or by building up a config hash and handing that in. I recommend
    building the hash and then passing it in thus:

    my %config = ();
    $config{'number'} = 5;
    $config{'debug'}  = 1;
    $config{'rcmds'}  = [ .... ];
    .
    .
    @devs = ('a','b',...'c');
    my $cmd = ExecCmds->new(%config); 

    later

    $cmd->configure('verbose'=>1);
    $cmd->run(@devs);

    Here is a list of the config options:

    number  => n, is the number of children to fork to get some parrallelism
    debug   => 1, -d Turns on debugging dont do anything to the devices
    care    => 0,  don't care about failures
    verbose => 0,  Be verbose about what is happening
    pretty  => 1,  Add lots of useful fluff in the logs
 
    log     => 'file',  where loggin should go. Into file if specified
                        otherwise it goes to routername.log. If you want
                        loggin to STDOUT use '-' as the file name. if
                        you want no logging use '/dev/null'

    # Our router commands to execute. These commands will be fed directly
    # to the router for consumption once Questions, Preconditions and
    # macro processing side effects have taken place.
    rcmds => [
            'show ip interface brief',
            'show proc cpu',
            'show proc mem',
    ];

    # An optional User/Pass/Enable combination. Each combination
    # is tried in the order show. If this arrayref is empty then
    # standard TACACS passwords are tried. If you want to try
    # TACACS first then fall back just make the first user TACACS
    # as shown below
    pass => [
        {'user' => 'TACACS', 'pass' => '',         'enable' => ''},
        {'user' => '',       'pass' => 'b00k1ngs', 'enable' => '0r1g1n'},
        {'user' => 'tzpj07', 'pass' => '0rico001', 'enable' => 'foresite'},
    ];

    # Our router Questions. Note: this is not a Pre/Post condition, Just
    # a question over the config. We print the truth or otherwise of the
    # question.
    r_q_regex => [
        'm/access-list 55 permit/s',
    ];

    # Our router Pre conditions. Note: Pre conditions must execute and
    # return true otherwise we halt processing
    r_pre_regex => [
            'm/access-list 55 permit/s'
    ];

    # Our router Post conditions. These don't effect the final execution
    # but they do define if we will say everything executed OK.
    r_post_regex => [
        'm/access-list 55 permit/s'
    ];

    # Our Switch commands. A distinction is made between switches and
    # routers. Really IOS and CATOS devices
    scmds => [
        'show proc',
        'show ver',
        'show loggining buffer',
        'show port status'
    ];

    # Our Switch Questions. Note: this is not a Pre/Post condition
    s_q_regex => [
        'm/set ip permit/s',
    ];

    # Our Switch Pre conditions
    s_post_regex => [
        'm/set ip permit/s',
    ];


    # Our Switch Post conditions
    s_pre_regex => [
        'm/set ip permit/s',
    ];



=head1 DEVICES

    Devices are handed to ExecCmds::run via an array reference. It
    can come in two forms. 
    
    Form1 (simple) is just an array of devices to execute
    against. It is the simplest way to apply the config over a
    number ofdevcies.

    Form2 (complex) allows name to ipaddress mapings that don't match DNS
    to be used. Also allows for macro processing, copy/paste and the
    like.

    Here is how we normally pick up all the devices.

    # Pick up all the devices names from the DB. This could be specified
    # explicitly if we liked.
    use IPSM::Devices;
    $db = IPSM::Devices->new() || die "Can't get Device DB connection";
    @devices = $db->list_devices();

	But you probably dont do this. You probably use a file or DNS or your
	own DB :-)

    Form1
    -----

    %config = (....);
    @devices = ( dev1, dev2, dev3, .....) ;
	my $exec = ::ExecCmds->new(%config);
    $exec->run(@devices);

    In this case rcmds and scmds are executed against each device just
    as they were defined.

    Form2
    -----

    @devices = (
      [
       {'CN' => 'ddarwa01'},        # cn is the name
       {'IP' => '10.145.224.249'},  # ip is the IP address to connect to

       # Some commands to execute in this order
       {'$snarf0' => 'cmd("sh ip interface brief")'},
       {'$loop'   => '$snarf0 =~ /^(Loopback\d+)\s+10.87.71.254/m'},
      ],

      # next device
      [
       {'CN' => 'nbanka01'},        # cn is the name
       {'IP' => '10.49.225.232'},   # ip is the IP address to connect to

       # Some commands to execute in this order
       {'$snarf0' => 'cmd("sh ip interface brief")'},
       {'$loop'   => '$snarf0 =~ /^(Loopback\d+)\s+10.69.15.254/m'},
      ],
    .
    .
    .
    );

    $rcmds = [ 
        'conf t',
        'int %%loop%%',
        'no shut',
        'exit',
        'wr',
        'quit',
    ];

    %config = (..,rcmds=>$rcmds ,..);
    my $exec = ::ExecCmds->new(%config);
    $exec->run(@devices);

    In this case the name (CN) and the IP address (IP) must be defined.
    CN is used to name the output messages for logging. It will be
    converted to upper case. IP is used to specify the address to connect
    to (just in case CN doesn't resolve).

    You can also define a number of variables that will be expanded into
    your $rcmds/$scmds array refs. Above we define the variable %%loop%%
    The $rcmds/$scmds commands will have %%loop%% expanded on a per device
    basis before commands, queries and pre/post conditions are executed.

    In the above case %%loop%% is set to contain what the $loop Perl 
    variable has been defined as in the devices array.

    $loop contains the results of the Perl code:
        $snarf0 =~ /^(Loopback\d+)\s+10.87.71.254/m';

    $snarf was filled with the data from running a command against the
    device. The command run was "sh ip interface brief" in this case.
    Each command will be executed seperately and tested to make sure it
    completed properly. Any failure will fail the run on this device.


=head1 Example 1

Turn on service password encryption for a set of devices. We already
have a copy of the configs for these devices in /home/configs/current


 # Setup the config hash
 %config = (

  # Note we use TACACS first then xyppy2, kz2ykc, and finally try without
  # any user name at all.
  pass => [
       {'user' => 'TACACS', 'pass' => '', 'enable' => ''},
       {'user' => 'xyppy2', 'pass' => 'x2dvm413', 'enable' => 'p4f2bcuw'},
       {'user' => 'kz2ykc', 'pass' => 'cHarChaR', 'enable' => 'please'},
       {'user' => '',       'pass' => 'smarty',   'enable' => 'dumb'},
  ],
  
  # Our router commands to execute
  rcmds => [ 
          'conf t',
          'service password-encryption',
          '',   # This is a real control Z
          'wr',
  ],
  
  # Our router Pre conditions say we don't want to find service
  # password-encryption turned on in the running config
  r_pre_regex => [
      '!m/^service password-encryption/m',
  ],
  
  # Our router Post conditions say we want to see that it is turned on
  # after the commands have been run
  r_post_regex => [
      'm/^service password-encryption/m',
  ],
  
  # Our Switch commands - none
  scmds => [ ],
  
  # Our Switch Pre conditions - none
  s_pre_regex => [ ],
  
  # Our Switch Post conditions - none
  s_post_regex => [ ],
 );
  
  # Collect some machines
  my $cmd='find /home/configs/current -type f | xargs grep -l "no service password-encryption" | perl -pe "s{/home/configs/current/}{}"';
  my @devs = `$cmd`;
  
  # Some machines 1070 actually
  @devices = map { s/\.txt\n//; $_; } @devs;

  my $cmds = ExecCmds->new();
  $cmds->configure(%config);
  $cmds->run(@devices);

=cut

# Flush STDOUT please. Helps when in debug mode. Both warn/die and print
# inter leave correctly
$| = 1;

#use ExecCmds::Utility;
use POSIX ":sys_wait_h";
use Data::Dumper;

use vars qw/$COMPLEX $DEBUG $WE_CARE $VERBOSE $ccount $PRETTY/;


=head1 new
 
     Usage:
        my $exec = ExecCmds->new();
        my $exec = ExecCmds->new(%config);

    Inputs:
        Nothing or a hash defining current configuration data as describe
        under CONFIG above

    Returns:
        A reference to an ExecCmds object that can later be used to
        access the API

=cut

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);

	$self->configure(@_);
	return $self;
}


=head1 configure
 
     Usage:
        $exec->configure(%config);
        my %config = $exec->configure();

    Inputs:
        A hash defining current configuration data as describe
        under CONFIG above

    Returns:
        A hash of the current configuration

=cut

sub configure
{
	my $self   = shift;
	my %config = @_;

	my @array_ref = qw/rcmds pass r_q_regex r_pre_regex r_post_regex scmds 
				s_q_regex s_post_regex s_pre_regex/;

	my @scalar = qw/debug verbose care log number pretty timeout/;

	# Configure array reference variables
	foreach (@array_ref)
	{
		if( defined $config{$_} && ref($config{$_}) ne 'ARRAY')
		{
			warn "ExecCmds config variable $_ should be an array reference. Skipping\n";
			next;
		}
		$self->{$_} = $config{$_} if defined $config{$_};

		# Make sure array reference variables have reasonable vaules
		$self->{$_} = [] unless defined $self->{$_};
	}

	# Configure scalar variables
	foreach (@scalar)
	{
		if( defined $config{$_} && ref($config{$_}))
		{
			warn "ExecCmds config variable $_ shouldn't be a reference. Skipping\n";
			next;
		}
		$self->{$_} = $config{$_} if defined $config{$_};
	}

	# Some reasonable defaults
	$self->{'log'}     = '' unless defined $self->{'log'};
	$self->{'number'}  = 5  unless defined $self->{'number'};
	$self->{'care'}    = 1  unless defined $self->{'care'};
	$self->{'verbose'} = 0  unless defined $self->{'verbose'};
	$self->{'debug'}   = 0  unless defined $self->{'debug'};
	$self->{'pretty'}  = 1  unless defined $self->{'pretty'};


	# Do a simple test on configuration details handed in. Are they valid?
	foreach my $ckey (keys %config)
	{
		next if grep($ckey eq $_, @array_ref, @scalar); 
		warn "ExecCmds: unknown configuration variable $ckey\n";
	}

	return %$self;
}


=head1 run
 
     Usage:
        $exec->run(@devices);

    Args:
        An array of devices to execute commands against. You must have
        configured the object first before this will do anything useful.

    Returns:
        Nothing usually unless only one device is handed in. In which
        case it will return an array describing the run.

    Comments:
        Output is usually logged to whereever you have specified the
        'log' config variable. If you didn't set 'log' then a comentary
        of the run is placed in DEVICENAME.log. Where DEVICENAME is the
        name of the device from @devices above.

        To get a more complete output of what was done, including the
        output from the device interaction make sure the 'verbose' config
        variable is set to 1.

        To have ONLY the interaction with the device passed back in an
        array do this;

        $exec->configure('pretty'=>0, 'verbose'=>1, 'log'=>'/dev/null');
        foreach (@devices)
        {
            my @interaction = $exec->run($_);
        }

        That is, set 'pretty' off, 'verbose' on and call run() with only
        one device specified. Passing more than one device allows run()
        to fork as many processes as defined in the 'number' setting.

    More comments:
        The run() method will organise a number of sub processes to
        execute to get the job done. To specify how many sub process you
        want run you set the 'number' config variable. Default is 5.

        Setting 'number' to 1 stops forking and causes only the first
        device in @devices to be accessed with the results returned in an
        array.

        Because we use sub processes it is easier to have each process
        log its interaction to a per-process file. If you defined a log
        file then it will get over written unless you set the 'log'
        config variable properly thus:

        $exec->configure('log'=>'/tmp/mylog-%%name%%.log');
        $exec->run(@devices);

        Here %%name%% will be expanded to be the device name as passed
        into run().

=cut


sub run
{
	my ($self,@devices) = @_;

	# $DEBUG used for printing verbage. $DEBUG used for flow control
	$DEBUG   = $self->{'debug'};
	$VERBOSE = $self->{'verbose'};
	$PRETTY  = $self->{'pretty'};

	# Default into a caring mode
	$WE_CARE = $self->{'care'};

	# Pickup any changed logging details
	my $logwhere  = $self->{'log'};

	use vars qw/$rcmds $pass $r_q_regex $r_pre_regex $r_post_regex $scmds 
				$s_q_regex $s_post_regex $s_pre_regex  @devices /;

	# Pick up our setting as defined in the config hash ref
	$rcmds        = $self->{'rcmds'};
	$pass         = $self->{'pass'};
	$r_pre_regex  = $self->{'r_pre_regex'};
	$r_q_regex    = $self->{'r_q_regex'};
	$r_post_regex = $self->{'r_post_regex'};
	$scmds        = $self->{'scmds'};
	$s_post_regex = $self->{'s_post_regex'};
	$s_pre_regex  = $self->{'s_pre_regex'};
	$s_q_regex    = $self->{'s_q_regex'};

	# if we only have one device to handle then don't fork. That way we
	# can return details to the caller
	my $fork = 1;  # Default to forking
	$fork = 0 if scalar(@devices) <= 1;
	$fork = 0 if $self->{'number'} == 1;

	# Setup Reaper and count of children procs
	my $pid;
	$SIG{CHLD}  = \&REAPER;
	$ccount     = 0;
	my $maxkids = $self->{'number'};

	my $i          = 0;
	my $parenttime = time();
	$COMPLEX       = 0;    # Is this a complex device to handle? Initially No
	foreach my $dev (@devices)
	{
		# Wait until some of our kids have died. Only want a few
		while($ccount >= $maxkids) {sleep(1);}


		# Check to see how we are going to handle this device. If its a ref
		# then we may have some command sets to execute before anything is
		# done to a device.
		my $name = "noname";
		if(ref($dev) eq "ARRAY")
		{
			$COMPLEX = 1;  # Global var set
			$name = $dev->[0]{'CN'} || 'no name for device'; 
		}
		elsif(!ref($dev))
		{
			$COMPLEX = 0;  # Global var set
			$name = $dev;
		}
		else
		{
			warn "This referenced Device record is invalid:";
			warn Dumper($dev);
			warn "Continuing\n";
			next;
		}

		# Define this runs log file
		$name = uc($name);
		my $logfile = $name.".log";
		$logfile = $logwhere if($logwhere);
		$logfile =~ s/%%name%%/$name/g;

		FORK: {
			if(!$DEBUG && $fork && ($pid = fork)) # don't fork if debugging
			{
				# Parent
				$ccount++;
			}
			elsif($DEBUG || !$fork || defined $pid)
			{
				# Setup STDOUT and STDERR to log file
				no warnings;
				open(OLDOUT, ">&STDOUT");
				open(OLDERR, ">&STDERR");
				use warnings;

				# Leave STDOUT alone if '-' defined as log file
				unless($logwhere eq '-')
				{
					open(STDOUT, '>', "$logfile") || die "Can't redirect stdout";
				}
				open(STDERR, ">&STDOUT")     || die "Can't dup stdout";

				my $details = '';
				my $time    = time();

				# Do the deed
				if( exec_dev_cmds( $dev, $pass, $rcmds, $r_q_regex, $r_pre_regex, 
								   $r_post_regex, $scmds, $s_q_regex, 
								   $s_pre_regex, $s_post_regex,\$details))
				{
					print $details;
					print "$name: completed commands OK.. Yippee!\n" if $PRETTY;
				}
				else
				{
					print $details;
					print "$name: Failed\n" if $PRETTY;
				}
				my $finish = time();
				print "$name: took ", $finish - $time, " seconds to complete\n\n" if $PRETTY;

				# Print an indication of finishing to executor
				close(STDOUT);
				close(STDERR);
				open(STDOUT, ">&OLDOUT");
				open(STDERR, ">&OLDERR");
				print "$name: took ", $finish - $time, " seconds to run\n\n" if $PRETTY;

				exit unless $DEBUG || !$fork;
				return split(/\n/,$details) if !$fork;

			}
			elsif($! =~ /No more process/)
			{
				sleep 5;
				redo FORK;
			}
			else
			{
				# System error of some kind
				die "Can't fork any more! $!";
			}
		};
	}

	# Wait for kids to finish otherwise any pipe
	# we are apart of will end too early
	while($ccount > 0) {sleep(1);}

	print "Total Parent time =  ", time() - $parenttime, "\n" if $PRETTY;
}

=pod


=head1  exec_dev_cmds
 
    Usage:
        This is an internal function. Don't use it unless you know what
        your doing.

        ExecCmds::exec_dev_cmds(....);

    Args: 
        $dev the device to mess with
        $pass a ref to an array of hashrefs containing details of 
            user/pass/enable to try
        $router_cmds a ref to an array of commands to add to router
            if it is indeed a router
        $r_q_regex a ref to an array of regex's to test for. But we
            dont fail the run if these fail. Just print out if is
            true or false
        $r_pre_regex and $r_post_regex are refs to arrays of regex's 
            to run over the config. These must all succeed before/after 
            commands. Maybe undef
        $switch_cmds a ref to an array of commands to add to swtch
            if it is indeed a switch
        $s_q_regex a ref to an array of regex's to test for. But we
            dont fail the run if these fail. Just print out if is
            true or false
        $s_pre_regex and $s_post_regex are refs to arrays of regex's 
            to run over the config. 
        $txt  is a string that will be modified in place with
            details of the run.

    Returns:
        A string of details of the run.

    Comments:
        You can ignore this method it is used internally. The run()
        method uses exec_dev_cmds() to get its job done.

exec_dev_cmds adds a new setting to a router/switch config whilst
testing pre and/or post conditions over the config. Tests can also
be performed to see if something is true or not about the
router/switch.

In the case of routers we check the  'start-config' in the
post-condition regular expression and the 'running config'
in the pre-condition. The pre/post conditions can be any Perl
expression that evaluates to True. Examples are shown below.

This example shows an access-list being dropped and rebuilt and tested
for. We are checking to make sure the access-list is already there and
failing if it isn't $r_pre_regex defines this. Once the commands are
executed we do a post check $r_post_regex. The same is done for a switch
device. If we had used $r_q_regex instead the success or failure of the
test would not stop the commands from being executed.

The routine does a check on the device to work out wether it is a switch
or router or whatever and runs the appropriate commands.
      
 $dev = 'RN-48MA-05-2610-99';

 Note: conf t, exit and write should be in all $rcmds array-refs.

 $rcmds = [
      'conf t',
      'no access-list 55',
      'access-list 55 permit 10.25.159.44',
      'access-list 55 permit 10.25.155.24',
      'exit',
      'write',
      ];
 $pass          = [];  # Just default to using our DB of info
 $r_q_regex     = [];  # No looking and testing
 $r_pre_regex   = ['m/access-list 55 permit/s'];
 $r_post_regexp = ['m/access-list 55 permit/s'];

 # switch commands here
 $scmds         = ['set ip permit 10.25.155.24  telnet'];
 $s_q_regex     = [];  # No simple tests
 $s_post_regex  = ['m/set ip permit/s'];
 $s_pre_regex   = ['m/set ip permit/s'];

 Here is a call to the subroutine given the above definitions. Note well
 how $ret is passed in. $ret will be populated with a run down of how the
 interaction went. It will contain any success\failure strings returned
 from Cisco::Utility. If no \$ret is passed in then it is ignored. Pre
 and Post conditions are also ignored if not defined. $s/r_q_regex arrays
 are also ignored if they are empty

    my $ret = '';
    if (ExecCmds::exec_dev_cmds(
                    $dev,$pass,$rcmds,$r_q_regex, $r_pre_regex,$r_post_regexp,
                     $scmds,$s_q_regex,$s_pre_regex,$s_post_regex,\$ret))
    {
        Great it worked
    }
    else
    {
        bummer!
    }
    print $ret;

=cut

sub exec_dev_cmds
{
	my ($cn, $pass_info, $router_cmds, $r_q_regex, $r_pre_regex, $r_post_regex,
	    $switch_cmds, $s_q_regex, $s_pre_regex, $s_post_regex, $ret) = @_;


	my $time = time();
	my (@r, $r, @t, $t, $txt);
	my $rtn = \$txt;
	$rtn = $ret if defined $ret && ref($ret) eq "SCALAR";

	# Get our device name
	my $dev = '';
	if($COMPLEX) { $dev = $cn->[0]{'CN'} || ''; }
	else { $dev = $cn; }

	unless($dev)
	{
		$$rtn = "Failed no device entered\n";
		return 0;
	}
	
	$dev = uc($dev) . ": ";
	$dev = '' if( !$PRETTY );

	# Get a new connection object
	my $cu = getconnected($cn,$pass_info);
	unless(defined $cu)
	{
		$$rtn = $dev . "Failed to connect/login.. bummer\n";
		return 0;
	}
	print $dev . "got new connection at ", time() - $time, " seconds\n" if $DEBUG;

	# True if we need to grep over the config before running commands
	my $needconfig = 
		defined $r_q_regex->[0] || defined $r_pre_regex ||
		defined $s_q_regex->[0] || defined $s_pre_regex;

	$r = '';
	if( $needconfig )
	{
		# Make sure we can get the config for the device and snarf it away
		# into $r for later regexp checking
		@r = runcommand($cu, $cu->{'SHOWCONFIG'} );
		if(my $err = $cu->error() && $WE_CARE) { $cu->close; $$rtn .= "\n$dev$err\n"; return 0;}
		$r = join("",@r);
		$ret .= $dev . "picked up config OK\n";
	}

	# Check the type of box we are connected to
	# Are we running IOS
	if($cu->type( $CISCO_IOS ))
	{
		print $dev . "is a router box\n" if $DEBUG;
		unless($router_cmds->[0])
		{
			$$rtn .= $dev . "no router commands to run\n";
		}

		# Do any complex stuff first
		if($COMPLEX)
		{
			($t,$txt) = prepare_cmds($cu,$dev,$cn,$router_cmds);
			$$rtn .= $txt; return 0 unless $t;
		}

		# build a simple query test
		$$rtn .= dev_query($dev,$r_q_regex,$r) if defined $r_q_regex->[0];

		if(defined $r_pre_regex->[0])
		{
			# build the eval test unless( 1 && blah && blah){die 'sucker'}
			($t,$txt) = dev_assert($dev,'pre',$r_pre_regex,$r);
			$$rtn .= $txt; return 0 unless $t;
		}

		# Ok now do the commands
		for my $cmd (@$router_cmds)
		{
			next unless $cmd;
			$$rtn .= $dev . "Issuing command $cmd\n" if $PRETTY;

			next if $DEBUG;  # Dont do if we are testing

			@t = runcommand($cu, $cmd );
			$$rtn .= $dev .  join($dev ,@t) if $VERBOSE;
			if(my $err = $cu->error() && $WE_CARE) { $cu->close; $$rtn .= "\n$dev$err\n"; return 0;}
			$$rtn .= $dev . $cu->error() . "\n" if $cu->error();
			$$rtn .= $dev . $cu->status() . "\n" if $PRETTY;
		}

		# If we need to do post config processing
		$r = '';
		if(defined $r_post_regex->[0])
		{
			# Do the post test and error appropriately. make sure we look in
			# the startup config to be sure to be sure :-)
			$$rtn .= $dev . "Issuing command show startup-config\n" if $PRETTY;
			@r = runcommand($cu, 'show startup-config' );
			if(my $err = $cu->error() && $WE_CARE) { $cu->close; $$rtn .= "\n$dev$err\n"; return 0;}
			$$rtn .= $dev . $cu->error() . "\n" if $cu->error();
			$$rtn .= $dev . $cu->status() . "\n" if $PRETTY;
			$r = join("",@r);

			($t,$txt) = dev_assert($dev,'post',$r_post_regex,$r);
			$$rtn .= $txt; return 0 unless $t;
		}

	}
	# Are we a Catalyst switch
	elsif($cu->type( $CISCO_CATALYST ))
	{
		print $dev . "is a switch box\n" if $DEBUG;
		unless($switch_cmds->[0])
		{
			$$rtn .= $dev . "no switch commands to run\n";
		}

		# Do any complex stuff first
		if( $COMPLEX )
		{
			($t,$txt) = prepare_cmds($cu,$dev,$cn,$switch_cmds);
			$$rtn .= $txt; return 0 unless $t;
		}

		# build a simple query test
		$$rtn .= dev_query($dev,$s_q_regex,$r) if defined $s_q_regex->[0] ;

		# Now build pre eval script and test assertions
		if( defined $s_pre_regex->[0] )
		{
			($t,$txt) = dev_assert($dev,'pre',$s_pre_regex,$r);
			$$rtn .= $txt; return 0 unless $t;
		}

		# Ok now do the commands
		for my $cmd (@$switch_cmds)
		{
			next unless $cmd;
			$$rtn .= $dev . "Issuing command $cmd\n";

			next if $DEBUG;  # Dont do if we are testing

			@t = runcommand($cu, $cmd );
			$$rtn .= $dev . join($dev ,@t) if $VERBOSE;
			if(my $err = $cu->error() && $WE_CARE) { $cu->close; $$rtn .= "\n$dev$err\n"; return 0;}
			$$rtn .= $dev . $cu->error() . "\n" if $cu->error();
			$$rtn .= $dev . $cu->status() . "\n" if $PRETTY;
		}

		# If we need to do post config processing
		$r = '';
		if(defined $s_post_regex->[0])
		{
			# Do the post test and error appropriately. Refresh our view of
			# the config to be sure to be sure :-)
			@r = runcommand($cu, $cu->{'SHOWCONFIG'} );
			if(my $err = $cu->error() && $WE_CARE) { $cu->close; $$rtn .= "\n$dev$err\n"; return 0;}
			$$rtn .= $dev . $cu->error() . "\n" if $cu->error();
			$$rtn .= $dev . $cu->status() . "\n" if $PRETTY;
			$r = join("",@r);

			# Now build post eval script and test assertions
			($t,$txt) = dev_assert($dev,'post',$s_post_regex,$r);
			$$rtn .= $txt; return 0 unless $t;
		}

	}
	# What on earth are we?
	else
	{
		print $dev . "Bad device type for $dev\n" if $DEBUG;
		$$rtn .= $dev . "Bad device type for $dev\n";
		$cu->close;
		return 0;
	}

	$cu->close;
	return 1;

}

# Create a comand much like the following and assert it
# unless(1 && test1 && test2 && ....) 
# {
#   die "dev: postcondition test1 && test2 && ... Failed"
# }
sub dev_assert
{
	my $dev = shift;
	my $prepost = shift;
	my $conds = shift;
	my $scan_buf = shift;

	if(!defined $conds->[0])
	{
		return(1,$dev . "no $prepost"."condition to check, OK\n") if $PRETTY;
		return(1,'');
	}
	
	my $test = 'unless( 1 && ';
	for my $i (@$conds) { $test .= "$i && "; }
	$test =~ s/...$//o; # remove last 3 chars
	if( $WE_CARE)
	{
		$test .= ") { die '$dev$prepost" . "condition regexp Failed'; }";
	}
	else # We Don't care, so don't die in eval
	{
		$test .= ") { # die '$dev$prepost" . "condition regexp Failed'; }";
	}

	# Put conditions in the die message
	my ($cond) = $test=~ m/1 && ([^)]+)/;
	$test =~ s/regexp/$cond/e;

	# Do the pre test and error appropriately
	$_ = $scan_buf;
	eval $test;
	if($@)
	{
		return (0, $@);
	}
	else
	{
		return (1,$dev . "$prepost"."condition asserted as OK\n") if $PRETTY;
		return(1,'');
	}

}

# Create a comand much like the following and return the results
# unless(1 && test1 && test2 && ....) 
# {
#    return "dev: query test1 && test2 && ... Failed"
# }
# return "dev: query test1 && test2 && ... OK"
sub dev_query
{
	my $dev = shift;
	my $conds = shift;
	my $scan_buf = shift;

	# Jump out if no conditions to test
	if(!defined $conds->[0])
	{
		return $dev . "no query condition to test. OK\n" if $PRETTY;
		return '';
	}

	my $test = 'unless( 1 && ';
	for my $i (@$conds) { $test .= "$i && "; }
	$test =~ s/...$//o; # remove last 3 chars
	$test .= ") { return '$dev" ."query condition regexp Failed'; }";
	if( $PRETTY )
	{
		$test .= "return '$dev"."query condition regexp OK'; ";
	}
	else
	{
		$test .= "return; ";
	}

	# Put conditions in the die message
	my ($cond) = $test=~ m/1 && ([^)]+)/;
	$test =~ s/regexp/$cond/ge;

	# Do the pre test and error appropriately
	$_ = $scan_buf;
	my $result =  eval $test;
	if($@)
	{
		return $@;
	}
	
	return $result ."\n";
}


###########################################################################
#
# Subroutine 
#       
#       Args: prepare_cmds
#
#       Rtns: $router_cmds modified in place
#             $t   is 0 for OK run, 1 otherwise
#             $txt is any commands text picked up
#
# Description:
#     Prepare_cmds will execute any preliminary commands that are
#     required to gather information. This information can then be used
#     to modify the $router_cmds that need to be executed. $vars are
#     collected and then substitued into %%vars%%.
#
#     ($t,$txt) = prepare_cmds($cu,$dev,$cn,$router_cmds) if $COMPLEX;
#
#     For example given $dev and $router_cmds that look like this
#       
#	  $dev = [
#	   {'CN' => 'ddarwa01'},        # cn is the name
#	   {'IP' => '10.145.224.249'},  # ip is the IP address to connect to
#
#	   # Some commands to execute in this order. The first command
#	   # is special and 'cmd' gets expanded to execute a command on the
#      # cisco box
#	   {'$Snarf0' => 'cmd("sh ip interface brief")'},
#
#      # This command is normal Perl. It sets the "loop" variable for the
#      # template code in the router commands
#	   {'($loop)'   => '$Snarf0 =~ /^(Loopback\d+)\s+10.87.71.254/m'},
#	  ],
#
#
#	$router_cmds = [ 
#		'conf t',
#		'int %%loop%%',
#		'no shut',
#		'exit',
#		'wr',
#		'quit',
#	];
#
#   Router_cmds will end up looking some thing like
#
#	$router_cmds = [ 
#		'conf t',
#		'int Loopback0',
#		'no shut',
#		'exit',
#		'wr',
#		'quit',
#	];
#

sub prepare_cmds
{
    my($cu,$dev,$cn,$cmds) = @_;
	my $t = 1;  # True or false return code
	my $text = '';

	# Loop through each $dev commands picking up any details asked for.
	# Note keys CN and IP are skipped. We collect each command in order
	# place them in a single eval so command substitution can happen.
	for my $cmd (@$cn)
	{
		next if grep /^CN|^IP/i, keys %$cmd;

		# $pvar is a Perl variable to hold the result. $str is the string
		# to eval, $left is the left hand side of the assignment
		my ($left,$str) = %$cmd;
		my $pvar = $left;

		# Need to sanitise our $pvar just in case it is surrounded in
		# ()'s
		if($left =~ m/^\s*\(\s*(\$\w+)\s*\)/) { $pvar = $1; } # ($x)
		if($left =~ m/^\s*\(\s*(\@\w+)\s*\)/) { $pvar = $1; } # (@x)
		if($left =~ m/^\s*\(\s*(\%\w+)\s*\)/) { $pvar = $1; } # (%x)

		# Build eval command; Should really place everything in another
		# package for safety...
		# Handle device commands of the form cmd("command")
		if( $str =~ m/^cmd\(/)
		{
			$str =~ s/cmd\(/\$cu->cmd(/i;
			$str = 'package NN;' .
			       "use vars qw/\@t $pvar/;\n$pvar = '';\n".
				   '@t = ' . $str . ";\n$pvar = " . 'join("",@t);';
		    $str .= <<'EOT'

				if(my $err = $cu->error()) 
				{ 
					$cu->close; 
					die $dev . "$err\n"; 
				} 
EOT

		}
		else # Assume normal Perl expression
		{
			# Handle normal case of $var = statement, or var = statement
			if($left =~ /\w+/)
			{
				# make template names variables as well (scalar only mate)
				$pvar = '$' . $pvar unless $pvar =~ /^\$|^\@|^\%/;
				$str = "package NN; use vars qw/$pvar/;\n$left = " . $str;
			}
			# Handle possible null $left and null $pvar
			elsif($left =~ /^\s*$/)
			{
				$str = "package NN; " . $str;
			}
			else # I give up
			{
				warn "Sorry. Don't know how to handle: $left => $str";
			}
		}

		# Do eval. Setting any variables as side effects
		$text .= $dev . "Issuing preliminary command $str\n" if $DEBUG;
		eval $str;
		if($@)
		{
			my $error = $@;
			warn $error;
			$text .= $error;
			$t = 0;
			last;
		}
		else
		{
			$text .= $dev . "Completed preliminary command $str\n" if $DEBUG;
			$t = 1;
		}

	}

	# Ok now fill up all the substitution data
	my %fillings;
	for my $hr (@$cn)
	{
		for my $fill_key (keys %$hr)
		{
			# Only want real fills. That is vars with no $name, @  % ...
			next unless $fill_key;
			next if     $fill_key =~ /^CN|^IP/;
			next if     $fill_key =~ /\@|\%/; # Want scalars

			# Need to handle ($var) stuff on the left handside of a
			# command as well
			$fill_key =~ s/^\s*\(\s*(\$\w+)\s*\)/$1/;
			$fill_key =~ s/^\s*\$(\w+).*$/$1/;  # Strip leading $

			$fillings{$fill_key} = eval '$NN::'.$fill_key;
		}
	}

	# For each command do any substituions
	for my $cmd_instance (@$cmds)
	{
		$cmd_instance =~ s{ %% ( .*? ) %% }
		                  {exists( $fillings{$1} )
						          ? $fillings{$1}
								  : ""
						  }gsex
	}

	# OK now we need to fix up any multi line commands that may have
	# crept in
	my $new_cmds = [];
	for my $cmd_instance (@$cmds)
	{
		push(@$new_cmds,split(/\n/,$cmd_instance));
	}
	$cmds = $new_cmds;
	$_[3] = $new_cmds;

	#ready to test...
	if($DEBUG)
	{
		print "Router commands are now:\n";
		print Dumper($cmds);
	}

	return wantarray ? ($t,$text) : $t;
}

###########################################################################
#
# Subroutine runcommand
#       
#       Args: connection, commands
#
#       Rtns: command results
#
# Description:
#     run a command or possibly multiple commands against a device
#       
#       
sub runcommand
{
	my ($cu,$cmd) = @_;
	my @result = ();

	# handle single commands as ususal
	return $cu->cmd( $cmd ) unless $cmd =~ /\n/s;

	# Have a multi line command
	for my $c (split(/\n/,$cmd))
	{
		my @res =$cu->cmd($c);
		push(@res, $cu->error(),"\n") if $cu->error();

		push(@result, @res);
		last if $cu->error() && $WE_CARE;
	}
	return @result;
}

###########################################################################
#
# Subroutine getconnected
#       
#       Args: device, password information
#
#       Rtns: a connection object
#
# Description:
#     getconnected takes a device to connect to and an arrayref of
#     hashrefs that contain user/password/enable information and tries to
#     make a connection
#       
#       
sub getconnected
{
	my ($cn,$pass_info) = @_;

	my $dev = $cn;   # Default to the non-complex state
	my $ip  = '';

	if( $COMPLEX )
	{
		$dev = uc($cn->[0]{'CN'});
		$ip  = $cn->[1]{'IP'};

		# Check IP address
		unless($ip =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
		{
			warn "Bad IP address passed $ip";
			return undef;
		}
	}

	for my $hashref (@$pass_info)
	{
		# Where to put the connection object
		my $cu;

		# Must have each element at least defined. My be null though
		next unless defined $hashref->{'user'};
		next unless defined $hashref->{'pass'};
		next unless defined $hashref->{'enable'};

		# Is it a TACACS login using the normal DB
		if($hashref->{'user'} =~ m/tacacs/io)
		{
			if($DEBUG)
			{
					$cu = ExecCmds::Utility->new( cn=>$dev, 
											   'debug' => 1,
									 $COMPLEX ? (ipaddress=>$ip) : (),
									 );
			}
			else
			{
					$cu = ExecCmds::Utility->new( cn=>$dev ,
									 $COMPLEX ? (ipaddress=>$ip) : (),
									 );
			}
		}
		# Else try a normal user/pass/enable
		else
		{
			if($DEBUG)
			{
				print "$dev: trying user=>",$hashref->{'user'},
				      $COMPLEX ? " IP=>$ip" : '',
				      " password=>",   $hashref->{'pass'},
					  " enable=>",     $hashref->{'enable'},
					  "\n";
			}

			$cu = ExecCmds::Utility->new( cn=>$dev,
									 'username' => $hashref->{'user'},
									 'password' => $hashref->{'pass'},
									 'execpassword' => $hashref->{'enable'},
									 'debug' => 1,
									 $COMPLEX ? (ipaddress=>$ip) : (),
									 );
			if($DEBUG)
			{
				print "$dev: user=>",$hashref->{'user'},
				      " password=>",   $hashref->{'pass'},
					  " enable=>",     $hashref->{'enable'},
					  $cu ? " Success" : " Failed", "\n";
			}
		}
		
		# Success
		return $cu if $cu;
	}

	# Failure
	return undef;

}


# Sigchld reaper
sub REAPER {
    my $stiff;
    # see http://www.perlmonks.org/index.pl?node=reaper%20subroutines
	# for why WNOHANG() and not &WNOHANG. Basically 2nd call passes @_
	# to POSIX module thus WNOHANG(@_)
    while (($stiff = waitpid(-1, WNOHANG())) > 0) {
        # do something with $stiff if you want
        $ccount--;
    }
    $SIG{CHLD} = \&REAPER;                  # install *after* calling waitpid
}

=pod

=head1 AUTHOR

Mark Pfeiffer <markpf@mlp-consulting.com.au>

Jeremy Nelson <jem@apposite.com.au> provided Utility functions

=head1 COPYRIGHT

Copyright (c) 2002 Mark Pfeiffer and Jeremy Nelson. All rights
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

    Cisco is a registered trade mark of Cisco Systems, Inc.
    This code is in no way associated with Cisco Systems, Inc.

    All other trademarks mentioned in this document are the property of
    their respective owners.

=head1 DISCLAIMER

We make no warranties, implied or otherwise, about the suitability
of this software. We shall not in any case be liable for special,
incidental, consequential, indirect or other similar damages arising
from the transfer, storage, or use of this code.

This code is offered in good faith and in the hope that it may be of use.

cheers  

markp   
 
Mon May 20 13:14:39 EST 2002 or there abouts

=cut

