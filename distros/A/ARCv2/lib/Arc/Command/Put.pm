package Arc::Command::Put;

use strict;
use warnings;
use Carp;
use Arc::Command;

@Arc::Command::Put::ISA = qw(Arc::Command);

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
	return $this->_SetError("No destination filename given!") unless (@_);
	return $this->_SetError($_[0]," is not writeable for me. !") unless (open FH, ">".$_[0]);

	while ($_ = <STDIN>)
	{
		print FH $_;
	}

	close FH;
	
	return 1;
}

return 1;
