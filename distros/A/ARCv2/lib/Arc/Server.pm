package Arc::Server;

use strict;
use warnings;
use Carp;
use Net::Server::PreFork;
use IO::Socket;
use Arc qw(LOG_AUTH LOG_USER LOG_ERR LOG_CMD LOG_SIDE LOG_DEBUG);

@Arc::Server::ISA = qw(Arc Net::Server::PreFork);

sub members
{
	my $this = shift;
	return { %{$this->SUPER::members},
		# private:
			__arc => undef,                # stores the Arc::Connection::Server object for optimal PreFork
		# protected:

		# public:
			connection_type => 'Arc::Connection::Server', # Class to use for connections
			connection_vars => undef,      # variables passed directly to every connection handle See C<Arc::Connection::Server>

			logfileprefix => "mainserver", # Logfileprefix

		# net::server
			server => undef,        # attributes for Net::Server::PreFork
	};
}

sub _Init
{
	my $this = shift;

	return unless $this->SUPER::_Init(@_);

	return $this->_SetError("You have to specify at least the SASL mechs and the commands you want to run, to start the ARCv2 Server.")
		unless $this->{connection_vars};

	unless (defined $this->{server}->{host}) {
		$this->Log(LOG_SIDE,"No host (listenaddress) specified, falling back to all addresses (0).");
		$this->{server}->{host} = 0;
	}

	unless (defined $this->{server}->{port}) {
		$this->Log(LOG_SIDE,"No port specified, falling back to standard port $Arc::DefaultPort.");
		$this->{server}->{port} = [$Arc::DefaultPort];
	}

# net::server::* initilizations
	$this->{server}->{proto} = 'tcp';
	$this->{server}->{listen} = SOMAXCONN;
	$this->{server}->{child_communication} = undef,
}

## start the server
## This function is used by the user to start the server and enter the main accept-loop.
## Only by calling the C<Interrupt> function this call can be aborted.
##out> return true if everything worked fine, otherwise false is returned and C<IsError> should be checked.
##eg> $arc->Start();
sub Start
{
	my $this = shift;
	my $ct = $this->{connection_type};
	eval "require $ct";
	croak "Please \"use $ct\" before calling Start(): $@" if $@;
	$this->run();
	return 1;
}

# Net::Server::* hooks and overrides

sub process_request
{
	my $this = shift;
	my $arc = $this->{__arc};
#	my $arc = new Arc::Connection::Server(
#		%{$this->{connection_vars}},
#	);
	return $this->_SetError("No Arc::Connection::Server object was created.")
		unless $arc;
	$this->Log(LOG_USER,"Client connection from",$this->{server}->{client}->peerhost);
	$arc->HandleClient($this->{server}->{client});
	$arc->clean;
	$this->Log(LOG_USER,"Client connection closed.");
}

sub write_to_log_hook
{
	my ($this,$loglevel,$msg) = @_;
	$msg =~ s/[\n\r]//g;
	$this->Log(LOG_SIDE,$msg);
	1;
}

sub child_init_hook
{
	my $this = shift;
	my $ct = $this->{connection_type};
	$this->{__arc} = new $ct (
		%{$this->{connection_vars}},
	);
}

# deleting STDIN and STDOUT kills ARCv2, don't know if Net::Server does
# is right
sub post_accept
{
	my $this = shift;
	my $prop = $this->{server};

### keep track of the requests
	$prop->{requests} ++;
}

1;
