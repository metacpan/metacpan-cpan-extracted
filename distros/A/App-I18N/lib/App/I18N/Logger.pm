package App::I18N::Logger;
use warnings;
use strict;

sub new { 
	return bless {} , shift;
}

sub info {
	my $class = shift;
	print @_ , "\n";
}

sub debug {
	my $class = shift;
	print @_ , "\n";
}

sub error {
	my $class = shift;
	print @_, "\n";
}

1;
