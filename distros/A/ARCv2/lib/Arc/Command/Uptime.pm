package Arc::Command::Uptime;

use strict;
use warnings;
use Carp;
use Arc::Command;
use POSIX qw(setsid);

@Arc::Command::Uptime::ISA = qw(Arc::Command);

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

	system("uptime");

	return 1;
}

return 1;
