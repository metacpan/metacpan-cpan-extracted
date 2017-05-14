package Arc::Connection::Client;

use strict;
use warnings;
use Carp;

use IO::Socket::INET; 
use IO::Select;
use Arc qw(LOG_AUTH LOG_USER LOG_ERR LOG_CMD LOG_SIDE LOG_DEBUG);
use Arc::Connection;
use MIME::Base64; 

@Arc::Connection::Client::ISA = qw(Arc::Connection);

sub members 
{
	my $this = shift;
	return { %{$this->SUPER::members},
		logfileprefix => "client",
		logdestination => "stderr",
		
		sasl_cb_user => $ENV{'USER'}, # SASL Callback for username (PLAIN and some other mechs only)
		sasl_cb_auth => $ENV{'USER'}, # SASL Callback for authname (PLAIN and some other mechs only)
		sasl_cb_pass => "",           # SASL Callback for password (PLAIN and some other mechs only)

		server => undef,              # Server to connect to
		port => undef,                # Port to connect to
		sasl_mechanism => undef,      # use this mechanism for authentication
		server_sasl_mechanisms => [], # filled by the sasl mechanisms
		protocol => 1,	              # Which protocol type the shall use.
	};
}

sub _Init
{
	my $this = shift;

	return 0 unless $this->SUPER::_Init(@_);

	# server
	return $this->_SetError("No ARCv2 server given.") unless defined $this->{server};

	# port
	unless (defined $this->{port}) {
		$this->Log(LOG_SIDE,"No port specified. Using $Arc::DefaultPort.");
		$this->{port} = $Arc::DefaultPort;
	}
	
	# sasl mech
	$this->Log(LOG_SIDE,"No sasl mechanism specified. Using the one supplied by the server.") 
		unless defined $this->{sasl_mechanism};
}

## connects to the server
##out> true when succesful, otherwise false
##eg> $this->_Connect();
sub _Connect
{
	my $this = shift;

	$this->{_connection} = new IO::Socket::INET(
				PeerAddr => $this->{server}, 
				PeerPort => $this->{port}, 
				Type => SOCK_STREAM,
	) || return $this->_SetError("Could not create Client socket: $! $@.");
	
# Fill the connected Socket into the select object
	$this->{_select} = new IO::Select($this->{_connection}) 
		|| return $this->_SetError("Select creation failed.");

	$this->{_connection}->autoflush(0);
	$this->{_connected} = 1;

	return 1;
}

## initialize the protocol.
## Sends the initial protocol message ARC/2.0
##out> true when succesful, otherwise false
##eg> $this->_InitARC2();
sub _InitARC2
{
	my $this = shift;
	@{$this->{_expectedcmds}} = qw(ERR AUTH);
	$this->{_authenticated} = 0;
	return $this->_SendCommand ("ARC/2.".$this->{protocol});
}

## initiate the authentication.
## Tells the server which authtype we want to use.
## Protocol command: AUTHENTICATE [<authtype>]\r\n
##out> true when succesful, otherwise false
##eg> $this->_Authenticate();
sub _Authenticate
{
	my $this = shift;
	@{$this->{_expectedcmds}} = qw(ERR AUTHTYPE);
	return $this->_SendCommand ("AUTHENTICATE",$this->{sasl_mechanism});
}

## initiate the authentication (sasl)
## Creates the sasl object (client_new).
## Client begins always and sends the first SASL challenge
## Protocol command: SASL <base64 encoded SASL output>\r\n
##out> true when succesful, otherwise false
##eg> $this->_StartAuthentication();
sub _StartAuthentication
{
	my $this = shift;

	$this->_PrepareAuthentication() || return;
	
	$this->{__sasl}->callback(
		user => $this->{sasl_cb_user}, 
		auth => $this->{sasl_cb_auth},
		pass => $this->{sasl_cb_pass},
	);

	my $sasl = $this->{_sasl} = $this->{__sasl}->client_new(
				$this->{service},
				$this->{server},
				$this->{_connection}->sockhost.";".$this->{_connection}->sockport,
				$this->{_connection}->peerhost.";".$this->{_connection}->peerport,
	);

	# sasl Context created
	if (!defined $sasl || $sasl->code != 0) {
		return $this->_SetError("creating SASL object failed: ",$sasl->error());
	}
	
	@{$this->{_expectedcmds}} = qw(SASL ERR);
	return $this->_StepAuthentication(1);
}

