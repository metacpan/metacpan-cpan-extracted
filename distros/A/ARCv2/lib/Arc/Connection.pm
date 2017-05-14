package Arc::Connection;

use strict;
use warnings;
use Carp;
use MIME::Base64;
use Arc qw(LOG_AUTH LOG_USER LOG_ERR LOG_CMD LOG_SIDE LOG_DEBUG);
use Authen::SASL;

@Arc::Connection::ISA = qw(Arc);

sub members 
{
	my $this = shift;
	return { %{$this->SUPER::members},
		# private:
			__sasl => undef,   # Authen::SASL Handle
			__linequeue => [], # internal line buffer (idea From Net::Cmd)
			__partial => "",   # a partial line (idea From Net::Cmd)
		# protected:
			_connection => undef,    # IO::Socket for the ARCv2 Connection
			_cmdclientsock => undef, # IO::Socket for the command connection (encrypted)
			_select => undef,        # IO::Select for the ARCv2 Connection
			
			_authenticated => 0,     # Are we authenticated
			#_sasl => undef,         # Authen::SASL::Cyrus Handle
			#_saslmech => "",        # SASL mechnanism used at authentication
			
			_cmdparameter => undef,   # parameter after the command
			_expectedcmds => undef,   # array, which ARCv2 protocol commands are allowed to come next
			_connected => 0,          # are we connected
			_username => "anonymous", # username extracted from SASL

		# public:
			protocol => undef, # Which protocol is used (0 = ARC/2.0, 1 = ARC/2.1)

			timeout => undef,  # timeout for all connections (ARCv2 and command) in seconds
			service => undef,  # name of the server (for SASL)
	};
}

sub _Init
{
	my $this = shift;
		 
	return $this->_SetError("Initialization failed.") unless $this->SUPER::_Init(@_);
	
	# timeout
#	unless (defined $this->{timeout}) {
#		$this->Log(LOG_SIDE,"Setting timeout to 30 secs since no time specified.");
#		$this->{timeout} = 30;
#	}		  
	
	return $this->_SetError("No service name for SASL authentication specified.") 
		unless defined $this->{service};
		
	return 1; 
}

## initializes command connection. (protocol)
## Starts listen on the Command socket and sends the B<CMDPASV> command.
##out> true if everything went like expected, otherwise false.
##eg> $this->_CommandConnection();
sub _CommandConnection
{
	my $this = shift;

	my $consock = IO::Socket::INET->new(
				Listen    => 1,
				Proto     => 'tcp',
				LocalAddr => $this->{_connection}->sockhost,
				ReuseAddr => 1,
	) || return $this->_SetError("Socket creation for CommandConnection failed.");

	unless ($this->_SendCommand("CMDPASV",$consock->sockhost.':'.$consock->sockport)) {
		return;
	}

	my $sel = new IO::Select($consock);

	if (my @socks = $sel->can_read(10)) {
		foreach my $sock (@socks) {
			if ($sock == $consock) {
				$this->{_cmdclientsock} = $consock->accept() || last;
				return 1;
			}
		}
	} else {
		return $this->_SetError("No CommandConnection received (Client died?).");
	}	
}

