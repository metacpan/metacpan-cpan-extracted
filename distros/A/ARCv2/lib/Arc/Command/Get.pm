package Arc::Command::Get;

use strict;
use warnings;
use Carp;
use Arc::Command;

@Arc::Command::Get::ISA = qw(Arc::Command);

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
	
	return $this->_SetError("What shall I copy? Please give the filename.") unless @_;
	return $this->_SetError($_[0]," not found or is not readable for me. $!") unless (open FH, "<", $_[0]);

	print <FH>;
	close FH;
}

return 1;
