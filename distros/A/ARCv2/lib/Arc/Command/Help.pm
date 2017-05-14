package Arc::Command::Help;

use strict;
use warnings;
use Carp;
use Arc::Command;

@Arc::Command::Help::ISA = qw(Arc::Command);

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

	print "This is $Arc::Copyright\n";
	print "Please report bugs to: $Arc::Contact\n";
	
	print "\n";
	print "Available Commands:\n";

# sort command 
	my %h;

	foreach (keys %{$this->{_commands}}) {
		push (@{$h{$this->{_commands}->{$_}}}, $_);
	}
	
	foreach (sort keys %h) {
		print "\t",join (", ",@{$h{$_}}),"\n";
	}
	
	
	1;
}

1;