## function for reading and writing on the command connection.
## This function is always used by the C<Arc::Connection::Server> to handle 
## command data. When calling the C<ProcessCommand> from C<Arc::Connection::Client> 
## this function is also used.
## Data is read from the local socket resp. pipe and is written encrypted 
## to the network socket. The other side reads the data from network socket, 
## decrypts it and writes it to its local socket. This function behaves differently on 
## client and server sides, when the local or network socket is closed.
##in> *locfdin, *locfdout
##out> always true
##eg> $this->ReadWriteBinary(*STDIN,*STDOUT);
sub _ReadWriteBinary
{
	my $this = shift;
	my $locin = shift;
	my $locout = shift;
	my $client = ref ($this) eq "Arc::Connection::Client";
	my $netsock = $this->{_cmdclientsock};
	
#	$this->_Debug("ReadWriteBinary (C:",$client,") locin: ",$locin->fileno,", locout:",$locout->fileno,", net: ",$netsock->fileno);
	my $sel = new IO::Select($netsock,$locin);
	my $lwsel = new IO::Select($locout);
	my $nwsel = new IO::Select($netsock);

	my $buf;
	my $stop = 0;
	while (my @rs = $sel->can_read) {
		foreach my $r (@rs) {
			# Something is readable.
			my $ret = $r->sysread($buf,4096);
			# If no data received, this read socket is closed
			# We don't want to listen to it anymore
			unless ($ret) {
				$sel->remove($r);
				# If there is nothing to read anymore
				# we will never write to the other socket again.
				if ($r->fileno == $locin->fileno) {
					$stop = 1 unless $client;
					shutdown($netsock,1); # Close write connection
				} elsif ($r->fileno == $netsock->fileno) {
					# on client-side the netsock is closed only
					# if the command on server side has ended.
					# so game over
					$stop = 1 if $client;
					close($locout) unless $stop; # Local pipe is not needed anymore
				}
				
				last if $stop;
			} else {
				# select the appropriate write-"select"
				my $tsel = $r->fileno == $locin->fileno ? $nwsel : $lwsel;
				# encryption, decode or encode
				$buf = $r->fileno == $locin->fileno ? 
						$this->{_sasl}->encode($buf) : 
						$this->{_sasl}->decode($buf); 

				# sometimes SASL replies NULL if something is missing	
				# this is normal behaviour, the next buf will complete it 
				next unless $buf; 
			
				# if nothing is writeable, gameover
				last unless (my @ws = $tsel->can_write);
				last unless ($ws[0]->syswrite($buf));
			}
		}
		last if $stop;
	}

#	$this->_Debug("RW Binary ended.");
	return 1;
}

## send a line. (protocol)
## This function sends a command line to the ARCv2 socket.
##in> ... (line)
##out> true if writing has succeeded, otherwise false.
##eg> $this->_SendLine($cmd,"test"); 
sub _SendLine
{
	my $this = shift;
	return unless @_;
	my $line = join("",@_);
	$line =~ s/\r//g;
	$line =~ s/\n/ /g;
	return $this->_SetError("SendLine only available when connection and select is set.") unless $this->{_connected};

	if ($this->{_select}->can_write($this->{timeout})) { 
		$this->_Debug(substr ($line,0,30),"..");
		$line .= "\015\012";
		
# encrypt if necessary
		$line = $this->{_sasl}->encode($line)
			if $this->{_authenticated} == 1 and $this->{protocol} == 1;

		return $this->{_connection}->syswrite($line,4096) > 0;
	} else {
		$this->{_connected} = 0;
		$this->{_connection}->close;
		return $this->_SetError("Sending timed out.");
	}
}

## send a command. (protocol)  
## Send a command to the ARCv2 socket.
##in> $cmd, $parameter
##out> true if successful, otherwise false
##eg> $this->_SendCommand("CMDPASV",$consock->sockhost.':'.$consock->sockport);
sub _SendCommand
{
	my $this = shift;
	my ($cmd,$msg) = @_;
	my $ret = 1;

	$ret = $this->_SetError("Sending command $cmd failed.") unless $this->_SendLine($cmd,defined $msg ? " ".$msg : "");
	return $ret;
}

## receive a line (command). (protocol)
## This function receives data from the ARCv2 connection and
## fills the internal C<__linequeue> and C<__partial>. It returns 
## a line from the internal buffer if there is any. It also handles
## timeouts and "connection closed by foreign host"'s.
##out> true (and the line) if everything worked fine, otherwise false (undef)
##eg> if (my $line = $this->_RecvLine()) { ... }
sub _RecvLine
{
	my $this = shift;

	return shift @{$this->{__linequeue}} if scalar @{$this->{__linequeue}};

	# no connection is set not connected
	return $this->_SetError("RecvCommand only Available when connection and select is set.") unless $this->{_connected};

	my $partial = defined($this->{__partial}) ? $this->{__partial} : "";

	my $buf = "";
	until (scalar @{$this->{__linequeue}}) {
		if ($this->{_select}->can_read($this->{timeout})) { # true if select thinks there is data 
			my $inbuf;
			unless ($this->{_connection}->sysread($inbuf,4096)) {
				$this->{_connected} = 0;
				$this->{_connection}->close();
				return $this->_SetError("Connection closed by foreign host.");
			}
# decrypt if possible and necessary
			$buf = $this->{_sasl}->decode($inbuf) 
				if $this->{_authenticated} == 1 and $this->{protocol} == 1;
				
# if authentication went wrong on the server side, but client thought it was ok
			$buf = $inbuf unless $buf;
			
			substr($buf,0,0) = $partial;
			my @buf1 = split (/\015?\012/,$buf,-1);
			$partial = pop @buf1;
			
			push(@{$this->{__linequeue}}, map { "$_\n" } @buf1);
		} else {
			$this->{_connected} = 0;
			$this->{_connection}->close();
			# if timed out, 
			return $this->_SetError("Connection timed out.");
		}
	}
	$this->{__partial} = $partial;
	return shift @{$this->{__linequeue}};
}

