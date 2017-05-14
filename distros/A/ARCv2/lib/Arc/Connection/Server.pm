package Arc::Connection::Server;

use strict;
use warnings;
use Carp;

use IO::Select;
use IO::Pipe;
use IO::Socket::INET;
use Arc qw(LOG_AUTH LOG_USER LOG_ERR LOG_CMD LOG_SIDE LOG_DEBUG);
use Arc::Connection;
use MIME::Base64;

@Arc::Connection::Server::ISA = qw(Arc::Connection);

sub members
{
	my $this = shift;
	return { %{$this->SUPER::members},
		_realm => "",             # Name of the SASL realm, if the user is from the default realm, this is empty
		logfileprefix => "server",

		sasl_cb_getsecret => "",  # Callback for SASL (if PLAIN (or equal) mechanisms are used). See Authen::SASL(::Cyrus).
		sasl_cb_checkpass => 0,   # Callback for SASL (if PLAIN (or equal) mechanisms are used). See Authen::SASL(::Cyrus).
		sasl_mechanisms => undef, # array of allowed SASL mechanisms

		commands => undef,        # hash of assignment between B<Command Name> and B<Command Class>. See L<Arc::Command>
	};
}

sub _Init
{
	my $this = shift;

	return unless $this->SUPER::_Init(@_);

	# sasl_mechanisms
	return $this->_SetError("No SASL mechanisms given.")
		unless defined $this->{sasl_mechanisms};

	# commands
	return $this->_SetError("No ARCv2 commands given. There is no reason the run ARCv2.")
		unless defined $this->{commands};
}

## Callback function to canonicalize the username (SASL)
## see Authen::SASL(::Cyrus) for parameter list and how to use.
sub _CBCanonUser
{
	my ($this,$type,$realm,$maxlen,$user) = @_;
	return $user;
}

## send the available SASL mechanisms.
## Protocol command: AUTH <comma-seperated list of SASL mechansims>\r\n
##out> true when succesful, otherwise false
##eg> $this->_Auth();
sub _Auth
{
	my $this = shift;

	@{$this->{_expectedcmds}} = qw(QUIT AUTHENTICATE);
	return $this->_SendCommand("AUTH",join (",",@{$this->{sasl_mechanisms}}));
}

## send an error msg to client (Server error).
## Protocol command: ERR <msg>\r\n
##out> true when succesful, otherwise false
##eg> $this->_Error("failure.");
sub _Error
{
	my $this = shift;
	return $this->_SendCommand("ERR",join("",@_));
}

## send a command error msg to client.
## Protocol command: CMDERR <msg>\r\n
##out> true when succesful, otherwise false
##eg> $this->_CmdError("failure.");
sub _CmdError
{
	my $this = shift;
	return $this->_SendCommand("CMDERR",join("",@_));
}

## command is ready.
## When the ARCv2 command is ready with its work, the server
## sends the DONE command on the control connection.
## Protocol command: DONE\r\n
##out> true when succesful, otherwise false
##eg> $this->_Done();
sub _Done
{
	my $this = shift;
	return $this->_SendCommand("DONE");
}

## tell the client, which SASL mechanism is used.
## Protocol command: AUTHTYPE <SASL mechansism>\r\n
##out> true when succesful, otherwise false
##eg> $this->_Authtype();
sub _Authtype
{
	my $this = shift;
	@{$this->{_expectedcmds}} = qw(QUIT SASL);
	return $this->_SendCommand("AUTHTYPE",$this->{_saslmech});
}

## Creates the sasl object (server_new)
## and sends the first sasl challenge/response.
## Protocol command: SASL <base64 encoded SASL output>\r\n
##out> true when succesful, otherwise false
##eg> $this->_StartAuthentication();
sub _StartAuthentication
{
	my $this = shift;

	$this->_PrepareAuthentication() || return;

	# Setting the Callback for getting the username
	# This has to happen just before the object-creation of cyrus sasl
	# because there is no way to set a callback after sasl_*_new
	$this->{__sasl}->callback(
		canonuser => [ \&_CBCanonUser, $this ],
		checkpass => $this->{sasl_cb_checkpass},
		getsecret => $this->{sasl_cb_getsecret},
	);

	my $sasl = $this->{_sasl} =
		$this->{__sasl}->server_new(
			$this->{service},
			"",
			inet_ntoa($this->{_connection}->sockaddr).";".$this->{_connection}->sockport,
			inet_ntoa($this->{_connection}->peeraddr).";".$this->{_connection}->peerport,
	);

	if ((!defined $sasl) or ($sasl->code != 0)) {
		return $this->_SetError("SASL: ",$sasl->error());
	}

	$this->_Debug("Available mechanisms. ",$sasl->listmech("","|",""));

	return $this->_StepAuthentication(1);
}