## another SASL step.
## Response of a SASL command from the server.
## Protocol command: SASL <base64 encoded SASL outout>\r\n
##in> $first_step
##out> true when succesful, otherwise false
##eg> return $this->_StepAuthentication(1);
sub _StepAuthentication
{
	my $this = shift;
	my $first = shift;
	my $sasl = $this->{_sasl};
	my $ret = 0;
	my $str;

	if ($first) {
		$str = $sasl->client_start();
	} else {
		$str = $sasl->client_step(decode_base64($this->{_cmdparameter}));
	}

	$str = "" unless defined $str;
		
	if ($sasl->need_step || $sasl->code == 0) {
		if ($sasl->code == 0) {
			$this->_Sasl($str) if $str ne "";
			
			$this->{_authenticated} = 1;
			@{$this->{_expectedcmds}} = qw(ERR);
			$this->{sasl_mechanism} = $this->{_saslmech};
			$this->Log(LOG_AUTH,"SASL: Negotiation complete. User is authenticated.");
			$ret = 1;
		} else {
			$ret = $this->_Sasl($str);
		}
	} else {
		$this->Quit();
		$ret = $this->_SetError("SASL: Negotiation failed. User is not authenticated. SASL error: (",$sasl->code,") ",$sasl->error);
	}
	return $ret
}

## send an ARCv2 command request
## Protocol command: CMD <cmd> <cmdparameter>\r\n
##in> ... (cmd and parameter)
##out> true when succesful, otherwise false
##eg> $this->_Cmd ("whoami");
sub _Cmd
{
	my $this = shift;
	my $str = join " ",@_;
	$str =~ s/[\r\n]//g;
	return $this->_SetError("Empty command won't be sent.") unless length $str;
	@{$this->{_expectedcmds}} = qw(ERR CMDPASV DONE);
	return $this->_SendCommand("CMD",$str);
}

# The _R subs are processing a server response, call resp. subs and set the expectedcmds array approp.
## parses the AUTH <list of SASL mech>\r\n, sent by the server
sub _RAUTH
{
	my $this = shift;
	@{$this->{server_sasl_mechanisms}} = split(',',$this->{_cmdparameter});

	return $this->_Authenticate();
}

## parses the AUTHTYPE <SASL mech>\r\n, sent by the server.
## Which SASL mech the server will use.
sub _RAUTHTYPE
{
	my $this = shift;
	$this->{_saslmech} = $this->{_cmdparameter};
	
	return $this->_StartAuthentication();
}

## parses the SASL <base64 encoded SASL string>\r\n, sent by the server.
## Sasl response from the server
sub _RSASL
{
	my $this = shift;
	return $this->_SetError("SASL Negotiation failed.") unless ($this->_StepAuthentication(0));
	return 1;
}

## parses the ERR <msg>\r\n, sent by the server.
## Server command, which reports an server-side error
sub _RERR
{
	my $this = shift;

	$this->_SetError("Server ERROR:",$this->{_cmdparameter});
	return 1;
}

## parses the CMDERR <msg>\r\n, sent by the server.
## Command specific error, which reports an error during the command
sub _RCMDERR
{
	my $this = shift;
	$this->_SetError("Command ERROR:",$this->{_cmdparameter});
	return 1;
}

## parses CMDPASV <host:port>\r\n, sent by the server.
## Establish the encrypted command connection.
sub _RCMDPASV
{
	my $this = shift;
	$this->Log(LOG_SIDE,"Try to connect to:",$this->{_cmdparameter});
	
	@{$this->{_expectedcmds}} = qw(ERR DONE CMDERR);

	return if defined $this->{_cmdclientsock};

	my ($host,$port) = split(/:/,$this->{_cmdparameter});

	return unless defined $host || defined $port;

	$this->{_cmdclientsock} = new IO::Socket::INET(
		PeerAddr => $host,
		PeerPort => $port,
		Type => SOCK_STREAM,
	) || return $this->_SetError("Passive Connection failed."); 
	
	return 1;
}

## parses DONE\r\n, sent by the server.
## This is received when a command is done.
sub _RDONE
{
	my $this = shift;
	@{$this->{_exceptedcmds}} = qw(ERR CMD);
	return 1;
}

