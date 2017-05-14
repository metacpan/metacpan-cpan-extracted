package Arc::Command::Whoami;

use strict;
use warnings;
use Arc::Command;
use IO::Socket;

@Arc::Command::Whoami::ISA = qw(Arc::Command);

sub members 
{
	my $this = shift;
	return { %{$this->SUPER::members},
		# private:
		# protected:
	};
}

sub Execute
{
	my $this = shift;
	my $name = gethostbyaddr(inet_aton($this->{_peeraddr}),AF_INET);
	print $this->{_username}," coming from ",$name," [",$this->{_peeraddr},"] Port ",
		$this->{_peerport},"\n";
	return 1;
}

return 1;
