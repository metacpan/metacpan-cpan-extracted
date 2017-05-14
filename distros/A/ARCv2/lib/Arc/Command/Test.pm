package Arc::Command::Test;

use strict;
use warnings;
use Carp;
use Arc::Command;

@Arc::Command::Test::ISA = qw(Arc::Command);

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

	print "Command line arguments: ", join("|",@_),"\n" if @_;

	while ($_ = <STDIN>) {
		my $y = length($_)/2;
		print substr($_,(length($_)-$y)/2,$y),"\n";
	}

	return 1;
}

return 1;