## receives an ARCv2 Command. (protocol)
## This function gets a line from C<_RecvLine> and extracts the ARCv2 command and
## the optional command parameter C<_cmdparameter>.
##out> ARCv2 command and true if everything works fine, otherwise false
##eg> while (my $cmd = $this->_RecvCommand()) { ... }
sub _RecvCommand
{
	my $this = shift;

	my $command = undef;
	if (my $line = $this->_RecvLine()) { # Fetch and parse a cmd from queue
		$line =~ s/[\r\n]//g;
		($command,$this->{_cmdparameter}) = $line =~ m/^([A-Z]+)\ ?(.*)?$/;
	}
		
	return $command; # There was an error if undef is return 
}

## process an ARCv2 command. (protocol)
## Process a command by evaling $this->_R$cmd. Also checks if 
## this command was expected now (looks into the $this->{_expectedcmds} array). 
## Used by client and server.
##in> $cmd
##out> true, if ARCv2 command has been in place, otherwise false
##eg> while (my $cmd = $this->_RecvCommand() && $this->_ProcessLine($cmd)) {}
sub _ProcessLine
{
	my $this = shift;
	my $cmd = shift;
	my $ret = 1;

	$this->_Debug("Received Command: $cmd (",@{$this->{_expectedcmds}},")");
	if (grep { $_ eq $cmd } @{$this->{_expectedcmds}} ) {
		$cmd = "_R".$cmd;
		$ret = $this->_SetError("Evaluation of command $cmd failed ($@).") 
			unless eval { $this->$cmd; }
	} else {
		$ret = $this->_SetError("Unexpected command: $cmd");
	}
	return $ret;
}

## send the ARCv2 SASL command. (protocol)
## This function encodes the output from sasl_*_start and sasl_*_step with Base-64 and sends
## it to the other side
##in> $saslstr
##out> true if successful, otherwise false
##eg> $this->_Sasl($sasl->client_start());
sub _Sasl
{
	my ($this,$str) = @_;
	return $this->_SendCommand("SASL",encode_base64($str,""));
}

## initialize sasl.
## This function initializes the C<__sasl> member with an object
## of C<Authen::SASL>.
##out> true if successful, otherwise false
##eg> $this->_PrepareAuthentication() || return;
sub _PrepareAuthentication
{
	my $this = shift;
	
	# Authen::SASL Instance creation
	$this->{__sasl} = Authen::SASL->new(
		mechanism => "".$this->{_saslmech},
	);

	if (!defined $this->{__sasl}) {
		return $this->_SetError("SASL error. No SASL object created.");
	}
	return 1;
}

## are we connected?
##out> true, if the ARCv2 control connection is connected, otherwise false
##eg> last unless $arc->IsConnected;
sub IsConnected
{
	my $this = shift;
	return $this->{_connected};
}


sub clean
{
	my $this = shift;
	delete $this->{__sasl};
	$this->{__linequeue} = [];
	$this->{__partial} = ""; 
	
	$this->{_authenticated} = 0;
	$this->{_sasl} = undef;
	$this->{_saslmech} = "";

	$this->{_cmdparameter} = undef;
	$this->{_expectedcmds} = undef;
	$this->{_connected} = 0;
	$this->{_username} = "anonymous";
	$this->{_error} = undef;		

# public:
	$this->{protocol} = undef;
}

1;
