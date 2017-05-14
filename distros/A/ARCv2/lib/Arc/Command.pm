package Arc::Command;

use strict;
use warnings;
use Carp;
use Arc;

@Arc::Command::ISA = qw(Arc);

# Friend class Arc::Connection::Server;
sub members 
{
	my $this = shift;
	return { %{$this->SUPER::members},
		# private:
			
		# protected:
			_commands => {},    # the "available commands"-hash from the server, 
			_username => "",    # user, who has authenticated against ARCv2 Server by using SASL
			_realm => "",       # the name of the realm, to which the user belongs (SASL)
			_mech => undef,     # user uses this authentication mechanism (e.g. GSSAPI)
			_peeraddr => undef, # users ip address
			_peername => undef, # users host address in sockaddr_in format
			_peerport => undef, # users port
			_cmd => undef,      # user runs this command

		# public: 
			logfileprefix => "command",
	};
}

## execute this command.
## This function is called by the ARCv2 Server when the user wants 
## to execute this command. 
##in> ... (parameter from users request)
##out> true if the command has succeeded, false (and please set _SetError) if not.
sub Execute
{
	my $this = shift;
	
	return 1;
}

return 1;