## start an ARCv2 session.
## This function which will change the status of the connection into a
## authenticated status. Users have to call this function
## to be able to run ARCv2 commands afterwards.
##out> true if authentication was successful, otherwise false.
##eg> if ($arc->StartSession()) { .. }
sub StartSession
{
	my $this = shift;
	return $this->_SetError("There is already a command running.") if $this->IsConnected();
	return $this->_SetError("Connection to host ",$this->{server},":",$this->{port}," failed") unless $this->_Connect();
	$this->_InitARC2();

	while (!$this->{_error} && ($this->{_authenticated} == 0) && (my $cmd = $this->_RecvCommand())) {
		last unless $this->_ProcessLine($cmd);
	}
	return !$this->{_error} && $this->{_authenticated};
}

## ends the connection.
## Tells the server that we want to end the conversation. (Userlevel)
## Protocol command: QUIT\r\n
##out> always true
##eg> $arc->Quit();
sub Quit
{
	my $this = shift;
	$this->_SendCommand("QUIT");
	$this->{_connection}->close();
	$this->{_connected} = 0;
	$this->{_expectedcmds} = qw();
	return 1;
}

## process a command.
## This function runs a command with STDIN and STDOUT as clients 
## in- and output control.
##in> ... (command and its parameters)
##out> true if successful, false if not. (IsError is set appropriatly)
##eg> $arc->ProcessCommand("whoami");
sub ProcessCommand
{
	my $this = shift;

	return unless $this->CommandStart(@_);

	STDOUT->autoflush(1);
	$this->_ReadWriteBinary(*STDIN,*STDOUT);

	return $this->CommandEnd();
}

## start an ARCv2 command
## This function starts the given ARCv2 Command and enables the Command* functions.
##in> ... (command and its parameters)
##out> true if successful, false if not. (IsError is set appropriatly)
##eg> if ($arc->CommandStart()) { ... }
sub CommandStart
{
	my $this = shift;
	return $this->_SetError("You are not authenticated.") unless $this->{_authenticated};
	return $this->_SetError("Already running a command.") if defined $this->{_cmdclientsock};
	return unless @_;
	return unless $this->_Cmd(@_);

	while (!$this->{_error} && (not defined $this->{_cmdclientsock}) && (my $cmd = $this->_RecvCommand()) ) {
		$this->_ProcessLine($cmd);
		last if $cmd eq "DONE";
	}
	return 1 if defined $this->{_cmdclientsock};
	return;
}

## write something to the command.
## Write something to the standard input of the command started by C<CommandStart>.
##in> ... (data)
##out> true if successful, false if not. (IsError is set appropriatly)
##eg> last unless $this->CommandWrite();
sub CommandWrite
{
	my $this = shift;
	return $this->_SetError("There is no command running.") unless defined $this->{_cmdclientsock};
	return unless @_;

	my $str = join("",@_);
	$str = $this->{_sasl}->encode($str);

	return $this->{_cmdclientsock}->syswrite($str);
}

## close the write part of the netsock.
## This function closes the write-part of the command connection.
##out> true if successful, false if not. (IsError is set appropriatly)
##eg> last unless $arc->CommandEOF();
sub CommandEOF
{
	my $this = shift;
	return $this->_SetError("There is no command running.") unless defined $this->{_cmdclientsock};

	return shutdown($this->{_cmdclientsock},1);
}

## read data from the Command connection.
##out> if successful the received data is returned, otherwise false.
##eg> while (my $data = $arc->CommandRead()) { ... }
sub CommandRead
{
	my $this = shift;
	return $this->_SetError("There is no command running.") unless defined $this->{_cmdclientsock};

	my $sel = new IO::Select ( $this->{_cmdclientsock} );
	my $buf;
	while ($sel->can_read($this->{timeout})) {
		return unless $this->{_cmdclientsock}->sysread($buf,1024);
		$buf = $this->{_sasl}->decode($buf);
		next unless $buf; # SASL incomplete decode
		return $buf;
	}
	return;
}

## end the command on the server side.
## Closes the command connection and ends the command.
##out> true if successful, false if not. (IsError is set appropriatly)
##eg> $arc->CommandEnd();
sub CommandEnd
{
	my $this = shift;
	return $this->_SetError("There is no command running.") unless defined $this->{_cmdclientsock};

	if ($this->{protocol} == 1) {
# encrypted protocol and command connection, don't lose synchronized sasl_de/encode
		$this->CommandEOF();
		while ($_ = $this->CommandRead()) { $this->_Debug("read text: ".$_); };
	}		

	$this->{_cmdclientsock}->close();
	$this->{_cmdclientsock} = undef;

	while (my $cmd = $this->_RecvCommand()) {
		last unless $this->_ProcessLine($cmd);
		last if $cmd eq "DONE";
	}

	return if $this->{_error};
	return 1;
}

return 1;