## Another SASL step
## Response of a SASL command from the client
## Protocol command: SASL <base64 encoded SASL outout>\r\n
##in> bool $first_step
##out> true when succesful, otherwise false
##eg> $this->_StepAuthentication(1);
sub _StepAuthentication
{
	my $this = shift;
	my $first = shift;
	my $sasl = $this->{_sasl};
	my $ret = 0;
	my $str;

	if ($first) {
		if ($this->{_cmdparameter} =~ /^\s+$/) {
			$this->_Debug("No cmdparameter, plain server start.");
			$str = $sasl->server_start();
		} else {
			$this->_Debug("SASL parameter is present.");
			$str = $sasl->server_start(decode_base64($this->{_cmdparameter}));
		}
	} else {
		$str = $sasl->server_step(decode_base64($this->{_cmdparameter}));
	}

	$str = "" unless defined $str;

	if ($sasl->need_step || $sasl->code == 0) {
		if ($sasl->code == 0) {
			$this->_Sasl($str) if $str ne "";

			$this->{_authenticated} = 1;
			@{$this->{_expectedcmds}} = qw(QUIT CMD);
			$this->{_username} = $sasl->property("user");
			$this->{_realm} = $sasl->property("realm");

			$this->Log(LOG_AUTH,"SASL: Negotiation complete. User '".$this->{_username}.
				"' is authenticated using ".$this->{_saslmech}.". (".$this->{_connection}->peerhost.")");
			$ret = 1;
		} else {
			$ret = $this->_Sasl($str);
		}
	} else {
		$ret = $this->_Error("SASL: Negotiation failed. User is not authenticated. (",$sasl->code,") ",
			$sasl->error);
	}
	return $ret;
}
## parses the AUTHENTICATE[ <SASL mech>]\r\n, sent by the client.
## Checks if the demanded SASL mechanism is allowed and returns the
## selected mechanism.
sub _RAUTHENTICATE
{
	my $this = shift;

	if ( $this->{_cmdparameter} ne "") {
		if (grep ({ $_ eq $this->{_cmdparameter}} @{$this->{sasl_mechanisms}} )) {
			$this->{_saslmech} = $this->{_cmdparameter};
		} else {
			return $this->_Error("SASL mechanism not allowed by server.");
		}
	} else {
		$this->_Debug("Default Sasl: ",@{$this->{sasl_mechanisms}}[0]);

		$this->{_saslmech} = @{$this->{sasl_mechanisms}}[0];
	}

	return $this->_Authtype();
}

## parses the SASL <base64 encoded SASL string>\r\n, sent by the client.
## Sasl challenge/response from the client
sub _RSASL
{
	my $this = shift;
	my $ret;

	if (!defined $this->{_sasl}) {
		$ret = $this->_StartAuthentication() || die "Sasl StartAuthentication failed.";
	} else {
		$ret = $this->_StepAuthentication() || die "Sasl StepAuthentication failed.";
	}
	return $ret;
}

## See source code for this method. /dev/null for unwanted output.
sub tonne {

}

## parses the CMD <cmd>\r\n, sent by the client.
## check if the command exists, prepares the command connection, executes the command and
## does cleanups after execution.
sub _RCMD
{
	my $this = shift;

	my ($cmd,$para) = split(/\s+/,$this->{_cmdparameter},2);
	$this->_Error("Command not found.") unless defined $cmd;

	my $perlcmd = $this->{commands}->{$cmd};
my $reason = $this->_CheckCmd($cmd, $perlcmd);

	if (defined $reason) {
		$this->Log(LOG_USER, "Command '$cmd' requested by user '".$this->{_username}.
		"' not ok", $reason ? ": $reason" : "");
		$this->_Error("Command $cmd not ok", $reason ? ": $reason" : "");
	} elsif( !$this->{_error} && defined $perlcmd ) {
		$this->Log(LOG_USER,"Command '$cmd' requested by user '".$this->{_username}.
			"' mapped to '$perlcmd'",$para ? "with parameters '$para'" : "");
		if (eval "require $perlcmd;") {

			my $in =  new IO::Pipe || return $this->_SetError("Could not create in-Pipe");
			my $out = new IO::Pipe || return $this->_SetError("Could not create out-Pipe");
			my $err = new IO::Pipe || return $this->_SetError("Could not create err-Pipe");

			my $oldsigchld = $SIG{CHLD};
			$SIG{CHLD} = 'IGNORE';

			my $cmdpid = fork();
			if ($cmdpid == 0) { # Child
				$this->{logfileprefix} = "commandchild";

# prepare environment for the command
				$in->writer(); $out->reader(); $err->writer();
				open STDIN, "<&", $out;
				open STDOUT, ">&", $in;
				open STDERR, ">&", $err;

				my @a = $this->_SplitCmdArgs($para);
				my ($ret, $cmderr) = $this->_RunCmd($cmd, $perlcmd, \@a);

				if ($cmderr) {
					$ret = 1;
					$cmderr =~ s/\r//g; $cmderr =~ s/\n/ /g; $cmderr =~ s/ +/ /g;
					print $err $cmderr;
				}
				close $in; close $out; close $err;

				exit $ret;
			} elsif ($cmdpid) {

				$this->Log(LOG_SIDE,"Awaiting command connection.");
				$this->_CommandConnection();

				# check that the connecting host is really the host we are expecting to be.
				my ($peerport,$peeraddr) = sockaddr_in($this->{_cmdclientsock}->peername);
				$peeraddr = inet_ntoa($peeraddr);

				if ($peeraddr eq $this->{_connection}->peerhost) {

					$this->Log(LOG_CMD,"Command connection established.");

					$in->reader(); $out->writer(); $err->reader();

					$out->autoflush(1);
					$this->_ReadWriteBinary($in,$out);

					$this->{_cmdclientsock}->close();

					$this->Log(LOG_CMD,"Command done.");

					while (<$err>) {
						$this->_CmdError($_);
#						$this->_Debug("command errors: $_");
					}

					close $in; close $out; close $err;
				} else {
					$this->_SetError("Unknown host wanted ".
						"to use our command connection. ($peeraddr)");
				}
				wait();
			} else {
				$this->_SetError("Fork error.");
			}
			$SIG{CHLD} = $oldsigchld;
		} else {
			my $e = $@;
			$this->Log(LOG_CMD,"$perlcmd: ",$e);
			$this->_Error("Command $perlcmd not found or error: ".$e);
		}
	} else {
		$this->Log(LOG_USER,"Command '$cmd' requested by user '".$this->{_username}.
			"'",$para ? "with parameters '$para'" : "","was not found!");
		$this->_Error("Command $cmd not found (Unknown Command).");
	}
	$this->_Done();
	$SIG{__WARN__} = 'DEFAULT';
	if ($this->{_error}) {
		$this->_Debug("_RCMD ended with an error");
	} else {
		$this->_Debug("_RCMD ended ok");
	}

	return !$this->{_error};
}

sub _CheckCmd
{
   my $this = shift;
   my ($cmd, $perlcmd) = @_;

   # Do nothing by default.
   # This method is mearly here so a sub-class can override it.

   return undef;
}

sub _SplitCmdArgs
{
   my $this = shift;
   my $para = shift;
   return split(/\s+/,$para) if defined $para; # better splitting for array TODO
   return ();
}

sub _RunCmd
{
	my $this = shift;
	my ($cmd, $perlcmd, $argref) = @_;

	my $cmderr;
	my $ret = eval {
		my $object = new $perlcmd (
			_commands => $this->{commands},
			_username => $this->{_username},
			_realm    => $this->{_realm},
			_mech     => $this->{_saslmech},
			_peeraddr => $this->{_connection}->peerhost,
			_peerport => $this->{_connection}->peerport,
			_peername => $this->{_connection}->peername,
			_cmd => $cmd,
			logfileprefix => "command",
		);
		$object->Execute(@{ $argref });
		$cmderr = $object->IsError();
		return 0;
	};

	$ret = 2 unless defined($ret);
	$cmderr .= " ".$@ if $@;

	return ($ret, $cmderr);
}

## does nothing, placeholder for QUIT\r\n command, sent by the client.
sub _RQUIT
{
	my $this = shift;
	return 1;
}

## Public function, gets the clientsocket (from Arc::Server) and handles it.
## Handles a connection (main loop).
##in> $clientsock (IO::Socket)
##out> true on success, otherwise false
##eg> $arc->HandleClient(sock);
sub HandleClient
{
	my $this = shift;
	return $this->_SetError("Client socket needed.") unless (@_ == 1);
	my $client = shift;

# Fill the connected Socket into the select object
	$this->{_connection} = $client;
	$this->{_connected} = 1;
	$this->{_select} = new IO::Select( $client );

	my $line = $this->_RecvLine();
	unless ($this->{_error}) {
		if ($line =~ m/^ARC\/2.(0|1)\r?\n$/) { # Protocoltype 2

			$this->{protocol} = $1;
			$this->Log(LOG_USER,"Arc v2.$1 Session recognized.");
			$this->_Auth();

			my $cmd;
			while ((!$this->{_error}) && ($cmd = $this->_RecvCommand())) {
				last unless $this->_ProcessLine($cmd);
				last if $cmd eq "QUIT";
			}
			$this->Quit();
		} else {
			return $line;
		}
	}
	return !$this->{_error};
}

## Ends the connection.
## Do some cleanup.
##out> always true
##eg> $arc->Quit();
sub Quit
{
	my $this = shift;

	$this->{_connection}->close if ($this->{_connection});
	$this->{_connected} = 0;
	delete $this->{_sasl};
	$this->{_authenticated} = 0;

	1;
}

1;
